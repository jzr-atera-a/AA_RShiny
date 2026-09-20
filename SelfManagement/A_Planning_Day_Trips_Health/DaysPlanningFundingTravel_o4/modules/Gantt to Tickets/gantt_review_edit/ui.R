# modules/Gantt to Tickets/gantt_review_edit/ui.R

gantt_review_edit_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Edit Tasks", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(6, p("Double-click a cell to edit it directly.")),
            column(6, downloadButton(ns("download_calendar"), "📅 Download Task Timeline", class = "btn-success", style = "float: right; margin-bottom: 10px;"))
          ),
          DT::dataTableOutput(ns("editable_table")),
          br(),
          actionButton(ns("refresh_table"), "Refresh Table", class = "btn-info", icon = icon("sync"))
      )
    ),
    fluidRow(
      box(title = "Add Notes / Labels to a Task", status = "info", solidHeader = TRUE, width = 12,
          selectInput(ns("select_task"), "Select Task:", choices = NULL),
          textAreaInput(ns("additional_notes"), "Additional Notes:", rows = 3),
          textInput(ns("additional_labels"), "Additional Labels (comma-separated):", placeholder = "e.g., urgent, review"),
          actionButton(ns("update_task"), "Update Task", class = "btn-success")
      )
    ),
    fluidRow(
      box(title = "Save to BigQuery", status = "success", solidHeader = TRUE, width = 12,
          p("Save the current state of all tasks as a reviewed batch - this is what Browse Data and ",
            "Submit to Boards' history will show. You can save again after further edits; each save ",
            "adds a new snapshot rather than overwriting the last one."),
          actionButton(ns("save_to_bq"), "Save Tasks to BigQuery", class = "btn-success btn-lg", icon = icon("cloud-upload-alt")),
          br(), br(),
          htmlOutput(ns("save_status"))
      )
    )
  )
}
