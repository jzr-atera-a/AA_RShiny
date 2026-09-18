# R/utils_api.R
# APIManager R6 Class - UNIFIED across Book Summary, Flex Table, Mind
# Map, and Knowledge Graph suites.
# =================================================================
# One shared Claude API connection and one shared BigQuery
# authentication (same project/dataset), but each sub-app has its OWN
# table and its OWN schema - so every BigQuery-specific method below
# is named per sub-app (bq_insert_books / bq_insert_flex /
# bq_insert_mindmap / bq_insert_kg, etc) rather than sharing a single
# generic name, since the four original apps' methods of the same name
# (bq_insert, bq_get_taxonomy, empty_taxonomy) had DIFFERENT required
# columns and DIFFERENT target tables - merging them under one name
# would only be able to support one sub-app correctly. Same for
# pending_bulk_text (Generate -> Bulk Import handoff): Book Summary and
# Flex Table BOTH have their own independent Generate->Bulk Import
# flow, so this is also scoped per-suite (pending_bulk_text_books /
# pending_bulk_text_flex) to avoid one suite's generated content
# leaking into the other's Bulk Import box.
#
# Everything Claude-API-related (call_claude, streaming, diagnostics,
# logging) was byte-for-byte identical across all four source apps
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

    # ---- BigQuery credentials (shared project/dataset, 4 tables) ----
    bq_project_id = "atera-2",
    bq_dataset_id = "Wonderfulp_March",
    bq_table_books = "book_summaries_test3",
    bq_table_flex = "flex_comparison_tables",
    bq_table_mindmap = "mindmap_nodes",
    bq_table_kg = "knowledge_graph",
    bq_table_sankey = "sankey_graphs",
    bq_table_diagram = "strategy_diagrams",
    bq_table_sixsigma = "six_sigma_diagrams",
    bq_full_table_books = NULL,
    bq_full_table_flex = NULL,
    bq_full_table_mindmap = NULL,
    bq_full_table_kg = NULL,
    bq_full_table_sankey = NULL,
    bq_full_table_diagram = NULL,
    bq_full_table_sixsigma = NULL,
    bq_authenticated = FALSE,
    bq_temp_file = NULL,

    # ⭐ Reactive triggers for cross-module updates - deliberately SCOPED
    # PER SUB-APP (not one shared trigger), so an upload/edit in one
    # suite doesn't cause another suite's taxonomy/table reactives to
    # needlessly re-fire and re-query BigQuery. Each sub-app's modules
    # only ever listen to (and fire) their own trigger.
    state_trigger_books = NULL,
    state_trigger_flex = NULL,
    state_trigger_mindmap = NULL,
    state_trigger_kg = NULL,
    state_trigger_sankey = NULL,
    state_trigger_diagram = NULL,
    state_trigger_sixsigma = NULL,

    # ⭐ PERFORMANCE: taxonomy result cache, one per sub-app. Because
    # shinydashboard doesn't lazy-load hidden tabs, EVERY module across
    # all four suites is reactively alive simultaneously regardless of
    # which tab is visible - so a single trigger fire (e.g. right after
    # connecting to BigQuery) can wake up several independent reactive
    # blocks that all want the SAME taxonomy data at once (e.g. Table
    # Viewer AND Generate Table both want Flex Table's Category/Topic
    # list). Without this cache, each of those fires its own BigQuery
    # query even though the data is identical - with it, only the
    # FIRST caller per trigger increment actually queries BigQuery; the
    # rest reuse the cached result instantly. Set to NULL to force a
    # fresh fetch (done automatically whenever the matching trigger fires).
    books_taxonomy_cache = NULL,
    flex_taxonomy_cache = NULL,
    mindmap_taxonomy_cache = NULL,
    kg_taxonomy_cache = NULL,
    # Small per-(category,domain,topic) caches for the "which map/graph IDs
    # exist under this exact topic" follow-on lookups, separate from the
    # taxonomy caches above - without this, two independent reactive
    # contexts asking for the same topic (e.g. Knowledge Graph's D3 and
    # Cytoscape visualize tabs, both alive simultaneously) each hit
    # BigQuery separately for an identical result. Cleared alongside the
    # matching taxonomy cache whenever that suite's trigger fires.
    mindmap_ids_for_topic_cache = NULL,
    kg_ids_for_topic_cache = NULL,
    sankey_taxonomy_cache = NULL,
    diagram_taxonomy_cache = NULL,
    sixsigma_taxonomy_cache = NULL,

    # Generate -> Bulk Import handoff, SCOPED PER SUITE. Book Summary
    # and Flex Table each have their own independent "Generate then
    # copy to Bulk Import" flow - sharing one field would let one
    # suite's generated content leak into the other's Bulk Import box.
    pending_bulk_text_books = NULL,
    pending_bulk_text_flex = NULL,
    pending_bulk_text_sankey = NULL,
    pending_bulk_text_diagram = NULL,
    pending_bulk_text_sixsigma = NULL,

    # Tool Recommender -> Generate Diagram handoff (Strategic Analysis
    # only). Clicking a recommended framework's name stores its
    # diagram_type id here; Generate Diagram's server watches this and
    # auto-selects the matching Diagram Group + Framework dropdowns, same
    # "store it, watch it, switch tabs" handoff shape as the pending_bulk_
    # text_* fields above, just carrying a single id instead of a block
    # of text.
    pending_diagram_selection = NULL,

    # Tool Recommender -> Generate Six Sigma Diagram handoff (Six Sigma
    # Analysis only). Same shape as pending_diagram_selection above.
    pending_sixsigma_selection = NULL,

    initialize = function() {
      self$state_trigger_books <- shiny::reactiveVal(0)
      self$state_trigger_flex <- shiny::reactiveVal(0)
      self$state_trigger_mindmap <- shiny::reactiveVal(0)
      self$state_trigger_kg <- shiny::reactiveVal(0)
      self$state_trigger_sankey <- shiny::reactiveVal(0)
      self$state_trigger_diagram <- shiny::reactiveVal(0)
      self$state_trigger_sixsigma <- shiny::reactiveVal(0)
      self$pending_bulk_text_books <- shiny::reactiveVal("")
      self$pending_bulk_text_flex <- shiny::reactiveVal("")
      self$pending_bulk_text_sankey <- shiny::reactiveVal("")
      self$pending_bulk_text_diagram <- shiny::reactiveVal("")
      self$pending_bulk_text_sixsigma <- shiny::reactiveVal("")
      self$pending_diagram_selection <- shiny::reactiveVal(NULL)
      self$pending_sixsigma_selection <- shiny::reactiveVal(NULL)
      private$recompute_full_table_ids()
      cat("🔌 API Manager initialized (Book Summary + Flex Table + Mind Map + Knowledge Graph + Sankey Graph + Strategic Analysis + Six Sigma Analysis)\n")
    },

    trigger_state_update_books = function() {
      current <- self$state_trigger_books()
      self$state_trigger_books(current + 1)
      self$books_taxonomy_cache <- NULL
      cat("🔔 [Book Summary] State trigger fired:", current + 1, "\n")
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
      self$mindmap_ids_for_topic_cache <- NULL
      cat("🔔 [Mind Map] State trigger fired:", current + 1, "\n")
    },
    trigger_state_update_kg = function() {
      current <- self$state_trigger_kg()
      self$state_trigger_kg(current + 1)
      self$kg_taxonomy_cache <- NULL
      self$kg_ids_for_topic_cache <- NULL
      cat("🔔 [Knowledge Graph] State trigger fired:", current + 1, "\n")
    },
    trigger_state_update_sankey = function() {
      current <- self$state_trigger_sankey()
      self$state_trigger_sankey(current + 1)
      self$sankey_taxonomy_cache <- NULL
      cat("🔔 [Sankey Graph] State trigger fired:", current + 1, "\n")
    },
    trigger_state_update_diagram = function() {
      current <- self$state_trigger_diagram()
      self$state_trigger_diagram(current + 1)
      self$diagram_taxonomy_cache <- NULL
      cat("🔔 [Strategic Analysis] State trigger fired:", current + 1, "\n")
    },
    trigger_state_update_sixsigma = function() {
      current <- self$state_trigger_sixsigma()
      self$state_trigger_sixsigma(current + 1)
      self$sixsigma_taxonomy_cache <- NULL
      cat("🔔 [Six Sigma Analysis] State trigger fired:", current + 1, "\n")
    },

    set_pending_bulk_text_books = function(text) {
      self$pending_bulk_text_books(text)
    },
    set_pending_bulk_text_flex = function(text) {
      self$pending_bulk_text_flex(text)
    },
    set_pending_bulk_text_sankey = function(text) {
      self$pending_bulk_text_sankey(text)
    },
    set_pending_bulk_text_diagram = function(text) {
      self$pending_bulk_text_diagram(text)
    },
    set_pending_bulk_text_sixsigma = function(text) {
      self$pending_bulk_text_sixsigma(text)
    },
    set_pending_diagram_selection = function(diagram_type) {
      self$pending_diagram_selection(diagram_type)
    },
    set_pending_sixsigma_selection = function(diagram_type) {
      self$pending_sixsigma_selection(diagram_type)
    },

    log_debug = function(msg, tag = "APIManager") {
      cat(sprintf("[%s] [%s] %s\n", format(Sys.time(), "%H:%M:%OS3"), tag, msg))
    },

    empty_books_taxonomy = function() {
      data.frame(genre = character(), topic = character(),
                 book_name = character(), author = character(), stringsAsFactors = FALSE)
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
    empty_sankey_taxonomy = function() {
      data.frame(sankey_id = character(), title = character(),
                 category = character(), domain = character(), topic = character(),
                 num_columns = integer(), num_initial_rows = integer(),
                 is_template = logical(), created_at = character(), stringsAsFactors = FALSE)
    },
    empty_diagram_taxonomy = function() {
      data.frame(diagram_id = character(), diagram_name = character(), diagram_type = character(),
                 diagram_group = character(),
                 category = character(), domain = character(), topic = character(), title = character(),
                 is_template = logical(), created_at = character(), stringsAsFactors = FALSE)
    },
    empty_sixsigma_taxonomy = function() {
      data.frame(diagram_id = character(), diagram_name = character(), diagram_type = character(),
                 diagram_group = character(),
                 category = character(), domain = character(), topic = character(), title = character(),
                 is_template = logical(), created_at = character(), stringsAsFactors = FALSE)
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
          # NOTE: deliberately NOT firing any trigger_state_update_*() calls
          # here. Those triggers exist to tell each suite's Generate/
          # Visualize dropdowns "BigQuery data may have changed, requery" -
          # Claude authenticating successfully has no bearing on that
          # whatsoever, and firing all 7 of them here used to cause a
          # second, completely redundant multi-minute BigQuery requery
          # cascade across every suite every time someone connected Claude
          # AFTER already connecting BigQuery (the common order), on top of
          # the one authenticate_bigquery() already correctly triggers.
          # Whether Claude itself is ready to generate is checked directly
          # via api_manager$claude_authenticated inside each Generate tab's
          # own button handler - it was never gated behind these triggers.
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

        # ---- Create ALL FOUR tables (one per sub-app) if missing ----
        books_create <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            book_name STRING, author STRING, genre STRING, topic STRING,
            chapter STRING, section STRING, main_details STRING,
            formula STRING, formula_explanation STRING,
            reference_url STRING, reference_description STRING,
            numeric_data STRING, numeric_data_description STRING
          )", self$bq_full_table_books)

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

        # ---- Sankey Graph: sankey_graphs. One row = either a NODE (a
        #     labeled box at a specific left-right column) or a LINK (a
        #     weighted flow between two nodes, source_ref -> target_ref,
        #     any two columns as long as target's column > source's column -
        #     skip-ahead links are explicitly allowed, matching how real
        #     Sankeys work, e.g. an energy source flowing straight to
        #     "Losses" while bypassing intermediate conversion stages).
        #     row_kind distinguishes the two ("node"/"link"), exactly the
        #     same denormalization pattern Knowledge Graph uses for
        #     entity/relationship rows. num_columns/num_initial_rows are
        #     the slider values used to generate this specific sankey_id,
        #     repeated on every row for that id (no separate lookup table
        #     needed - matches the KG/Strategic Analysis convention of one
        #     flat, self-describing table per suite).
        #     Node sizing/vertical position is NEVER computed by Claude or
        #     R - the d3-sankey layout algorithm derives every node's
        #     height and every link's curve width directly from the raw
        #     value_numeric figures at render time, the same "let the
        #     library do the real math" principle used throughout this app.
        sankey_create <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            sankey_id STRING, title STRING, category STRING, domain STRING, topic STRING,
            is_template BOOL, source_sankey_id STRING,
            num_columns INTEGER, num_initial_rows INTEGER,
            row_kind STRING,
            component_ref STRING, column_index INTEGER, sequence_order INTEGER,
            label_text STRING, sub_text STRING, items_packed STRING,
            source_ref STRING, target_ref STRING, value_numeric FLOAT64, unit_label STRING,
            color_hint STRING, created_by STRING
          )", self$bq_full_table_sankey)

        # ---- Strategic Analysis: strategy_diagrams. One row = one visual
        #     component (a grid cell, a quadrant, an axis, a chart series),
        #     denormalized (diagram_name/diagram_type/category/domain/topic
        #     repeated on every row belonging to the same diagram_id) so a
        #     whole diagram is one WHERE diagram_id = ... query, no joins.
        #     Classification mirrors Mind Map/Knowledge Graph's 3-level
        #     Category -> Domain -> Topic hierarchy exactly (same shared
        #     category_domain_topic_dropdown_ui()/setup_category_domain_topic_cascade()
        #     helpers): category = broad life domain (Business, Personal
        #     Life, Health, ...), domain = the analysis/framework family
        #     (Situational Analysis, Decision-Making Process, ...), topic =
        #     the specific subject. List-like content (bullets, series
        #     points) is packed into items_packed using DIAG_ITEM_SEP rather
        #     than exploded into one row per item - see R/utils_common.R.
        #     Append-only, same pattern as every other suite in this app. --
        diagram_create <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            diagram_id STRING, diagram_name STRING, diagram_type STRING, diagram_group STRING,
            category STRING, domain STRING, topic STRING, title STRING, is_template BOOL,
            source_diagram_id STRING,
            component_type STRING, layout_role STRING,
            grid_row INTEGER, grid_col INTEGER, quadrant_position STRING,
            sequence_order INTEGER, z_index INTEGER,
            pos_x FLOAT64, pos_y FLOAT64, width FLOAT64, height FLOAT64,
            label_text STRING, sub_text STRING, items_packed STRING,
            value_numeric FLOAT64, value_axis STRING, series_name STRING, unit_label STRING,
            axis_type STRING, axis_min FLOAT64, axis_max FLOAT64, metric_name STRING,
            color_hint STRING, icon_name STRING,
            created_by STRING
          )", self$bq_full_table_diagram)

        # Schema evolution safety net: if strategy_diagrams already existed
        # from before the `domain`/`diagram_group` columns were introduced,
        # ADD COLUMN IF NOT EXISTS brings it up to date without touching any
        # existing rows (they simply get NULL for the new columns, same
        # non-destructive philosophy as every CREATE TABLE IF NOT EXISTS in
        # this app). diagram_group holds the strategy-framework family
        # (Situational Analysis / Competitive Positioning / etc.) - added
        # alongside the expanded ~27-framework catalog in R/utils_common.R,
        # exactly mirroring how six_sigma_diagrams already uses diagram_group
        # for its DMAIC phases.
        diagram_alter_add_domain <- sprintf(
          "ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS domain STRING",
          self$bq_full_table_diagram
        )
        diagram_alter_add_group <- sprintf(
          "ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS diagram_group STRING",
          self$bq_full_table_diagram
        )

        # ---- Six Sigma Analysis: six_sigma_diagrams. Same denormalized,
        #     one-row-per-visual-component design as strategy_diagrams,
        #     plus fields specific to Six Sigma tools that generic columns
        #     don't cover well:
        #       - diagram_group: the DMAIC phase this tool belongs to
        #         (Define/Measure/Analyse/Improve/Control) - a coarser
        #         grouping ABOVE diagram_type, since Six Sigma has many
        #         more distinct diagram types than Strategic Analysis and
        #         benefits from an extra filtering level.
        #       - severity/occurrence/detection: FMEA's three 1-10 scores.
        #         RPN (their product) is DELIBERATELY NOT stored - it is
        #         always computed at render time from these three columns
        #         (see render_sixsigma_html() in R/utils_common.R), so it
        #         can never drift out of sync with edited inputs and is
        #         never trusted as arithmetic Claude did itself.
        #       - component_ref/parent_ref: lightweight local identifiers
        #         (e.g. "N1", "C1", "C2") used ONLY by tree-shaped diagrams
        #         (ctq_tree) to record parent-child edges for the renderer
        #         to draw connecting lines - analogous in spirit to
        #         Knowledge Graph's entity_id/source_entity_id, but scoped
        #         to a single diagram_id rather than a whole graph table.
        #     Classification again mirrors Mind Map/Knowledge Graph/
        #     Strategic Analysis's Category -> Domain -> Topic hierarchy.
        #     Append-only, same pattern as every other suite in this app. -
        sixsigma_create <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            diagram_id STRING, diagram_name STRING, diagram_type STRING, diagram_group STRING,
            category STRING, domain STRING, topic STRING, title STRING, is_template BOOL,
            source_diagram_id STRING,
            component_type STRING, layout_role STRING,
            grid_row INTEGER, grid_col INTEGER, quadrant_position STRING,
            sequence_order INTEGER, z_index INTEGER,
            pos_x FLOAT64, pos_y FLOAT64, width FLOAT64, height FLOAT64,
            label_text STRING, sub_text STRING, items_packed STRING,
            value_numeric FLOAT64, value_axis STRING, series_name STRING, unit_label STRING,
            axis_type STRING, axis_min FLOAT64, axis_max FLOAT64, metric_name STRING,
            severity INTEGER, occurrence INTEGER, detection INTEGER,
            component_ref STRING, parent_ref STRING,
            color_hint STRING, icon_name STRING,
            created_by STRING
          )", self$bq_full_table_sixsigma)

        for (q in list(books_create, flex_create, mindmap_create, kg_create, sankey_create, diagram_create, diagram_alter_add_domain, diagram_alter_add_group, sixsigma_create)) {
          tryCatch({ bq_project_query(self$bq_project_id, q) }, error = function(e) {})
        }

        self$bq_authenticated <- TRUE
        self$trigger_state_update_books()
        self$trigger_state_update_flex()
        self$trigger_state_update_mindmap()
        self$trigger_state_update_kg()
        self$trigger_state_update_sankey()
        self$trigger_state_update_diagram()
        self$trigger_state_update_sixsigma()
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
    # BOOK SUMMARY - BigQuery methods
    # ============================================================
    bq_get_books_taxonomy = function() {
      if (!self$bq_authenticated) return(self$empty_books_taxonomy())
      if (!is.null(self$books_taxonomy_cache)) return(self$books_taxonomy_cache)

      query <- sprintf(
        "SELECT DISTINCT genre, topic, book_name, author FROM `%s` ORDER BY genre, topic, book_name",
        self$bq_full_table_books
      )
      result <- tryCatch(self$bq_query(query), error = function(e) {
        cat("⚠️  [bq_get_books_taxonomy] Query failed:", e$message, "\n")
        self$empty_books_taxonomy()
      })
      self$books_taxonomy_cache <- result
      result
    },

    bq_insert_books = function(data_frame, table_name = NULL) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_books)
      start_id <- tryCatch({
        result <- bq_project_query(self$bq_project_id, max_id_query)
        as.integer(bq_table_download(result)$max_id) + 1
      }, error = function(e) { 1 })

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1)
      data_frame$created_at <- Sys.time()

      required_cols <- c("id", "created_at", "book_name", "author", "genre", "topic",
                         "chapter", "section", "main_details",
                         "formula", "formula_explanation",
                         "reference_url", "reference_description",
                         "numeric_data", "numeric_data_description")
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, table_name %||% self$bq_table_books)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")
      return(nrow(data_frame))
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

      cache_key <- paste(category, domain, topic, sep = "|||")
      if (!is.null(self$mindmap_ids_for_topic_cache[[cache_key]])) {
        return(self$mindmap_ids_for_topic_cache[[cache_key]])
      }

      safe_category <- gsub("'", "''", category); safe_domain <- gsub("'", "''", domain); safe_topic <- gsub("'", "''", topic)
      query <- sprintf(
        "SELECT map_id, MAX(created_at) as last_touched, ANY_VALUE(map_title) as map_title
         FROM `%s` WHERE category = '%s' AND domain = '%s' AND topic = '%s'
         GROUP BY map_id ORDER BY last_touched DESC",
        self$bq_full_table_mindmap, safe_category, safe_domain, safe_topic
      )
      result <- tryCatch(self$bq_query(query), error = function(e) {
        cat("⚠️  [bq_get_map_ids_for_topic] Query failed:", e$message, "\n")
        data.frame(map_id = character(), last_touched = character(), map_title = character())
      })

      if (is.null(self$mindmap_ids_for_topic_cache)) self$mindmap_ids_for_topic_cache <- list()
      self$mindmap_ids_for_topic_cache[[cache_key]] <- result
      result
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

      cache_key <- paste(category, domain, topic, sep = "|||")
      if (!is.null(self$kg_ids_for_topic_cache[[cache_key]])) {
        return(self$kg_ids_for_topic_cache[[cache_key]])
      }

      safe_category <- gsub("'", "''", category); safe_domain <- gsub("'", "''", domain); safe_topic <- gsub("'", "''", topic)
      query <- sprintf(
        "SELECT graph_id, MAX(created_at) as last_touched, ANY_VALUE(graph_title) as graph_title
         FROM `%s` WHERE category = '%s' AND domain = '%s' AND topic = '%s'
         GROUP BY graph_id ORDER BY last_touched DESC",
        self$bq_full_table_kg, safe_category, safe_domain, safe_topic
      )
      result <- tryCatch(self$bq_query(query), error = function(e) {
        cat("⚠️  [bq_get_graph_ids_for_topic] Query failed:", e$message, "\n")
        data.frame(graph_id = character(), last_touched = character(), graph_title = character())
      })

      if (is.null(self$kg_ids_for_topic_cache)) self$kg_ids_for_topic_cache <- list()
      self$kg_ids_for_topic_cache[[cache_key]] <- result
      result
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
    },

    # ============================================================
    # STRATEGIC ANALYSIS (AI-generated strategy diagrams)
    # ============================================================
    bq_get_diagram_taxonomy = function() {
      if (!is.null(self$diagram_taxonomy_cache)) return(self$diagram_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_diagram_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf("
          SELECT diagram_id, ANY_VALUE(diagram_name) AS diagram_name,
                 ANY_VALUE(diagram_type) AS diagram_type, ANY_VALUE(diagram_group) AS diagram_group,
                 ANY_VALUE(category) AS category,
                 ANY_VALUE(domain) AS domain, ANY_VALUE(topic) AS topic, ANY_VALUE(title) AS title,
                 ANY_VALUE(is_template) AS is_template, MIN(created_at) AS created_at
          FROM `%s`
          GROUP BY diagram_id
          ORDER BY topic, diagram_name, created_at DESC
        ", self$bq_full_table_diagram))
      }, error = function(e) {
        cat("⚠️  [bq_get_diagram_taxonomy] Query failed:", e$message, "\n")
        self$empty_diagram_taxonomy()
      })

      self$diagram_taxonomy_cache <- result
      result
    },

    # Every component row for one diagram_id, in render order - the single
    # query the Visualizations tab needs to draw a diagram.
    bq_get_diagram_components = function(diagram_id) {
      if (!self$bq_authenticated) return(data.frame())
      cat(sprintf("🔎 [Strategic Analysis][DEBUG] Pulling components for diagram_id=%s from %s\n",
                  diagram_id, self$bq_full_table_diagram))

      result <- tryCatch({
        self$bq_query(sprintf("
          SELECT * FROM `%s`
          WHERE diagram_id = '%s'
          ORDER BY grid_row, grid_col, sequence_order, z_index
        ", self$bq_full_table_diagram, safe_sql_escape(diagram_id)))
      }, error = function(e) {
        cat("⚠️  [bq_get_diagram_components] Query failed:", e$message, "\n")
        data.frame()
      })

      cat(sprintf(
        "🔎 [Strategic Analysis][DEBUG] Pulled %d component row(s) | diagram_type=%s | component_types=%s\n",
        nrow(result),
        if (nrow(result) > 0) result$diagram_type[1] else "NA",
        if (nrow(result) > 0) paste(unique(result$component_type), collapse = ", ") else "NA"
      ))

      result
    },

    bq_insert_diagram = function(data_frame) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "diagram_id", "diagram_name", "diagram_type", "diagram_group",
                        "category", "domain", "topic", "title", "is_template", "source_diagram_id",
                        "component_type", "layout_role",
                        "grid_row", "grid_col", "quadrant_position", "sequence_order", "z_index",
                        "pos_x", "pos_y", "width", "height",
                        "label_text", "sub_text", "items_packed",
                        "value_numeric", "value_axis", "series_name", "unit_label",
                        "axis_type", "axis_min", "axis_max", "metric_name",
                        "color_hint", "icon_name", "created_by")

      max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_diagram)
      start_id <- tryCatch({
        result <- bq_project_query(self$bq_project_id, max_id_query)
        as.integer(bq_table_download(result)$max_id) + 1
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- NA
      data_frame <- data_frame[, required_cols]

      # ---- DEBUG: full detail on exactly what is about to be written,
      #     printed to the console every time a new diagram is persisted ---
      cat("========================================================\n")
      cat(sprintf("🧩 [Strategic Analysis][DEBUG] Inserting diagram components -> %s\n", self$bq_full_table_diagram))
      cat(sprintf("    diagram_id      : %s\n", data_frame$diagram_id[1]))
      cat(sprintf("    diagram_name    : %s\n", data_frame$diagram_name[1]))
      cat(sprintf("    diagram_type    : %s (framework group: %s)\n", data_frame$diagram_type[1], data_frame$diagram_group[1]))
      cat(sprintf("    category/domain/topic  : %s / %s / %s\n", data_frame$category[1], data_frame$domain[1], data_frame$topic[1]))
      cat(sprintf("    is_template     : %s\n", data_frame$is_template[1]))
      cat(sprintf("    row count       : %d\n", nrow(data_frame)))
      cat(sprintf("    component_types : %s\n", paste(unique(data_frame$component_type), collapse = ", ")))
      cat(sprintf("    id range        : %d - %d\n", min(data_frame$id), max(data_frame$id)))
      cat("========================================================\n")

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_diagram)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) ->", self$bq_full_table_diagram, "\n")
      self$trigger_state_update_diagram()
      return(nrow(data_frame))
    },

    # ============================================================
    # SIX SIGMA ANALYSIS (AI-generated Six Sigma diagrams)
    # ============================================================
    bq_get_sixsigma_taxonomy = function() {
      if (!is.null(self$sixsigma_taxonomy_cache)) return(self$sixsigma_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_sixsigma_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf("
          SELECT diagram_id, ANY_VALUE(diagram_name) AS diagram_name,
                 ANY_VALUE(diagram_type) AS diagram_type, ANY_VALUE(diagram_group) AS diagram_group,
                 ANY_VALUE(category) AS category, ANY_VALUE(domain) AS domain,
                 ANY_VALUE(topic) AS topic, ANY_VALUE(title) AS title,
                 ANY_VALUE(is_template) AS is_template, MIN(created_at) AS created_at
          FROM `%s`
          GROUP BY diagram_id
          ORDER BY topic, diagram_name, created_at DESC
        ", self$bq_full_table_sixsigma))
      }, error = function(e) {
        cat("⚠️  [bq_get_sixsigma_taxonomy] Query failed:", e$message, "\n")
        self$empty_sixsigma_taxonomy()
      })

      self$sixsigma_taxonomy_cache <- result
      result
    },

    # Every component row for one diagram_id, in render order - the single
    # query the Visualizations tab needs to draw a Six Sigma diagram.
    bq_get_sixsigma_components = function(diagram_id) {
      if (!self$bq_authenticated) return(data.frame())
      cat(sprintf("🔎 [Six Sigma Analysis][DEBUG] Pulling components for diagram_id=%s from %s\n",
                  diagram_id, self$bq_full_table_sixsigma))

      result <- tryCatch({
        self$bq_query(sprintf("
          SELECT * FROM `%s`
          WHERE diagram_id = '%s'
          ORDER BY grid_row, grid_col, sequence_order, z_index
        ", self$bq_full_table_sixsigma, safe_sql_escape(diagram_id)))
      }, error = function(e) {
        cat("⚠️  [bq_get_sixsigma_components] Query failed:", e$message, "\n")
        data.frame()
      })

      cat(sprintf(
        "🔎 [Six Sigma Analysis][DEBUG] Pulled %d component row(s) | diagram_type=%s | component_types=%s\n",
        nrow(result),
        if (nrow(result) > 0) result$diagram_type[1] else "NA",
        if (nrow(result) > 0) paste(unique(result$component_type), collapse = ", ") else "NA"
      ))

      result
    },

    bq_insert_sixsigma = function(data_frame) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "diagram_id", "diagram_name", "diagram_type", "diagram_group",
                        "category", "domain", "topic", "title", "is_template", "source_diagram_id",
                        "component_type", "layout_role",
                        "grid_row", "grid_col", "quadrant_position", "sequence_order", "z_index",
                        "pos_x", "pos_y", "width", "height",
                        "label_text", "sub_text", "items_packed",
                        "value_numeric", "value_axis", "series_name", "unit_label",
                        "axis_type", "axis_min", "axis_max", "metric_name",
                        "severity", "occurrence", "detection",
                        "component_ref", "parent_ref",
                        "color_hint", "icon_name", "created_by")

      max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_sixsigma)
      start_id <- tryCatch({
        result <- bq_project_query(self$bq_project_id, max_id_query)
        as.integer(bq_table_download(result)$max_id) + 1
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- NA
      data_frame <- data_frame[, required_cols]

      # ---- DEBUG: full detail on exactly what is about to be written,
      #     printed to the console every time a new diagram is persisted ---
      cat("========================================================\n")
      cat(sprintf("🧩 [Six Sigma Analysis][DEBUG] Inserting diagram components -> %s\n", self$bq_full_table_sixsigma))
      cat(sprintf("    diagram_id      : %s\n", data_frame$diagram_id[1]))
      cat(sprintf("    diagram_name    : %s\n", data_frame$diagram_name[1]))
      cat(sprintf("    diagram_type    : %s (group: %s)\n", data_frame$diagram_type[1], data_frame$diagram_group[1]))
      cat(sprintf("    category/domain/topic  : %s / %s / %s\n", data_frame$category[1], data_frame$domain[1], data_frame$topic[1]))
      cat(sprintf("    is_template     : %s\n", data_frame$is_template[1]))
      cat(sprintf("    row count       : %d\n", nrow(data_frame)))
      cat(sprintf("    component_types : %s\n", paste(unique(data_frame$component_type), collapse = ", ")))
      if (any(!is.na(data_frame$severity))) {
        cat(sprintf("    FMEA rows with S/O/D set : %d (RPN computed at render time, never stored)\n", sum(!is.na(data_frame$severity))))
      }
      cat(sprintf("    id range        : %d - %d\n", min(data_frame$id), max(data_frame$id)))
      cat("========================================================\n")

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_sixsigma)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) ->", self$bq_full_table_sixsigma, "\n")
      self$trigger_state_update_sixsigma()
      return(nrow(data_frame))
    },

    # ============================================================
    # SANKEY GRAPH (AI-generated Sankey flow diagrams)
    # ============================================================
    bq_get_sankey_taxonomy = function() {
      if (!is.null(self$sankey_taxonomy_cache)) return(self$sankey_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_sankey_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf("
          SELECT sankey_id, ANY_VALUE(title) AS title,
                 ANY_VALUE(category) AS category, ANY_VALUE(domain) AS domain, ANY_VALUE(topic) AS topic,
                 ANY_VALUE(num_columns) AS num_columns, ANY_VALUE(num_initial_rows) AS num_initial_rows,
                 ANY_VALUE(is_template) AS is_template, MIN(created_at) AS created_at
          FROM `%s`
          GROUP BY sankey_id
          ORDER BY topic, title, created_at DESC
        ", self$bq_full_table_sankey))
      }, error = function(e) {
        cat("⚠️  [bq_get_sankey_taxonomy] Query failed:", e$message, "\n")
        self$empty_sankey_taxonomy()
      })

      self$sankey_taxonomy_cache <- result
      result
    },

    # Every node/link row for one sankey_id, in a sensible render order -
    # the single query the Visualizations tab needs to draw a Sankey.
    bq_get_sankey_components = function(sankey_id) {
      if (!self$bq_authenticated) return(data.frame())
      cat(sprintf("🔎 [Sankey Graph][DEBUG] Pulling components for sankey_id=%s from %s\n",
                  sankey_id, self$bq_full_table_sankey))

      result <- tryCatch({
        self$bq_query(sprintf("
          SELECT * FROM `%s`
          WHERE sankey_id = '%s'
          ORDER BY row_kind DESC, column_index, sequence_order
        ", self$bq_full_table_sankey, safe_sql_escape(sankey_id)))
      }, error = function(e) {
        cat("⚠️  [bq_get_sankey_components] Query failed:", e$message, "\n")
        data.frame()
      })

      cat(sprintf(
        "🔎 [Sankey Graph][DEBUG] Pulled %d row(s) | nodes=%d | links=%d\n",
        nrow(result),
        if (nrow(result) > 0) sum(result$row_kind == "node") else 0,
        if (nrow(result) > 0) sum(result$row_kind == "link") else 0
      ))

      result
    },

    bq_insert_sankey = function(data_frame) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "sankey_id", "title", "category", "domain", "topic",
                        "is_template", "source_sankey_id", "num_columns", "num_initial_rows",
                        "row_kind", "component_ref", "column_index", "sequence_order",
                        "label_text", "sub_text", "items_packed",
                        "source_ref", "target_ref", "value_numeric", "unit_label",
                        "color_hint", "created_by")

      max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_sankey)
      start_id <- tryCatch({
        result <- bq_project_query(self$bq_project_id, max_id_query)
        as.integer(bq_table_download(result)$max_id) + 1
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- NA
      data_frame <- data_frame[, required_cols]

      # ---- DEBUG: full detail on exactly what is about to be written ----
      node_rows <- sum(data_frame$row_kind == "node")
      link_rows <- sum(data_frame$row_kind == "link")
      cat("========================================================\n")
      cat(sprintf("🧩 [Sankey Graph][DEBUG] Inserting sankey rows -> %s\n", self$bq_full_table_sankey))
      cat(sprintf("    sankey_id       : %s\n", data_frame$sankey_id[1]))
      cat(sprintf("    title           : %s\n", data_frame$title[1]))
      cat(sprintf("    category/domain/topic  : %s / %s / %s\n", data_frame$category[1], data_frame$domain[1], data_frame$topic[1]))
      cat(sprintf("    num_columns / num_initial_rows : %s / %s\n", data_frame$num_columns[1], data_frame$num_initial_rows[1]))
      cat(sprintf("    node rows       : %d\n", node_rows))
      cat(sprintf("    link rows       : %d\n", link_rows))
      if (link_rows > 0) {
        total_flow <- sum(data_frame$value_numeric[data_frame$row_kind == "link"], na.rm = TRUE)
        cat(sprintf("    total flow value across all links : %.2f (informational only - not validated for conservation)\n", total_flow))
      }
      cat(sprintf("    id range        : %d - %d\n", min(data_frame$id), max(data_frame$id)))
      cat("========================================================\n")

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_sankey)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) ->", self$bq_full_table_sankey, "\n")
      self$trigger_state_update_sankey()
      return(nrow(data_frame))
    }
  ),

  private = list(
    recompute_full_table_ids = function() {
      self$bq_full_table_books <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_books)
      self$bq_full_table_flex <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_flex)
      self$bq_full_table_mindmap <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_mindmap)
      self$bq_full_table_kg <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_kg)
      self$bq_full_table_sankey <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_sankey)
      self$bq_full_table_diagram <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_diagram)
      self$bq_full_table_sixsigma <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_sixsigma)
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
