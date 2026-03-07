# modules/quest3_ar_viewer.R
# Quest 3 AR Viewer Module - Complete Map Rendering
# Sends full route data to Quest 3 for AR floor projection

# ============================================================================
# UI FUNCTION
# ============================================================================

advanced_visualization_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Quest 3 AR Visualization", 
        status = "success", 
        solidHeader = TRUE, 
        width = 12,
        
        tags$div(style = "background: #e8f5e9; padding: 15px; border-radius: 5px; margin-bottom: 20px;",
          tags$h4(style = "margin-top: 0; color: #2e7d32;", 
                  icon("vr-cardboard"), " Meta Quest 3 AR Setup"),
          tags$p(style = "margin-bottom: 10px;",
                 "Project the complete route map (roads, labels, markers) on your AR floor!"),
          tags$ol(style = "margin: 0; padding-left: 20px;",
            tags$li("Ensure Quest 3 AR server is running (Python script)"),
            tags$li("Put on your Quest 3 headset"),
            tags$li("Open browser and navigate to: ", 
                   tags$code("https://192.168.100.3:8443")),
            tags$li("Click 'Send to Quest 3' button below"),
            tags$li("The complete map will appear on your AR floor!")
          )
        ),
        
        fluidRow(
          column(6,
            h5("Server Configuration"),
            textInput(ns("quest3IP"), "Quest 3 Server IP:", 
                     value = "192.168.100.3"),
            numericInput(ns("quest3Port"), "Server Port:", 
                        value = 8443, min = 1024, max = 65535),
            
            checkboxInput(ns("verifySSL"), "Verify SSL Certificate", 
                         value = FALSE),
            
            actionButton(ns("testConnection"), "Test Connection", 
                        class = "btn-info", icon = icon("plug")),
            
            br(), br(),
            
            actionButton(ns("sendToQuest"), "Send to Quest 3", 
                        class = "btn-success btn-lg", 
                        icon = icon("paper-plane"),
                        style = "width: 100%; font-size: 18px;")
          ),
          
          column(6,
            h5("Connection Status"),
            uiOutput(ns("connectionStatus")),
            
            br(),
            
            h5("Current Scenario"),
            uiOutput(ns("scenarioInfo")),
            
            br(),
            
            tags$div(style = "background: #fff3cd; padding: 10px; border-radius: 5px;",
              tags$p(style = "margin: 0; font-size: 12px;",
                icon("lightbulb"), " ", tags$strong("AR Map Features:"),
                tags$ul(style = "margin: 5px 0 0 0; padding-left: 20px;",
                  tags$li("Complete map with roads and labels"),
                  tags$li("Green route line overlay"),
                  tags$li("Colored markers (GREEN/AMBER/RED)"),
                  tags$li("3D floating markers above floor")
                )
              )
            )
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "AR Preview", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        tags$p("This is how your route will appear in Quest 3 AR:"),
        
        htmlOutput(ns("arPreview"))
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

advanced_visualization_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Get selected scenario
    selected_scenario <- reactive({
      req(api_manager$selected_scenario)
      api_manager$selected_scenario
    })
    
    # Test connection to Quest 3 server
    observeEvent(input$testConnection, {
      url <- paste0("https://", input$quest3IP, ":", input$quest3Port, "/health")
      
      tryCatch({
        response <- httr::GET(
          url,
          httr::config(ssl_verifypeer = input$verifySSL, ssl_verifyhost = FALSE),
          httr::timeout(5)
        )
        
        if (httr::status_code(response) == 200) {
          showNotification(
            "✓ Quest 3 server is online!",
            type = "message",
            duration = 3
          )
        } else {
          showNotification(
            paste("Server responded with status:", httr::status_code(response)),
            type = "warning",
            duration = 5
          )
        }
      }, error = function(e) {
        showNotification(
          paste0("✗ Connection failed: ", e$message,
                "\n\nMake sure:\n",
                "1. Python AR server is running\n",
                "2. IP address is correct\n",
                "3. Firewall allows port ", input$quest3Port),
          type = "error",
          duration = 10
        )
      })
    })
    
    # Send scenario to Quest 3
    observeEvent(input$sendToQuest, {
      s <- selected_scenario()
      
      if (is.null(s)) {
        showNotification(
          "No scenario selected! Please generate or load a scenario first.",
          type = "warning",
          duration = 5
        )
        return()
      }
      
      url <- paste0("https://", input$quest3IP, ":", input$quest3Port, "/set_scenario")
      
      # Prepare scenario data
      scenario_json <- jsonlite::toJSON(list(scenario = s), auto_unbox = TRUE)
      
      tryCatch({
        showNotification(
          "Sending complete map to Quest 3...",
          type = "message",
          duration = 3,
          id = "quest3_sending"
        )
        
        response <- httr::POST(
          url,
          body = scenario_json,
          encode = "json",
          httr::add_headers(`Content-Type` = "application/json"),
          httr::config(ssl_verifypeer = input$verifySSL, ssl_verifyhost = FALSE),
          httr::timeout(10)
        )
        
        if (httr::status_code(response) == 200) {
          removeNotification("quest3_sending")
          
          num_points <- length(s$trajectories %||% list())
          
          showNotification(
            HTML(paste0(
              "✓ <strong>Map sent to Quest 3 successfully!</strong><br><br>",
              "<b>Route:</b> ", s$route %||% "Unknown", "<br>",
              "<b>Points:</b> ", num_points, "<br>",
              "<b>AV Readiness:</b> ", s$av_readiness %||% "N/A", "<br><br>",
              "Open Quest 3 browser and look down at the floor!"
            )),
            type = "message",
            duration = 10
          )
        } else {
          showNotification(
            paste("Server error:", httr::status_code(response)),
            type = "error",
            duration = 5
          )
        }
      }, error = function(e) {
        removeNotification("quest3_sending")
        showNotification(
          paste0("✗ Failed to send to Quest 3: ", e$message),
          type = "error",
          duration = 8
        )
      })
    })
    
    # Connection status display
    output$connectionStatus <- renderUI({
      tags$div(
        tags$div(
          style = "padding: 10px; background: #f0f0f0; border-radius: 5px;",
          tags$p(style = "margin: 0;",
            tags$strong("Server URL:"), tags$br(),
            tags$code(paste0("https://", input$quest3IP, ":", input$quest3Port))
          ),
          tags$p(style = "margin: 10px 0 0 0;",
            tags$strong("SSL Verification:"), 
            ifelse(input$verifySSL, "Enabled", "Disabled (Recommended)")
          )
        )
      )
    })
    
    # Scenario info display
    output$scenarioInfo <- renderUI({
      s <- selected_scenario()
      
      if (is.null(s)) {
        return(tags$p("No scenario selected", style = "color: #999;"))
      }
      
      num_points <- length(s$trajectories %||% list())
      
      tags$div(
        style = "padding: 10px; background: #e3f2fd; border-radius: 5px;",
        tags$p(style = "margin: 0;",
          tags$strong("Route:"), s$route %||% "Unknown", tags$br(),
          tags$strong("Points:"), num_points, tags$br(),
          tags$strong("AV Readiness:"), 
          tags$span(s$av_readiness %||% "N/A", 
                   style = paste0("color: ",
                     ifelse((s$av_readiness %||% "AMBER") == "GREEN", "#28a745",
                           ifelse((s$av_readiness %||% "AMBER") == "AMBER", "#ffc107", "#dc3545")),
                     "; font-weight: bold;"))
        )
      )
    })
    
    # AR Preview
    output$arPreview <- renderUI({
      s <- selected_scenario()
      
      if (is.null(s) || length(s$trajectories) == 0) {
        return(tags$p("Generate a scenario to see AR preview", style = "color: #999;"))
      }
      
      # Extract coordinates for preview
      lats <- sapply(s$trajectories, function(t) t$lat %||% NA)
      lons <- sapply(s$trajectories, function(t) t$lon %||% NA)
      
      valid <- !is.na(lats) & !is.na(lons)
      lats <- lats[valid]
      lons <- lons[valid]
      
      if (length(lats) == 0) {
        return(tags$p("No valid trajectory data", style = "color: #999;"))
      }
      
      minLat <- min(lats)
      maxLat <- max(lats)
      minLon <- min(lons)
      maxLon <- max(lons)
      centerLat <- (minLat + maxLat) / 2
      centerLon <- (minLon + maxLon) / 2
      
      # Calculate zoom
      latDiff <- maxLat - minLat
      lonDiff <- maxLon - minLon
      maxDiff <- max(latDiff, lonDiff)
      
      zoom <- if (maxDiff > 1.0) 9
         else if (maxDiff > 0.5) 10
         else if (maxDiff > 0.2) 11
         else if (maxDiff > 0.1) 12
         else if (maxDiff > 0.05) 13
         else 14
      
      # Build path
      pathCoords <- paste(sapply(seq_along(lons), function(i) {
        paste0(lons[i], ",", lats[i])
      }), collapse = ",")
      
      # Mapbox token
      token <- "MAPBOX_TOKEN_REMOVED"
      
      # Static map URL
      mapUrl <- paste0(
        "https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/",
        "path-5+00ff00-0.8(", pathCoords, ")/",
        centerLon, ",", centerLat, ",", zoom, ",0/800x600@2x",
        "?access_token=", token
      )
      
      tags$div(
        tags$img(src = mapUrl, style = "width: 100%; border-radius: 5px; box-shadow: 0 2px 8px rgba(0,0,0,0.2);"),
        tags$p(style = "margin-top: 10px; font-size: 12px; color: #666;",
          "This map (with roads, labels, and route) will be projected on your Quest 3 AR floor"
        )
      )
    })
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x
