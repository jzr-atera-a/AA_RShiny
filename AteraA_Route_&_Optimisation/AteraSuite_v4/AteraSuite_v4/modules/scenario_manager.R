# modules/scenario_manager.R
# Scenario Browser and Manager Module - WITH QUEST 3 INTEGRATION
# Contains both UI and Server logic in ONE file

# ============================================================================
# UI FUNCTION
# ============================================================================

scenario_manager_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Available Scenarios", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 8,
        
        p("Browse and select Omniverse AV simulation scenarios loaded from Isaac Sim."),
        
        DT::dataTableOutput(ns("scenarioTable")),
        
        br(),
        fluidRow(
          column(6,
                 actionButton(ns("refreshScenarios"), "Refresh List", 
                              class = "btn-info", icon = icon("sync"), width = "100%")
          ),
          column(6,
                 actionButton(ns("sendToQuest"), "Send to Quest 3", 
                              class = "btn-success", icon = icon("vr-cardboard"), 
                              width = "100%", disabled = TRUE)
          )
        )
      ),
      
      box(
        title = "Scenario Details",
        status = "info",
        solidHeader = TRUE,
        width = 4,
        
        h4("Selected Scenario Information"),
        
        uiOutput(ns("vehicleInfo")),
        
        hr(),
        
        uiOutput(ns("scenarioDetails")),
        
        br(),
        uiOutput(ns("quest3Status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Trajectory Analysis",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        
        plotly::plotlyOutput(ns("trajectoryPlot"), height = "400px")
      ),
      
      box(
        title = "Quality Score Distribution",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        
        plotly::plotlyOutput(ns("qualityPlot"), height = "400px")
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

scenario_manager_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    selected_scenario <- reactiveVal(NULL)
    quest3_server_url <- reactiveVal("https://127.0.0.1:8443")
    
    # Create reactive wrapper for api_manager scenarios
    scenarios <- reactive({
      # Force re-evaluation when refresh button clicked
      input$refreshScenarios
      
      # Return scenarios from api_manager
      if (!is.null(api_manager$omniverse_scenarios)) {
        return(api_manager$omniverse_scenarios)
      } else {
        return(NULL)
      }
    })
    
    output$scenarioTable <- DT::renderDataTable({
      scenario_list <- scenarios()
      
      if (is.null(scenario_list) || length(scenario_list) == 0) {
        # Return empty table with message
        return(DT::datatable(
          data.frame(Message = "No scenarios loaded. Go to 'Omniverse' tab to load data."),
          options = list(dom = 't'),
          rownames = FALSE
        ))
      }
      
      table_data <- lapply(scenario_list, function(s) {
        data.frame(
          ScenarioID = s$scenario_id %||% "Unknown",
          Route = s$route %||% "N/A",
          AVReadiness = s$av_readiness %||% "N/A",
          QualityScore = s$quality_score %||% 0,
          Trajectories = length(s$trajectories %||% list()),
          Incidents = length(s$incidents %||% list()),
          Infrastructure = length(s$infrastructure %||% list()),
          stringsAsFactors = FALSE
        )
      })
      
      df <- do.call(rbind, table_data)
      
      DT::datatable(
        df,
        selection = 'single',
        options = list(
          pageLength = 10,
          dom = 'frtip',
          order = list(list(3, 'desc'))
        ),
        rownames = FALSE
      ) %>%
        DT::formatStyle(
          'AVReadiness',
          backgroundColor = DT::styleEqual(
            c('GREEN', 'AMBER', 'RED'),
            c('#27ae60', '#f39c12', '#e74c3c')
          ),
          color = 'white',
          fontWeight = 'bold'
        ) %>%
        DT::formatRound('QualityScore', 1)
    })
    
    # Scenario selection
    observeEvent(input$scenarioTable_rows_selected, {
      scenario_list <- scenarios()
      req(scenario_list, input$scenarioTable_rows_selected)
      
      # Safety check
      row_index <- input$scenarioTable_rows_selected
      if (row_index > 0 && row_index <= length(scenario_list)) {
        selected_scenario(scenario_list[[row_index]])
        api_manager$selected_scenario <- scenario_list[[row_index]]
        
        # Enable "Send to Quest 3" button
        shiny::updateActionButton(session, "sendToQuest", disabled = FALSE)
      }
    })
    
    # Send scenario to Quest 3
    observeEvent(input$sendToQuest, {
      req(selected_scenario())
      
      tryCatch({
        # Send scenario to Python HTTPS server with SSL verification disabled
        response <- httr::POST(
          paste0(quest3_server_url(), "/set_scenario"),
          body = selected_scenario(),
          encode = "json",
          httr::config(
            ssl_verifypeer = FALSE,
            ssl_verifyhost = FALSE
          )
        )
        
        if (httr::status_code(response) == 200) {
          result <- httr::content(response)
          
          showNotification(
            paste0("✓ Scenario sent to Quest 3!\n",
                   "Scenario: ", result$scenario_id, "\n\n",
                   "Open Quest 3 browser and navigate to:\n",
                   "https://192.168.100.3:8443/ar"),
            type = "message",
            duration = 10
          )
          
        } else {
          stop("Server returned error")
        }
        
      }, error = function(e) {
        showNotification(
          paste0("❌ Failed to send to Quest 3: ", e$message, "\n\n",
                 "Make sure Python HTTPS server is running:\n",
                 "python quest3_ar_https_server.py 192.168.100.3"),
          type = "error",
          duration = 8
        )
      })
    })
    
    # Vehicle Info Output
    output$vehicleInfo <- renderUI({
      vehicle_config <- api_manager$vehicle_config
      
      if (is.null(vehicle_config)) {
        return(tags$p(class = "text-muted", "No vehicle configuration loaded"))
      }
      
      tags$div(
        style = "background: #fff3cd; padding: 10px; border-radius: 5px; margin-bottom: 10px;",
        tags$h5(icon("car"), " Vehicle: ", vehicle_config$name),
        tags$p(style = "margin: 5px 0;", 
               tags$b("Mass:"), sprintf(" %,d kg", vehicle_config$mass_properties$curb_weight_kg)),
        tags$p(style = "margin: 5px 0;", 
               tags$b("Power:"), sprintf(" %d kW", vehicle_config$powertrain$motor_power_kw))
      )
    })
    
    # Scenario details panel
    output$scenarioDetails <- renderUI({
      if (is.null(selected_scenario())) {
        return(div(class = "status-info",
                   icon("info-circle"), " Select a scenario from the table to view details."
        ))
      }
      
      s <- selected_scenario()
      
      tagList(
        h4(s$scenario_id %||% "Unknown Scenario"),
        hr(),
        tags$p(tags$strong("Route:"), s$route %||% "N/A"),
        tags$p(tags$strong("Road Type:"), s$road_type %||% "N/A"),
        tags$p(tags$strong("AV Readiness:"), 
               span(class = paste0("readiness-", tolower(s$av_readiness %||% "amber")),
                    style = paste0("color: ",
                                   if(s$av_readiness == "GREEN") "#00ff00" else
                                     if(s$av_readiness == "AMBER") "#ffaa00" else "#ff0000"),
                    s$av_readiness %||% "N/A")),
        tags$p(tags$strong("Quality Score:"), 
               paste0(s$quality_score %||% "N/A", "/10")),
        tags$p(tags$strong("Trajectory Points:"), 
               length(s$trajectories %||% list())),
        tags$p(tags$strong("Incidents:"), 
               length(s$incidents %||% list())),
        tags$p(tags$strong("Infrastructure:"), 
               length(s$infrastructure %||% list())),
        
        if (!is.null(s$traffic_condition)) {
          tags$p(tags$strong("Traffic:"), s$traffic_condition)
        },
        
        if (!is.null(s$weather_condition)) {
          tags$p(tags$strong("Weather:"), s$weather_condition)
        },
        
        hr(),
        h5("Incident Summary:"),
        if (length(s$incidents %||% list()) > 0) {
          tags$ul(
            lapply(s$incidents, function(inc) {
              tags$li(
                paste0(inc$type %||% "Unknown", " (", 
                       inc$severity %||% "unknown", " severity)")
              )
            })
          )
        } else {
          tags$p(class = "text-muted", "No incidents detected")
        },
        
        if (length(s$infrastructure %||% list()) > 0) {
          tagList(
            hr(),
            h5("Infrastructure Points:"),
            tags$ul(
              lapply(head(s$infrastructure, 5), function(inf) {
                tags$li(
                  paste0(inf$type %||% "Unknown", 
                         if(!is.null(inf$av_ready) && !inf$av_ready) {
                           paste0(" - ⚠️ Not AV Ready: ", inf$issue %||% "Unknown issue")
                         } else {
                           " - ✓ AV Ready"
                         })
                )
              })
            )
          )
        }
      )
    })
    
    # Quest 3 status panel
    output$quest3Status <- renderUI({
      if (is.null(selected_scenario())) {
        return(NULL)
      }
      
      div(
        style = "background: rgba(0, 163, 154, 0.1); padding: 10px; border-radius: 8px; margin-top: 10px;",
        h5(icon("vr-cardboard"), " Quest 3 AR Preview"),
        tags$p(class = "text-muted", style = "font-size: 12px;",
               "This scenario will display on Quest 3 floor with:"
        ),
        tags$ul(style = "font-size: 12px; margin-left: -20px;",
                tags$li(paste0(length(selected_scenario()$trajectories %||% list()), 
                               " trajectory segments (color-coded by quality)")),
                tags$li(paste0(length(selected_scenario()$incidents %||% list()), 
                               " incident markers (red/orange triangles)")),
                tags$li(paste0(length(selected_scenario()$infrastructure %||% list()), 
                               " infrastructure points (blue/orange spheres)"))
        )
      )
    })
    
    # Trajectory plot
    output$trajectoryPlot <- plotly::renderPlotly({
      req(selected_scenario())
      s <- selected_scenario()
      
      if (is.null(s$trajectories) || length(s$trajectories) == 0) {
        return(plotly::plot_ly() %>% 
                 plotly::add_annotations(
                   text = "No trajectory data available",
                   xref = "paper", yref = "paper",
                   x = 0.5, y = 0.5, showarrow = FALSE
                 ))
      }
      
      lats <- sapply(s$trajectories, function(t) t$lat %||% NA)
      lons <- sapply(s$trajectories, function(t) t$lon %||% NA)
      speeds <- sapply(s$trajectories, function(t) t$speed %||% NA)
      
      plotly::plot_ly() %>%
        plotly::add_trace(
          x = lons,
          y = lats,
          type = 'scatter',
          mode = 'lines+markers',
          marker = list(
            size = 8,
            color = speeds,
            colorscale = 'Viridis',
            showscale = TRUE,
            colorbar = list(title = "Speed (km/h)")
          ),
          line = list(color = '#008A82', width = 2),
          text = paste0("Speed: ", speeds, " km/h"),
          hoverinfo = 'text'
        ) %>%
        plotly::layout(
          title = "Vehicle Trajectory",
          xaxis = list(title = "Longitude"),
          yaxis = list(title = "Latitude"),
          hovermode = 'closest'
        )
    })
    
    # Quality score plot
    output$qualityPlot <- plotly::renderPlotly({
      req(selected_scenario())
      s <- selected_scenario()
      
      if (is.null(s$trajectories) || length(s$trajectories) == 0) {
        return(plotly::plot_ly() %>% 
                 plotly::add_annotations(
                   text = "No quality data available",
                   xref = "paper", yref = "paper",
                   x = 0.5, y = 0.5, showarrow = FALSE
                 ))
      }
      
      scores <- sapply(s$trajectories, function(t) t$quality_score %||% 0)
      colors <- ifelse(scores >= 8, '#27ae60',
                       ifelse(scores >= 5, '#f39c12', '#e74c3c'))
      
      plotly::plot_ly() %>%
        plotly::add_trace(
          x = 1:length(scores),
          y = scores,
          type = 'bar',
          marker = list(color = colors),
          text = paste0("Score: ", scores, "/10"),
          hoverinfo = 'text'
        ) %>%
        plotly::layout(
          title = "Quality Score Distribution",
          xaxis = list(title = "Trajectory Point"),
          yaxis = list(title = "Quality Score", range = c(0, 10)),
          shapes = list(
            list(type = "line", y0 = 8, y1 = 8, x0 = 0, x1 = length(scores),
                 line = list(color = "#27ae60", dash = "dash")),
            list(type = "line", y0 = 5, y1 = 5, x0 = 0, x1 = length(scores),
                 line = list(color = "#f39c12", dash = "dash"))
          )
        )
    })
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x