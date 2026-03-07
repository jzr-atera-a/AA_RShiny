# modules/risk_map/server.R

risk_map_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    map_data <- reactiveVal(NULL)
    stats <- reactiveVal(NULL)
    
    # Initialize map
    output$risk_map <- renderLeaflet({
      leaflet() %>%
        addTiles() %>%
        setView(lng = -1.0, lat = 52.5, zoom = 6)
    })
    
    observeEvent(input$update_map, {
      
      # Check for required data
      if (is.null(api_manager)) {
        showNotification("API manager not available", type = "error")
        return()
      }
      
      withProgress(message = 'Updating map...', value = 0, {
        
        tryCatch({
          
          incProgress(0.2, detail = "Gathering data")
          
          # Get waypoints
          waypoints <- api_manager$cav_waypoints
          if (is.null(waypoints)) {
            showNotification("No waypoints available. Generate waypoints first.", type = "warning")
            return()
          }
          
          # Get features
          features <- api_manager$cav_features
          
          # Get detections
          detections <- api_manager$cav_detections
          
          # Combine all detection sources
          combined_data <- list()
          
          # Add OSM features if available
          if (!is.null(features)) {
            features_filtered <- features %>%
              filter(risk_level %in% input$risk_filter)
            
            if (nrow(features_filtered) > 0) {
              combined_data[[length(combined_data) + 1]] <- features_filtered
            }
          }
          
          # Add YOLO detections if available
          if (!is.null(detections)) {
            detections_filtered <- detections %>%
              filter(
                risk_level %in% input$risk_filter,
                confidence >= input$min_confidence
              )
            
            # If detections don't have lat/lon, try to join with waypoints
            if (!all(c("lat", "lon") %in% names(detections_filtered))) {
              # Simplified: assign random coordinates for demo
              # In production: join with image metadata -> waypoints
              detections_filtered$lat <- runif(nrow(detections_filtered), min(waypoints$lat), max(waypoints$lat))
              detections_filtered$lon <- runif(nrow(detections_filtered), min(waypoints$lon), max(waypoints$lon))
            }
            
            if (nrow(detections_filtered) > 0) {
              combined_data[[length(combined_data) + 1]] <- detections_filtered
            }
          }
          
          incProgress(0.5, detail = "Processing markers")
          
          # Combine all data
          if (length(combined_data) == 0) {
            showNotification("No features to display with current filters", type = "info")
            return()
          }
          
          all_data <- do.call(rbind, lapply(combined_data, function(df) {
            df[, c("lat", "lon", "feature_type", "risk_level")]
          }))
          
          # Filter by feature type if specified
          if (length(input$feature_filter) > 0) {
            all_data <- all_data %>%
              filter(feature_type %in% input$feature_filter)
          }
          
          if (nrow(all_data) == 0) {
            showNotification("No features match the selected filters", type = "info")
            return()
          }
          
          map_data(all_data)
          
          # Calculate statistics
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
          
          # Color palette for risk levels
          risk_colors <- c(
            "CRITICAL" = "red",
            "MEDIUM" = "orange",
            "LOW" = "green"
          )
          
          # Create map
          map <- leaflet(all_data) %>%
            addTiles() %>%
            fitBounds(
              lng1 = min(all_data$lon), lat1 = min(all_data$lat),
              lng2 = max(all_data$lon), lat2 = max(all_data$lat)
            )
          
          # Add route polyline if waypoints available
          if (!is.null(waypoints)) {
            map <- map %>%
              addPolylines(
                lng = waypoints$lon,
                lat = waypoints$lat,
                color = "black",
                weight = 3,
                opacity = 0.7,
                group = "Route"
              )
          }
          
          # Add markers for each feature
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
                  popup = ~paste0(
                    "<b>", feature_type, "</b><br>",
                    "Risk: ", risk_level
                  ),
                  group = risk_level
                )
            }
          }
          
          # Add layer controls
          map <- map %>%
            addLayersControl(
              overlayGroups = c("Route", "CRITICAL", "MEDIUM", "LOW"),
              options = layersControlOptions(collapsed = FALSE)
            )
          
          incProgress(0.9, detail = "Rendering")
          
          # Update map
          leafletProxy("risk_map", data = all_data) %>%
            clearShapes() %>%
            clearMarkers() %>%
            addTiles() %>%
            fitBounds(
              lng1 = min(all_data$lon), lat1 = min(all_data$lat),
              lng2 = max(all_data$lon), lat2 = max(all_data$lat)
            )
          
          # Re-render full map
          output$risk_map <- renderLeaflet({
            map
          })
          
          showNotification(
            paste("Map updated with", nrow(all_data), "features"),
            type = "message"
          )
          
        }, error = function(e) {
          showNotification(paste("Error updating map:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    # Export data
    observeEvent(input$export_data, {
      data <- map_data()
      if (is.null(data)) {
        showNotification("No data to export", type = "warning")
        return()
      }
      
      filename <- paste0("cav_risk_export_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
      write.csv(data, filename, row.names = FALSE)
      
      showNotification(
        paste("Data exported to", filename),
        type = "message",
        duration = 5
      )
    })
    
    # Value boxes
    output$total_features_map <- renderValueBox({
      s <- stats()
      valueBox(
        if (is.null(s)) "0" else format(s$total, big.mark = ","),
        "Total Features",
        icon = icon("map-signs"),
        color = "blue"
      )
    })
    
    output$critical_count <- renderValueBox({
      s <- stats()
      valueBox(
        if (is.null(s)) "0" else format(s$critical, big.mark = ","),
        "Critical",
        icon = icon("exclamation-triangle"),
        color = "red"
      )
    })
    
    output$medium_count <- renderValueBox({
      s <- stats()
      valueBox(
        if (is.null(s)) "0" else format(s$medium, big.mark = ","),
        "Medium",
        icon = icon("exclamation-circle"),
        color = "orange"
      )
    })
    
    output$low_count <- renderValueBox({
      s <- stats()
      valueBox(
        if (is.null(s)) "0" else format(s$low, big.mark = ","),
        "Low",
        icon = icon("info-circle"),
        color = "green"
      )
    })
    
    output$avg_confidence <- renderValueBox({
      s <- stats()
      valueBox(
        if (is.null(s) || s$avg_conf == 0) "N/A" else sprintf("%.2f", s$avg_conf),
        "Avg Confidence",
        icon = icon("percentage"),
        color = "purple"
      )
    })
    
    output$route_length <- renderValueBox({
      s <- stats()
      valueBox(
        if (is.null(s) || s$route_km == 0) "N/A" else sprintf("%.1f km", s$route_km),
        "Route Length",
        icon = icon("route"),
        color = "teal"
      )
    })
  })
}
