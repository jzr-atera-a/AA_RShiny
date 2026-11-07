# R/utils_api.R
# APIManager R6 Class - Manages Claude API and BigQuery connections
# Uses reactive triggers for cross-module state updates
# =================================================================

library(R6)
library(httr)
library(jsonlite)
library(bigrquery)

APIManager <- R6::R6Class(
  "APIManager",

  public = list(
    # Claude API credentials
    claude_api_key = NULL,
    claude_model = "claude-sonnet-4-6",
    claude_max_tokens = 16000,
    claude_timeout = 300,
    claude_authenticated = FALSE,

    # BigQuery credentials
    bq_project_id = "atera-2",
    bq_dataset_id = "Wonderfulp_March",
    bq_table_id = "flex_comparison_tables",
    bq_full_table_id = NULL,
    bq_authenticated = FALSE,
    bq_temp_file = NULL,

    # ⭐ CRITICAL: Reactive trigger for cross-module updates
    state_trigger = NULL,

    # Cross-module data handoff: generate_table -> bulk_import textarea
    pending_bulk_text = NULL,

    # ============================================================
    # DEBUG / CONSOLE LOGGING
    # ============================================================
    # Every stage of a Claude API call is logged to the R console with a
    # timestamp so that failures (network drops, timeouts, TLS errors)
    # leave a forensic trail even when the UI can only show a short,
    # user-friendly message. NEVER logs the API key itself.
    log_debug = function(msg, tag = "APIManager") {
      cat(sprintf("[%s] [%s] %s\n", format(Sys.time(), "%H:%M:%OS3"), tag, msg))
    },

    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
      self$pending_bulk_text <- shiny::reactiveVal("")
      self$bq_full_table_id <- paste0(self$bq_project_id, ".",
                                       self$bq_dataset_id, ".",
                                       self$bq_table_id)
      cat("🔌 API Manager initialized with reactive trigger\n")
    },

    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)
      cat("🔔 State trigger fired:", current + 1, "\n")
    },

    set_pending_bulk_text = function(text) {
      self$pending_bulk_text(text)
    },

    empty_taxonomy = function() {
      data.frame(category = character(), topic = character(),
                 table_title = character(), row_dimension_label = character(),
                 column_dimension_label = character(),
                 stringsAsFactors = FALSE)
    },

    # ============================================================
    # CLAUDE API METHODS
    # ============================================================

    set_claude_credentials = function(api_key, model = NULL, max_tokens = NULL, timeout = NULL) {
      self$claude_api_key <- api_key
      if (!is.null(model)) self$claude_model <- model
      if (!is.null(max_tokens)) self$claude_max_tokens <- max_tokens
      if (!is.null(timeout)) self$claude_timeout <- timeout
    },

    test_claude_connection = function() {
      if (is.null(self$claude_api_key)) {
        stop("Claude API key not set")
      }

      tryCatch({
        response <- POST(
          url = "https://api.anthropic.com/v1/messages",
          add_headers(
            "x-api-key" = self$claude_api_key,
            "anthropic-version" = "2023-06-01",
            "content-type" = "application/json"
          ),
          body = toJSON(list(
            model = self$claude_model,
            max_tokens = 100,
            messages = list(list(role = "user", content = "Hello, test message."))
          ), auto_unbox = TRUE),
          encode = "json",
          config = httr::config(timeout = 60)
        )

        if (status_code(response) == 200) {
          self$claude_authenticated <- TRUE
          self$trigger_state_update()
          return(TRUE)
        } else {
          status <- status_code(response)
          error_content <- tryCatch({
            content(response, "parsed", encoding = "UTF-8")
          }, error = function(e) {
            content(response, "text", encoding = "UTF-8")
          })

          detail <- if (is.list(error_content) && !is.null(error_content$error$message)) {
            error_content$error$message
          } else if (is.character(error_content)) {
            error_content
          } else {
            "(no error detail in response body)"
          }

          stop(sprintf("Status code: %d - %s", status, detail))
        }
      }, error = function(e) {
        self$claude_authenticated <- FALSE
        stop(paste("Connection failed:", e$message))
      })
    },

    call_claude = function(prompt, max_tokens = NULL, progress_callback = NULL) {
      if (!self$claude_authenticated) {
        stop("Not authenticated to Claude API. Please save credentials first.")
      }
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0) {
        stop("Claude API key is empty. Please configure credentials.")
      }

      tokens <- max_tokens %||% self$claude_max_tokens

      if (!is.null(progress_callback)) progress_callback("Connecting to Claude API...")

      call_id <- paste(sample(c(letters, LETTERS, 0:9), 8, replace = TRUE), collapse = "")
      start_time <- Sys.time()

      self$log_debug(sprintf(
        "[%s] Sending STREAMING request | model=%s | max_tokens=%d | timeout=%ds | prompt_chars=%d",
        call_id, self$claude_model, tokens, self$claude_timeout, nchar(prompt)
      ), tag = "call_claude")

      # ============================================================
      # STREAMING (Server-Sent Events) instead of a single blocking
      # POST/wait/receive-everything-at-once call.
      #
      # WHY: a plain (non-streaming) request sends ZERO bytes back while
      # Claude generates the full response server-side - for a detailed
      # table that can be 60+ seconds of complete silence on the wire.
      # Many corporate proxies / VPN clients / antivirus HTTPS-inspection
      # layers enforce a fixed IDLE-connection timeout (commonly ~60s)
      # and will kill a silent connection even though nothing is actually
      # wrong - this is what produced the repeated "schannel: server
      # closed abruptly" errors at ~60.1s regardless of the configured
      # 1800s timeout. Streaming sends small chunks continuously as each
      # token is generated, so the connection never looks idle.
      # ============================================================

      body_json <- toJSON(list(
        model = self$claude_model,
        max_tokens = tokens,
        stream = TRUE,
        messages = list(list(role = "user", content = prompt))
      ), auto_unbox = TRUE)

      h <- curl::new_handle()
      curl::handle_setopt(h, post = TRUE, postfields = body_json, timeout = self$claude_timeout)
      curl::handle_setheaders(h,
        "x-api-key" = self$claude_api_key,
        "anthropic-version" = "2023-06-01",
        "content-type" = "application/json"
      )

      accumulated_text <- character(0)
      sse_buffer <- ""
      raw_buffer <- ""          # full raw bytes, used to parse a non-streamed error body
      last_log_time <- start_time
      chunk_count <- 0
      byte_count <- 0
      stream_error_msg <- NULL
      final_usage <- NULL

      parse_sse_event <- function(event_block) {
        data_lines <- grep("^data: ", strsplit(event_block, "\n")[[1]], value = TRUE)
        if (length(data_lines) == 0) return(invisible(NULL))

        for (dl in data_lines) {
          json_str <- sub("^data: ", "", dl)
          if (trimws(json_str) == "[DONE]" || trimws(json_str) == "") next

          parsed <- tryCatch(jsonlite::fromJSON(json_str, simplifyVector = FALSE),
                              error = function(e) NULL)
          if (is.null(parsed) || is.null(parsed$type)) next

          if (parsed$type == "content_block_delta" &&
              !is.null(parsed$delta) && identical(parsed$delta$type, "text_delta")) {
            accumulated_text[[length(accumulated_text) + 1]] <<- parsed$delta$text %||% ""

          } else if (parsed$type == "message_delta" && !is.null(parsed$usage)) {
            final_usage <<- parsed$usage

          } else if (parsed$type == "error") {
            stream_error_msg <<- parsed$error$message %||% "Unknown streaming error from Claude API"
          }
        }
      }

      process_chunk <- function(raw_bytes) {
        chunk_count <<- chunk_count + 1
        byte_count <<- byte_count + length(raw_bytes)

        text_piece <- tryCatch(rawToChar(raw_bytes), error = function(e) "")
        sse_buffer <<- paste0(sse_buffer, text_piece)
        raw_buffer <<- paste0(raw_buffer, text_piece)

        now <- Sys.time()
        if (as.numeric(difftime(now, last_log_time, units = "secs")) >= 5) {
          self$log_debug(sprintf(
            "[%s] Streaming... %d chunk(s), %d bytes, %d chars accumulated so far (%.1fs elapsed)",
            call_id, chunk_count, byte_count, sum(nchar(accumulated_text)),
            as.numeric(difftime(now, start_time, units = "secs"))
          ), tag = "call_claude")
          if (!is.null(progress_callback)) {
            progress_callback(sprintf("Streaming response... %d characters received so far",
                                       sum(nchar(accumulated_text))))
          }
          last_log_time <<- now
        }

        while (grepl("\n\n", sse_buffer, fixed = TRUE)) {
          split_pos <- regexpr("\n\n", sse_buffer, fixed = TRUE)
          event_block <- substr(sse_buffer, 1, split_pos - 1)
          sse_buffer <<- substr(sse_buffer, split_pos + 2, nchar(sse_buffer))
          parse_sse_event(event_block)
        }
      }

      tryCatch({
        curl::curl_fetch_stream(url = "https://api.anthropic.com/v1/messages",
                                fun = process_chunk, handle = h)

        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

        # Flush any trailing event that didn't end with a blank line
        if (nchar(trimws(sse_buffer)) > 0) parse_sse_event(sse_buffer)

        resp_meta <- tryCatch(curl::handle_data(h), error = function(e) NULL)
        status <- if (!is.null(resp_meta)) resp_meta$status_code else NA_integer_

        self$log_debug(sprintf(
          "[%s] Stream finished | status=%s | elapsed=%.2fs | chunks=%d | bytes=%d",
          call_id, status, elapsed, chunk_count, byte_count
        ), tag = "call_claude")

        if (!is.na(status) && status != 200) {
          error_content <- tryCatch(jsonlite::fromJSON(raw_buffer, simplifyVector = FALSE),
                                     error = function(e) raw_buffer)

          self$log_debug(sprintf("[%s] Non-200 response body: %s", call_id,
                                  jsonlite::toJSON(error_content, auto_unbox = TRUE)),
                          tag = "call_claude")

          error_msg <- if (is.list(error_content) && !is.null(error_content$error)) {
            paste0("API Error (", status, "): ", error_content$error$message)
          } else if (is.character(error_content)) {
            paste0("API Error (", status, "): ", error_content)
          } else {
            paste0("API Error: HTTP ", status)
          }

          if (status == 401) {
            error_msg <- "Authentication failed: Invalid API key. Please check your credentials."
          } else if (status == 429) {
            error_msg <- "Rate limit exceeded: Too many requests. Please wait and try again."
          } else if (status == 500) {
            error_msg <- "Claude API server error: Please try again in a few moments."
          } else if (status == 529) {
            error_msg <- "Claude API is overloaded: Please try again in a few moments."
          }

          stop(error_msg)
        }

        if (!is.null(stream_error_msg)) {
          stop(paste0("Streaming error from Claude API: ", stream_error_msg))
        }

        response_text <- paste(accumulated_text, collapse = "")

        if (nchar(response_text) == 0) {
          self$log_debug(sprintf("[%s] Stream completed but produced no text", call_id), tag = "call_claude")
          stop("Claude API returned an empty response. Please try again.")
        }

        self$log_debug(sprintf(
          "[%s] SUCCESS | response_chars=%d | elapsed=%.2fs | usage=%s",
          call_id, nchar(response_text), elapsed,
          jsonlite::toJSON(final_usage %||% list(), auto_unbox = TRUE)
        ), tag = "call_claude")

        if (!is.null(progress_callback)) progress_callback("Complete!")

        return(response_text)

      }, error = function(e) {
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        error_msg <- e$message

        # ---- Full, unredacted diagnostic dump to the R console ----
        self$log_debug(sprintf("[%s] FAILED after %.2fs", call_id, elapsed), tag = "call_claude ERROR")
        self$log_debug(sprintf("[%s] Condition class: %s", call_id, paste(class(e), collapse = ", ")),
                        tag = "call_claude ERROR")
        self$log_debug(sprintf("[%s] Raw message: %s", call_id, error_msg), tag = "call_claude ERROR")
        self$log_debug(sprintf(
          "[%s] Stream progress before failure: %d chunk(s), %d bytes, %d chars accumulated",
          call_id, chunk_count, byte_count, sum(nchar(accumulated_text))
        ), tag = "call_claude ERROR")
        self$log_debug(sprintf(
          "[%s] Request context: model=%s max_tokens=%d timeout=%ds prompt_chars=%d",
          call_id, self$claude_model, tokens, self$claude_timeout, nchar(prompt)
        ), tag = "call_claude ERROR")
        tryCatch({
          cv <- curl::curl_version()
          self$log_debug(sprintf("[%s] curl version: %s | ssl_version: %s",
                                  call_id, cv$version, cv$ssl_version), tag = "call_claude ERROR")
        }, error = function(e2) {
          self$log_debug(sprintf("[%s] Could not read curl::curl_version() (curl pkg not available?)", call_id),
                          tag = "call_claude ERROR")
        })
        self$log_debug("---- end of diagnostic dump ----", tag = "call_claude ERROR")

        # ---- Short, user-facing message shown in the Shiny UI ----
        if (chunk_count > 0 && grepl("schannel|close_notify|peer", error_msg, ignore.case = TRUE)) {
          # Streaming WAS active (bytes were flowing) and it still dropped -
          # this points away from a simple idle-timeout and toward a proxy/
          # firewall actively terminating long-lived HTTPS streams outright.
          error_msg <- paste0(
            "Connection dropped mid-stream after ", round(elapsed, 1), "s, having already received ",
            chunk_count, " chunk(s) / ", byte_count, " bytes / ", sum(nchar(accumulated_text)),
            " characters. Since data WAS flowing, this looks like a firewall/proxy/VPN actively ",
            "terminating long HTTPS connections rather than a simple idle timeout. ",
            "Try: (1) a different network (e.g. mobile hotspot) to confirm, (2) ask IT to allow-list ",
            "api.anthropic.com for long-lived streaming connections, (3) temporarily disable VPN/antivirus ",
            "HTTPS inspection. [call_id: ", call_id, " - see R console for full diagnostic dump]"
          )
        } else if (grepl("Timeout", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "Request timeout after ", self$claude_timeout, " seconds (elapsed ", round(elapsed, 1), "s). ",
            "Try: (1) Increase timeout in Claude API Config, ",
            "(2) narrow the request scope, or (3) try again later. ",
            "[call_id: ", call_id, " - see R console for full diagnostic dump]"
          )
        } else if (grepl("schannel|close_notify", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "TLS connection closed abruptly after ", round(elapsed, 1), "s (schannel/close_notify), before any ",
            "data was received. This points to a firewall, antivirus HTTPS inspection, VPN, or proxy blocking ",
            "the connection outright - it is usually NOT a real loss of internet access. ",
            "Try: (1) Run Network Diagnostics in Claude API Config, (2) temporarily disable VPN/antivirus ",
            "HTTPS scanning, (3) try a different network. ",
            "[call_id: ", call_id, " - see R console for full diagnostic dump]"
          )
        } else if (grepl("peer|SSL|connection", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0("Network connection error (elapsed ", round(elapsed, 1), "s): ", error_msg,
                               ". Please check your connection and try again. ",
                               "[call_id: ", call_id, " - see R console for full diagnostic dump]")
        } else if (grepl("curl", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0("HTTP request error (elapsed ", round(elapsed, 1), "s): ", error_msg,
                               ". Please check your internet connection and try again. ",
                               "[call_id: ", call_id, " - see R console for full diagnostic dump]")
        } else {
          error_msg <- paste0(error_msg, " [call_id: ", call_id, " - see R console for full diagnostic dump]")
        }

        stop(error_msg)
      })
    },

    # Lightweight pre-flight connectivity/SSL check - separate from a real
    # generation call so the user can diagnose network issues (e.g. the
    # Windows Schannel "close_notify" TLS error) without waiting minutes
    # for a large table to time out first. Prints full detail to console
    # and returns a short summary list for the UI.
    diagnose_network = function() {
      lines <- c()
      log_line <- function(msg) {
        self$log_debug(msg, tag = "diagnose_network")
        lines <<- c(lines, msg)
      }

      log_line("Starting network diagnostics...")

      cv <- tryCatch(curl::curl_version(), error = function(e) NULL)
      if (!is.null(cv)) {
        log_line(sprintf("curl version: %s | ssl_version: %s | libssh2: %s",
                         cv$version, cv$ssl_version %||% "unknown", cv$libssh2_version %||% "n/a"))
      } else {
        log_line("Could not read curl::curl_version()")
      }

      start_time <- Sys.time()
      reach <- tryCatch({
        r <- httr::GET("https://api.anthropic.com", httr::timeout(15))
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        list(ok = TRUE, status = httr::status_code(r), elapsed = elapsed)
      }, error = function(e) {
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        list(ok = FALSE, error = e$message, elapsed = elapsed)
      })

      if (reach$ok) {
        log_line(sprintf("Reachability check to api.anthropic.com: OK (HTTP %d, %.2fs)",
                         reach$status, reach$elapsed))
      } else {
        log_line(sprintf("Reachability check to api.anthropic.com: FAILED after %.2fs - %s",
                         reach$elapsed, reach$error))
      }

      log_line("Diagnostics complete. Full detail above in R console.")
      return(lines)
    },

    # ============================================================
    # BIGQUERY METHODS
    # ============================================================

    set_bigquery_credentials = function(project_id, dataset_id, table_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      self$bq_table_id <- table_id
      self$bq_full_table_id <- paste0(project_id, ".", dataset_id, ".", table_id)
    },

    authenticate_bigquery = function(json_path = NULL, json_text = NULL) {
      tryCatch({
        tryCatch({ bq_deauth() }, error = function(e) {})
        Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
        Sys.unsetenv("GCE_METADATA_HOST")

        if (!is.null(json_path)) {
          json_content <- fromJSON(json_path)
          required_fields <- c("type", "project_id", "private_key", "client_email")
          missing <- setdiff(required_fields, names(json_content))
          if (length(missing) > 0) stop("Missing JSON fields: ", paste(missing, collapse = ", "))
          bq_auth(path = json_path, cache = FALSE)

        } else if (!is.null(json_text)) {
          json_content <- fromJSON(json_text)
          required_fields <- c("type", "project_id", "private_key", "client_email")
          missing <- setdiff(required_fields, names(json_content))
          if (length(missing) > 0) stop("Missing JSON fields: ", paste(missing, collapse = ", "))
          temp_file <- tempfile(fileext = ".json")
          writeLines(json_text, temp_file)
          self$bq_temp_file <- temp_file
          bq_auth(path = temp_file, cache = FALSE)

        } else {
          stop("Provide JSON file path or text")
        }

        datasets <- bq_project_datasets(self$bq_project_id)

        # Create table if not exists - flexible-column schema.
        # columns_data holds an EVER-CHANGING number of "columns" per row,
        # packed as delimited text (see R/utils_common.R DELIMITER CONTRACT).
        create_table_query <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            source STRING,
            category STRING,
            topic STRING,
            table_title STRING,
            row_dimension_label STRING,
            column_dimension_label STRING,
            row_index STRING,
            columns_data STRING,
            notes STRING
          )", self$bq_full_table_id)

        tryCatch({
          bq_project_query(self$bq_project_id, create_table_query)
        }, error = function(e) {})

        self$bq_authenticated <- TRUE
        self$trigger_state_update()

        return(TRUE)
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        stop(paste("BigQuery authentication failed:", e$message))
      })
    },

    bq_query = function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      job <- bq_project_query(self$bq_project_id, query)
      return(bq_table_download(job))
    },

    # Distinct Category/Topic combinations (+ the fixed row/column
    # dimension labels that go with each Topic), used to build the
    # cascading Category -> Topic dropdowns, and to auto-fill the
    # dimension-label boxes when an existing Topic is picked.
    bq_get_taxonomy = function() {
      if (!self$bq_authenticated) return(self$empty_taxonomy())

      query <- sprintf(
        "SELECT DISTINCT category, topic, table_title, row_dimension_label, column_dimension_label
         FROM `%s` ORDER BY category, topic",
        self$bq_full_table_id
      )

      tryCatch({
        self$bq_query(query)
      }, error = function(e) {
        cat("⚠️  [bq_get_taxonomy] Query failed:", e$message, "\n")
        self$empty_taxonomy()
      })
    },

    # Insert data to BigQuery
    bq_insert = function(data_frame, table_name = NULL, source = "claude") {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`",
                              self$bq_full_table_id)

      start_id <- tryCatch({
        result <- bq_project_query(self$bq_project_id, max_id_query)
        max_id_data <- bq_table_download(result)
        as.integer(max_id_data$max_id) + 1
      }, error = function(e) { 1 })

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1)
      data_frame$created_at <- Sys.time()
      if (!"source" %in% names(data_frame)) data_frame$source <- source

      required_cols <- c("id", "created_at", "source", "category", "topic", "table_title",
                          "row_dimension_label", "column_dimension_label",
                          "row_index", "columns_data", "notes")

      for (col in required_cols) {
        if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      }

      data_frame <- data_frame[, required_cols]

      table_name <- table_name %||% self$bq_table_id
      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, table_name)
      bq_table_upload(table_ref, data_frame,
                     create_disposition = "CREATE_IF_NEEDED",
                     write_disposition = "WRITE_APPEND")

      return(nrow(data_frame))
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
