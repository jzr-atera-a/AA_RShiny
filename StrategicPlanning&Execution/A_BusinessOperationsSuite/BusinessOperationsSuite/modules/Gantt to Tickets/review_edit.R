# modules/Gantt to Tickets/review_edit.R
# Subtab: Review & Edit Tasks

review_edit_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Task List - Edit as Needed", status = "primary", solidHeader = TRUE, width = 12,
          DT::dataTableOutput(ns("editable_table")), br(),
          actionButton(ns("refresh_table"), "Refresh Table", icon = icon("refresh")))
    ),
    fluidRow(
      box(title = "Add Additional Information", status = "info", solidHeader = TRUE, width = 12,
          selectInput(ns("select_task"), "Select Task:", choices = NULL),
          textAreaInput(ns("additional_notes"), "Additional Notes:", rows = 3),
          textInput(ns("additional_labels"), "Add Labels (comma-separated):", ""),
          actionButton(ns("update_task"), "Update Task", class = "btn-primary"))
    ),
    fluidRow(
      box(title = "Task Timeline (.ics)", status = "info", solidHeader = TRUE, width = 6,
          p("One all-day calendar entry per task, from its Start Date to its End Date, with a reminder the day before."),
          htmlOutput(ns("timeline_status")),
          downloadButton(ns("download_calendar"), "Download Task Timeline (.ics)", class = "btn-success"),
          uiOutput(ns("titan_buttons"))),
      box(title = "Save to BigQuery", status = "success", solidHeader = TRUE, width = 6,
          p("Saves the current state of all tasks as a reviewed batch in ", tags$code("gantt_tasks"),
            ". Each save adds a new snapshot; nothing is overwritten. Submit to Boards shows this history."),
          bos_tz_dropdown_ui(ns, label = "Time zone of these task dates:",
                             help = "Saved with every task row and reused for the Submit to Boards history."),
          actionButton(ns("save_to_bq"), "Save Tasks to BigQuery", class = "btn-success", icon = icon("cloud-upload-alt")),
          br(), br(),
          htmlOutput(ns("save_status")))
    )
  )
}

# task data.frame -> gantt_tasks rows (shared with Submit to Boards)
gantt_rows_for_bq <- function(d, submission_result = "N/A", time_zone = NULL) {
  col <- function(n) if (n %in% names(d)) ifelse(is.na(d[[n]]), "", as.character(d[[n]])) else rep("", nrow(d))
  data.frame(task_name = col("Task_Name"), description = col("Description"), start_date = col("Start_Date"),
             end_date = col("End_Date"), duration_days = col("Duration_Days"), assignee = col("Assignee"),
             priority = col("Priority"), status = col("Status"), labels = col("Labels"),
             additional_notes = col("Additional_Notes"), submission_result = rep_len(as.character(submission_result), nrow(d)),
             time_zone = rep(bos_tz_value(time_zone), nrow(d)), stringsAsFactors = FALSE)
}

review_edit_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observe({
      api_manager$state_trigger_gantt()
      if (!is.null(api_manager$gantt_data)) {
        updateSelectInput(session, "select_task", choices = api_manager$gantt_data$Task_Name)
      }
    })

    output$editable_table <- DT::renderDataTable({
      req(api_manager$gantt_data)
      DT::datatable(api_manager$gantt_data, editable = TRUE, options = list(scrollX = TRUE, pageLength = 15))
    })

    observeEvent(input$editable_table_cell_edit, {
      info <- input$editable_table_cell_edit
      api_manager$gantt_data[info$row, info$col] <- info$value
      api_manager$trigger_state_update_gantt()
    })

    observeEvent(input$update_task, {
      req(api_manager$gantt_data, input$select_task)
      row_idx <- which(api_manager$gantt_data$Task_Name == input$select_task)

      if (length(row_idx) > 0) {
        if (!"Additional_Notes" %in% names(api_manager$gantt_data)) api_manager$gantt_data$Additional_Notes <- NA
        api_manager$gantt_data$Additional_Notes[row_idx] <- input$additional_notes

        if (input$additional_labels != "") {
          current_labels <- api_manager$gantt_data$Labels[row_idx]
          if (is.na(current_labels) || current_labels == "") {
            api_manager$gantt_data$Labels[row_idx] <- input$additional_labels
          } else {
            api_manager$gantt_data$Labels[row_idx] <- paste(current_labels, input$additional_labels, sep = ",")
          }
        }

        api_manager$trigger_state_update_gantt()
        showNotification("Task updated successfully!", type = "message")
      }
    })

    observeEvent(input$refresh_table, {
      api_manager$trigger_state_update_gantt()
    })

    # ---- task timeline (.ics) - engine in R/utils_ics.R ----
    timeline <- reactive({
      api_manager$state_trigger_gantt()
      ics_safe_build(ics_events_gantt, api_manager$gantt_data)
    })
    # Titan calendar: one all-day "Due" entry per task on its End Date (Events Scheduling > Events to Calendar)
    titan_due <- reactive({
      r <- timeline()
      r$events <- lapply(r$events, function(ev) {
        if (!is.null(ev$end_date) && !is.na(ev$end_date)) ev$date <- ev$end_date
        ev$end_date <- NULL; ev$summary <- paste0("Due: ", ev$summary); ev$uid <- paste0("due-", ev$uid); ev })
      r
    })
    DPET_ENV$titan_viz_hook(input, output, session, dpet_manager(api_manager), titan_due, "Gantt to Tickets")
    output$timeline_status <- renderUI(ics_status_html(timeline(), loaded = !is.null(api_manager$gantt_data)))
    output$download_calendar <- downloadHandler(
      filename = function() ics_filename("project_tasks"),
      content = function(file) ics_write_safe(function() timeline()$events, "Project Task Timeline", file),
      contentType = "text/calendar"
    )

    # ---- save a reviewed snapshot to BigQuery ----
    observeEvent(input$save_to_bq, {
      if (!isTRUE(api_manager$bq_authenticated)) { showNotification("Please connect to BigQuery first (API Settings > BigQuery).", type = "error"); return() }
      d <- api_manager$gantt_data
      if (is.null(d) || nrow(d) == 0) { showNotification("No tasks to save. Upload a Gantt file first.", type = "warning"); return() }
      output$save_status <- renderUI(tags$div(class = "status-info", icon("spinner", class = "fa-spin"), " Saving..."))
      tryCatch({
        tz <- bos_tz_value(input$time_zone)
        api_manager$gantt_time_zone <- tz
        batch <- paste0("Reviewed_", format(Sys.time(), "%Y-%m-%d_%H%M%S"))
        n <- api_manager$bq_insert_gantt_tasks(gantt_rows_for_bq(d, "N/A", tz), log_stage = "Saved", upload_batch = batch)
        output$save_status <- renderUI(tags$div(class = "status-success", icon("check-circle"),
                                                sprintf(" Saved %d task(s) to BigQuery (batch: %s)", n, batch)))
        showNotification(sprintf("Saved %d task(s) to BigQuery.", n), type = "message")
      }, error = function(e) {
        output$save_status <- renderUI(tags$div(class = "status-error", icon("times-circle"), " Error: ", conditionMessage(e)))
        showNotification(paste("Error:", conditionMessage(e)), type = "error")
      })
    })
  })
}
