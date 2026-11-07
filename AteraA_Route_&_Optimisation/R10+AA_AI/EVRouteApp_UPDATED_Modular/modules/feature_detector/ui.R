# modules/feature_detector/ui.R

feature_detector_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Feature Detection Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        p(class = "text-muted",
          "Detect road features and hazards from OpenStreetMap data."),
        
        br(),
        
        checkboxGroupInput(
          ns("feature_types"),
          "Features to Detect:",
          choices = c(
            "Roundabouts" = "roundabout",
            "Junctions" = "junction",
            "Traffic Signals" = "traffic_signals",
            "Motorway Junctions" = "motorway_junction",
            "Curves (geometry-based)" = "curve"
          ),
          selected = c("roundabout", "junction", "curve")
        ),
        
        br(),
        
        sliderInput(
          ns("curve_threshold"),
          "Curve Detection Threshold (degrees):",
          min = 15,
          max = 60,
          value = 30,
          step = 5
        ),
        
        p(class = "text-muted small",
          "Larger values detect sharper curves only."),
        
        br(),
        
        actionButton(
          ns("detect_features"),
          "Detect Features",
          class = "btn-success",
          icon = icon("search"),
          width = "100%"
        ),
        
        br(), br(),
        
        uiOutput(ns("detection_status"))
      ),
      
      box(
        title = "Detection Summary",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        h5("Feature Detection Methods:"),
        tags$ul(
          tags$li(strong("OSM Tags:"), "Extract from OpenStreetMap database"),
          tags$li(strong("Geometry Analysis:"), "Detect curves from bearing changes"),
          tags$li(strong("Network Topology:"), "Identify junctions from road connectivity")
        ),
        
        br(),
        
        fluidRow(
          column(4, valueBoxOutput(ns("total_features"), width = NULL)),
          column(4, valueBoxOutput(ns("critical_features"), width = NULL)),
          column(4, valueBoxOutput(ns("feature_types_found"), width = NULL))
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Detected Features",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        
        DTOutput(ns("features_table"))
      )
    )
  )
}
