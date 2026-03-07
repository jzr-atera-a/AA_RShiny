# modules/risk_map/ui.R

risk_map_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Risk Map Filters",
        status = "primary",
        solidHeader = TRUE,
        width = 3,
        
        checkboxGroupInput(
          ns("risk_filter"),
          "Risk Levels:",
          choices = c("Critical" = "CRITICAL",
                      "Medium" = "MEDIUM",
                      "Low" = "LOW"),
          selected = c("CRITICAL", "MEDIUM", "LOW")
        ),
        
        br(),
        
        checkboxGroupInput(
          ns("feature_filter"),
          "Feature Types:",
          choices = c(
            "Roundabout" = "roundabout",
            "Tunnel" = "tunnel",
            "Junction" = "junction",
            "Curve" = "curve",
            "Lane Merge" = "lane_merge",
            "Pedestrian Crossing" = "pedestrian_crossing",
            "Traffic Signals" = "traffic_signals"
          ),
          selected = c("roundabout", "tunnel", "junction", "curve")
        ),
        
        br(),
        
        sliderInput(
          ns("min_confidence"),
          "Minimum Confidence:",
          min = 0,
          max = 1,
          value = 0.5,
          step = 0.1
        ),
        
        br(),
        
        actionButton(
          ns("update_map"),
          "Update Map",
          class = "btn-success",
          icon = icon("sync"),
          width = "100%"
        ),
        
        br(), br(),
        
        actionButton(
          ns("export_data"),
          "Export Data",
          class = "btn-info",
          icon = icon("download"),
          width = "100%"
        )
      ),
      
      box(
        title = "CAV Risk Visualization Map",
        status = "danger",
        solidHeader = TRUE,
        width = 9,
        
        leafletOutput(ns("risk_map"), height = 600)
      )
    ),
    
    fluidRow(
      box(
        title = "Risk Statistics",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(2, valueBoxOutput(ns("total_features_map"), width = NULL)),
          column(2, valueBoxOutput(ns("critical_count"), width = NULL)),
          column(2, valueBoxOutput(ns("medium_count"), width = NULL)),
          column(2, valueBoxOutput(ns("low_count"), width = NULL)),
          column(2, valueBoxOutput(ns("avg_confidence"), width = NULL)),
          column(2, valueBoxOutput(ns("route_length"), width = NULL))
        )
      )
    )
  )
}
