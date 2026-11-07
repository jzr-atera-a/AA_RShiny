# R/utils_api.R  -  Maternal Health Intelligence App APIManager
# Shared Claude API + BigQuery (tables: maternal_screening_log)
# API config subtabs are the SAME as the business_suite originals.

library(R6)
library(httr)
library(curl)
library(jsonlite)
library(bigrquery)

APIManager <- R6::R6Class(
  "APIManager",

  public = list(
    # ── Claude ───────────────────────────────────────────────
    claude_api_key        = NULL,
    claude_model          = "claude-sonnet-4-6",
    claude_max_tokens     = 8000,
    claude_timeout        = 180,
    claude_authenticated  = FALSE,

    # ── BigQuery shared ──────────────────────────────────────
    bq_project_id    = "atera-2",
    bq_dataset_id    = "business_strategy",
    bq_authenticated = FALSE,
    bq_temp_file     = NULL,

    # ── Maternal Health table ──────────────────────────────────────
    bq_table_driver        = "maternal_screening_log",
    bq_full_table_driver   = NULL,
    state_trigger_driver   = NULL,
    driver_taxonomy_cache  = NULL,

    # ── Stubs so bigquery_auth server doesn't error ──────────
    # (it references these fields generically)
    bq_table_schedule      = "maternal_screening_log",
    bq_table_events        = "maternal_screening_log",
    bq_table_funding       = "maternal_screening_log",
    bq_full_table_schedule = NULL,
    bq_full_table_events   = NULL,
    bq_full_table_funding  = NULL,
    state_trigger_schedule = NULL,
    state_trigger_events   = NULL,
    state_trigger_funding  = NULL,
    events_schema_warning  = NULL,
    schedule_taxonomy_cache = NULL,
    events_taxonomy_cache   = NULL,
    funding_taxonomy_cache  = NULL,
    pending_bulk_text_schedule = NULL,
    pending_bulk_text_events   = NULL,
    pending_bulk_text_funding  = NULL,

    initialize = function() {
      self$state_trigger_driver   <- shiny::reactiveVal(0)
      self$state_trigger_schedule <- shiny::reactiveVal(0)
      self$state_trigger_events   <- shiny::reactiveVal(0)
      self$state_trigger_funding  <- shiny::reactiveVal(0)
      self$pending_bulk_text_schedule <- shiny::reactiveVal("")
      self$pending_bulk_text_events   <- shiny::reactiveVal("")
      self$pending_bulk_text_funding  <- shiny::reactiveVal("")
      self$recompute_full_table_ids()
      cat("API Manager initialised (Maternal Health Intelligence App)\n")
    },

    recompute_full_table_ids = function() {
      base <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".")
      self$bq_full_table_driver   <- paste0(base, self$bq_table_driver)
      self$bq_full_table_schedule <- self$bq_full_table_driver
      self$bq_full_table_events   <- self$bq_full_table_driver
      self$bq_full_table_funding  <- self$bq_full_table_driver
    },

    trigger_state_update_driver = function() {
      self$state_trigger_driver(self$state_trigger_driver() + 1)
      self$driver_taxonomy_cache <- NULL
      cat("[DriveSafe] state trigger fired\n")
    },

    # Stubs so bigquery_auth server's calls don't error
    trigger_state_update_schedule = function() {
      self$state_trigger_schedule(self$state_trigger_schedule() + 1)
    },
    trigger_state_update_events = function() {
      self$state_trigger_events(self$state_trigger_events() + 1)
    },
    trigger_state_update_funding = function() {
      self$state_trigger_funding(self$state_trigger_funding() + 1)
    },

    set_pending_bulk_text_schedule = function(t) self$pending_bulk_text_schedule(t),
    set_pending_bulk_text_events   = function(t) self$pending_bulk_text_events(t),
    set_pending_bulk_text_funding  = function(t) self$pending_bulk_text_funding(t),

    log_debug = function(msg, tag = "APIManager") {
      cat(sprintf("[%s] %s\n", tag, msg))
    },

    # ── Claude ───────────────────────────────────────────────
    set_claude_credentials = function(api_key, model = NULL,
                                      max_tokens = NULL, timeout = NULL) {
      self$claude_api_key <- api_key
      if (!is.null(model))      self$claude_model      <- model
      if (!is.null(max_tokens)) self$claude_max_tokens <- max_tokens
      if (!is.null(timeout))    self$claude_timeout    <- timeout
    },

    test_claude_connection = function() {
      if (is.null(self$claude_api_key)) stop("Claude API key not set")
      tryCatch({
        r <- POST(
          url = "https://api.anthropic.com/v1/messages",
          add_headers(
            "x-api-key"          = self$claude_api_key,
            "anthropic-version"  = "2023-06-01",
            "content-type"       = "application/json"
          ),
          body = toJSON(list(
            model      = self$claude_model,
            max_tokens = 100,
            messages   = list(list(role = "user", content = "Hello, test."))
          ), auto_unbox = TRUE),
          encode = "json",
          config = httr::config(timeout = 60)
        )
        if (status_code(r) == 200) {
          self$claude_authenticated <- TRUE
          return(TRUE)
        }
        ec  <- tryCatch(content(r, "parsed", encoding = "UTF-8"),
                        error = function(e) content(r, "text", encoding = "UTF-8"))
        msg <- if (is.list(ec) && !is.null(ec$error$message)) ec$error$message
                else if (is.character(ec)) ec else "(no detail)"
        stop(sprintf("HTTP %d - %s", status_code(r), msg))
      }, error = function(e) {
        self$claude_authenticated <- FALSE
        stop(paste("Connection failed:", e$message))
      })
    },

    diagnose_network = function() {
      lines   <- c()
      log_line <- function(m) { lines <<- c(lines, m) }
      log_line("Starting network diagnostics...")
      cv <- tryCatch(curl::curl_version(), error = function(e) NULL)
      if (!is.null(cv)) log_line(sprintf("curl %s | ssl %s", cv$version, cv$ssl_version %||% "?"))
      t0 <- Sys.time()
      res <- tryCatch({
        r <- httr::GET("https://api.anthropic.com", httr::timeout(15))
        list(ok = TRUE, status = status_code(r),
             elapsed = as.numeric(difftime(Sys.time(), t0, units = "secs")))
      }, error = function(e) list(ok = FALSE, error = e$message,
                                  elapsed = as.numeric(difftime(Sys.time(), t0, units = "secs"))))
      if (res$ok) log_line(sprintf("api.anthropic.com reachable: HTTP %d (%.2fs)", res$status, res$elapsed))
      else        log_line(sprintf("api.anthropic.com FAILED after %.2fs: %s", res$elapsed, res$error))
      log_line("Diagnostics complete.")
      lines
    },

    call_claude = function(prompt, max_tokens = NULL,
                           progress_callback = NULL, enable_web_search = FALSE) {
      if (!self$claude_authenticated)
        stop("Not authenticated to Claude API. Please save credentials first.")
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0)
        stop("Claude API key is empty.")

      tokens    <- max_tokens %||% self$claude_max_tokens
      call_id   <- paste(sample(c(letters, LETTERS, 0:9), 8, replace = TRUE), collapse = "")
      start_t   <- Sys.time()

      if (!is.null(progress_callback)) progress_callback("Connecting to Claude API...")

      body_list <- list(
        model      = self$claude_model,
        max_tokens = tokens,
        stream     = TRUE,
        messages   = list(list(role = "user", content = prompt))
      )
      if (isTRUE(enable_web_search))
        body_list$tools <- list(list(type = "web_search_20250305", name = "web_search"))

      body_json <- toJSON(body_list, auto_unbox = TRUE)

      h <- curl::new_handle()
      curl::handle_setopt(h, post = TRUE, postfields = body_json, timeout = self$claude_timeout)
      curl::handle_setheaders(h,
        "x-api-key"         = self$claude_api_key,
        "anthropic-version" = "2023-06-01",
        "content-type"      = "application/json"
      )

      accumulated_text <- character(0)
      sse_buffer       <- ""
      raw_buffer       <- ""
      last_log_t       <- start_t
      chunk_count      <- 0L
      byte_count       <- 0L
      stream_err       <- NULL
      final_stop       <- NULL

      parse_sse <- function(block) {
        dls <- grep("^data: ", strsplit(block, "\n")[[1]], value = TRUE)
        for (dl in dls) {
          js <- sub("^data: ", "", dl)
          if (trimws(js) %in% c("[DONE]", "")) next
          p <- tryCatch(jsonlite::fromJSON(js, simplifyVector = FALSE), error = function(e) NULL)
          if (is.null(p) || is.null(p$type)) next
          if (p$type == "content_block_delta" &&
              identical(p$delta$type, "text_delta"))
            accumulated_text[[length(accumulated_text) + 1]] <<- p$delta$text %||% ""
          else if (p$type == "message_delta" && !is.null(p$delta$stop_reason))
            final_stop <<- p$delta$stop_reason
          else if (p$type == "error")
            stream_err <<- p$error$message %||% "Unknown streaming error"
        }
      }

      process_chunk <- function(raw_bytes) {
        chunk_count <<- chunk_count + 1L
        byte_count  <<- byte_count  + length(raw_bytes)
        piece       <- tryCatch(rawToChar(raw_bytes), error = function(e) "")
        sse_buffer  <<- paste0(sse_buffer, piece)
        raw_buffer  <<- paste0(raw_buffer, piece)
        now <- Sys.time()
        if (as.numeric(difftime(now, last_log_t, units = "secs")) >= 5) {
          if (!is.null(progress_callback))
            progress_callback(sprintf("Streaming... %d chars", sum(nchar(accumulated_text))))
          last_log_t <<- now
        }
        while (grepl("\n\n", sse_buffer, fixed = TRUE)) {
          sp  <- regexpr("\n\n", sse_buffer, fixed = TRUE)
          evt <- substr(sse_buffer, 1, sp - 1)
          sse_buffer <<- substr(sse_buffer, sp + 2, nchar(sse_buffer))
          parse_sse(evt)
        }
      }

      tryCatch({
        curl::curl_fetch_stream(url = "https://api.anthropic.com/v1/messages",
                                fun = process_chunk, handle = h)
        if (nchar(trimws(sse_buffer)) > 0) parse_sse(sse_buffer)

        meta   <- tryCatch(curl::handle_data(h), error = function(e) NULL)
        status <- if (!is.null(meta)) meta$status_code else NA_integer_

        if (!is.na(status) && status != 200) {
          ec  <- tryCatch(jsonlite::fromJSON(raw_buffer, simplifyVector = FALSE),
                          error = function(e) raw_buffer)
          msg <- if (is.list(ec) && !is.null(ec$error)) paste0("API Error (", status, "): ", ec$error$message)
                 else paste0("API Error: HTTP ", status)
          if (status == 401) msg <- "Authentication failed: Invalid API key."
          else if (status == 429) msg <- "Rate limit exceeded."
          else if (status == 500) msg <- "Claude API server error."
          stop(msg)
        }
        if (!is.null(stream_err)) stop(paste("Streaming error:", stream_err))

        txt <- paste(accumulated_text, collapse = "")
        if (nchar(txt) == 0) stop("Claude returned an empty response.")
        if (!is.null(progress_callback)) progress_callback("Complete!")
        list(text = txt, stop_reason = final_stop %||% "unknown",
             truncated = identical(final_stop, "max_tokens"))

      }, error = function(e) {
        elapsed <- as.numeric(difftime(Sys.time(), start_t, units = "secs"))
        msg <- e$message
        if (chunk_count > 0 && grepl("schannel|close_notify|peer", msg, ignore.case = TRUE))
          msg <- paste0("Connection dropped mid-stream after ", round(elapsed, 1), "s. ",
                        "Try a different network or disable VPN HTTPS inspection.")
        else if (grepl("Timeout", msg, ignore.case = TRUE))
          msg <- paste0("Timeout after ", self$claude_timeout, "s. Increase timeout or narrow the request.")
        stop(paste0(msg, " [call_id: ", call_id, "]"))
      })
    },

    # ── BigQuery ─────────────────────────────────────────────
    set_bigquery_credentials = function(project_id, dataset_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      self$recompute_full_table_ids()
    },

    authenticate_bigquery = function(json_path = NULL, json_text = NULL) {
      tryCatch({
        tryCatch(bq_deauth(), error = function(e) {})
        Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
        Sys.unsetenv("GCE_METADATA_HOST")

        if (!is.null(json_path)) {
          jc <- fromJSON(json_path)
          required <- c("type", "project_id", "private_key", "client_email")
          miss     <- setdiff(required, names(jc))
          if (length(miss) > 0) stop("Missing JSON fields: ", paste(miss, collapse = ", "))
          bq_auth(path = json_path, cache = FALSE)
        } else if (!is.null(json_text)) {
          jc <- fromJSON(json_text)
          required <- c("type", "project_id", "private_key", "client_email")
          miss     <- setdiff(required, names(jc))
          if (length(miss) > 0) stop("Missing JSON fields: ", paste(miss, collapse = ", "))
          tf <- tempfile(fileext = ".json")
          writeLines(json_text, tf)
          self$bq_temp_file <- tf
          bq_auth(path = tf, cache = FALSE)
        } else {
          stop("Provide JSON file path or text")
        }

        bq_project_datasets(self$bq_project_id)

        # Create maternal_screening_log if it doesn't exist
        tryCatch({
          bq_project_query(self$bq_project_id, sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              driver_id STRING, driver_name STRING,
              osa_group STRING, cpap_treated STRING,
              journey_id STRING, journey_date STRING,
              journey_hour FLOAT64, journey_duration_h FLOAT64,
              kss_score FLOAT64, reaction_time_ms INTEGER,
              mind_wander_idx FLOAT64, osa_risk_score FLOAT64,
              sleep_quality FLOAT64, speed_variance FLOAT64,
              hard_braking_n INTEGER, lane_events_n INTEGER,
              pvt_lapses_n INTEGER, recorded_at STRING
            )", self$bq_full_table_driver))
          cat("BigQuery: maternal_screening_log table ready\n")
        }, error = function(e) {
          cat("BigQuery: maternal_screening_log CREATE check failed:", e$message, "\n")
        })

        self$events_schema_warning <- NULL
        self$bq_authenticated <- TRUE
        self$trigger_state_update_driver()
        self$trigger_state_update_schedule()
        self$trigger_state_update_events()
        self$trigger_state_update_funding()
        return(TRUE)

      }, error = function(e) {
        self$bq_authenticated <- FALSE
        stop(paste("BigQuery authentication failed:", e$message))
      })
    },

    # Stub - bigquery_auth server calls this on successful connect
    check_events_table_compatibility = function() NULL,

    bq_query = function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      job <- bq_project_query(self$bq_project_id, query)
      bq_table_download(job)
    },

    # ── Driver health log CRUD ───────────────────────────────
    bq_get_driver_taxonomy = function() {
      if (!is.null(self$driver_taxonomy_cache)) return(self$driver_taxonomy_cache)
      if (!self$bq_authenticated)
        return(data.frame(driver_id = character(), osa_group = character(),
                          stringsAsFactors = FALSE))
      result <- tryCatch({
        self$bq_query(sprintf(
          "SELECT DISTINCT driver_id, driver_name, osa_group
           FROM `%s` ORDER BY driver_id",
          self$bq_full_table_driver
        ))
      }, error = function(e) {
        cat("bq_get_driver_taxonomy failed:", e$message, "\n")
        data.frame(driver_id = character(), osa_group = character(),
                   stringsAsFactors = FALSE)
      })
      self$driver_taxonomy_cache <- result
      result
    },

    bq_insert_driver_log = function(data_frame) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "driver_id", "driver_name",
                         "osa_group", "cpap_treated", "journey_id",
                         "journey_date", "journey_hour", "journey_duration_h",
                         "kss_score", "reaction_time_ms", "mind_wander_idx",
                         "osa_risk_score", "sleep_quality", "speed_variance",
                         "hard_braking_n", "lane_events_n", "pvt_lapses_n",
                         "recorded_at")

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id, sprintf(
          "SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`",
          self$bq_full_table_driver)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id         <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      data_frame$cpap_treated <- as.character(data_frame$cpap_treated)

      for (col in required_cols)
        if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_driver)
      bq_table_upload(table_ref, data_frame,
                      create_disposition = "CREATE_IF_NEEDED",
                      write_disposition  = "WRITE_APPEND")

      cat("BigQuery: inserted", nrow(data_frame), "rows ->", self$bq_full_table_driver, "\n")
      self$trigger_state_update_driver()
      return(nrow(data_frame))
    },

    # Taxonomy stubs called by bigquery_auth server
    bq_get_schedule_taxonomy = function() data.frame(stringsAsFactors = FALSE),
    bq_get_events_taxonomy   = function() data.frame(stringsAsFactors = FALSE),
    bq_get_funding_taxonomy  = function() data.frame(stringsAsFactors = FALSE)
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
