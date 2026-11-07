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
# This app has one BigQuery-backed suite so far: "economic_calendar"
# (bq_table_economic_calendar / bq_full_table_economic_calendar), targeting
# atera-2.business_strategy.economic_calendar — the confirmed official
# dataset/table for this app's Economic Calendars group, shared with the
# Business Operations suite's dataset (by design, not a naming collision).
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
    bq_table_economic_calendar      = "economic_calendar",
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
      tryCatch({ bq_deauth() }, error = function(e) {})
      Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
      sdm_log("BQ", sprintf("Connecting: project %s, dataset %s", self$bq_project_id, self$bq_dataset_id), "cmd")

      if (!is.null(json_path)) {
        json_content <- jsonlite::fromJSON(json_path)
        req <- c("type", "project_id", "private_key", "client_email")
        missing <- setdiff(req, names(json_content))
        if (length(missing) > 0) stop("Missing JSON fields: ", paste(missing, collapse = ", "))
        bq_auth(path = json_path, cache = FALSE)

      } else if (!is.null(json_text) && trimws(json_text) != "") {
        json_content <- jsonlite::fromJSON(json_text)
        req <- c("type", "project_id", "private_key", "client_email")
        missing <- setdiff(req, names(json_content))
        if (length(missing) > 0) stop("Missing JSON fields: ", paste(missing, collapse = ", "))
        temp_file <- tempfile(fileext = ".json")
        writeLines(json_text, temp_file)
        self$bq_temp_file <- temp_file
        bq_auth(path = temp_file, cache = FALSE)

      } else {
        stop("Provide a service-account JSON file or paste its contents")
      }

      # Quick connection check
      tryCatch(bq_project_datasets(self$bq_project_id), error = function(e) {
        sdm_log("BQ", paste("Project check FAILED:", conditionMessage(e)), "error")
        stop("Project check failed: ", conditionMessage(e), call. = FALSE)
      })
      sdm_log("BQ", "Service account accepted; project reachable", "success")

      # ── deploy_apps: CREATE TABLE IF NOT EXISTS + one-time seed of the
      #    shinyapps.io registry (see R/utils_app_registry.R). Never alters
      #    or drops anything else in the dataset.
      tryCatch(bq_ensure_apps_table(self), error = function(e) {
        sdm_log("REGISTRY", paste("deploy_apps setup FAILED:", conditionMessage(e)), "error")
        stop("deploy_apps table check failed: ", conditionMessage(e), call. = FALSE)
      })

      self$bq_authenticated <- TRUE
      sdm_log("BQ", "Connected. BigQuery is active for this session.", "success")
      invisible(TRUE)
    },

    bq_query = function(query) {
      job <- bq_project_query(self$bq_project_id, query)
      bq_table_download(job)
    },

    bq_insert_economic_calendar = function(data_frame) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("row_id", "query_id", "query_date", "query_timestamp",
                          "event_id", "event_date", "event_name", "event_description",
                          "event_importance", "event_role", "linked_to_event_id",
                          "asset_class", "specific_asset", "impact_direction",
                          "impact_rationale", "source", "created_at")

      now <- format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")
      data_frame$created_at <- now
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- NA_character_
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_economic_calendar)
      bq_table_upload(table_ref, data_frame,
                       create_disposition = "CREATE_IF_NEEDED",
                       write_disposition  = "WRITE_APPEND")

      cat("\u2705 [BigQuery] Inserted", nrow(data_frame), "row(s) \u2192", self$bq_full_table_economic_calendar, "\n")
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
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0)
        stop("Claude API key is empty")

      resp <- httr::POST(
        "https://api.anthropic.com/v1/messages",
        httr::add_headers("x-api-key" = self$claude_api_key,
                           "anthropic-version" = "2023-06-01",
                           "content-type" = "application/json"),
        body = jsonlite::toJSON(list(model = self$claude_model, max_tokens = 16,
                                      messages = list(list(role = "user", content = "Reply with OK."))),
                                 auto_unbox = TRUE),
        encode = "raw"
      )
      if (httr::status_code(resp) != 200) stop("Claude API test failed: HTTP ", httr::status_code(resp))
      invisible(TRUE)
    },

    # Streaming Claude call (SSE via curl) - same pattern as the reference
    # app's shared call_claude(). enable_web_search = TRUE so Claude looks up
    # real, currently-scheduled/released calendar events from reputable
    # sources rather than generating dates/figures from training data.
    call_claude = function(prompt, max_tokens = NULL, progress_callback = NULL, enable_web_search = TRUE) {
      if (!self$claude_authenticated) stop("Not authenticated to Claude API. Please save credentials first.")
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0) stop("Claude API key is empty.")

      tokens <- max_tokens %||% self$claude_max_tokens
      if (!is.null(progress_callback)) progress_callback("Connecting to Claude API...")

      body_list <- list(
        model = self$claude_model, max_tokens = tokens, stream = TRUE,
        messages = list(list(role = "user", content = prompt))
      )
      if (isTRUE(enable_web_search)) {
        body_list$tools <- list(list(type = "web_search_20250305", name = "web_search"))
      }
      body_json <- jsonlite::toJSON(body_list, auto_unbox = TRUE)

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
          }
        }
      }

      curl::curl_fetch_stream(
        curl::handle_setopt(h, url = "https://api.anthropic.com/v1/messages"),
        fun = function(data) {
          chunk_count <<- chunk_count + 1
          sse_buffer <<- paste0(sse_buffer, rawToChar(data))
          if (!is.null(progress_callback) && chunk_count %% 5 == 0)
            progress_callback(sprintf("Streaming... %d chunks received", chunk_count))
          while (grepl("\n\n", sse_buffer, fixed = TRUE)) {
            split_pos <- regexpr("\n\n", sse_buffer, fixed = TRUE)
            event_block <- substr(sse_buffer, 1, split_pos - 1)
            sse_buffer <<- substr(sse_buffer, split_pos + 2, nchar(sse_buffer))
            parse_sse_event(event_block)
          }
        }
      )

      if (!is.null(stream_error_msg)) stop("Claude stream error: ", stream_error_msg)
      if (length(accumulated_text) == 0) stop("No content received from Claude (empty stream)")

      paste(accumulated_text, collapse = "")
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
