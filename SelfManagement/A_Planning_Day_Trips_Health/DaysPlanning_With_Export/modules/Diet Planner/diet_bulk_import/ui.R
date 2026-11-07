# modules/Diet Planner/diet_bulk_import/ui.R

diet_bulk_import_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Bulk Import Diet Log to BigQuery",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("Paste or Generate a Day's Diet Log"),
        p("Paste a complete day of meals to parse and upload to BigQuery."),

        div(class = "alert alert-info",
            tags$strong("Expected Format:"),
            tags$ul(
              tags$li("Day metadata: [Date], [Diet Type], [Dietary Restrictions]"),
              tags$li("[row_type]: Meal | Summary"),
              tags$li("[meal_name], [meal_details]"),
              tags$li("[meal_time], [calories_macros]"),
              tags$li("[observations]")
            )
        ),

        textAreaInput(ns("diet_text"), "Paste Diet Log Here:", height = "500px",
                      placeholder = "[2026-07-10]\n[Keto]\n[Gluten-free]\n\n[row_type]: Meal\n..."),

        fluidRow(
          column(4, actionButton(ns("parse"), "Parse Diet Log", class = "btn-info btn-lg", icon = icon("cogs"), width = "100%")),
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
