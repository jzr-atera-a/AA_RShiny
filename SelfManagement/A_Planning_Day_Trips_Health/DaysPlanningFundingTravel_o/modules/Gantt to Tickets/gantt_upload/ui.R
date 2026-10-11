# modules/Gantt to Tickets/gantt_upload/ui.R

gantt_upload_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Upload Gantt Chart", status = "primary", solidHeader = TRUE, width = 12,
          p("Upload an Excel file with your Gantt chart tasks, or download the template below to get started."),
          fluidRow(
            column(6, fileInput(ns("gantt_file"), "Select Excel File:", accept = c(".xlsx", ".xls"))),
            column(6, br(), downloadButton(ns("download_template"), "Download Template", class = "btn-info"))
          ),
          div(class = "alert alert-info",
              tags$strong("Required columns:"), " Task_Name, Description, Start_Date, End_Date, ",
              "Duration_Days, Assignee, Priority, Status, Labels")
      )
    ),
    fluidRow(
      box(title = "Preview", status = "info", solidHeader = TRUE, width = 12,
          DT::dataTableOutput(ns("preview_table")))
    )
  )
}
