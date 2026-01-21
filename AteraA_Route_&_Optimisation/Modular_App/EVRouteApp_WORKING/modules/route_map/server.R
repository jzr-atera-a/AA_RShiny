# modules/route_map/server.R

route_map_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    # Render route map
    output$routeMap <- renderLeaflet({
      
      # Check if route info exists
      if (is.null(api_manager) || is.null(api_manager$route_info)) {
        # Show empty map with message
        return(
          leaflet() %>%
            addTiles() %>%
            setView(lng = 0.1218, lat = 52.2053, zoom = 13) %>%
            addControl(
              html = "<div style='padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);'>
                      <h4 style='margin: 0; color: #7f8c8d;'>No Route Calculated</h4>
                      <p style='margin: 5px 0 0 0; color: #95a5a6;'>Please calculate a route first.</p>
                    </div>",
              position = "topright"
            )
        )
      }
      
      route_info <- api_manager$route_info
      
      tryCatch({
        # Create base map
        map <- leaflet() %>%
          addTiles() %>%
          setView(lng = route_info$start_coords[1], 
                  lat = route_info$start_coords[2], 
                  zoom = 13)
        
        # Add start marker
        map <- map %>%
          addAwesomeMarkers(
            lng = route_info$start_coords[1],
            lat = route_info$start_coords[2],
            popup = paste("<b>Start:</b><br>", route_info$origin_address),
            icon = awesomeIcons(
              icon = "play",
              iconColor = "white",
              markerColor = "green",
              library = "fa"
            )
          )
        
        # Add end marker
        map <- map %>%
          addAwesomeMarkers(
            lng = route_info$end_coords[1],
            lat = route_info$end_coords[2],
            popup = paste("<b>End:</b><br>", route_info$destination_address),
            icon = awesomeIcons(
              icon = "stop",
              iconColor = "white",
              markerColor = "red",
              library = "fa"
            )
          )
        
        # Add charging point markers
        if (!is.null(route_info$nearest_points)) {
          for (i in 1:nrow(route_info$nearest_points)) {
            point <- route_info$nearest_points[i,]
            coords <- st_coordinates(st_geometry(point))
            
            is_selected <- (i == route_info$route_data$charge_point_index)
            
            popup_text <- sprintf(
              "<b>Charging Point %d</b><br>Distance from origin: %.2f km<br>%s",
              i,
              point$distance/1000,
              if(is_selected) "<b style='color: #00A39A;'>✓ Selected</b>" else ""
            )
            
            map <- map %>%
              addCircleMarkers(
                lng = coords[1],
                lat = coords[2],
                radius = if(is_selected) 10 else 7,
                color = if(is_selected) "#00A39A" else "#f39c12",
                fillColor = if(is_selected) "#00A39A" else "#f39c12",
                fillOpacity = if(is_selected) 0.9 else 0.7,
                weight = if(is_selected) 3 else 2,
                popup = popup_text
              )
          }
        }
        
        # Draw actual road-based route
        if (!is.null(route_info$route_data$charge_point_index)) {
          charge_point <- route_info$nearest_points[route_info$route_data$charge_point_index,]
          charge_coords <- st_coordinates(st_geometry(charge_point))
          
          graph <- api_manager$network_data$graph
          
          withProgress(message = 'Drawing route...', value = 0, {
            
            tryCatch({
              incProgress(0.3, detail = "Computing route geometry")
              
              # Use dodgr_flows_aggregate to get actual route geometry
              # This creates flow data that we can visualize
              
              # Create flows data - route to charging point
              flows_to_charge <- data.frame(
                from_x = route_info$start_coords[1],
                from_y = route_info$start_coords[2],
                to_x = charge_coords[1],
                to_y = charge_coords[2],
                flow = 1
              )
              
              # Aggregate flows on the network
              graph_with_flow_1 <- dodgr::dodgr_flows_aggregate(
                graph = graph,
                from = flows_to_charge[, c("from_x", "from_y")],
                to = flows_to_charge[, c("to_x", "to_y")],
                flows = flows_to_charge$flow
              )
              
              # Filter to edges with flow > 0 (these are the route edges)
              route_edges_1 <- graph_with_flow_1[graph_with_flow_1$flow > 0, ]
              
              incProgress(0.5, detail = "Drawing first segment")
              
              if (nrow(route_edges_1) > 0) {
                # Draw each edge of the route
                for (i in 1:nrow(route_edges_1)) {
                  edge <- route_edges_1[i, ]
                  
                  map <- map %>%
                    addPolylines(
                      lng = c(edge$from_lon, edge$to_lon),
                      lat = c(edge$from_lat, edge$to_lat),
                      color = "#3498db",
                      weight = 6,
                      opacity = 0.9,
                      group = "route_to_charge"
                    )
                }
              }
              
              incProgress(0.7, detail = "Computing return route")
              
              # Create flows data - route from charging point to destination
              flows_from_charge <- data.frame(
                from_x = charge_coords[1],
                from_y = charge_coords[2],
                to_x = route_info$end_coords[1],
                to_y = route_info$end_coords[2],
                flow = 1
              )
              
              # Aggregate flows on the network
              graph_with_flow_2 <- dodgr::dodgr_flows_aggregate(
                graph = graph,
                from = flows_from_charge[, c("from_x", "from_y")],
                to = flows_from_charge[, c("to_x", "to_y")],
                flows = flows_from_charge$flow
              )
              
              # Filter to edges with flow > 0
              route_edges_2 <- graph_with_flow_2[graph_with_flow_2$flow > 0, ]
              
              incProgress(0.9, detail = "Drawing second segment")
              
              if (nrow(route_edges_2) > 0) {
                # Draw each edge of the route
                for (i in 1:nrow(route_edges_2)) {
                  edge <- route_edges_2[i, ]
                  
                  map <- map %>%
                    addPolylines(
                      lng = c(edge$from_lon, edge$to_lon),
                      lat = c(edge$from_lat, edge$to_lat),
                      color = "#2980b9",
                      weight = 6,
                      opacity = 0.9,
                      group = "route_from_charge"
                    )
                }
              }
              
            }, error = function(e) {
              # Fallback to straight lines if route drawing fails
              showNotification(paste("Could not draw detailed route:", e$message), 
                               type = "warning", duration = 5)
              
              map <<- map %>%
                addPolylines(
                  lng = c(route_info$start_coords[1], charge_coords[1]),
                  lat = c(route_info$start_coords[2], charge_coords[2]),
                  color = "#3498db",
                  weight = 4,
                  opacity = 0.6,
                  dashArray = "10, 10",
                  popup = "Approximate route to charging point"
                ) %>%
                addPolylines(
                  lng = c(charge_coords[1], route_info$end_coords[1]),
                  lat = c(charge_coords[2], route_info$end_coords[2]),
                  color = "#2980b9",
                  weight = 4,
                  opacity = 0.6,
                  dashArray = "10, 10",
                  popup = "Approximate route from charging point"
                )
            })
          })
        }
        
        # Add legend
        map <- map %>%
          addControl(
            html = sprintf(
              "<div style='padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);'>
              <h4 style='margin: 0 0 10px 0; color: #2c3e50;'>Route Summary</h4>
              <p style='margin: 5px 0;'><span style='color: green;'>●</span> <b>Start:</b> %s</p>
              <p style='margin: 5px 0;'><span style='color: #00A39A;'>●</span> <b>Charging Point</b></p>
              <p style='margin: 5px 0;'><span style='color: red;'>●</span> <b>End:</b> %s</p>
              <p style='margin: 5px 0;'><span style='color: #3498db;'>━━</span> <b>Total:</b> %.2f km</p>
            </div>",
              route_info$origin_address,
              route_info$destination_address,
              route_info$route_data$length/1000
            ),
            position = "topright"
          )
        
        map
        
      }, error = function(e) {
        leaflet() %>%
          addTiles() %>%
          setView(lng = 0.1218, lat = 52.2053, zoom = 13) %>%
          addControl(
            html = paste0("<div style='padding: 15px; background: #fff3cd; border-radius: 8px;'>
                          <h4 style='margin: 0; color: #856404;'>⚠ Unable to Display Route</h4>
                          <p style='margin: 5px 0;'>", e$message, "</p>
                        </div>"),
            position = "topright"
          )
      })
    })
  })
}