# modules/omniverse_connection.R
# FIXED with debugging for Flask API integration

omniverse_connection_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Isaac Sim Connection Settings", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        
        h4("Omniverse Data Source"),
        p("Connect to NVIDIA Isaac Sim simulation for WP5 AV scenarios."),
        
        selectInput(ns("dataSource"), "Data Source:",
                    choices = c("Local File" = "file", 
                                "Flask API (Live)" = "flask",
                                "Demo Data" = "demo"),
                    selected = "flask"),
        
        conditionalPanel(
          condition = paste0("input['", ns("dataSource"), "'] == 'file'"),
          fileInput(ns("scenarioFile"), "Upload Scenario JSON:", accept = c(".json"))
        ),
        
        conditionalPanel(
          condition = paste0("input['", ns("dataSource"), "'] == 'flask'"),
          textInput(ns("flaskURL"), "Flask API URL:", value = "http://localhost:5000",
                    placeholder = "http://localhost:5000"),
          p(class = "text-muted", style = "font-size: 12px;",
            "Make sure Flask API is running: python isaac_sim_flask_api_KIANIRO.py")
        ),
        
        br(),
        
        actionButton(ns("testConnection"), "Test Connection", 
                     class = "btn-primary", icon = icon("plug"), width = "48%"),
        actionButton(ns("loadScenarios"), "Load Scenarios", 
                     class = "btn-success", icon = icon("download"), width = "48%"),
        
        br(), br(),
        uiOutput(ns("connectionStatus"))
      ),
      
      box(
        title = "Scenario Generation Parameters", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        
        h4("Generate Scenarios for ANY UK Route:"),
        p(class = "text-info", style = "background: #d1ecf1; padding: 10px; border-radius: 5px;",
          icon("map-marker-alt"), " Enter ANY two UK cities! System will geocode locations and generate realistic AV scenarios."),
        
        textInput(ns("queryOrigin"), "Origin City (REQUIRED):",
                  value = "",
                  placeholder = "Manchester, Bristol, Edinburgh, York..."),
        
        textInput(ns("queryDestination"), "Destination City (REQUIRED):",
                  value = "",
                  placeholder = "Liverpool, Cardiff, Glasgow, Leeds..."),
        
        selectInput(ns("queryRoadType"), "Road Type:",
                    choices = c("Auto-Detect (Recommended)" = "",
                                "Motorway" = "motorway",
                                "A-Road" = "a_road",
                                "B-Road" = "b_road")),
        
        selectInput(ns("queryTraffic"), "Traffic Condition:",
                    choices = c("Random Mix" = "",
                                "Free Flow" = "free_flow",
                                "Light" = "light",
                                "Moderate Congestion" = "moderate_congestion",
                                "Heavy Congestion" = "heavy_congestion",
                                "Rush Hour" = "rush_hour")),
        
        selectInput(ns("queryWeather"), "Weather Condition:",
                    choices = c("Clear" = "clear",
                                "Rain" = "rain",
                                "Fog" = "fog",
                                "Night" = "night",
                                "Dusk" = "dusk")),
        
        sliderInput(ns("queryQualityRange"), "Quality Score Range (for filtering):",
                    min = 1, max = 10, value = c(1, 10), step = 1),
        
        numericInput(ns("queryLimit"), "Number of Scenario Variations:",
                     value = 1, min = 1, max = 10, step = 1),
        
        br(),
        
        actionButton(ns("generateScenarios"), "Generate Scenarios",
                     class = "btn-primary btn-lg", icon = icon("cogs"), width = "100%")
      )
    ),
    
    fluidRow(
      box(
        title = "System Status",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(3, valueBoxOutput(ns("totalScenarios"), width = NULL)),
          column(3, valueBoxOutput(ns("totalTrajectories"), width = NULL)),
          column(3, valueBoxOutput(ns("totalIncidents"), width = NULL)),
          column(3, valueBoxOutput(ns("avgQuality"), width = NULL))
        )
      )
    )
  )
}

omniverse_connection_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    omniverse_data <- reactiveValues(
      connected = FALSE,
      flask_url = "http://localhost:5000",
      scenarios = list(),
      error = NULL
    )
    
    # Test Connection
    observeEvent(input$testConnection, {
      cat("\n=== TESTING OMNIVERSE CONNECTION ===\n")
      
      tryCatch({
        if (input$dataSource == "flask") {
          url <- input$flaskURL
          omniverse_data$flask_url <- url
          
          cat("DEBUG: Testing Flask API at:", url, "\n")
          
          response <- httr::GET(paste0(url, "/status"), httr::timeout(5))
          
          cat("DEBUG: Response status code:", httr::status_code(response), "\n")
          
          if (httr::status_code(response) == 200) {
            data <- httr::content(response)
            cat("DEBUG: Status response:", toJSON(data, auto_unbox = TRUE), "\n")
            
            omniverse_data$connected <- TRUE
            omniverse_data$error <- NULL
            
            showNotification("✓ Connected to Flask API!", type = "message", duration = 3)
          } else {
            stop("Flask API returned non-200 status")
          }
        } else {
          omniverse_data$connected <- TRUE
          showNotification("✓ Ready to load data", type = "message", duration = 2)
        }
        
      }, error = function(e) {
        cat("DEBUG: Connection test FAILED:", e$message, "\n")
        omniverse_data$connected <- FALSE
        omniverse_data$error <- e$message
        showNotification(paste("Connection failed:", e$message), type = "error", duration = 5)
      })
      
      cat("=== CONNECTION TEST END ===\n\n")
    })
    
    # Generate Scenarios
    observeEvent(input$generateScenarios, {
      cat("\n=== GENERATE SCENARIOS CLICKED ===\n")
      
      # Validate inputs
      if (nchar(input$queryOrigin) == 0 || nchar(input$queryDestination) == 0) {
        cat("DEBUG: Missing origin or destination\n")
        showNotification("Both Origin and Destination are REQUIRED!", type = "error", duration = 3)
        return()
      }
      
      cat("DEBUG: Origin:", input$queryOrigin, "\n")
      cat("DEBUG: Destination:", input$queryDestination, "\n")
      cat("DEBUG: Weather:", input$queryWeather, "\n")
      cat("DEBUG: Limit:", input$queryLimit, "\n")
      
      tryCatch({
        url <- omniverse_data$flask_url
        
        cat("DEBUG: Flask URL:", url, "\n")
        
        # Build query body
        query_body <- list(
          origin = input$queryOrigin,
          destination = input$queryDestination,
          weather = input$queryWeather,
          time_of_day = "day",
          limit = as.integer(input$queryLimit)
        )
        
        cat("DEBUG: Query body:", toJSON(query_body, auto_unbox = TRUE), "\n")
        
        withProgress(message = 'Generating scenarios...', value = 0, {
          
          incProgress(0.2, detail = "Sending request to Isaac Sim...")
          
          cat("DEBUG: Sending POST to", paste0(url, "/scenarios/query"), "\n")
          
          response <- httr::POST(
            paste0(url, "/scenarios/query"),
            body = query_body,
            encode = "json",
            httr::timeout(1800),
            httr::verbose()
          )
          
          cat("DEBUG: Response received, status code:", httr::status_code(response), "\n")
          
          incProgress(0.8, detail = "Processing response...")
          
          if (httr::status_code(response) == 200) {
            data <- httr::content(response)
            
            cat("DEBUG: Response data count:", data$count, "\n")
            
            if (data$count == 0) {
              showNotification("No scenarios generated.", type = "warning", duration = 3)
              omniverse_data$scenarios <- list()
            } else {
              omniverse_data$scenarios <- data$scenarios
              api_manager$load_omniverse_scenarios(data$scenarios)
              
              cat("DEBUG: Loaded", data$count, "scenarios into memory\n")
              
              showNotification(
                paste0("✓ Generated ", data$count, " scenario(s) for:\n",
                       input$queryOrigin, " → ", input$queryDestination), 
                type = "message", 
                duration = 5
              )
            }
            
            incProgress(1, detail = "Complete")
          } else {
            error_data <- httr::content(response)
            error_msg <- if (!is.null(error_data$error)) error_data$error else "Unknown error"
            cat("DEBUG: API returned error:", error_msg, "\n")
            stop(paste("Flask API error:", error_msg))
          }
        })
        
      }, error = function(e) {
        cat("DEBUG: ERROR in generateScenarios:", e$message, "\n")
        showNotification(paste("❌ Error:", e$message), type = "error", duration = 10)
      })
      
      cat("=== GENERATE SCENARIOS END ===\n\n")
    })
    
    # Connection Status UI
    output$connectionStatus <- renderUI({
      if (omniverse_data$connected) {
        div(class = "connection-success",
            style = "background: #d4edda; padding: 10px; border-radius: 5px; color: #155724;",
            icon("check-circle"), " Connected to ", 
            if (input$dataSource == "flask") {
              paste0("Flask API (", omniverse_data$flask_url, ")")
            } else {
              "Omniverse data source"
            }
        )
      } else if (!is.null(omniverse_data$error)) {
        div(class = "connection-error",
            style = "background: #f8d7da; padding: 10px; border-radius: 5px; color: #721c24;",
            icon("times-circle"), " Error: ", omniverse_data$error
        )
      } else {
        div(class = "connection-warning",
            style = "background: #fff3cd; padding: 10px; border-radius: 5px; color: #856404;",
            icon("info-circle"), " Not connected. Click 'Test Connection' to verify setup.")
      }
    })
    
    # Value boxes
    output$totalScenarios <- renderValueBox({
      count <- length(omniverse_data$scenarios)
      valueBox(count, "Scenarios", icon = icon("route"), color = "blue")
    })
    
    output$totalTrajectories <- renderValueBox({
      total <- sum(sapply(omniverse_data$scenarios, function(s) length(s$trajectories %||% list())))
      valueBox(total, "Trajectories", icon = icon("map-signs"), color = "green")
    })
    
    output$totalIncidents <- renderValueBox({
      total <- sum(sapply(omniverse_data$scenarios, function(s) length(s$incidents %||% list())))
      valueBox(total, "Incidents", icon = icon("exclamation-triangle"), color = "red")
    })
    
    output$avgQuality <- renderValueBox({
      scores <- sapply(omniverse_data$scenarios, function(s) s$quality_score %||% 0)
      avg <- if (length(scores) > 0) round(mean(scores), 1) else 0
      valueBox(avg, "Avg Quality", icon = icon("star"), color = "yellow")
    })
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x
