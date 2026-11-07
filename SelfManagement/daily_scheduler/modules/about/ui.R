# modules/about/ui.R

about_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "About This Application",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        
        h3("Daily Scheduler Suite v1.0"),
        p("An integrated platform combining AI-powered day/trip schedule generation with cloud database storage and rich itinerary visualization."),
        
        hr(),
        
        h4("Features:"),
        tags$ul(
          tags$li(tags$strong("AI Schedule Generation:"), " Claude AI plans an optimal day, minimizing travel time/distance and respecting opening hours"),
          tags$li(tags$strong("BigQuery Integration:"), " Cloud database storage (atera-2.business_strategy.day_scheduler)"),
          tags$li(tags$strong("Location & Transport Rows:"), " Each stop and each transfer between stops gets its own row"),
          tags$li(tags$strong("Day Summary:"), " A closing row with total day time and key insights"),
          tags$li(tags$strong("Rich Visualizations:"), " Interactive HTML timeline with Plotly time-allocation charts")
        ),
        
        hr(),
        
        h4("Data Schema (BigQuery):"),
        p("Table: atera-2.business_strategy.day_scheduler"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - schedule_date (STRING)\n  - day_type (STRING)\n  - country (STRING)\n  - city (STRING)\n  - trip_details (STRING)\n  - row_type (STRING)\n  - row_sequence (INTEGER)\n  - location_name (STRING)\n  - location_details (STRING)\n  - opening_hours (STRING)\n  - recommended_time (STRING)\n  - observations (STRING)"),
        
        hr(),
        
        h4("Row Structure:"),
        tags$ul(
          tags$li(tags$strong("Location"), " row - one per place visited: name, address/description, opening hours, recommended time window, and what to expect"),
          tags$li(tags$strong("Transport"), " row - follows every location (except the last): how to get to the next stop, expected travel time, and practical directions"),
          tags$li(tags$strong("Summary"), " row - one per day, at the end: a one-line day title, the total time for the whole day, and key insights")
        ),
        p(tags$em("The Recommended/Expected Time and Observations columns are reused across all three row types.")),
        
        hr(),
        
        h4("Modular Architecture:"),
        p("This application uses a modern modular architecture where each feature is a self-contained module."),
        tags$ul(
          tags$li("Enable/disable modules by editing modules/_module_registry.yml"),
          tags$li("Each module has its own UI, server, manifest, and README"),
          tags$li("Zero namespace conflicts with proper NS() usage"),
          tags$li("Reactive state sharing via api_manager$state_trigger()")
        ),
        
        hr(),
        
        p("Version 1.0.0 - Modular Architecture | Row-Based Schedule Schema", 
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}
