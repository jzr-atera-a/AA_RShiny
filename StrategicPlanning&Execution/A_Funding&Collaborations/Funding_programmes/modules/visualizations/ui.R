# modules/visualizations/ui.R

visualizations_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Filter Funding Programmes",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        p("Filter by location and/or date range, then load results. Leave a filter at its default to ignore it."),
        
        fluidRow(
          column(3, selectInput(ns("viz_category"), "Category:", choices = c("All" = "all"))),
          column(3, selectInput(ns("viz_country"), "Country:", choices = c("All" = "all"))),
          column(3, selectInput(ns("viz_cityregion"), "City / Region:", choices = c("All" = "all"))),
          column(3, br(), actionButton(ns("load_viz"), "Load Programmes",
                                       class = "btn-success btn-lg", icon = icon("chart-bar"),
                                       style = "width: 100%;"))
        ),
        
        fluidRow(
          column(6,
                 checkboxInput(ns("filter_start_date"), "Filter by Start Date for Applying", value = FALSE),
                 conditionalPanel(
                   condition = sprintf("input['%s']", ns("filter_start_date")),
                   dateRangeInput(ns("start_date_range"), "Start Date Range:",
                                  start = Sys.Date(), end = Sys.Date() + 365)
                 )
          ),
          column(6,
                 checkboxInput(ns("filter_deadline"), "Filter by Deadline", value = FALSE),
                 conditionalPanel(
                   condition = sprintf("input['%s']", ns("filter_deadline")),
                   dateRangeInput(ns("deadline_range"), "Deadline Range:",
                                  start = Sys.Date(), end = Sys.Date() + 365)
                 )
          )
        ),
        
        div(class = "alert alert-info", style = "font-size: 0.9em;",
            tags$strong("Note:"), " Date filters only match programmes with a specific YYYY-MM-DD date in ",
            "that field. Programmes marked \"Rolling basis\" or \"Not confirmed\" won't match a date range ",
            "filter but will still appear when no date filter is applied."),
        
        hr(),
        htmlOutput(ns("status"))
      )
    ),
    
    fluidRow(
      box(title = "Overview", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          fluidRow(
            column(3, valueBoxOutput(ns("total_programmes"), width = 12)),
            column(3, valueBoxOutput(ns("total_categories"), width = 12)),
            column(3, valueBoxOutput(ns("total_countries"), width = 12)),
            column(3, valueBoxOutput(ns("upcoming_deadlines"), width = 12))
          )
      )
    ),
    
    fluidRow(
      box(title = "Programmes by Category", status = "warning", solidHeader = TRUE, width = 12,
          collapsible = TRUE,
          plotlyOutput(ns("category_chart"), height = "400px"))
    ),
    
    fluidRow(
      box(title = "Programme Details", status = "success", solidHeader = TRUE, width = 12,
          collapsible = TRUE,
          htmlOutput(ns("programme_cards")))
    )
  )
}
