# modules/cav_route_sampler/ui.R

cav_route_sampler_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Route Sampling Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        p(class = "text-muted", 
          "Generate evenly-spaced waypoints from the optimized route for CAV analysis."),
        
        br(),
        
        sliderInput(
          ns("sampling_interval"),
          "Sampling Interval (meters):",
          min = 25,
          max = 200,
          value = 50,
          step = 25
        ),
        
        p(class = "text-muted small", 
          "Smaller intervals = more waypoints = higher accuracy but more data."),
        
        br(),
        
        actionButton(
          ns("generate_waypoints"),
          "Generate Waypoints",
          class = "btn-success",
          icon = icon("map-marked-alt"),
          width = "100%"
        ),
        
        br(), br(),
        
        uiOutput(ns("sampling_status"))
      ),
      
      box(
        title = "Sampling Information",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        h5("About Route Sampling:"),
        p("Route sampling creates evenly-spaced waypoints along the route for detailed analysis."),
        
        tags$ul(
          tags$li("Waypoints are generated at fixed distance intervals"),
          tags$li("Uses Haversine formula for accurate distance calculations"),
          tags$li("Default 50m spacing provides good balance of detail and performance"),
          tags$li("Waypoints are used for Street View image capture and feature detection")
        ),
        
        br(),
        
        fluidRow(
          column(3, valueBoxOutput(ns("route_distance"), width = NULL)),
          column(3, valueBoxOutput(ns("waypoint_count"), width = NULL)),
          column(3, valueBoxOutput(ns("estimated_images"), width = NULL)),
          column(3, valueBoxOutput(ns("estimated_cost"), width = NULL))
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Generated Waypoints Preview",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        collapsed = FALSE,
        
        DTOutput(ns("waypoints_table"))
      )
    )
  )
}
