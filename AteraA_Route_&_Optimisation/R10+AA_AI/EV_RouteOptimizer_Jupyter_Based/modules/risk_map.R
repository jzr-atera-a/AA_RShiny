# modules/risk_map.R
# Risk Map Module - Interactive Visualization

# ============================================================================
# UI FUNCTION
# ============================================================================

risk_map_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Risk Map Filters",
        status = "primary",
        solidHeader = TRUE,
        width = 3,
        
        checkboxGroupInput(ns("risk_filter"),
                          "Risk Levels:",
                          choices = c("Critical" = "CRITICAL",
                                     "Medium" = "MEDIUM",
                                     "Low" = "LOW"),
                          selected = c("CRITICAL", "MEDIUM", "LOW")),
        
        checkboxGroupInput(ns("feature_filter"),
                          "Feature Types:",
                          choices = c(
                            "Roundabout" = "roundabout",
                            "Tunnel" = "tunnel",
                            "Junction" = "junction",
                            "Curve" = "curve",
                            "Traffic Signals" = "traffic_signals"
                          ),
                          selected = c("roundabout", "tunnel", "junction")),
        
        sliderInput(ns("min_confidence"),
                    "Min Confidence:",
                    min = 0, max = 1, value = 0.5, step = 0.1),
        
        actionButton(ns("update_map"),
                     "Update Map",
                     class = "btn-success btn-block",
                     icon = icon("sync")),
        
        br(),
        
        actionButton(ns("export_data"),
                     "Export Data",
                     class = "btn-info btn-block",
                     icon = icon("download"))
      ),
      
      box(
        title = "CAV Risk Visualization",
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

# ============================================================================
# SERVER FUNCTION
# ============================================================================

risk_map_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    map_data <- reactiveVal(NULL)
    stats <- reactiveVal(NULL)
    
    output$risk_map <- renderLeaflet({
      leaflet() %>%
        addTiles() %>%
        setView(lng = -1.0, lat = 52.5, zoom = 6)
    })
    
    observeEvent(input$update_map, {
      
      if (is.null(api_manager)) {
        showNotification("API manager not available", type = "error")
        return()
      }
      
      withProgress(message = 'Updating map...', value = 0, {
        
        tryCatch({
          
          incProgress(0.2, detail = "Gathering data")
          
          waypoints <- api_manager$cav_waypoints
          if (is.null(waypoints)) {
            showNotification("No waypoints. Generate route first.", type = "warning")
            return()
          }
          
          features <- api_manager$cav_features
          detections <- api_manager$cav_detections
          
          combined_data <- list()
          
          if (!is.null(features)) {
            features_filtered <- features %>%
              filter(risk_level %in% input$risk_filter)
            if (nrow(features_filtered) > 0) {
              combined_data[[length(combined_data) + 1]] <- features_filtered
            }
          }
          
          if (!is.null(detections)) {
            detections_filtered <- detections %>%
              filter(
                risk_level %in% input$risk_filter,
                confidence >= input$min_confidence
              )
            
            if (!all(c("lat", "lon") %in% names(detections_filtered))) {
              detections_filtered$lat <- runif(nrow(detections_filtered),
                                               min(waypoints$lat), max(waypoints$lat))
              detections_filtered$lon <- runif(nrow(detections_filtered),
                                               min(waypoints$lon), max(waypoints$lon))
            }
            
            if (nrow(detections_filtered) > 0) {
              combined_data[[length(combined_data) + 1]] <- detections_filtered
            }
          }
          
          incProgress(0.5, detail = "Processing markers")
          
          if (length(combined_data) == 0) {
            showNotification("No features to display", type = "info")
            return()
          }
          
          all_data <- do.call(rbind, lapply(combined_data, function(df) {
            df[, c("lat", "lon", "feature_type", "risk_level")]
          }))
          
          if (length(input$feature_filter) > 0) {
            all_data <- all_data %>%
              filter(feature_type %in% input$feature_filter)
          }
          
          if (nrow(all_data) == 0) {
            showNotification("No features match filters", type = "info")
            return()
          }
          
          map_data(all_data)
          
          stats_data <- list(
            total = nrow(all_data),
            critical = sum(all_data$risk_level == "CRITICAL"),
            medium = sum(all_data$risk_level == "MEDIUM"),
            low = sum(all_data$risk_level == "LOW"),
            avg_conf = if (!is.null(detections)) mean(detections$confidence, na.rm = TRUE) else 0,
            route_km = if (!is.null(waypoints)) max(waypoints$distance_from_start, na.rm = TRUE) / 1000 else 0
          )
          stats(stats_data)
          
          incProgress(0.7, detail = "Creating map")
          
          risk_colors <- c("CRITICAL" = "red", "MEDIUM" = "orange", "LOW" = "green")
          
          map <- leaflet(all_data) %>%
            addTiles() %>%
            fitBounds(
              lng1 = min(all_data$lon), lat1 = min(all_data$lat),
              lng2 = max(all_data$lon), lat2 = max(all_data$lat)
            )
          
          if (!is.null(waypoints)) {
            map <- map %>%
              addPolylines(
                lng = waypoints$lon,
                lat = waypoints$lat,
                color = "blue",
                weight = 3,
                opacity = 0.7,
                group = "Route"
              )
          }
          
          for (risk_level in c("CRITICAL", "MEDIUM", "LOW")) {
            data_subset <- all_data %>% filter(risk_level == !!risk_level)
            
            if (nrow(data_subset) > 0) {
              map <- map %>%
                addCircleMarkers(
                  data = data_subset,
                  lng = ~lon,
                  lat = ~lat,
                  color = risk_colors[risk_level],
                  fillColor = risk_colors[risk_level],
                  fillOpacity = 0.7,
                  radius = 8,
                  stroke = TRUE,
                  weight = 2,
                  popup = ~paste0("<b>", feature_type, "</b><br>Risk: ", risk_level),
                  group = risk_level
                )
            }
          }
          
          map <- map %>%
            addLayersControl(
              overlayGroups = c("Route", "CRITICAL", "MEDIUM", "LOW"),
              options = layersControlOptions(collapsed = FALSE)
            )
          
          output$risk_map <- renderLeaflet({ map })
          
          showNotification(
            paste("Map updated with", nrow(all_data), "features"),
            type = "message"
          )
          
        }, error = function(e) {
          showNotification(paste("Error:", e$message), type = "error")
        })
      })
    })
    
    observeEvent(input$export_data, {
      data <- map_data()
      if (is.null(data)) {
        showNotification("No data to export", type = "warning")
        return()
      }
      
      filename <- paste0("cav_risk_export_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
      write.csv(data, filename, row.names = FALSE)
      
      showNotification(paste("Exported to", filename), type = "message", duration = 5)
    })
    
    output$total_features_map <- renderValueBox({
      s <- stats()
      valueBox(if (is.null(s)) "0" else s$total,
              "Features", icon = icon("map-signs"), color = "blue")
    })
    
    output$critical_count <- renderValueBox({
      s <- stats()
      valueBox(if (is.null(s)) "0" else s$critical,
              "Critical", icon = icon("exclamation-triangle"), color = "red")
    })
    
    output$medium_count <- renderValueBox({
      s <- stats()
      valueBox(if (is.null(s)) "0" else s$medium,
              "Medium", icon = icon("exclamation-circle"), color = "orange")
    })
    
    output$low_count <- renderValueBox({
      s <- stats()
      valueBox(if (is.null(s)) "0" else s$low,
              "Low", icon = icon("info-circle"), color = "green")
    })
    
    output$avg_confidence <- renderValueBox({
      s <- stats()
      valueBox(if (is.null(s) || s$avg_conf == 0) "N/A" else sprintf("%.2f", s$avg_conf),
              "Avg Conf", icon = icon("percentage"), color = "purple")
    })
    
    output$route_length <- renderValueBox({
      s <- stats()
      valueBox(if (is.null(s) || s$route_km == 0) "N/A" else sprintf("%.1f km", s$route_km),
              "Route", icon = icon("route"), color = "teal")
    })
  })
}
