# modules/Exercise Tracker/exercise_visualizations/ui.R

exercise_visualizations_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Select a Session to Visualize", status = "primary", solidHeader = TRUE, width = 12,
          p("Filter by Session Type to find the logged workout you want, then load its timeline."),
          fluidRow(
            column(4, selectInput(ns("viz_session_type"), "Session Type:", choices = NULL)),
            column(4, selectInput(ns("select_date"), "Date:", choices = NULL)),
            column(4, selectInput(ns("filter_row_type"), "Filter by Row Type (Optional):", choices = c("All Rows" = "all")))
          ),
          fluidRow(column(12, actionButton(ns("load_viz"), "Load Visualizations",
                                          class = "btn-success btn-lg", icon = icon("chart-bar"), style = "width: 100%;"))),
          hr(), htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(title = "Session Overview", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          htmlOutput(ns("day_header")),
          fluidRow(
            column(3, valueBoxOutput(ns("total_exercises"), width = 12)),
            column(3, valueBoxOutput(ns("total_calories"), width = 12)),
            column(3, valueBoxOutput(ns("session_type_box"), width = 12)),
            column(3, valueBoxOutput(ns("total_entries"), width = 12))
          )
      )
    ),

    fluidRow(
      box(title = "Session Timeline", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE,
          htmlOutput(ns("timeline_html")))
    ),

    fluidRow(
      box(title = "Calories Burned per Entry", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE,
          plotlyOutput(ns("calories_chart"), height = "500px"))
    )
  )
}
