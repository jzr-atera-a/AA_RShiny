# modules/route_optimizer.R
# Route Optimizer — text-based origin/destination with region validation
# Atera Analytics | Innovate UK 10153306

route_optimizer_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Route Selection", status = "primary", solidHeader = TRUE, width = 6,

        h4("Origin & Destination"),

        # Region hint banner — shown when network is loaded
        uiOutput(ns("regionBanner")),

        br(),

        div(style="margin-bottom:5px;",
          tags$label(class="control-label", "Origin:"),
          textInput(ns("originAddress"), label=NULL,
                    value="Judge Business School, Cambridge, England",
                    placeholder="e.g., Addenbrooke's Hospital, Cambridge"),
          uiOutput(ns("originWarning"))
        ),

        div(style="margin-bottom:15px;",
          tags$label(class="control-label", "Destination:"),
          textInput(ns("destinationAddress"), label=NULL,
                    value="Petersfield, Cambridge, England",
                    placeholder="e.g., Girton, Cambridge, England"),
          uiOutput(ns("destWarning"))
        ),

        numericInput(ns("numChargingPoints"), "Number of Charging Points:",
                     value=3, min=1, max=10, step=1),

        p(class="text-muted",
          "The system will find nearest charging points and calculate the optimal route. ",
          "Origin and destination will be geocoded via OpenStreetMap Nominatim."),
        br(),

        actionButton(ns("calculateRoute"), "Calculate Optimal Route",
                     class="btn-success", icon=icon("route"), width="100%"),
        br(), br(),
        uiOutput(ns("routeStatus"))
      ),

      box(
        title = "Route Information", status = "info", solidHeader = TRUE, width = 6,

        conditionalPanel(
          condition = paste0("output['", ns("routeCalculated"), "']"),
          h5("Route Summary:"),
          verbatimTextOutput(ns("routeSummary")),
          br(),
          h5("Nearest Charging Points:"),
          verbatimTextOutput(ns("chargingPointsInfo")),
          br(),
          actionButton(ns("viewMap"), "View Route Map",
                       class="btn-info", icon=icon("map"), width="100%"),
          br(), br(),
          actionButton(ns("sendToSimulator"), "Send to Simulator",
                       class="btn-success", icon=icon("paper-plane"), width="100%")
        ),

        conditionalPanel(
          condition = paste0("!output['", ns("routeCalculated"), "']"),
          div(style="text-align:center; padding:50px;",
              icon("info-circle", style="font-size:48px; color:#95a5a6;"),
              h4("No Route Calculated", style="color:#7f8c8d; margin-top:20px;"),
              p("Enter addresses and click Calculate.", style="color:#95a5a6;")
          )
        )
      )
    )
  )
}

route_optimizer_server <- function(id, api_manager=NULL) {

  moduleServer(id, function(input, output, session) {

    route_calculated <- reactiveVal(FALSE)
    route_data       <- reactiveVal(NULL)
    nearest_points   <- reactiveVal(NULL)
    start_coords     <- reactiveVal(NULL)
    end_coords       <- reactiveVal(NULL)

    # ── Region banner — shows loaded network extent ──────────────────────────
    output$regionBanner <- renderUI({
      if (is.null(api_manager) || is.null(api_manager$network_data)) {
        div(style="background:#fef9e7;border-radius:4px;padding:8px 12px;margin-bottom:10px;border-left:3px solid #e67e22;",
            tags$small(icon("exclamation-circle", style="color:#e67e22;"),
                       " Road Network not yet downloaded. Download it in the Road Network tab first."))
      } else {
        bbox <- api_manager$network_data$bbox
        loc  <- api_manager$network_data$location
        div(style="background:#eafaf1;border-radius:4px;padding:8px 12px;margin-bottom:10px;border-left:3px solid #27ae60;",
            tags$small(
              icon("check-circle", style="color:#27ae60;"),
              strong(" Active region: "), loc, br(),
              style="color:#2c3e50;",
              sprintf("Bounds: %.4f°N – %.4f°N, %.4f°E – %.4f°E",
                      bbox["y","min"], bbox["y","max"],
                      bbox["x","min"], bbox["x","max"])
            ))
      }
    })

    # ── Helper: geocode a text address safely ────────────────────────────────
    geocode_address <- function(address) {
      tryCatch({
        tmaptools::geocode_OSM(address, as.sf=TRUE, return.first.only=TRUE)
      }, error=function(e) {
        query_url <- paste0("https://nominatim.openstreetmap.org/search?q=",
                            URLencode(address), "&format=json&limit=1")
        result <- jsonlite::fromJSON(query_url)
        if (length(result)==0) return(NULL)
        st_sf(geometry=st_sfc(
          st_point(c(as.numeric(result$lon[1]), as.numeric(result$lat[1]))), crs=4326))
      })
    }

    # ── Helper: check if a coordinate (lon, lat) is within the network bbox ──
    in_region <- function(lon, lat, bbox) {
      !is.null(bbox) &&
        lon >= bbox["x","min"] && lon <= bbox["x","max"] &&
        lat >= bbox["y","min"] && lat <= bbox["y","max"]
    }

    # ── Route calculation ────────────────────────────────────────────────────
    observeEvent(input$calculateRoute, {

      cat("\n=== ROUTE OPTIMIZER START ===\n")

      # Reset warnings
      output$originWarning <- renderUI({ NULL })
      output$destWarning   <- renderUI({ NULL })

      if (is.null(api_manager) || !api_manager$bq_authenticated) {
        cat("DEBUG: BigQuery NOT authenticated\n")
        output$routeStatus <- renderUI({
          div(class="status-error", h5("Not Connected"), p("Connect BigQuery first"))
        })
        return()
      }

      if (is.null(api_manager$network_data)) {
        cat("DEBUG: No network data\n")
        output$routeStatus <- renderUI({
          div(class="status-error", h5("No Network"), p("Download road network first"))
        })
        return()
      }

      bbox <- api_manager$network_data$bbox

      withProgress(message="Calculating route...", value=0, {
        tryCatch({

          incProgress(0.15, detail="Geocoding origin")
          cat("DEBUG: Geocoding origin:", input$originAddress, "\n")

          origin_result <- geocode_address(input$originAddress)
          if (is.null(origin_result)) stop(paste("Geocoding failed for origin:", input$originAddress))

          dest_result   <- geocode_address(input$destinationAddress)
          if (is.null(dest_result)) stop(paste("Geocoding failed for destination:", input$destinationAddress))

          start_point <- st_geometry(origin_result)[[1]]
          end_point   <- st_geometry(dest_result)[[1]]

          s_coords <- st_coordinates(start_point)
          e_coords <- st_coordinates(end_point)
          start_coords(s_coords)
          end_coords(e_coords)

          cat("DEBUG: Start:", s_coords, "\n")
          cat("DEBUG: End:  ", e_coords, "\n")

          # ── Region validation ──────────────────────────────────────────────
          origin_ok <- in_region(s_coords[1,"X"], s_coords[1,"Y"], bbox)
          dest_ok   <- in_region(e_coords[1,"X"], e_coords[1,"Y"], bbox)

          if (!origin_ok) {
            cat("DEBUG: Origin is OUTSIDE the road network region\n")
            output$originWarning <- renderUI({
              div(style="background:#fdf2f8;border-radius:3px;padding:6px 10px;margin-top:4px;border-left:3px solid #c0392b;",
                  tags$small(icon("exclamation-triangle", style="color:#c0392b;"),
                             strong(" Origin is outside the Road Network region."),
                             br(), "Route calculation may fail or use incomplete data. ",
                             "Re-download the network for a wider area to include this location."))
            })
          } else {
            output$originWarning <- renderUI({ NULL })
          }

          if (!dest_ok) {
            cat("DEBUG: Destination is OUTSIDE the road network region\n")
            output$destWarning <- renderUI({
              div(style="background:#fdf2f8;border-radius:3px;padding:6px 10px;margin-top:4px;border-left:3px solid #c0392b;",
                  tags$small(icon("exclamation-triangle", style="color:#c0392b;"),
                             strong(" Destination is outside the Road Network region."),
                             br(), "Route calculation may fail or use incomplete data. ",
                             "Re-download the network for a wider area to include this location."))
            })
          } else {
            output$destWarning <- renderUI({ NULL })
          }

          incProgress(0.35, detail="Finding charging points")
          charging_points <- api_manager$get_charging_points()

          cat("DEBUG: charging_points NULL?", is.null(charging_points), "\n")

          if (is.null(charging_points) || nrow(charging_points)==0) {
            stop("No charging points available — ensure BigQuery data is loaded")
          }

          cat("DEBUG: Charging points:", nrow(charging_points), "\n")

          charging_proj <- st_transform(charging_points, crs=27700)
          start_proj    <- st_transform(st_sfc(start_point, crs=4326), crs=27700)
          distances     <- st_distance(charging_proj, start_proj)
          charging_points$distance <- as.numeric(distances)
          nearest <- charging_points %>% arrange(distance) %>% head(input$numChargingPoints)
          nearest_points(nearest)

          incProgress(0.6, detail="Routing via dodgr graph")
          graph          <- api_manager$network_data$graph
          shortest_len   <- Inf
          best_charge_pt <- NULL

          for (i in 1:nrow(nearest)) {
            cp    <- st_coordinates(st_geometry(nearest[i,]))
            d_to  <- tryCatch(dodgr_dists(graph, from=s_coords, to=cp)[1],   error=function(e) Inf)
            d_from<- tryCatch(dodgr_dists(graph, from=cp, to=e_coords)[1],   error=function(e) Inf)
            total <- d_to + d_from
            if (!is.na(total) && !is.infinite(total) && total < shortest_len) {
              shortest_len   <- total
              best_charge_pt <- i
            }
          }

          if (is.null(best_charge_pt)) stop("No valid route found through the charging points")

          cat("DEBUG: Best route:", round(shortest_len/1000,2), "km\n")

          incProgress(0.9, detail="Finalising")
          route_data(list(length=shortest_len, charge_point_index=best_charge_pt))
          route_calculated(TRUE)

          if (!is.null(api_manager)) {
            api_manager$route_info <- list(
              route_data          = route_data(),
              nearest_points      = nearest_points(),
              start_coords        = start_coords(),
              end_coords          = end_coords(),
              origin_address      = input$originAddress,
              destination_address = input$destinationAddress
            )
            api_manager$trigger_route_update()
          }

          output$routeStatus <- renderUI({
            div(class="status-success",
                h5("✓ Route Calculated"),
                p(strong("Distance: "), round(shortest_len/1000, 2), "km"),
                if (!origin_ok || !dest_ok)
                  p(style="color:#e67e22;font-size:12px;",
                    icon("exclamation-triangle"),
                    " One or more locations were outside the network region — results may be approximate.")
            )
          })

          cat("=== ROUTE OPTIMIZER SUCCESS ===\n\n")
          showNotification("Route calculated successfully!", type="message", duration=3)

        }, error=function(e) {
          cat("DEBUG: ERROR:", e$message, "\n")
          cat("=== ROUTE OPTIMIZER ERROR ===\n\n")
          route_calculated(FALSE)
          output$routeStatus <- renderUI({
            div(class="status-error", h5("✗ Failed"), p(as.character(e$message)))
          })
          showNotification(paste("Error:", e$message), type="error", duration=10)
        })
      })
    })

    output$routeSummary <- renderText({
      if (!route_calculated() || is.null(route_data())) return("No route calculated")
      paste0("Origin      : ", input$originAddress,
             "\nDestination : ", input$destinationAddress,
             "\nDistance    : ", round(route_data()$length/1000, 2), " km")
    })

    output$chargingPointsInfo <- renderText({
      if (is.null(nearest_points())) return("No charging points")
      np <- nearest_points()
      paste(sapply(1:nrow(np), function(i) {
        sel <- if (!is.null(route_data()) && i==route_data()$charge_point_index) " ✓ selected" else ""
        sprintf("%d. %.2f km%s", i, np[i,]$distance/1000, sel)
      }), collapse="\n")
    })

    output$routeCalculated <- reactive({ route_calculated() })
    outputOptions(output, "routeCalculated", suspendWhenHidden=FALSE)

    observeEvent(input$viewMap, {
      updateTabItems(session, "sidebar_menu", "route_map")
    })

    observeEvent(input$sendToSimulator, {
      if (!route_calculated() || is.null(route_data())) {
        showNotification("Please calculate a route first", type="warning", duration=5)
        return()
      }
      scenario <- api_manager$route_to_scenario(
        api_manager$route_info,
        conditions=list(road_type="auto", traffic="moderate_congestion", weather="clear")
      )
      if (!is.null(scenario)) {
        current_scenarios <- api_manager$get_scenarios()
        if (is.null(current_scenarios)) current_scenarios <- list()
        current_scenarios[[length(current_scenarios)+1]] <- scenario
        api_manager$load_omniverse_scenarios(current_scenarios)
        updateTabItems(session, "sidebar_menu", "omniverse_connection")
        showNotification("Route sent to simulation!", type="message", duration=5)
      }
    })
  })
}
