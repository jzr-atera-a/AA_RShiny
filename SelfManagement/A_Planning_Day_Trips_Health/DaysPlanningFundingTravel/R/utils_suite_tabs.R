# R/utils_suite_tabs.R
# SHARED SUB-TABS: one implementation for tabs that several suites repeat with different constants.
#   suite_bulk_import_ui/_server  - "Bulk Import" of Day Planner, Diet Planner, Exercise Tracker, Funding Programmes
#   suite_browse_ui/_server       - "Browse Data" of Diet Planner, Exercise Tracker, Funding Programmes
# Each sub-tab file passes its entry of SUITE_BULK_IMPORT / SUITE_BROWSE, so texts, input ids, parsers, tables and file
# names are exactly the ones those tabs had when each was a separate copy.
# (Events' bulk import / browse and the Day Planner browse differ in behaviour and keep their own code.)

SUITE_BULK_IMPORT <- list(
  schedule = list(
    key = "schedule", text_id = "schedule_text", parser = "parse_schedule_text",
    title = "Bulk Import Day Schedule to BigQuery", heading = "Paste or Generate Day Schedule",
    intro = "Paste a complete day schedule to parse and upload to BigQuery.",
    format_title = "Expected Format:",
    format = c("Day metadata: [Date], [Day Type], [Country], [City], [Trip Details]", "[row_type]: Location | Transport | Summary",
               "[location_name], [location_details]", "[opening_hours], [recommended_time]", "[observations]"),
    text_label = "Paste Day Schedule Here:",
    placeholder = "[2026-07-10]\n[Travel]\n[France]\n[Paris]\n[Museum day]\n\n[row_type]: Location\n...",
    parse_label = "Parse Schedule", empty_msg = " Please paste a schedule to parse", need_parse_msg = "Please parse the schedule first!",
    unit = "rows", parsed_info = function(d) sprintf(" Successfully parsed %d rows for %s (%s)", nrow(d), d$schedule_date[1], d$day_type[1])),
  diet = list(
    key = "diet", text_id = "diet_text", parser = "parse_diet_text",
    title = "Bulk Import Diet Log to BigQuery", heading = "Paste or Generate a Day's Diet Log",
    intro = "Paste a complete day of meals to parse and upload to BigQuery.",
    format_title = "Expected Format:",
    format = c("Day metadata: [Date], [Diet Type], [Dietary Restrictions]", "[row_type]: Meal | Summary",
               "[meal_name], [meal_details]", "[meal_time], [calories_macros]", "[observations]"),
    text_label = "Paste Diet Log Here:",
    placeholder = "[2026-07-10]\n[Keto]\n[Gluten-free]\n\n[row_type]: Meal\n...",
    parse_label = "Parse Diet Log", empty_msg = " Please paste a diet log to parse", need_parse_msg = "Please parse the diet log first!",
    unit = "rows", parsed_info = function(d) sprintf(" Successfully parsed %d rows for %s (%s)", nrow(d), d$log_date[1], d$diet_type[1])),
  exercise = list(
    key = "exercise", text_id = "exercise_text", parser = "parse_exercise_text",
    title = "Bulk Import Workout Session to BigQuery", heading = "Paste or Generate a Workout Session",
    intro = "Paste a complete workout session to parse and upload to BigQuery.",
    format_title = "Expected Format:",
    format = c("Session metadata: [Date], [Session Type], [Session Notes]", "[row_type]: Exercise | Summary",
               "[exercise_category], [exercise_name], [exercise_details]", "[metric_primary], [metric_secondary], [calories_burned]", "[observations]"),
    text_label = "Paste Workout Session Here:",
    placeholder = "[2026-07-10]\n[Weights]\n[Focus on upper body]\n\n[row_type]: Exercise\n...",
    parse_label = "Parse Session", empty_msg = " Please paste a workout session to parse", need_parse_msg = "Please parse the workout session first!",
    unit = "rows", parsed_info = function(d) sprintf(" Successfully parsed %d rows for %s (%s)", nrow(d), d$workout_date[1], d$session_type[1])),
  funding = list(
    key = "funding", text_id = "programme_text", parser = "parse_programme_text",
    title = "Bulk Import Funding Programmes to BigQuery", heading = "Paste or Generate Programme Data",
    intro = "Paste one or more programme entries to parse and upload to BigQuery.",
    format_title = "Expected Format (one block per programme, blank line between):",
    format = c("[programme_name], [category], [country], [city_region]", "[amount_of_money], [conditions], [key_sponsors]",
               "[key_organiser_profiles], [areas_of_application]", "[start_date_for_applying], [deadline]", "[recommendations_for_applying], [verified_urls]"),
    text_label = "Paste Programme Data Here:",
    placeholder = "[programme_name]: Horizon Europe SME Instrument\n[category]: Grant\n[country]: European Union\n[city_region]: All\n...",
    parse_label = "Parse Programmes", empty_msg = " Please paste programme data to parse", need_parse_msg = "Please parse the programme data first!",
    unit = "programme(s)", parsed_info = function(d) sprintf(" Successfully parsed %d programme(s)", nrow(d)))
)

suite_bulk_import_ui <- function(id, cfg) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = cfg$title, status = "primary", solidHeader = TRUE, width = 12,
        h4(cfg$heading),
        p(cfg$intro),
        div(class = "alert alert-info", tags$strong(cfg$format_title), tags$ul(lapply(cfg$format, tags$li))),
        bos_tz_dropdown_ui(ns, label = "Time zone of the pasted times:", help = "Used only when the text has no [time_zone] line (text from the generator tabs already carries one)."),
        textAreaInput(ns(cfg$text_id), cfg$text_label, height = "500px", placeholder = cfg$placeholder),
        fluidRow(
          column(4, actionButton(ns("parse"), cfg$parse_label, class = "btn-info btn-lg", icon = icon("cogs"), width = "100%")),
          column(4, actionButton(ns("upload"), "Upload to BigQuery", class = "btn-success btn-lg", icon = icon("cloud-upload-alt"), width = "100%")),
          column(4, actionButton(ns("clear"), "Clear All", class = "btn-danger", icon = icon("trash"), width = "100%"))
        ),
        br(),
        htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Parsed Data Preview", status = "info", solidHeader = TRUE, width = 12,
          htmlOutput(ns("parse_info")), br(),
          div(class = "preview-section", DT::dataTableOutput(ns("preview_table"))))
    )
  )
}

suite_bulk_import_server <- function(id, api_manager, cfg) {
  moduleServer(id, function(input, output, session) {
    parsed_data <- reactiveVal(NULL)
    pending <- api_manager[[paste0("pending_bulk_text_", cfg$key)]]       # text handed over by the suite's Generate tab
    status <- function(class, icon_class, ...) output$status <- renderUI({ tags$div(class = class, if (!is.null(icon_class)) tags$i(class = icon_class), ...) })
    show_error <- function(e) {
      status("status-error", "fa fa-times-circle", " Error: ", e$message)
      showNotification(paste("Error:", e$message), type = "error")
    }

    observeEvent(pending(), {
      incoming_text <- pending()
      if (nchar(incoming_text) > 0) updateTextAreaInput(session, cfg$text_id, value = incoming_text)
    }, ignoreInit = TRUE)

    observeEvent(input$parse, {
      text <- input[[cfg$text_id]]
      if (trimws(text) == "") { status("status-error", "fa fa-exclamation-triangle", cfg$empty_msg); return() }
      status("status-info", "fa fa-spinner fa-spin", " Parsing...")
      tryCatch({
        parsed_df <- get(cfg$parser, mode = "function")(text, default_tz = input$time_zone)
        parsed_data(parsed_df)
        output$parse_info <- renderUI({ tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), cfg$parsed_info(parsed_df)) })
        output$preview_table <- DT::renderDataTable({ DT::datatable(parsed_df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE) })
        status("status-success", "fa fa-check-circle", sprintf(" Parsed %d %s!", nrow(parsed_df), cfg$unit))
        showNotification(sprintf("✓ Parsed %d %s!", nrow(parsed_df), cfg$unit), type = "message")
      }, error = show_error)
    })

    observeEvent(input$upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      if (is.null(parsed_data())) { showNotification(cfg$need_parse_msg, type = "error"); return() }
      status("status-info", "fa fa-spinner fa-spin", " Uploading...")
      tryCatch({
        rows_uploaded <- api_manager[[paste0("bq_insert_", cfg$key)]](parsed_data())
        api_manager[[paste0("trigger_state_update_", cfg$key)]]()
        status("status-success", "fa fa-check-circle", sprintf(" Successfully uploaded %d %s!", rows_uploaded, cfg$unit))
        showNotification(sprintf("✓ Uploaded %d %s!", rows_uploaded, cfg$unit), type = "message")
      }, error = show_error)
    })

    observeEvent(input$clear, {
      updateTextAreaInput(session, cfg$text_id, value = "")
      parsed_data(NULL)
      output$parse_info <- renderUI({})
      output$preview_table <- DT::renderDataTable({})
      status("status-info", NULL, "Cleared.")
    })

    output$status <- renderUI({ tags$div() })
    output$parse_info <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
  })
}

# ---- Browse Data ------------------------------------------------------------------------------------------------------
# rename: columns renamed for the calendar export, applied in order (first match per target wins, as before).
SUITE_BROWSE <- list(
  diet = list(
    key = "diet", title = "Browse Logged Diet Days", order_by = "log_date DESC, row_sequence ASC",
    csv_prefix = "diet_log_", ics_prefix = "meal_schedule_", empty_msg = "No diet entries to export",
    rename = list(c("log_date", "date"), c("meal_name", "name"), c("meal_type", "name")),
    cal_title = "Meal Schedule", use_time = TRUE, duration = 60,
    cal_description = "Meal session - Exported from Business Operations Suite", item_fallback = "meal_name",
    done_msg = "✓ Meal schedule exported successfully"),
  exercise = list(
    key = "exercise", title = "Browse Logged Workouts", order_by = "workout_date DESC, row_sequence ASC",
    csv_prefix = "exercise_log_", ics_prefix = "workout_schedule_", empty_msg = "No workout entries to export",
    rename = list(c("workout_date", "date"), c("activity", "name"), c("exercise_type", "name")),
    cal_title = "Workout Schedule", use_time = TRUE, duration = 60,
    cal_description = "Workout session - Exported from Business Operations Suite", item_fallback = "activity",
    done_msg = "✓ Workout schedule exported successfully"),
  funding = list(
    key = "funding", title = "Browse Planned Programmes", order_by = "deadline ASC, category ASC",
    csv_prefix = "funding_programmes_", ics_prefix = "funding_deadlines_", empty_msg = "No funding programmes to export",
    rename = list(c("deadline", "date"), c("programme_name", "name"), c("title", "name")),
    cal_title = "Funding Programme Deadlines", use_time = FALSE, duration = 480,
    cal_description = "Funding application deadline - Exported from Business Operations Suite", item_fallback = "programme_name",
    done_msg = "✓ Funding deadlines exported successfully")
)

suite_browse_ui <- function(id, cfg) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = cfg$title, status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(2, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary", icon = icon("sync"))),
            column(2, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
            column(2, downloadButton(ns("download_calendar"), "\U0001F4C5 Calendar", class = "btn-success")),
            column(6, numericInput(ns("max_rows"), "Max Rows to Display:", value = 200, min = 10, max = 2000, step = 10))
          ),
          br(), htmlOutput(ns("status")), br(),
          DT::dataTableOutput(ns("table"))
      )
    )
  )
}

suite_browse_server <- function(id, api_manager, cfg) {
  moduleServer(id, function(input, output, session) {
    browse_data <- reactiveVal(NULL)

    observeEvent(input$refresh, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading data...") })
      tryCatch({
        query <- sprintf("SELECT * FROM `%s` ORDER BY %s LIMIT %d", api_manager[[paste0("bq_full_table_", cfg$key)]], cfg$order_by, input$max_rows)
        data <- api_manager$bq_query(query)
        browse_data(data)
        output$table <- DT::renderDataTable({ DT::datatable(data, options = list(pageLength = 25, scrollX = TRUE), rownames = FALSE) })
        output$status <- renderUI({ tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Loaded %d rows", nrow(data))) })
        showNotification(sprintf("✓ Loaded %d rows", nrow(data)), type = "message")
      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0(cfg$csv_prefix, format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) if (!is.null(browse_data())) write.csv(browse_data(), file, row.names = FALSE)
    )

    output$download_calendar <- downloadHandler(
      filename = function() paste0(cfg$ics_prefix, format(Sys.Date(), "%Y%m%d"), ".ics"),
      content = function(file) {
        tryCatch({
          data <- browse_data()
          if (is.null(data) || nrow(data) == 0) { showNotification(cfg$empty_msg, type = "warning"); return() }
          cal_data <- data
          for (r in cfg$rename) if (r[1] %in% names(cal_data)) names(cal_data)[names(cal_data) == r[1]] <- r[2]
          ics_lines <- generate_calendar_ics(
            title = cfg$cal_title, items = cal_data, date_col = "date",
            time_col = if (isTRUE(cfg$use_time) && "time" %in% names(cal_data)) "time" else NULL,
            duration_minutes = cfg$duration, description = cfg$cal_description,
            item_col = if ("name" %in% names(cal_data)) "name" else cfg$item_fallback
          )
          export_calendar_file(ics_lines, file)
          showNotification(cfg$done_msg, type = "message")
        }, error = function(e) showNotification(paste("Error exporting calendar:", e$message), type = "error"))
      }
    )

    output$status <- renderUI({ tags$div() })
    output$table <- DT::renderDataTable({})
  })
}
