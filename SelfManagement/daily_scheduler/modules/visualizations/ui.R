# modules/visualizations/ui.R

visualizations_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Rich Itinerary Visualizations",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4("Select a Day to Visualize"),
        p("Filter by Type of Day and Country to find the planned day you want, then load its itinerary."),
        
        fluidRow(
          column(3, selectInput(ns("viz_day_type"), "Type of Day:", choices = NULL)),
          column(3, selectInput(ns("viz_country"), "Country:", choices = NULL)),
          column(3, selectInput(ns("select_date"), "Date:", choices = NULL)),
          column(3, selectInput(ns("filter_row_type"), "Filter by Row Type (Optional):",
                                choices = c("All Rows" = "all")))
        ),
        
        fluidRow(
          column(12, actionButton(ns("load_viz"), "Load Visualizations",
                                 class = "btn-success btn-lg", icon = icon("chart-bar"),
                                 style = "width: 100%;"))
        ),
        
        hr(),
        htmlOutput(ns("status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Day Overview",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        htmlOutput(ns("day_header")),
        fluidRow(
          column(3, valueBoxOutput(ns("total_locations"), width = 12)),
          column(3, valueBoxOutput(ns("total_transport"), width = 12)),
          column(3, valueBoxOutput(ns("total_time"), width = 12)),
          column(3, valueBoxOutput(ns("total_entries"), width = 12))
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Itinerary Timeline",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        htmlOutput(ns("timeline_html"))
      )
    ),
    
    fluidRow(
      box(
        title = "Time Allocation Trends",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        plotlyOutput(ns("time_chart"), height = "500px")
      )
    )
  )
}
