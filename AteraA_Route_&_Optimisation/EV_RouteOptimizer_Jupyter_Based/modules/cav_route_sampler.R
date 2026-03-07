# modules/cav_route_sampler.R
# CAV Route Sampler Module - Google Maps Integration via Python
# Extracts routes and generates waypoints

# ============================================================================
# UI FUNCTION
# ============================================================================

cav_route_sampler_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Google Maps Route Extraction",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        tags$div(style = "background: #e3f2fd; padding: 15px; border-radius: 5px; margin-bottom: 15px;",
          tags$h5(style = "margin-top: 0; color: #1976d2;", 
                  icon("map"), " Route Configuration"),
          tags$p(style = "margin-bottom: 0; font-size: 13px;",
                 "Extract routes from Google Maps and generate waypoints for CAV analysis")
        ),
        
        textInput(ns("google_api_key"), 
                  "Google Maps API Key:", 
                  placeholder = "Enter your API key"),
        
        tags$small(class = "text-muted", 
                  "Required: Directions API + Street View Static API enabled"),
        
        br(), br(),
        
        textInput(ns("origin"), 
                  "Origin:", 
                  placeholder = "e.g., London, UK"),
        
        textInput(ns("destination"), 
                  "Destination:", 
                  placeholder = "e.g., Cambridge, UK"),
        
        sliderInput(ns("sampling_interval"),
                    "Waypoint Spacing (meters):",
                    min = 25,
                    max = 200,
                    value = 50,
                    step = 25),
        
        tags$small(class = "text-muted", 
                  "Lower = more waypoints = higher accuracy & cost"),
        
        br(), br(),
        
        actionButton(ns("generate_waypoints"),
                     "Get Route & Generate Waypoints",
                     class = "btn-success btn-block",
                     icon = icon("route")),
        
        br(), br(),
        
        uiOutput(ns("sampling_status"))
      ),
      
      box(
        title = "Route Statistics",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        tags$div(style = "background: #fff3e0; padding: 15px; border-radius: 5px; margin-bottom: 15px;",
          tags$h5(style = "margin-top: 0;", icon("python"), " Python Backend Integration"),
          tags$ul(style = "margin-bottom: 0; padding-left: 20px;",
            tags$li("Google Maps Directions API for routing"),
            tags$li("Polyline decoding for route coordinates"),
            tags$li("Haversine distance-based waypoint resampling")
          )
        ),
        
        fluidRow(
          column(3, valueBoxOutput(ns("route_distance"), width = NULL)),
          column(3, valueBoxOutput(ns("waypoint_count"), width = NULL)),
          column(3, valueBoxOutput(ns("estimated_images"), width = NULL)),
          column(3, valueBoxOutput(ns("estimated_cost"), width = NULL))
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Generated Waypoints",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        
        DTOutput(ns("waypoints_table"))
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

cav_route_sampler_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    waypoints_data <- reactiveVal(NULL)
    route_info <- reactiveVal(NULL)
    
    observeEvent(input$generate_waypoints, {
      
      # Validate inputs
      if (is.null(input$google_api_key) || input$google_api_key == "") {
        output$sampling_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  tags$strong(icon("times-circle"), " Missing API Key"),
                  tags$p("Please enter your Google Maps API key above."))
        })
        return()
      }
      
      if (is.null(input$origin) || input$origin == "" ||
          is.null(input$destination) || input$destination == "") {
        output$sampling_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  tags$strong(icon("times-circle"), " Missing Locations"),
                  tags$p("Please enter both origin and destination."))
        })
        return()
      }
      
      withProgress(message = 'Calling Python backend...', value = 0, {
        
        tryCatch({
          
          incProgress(0.2, detail = "Calling Google Maps API via Python")
          
          # CALL PYTHON BACKEND
          result <- get_route_python(
            origin = input$origin,
            destination = input$destination,
            api_key = input$google_api_key,
            spacing_meters = input$sampling_interval
          )
          
          if (!result$success) {
            stop(result$error)
          }
          
          incProgress(0.6, detail = "Processing waypoints")
          
          # Convert to dataframe
          waypoints <- as.data.frame(do.call(rbind, result$waypoints))
          waypoints$waypoint_id <- paste0("WP_", sprintf("%04d", waypoints$sequence))
          
          # Store route info
          route_info(list(
            origin = result$origin$address,
            destination = result$destination$address,
            distance_km = result$distance_km,
            duration_min = result$duration_min,
            waypoint_count = nrow(waypoints),
            sampling_interval = input$sampling_interval,
            polyline_encoded = result$polyline_encoded
          ))
          
          incProgress(0.9, detail = "Storing data")
          
          # Store in api_manager for other modules
          if (!is.null(api_manager)) {
            api_manager$cav_waypoints <- waypoints
            api_manager$cav_route_info <- route_info()
          }
          
          waypoints_data(waypoints)
          
          output$sampling_status <- renderUI({
            tags$div(class = "alert alert-success",
                    tags$strong(icon("check-circle"), " Success!"),
                    tags$p(sprintf("Route retrieved: %s → %s", 
                                  result$origin$address, 
                                  result$destination$address)),
                    tags$ul(
                      tags$li(strong("Waypoints:"), nrow(waypoints)),
                      tags$li(strong("Distance:"), sprintf("%.1f km", result$distance_km)),
                      tags$li(strong("Duration:"), sprintf("%.0f minutes", result$duration_min))
                    ))
          })
          
          showNotification(
            paste("Generated", nrow(waypoints), "waypoints successfully!"),
            type = "message",
            duration = 3
          )
          
        }, error = function(e) {
          output$sampling_status <- renderUI({
            tags$div(class = "alert alert-danger",
                    tags$strong(icon("exclamation-triangle"), " Error"),
                    tags$p(as.character(e$message)))
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    # Value boxes
    output$route_distance <- renderValueBox({
      info <- route_info()
      valueBox(
        value = if (is.null(info)) "N/A" else sprintf("%.1f km", info$distance_km),
        subtitle = "Route Distance",
        icon = icon("route"),
        color = "blue"
      )
    })
    
    output$waypoint_count <- renderValueBox({
      info <- route_info()
      valueBox(
        value = if (is.null(info)) "N/A" else format(info$waypoint_count, big.mark = ","),
        subtitle = "Waypoints Generated",
        icon = icon("map-marker-alt"),
        color = "green"
      )
    })
    
    output$estimated_images <- renderValueBox({
      info <- route_info()
      valueBox(
        value = if (is.null(info)) "N/A" else format(info$waypoint_count, big.mark = ","),
        subtitle = "Estimated Images",
        icon = icon("camera"),
        color = "orange"
      )
    })
    
    output$estimated_cost <- renderValueBox({
      info <- route_info()
      cost <- if (is.null(info)) 0 else info$waypoint_count * 0.007
      valueBox(
        value = if (is.null(info)) "N/A" else sprintf("$%.2f", cost),
        subtitle = "Estimated API Cost",
        icon = icon("dollar-sign"),
        color = "red"
      )
    })
    
    # Waypoints table
    output$waypoints_table <- renderDT({
      wp <- waypoints_data()
      
      if (is.null(wp)) {
        return(datatable(
          data.frame(Message = "Generate waypoints first to see data here"),
          options = list(dom = 't'),
          rownames = FALSE
        ))
      }
      
      display_data <- wp %>%
        select(waypoint_id, sequence, lat, lng, distance_from_start) %>%
        mutate(
          lat = round(as.numeric(lat), 6),
          lng = round(as.numeric(lng), 6),
          distance_km = round(as.numeric(distance_from_start) / 1000, 2)
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
