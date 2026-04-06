# modules/feature_detector/server.R

feature_detector_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    features_data <- reactiveVal(NULL)
    detection_summary <- reactiveVal(NULL)
    
    observeEvent(input$detect_features, {
      
      # Check prerequisites
      if (is.null(api_manager) || is.null(api_manager$network_data)) {
        output$detection_status <- renderUI({
          div(class = "status-error",
              h5("✗ No Network Data"),
              p("Please download road network first."))
        })
        return()
      }
      
      if (is.null(api_manager$cav_waypoints)) {
        output$detection_status <- renderUI({
          div(class = "status-error",
              h5("✗ No Waypoints"),
              p("Please generate waypoints in Route Sampler first."))
        })
        return()
      }
      
      withProgress(message = 'Detecting features...', value = 0, {
        
        tryCatch({
          
          all_features <- list()
          
          incProgress(0.2, detail = "Processing waypoints")
          
          waypoints <- api_manager$cav_waypoints
          network_data <- api_manager$network_data
          
          # Detect curves from geometry
          if ("curve" %in% input$feature_types) {
            incProgress(0.3, detail = "Detecting curves")
            
            curves <- detect_curves(waypoints, threshold_degrees = input$curve_threshold)
            if (nrow(curves) > 0) {
              all_features[[length(all_features) + 1]] <- curves
            }
          }
          
          # Extract OSM features
          if (any(c("roundabout", "junction", "traffic_signals", "motorway_junction") %in% input$feature_types)) {
            incProgress(0.5, detail = "Querying OSM")
            
            bbox <- network_data$bbox
            
            # Query roundabouts
            if ("roundabout" %in% input$feature_types) {
              tryCatch({
                roundabouts_query <- opq(bbox) %>%
                  add_osm_feature(key = "junction", value = "roundabout") %>%
                  osmdata_sf()
                
                if (!is.null(roundabouts_query$osm_points) && nrow(roundabouts_query$osm_points) > 0) {
                  rb_coords <- st_coordinates(roundabouts_query$osm_points)
                  rb_df <- data.frame(
                    lat = rb_coords[, 2],
                    lon = rb_coords[, 1],
                    feature_type = "roundabout",
                    angle_change = NA,
                    sequence = NA
                  )
                  all_features[[length(all_features) + 1]] <- rb_df
                }
              }, error = function(e) {
                cat("Warning: Could not fetch roundabouts\n")
              })
            }
            
            # Query traffic signals
            if ("traffic_signals" %in% input$feature_types) {
              tryCatch({
                signals_query <- opq(bbox) %>%
                  add_osm_feature(key = "highway", value = "traffic_signals") %>%
                  osmdata_sf()
                
                if (!is.null(signals_query$osm_points) && nrow(signals_query$osm_points) > 0) {
                  sig_coords <- st_coordinates(signals_query$osm_points)
                  sig_df <- data.frame(
                    lat = sig_coords[, 2],
                    lon = sig_coords[, 1],
                    feature_type = "traffic_signals",
                    angle_change = NA,
                    sequence = NA
                  )
                  all_features[[length(all_features) + 1]] <- sig_df
                }
              }, error = function(e) {
                cat("Warning: Could not fetch traffic signals\n")
              })
            }
            
            # Query motorway junctions
            if ("motorway_junction" %in% input$feature_types) {
              tryCatch({
                junction_query <- opq(bbox) %>%
                  add_osm_feature(key = "highway", value = "motorway_junction") %>%
                  osmdata_sf()
                
                if (!is.null(junction_query$osm_points) && nrow(junction_query$osm_points) > 0) {
                  junc_coords <- st_coordinates(junction_query$osm_points)
                  junc_df <- data.frame(
                    lat = junc_coords[, 2],
                    lon = junc_coords[, 1],
                    feature_type = "motorway_junction",
                    angle_change = NA,
                    sequence = NA
                  )
                  all_features[[length(all_features) + 1]] <- junc_df
                }
              }, error = function(e) {
                cat("Warning: Could not fetch motorway junctions\n")
              })
            }
          }
          
          incProgress(0.8, detail = "Consolidating results")
          
          # Combine all features
          if (length(all_features) == 0) {
            stop("No features detected")
          }
          
          combined_features <- do.call(rbind, all_features)
          
          # Add risk classification
          combined_features$risk_level <- sapply(combined_features$feature_type, classify_risk)
          combined_features$feature_id <- paste0("FT_", sprintf("%04d", seq_len(nrow(combined_features))))
          
          # Calculate summary
          summary <- list(
            total = nrow(combined_features),
            critical = sum(combined_features$risk_level == "CRITICAL"),
            medium = sum(combined_features$risk_level == "MEDIUM"),
            low = sum(combined_features$risk_level == "LOW"),
            types = length(unique(combined_features$feature_type))
          )
          
          # Store results
          features_data(combined_features)
          detection_summary(summary)
          
          if (!is.null(api_manager)) {
            api_manager$cav_features <- combined_features
          }
          
          output$detection_status <- renderUI({
            div(class = "status-success",
                h5("✓ Detection Complete"),
                p(strong("Features found:"), summary$total),
                p(strong("Critical:"), summary$critical,
                  " | Medium:", summary$medium,
                  " | Low:", summary$low))
          })
          
          showNotification(
            paste("Detected", summary$total, "features!"),
            type = "message",
            duration = 3
          )
          
        }, error = function(e) {
          output$detection_status <- renderUI({
            div(class = "status-error",
                h5("✗ Detection Failed"),
                p(as.character(e$message)))
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    # Value boxes
    output$total_features <- renderValueBox({
      summary <- detection_summary()
      valueBox(
        if (is.null(summary)) "0" else format(summary$total, big.mark = ","),
        "Total Features",
        icon = icon("map-signs"),
        color = "blue"
      )
    })
    
    output$critical_features <- renderValueBox({
      summary <- detection_summary()
      valueBox(
        if (is.null(summary)) "0" else format(summary$critical, big.mark = ","),
        "Critical Risk",
        icon = icon("exclamation-triangle"),
        color = "red"
      )
    })
    
    output$feature_types_found <- renderValueBox({
      summary <- detection_summary()
      valueBox(
        if (is.null(summary)) "0" else summary$types,
        "Feature Types",
        icon = icon("list"),
        color = "green"
      )
    })
    
    # Features table
    output$features_table <- renderDT({
      features <- features_data()
      if (is.null(features)) {
        return(datatable(
          data.frame(Message = "No features detected yet"),
          options = list(dom = 't')
        ))
      }
      
      display_data <- features %>%
        select(feature_id, feature_type, lat, lon, risk_level) %>%
        mutate(
          lat = round(lat, 6),
          lon = round(lon, 6)
        )
      
      datatable(
        display_data,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE
      ) %>%
        formatStyle(
          'risk_level',
          backgroundColor = styleEqual(
            c('CRITICAL', 'MEDIUM', 'LOW'),
            c('#f8d7da', '#fff3cd', '#d4edda')
          )
        ) %>%
        formatStyle(columns = colnames(display_data), fontSize = '12px')
    })
  })
}
