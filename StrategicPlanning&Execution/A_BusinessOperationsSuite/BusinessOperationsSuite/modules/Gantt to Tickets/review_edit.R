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
    )
  )
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
  })
}
