# R/utils_api_manager.R
#
# ApiManager - shared credentials object, following the exact convention
# shown in the uploaded reference zips:
#   - API_Configuration_BigQ_Claude.zip: ONE bigquery_auth tab authenticates
#     ONE project+dataset+service-account for ALL suites; each suite gets its
#     own bq_table_<suite> / bq_full_table_<suite> pair. ONE claude_api_config
#     tab authenticates ONE Claude key/model for all suites.
#   - Atlassian_API.zip (gantt_api_config): calls
#     api_manager$set_trello_credentials()/test_trello_connection() and
#     set_jira_credentials()/test_jira_connection() - referenced but NOT
#     defined in that zip (only the module UI/server was included, not the
#     underlying ApiManager methods). Implemented below against the real
#     Trello and Jira Cloud REST APIs.
#
# This app has one BigQuery-backed suite so far: "economic_calendar_summary"
# (bq_table_economic_calendar / bq_full_table_economic_calendar), targeting
# atera-2.business_strategy.economic_calendar_summary — dataset "business_strategy"
# is the confirmed official dataset for this app, shared with the Business
# Operations suite (by design, not a naming collision). The TABLE, however, is
# a name of our own within that dataset, created fresh via CREATE TABLE IF NOT
# EXISTS in authenticate_bigquery() — deliberately NOT the plain "economic_calendar"
# name, since that could collide with a same-named table created by a different
# app/script with an incompatible column layout (this happened once already —
# every insert failed with an opaque "Job ... failed" error until traced back
# to a schema mismatch on a pre-existing table we didn't create). Using our own
# table name means CREATE TABLE IF NOT EXISTS actually creates it matching our
# schema on first connect, rather than silently no-op'ing against someone
# else's differently-shaped table of the same name.
# Added following the same bq_table_<suite> naming pattern the reference
# apps use for schedule/diet/exercise/events/funding/gantt_tasks/
# gantt_contacts/contacts/communications, so a future suite can be added
# here the same way.

library(bigrquery)
library(curl)

ApiManager <- R6::R6Class(
  "ApiManager",
  public = list(

    # ---- BigQuery: shared connection ------------------------------------
    bq_project_id    = "atera-2",
    bq_dataset_id    = "business_strategy",
    bq_authenticated = FALSE,
    bq_temp_file     = NULL,

    # ---- BigQuery: per-suite table names (add more here as new suites
    #      are added, same pattern as the reference apps) ------------------
    bq_table_economic_calendar      = "economic_calendar_summary",
    bq_full_table_economic_calendar = NULL,

    # ---- Claude: shared connection --------------------------------------
    claude_api_key       = NULL,
    claude_model          = "claude-sonnet-4-6",
    claude_max_tokens     = 8000,
    claude_timeout        = 120,
    claude_authenticated  = FALSE,

    # ---- Trello: shared connection ---------------------------------------
    trello_key         = NULL,
    trello_token        = NULL,
    trello_board_id     = NULL,
    trello_authenticated = FALSE,

    # ---- Jira: shared connection -----------------------------------------
    jira_url            = NULL,
    jira_email           = NULL,
    jira_token           = NULL,
    jira_project_key     = NULL,
    jira_authenticated   = FALSE,

    # ---- Economic Calendar: last generated batch (shared across
    #      Trend Summary / Export tabs) ------------------------------------
    last_query_id       = NULL,
    last_query_date     = NULL,
    last_raw_response   = NULL,
    last_parsed_df      = NULL,

    initialize = function() {
      self$recompute_full_table_ids()
    },

    recompute_full_table_ids = function() {
      self$bq_full_table_economic_calendar <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_economic_calendar)
    },

    # ============================================================
    # BIGQUERY
    # ============================================================

    set_bigquery_credentials = function(project_id, dataset_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      self$recompute_full_table_ids()
    },

    authenticate_bigquery = function(json_path = NULL, json_text = NULL) {
      cat("\n=== [BigQuery] authenticate_bigquery() START ===\n")
      cat("[BigQuery] target:", self$bq_project_id, "/", self$bq_dataset_id, "/", self$bq_table_economic_calendar, "\n")
      tryCatch({ bq_deauth() }, error = function(e) {})
      Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")

      if (!is.null(json_path)) {
        cat("[BigQuery] auth mode: file upload\n")
        json_content <- jsonlite::fromJSON(json_path)
        req <- c("type", "project_id", "private_key", "client_email")
        missing <- setdiff(req, names(json_content))
        if (length(missing) > 0) {
          cat("[BigQuery] ERROR: missing JSON fields:", paste(missing, collapse = ", "), "\n")
          stop("Missing JSON fields: ", paste(missing, collapse = ", "))
        }
        bq_auth(path = json_path, cache = FALSE)

      } else if (!is.null(json_text) && trimws(json_text) != "") {
        cat("[BigQuery] auth mode: pasted text\n")
        json_content <- jsonlite::fromJSON(json_text)
        req <- c("type", "project_id", "private_key", "client_email")
        missing <- setdiff(req, names(json_content))
        if (length(missing) > 0) {
          cat("[BigQuery] ERROR: missing JSON fields:", paste(missing, collapse = ", "), "\n")
          stop("Missing JSON fields: ", paste(missing, collapse = ", "))
        }
        temp_file <- tempfile(fileext = ".json")
        writeLines(json_text, temp_file)
        self$bq_temp_file <- temp_file
        bq_auth(path = temp_file, cache = FALSE)

      } else {
        cat("[BigQuery] ERROR: no credentials provided\n")
        stop("Provide a service-account JSON file or paste its contents")
      }

      cat("[BigQuery] Service-account auth accepted, checking project access...\n")
      # Quick connection check
      tryCatch({
        bq_project_datasets(self$bq_project_id)
        cat("[BigQuery] Project access OK\n")
      }, error = function(e) {
        cat("[BigQuery] ERROR: project access check failed:", e$message, "\n")
        stop("Could not access project '", self$bq_project_id, "': ", e$message)
      })

      # ── economic_calendar_summary: CREATE TABLE IF NOT EXISTS — safe no-op if it
      #    already exists, never alters or drops anything. Add further
      #    suites' CREATE TABLE blocks here, same pattern, as they're added.
      cat("[BigQuery] Checking/creating table", self$bq_full_table_economic_calendar, "...\n")
      tryCatch({
        bq_project_query(self$bq_project_id, sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            row_id              STRING,
            query_id             STRING,
            query_date           DATE,
            query_timestamp      TIMESTAMP,
            event_id             STRING,
            event_date           DATE,
            event_name           STRING,
            event_description    STRING,
            event_importance     STRING,
            event_role           STRING,
            linked_to_event_id   STRING,
            asset_class          STRING,
            specific_asset       STRING,
            impact_direction     STRING,
            impact_rationale     STRING,
            source               STRING,
            created_at           TIMESTAMP
          )", self$bq_full_table_economic_calendar))
        cat("\u2713 [BigQuery] economic_calendar_summary table ready\n")
      }, error = function(e) {
        cat("[BigQuery] ERROR: CREATE TABLE check failed:", e$message, "\n")
        stop("economic_calendar_summary CREATE TABLE check failed: ", e$message)
      })

      self$bq_authenticated <- TRUE
      cat("=== [BigQuery] authenticate_bigquery() END (success) ===\n")
      invisible(TRUE)
    },

    bq_query = function(query) {
      job <- bq_project_query(self$bq_project_id, query)
      bq_table_download(job)
    },

    bq_insert_economic_calendar = function(data_frame) {
      cat("\n=== [BigQuery] bq_insert_economic_calendar() START \u2014", nrow(data_frame), "row(s) received ===\n")
      if (!self$bq_authenticated) {
        cat("[BigQuery] ERROR: not authenticated\n")
        stop("Not authenticated to BigQuery")
      }

      required_cols <- c("row_id", "query_id", "query_date", "query_timestamp",
                          "event_id", "event_date", "event_name", "event_description",
                          "event_importance", "event_role", "linked_to_event_id",
                          "asset_class", "specific_asset", "impact_direction",
                          "impact_rationale", "source", "created_at")

      now <- format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")
      data_frame$created_at <- now
      missing_cols <- setdiff(required_cols, names(data_frame))
      if (length(missing_cols) > 0) cat("[BigQuery] filling missing columns with NA:", paste(missing_cols, collapse = ", "), "\n")
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- NA_character_
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_economic_calendar)

      # ── Proactive schema check ────────────────────────────────────────
      # A generic "Job ... failed" from bq_table_upload() is BigQuery's
      # normal response to a column mismatch between the data frame and an
      # ALREADY-EXISTING table (CREATE TABLE IF NOT EXISTS is a no-op if the
      # table is already there, so if it was created earlier with different
      # columns, every insert fails this way with no further detail). Check
      # the real live schema first so a mismatch is reported clearly by name
      # instead of surfacing as an opaque job failure.
      cat("[BigQuery] Checking existing table schema before upload...\n")
      existing_fields <- tryCatch(bigrquery::bq_table_fields(table_ref), error = function(e) NULL)
      if (!is.null(existing_fields)) {
        existing_names <- vapply(existing_fields, function(f) f$name, character(1))
        cat("[BigQuery] Existing table columns (", length(existing_names), "):", paste(existing_names, collapse = ", "), "\n")
        extra_in_data  <- setdiff(required_cols, existing_names)
        extra_in_table <- setdiff(existing_names, required_cols)
        if (length(extra_in_data) > 0 || length(extra_in_table) > 0) {
          cat("[BigQuery] SCHEMA MISMATCH DETECTED\n")
          if (length(extra_in_data) > 0)  cat("[BigQuery]   Columns we're sending that the table does NOT have:", paste(extra_in_data, collapse = ", "), "\n")
          if (length(extra_in_table) > 0) cat("[BigQuery]   Columns the table has that we're NOT sending:      ", paste(extra_in_table, collapse = ", "), "\n")
          cat("=== [BigQuery] bq_insert_economic_calendar() END (schema mismatch) ===\n")
          stop(
            "The table '", self$bq_full_table_economic_calendar, "' already exists with a different schema ",
            "than this app expects.\n  Table has: ", paste(existing_names, collapse = ", "),
            "\n  We tried to send: ", paste(required_cols, collapse = ", "),
            "\nThis table was likely created earlier (by a different version of this app, or manually) with a ",
            "different column layout. Either recreate the table to match this schema, or the insert logic needs ",
            "to be remapped to the table's real columns \u2014 tell me the exact column list above and I'll fix the mapping."
          )
        }
        cat("[BigQuery] Schema check OK \u2014 columns match\n")
      } else {
        cat("[BigQuery] Could not read existing schema (table may not exist yet \u2014 CREATE TABLE IF NOT EXISTS should have handled that during authenticate_bigquery())\n")
      }

      cat("[BigQuery] Uploading to", self$bq_full_table_economic_calendar, "...\n")
      tryCatch({
        bq_table_upload(table_ref, data_frame,
                         create_disposition = "CREATE_IF_NEEDED",
                         write_disposition  = "WRITE_APPEND")
      }, error = function(e) {
        cat("[BigQuery] ERROR: upload failed:", e$message, "\n")

        # Try to pull the full job error detail using the job id embedded in
        # the error message (format: project.job_XXXX.LOCATION), since
        # bq_table_upload()'s own error is often just this generic sentence
        # with the real reason only visible via the job's own status.
        job_id_match <- regmatches(e$message, regexpr("job_[A-Za-z0-9_-]+", e$message))
        if (length(job_id_match) > 0 && nchar(job_id_match) > 0) {
          cat("[BigQuery] Fetching full error detail for job", job_id_match, "...\n")
          tryCatch({
            job <- bigrquery::bq_job(project = self$bq_project_id, job = job_id_match, location = "US")
            meta <- bigrquery::bq_job_meta(job)
            err_result <- meta$status$errorResult
            all_errors <- meta$status$errors
            if (!is.null(err_result)) cat("[BigQuery] Job errorResult: reason =", err_result$reason %||% "?", "| message =", err_result$message %||% "?", "\n")
            if (!is.null(all_errors)) {
              for (er in all_errors) cat("[BigQuery] Job error detail: reason =", er$reason %||% "?", "| message =", er$message %||% "?", "\n")
            }
          }, error = function(e2) {
            cat("[BigQuery] Could not fetch job detail:", e2$message, "\n")
          })
        }
        cat("=== [BigQuery] bq_insert_economic_calendar() END (upload failed) ===\n")
        stop("BigQuery insert failed: ", e$message)
      })

      cat("\u2705 [BigQuery] Inserted", nrow(data_frame), "row(s) \u2192", self$bq_full_table_economic_calendar, "\n")
      cat("=== [BigQuery] bq_insert_economic_calendar() END (success) ===\n")
      invisible(nrow(data_frame))
    },

    bq_get_economic_calendar = function(date_from = NULL, date_to = NULL,
                                         asset_class = NULL, specific_asset = NULL) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      where <- c("1=1")
      if (!is.null(date_from)) where <- c(where, sprintf("event_date >= DATE('%s')", date_from))
      if (!is.null(date_to))   where <- c(where, sprintf("event_date <= DATE('%s')", date_to))
      if (!is.null(asset_class) && asset_class != "All")
        where <- c(where, sprintf("asset_class = '%s'", gsub("'", "\\\\'", asset_class)))
      if (!is.null(specific_asset) && specific_asset != "All")
        where <- c(where, sprintf("specific_asset = '%s'", gsub("'", "\\\\'", specific_asset)))

      q <- sprintf("SELECT * FROM `%s` WHERE %s ORDER BY event_date DESC, event_id, asset_class",
                    self$bq_full_table_economic_calendar, paste(where, collapse = " AND "))
      self$bq_query(q)
    },

    # ============================================================
    # CLAUDE
    # ============================================================

    set_claude_credentials = function(api_key, model = NULL, max_tokens = NULL, timeout = NULL) {
      self$claude_api_key <- api_key
      if (!is.null(model))      self$claude_model      <- model
      if (!is.null(max_tokens)) self$claude_max_tokens <- max_tokens
      if (!is.null(timeout))    self$claude_timeout    <- timeout
      self$claude_authenticated <- TRUE
    },

    test_claude_connection = function() {
      cat("\n=== [Claude] test_claude_connection() START ===\n")
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0) {
        cat("[Claude] ERROR: API key empty\n")
        stop("Claude API key is empty")
      }

      resp <- tryCatch({
        httr::POST(
          "https://api.anthropic.com/v1/messages",
          httr::add_headers("x-api-key" = self$claude_api_key,
                             "anthropic-version" = "2023-06-01",
                             "content-type" = "application/json"),
          body = jsonlite::toJSON(list(model = self$claude_model, max_tokens = 16,
                                        messages = list(list(role = "user", content = "Reply with OK."))),
                                   auto_unbox = TRUE),
          encode = "raw"
        )
      }, error = function(e) {
        cat("[Claude] ERROR: request failed at network layer:", e$message, "\n")
        stop("Claude connection test failed at the network layer: ", e$message)
      })
      cat("[Claude] Test response: HTTP", httr::status_code(resp), "\n")
      if (httr::status_code(resp) != 200) {
        cat("=== [Claude] test_claude_connection() END (failed) ===\n")
        stop("Claude API test failed: HTTP ", httr::status_code(resp))
      }
      cat("=== [Claude] test_claude_connection() END (success) ===\n")
      invisible(TRUE)
    },

    # Streaming Claude call (SSE via curl) - same pattern as the reference
    # app's shared call_claude(). enable_web_search = TRUE so Claude looks up
    # real, currently-scheduled/released calendar events from reputable
    # sources rather than generating dates/figures from training data.
    #
    # Why streaming at all: a request with web search enabled routinely takes
    # 60-130+ seconds (Claude runs several searches before writing the
    # answer). A plain, non-streaming POST sends zero bytes back for that
    # entire time, and corporate proxies/VPNs/antivirus HTTPS-inspection
    # commonly kill a connection that looks "idle" for ~60s even though
    # nothing is wrong (documented failure mode: "TLS connection closed
    # abruptly... schannel: server closed abruptly"). Streaming (stream=TRUE
    # + SSE) makes small pieces of text arrive continuously instead, so the
    # connection never looks idle. This does NOT mean more data is sent —
    # total bytes are the same either way — only that it arrives gradually
    # rather than in one lump at the end. The high "chunk" count you may see
    # in the console is a byproduct of that (each chunk is one raw network
    # read off the open socket, not a unit of work or a sign of inefficiency)
    # and is logged sparingly for exactly that reason.
    call_claude = function(prompt, max_tokens = NULL, progress_callback = NULL, enable_web_search = TRUE) {
      cat("\n=== [Claude] call_claude() START ===\n")
      if (!self$claude_authenticated) {
        cat("[Claude] ERROR: not authenticated\n")
        stop("Not authenticated to Claude API. Please save credentials first.")
      }
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0) {
        cat("[Claude] ERROR: API key empty\n")
        stop("Claude API key is empty.")
      }

      tokens <- max_tokens %||% self$claude_max_tokens
      cat("[Claude] model:", self$claude_model, "| max_tokens:", tokens,
          "| web_search:", isTRUE(enable_web_search), "| timeout:", self$claude_timeout, "s\n")
      if (!is.null(progress_callback)) progress_callback("Connecting to Claude API...")

      body_list <- list(
        model = self$claude_model, max_tokens = tokens, stream = TRUE,
        messages = list(list(role = "user", content = prompt))
      )
      if (isTRUE(enable_web_search)) {
        body_list$tools <- list(list(type = "web_search_20250305", name = "web_search"))
      }
      body_json <- jsonlite::toJSON(body_list, auto_unbox = TRUE)

      claude_url <- "https://api.anthropic.com/v1/messages"

      h <- curl::new_handle()
      curl::handle_setopt(h, post = TRUE, postfields = body_json, timeout = self$claude_timeout)
      curl::handle_setheaders(h,
        "x-api-key" = self$claude_api_key,
        "anthropic-version" = "2023-06-01",
        "content-type" = "application/json"
      )

      accumulated_text <- character(0)
      sse_buffer <- ""
      stream_error_msg <- NULL
      chunk_count <- 0

      parse_sse_event <- function(event_block) {
        data_lines <- grep("^data: ", strsplit(event_block, "\n")[[1]], value = TRUE)
        if (length(data_lines) == 0) return(invisible(NULL))
        for (dl in data_lines) {
          json_str <- sub("^data: ", "", dl)
          if (trimws(json_str) %in% c("[DONE]", "")) next
          parsed <- tryCatch(jsonlite::fromJSON(json_str, simplifyVector = FALSE), error = function(e) NULL)
          if (is.null(parsed) || is.null(parsed$type)) next
          if (parsed$type == "content_block_delta" &&
              !is.null(parsed$delta) && identical(parsed$delta$type, "text_delta")) {
            accumulated_text[[length(accumulated_text) + 1]] <<- parsed$delta$text %||% ""
          }
          if (parsed$type == "error") {
            stream_error_msg <<- parsed$error$message %||% "Unknown stream error"
            cat("[Claude] STREAM ERROR EVENT:", stream_error_msg, "\n")
          }
        }
      }

      cat("[Claude] Sending request to", claude_url, "...\n")
      t_start <- proc.time()[["elapsed"]]

      # BUGFIX: curl_fetch_stream()'s first argument must be the URL as a
      # STRING (signature: curl_fetch_stream(url, fun, handle)). The previous
      # version passed curl::handle_setopt(h, url = ...) here instead, which
      # sets the URL on the handle and returns the HANDLE OBJECT — not a
      # string — as that first argument. That mismatch is exactly what threw
      # "Argument 'url' must be string." on every Generate click. Fixed by
      # passing the URL string directly and the handle (carrying headers/
      # postfields already set above) via the separate `handle` argument.
      tryCatch({
        curl::curl_fetch_stream(
          url = claude_url,
          fun = function(data) {
            chunk_count <<- chunk_count + 1
            sse_buffer <<- paste0(sse_buffer, rawToChar(data))
            # NOTE: "chunks" here are raw network read events from the open
            # socket, not discrete pieces of content — a streaming response
            # naturally arrives in many small bursts over the ~1-2 minutes
            # Claude takes to search and generate. That volume is normal and
            # is what keeps the connection visibly "alive" (see the header
            # comment on call_claude below) — it doesn't mean more data is
            # being transferred than a non-streaming call would send, just
            # that it arrives in a steady trickle instead of one lump at the
            # end. Logged/reported sparingly since the raw count itself
            # isn't a meaningful progress metric — total characters
            # accumulated so far is more informative than chunk number.
            total_chars <- sum(nchar(accumulated_text))
            if (chunk_count %% 100 == 0) cat("[Claude] ...", total_chars, "chars received so far (", chunk_count, "network reads)\n")
            if (!is.null(progress_callback) && chunk_count %% 25 == 0)
              progress_callback(sprintf("Receiving response... %d characters so far", total_chars))
            while (grepl("\n\n", sse_buffer, fixed = TRUE)) {
              split_pos <- regexpr("\n\n", sse_buffer, fixed = TRUE)
              event_block <- substr(sse_buffer, 1, split_pos - 1)
              sse_buffer <<- substr(sse_buffer, split_pos + 2, nchar(sse_buffer))
              parse_sse_event(event_block)
            }
          },
          handle = h
        )
      }, error = function(e) {
        cat("[Claude] curl_fetch_stream() FAILED:", e$message, "\n")
        stop("Claude request failed at the network layer: ", e$message)
      })

      elapsed <- round(proc.time()[["elapsed"]] - t_start, 1)
      cat("[Claude] Stream finished after", elapsed, "s \u2014", sum(nchar(accumulated_text)),
          "chars accumulated (", chunk_count, "network reads, not a work unit \u2014 see comment above)\n")

      if (!is.null(stream_error_msg)) {
        cat("=== [Claude] call_claude() END (stream error) ===\n")
        stop("Claude stream error: ", stream_error_msg)
      }
      if (length(accumulated_text) == 0) {
        cat("[Claude] ERROR: empty stream, no text accumulated\n")
        cat("=== [Claude] call_claude() END (empty) ===\n")
        stop("No content received from Claude (empty stream)")
      }

      result_text <- paste(accumulated_text, collapse = "")
      cat("[Claude] SUCCESS \u2014", nchar(result_text), "total characters\n")
      cat("=== [Claude] call_claude() END (success) ===\n")
      result_text
    },

    # ============================================================
    # TRELLO
    # (methods referenced by Atlassian_API.zip's gantt_api_config/server.R
    # but not defined in that zip - implemented here against the real
    # Trello REST API: https://developer.atlassian.com/cloud/trello/rest/)
    # ============================================================

    set_trello_credentials = function(key, token, board_id = NULL) {
      self$trello_key      <- key
      self$trello_token     <- token
      self$trello_board_id  <- if (!is.null(board_id) && trimws(board_id) != "") trimws(board_id) else NULL
      self$trello_authenticated <- TRUE
    },

    test_trello_connection = function() {
      if (is.null(self$trello_key) || is.null(self$trello_token) ||
          nchar(self$trello_key) == 0 || nchar(self$trello_token) == 0)
        stop("Trello API Key and Token are both required")

      resp <- httr::GET("https://api.trello.com/1/members/me",
                         query = list(key = self$trello_key, token = self$trello_token))
      if (httr::status_code(resp) != 200)
        stop("Trello authentication failed: HTTP ", httr::status_code(resp), " - check your Key and Token")

      # Optional: if a board ID was given, confirm it's actually accessible
      # with these credentials (catches a valid key/token but wrong/typo'd
      # board id early, rather than failing later on first real use).
      if (!is.null(self$trello_board_id)) {
        board_resp <- httr::GET(paste0("https://api.trello.com/1/boards/", self$trello_board_id),
                                 query = list(key = self$trello_key, token = self$trello_token, fields = "name"))
        if (httr::status_code(board_resp) != 200)
          stop("Connected to Trello, but Board ID '", self$trello_board_id, "' is not accessible: HTTP ", httr::status_code(board_resp))
      }

      invisible(TRUE)
    },

    # ============================================================
    # JIRA
    # (same situation: referenced but not defined in the uploaded zip -
    # implemented against the real Jira Cloud REST API v3, Basic Auth with
    # email + API token per Atlassian's documented method)
    # ============================================================

    set_jira_credentials = function(url, email, token, project_key = NULL) {
      self$jira_url          <- sub("/+$", "", trimws(url))
      self$jira_email         <- email
      self$jira_token         <- token
      self$jira_project_key   <- if (!is.null(project_key) && trimws(project_key) != "") trimws(project_key) else NULL
      self$jira_authenticated <- TRUE
    },

    test_jira_connection = function() {
      if (is.null(self$jira_url) || is.null(self$jira_email) || is.null(self$jira_token) ||
          nchar(self$jira_url) == 0 || nchar(self$jira_email) == 0 || nchar(self$jira_token) == 0)
        stop("Jira URL, Email, and API Token are all required")

      resp <- httr::GET(paste0(self$jira_url, "/rest/api/3/myself"),
                         httr::authenticate(self$jira_email, self$jira_token, type = "basic"))
      if (httr::status_code(resp) != 200)
        stop("Jira authentication failed: HTTP ", httr::status_code(resp), " - check your URL, Email and API Token")

      if (!is.null(self$jira_project_key)) {
        proj_resp <- httr::GET(paste0(self$jira_url, "/rest/api/3/project/", self$jira_project_key),
                                httr::authenticate(self$jira_email, self$jira_token, type = "basic"))
        if (httr::status_code(proj_resp) != 200)
          stop("Connected to Jira, but Project Key '", self$jira_project_key, "' is not accessible: HTTP ", httr::status_code(proj_resp))
      }

      invisible(TRUE)
    }
  )
)
