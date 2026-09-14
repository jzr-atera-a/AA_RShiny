# modules/Travel Planning/travel_itinerary_planner/ui.R
# ORIGINAL UI - Only added geo download buttons, no styling changes

travel_itinerary_planner_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    shinyjs::useShinyjs(),
    
    # Step 1: Discovery
    fluidRow(
      column(12,
        tags$h3("Step 1: Discover Places")
      )
    ),
    
    fluidRow(
      column(4,
        tags$label("Destination:"),
        textInput(ns("destination"), NULL, placeholder = "e.g., Paris, Tokyo")
      ),
      column(4,
        tags$label("Number of Places:"),
        sliderInput(ns("num_places"), NULL, 1, 10, 5)
      ),
      column(4,
        tags$br(),
        actionButton(ns("discover_places"), "Discover Places", class = "btn-primary")
      )
    ),
    
    # Discovery loading and results
    tags$div(
      id = ns("loading_spinner"),
      style = "display:none;",
      tags$p("Loading...")
    ),
    
    uiOutput(ns("discovery_status")),
    uiOutput(ns("places_checkboxes")),
    uiOutput(ns("places_counter")),
    
    tags$hr(),
    
    # Step 2: Planning
    fluidRow(
      column(12,
        tags$h3("Step 2: Plan Your Trip")
      )
    ),
    
    fluidRow(
      column(3,
        tags$label("Start Date:"),
        dateInput(ns("trip_start_date"), NULL, value = Sys.Date() + 7)
      ),
      column(3,
        tags$label("Number of Days:"),
        sliderInput(ns("num_days"), NULL, 1, 14, 3)
      ),
      column(3,
        tags$label("End Date:"),
        uiOutput(ns("trip_end_date_display"))
      ),
      column(3,
        tags$br(),
        actionButton(ns("generate_itinerary"), "Generate Itinerary", class = "btn-success")
      )
    ),
    
    # Itinerary loading
    tags$div(
      id = ns("itinerary_loading_spinner"),
      style = "display:none;",
      tags$p("Generating itinerary...")
    ),
    
    uiOutput(ns("itinerary_status")),
    
    tags$hr(),
    
    # Itinerary content (hidden until generated)
    tags$div(
      id = ns("itinerary_content"),
      style = "display:none;",
      
      # Download buttons - Documents
      tags$h4("Download Itinerary"),
      fluidRow(
        column(3, downloadButton(ns("download_html"), "HTML + Map")),
        column(3, downloadButton(ns("download_pdf"), "PDF")),
        column(3, downloadButton(ns("download_calendar"), "ICS Calendar")),
        column(3, downloadButton(ns("reset_discovery"), "Reset"))
      ),
      
      tags$hr(),
      
      # Download buttons - Geo Files
      tags$h4("Download Geo Files"),
      fluidRow(
        column(4, downloadButton(ns("download_kml"), "Google Maps (.kml)")),
        column(4, downloadButton(ns("download_gpx"), "GPS Navigation (.gpx)")),
        column(4, downloadButton(ns("download_gmaps_link"), "Google Maps Link"))
      ),
      
      tags$hr(),
      
      # Itinerary display
      uiOutput(ns("itinerary_html"))
    ),
    
    tags$hr(),
    
    # Map
    tags$h3("Map View"),
    fluidRow(
      column(8,
        plotly::plotlyOutput(ns("trip_map"), height = "500px")
      ),
      column(4,
        tags$h4("Details"),
        uiOutput(ns("attraction_detail"))
      )
    )
  )
}
