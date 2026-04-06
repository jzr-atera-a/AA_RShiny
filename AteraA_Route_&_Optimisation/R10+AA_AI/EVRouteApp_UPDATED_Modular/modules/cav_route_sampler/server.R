# modules/cav_route_sampler/server.R

cav_route_sampler_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    waypoints_data <- reactiveVal(NULL)
    route_info <- reactiveVal(NULL)
    
    observeEvent(input$generate_waypoints, {
      
      # Check if route exists
      if (is.null(api_manager) || is.null(api_manager$network_data)) {
        output$sampling_status <- renderUI({
          div(class = "status-error",
              h5("✗ No Route Available"),
              p("Please generate a route in the Route Optimizer module first."))
        })
        return()
      }
      
      withProgress(message = 'Generating waypoints...', value = 0, {
        
        tryCatch({
          
          incProgress(0.2, detail = "Extracting route")
          
          # Get route from api_manager (this is a simplified approach)
          # In real implementation, extract from route_optimizer results
          network_data <- api_manager$network_data
          
          # For demonstration, create sample route coordinates
          # In production, extract from actual route calculation
          if (!is.null(network_data$bbox)) {
            bbox <- network_data$bbox
            
            # Generate sample route (in production, use actual route)
            n_points <- 100
            lats <- seq(bbox[2,1], bbox[2,2], length.out = n_points)
            lons <- seq(bbox[1,1], bbox[1,2], length.out = n_points)
            
            route_coords <- data.frame(
              lat = lats,
              lon = lons
            )
          } else {
            stop("No route data available")
          }
          
          incProgress(0.4, detail = "Resampling route")
          
          # Resample at specified interval
          waypoints <- resample_route(route_coords, spacing_m = input$sampling_interval)
          
          incProgress(0.6, detail = "Adding metadata")
          
          # Add additional metadata
          waypoints$waypoint_id <- paste0("WP_", sprintf("%04d", waypoints$sequence_number))
          waypoints$distance_from_start <- cumsum(c(0, sapply(2:nrow(waypoints), function(i) {
            haversine_distance(
              waypoints$lat[i-1], waypoints$lon[i-1],
              waypoints$lat[i], waypoints$lon[i]
            )
          })))
          
          incProgress(0.8, detail = "Calculating estimates")
          
          # Calculate route statistics
          total_distance <- max(waypoints$distance_from_start) / 1000  # km
          n_waypoints <- nrow(waypoints)
          
          route_info(list(
            distance_km = total_distance,
            waypoint_count = n_waypoints,
            sampling_interval = input$sampling_interval
          ))
          
          incProgress(0.9, detail = "Finalizing")
          
          # Store in api_manager for other modules
          if (!is.null(api_manager)) {
            api_manager$cav_waypoints <- waypoints
          }
          
          waypoints_data(waypoints)
          
          output$sampling_status <- renderUI({
            div(class = "status-success",
                h5("✓ Success"),
                p(strong("Waypoints generated:"), n_waypoints),
                p(strong("Sampling interval:"), input$sampling_interval, "meters"))
          })
          
          showNotification(
            paste("Generated", n_waypoints, "waypoints!"),
            type = "message",
            duration = 3
          )
          
        }, error = function(e) {
          output$sampling_status <- renderUI({
            div(class = "status-error",
                h5("✗ Error"),
                p(as.character(e$message)))
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    # Route distance value box
    output$route_distance <- renderValueBox({
      info <- route_info()
      valueBox(
        if (is.null(info)) "N/A" else sprintf("%.1f km", info$distance_km),
        "Route Distance",
        icon = icon("route"),
        color = "blue"
      )
    })
    
    # Waypoint count value box
    output$waypoint_count <- renderValueBox({
      info <- route_info()
      valueBox(
        if (is.null(info)) "N/A" else format(info$waypoint_count, big.mark = ","),
        "Waypoints",
        icon = icon("map-marker-alt"),
        color = "green"
      )
    })
    
    # Estimated images value box
    output$estimated_images <- renderValueBox({
      info <- route_info()
      valueBox(
        if (is.null(info)) "N/A" else format(info$waypoint_count, big.mark = ","),
        "Est. Images",
        icon = icon("camera"),
        color = "orange"
      )
    })
    
    # Estimated cost value box
    output$estimated_cost <- renderValueBox({
      info <- route_info()
      cost <- if (is.null(info)) 0 else info$waypoint_count * 0.007  # $0.007 per image
      valueBox(
        if (is.null(info)) "N/A" else sprintf("$%.2f", cost),
        "Est. API Cost",
        icon = icon("dollar-sign"),
        color = "red"
      )
    })
    
    # Waypoints data table
    output$waypoints_table <- renderDT({
      wp <- waypoints_data()
      if (is.null(wp)) {
        return(datatable(
          data.frame(Message = "No waypoints generated yet"),
          options = list(dom = 't')
        ))
      }
      
      display_data <- wp %>%
        select(waypoint_id, sequence_number, lat, lon, distance_from_start) %>%
        mutate(
          lat = round(lat, 6),
          lon = round(lon, 6),
          distance_km = round(distance_from_start / 1000, 2)
        ) %>%
        select(-distance_from_start)
      
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
        formatStyle(columns = colnames(display_data), fontSize = '12px')
    })
  })
}
