# CAV Road Readiness Assessment Dashboard
# Based on Route10 AI Research Documents

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(leaflet)
library(dplyr)
library(ggplot2)
library(shinycssloaders)

# Sample data based on the research documents
vehicle_capabilities <- data.frame(
  Vehicle = c("Waymo Driver", "NVIDIA DRIVE Thor", "Mobileye Chauffeur", "Wayve", "Oxa"),
  Primary_Sensors = c("LiDAR + 29 Cameras + Radar", "Up to 18 Cameras + LiDAR/Radar", 
                      "11 Cameras + LiDAR + Radar", "Camera-based + Others", "Multi-sensor Suite"),
  Mapping_Dependency = c("High-Res 3D Pre-built", "Platform Agnostic", "Crowdsourced REM", 
                         "Map-lite/End-to-End AI", "Flexible HD Maps"),
  Weather_ODD = c("All rain/fog, No snow/ice", "Developer Dependent", "Specified ODDs", 
                  "Complex weather learning", "Details not public"),
  AI_Paradigm = c("Modular: Perception/Prediction/Planning", "Centralized AI Platform", 
                  "Modular with RSS Safety", "End-to-End Deep Learning", "Modular Software Stack"),
  V2X_Capability = c("Planned", "Supported", "Supported", "Planned", "Supported"),
  stringsAsFactors = FALSE
)

# Infrastructure feature matrix data
infrastructure_features <- data.frame(
  Feature_ID = c("INF-01", "INF-02", "INF-03", "INF-04", "INF-05", "INF-06", "INF-07", 
                 "INF-08", "INF-09", "INF-10", "INF-11", "INF-12", "INF-13", "INF-14"),
  Category = c("Road Markings", "Road Markings", "Road Markings", "Road Geometry", 
               "Road Geometry", "Road Geometry", "Road Geometry", "Signage", "Signage", 
               "Surface Quality", "Roadside", "Roadside", "Roadside", "Traffic"),
  Feature = c("Lane Line Type", "Lane Line Quality", "Crosswalk Presence", "Lane Width", 
              "Road Curvature", "Road Gradient", "Intersection Type", "Stop/Yield Signs", 
              "Speed Limit Signs", "Pothole/Crack Density", "Curb Presence", "Safe Run-off Area", 
              "Tree Canopy Occlusion", "Assertiveness Index"),
  Impact_Area = c("Lane Keeping", "Perception", "Pedestrian Prediction", "Path Planning", 
                  "Control", "Powertrain", "Decision Making", "Control", "Legal Compliance", 
                  "Perception", "Localization", "Emergency Maneuver", "GPS Signal", "Social Compliance"),
  stringsAsFactors = FALSE
)

# Performance impact data from Table 3
performance_impact <- data.frame(
  Factor = c("50% Faded Markings", "75% Faded Markings", "Heavy Rain", "Dense Fog", 
             "Sharp Curvature", "Unsignalized Intersections"),
  System_Affected = c("Camera LDW/LKA", "Camera LDW/LKA", "LiDAR", "LiDAR & Camera", 
                      "Lane Keeping", "Full ADS"),
  Performance_Impact = c(">95% Accuracy", "54% Accuracy", "50% Range Reduction", 
                         "Simultaneous Compromise", "Significant Deviation", "Highly Intractable"),
  Severity = c("Low", "Critical", "High", "Critical", "High", "Critical"),
  Evidence_Strength = c("Quantitative", "Quantitative", "Quantitative", "Qualitative", 
                        "Quantitative", "Qualitative"),
  stringsAsFactors = FALSE
)

# Dover to Milton Keynes route simulation data
set.seed(123)
route_segments <- data.frame(
  Segment_ID = 1:50,
  Latitude = seq(51.1279, 52.0406, length.out = 50),
  Longitude = seq(1.3134, -0.7594, length.out = 50),
  Distance_km = cumsum(c(0, runif(49, 3, 8))),
  Lane_Contrast = runif(50, 0.2, 0.9),
  Road_Curvature = runif(50, 0.001, 0.02),
  Weather_Risk = sample(c("Low", "Moderate", "High"), 50, replace = TRUE, prob = c(0.6, 0.3, 0.1)),
  Infrastructure_Score = runif(50, 40, 95),
  Overall_Risk = sample(c("Compliant", "Moderate", "Critical"), 50, replace = TRUE, prob = c(0.5, 0.3, 0.2)),
  stringsAsFactors = FALSE
)

# Risk assessment summary
risk_summary <- data.frame(
  Risk_Category = c("Lane Markings", "Weather Conditions", "Road Geometry", "Signage", 
                    "Surface Quality", "Dynamic Scenarios"),
  Critical_Count = c(8, 3, 2, 5, 4, 6),
  Moderate_Count = c(12, 8, 6, 10, 8, 9),
  Compliant_Count = c(30, 39, 42, 35, 38, 35),
  Total_Segments = c(50, 50, 50, 50, 50, 50),
  stringsAsFactors = FALSE
)

# UI Definition
ui <- dashboardPage(
  
  # Dashboard Header
  dashboardHeader(
    title = "CAV Road Readiness Assessment",
    titleWidth = 350
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      menuItem("Executive Overview", tabName = "overview", icon = icon("tachometer-alt")),
      menuItem("Vehicle Capabilities", tabName = "vehicles", icon = icon("car")),
      menuItem("Infrastructure Analysis", tabName = "infrastructure", icon = icon("road")),
      menuItem("Performance Impact", tabName = "performance", icon = icon("chart-line")),
      menuItem("Route Assessment", tabName = "route", icon = icon("map-marked-alt")),
      menuItem("Risk Dashboard", tabName = "risks", icon = icon("exclamation-triangle"))
    )
  ),
  
  # Dashboard Body
  dashboardBody(
    
    # Custom CSS for dark grey theme
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #2c3e50 !important;
        }
        .main-header .navbar {
          background-color: #34495e !important;
        }
        .main-header .logo {
          background-color: #2c3e50 !important;
        }
        .main-sidebar {
          background-color: #34495e !important;
        }
        .sidebar-menu > li > a {
          color: #ecf0f1 !important;
        }
        .sidebar-menu > li.active > a {
          background-color: #2c3e50 !important;
          border-left: 3px solid #3498db !important;
        }
        .box {
          background-color: #34495e !important;
          border: 1px solid #4a6741 !important;
        }
        .box-header {
          color: #ecf0f1 !important;
        }
        .content {
          background-color: #2c3e50 !important;
        }
        .nav-tabs-custom > .nav-tabs > li.active {
          border-top-color: #3498db !important;
        }
        .small-box {
          border-radius: 5px !important;
        }
        h1, h2, h3, h4, h5, h6, p, label {
          color: #ecf0f1 !important;
        }
      "))
    ),
    
    tabItems(
      
      # Executive Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                valueBoxOutput("total_segments", width = 3),
                valueBoxOutput("critical_risks", width = 3),
                valueBoxOutput("avg_compatibility", width = 3),
                valueBoxOutput("ready_segments", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Key Research Findings", status = "primary", solidHeader = TRUE, width = 6,
                  height = "400px",
                  div(style = "color: #ecf0f1;",
                      h4("Infrastructure Integrity is Paramount"),
                      p("• Lane marking degradation shows non-linear failure: >95% accuracy at 50% fade drops to 54% at 75% fade"),
                      p("• UK's £10 billion road repair backlog poses systematic risk"),
                      br(),
                      h4("Weather Systematically Blinds Sensors"),
                      p("• LiDAR loses up to 50% effective range in heavy rain/snow"),
                      p("• Multiple sensors can fail simultaneously in dense fog"),
                      br(),
                      h4("Complex Scenarios Expose Brittleness"),
                      p("• Unsignalized intersections require social negotiation"),
                      p("• Dense pedestrian environments challenge prediction models")
                  )
                ),
                
                box(
                  title = "UK Deployment Timeline", status = "warning", solidHeader = TRUE, width = 6,
                  height = "400px",
                  div(style = "color: #ecf0f1;",
                      h4("Policy vs Reality Gap"),
                      p("• Commercial pilots: Spring 2026"),
                      p("• Full regulatory framework: 2027"),
                      p("• AV Act 2024: High safety standards mandated"),
                      br(),
                      h4("Infrastructure Challenges"),
                      p("• Aging road network with degraded markings"),
                      p("• Lack of AV-specific maintenance standards"),
                      p("• Need for route-specific compatibility assessments"),
                      br(),
                      tags$div(
                        style = "background-color: #e74c3c; padding: 10px; border-radius: 5px; margin-top: 20px;",
                        h5("Critical Gap: Ambitious timeline vs infrastructure reality", style = "color: white; margin: 0;")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Strategic Recommendations", status = "success", solidHeader = TRUE, width = 12,
                  div(style = "color: #ecf0f1;",
                      h4("Proposed Solution: Granular Route-Specific Assessment"),
                      p("• Move beyond broad ODD definitions to quantitative vehicle-road matching"),
                      p("• Computer vision analysis of Street View imagery as cost-effective alternative to Digital Twins"),
                      p("• Dynamic overlay system incorporating real-time weather, traffic, connectivity"),
                      p("• Enable intelligent routing for AV fleets and infrastructure investment prioritization")
                  )
                )
              )
      ),
      
      # Vehicle Capabilities Tab
      tabItem(tabName = "vehicles",
              fluidRow(
                box(
                  title = "Vehicle Capability Comparison", status = "primary", solidHeader = TRUE, width = 12,
                  withSpinner(DT::dataTableOutput("vehicle_table"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Sensor Suite Analysis", status = "info", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("sensor_plot"))
                ),
                
                box(
                  title = "AI Paradigm Distribution", status = "info", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("ai_paradigm_plot"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Vehicle Selection for Route Analysis", status = "warning", solidHeader = TRUE, width = 12,
                  fluidRow(
                    column(4, selectInput("selected_vehicle", "Select Vehicle:", 
                                          choices = vehicle_capabilities$Vehicle, 
                                          selected = "Waymo Driver")),
                    column(8, 
                           div(style = "color: #ecf0f1; margin-top: 25px;",
                               textOutput("vehicle_description")
                           )
                    )
                  )
                )
              )
      ),
      
      # Infrastructure Analysis Tab
      tabItem(tabName = "infrastructure",
              fluidRow(
                box(
                  title = "Infrastructure Feature Matrix", status = "primary", solidHeader = TRUE, width = 8,
                  withSpinner(DT::dataTableOutput("infrastructure_table"))
                ),
                
                box(
                  title = "Feature Category Distribution", status = "info", solidHeader = TRUE, width = 4,
                  withSpinner(plotlyOutput("feature_category_plot"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Critical Infrastructure Dependencies", status = "warning", solidHeader = TRUE, width = 6,
                  div(style = "color: #ecf0f1;",
                      h4("Lane Markings (Critical)"),
                      p("• Primary navigation aid for camera-based systems"),
                      p("• Non-linear failure: 95% → 54% accuracy (50% → 75% fade)"),
                      br(),
                      h4("Road Geometry"),
                      p("• Sharp curvature challenges LKA systems"),
                      p("• UK roundabouts require human-like navigation"),
                      br(),
                      h4("Signage Detection"),
                      p("• Non-standard placement and occlusion issues"),
                      p("• Temporary construction signs problematic")
                  )
                ),
                
                box(
                  title = "UK Infrastructure Readiness", status = "danger", solidHeader = TRUE, width = 6,
                  div(style = "color: #ecf0f1;",
                      h4("£10 Billion Repair Backlog"),
                      p("• Widespread faded markings"),
                      p("• Pothole and surface degradation"),
                      p("• Inconsistent signage standards"),
                      br(),
                      h4("Channelisation Risk"),
                      p("• AVs follow same path repeatedly"),
                      p("• Accelerates road surface wear"),
                      p("• Creates negative feedback loop"),
                      br(),
                      tags$div(
                        style = "background-color: #e74c3c; padding: 10px; border-radius: 5px;",
                        h5("Many roads likely operate beyond safe AV thresholds", style = "color: white; margin: 0;")
                      )
                  )
                )
              )
      ),
      
      # Performance Impact Tab
      tabItem(tabName = "performance",
              fluidRow(
                box(
                  title = "Performance Impact Analysis", status = "primary", solidHeader = TRUE, width = 8,
                  withSpinner(DT::dataTableOutput("performance_table"))
                ),
                
                box(
                  title = "Sensor Performance vs Weather", status = "info", solidHeader = TRUE, width = 4,
                  withSpinner(plotlyOutput("weather_impact_plot"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Lane Marking Degradation Impact", status = "warning", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("lane_degradation_plot"))
                ),
                
                box(
                  title = "Sensor Vulnerability Matrix", status = "danger", solidHeader = TRUE, width = 6,
                  div(style = "color: #ecf0f1;",
                      h4("Camera Vulnerabilities"),
                      p("• Rain/fog: Reduced visibility and contrast"),
                      p("• Sun glare: Sensor saturation"),
                      p("• Night conditions: Lighting dependent"),
                      br(),
                      h4("LiDAR Vulnerabilities"),
                      p("• Rain/snow: Up to 50% range reduction"),
                      p("• Fog: Backscatter and ghost points"),
                      p("• Particulates: Signal attenuation"),
                      br(),
                      h4("Radar Strengths"),
                      p("• Weather robust: Unaffected by rain/fog"),
                      p("• Limitations: Low resolution, poor pedestrian detection")
                  )
                )
              )
      ),
      
      # Route Assessment Tab
      tabItem(tabName = "route",
              fluidRow(
                box(
                  title = "Dover to Milton Keynes Route Analysis", status = "primary", solidHeader = TRUE, width = 8,
                  withSpinner(leafletOutput("route_map", height = "500px"))
                ),
                
                box(
                  title = "Route Statistics", status = "info", solidHeader = TRUE, width = 4,
                  valueBoxOutput("route_length", width = 12),
                  valueBoxOutput("high_risk_segments", width = 12),
                  valueBoxOutput("weather_alerts", width = 12),
                  br(),
                  div(style = "color: #ecf0f1;",
                      h4("Prototype Achievements"),
                      p("• 3,098 Street View images analyzed"),
                      p("• 21 risk categories defined"),
                      p("• YOLOv8 model trained on UK imagery"),
                      p("• Interactive risk visualization")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Segment Risk Distribution", status = "warning", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("risk_distribution_plot"))
                ),
                
                box(
                  title = "Infrastructure Quality Along Route", status = "info", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("infrastructure_quality_plot"))
                )
              )
      ),
      
      # Risk Dashboard Tab
      tabItem(tabName = "risks",
              fluidRow(
                box(
                  title = "Risk Category Summary", status = "primary", solidHeader = TRUE, width = 8,
                  withSpinner(DT::dataTableOutput("risk_summary_table"))
                ),
                
                box(
                  title = "Overall Risk Assessment", status = "danger", solidHeader = TRUE, width = 4,
                  div(style = "color: #ecf0f1; text-align: center;",
                      h3("System Readiness"),
                      br(),
                      tags$div(
                        style = "background-color: #f39c12; padding: 20px; border-radius: 10px; margin: 10px;",
                        h2("CAUTION", style = "color: white; margin: 0;"),
                        h4("67% Route Ready", style = "color: white; margin: 5px 0;")
                      ),
                      br(),
                      p("Significant infrastructure gaps identified"),
                      p("Weather resilience concerns"),
                      p("Complex scenario challenges remain")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Risk Distribution by Category", status = "warning", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("risk_category_plot"))
                ),
                
                box(
                  title = "Deployment Readiness Heatmap", status = "info", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("readiness_heatmap"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Recommended Actions", status = "success", solidHeader = TRUE, width = 12,
                  div(style = "color: #ecf0f1;",
                      h4("Immediate Priorities"),
                      tags$ul(
                        tags$li("Infrastructure upgrade: Focus on lane marking renewal in critical segments"),
                        tags$li("Weather monitoring: Implement real-time sensor degradation alerts"),
                        tags$li("Geofencing: Restrict initial deployment to compliant road segments")
                      ),
                      br(),
                      h4("Medium-term Development"),
                      tags$ul(
                        tags$li("Enhanced training data: Expand to 1000+ annotated images"),
                        tags$li("Multi-angle capture: Improve detection reliability"),
                        tags$li("Dynamic risk integration: Real-time weather and traffic overlays")
                      ),
                      br(),
                      h4("Strategic Considerations"),
                      tags$ul(
                        tags$li("Vehicle adaptation vs infrastructure adaptation approach"),
                        tags$li("V2X connectivity deployment for enhanced safety"),
                        tags$li("Regulatory compliance with AV Act 2024 safety standards")
                      )
                  )
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Executive Overview Value Boxes
  output$total_segments <- renderValueBox({
    valueBox(
      value = nrow(route_segments),
      subtitle = "Route Segments Analyzed",
      icon = icon("route"),
      color = "blue"
    )
  })
  
  output$critical_risks <- renderValueBox({
    critical_count <- sum(route_segments$Overall_Risk == "Critical")
    valueBox(
      value = critical_count,
      subtitle = "Critical Risk Segments",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$avg_compatibility <- renderValueBox({
    avg_score <- round(mean(route_segments$Infrastructure_Score), 1)
    valueBox(
      value = paste0(avg_score, "%"),
      subtitle = "Average Compatibility",
      icon = icon("chart-line"),
      color = "yellow"
    )
  })
  
  output$ready_segments <- renderValueBox({
    ready_count <- sum(route_segments$Overall_Risk == "Compliant")
    ready_pct <- round(ready_count / nrow(route_segments) * 100, 0)
    valueBox(
      value = paste0(ready_pct, "%"),
      subtitle = "Deployment Ready",
      icon = icon("check-circle"),
      color = "green"
    )
  })
  
  # Vehicle Capabilities Table
  output$vehicle_table <- DT::renderDataTable({
    DT::datatable(vehicle_capabilities, 
                  options = list(
                    pageLength = 10,
                    scrollX = TRUE,
                    dom = 'frtip'
                  ),
                  style = 'bootstrap',
                  class = 'table-dark') %>%
      formatStyle(columns = colnames(vehicle_capabilities), 
                  backgroundColor = '#34495e', 
                  color = '#ecf0f1')
  })
  
  # Sensor Suite Analysis Plot
  output$sensor_plot <- renderPlotly({
    sensor_data <- data.frame(
      Vehicle = vehicle_capabilities$Vehicle,
      LiDAR = c(1, 1, 1, 0.5, 1),
      Camera = c(1, 1, 1, 1, 1),
      Radar = c(1, 1, 1, 0.5, 1),
      stringsAsFactors = FALSE
    )
    
    p <- sensor_data %>%
      tidyr::pivot_longer(cols = c("LiDAR", "Camera", "Radar"), 
                          names_to = "Sensor", values_to = "Capability") %>%
      ggplot(aes(x = Vehicle, y = Capability, fill = Sensor)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = c("#3498db", "#e74c3c", "#f39c12")) +
      theme_minimal() +
      theme(
        panel.background = element_rect(fill = "#2c3e50"),
        plot.background = element_rect(fill = "#2c3e50"),
        text = element_text(color = "#ecf0f1"),
        axis.text = element_text(color = "#ecf0f1", angle = 45, hjust = 1),
        legend.background = element_rect(fill = "#34495e"),
        legend.text = element_text(color = "#ecf0f1"),
        panel.grid = element_line(color = "#34495e")
      ) +
      labs(title = "Sensor Suite Capabilities by Vehicle", x = "", y = "Capability Level")
    
    ggplotly(p) %>% 
      layout(paper_bgcolor = '#2c3e50', plot_bgcolor = '#2c3e50')
  })
  
  # AI Paradigm Plot
  output$ai_paradigm_plot <- renderPlotly({
    paradigm_counts <- table(c("Modular", "Platform", "Modular", "End-to-End", "Modular"))
    
    p <- plot_ly(
      labels = names(paradigm_counts),
      values = as.numeric(paradigm_counts),
      type = 'pie',
      marker = list(colors = c('#3498db', '#e74c3c', '#f39c12', '#2ecc71'))
    ) %>%
      layout(
        title = list(text = "AI Paradigm Distribution", font = list(color = '#ecf0f1')),
        paper_bgcolor = '#2c3e50',
        plot_bgcolor = '#2c3e50',
        font = list(color = '#ecf0f1')
      )
    
    p
  })
  
  # Vehicle Description
  output$vehicle_description <- renderText({
    selected <- input$selected_vehicle
    if (is.null(selected)) return("")
    
    descriptions <- list(
      "Waymo Driver" = "Safety-by-Design approach with comprehensive 3D mapping. 20M+ real-world miles tested.",
      "NVIDIA DRIVE Thor" = "High-performance platform supporting 1000+ TOPS AI performance. Developer-agnostic.",
      "Mobileye Chauffeur" = "Camera-centric with crowdsourced mapping. Formal RSS safety model.",
      "Wayve" = "End-to-end learning approach. Designed for complex UK urban environments.",
      "Oxa" = "Universal autonomy stack for multiple platforms. Deployed at Heathrow Airport."
    )
    
    descriptions[[selected]]
  })
  
  # Infrastructure Features Table
  output$infrastructure_table <- DT::renderDataTable({
    DT::datatable(infrastructure_features,
                  options = list(
                    pageLength = 15,
                    scrollX = TRUE,
                    dom = 'frtip'
                  ),
                  style = 'bootstrap',
                  class = 'table-dark') %>%
      formatStyle(columns = colnames(infrastructure_features),
                  backgroundColor = '#34495e',
                  color = '#ecf0f1')
  })
  
  # Feature Category Plot
  output$feature_category_plot <- renderPlotly({
    category_counts <- table(infrastructure_features$Category)
    
    p <- plot_ly(
      x = names(category_counts),
      y = as.numeric(category_counts),
      type = 'bar',
      marker = list(color = '#3498db')
    ) %>%
      layout(
        title = list(text = "Features by Category", font = list(color = '#ecf0f1')),
        xaxis = list(title = "", tickfont = list(color = '#ecf0f1')),
        yaxis = list(title = "Count", tickfont = list(color = '#ecf0f1')),
        paper_bgcolor = '#2c3e50',
        plot_bgcolor = '#2c3e50'
      )
    
    p
  })
  
  # Performance Impact Table
  output$performance_table <- DT::renderDataTable({
    DT::datatable(performance_impact,
                  options = list(
                    pageLength = 10,
                    scrollX = TRUE,
                    dom = 'frtip'
                  ),
                  style = 'bootstrap',
                  class = 'table-dark') %>%
      formatStyle(columns = colnames(performance_impact),
                  backgroundColor = '#34495e',
                  color = '#ecf0f1') %>%
      formatStyle('Severity',
                  backgroundColor = styleEqual(c('Critical', 'High', 'Low'), 
                                               c('#e74c3c', '#f39c12', '#2ecc71')))
  })
  
  # Weather Impact Plot
  output$weather_impact_plot <- renderPlotly({
    weather_data <- data.frame(
      Condition = c("Clear", "Light Rain", "Heavy Rain", "Fog", "Snow"),
      LiDAR_Range = c(100, 85, 50, 30, 45),
      Camera_Accuracy = c(95, 80, 45, 25, 40),
      stringsAsFactors = FALSE
    )
    
    p <- weather_data %>%
      tidyr::pivot_longer(cols = c("LiDAR_Range", "Camera_Accuracy"), 
                          names_to = "Sensor", values_to = "Performance") %>%
      ggplot(aes(x = Condition, y = Performance, color = Sensor, group = Sensor)) +
      geom_line(size = 1.2) +
      geom_point(size = 3) +
      scale_color_manual(values = c("#e74c3c", "#3498db")) +
      theme_minimal() +
      theme(
        panel.background = element_rect(fill = "#2c3e50"),
        plot.background = element_rect(fill = "#2c3e50"),
        text = element_text(color = "#ecf0f1"),
        axis.text = element_text(color = "#ecf0f1", angle = 45, hjust = 1),
        legend.background = element_rect(fill = "#34495e"),
        legend.text = element_text(color = "#ecf0f1"),
        panel.grid = element_line(color = "#34495e")
      ) +
      labs(title = "Sensor Performance vs Weather", x = "", y = "Performance %")
    
    ggplotly(p) %>% 
      layout(paper_bgcolor = '#2c3e50', plot_bgcolor = '#2c3e50')
  })
  
  # Lane Degradation Plot
  output$lane_degradation_plot <- renderPlotly({
    degradation_data <- data.frame(
      Fade_Percentage = c(0, 25, 50, 75, 90),
      LDW_Accuracy = c(98, 96, 95, 54, 25),
      stringsAsFactors = FALSE
    )
    
    p <- ggplot(degradation_data, aes(x = Fade_Percentage, y = LDW_Accuracy)) +
      geom_line(color = "#e74c3c", size = 2) +
      geom_point(color = "#3498db", size = 4) +
      geom_hline(yintercept = 75, linetype = "dashed", color = "#f39c12", size = 1) +
      annotate("text", x = 60, y = 80, label = "Safety Threshold", color = "#f39c12", size = 4) +
      theme_minimal() +
      theme(
        panel.background = element_rect(fill = "#2c3e50"),
        plot.background = element_rect(fill = "#2c3e50"),
        text = element_text(color = "#ecf0f1"),
        axis.text = element_text(color = "#ecf0f1"),
        legend.background = element_rect(fill = "#34495e"),
        legend.text = element_text(color = "#ecf0f1"),
        panel.grid = element_line(color = "#34495e")
      ) +
      labs(title = "Lane Marking Degradation Impact", 
           x = "Lane Marking Fade %", 
           y = "LDW System Accuracy %")
    
    ggplotly(p) %>% 
      layout(paper_bgcolor = '#2c3e50', plot_bgcolor = '#2c3e50')
  })
  
  # Route Map
  output$route_map <- renderLeaflet({
    # Color coding based on risk
    colors <- c("Compliant" = "#2ecc71", "Moderate" = "#f39c12", "Critical" = "#e74c3c")
    
    leaflet(route_segments) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~Longitude,
        lat = ~Latitude,
        color = ~colors[Overall_Risk],
        radius = 6,
        fillOpacity = 0.8,
        stroke = TRUE,
        weight = 2,
        popup = ~paste(
          "<b>Segment:", Segment_ID, "</b><br>",
          "Risk Level:", Overall_Risk, "<br>",
          "Infrastructure Score:", round(Infrastructure_Score, 1), "%<br>",
          "Lane Contrast:", round(Lane_Contrast, 2), "<br>",
          "Distance:", round(Distance_km, 1), "km"
        )
      ) %>%
      addLegend(
        position = "bottomright",
        colors = c("#2ecc71", "#f39c12", "#e74c3c"),
        labels = c("Compliant", "Moderate", "Critical"),
        title = "Risk Level"
      ) %>%
      setView(lng = 0.5, lat = 51.5, zoom = 8)
  })
  
  # Route Statistics Value Boxes
  output$route_length <- renderValueBox({
    total_length <- round(max(route_segments$Distance_km), 1)
    valueBox(
      value = paste0(total_length, " km"),
      subtitle = "Total Route Length",
      icon = icon("road"),
      color = "blue",
      width = 12
    )
  })
  
  output$high_risk_segments <- renderValueBox({
    high_risk <- sum(route_segments$Overall_Risk %in% c("Critical", "Moderate"))
    valueBox(
      value = high_risk,
      subtitle = "High Risk Segments",
      icon = icon("warning"),
      color = "red",
      width = 12
    )
  })
  
  output$weather_alerts <- renderValueBox({
    weather_high <- sum(route_segments$Weather_Risk == "High")
    valueBox(
      value = weather_high,
      subtitle = "Weather Alerts",
      icon = icon("cloud-rain"),
      color = "yellow",
      width = 12
    )
  })
  
  # Risk Distribution Plot
  output$risk_distribution_plot <- renderPlotly({
    risk_counts <- table(route_segments$Overall_Risk)
    
    p <- plot_ly(
      x = names(risk_counts),
      y = as.numeric(risk_counts),
      type = 'bar',
      marker = list(color = c("#2ecc71", "#e74c3c", "#f39c12"))
    ) %>%
      layout(
        title = list(text = "Risk Level Distribution", font = list(color = '#ecf0f1')),
        xaxis = list(title = "Risk Level", tickfont = list(color = '#ecf0f1')),
        yaxis = list(title = "Number of Segments", tickfont = list(color = '#ecf0f1')),
        paper_bgcolor = '#2c3e50',
        plot_bgcolor = '#2c3e50'
      )
    
    p
  })
  
  # Infrastructure Quality Plot
  output$infrastructure_quality_plot <- renderPlotly({
    p <- ggplot(route_segments, aes(x = Distance_km, y = Infrastructure_Score)) +
      geom_line(color = "#3498db", size = 1) +
      geom_point(aes(color = Overall_Risk), size = 2) +
      scale_color_manual(values = c("Compliant" = "#2ecc71", "Moderate" = "#f39c12", "Critical" = "#e74c3c")) +
      geom_hline(yintercept = 75, linetype = "dashed", color = "#f39c12") +
      theme_minimal() +
      theme(
        panel.background = element_rect(fill = "#2c3e50"),
        plot.background = element_rect(fill = "#2c3e50"),
        text = element_text(color = "#ecf0f1"),
        axis.text = element_text(color = "#ecf0f1"),
        legend.background = element_rect(fill = "#34495e"),
        legend.text = element_text(color = "#ecf0f1"),
        panel.grid = element_line(color = "#34495e")
      ) +
      labs(title = "Infrastructure Quality Along Route", 
           x = "Distance (km)", 
           y = "Infrastructure Score (%)",
           color = "Risk Level")
    
    ggplotly(p) %>% 
      layout(paper_bgcolor = '#2c3e50', plot_bgcolor = '#2c3e50')
  })
  
  # Risk Summary Table
  output$risk_summary_table <- DT::renderDataTable({
    DT::datatable(risk_summary,
                  options = list(
                    pageLength = 10,
                    scrollX = TRUE,
                    dom = 'frtip'
                  ),
                  style = 'bootstrap',
                  class = 'table-dark') %>%
      formatStyle(columns = colnames(risk_summary),
                  backgroundColor = '#34495e',
                  color = '#ecf0f1') %>%
      formatStyle('Critical_Count',
                  backgroundColor = styleInterval(c(3, 6), c('#2ecc71', '#f39c12', '#e74c3c')))
  })
  
  # Risk Category Plot
  output$risk_category_plot <- renderPlotly({
    risk_long <- risk_summary %>%
      tidyr::pivot_longer(cols = c("Critical_Count", "Moderate_Count", "Compliant_Count"),
                          names_to = "Risk_Level", values_to = "Count") %>%
      mutate(Risk_Level = gsub("_Count", "", Risk_Level))
    
    p <- ggplot(risk_long, aes(x = Risk_Category, y = Count, fill = Risk_Level)) +
      geom_col(position = "stack") +
      scale_fill_manual(values = c("Compliant" = "#2ecc71", "Critical" = "#e74c3c", "Moderate" = "#f39c12")) +
      theme_minimal() +
      theme(
        panel.background = element_rect(fill = "#2c3e50"),
        plot.background = element_rect(fill = "#2c3e50"),
        text = element_text(color = "#ecf0f1"),
        axis.text = element_text(color = "#ecf0f1", angle = 45, hjust = 1),
        legend.background = element_rect(fill = "#34495e"),
        legend.text = element_text(color = "#ecf0f1"),
        panel.grid = element_line(color = "#34495e")
      ) +
      labs(title = "Risk Distribution by Category", x = "", y = "Segment Count", fill = "Risk Level")
    
    ggplotly(p) %>% 
      layout(paper_bgcolor = '#2c3e50', plot_bgcolor = '#2c3e50')
  })
  
  # Readiness Heatmap
  output$readiness_heatmap <- renderPlotly({
    # Create heatmap data
    heatmap_data <- expand.grid(
      Infrastructure = c("Lane Markings", "Signage", "Road Surface", "Geometry"),
      Weather = c("Clear", "Light Rain", "Heavy Rain", "Fog"),
      stringsAsFactors = FALSE
    )
    
    # Simulate readiness scores
    set.seed(456)
    heatmap_data$Readiness_Score <- case_when(
      heatmap_data$Weather == "Clear" ~ runif(4, 70, 95),
      heatmap_data$Weather == "Light Rain" ~ runif(4, 50, 80),
      heatmap_data$Weather == "Heavy Rain" ~ runif(4, 20, 60),
      heatmap_data$Weather == "Fog" ~ runif(4, 10, 40)
    )
    
    p <- plot_ly(
      data = heatmap_data,
      x = ~Weather,
      y = ~Infrastructure,
      z = ~Readiness_Score,
      type = "heatmap",
      colorscale = list(c(0, "#e74c3c"), c(0.5, "#f39c12"), c(1, "#2ecc71")),
      showscale = TRUE
    ) %>%
      layout(
        title = list(text = "Deployment Readiness by Conditions", font = list(color = '#ecf0f1')),
        xaxis = list(title = "Weather Conditions", tickfont = list(color = '#ecf0f1')),
        yaxis = list(title = "Infrastructure Type", tickfont = list(color = '#ecf0f1')),
        paper_bgcolor = '#2c3e50',
        plot_bgcolor = '#2c3e50'
      )
    
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)