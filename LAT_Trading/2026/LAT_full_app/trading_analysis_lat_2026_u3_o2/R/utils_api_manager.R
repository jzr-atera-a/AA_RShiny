# R/api_manager.R
# APIManager R6 Class — Trading Analysis App
# Corrected to follow proven events-app pattern
# ==========================================

library(R6)
library(httr)
library(jsonlite)
library(bigrquery)

APIManager <- R6::R6Class(
  "APIManager",

  public = list(
    # Claude API
    claude_api_key       = NULL,
    claude_model         = "claude-sonnet-4-6",
    claude_max_tokens    = 4000,
    claude_timeout       = 60,
    claude_authenticated = FALSE,

    # BigQuery
    bq_project_id    = "atera-2",
    bq_dataset_id    = "trading_signals",
    bq_table_id      = "economic_calendar",
    bq_full_table_id = NULL,
    bq_authenticated = FALSE,
    bq_temp_file     = NULL,

    # Economic calendar cache
    last_parsed_df = NULL,

    initialize = function() {
      self$bq_full_table_id  <- paste0(self$bq_project_id, ".",
                                        self$bq_dataset_id, ".",
                                        self$bq_table_id)
      self$last_parsed_df    <- data.frame()
    },

    # ============================================================
    # CLAUDE API
    # ============================================================
    set_claude_credentials = function(api_key, model = NULL, max_tokens = NULL, timeout = NULL) {
      self$claude_api_key  <- api_key
      if (!is.null(model))      self$claude_model      <- model
      if (!is.null(max_tokens)) self$claude_max_tokens <- max_tokens
      if (!is.null(timeout))    self$claude_timeout    <- timeout
      cat("🤖 [Claude] Credentials saved — model:", self$claude_model, "\n")
    },

    test_claude_connection = function() {
      if (is.null(self$claude_api_key)) stop("Claude API key not set")
      tryCatch({
        response <- POST(
          url = "https://api.anthropic.com/v1/messages",
          add_headers(
            "x-api-key"         = self$claude_api_key,
            "anthropic-version" = "2023-06-01",
            "content-type"      = "application/json"
          ),
          body = toJSON(list(
            model      = self$claude_model,
            max_tokens = 10,
            messages   = list(list(role = "user", content = "Hi"))
          ), auto_unbox = TRUE),
          encode = "json",
          config = httr::config(timeout = 30)
        )
        if (status_code(response) == 200) {
          self$claude_authenticated <- TRUE
          cat("✅ [Claude] Connected OK\n")
          return(TRUE)
        }
        ec     <- tryCatch(content(response, "parsed", encoding = "UTF-8"),
                           error = function(e) content(response, "text", encoding = "UTF-8"))
        detail <- if (is.list(ec) && !is.null(ec$error$message)) ec$error$message else "(no detail)"
        stop(sprintf("HTTP %d: %s", status_code(response), detail))
      }, error = function(e) {
        self$claude_authenticated <- FALSE
        cat("❌ [Claude] Connection failed:", e$message, "\n")
        stop(paste("Connection failed:", e$message))
      })
    },

    # call_claude with web_search enabled for real event discovery
    call_claude = function(prompt, max_tokens = NULL, progress_callback = NULL) {
      if (!self$claude_authenticated) stop("Not authenticated to Claude API.")
      tokens  <- max_tokens %||% self$claude_max_tokens
      t_start <- proc.time()[["elapsed"]]

      cat("🤖 [Claude] Calling (web search enabled) —", tokens, "max tokens\n")
      if (!is.null(progress_callback)) progress_callback("Searching for economic events...")

      tryCatch({
        response <- POST(
          url = "https://api.anthropic.com/v1/messages",
          add_headers(
            "x-api-key"         = self$claude_api_key,
            "anthropic-version" = "2023-06-01",
            "content-type"      = "application/json"
          ),
          body = toJSON(list(
            model      = self$claude_model,
            max_tokens = tokens,
            tools      = list(
              list(
                type = "web_search_20250305",
                name = "web_search"
              )
            ),
            messages   = list(list(role = "user", content = prompt))
          ), auto_unbox = TRUE),
          encode  = "json",
          timeout(self$claude_timeout)
        )

        elapsed <- round(proc.time()[["elapsed"]] - t_start, 1)

        if (status_code(response) != 200) {
          ec  <- tryCatch(content(response, "parsed", encoding = "UTF-8"),
                          error = function(e) content(response, "text", encoding = "UTF-8"))
          msg <- if (is.list(ec) && !is.null(ec$error))
            paste0("API Error (", status_code(response), "): ", ec$error$message)
          else paste0("API Error: HTTP ", status_code(response))
          if (status_code(response) == 401) msg <- "Authentication failed — invalid API key."
          if (status_code(response) == 429) msg <- "Rate limit exceeded — wait and retry."
          cat("❌ [Claude] Error:", msg, "\n")
          stop(msg)
        }

        if (!is.null(progress_callback)) progress_callback("Parsing response...")

        result <- content(response, "parsed", encoding = "UTF-8")
        if (is.null(result$content) || length(result$content) == 0)
          stop("Empty response from Claude.")

        # Extract text blocks only (ignore tool_use / tool_result blocks)
        text_blocks <- Filter(function(b) !is.null(b$type) && b$type == "text", result$content)
        if (length(text_blocks) == 0) stop("No text in Claude response.")

        text        <- paste(sapply(text_blocks, function(b) b$text), collapse = "\n")
        stop_reason <- result$stop_reason %||% "unknown"
        truncated   <- identical(stop_reason, "max_tokens")

        cat("✅ [Claude] Done in", elapsed, "s —",
            result$usage$output_tokens, "output tokens",
            if (truncated) "⚠️ TRUNCATED" else "", "\n")

        if (!is.null(progress_callback)) progress_callback("Complete!")
        return(list(text = text, stop_reason = stop_reason, truncated = truncated))

      }, error = function(e) {
        elapsed <- round(proc.time()[["elapsed"]] - t_start, 1)
        msg <- e$message
        cat("❌ [Claude] Failed after", elapsed, "s:", msg, "\n")
        if (grepl("timeout|Timeout|Operation was aborted", msg, ignore.case = TRUE))
          msg <- paste0("Request timed out after ", self$claude_timeout, "s. Increase timeout in Claude API Config.")
        else if (grepl("peer|SSL|connection refused|Could not resolve", msg, ignore.case = TRUE))
          msg <- "Network error — check your internet connection."
        stop(msg)
      })
    },

    # ============================================================
    # BIGQUERY — FIXED PATTERN (NO AUTO-CREATE TABLE)
    # ============================================================
    set_bigquery_credentials = function(project_id, dataset_id, table_id) {
      self$bq_project_id    <- project_id
      self$bq_dataset_id    <- dataset_id
      self$bq_table_id      <- table_id
      self$bq_full_table_id <- paste0(project_id, ".", dataset_id, ".", table_id)
      cat("💾 [BigQuery] Credentials set: project=", project_id, ", dataset=", dataset_id, ", table=", table_id, "\n", sep = "")
    },

    authenticate_bigquery = function(json_path = NULL, json_text = NULL) {
      tryCatch({
        # Clear any existing auth
        tryCatch({ bq_deauth() }, error = function(e) {})
        Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
        Sys.unsetenv("GCE_METADATA_HOST")

        # Load credentials
        if (!is.null(json_path)) {
          json_content <- fromJSON(json_path)
          required     <- c("type", "project_id", "private_key", "client_email")
          missing_f    <- setdiff(required, names(json_content))
          if (length(missing_f) > 0) stop("Missing JSON fields: ", paste(missing_f, collapse = ", "))
          bigrquery::bq_auth(path = json_path)

        } else if (!is.null(json_text)) {
          json_content <- fromJSON(json_text)
          required     <- c("type", "project_id", "private_key", "client_email")
          missing_f    <- setdiff(required, names(json_content))
          if (length(missing_f) > 0) stop("Missing JSON fields: ", paste(missing_f, collapse = ", "))
          tmp <- tempfile(fileext = ".json")
          writeLines(json_text, tmp)
          self$bq_temp_file <- tmp
          bigrquery::bq_auth(path = tmp)

        } else {
          stop("Provide JSON file path or text")
        }

        # Quick connection check
        bq_project_datasets(self$bq_project_id)

        # *** KEY FIX: Check table existence, DO NOT CREATE ***
        tbl          <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_id)
        table_exists <- tryCatch(bq_table_exists(tbl), error = function(e) FALSE)

        if (table_exists) {
          cat("✅ [BigQuery] Connected —", self$bq_full_table_id, "\n")
        } else {
          cat("⚠️  [BigQuery] Connected but table NOT found:", self$bq_full_table_id, "\n")
          cat("   Please run the SQL creation script in BigQuery console first.\n")
        }

        self$bq_authenticated <- TRUE
        return(list(ok = TRUE, table_exists = table_exists))

      }, error = function(e) {
        self$bq_authenticated <- FALSE
        cat("❌ [BigQuery] Auth failed:", e$message, "\n")
        stop(paste("BigQuery authentication failed:", e$message))
      })
    },

    # Query helper — only works if authenticated
    bq_query = function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      tryCatch({
        job  <- bq_project_query(self$bq_project_id, query)
        data <- bq_table_download(job)
        data
      }, error = function(e) {
        cat("⚠️  [BigQuery] Query failed:", e$message, "\n")
        stop(e$message)
      })
    },

    # Insert data (appends to existing table; table must exist first)
    bq_insert = function(data_frame) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c(
        "event_date", "event_time", "country", "currency",
        "event_name", "importance", "forecast", "previous", "actual"
      )

      missing_cols <- setdiff(required_cols, names(data_frame))
      if (length(missing_cols) > 0) {
        warning("Missing required columns: ", paste(missing_cols, collapse = ", "))
      }

      for (col in missing_cols) data_frame[[col]] <- ""

      con <- dbConnect(
        bigrquery::bigquery(),
        project = self$bq_project_id,
        dataset = self$bq_dataset_id,
        billing = self$bq_project_id
      )

      tryCatch({
        dbWriteTable(
          conn = con,
          name = self$bq_table_id,
          value = data_frame,
          append = TRUE,
          row.names = FALSE
        )
        cat("✅ [BigQuery] Inserted", nrow(data_frame), "rows →", self$bq_full_table_id, "\n")
        self$trigger_state_update()
        return(nrow(data_frame))
      }, error = function(e) {
        cat("❌ [BigQuery] Insert failed:", e$message, "\n")
        stop(e$message)
      }, finally = {
        dbDisconnect(con)
      })
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
