# modules/advanced_viz.R
# Advanced Visualization Module - 3D Plotly & Interactive Charts
# Contains both UI and Server logic in ONE file

# ============================================================================
# UI FUNCTION
# ============================================================================

advanced_viz_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Advanced Visualization Dashboard", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        h3(icon("chart-line"), " 3D Analytics & Interactive Visualizations")
      )
    ),
    
    # 3D Route Trajectory
    fluidRow(
      box(
        title = "3D Route Trajectory", 
        status = "info", 
        solidHeader = TRUE, 
        width = 12,
        collapsible = TRUE,
        
        p("Interactive 3D visualization of vehicle trajectory with elevation, speed, and quality indicators."),
        
        plotly::plotlyOutput(ns("trajectory3D"), height = 500)
      )
    ),
    
    # Physics Time Series
    fluidRow(
      box(
        title = "Vehicle Dynamics Over Time", 
        status = "warning", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        selectInput(ns("physicsMetric"), "Select Metric:",
                    choices = c("Speed (km/h)" = "speed",
                                "Acceleration (m/s²)" = "acceleration",
                                "Brake Force (N)" = "brake_force",
                                "Steering Angle (°)" = "steering_angle")),
        
        plotly::plotlyOutput(ns("physicsTimeSeries"), height = 400)
      ),
      
      box(
        title = "Energy Consumption", 
        status = "success", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        plotly::plotlyOutput(ns("energyChart"), height = 400)
      )
    ),
    
    # Sensor Heatmaps
    fluidRow(
      box(
        title = "LiDAR Point Cloud Density", 
        status = "danger", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        plotly::plotlyOutput(ns("lidarHeatmap"), height = 400)
      ),
      
      box(
        title = "Incident Severity Map", 
        status = "warning", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        plotly::plotlyOutput(ns("incidentMap"), height = 400)
      )
    ),
    
    # Comparative Analysis
    fluidRow(
      box(
        title = "Multi-Scenario Comparison", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        collapsible = TRUE,
        
        p("Compare quality scores, incidents, and performance across multiple scenarios."),
        
        plotly::plotlyOutput(ns("scenarioComparison"), height = 400)
      )
    ),
    
    # Vehicle Physics Distribution
    fluidRow(
      box(
        title = "Suspension Load Distribution", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        plotly::plotlyOutput(ns("suspensionChart"), height = 350)
      ),
      
      box(
        title = "Tire Friction Utilization", 
        status = "success", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        plotly::plotlyOutput(ns("frictionChart"), height = 350)
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

advanced_viz_server <- function(id, api_manager = NULL) {
  moduleServer(id, function(input, output, session) {
    
    # Get data
    get_scenarios <- reactive({
      if (!is.null(api_manager) && !is.null(api_manager$omniverse_scenarios)) {
        return(api_manager$omniverse_scenarios)
      }
      return(NULL)
    })
    
    get_vehicle_config <- reactive({
      if (!is.null(api_manager) && !is.null(api_manager$vehicle_config)) {
        return(api_manager$vehicle_config)
      }
      return(NULL)
    })
    
    # 3D Route Trajectory
    output$trajectory3D <- plotly::renderPlotly({
      scenarios <- get_scenarios()
      
      if (is.null(scenarios) || length(scenarios) == 0) {
        # Empty plot with message
        plotly::plot_ly() %>%
          plotly::add_text(x = 0, y = 0, z = 0, 
                          text = "Generate scenarios in Tab 5 to see 3D trajectory",
                          textfont = list(size = 16, color = "#999")) %>%
          plotly::layout(
            scene = list(
              xaxis = list(title = "Longitude"),
              yaxis = list(title = "Latitude"),
              zaxis = list(title = "Elevation (m)")
            )
          )
      } else {
        # Generate sample trajectory data
        scenario <- scenarios[[1]]
        n_points <- 100
        
        # Simulate trajectory (replace with real data when available)
        t <- seq(0, 1, length.out = n_points)
        lon <- -0.1276 + t * 0.5
        lat <- 51.5074 + t * 0.3
        elevation <- 50 + 30 * sin(t * 2 * pi)
        speed <- 60 + 20 * sin(t * 4 * pi)
        quality <- 7 + 2 * cos(t * 3 * pi)
        
        plotly::plot_ly() %>%
          plotly::add_trace(
            type = "scatter3d",
            mode = "lines+markers",
            x = lon,
            y = lat,
            z = elevation,
            line = list(width = 4, color = speed, colorscale = "Viridis"),
            marker = list(size = 3, color = quality, colorscale = "RdYlGn",
                         colorbar = list(title = "Quality")),
            text = paste0("Point ", 1:n_points, "<br>",
                         "Speed: ", round(speed, 1), " km/h<br>",
                         "Quality: ", round(quality, 1), "/10"),
            hoverinfo = "text",
            name = scenario$route %||% "Route"
          ) %>%
          plotly::layout(
            title = paste0("3D Trajectory: ", scenario$route %||% "Route"),
            scene = list(
              xaxis = list(title = "Longitude"),
              yaxis = list(title = "Latitude"),
              zaxis = list(title = "Elevation (m)"),
              camera = list(
                eye = list(x = 1.5, y = 1.5, z = 1.2)
              )
            )
          )
      }
    })
    
    # Physics Time Series
    output$physicsTimeSeries <- plotly::renderPlotly({
      scenarios <- get_scenarios()
      
      if (is.null(scenarios) || length(scenarios) == 0) {
        plotly::plot_ly() %>%
          plotly::add_text(x = 50, y = 50, 
                          text = "No scenario data available",
                          textfont = list(size = 14)) %>%
          plotly::layout(xaxis = list(title = "Time (s)"),
                        yaxis = list(title = input$physicsMetric))
      } else {
        # Generate sample physics data
        time <- seq(0, 100, length.out = 200)
        
        value <- switch(input$physicsMetric,
          "speed" = 60 + 20 * sin(time / 10) + rnorm(200, 0, 2),
          "acceleration" = 0.5 * sin(time / 5) + rnorm(200, 0, 0.2),
          "brake_force" = abs(1000 * sin(time / 8)) + rnorm(200, 0, 50),
          "steering_angle" = 15 * sin(time / 12) + rnorm(200, 0, 1),
          60 + 20 * sin(time / 10)
        )
        
        metric_labels <- c(
          "speed" = "Speed (km/h)",
          "acceleration" = "Acceleration (m/s²)",
          "brake_force" = "Brake Force (N)",
          "steering_angle" = "Steering Angle (°)"
        )
        
        plotly::plot_ly() %>%
          plotly::add_trace(
            type = "scatter",
            mode = "lines",
            x = time,
            y = value,
            line = list(color = "#3498db", width = 2),
            name = metric_labels[[input$physicsMetric]]
          ) %>%
          plotly::layout(
            title = paste("Vehicle", metric_labels[[input$physicsMetric]], "Over Time"),
            xaxis = list(title = "Time (s)"),
            yaxis = list(title = metric_labels[[input$physicsMetric]]),
            hovermode = "x unified"
          )
      }
    })
    
    # Energy Consumption Chart
    output$energyChart <- plotly::renderPlotly({
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        plotly::plot_ly() %>%
          plotly::add_text(x = 50, y = 50, text = "No vehicle data",
                          textfont = list(size = 14))
      } else {
        # Sample energy data
        time <- seq(0, 60, length.out = 100)
        battery_capacity <- vehicle$battery$capacity_kwh
        
        energy_remaining <- battery_capacity * (1 - time/120 - 0.1*sin(time/10))
        energy_used <- battery_capacity - energy_remaining
        
        plotly::plot_ly() %>%
          plotly::add_trace(
            type = "scatter",
            mode = "lines",
            x = time,
            y = energy_remaining,
            name = "Battery Remaining",
            line = list(color = "#27ae60", width = 3),
            fill = "tozeroy",
            fillcolor = "rgba(39, 174, 96, 0.2)"
          ) %>%
          plotly::add_trace(
            type = "scatter",
            mode = "lines",
            x = time,
            y = energy_used,
            name = "Energy Consumed",
            line = list(color = "#e74c3c", width = 2, dash = "dash"),
            yaxis = "y2"
          ) %>%
          plotly::layout(
            title = paste0("Energy Profile: ", vehicle$name),
            xaxis = list(title = "Time (min)"),
            yaxis = list(title = "Battery Remaining (kWh)", side = "left"),
            yaxis2 = list(title = "Energy Consumed (kWh)", 
                         overlaying = "y", side = "right"),
            hovermode = "x unified"
          )
      }
    })
    
    # LiDAR Heatmap
    output$lidarHeatmap <- plotly::renderPlotly({
      scenarios <- get_scenarios()
      
      if (is.null(scenarios) || length(scenarios) == 0) {
        plotly::plot_ly() %>%
          plotly::add_text(x = 0, y = 0, text = "No LiDAR data",
                          textfont = list(size = 14))
      } else {
        # Generate sample LiDAR density heatmap
        x <- seq(-10, 10, length.out = 50)
        y <- seq(-10, 10, length.out = 50)
        
        z <- outer(x, y, function(x, y) {
          1000 * exp(-((x^2 + y^2) / 50)) + rnorm(1, 0, 50)
        })
        
        plotly::plot_ly(x = x, y = y, z = z, type = "heatmap",
                       colorscale = "Hot") %>%
          plotly::layout(
            title = "LiDAR Point Cloud Density",
            xaxis = list(title = "X Position (m)"),
            yaxis = list(title = "Y Position (m)")
          )
      }
    })
    
    # Incident Severity Map
    output$incidentMap <- plotly::renderPlotly({
      scenarios <- get_scenarios()
      
      if (is.null(scenarios) || length(scenarios) == 0) {
        plotly::plot_ly() %>%
          plotly::add_text(x = 0, y = 0, text = "No incident data",
                          textfont = list(size = 14))
      } else {
        # Generate sample incident data
        n_incidents <- 15
        incident_x <- runif(n_incidents, -1, 1)
        incident_y <- runif(n_incidents, -1, 1)
        severity <- sample(c("LOW", "MEDIUM", "HIGH"), n_incidents, replace = TRUE)
        
        severity_colors <- c("LOW" = "#27ae60", "MEDIUM" = "#f39c12", "HIGH" = "#e74c3c")
        severity_sizes <- c("LOW" = 10, "MEDIUM" = 15, "HIGH" = 25)
        
        plotly::plot_ly() %>%
          plotly::add_trace(
            type = "scatter",
            mode = "markers",
            x = incident_x,
            y = incident_y,
            marker = list(
              size = severity_sizes[severity],
              color = severity_colors[severity],
              line = list(width = 2, color = "white")
            ),
            text = paste0("Incident ", 1:n_incidents, "<br>",
                         "Severity: ", severity),
            hoverinfo = "text",
            showlegend = FALSE
          ) %>%
          plotly::layout(
            title = "Incident Locations by Severity",
            xaxis = list(title = "Relative Position X", zeroline = TRUE),
            yaxis = list(title = "Relative Position Y", zeroline = TRUE)
          )
      }
    })
    
    # Multi-Scenario Comparison
    output$scenarioComparison <- plotly::renderPlotly({
      scenarios <- get_scenarios()
      
      if (is.null(scenarios) || length(scenarios) == 0) {
        plotly::plot_ly() %>%
          plotly::add_text(x = 1, y = 5, text = "Generate multiple scenarios to compare",
                          textfont = list(size = 14))
      } else {
        # Build comparison data
        scenario_names <- paste0("Scenario ", 1:length(scenarios))
        quality_scores <- sapply(scenarios, function(s) s$quality_score %||% 5)
        incident_counts <- sapply(scenarios, function(s) length(s$incidents %||% list()))
        trajectory_counts <- sapply(scenarios, function(s) length(s$trajectories %||% list()))
        
        plotly::plot_ly() %>%
          plotly::add_trace(
            type = "bar",
            x = scenario_names,
            y = quality_scores,
            name = "Quality Score",
            marker = list(color = "#3498db")
          ) %>%
          plotly::add_trace(
            type = "bar",
            x = scenario_names,
            y = incident_counts,
            name = "Incidents",
            marker = list(color = "#e74c3c"),
            yaxis = "y2"
          ) %>%
          plotly::layout(
            title = "Scenario Quality & Incident Comparison",
            xaxis = list(title = "Scenario"),
            yaxis = list(title = "Quality Score (0-10)", side = "left"),
            yaxis2 = list(title = "Incident Count", 
                         overlaying = "y", side = "right"),
            barmode = "group",
            hovermode = "x unified"
          )
      }
    })
    
    # Suspension Load Distribution
    output$suspensionChart <- plotly::renderPlotly({
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        plotly::plot_ly() %>%
          plotly::add_text(x = 2, y = 5000, text = "No vehicle data",
                          textfont = list(size = 14))
      } else {
        # Suspension load data
        wheels <- c("Front Left", "Front Right", "Rear Left", "Rear Right")
        loads <- c(
          vehicle$mass_properties$front_axle_weight_kg / 2,
          vehicle$mass_properties$front_axle_weight_kg / 2,
          vehicle$mass_properties$rear_axle_weight_kg / 2,
          vehicle$mass_properties$rear_axle_weight_kg / 2
        )
        
        plotly::plot_ly() %>%
          plotly::add_trace(
            type = "bar",
            x = wheels,
            y = loads,
            marker = list(
              color = c("#3498db", "#3498db", "#e67e22", "#e67e22"),
              line = list(width = 2, color = "white")
            ),
            text = paste0(round(loads, 0), " kg"),
            textposition = "outside"
          ) %>%
          plotly::layout(
            title = "Static Wheel Load Distribution",
            xaxis = list(title = "Wheel Position"),
            yaxis = list(title = "Load (kg)"),
            showlegend = FALSE
          )
      }
    })
    
    # Tire Friction Utilization
    output$frictionChart <- plotly::renderPlotly({
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        plotly::plot_ly() %>%
          plotly::add_text(x = 50, y = 0.5, text = "No vehicle data",
                          textfont = list(size = 14))
      } else {
        # Friction coefficient data
        time <- seq(0, 100, length.out = 200)
        
        friction_dry <- vehicle$tire_friction$dynamic_friction_dry
        friction_wet <- vehicle$tire_friction$dynamic_friction_wet
        
        # Simulate varying friction utilization
        utilization_dry <- friction_dry * (0.6 + 0.3 * abs(sin(time / 20)))
        utilization_wet <- friction_wet * (0.5 + 0.4 * abs(sin(time / 15)))
        
        plotly::plot_ly() %>%
          plotly::add_trace(
            type = "scatter",
            mode = "lines",
            x = time,
            y = utilization_dry,
            name = "Dry Surface",
            line = list(color = "#27ae60", width = 3),
            fill = "tozeroy",
            fillcolor = "rgba(39, 174, 96, 0.2)"
          ) %>%
          plotly::add_trace(
            type = "scatter",
            mode = "lines",
            x = time,
            y = utilization_wet,
            name = "Wet Surface",
            line = list(color = "#3498db", width = 3, dash = "dash")
          ) %>%
          plotly::add_trace(
            type = "scatter",
            mode = "lines",
            x = c(0, 100),
            y = c(friction_dry, friction_dry),
            name = "Dry Limit",
            line = list(color = "#e74c3c", width = 2, dash = "dot"),
            showlegend = TRUE
          ) %>%
          plotly::layout(
            title = "Tire Friction Coefficient Utilization",
            xaxis = list(title = "Time (s)"),
            yaxis = list(title = "Friction Coefficient (μ)"),
            hovermode = "x unified"
          )
      }
    })
    
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x
