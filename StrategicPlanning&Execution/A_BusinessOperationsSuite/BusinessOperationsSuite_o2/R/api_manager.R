# R/api_manager.R
#
# One shared APIManager R6 instance is created per session (see global.R) and
# passed into every module's server function. It centralizes:
#   - Claude LLM config + call_claude()
#   - BigQuery connection + generic bq_query()/bq_execute() + per-suite table
#     helpers (contacts, communications, funding)
#   - SMTP connection state + send_email()
#
# Plus generic helpers (%||%, safe_sql_escape) and the Funding Programmes
# text-format parser/prompt-builder/taxonomy-cascade helpers (ported from
# utils_funding_common.R, unchanged apart from now reading BigQuery via the
# shared api_manager$bq_query() instead of their own connection).

# ---------------------------------------------------------------------------
# Generic helpers
# ---------------------------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x) || (length(x) == 1 && (x == "" || is.na(x)))) y else x

safe_sql_escape <- function(x) gsub("'", "''", x)

# ---- Gantt to Tickets suite helpers ----

safe_string <- function(x) if (is.null(x) || is.na(x)) "" else as.character(x)

parse_email <- function(assignee) {
  if (grepl("<.*@.*>", assignee)) return(gsub(".*<(.*)>.*", "\\1", assignee))
  assignee
}

is_valid_email <- function(email) grepl("@", email) && grepl("\\.", email)

replace_placeholders <- function(template, data_row) {
  result <- template
  for (col in names(data_row)) {
    placeholder <- paste0("{", col, "}")
    value <- ifelse(is.na(data_row[[col]]), "", as.character(data_row[[col]]))
    result <- gsub(placeholder, value, result, fixed = TRUE)
  }
  result
}

# ---- Project Application suite helpers ----

count_words <- function(text) {
  if (is.null(text) || nchar(trimws(text %||% "")) == 0) return(0)
  length(strsplit(trimws(text), "\\s+")[[1]])
}

format_word_count <- function(text, limit) {
  n <- count_words(text)
  paste("Words:", n, "/", limit, "| Remaining:", limit - n)
}

# Lightweight preview of an uploaded reference file - not sent to any LLM
# (neither diagram module actually forwards file contents to the API; this
# purely powers the "Select File" info box already present in both UIs).
preview_uploaded_file <- function(file_path, file_name) {
  ext <- tolower(tools::file_ext(file_name))
  size_kb <- round(file.info(file_path)$size / 1024, 1)
  if (ext %in% c("jpg", "jpeg", "png", "gif", "webp")) {
    sprintf("Image loaded: %s (%s KB)", file_name, size_kb)
  } else if (ext == "csv") {
    tryCatch({
      d <- read.csv(file_path)
      sprintf("CSV loaded: %s (%d rows x %d cols)", file_name, nrow(d), ncol(d))
    }, error = function(e) sprintf("CSV loaded: %s (could not preview: %s)", file_name, e$message))
  } else {
    sprintf("File loaded: %s (%s KB, %s)", file_name, size_kb, toupper(ext))
  }
}

create_status_ui <- function(success = TRUE, message = "") {
  if (success) div(class = "save-status-success", icon("check-circle"), message)
  else div(class = "save-status-error", icon("exclamation-circle"), message)
}

# ---- Audio Transcription suite helper ----
# Volume roots for shinyFiles-based native file/directory browsing. This
# suite is designed for local/desktop execution (see README) where the
# Shiny process has direct filesystem access matching the host OS.
get_volume_roots <- function() {
  if (.Platform$OS.type == "windows") {
    volumes <- c("C:" = "C:/", "D:" = "D:/", "E:" = "E:/", "Home" = fs::path_home())
    volumes <- volumes[sapply(volumes, dir.exists)]
  } else {
    volumes <- c(
      "Home" = fs::path_home(), "Root" = "/",
      "Documents" = path.expand("~/Documents"), "Desktop" = path.expand("~/Desktop"),
      "Downloads" = path.expand("~/Downloads")
    )
    volumes <- volumes[sapply(volumes, dir.exists)]
  }
  volumes
}

# ---- Receipt Processor suite helpers ----
# (get_folder_volumes is distinct from get_volume_roots above - it additionally
# merges shinyFiles::getVolumes()' auto-detected system volumes, as the source
# app did; kept separate rather than forcing both suites onto one function.)

encode_file <- function(file_path) {
  file_content <- readBin(file_path, "raw", file.info(file_path)$size)
  base64enc::base64encode(file_content)
}

get_media_type <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  if (ext %in% c("jpg", "jpeg")) "image/jpeg"
  else if (ext == "pdf") "application/pdf"
  else "image/jpeg"
}

create_safe_filename <- function(text, max_length = NULL) {
  safe_text <- gsub("[^a-zA-Z0-9 ]", "", text)
  safe_text <- gsub("\\s+", "_", safe_text)
  safe_text <- trimws(safe_text)
  if (!is.null(max_length) && nchar(safe_text) > max_length) safe_text <- substr(safe_text, 1, max_length)
  safe_text
}

create_renamed_filename <- function(provider, description, date, amount, original_ext) {
  provider_clean <- create_safe_filename(provider, max_length = 50)
  if (provider_clean == "" || provider_clean == "N_A") provider_clean <- "Unknown"

  desc_clean <- create_safe_filename(description, max_length = 40)
  if (desc_clean == "" || desc_clean == "N_A") desc_clean <- "NoDescription"

  date_formatted <- gsub("-", "", date)
  if (nchar(date_formatted) != 8 || date_formatted == "N_A") date_formatted <- format(Sys.Date(), "%Y%m%d")

  amount_formatted <- sprintf("%.2f", amount)

  paste0(provider_clean, "_", desc_clean, "_", date_formatted, "_", amount_formatted, original_ext)
}

get_folder_volumes <- function() {
  if (.Platform$OS.type == "windows") {
    volumes <- c("C:" = "C:/", "D:" = "D:/", "E:" = "E:/", Home = fs::path_home(), shinyFiles::getVolumes()())
  } else {
    volumes <- c(Root = "/", Home = fs::path_home(), shinyFiles::getVolumes()())
  }
  volumes
}

# ---- Visual Media suite helpers ----

cm_to_inches <- function(cm) cm / 2.54
inches_to_cm <- function(inches) inches * 2.54

calculate_width <- function(height, aspect_ratio, unit = "cm") {
  ratio_parts <- as.numeric(strsplit(aspect_ratio, ":")[[1]])
  width <- height * (ratio_parts[1] / ratio_parts[2])
  round(width, 2)
}

get_dalle_size <- function(aspect_ratio, model) {
  if (model == "dall-e-3") {
    size_map <- list("1:1" = "1024x1024", "4:3" = "1024x1024", "3:4" = "1024x1024",
                      "16:9" = "1792x1024", "9:16" = "1024x1792")
  } else {
    size_map <- list("1:1" = "1024x1024", "4:3" = "1024x1024", "3:4" = "1024x1024",
                      "16:9" = "1024x1024", "9:16" = "1024x1024")
  }
  size_map[[aspect_ratio]] %||% "1024x1024"
}

enhance_prompt <- function(description, style) {
  if (style == "art") {
    prefix <- "Create an artistic illustration of: "
    suffix <- ". Style: digital art, vibrant colors, creative composition, artistic interpretation."
  } else if (style == "photo") {
    prefix <- "Create a photorealistic photograph of: "
    suffix <- ". Style: high-resolution photography, natural lighting, sharp focus, professional quality."
  } else {
    prefix <- ""; suffix <- ""
  }
  paste0(prefix, description, suffix)
}

# Extracts up to n of the most dominant colors from an image as hex strings
# (used by the Image to PDF tab's page-gap-fill color picker).
get_top_colors <- function(file_path, n = 5) {
  tryCatch({
    img <- magick::image_read(file_path)
    if (length(img) > 1) img <- img[1]
    img <- magick::image_background(img, "white", flatten = TRUE)
    img_small <- magick::image_resize(img, "300x300>")
    img_quant <- magick::image_quantize(img_small, max = n, colorspace = "srgb")

    raster_mat <- grDevices::as.raster(img_quant)
    colors <- as.vector(raster_mat)
    color_counts <- sort(table(colors), decreasing = TRUE)

    if (length(color_counts) == 0) return(character(0))
    top_n <- min(n, length(color_counts))
    names(color_counts)[1:top_n]
  }, error = function(e) character(0))
}

# ---------------------------------------------------------------------------
# APIManager
# ---------------------------------------------------------------------------

APIManager <- R6::R6Class("APIManager",
  public = list(

    # ---- Claude -------------------------------------------------------
    claude_api_key = NULL,
    claude_model = "claude-sonnet-4-5",
    claude_authenticated = FALSE,

    # ---- OpenAI (Project Application suite only) -------------------------------------------------------
    openai_api_key = NULL,
    openai_model = "gpt-4",
    openai_authenticated = FALSE,

    # ---- BigQuery -------------------------------------------------------
    bq_project_id = "atera-2",
    bq_dataset_id = "business_strategy",
    bq_table_contacts = "business_contacts",
    bq_table_communications = "contact_communications",
    bq_table_funding = "funding_programmes",
    bq_table_bm_canvas = "business_model_canvas",
    bq_table_de_canvas = "disciplined_entrepreneurship_canvas",
    bq_table_de_roadmap = "disciplined_entrepreneurship_roadmap",
    bq_full_table_contacts = NULL,
    bq_full_table_communications = NULL,
    bq_full_table_funding = NULL,
    bq_full_table_bm_canvas = NULL,
    bq_full_table_de_canvas = NULL,
    bq_full_table_de_roadmap = NULL,
    bq_credentials_path = NULL,
    bq_authenticated = FALSE,

    # ---- SMTP (Communications suite) -------------------------------------------------------
    smtp_host = "smtpout.secureserver.net",
    smtp_port = "465",
    smtp_username = NULL,
    smtp_password = NULL,
    smtp_tested = FALSE,
    smtp_connected = FALSE,

    # ---- Trello / Jira / Gantt-SMTP (Gantt to Tickets suite) -------------------------------------------------------
    # NOTE: this suite has its OWN email plumbing (gantt_smtp_config / gantt_email_connected /
    # send_gantt_email(), blastula-based) deliberately kept separate from the smtp_* fields
    # above (curl-based, used by Communications) - same concept, different provider/shape,
    # so they must not share fields.
    trello_key = NULL,
    trello_token = NULL,
    trello_board_id = NULL,
    trello_connected = FALSE,

    jira_url = NULL,
    jira_email = NULL,
    jira_token = NULL,
    jira_project_key = NULL,
    jira_connected = FALSE,

    gantt_smtp_config = list(),
    gantt_email_connected = FALSE,

    gantt_data = NULL,                    # uploaded Gantt/task data.frame
    gantt_contacts_data = NULL,           # Country/City/Organization/Full_Name/LinkedIn/Email/Phone/Date_Added
    gantt_contacts_file = "contacts_database.xlsx",
    state_trigger_gantt = NULL,           # reactiveVal(0) - review_edit/email_send/manage_contacts/email_contacts depend on this

    # ---- Whisper / ChatGPT (Audio Transcription suite) -------------------------------------------------------
    # NOTE: kept separate from api_manager$openai_api_key (Project Application) and from
    # each other, matching this suite's own source design - a user may reasonably want a
    # different/restricted-scope key for audio transcription vs. text analysis vs. other suites.
    whisper_api_key = "",
    whisper_model = "whisper-1",
    whisper_language = "",
    chatgpt_api_key = "",
    chatgpt_model = "gpt-4o-mini",
    transcriptions = NULL,                 # data.frame log: timestamp/filename/word_count/processing_time/file_size
    state_trigger_audio = NULL,            # reactiveVal(0) - Analytics Dashboard depends on this

    # ---- Receipt Processor (OpenAI Vision) -------------------------------------------------------
    # NOTE: kept separate from openai_api_key/whisper_api_key/chatgpt_api_key for the same reason
    # as the other suites - a user may reasonably use a different/restricted key here.
    receipt_api_key = "",
    receipt_folder = "receipts",
    receipt_excel_filename = "receipt_data.xlsx",

    # ---- Visual Media (DALL-E image generation + ChatGPT text enrichment) -------------------------------------------------------
    # Uses the SAME shared api_manager$openai_api_key / call_openai() as
    # Project Application (per explicit user decision) - no separate key here.
    generated_images = NULL,               # data.frame log: timestamp/prompt/model/size/filepath
    pending_prompt_visual_media = NULL,     # reactiveVal("") - Image Generation -> Further Context handoff

    # ---- Shared reactive state -------------------------------------------------------
    state_trigger_contacts = NULL,   # reactiveVal(0) - Explore Contacts / Customise Comm depend on this
    state_trigger_funding = NULL,    # reactiveVal(0) - Funding taxonomy dropdowns depend on this
    state_trigger_canvas = NULL,     # reactiveVal(0) - Strategy Canvases taxonomy dropdowns depend on this
    pending_bulk_text_funding = NULL,# reactiveVal("") - Generate Programme -> Bulk Import handoff

    selected_contact = NULL,         # reactiveVal(NULL) - shared between Explore Contacts & Customise Comm
    selected_contact_email = NULL,   # reactiveVal(NULL)
    recent_messages = NULL,          # reactiveVal(NULL)
    communication_summary = NULL,    # reactiveVal(NULL)
    generated_message = NULL,        # reactiveVal(NULL)
    pending_email_subject = NULL,    # reactiveVal("") - Customise Comm -> Send Email handoff

    contacts_cache = NULL,           # plain data.frame cache (not reactive - modules wrap in reactiveVal via trigger)
    communications_cache = NULL,
    funding_taxonomy_cache = NULL,
    canvas_taxonomy_cache = NULL,    # distinct business_area/project/business_focus from the BM Canvas table

    initialize = function() {
      self$state_trigger_contacts <- shiny::reactiveVal(0)
      self$state_trigger_funding <- shiny::reactiveVal(0)
      self$state_trigger_canvas <- shiny::reactiveVal(0)
      self$state_trigger_gantt <- shiny::reactiveVal(0)
      self$state_trigger_audio <- shiny::reactiveVal(0)
      self$pending_bulk_text_funding <- shiny::reactiveVal("")

      self$selected_contact <- shiny::reactiveVal(NULL)
      self$selected_contact_email <- shiny::reactiveVal(NULL)
      self$recent_messages <- shiny::reactiveVal(NULL)
      self$communication_summary <- shiny::reactiveVal(NULL)
      self$generated_message <- shiny::reactiveVal(NULL)
      self$pending_email_subject <- shiny::reactiveVal("")

      self$recompute_full_table_ids()
      self$gantt_contacts_data <- self$empty_gantt_contacts_df()
      if (file.exists(self$gantt_contacts_file)) {
        tryCatch({
          self$gantt_contacts_data <- readxl::read_excel(self$gantt_contacts_file)
        }, error = function(e) NULL)
      }
      self$transcriptions <- self$empty_transcriptions_df()
      self$init_receipt_storage()
      self$generated_images <- self$empty_generated_images_df()
      self$pending_prompt_visual_media <- shiny::reactiveVal("")
      invisible(self)
    },

    recompute_full_table_ids = function() {
      self$bq_full_table_contacts <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_contacts)
      self$bq_full_table_communications <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_communications)
      self$bq_full_table_funding <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_funding)
      self$bq_full_table_bm_canvas <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_bm_canvas)
      self$bq_full_table_de_canvas <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_de_canvas)
      self$bq_full_table_de_roadmap <- paste0(self$bq_project_id, ".", self$bq_dataset_id, ".", self$bq_table_de_roadmap)
    },

    # =====================================================================
    # CLAUDE
    # =====================================================================

    save_claude_config = function(api_key, model) {
      self$claude_api_key <- trimws(api_key)
      self$claude_model <- trimws(model)
      self$claude_authenticated <- nchar(self$claude_api_key) > 0
      invisible(self$claude_authenticated)
    },

    # Returns list(text=, stop_reason=, truncated=). Modules pass an optional
    # progress_callback(msg) for a live status line during long calls.
    call_claude = function(prompt, progress_callback = NULL, max_tokens = 3000, system = NULL) {
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0) {
        stop("Claude API key not configured - set it in API Settings > Claude API Config")
      }
      if (!is.null(progress_callback)) progress_callback("Contacting Claude API...")

      body_list <- list(
        model = self$claude_model,
        max_tokens = max_tokens,
        messages = list(list(role = "user", content = prompt))
      )
      if (!is.null(system)) body_list$system <- system

      response <- httr::POST(
        url = "https://api.anthropic.com/v1/messages",
        httr::add_headers(
          "x-api-key" = self$claude_api_key,
          "anthropic-version" = "2023-06-01",
          "content-type" = "application/json"
        ),
        body = jsonlite::toJSON(body_list, auto_unbox = TRUE),
        encode = "json",
        httr::timeout(120)
      )

      status <- httr::status_code(response)
      if (status != 200) {
        body_txt <- tryCatch(httr::content(response, "text", encoding = "UTF-8"), error = function(e) "")
        stop(sprintf("Claude API error %s: %s", status, substr(body_txt, 1, 300)))
      }

      if (!is.null(progress_callback)) progress_callback("Processing response...")

      parsed <- httr::content(response, "parsed")
      text <- paste(vapply(parsed$content, function(block) block$text %||% "", character(1)), collapse = "")

      list(
        text = text,
        stop_reason = parsed$stop_reason %||% NA,
        truncated = identical(parsed$stop_reason, "max_tokens")
      )
    },

    test_claude = function() {
      self$call_claude("Reply with exactly these three words: Claude connection OK", max_tokens = 20)
    },

    # =====================================================================
    # OPENAI (used only by the Project Application suite - diagram_generator
    # and the AI-generation buttons in project_details/business_case/team_impact)
    # =====================================================================

    save_openai_config = function(api_key) {
      self$openai_api_key <- trimws(api_key)
      self$openai_authenticated <- nchar(self$openai_api_key) > 0
      invisible(self$openai_authenticated)
    },

    # Same contract as call_claude(): throws on failure, returns list(text=, stop_reason=, truncated=)
    call_openai = function(prompt, progress_callback = NULL, max_tokens = 1000, system = NULL) {
      if (is.null(self$openai_api_key) || nchar(self$openai_api_key) == 0) {
        stop("OpenAI API key not configured - set it in Project Application > OpenAI API Config")
      }
      if (!is.null(progress_callback)) progress_callback("Contacting OpenAI API...")

      messages <- list()
      if (!is.null(system)) messages <- c(messages, list(list(role = "system", content = system)))
      messages <- c(messages, list(list(role = "user", content = prompt)))

      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers("Authorization" = paste("Bearer", self$openai_api_key), "Content-Type" = "application/json"),
        body = jsonlite::toJSON(list(
          model = self$openai_model,
          messages = messages,
          max_tokens = as.integer(max_tokens),
          temperature = 0.7
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(240)
      )

      status <- httr::status_code(response)
      if (status != 200) {
        body_txt <- tryCatch(httr::content(response, "text", encoding = "UTF-8"), error = function(e) "")
        stop(sprintf("OpenAI API error %s: %s", status, substr(body_txt, 1, 300)))
      }

      parsed <- httr::content(response, "parsed")
      text <- parsed$choices[[1]]$message$content %||% ""
      finish_reason <- parsed$choices[[1]]$finish_reason %||% NA

      list(text = text, stop_reason = finish_reason, truncated = identical(finish_reason, "length"))
    },

    test_openai = function() {
      self$call_openai("Reply with exactly these three words: OpenAI connection OK", max_tokens = 20)
    },

    # =====================================================================
    # BIGQUERY - generic plumbing
    # =====================================================================

    authenticate_bigquery = function(credentials_path = NULL) {
      if (!is.null(credentials_path)) {
        self$bq_credentials_path <- credentials_path
        bigrquery::bq_auth(path = credentials_path)
      }
      con <- DBI::dbConnect(bigrquery::bigquery(),
                             project = self$bq_project_id,
                             dataset = self$bq_dataset_id,
                             billing = self$bq_project_id)
      DBI::dbDisconnect(con)
      self$bq_authenticated <- TRUE
      invisible(TRUE)
    },

    bq_connect = function() {
      if (!is.null(self$bq_credentials_path)) bigrquery::bq_auth(path = self$bq_credentials_path)
      DBI::dbConnect(bigrquery::bigquery(),
                      project = self$bq_project_id,
                      dataset = self$bq_dataset_id,
                      billing = self$bq_project_id)
    },

    bq_query = function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      con <- self$bq_connect()
      on.exit(DBI::dbDisconnect(con), add = TRUE)
      DBI::dbGetQuery(con, query)
    },

    bq_execute = function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      con <- self$bq_connect()
      on.exit(DBI::dbDisconnect(con), add = TRUE)
      DBI::dbExecute(con, query)
    },

    create_all_tables = function() {
      results <- c()

      tryCatch({
        self$bq_execute(sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            contact_id STRING, full_name STRING, industry STRING, company STRING,
            job_title STRING, location STRING, country STRING, email STRING,
            phone STRING, linkedin STRING, areas_of_interest STRING, university STRING,
            academic_background STRING, user_notes STRING, last_interaction_date DATE,
            created_at TIMESTAMP, updated_at TIMESTAMP
          )", self$bq_full_table_contacts))
        results <- c(results, paste("✓", self$bq_table_contacts))
      }, error = function(e) results <<- c(results, paste("⚠️", self$bq_table_contacts, "-", e$message)))

      tryCatch({
        self$bq_execute(sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            message_id STRING, contact_id STRING, channel_type STRING,
            communication_purpose STRING, language STRING, message_length STRING,
            message_content STRING, created_at TIMESTAMP
          )", self$bq_full_table_communications))
        results <- c(results, paste("✓", self$bq_table_communications))
      }, error = function(e) results <<- c(results, paste("⚠️", self$bq_table_communications, "-", e$message)))

      tryCatch({
        self$bq_execute(sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            category STRING, country STRING, city_region STRING,
            programme_name STRING, amount_of_money STRING, conditions STRING,
            key_sponsors STRING, key_organiser_profiles STRING, areas_of_application STRING,
            start_date_for_applying STRING, deadline STRING,
            recommendations_for_applying STRING, verified_urls STRING
          )", self$bq_full_table_funding))
        results <- c(results, paste("✓", self$bq_table_funding))
      }, error = function(e) results <<- c(results, paste("⚠️", self$bq_table_funding, "-", e$message)))

      tryCatch({
        self$bq_execute(sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            canvas_id STRING NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            business_area STRING, project STRING, business_focus STRING,
            key_partners STRING, key_activities STRING, key_resources STRING,
            value_propositions STRING, customer_relationships STRING, channels STRING,
            customer_segments STRING, cost_structure STRING, revenue_streams STRING
          )", self$bq_full_table_bm_canvas))
        results <- c(results, paste("✓", self$bq_table_bm_canvas))
      }, error = function(e) results <<- c(results, paste("⚠️", self$bq_table_bm_canvas, "-", e$message)))

      tryCatch({
        self$bq_execute(sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            canvas_id STRING NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            business_area STRING, project STRING, business_focus STRING,
            raison_detre STRING, initial_market STRING, value_creation STRING,
            competitive_advantage STRING, customer_acquisition STRING, product_unit_economics STRING,
            sales STRING, overall_economics STRING, design_build STRING, scaling STRING
          )", self$bq_full_table_de_canvas))
        results <- c(results, paste("✓", self$bq_table_de_canvas))
      }, error = function(e) results <<- c(results, paste("⚠️", self$bq_table_de_canvas, "-", e$message)))

      tryCatch({
        self$bq_execute(sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            roadmap_id STRING NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            business_area STRING, project STRING, business_focus STRING,
            step_01_market_segmentation STRING, step_02_select_beachhead_market STRING,
            step_03_build_end_user_profile STRING, step_04_calculate_tam_beachhead STRING,
            step_05_profile_persona STRING, step_06_full_life_cycle_use_case STRING,
            step_07_high_level_product_spec STRING, step_08_quantify_value_proposition STRING,
            step_09_identify_next_10_customers STRING, step_10_define_your_core STRING,
            step_11_chart_competitive_position STRING, step_12_determine_dmu STRING,
            step_13_map_process_acquire_customer STRING, step_14_calculate_tam_followon STRING,
            step_15_design_business_model STRING, step_16_set_pricing_framework STRING,
            step_17_calculate_ltv STRING, step_18_map_sales_process STRING,
            step_19_calculate_cac STRING, step_20_identify_key_assumptions STRING,
            step_21_test_key_assumptions STRING, step_22_define_mvbp STRING,
            step_23_dogs_eat_dog_food STRING, step_24_develop_product_plan STRING
          )", self$bq_full_table_de_roadmap))
        results <- c(results, paste("✓", self$bq_table_de_roadmap))
      }, error = function(e) results <<- c(results, paste("⚠️", self$bq_table_de_roadmap, "-", e$message)))

      results
    },

    # =====================================================================
    # CONTACTS (Communications suite)
    # =====================================================================

    empty_contacts_df = function() {
      data.frame(
        contact_id = character(), full_name = character(), industry = character(),
        company = character(), job_title = character(), location = character(),
        country = character(), email = character(), phone = character(),
        linkedin = character(), areas_of_interest = character(), university = character(),
        academic_background = character(), user_notes = character(),
        last_interaction_date = character(), created_at = character(), updated_at = character(),
        stringsAsFactors = FALSE
      )
    },

    bq_load_contacts = function() {
      df <- tryCatch(
        self$bq_query(sprintf("SELECT * FROM `%s`", self$bq_full_table_contacts)),
        error = function(e) self$empty_contacts_df()
      )
      self$contacts_cache <- df
      df
    },

    bq_insert_contact = function(record) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      con <- self$bq_connect()
      on.exit(DBI::dbDisconnect(con), add = TRUE)
      DBI::dbWriteTable(conn = con, name = self$bq_table_contacts, value = record, append = TRUE, row.names = FALSE)

      self$contacts_cache <- if (is.null(self$contacts_cache) || nrow(self$contacts_cache) == 0) record
                              else rbind(self$contacts_cache, record)
      self$trigger_state_update_contacts()
      invisible(TRUE)
    },

    # Local-cache update. NOTE: BigQuery streaming-inserted rows sit in the
    # streaming buffer for up to ~90 min and cannot be targeted by UPDATE/DELETE
    # DML during that window. We update the in-memory cache immediately (so the
    # UI reflects the edit right away) and best-effort attempt a DML UPDATE,
    # swallowing the streaming-buffer error rather than failing the whole action.
    bq_update_contact = function(contact_id, updates) {
      if (!is.null(self$contacts_cache)) {
        row <- which(self$contacts_cache$contact_id == contact_id)
        for (col in names(updates)) self$contacts_cache[row, col] <- updates[[col]]
        self$contacts_cache[row, "updated_at"] <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      }
      tryCatch({
        set_clause <- paste(sprintf("%s = '%s'", names(updates), vapply(updates, safe_sql_escape, character(1))), collapse = ", ")
        self$bq_execute(sprintf("UPDATE `%s` SET %s, updated_at = CURRENT_TIMESTAMP() WHERE contact_id = '%s'",
                                 self$bq_full_table_contacts, set_clause, safe_sql_escape(contact_id)))
      }, error = function(e) cat("⚠️  [bq_update_contact] DML skipped (likely streaming buffer):", e$message, "\n"))
      self$trigger_state_update_contacts()
      invisible(TRUE)
    },

    bq_delete_contact = function(contact_id) {
      if (!is.null(self$contacts_cache)) {
        self$contacts_cache <- self$contacts_cache[self$contacts_cache$contact_id != contact_id, ]
      }
      if (!is.null(self$communications_cache)) {
        self$communications_cache <- self$communications_cache[self$communications_cache$contact_id != contact_id, ]
      }
      tryCatch({
        self$bq_execute(sprintf("DELETE FROM `%s` WHERE contact_id = '%s'",
                                 self$bq_full_table_contacts, safe_sql_escape(contact_id)))
      }, error = function(e) cat("⚠️  [bq_delete_contact] DML skipped (likely streaming buffer):", e$message, "\n"))
      self$trigger_state_update_contacts()
      invisible(TRUE)
    },

    trigger_state_update_contacts = function() {
      self$state_trigger_contacts(self$state_trigger_contacts() + 1)
      cat("🔔 [Communications] contacts state trigger fired\n")
    },

    # =====================================================================
    # COMMUNICATIONS (messages)
    # =====================================================================

    bq_insert_communication = function(record) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      con <- self$bq_connect()
      on.exit(DBI::dbDisconnect(con), add = TRUE)
      DBI::dbWriteTable(conn = con, name = self$bq_table_communications, value = record, append = TRUE, row.names = FALSE)

      self$communications_cache <- if (is.null(self$communications_cache) || nrow(self$communications_cache) == 0) record
                                    else rbind(self$communications_cache, record)
      invisible(TRUE)
    },

    bq_get_recent_messages = function(contact_id, n = 3) {
      self$bq_query(sprintf("
        SELECT * FROM `%s` WHERE contact_id = '%s' ORDER BY created_at DESC LIMIT %d
      ", self$bq_full_table_communications, safe_sql_escape(contact_id), n))
    },

    # =====================================================================
    # SMTP
    # =====================================================================

    smtp_test_connection = function(host, port, username, password) {
      test_cmd <- sprintf(
        'curl -v --url "smtps://%s:%s" --user "%s:%s" --ssl-reqd 2>&1',
        host, port, username, password
      )
      result <- system(test_cmd, intern = TRUE, ignore.stderr = FALSE)
      ok <- any(grepl("250|220|AUTH", result, ignore.case = TRUE))
      self$smtp_tested <- ok
      if (!ok) stop("Connection test failed - please check credentials")
      invisible(TRUE)
    },

    smtp_open_connection = function(host, port, username, password) {
      if (!self$smtp_tested) stop("Test the connection first")
      self$smtp_host <- host
      self$smtp_port <- port
      self$smtp_username <- username
      self$smtp_password <- password
      self$smtp_connected <- TRUE
      invisible(TRUE)
    },

    smtp_close_connection = function() {
      self$smtp_connected <- FALSE
      self$smtp_tested <- FALSE
      self$smtp_username <- NULL
      self$smtp_password <- NULL
      invisible(TRUE)
    },

    send_email = function(to, subject, body, attachments = NULL) {
      if (!self$smtp_connected) stop("Open the SMTP connection first (SMTP Configuration tab)")
      send_email_with_curl(
        from = self$smtp_username, to = to, subject = subject, body = body,
        host = self$smtp_host, port = self$smtp_port,
        username = self$smtp_username, password = self$smtp_password,
        attachments = attachments
      )
    },

    # =====================================================================
    # FUNDING PROGRAMMES
    # =====================================================================

    empty_funding_taxonomy = function() {
      data.frame(category = character(), country = character(), city_region = character(), stringsAsFactors = FALSE)
    },

    bq_get_funding_taxonomy = function() {
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
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")

      required_cols <- c("id", "created_at", "category", "country", "city_region",
                        "programme_name", "amount_of_money", "conditions", "key_sponsors",
                        "key_organiser_profiles", "areas_of_application",
                        "start_date_for_applying", "deadline",
                        "recommendations_for_applying", "verified_urls")

      start_id <- tryCatch({
        res <- bigrquery::bq_table_download(bigrquery::bq_project_query(self$bq_project_id,
          sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", self$bq_full_table_funding)))
        as.integer(res$max_id) + 1L
      }, error = function(e) 1L)

      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1L)
      data_frame$created_at <- Sys.time()
      for (col in required_cols) if (!col %in% names(data_frame)) data_frame[[col]] <- ""
      data_frame <- data_frame[, required_cols]

      table_ref <- bigrquery::bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_funding)
      bigrquery::bq_table_upload(table_ref, data_frame, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")

      cat("✅ [BigQuery] Inserted", nrow(data_frame), "row(s) →", self$bq_full_table_funding, "\n")
      return(nrow(data_frame))
    },

    trigger_state_update_funding = function() {
      self$state_trigger_funding(self$state_trigger_funding() + 1)
      self$funding_taxonomy_cache <- NULL
      cat("🔔 [Funding Programmes] state trigger fired\n")
    },

    set_pending_bulk_text_funding = function(text) { self$pending_bulk_text_funding(text) },

    # =====================================================================
    # STRATEGY CANVASES (Business Model Canvas, Disciplined Entrepreneurship
    # Canvas, Disciplined Entrepreneurship Roadmap)
    #
    # All three share one taxonomy (business_area / project / business_focus)
    # sourced from the BM Canvas table only, matching the source app's design
    # (a single project identity ties its BM Canvas, DE Canvas and DE Roadmap
    # together) - the same pattern as bq_get_funding_taxonomy() above.
    # =====================================================================

    empty_canvas_taxonomy = function() {
      data.frame(business_area = character(), project = character(), business_focus = character(), stringsAsFactors = FALSE)
    },

    bq_get_canvas_taxonomy = function() {
      if (!is.null(self$canvas_taxonomy_cache)) return(self$canvas_taxonomy_cache)
      if (!self$bq_authenticated) return(self$empty_canvas_taxonomy())

      result <- tryCatch({
        self$bq_query(sprintf(
          "SELECT DISTINCT business_area, project, business_focus FROM `%s` ORDER BY business_area, project, business_focus",
          self$bq_full_table_bm_canvas
        ))
      }, error = function(e) {
        cat("⚠️  [bq_get_canvas_taxonomy] Query failed:", e$message, "\n")
        self$empty_canvas_taxonomy()
      })

      self$canvas_taxonomy_cache <- result
      result
    },

    trigger_state_update_canvas = function() {
      self$state_trigger_canvas(self$state_trigger_canvas() + 1)
      self$canvas_taxonomy_cache <- NULL
      cat("🔔 [Strategy Canvases] state trigger fired\n")
    },

    make_canvas_id = function(business_area, project, business_focus) {
      paste0(
        gsub("[^A-Za-z0-9]", "_", business_area), "_",
        gsub("[^A-Za-z0-9]", "_", project), "_",
        gsub("[^A-Za-z0-9]", "_", business_focus), "_",
        format(Sys.time(), "%Y%m%d%H%M%S")
      )
    },

    bq_insert_bm_canvas = function(fields) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      record <- data.frame(
        canvas_id = self$make_canvas_id(fields$business_area, fields$project, fields$business_focus),
        created_at = Sys.time(), updated_at = Sys.time(),
        business_area = fields$business_area, project = fields$project, business_focus = fields$business_focus,
        key_partners = fields$key_partners, key_activities = fields$key_activities, key_resources = fields$key_resources,
        value_propositions = fields$value_propositions, customer_relationships = fields$customer_relationships,
        channels = fields$channels, customer_segments = fields$customer_segments,
        cost_structure = fields$cost_structure, revenue_streams = fields$revenue_streams,
        stringsAsFactors = FALSE
      )
      table_ref <- bigrquery::bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_bm_canvas)
      bigrquery::bq_table_upload(table_ref, record, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")
      self$trigger_state_update_canvas()
      record$canvas_id
    },

    bq_insert_de_canvas = function(fields) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      record <- data.frame(
        canvas_id = self$make_canvas_id(fields$business_area, fields$project, fields$business_focus),
        created_at = Sys.time(), updated_at = Sys.time(),
        business_area = fields$business_area, project = fields$project, business_focus = fields$business_focus,
        raison_detre = fields$raison_detre, initial_market = fields$initial_market, value_creation = fields$value_creation,
        competitive_advantage = fields$competitive_advantage, customer_acquisition = fields$customer_acquisition,
        product_unit_economics = fields$product_unit_economics, sales = fields$sales,
        overall_economics = fields$overall_economics, design_build = fields$design_build, scaling = fields$scaling,
        stringsAsFactors = FALSE
      )
      table_ref <- bigrquery::bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_de_canvas)
      bigrquery::bq_table_upload(table_ref, record, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")
      self$trigger_state_update_canvas()
      record$canvas_id
    },

    bq_insert_de_roadmap = function(fields) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      record <- data.frame(
        roadmap_id = self$make_canvas_id(fields$business_area, fields$project, fields$business_focus),
        created_at = Sys.time(), updated_at = Sys.time(),
        business_area = fields$business_area, project = fields$project, business_focus = fields$business_focus,
        step_01_market_segmentation = fields$step_01, step_02_select_beachhead_market = fields$step_02,
        step_03_build_end_user_profile = fields$step_03, step_04_calculate_tam_beachhead = fields$step_04,
        step_05_profile_persona = fields$step_05, step_06_full_life_cycle_use_case = fields$step_06,
        step_07_high_level_product_spec = fields$step_07, step_08_quantify_value_proposition = fields$step_08,
        step_09_identify_next_10_customers = fields$step_09, step_10_define_your_core = fields$step_10,
        step_11_chart_competitive_position = fields$step_11, step_12_determine_dmu = fields$step_12,
        step_13_map_process_acquire_customer = fields$step_13, step_14_calculate_tam_followon = fields$step_14,
        step_15_design_business_model = fields$step_15, step_16_set_pricing_framework = fields$step_16,
        step_17_calculate_ltv = fields$step_17, step_18_map_sales_process = fields$step_18,
        step_19_calculate_cac = fields$step_19, step_20_identify_key_assumptions = fields$step_20,
        step_21_test_key_assumptions = fields$step_21, step_22_define_mvbp = fields$step_22,
        step_23_dogs_eat_dog_food = fields$step_23, step_24_develop_product_plan = fields$step_24,
        stringsAsFactors = FALSE
      )
      table_ref <- bigrquery::bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_de_roadmap)
      bigrquery::bq_table_upload(table_ref, record, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")
      self$trigger_state_update_canvas()
      record$roadmap_id
    },

    bq_load_canvas_row = function(full_table_id, business_area, project, business_focus) {
      query <- sprintf(
        "SELECT * FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus = '%s' ORDER BY updated_at DESC LIMIT 1",
        full_table_id, safe_sql_escape(business_area), safe_sql_escape(project), safe_sql_escape(business_focus)
      )
      self$bq_query(query)
    },

    bq_load_bm_canvas = function(business_area, project, business_focus) {
      self$bq_load_canvas_row(self$bq_full_table_bm_canvas, business_area, project, business_focus)
    },
    bq_load_de_canvas = function(business_area, project, business_focus) {
      self$bq_load_canvas_row(self$bq_full_table_de_canvas, business_area, project, business_focus)
    },
    bq_load_de_roadmap = function(business_area, project, business_focus) {
      self$bq_load_canvas_row(self$bq_full_table_de_roadmap, business_area, project, business_focus)
    },

    # =====================================================================
    # GANTT TO TICKETS (Trello, Jira, Gantt-suite email, Gantt-suite contacts)
    # =====================================================================

    set_trello_credentials = function(key, token, board_id = NULL) {
      self$trello_key <- key
      self$trello_token <- token
      self$trello_board_id <- board_id
    },

    test_trello_connection = function() {
      if (is.null(self$trello_key) || is.null(self$trello_token)) stop("Trello credentials not set")
      response <- httr::GET(url = "https://api.trello.com/1/members/me",
                             query = list(key = self$trello_key, token = self$trello_token))
      if (httr::status_code(response) != 200) {
        self$trello_connected <- FALSE
        stop(paste("Connection failed:", httr::status_code(response)))
      }
      self$trello_connected <- TRUE
      user_data <- httr::content(response)
      list(success = TRUE, name = user_data$fullName)
    },

    get_trello_lists = function() {
      if (is.null(self$trello_board_id)) stop("Trello board ID not set")
      response <- httr::GET(url = paste0("https://api.trello.com/1/boards/", self$trello_board_id, "/lists"),
                             query = list(key = self$trello_key, token = self$trello_token))
      if (httr::status_code(response) != 200) stop(paste("Failed to load lists:", httr::status_code(response)))
      httr::content(response)
    },

    create_trello_card = function(list_id, name, description) {
      response <- httr::POST(url = "https://api.trello.com/1/cards",
                              query = list(key = self$trello_key, token = self$trello_token,
                                           idList = list_id, name = name, desc = description))
      httr::status_code(response) == 200
    },

    set_jira_credentials = function(url, email, token, project_key) {
      self$jira_url <- url
      self$jira_email <- email
      self$jira_token <- token
      self$jira_project_key <- project_key
    },

    test_jira_connection = function() {
      if (is.null(self$jira_url) || is.null(self$jira_email) || is.null(self$jira_token)) stop("Jira credentials not set")
      auth_encoded <- openssl::base64_encode(charToRaw(paste0(self$jira_email, ":", self$jira_token)))
      response <- httr::GET(url = paste0(self$jira_url, "/rest/api/3/myself"),
                             httr::add_headers(Authorization = paste("Basic", auth_encoded), "Content-Type" = "application/json"))
      if (httr::status_code(response) != 200) {
        self$jira_connected <- FALSE
        stop(paste("Connection failed:", httr::status_code(response)))
      }
      self$jira_connected <- TRUE
      user_data <- httr::content(response)
      list(success = TRUE, name = user_data$displayName)
    },

    create_jira_issue = function(summary, description, issue_type, priority = NULL, labels = NULL) {
      auth_encoded <- openssl::base64_encode(charToRaw(paste0(self$jira_email, ":", self$jira_token)))
      issue_data <- list(fields = list(project = list(key = self$jira_project_key), summary = summary,
                                        description = description, issuetype = list(name = issue_type)))
      if (!is.null(priority)) issue_data$fields$priority <- list(name = priority)
      if (!is.null(labels) && length(labels) > 0) issue_data$fields$labels <- labels

      response <- httr::POST(url = paste0(self$jira_url, "/rest/api/3/issue"),
                              httr::add_headers(Authorization = paste("Basic", auth_encoded), "Content-Type" = "application/json"),
                              body = jsonlite::toJSON(issue_data, auto_unbox = TRUE), encode = "json")

      if (httr::status_code(response) == 201) list(success = TRUE, key = httr::content(response)$key)
      else list(success = FALSE, error = httr::status_code(response))
    },

    set_gantt_smtp_config = function(host, port, user, password, use_ssl) {
      self$gantt_smtp_config <- list(host = host, port = port, user = user, password = password, ssl = use_ssl)
    },

    test_gantt_email_connection = function() {
      if (length(self$gantt_smtp_config) == 0) stop("Email configuration not set")
      smtp_creds <- blastula::creds(user = self$gantt_smtp_config$user, password = self$gantt_smtp_config$password,
                                     host = self$gantt_smtp_config$host, port = self$gantt_smtp_config$port,
                                     use_ssl = self$gantt_smtp_config$ssl)
      test_email <- blastula::compose_email(
        body = blastula::md("# Test Email\n\nThis is a test email from the Gantt to Tickets Converter suite.\nYour email configuration is working correctly!")
      )
      blastula::smtp_send(test_email, to = self$gantt_smtp_config$user, from = self$gantt_smtp_config$user,
                           subject = "Test Email - Gantt to Tickets", credentials = smtp_creds)
      self$gantt_email_connected <- TRUE
      invisible(TRUE)
    },

    send_gantt_email = function(to, subject, body, cc = NULL) {
      if (!self$gantt_email_connected) stop("Email not configured")
      smtp_creds <- blastula::creds(user = self$gantt_smtp_config$user, password = self$gantt_smtp_config$password,
                                     host = self$gantt_smtp_config$host, port = self$gantt_smtp_config$port,
                                     use_ssl = self$gantt_smtp_config$ssl)
      email <- blastula::compose_email(body = blastula::md(body))
      blastula::smtp_send(email, to = to, from = self$gantt_smtp_config$user, subject = subject, credentials = smtp_creds)
      invisible(TRUE)
    },

    empty_gantt_contacts_df = function() {
      data.frame(Country = character(), City = character(), Organization = character(), Full_Name = character(),
                 LinkedIn = character(), Email = character(), Phone = character(), Date_Added = character(),
                 stringsAsFactors = FALSE)
    },

    save_gantt_contacts = function() {
      writexl::write_xlsx(self$gantt_contacts_data, self$gantt_contacts_file)
    },

    trigger_state_update_gantt = function() {
      self$state_trigger_gantt(self$state_trigger_gantt() + 1)
      cat("🔔 [Gantt to Tickets] state trigger fired\n")
    },

    # =====================================================================
    # AUDIO TRANSCRIPTION (Whisper + ChatGPT/OpenAI, separate keys from
    # both each other and from api_manager$openai_api_key - see field comments above)
    # =====================================================================

    set_whisper_credentials = function(api_key, model = "whisper-1", language = "") {
      self$whisper_api_key <- api_key
      self$whisper_model <- model
      self$whisper_language <- language
      invisible(self)
    },

    set_chatgpt_credentials = function(api_key, model = "gpt-4o-mini") {
      self$chatgpt_api_key <- api_key
      self$chatgpt_model <- model
      invisible(self)
    },

    test_whisper_connection = function() {
      if (nchar(trimws(self$whisper_api_key)) == 0) return(list(success = FALSE, message = "API key not set"))
      tryCatch({
        response <- httr::GET("https://api.openai.com/v1/models",
                               httr::add_headers(Authorization = paste("Bearer", self$whisper_api_key)),
                               httr::timeout(10))
        if (httr::status_code(response) == 200) list(success = TRUE, message = "✓ API connection successful!")
        else list(success = FALSE, message = paste("✗ HTTP Error:", httr::status_code(response)))
      }, error = function(e) list(success = FALSE, message = paste("✗ Connection failed:", e$message)))
    },

    test_chatgpt_connection = function() {
      if (nchar(trimws(self$chatgpt_api_key)) == 0) return(list(success = FALSE, message = "API key not set"))
      tryCatch({
        response <- httr::GET("https://api.openai.com/v1/models",
                               httr::add_headers(Authorization = paste("Bearer", self$chatgpt_api_key)),
                               httr::timeout(10))
        if (httr::status_code(response) == 200) list(success = TRUE, message = "✓ API connection successful!")
        else list(success = FALSE, message = paste("✗ HTTP Error:", httr::status_code(response)))
      }, error = function(e) list(success = FALSE, message = paste("✗ Connection failed:", e$message)))
    },

    # Retry logic with exponential backoff on network errors and 429s,
    # auto-sized timeout based on file size when the caller doesn't set one.
    transcribe_audio = function(file_path, use_timeout = FALSE, timeout_seconds = NULL) {
      if (nchar(trimws(self$whisper_api_key)) == 0) stop("Whisper API key not set")

      file_size_mb <- file.size(file_path) / (1024^2)
      if (file_size_mb > 25) {
        stop("File too large. OpenAI Whisper API limit is 25MB. Current file: ", round(file_size_mb, 2), "MB")
      }

      url <- "https://api.openai.com/v1/audio/transcriptions"
      body <- list(file = httr::upload_file(file_path), model = "whisper-1")
      if (nchar(self$whisper_language) > 0) body$language <- self$whisper_language

      max_retries <- 3
      retry_count <- 0
      last_error <- NULL

      while (retry_count < max_retries) {
        result <- tryCatch({
          actual_timeout <- if (use_timeout && !is.null(timeout_seconds) && timeout_seconds > 0) {
            timeout_seconds
          } else {
            max(60, min(600, ceiling(file_size_mb * 30)))
          }

          response <- httr::POST(
            url, httr::add_headers(Authorization = paste("Bearer", self$whisper_api_key)),
            body = body, encode = "multipart", httr::timeout(actual_timeout),
            httr::config(connecttimeout = 60, ssl_verifypeer = TRUE, http_version = 2)
          )

          status <- httr::status_code(response)
          if (status == 200) {
            return(httr::content(response, "parsed")$text)
          } else if (status == 401) {
            stop("❌ Authentication failed. Check your API key.")
          } else if (status == 413) {
            stop("❌ File too large for API (max 25MB)")
          } else if (status == 429) {
            list(retry = TRUE, error = paste("HTTP 429:", httr::content(response, "text", encoding = "UTF-8")))
          } else {
            stop(paste("HTTP", status, ":", httr::content(response, "text", encoding = "UTF-8")))
          }
        }, error = function(e) {
          if (grepl("Connection was reset|Timeout|timed out|peer|SSL", e$message, ignore.case = TRUE)) {
            list(retry = TRUE, error = e$message)
          } else {
            stop(e$message)
          }
        })

        if (is.list(result) && isTRUE(result$retry)) {
          Sys.sleep(2^retry_count)
          retry_count <- retry_count + 1
          last_error <- result$error
        } else if (is.character(result)) {
          return(result)
        }
      }

      stop("❌ Transcription failed after ", max_retries, " attempts. Last error: ", last_error)
    },

    analyze_text = function(text, max_words = 500, custom_prompt = NULL, timeout_seconds = NULL) {
      if (nchar(trimws(self$chatgpt_api_key)) == 0) stop("ChatGPT API key not set")

      system_prompt <- if (!is.null(custom_prompt) && nchar(trimws(custom_prompt)) > 0) {
        custom_prompt
      } else {
        paste0("Summarize the following text in no more than ", max_words, " words. Focus on the key points and main ideas.")
      }

      body <- list(
        model = self$chatgpt_model,
        messages = list(list(role = "system", content = system_prompt), list(role = "user", content = text)),
        max_tokens = max_words * 2
      )

      response <- httr::POST(
        "https://api.openai.com/v1/chat/completions",
        httr::add_headers(Authorization = paste("Bearer", self$chatgpt_api_key), "Content-Type" = "application/json"),
        body = jsonlite::toJSON(body, auto_unbox = TRUE), encode = "raw",
        httr::timeout(if (!is.null(timeout_seconds)) timeout_seconds else 180)
      )

      status <- httr::status_code(response)
      if (status != 200) stop("API Error ", status, ": ", httr::content(response, "text", encoding = "UTF-8"))

      httr::content(response, "parsed")$choices[[1]]$message$content
    },

    empty_transcriptions_df = function() {
      data.frame(timestamp = character(), filename = character(), word_count = numeric(),
                 processing_time = numeric(), file_size = numeric(), stringsAsFactors = FALSE)
    },

    add_transcription_record = function(filename, word_count, processing_time, file_size) {
      new_row <- data.frame(timestamp = as.character(Sys.time()), filename = filename, word_count = word_count,
                             processing_time = processing_time, file_size = file_size, stringsAsFactors = FALSE)
      self$transcriptions <- rbind(self$transcriptions, new_row)
      self$trigger_state_update_audio()
    },

    trigger_state_update_audio = function() {
      self$state_trigger_audio(self$state_trigger_audio() + 1)
    },

    # =====================================================================
    # RECEIPT PROCESSOR (OpenAI Vision - gpt-4o)
    # =====================================================================

    init_receipt_storage = function() {
      if (!dir.exists(self$receipt_folder)) dir.create(self$receipt_folder, recursive = TRUE)
      if (!file.exists(self$receipt_excel_filename)) {
        empty_df <- data.frame(
          receipt_id = character(), filename = character(), provider = character(), amount = numeric(),
          date = character(), description = character(), processed_timestamp = character(),
          Labour = integer(), Overheads = integer(), Materials = integer(), Capital_Usage = integer(),
          TS = integer(), Contractor = integer(), stringsAsFactors = FALSE
        )
        openxlsx::write.xlsx(empty_df, self$receipt_excel_filename)
      }
    },

    test_receipt_api_connection = function() {
      if (nchar(trimws(self$receipt_api_key)) == 0) {
        return(list(success = FALSE, message = "Please enter and save your API key first."))
      }
      tryCatch({
        response <- httr::POST(
          url = "https://api.openai.com/v1/chat/completions",
          httr::add_headers(Authorization = paste("Bearer", self$receipt_api_key), "Content-Type" = "application/json"),
          body = list(model = "gpt-4o", messages = list(list(role = "user",
                      content = "Say 'API test successful' if you receive this message.")), max_tokens = 10),
          encode = "json", httr::timeout(30)
        )
        status <- httr::status_code(response)
        if (status == 200) {
          list(success = TRUE, message = paste("✓ Success! API connection is working correctly. You can now process receipts.\n\nResponse received at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
        } else if (status == 401) {
          list(success = FALSE, message = "✗ Authentication Failed (401): Your API key is invalid or has expired. Please check your key at https://platform.openai.com/api-keys")
        } else if (status == 429) {
          list(success = FALSE, message = "✗ Rate Limit Exceeded (429): Too many requests. Please wait a moment and try again.")
        } else {
          list(success = FALSE, message = paste("✗ Error: API returned status code:", status))
        }
      }, error = function(e) list(success = FALSE, message = paste("✗ Connection Error: Could not connect to OpenAI API:", e$message)))
    },

    # Extracts provider/amount/date/description from a receipt image via
    # OpenAI Vision. Returns a list with those fields, or list(error=...).
    call_receipt_api = function(file_path, filename) {
      if (nchar(trimws(self$receipt_api_key)) == 0) return(list(error = "API key not set"))

      base64_data <- encode_file(file_path)
      media_type <- get_media_type(filename)
      if (media_type == "application/pdf") {
        return(list(error = "PDF files are not supported with OpenAI Vision API. Please use JPG/JPEG images only."))
      }

      body <- list(
        model = "gpt-4o",
        messages = list(list(role = "user", content = list(
          list(type = "image_url", image_url = list(url = paste0("data:", media_type, ";base64,", base64_data))),
          list(type = "text", text = paste0(
            "Please analyze this purchase receipt and extract the following information:\n\n",
            "1. Provider/Seller name\n",
            "2. Final amount paid - IMPORTANT: Return ONLY the numeric value without any currency symbols (£, $, etc.). Just the number like 18.34\n",
            "3. Date of payment (in YYYY-MM-DD format if possible)\n",
            "4. Description of items or services purchased (brief summary)\n\n",
            "Respond ONLY with a valid JSON object in this exact format:\n{\n",
            '  "provider": "Name of provider/seller",\n  "amount": 18.34,\n  "date": "2025-11-13",\n  "description": "Brief description of items/services"\n}\n\n',
            "CRITICAL: The amount field must be a NUMBER (like 18.34), NOT a string with currency symbol.\n",
            "DO NOT include any text outside the JSON object. DO NOT use markdown code blocks or backticks. Return ONLY the JSON object."
          ))
        ))),
        max_tokens = 500
      )

      response <- tryCatch({
        httr::POST(url = "https://api.openai.com/v1/chat/completions",
                    httr::add_headers(Authorization = paste("Bearer", self$receipt_api_key), "Content-Type" = "application/json"),
                    body = body, encode = "json", httr::timeout(60))
      }, error = function(e) list(error = paste("API request failed:", e$message)))

      if ("error" %in% names(response)) return(response)

      status <- httr::status_code(response)
      if (status == 200) {
        content <- httr::content(response, "parsed")
        if (!is.null(content$choices) && length(content$choices) > 0) {
          response_text <- content$choices[[1]]$message$content
          response_text <- trimws(gsub("```json\\s*|```\\s*", "", response_text))
          tryCatch(jsonlite::fromJSON(response_text), error = function(e) {
            list(error = paste("Failed to parse JSON response:", e$message, "\nRaw response:", substr(response_text, 1, 200)))
          })
        } else {
          list(error = "API returned empty response")
        }
      } else if (status == 401) {
        list(error = "Authentication failed (401). Your API key is invalid. Check Settings tab.")
      } else if (status == 429) {
        list(error = "Rate limit exceeded (429). Please wait a moment and try again.")
      } else if (status == 400) {
        error_content <- tryCatch(httr::content(response, "text", encoding = "UTF-8"), error = function(e) "Unknown error")
        list(error = paste("Bad request (400):", error_content))
      } else {
        list(error = paste("API error: Status code", status))
      }
    },

    # For train/accommodation receipts, asks the model to condense the
    # description into a short route/city string for the saved filename.
    get_receipt_smart_description = function(provider, description) {
      provider_lower <- tolower(provider)
      description_lower <- tolower(description)
      smart_description <- description

      if (grepl("train|rail|railway|trainline", provider_lower) || grepl("train|rail|railway", description_lower)) {
        train_response <- tryCatch({
          httr::POST(
            url = "https://api.openai.com/v1/chat/completions",
            httr::add_headers(Authorization = paste("Bearer", self$receipt_api_key), "Content-Type" = "application/json"),
            body = list(model = "gpt-4o", messages = list(list(role = "user", content = paste0(
              "From this train receipt description: '", description,
              "'\n\nExtract ONLY the origin station and destination station.\n",
              "Format: OriginStation to DestinationStation\nExample: 'London Euston to Manchester Piccadilly'\n",
              "Keep station names clear and concise. Maximum 40 characters total.\nReturn ONLY the formatted route, nothing else."
            ))), max_tokens = 50),
            encode = "json", httr::timeout(30)
          )
        }, error = function(e) NULL)

        if (!is.null(train_response) && httr::status_code(train_response) == 200) {
          train_content <- httr::content(train_response, "parsed")
          if (!is.null(train_content$choices) && length(train_content$choices) > 0) {
            extracted_route <- trimws(train_content$choices[[1]]$message$content)
            if (nchar(extracted_route) > 0 && nchar(extracted_route) <= 60) smart_description <- extracted_route
          }
        }
      }

      if (grepl("booking\\.com|airbnb|hotel|hostel|accommodation", provider_lower) || grepl("hotel|accommodation|stay|night", description_lower)) {
        city_match <- gsub(".*?\\b(in|at)\\s+([A-Za-z\\s]+).*", "\\2", description, ignore.case = TRUE)
        if (city_match != description && nchar(city_match) > 0 && nchar(city_match) < 30) smart_description <- city_match
      }

      smart_description
    },

    # =====================================================================
    # VISUAL MEDIA (DALL-E image generation + ChatGPT text enrichment)
    # =====================================================================

    empty_generated_images_df = function() {
      data.frame(timestamp = character(), prompt = character(), model = character(),
                 size = character(), filepath = character(), stringsAsFactors = FALSE)
    },

    # Calls OpenAI's image-generation endpoint using the shared openai_api_key.
    # Returns list(success=TRUE, filepath=<temp .png>, b64_data=, revised_prompt=) or throws.
    generate_dalle_image = function(prompt, model = "dall-e-3", size = "1024x1024", quality = "standard", style = "vivid") {
      if (nchar(trimws(self$openai_api_key)) == 0) {
        stop("OpenAI API key not set. Please configure in API Settings > ChatGPT API Config.")
      }

      url <- "https://api.openai.com/v1/images/generations"

      body <- if (model == "dall-e-3") {
        list(model = model, prompt = prompt, n = 1, size = size, quality = quality, style = style, response_format = "b64_json")
      } else {
        list(model = model, prompt = prompt, n = 1, size = size, response_format = "b64_json")
      }

      response <- httr::POST(
        url, httr::add_headers(Authorization = paste("Bearer", self$openai_api_key), "Content-Type" = "application/json"),
        body = jsonlite::toJSON(body, auto_unbox = TRUE), encode = "raw",
        httr::timeout(120), httr::config(connecttimeout = 60)
      )

      status <- httr::status_code(response)
      if (status != 200) {
        error_content <- httr::content(response, "text", encoding = "UTF-8")
        if (status == 401) stop("Authentication failed. Check your ChatGPT/OpenAI API key in API Settings.")
        else if (status == 429) stop("Rate limit exceeded. Wait a few minutes and try again.")
        else if (status == 400) stop(paste("Bad request. Please check your prompt and try again. Details:", error_content))
        else stop(paste("API Error (Status", status, "):", error_content))
      }

      content_result <- httr::content(response, "parsed", encoding = "UTF-8")
      if (is.null(content_result$data) || length(content_result$data) == 0) stop("No image data returned from DALL-E")

      b64_image <- content_result$data[[1]]$b64_json
      if (is.null(b64_image) || nchar(b64_image) == 0) stop("Empty image data from DALL-E")

      image_binary <- base64enc::base64decode(b64_image)
      temp_file <- tempfile(fileext = ".png")
      writeBin(image_binary, temp_file)

      new_record <- data.frame(timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), prompt = substr(prompt, 1, 100),
                                model = model, size = size, filepath = temp_file, stringsAsFactors = FALSE)
      self$generated_images <- rbind(self$generated_images, new_record)

      list(success = TRUE, filepath = temp_file, b64_data = b64_image,
           revised_prompt = content_result$data[[1]]$revised_prompt %||% prompt)
    },

    # Converts/saves a generated image (PNG source) to jpg/png/gif/tiff/svg/pdf.
    save_image_with_format = function(source_path, output_path, format, dpi = 300) {
      tryCatch({
        img <- magick::image_read(source_path)
        info <- magick::image_info(img)

        if (format %in% c("jpg", "jpeg")) {
          img <- magick::image_convert(img, format = "jpeg")
          magick::image_write(img, path = output_path, format = "jpeg", quality = 100, density = dpi)
        } else if (format == "png") {
          img <- magick::image_convert(img, format = "png")
          magick::image_write(img, path = output_path, format = "png", density = dpi)
        } else if (format == "gif") {
          img <- magick::image_convert(img, format = "gif")
          magick::image_write(img, path = output_path, format = "gif")
        } else if (format == "tiff") {
          img <- magick::image_convert(img, format = "tiff")
          magick::image_write(img, path = output_path, format = "tiff", compression = "LZW", density = dpi)
        } else if (format == "svg") {
          img_png <- magick::image_convert(img, format = "png")
          png_b64 <- base64enc::base64encode(magick::image_write(img_png, format = "png"))
          svg_content <- sprintf(
            '<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d">\n  <image width="%d" height="%d" xlink:href="data:image/png;base64,%s"/>\n</svg>',
            info$width, info$height, info$width, info$height, info$width, info$height, png_b64
          )
          writeLines(svg_content, output_path)
        } else if (format == "pdf") {
          img_pdf <- magick::image_convert(img, format = "pdf")
          magick::image_write(img_pdf, path = output_path, format = "pdf", density = dpi)
        } else {
          stop("Unsupported format: ", format)
        }

        list(success = TRUE, message = paste0("Image saved successfully as ", toupper(format), "!"))
      }, error = function(e) list(success = FALSE, message = paste("Error:", e$message)))
    },

    set_pending_prompt_visual_media = function(text) { self$pending_prompt_visual_media(text) }
  )
)

# ---------------------------------------------------------------------------
# SMTP raw-send helper (used by APIManager$send_email)
# ---------------------------------------------------------------------------

send_email_with_curl <- function(from, to, subject, body, host, port, username, password, attachments = NULL) {
  boundary <- paste0("----=_Part_", as.integer(as.numeric(Sys.time()) * 1000))

  email_content <- c(
    paste0("From: ", from),
    paste0("To: ", paste(to, collapse = ", ")),
    paste0("Subject: ", subject),
    "MIME-Version: 1.0"
  )

  if (!is.null(attachments) && length(attachments) > 0) {
    email_content <- c(
      email_content,
      paste0('Content-Type: multipart/mixed; boundary="', boundary, '"'),
      "", paste0("--", boundary),
      "Content-Type: text/plain; charset=UTF-8",
      "Content-Transfer-Encoding: 7bit",
      "", body, ""
    )

    for (att in attachments) {
      if (file.exists(att$path)) {
        file_raw <- readBin(att$path, "raw", file.info(att$path)$size)
        file_b64 <- base64enc::base64encode(file_raw)

        ext <- tolower(tools::file_ext(att$name))
        content_type <- switch(ext,
                               "pdf" = "application/pdf",
                               "doc" = "application/msword",
                               "docx" = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                               "xls" = "application/vnd.ms-excel",
                               "xlsx" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                               "txt" = "text/plain",
                               "csv" = "text/csv",
                               "jpg" = "image/jpeg",
                               "jpeg" = "image/jpeg",
                               "png" = "image/png",
                               "gif" = "image/gif",
                               "zip" = "application/zip",
                               "application/octet-stream")

        email_content <- c(
          email_content,
          paste0("--", boundary),
          paste0('Content-Type: ', content_type, '; name="', att$name, '"'),
          "Content-Transfer-Encoding: base64",
          paste0('Content-Disposition: attachment; filename="', att$name, '"'),
          "", file_b64, ""
        )
      }
    }
    email_content <- c(email_content, paste0("--", boundary, "--"))
  } else {
    email_content <- c(email_content, "Content-Type: text/plain; charset=UTF-8", "", body)
  }

  email_file <- tempfile(fileext = ".eml")
  writeLines(email_content, email_file, useBytes = TRUE)

  curl_cmd <- sprintf(
    'curl --url "smtps://%s:%s" --ssl-reqd --mail-from "%s" --user "%s:%s" --upload-file "%s"',
    host, port, from, username, password, email_file
  )
  for (recipient in to) curl_cmd <- paste0(curl_cmd, sprintf(' --mail-rcpt "%s"', recipient))

  system(curl_cmd, intern = TRUE, ignore.stderr = FALSE)
  if (file.exists(email_file)) file.remove(email_file)
  TRUE
}

# ---------------------------------------------------------------------------
# FUNDING PROGRAMMES - text format parser, prompt builder, taxonomy cascades
# (ported unchanged from utils_funding_common.R; all now source taxonomy via
# the shared api_manager$bq_get_funding_taxonomy())
# ---------------------------------------------------------------------------

PROGRAMME_FIELDS <- c(
  "programme_name", "category", "country", "city_region",
  "amount_of_money", "conditions", "key_sponsors", "key_organiser_profiles",
  "areas_of_application", "start_date_for_applying", "deadline",
  "recommendations_for_applying", "verified_urls"
)

parse_programme_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]
  entries <- list()
  current_entry <- list()
  last_field <- NULL

  flush_entry <- function() {
    if (length(current_entry) > 0 && !is.null(current_entry$programme_name)) {
      entries[[length(entries) + 1]] <<- current_entry
    }
  }

  for (line in lines) {
    line <- trimws(line)
    if (line == "") next
    matched <- FALSE

    for (field in PROGRAMME_FIELDS) {
      pat <- paste0("^\\[", field, "\\]:\\s*(.*)$")
      if (grepl(pat, line, ignore.case = TRUE)) {
        value <- trimws(sub(pat, "\\1", line, ignore.case = TRUE))
        if (field == "programme_name") { flush_entry(); current_entry <- list() }
        current_entry[[field]] <- value
        last_field <- field
        matched <- TRUE
        break
      }
    }

    if (!matched && length(current_entry) > 0 && !is.null(last_field) && !grepl("^\\[", line)) {
      current_entry[[last_field]] <- paste(current_entry[[last_field]], line)
    }
  }
  flush_entry()

  if (length(entries) == 0) stop("No valid programme entries found in text")

  parsed_df <- data.frame(
    category = character(), country = character(), city_region = character(),
    programme_name = character(), amount_of_money = character(), conditions = character(),
    key_sponsors = character(), key_organiser_profiles = character(),
    areas_of_application = character(), start_date_for_applying = character(),
    deadline = character(), recommendations_for_applying = character(),
    verified_urls = character(), stringsAsFactors = FALSE
  )

  for (entry in entries) {
    parsed_df <- rbind(parsed_df, data.frame(
      category = entry$category %||% "",
      country = entry$country %||% "",
      city_region = entry$city_region %||% "All",
      programme_name = entry$programme_name %||% "",
      amount_of_money = entry$amount_of_money %||% "",
      conditions = entry$conditions %||% "",
      key_sponsors = entry$key_sponsors %||% "",
      key_organiser_profiles = entry$key_organiser_profiles %||% "",
      areas_of_application = entry$areas_of_application %||% "",
      start_date_for_applying = entry$start_date_for_applying %||% "",
      deadline = entry$deadline %||% "",
      recommendations_for_applying = entry$recommendations_for_applying %||% "",
      verified_urls = entry$verified_urls %||% "",
      stringsAsFactors = FALSE
    ))
  }
  parsed_df
}

overwrite_programme_taxonomy <- function(text, category, country, city_region) {
  lines <- strsplit(text, "\n")[[1]]
  for (i in seq_along(lines)) {
    if (grepl("^\\[category\\]:", lines[i], ignore.case = TRUE)) lines[i] <- paste0("[category]: ", category)
    else if (grepl("^\\[country\\]:", lines[i], ignore.case = TRUE)) lines[i] <- paste0("[country]: ", country)
    else if (grepl("^\\[city_region\\]:", lines[i], ignore.case = TRUE)) lines[i] <- paste0("[city_region]: ", city_region)
  }
  paste(lines, collapse = "\n")
}

generate_programme_prompt <- function(category, country, city_region, search_focus, n_results = 4) {
  region_text <- if (identical(city_region, "All") || nchar(trimws(city_region)) == 0) country
                 else paste0(city_region, ", ", country)
  focus_text <- if (nchar(trimws(search_focus)) > 0) search_focus
                else "No further focus provided - use your best judgement for relevant, well-known programmes."

  paste0(
    'You are a research assistant specializing in startup/business funding programmes. ',
    'Find up to ', n_results, ' real, well-known ', category, ' programmes relevant to ', region_text, '. ',
    'Focus area: ', focus_text, '\n\n',
    'CRITICAL ACCURACY RULES:\n',
    '- Only include programmes you have genuine knowledge of. Do NOT invent fictional programmes.\n',
    '- If you are not confident about a specific date, amount, or URL, say so explicitly in that field ',
    '(e.g. "Check official site - exact deadline varies by year") rather than guessing a precise-looking but unverified value.\n',
    '- Dates should be in the format YYYY-MM-DD when known and confident.\n\n',
    'For EACH programme, output EXACTLY this format (no markdown, no extra commentary):\n\n',
    '[programme_name]: Full official name of the programme\n',
    '[category]: ', category, '\n',
    '[country]: ', country, '\n',
    '[city_region]: ', city_region, '\n',
    '[amount_of_money]: Funding amount or range offered (e.g. "Up to EUR 2.5 million" or "Equity-free grant, USD 50,000")\n',
    '[conditions]: Key eligibility conditions (company stage, sector, location requirements, etc.)\n',
    '[key_sponsors]: Who funds/sponsors this programme\n',
    '[key_organiser_profiles]: Names/roles of key people who run or represent the programme, if known\n',
    '[areas_of_application]: Sectors or fields this programme applies to\n',
    '[start_date_for_applying]: When applications open (YYYY-MM-DD if known, otherwise a description)\n',
    '[deadline]: Application deadline (YYYY-MM-DD if known, otherwise a description, e.g. "Rolling basis")\n',
    '[recommendations_for_applying]: Practical tips for a strong application\n',
    '[verified_urls]: Official URL(s) for this programme, comma-separated. Only include URLs you are ',
    'reasonably confident are correct.\n\n',
    'Separate each programme with a blank line. Every field must be present for every programme ',
    '(if something is genuinely unknown, write "Not confirmed - verify on official site").\n\n',
    'Now find and list the programmes.'
  )
}

FUNDING_CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_CATEGORY_FUND__"
FUNDING_DEFAULT_CATEGORIES <- c("Grant", "Incubator", "Accelerator", "Competition")

funding_category_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("category_select"), "Category: *",
                choices = c(setNames(FUNDING_DEFAULT_CATEGORIES, FUNDING_DEFAULT_CATEGORIES),
                            "+ Add New Category" = FUNDING_CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("category_select"), FUNDING_CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_category_text"), "New Category Name:", placeholder = "e.g., Fellowship, Award")
    )
  )
}

setup_funding_category_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_funding()
    if (!api_manager$bq_authenticated) return(data.frame(category = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_funding_taxonomy(), error = function(e) data.frame(category = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    all_categories <- sort(unique(c(FUNDING_DEFAULT_CATEGORIES, stored)))
    choices <- c(setNames(all_categories, all_categories), "+ Add New Category" = FUNDING_CATEGORY_ADD_NEW_VALUE)
    current <- isolate(input$category_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_categories[1]
    updateSelectInput(session, "category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$category_select, FUNDING_CATEGORY_ADD_NEW_VALUE)) trimws(input$new_category_text %||% "")
    else input$category_select %||% ""
  })
}

FUNDING_COUNTRY_ADD_NEW_VALUE <- "__ADD_NEW_COUNTRY_FUND__"
FUNDING_CITYREGION_ADD_NEW_VALUE <- "__ADD_NEW_CITYREGION_FUND__"

funding_country_cityregion_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("country_select"), "Country: *",
                choices = c("+ Add New Country" = FUNDING_COUNTRY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("country_select"), FUNDING_COUNTRY_ADD_NEW_VALUE),
      textInput(ns("new_country_text"), "New Country Name:", placeholder = "e.g., Germany")
    ),
    selectInput(ns("cityregion_select"), "City / Region:",
                choices = c("All" = "All", "+ Add New City/Region" = FUNDING_CITYREGION_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("cityregion_select"), FUNDING_CITYREGION_ADD_NEW_VALUE),
      textInput(ns("new_cityregion_text"), "New City/Region Name:", placeholder = "e.g., Bavaria, Berlin")
    )
  )
}

setup_funding_country_cityregion_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_funding()
    if (!api_manager$bq_authenticated) return(data.frame(country = character(), city_region = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_funding_taxonomy(), error = function(e) data.frame(country = character(), city_region = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    countries <- sort(unique(tax$country[nchar(trimws(tax$country)) > 0]))
    choices <- c("+ Add New Country" = FUNDING_COUNTRY_ADD_NEW_VALUE, setNames(countries, countries))
    current <- isolate(input$country_select)
    selected <- if (!is.null(current) && current %in% choices) current else FUNDING_COUNTRY_ADD_NEW_VALUE
    updateSelectInput(session, "country_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  observeEvent(input$country_select, {
    tax <- taxonomy()
    base_choices <- c("All" = "All", "+ Add New City/Region" = FUNDING_CITYREGION_ADD_NEW_VALUE)
    if (is.null(input$country_select) || input$country_select == FUNDING_COUNTRY_ADD_NEW_VALUE) {
      updateSelectInput(session, "cityregion_select", choices = base_choices)
      return()
    }
    regions <- sort(unique(tax$city_region[tax$country == input$country_select &
                                            nchar(trimws(tax$city_region)) > 0 & tax$city_region != "All"]))
    if (length(regions) == 0) {
      updateSelectInput(session, "cityregion_select", choices = base_choices)
    } else {
      updateSelectInput(session, "cityregion_select",
                        choices = c("All" = "All", setNames(regions, regions),
                                    "+ Add New City/Region" = FUNDING_CITYREGION_ADD_NEW_VALUE))
    }
  }, ignoreInit = TRUE)

  reactive({
    country <- if (identical(input$country_select, FUNDING_COUNTRY_ADD_NEW_VALUE)) trimws(input$new_country_text %||% "") else input$country_select %||% ""
    city_region <- if (identical(input$cityregion_select, FUNDING_CITYREGION_ADD_NEW_VALUE)) trimws(input$new_cityregion_text %||% "") else input$cityregion_select %||% "All"
    list(country = country, city_region = city_region)
  })
}

# ---------------------------------------------------------------------------
# STRATEGY CANVASES - shared taxonomy cascade for the 3 "view" subtabs
# (BM Canvas, DE Canvas, DE Roadmap). Every view module names its selectInputs
# "business_area" / "project" / "business_focus" / "load_btn" inside its own
# module namespace, so this one function works for all three unchanged.
# ---------------------------------------------------------------------------

setup_canvas_selection_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_canvas()
    if (!api_manager$bq_authenticated) return(api_manager$empty_canvas_taxonomy())
    tryCatch(api_manager$bq_get_canvas_taxonomy(), error = function(e) api_manager$empty_canvas_taxonomy())
  })

  observeEvent(taxonomy(), {
    areas <- sort(unique(taxonomy()$business_area[nchar(trimws(taxonomy()$business_area)) > 0]))
    updateSelectInput(session, "business_area", choices = c("Select..." = "", areas))
  }, ignoreNULL = FALSE)

  observeEvent(input$business_area, {
    if (is.null(input$business_area) || input$business_area == "") {
      updateSelectInput(session, "project", choices = c("Select..." = ""))
      return()
    }
    tax <- taxonomy()
    projects <- sort(unique(tax$project[tax$business_area == input$business_area & nchar(trimws(tax$project)) > 0]))
    if (length(projects) == 0) updateSelectInput(session, "project", choices = c("No projects available" = ""))
    else updateSelectInput(session, "project", choices = c("Select..." = "", projects))
  }, ignoreInit = TRUE)

  observeEvent(input$project, {
    if (is.null(input$project) || input$project == "") {
      updateSelectInput(session, "business_focus", choices = c("Select..." = ""))
      return()
    }
    tax <- taxonomy()
    focuses <- sort(unique(tax$business_focus[tax$business_area == input$business_area & tax$project == input$project &
                                                 nchar(trimws(tax$business_focus)) > 0]))
    if (length(focuses) == 0) updateSelectInput(session, "business_focus", choices = c("No business focus available" = ""))
    else updateSelectInput(session, "business_focus", choices = c("Select..." = "", focuses))
  }, ignoreInit = TRUE)
}

# Renders an HTML fragment for a canvas text field: newline -> <br>, with an
# optional extra class (e.g. "two-column-content" for Cost Structure/Revenue Streams).
canvas_html_field <- function(text, extra_class = "") {
  cls <- paste("section-content", extra_class)
  HTML(paste0('<div class="', trimws(cls), '">', gsub("\n", "<br>", text %||% ""), '</div>'))
}

de_box_html_field <- function(text) {
  HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", text %||% ""), '</div>'))
}

# ---------------------------------------------------------------------------
# STRATEGY CANVASES - shared field/label constants (used by both the
# "generate" and "view" modules; defined here so they're always available
# regardless of which of those modules is enabled in the registry).
# ---------------------------------------------------------------------------

BM_CANVAS_FIELDS <- c("key_partners", "key_activities", "key_resources", "value_propositions",
                       "customer_relationships", "channels", "customer_segments",
                       "cost_structure", "revenue_streams")
BM_CANVAS_LABELS <- c("Key Partners", "Key Activities", "Key Resources", "Value Propositions",
                       "Customer Relationships", "Channels", "Customer Segments",
                       "Cost Structure", "Revenue Streams")

DE_CANVAS_FIELDS <- c("raison_detre", "initial_market", "value_creation", "competitive_advantage",
                       "customer_acquisition", "product_unit_economics", "sales", "overall_economics",
                       "design_build", "scaling")
DE_CANVAS_LABELS <- c("Raison d'Être", "Initial Market", "Value Creation", "Competitive Advantage",
                       "Customer Acquisition", "Product Unit Economics", "Sales", "Overall Economics",
                       "Design & Build", "Scaling")

ROADMAP_STEP_TITLES <- c(
  "Market Segmentation", "Select a Beachhead Market", "Build an End User Profile",
  "Calculate TAM Size for Beachhead Market", "Profile the Persona for the Beachhead Market",
  "Full Life Cycle Use Case", "High-Level Product Specification", "Quantify the Value Proposition",
  "Identify Your Next 10 Customers", "Define Your Core", "Chart Your Competitive Position",
  "Determine the Customer's Decision-Making Unit", "Map Process to Acquire Paying Customer",
  "Calculate TAM Size for Follow-on Markets", "Design a Business Model", "Set Your Pricing Framework",
  "Calculate Lifetime Value of an Acquired Customer", "Map Sales Process to Acquire a Customer",
  "Calculate the Cost of Customer Acquisition", "Identify Key Assumptions", "Test Key Assumptions",
  "Define the Minimum Viable Business Product (MVBP)", "Show That \"The Dogs Will Eat the Dog Food\"",
  "Develop a Product Plan"
)
ROADMAP_STEP_FIELDS <- sprintf("step_%02d", 1:24)

# Category (for the 5-color legend) each of the 24 roadmap steps belongs to,
# matching the source app's static roadmap-cat1..5 box coloring.
ROADMAP_STEP_CATEGORY <- c(1,1,1,1, 1,2,2,2, 1,2,2,1, 3,3,4,4, 4,3,4,4, 5,5,5,5)
