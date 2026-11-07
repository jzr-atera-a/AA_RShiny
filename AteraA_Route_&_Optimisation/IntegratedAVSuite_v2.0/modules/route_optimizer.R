# modules/route_optimizer.R
# Route Optimizer with EXTENSIVE DEBUGGING

route_optimizer_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Route Selection", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        
        h4("Select Origin and Destination"),
        
        selectInput(ns("originAddress"), "Origin:",
                    choices = c(
                      "Judge Business School, Cambridge England",
                      "North Cambridge, Cambridge England",
                      "Cambridge West, Cambridge England",
                      "Addenbrooke's Hospital, Cambridge England"
                    ),
                    selected = "Judge Business School, Cambridge England"),
        
        selectInput(ns("destinationAddress"), "Destination:",
                    choices = c(
                      "Petersfield, Cambridge England",
                      "Chesterton, Cambridge England",
                      "Teversham, Cambridge England",
                      "Girton, Cambridge England"
                    ),
                    selected = "Petersfield, Cambridge England"),
        
        br(),
        
        numericInput(ns("numChargingPoints"), "Number of Charging Points:",
                     value = 3, min = 1, max = 10, step = 1),
        
        p(class = "text-muted", 
          "The system will find nearest charging points and calculate optimal route."),
        
        br(),
        
        actionButton(ns("calculateRoute"), "Calculate Optimal Route", 
                     class = "btn-success", 
                     icon = icon("route"),
                     width = "100%"),
        
        br(), br(),
        uiOutput(ns("routeStatus"))
      ),
      
      box(
        title = "Route Information", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        
        conditionalPanel(
          condition = paste0("output['", ns("routeCalculated"), "']"),
          h5("Route Summary:"),
          verbatimTextOutput(ns("routeSummary")),
          br(),
          h5("Nearest Charging Points:"),
          verbatimTextOutput(ns("chargingPointsInfo")),
          br(),
          actionButton(ns("viewMap"), "View Route Map", 
                       class = "btn-info", 
                       icon = icon("map"),
                       width = "100%"),
          br(), br(),
          actionButton(ns("sendToSimulator"), "Send to Simulator", 
                       class = "btn-success", 
                       icon = icon("paper-plane"),
                       width = "100%")
        ),
        
        conditionalPanel(
          condition = paste0("!output['", ns("routeCalculated"), "']"),
          div(style = "text-align: center; padding: 50px;",
              icon("info-circle", style = "font-size: 48px; color: #95a5a6;"),
              h4("No Route Calculated", style = "color: #7f8c8d; margin-top: 20px;"),
              p("Select addresses and click Calculate.", style = "color: #95a5a6;")
          )
        )
      )
    )
  )
}

route_optimizer_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    route_calculated <- reactiveVal(FALSE)
    route_data <- reactiveVal(NULL)
    nearest_points <- reactiveVal(NULL)
    start_coords <- reactiveVal(NULL)
    end_coords <- reactiveVal(NULL)
    
    observeEvent(input$calculateRoute, {
      
      cat("\n=== ROUTE OPTIMIZER DEBUG START ===\n")
      
      # DEBUG: Check api_manager
      cat("DEBUG: api_manager is NULL?", is.null(api_manager), "\n")
      if (!is.null(api_manager)) {
        cat("DEBUG: api_manager$bq_authenticated =", api_manager$bq_authenticated, "\n")
      }
      
      if (is.null(api_manager) || !api_manager$bq_authenticated) {
        cat("DEBUG: BigQuery NOT authenticated\n")
        output$routeStatus <- renderUI({
          div(class = "status-error", h5("❌ Not Connected"), p("Connect BigQuery first"))
        })
        return()
      }
      
      # DEBUG: Check network data
      cat("DEBUG: api_manager$network_data is NULL?", is.null(api_manager$network_data), "\n")
      
      if (is.null(api_manager$network_data)) {
        cat("DEBUG: Network data NOT available\n")
        output$routeStatus <- renderUI({
          div(class = "status-error", h5("❌ No Network"), p("Download network first"))
        })
        return()
      }
      
      cat("DEBUG: Network data available, graph rows:", nrow(api_manager$network_data$graph), "\n")
      
      withProgress(message = 'Calculating...', value = 0, {
        
        tryCatch({
          
          incProgress(0.2, detail = "Geocoding")
          cat("DEBUG: Starting geocoding...\n")
          
          # Geocoding with fallback
          origin_result <- tryCatch({
            tmaptools::geocode_OSM(input$originAddress, as.sf = TRUE, return.first.only = TRUE)
          }, error = function(e) {
            cat("DEBUG: tmaptools geocoding failed, trying Nominatim\n")
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
            cat("DEBUG: tmaptools geocoding failed for dest, trying Nominatim\n")
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
          
          cat("DEBUG: Geocoding successful\n")
          cat("DEBUG: Start coords:", start_coords(), "\n")
          cat("DEBUG: End coords:", end_coords(), "\n")
          
          incProgress(0.4, detail = "Finding charging points")
          
          # CRITICAL DEBUG: Check charging points
          cat("DEBUG: Calling api_manager$get_charging_points()...\n")
          charging_points <- api_manager$get_charging_points()
          
          cat("DEBUG: charging_points is NULL?", is.null(charging_points), "\n")
          
          if (!is.null(charging_points)) {
            cat("DEBUG: charging_points class:", class(charging_points), "\n")
            cat("DEBUG: charging_points nrow:", nrow(charging_points), "\n")
            cat("DEBUG: charging_points columns:", paste(names(charging_points), collapse=", "), "\n")
          } else {
            cat("DEBUG: CRITICAL - charging_points is NULL!\n")
            cat("DEBUG: Checking api_manager$charging_points directly...\n")
            cat("DEBUG: api_manager$charging_points is NULL?", is.null(api_manager$charging_points), "\n")
            if (!is.null(api_manager$charging_points)) {
              cat("DEBUG: api_manager$charging_points nrow:", nrow(api_manager$charging_points), "\n")
            }
          }
          
          if (is.null(charging_points) || nrow(charging_points) == 0) {
            cat("DEBUG: STOPPING - No charging points available\n")
            stop("No charging points - BigQuery data not loaded properly")
          }
          
          cat("DEBUG: Charging points found:", nrow(charging_points), "\n")
          
          charging_proj <- st_transform(charging_points, crs = 27700)
          start_proj <- st_transform(st_sfc(start_point, crs = 4326), crs = 27700)
          distances <- st_distance(charging_proj, start_proj)
          charging_points$distance <- as.numeric(distances)
          
          nearest <- charging_points %>% arrange(distance) %>% head(input$numChargingPoints)
          nearest_points(nearest)
          
          cat("DEBUG: Nearest points selected:", nrow(nearest), "\n")
          
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
          
          cat("DEBUG: Best route found, distance:", shortest_length, "m\n")
          
          incProgress(0.9, detail = "Done")
          route_data(list(length = shortest_length, charge_point_index = best_charge_point))
          route_calculated(TRUE)
          
          if (!is.null(api_manager)) {
            api_manager$route_info <- list(
              route_data = route_data(), 
              nearest_points = nearest_points(),
              start_coords = start_coords(), 
              end_coords = end_coords(),
              origin_address = input$originAddress, 
              destination_address = input$destinationAddress
            )
            api_manager$trigger_route_update()
          }
          
          output$routeStatus <- renderUI({
            div(class = "status-success", h5("✓ Success"), 
                p(paste("Distance:", round(shortest_length/1000, 2), "km")))
          })
          
          cat("DEBUG: Route calculation SUCCESSFUL\n")
          cat("=== ROUTE OPTIMIZER DEBUG END ===\n\n")
          
          showNotification("Route ready!", type = "message", duration = 3)
          
        }, error = function(e) {
          cat("DEBUG: ERROR OCCURRED:", e$message, "\n")
          cat("=== ROUTE OPTIMIZER DEBUG END ===\n\n")
          
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
      paste("Origin:", input$originAddress, 
            "\nDestination:", input$destinationAddress, 
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
    
    observeEvent(input$viewMap, {
      updateTabItems(session, "sidebar_menu", "route_map")
    })
    
    observeEvent(input$sendToSimulator, {
      if (!route_calculated() || is.null(route_data())) {
        showNotification("Please calculate a route first", type = "warning", duration = 5)
        return()
      }
      
      scenario <- api_manager$route_to_scenario(
        api_manager$route_info,
        conditions = list(
          road_type = "auto",
          traffic = "moderate_congestion",
          weather = "clear"
        )
      )
      
      if (!is.null(scenario)) {
        current_scenarios <- api_manager$get_scenarios()
        if (is.null(current_scenarios)) {
          current_scenarios <- list()
        }
        current_scenarios[[length(current_scenarios) + 1]] <- scenario
        
        api_manager$load_omniverse_scenarios(current_scenarios)
        
        updateTabItems(session, "sidebar_menu", "omniverse_connection")
        
        showNotification(
          "✓ Route sent to simulation! Check Omniverse Connection tab.",
          type = "message",
          duration = 8
        )
      }
    })
  })
}
