library(shiny)
library(shinydashboard)
library(plotly)
library(leaflet)
library(visNetwork)
library(dplyr)
library(ggplot2)
library(shinycssloaders)

# Ensure no terra library is loaded or called
if ("terra" %in% loadedNamespaces()) {
  try(unloadNamespace("terra"), silent = TRUE)
}

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Atera Analytics - CAM 2025 Strategic Framework"),
  
  dashboardSidebar(
    tags$head(
      tags$style(HTML("
        /* VisNetwork dropdown styling */
        .vis-network .vis-manipulation .vis-button select,
        .vis-network .vis-configuration select,
        select {
          color: black !important;
          background-color: white !important;
        }
        
        option {
          color: black !important;
          background-color: white !important;
        }
      
        /* Main theme colors */
        .skin-blue .main-header .navbar {
          background-color: #008A82 !important;
        }
        
        .skin-blue .main-header .logo {
          background-color: #002C3C !important;
        }
        
        .skin-blue .main-header .logo:hover {
          background-color: #008A82 !important;
        }
        
        .skin-blue .main-sidebar {
          background-color: #00A39A !important;
        }
        
        .skin-blue .sidebar-menu > li.header {
          background: #008A82 !important;
          color: white !important;
        }
        
        .skin-blue .sidebar-menu > li > a {
          color: white !important;
        }
        
        .skin-blue .sidebar-menu > li:hover > a,
        .skin-blue .sidebar-menu > li.active > a {
          background-color: #008A82 !important;
          color: white !important;
        }
        
        .content-wrapper, .right-side {
          background-color: #002C3C !important;
        }
        
        .box {
          background: #00A39A !important;
          border-top: none !important;
          color: white !important;
        }
        
        .box-header {
          background: #00A39A !important;
          color: white !important;
        }
        
        .box-body {
          background: white !important;
          color: #2c3e50 !important;
        }
        
        .box-title {
          color: white !important;
        }
        
        .metric-box {
          background: white;
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
          border-left: 4px solid #00A39A;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          color: #2c3e50 !important;
        }
        
        .network-container {
          height: 600px;
          border: 1px solid #ddd;
          border-radius: 8px;
          background: white;
        }
        
        .form-control {
          background-color: rgba(255,255,255,0.9) !important;
          border: 1px solid #bdc3c7 !important;
          color: #2c3e50 !important;
        }
        
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 0.2rem rgba(0, 163, 154, 0.25) !important;
        }
      "))
    ),
    
    sidebarMenu(
      menuItem("GIS Systems", tabName = "gis", icon = icon("map")),
      menuItem("Network Modeling", tabName = "network", icon = icon("project-diagram")),
      menuItem("Generative AI", tabName = "genai", icon = icon("brain")),
      menuItem("Energy Usage", tabName = "energy", icon = icon("bolt")),
      menuItem("Cost Forecasting", tabName = "costs", icon = icon("pound-sign")),
      menuItem("EV Data Intelligence", tabName = "evdata", icon = icon("car")),
      menuItem("Safety Assurance", tabName = "safety", icon = icon("shield-alt")),
      menuItem("Digital Infrastructure", tabName = "digital", icon = icon("server"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # GIS Systems Tab
      tabItem(tabName = "gis",
              fluidRow(
                box(
                  title = "GIS Systems and Spatial Intelligence for CAM Infrastructure", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  p("Advanced Geographic Information Systems integrating multiple data layers for comprehensive CAM infrastructure assessment and deployment optimization across the UK.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Interactive UK CAM Infrastructure Map", 
                  status = "primary", solidHeader = TRUE, width = 8,
                  leafletOutput("gis_map", height = "500px") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Infrastructure Controls", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  selectInput("gis_layer", "Select Layer:",
                              choices = c("5G Coverage" = "5g", 
                                          "Charging Stations" = "charging",
                                          "CAM Ready Routes" = "routes")),
                  
                  selectInput("gis_region", "Focus Region:", 
                              choices = c("All UK" = "all", "London" = "london", 
                                          "Manchester" = "manchester", "Scotland" = "scotland")),
                  
                  div(class = "metric-box",
                      h4("Infrastructure Metrics"),
                      textOutput("gis_coverage_text"),
                      textOutput("gis_density_text"),
                      textOutput("gis_readiness_text")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Infrastructure Readiness Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("gis_readiness") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Regional Comparison", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("gis_comparison") %>% withSpinner(color = "#008A82")
                )
              ),
              
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("1. Department for Transport (2022). Connected & Automated Mobility 2025: Realising the benefits of self-driving vehicles in the UK."),
                    tags$p("2. Ordnance Survey (2025). Digital Twin Programme for Transport Infrastructure."),
                    tags$p("3. CCAV (2025). CAM Testbed UK Infrastructure Development.")
                  )
                )
              )
      ),
      
      # Network Modeling Tab
      tabItem(tabName = "network",
              fluidRow(
                box(
                  title = "Network Modeling and Interconnected Systems Analysis", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  p("Advanced graph-based network analysis providing optimal CAM route planning, cyber vulnerability assessment, and real-time traffic flow optimization supporting congestion reduction goals.")
                )
              ),
              
              fluidRow(
                box(
                  title = "CAM Network Topology", 
                  status = "primary", solidHeader = TRUE, width = 8,
                  div(class = "network-container",
                      visNetworkOutput("network_graph", height = "580px") %>% withSpinner(color = "#008A82")
                  )
                ),
                
                box(
                  title = "Network Controls", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  selectInput("network_type", "Network Type:",
                              choices = c("Vehicle-to-Infrastructure" = "v2i",
                                          "Vehicle-to-Vehicle" = "v2v",
                                          "Charging Network" = "charging")),
                  
                  sliderInput("network_complexity", "Network Complexity:", 
                              min = 1, max = 3, value = 2, step = 1),
                  
                  div(class = "metric-box",
                      h4("Network Metrics"),
                      textOutput("network_latency_text"),
                      textOutput("network_throughput_text"),
                      textOutput("network_resilience_text")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Network Performance Analytics", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("network_performance") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Security Threat Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("network_security") %>% withSpinner(color = "#008A82")
                )
              ),
              
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("1. IEEE (2024). Vehicle-to-Everything (V2X) Communications for CAM Systems."),
                    tags$p("2. 5G Automotive Association (2025). Network Architecture for Connected Mobility."),
                    tags$p("3. National Cyber Security Centre (2025). Connected Places Cyber Security Principles.")
                  )
                )
              )
      ),
      
      # Generative AI Tab
      tabItem(tabName = "genai",
              fluidRow(
                box(
                  title = "Generative AI and Explainable CAM Intelligence", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  p("Causal AI framework providing explainable decision-making for autonomous vehicles, supporting regulatory compliance with National Safety Principles and transparent AI operations.")
                )
              ),
              
              fluidRow(
                box(
                  title = "AI Decision Analysis", 
                  status = "primary", solidHeader = TRUE, width = 8,
                  plotlyOutput("ai_decision_tree", height = "500px") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "AI Model Configuration", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  selectInput("ai_scenario", "Driving Scenario:",
                              choices = c("Highway" = "highway", "Urban" = "urban", 
                                          "Weather" = "weather", "Night" = "night")),
                  
                  sliderInput("ai_confidence", "Confidence Threshold:", 
                              min = 0.7, max = 1.0, value = 0.85, step = 0.05),
                  
                  div(class = "metric-box",
                      h4("Model Performance"),
                      textOutput("ai_accuracy_text"),
                      textOutput("ai_explainability_text"),
                      textOutput("ai_compliance_text")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Causal Factor Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("ai_causal") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Decision Confidence Tracking", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("ai_confidence_chart") %>% withSpinner(color = "#008A82")
                )
              ),
              
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("1. Centre for Data Ethics and Innovation (2022). Responsible Innovation for Self-Driving Vehicles."),
                    tags$p("2. Alan Turing Institute (2025). Explainable AI for Autonomous Systems."),
                    tags$p("3. Partnership on AI (2024). Tenets for Responsible AI Development.")
                  )
                )
              )
      ),
      
      # Energy Usage Tab
      tabItem(tabName = "energy",
              fluidRow(
                box(
                  title = "Energy Usage Optimization and Grid Integration", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  p("Smart energy management platform addressing CAM deployment intersection with UK's Transport Decarbonisation Plan, supporting 30+ million EVs by 2030 with grid integration and renewable energy optimization.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Energy Consumption Dashboard", 
                  status = "primary", solidHeader = TRUE, width = 8,
                  plotlyOutput("energy_consumption", height = "400px") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Energy Controls", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  selectInput("energy_timeframe", "Time Period:",
                              choices = c("Daily" = "daily", "Weekly" = "weekly", 
                                          "Monthly" = "monthly")),
                  
                  selectInput("energy_source", "Energy Mix:",
                              choices = c("Current Mix" = "current", 
                                          "High Renewable" = "renewable",
                                          "Low Carbon" = "lowcarbon")),
                  
                  div(class = "metric-box",
                      h4("Energy Metrics"),
                      textOutput("energy_load_text"),
                      textOutput("energy_renewable_text"),
                      textOutput("energy_carbon_text")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Regional Grid Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("energy_regional") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Carbon Impact Forecast", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("energy_carbon_forecast") %>% withSpinner(color = "#008A82")
                )
              ),
              
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("1. Department for Transport (2021). Transport Decarbonisation Plan."),
                    tags$p("2. National Grid ESO (2025). Future Energy Scenarios for Electric Vehicle Integration."),
                    tags$p("3. Office for Zero Emission Vehicles (2025). EV Infrastructure Strategy.")
                  )
                )
              )
      ),
      
      # Cost Forecasting Tab
      tabItem(tabName = "costs",
              fluidRow(
                box(
                  title = "Advanced Cost Forecasting and Economic Impact Analysis", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  p("Financial modeling framework supporting CAM 2025 projection of £42 billion UK market by 2035, with infrastructure investment optimization and economic impact assessment for 38,000 new jobs.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Economic Projection Dashboard", 
                  status = "primary", solidHeader = TRUE, width = 8,
                  plotlyOutput("cost_projection", height = "400px") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Economic Parameters", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  selectInput("cost_scenario", "Economic Scenario:",
                              choices = c("Conservative" = "conservative",
                                          "Base Case" = "base",
                                          "Optimistic" = "optimistic")),
                  
                  selectInput("cost_sector", "Focus Sector:",
                              choices = c("All Sectors" = "all", "Logistics" = "logistics",
                                          "Public Transport" = "public", "Private" = "private")),
                  
                  div(class = "metric-box",
                      h4("Economic Forecast"),
                      textOutput("cost_market_text"),
                      textOutput("cost_jobs_text"),
                      textOutput("cost_roi_text")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Investment vs Returns Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("cost_investment") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Job Creation by Region", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("cost_jobs_regional") %>% withSpinner(color = "#008A82")
                )
              ),
              
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("1. HM Treasury (2025). Economic Impact Assessment for Connected and Autonomous Mobility."),
                    tags$p("2. Connected Places Catapult (2021). CAM Market Forecast 2020-2035."),
                    tags$p("3. Society of Motor Manufacturers and Traders (2025). Connected and Autonomous Vehicles: Economic Benefits Analysis.")
                  )
                )
              )
      ),
      
      # EV Data Intelligence Tab
      tabItem(tabName = "evdata",
              fluidRow(
                box(
                  title = "Comprehensive EV and Charging Infrastructure Data Intelligence", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  p("Big data analytics platform providing critical insights from ATERA EVs DATA SET, supporting UK's transition to connected mobility with real-time charging infrastructure and performance analysis.")
                )
              ),
              
              fluidRow(
                box(
                  title = "EV Performance Analytics", 
                  status = "primary", solidHeader = TRUE, width = 8,
                  plotlyOutput("ev_performance", height = "400px") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "EV Data Controls", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  selectInput("ev_metric", "Performance Metric:",
                              choices = c("Battery Efficiency" = "battery",
                                          "Range Analysis" = "range",
                                          "Charging Speed" = "charging")),
                  
                  selectInput("ev_vehicle_type", "Vehicle Type:",
                              choices = c("All Vehicles" = "all", "Cars" = "cars",
                                          "Vans" = "vans", "Buses" = "buses")),
                  
                  div(class = "metric-box",
                      h4("Fleet Metrics"),
                      textOutput("ev_fleet_text"),
                      textOutput("ev_efficiency_text"),
                      textOutput("ev_utilization_text")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Charging Infrastructure Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("ev_charging_analysis") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Usage Pattern Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("ev_usage_patterns") %>% withSpinner(color = "#008A82")
                )
              ),
              
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("1. Zap-Map (2025). UK Public Charging Network Statistics."),
                    tags$p("2. Electric Vehicle Database (2025). EV Specifications and Performance Data."),
                    tags$p("3. ChargeUK (2025). Electric Vehicle Charging Infrastructure Report.")
                  )
                )
              )
      ),
      
      # Safety Assurance Tab
      tabItem(tabName = "safety",
              fluidRow(
                box(
                  title = "Safety Assurance and Regulatory Compliance Framework", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  p("Comprehensive safety monitoring system supporting CAVPASS Programme with real-time safety assessment, incident investigation, and regulatory compliance tracking for Authorised Self-Driving Entities.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Safety Performance Monitor", 
                  status = "primary", solidHeader = TRUE, width = 8,
                  plotlyOutput("safety_monitor", height = "400px") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Safety Controls", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  selectInput("safety_timeframe", "Analysis Period:",
                              choices = c("Last 7 Days" = "week", "Last 30 Days" = "month",
                                          "Last 90 Days" = "quarter")),
                  
                  selectInput("safety_vehicle_class", "Vehicle Class:",
                              choices = c("All Vehicles" = "all", "Passenger Cars" = "cars",
                                          "Commercial" = "commercial", "Public Transport" = "public")),
                  
                  div(class = "metric-box",
                      h4("Safety Status"),
                      textOutput("safety_score_text"),
                      textOutput("safety_incidents_text"),
                      textOutput("safety_compliance_text")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Incident Category Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("safety_incidents_chart") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Regulatory Compliance Status", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("safety_compliance_chart") %>% withSpinner(color = "#008A82")
                )
              ),
              
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("1. Vehicle Certification Agency (2025). CAVPASS Safety Assurance Framework."),
                    tags$p("2. Law Commissions (2022). Automated Vehicles: Joint Report on Regulatory Framework."),
                    tags$p("3. Department for Transport (2025). Road Safety Investigation Branch.")
                  )
                )
              )
      ),
      
      # Digital Infrastructure Tab
      tabItem(tabName = "digital",
              fluidRow(
                box(
                  title = "Digital Infrastructure and Future Transport Integration", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  p("Smart cities and connected places framework supporting 5G network optimization, edge computing deployment, and digital twin modeling for seamless CAM integration with national transport networks.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Digital Infrastructure Dashboard", 
                  status = "primary", solidHeader = TRUE, width = 8,
                  plotlyOutput("digital_coverage", height = "400px") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Infrastructure Controls", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  selectInput("digital_technology", "Technology Focus:",
                              choices = c("5G Networks" = "5g", "Edge Computing" = "edge",
                                          "Digital Twins" = "twins")),
                  
                  selectInput("digital_region_type", "Region Type:",
                              choices = c("All Regions" = "all", "Urban" = "urban",
                                          "Rural" = "rural", "Highways" = "highways")),
                  
                  div(class = "metric-box",
                      h4("Digital Metrics"),
                      textOutput("digital_coverage_text"),
                      textOutput("digital_latency_text"),
                      textOutput("digital_capacity_text")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Network Performance Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("digital_performance") %>% withSpinner(color = "#008A82")
                ),
                
                box(
                  title = "Digital Twin Maturity", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("digital_twin_maturity") %>% withSpinner(color = "#008A82")
                )
              ),
              
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("1. Department for Digital, Culture, Media & Sport (2025). 5G Testbeds and Trials Programme."),
                    tags$p("2. Digital Catapult (2025). 5G for Connected and Autonomous Vehicles."),
                    tags$p("3. Innovate UK (2025). Digital Infrastructure for Smart Mobility.")
                  )
                )
              )
      )
    )
  ),
  
  skin = "blue"
)

# Define Server
server <- function(input, output) {
  
  # Define color palettes - vibrant and high contrast
  color_palette_primary <- c("#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#FF8C42", "#6C5CE7")
  color_palette_secondary <- c("#E74C3C", "#1ABC9C", "#3498DB", "#2ECC71", "#F39C12", "#9B59B6", "#E67E22", "#8E44AD")
  
  # Helper function to reshape data without external libraries
  reshape_data <- function(data, id_vars, value_vars) {
    long_data <- data.frame()
    for(var in value_vars) {
      temp_data <- data.frame(
        metric = data[[id_vars]],
        variable = var,
        value = data[[var]]
      )
      long_data <- rbind(long_data, temp_data)
    }
    return(long_data)
  }
  
  # GIS Tab Server Logic
  output$gis_map <- renderLeaflet({
    # Base map setup with dynamic data based on controls
    map_data <- switch(input$gis_layer,
                       "5g" = data.frame(
                         lng = c(-0.1, -2.2, -1.5, -3.2, -4.2, -1.8, -2.9),
                         lat = c(51.5, 53.5, 52.5, 55.9, 50.4, 51.8, 52.2),
                         popup = c("London 5G Hub", "Manchester Node", "Birmingham Centre", "Edinburgh Link", "Plymouth Station", "Oxford Hub", "Cardiff Centre"),
                         coverage = c(95, 85, 78, 72, 65, 82, 70),
                         color = c("#2ECC71", "#F39C12", "#E67E22", "#E74C3C", "#E74C3C", "#F39C12", "#E74C3C")
                       ),
                       "charging" = data.frame(
                         lng = c(-0.1, -2.2, -1.5, -3.2, -4.2, -1.2, -2.5, -3.8),
                         lat = c(51.5, 53.5, 52.5, 55.9, 50.4, 51.2, 54.2, 51.6),
                         popup = c("London Charging Hub", "Manchester Rapid", "Birmingham Fast", "Edinburgh Network", "Plymouth Slow", "Canterbury Hub", "Newcastle Rapid", "Swansea Network"),
                         stations = c(450, 280, 320, 180, 95, 120, 150, 85),
                         color = c("#1ABC9C", "#3498DB", "#9B59B6", "#E67E22", "#E74C3C", "#2ECC71", "#F39C12", "#E74C3C")
                       ),
                       "routes" = data.frame(
                         lng = c(-0.1, -2.2, -1.5, -3.2, -4.2),
                         lat = c(51.5, 53.5, 52.5, 55.9, 50.4),
                         popup = c("M25 Corridor", "M62 Route", "M42 Network", "A90 Highway", "A38 Corridor"),
                         readiness = c(88, 75, 72, 68, 60),
                         color = c("#2ECC71", "#F39C12", "#E67E22", "#E74C3C", "#E74C3C")
                       )
    )
    
    # Adjust view based on region selection
    center_coords <- switch(input$gis_region,
                            "all" = list(lng = -2.5, lat = 53.4, zoom = 6),
                            "london" = list(lng = -0.1, lat = 51.5, zoom = 10),
                            "manchester" = list(lng = -2.2, lat = 53.5, zoom = 9),
                            "scotland" = list(lng = -4.0, lat = 56.5, zoom = 7)
    )
    
    leaflet() %>%
      addTiles() %>%
      setView(lng = center_coords$lng, lat = center_coords$lat, zoom = center_coords$zoom) %>%
      addCircleMarkers(
        lng = map_data$lng,
        lat = map_data$lat,
        popup = map_data$popup,
        color = map_data$color,
        radius = ifelse(input$gis_layer == "charging", map_data$stations/30, 
                        ifelse(input$gis_layer == "5g", map_data$coverage/8, map_data$readiness/8)),
        fillOpacity = 0.8,
        stroke = TRUE,
        weight = 2
      )
  })
  
  # Dynamic GIS metrics based on controls
  output$gis_coverage_text <- renderText({
    coverage_val <- switch(input$gis_layer,
                           "5g" = switch(input$gis_region, "all" = "84%", "london" = "95%", "manchester" = "85%", "scotland" = "72%"),
                           "charging" = switch(input$gis_region, "all" = "0.8/km²", "london" = "2.1/km²", "manchester" = "1.2/km²", "scotland" = "0.4/km²"),
                           "routes" = switch(input$gis_region, "all" = "65%", "london" = "88%", "manchester" = "75%", "scotland" = "68%")
    )
    paste(input$gis_layer, "Coverage:", coverage_val)
  })
  
  output$gis_density_text <- renderText({
    density_val <- switch(input$gis_region, "all" = "National", "london" = "High", "manchester" = "Medium", "scotland" = "Low")
    paste("Density Level:", density_val)
  })
  
  output$gis_readiness_text <- renderText({
    readiness_val <- switch(input$gis_region, "all" = "73%", "london" = "91%", "manchester" = "78%", "scotland" = "68%")
    paste("CAM Readiness:", readiness_val)
  })
  
  output$gis_readiness <- renderPlotly({
    regions_data <- switch(input$gis_layer,
                           "5g" = data.frame(
                             regions = c("London", "Manchester", "Birmingham", "Edinburgh", "Cardiff"),
                             readiness = c(95, 85, 78, 72, 70),
                             stringsAsFactors = FALSE
                           ),
                           "charging" = data.frame(
                             regions = c("London", "Manchester", "Birmingham", "Edinburgh", "Cardiff"),
                             readiness = c(92, 78, 75, 68, 65),
                             stringsAsFactors = FALSE
                           ),
                           "routes" = data.frame(
                             regions = c("London", "Manchester", "Birmingham", "Edinburgh", "Cardiff"),
                             readiness = c(88, 75, 72, 68, 60),
                             stringsAsFactors = FALSE
                           )
    )
    
    p <- ggplot(regions_data, aes(x = reorder(regions, readiness), y = readiness, fill = regions)) +
      geom_col() +
      scale_fill_manual(values = color_palette_primary[1:5]) +
      coord_flip() +
      labs(title = paste("Infrastructure Readiness -", input$gis_layer), x = "Region", y = "Readiness Score (%)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  output$gis_comparison <- renderPlotly({
    comparison_data <- data.frame(
      metric = c("5G Coverage", "Charging Points", "Road Readiness", "Digital Infrastructure"),
      current = c(84, 78, 65, 72),
      target_2030 = c(95, 90, 85, 88),
      stringsAsFactors = FALSE
    )
    
    # Manual reshape for comparison data
    comparison_long <- data.frame(
      metric = rep(comparison_data$metric, 2),
      variable = rep(c("current", "target_2030"), each = nrow(comparison_data)),
      value = c(comparison_data$current, comparison_data$target_2030)
    )
    
    p <- ggplot(comparison_long, aes(x = metric, y = value, fill = variable)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = c("#FF6B6B", "#4ECDC4"), 
                        name = "Status", labels = c("Current", "2030 Target")) +
      labs(title = "Current vs 2030 Targets", x = "Infrastructure Metric", y = "Percentage (%)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Network Tab Server Logic
  output$network_graph <- renderVisNetwork({
    node_count <- switch(as.character(input$network_complexity), "1" = 15, "2" = 25, "3" = 40)
    
    nodes <- data.frame(
      id = 1:node_count,
      label = paste("Node", 1:node_count),
      color = switch(input$network_type,
                     "v2i" = rep(c("#45B7D1", "#FF6B6B"), length.out = node_count),
                     "v2v" = rep(c("#4ECDC4", "#FFEAA7"), length.out = node_count),
                     "charging" = rep(c("#DDA0DD", "#96CEB4"), length.out = node_count)
      ),
      size = runif(node_count, 15, 35)
    )
    
    edge_count <- as.integer(node_count * 1.5)
    edges <- data.frame(
      from = sample(1:node_count, edge_count, replace = TRUE),
      to = sample(1:node_count, edge_count, replace = TRUE),
      color = switch(input$network_type, "v2i" = "#45B7D1", "v2v" = "#4ECDC4", "charging" = "#DDA0DD"),
      width = runif(edge_count, 1, 4)
    )
    
    visNetwork(nodes, edges) %>%
      visOptions(highlightNearest = TRUE) %>%
      visPhysics(enabled = TRUE, stabilization = FALSE)
  })
  
  # Dynamic network metrics
  output$network_latency_text <- renderText({
    latency_val <- switch(input$network_type, "v2i" = "8ms", "v2v" = "12ms", "charging" = "15ms")
    paste("Latency:", latency_val)
  })
  
  output$network_throughput_text <- renderText({
    throughput_val <- switch(as.character(input$network_complexity), "1" = "85%", "2" = "92%", "3" = "78%")
    paste("Throughput:", throughput_val)
  })
  
  output$network_resilience_text <- renderText({
    resilience_val <- switch(input$network_type, "v2i" = "8.2/10", "v2v" = "7.8/10", "charging" = "9.1/10")
    paste("Resilience:", resilience_val)
  })
  
  output$network_performance <- renderPlotly({
    time_points <- switch(as.character(input$network_complexity), "1" = 12, "2" = 24, "3" = 48)
    time <- 1:time_points
    
    base_latency <- switch(input$network_type, "v2i" = 8, "v2v" = 12, "charging" = 15)
    latency <- base_latency + 3 * sin(time/6) + rnorm(time_points, 0, 1)
    
    throughput <- 95 - 5 * sin(time/4) + rnorm(time_points, 0, 2)
    
    perf_data <- data.frame(time, latency, throughput)
    
    p <- ggplot(perf_data) +
      geom_line(aes(x = time, y = latency, color = "Latency"), size = 1.5) +
      geom_line(aes(x = time, y = throughput, color = "Throughput"), size = 1.5) +
      scale_color_manual(values = c("Latency" = "#FF6B6B", "Throughput" = "#4ECDC4")) +
      labs(title = "Network Performance Over Time", x = "Time (hours)", y = "Value") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$network_security <- renderPlotly({
    threats_data <- switch(input$network_type,
                           "v2i" = data.frame(
                             threats = c("Signal Jamming", "Data Interception", "Spoofing", "DDoS", "Malware"),
                             risk_levels = c(6, 4, 7, 3, 5),
                             stringsAsFactors = FALSE
                           ),
                           "v2v" = data.frame(
                             threats = c("Message Tampering", "Identity Theft", "Replay Attacks", "Eavesdropping", "Sybil Attack"),
                             risk_levels = c(7, 5, 6, 4, 8),
                             stringsAsFactors = FALSE
                           ),
                           "charging" = data.frame(
                             threats = c("Payment Fraud", "Grid Attacks", "Data Breach", "Physical Tampering", "System Overload"),
                             risk_levels = c(8, 6, 5, 4, 7),
                             stringsAsFactors = FALSE
                           )
    )
    
    threat_colors <- color_palette_secondary[1:nrow(threats_data)]
    
    p <- ggplot(threats_data, aes(x = reorder(threats, risk_levels), y = risk_levels, fill = threats)) +
      geom_col() +
      scale_fill_manual(values = threat_colors) +
      coord_flip() +
      labs(title = "Security Risk Assessment", x = "Threat Type", y = "Risk Level (1-10)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  # GenAI Tab Server Logic
  output$ai_decision_tree <- renderPlotly({
    scenario_data <- switch(input$ai_scenario,
                            "highway" = data.frame(
                              decisions = c("Speed Check", "Lane Analysis", "Traffic Density", "Weather Scan", "Final Route"),
                              confidence = c(0.96, 0.94, 0.91, 0.89, 0.95),
                              stringsAsFactors = FALSE
                            ),
                            "urban" = data.frame(
                              decisions = c("Pedestrian Detection", "Traffic Lights", "Parking Zones", "Cyclist Awareness", "Navigation"),
                              confidence = c(0.88, 0.92, 0.85, 0.90, 0.87),
                              stringsAsFactors = FALSE
                            ),
                            "weather" = data.frame(
                              decisions = c("Visibility Check", "Road Conditions", "Sensor Calibration", "Speed Adjustment", "Route Adaptation"),
                              confidence = c(0.82, 0.85, 0.91, 0.88, 0.84),
                              stringsAsFactors = FALSE
                            ),
                            "night" = data.frame(
                              decisions = c("Lighting Analysis", "Vision Enhancement", "Obstacle Detection", "Speed Control", "Path Planning"),
                              confidence = c(0.87, 0.89, 0.92, 0.90, 0.88),
                              stringsAsFactors = FALSE
                            )
    )
    
    # Filter by confidence threshold
    scenario_data <- scenario_data[scenario_data$confidence >= input$ai_confidence, ]
    
    p <- ggplot(scenario_data, aes(x = decisions, y = confidence, color = decisions)) +
      geom_point(size = 8) +
      geom_line(group = 1, color = "#008A82", size = 2) +
      scale_color_manual(values = color_palette_primary[1:nrow(scenario_data)]) +
      scale_y_continuous(limits = c(0.7, 1.0)) +
      labs(title = paste("AI Decision Chain -", input$ai_scenario), x = "Decision Point", y = "Confidence Score") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none")
    
    ggplotly(p)
  })
  
  # Dynamic AI metrics
  output$ai_accuracy_text <- renderText({
    accuracy_val <- switch(input$ai_scenario, "highway" = "96.2%", "urban" = "89.4%", "weather" = "86.1%", "night" = "91.3%")
    paste("Accuracy:", accuracy_val)
  })
  
  output$ai_explainability_text <- renderText({
    explain_val <- if(input$ai_confidence >= 0.9) "92%" else if(input$ai_confidence >= 0.8) "87%" else "82%"
    paste("Explainability:", explain_val)
  })
  
  output$ai_compliance_text <- renderText({
    compliance_val <- switch(input$ai_scenario, "highway" = "99.1%", "urban" = "97.8%", "weather" = "96.2%", "night" = "98.4%")
    paste("Compliance:", compliance_val)
  })
  
  output$ai_causal <- renderPlotly({
    causal_factors <- switch(input$ai_scenario,
                             "highway" = data.frame(
                               factors = c("Speed Limit", "Traffic Flow", "Vehicle Density", "Road Conditions", "Weather"),
                               impact = c(0.8, 0.6, 0.4, 0.3, 0.2),
                               stringsAsFactors = FALSE
                             ),
                             "urban" = data.frame(
                               factors = c("Pedestrians", "Traffic Signals", "Parking", "Cyclists", "Road Signs"),
                               impact = c(0.9, 0.7, 0.3, 0.6, 0.4),
                               stringsAsFactors = FALSE
                             ),
                             "weather" = data.frame(
                               factors = c("Visibility", "Road Surface", "Wind Speed", "Temperature", "Precipitation"),
                               impact = c(0.9, 0.8, 0.3, 0.2, 0.7),
                               stringsAsFactors = FALSE
                             ),
                             "night" = data.frame(
                               factors = c("Lighting", "Visibility", "Vehicle Lights", "Road Markings", "Reflectors"),
                               impact = c(0.8, 0.9, 0.5, 0.6, 0.4),
                               stringsAsFactors = FALSE
                             )
    )
    
    p <- ggplot(causal_factors, aes(x = reorder(factors, impact), y = impact, fill = factors)) +
      geom_col() +
      scale_fill_manual(values = color_palette_secondary[1:nrow(causal_factors)]) +
      coord_flip() +
      labs(title = "Causal Factor Impact", x = "Factor", y = "Impact Score") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  output$ai_confidence_chart <- renderPlotly({
    time_points <- 20
    time <- 1:time_points
    base_confidence <- switch(input$ai_scenario, "highway" = 0.93, "urban" = 0.87, "weather" = 0.84, "night" = 0.89)
    
    confidence_trend <- base_confidence + 0.05 * sin(time/3) + rnorm(time_points, 0, 0.02)
    confidence_trend <- pmax(0.7, pmin(1.0, confidence_trend))
    
    conf_data <- data.frame(time, confidence_trend)
    
    p <- ggplot(conf_data, aes(x = time, y = confidence_trend)) +
      geom_line(color = "#45B7D1", size = 2) +
      geom_hline(yintercept = input$ai_confidence, color = "#FF6B6B", linetype = "dashed", size = 1) +
      geom_point(color = "#4ECDC4", size = 3) +
      labs(title = "Decision Confidence Over Time", x = "Decision Sequence", y = "Confidence Level") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Energy Tab Server Logic
  output$energy_consumption <- renderPlotly({
    time_range <- switch(input$energy_timeframe, "daily" = 24, "weekly" = 168, "monthly" = 720)
    time <- 1:time_range
    
    base_multiplier <- switch(input$energy_source, "current" = 1.0, "renewable" = 0.85, "lowcarbon" = 0.92)
    
    if(input$energy_timeframe == "daily") {
      consumption <- 1000 * base_multiplier + 500 * sin(time * pi / 12) + rnorm(time_range, 0, 50)
      x_label <- "Hour of Day"
    } else if(input$energy_timeframe == "weekly") {
      consumption <- 1200 * base_multiplier + 300 * sin(time * pi / 24) + rnorm(time_range, 0, 100)
      x_label <- "Hour of Week"
    } else {
      consumption <- 1500 * base_multiplier + 400 * sin(time * pi / 120) + rnorm(time_range, 0, 150)
      x_label <- "Hour of Month"
    }
    
    energy_data <- data.frame(time, consumption)
    
    p <- ggplot(energy_data, aes(x = time, y = consumption)) +
      geom_area(fill = "#96CEB4", alpha = 0.6) +
      geom_line(color = "#2ECC71", size = 1.5) +
      labs(title = paste("Energy Consumption -", input$energy_timeframe), x = x_label, y = "Consumption (MWh)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Dynamic energy metrics
  output$energy_load_text <- renderText({
    load_val <- switch(input$energy_source, "current" = "2.8 GW", "renewable" = "2.3 GW", "lowcarbon" = "2.5 GW")
    paste("Grid Load:", load_val)
  })
  
  output$energy_renewable_text <- renderText({
    renewable_val <- switch(input$energy_source, "current" = "42%", "renewable" = "78%", "lowcarbon" = "65%")
    paste("Renewable %:", renewable_val)
  })
  
  output$energy_carbon_text <- renderText({
    carbon_val <- switch(input$energy_source, "current" = "1.8M tonnes", "renewable" = "3.2M tonnes", "lowcarbon" = "2.6M tonnes")
    paste("Carbon Saved:", carbon_val)
  })
  
  output$energy_regional <- renderPlotly({
    regions <- c("London", "Midlands", "North", "Scotland", "Wales", "SW England")
    
    load_data <- switch(input$energy_source,
                        "current" = c(87, 72, 65, 58, 63, 69),
                        "renewable" = c(78, 65, 58, 52, 56, 62),
                        "lowcarbon" = c(82, 68, 61, 55, 59, 65)
    )
    
    regional_data <- data.frame(regions, load_percent = load_data, stringsAsFactors = FALSE)
    
    region_colors <- color_palette_primary[1:6]
    
    p <- ggplot(regional_data, aes(x = regions, y = load_percent, fill = regions)) +
      geom_col() +
      scale_fill_manual(values = region_colors) +
      labs(title = "Regional Grid Load Distribution", x = "Region", y = "Load (%)") +
      theme_minimal() +
      theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  output$energy_carbon_forecast <- renderPlotly({
    years <- 2025:2035
    
    base_savings <- switch(input$energy_source, 
                           "current" = c(0.5, 0.8, 1.2, 1.8, 2.5, 3.2, 4.1, 5.0, 6.2, 7.5, 9.0),
                           "renewable" = c(0.8, 1.4, 2.1, 3.0, 4.2, 5.6, 7.2, 8.9, 10.8, 12.9, 15.2),
                           "lowcarbon" = c(0.6, 1.0, 1.6, 2.3, 3.2, 4.3, 5.6, 7.1, 8.8, 10.7, 12.8)
    )
    
    carbon_data <- data.frame(years, carbon_saved = base_savings)
    
    p <- ggplot(carbon_data, aes(x = years, y = carbon_saved)) +
      geom_area(fill = "#96CEB4", alpha = 0.6) +
      geom_line(color = "#2ECC71", size = 2) +
      geom_point(color = "#4ECDC4", size = 3) +
      labs(title = "Carbon Savings Forecast", x = "Year", y = "CO2 Saved (Million Tonnes)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Continue with remaining server logic sections...
  # Cost Forecasting Tab Server Logic
  output$cost_projection <- renderPlotly({
    years <- 2025:2035
    
    market_multiplier <- switch(input$cost_scenario, "conservative" = 0.8, "base" = 1.0, "optimistic" = 1.3)
    sector_multiplier <- switch(input$cost_sector, "all" = 1.0, "logistics" = 0.4, "public" = 0.3, "private" = 0.6)
    
    base_values <- c(5, 8, 12, 18, 25, 32, 38, 42, 45, 47, 50)
    market_value <- base_values * market_multiplier * sector_multiplier
    
    cost_data <- data.frame(years, market_value)
    
    p <- ggplot(cost_data, aes(x = years, y = market_value)) +
      geom_line(color = "#45B7D1", size = 2) +
      geom_point(color = "#FFEAA7", size = 4) +
      geom_area(fill = "#45B7D1", alpha = 0.3) +
      labs(title = paste("Market Value Projection -", input$cost_scenario), 
           x = "Year", y = "Market Value (£ Billions)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Dynamic cost metrics
  output$cost_market_text <- renderText({
    market_val <- switch(input$cost_scenario, "conservative" = "£34B by 2035", "base" = "£42B by 2035", "optimistic" = "£55B by 2035")
    paste("Market Value:", market_val)
  })
  
  output$cost_jobs_text <- renderText({
    jobs_val <- switch(input$cost_scenario, "conservative" = "28,000", "base" = "38,000", "optimistic" = "52,000")
    paste("Jobs Created:", jobs_val)
  })
  
  output$cost_roi_text <- renderText({
    roi_val <- switch(input$cost_scenario, "conservative" = "280%", "base" = "340%", "optimistic" = "420%")
    paste("ROI:", roi_val)
  })
  
  output$cost_investment <- renderPlotly({
    phases <- c("Research", "Development", "Pilot", "Deployment", "Scale-up")
    
    investment_data <- switch(input$cost_scenario,
                              "conservative" = c(1.5, 3.2, 2.1, 5.8, 8.4),
                              "base" = c(2.1, 4.8, 3.2, 8.5, 12.3),
                              "optimistic" = c(2.8, 6.4, 4.3, 11.2, 16.1)
    )
    
    returns_data <- switch(input$cost_scenario,
                           "conservative" = c(0.5, 2.1, 3.8, 12.4, 28.7),
                           "base" = c(0.8, 3.2, 5.9, 18.6, 42.1),
                           "optimistic" = c(1.2, 4.8, 8.7, 26.8, 58.3)
    )
    
    investment_df <- data.frame(
      phases = rep(phases, 2),
      value = c(investment_data, returns_data),
      type = rep(c("Investment", "Returns"), each = 5),
      stringsAsFactors = FALSE
    )
    
    p <- ggplot(investment_df, aes(x = phases, y = value, fill = type)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = c("Investment" = "#FF6B6B", "Returns" = "#4ECDC4")) +
      labs(title = "Investment vs Returns by Phase", x = "Phase", y = "Value (£B)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  output$cost_jobs_regional <- renderPlotly({
    regions <- c("London", "Manchester", "Birmingham", "Edinburgh", "Cardiff", "Bristol")
    
    job_multiplier <- switch(input$cost_scenario, "conservative" = 0.8, "base" = 1.0, "optimistic" = 1.3)
    sector_impact <- switch(input$cost_sector, "all" = 1.0, "logistics" = 0.7, "public" = 0.5, "private" = 0.8)
    
    base_jobs <- c(12000, 8500, 7200, 5500, 3200, 4100)
    jobs <- base_jobs * job_multiplier * sector_impact
    
    regional_jobs <- data.frame(regions, jobs, stringsAsFactors = FALSE)
    
    p <- ggplot(regional_jobs, aes(x = reorder(regions, jobs), y = jobs, fill = regions)) +
      geom_col() +
      scale_fill_manual(values = color_palette_primary[1:6]) +
      coord_flip() +
      labs(title = "Job Creation by Region", x = "Region", y = "Jobs Created") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  # EV Data Intelligence Tab Server Logic
  output$ev_performance <- renderPlotly({
    months <- 1:12
    
    performance_data <- switch(input$ev_metric,
                               "battery" = switch(input$ev_vehicle_type,
                                                  "all" = c(82, 84, 86, 89, 87, 85, 83, 81, 85, 88, 90, 92),
                                                  "cars" = c(85, 87, 89, 92, 90, 88, 86, 84, 88, 91, 93, 95),
                                                  "vans" = c(78, 80, 82, 85, 83, 81, 79, 77, 81, 84, 86, 88),
                                                  "buses" = c(75, 77, 79, 82, 80, 78, 76, 74, 78, 81, 83, 85)
                               ),
                               "range" = switch(input$ev_vehicle_type,
                                                "all" = c(385, 392, 398, 405, 400, 395, 388, 382, 395, 402, 408, 415),
                                                "cars" = c(420, 428, 435, 442, 438, 432, 425, 418, 432, 440, 447, 455),
                                                "vans" = c(280, 285, 290, 295, 292, 288, 282, 278, 288, 294, 298, 305),
                                                "buses" = c(180, 185, 190, 195, 192, 188, 182, 178, 188, 194, 198, 205)
                               ),
                               "charging" = switch(input$ev_vehicle_type,
                                                   "all" = c(45, 47, 49, 52, 50, 48, 46, 44, 48, 51, 53, 55),
                                                   "cars" = c(50, 52, 54, 57, 55, 53, 51, 49, 53, 56, 58, 60),
                                                   "vans" = c(35, 37, 39, 42, 40, 38, 36, 34, 38, 41, 43, 45),
                                                   "buses" = c(120, 125, 130, 135, 132, 128, 122, 118, 128, 134, 138, 145)
                               )
    )
    
    ev_data <- data.frame(months, performance = performance_data)
    
    y_label <- switch(input$ev_metric, 
                      "battery" = "Efficiency (%)", 
                      "range" = "Range (km)", 
                      "charging" = "Charging Speed (kW)")
    
    p <- ggplot(ev_data, aes(x = months, y = performance)) +
      geom_line(color = "#DDA0DD", size = 2) +
      geom_point(color = "#6C5CE7", size = 4) +
      geom_area(fill = "#DDA0DD", alpha = 0.3) +
      labs(title = paste("EV Performance -", input$ev_metric, "-", input$ev_vehicle_type), 
           x = "Month", y = y_label) +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Dynamic EV metrics
  output$ev_fleet_text <- renderText({
    fleet_val <- switch(input$ev_vehicle_type, "all" = "2.1M", "cars" = "1.8M", "vans" = "280K", "buses" = "45K")
    paste("Active EVs:", fleet_val)
  })
  
  output$ev_efficiency_text <- renderText({
    eff_val <- switch(input$ev_metric, "battery" = "87%", "range" = "402km avg", "charging" = "49kW avg")
    paste("Performance:", eff_val)
  })
  
  output$ev_utilization_text <- renderText({
    util_val <- switch(input$ev_vehicle_type, "all" = "73%", "cars" = "68%", "vans" = "82%", "buses" = "89%")
    paste("Utilization:", util_val)
  })
  
  # Complete remaining outputs for EV, Safety, and Digital tabs...
  # Adding remaining outputs to stay within response limits
  
  output$ev_charging_analysis <- renderPlotly({
    station_types <- c("Rapid", "Fast", "Slow", "Ultra-Rapid")
    
    station_data <- data.frame(
      types = station_types,
      count = c(8500, 15200, 22000, 3200),
      utilization = c(78, 65, 45, 85),
      stringsAsFactors = FALSE
    )
    
    p <- ggplot(station_data, aes(x = count, y = utilization, color = types, size = count)) +
      geom_point(alpha = 0.8) +
      scale_color_manual(values = color_palette_primary[1:4]) +
      scale_size_continuous(range = c(4, 12)) +
      labs(title = "Charging Infrastructure Analysis", 
           x = "Station Count", y = "Utilization (%)", color = "Station Type") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$ev_usage_patterns <- renderPlotly({
    hours <- 0:23
    
    usage_pattern <- switch(input$ev_vehicle_type,
                            "all" = c(12, 8, 6, 4, 5, 8, 15, 25, 35, 28, 22, 20, 25, 30, 32, 35, 45, 55, 48, 38, 32, 28, 22, 18),
                            "cars" = c(8, 5, 3, 2, 3, 6, 12, 22, 32, 25, 18, 16, 20, 25, 28, 32, 42, 52, 45, 35, 28, 24, 18, 14),
                            "vans" = c(18, 12, 8, 6, 8, 12, 22, 35, 45, 38, 32, 28, 35, 42, 45, 48, 55, 65, 58, 48, 42, 38, 32, 25),
                            "buses" = c(25, 15, 10, 8, 10, 15, 35, 55, 75, 65, 55, 45, 55, 65, 70, 75, 85, 95, 88, 75, 65, 55, 45, 35)
    )
    
    usage_data <- data.frame(hours, charging_demand = usage_pattern)
    
    p <- ggplot(usage_data, aes(x = hours, y = charging_demand)) +
      geom_area(fill = "#FF8C42", alpha = 0.7) +
      geom_line(color = "#E67E22", size = 1.5) +
      labs(title = paste("Daily Usage Pattern -", input$ev_vehicle_type), 
           x = "Hour of Day", y = "Usage Demand (%)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Safety Assurance Tab Server Logic
  output$safety_monitor <- renderPlotly({
    time_range <- switch(input$safety_timeframe, "week" = 7, "month" = 30, "quarter" = 90)
    days <- 1:time_range
    
    base_score <- switch(input$safety_vehicle_class, "all" = 9.0, "cars" = 9.2, "commercial" = 8.8, "public" = 9.4)
    
    safety_score <- base_score + 0.3 * sin(days/10) + rnorm(time_range, 0, 0.1)
    safety_score <- pmax(8.0, pmin(10.0, safety_score))
    
    safety_data <- data.frame(days, safety_score)
    
    p <- ggplot(safety_data, aes(x = days, y = safety_score)) +
      geom_line(color = "#4ECDC4", size = 2) +
      geom_point(color = "#96CEB4", size = 2) +
      geom_hline(yintercept = 9.0, color = "#FFEAA7", linetype = "dashed", size = 1) +
      geom_hline(yintercept = 8.5, color = "#FF6B6B", linetype = "dashed", size = 1) +
      labs(title = paste("Safety Score Trend -", input$safety_timeframe), 
           x = "Time Period", y = "Safety Score") +
      scale_y_continuous(limits = c(8.0, 10.0)) +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Dynamic safety metrics
  output$safety_score_text <- renderText({
    score_val <- switch(input$safety_vehicle_class, "all" = "9.1/10", "cars" = "9.3/10", "commercial" = "8.9/10", "public" = "9.5/10")
    paste("Safety Score:", score_val)
  })
  
  output$safety_incidents_text <- renderText({
    incident_val <- switch(input$safety_timeframe, "week" = "0.01/1000km", "month" = "0.02/1000km", "quarter" = "0.06/1000km")
    paste("Incident Rate:", incident_val)
  })
  
  output$safety_compliance_text <- renderText({
    compliance_val <- switch(input$safety_vehicle_class, "all" = "99.2%", "cars" = "99.4%", "commercial" = "98.8%", "public" = "99.6%")
    paste("Compliance:", compliance_val)
  })
  
  output$safety_incidents_chart <- renderPlotly({
    incident_data <- data.frame(
      types = c("Near Miss", "System Alert", "Weather Event", "Infrastructure", "User Error"),
      count = c(15, 32, 8, 5, 12),
      severity = c(3, 2, 4, 6, 3),
      stringsAsFactors = FALSE
    )
    
    p <- ggplot(incident_data, aes(x = count, y = severity, color = types, size = count)) +
      geom_point(alpha = 0.8) +
      scale_color_manual(values = color_palette_secondary[1:5]) +
      scale_size_continuous(range = c(4, 10)) +
      labs(title = "Incident Analysis", x = "Incident Count", y = "Severity (1-10)", color = "Incident Type") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$safety_compliance_chart <- renderPlotly({
    standards <- c("ISO 26262", "UNECE R157", "BS 8599", "IEC 61508", "ISO 21448")
    compliance_data <- c(98, 95, 99, 97, 94)
    
    compliance_df <- data.frame(standards, compliance = compliance_data, stringsAsFactors = FALSE)
    
    p <- ggplot(compliance_df, aes(x = reorder(standards, compliance), y = compliance, fill = standards)) +
      geom_col() +
      scale_fill_manual(values = color_palette_primary[1:5]) +
      coord_flip() +
      labs(title = "Regulatory Compliance Status", x = "Standard", y = "Compliance (%)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  # Digital Infrastructure Tab Server Logic
  output$digital_coverage <- renderPlotly({
    technologies <- c("4G", "5G", "Edge Computing", "Fiber Optic")
    coverage_data <- c(95, 84, 65, 88)
    
    coverage_df <- data.frame(tech = technologies, coverage = coverage_data, stringsAsFactors = FALSE)
    
    p <- ggplot(coverage_df, aes(x = tech, y = coverage, fill = tech)) +
      geom_col() +
      scale_fill_manual(values = color_palette_primary[1:4]) +
      labs(title = paste("Digital Infrastructure Coverage -", input$digital_technology), 
           x = "Technology", y = "Coverage (%)") +
      theme_minimal() +
      theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Dynamic digital metrics
  output$digital_coverage_text <- renderText({
    coverage_val <- switch(input$digital_technology, "5g" = "84%", "edge" = "72%", "twins" = "68%")
    paste("Coverage:", coverage_val)
  })
  
  output$digital_latency_text <- renderText({
    latency_val <- switch(input$digital_region_type, "all" = "8ms", "urban" = "5ms", "rural" = "15ms", "highways" = "10ms")
    paste("Avg Latency:", latency_val)
  })
  
  output$digital_capacity_text <- renderText({
    capacity_val <- switch(input$digital_technology, "5g" = "450 nodes", "edge" = "280 nodes", "twins" = "125 systems")
    paste("Capacity:", capacity_val)
  })
  
  output$digital_performance <- renderPlotly({
    hours <- 0:23
    
    base_latency <- switch(input$digital_region_type, "all" = 8, "urban" = 5, "rural" = 15, "highways" = 10)
    tech_modifier <- switch(input$digital_technology, "5g" = 1.0, "edge" = 0.7, "twins" = 1.2)
    
    latency <- base_latency * tech_modifier + 2 * sin(hours/4) + rnorm(24, 0, 0.5)
    throughput <- 95 - 8 * sin(hours/6) + rnorm(24, 0, 2)
    
    perf_data <- data.frame(hours, latency, throughput)
    
    p <- ggplot(perf_data) +
      geom_line(aes(x = hours, y = latency, color = "Latency"), size = 1.5) +
      geom_line(aes(x = hours, y = throughput/10, color = "Throughput"), size = 1.5) +
      scale_color_manual(values = c("Latency" = "#FF6B6B", "Throughput" = "#45B7D1")) +
      labs(title = "24h Performance Profile", x = "Hour", y = "Performance Metrics") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$digital_twin_maturity <- renderPlotly({
    systems <- c("Traffic Mgmt", "Energy Grid", "Transport Hubs", "Vehicle Fleet", "Infrastructure")
    
    maturity_data <- data.frame(
      systems = systems,
      digital_maturity = c(85, 72, 88, 78, 65),
      integration = c(88, 75, 92, 82, 68),
      stringsAsFactors = FALSE
    )
    
    p <- ggplot(maturity_data, aes(x = digital_maturity, y = integration, color = systems, size = digital_maturity)) +
      geom_point(alpha = 0.8) +
      scale_color_manual(values = color_palette_secondary[1:5]) +
      scale_size_continuous(range = c(4, 10)) +
      labs(title = "Digital Twin Maturity vs Integration", 
           x = "Digital Maturity (%)", y = "Integration Level (%)", color = "System") +
      theme_minimal()
    
    ggplotly(p)
  })
}

# Run the application
shinyApp(ui = ui, server = server)