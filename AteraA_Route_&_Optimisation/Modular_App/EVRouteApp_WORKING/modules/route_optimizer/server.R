# modules/route_optimizer/server.R - WORKING VERSION

route_optimizer_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    route_calculated <- reactiveVal(FALSE)
    route_data <- reactiveVal(NULL)
    nearest_points <- reactiveVal(NULL)
    start_coords <- reactiveVal(NULL)
    end_coords <- reactiveVal(NULL)
    
    observeEvent(input$calculateRoute, {
      
      if (is.null(api_manager) || !api_manager$bq_authenticated) {
        output$routeStatus <- renderUI({
          div(class = "status-error", h5("❌ Not Connected"), p("Connect BigQuery first"))
        })
        return()
      }
      
      if (is.null(api_manager$network_data)) {
        output$routeStatus <- renderUI({
          div(class = "status-error", h5("❌ No Network"), p("Download network first"))
        })
        return()
      }
      
      withProgress(message = 'Calculating...', value = 0, {
        
        tryCatch({
          
          incProgress(0.2, detail = "Geocoding")
          
          # Use Nominatim directly to avoid getbb polygon requirement
          origin_result <- tryCatch({
            tmaptools::geocode_OSM(input$originAddress, as.sf = TRUE, return.first.only = TRUE)
          }, error = function(e) {
            # Fallback: try with just coordinates
            query_url <- paste0("https://nominatim.openstreetmap.org/search?q=",
                                URLencode(input$originAddress),
                                "&format=json&limit=1")
            result <- jsonlite::fromJSON(query_url)
            if (length(result) == 0) return(NULL)
            st_sf(geometry = st_sfc(st_point(c(as.numeric(result$lon[1]), 
                                               as.numeric(result$lat[1]))), crs = 4326))
          })
          
          dest_result <- tryCatch({
            tmaptools::geocode_OSM(input$destinationAddress, as.sf = TRUE, return.first.only = TRUE)
          }, error = function(e) {
            # Fallback: try with just coordinates
            query_url <- paste0("https://nominatim.openstreetmap.org/search?q=",
                                URLencode(input$destinationAddress),
                                "&format=json&limit=1")
            result <- jsonlite::fromJSON(query_url)
            if (length(result) == 0) return(NULL)
            st_sf(geometry = st_sfc(st_point(c(as.numeric(result$lon[1]), 
                                               as.numeric(result$lat[1]))), crs = 4326))
          })
          
          if (is.null(origin_result) || is.null(dest_result)) stop("Geocoding failed")
          
          start_point <- st_geometry(origin_result)[[1]]
          end_point <- st_geometry(dest_result)[[1]]
          
          start_coords(st_coordinates(start_point))
          end_coords(st_coordinates(end_point))
          
          incProgress(0.4, detail = "Finding points")
          charging_points <- api_manager$get_charging_points()
          if (is.null(charging_points) || nrow(charging_points) == 0) stop("No charging points")
          
          charging_proj <- st_transform(charging_points, crs = 27700)
          start_proj <- st_transform(st_sfc(start_point, crs = 4326), crs = 27700)
          distances <- st_distance(charging_proj, start_proj)
          charging_points$distance <- as.numeric(distances)
          
          nearest <- charging_points %>% arrange(distance) %>% head(input$numChargingPoints)
          nearest_points(nearest)
          
          incProgress(0.6, detail = "Routing")
          graph <- api_manager$network_data$graph
          shortest_length <- Inf
          best_charge_point <- NULL
          
          for (i in 1:nrow(nearest)) {
            charge_coords <- st_coordinates(st_geometry(nearest[i,]))
            dist_to <- tryCatch(dodgr_dists(graph, from = start_coords(), to = charge_coords)[1], error = function(e) Inf)
            dist_from <- tryCatch(dodgr_dists(graph, from = charge_coords, to = end_coords())[1], error = function(e) Inf)
            total <- dist_to + dist_from
            if (!is.na(total) && !is.infinite(total) && total < shortest_length) {
              shortest_length <- total
              best_charge_point <- i
            }
          }
          
          if (is.null(best_charge_point)) stop("No valid route")
          
          incProgress(0.9, detail = "Done")
          route_data(list(length = shortest_length, charge_point_index = best_charge_point))
          route_calculated(TRUE)
          
          if (!is.null(api_manager)) {
            api_manager$route_info <- list(
              route_data = route_data(), nearest_points = nearest_points(),
              start_coords = start_coords(), end_coords = end_coords(),
              origin_address = input$originAddress, destination_address = input$destinationAddress
            )
          }
          
          output$routeStatus <- renderUI({
            div(class = "status-success", h5("✓ Success"), 
                p(paste("Distance:", round(shortest_length/1000, 2), "km")))
          })
          showNotification("Route ready!", type = "message", duration = 3)
          
        }, error = function(e) {
          route_calculated(FALSE)
          output$routeStatus <- renderUI({
            div(class = "status-error", h5("✗ Failed"), p(as.character(e$message)))
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    output$routeSummary <- renderText({
      if (!route_calculated() || is.null(route_data())) return("No route")
      paste("Origin:", input$originAddress, "\nDestination:", input$destinationAddress, 
            "\nDistance:", round(route_data()$length/1000, 2), "km")
    })
    
    output$chargingPointsInfo <- renderText({
      if (is.null(nearest_points())) return("No points")
      np <- nearest_points()
      paste(sapply(1:nrow(np), function(i) {
        sel <- if (!is.null(route_data()) && i == route_data()$charge_point_index) " ✓" else ""
        sprintf("%d. %.2f km%s", i, np[i,]$distance/1000, sel)
      }), collapse = "\n")
    })
    
    output$routeCalculated <- reactive({ route_calculated() })
    outputOptions(output, "routeCalculated", suspendWhenHidden = FALSE)
    
    observeEvent(input$viewMap, {updateTabItems(session, "sidebar_menu", "route_map")})
  })
}