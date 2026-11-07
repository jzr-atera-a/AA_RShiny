# modules/metrics_statistics.R
# Tab 9: Comprehensive Metrics & Statistics
# Displays all vehicle physics, sensor data, and scenario comparisons

# ============================================================================
# UI FUNCTION
# ============================================================================

metrics_statistics_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Metrics Dashboard", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        h3(icon("chart-bar"), " Comprehensive Scenario Metrics & Statistics")
      )
    ),
    
    # Vehicle Configuration Metrics
    fluidRow(
      box(
        title = "Vehicle Configuration", 
        status = "warning", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        uiOutput(ns("vehicleMetrics"))
      ),
      
      box(
        title = "Sensor Configuration", 
        status = "success", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        uiOutput(ns("sensorMetrics"))
      )
    ),
    
    # Physics Metrics
    fluidRow(
      box(
        title = "Mass & Inertia Properties", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        uiOutput(ns("massInertiaMetrics"))
      ),
      
      box(
        title = "Dynamics & Performance", 
        status = "danger", 
        solidHeader = TRUE, 
        width = 6,
        collapsible = TRUE,
        
        uiOutput(ns("dynamicsMetrics"))
      )
    ),
    
    # Component Metrics
    fluidRow(
      box(
        title = "Wheel & Tire Metrics", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        collapsible = TRUE,
        
        uiOutput(ns("wheelMetrics"))
      ),
      
      box(
        title = "Suspension & Braking", 
        status = "warning", 
        solidHeader = TRUE, 
        width = 4,
        collapsible = TRUE,
        
        uiOutput(ns("suspensionBrakingMetrics"))
      ),
      
      box(
        title = "Powertrain & Aerodynamics", 
        status = "success", 
        solidHeader = TRUE, 
        width = 4,
        collapsible = TRUE,
        
        uiOutput(ns("powertrainAeroMetrics"))
      )
    ),
    
    # Scenario Statistics
    fluidRow(
      box(
        title = "Scenario Statistics", 
        status = "info", 
        solidHeader = TRUE, 
        width = 12,
        collapsible = TRUE,
        
        uiOutput(ns("scenarioStats"))
      )
    ),
    
    # Scenario Comparison Table
    fluidRow(
      box(
        title = "Scenario Comparison", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        collapsible = TRUE,
        
        DT::dataTableOutput(ns("scenarioComparison"))
      )
    ),
    
    # Braking Distance Calculator
    fluidRow(
      box(
        title = "Braking Distance Calculator", 
        status = "danger", 
        solidHeader = TRUE, 
        width = 12,
        collapsible = TRUE,
        
        fluidRow(
          column(4,
                 numericInput(ns("braking_speed_kmh"), "Speed (km/h):", 
                              value = 100, min = 0, max = 200)),
          column(4,
                 selectInput(ns("braking_surface"), "Road Surface:",
                             choices = c("Dry Asphalt" = "dry",
                                         "Wet Asphalt" = "wet"))),
          column(4,
                 actionButton(ns("calculateBraking"), "Calculate", 
                              class = "btn-danger", 
                              style = "margin-top: 25px;"))
        ),
        
        hr(),
        
        uiOutput(ns("brakingResults"))
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

metrics_statistics_server <- function(id, api_manager = NULL) {
  moduleServer(id, function(input, output, session) {
    
    # Get data from api_manager
    get_vehicle_config <- reactive({
      if (!is.null(api_manager) && !is.null(api_manager$vehicle_config)) {
        return(api_manager$vehicle_config)
      }
      return(NULL)
    })
    
    get_scenarios <- reactive({
      if (!is.null(api_manager) && !is.null(api_manager$omniverse_scenarios)) {
        return(api_manager$omniverse_scenarios)
      }
      return(NULL)
    })
    
    get_sensor_config <- reactive({
      if (!is.null(api_manager) && !is.null(api_manager$sensor_config)) {
        return(api_manager$sensor_config)
      }
      return(NULL)
    })
    
    get_physics_config <- reactive({
      if (!is.null(api_manager) && !is.null(api_manager$physics_config)) {
        return(api_manager$physics_config)
      }
      return(NULL)
    })
    
    # Vehicle Metrics
    output$vehicleMetrics <- renderUI({
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        return(tags$p("No vehicle data loaded. Generate scenarios first."))
      }
      
      tags$div(
        tags$h4(vehicle$name),
        tags$p(tags$b("Category:"), vehicle$category),
        tags$p(tags$b("Manufacturer:"), vehicle$manufacturer),
        tags$hr(),
        tags$h5("Dimensions (m):"),
        tags$ul(
          tags$li(sprintf("Length: %.3f", vehicle$dimensions$length)),
          tags$li(sprintf("Width: %.3f", vehicle$dimensions$width)),
          tags$li(sprintf("Height: %.3f", vehicle$dimensions$height)),
          tags$li(sprintf("Wheelbase: %.3f", vehicle$dimensions$wheelbase)),
          tags$li(sprintf("Ground Clearance: %.3f", vehicle$dimensions$ground_clearance))
        )
      )
    })
    
    # Sensor Metrics
    output$sensorMetrics <- renderUI({
      sensor_cfg <- get_sensor_config()
      
      if (is.null(sensor_cfg)) {
        return(tags$p("No sensor configuration loaded."))
      }
      
      tags$div(
        tags$h5("Enabled Sensors:"),
        tags$ul(
          if (length(sensor_cfg$camera) > 0) {
            tags$li(tags$b("Camera:"), paste(sensor_cfg$camera, collapse = ", "))
          },
          if (sensor_cfg$lidar) tags$li(tags$b("LiDAR:"), "Enabled"),
          if (sensor_cfg$radar) tags$li(tags$b("Radar:"), "Enabled"),
          if (sensor_cfg$imu) tags$li(tags$b("IMU:"), "Enabled"),
          if (sensor_cfg$contact) tags$li(tags$b("Contact:"), "Enabled")
        )
      )
    })
    
    # Mass & Inertia Metrics
    output$massInertiaMetrics <- renderUI({
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        return(tags$p("No data available."))
      }
      
      mass <- vehicle$mass_properties
      inertia <- vehicle$inertia_tensor
      
      tags$div(
        tags$h5("Mass Properties:"),
        tags$ul(
          tags$li(sprintf("Curb Weight: %,d kg", mass$curb_weight_kg)),
          tags$li(sprintf("GVW/GCW: %,d kg", 
                          if(!is.null(mass$gcw_kg)) mass$gcw_kg else mass$gvw_kg)),
          tags$li(sprintf("Payload: %,d kg", mass$payload_kg)),
          tags$li(sprintf("Front Axle: %,d kg", mass$front_axle_weight_kg)),
          tags$li(sprintf("Rear Axle: %,d kg", mass$rear_axle_weight_kg)),
          tags$li(sprintf("CoG Height: %.3f m", mass$center_of_mass_height_m))
        ),
        tags$hr(),
        tags$h5("Inertia Tensor (kg·m²):"),
        tags$ul(
          tags$li(sprintf("Ixx (Roll): %,d", round(inertia$Ixx))),
          tags$li(sprintf("Iyy (Pitch): %,d", round(inertia$Iyy))),
          tags$li(sprintf("Izz (Yaw): %,d", round(inertia$Izz)))
        )
      )
    })
    
    # Dynamics Metrics
    output$dynamicsMetrics <- renderUI({
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        return(tags$p("No data available."))
      }
      
      perf <- vehicle$performance
      battery <- vehicle$battery
      
      tags$div(
        tags$h5("Performance:"),
        tags$ul(
          tags$li(sprintf("Max Speed: %d km/h", perf$max_speed_kmh)),
          tags$li(sprintf("Range: %d km", perf$range_km)),
          if (!is.null(perf$acceleration_0_100_kmh_s)) {
            tags$li(sprintf("0-100 km/h: %.1f s", perf$acceleration_0_100_kmh_s))
          }
        ),
        tags$hr(),
        tags$h5("Battery:"),
        tags$ul(
          tags$li(sprintf("Capacity: %.1f kWh", battery$capacity_kwh)),
          tags$li(sprintf("Voltage: %d V", battery$voltage_v)),
          tags$li(sprintf("Weight: %d kg", battery$weight_kg))
        )
      )
    })
    
    # Wheel Metrics
    output$wheelMetrics <- renderUI({
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        return(tags$p("No data available."))
      }
      
      wheels <- vehicle$wheels
      friction <- vehicle$tire_friction
      
      tags$div(
        tags$h5("Wheel Configuration:"),
        tags$ul(
          tags$li(sprintf("Number: %d wheels", wheels$num_wheels)),
          tags$li(sprintf("Radius: %.3f m", wheels$wheel_radius_m)),
          tags$li(sprintf("Width: %.3f m", wheels$wheel_width_m)),
          tags$li(sprintf("Mass: %d kg each", wheels$wheel_mass_kg)),
          tags$li(sprintf("Inertia: %.2f kg·m²", wheels$wheel_inertia_kgm2))
        ),
        tags$hr(),
        tags$h5("Tire Friction:"),
        tags$ul(
          tags$li(sprintf("Dry μs: %.2f", friction$static_friction_dry)),
          tags$li(sprintf("Dry μk: %.2f", friction$dynamic_friction_dry)),
          tags$li(sprintf("Wet μs: %.2f", friction$static_friction_wet)),
          tags$li(sprintf("Wet μk: %.2f", friction$dynamic_friction_wet))
        )
      )
    })
    
    # Suspension & Braking Metrics
    output$suspensionBrakingMetrics <- renderUI({
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        return(tags$p("No data available."))
      }
      
      susp <- vehicle$suspension
      brake <- vehicle$braking
      
      tags$div(
        tags$h5("Suspension:"),
        tags$ul(
          tags$li(sprintf("Front Spring: %,d N/m", susp$front_spring_rate_nm)),
          tags$li(sprintf("Front Damping: %,d N·s/m", susp$front_damping_rate_nsm)),
          tags$li(sprintf("Rear Spring: %,d N/m", susp$rear_spring_rate_nm)),
          tags$li(sprintf("Rear Damping: %,d N·s/m", susp$rear_damping_rate_nsm))
        ),
        tags$hr(),
        tags$h5("Braking:"),
        tags$ul(
          tags$li(sprintf("Front: %,d Nm", brake$max_brake_torque_front_nm)),
          tags$li(sprintf("Rear: %,d Nm", brake$max_brake_torque_rear_nm)),
          tags$li(sprintf("Distribution: %s", brake$brake_distribution)),
          if (brake$abs_enabled) tags$li("ABS: Enabled")
        )
      )
    })
    
    # Powertrain & Aero Metrics
    output$powertrainAeroMetrics <- renderUI({
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        return(tags$p("No data available."))
      }
      
      power <- vehicle$powertrain
      aero <- vehicle$aerodynamics
      
      tags$div(
        tags$h5("Powertrain:"),
        tags$ul(
          tags$li(sprintf("Type: %s", power$motor_type)),
          tags$li(sprintf("Power: %d kW", power$motor_power_kw)),
          tags$li(sprintf("Torque: %,d Nm", power$motor_torque_nm)),
          tags$li(sprintf("Drive: %s", power$drive_type))
        ),
        tags$hr(),
        tags$h5("Aerodynamics:"),
        tags$ul(
          tags$li(sprintf("Cd: %.2f", aero$drag_coefficient)),
          tags$li(sprintf("Frontal Area: %.2f m²", aero$frontal_area_m2))
        )
      )
    })
    
    # Scenario Statistics
    output$scenarioStats <- renderUI({
      scenarios <- get_scenarios()
      
      if (is.null(scenarios) || length(scenarios) == 0) {
        return(tags$p("No scenarios loaded. Generate scenarios first."))
      }
      
      total_scenarios <- length(scenarios)
      
      # Calculate statistics
      quality_scores <- sapply(scenarios, function(s) {
        if (!is.null(s$quality_score)) as.numeric(s$quality_score) else 0
      })
      
      total_trajectories <- sum(sapply(scenarios, function(s) {
        if (!is.null(s$trajectories) && is.list(s$trajectories)) {
          length(s$trajectories)
        } else {
          0
        }
      }))
      
      total_incidents <- sum(sapply(scenarios, function(s) {
        if (!is.null(s$incidents) && is.list(s$incidents)) {
          length(s$incidents)
        } else {
          0
        }
      }))
      
      tags$div(
        fluidRow(
          column(3,
                 tags$div(
                   style = "background: #d1ecf1; padding: 15px; border-radius: 5px; text-align: center;",
                   tags$h3(total_scenarios),
                   tags$p("Total Scenarios")
                 )
          ),
          column(3,
                 tags$div(
                   style = "background: #d4edda; padding: 15px; border-radius: 5px; text-align: center;",
                   tags$h3(total_trajectories),
                   tags$p("Total Trajectory Points")
                 )
          ),
          column(3,
                 tags$div(
                   style = "background: #fff3cd; padding: 15px; border-radius: 5px; text-align: center;",
                   tags$h3(total_incidents),
                   tags$p("Total Incidents")
                 )
          ),
          column(3,
                 tags$div(
                   style = "background: #cce5ff; padding: 15px; border-radius: 5px; text-align: center;",
                   tags$h3(sprintf("%.1f", mean(quality_scores, na.rm = TRUE))),
                   tags$p("Avg Quality Score")
                 )
          )
        )
      )
    })
    
    # Scenario Comparison Table
    output$scenarioComparison <- DT::renderDataTable({
      scenarios <- get_scenarios()
      
      if (is.null(scenarios) || length(scenarios) == 0) {
        return(NULL)
      }
      
      # Build comparison data frame
      comparison_df <- data.frame(
        Scenario = paste0("Scenario ", 1:length(scenarios)),
        Route = sapply(scenarios, function(s) s$route %||% "N/A"),
        Weather = sapply(scenarios, function(s) s$weather %||% "N/A"),
        Quality = sapply(scenarios, function(s) s$quality_score %||% 0),
        Trajectories = sapply(scenarios, function(s) {
          if (!is.null(s$trajectories) && is.list(s$trajectories)) {
            length(s$trajectories)
          } else {
            0
          }
        }),
        Incidents = sapply(scenarios, function(s) {
          if (!is.null(s$incidents) && is.list(s$incidents)) {
            length(s$incidents)
          } else {
            0
          }
        }),
        Readiness = sapply(scenarios, function(s) s$av_readiness %||% "UNKNOWN"),
        stringsAsFactors = FALSE
      )
      
      DT::datatable(
        comparison_df,
        options = list(
          pageLength = 10,
          scrollX = TRUE
        ),
        rownames = FALSE
      )
    })
    
    # Braking Distance Calculator
    observeEvent(input$calculateBraking, {
      vehicle <- get_vehicle_config()
      
      if (is.null(vehicle)) {
        showNotification("No vehicle data loaded!", type = "error")
        return()
      }
      
      speed_kmh <- input$braking_speed_kmh
      speed_ms <- speed_kmh / 3.6
      
      friction <- vehicle$tire_friction
      mu <- if (input$braking_surface == "dry") {
        friction$dynamic_friction_dry
      } else {
        friction$dynamic_friction_wet
      }
      
      g <- 9.81  # m/s²
      
      # Calculate braking distance
      deceleration <- mu * g
      braking_distance <- (speed_ms^2) / (2 * deceleration)
      stopping_time <- speed_ms / deceleration
      
      output$brakingResults <- renderUI({
        tags$div(
          style = "background: #f8f9fa; padding: 20px; border-radius: 5px;",
          tags$h4("Braking Calculation Results:"),
          tags$hr(),
          tags$p(tags$b("Input Conditions:")),
          tags$ul(
            tags$li(sprintf("Speed: %d km/h (%.2f m/s)", speed_kmh, speed_ms)),
            tags$li(sprintf("Surface: %s", 
                            if(input$braking_surface == "dry") "Dry Asphalt" else "Wet Asphalt")),
            tags$li(sprintf("Friction Coefficient (μ): %.2f", mu)),
            tags$li(sprintf("Vehicle: %s", vehicle$name))
          ),
          tags$hr(),
          tags$p(tags$b("Results:")),
          tags$ul(
            tags$li(tags$span(style = "color: #dc3545; font-size: 18px; font-weight: bold;",
                              sprintf("Braking Distance: %.1f meters", braking_distance))),
            tags$li(sprintf("Deceleration: %.2f m/s²", deceleration)),
            tags$li(sprintf("Stopping Time: %.2f seconds", stopping_time))
          )
        )
      })
    })
    
  })
}

# Helper function
`%||%` <- function(x, y) if (is.null(x)) y else x
