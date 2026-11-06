# R/utils_api.R
# APIManager R6 Class — Business Operations Suite
# One shared Claude connection + one shared BigQuery connection, serving
# THREE independent tables (Day Planner, Events Scheduling, Funding
# Programmes). Every BigQuery method, state trigger, taxonomy cache, and
# cross-module handoff buffer is suite-scoped (suffixed _schedule / _events
# / _funding) to prevent one suite's activity from needlessly re-firing
# another suite's reactives, and to prevent silent function/method name
# collisions between suites that started life as separate apps.
# =============================================================================

library(R6)
library(httr)
library(curl)
library(jsonlite)
library(bigrquery)

APIManager <- R6::R6Class(
  "APIManager",

  public = list(
    # ── Claude API credentials (shared) ─────────────────────────────────────
    claude_api_key      = NULL,
    claude_model        = "claude-sonnet-4-6",
    claude_max_tokens   = 8000,
    claude_timeout      = 180,
    claude_authenticated = FALSE,
    claude_tested       = NA,        # NA = key loaded but never tested; TRUE/FALSE after Test Connection

    # ── BigQuery credentials (shared project/dataset, nine tables) ──────────
    bq_project_id      = "atera-2",
    bq_dataset_id      = "business_strategy",
    bq_table_schedule  = "day_scheduler",
    bq_table_prep      = "day_prep_steps",
    bq_table_commitments = "monthly_commitments",
    bq_table_diet      = "diet_log",
    bq_table_exercise  = "exercise_log",
    bq_table_events    = "city_events",
    bq_table_funding   = "funding_programmes",
    bq_table_gantt_tasks    = "gantt_tasks",
    bq_table_gantt_contacts = "gantt_contacts",
    bq_table_contacts       = "business_contacts",
    bq_table_communications = "contact_communications",
    bq_full_table_schedule = NULL,
    bq_full_table_prep     = NULL,
    bq_full_table_commitments = NULL,
    bq_full_table_diet     = NULL,
    bq_full_table_exercise = NULL,
    bq_full_table_events   = NULL,
    bq_full_table_funding  = NULL,
    bq_full_table_gantt_tasks    = NULL,
    bq_full_table_gantt_contacts = NULL,
    bq_full_table_contacts       = NULL,
    bq_full_table_communications = NULL,
    bq_authenticated   = FALSE,
    bq_temp_file       = NULL,

    # ── Non-blocking schema-compatibility warning (Events only — see notes
    #    on check_events_table_compatibility below) ─────────────────────────
    events_schema_warning = NULL,
    bq_setup_key = NULL,
    bq_units_opened = list(),     # tab groups the user has opened this session (only these are refreshed/loaded)
    bq_keys_ready = list(),       # table key -> TRUE once verified (once per connection)
    bq_units_ready = list(),      # tab group -> TRUE once its tables are verified (on demand)
    bq_unit_status = list(),      # tab group -> list(label, state, detail, at) for the sidebar

    # ── Suite-scoped reactive triggers ──────────────────────────────────────
    state_trigger_schedule = NULL,
    state_trigger_diet      = NULL,
    state_trigger_exercise  = NULL,
    state_trigger_events   = NULL,
    state_trigger_funding  = NULL,
    state_trigger_gantt    = NULL,
    state_trigger_contacts = NULL,

    # ── Suite-scoped taxonomy caches (avoid redundant simultaneous queries
    #    when multiple modules in the same suite ask for the same dropdown
    #    data right after a connect/upload) ─────────────────────────────────
    schedule_taxonomy_cache = NULL,
    prep_taxonomy_cache      = NULL,
    commitments_taxonomy_cache = NULL,
    diet_taxonomy_cache      = NULL,
    exercise_taxonomy_cache  = NULL,
    events_taxonomy_cache   = NULL,
    funding_taxonomy_cache  = NULL,

    # ── Suite-scoped generate -> bulk-import handoff buffers ────────────────
    pending_bulk_text_schedule = NULL,
    pending_commitment_context = NULL,
    pending_bulk_text_diet      = NULL,
    pending_bulk_text_exercise  = NULL,
    pending_bulk_text_events   = NULL,
    pending_bulk_text_funding  = NULL,

    # ── Gantt to Tickets: in-memory staging (mirrors the original app's
    #    plain-mutable-field + state_trigger pattern - Upload/Review/Edit
    #    work on this in-memory data.frame; "Save to BigQuery" in
    #    Review & Edit and every Submit action in Submit to Boards persist
    #    a snapshot row per task into gantt_tasks, an append-only log like
    #    every other suite in this app) ────────────────────────────────────
    gantt_tasks_data = NULL,

    # ── Gantt to Tickets: Trello / Jira / SMTP credentials — kept local to
    #    this suite only, per instruction (never merged into the shared
    #    API Configuration group) ────────────────────────────────────────
    trello_key = NULL, trello_token = NULL, trello_board_id = NULL,
    trello_authenticated = FALSE,

    # ── Day Planner Commitments: a SEPARATE Trello connection, local to
    #    this feature only - deliberately NOT shared with Gantt to Tickets'
    #    own Trello credentials above, since a commitments board and a
    #    project-tasks board are commonly different boards/accounts. If you
    #    actually want one shared Trello connection across both suites,
    #    consolidate these two credential sets into one. ─────────────────
    commitment_trello_key = NULL, commitment_trello_token = NULL, commitment_trello_board_id = NULL,
    commitment_trello_authenticated = FALSE,
    jira_url = NULL, jira_email = NULL, jira_token = NULL, jira_project_key = NULL,
    jira_authenticated = FALSE,
    gantt_smtp_host = NULL, gantt_smtp_port = NULL,
    gantt_smtp_user = NULL, gantt_smtp_password = NULL,
    gantt_smtp_authenticated = FALSE,
    gantt_email_subject_template = "New Task Assignment: {Task_Name}",
    gantt_email_body_template = "Hello {Assignee},\n\nYou have been assigned a new task:\n\nTask: {Task_Name}\nDescription: {Description}\nStart Date: {Start_Date}\nEnd Date: {End_Date}\nPriority: {Priority}\n\nPlease review and confirm.\n\nBest regards",

    # ── Contact Manager: OpenAI + its own SMTP credentials — kept local to
    #    this suite only, per instruction ────────────────────────────────
    contacts_openai_key = NULL, contacts_gpt_model = "gpt-4o",
    contacts_api_authenticated = FALSE,
    contacts_smtp_host = NULL, contacts_smtp_port = NULL,
    contacts_smtp_user = NULL, contacts_smtp_password = NULL,
    contacts_smtp_authenticated = FALSE,

    # ── Contact Manager: selected-contact / generated-message handoff
    #    (mirrors the original app's cross-module handoff, using our
    #    state_trigger_contacts as the reactive dependency) ───────────────
    contacts_selected_contact = NULL,
    contacts_selected_contact_email = NULL,
    contacts_generated_message = NULL,

    # ── Titan calendar (Events Scheduling group): sign-in state, the
    #    "Events to save" list, and the hand-off buffers used by the
    #    Visualisation tabs. The password lives only here, in server memory.
    gantt_time_zone = NULL,       # zone chosen in Gantt > Review & Edit, used for later history rows
    bq_time_zone_ready = list(),  # per table: TRUE once the time_zone column is confirmed to exist
    titan_state = NULL,          # reactiveVal: list(ok, email, server, calendars)
    titan_pass = NULL,           # plain string, never printed or logged
    titan_tz = "America/Mexico_City",  # zone chosen on Events to Calendar > Events to save
    titan_queue = NULL,          # reactiveVal: list of "Events to save" items
    titan_pending_ics = NULL,    # reactiveVal: list(text, label, stamp) for the Import tab
    titan_goto_tab = NULL,       # reactiveVal: list(tab, stamp) horizontal subtab to show
    titan_log = NULL,            # reactiveVal: character vector, newest first
    zoom_invite = NULL,          # reactiveVal: invite read from a screenshot (Zoom Schedule -> Events to Calendar)
    mail_drafts = NULL,          # reactiveVal: list of invite emails waiting in Send Email
    muscle_tick = NULL,          # reactiveVal counter: bumps when muscle_* data changes
    muscle_goto = NULL,          # reactiveVal: list(programme_id, option_key) handed to Muscle Log
    muscle_cache = NULL,         # environment: cached muscle_* tables
    muscle_tables_key = NULL,    # project|dataset the muscle tables were ensured for
    titan_smtp = NULL,           # reactiveVal: list(host, port) used for sending email
    titan_smtp_ok = NULL,        # reactiveVal: TRUE after a successful SMTP login test
    # ---- Slack (Online Collaboration group) ----
    slack_state = NULL,          # reactiveVal: list(ok, team, bot_user, url, scopes...)
    slack_token = NULL,          # plain string, never printed or logged
    slack_users = NULL,          # named vector: user id -> display name
    slack_log = NULL,            # reactiveVal: character vector, newest first

    initialize = function() {
      self$titan_state       <- shiny::reactiveVal(list(ok = FALSE))
      self$titan_queue       <- shiny::reactiveVal(list())
      self$titan_pending_ics <- shiny::reactiveVal(NULL)
      self$titan_goto_tab    <- shiny::reactiveVal(NULL)
      self$titan_log         <- shiny::reactiveVal(character())
      self$zoom_invite       <- shiny::reactiveVal(NULL)
      self$mail_drafts       <- shiny::reactiveVal(list())
      self$muscle_tick       <- shiny::reactiveVal(0L)
      self$muscle_goto       <- shiny::reactiveVal(NULL)
      self$muscle_cache      <- new.env(parent = emptyenv())
      self$titan_smtp        <- shiny::reactiveVal(list(host = "", port = 465))
      self$titan_smtp_ok     <- shiny::reactiveVal(FALSE)
      self$slack_state       <- shiny::reactiveVal(list(ok = FALSE))
      self$slack_log         <- shiny::reactiveVal(character())
      self$initialize_core()
    },

    initialize_core = function() {
      self$state_trigger_schedule <- shiny::reactiveVal(0)
      self$state_trigger_diet     <- shiny::reactiveVal(0)
      self$state_trigger_exercise <- shiny::reactiveVal(0)
      self$state_trigger_events   <- shiny::reactiveVal(0)
      self$state_trigger_funding  <- shiny::reactiveVal(0)
      self$state_trigger_gantt    <- shiny::reactiveVal(0)
      self$state_trigger_contacts <- shiny::reactiveVal(0)

      self$pending_bulk_text_schedule <- shiny::reactiveVal("")
      self$pending_commitment_context <- shiny::reactiveVal("")
      self$pending_bulk_text_diet     <- shiny::reactiveVal("")
      self$pending_bulk_text_exercise <- shiny::reactiveVal("")
      self$pending_bulk_text_events   <- shiny::reactiveVal("")
      self$pending_bulk_text_funding  <- shiny::reactiveVal("")

      self$gantt_tasks_data <- data.frame()

      self$recompute_full_table_ids()
      cat("🔌 API Manager initialized (Day Planner + Diet + Exercise + Events + Funding + Gantt to Tickets + Contact Manager)\n")
    },

    recompute_full_table_ids = function() {
      self$bq_full_table_schedule <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_schedule)
      self$bq_full_table_prep     <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_prep)
      self$bq_full_table_commitments <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_commitments)
      self$bq_full_table_diet     <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_diet)
      self$bq_full_table_exercise <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_exercise)
      self$bq_full_table_events   <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_events)
      self$bq_full_table_funding  <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_funding)
      self$bq_full_table_gantt_tasks    <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_gantt_tasks)
      self$bq_full_table_gantt_contacts <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_gantt_contacts)
      self$bq_full_table_contacts       <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_contacts)
      self$bq_full_table_communications <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_communications)
    },

    # ── Suite-scoped state triggers (each also invalidates its OWN taxonomy
    #    cache only — an upload in one suite never re-fires another suite's
    #    dropdown-populating reactives) ──────────────────────────────────────
    trigger_state_update_schedule = function() {
      self$state_trigger_schedule(shiny::isolate(self$state_trigger_schedule()) + 1)
      self$schedule_taxonomy_cache <- NULL
      self$prep_taxonomy_cache <- NULL
      self$commitments_taxonomy_cache <- NULL
      cat("🔔 [Day Planner] state trigger fired\n")
    },
    trigger_state_update_diet = function() {
      self$state_trigger_diet(shiny::isolate(self$state_trigger_diet()) + 1)
      self$diet_taxonomy_cache <- NULL
      cat("🔔 [Diet Planner] state trigger fired\n")
    },
    trigger_state_update_exercise = function() {
      self$state_trigger_exercise(shiny::isolate(self$state_trigger_exercise()) + 1)
      self$exercise_taxonomy_cache <- NULL
      cat("🔔 [Exercise Tracker] state trigger fired\n")
    },
    trigger_state_update_events = function() {
      self$state_trigger_events(shiny::isolate(self$state_trigger_events()) + 1)
      self$events_taxonomy_cache <- NULL
      cat("🔔 [Events Scheduling] state trigger fired\n")
    },
    trigger_state_update_gantt = function() {
      self$state_trigger_gantt(shiny::isolate(self$state_trigger_gantt()) + 1)
      cat("🔔 [Gantt to Tickets] state trigger fired\n")
    },
    trigger_state_update_contacts = function() {
      self$state_trigger_contacts(shiny::isolate(self$state_trigger_contacts()) + 1)
      cat("🔔 [Contact Manager] state trigger fired\n")
    },
    trigger_state_update_funding = function() {
      self$state_trigger_funding(shiny::isolate(self$state_trigger_funding()) + 1)
      self$funding_taxonomy_cache <- NULL
      cat("🔔 [Funding Programmes] state trigger fired\n")
    },

    # ============================================================
    # TITAN CALENDAR METHODS (Events Scheduling group)
    # ============================================================
    titan_set_session = function(email, pass, server, calendars) {
      self$titan_pass <- pass
      self$titan_state(list(ok = TRUE, email = email, server = server, calendars = calendars))
    },
    titan_sign_out = function() {
      self$titan_pass <- NULL
      self$titan_smtp_ok(FALSE)
      self$titan_state(list(ok = FALSE))
    },
    titan_credentials = function() {
      st <- self$titan_state()
      list(user = if (isTRUE(st$ok)) st$email else "", pass = if (isTRUE(st$ok)) self$titan_pass else "")
    },
    titan_log_add = function(msg) {
      line <- sprintf("[%s] %s", format(Sys.time(), "%H:%M:%S"), paste0(msg, collapse = ""))
      self$titan_log(head(c(line, shiny::isolate(self$titan_log())), 500))
    },
    # Adds items (by UID, skipping ones already queued); returns how many were new.
    titan_queue_add = function(items) {
      q <- shiny::isolate(self$titan_queue())
      have <- vapply(q, function(x) as.character(x$uid), "")
      fresh <- Filter(function(x) !(as.character(x$uid) %in% have), items)
      if (length(fresh)) self$titan_queue(c(q, fresh))
      length(fresh)
    },
    titan_set_pending_ics = function(text, label = "") {
      self$titan_pending_ics(list(text = text, label = label, stamp = Sys.time()))
    },
    slack_set_session = function(token, info) {
      self$slack_token <- token
      self$slack_state(c(list(ok = TRUE), info))
    },
    slack_sign_out = function() {
      self$slack_token <- NULL
      self$slack_users <- NULL
      self$slack_state(list(ok = FALSE))
    },
    slack_log_add = function(method, result, secs = NA) {
      line <- sprintf("[%s] %s - %s%s", format(Sys.time(), "%H:%M:%S"), method, result,
                      if (is.na(secs)) "" else sprintf(" (%.1fs)", secs))
      self$slack_log(head(c(line, self$slack_log()), 500))
    },
    titan_goto = function(tab) {
      self$titan_goto_tab(list(tab = tab, stamp = Sys.time()))
    },

    set_pending_bulk_text_schedule = function(text) { self$pending_bulk_text_schedule(text) },
    set_pending_commitment_context = function(text) { self$pending_commitment_context(text) },
    set_pending_bulk_text_diet     = function(text) { self$pending_bulk_text_diet(text) },
    set_pending_bulk_text_exercise = function(text) { self$pending_bulk_text_exercise(text) },
    set_pending_bulk_text_events   = function(text) { self$pending_bulk_text_events(text) },
    set_pending_bulk_text_funding  = function(text) { self$pending_bulk_text_funding(text) },

    log_debug = function(msg, tag = "APIManager") {
      cat(sprintf("[%s] %s\n", tag, msg))
    },

    # ============================================================
    # CLAUDE API METHODS (shared by all three suites)
    # ============================================================

    set_claude_credentials = function(api_key, model = NULL, max_tokens = NULL, timeout = NULL) {
      self$claude_api_key <- trimws(api_key)
      self$claude_tested <- NA
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
          self$claude_tested <- TRUE
          # refresh the status text of the modules (their data loaders are gated per tab, so this loads nothing for unopened tabs)
          tryCatch({ self$trigger_state_update_schedule(); self$trigger_state_update_events(); self$trigger_state_update_funding() }, error = function(e) NULL)
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
        self$claude_tested <- FALSE
        stop(paste("Connection failed:", e$message))
      })
    },

    # Quick standalone reachability/TLS diagnostic, surfaced via a "Run
    # Network Diagnostics" button in Claude API Config. Distinguishes "can't
    # reach api.anthropic.com at all" from other failure modes without
    # requiring a real generation call.
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

    # Streaming Claude call (SSE via curl::curl_fetch_stream), shared by
    # every suite's Generate/Scan tab. `enable_web_search = TRUE` is used
    # only by Events Scheduling's scan_events, which needs Claude to look up
    # real, currently-happening events rather than generate from training
    # data alone. The SSE parser already ignores any event type it doesn't
    # recognise (content_block_start, server_tool_use, web_search_tool_result,
    # ping, etc.) and only accumulates text_delta pieces, so enabling the
    # web_search tool works with no change to the parsing loop itself.
    call_claude = function(prompt, max_tokens = NULL, progress_callback = NULL, enable_web_search = FALSE, images = NULL) {
      if (!self$claude_authenticated) stop("Not authenticated to Claude API. Please save credentials first.")
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0) stop("Claude API key is empty. Please configure credentials.")

      tokens <- max_tokens %||% self$claude_max_tokens
      if (!is.null(progress_callback)) progress_callback("Connecting to Claude API...")

      call_id <- paste(sample(c(letters, LETTERS, 0:9), 8, replace = TRUE), collapse = "")
      start_time <- Sys.time()

      self$log_debug(sprintf(
        "[%s] Sending STREAMING request | model=%s | max_tokens=%d | timeout=%ds | web_search=%s | prompt_chars=%d",
        call_id, self$claude_model, tokens, self$claude_timeout, enable_web_search, nchar(prompt)
      ), tag = "call_claude")

      body_list <- list(
        model = self$claude_model, max_tokens = tokens, stream = TRUE,
        messages = list(list(role = "user", content = if (length(images)) c(
          lapply(images, function(im) list(type = "image", source = list(type = "base64",
                                           media_type = im$media_type, data = im$data))),
          list(list(type = "text", text = prompt))) else prompt))
      )
      if (isTRUE(enable_web_search)) {
        body_list$tools <- list(list(type = "web_search_20250305", name = "web_search"))
      }
      body_json <- toJSON(body_list, auto_unbox = TRUE)

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
          # Any other event type (content_block_start/stop, message_start,
          # ping, server_tool_use, web_search_tool_result, ...) is silently
          # ignored - only text_delta content ends up in the final result.
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

        list(text = response_text, stop_reason = final_stop_reason %||% "unknown",
             truncated = identical(final_stop_reason, "max_tokens"))

      }, error = function(e) {
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        error_msg <- e$message

        self$log_debug(sprintf("[%s] FAILED after %.2fs", call_id, elapsed), tag = "call_claude ERROR")
        self$log_debug(sprintf("[%s] Raw message: %s", call_id, error_msg), tag = "call_claude ERROR")
        self$log_debug(sprintf(
          "[%s] Stream progress before failure: %d chunk(s), %d bytes, %d chars accumulated",
          call_id, chunk_count, byte_count, sum(nchar(accumulated_text))
        ), tag = "call_claude ERROR")
        tryCatch({
          cv <- curl::curl_version()
          self$log_debug(sprintf("[%s] curl version: %s | ssl_version: %s", call_id, cv$version, cv$ssl_version), tag = "call_claude ERROR")
        }, error = function(e2) {})

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
        } else if (grepl("schannel|close_notify", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "TLS connection closed abruptly after ", round(elapsed, 1), "s, before any data was received. ",
            "This points to a firewall, antivirus HTTPS inspection, VPN, or proxy blocking the connection ",
            "outright - it is usually NOT a real loss of internet access. ",
            "Try: (1) Run Network Diagnostics in Claude API Config, (2) temporarily disable VPN/antivirus ",
            "HTTPS scanning, (3) try a different network. [call_id: ", call_id, "]"
          )
        } else if (grepl("Timeout", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "Request timeout after ", self$claude_timeout, " seconds (elapsed ", round(elapsed, 1), "s). ",
            "Try: (1) Increase timeout in Claude API Config, (2) narrow the request scope, or (3) try again later. ",
            "[call_id: ", call_id, "]"
          )
        } else if (grepl("peer|SSL|connection", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0("Network connection error (elapsed ", round(elapsed, 1), "s): ", error_msg,
                              ". Please check your connection and try again. [call_id: ", call_id, "]")
        } else if (grepl("curl", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0("HTTP request error (elapsed ", round(elapsed, 1), "s): ", error_msg,
                              ". Please check your internet connection and try again. [call_id: ", call_id, "]")
        } else {
          error_msg <- paste0(error_msg, " [call_id: ", call_id, "]")
        }

        stop(error_msg)
      })
    },

    # ============================================================
    # BIGQUERY: SHARED AUTHENTICATION, PER-SUITE TABLES
    # ============================================================

    set_bigquery_credentials = function(project_id, dataset_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      self$recompute_full_table_ids()
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

        # Quick connection check ONLY. Tables are no longer verified here: each tab group
        # checks its own tables the first time it is opened (see bq_ensure_unit / bq_need),
        # so start-up is one fast round trip instead of ~20.
        bq_project_datasets(self$bq_project_id)

        self$bq_setup_key <- paste(self$bq_project_id, self$bq_dataset_id, sep = "|")
        self$bq_units_ready <- list(); self$bq_keys_ready <- list()    # a new connection / project: nothing verified yet
        self$muscle_tables_key <- NULL
        self$bq_authenticated <- TRUE
        cat("\u2713 [BigQuery] connected - each tab verifies its tables the first time it is opened\n")
        # refresh the modules' status text (their data loaders are gated per tab, so unopened tabs load nothing)
        tryCatch({ self$trigger_state_update_schedule(); self$trigger_state_update_events(); self$trigger_state_update_funding() },
                 error = function(e) cat("[BigQuery] note: refresh trigger skipped:", conditionMessage(e), "\n"))

        # the refresh triggers are cosmetic: a failure here must never undo a good connection

        return(TRUE)
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        stop(paste("BigQuery authentication failed:", e$message))
      })
    },

    # CREATE TABLE IF NOT EXISTS text for one app table (safe no-op if it exists; never alters or drops anything)
    bq_table_ddl = function(key) {
      switch(key,
        schedule = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              schedule_date STRING, day_type STRING, country STRING, city STRING,
              trip_details STRING, row_type STRING, row_sequence INTEGER,
              location_name STRING, location_details STRING, opening_hours STRING,
              recommended_time STRING, observations STRING
            )", self$bq_full_table_schedule),
        prep = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              schedule_date STRING, category STRING, location STRING,
              additional_context STRING, step_sequence INTEGER, step_text STRING,
              is_completed BOOL
            )", self$bq_full_table_prep),
        commitments = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              category STRING, sector STRING, topic STRING,
              commitment_date STRING, deadline STRING, status STRING,
              description STRING, stakeholders STRING,
              value_of_delivery STRING, consequences_of_failure STRING,
              trello_card_id STRING, trello_card_url STRING
            )", self$bq_full_table_commitments),
        diet = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              log_date STRING, diet_type STRING, dietary_restrictions STRING,
              row_type STRING, row_sequence INTEGER,
              meal_name STRING, meal_details STRING, meal_time STRING,
              calories_macros STRING, observations STRING
            )", self$bq_full_table_diet),
        exercise = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              workout_date STRING, session_type STRING, session_notes STRING,
              row_type STRING, row_sequence INTEGER,
              exercise_category STRING, exercise_name STRING, exercise_details STRING,
              metric_primary STRING, metric_secondary STRING,
              calories_burned STRING, observations STRING
            )", self$bq_full_table_exercise),
        funding = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              category STRING, country STRING, city_region STRING,
              programme_name STRING, amount_of_money STRING, conditions STRING,
              key_sponsors STRING, key_organiser_profiles STRING, areas_of_application STRING,
              start_date_for_applying STRING, deadline STRING,
              recommendations_for_applying STRING, verified_urls STRING
            )", self$bq_full_table_funding),
        gantt_tasks = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              upload_batch STRING, log_stage STRING,
              task_name STRING, description STRING, start_date STRING, end_date STRING,
              duration_days STRING, assignee STRING, priority STRING, status STRING,
              labels STRING, additional_notes STRING, submission_result STRING
            )", self$bq_full_table_gantt_tasks),
        gantt_contacts = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              country STRING, city STRING, organization STRING, full_name STRING,
              linkedin STRING, email STRING, phone STRING, date_added STRING
            )", self$bq_full_table_gantt_contacts),
        contacts = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              contact_id STRING, full_name STRING, industry STRING, company STRING,
              job_title STRING, location STRING, country STRING, email STRING,
              phone STRING, linkedin STRING, areas_of_interest STRING, university STRING,
              academic_background STRING, user_notes STRING, last_interaction_date STRING,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(), updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
            )", self$bq_full_table_contacts),
        communications = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              message_id STRING, contact_id STRING, channel_type STRING,
              communication_purpose STRING, language STRING, message_length STRING,
              message_content STRING, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
            )", self$bq_full_table_communications),
        events = sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              event_name STRING, organiser STRING, city STRING, country STRING,
              category STRING, subcategory STRING, event_date STRING, event_time STRING,
              venue_name STRING, address STRING, latitude STRING, longitude STRING,
              description STRING, ticket_url STRING, price_range STRING,
              source_url STRING, scan_date STRING, extra_info STRING
            )", self$bq_full_table_events),
        NULL)
    },

    # ============================================================
    # ON-DEMAND TABLE CHECKS (one "unit" per tab group)
    # ============================================================
    # unit -> the table keys it owns (keys match bq_table_<key> / bq_full_table_<key>)
    bq_unit_tables = function(unit) switch(unit,
      planner  = c("schedule", "prep", "commitments"),
      diet     = "diet",
      exercise = "exercise",
      events   = "events",
      funding  = "funding",
      gantt    = c("gantt_tasks", "gantt_contacts"),
      contacts = c("contacts", "communications"),
      character()),
    bq_unit_label = function(unit) switch(unit, planner = "Day Planner", diet = "Diet Planner", exercise = "Exercise Tracker",
      events = "Events Scheduling", funding = "Funding Programmes", gantt = "Gantt to Tickets", contacts = "Contact Manager",
      muscle = "Muscle Programme", unit),
    # which unit owns a table key (used to find what a query or insert needs)
    bq_unit_of_key = function(key) {
      for (u in c("planner", "diet", "exercise", "events", "funding", "gantt", "contacts"))
        if (key %in% self$bq_unit_tables(u)) return(u)
      NULL
    },

    # Verifies the given tables (keys like "schedule", "prep"; "muscle" = the four muscle tables): ONE INFORMATION_SCHEMA
    # query limited to the tables not verified yet, then creates only what is missing, checks city_events compatibility
    # (events) and adds time_zone only where absent. Each table is verified ONCE per connection, so reopening a tab or opening
    # another tab that shares a table costs nothing. `label` names the tab in the sidebar. Never raises; a failed check is retried.
    bq_ensure_keys = function(keys, label = NULL) {
      keys <- unique(keys); if (!length(keys)) return(TRUE)
      if (!isTRUE(self$bq_authenticated)) return(FALSE)
      label <- label %||% paste(keys, collapse = ", ")
      ok_all <- TRUE
      if ("muscle" %in% keys) {
        if (!isTRUE(self$bq_keys_ready[["muscle"]])) ok_all <- isTRUE(tryCatch(self$bq_muscle_ensure(label), error = function(e) FALSE))
        keys <- setdiff(keys, "muscle")
      }
      todo <- keys[!vapply(keys, function(k) isTRUE(self$bq_keys_ready[[k]]), TRUE)]
      if (!length(todo)) return(ok_all)
      t0 <- Sys.time(); self$bq_note_status(label, "checking", sprintf("checking %d table(s)...", length(todo)))
      ok <- tryCatch({
        names_sql <- paste0("'", vapply(todo, function(k) self[[paste0("bq_table_", k)]], ""), "'", collapse = ",")
        schema_cols <- tryCatch(bq_table_download(bq_project_query(self$bq_project_id, sprintf(
          "SELECT table_name, column_name FROM `%s.%s.INFORMATION_SCHEMA.COLUMNS` WHERE table_name IN (%s)",
          self$bq_project_id, self$bq_dataset_id, names_sql))), error = function(e) {
            cat("\u26a0\ufe0f  [BigQuery] could not read INFORMATION_SCHEMA - falling back to CREATE IF NOT EXISTS:", conditionMessage(e), "\n"); NULL })
        known <- if (is.null(schema_cols)) character() else unique(schema_cols$table_name)
        for (k in todo) {
          tn <- self[[paste0("bq_table_", k)]]
          tryCatch({
            if (!tn %in% known) bq_project_query(self$bq_project_id, self$bq_table_ddl(k))
            cat(sprintf("\u2713 [BigQuery] %s table ready (%s)\n", tn, label))
          }, error = function(e) { cat("\u26a0\ufe0f  [BigQuery]", tn, "CREATE TABLE check failed:", conditionMessage(e), "\n"); stop(conditionMessage(e)) })
        }
        if ("events" %in% todo) self$events_schema_warning <- self$check_events_table_compatibility(schema_cols)
        for (k in intersect(todo, c("schedule", "diet", "exercise", "events", "funding", "gantt_tasks"))) {
          tn <- self[[paste0("bq_table_", k)]]
          if (!is.null(schema_cols) && any(schema_cols$table_name == tn & schema_cols$column_name == "time_zone")) self$bq_time_zone_ready[[k]] <- TRUE
          else self$bq_ensure_time_zone_column(k)
        }
        TRUE
      }, error = function(e) { self$bq_note_status(label, "failed", conditionMessage(e)); FALSE })
      if (isTRUE(ok)) {
        for (k in todo) self$bq_keys_ready[[k]] <- TRUE
        for (u in c("planner", "diet", "exercise", "events", "funding", "gantt", "contacts"))
          if (all(vapply(self$bq_unit_tables(u), function(k) isTRUE(self$bq_keys_ready[[k]]), TRUE))) self$bq_units_ready[[u]] <- TRUE
        self$bq_note_status(label, "ready", sprintf("%d table(s) ready in %.1f s", length(todo), as.numeric(difftime(Sys.time(), t0, units = "secs"))))
      }
      isTRUE(ok) && ok_all
    },
    # a whole tab group's tables (used by tests and by code that needs the full set)
    bq_ensure_unit = function(unit) {
      if (identical(unit, "muscle")) return(self$bq_ensure_keys("muscle", self$bq_unit_label(unit)))
      self$bq_ensure_keys(self$bq_unit_tables(unit), self$bq_unit_label(unit))
    },
    # ---- per-tab lazy loading ------------------------------------------------------------------
    # A module's data loaders call tab_gate("<its tab name>") first: inside a reactive/observer it stops silently until
    # that tab has been opened (and its tables verified) in THIS browser session, then runs once and again only when
    # its own refresh trigger fires. Opened tabs live in session$userData$tabs_opened (set up in create_server); without
    # a session (unit tests) nothing is gated.
    tabs_opened_rv = function() {
      dom <- shiny::getDefaultReactiveDomain(); if (is.null(dom)) return(NULL)
      root <- tryCatch(dom$rootScope(), error = function(e) dom)
      tryCatch(root$userData$tabs_opened, error = function(e) NULL)
    },
    keys_opened_rv = function() {
      dom <- shiny::getDefaultReactiveDomain(); if (is.null(dom)) return(NULL)
      root <- tryCatch(dom$rootScope(), error = function(e) dom)
      tryCatch(root$userData$keys_opened, error = function(e) NULL)
    },
    # shared dropdown/taxonomy loaders wait until ANY opened tab uses their table (then the result is cached for the other tabs)
    keys_gate = function(keys) { rv <- self$keys_opened_rv(); if (!is.null(rv)) shiny::req(any(keys %in% rv())); invisible(TRUE) },
    tab_open = function(tab) { rv <- self$tabs_opened_rv(); if (is.null(rv)) TRUE else tab %in% rv() },
    tab_gate = function(tab) { shiny::req(self$tab_open(tab)); invisible(TRUE) },
    # Called when the user opens a tab group (or a tab in it): verify its tables, then refresh its modules.
    bq_open_unit = function(unit, fire = TRUE) {
      self$bq_units_opened[[unit]] <- TRUE
      if (!isTRUE(self$bq_authenticated)) return(invisible(FALSE))
      ok <- self$bq_ensure_unit(unit)
      if (isTRUE(ok) && fire) self$bq_fire_unit(unit)
      invisible(ok)
    },
    bq_fire_unit = function(unit) switch(unit,
      planner = self$trigger_state_update_schedule(), diet = self$trigger_state_update_diet(),
      exercise = self$trigger_state_update_exercise(), events = self$trigger_state_update_events(),
      funding = self$trigger_state_update_funding(), gantt = self$trigger_state_update_gantt(),
      contacts = self$trigger_state_update_contacts(), muscle = self$muscle_changed(), NULL),
    bq_fire_opened = function() {
      for (u in names(self$bq_units_opened)) if (isTRUE(self$bq_units_opened[[u]])) self$bq_fire_unit(u)
      invisible(TRUE)
    },
    # shorthand used at the top of data methods: make sure the table (key) or the whole unit is verified
    bq_need = function(key_or_unit) {
      keys <- if (key_or_unit %in% c("schedule", "prep", "commitments", "diet", "exercise", "events", "funding", "gantt_tasks",
                                     "gantt_contacts", "contacts", "communications", "muscle")) key_or_unit else self$bq_unit_tables(key_or_unit)
      invisible(self$bq_ensure_keys(keys, self$bq_unit_label(self$bq_unit_of_key(key_or_unit) %||% key_or_unit)))
    },
    # finds which app tables a SQL text mentions and ensures their units (safety net for direct queries)
    bq_need_for_query = function(query) {
      for (k in c("schedule", "prep", "commitments", "diet", "exercise", "events", "funding", "gantt_tasks", "gantt_contacts", "contacts", "communications")) {
        tn <- self[[paste0("bq_table_", k)]]
        if (!is.null(tn) && grepl(sprintf("%s`", tn), query, fixed = TRUE)) self$bq_need(k)
      }
      invisible(TRUE)
    },
    # status notes for the sidebar (plain list; the sidebar polls and the click handler also pushes updates)
    bq_note_status = function(unit, state, detail = "") {
      self$bq_unit_status[[unit]] <- list(label = self$bq_unit_label(unit), state = state, detail = detail, at = Sys.time())
      invisible(NULL)
    },

    # Compares city_events' ACTUAL columns (queried from
    # INFORMATION_SCHEMA.COLUMNS) against the columns this app's
    # bq_insert_events() needs to write. Returns NULL if fully compatible,
    # or a character string describing what's missing if not. Never raises
    # an error itself - incompatibility is reported, not blocked, since the
    # table may intentionally have a different but still-writable shape.
    check_events_table_compatibility = function(schema_cols = NULL) {
      required_cols <- c("id", "created_at", "event_name", "organiser", "city", "country",
                         "category", "subcategory", "event_date", "event_time", "venue_name",
                         "address", "latitude", "longitude", "description", "ticket_url",
                         "price_range", "source_url", "scan_date", "extra_info")

      result <- tryCatch({
        if (!is.null(schema_cols) && any(schema_cols$table_name == self$bq_table_events))
          return_cols <- schema_cols[schema_cols$table_name == self$bq_table_events, "column_name", drop = FALSE]
        else return_cols <- NULL
        if (!is.null(return_cols)) return_cols else {
        query <- sprintf(
          "SELECT column_name FROM `%s.%s.INFORMATION_SCHEMA.COLUMNS` WHERE table_name = '%s'",
          self$bq_project_id, self$bq_dataset_id, self$bq_table_events
        )
        job <- bq_project_query(self$bq_project_id, query)
        bq_table_download(job)
        }
      }, error = function(e) {
        cat("⚠️  [check_events_table_compatibility] Could not read INFORMATION_SCHEMA:", e$message, "\n")
        NULL
      })

      if (is.null(result) || nrow(result) == 0) {
        return("Could not verify city_events' actual schema (INFORMATION_SCHEMA query failed or returned no columns).")
      }

      actual_cols <- result$column_name
      missing <- setdiff(required_cols, actual_cols)

      if (length(missing) == 0) {
        cat("✓ [BigQuery] city_events schema compatibility check passed\n")
        return(NULL)
      }

      warning_msg <- paste0(
        "city_events is missing ", length(missing), " column(s) this app expects: ",
        paste(missing, collapse = ", "),
        ". Uploads that use those columns will fail until the table is updated to include them."
      )
      cat("⚠️  [BigQuery] ", warning_msg, "\n")
      warning_msg
    },

    # ============================================================
    # MUSCLE PROGRAMME (new tables: muscle_programmes / _diagrams / _set_log / _targets)
    # ============================================================
    bq_muscle_full = function(key) paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", MUSCLE_TABLES[[key]]),

    # creates any missing muscle_* table (checked once per connection, on demand: only when a Muscle tab is used)
    bq_muscle_ensure = function(label = "Muscle Programme") {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      k <- paste(self$bq_project_id, self$bq_dataset_id, sep = "|")
      if (identical(self$muscle_tables_key, k)) return(invisible(TRUE))
      t0 <- Sys.time(); self$bq_note_status(label, "checking", "checking 4 table(s)...")
      tryCatch({
        have <- tryCatch(unique(bq_table_download(bq_project_query(self$bq_project_id, sprintf(
          "SELECT table_name FROM `%s.%s.INFORMATION_SCHEMA.TABLES` WHERE table_name IN (%s)", self$bq_project_id, self$bq_dataset_id,
          paste0("'", unname(MUSCLE_TABLES), "'", collapse = ","))))$table_name), error = function(e) character())
        for (key in names(MUSCLE_TABLES)) {
          if (MUSCLE_TABLES[[key]] %in% have) next
          cat("[Muscle] creating table", self$bq_muscle_full(key), "\n")
          bq_project_query(self$bq_project_id, muscle_ddl(self$bq_muscle_full(key), MUSCLE_SCHEMAS[[key]]))
        }
        self$muscle_tables_key <- k; self$bq_keys_ready[["muscle"]] <- TRUE; self$bq_units_ready[["muscle"]] <- TRUE
        self$bq_note_status(label, "ready", sprintf("4 table(s) ready in %.1f s", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
      }, error = function(e) { self$bq_note_status(label, "failed", conditionMessage(e)); stop(e) })
      invisible(TRUE)
    },

    bq_muscle_read = function(key, force = FALSE) {
      if (!self$bq_authenticated) return(muscle_empty(key))
      ck <- paste(self$bq_project_id, self$bq_dataset_id, key, sep = "|")
      if (!force && !is.null(self$muscle_cache[[ck]])) return(self$muscle_cache[[ck]])
      self$bq_muscle_ensure()
      df <- self$bq_query(sprintf("SELECT * FROM `%s` ORDER BY id", self$bq_muscle_full(key)))
      cat(sprintf("[Muscle] read %d row(s) from %s\n", nrow(df), MUSCLE_TABLES[[key]]))
      self$muscle_cache[[ck]] <- df
      df
    },

    bq_muscle_insert = function(key, df) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      if (!nrow(df)) return(0L)
      self$bq_muscle_ensure()
      start_id <- tryCatch(as.integer(self$bq_query(sprintf("SELECT COALESCE(MAX(id), 0) AS m FROM `%s`", self$bq_muscle_full(key)))$m) + 1L,
                           error = function(e) 1L)
      df$id <- seq(start_id, length.out = nrow(df)); df$created_at <- Sys.time()
      df <- muscle_conform(df, MUSCLE_SCHEMAS[[key]])
      bq_table_upload(bq_table(self$bq_project_id, self$bq_dataset_id, MUSCLE_TABLES[[key]]), df,
                      create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")
      cat(sprintf("[Muscle] inserted %d row(s) -> %s\n", nrow(df), self$bq_muscle_full(key)))
      self$muscle_cache <- new.env(parent = emptyenv())
      invisible(nrow(df))
    },

    # removes rows whose `col` is in `values` (used to replace a regenerated programme day)
    bq_muscle_delete = function(key, col, values) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      values <- unique(as.character(values)); if (!length(values)) return(invisible(0L))
      self$bq_muscle_ensure()
      lit <- paste0("'", gsub("'", "\\\\'", values), "'", collapse = ",")
      bq_project_query(self$bq_project_id, sprintf("DELETE FROM `%s` WHERE %s IN (%s)", self$bq_muscle_full(key), col, lit))
      self$muscle_cache <- new.env(parent = emptyenv())
      invisible(length(values))
    },
    muscle_changed = function() self$muscle_tick(shiny::isolate(self$muscle_tick()) + 1L),

    bq_query = function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      self$bq_need_for_query(query)      # make sure the tab group that owns the queried table is verified
      job <- bq_project_query(self$bq_project_id, query)
      bq_table_download(job)
    },

    # ============================================================
    # DAY PLANNER
    # ============================================================
    empty_schedule_taxonomy = function() {
      data.frame(day_type = character(), country = character(), city = character(),
                stringsAsFactors = FALSE)
    },

    bq_get_schedule_taxonomy = function() {
      if (isTRUE(self$bq_authenticated)) self$bq_need("schedule")
      if (!is.null(self$schedule_taxonomy_cache)) return(self$schedule_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_schedule_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf(
          "SELECT DISTINCT day_type, country, city FROM `%s` ORDER BY day_type, country, city",
          self$bq_full_table_schedule
        ))
      }, error = function(e) {
        cat("⚠️  [bq_get_schedule_taxonomy] Query failed:", e$message, "\n")
        self$empty_schedule_taxonomy()
      })

      self$schedule_taxonomy_cache <- result
      result
    },

    # ── Time zone column (itineraries/schedules/events/deadlines) ────────
    # ALTER TABLE ... ADD COLUMN IF NOT EXISTS only ever ADDS a nullable
    # column: existing rows and tables are never altered, dropped or rewritten
    # (old rows simply have NULL, which the app reads as the default zone).
    bq_ensure_time_zone_column = function(key) {
      full <- switch(key,
        schedule = self$bq_full_table_schedule, diet = self$bq_full_table_diet,
        exercise = self$bq_full_table_exercise, events = self$bq_full_table_events,
        funding = self$bq_full_table_funding, gantt_tasks = self$bq_full_table_gantt_tasks, NULL)
      if (is.null(full)) return(invisible(FALSE))
      ok <- tryCatch({
        bq_project_query(self$bq_project_id, sprintf("ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS time_zone STRING", full))
        TRUE
      }, error = function(e) {
        # no permission to alter? the column may already exist - check by reading it
        tryCatch({
          bq_project_query(self$bq_project_id, sprintf("SELECT time_zone FROM `%s` LIMIT 0", full))
          TRUE
        }, error = function(e2) {
          cat("\u26a0\ufe0f  [BigQuery] could not add time_zone to", key, "-", e$message, "\n")
          FALSE
        })
      })
      self$bq_time_zone_ready[[key]] <- isTRUE(ok)
      if (isTRUE(ok)) cat("\u2713 [BigQuery]", key, "time_zone column ready\n")
      invisible(isTRUE(ok))
    },

    # Adds the time_zone column to an upload only when the table is known to
    # have it, so a failed ALTER can never break saving.
    bq_attach_time_zone = function(data_frame, tz_vec, key) {
      self$bq_need(key)
      if (isTRUE(self$bq_time_zone_ready[[key]])) data_frame$time_zone <- tz_vec
      data_frame
    },

    # ============================================================
    # DAY PLANNER
    # ============================================================
    bq_insert_schedule = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("schedule")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "schedule_date", "day_type", "country", "city",
                        "trip_details", "row_type", "row_sequence",
                        "location_name", "location_details", "opening_hours",
                        "recommended_time", "observations")

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_schedule)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      tz_vec <- bos_tz_vector(data_frame$time_zone, nrow(data_frame))   # zone saved with each row
      data_frame <- data_frame[, required_cols]
      data_frame <- self$bq_attach_time_zone(data_frame, tz_vec, "schedule")

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_schedule)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_schedule, "\n")
      return(nrow(data_frame))
    },

    # ── Day Planner: prep-steps checklist methods ───────────────────────
    empty_prep_taxonomy = function() {
      data.frame(category = character(), location = character(), stringsAsFactors = FALSE)
    },

    bq_get_prep_taxonomy = function() {
      if (isTRUE(self$bq_authenticated)) self$bq_need("prep")
      if (!is.null(self$prep_taxonomy_cache)) return(self$prep_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_prep_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf(
          "SELECT DISTINCT category, location FROM `%s` ORDER BY category, location",
          self$bq_full_table_prep
        ))
      }, error = function(e) {
        cat("⚠️  [bq_get_prep_taxonomy] Query failed:", e$message, "\n")
        self$empty_prep_taxonomy()
      })

      self$prep_taxonomy_cache <- result
      result
    },

    # Bulk-inserts one full generated batch of steps (WRITE_APPEND, like
    # every other suite). Regenerating for the same date does NOT overwrite
    # in place - call bq_delete_prep_steps_for_date() first if you want the
    # "replace this day's steps" behavior the source app used.
    bq_insert_prep_steps = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("prep")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "schedule_date", "category", "location",
                        "additional_context", "step_sequence", "step_text", "is_completed")

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_prep)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      if (!"is_completed" %in% names(data_frame)) data_frame$is_completed <- FALSE
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_prep)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_prep, "\n")
      self$trigger_state_update_schedule()
      return(nrow(data_frame))
    },

    bq_get_prep_steps_for_date = function(schedule_date) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("prep")
      if (!self$bq_authenticated) return(data.frame())
      tryCatch({
        self$bq_query(sprintf(
          "SELECT * FROM `%s` WHERE schedule_date = '%s' ORDER BY step_sequence",
          self$bq_full_table_prep, safe_sql_escape(schedule_date)
        ))
      }, error = function(e) { cat("⚠️  [bq_get_prep_steps_for_date] Query failed:", e$message, "\n"); data.frame() })
    },

    # Genuine UPDATE - is_completed is toggled live from a checkbox, the
    # same deliberate exception class as Contact Manager's bq_update_contact.
    bq_update_prep_completion = function(step_id, is_completed) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("prep")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      query <- sprintf("UPDATE `%s` SET is_completed = %s WHERE id = %d",
                       self$bq_full_table_prep, if (isTRUE(is_completed)) "TRUE" else "FALSE", as.integer(step_id))
      bq_project_query(self$bq_project_id, query)
      cat("✅ [BigQuery] Updated prep step", step_id, "-> is_completed =", is_completed, "\n")
      TRUE
    },

    # Genuine DELETE, used only when the person explicitly regenerates
    # steps for a date they've already saved (mirrors the source app's
    # "delete existing steps for this day before saving new ones").
    bq_delete_prep_steps_for_date = function(schedule_date) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("prep")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      query <- sprintf("DELETE FROM `%s` WHERE schedule_date = '%s'",
                       self$bq_full_table_prep, safe_sql_escape(schedule_date))
      bq_project_query(self$bq_project_id, query)
      cat("✅ [BigQuery] Deleted existing prep steps for", schedule_date, "\n")
      self$trigger_state_update_schedule()
      TRUE
    },

    # ── Day Planner Commitments: Trello (local to this feature - see the
    #    field-declaration comment above for why it's separate from Gantt's
    #    own Trello connection). Mirrors Gantt's Trello methods exactly. ──
    set_commitment_trello_credentials = function(key, token, board_id = NULL) {
      self$commitment_trello_key <- key
      self$commitment_trello_token <- token
      self$commitment_trello_board_id <- board_id
    },

    test_commitment_trello_connection = function() {
      if (is.null(self$commitment_trello_key) || is.null(self$commitment_trello_token)) stop("Trello API key/token not set")
      tryCatch({
        response <- GET(
          url = "https://api.trello.com/1/members/me",
          query = list(key = self$commitment_trello_key, token = self$commitment_trello_token)
        )
        if (status_code(response) == 200) {
          self$commitment_trello_authenticated <- TRUE
          return(TRUE)
        } else {
          stop(sprintf("Trello returned status %d", status_code(response)))
        }
      }, error = function(e) {
        self$commitment_trello_authenticated <- FALSE
        stop(paste("Trello connection failed:", e$message))
      })
    },

    get_commitment_trello_lists = function() {
      if (!self$commitment_trello_authenticated) stop("Not authenticated to Trello")
      if (is.null(self$commitment_trello_board_id) || nchar(self$commitment_trello_board_id) == 0) stop("Board ID not set")
      response <- GET(
        url = sprintf("https://api.trello.com/1/boards/%s/lists", self$commitment_trello_board_id),
        query = list(key = self$commitment_trello_key, token = self$commitment_trello_token)
      )
      if (status_code(response) != 200) stop(sprintf("Failed to fetch lists (status %d)", status_code(response)))
      content(response, "parsed")
    },

    create_commitment_trello_card = function(list_id, name, description) {
      if (!self$commitment_trello_authenticated) stop("Not authenticated to Trello")
      response <- POST(
        url = "https://api.trello.com/1/cards",
        query = list(key = self$commitment_trello_key, token = self$commitment_trello_token,
                    idList = list_id, name = name, desc = description)
      )
      if (status_code(response) == 200) {
        card <- content(response, "parsed")
        return(list(success = TRUE, id = card$id, url = card$shortUrl))
      }
      list(success = FALSE, error = sprintf("Status %d", status_code(response)))
    },

    # ── Day Planner Commitments: BigQuery CRUD ──────────────────────────
    empty_commitments_taxonomy = function() {
      data.frame(category = character(), sector = character(), topic = character(), stringsAsFactors = FALSE)
    },

    bq_get_commitments_taxonomy = function() {
      if (isTRUE(self$bq_authenticated)) self$bq_need("commitments")
      if (!is.null(self$commitments_taxonomy_cache)) return(self$commitments_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_commitments_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf(
          "SELECT DISTINCT category, sector, topic FROM `%s` ORDER BY category, sector, topic",
          self$bq_full_table_commitments
        ))
      }, error = function(e) {
        cat("⚠️  [bq_get_commitments_taxonomy] Query failed:", e$message, "\n")
        self$empty_commitments_taxonomy()
      })

      self$commitments_taxonomy_cache <- result
      result
    },

    bq_insert_commitment = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("commitments")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "category", "sector", "topic",
                        "commitment_date", "deadline", "status", "description", "stakeholders",
                        "value_of_delivery", "consequences_of_failure", "trello_card_id", "trello_card_url")

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_commitments)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- start_id
      data_frame$created_at <- Sys.time()
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_commitments)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted commitment id", start_id, "→", self$bq_full_table_commitments, "\n")
      self$trigger_state_update_schedule()
      return(start_id)
    },

    bq_get_commitments = function(limit = 500) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("commitments")
      if (!self$bq_authenticated) return(data.frame())
      tryCatch({
        self$bq_query(sprintf("SELECT * FROM `%s` ORDER BY deadline ASC LIMIT %d", self$bq_full_table_commitments, limit))
      }, error = function(e) { cat("⚠️  [bq_get_commitments] Query failed:", e$message, "\n"); data.frame() })
    },

    bq_get_commitment_by_id = function(commitment_id) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("commitments")
      if (!self$bq_authenticated) return(data.frame())
      tryCatch({
        self$bq_query(sprintf("SELECT * FROM `%s` WHERE id = %d", self$bq_full_table_commitments, as.integer(commitment_id)))
      }, error = function(e) { cat("⚠️  [bq_get_commitment_by_id] Query failed:", e$message, "\n"); data.frame() })
    },

    # Genuine UPDATE - status and Trello linkage change after creation (see
    # CREATE TABLE comment above). `updates` is a named list of columns to
    # set; only those columns are touched.
    bq_update_commitment = function(commitment_id, updates) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("commitments")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      if (length(updates) == 0) stop("No fields to update")

      set_clauses <- sapply(names(updates), function(col) {
        sprintf("%s = '%s'", col, safe_sql_escape(as.character(updates[[col]])))
      })

      query <- sprintf("UPDATE `%s` SET %s WHERE id = %d",
                       self$bq_full_table_commitments, paste(set_clauses, collapse = ", "), as.integer(commitment_id))
      bq_project_query(self$bq_project_id, query)
      cat("✅ [BigQuery] Updated commitment", commitment_id, "\n")
      self$trigger_state_update_schedule()
      TRUE
    },

    # ============================================================
    # DIET PLANNER
    # ============================================================
    empty_diet_taxonomy = function() {
      data.frame(diet_type = character(), stringsAsFactors = FALSE)
    },

    bq_get_diet_taxonomy = function() {
      if (isTRUE(self$bq_authenticated)) self$bq_need("diet")
      if (!is.null(self$diet_taxonomy_cache)) return(self$diet_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_diet_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf(
          "SELECT DISTINCT diet_type FROM `%s` ORDER BY diet_type",
          self$bq_full_table_diet
        ))
      }, error = function(e) {
        cat("⚠️  [bq_get_diet_taxonomy] Query failed:", e$message, "\n")
        self$empty_diet_taxonomy()
      })

      self$diet_taxonomy_cache <- result
      result
    },

    bq_insert_diet = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("diet")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "log_date", "diet_type", "dietary_restrictions",
                        "row_type", "row_sequence",
                        "meal_name", "meal_details", "meal_time",
                        "calories_macros", "observations")

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_diet)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      tz_vec <- bos_tz_vector(data_frame$time_zone, nrow(data_frame))   # zone saved with each row
      data_frame <- data_frame[, required_cols]
      data_frame <- self$bq_attach_time_zone(data_frame, tz_vec, "diet")

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_diet)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_diet, "\n")
      return(nrow(data_frame))
    },

    # ============================================================
    # EXERCISE TRACKER
    # ============================================================
    empty_exercise_taxonomy = function() {
      data.frame(session_type = character(), exercise_category = character(),
                exercise_name = character(), stringsAsFactors = FALSE)
    },

    bq_get_exercise_taxonomy = function() {
      if (isTRUE(self$bq_authenticated)) self$bq_need("exercise")
      if (!is.null(self$exercise_taxonomy_cache)) return(self$exercise_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_exercise_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf(
          "SELECT DISTINCT session_type, exercise_category, exercise_name FROM `%s`
           ORDER BY session_type, exercise_category, exercise_name",
          self$bq_full_table_exercise
        ))
      }, error = function(e) {
        cat("⚠️  [bq_get_exercise_taxonomy] Query failed:", e$message, "\n")
        self$empty_exercise_taxonomy()
      })

      self$exercise_taxonomy_cache <- result
      result
    },

    bq_insert_exercise = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("exercise")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "workout_date", "session_type", "session_notes",
                        "row_type", "row_sequence",
                        "exercise_category", "exercise_name", "exercise_details",
                        "metric_primary", "metric_secondary", "calories_burned", "observations")

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_exercise)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      tz_vec <- bos_tz_vector(data_frame$time_zone, nrow(data_frame))   # zone saved with each row
      data_frame <- data_frame[, required_cols]
      data_frame <- self$bq_attach_time_zone(data_frame, tz_vec, "exercise")

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_exercise)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_exercise, "\n")
      return(nrow(data_frame))
    },

    # ============================================================
    # EVENTS SCHEDULING
    # ============================================================
    empty_events_taxonomy = function() {
      data.frame(category = character(), subcategory = character(),
                city = character(), country = character(), scan_date = character(),
                stringsAsFactors = FALSE)
    },

    bq_get_events_taxonomy = function() {
      if (isTRUE(self$bq_authenticated)) self$bq_need("events")
      if (!is.null(self$events_taxonomy_cache)) return(self$events_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_events_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf(
          "SELECT DISTINCT category, subcategory, city, country, scan_date
           FROM `%s` ORDER BY scan_date DESC, category, subcategory",
          self$bq_full_table_events
        ))
      }, error = function(e) {
        cat("⚠️  [bq_get_events_taxonomy] Query failed:", e$message, "\n")
        self$empty_events_taxonomy()
      })

      self$events_taxonomy_cache <- result
      result
    },

    bq_insert_events = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("events")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "event_name", "organiser",
                         "city", "country", "category", "subcategory",
                         "event_date", "event_time", "venue_name", "address",
                         "latitude", "longitude", "description",
                         "ticket_url", "price_range", "source_url",
                         "scan_date", "extra_info")

      missing_cols <- setdiff(required_cols, names(data_frame))
      for (col in missing_cols) data_frame[[col]] <- ""

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_events)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      tz_vec <- bos_tz_vector(data_frame$time_zone, nrow(data_frame))   # zone saved with each row
      data_frame <- data_frame[, required_cols]
      data_frame <- self$bq_attach_time_zone(data_frame, tz_vec, "events")

      # Standardised on bq_table_upload() (same mechanism as Day Planner and
      # Funding Programmes) instead of the standalone app's DBI::dbWriteTable().
      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_events)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_events, "\n")
      return(nrow(data_frame))
    },

    # ============================================================
    # FUNDING PROGRAMMES
    # ============================================================
    empty_funding_taxonomy = function() {
      data.frame(category = character(), country = character(),
                city_region = character(), stringsAsFactors = FALSE)
    },

    bq_get_funding_taxonomy = function() {
      if (isTRUE(self$bq_authenticated)) self$bq_need("funding")
      if (!is.null(self$funding_taxonomy_cache)) return(self$funding_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_funding_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf(
          "SELECT DISTINCT category, country, city_region FROM `%s` ORDER BY category, country, city_region",
          self$bq_full_table_funding
        ))
      }, error = function(e) {
        cat("⚠️  [bq_get_funding_taxonomy] Query failed:", e$message, "\n")
        self$empty_funding_taxonomy()
      })

      self$funding_taxonomy_cache <- result
      result
    },

    bq_insert_funding = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("funding")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "category", "country", "city_region",
                        "programme_name", "amount_of_money", "conditions", "key_sponsors",
                        "key_organiser_profiles", "areas_of_application",
                        "start_date_for_applying", "deadline",
                        "recommendations_for_applying", "verified_urls")

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_funding)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      tz_vec <- bos_tz_vector(data_frame$time_zone, nrow(data_frame))   # zone saved with each row
      data_frame <- data_frame[, required_cols]
      data_frame <- self$bq_attach_time_zone(data_frame, tz_vec, "funding")

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_funding)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_funding, "\n")
      return(nrow(data_frame))
    },

    # ============================================================
    # GANTT TO TICKETS — Trello, Jira, SMTP (all local to this suite)
    # ============================================================
    set_trello_credentials = function(key, token, board_id = NULL) {
      self$trello_key <- key
      self$trello_token <- token
      self$trello_board_id <- board_id
    },

    test_trello_connection = function() {
      if (is.null(self$trello_key) || is.null(self$trello_token)) stop("Trello API key/token not set")
      tryCatch({
        response <- GET(
          url = "https://api.trello.com/1/members/me",
          query = list(key = self$trello_key, token = self$trello_token)
        )
        if (status_code(response) == 200) {
          self$trello_authenticated <- TRUE
          return(TRUE)
        } else {
          stop(sprintf("Trello returned status %d", status_code(response)))
        }
      }, error = function(e) {
        self$trello_authenticated <- FALSE
        stop(paste("Trello connection failed:", e$message))
      })
    },

    get_trello_lists = function() {
      if (!self$trello_authenticated) stop("Not authenticated to Trello")
      if (is.null(self$trello_board_id) || nchar(self$trello_board_id) == 0) stop("Board ID not set")
      response <- GET(
        url = sprintf("https://api.trello.com/1/boards/%s/lists", self$trello_board_id),
        query = list(key = self$trello_key, token = self$trello_token)
      )
      if (status_code(response) != 200) stop(sprintf("Failed to fetch lists (status %d)", status_code(response)))
      content(response, "parsed")
    },

    create_trello_card = function(list_id, name, description) {
      if (!self$trello_authenticated) stop("Not authenticated to Trello")
      response <- POST(
        url = "https://api.trello.com/1/cards",
        query = list(key = self$trello_key, token = self$trello_token,
                    idList = list_id, name = name, desc = description)
      )
      if (status_code(response) == 200) {
        card <- content(response, "parsed")
        return(list(success = TRUE, id = card$id, url = card$shortUrl))
      }
      list(success = FALSE, error = sprintf("Status %d", status_code(response)))
    },

    set_jira_credentials = function(url, email, token, project_key) {
      self$jira_url <- sub("/+$", "", url)
      self$jira_email <- email
      self$jira_token <- token
      self$jira_project_key <- project_key
    },

    test_jira_connection = function() {
      if (is.null(self$jira_url) || is.null(self$jira_email) || is.null(self$jira_token)) stop("Jira credentials not set")
      tryCatch({
        response <- GET(
          url = paste0(self$jira_url, "/rest/api/3/myself"),
          authenticate(self$jira_email, self$jira_token)
        )
        if (status_code(response) == 200) {
          self$jira_authenticated <- TRUE
          return(TRUE)
        } else {
          stop(sprintf("Jira returned status %d", status_code(response)))
        }
      }, error = function(e) {
        self$jira_authenticated <- FALSE
        stop(paste("Jira connection failed:", e$message))
      })
    },

    create_jira_issue = function(summary, description, issue_type = "Task", priority = NULL, labels = NULL) {
      if (!self$jira_authenticated) stop("Not authenticated to Jira")

      fields <- list(
        project = list(key = self$jira_project_key),
        summary = summary,
        description = list(
          type = "doc", version = 1,
          content = list(list(type = "paragraph",
                              content = list(list(type = "text", text = description %||% ""))))
        ),
        issuetype = list(name = issue_type)
      )
      if (!is.null(labels) && length(labels) > 0) fields$labels <- as.list(labels)

      response <- POST(
        url = paste0(self$jira_url, "/rest/api/3/issue"),
        authenticate(self$jira_email, self$jira_token),
        add_headers("Content-Type" = "application/json"),
        body = toJSON(list(fields = fields), auto_unbox = TRUE)
      )

      if (status_code(response) %in% c(200, 201)) {
        issue <- content(response, "parsed")
        list(success = TRUE, key = issue$key)
      } else {
        err <- tryCatch(content(response, "parsed"), error = function(e) NULL)
        list(success = FALSE, error = sprintf("Status %d: %s", status_code(response),
                                              jsonlite::toJSON(err %||% list(), auto_unbox = TRUE)))
      }
    },

    set_gantt_smtp_config = function(host, port, user, password) {
      self$gantt_smtp_host <- host; self$gantt_smtp_port <- port
      self$gantt_smtp_user <- user; self$gantt_smtp_password <- password
    },

    # Shared raw-SMTP-via-curl sender, used by both Gantt and Contact
    # Manager (each keeps its own separate credentials, but the mechanism
    # is identical and self-contained - no external mail package needed).
    send_email_via_curl = function(host, port, user, password, from, to, subject, body, cc = NULL, attachments = NULL) {
      boundary <- paste0("----=_Part_", as.integer(as.numeric(Sys.time()) * 1000))

      email_lines <- c(
        paste0("From: ", from),
        paste0("To: ", paste(to, collapse = ", ")),
        if (!is.null(cc) && length(cc) > 0) paste0("Cc: ", paste(cc, collapse = ", ")) else NULL,
        paste0("Subject: ", subject),
        "MIME-Version: 1.0"
      )

      if (!is.null(attachments) && length(attachments) > 0) {
        email_lines <- c(email_lines,
          paste0('Content-Type: multipart/mixed; boundary="', boundary, '"'), "",
          paste0("--", boundary), "Content-Type: text/plain; charset=UTF-8",
          "Content-Transfer-Encoding: 7bit", "", body, "")

        for (att in attachments) {
          if (file.exists(att$path)) {
            file_raw <- readBin(att$path, "raw", file.info(att$path)$size)
            file_b64 <- base64enc::base64encode(file_raw)
            ext <- tolower(tools::file_ext(att$name))
            content_type <- switch(ext, pdf = "application/pdf",
              docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
              xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              txt = "text/plain", csv = "text/csv", jpg = "image/jpeg", png = "image/png",
              "application/octet-stream")
            email_lines <- c(email_lines,
              paste0("--", boundary),
              paste0('Content-Type: ', content_type, '; name="', att$name, '"'),
              "Content-Transfer-Encoding: base64",
              paste0('Content-Disposition: attachment; filename="', att$name, '"'),
              "", file_b64, "")
          }
        }
        email_lines <- c(email_lines, paste0("--", boundary, "--"))
      } else {
        email_lines <- c(email_lines, "Content-Type: text/plain; charset=UTF-8", "", body)
      }

      email_file <- tempfile(fileext = ".eml")
      writeLines(email_lines, email_file, useBytes = TRUE)

      all_recipients <- c(to, cc)
      recipient_args <- paste(sprintf("--mail-rcpt '%s'", all_recipients), collapse = " ")
      protocol <- if (as.integer(port) == 465) "smtps" else "smtp"

      curl_cmd <- sprintf(
        "curl -s --%s://%s:%s --mail-from '%s' %s --upload-file '%s' --user '%s:%s' %s",
        protocol, host, port, user, recipient_args, email_file, user, password,
        if (protocol == "smtp") "--ssl-reqd" else ""
      )

      result <- system(curl_cmd, intern = TRUE, ignore.stderr = FALSE)
      unlink(email_file)
      status <- attr(result, "status") %||% 0
      if (!is.null(status) && status != 0) stop(paste("curl SMTP send failed:", paste(result, collapse = "\n")))
      TRUE
    },

    test_gantt_smtp_connection = function() {
      if (is.null(self$gantt_smtp_host) || is.null(self$gantt_smtp_user)) stop("SMTP not configured")
      tryCatch({
        protocol <- if (as.integer(self$gantt_smtp_port) == 465) "smtps" else "smtp"
        test_cmd <- sprintf("curl -s --%s://%s:%s --user '%s:%s' --mail-from '%s' --mail-rcpt '%s' -T /dev/null %s --max-time 15",
                            protocol, self$gantt_smtp_host, self$gantt_smtp_port,
                            self$gantt_smtp_user, self$gantt_smtp_password,
                            self$gantt_smtp_user, self$gantt_smtp_user,
                            if (protocol == "smtp") "--ssl-reqd" else "")
        system(test_cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
        self$gantt_smtp_authenticated <- TRUE
        TRUE
      }, error = function(e) {
        self$gantt_smtp_authenticated <- FALSE
        stop(paste("SMTP test failed:", e$message))
      })
    },

    # Append-only task log - one row per task per stage event (see
    # CREATE TABLE comment above for why this is log-style, not CRUD).
    bq_insert_gantt_tasks = function(data_frame, log_stage, upload_batch) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("gantt_tasks")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "upload_batch", "log_stage",
                        "task_name", "description", "start_date", "end_date",
                        "duration_days", "assignee", "priority", "status",
                        "labels", "additional_notes", "submission_result")

      data_frame$upload_batch <- upload_batch
      data_frame$log_stage <- log_stage
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_gantt_tasks)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      tz_vec <- bos_tz_vector(if (!is.null(data_frame$time_zone)) data_frame$time_zone else self$gantt_time_zone, nrow(data_frame))   # zone saved with each row
      data_frame <- data_frame[, required_cols]
      data_frame <- self$bq_attach_time_zone(data_frame, tz_vec, "gantt_tasks")

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_gantt_tasks)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_gantt_tasks, "\n")
      return(nrow(data_frame))
    },

    bq_get_gantt_tasks = function(limit = 500) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("gantt_tasks")
      if (!self$bq_authenticated) return(data.frame())
      tryCatch({
        self$bq_query(sprintf("SELECT * FROM `%s` ORDER BY created_at DESC LIMIT %d", self$bq_full_table_gantt_tasks, limit))
      }, error = function(e) { cat("⚠️  [bq_get_gantt_tasks] Query failed:", e$message, "\n"); data.frame() })
    },

    bq_insert_gantt_contact = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("gantt_contacts")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "country", "city", "organization",
                        "full_name", "linkedin", "email", "phone", "date_added")
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""

      start_id <- tryCatch({
        res <- bq_table_download(bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_gantt_contacts)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_gantt_contacts)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_gantt_contacts, "\n")
      return(nrow(data_frame))
    },

    bq_get_gantt_contacts = function(limit = 1000) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("gantt_contacts")
      if (!self$bq_authenticated) return(data.frame())
      tryCatch({
        self$bq_query(sprintf("SELECT * FROM `%s` ORDER BY created_at DESC LIMIT %d", self$bq_full_table_gantt_contacts, limit))
      }, error = function(e) { cat("⚠️  [bq_get_gantt_contacts] Query failed:", e$message, "\n"); data.frame() })
    },

    # ============================================================
    # CONTACT MANAGER — OpenAI (kept local, per instruction, distinct
    # from the app's shared Claude connection), SMTP, and BigQuery CRUD
    # ============================================================
    set_contacts_openai_credentials = function(api_key, model = NULL) {
      self$contacts_openai_key <- api_key
      if (!is.null(model)) self$contacts_gpt_model <- model
    },

    test_contacts_openai_connection = function() {
      if (is.null(self$contacts_openai_key)) stop("OpenAI API key not set")
      response <- POST(
        url = "https://api.openai.com/v1/chat/completions",
        add_headers("Authorization" = paste("Bearer", self$contacts_openai_key), "Content-Type" = "application/json"),
        body = toJSON(list(model = self$contacts_gpt_model,
                          messages = list(list(role = "user", content = "Hello")),
                          max_tokens = 5), auto_unbox = TRUE),
        encode = "json", httr::timeout(30)
      )
      if (status_code(response) == 200) {
        self$contacts_api_authenticated <- TRUE
        return(TRUE)
      }
      self$contacts_api_authenticated <- FALSE
      stop(sprintf("OpenAI API error: status %d", status_code(response)))
    },

    call_openai = function(prompt, system_message = NULL, max_tokens = 1000, temperature = 0.3) {
      if (!self$contacts_api_authenticated) stop("Not authenticated to OpenAI API")

      messages <- list()
      if (!is.null(system_message)) {
        messages[[1]] <- list(role = "system", content = system_message)
        messages[[2]] <- list(role = "user", content = prompt)
      } else {
        messages[[1]] <- list(role = "user", content = prompt)
      }

      response <- POST(
        url = "https://api.openai.com/v1/chat/completions",
        add_headers("Authorization" = paste("Bearer", self$contacts_openai_key), "Content-Type" = "application/json"),
        body = toJSON(list(model = self$contacts_gpt_model, messages = messages,
                          max_tokens = max_tokens, temperature = temperature), auto_unbox = TRUE),
        encode = "json", httr::timeout(120)
      )

      if (status_code(response) == 200) {
        content(response, "parsed")$choices[[1]]$message$content
      } else {
        stop(paste("OpenAI API Error: status", status_code(response)))
      }
    },

    set_contacts_smtp_config = function(host, port, user, password) {
      self$contacts_smtp_host <- host; self$contacts_smtp_port <- port
      self$contacts_smtp_user <- user; self$contacts_smtp_password <- password
    },

    test_contacts_smtp_connection = function() {
      if (is.null(self$contacts_smtp_host) || is.null(self$contacts_smtp_user)) stop("SMTP not configured")
      tryCatch({
        protocol <- if (as.integer(self$contacts_smtp_port) == 465) "smtps" else "smtp"
        test_cmd <- sprintf("curl -s --%s://%s:%s --user '%s:%s' --mail-from '%s' --mail-rcpt '%s' -T /dev/null %s --max-time 15",
                            protocol, self$contacts_smtp_host, self$contacts_smtp_port,
                            self$contacts_smtp_user, self$contacts_smtp_password,
                            self$contacts_smtp_user, self$contacts_smtp_user,
                            if (protocol == "smtp") "--ssl-reqd" else "")
        system(test_cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
        self$contacts_smtp_authenticated <- TRUE
        TRUE
      }, error = function(e) {
        self$contacts_smtp_authenticated <- FALSE
        stop(paste("SMTP test failed:", e$message))
      })
    },

    set_contacts_selected_contact = function(contact) {
      self$contacts_selected_contact <- contact
      email <- contact$email
      if (!is.null(email) && nchar(email) > 0 && !identical(email, "Not specified")) {
        self$contacts_selected_contact_email <- email
      } else {
        self$contacts_selected_contact_email <- NULL
      }
      self$trigger_state_update_contacts()
    },

    bq_insert_contact = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("contacts")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("contact_id", "full_name", "industry", "company", "job_title",
                        "location", "country", "email", "phone", "linkedin",
                        "areas_of_interest", "university", "academic_background",
                        "user_notes", "last_interaction_date", "created_at", "updated_at")
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      data_frame$created_at <- Sys.time()
      data_frame$updated_at <- Sys.time()
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_contacts)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_contacts, "\n")
      self$trigger_state_update_contacts()
      return(nrow(data_frame))
    },

    # Genuine UPDATE - contacts is the one mutable entity type in this app
    # (see CREATE TABLE comment above). Only updates the columns provided
    # in `updates` (a named list), always bumping updated_at.
    bq_update_contact = function(contact_id, updates) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("contacts")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      if (length(updates) == 0) stop("No fields to update")

      set_clauses <- sapply(names(updates), function(col) {
        sprintf("%s = '%s'", col, safe_sql_escape(as.character(updates[[col]])))
      })
      set_clauses <- c(set_clauses, "updated_at = CURRENT_TIMESTAMP()")

      query <- sprintf("UPDATE `%s` SET %s WHERE contact_id = '%s'",
                       self$bq_full_table_contacts, paste(set_clauses, collapse = ", "),
                       safe_sql_escape(contact_id))
      bq_project_query(self$bq_project_id, query)
      cat("✅ [BigQuery] Updated contact", contact_id, "\n")
      self$trigger_state_update_contacts()
      TRUE
    },

    # Genuine DELETE - see note on bq_update_contact above.
    bq_delete_contact = function(contact_id) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("contacts")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      query <- sprintf("DELETE FROM `%s` WHERE contact_id = '%s'",
                       self$bq_full_table_contacts, safe_sql_escape(contact_id))
      bq_project_query(self$bq_project_id, query)
      cat("✅ [BigQuery] Deleted contact", contact_id, "\n")
      self$trigger_state_update_contacts()
      TRUE
    },

    bq_get_contacts = function(limit = 2000) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("contacts")
      if (!self$bq_authenticated) return(data.frame())
      tryCatch({
        self$bq_query(sprintf("SELECT * FROM `%s` ORDER BY updated_at DESC LIMIT %d", self$bq_full_table_contacts, limit))
      }, error = function(e) { cat("⚠️  [bq_get_contacts] Query failed:", e$message, "\n"); data.frame() })
    },

    bq_insert_communication = function(data_frame) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("communications")
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("message_id", "contact_id", "channel_type", "communication_purpose",
                        "language", "message_length", "message_content", "created_at")
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      data_frame$created_at <- Sys.time()
      data_frame <- data_frame[, required_cols]

      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_communications)
      bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_communications, "\n")
      self$trigger_state_update_contacts()
      return(nrow(data_frame))
    },

    bq_get_recent_communications = function(contact_id, limit = 3) {
      if (isTRUE(self$bq_authenticated)) self$bq_need("communications")
      if (!self$bq_authenticated) return(data.frame())
      tryCatch({
        self$bq_query(sprintf(
          "SELECT * FROM `%s` WHERE contact_id = '%s' ORDER BY created_at DESC LIMIT %d",
          self$bq_full_table_communications, safe_sql_escape(contact_id), limit
        ))
      }, error = function(e) { cat("⚠️  [bq_get_recent_communications] Query failed:", e$message, "\n"); data.frame() })
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
