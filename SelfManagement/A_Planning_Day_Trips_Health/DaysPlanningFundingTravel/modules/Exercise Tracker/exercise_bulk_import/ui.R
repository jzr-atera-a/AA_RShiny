# modules/Exercise Tracker/exercise_bulk_import/ui.R

exercise_bulk_import_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Bulk Import Workout Session to BigQuery",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("Paste or Generate a Workout Session"),
        p("Paste a complete workout session to parse and upload to BigQuery."),

        div(class = "alert alert-info",
            tags$strong("Expected Format:"),
            tags$ul(
              tags$li("Session metadata: [Date], [Session Type], [Session Notes]"),
              tags$li("[row_type]: Exercise | Summary"),
              tags$li("[exercise_category], [exercise_name], [exercise_details]"),
              tags$li("[metric_primary], [metric_secondary], [calories_burned]"),
              tags$li("[observations]")
            )
        ),

        textAreaInput(ns("exercise_text"), "Paste Workout Session Here:", height = "500px",
                      placeholder = "[2026-07-10]\n[Weights]\n[Focus on upper body]\n\n[row_type]: Exercise\n..."),

        fluidRow(
          column(4, actionButton(ns("parse"), "Parse Session", class = "btn-info btn-lg", icon = icon("cogs"), width = "100%")),
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
