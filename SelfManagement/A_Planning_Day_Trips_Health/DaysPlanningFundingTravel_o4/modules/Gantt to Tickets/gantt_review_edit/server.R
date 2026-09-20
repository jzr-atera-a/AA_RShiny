# modules/Gantt to Tickets/gantt_review_edit/server.R

gantt_review_edit_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    source("R/utils_calendar_export.R", local = TRUE)

    # Source calendar utility

    observe({
      api_manager$state_trigger_gantt()
      if (!is.null(api_manager$gantt_tasks_data) && nrow(api_manager$gantt_tasks_data) > 0) {
        updateSelectInput(session, "select_task", choices = api_manager$gantt_tasks_data$Task_Name)
      }
    })

    output$editable_table <- DT::renderDataTable({
      api_manager$state_trigger_gantt()
      req(api_manager$gantt_tasks_data, nrow(api_manager$gantt_tasks_data) > 0)
      DT::datatable(api_manager$gantt_tasks_data, editable = TRUE, options = list(scrollX = TRUE, pageLength = 15))
    })

    observeEvent(input$editable_table_cell_edit, {
      info <- input$editable_table_cell_edit
      api_manager$gantt_tasks_data[info$row, info$col] <- info$value
      api_manager$trigger_state_update_gantt()
    })

    observeEvent(input$update_task, {
      req(api_manager$gantt_tasks_data, input$select_task)
      row_idx <- which(api_manager$gantt_tasks_data$Task_Name == input$select_task)

      if (length(row_idx) > 0) {
        if (!"Additional_Notes" %in% names(api_manager$gantt_tasks_data)) {
          api_manager$gantt_tasks_data$Additional_Notes <- NA
        }
        api_manager$gantt_tasks_data$Additional_Notes[row_idx] <- input$additional_notes

        if (nchar(input$additional_labels) > 0) {
          current_labels <- api_manager$gantt_tasks_data$Labels[row_idx]
          if (is.na(current_labels) || current_labels == "") {
            api_manager$gantt_tasks_data$Labels[row_idx] <- input$additional_labels
          } else {
            api_manager$gantt_tasks_data$Labels[row_idx] <- paste(current_labels, input$additional_labels, sep = ",")
          }
        }

        api_manager$trigger_state_update_gantt()
        showNotification("Task updated successfully!", type = "message")
      }
    })

    observeEvent(input$refresh_table, { api_manager$trigger_state_update_gantt() })

    output$download_calendar <- downloadHandler(
      filename = function() paste0("project_tasks_", format(Sys.Date(), "%Y%m%d"), ".ics"),
      content = function(file) {
        tryCatch({
          data <- api_manager$gantt_tasks_data
          if (is.null(data) || nrow(data) == 0) {
            showNotification("No tasks to export", type = "warning")
            return()
          }

          # Rename columns for calendar export
          cal_data <- data
          if ("Start_Date" %in% names(cal_data)) names(cal_data)[names(cal_data) == "Start_Date"] <- "date"
          if ("End_Date" %in% names(cal_data)) names(cal_data)[names(cal_data) == "End_Date"] <- "end_date"
          if ("Task_Name" %in% names(cal_data)) names(cal_data)[names(cal_data) == "Task_Name"] <- "name"

          ics_lines <- generate_calendar_ics(
            title = "Project Task Timeline",
            items = cal_data,
            date_col = "date",
            duration_minutes = 480,  # All-day events for tasks
            description = "Project task - Exported from Business Operations Suite",
            item_col = if ("name" %in% names(cal_data)) "name" else "Task_Name"
          )

          export_calendar_file(ics_lines, file)
          showNotification("✓ Project timeline exported successfully", type = "message")

        }, error = function(e) {
          showNotification(paste("Error exporting calendar:", e$message), type = "error")
        })
      }
    )

    observeEvent(input$save_to_bq, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      if (is.null(api_manager$gantt_tasks_data) || nrow(api_manager$gantt_tasks_data) == 0) {
        showNotification("No tasks to save. Upload a Gantt file first.", type = "warning"); return()
      }

      output$save_status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Saving...") })

      tryCatch({
        d <- api_manager$gantt_tasks_data
        df <- data.frame(
          task_name = d$Task_Name %||% "",
          description = if ("Description" %in% names(d)) as.character(d$Description) else "",
          start_date = if ("Start_Date" %in% names(d)) as.character(d$Start_Date) else "",
          end_date = if ("End_Date" %in% names(d)) as.character(d$End_Date) else "",
          duration_days = if ("Duration_Days" %in% names(d)) as.character(d$Duration_Days) else "",
          assignee = if ("Assignee" %in% names(d)) as.character(d$Assignee) else "",
          priority = if ("Priority" %in% names(d)) as.character(d$Priority) else "",
          status = if ("Status" %in% names(d)) as.character(d$Status) else "",
          labels = if ("Labels" %in% names(d)) as.character(d$Labels) else "",
          additional_notes = if ("Additional_Notes" %in% names(d)) as.character(d$Additional_Notes) else "",
          submission_result = "N/A",
          stringsAsFactors = FALSE
        )

        batch_label <- paste0("Reviewed_", format(Sys.time(), "%Y-%m-%d_%H%M%S"))
        rows_uploaded <- api_manager$bq_insert_gantt_tasks(df, log_stage = "Saved", upload_batch = batch_label)

        output$save_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Saved %d task(s) to BigQuery (batch: %s)", rows_uploaded, batch_label))
        })
        showNotification(sprintf("✓ Saved %d task(s)!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$save_status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$save_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
