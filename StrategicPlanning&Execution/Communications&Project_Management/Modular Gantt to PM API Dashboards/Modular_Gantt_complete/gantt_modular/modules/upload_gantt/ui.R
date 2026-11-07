# modules/upload_gantt/ui.R
# Upload Gantt Chart UI
# =====================

upload_gantt_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Upload Excel File",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        fileInput(ns("gantt_file"), "Choose Excel File (.xlsx or .xls)",
                  accept = c(".xlsx", ".xls")),
        hr(),
        h4("Expected Excel Format:"),
        p("Your Excel file should contain the following columns:"),
        tags$ul(
          tags$li(tags$strong("Task_Name"), " - Name of the task (required)"),
          tags$li(tags$strong("Description"), " - Detailed description of the task (optional)"),
          tags$li(tags$strong("Start_Date"), " - Start date (format: YYYY-MM-DD or MM/DD/YYYY)"),
          tags$li(tags$strong("End_Date"), " - End date (format: YYYY-MM-DD or MM/DD/YYYY)"),
          tags$li(tags$strong("Duration_Days"), " - Duration in days (optional if dates provided)"),
          tags$li(tags$strong("Assignee"), " - Person assigned to task (optional)"),
          tags$li(tags$strong("Priority"), " - High/Medium/Low (optional)"),
          tags$li(tags$strong("Status"), " - To Do/In Progress/Done (optional)"),
          tags$li(tags$strong("Labels"), " - Comma-separated tags (optional)")
        ),
        downloadButton(ns("download_template"), "Download Excel Template")
      )
    ),
    fluidRow(
      box(
        title = "Preview Uploaded Data",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}
