# modules/feature_detector.R
# Feature Detector Module - OSM-based Road Feature Detection

# ============================================================================
# UI FUNCTION  
# ============================================================================

feature_detector_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Feature Detection Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        checkboxGroupInput(ns("feature_types"),
                          "Features to Detect:",
                          choices = c(
                            "Roundabouts" = "roundabout",
                            "Junctions" = "junction",
                            "Traffic Signals" = "traffic_signals",
                            "Motorway Junctions" = "motorway_junction",
                            "Curves (geometry)" = "curve"
                          ),
                          selected = c("roundabout", "junction", "curve")),
        
        sliderInput(ns("curve_threshold"),
                    "Curve Detection Threshold (degrees):",
                    min = 15, max = 60, value = 30, step = 5),
        
        actionButton(ns("detect_features"),
                     "Detect Features",
                     class = "btn-success btn-block",
                     icon = icon("search")),
        
        br(), br(),
        uiOutput(ns("detection_status"))
      ),
      
      box(
        title = "Detection Summary",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        h5("Detection Methods:"),
        tags$ul(
          tags$li(strong("OSM Tags:"), "Roundabouts, traffic signals from OpenStreetMap"),
          tags$li(strong("Geometry:"), "Curve detection from bearing changes"),
          tags$li(strong("Risk Classification:"), "CRITICAL/MEDIUM/LOW assignment")
        ),
        
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

# ============================================================================
# SERVER FUNCTION
# ============================================================================

feature_detector_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    features_data <- reactiveVal(NULL)
    detection_summary <- reactiveVal(NULL)
    
    observeEvent(input$detect_features, {
      
      if (is.null(api_manager) || is.null(api_manager$network_data)) {
        output$detection_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  "No network data. Download road network first.")
        })
        return()
      }
      
      if (is.null(api_manager$cav_waypoints)) {
        output$detection_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  "No waypoints. Generate waypoints first.")
        })
        return()
      }
      
      withProgress(message = 'Detecting features...', value = 0, {
        
        tryCatch({
          
          all_features <- list()
          waypoints <- api_manager$cav_waypoints
          network_data <- api_manager$network_data
          
          incProgress(0.3, detail = "Detecting curves")
          
          if ("curve" %in% input$feature_types) {
            curves <- detect_curves(waypoints, threshold_degrees = input$curve_threshold)
            if (nrow(curves) > 0) all_features[[length(all_features) + 1]] <- curves
          }
          
          incProgress(0.5, detail = "Querying OSM")
          
          if (any(c("roundabout", "traffic_signals") %in% input$feature_types)) {
            bbox <- network_data$bbox
            
            if ("roundabout" %in% input$feature_types) {
              tryCatch({
                rb_query <- opq(bbox) %>%
                  add_osm_feature(key = "junction", value = "roundabout") %>%
                  osmdata_sf()
                
                if (!is.null(rb_query$osm_points) && nrow(rb_query$osm_points) > 0) {
                  coords <- st_coordinates(rb_query$osm_points)
                  rb_df <- data.frame(
                    lat = coords[, 2], lon = coords[, 1],
                    feature_type = "roundabout", 
                    angle_change = NA, sequence = NA
                  )
                  all_features[[length(all_features) + 1]] <- rb_df
                }
              }, error = function(e) cat("Warning: roundabouts query failed\n"))
            }
            
            if ("traffic_signals" %in% input$feature_types) {
              tryCatch({
                sig_query <- opq(bbox) %>%
                  add_osm_feature(key = "highway", value = "traffic_signals") %>%
                  osmdata_sf()
                
                if (!is.null(sig_query$osm_points) && nrow(sig_query$osm_points) > 0) {
                  coords <- st_coordinates(sig_query$osm_points)
                  sig_df <- data.frame(
                    lat = coords[, 2], lon = coords[, 1],
                    feature_type = "traffic_signals",
                    angle_change = NA, sequence = NA
                  )
                  all_features[[length(all_features) + 1]] <- sig_df
                }
              }, error = function(e) cat("Warning: signals query failed\n"))
            }
          }
          
          incProgress(0.8, detail = "Processing results")
          
          if (length(all_features) == 0) stop("No features detected")
          
          combined <- do.call(rbind, all_features)
          combined$risk_level <- sapply(combined$feature_type, classify_risk)
          combined$feature_id <- paste0("FT_", sprintf("%04d", seq_len(nrow(combined))))
          
          summary <- list(
            total = nrow(combined),
            critical = sum(combined$risk_level == "CRITICAL"),
            medium = sum(combined$risk_level == "MEDIUM"),
            low = sum(combined$risk_level == "LOW"),
            types = length(unique(combined$feature_type))
          )
          
          features_data(combined)
          detection_summary(summary)
          
          if (!is.null(api_manager)) {
            api_manager$cav_features <- combined
          }
          
          output$detection_status <- renderUI({
            tags$div(class = "alert alert-success",
                    sprintf("Found %d features (%d critical)", summary$total, summary$critical))
          })
          
        }, error = function(e) {
          output$detection_status <- renderUI({
            tags$div(class = "alert alert-danger", e$message)
          })
        })
      })
    })
    
    output$total_features <- renderValueBox({
      s <- detection_summary()
      valueBox(
        if (is.null(s)) "0" else s$total,
        "Total Features", icon = icon("map-signs"), color = "blue"
      )
    })
    
    output$critical_features <- renderValueBox({
      s <- detection_summary()
      valueBox(
        if (is.null(s)) "0" else s$critical,
        "Critical Risk", icon = icon("exclamation-triangle"), color = "red"
      )
    })
    
    output$feature_types_found <- renderValueBox({
      s <- detection_summary()
      valueBox(
        if (is.null(s)) "0" else s$types,
        "Feature Types", icon = icon("list"), color = "green"
      )
    })
    
    output$features_table <- renderDT({
      features <- features_data()
      if (is.null(features)) {
        return(datatable(data.frame(Message = "Detect features first")))
      }
      
      datatable(features %>% select(feature_id, feature_type, lat, lon, risk_level),
                options = list(pageLength = 10, scrollX = TRUE))
    })
  })
}
