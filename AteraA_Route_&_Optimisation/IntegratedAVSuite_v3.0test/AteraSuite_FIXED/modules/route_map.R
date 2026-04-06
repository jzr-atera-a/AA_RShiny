# modules/route_map.R
# Route Map Module - FIXED with actual road paths

route_map_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Interactive Route Map", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        leafletOutput(ns("routeMap"), height = 600),
        
        br(),
        
        div(class = "map-legend",
            h5("Legend:"),
            p(icon("play", style = "color: green;"), " Start Point"),
            p(icon("battery-half", style = "color: orange;"), " Charging Points"),
            p(icon("battery-full", style = "color: #00A39A;"), " Selected Charging Point"),
            p(icon("stop", style = "color: red;"), " End Point"),
            p(icon("minus", style = "color: #3498db;"), " Route Path (Actual Roads)")
        )
      )
    )
  )
}

route_map_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    output$routeMap <- renderLeaflet({
      
      if (is.null(api_manager) || is.null(api_manager$route_info)) {
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
              addAwesomeMarkers(
                lng = coords[1],
                lat = coords[2],
                popup = popup_text,
                icon = awesomeIcons(
                  icon = "charging-station",
                  iconColor = "white",
                  markerColor = if(is_selected) "lightblue" else "orange",
                  library = "fa"
                )
              )
          }
        }
        
        # CRITICAL: Draw actual route paths using dodgr_flows_aggregate
        if (!is.null(route_info$route_data$charge_point_index)) {
          charge_point <- route_info$nearest_points[route_info$route_data$charge_point_index,]
          charge_coords <- st_coordinates(st_geometry(charge_point))
          
          graph <- api_manager$network_data$graph
          
          withProgress(message = 'Drawing route...', value = 0, {
            
            tryCatch({
              incProgress(0.3, detail = "Computing route geometry")
              
              # Route segment 1: Start to charging point
              flows_to_charge <- data.frame(
                from_x = route_info$start_coords[1],
                from_y = route_info$start_coords[2],
                to_x = charge_coords[1],
                to_y = charge_coords[2],
                flow = 1
              )
              
              graph_with_flow_1 <- dodgr::dodgr_flows_aggregate(
                graph = graph,
                from = flows_to_charge[, c("from_x", "from_y")],
                to = flows_to_charge[, c("to_x", "to_y")],
                flows = flows_to_charge$flow
              )
              
              route_edges_1 <- graph_with_flow_1[graph_with_flow_1$flow > 0, ]
              
              incProgress(0.5, detail = "Drawing first segment")
              
              if (nrow(route_edges_1) > 0) {
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
              
              # Route segment 2: Charging point to destination
              flows_from_charge <- data.frame(
                from_x = charge_coords[1],
                from_y = charge_coords[2],
                to_x = route_info$end_coords[1],
                to_y = route_info$end_coords[2],
                flow = 1
              )
              
              graph_with_flow_2 <- dodgr::dodgr_flows_aggregate(
                graph = graph,
                from = flows_from_charge[, c("from_x", "from_y")],
                to = flows_from_charge[, c("to_x", "to_y")],
                flows = flows_from_charge$flow
              )
              
              route_edges_2 <- graph_with_flow_2[graph_with_flow_2$flow > 0, ]
              
              incProgress(0.9, detail = "Drawing second segment")
              
              if (nrow(route_edges_2) > 0) {
                for (i in 1:nrow(route_edges_2)) {
                  edge <- route_edges_2[i, ]
                  
                  map <- map %>%
                    addPolylines(
                      lng = c(edge$from_lon, edge$to_lon),
                      lat = c(edge$from_lat, edge$to_lat),
                      color = "#3498db",
                      weight = 6,
                      opacity = 0.9,
                      group = "route_from_charge"
                    )
                }
              }
              
              incProgress(1, detail = "Complete")
              
            }, error = function(e) {
              cat("Warning: Could not draw detailed route:", e$message, "\n")
              # Fallback to simple lines if detailed routing fails
              map <- map %>%
                addPolylines(
                  lng = c(route_info$start_coords[1], charge_coords[1]),
                  lat = c(route_info$start_coords[2], charge_coords[2]),
                  color = "#3498db",
                  weight = 4,
                  opacity = 0.7,
                  dashArray = "10, 5"
                ) %>%
                addPolylines(
                  lng = c(charge_coords[1], route_info$end_coords[1]),
                  lat = c(charge_coords[2], route_info$end_coords[2]),
                  color = "#3498db",
                  weight = 4,
                  opacity = 0.7,
                  dashArray = "10, 5"
                )
            })
          })
        }
        
        # Fit bounds to show entire route
        all_lngs <- c(route_info$start_coords[1], route_info$end_coords[1])
        all_lats <- c(route_info$start_coords[2], route_info$end_coords[2])
        
        if (!is.null(route_info$nearest_points)) {
          charging_coords <- st_coordinates(st_geometry(route_info$nearest_points))
          all_lngs <- c(all_lngs, charging_coords[,1])
          all_lats <- c(all_lats, charging_coords[,2])
        }
        
        map <- map %>%
          fitBounds(
            lng1 = min(all_lngs),
            lat1 = min(all_lats),
            lng2 = max(all_lngs),
            lat2 = max(all_lats)
          )
        
        return(map)
        
      }, error = function(e) {
        return(
          leaflet() %>%
            addTiles() %>%
            setView(lng = 0.1218, lat = 52.2053, zoom = 13) %>%
            addControl(
              html = paste("<div style='padding: 15px; background: #f8d7da; border-radius: 8px;'>
                           <h4 style='margin: 0; color: #721c24;'>Error Rendering Map</h4>
                           <p style='margin: 5px 0 0 0; color: #721c24;'>", e$message, "</p>
                           </div>"),
              position = "topright"
            )
        )
      })
    })
  })
}
