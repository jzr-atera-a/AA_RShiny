# modules/Diet Planner/diet_visualizations/ui.R

diet_visualizations_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Select a Day to Visualize", status = "primary", solidHeader = TRUE, width = 12,
          p("Filter by Diet Type to find the logged day you want, then load its meal timeline."),
          fluidRow(
            column(4, selectInput(ns("viz_diet_type"), "Diet Type:", choices = NULL)),
            column(4, selectInput(ns("select_date"), "Date:", choices = NULL)),
            column(4, selectInput(ns("filter_row_type"), "Filter by Row Type (Optional):", choices = c("All Rows" = "all")))
          ),
          fluidRow(column(12, actionButton(ns("load_viz"), "Load Visualizations",
                                          class = "btn-success btn-lg", icon = icon("chart-pie"), style = "width: 100%;"))),
          hr(), htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(title = "Day Overview", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          htmlOutput(ns("day_header")),
          fluidRow(
            column(3, valueBoxOutput(ns("total_meals"), width = 12)),
            column(3, valueBoxOutput(ns("total_calories"), width = 12)),
            column(3, valueBoxOutput(ns("diet_type_box"), width = 12)),
            column(3, valueBoxOutput(ns("total_entries"), width = 12))
          )
      )
    ),

    fluidRow(
      box(title = "Meal Timeline", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE,
          htmlOutput(ns("timeline_html")))
    ),

    fluidRow(
      box(title = "Macro Breakdown per Meal", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE,
          plotlyOutput(ns("macro_chart"), height = "500px"))
    )
  )
}
