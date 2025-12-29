# modules/review_edit/ui.R
# Review & Edit Tasks UI
# ======================

review_edit_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Task List - Edit as Needed",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        DT::dataTableOutput(ns("editable_table")),
        br(),
        actionButton(ns("refresh_table"), "Refresh Table", icon = icon("refresh"))
      )
    ),
    fluidRow(
      box(
        title = "Add Additional Information",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        selectInput(ns("select_task"), "Select Task:", choices = NULL),
        textAreaInput(ns("additional_notes"), "Additional Notes:", rows = 3),
        textInput(ns("additional_labels"), "Add Labels (comma-separated):", ""),
        actionButton(ns("update_task"), "Update Task", class = "btn-primary")
      )
    )
  )
}
