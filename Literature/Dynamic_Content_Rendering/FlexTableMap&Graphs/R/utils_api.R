# R/utils_api.R
# APIManager R6 Class - UNIFIED across Flex Table, Mind Map, and
# Knowledge Graph suites.
# =================================================================
# One shared Claude API connection and one shared BigQuery
# authentication (same project/dataset), but each sub-app has its OWN
# table and its OWN schema - so every BigQuery-specific method below
# is named per sub-app (bq_insert_flex / bq_insert_mindmap /
# bq_insert_kg, etc) rather than sharing a single generic name, since
# the three original apps' methods of the same name (bq_insert,
# bq_get_taxonomy, empty_taxonomy) had DIFFERENT required columns and
# DIFFERENT target tables - merging them under one name would only be
# able to support one sub-app correctly.
#
# Everything Claude-API-related (call_claude, streaming, diagnostics,
# logging) was byte-for-byte identical across all three source apps
# and is kept exactly once here.

library(R6)
library(httr)
library(jsonlite)
library(bigrquery)

APIManager <- R6::R6Class(
  "APIManager",

  public = list(
    # ---- Claude API credentials (shared) ----
    claude_api_key = NULL,
    claude_model = "claude-sonnet-4-6",
    claude_max_tokens = 16000,
    claude_timeout = 300,
    claude_authenticated = FALSE,

    # ---- BigQuery credentials (shared project/dataset, 3 tables) ----
    bq_project_id = "atera-2",
    bq_dataset_id = "Wonderfulp_March",
    bq_table_flex = "flex_comparison_tables",
    bq_table_mindmap = "mindmap_nodes",
    bq_table_kg = "knowledge_graph",
    bq_full_table_flex = NULL,
    bq_full_table_mindmap = NULL,
    bq_full_table_kg = NULL,
    bq_authenticated = FALSE,
    bq_temp_file = NULL,

    # ⭐ Reactive triggers for cross-module updates - deliberately SCOPED
    # PER SUB-APP (not one shared trigger), so an upload/edit in Mind Map
    # or Knowledge Graph doesn't cause Flex Table's taxonomy/table
    # reactives to needlessly re-fire and re-query BigQuery, and vice
    # versa. Each sub-app's modules only ever listen to (and fire) their
    # own trigger.
    state_trigger_flex = NULL,
    state_trigger_mindmap = NULL,
    state_trigger_kg = NULL,

    # ⭐ PERFORMANCE: taxonomy result cache, one per sub-app. Because
    # shinydashboard doesn't lazy-load hidden tabs, EVERY module across
    # all three suites is reactively alive simultaneously regardless of
    # which tab is visible - so a single trigger fire (e.g. right after
    # connecting to BigQuery) can wake up several independent reactive
    # blocks that all want the SAME taxonomy data at once (e.g. Table
    # Viewer AND Generate Table both want Flex Table's Category/Topic
    # list). Without this cache, each of those fires its own BigQuery
    # query even though the data is identical - with it, only the
    # FIRST caller per trigger increment actually queries BigQuery; the
    # rest reuse the cached result instantly. Set to NULL to force a
    # fresh fetch (done automatically whenever the matching trigger fires).
    flex_taxonomy_cache = NULL,
    mindmap_taxonomy_cache = NULL,
    kg_taxonomy_cache = NULL,

    # Flex Table specific: Generate Table -> Bulk Import handoff
    pending_bulk_text = NULL,

    initialize = function() {
      self$state_trigger_flex <- shiny::reactiveVal(0)
      self$state_trigger_mindmap <- shiny::reactiveVal(0)
      self$state_trigger_kg <- shiny::reactiveVal(0)
      self$pending_bulk_text <- shiny::reactiveVal("")
      private$recompute_full_table_ids()
      cat("🔌 API Manager initialized (Flex Table + Mind Map + Knowledge Graph)\n")
    },

    trigger_state_update_flex = function() {
      current <- self$state_trigger_flex()
      self$state_trigger_flex(current + 1)
      self$flex_taxonomy_cache <- NULL
      cat("🔔 [Flex Table] State trigger fired:", current + 1, "\n")
    },
    trigger_state_update_mindmap = function() {
      current <- self$state_trigger_mindmap()
      self$state_trigger_mindmap(current + 1)
      self$mindmap_taxonomy_cache <- NULL
      cat("🔔 [Mind Map] State trigger fired:", current + 1, "\n")
    },
    trigger_state_update_kg = function() {
      current <- self$state_trigger_kg()
      self$state_trigger_kg(current + 1)
      self$kg_taxonomy_cache <- NULL
      cat("🔔 [Knowledge Graph] State trigger fired:", current + 1, "\n")
    },

    set_pending_bulk_text = function(text) {
      self$pending_bulk_text(text)
    },

    log_debug = function(msg, tag = "APIManager") {
      cat(sprintf("[%s] [%s] %s\n", format(Sys.time(), "%H:%M:%OS3"), tag, msg))
    },

    empty_flex_taxonomy = function() {
      data.frame(category = character(), topic = character(),
                 table_title = character(), row_dimension_label = character(),
                 column_dimension_label = character(), stringsAsFactors = FALSE)
    },
    empty_mindmap_taxonomy = function() {
      data.frame(category = character(), domain = character(), topic = character(),
                 map_id = character(), map_title = character(), stringsAsFactors = FALSE)
    },
    empty_kg_taxonomy = function() {
      data.frame(category = character(), domain = character(), topic = character(),
                 graph_id = character(), graph_title = character(), stringsAsFactors = FALSE)
    },

    # ============================================================
    # CLAUDE API METHODS (identical across all three source apps)
    # ============================================================

    set_claude_credentials = function(api_key, model = NULL, max_tokens = NULL, timeout = NULL) {
      self$claude_api_key <- api_key
      if (!is.null(model)) self$claude_model <- model
      if (!is.null(max_tokens)) self$claude_max_tokens <- max_tokens
      if (!is.null(timeout)) self$claude_timeout <- timeout
    },

    test_claude_connection = function() {
      if (is.null(self$claude_api_key)) stop("Claude API key not set")

      tryCatch({
        response <- POST(
          url = "https://api.anthropic.com/v1/messages",
          add_headers(
            "x-api-key" = self$claude_api_key,
            "anthropic-version" = "2023-06-01",
            "content-type" = "application/json"
          ),
          body = toJSON(list(
            model = self$claude_model, max_tokens = 100,
            messages = list(list(role = "user", content = "Hello, test message."))
          ), auto_unbox = TRUE),
          encode = "json",
          config = httr::config(timeout = 60)
        )

        if (status_code(response) == 200) {
          self$claude_authenticated <- TRUE
          self$trigger_state_update_flex()
          self$trigger_state_update_mindmap()
          self$trigger_state_update_kg()
          return(TRUE)
        } else {
          status <- status_code(response)
          error_content <- tryCatch(content(response, "parsed", encoding = "UTF-8"),
                                    error = function(e) content(response, "text", encoding = "UTF-8"))
          detail <- if (is.list(error_content) && !is.null(error_content$error$message)) {
            error_content$error$message
          } else if (is.character(error_content)) error_content else "(no error detail in response body)"
          stop(sprintf("Status code: %d - %s", status, detail))
        }
      }, error = function(e) {
        self$claude_authenticated <- FALSE
        stop(paste("Connection failed:", e$message))
      })
    },

    diagnose_network = function() {
      lines <- c()
      log_line <- function(msg) { self$log_debug(msg, tag = "diagnose_network"); lines <<- c(lines, msg) }

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
        log_line(sprintf("Reachability check to api.anthropic.com: OK (HTTP %d, %.2fs)", reach$status, reach$elapsed))
      } else {
        log_line(sprintf("Reachability check to api.anthropic.com: FAILED after %.2fs - %s", reach$elapsed, reach$error))
      }

      log_line("Diagnostics complete. Full detail above in R console.")
      return(lines)
    },

    call_claude = function(prompt, max_tokens = NULL, progress_callback = NULL) {
      if (!self$claude_authenticated) stop("Not authenticated to Claude API. Please save credentials first.")
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0) stop("Claude API key is empty. Please configure credentials.")

      tokens <- max_tokens %||% self$claude_max_tokens
      if (!is.null(progress_callback)) progress_callback("Connecting to Claude API...")

      call_id <- paste(sample(c(letters, LETTERS, 0:9), 8, replace = TRUE), collapse = "")
      start_time <- Sys.time()

      self$log_debug(sprintf(
        "[%s] Sending STREAMING request | model=%s | max_tokens=%d | timeout=%ds | prompt_chars=%d",
        call_id, self$claude_model, tokens, self$claude_timeout, nchar(prompt)
      ), tag = "call_claude")

      body_json <- toJSON(list(
        model = self$claude_model, max_tokens = tokens, stream = TRUE,
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
      raw_buffer <- ""
      last_log_time <- start_time
      chunk_count <- 0
      byte_count <- 0
      stream_error_msg <- NULL
      final_usage <- NULL
      final_stop_reason <- NULL

      parse_sse_event <- function(event_block) {
        data_lines <- grep("^data: ", strsplit(event_block, "\n")[[1]], value = TRUE)
        if (length(data_lines) == 0) return(invisible(NULL))

        for (dl in data_lines) {
          json_str <- sub("^data: ", "", dl)
          if (trimws(json_str) == "[DONE]" || trimws(json_str) == "") next

          parsed <- tryCatch(jsonlite::fromJSON(json_str, simplifyVector = FALSE), error = function(e) NULL)
          if (is.null(parsed) || is.null(parsed$type)) next

          if (parsed$type == "content_block_delta" &&
              !is.null(parsed$delta) && identical(parsed$delta$type, "text_delta")) {
            accumulated_text[[length(accumulated_text) + 1]] <<- parsed$delta$text %||% ""
          } else if (parsed$type == "message_delta") {
            if (!is.null(parsed$usage)) final_usage <<- parsed$usage
            if (!is.null(parsed$delta$stop_reason)) final_stop_reason <<- parsed$delta$stop_reason
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
            progress_callback(sprintf("Streaming response... %d characters received so far", sum(nchar(accumulated_text))))
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
        curl::curl_fetch_stream(url = "https://api.anthropic.com/v1/messages", fun = process_chunk, handle = h)

        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        if (nchar(trimws(sse_buffer)) > 0) parse_sse_event(sse_buffer)

        resp_meta <- tryCatch(curl::handle_data(h), error = function(e) NULL)
        status <- if (!is.null(resp_meta)) resp_meta$status_code else NA_integer_

        self$log_debug(sprintf("[%s] Stream finished | status=%s | elapsed=%.2fs | chunks=%d | bytes=%d",
                               call_id, status, elapsed, chunk_count, byte_count), tag = "call_claude")

        if (!is.na(status) && status != 200) {
          error_content <- tryCatch(jsonlite::fromJSON(raw_buffer, simplifyVector = FALSE), error = function(e) raw_buffer)
          self$log_debug(sprintf("[%s] Non-200 response body: %s", call_id,
                                 jsonlite::toJSON(error_content, auto_unbox = TRUE)), tag = "call_claude")

          error_msg <- if (is.list(error_content) && !is.null(error_content$error)) {
            paste0("API Error (", status, "): ", error_content$error$message)
          } else if (is.character(error_content)) paste0("API Error (", status, "): ", error_content)
          else paste0("API Error: HTTP ", status)

          if (status == 401) error_msg <- "Authentication failed: Invalid API key. Please check your credentials."
          else if (status == 429) error_msg <- "Rate limit exceeded: Too many requests. Please wait and try again."
          else if (status == 500) error_msg <- "Claude API server error: Please try again in a few moments."
          else if (status == 529) error_msg <- "Claude API is overloaded: Please try again in a few moments."

          stop(error_msg)
        }

        if (!is.null(stream_error_msg)) stop(paste0("Streaming error from Claude API: ", stream_error_msg))

        response_text <- paste(accumulated_text, collapse = "")
        if (nchar(response_text) == 0) {
          self$log_debug(sprintf("[%s] Stream completed but produced no text", call_id), tag = "call_claude")
          stop("Claude API returned an empty response. Please try again.")
        }

        self$log_debug(sprintf(
          "[%s] SUCCESS | response_chars=%d | elapsed=%.2fs | stop_reason=%s | usage=%s",
          call_id, nchar(response_text), elapsed, final_stop_reason %||% "unknown",
          jsonlite::toJSON(final_usage %||% list(), auto_unbox = TRUE)
        ), tag = "call_claude")

        if (identical(final_stop_reason, "max_tokens")) {
          self$log_debug(sprintf("[%s] WARNING: response was CUT OFF by hitting the max_tokens limit - it is very likely incomplete.", call_id), tag = "call_claude")
        }

        if (!is.null(progress_callback)) progress_callback("Complete!")

        attr(response_text, "claude_stop_reason") <- final_stop_reason %||% "unknown"
        return(response_text)

      }, error = function(e) {
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        error_msg <- e$message

        self$log_debug(sprintf("[%s] FAILED after %.2fs", call_id, elapsed), tag = "call_claude ERROR")
        self$log_debug(sprintf("[%s] Condition class: %s", call_id, paste(class(e), collapse = ", ")), tag = "call_claude ERROR")
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
          self$log_debug(sprintf("[%s] curl version: %s | ssl_version: %s", call_id, cv$version, cv$ssl_version), tag = "call_claude ERROR")
        }, error = function(e2) {
          self$log_debug(sprintf("[%s] Could not read curl::curl_version() (curl pkg not available?)", call_id), tag = "call_claude ERROR")
        })
        self$log_debug("---- end of diagnostic dump ----", tag = "call_claude ERROR")

        if (chunk_count > 0 && grepl("schannel|close_notify|peer", error_msg, ignore.case = TRUE)) {
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
            "Try: (1) Increase timeout in Claude API Config, (2) narrow the request scope, or (3) try again later. ",
            "[call_id: ", call_id, " - see R console for full diagnostic dump]"
          )
        } else if (grepl("schannel|close_notify", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "TLS connection closed abruptly after ", round(elapsed, 1), "s (schannel/close_notify), before any ",
            "data was received. This points to a firewall, antivirus HTTPS inspection, VPN, or proxy blocking ",
            "the connection outright - it is usually NOT a real loss of internet access. ",
            "Try: (1) Run Network Diagnostics in Claude API Config, (2) temporarily disable VPN/antivirus ",
            "HTTPS scanning, (3) try a different network. [call_id: ", call_id, " - see R console for full diagnostic dump]"
          )
        } else if (grepl("peer|SSL|connection", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0("Network connection error (elapsed ", round(elapsed, 1), "s): ", error_msg,
                              ". Please check your connection and try again. [call_id: ", call_id, " - see R console for full diagnostic dump]")
        } else if (grepl("curl", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0("HTTP request error (elapsed ", round(elapsed, 1), "s): ", error_msg,
                              ". Please check your internet connection and try again. [call_id: ", call_id, " - see R console for full diagnostic dump]")
        } else {
          error_msg <- paste0(error_msg, " [call_id: ", call_id, " - see R console for full diagnostic dump]")
        }

        stop(error_msg)
      })
    },

    # ============================================================
    # BIGQUERY: SHARED AUTHENTICATION, PER-APP TABLES
    # ============================================================

    # No table_id param anymore - there are three FIXED table names
    # (bq_table_flex/bq_table_mindmap/bq_table_kg), only project/dataset
    # are user-configurable now that one connection serves all three apps.
    set_bigquery_credentials = function(project_id, dataset_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      private$recompute_full_table_ids()
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

        # ---- Create ALL THREE tables (one per sub-app) if missing ----
        flex_create <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(), source STRING,
            category STRING, topic STRING, table_title STRING,
            row_dimension_label STRING, column_dimension_label STRING,
            row_index STRING, columns_data STRING, notes STRING
          )", self$bq_full_table_flex)

        mindmap_create <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(), source STRING,
            change_type STRING, category STRING, domain STRING, topic STRING,
            map_id STRING, map_title STRING, node_id STRING, node_label STRING,
            node_content STRING, parent_node_id STRING, cross_links STRING, sort_order INTEGER
          )", self$bq_full_table_mindmap)

        kg_create <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(), source STRING,
            change_type STRING, row_kind STRING, category STRING, domain STRING, topic STRING,
            graph_id STRING, graph_title STRING, entity_id STRING, entity_label STRING,
            entity_type STRING, entity_description STRING, relationship_id STRING,
            source_entity_id STRING, predicate STRING, target_entity_id STRING,
            relationship_description STRING, sort_order INTEGER
          )", self$bq_full_table_kg)

        for (q in list(flex_create, mindmap_create, kg_create)) {
          tryCatch({ bq_project_query(self$bq_project_id, q) }, error = function(e) {})
        }

        self$bq_authenticated <- TRUE
        self$trigger_state_update_flex()
        self$trigger_state_update_mindmap()
        self$trigger_state_update_kg()
        return(TRUE)

      }, error = function(e) {
        self$bq_authenticated <- FALSE
        stop(paste("BigQuery authentication failed:", e$message))
      })
    },

    # Generic query runner - table-agnostic. Times every call and logs
    # duration + a truncated preview of the query text, so slowness can
    # be diagnosed from hard evidence (which specific query, how long)
    # instead of guessing.
    bq_query = function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      start_time <- Sys.time()
      query_preview <- if (nchar(query) > 100) paste0(substr(query, 1, 100), "...") else query
      query_preview <- gsub("\\s+", " ", query_preview)

      result <- tryCatch({
        job <- bq_project_query(self$bq_project_id, query)
        bq_table_download(job)
      }, error = function(e) {
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        self$log_debug(sprintf("FAILED after %.2fs | %s | error: %s", elapsed, query_preview, e$message),
                       tag = "bq_query")
        stop(e)
      })

      elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      self$log_debug(sprintf("%.2fs | %d row(s) | %s", elapsed, nrow(result), query_preview), tag = "bq_query")

      result
    },

    # ============================================================
    # FLEX TABLE - BigQuery methods
    # ============================================================
    bq_get_flex_taxonomy = function() {
      if (!self$bq_authenticated) return(self$empty_flex_taxonomy())
      if (!is.null(self$flex_taxonomy_cache)) return(self$flex_taxonomy_cache)

      query <- sprintf(
        "SELECT DISTINCT category, topic, table_title, row_dimension_label, column_dimension_label
         FROM `%s` ORDER BY category, topic", self$bq_full_table_flex
      )
      result <- tryCatch(self$bq_query(query), error = function(e) {
        cat("⚠️  [bq_get_flex_taxonomy] Query failed:", e$message, "\n")
        self$empty_flex_taxonomy()
      })
      self$flex_taxonomy_cache <- result
      result
    },

    bq_insert_flex = function(data_frame, table_name = NULL, source = "claude") {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_flex)
      start_id <- tryCatch({
        result <- bq_project_query(self$bq_project_id, max_id_query)
        as.integer(bq_table_download(result)$max_id) + 1
      }, error = function(e) { 1 })

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1)
      data_frame$created_at <- Sys.time()
      if (!"source" %in% names(data_frame)) data_frame$source <- source

      required_cols <- c("id", "created_at", "source", "category", "topic", "table_title",
                         "row_dimension_label", "column_dimension_label",
                         "row_index", "columns_data", "notes")
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, table_name %||% self$bq_table_flex)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")
      return(nrow(data_frame))
    },

    # ============================================================
    # MIND MAP - BigQuery methods
    # ============================================================
    bq_get_mindmap_taxonomy = function() {
      if (!self$bq_authenticated) return(self$empty_mindmap_taxonomy())
      if (!is.null(self$mindmap_taxonomy_cache)) return(self$mindmap_taxonomy_cache)

      query <- sprintf(
        "SELECT DISTINCT category, domain, topic, map_id, map_title
         FROM `%s` ORDER BY category, domain, topic, map_id", self$bq_full_table_mindmap
      )
      result <- tryCatch(self$bq_query(query), error = function(e) {
        cat("⚠️  [bq_get_mindmap_taxonomy] Query failed:", e$message, "\n")
        self$empty_mindmap_taxonomy()
      })
      self$mindmap_taxonomy_cache <- result
      result
    },

    bq_get_map_ids_for_topic = function(category, domain, topic) {
      if (!self$bq_authenticated) return(character(0))
      safe_category <- gsub("'", "''", category); safe_domain <- gsub("'", "''", domain); safe_topic <- gsub("'", "''", topic)
      query <- sprintf(
        "SELECT map_id, MAX(created_at) as last_touched, ANY_VALUE(map_title) as map_title
         FROM `%s` WHERE category = '%s' AND domain = '%s' AND topic = '%s'
         GROUP BY map_id ORDER BY last_touched DESC",
        self$bq_full_table_mindmap, safe_category, safe_domain, safe_topic
      )
      tryCatch(self$bq_query(query), error = function(e) {
        cat("⚠️  [bq_get_map_ids_for_topic] Query failed:", e$message, "\n")
        data.frame(map_id = character(), last_touched = character(), map_title = character())
      })
    },

    get_current_tree_state = function(map_id) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      safe_map_id <- gsub("'", "''", map_id)
      query <- sprintf("SELECT * FROM `%s` WHERE map_id = '%s' ORDER BY id", self$bq_full_table_mindmap, safe_map_id)
      all_versions <- self$bq_query(query)

      if (nrow(all_versions) == 0) {
        return(list(category = "", domain = "", topic = "", map_title = "",
                    nodes = data.frame(node_id = character(), node_label = character(),
                                       node_content = character(), parent_node_id = character(),
                                       cross_links = character(), sort_order = integer(), stringsAsFactors = FALSE)))
      }

      latest_idx <- tapply(seq_len(nrow(all_versions)), all_versions$node_id, function(idx) idx[which.max(all_versions$id[idx])])
      latest <- all_versions[unlist(latest_idx), ]
      current <- latest[latest$change_type != "delete", ]
      current <- current[order(current$sort_order, current$node_id), ]

      list(category = all_versions$category[1], domain = all_versions$domain[1],
           topic = all_versions$topic[1], map_title = all_versions$map_title[1],
           nodes = current[, c("node_id", "node_label", "node_content", "parent_node_id", "cross_links", "sort_order")])
    },

    bq_insert_mindmap = function(data_frame, source = "claude") {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_mindmap)
      start_id <- tryCatch({
        result <- bq_project_query(self$bq_project_id, max_id_query)
        as.integer(bq_table_download(result)$max_id) + 1
      }, error = function(e) { 1 })

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1)
      data_frame$created_at <- Sys.time()
      if (!"source" %in% names(data_frame)) data_frame$source <- source

      required_cols <- c("id", "created_at", "source", "change_type", "category", "domain",
                         "topic", "map_id", "map_title", "node_id", "node_label",
                         "node_content", "parent_node_id", "cross_links", "sort_order")
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- if (col == "sort_order") 0L else ""
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_mindmap)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")
      return(nrow(data_frame))
    },

    # ============================================================
    # KNOWLEDGE GRAPH - BigQuery methods
    # ============================================================
    bq_get_kg_taxonomy = function() {
      if (!self$bq_authenticated) return(self$empty_kg_taxonomy())
      if (!is.null(self$kg_taxonomy_cache)) return(self$kg_taxonomy_cache)

      query <- sprintf(
        "SELECT DISTINCT category, domain, topic, graph_id, graph_title
         FROM `%s` ORDER BY category, domain, topic, graph_id", self$bq_full_table_kg
      )
      result <- tryCatch(self$bq_query(query), error = function(e) {
        cat("⚠️  [bq_get_kg_taxonomy] Query failed:", e$message, "\n")
        self$empty_kg_taxonomy()
      })
      self$kg_taxonomy_cache <- result
      result
    },

    bq_get_graph_ids_for_topic = function(category, domain, topic) {
      if (!self$bq_authenticated) return(character(0))
      safe_category <- gsub("'", "''", category); safe_domain <- gsub("'", "''", domain); safe_topic <- gsub("'", "''", topic)
      query <- sprintf(
        "SELECT graph_id, MAX(created_at) as last_touched, ANY_VALUE(graph_title) as graph_title
         FROM `%s` WHERE category = '%s' AND domain = '%s' AND topic = '%s'
         GROUP BY graph_id ORDER BY last_touched DESC",
        self$bq_full_table_kg, safe_category, safe_domain, safe_topic
      )
      tryCatch(self$bq_query(query), error = function(e) {
        cat("⚠️  [bq_get_graph_ids_for_topic] Query failed:", e$message, "\n")
        data.frame(graph_id = character(), last_touched = character(), graph_title = character())
      })
    },

    get_current_graph_state = function(graph_id) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      safe_graph_id <- gsub("'", "''", graph_id)
      query <- sprintf("SELECT * FROM `%s` WHERE graph_id = '%s' ORDER BY id", self$bq_full_table_kg, safe_graph_id)
      all_versions <- self$bq_query(query)

      empty_entities <- data.frame(entity_id = character(), entity_label = character(),
                                   entity_type = character(), entity_description = character(),
                                   sort_order = integer(), stringsAsFactors = FALSE)
      empty_relationships <- data.frame(relationship_id = character(), source_entity_id = character(),
                                        predicate = character(), target_entity_id = character(),
                                        relationship_description = character(), sort_order = integer(),
                                        stringsAsFactors = FALSE)

      if (nrow(all_versions) == 0) {
        return(list(category = "", domain = "", topic = "", graph_title = "",
                    entities = empty_entities, relationships = empty_relationships))
      }

      entity_versions <- all_versions[all_versions$row_kind == "entity", ]
      relationship_versions <- all_versions[all_versions$row_kind == "relationship", ]

      current_entities <- empty_entities
      if (nrow(entity_versions) > 0) {
        latest_idx <- tapply(seq_len(nrow(entity_versions)), entity_versions$entity_id, function(idx) idx[which.max(entity_versions$id[idx])])
        latest <- entity_versions[unlist(latest_idx), ]
        latest <- latest[latest$change_type != "delete", ]
        if (nrow(latest) > 0) {
          latest <- latest[order(latest$sort_order, latest$entity_id), ]
          current_entities <- latest[, c("entity_id", "entity_label", "entity_type", "entity_description", "sort_order")]
        }
      }

      current_relationships <- empty_relationships
      if (nrow(relationship_versions) > 0) {
        latest_idx <- tapply(seq_len(nrow(relationship_versions)), relationship_versions$relationship_id, function(idx) idx[which.max(relationship_versions$id[idx])])
        latest <- relationship_versions[unlist(latest_idx), ]
        latest <- latest[latest$change_type != "delete", ]
        if (nrow(latest) > 0) {
          latest <- latest[order(latest$sort_order, latest$relationship_id), ]
          current_relationships <- latest[, c("relationship_id", "source_entity_id", "predicate",
                                              "target_entity_id", "relationship_description", "sort_order")]
        }
      }

      list(category = all_versions$category[1], domain = all_versions$domain[1],
           topic = all_versions$topic[1], graph_title = all_versions$graph_title[1],
           entities = current_entities, relationships = current_relationships)
    },

    bq_insert_kg = function(data_frame, source = "claude") {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_kg)
      start_id <- tryCatch({
        result <- bq_project_query(self$bq_project_id, max_id_query)
        as.integer(bq_table_download(result)$max_id) + 1
      }, error = function(e) { 1 })

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1)
      data_frame$created_at <- Sys.time()
      if (!"source" %in% names(data_frame)) data_frame$source <- source

      required_cols <- c("id", "created_at", "source", "change_type", "row_kind",
                         "category", "domain", "topic", "graph_id", "graph_title",
                         "entity_id", "entity_label", "entity_type", "entity_description",
                         "relationship_id", "source_entity_id", "predicate", "target_entity_id",
                         "relationship_description", "sort_order")
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- if (col == "sort_order") 0L else ""
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_kg)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")
      return(nrow(data_frame))
    }
  ),

  private = list(
    recompute_full_table_ids = function() {
      self$bq_full_table_flex <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_flex)
      self$bq_full_table_mindmap <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_mindmap)
      self$bq_full_table_kg <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_kg)
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
