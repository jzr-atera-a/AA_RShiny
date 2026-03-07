# modules/omniverse_connection.R
# NVIDIA Omniverse Isaac Sim Connection Module - FULL DYNAMIC API
# Contains both UI and Server logic in ONE file

# ============================================================================
# UI FUNCTION
# ============================================================================

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
        
        # File input
        uiOutput(ns("fileInputUI")),
        
        # Flask API inputs
        uiOutput(ns("flaskInputUI")),
        
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
        
        h5("Generate Scenarios for ANY UK Route:"),
        
        tags$div(
          style = "background: #e8f5e9; padding: 10px; border-radius: 5px; margin-bottom: 15px;",
          tags$p(style = "margin: 0; font-size: 12px;",
                 icon("lightbulb"), " ", tags$strong("Enter ANY two UK cities!"),
                 " System will geocode locations and generate realistic AV scenarios."
          )
        ),
        
        textInput(ns("queryOrigin"), "Origin City (REQUIRED):", 
                  placeholder = "Manchester, Bristol, Edinburgh, York..."),
        
        textInput(ns("queryDestination"), "Destination City (REQUIRED):", 
                  placeholder = "Liverpool, Cardiff, Glasgow, Leeds..."),
        
        selectInput(ns("queryRoadType"), "Road Type:",
                    choices = c("Auto-Detect (Recommended)" = "", 
                                "Motorway" = "motorway", 
                                "A-Road" = "A-road", 
                                "B-Road" = "B-road")),
        
        selectInput(ns("queryTraffic"), "Traffic Condition:",
                    choices = c("Random Mix" = "", 
                                "Free Flow" = "free_flow", 
                                "Light Traffic" = "light_traffic",
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
                    min = 1, max = 10, value = c(1, 10)),
        
        numericInput(ns("queryLimit"), "Number of Scenario Variations:", 
                     value = 3, min = 1, max = 10),
        
        br(),
        actionButton(ns("generateScenarios"), "Generate Scenarios", 
                     class = "btn-info", icon = icon("play-circle"), width = "100%")
      )
    ),
    
    fluidRow(
      box(
        title = "Omniverse System Status",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(3,
                 div(class = "small-box bg-aqua",
                     div(class = "inner",
                         h3(textOutput(ns("scenarioCount"))),
                         p("Scenarios Loaded")
                     ),
                     div(class = "icon", icon("database", style = "font-size: 70px;"))
                 )
          ),
          column(3,
                 div(class = "small-box bg-green",
                     div(class = "inner",
                         h3(textOutput(ns("trajectoryCount"))),
                         p("Trajectory Points")
                     ),
                     div(class = "icon", icon("route", style = "font-size: 70px;"))
                 )
          ),
          column(3,
                 div(class = "small-box bg-yellow",
                     div(class = "inner",
                         h3(textOutput(ns("incidentCount"))),
                         p("Incidents Detected")
                     ),
                     div(class = "icon", icon("exclamation-triangle", style = "font-size: 70px;"))
                 )
          ),
          column(3,
                 div(class = "small-box bg-blue",
                     div(class = "inner",
                         h3(textOutput(ns("avgQualityScore"))),
                         p("Avg Quality Score")
                     ),
                     div(class = "icon", icon("star", style = "font-size: 70px;"))
                 )
          )
        )
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

omniverse_connection_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    omniverse_data <- reactiveValues(
      scenarios = NULL,
      connected = FALSE,
      error = NULL,
      flask_url = "http://localhost:5000"
    )
    
    # Render file input conditionally
    output$fileInputUI <- renderUI({
      if (input$dataSource == "file") {
        fileInput(session$ns("jsonFile"), "Select Omniverse JSON Output:",
                  accept = c(".json"),
                  buttonLabel = "Browse...",
                  placeholder = "omniverse_av_scenarios.json")
      }
    })
    
    # Render Flask API inputs conditionally
    output$flaskInputUI <- renderUI({
      if (input$dataSource == "flask") {
        tagList(
          textInput(session$ns("flaskURL"), "Flask API URL:",
                    value = "http://localhost:5000",
                    placeholder = "http://localhost:5000"),
          tags$p(class = "text-muted", 
                 "Make sure Flask API is running: python isaac_sim_flask_api.py")
        )
      }
    })
    
    # Test Connection
    observeEvent(input$testConnection, {
      tryCatch({
        if (input$dataSource == "file") {
          if (is.null(input$jsonFile)) {
            stop("Please select a JSON file")
          }
          file_path <- input$jsonFile$datapath
          if (file.exists(file_path)) {
            omniverse_data$connected <- TRUE
            omniverse_data$error <- NULL
            showNotification("✓ File found and readable", type = "message", duration = 3)
          } else {
            stop("File not found")
          }
          
        } else if (input$dataSource == "flask") {
          # Test Flask API connection
          url <- input$flaskURL
          response <- httr::GET(paste0(url, "/"))
          
          if (httr::status_code(response) == 200) {
            omniverse_data$flask_url <- url
            omniverse_data$connected <- TRUE
            omniverse_data$error <- NULL
            
            showNotification(
              "✓ Flask API connected! Ready to generate scenarios for ANY UK route.", 
              type = "message", 
              duration = 3
            )
          } else {
            stop("Flask API returned error")
          }
          
        } else if (input$dataSource == "demo") {
          omniverse_data$connected <- TRUE
          omniverse_data$error <- NULL
          showNotification("✓ Demo data ready", type = "message", duration = 3)
        }
        
      }, error = function(e) {
        omniverse_data$connected <- FALSE
        omniverse_data$error <- e$message
        showNotification(
          paste("❌ Connection failed:", e$message, 
                "\n\nIf using Flask API, make sure it's running:\n",
                "python isaac_sim_flask_api.py"), 
          type = "error", 
          duration = 8
        )
      })
    })
    
    # Load/Generate Scenarios
    observeEvent(input$loadScenarios, {
      tryCatch({
        if (input$dataSource == "file") {
          if (is.null(input$jsonFile)) {
            stop("Please select a JSON file first")
          }
          json_data <- jsonlite::fromJSON(input$jsonFile$datapath, simplifyVector = FALSE)
          if (!is.null(json_data$scenario_id)) {
            json_data <- list(json_data)
          }
          omniverse_data$scenarios <- json_data
          
        } else if (input$dataSource == "flask") {
          # Generate scenarios via Flask API
          url <- omniverse_data$flask_url
          
          # Validate required fields
          if (nchar(input$queryOrigin) == 0 || nchar(input$queryDestination) == 0) {
            stop("Both Origin and Destination cities are REQUIRED for scenario generation")
          }
          
          # Build query parameters
          query_body <- list(
            origin = input$queryOrigin,
            destination = input$queryDestination
          )
          
          if (input$queryRoadType != "") {
            query_body$road_type <- input$queryRoadType
          }
          if (input$queryTraffic != "") {
            query_body$traffic <- input$queryTraffic
          }
          
          query_body$weather <- input$queryWeather
          query_body$min_quality <- input$queryQualityRange[1]
          query_body$max_quality <- input$queryQualityRange[2]
          query_body$limit <- input$queryLimit
          
          # Query API
          response <- httr::POST(
            paste0(url, "/scenarios/query"),
            body = query_body,
            encode = "json",
            httr::timeout(30)
          )
          
          if (httr::status_code(response) == 200) {
            data <- httr::content(response)
            
            if (data$count == 0) {
              showNotification("No scenarios generated. Try adjusting quality range.", 
                               type = "warning", duration = 3)
              omniverse_data$scenarios <- list()
            } else {
              omniverse_data$scenarios <- data$scenarios
              
              showNotification(
                paste0("✓ Generated ", data$count, " scenario(s) for:\n",
                       input$queryOrigin, " → ", input$queryDestination), 
                type = "message", 
                duration = 5
              )
            }
          } else {
            error_msg <- httr::content(response)$error
            stop(paste("Flask API error:", error_msg))
          }
          
        } else if (input$dataSource == "demo") {
          # Demo data
          omniverse_data$scenarios <- list(
            list(
              scenario_id = "demo_a10_amber",
              route = "A10 Cambridge to London",
              av_readiness = "AMBER",
              quality_score = 6.2,
              trajectories = list(
                list(lat = 52.2053, lon = 0.1218, speed = 55, quality_score = 6),
                list(lat = 52.2065, lon = 0.1230, speed = 52, quality_score = 6),
                list(lat = 52.2080, lon = 0.1245, speed = 50, quality_score = 7)
              ),
              incidents = list(
                list(lat = 52.210, lon = 0.125, type = "hard_braking", severity = "medium")
              )
            )
          )
        }
        
        # Store in shared API manager
        api_manager$omniverse_scenarios <- omniverse_data$scenarios
        
      }, error = function(e) {
        omniverse_data$error <- e$message
        showNotification(paste("❌ Generation failed:", e$message), type = "error", duration = 5)
      })
    })
    
    # Generate Scenarios Button - FIXED VERSION
    observeEvent(input$generateScenarios, {
      tryCatch({
        # Validate required fields
        if (nchar(input$queryOrigin) == 0 || nchar(input$queryDestination) == 0) {
          showNotification("Both Origin and Destination are REQUIRED!", type = "error", duration = 3)
          return()
        }
        
        url <- omniverse_data$flask_url
        
        # Build query parameters
        query_body <- list(
          origin = input$queryOrigin,
          destination = input$queryDestination,
          weather = input$queryWeather,
          min_quality = input$queryQualityRange[1],
          max_quality = input$queryQualityRange[2],
          limit = input$queryLimit
        )
        
        if (input$queryRoadType != "") query_body$road_type <- input$queryRoadType
        if (input$queryTraffic != "") query_body$traffic <- input$queryTraffic
        
        # Query API
        response <- httr::POST(
          paste0(url, "/scenarios/query"),
          body = query_body,
          encode = "json",
          httr::timeout(1800)
        )
        
        if (httr::status_code(response) == 200) {
          data <- httr::content(response)
          
          if (data$count == 0) {
            showNotification("No scenarios generated. Try adjusting quality range.", 
                             type = "warning", duration = 3)
            omniverse_data$scenarios <- list()
          } else {
            omniverse_data$scenarios <- data$scenarios
            api_manager$omniverse_scenarios <- data$scenarios
            
            showNotification(
              paste0("✓ Generated ", data$count, " scenario(s) for:\n",
                     input$queryOrigin, " → ", input$queryDestination), 
              type = "message", 
              duration = 5
            )
          }
        } else {
          error_msg <- httr::content(response)$error
          stop(paste("Flask API error:", error_msg))
        }
        
      }, error = function(e) {
        showNotification(paste("❌ Error:", e$message), type = "error", duration = 5)
      })
    })
    
    # Connection Status Output
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
            icon("info-circle"), " Not connected. Click 'Test Connection' to verify setup."
        )
      }
    })
    
    # Value Boxes
    output$scenarioCount <- renderText({
      if (is.null(omniverse_data$scenarios)) return("0")
      length(omniverse_data$scenarios)
    })
    
    output$trajectoryCount <- renderText({
      if (is.null(omniverse_data$scenarios)) return("0")
      total <- 0
      for (s in omniverse_data$scenarios) {
        if (!is.null(s$trajectories) && is.list(s$trajectories)) {
          total <- total + length(s$trajectories)
        }
      }
      return(as.character(total))
    })
    
    output$incidentCount <- renderText({
      if (is.null(omniverse_data$scenarios)) return("0")
      total <- 0
      for (s in omniverse_data$scenarios) {
        if (!is.null(s$incidents) && is.list(s$incidents)) {
          total <- total + length(s$incidents)
        }
      }
      return(as.character(total))
    })
    
    output$avgQualityScore <- renderText({
      if (is.null(omniverse_data$scenarios)) return("N/A")
      scores <- sapply(omniverse_data$scenarios, function(s) s$quality_score %||% 0)
      if (length(scores) == 0) return("N/A")
      paste0(round(mean(scores, na.rm = TRUE), 1), "/10")
    })
    
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x