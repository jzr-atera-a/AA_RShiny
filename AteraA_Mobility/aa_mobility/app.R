#renv::init()

# Install the specific version
#renv::install("bigrquery@1.4.0")

# Take a snapshot
#renv::snapshot()

# Complete CCAV Cohort Event Interactive Dashboard 

library(shiny)
library(shinydashboard)
library(visNetwork)
library(reshape2)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
  
ui <- dashboardPage(title = "Atera Analytics Mobility Profiling",
  dashboardHeader(
    title = div(
      img(src = "logo.jpeg", height = "40px", style = "margin-right: 10px;"),
      "Mobility Profiling"
    )
  ),
    
    
    dashboardSidebar(
      sidebarMenu(
        menuItem("AV Act Implementation", tabName = "av_act", icon = icon("gavel")),
        menuItem("CAM Pathfinder", tabName = "pathfinder", icon = icon("route")),
        menuItem("Mass Transit", tabName = "mass_transit", icon = icon("bus")),
        menuItem("Standards & Safety", tabName = "standards", icon = icon("shield-alt")),
        menuItem("Horizon Europe", tabName = "horizon", icon = icon("globe-europe")),
        menuItem("Industry Innovation", tabName = "innovation", icon = icon("lightbulb")),
        menuItem("Company Alignment", tabName = "company", icon = icon("building")),
        menuItem("Silverstone Opportunity", tabName = "silverstone", icon = icon("flag-checkered"))
      )
    ),
    
    dashboardBody(
      tags$head(
        tags$style(HTML("
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
        
        .reference-box {
          background: #f8f9fa;
          border: 1px solid #dee2e6;
          border-radius: 8px;
          padding: 15px;
          margin: 20px 0;
          font-size: 0.9em;
          color: #495057;
        }
        
        .reference-box h5 {
          color: #00A39A;
          margin-bottom: 10px;
          font-weight: bold;
        }
      "))
      ),
      
      tabItems(
        # AV Act Implementation Tab
        tabItem(tabName = "av_act",
                fluidRow(
                  box(width = 12, status = "primary", solidHeader = TRUE,
                      title = "Automated Vehicles Act 2024 Implementation",
                      h4("Overview:"),
                      p("The Automated Vehicles Act 2024 establishes the regulatory framework for self-driving vehicles in the UK, covering safety requirements, liability frameworks, licensing of automated passenger services, and misleading marketing prevention.")
                  )
                ),
                fluidRow(
                  box(width = 6, status = "success", solidHeader = TRUE,
                      title = "Implementation Timeline", plotlyOutput("av_timeline")
                  ),
                  box(width = 6, status = "info", solidHeader = TRUE,
                      title = "Key Components", plotlyOutput("av_components")
                  )
                ),
                fluidRow(
                  box(width = 12, status = "warning", solidHeader = TRUE,
                      title = "Regulatory Process Flow", visNetworkOutput("av_process_flow")
                  )
                ),
                fluidRow(
                  box(width = 12,
                      h5("References:"),
                      p("Law Commissions of England, Wales and Scotland. (2022). Automated Vehicles: A Joint Preliminary Consultation Paper. London: Law Commission."),
                      p("Department for Transport. (2024). Automated Vehicles Act 2024: Implementation Guidance. London: HMSO."),
                      p("Available at: https://www.legislation.gov.uk/ukpga/2024/10/contents")
                  )
                )
        ),
        
        # CAM Pathfinder Tab
        tabItem(tabName = "pathfinder",
                fluidRow(
                  box(width = 12, status = "primary", solidHeader = TRUE,
                      title = "CAM Pathfinder Programme",
                      h4("Overview:"),
                      p("The CAM Pathfinder provides £8M funding to enhance Commercialising CAM offerings, supporting autonomy-ready vehicle platforms and early commercialization opportunities.")
                  )
                ),
                fluidRow(
                  box(width = 6, status = "success", solidHeader = TRUE,
                      title = "Funding Distribution",
                      selectInput("funding_view", "Select View:", choices = c("By Category", "By Project Size")),
                      plotlyOutput("funding_chart")
                  ),
                  box(width = 6, status = "info", solidHeader = TRUE,
                      title = "Project Eligibility",
                      radioButtons("project_type", "Project Type:", choices = c("Enhancement (£1M max)", "Feasibility (£250K max)")),
                      plotlyOutput("eligibility_chart")
                  )
                ),
                fluidRow(
                  box(width = 12, status = "warning", solidHeader = TRUE,
                      title = "Pathfinder Roadmap", plotlyOutput("pathfinder_roadmap")
                  )
                ),
                fluidRow(
                  box(width = 12,
                      h5("References:"),
                      p("Innovate UK. (2024). CAM Pathfinder Programme Guidelines. Swindon: UKRI."),
                      p("CCAV. (2024). Commercialising Connected and Automated Mobility Strategy. London: Department for Transport."),
                      p("Available at: https://www.gov.uk/government/collections/centre-for-connected-and-autonomous-vehicles")
                  )
                )
        ),
        
        # Mass Transit Tab
        tabItem(tabName = "mass_transit",
                fluidRow(
                  box(width = 12, status = "primary", solidHeader = TRUE,
                      title = "CAM Mass Transit Feasibility Studies",
                      h4("Overview:"),
                      p("Mass transit feasibility studies explore CAM solutions for underserved routes, addressing gaps from historical railway closures through passenger services on segregated infrastructure.")
                  )
                ),
                fluidRow(
                  box(width = 8, status = "success", solidHeader = TRUE,
                      title = "Project Locations", 
                      div(style = "height: 400px; background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 5px; padding: 20px;",
                          h5("UK Mass Transit Projects"),
                          tags$ul(
                            tags$li(strong("Cambridge CART:"), " Active - Newmarket to Airport (Park & Ride)"),
                            tags$li(strong("Milton Keynes AVRT:"), " Planning - 25-30km radius (Urban Corridors)"),
                            tags$li(strong("Scottish Highlands CAV:"), " Active - Inverness-Skye (Rural Connectivity)"),
                            tags$li(strong("Bolton Dromos:"), " Development - Railway corridor (Hospital Access)"),
                            tags$li(strong("Birmingham Shuttle:"), " Active - East Birmingham Hub (Transport Hub)")
                          )
                      )
                  ),
                  box(width = 4, status = "info", solidHeader = TRUE,
                      title = "Project Statistics",
                      selectInput("competition_filter", "Competition:", choices = c("All", "Competition 1", "Competition 2")),
                      plotlyOutput("project_stats")
                  )
                ),
                fluidRow(
                  box(width = 12, status = "warning", solidHeader = TRUE,
                      title = "Project Details", DT::dataTableOutput("project_table")
                  )
                ),
                fluidRow(
                  box(width = 12,
                      h5("References:"),
                      p("Department for Transport. (2024). Mass Transit Feasibility Studies: CAM Solutions for Underserved Routes. London: DfT."),
                      p("Transport for the North. (2024). Connected and Autonomous Mobility in Mass Transit. Leeds: TfN."),
                      p("Available at: https://www.gov.uk/government/publications/connected-and-automated-mobility-2025")
                  )
                )
        ),
        
        # Standards & Safety Tab
        tabItem(tabName = "standards",
                fluidRow(
                  box(width = 12, status = "primary", solidHeader = TRUE,
                      title = "Standards & Safety Framework",
                      h4("Overview:"),
                      p("BSI and IMechE lead standards development including BSI Flex 1888 for Minimal Risk Events and Formula Student AI competitions, ensuring safety and international harmonization.")
                  )
                ),
                fluidRow(
                  box(width = 6, status = "success", solidHeader = TRUE,
                      title = "Standards Evolution", plotlyOutput("standards_timeline")
                  ),
                  box(width = 6, status = "info", solidHeader = TRUE,
                      title = "Safety Components", plotlyOutput("safety_components")
                  )
                ),
                fluidRow(
                  box(width = 6, status = "warning", solidHeader = TRUE,
                      title = "International Downloads",
                      sliderInput("countries_slider", "Countries Threshold:", min = 10, max = 55, value = 25),
                      plotlyOutput("downloads_chart")
                  ),
                  box(width = 6, status = "success", solidHeader = TRUE,
                      title = "Formula Student AI Growth", plotlyOutput("formula_growth")
                  )
                ),
                fluidRow(
                  box(width = 12,
                      h5("References:"),
                      p("BSI Group. (2024). BSI Flex 1888: Minimal Risk Events for Autonomous Vehicles. London: British Standards Institution."),
                      p("Institution of Mechanical Engineers. (2024). Formula Student Artificial Intelligence Competition Framework. London: IMechE."),
                      p("Available at: https://www.bsigroup.com/en-GB/CAV/")
                  )
                )
        ),
        
        # Horizon Europe Tab
        tabItem(tabName = "horizon",
                fluidRow(
                  box(width = 12, status = "primary", solidHeader = TRUE,
                      title = "Horizon Europe CCAM Opportunities",
                      h4("Overview:"),
                      p("Horizon Europe offers £81bn funding for 2021-27, with CCAM as Co-Programmed Partnership. UK participation enables coordination and funding access with six draft topics opening April 2025.")
                  )
                ),
                fluidRow(
                  box(width = 6, status = "success", solidHeader = TRUE,
                      title = "Topic Funding Distribution", plotlyOutput("horizon_funding")
                  ),
                  box(width = 6, status = "info", solidHeader = TRUE,
                      title = "Partnership Benefits",
                      checkboxGroupInput("benefits_filter", "Select Benefits:",
                                         choices = c("Early Topic Access", "Partnership Drafting", "Network Building", "Commercial Opportunities"),
                                         selected = c("Early Topic Access", "Network Building")),
                      plotlyOutput("benefits_chart")
                  )
                ),
                fluidRow(
                  box(width = 12, status = "warning", solidHeader = TRUE,
                      title = "CCAM Partnership Network", visNetworkOutput("partnership_network")
                  )
                ),
                fluidRow(
                  box(width = 12,
                      h5("References:"),
                      p("European Commission. (2024). Horizon Europe Programme Guide. Brussels: Publications Office of the European Union."),
                      p("CCAM Partnership. (2024). Connected, Cooperative and Automated Mobility Strategic Research and Innovation Agenda. Brussels: CCAM Association."),
                      p("Available at: https://ec.europa.eu/info/research-and-innovation/funding/funding-opportunities/funding-programmes-and-open-calls/horizon-europe_en")
                  )
                )
        ),
        
        # Industry Innovation Tab
        tabItem(tabName = "innovation",
                fluidRow(
                  box(width = 12, status = "primary", solidHeader = TRUE,
                      title = "Industry Innovation & Testing Infrastructure",
                      h4("Overview:"),
                      p("Zenzic champions UK CAM ecosystem through £66M Commercialising CAM programme, expanding testbed network including Catesby Tunnel, Teesside Freeport, and NICCAL.")
                  )
                ),
                fluidRow(
                  box(width = 6, status = "success", solidHeader = TRUE,
                      title = "Testbed Capabilities",
                      selectInput("testbed_select", "Select Testbed:", choices = c("Catesby Tunnel", "Teesside Freeport", "NICCAL Port")),
                      plotlyOutput("testbed_capabilities")
                  ),
                  box(width = 6, status = "info", solidHeader = TRUE,
                      title = "Scale-Up Companies", plotlyOutput("scaleup_companies")
                  )
                ),
                fluidRow(
                  box(width = 8, status = "warning", solidHeader = TRUE,
                      title = "UK CAM Supply Chain", plotlyOutput("supply_chain")
                  ),
                  box(width = 4, status = "success", solidHeader = TRUE,
                      title = "Investment Targets",
                      numericInput("target_year", "Target Year:", value = 2030, min = 2025, max = 2035),
                      plotlyOutput("investment_targets")
                  )
                ),
                fluidRow(
                  box(width = 12,
                      h5("References:"),
                      p("Zenzic. (2024). UK Connected and Automated Mobility Roadmap to 2035. Milton Keynes: Zenzic."),
                      p("Innovate UK. (2024). Commercialising CAM Programme Annual Report. Swindon: UKRI."),
                      p("Available at: https://zenzic.io/")
                  )
                )
        ),
        
        # Company Alignment Tab
        tabItem(tabName = "company",
                fluidRow(
                  box(width = 12, status = "primary", solidHeader = TRUE,
                      title = "Your Company's Strategic Alignment with CCAV Programme",
                      h4("Overview:"),
                      p("Your AI-driven platform addresses the £311.20bn sustainable transport market with GIS modelling, autonomous vehicle assessment, and route planning, managing 80,000+ UK charging points.")
                  )
                ),
                fluidRow(
                  box(width = 6, status = "success", solidHeader = TRUE,
                      title = "Technology Alignment Matrix", plotlyOutput("alignment_matrix")
                  ),
                  box(width = 6, status = "info", solidHeader = TRUE,
                      title = "Market Opportunity",
                      selectInput("market_segment", "Market Segment:", 
                                  choices = c("EV Infrastructure", "Autonomous Vehicles", "Mass Transit", "Fleet Operations")),
                      plotlyOutput("market_opportunity")
                  )
                ),
                fluidRow(
                  box(width = 8, status = "warning", solidHeader = TRUE,
                      title = "CCAV Programme Synergies", plotlyOutput("programme_synergies")
                  ),
                  box(width = 4, status = "success", solidHeader = TRUE,
                      title = "Climate Impact Projections",
                      sliderInput("impact_year", "Projection Year:", min = 2025, max = 2030, value = 2028),
                      plotlyOutput("climate_impact")
                  )
                ),
                fluidRow(
                  box(width = 12,
                      h5("Strategic Recommendations:"),
                      tags$ul(
                        tags$li("Engage with CAM Pathfinder feasibility studies for AI-powered route optimization"),
                        tags$li("Collaborate with mass transit projects requiring intelligent infrastructure assessment"),
                        tags$li("Participate in Horizon Europe CCAM partnerships for international expansion"),
                        tags$li("Leverage Zenzic testbed network for autonomous vehicle infrastructure validation")
                      )
                  )
                )
        ),
        
        # Silverstone Opportunity Tab
        tabItem(tabName = "silverstone",
                fluidRow(
                  box(width = 12, status = "primary", solidHeader = TRUE,
                      title = "Silverstone Circuit Testing Opportunities",
                      h4("Overview:"),
                      p("Silverstone offers controlled environment for AV and EV testing. Your AI platform's route optimization, energy forecasting, and infrastructure assessment align with circuit-based validation.")
                  )
                ),
                fluidRow(
                  box(width = 6, status = "success", solidHeader = TRUE,
                      title = "Testing Scenarios",
                      selectInput("test_scenario", "Select Scenario:", 
                                  choices = c("AV Route Optimization", "EV Charging Strategy", "Predictive Maintenance", "Energy Grid Integration")),
                      plotlyOutput("testing_scenarios")
                  ),
                  box(width = 6, status = "info", solidHeader = TRUE,
                      title = "Technology Applications", plotlyOutput("tech_applications")
                  )
                ),
                fluidRow(
                  box(width = 8, status = "warning", solidHeader = TRUE,
                      title = "Circuit Infrastructure Overview",
                      div(style = "height: 400px; background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 5px; padding: 20px;",
                          h5("Silverstone Testing Facilities"),
                          tags$ul(
                            tags$li(strong("Main Circuit:"), " 5.9km track for high-speed AV testing"),
                            tags$li(strong("Pit Lane:"), " Advanced telemetry and data collection"),
                            tags$li(strong("Formula Student Area:"), " Dedicated autonomous vehicle testing zone"),
                            tags$li(strong("EV Charging Stations:"), " Grid integration and charging optimization testing"),
                            tags$li(strong("Technology Centre:"), " Research and development facilities")
                          ),
                          br(),
                          p(strong("Location:"), " Silverstone, Northamptonshire, UK"),
                          p(strong("Coordinates:"), " 52.0786°N, 1.0169°W")
                      )
                  ),
                  box(width = 4, status = "success", solidHeader = TRUE,
                      title = "Validation Metrics",
                      checkboxGroupInput("metrics_select", "Key Metrics:",
                                         choices = c("Route Efficiency", "Energy Consumption", "Safety Parameters", "Charging Optimization"),
                                         selected = c("Route Efficiency", "Energy Consumption")),
                      plotlyOutput("validation_metrics")
                  )
                ),
                fluidRow(
                  box(width = 12,
                      h5("References:"),
                      p("Silverstone Circuit. (2024). Automotive Technology and Innovation Centre. Towcester: Silverstone Park."),
                      p("Motorsport UK. (2024). Future Technologies in Motorsport Strategy. Colnbrook: Motor Sports Association."),
                      p("Available at: https://www.silverstone.co.uk/")
                  )
                )
        )
      )
    )
  )
  
  # Define Server with ALL functions
  server <- function(input, output, session) {
    
    # Rich color palettes for charts
    rich_colors <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf")
    blue_palette <- c("#0d47a1", "#1565c0", "#1976d2", "#1e88e5", "#2196f3", "#42a5f5", "#64b5f6", "#90caf9")
    green_palette <- c("#1b5e20", "#2e7d32", "#388e3c", "#43a047", "#4caf50", "#66bb6a", "#81c784", "#a5d6a7")
    teal_palette <- c("#004d40", "#00695c", "#00796b", "#00897b", "#009688", "#26a69a", "#4db6ac", "#80cbc4")
    navy_palette <- c("#0f172a", "#1e293b", "#334155", "#475569", "#64748b", "#94a3b8", "#cbd5e1", "#e2e8f0")
    
    # AV Act Implementation
    output$av_timeline <- renderPlotly({
      timeline_data <- data.frame(
        Year = c("2024", "2025", "2026", "2027", "2028"),
        Consultation = c(2, 4, 2, 1, 0),
        Legislation = c(1, 2, 3, 1, 0),
        Implementation = c(0, 1, 2, 4, 3)
      )
      p <- ggplot(timeline_data, aes(x = Year)) +
        geom_line(aes(y = Consultation, color = "Consultation"), linewidth = 1.5, group = 1) +
        geom_line(aes(y = Legislation, color = "Legislation"), linewidth = 1.5, group = 1) +
        geom_line(aes(y = Implementation, color = "Implementation"), linewidth = 1.5, group = 1) +
        geom_point(aes(y = Consultation, color = "Consultation"), size = 3) +
        geom_point(aes(y = Legislation, color = "Legislation"), size = 3) +
        geom_point(aes(y = Implementation, color = "Implementation"), size = 3) +
        labs(title = "AV Act Implementation Timeline", y = "Activities") +
        scale_color_manual(values = c("Consultation" = "#1565c0", "Legislation" = "#2e7d32", "Implementation" = "#d32f2f")) +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$av_components <- renderPlotly({
      components_data <- data.frame(
        Component = c("Safety", "Liability", "Marketing", "Licensing", "ASDE", "NUICO"),
        Priority = c(95, 85, 70, 80, 75, 65)
      )
      p <- ggplot(components_data, aes(x = reorder(Component, Priority), y = Priority)) +
        geom_col(fill = blue_palette[1:6]) + coord_flip() +
        labs(title = "AV Act Components Priority", x = "Component", y = "Priority (%)") +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$av_process_flow <- renderVisNetwork({
      nodes <- data.frame(id = 1:6, 
                          label = c("Consultation", "Legislation", "UN Regulations", "Implementation", "Safety Principles", "Main Regulations"),
                          color = c("#1565c0", "#2e7d32", "#d32f2f", "#ff9800", "#9c27b0", "#00bcd4"))
      edges <- data.frame(from = c(1,1,2,2,3,4), to = c(2,5,4,6,4,6))
      visNetwork(nodes, edges) %>% visOptions(highlightNearest = TRUE)
    })
    
    # CAM Pathfinder
    output$funding_chart <- renderPlotly({
      if(input$funding_view == "By Category") {
        funding_data <- data.frame(
          Category = c("Enhancement CR&D", "Feasibility Studies", "Extensions"),
          Amount = c(6, 2, 25)
        )
      } else {
        funding_data <- data.frame(
          Category = c("£250K Projects", "£1M Projects", "Extension Projects"),
          Amount = c(8, 6, 10)
        )
      }
      p <- ggplot(funding_data, aes(x = Category, y = Amount)) +
        geom_col(fill = green_palette[1:3]) +
        labs(title = "CAM Pathfinder Funding", y = if(input$funding_view == "By Category") "Funding (£M)" else "Project Count") +
        theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1),
                                plot.background = element_rect(fill = "white"),
                                panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$eligibility_chart <- renderPlotly({
      if(input$project_type == "Enhancement (£1M max)") {
        criteria <- data.frame(
          Criterion = c("Autonomy Ready Platforms", "Safety Driver Removal", "Early Commercialization"),
          Score = c(90, 85, 80)
        )
      } else {
        criteria <- data.frame(
          Criterion = c("Technical Concepts", "Business Case Development", "Commercial Feasibility"),
          Score = c(85, 75, 70)
        )
      }
      p <- ggplot(criteria, aes(x = Criterion, y = Score)) +
        geom_col(fill = teal_palette[1:3]) + coord_flip() +
        labs(title = "Project Eligibility Criteria", y = "Relevance Score") +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$pathfinder_roadmap <- renderPlotly({
      roadmap_data <- data.frame(
        Phase = c("Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025", "Q1 2026"),
        Enhancement = c(2, 4, 6, 6, 6),
        Feasibility = c(1, 3, 6, 8, 8),
        Extensions = c(5, 8, 12, 15, 20)
      )
      p <- ggplot(roadmap_data, aes(x = Phase)) +
        geom_line(aes(y = Enhancement, color = "Enhancement"), linewidth = 2, group = 1) +
        geom_line(aes(y = Feasibility, color = "Feasibility"), linewidth = 2, group = 1) +
        geom_line(aes(y = Extensions, color = "Extensions"), linewidth = 2, group = 1) +
        geom_point(aes(y = Enhancement, color = "Enhancement"), size = 4) +
        geom_point(aes(y = Feasibility, color = "Feasibility"), size = 4) +
        geom_point(aes(y = Extensions, color = "Extensions"), size = 4) +
        labs(title = "Pathfinder Project Roadmap", y = "Active Projects") +
        scale_color_manual(values = c("#1565c0", "#2e7d32", "#d32f2f")) +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    # Mass Transit
    output$project_stats <- renderPlotly({
      if(input$competition_filter == "Competition 1") {
        stats_data <- data.frame(Type = c("Segregated Routes", "Passenger Only"), Count = c(4, 4))
      } else if(input$competition_filter == "Competition 2") {
        stats_data <- data.frame(Type = c("Public Spaces", "Mixed Services"), Count = c(6, 6))
      } else {
        stats_data <- data.frame(Type = c("Competition 1", "Competition 2"), Count = c(4, 6))
      }
      p <- ggplot(stats_data, aes(x = Type, y = Count)) +
        geom_col(fill = c("#1565c0", "#2e7d32")) +
        labs(title = "Project Statistics", y = "Number of Projects") +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$project_table <- DT::renderDataTable({
      project_details <- data.frame(
        Project = c("Cambridge CART", "Milton Keynes AVRT", "Scottish Highlands CAV", "Bolton Dromos", "Birmingham Shuttle"),
        Competition = c("1", "1", "2", "2", "1"),
        Route = c("Newmarket to Airport", "25-30km radius", "Inverness-Skye", "Railway corridor", "East Birmingham Hub"),
        Status = c("Active", "Planning", "Active", "Development", "Active"),
        Focus = c("Park & Ride", "Urban Corridors", "Rural Connectivity", "Hospital Access", "Transport Hub")
      )
      DT::datatable(project_details, options = list(pageLength = 10))
    })
    
    # Standards & Safety
    output$standards_timeline <- renderPlotly({
      standards_data <- data.frame(
        Year = c("2020", "2021", "2022", "2023", "2024"),
        Standards = c(5, 7, 8, 9, 10),
        Downloads = c(20, 35, 45, 50, 55)
      )
      p <- ggplot(standards_data, aes(x = Year)) +
        geom_line(aes(y = Standards * 5, color = "Standards Published"), linewidth = 2, group = 1) +
        geom_line(aes(y = Downloads, color = "Countries Downloading"), linewidth = 2, group = 1) +
        geom_point(aes(y = Standards * 5, color = "Standards Published"), size = 4) +
        geom_point(aes(y = Downloads, color = "Countries Downloading"), size = 4) +
        scale_y_continuous(sec.axis = sec_axis(~./5, name = "Standards Count")) +
        labs(title = "Standards Evolution", y = "Countries", x = "Year") +
        scale_color_manual(values = c("#1565c0", "#d32f2f")) +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$safety_components <- renderPlotly({
      safety_data <- data.frame(
        Component = c("Minimal Risk Events", "Safety Case", "Virtual Testing", "In-Service Monitoring"),
        Importance = c(95, 90, 85, 80)
      )
      p <- ggplot(safety_data, aes(x = reorder(Component, Importance), y = Importance)) +
        geom_col(fill = navy_palette[1:4]) + coord_flip() +
        labs(title = "Safety Framework Components", x = "Component", y = "Importance (%)") +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$downloads_chart <- renderPlotly({
      countries_above <- input$countries_slider
      download_data <- data.frame(
        Standard = c("BSI Flex 1886", "BSI Flex 1887", "BSI Flex 1888", "Roadmap 2035"),
        Downloads = c(countries_above + 5, countries_above + 8, countries_above + 12, countries_above + 3)
      )
      p <- ggplot(download_data, aes(x = Standard, y = Downloads)) +
        geom_col(fill = blue_palette[1:4]) +
        labs(title = paste("Standards Downloads (", countries_above, "+ Countries)"), y = "Countries") +
        theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1),
                                plot.background = element_rect(fill = "white"),
                                panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$formula_growth <- renderPlotly({
      formula_data <- data.frame(
        Year = c("2022", "2023", "2024", "2025"),
        Competitors = c(150, 180, 200, 250),
        Universities = c(25, 30, 35, 45)
      )
      p <- ggplot(formula_data, aes(x = Year)) +
        geom_line(aes(y = Competitors, color = "Competitors"), linewidth = 2, group = 1) +
        geom_line(aes(y = Universities * 5, color = "Universities"), linewidth = 2, group = 1) +
        geom_point(aes(y = Competitors, color = "Competitors"), size = 4) +
        geom_point(aes(y = Universities * 5, color = "Universities"), size = 4) +
        scale_y_continuous(sec.axis = sec_axis(~./5, name = "Universities")) +
        labs(title = "Formula Student AI Growth", y = "Competitors") +
        scale_color_manual(values = c("#2e7d32", "#ff9800")) +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    # Horizon Europe
    output$horizon_funding <- renderPlotly({
      horizon_data <- data.frame(
        Topic = c("Remote Operations", "Large Demonstrations", "Environment Perception", "Human Behaviour", "Edge-AI", "Data Exchange"),
        Budget = c(6, 4.5, 4, 5, 4, 4),
        Projects = c(2, 1, 2, 1, 1, 1)
      )
      p <- ggplot(horizon_data, aes(x = reorder(Topic, Budget), y = Budget)) +
        geom_col(fill = green_palette[1:6]) + coord_flip() +
        labs(title = "Horizon Europe Topic Funding", x = "Topic", y = "Budget (€M)") +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$benefits_chart <- renderPlotly({
      if(length(input$benefits_filter) > 0) {
        benefits_data <- data.frame(
          Benefit = input$benefits_filter,
          Impact = c(90, 85, 80, 75)[1:length(input$benefits_filter)]
        )
        p <- ggplot(benefits_data, aes(x = Benefit, y = Impact)) +
          geom_col(fill = teal_palette[1:length(input$benefits_filter)]) +
          labs(title = "Partnership Benefits Impact", y = "Impact Score") +
          theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1),
                                  plot.background = element_rect(fill = "white"),
                                  panel.background = element_rect(fill = "white"))
        ggplotly(p)
      } else {
        ggplotly(ggplot() + theme_void())
      }
    })
    
    output$partnership_network <- renderVisNetwork({
      nodes <- data.frame(
        id = 1:8,
        label = c("UK", "Germany", "France", "Netherlands", "Sweden", "Industry", "Academia", "CCAM Partnership"),
        color = c("#1565c0", "#2e7d32", "#d32f2f", "#ff9800", "#9c27b0", "#00bcd4", "#795548", "#607d8b"),
        size = c(30, 25, 25, 20, 20, 35, 30, 40)
      )
      edges <- data.frame(
        from = c(8,8,8,8,8,8,8,1,2,3,4,5),
        to = c(1,2,3,4,5,6,7,6,6,6,6,6)
      )
      visNetwork(nodes, edges) %>% 
        visOptions(highlightNearest = TRUE) %>%
        visPhysics(stabilization = FALSE)
    })
    
    # Industry Innovation
    output$testbed_capabilities <- renderPlotly({
      testbed_data <- switch(input$testbed_select,
                             "Catesby Tunnel" = data.frame(
                               Capability = c("Aerodynamics", "High Speed", "Controlled Environment", "Repeatable Tests"),
                               Score = c(95, 90, 100, 95)
                             ),
                             "Teesside Freeport" = data.frame(
                               Capability = c("5G Network", "Airport Access", "International Border", "Logistics"),
                               Score = c(90, 85, 95, 88)
                             ),
                             "NICCAL Port" = data.frame(
                               Capability = c("Port Operations", "5G Test Track", "Controlled Environment", "Investment Zone"),
                               Score = c(92, 87, 90, 85)
                             )
      )
      
      p <- ggplot(testbed_data, aes(x = reorder(Capability, Score), y = Score)) +
        geom_col(fill = navy_palette[1:4]) + coord_flip() +
        labs(title = paste(input$testbed_select, "Capabilities"), x = "Capability", y = "Score") +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$scaleup_companies <- renderPlotly({
      scaleup_data <- data.frame(
        Sector = c("Autonomous Vehicles", "EV Infrastructure", "Data Analytics", "Safety Systems", "Connectivity"),
        Companies = c(8, 6, 5, 4, 3)
      )
      p <- ggplot(scaleup_data, aes(x = reorder(Sector, Companies), y = Companies)) +
        geom_col(fill = blue_palette[1:5]) + 
        coord_flip() +
        labs(title = "CAM Scale-Up Companies by Sector", x = "Sector", y = "Number of Companies") +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$supply_chain <- renderPlotly({
      supply_data <- data.frame(
        Category = c("Research & Tech", "Finance & Tools", "Hardware", "Software", "Engineering Services", "Test Services", "Communications", "Operators"),
        Percentage = c(15, 12, 18, 20, 10, 8, 9, 8)
      )
      p <- ggplot(supply_data, aes(x = reorder(Category, Percentage), y = Percentage)) +
        geom_col(fill = rich_colors[1:8]) + coord_flip() +
        labs(title = "UK CAM Supply Chain Distribution", x = "Category", y = "Percentage (%)") +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$investment_targets <- renderPlotly({
      years_diff <- input$target_year - 2024
      investment_data <- data.frame(
        Year = seq(2024, input$target_year, by = 1),
        Investment = seq(66, 66 + years_diff * 15, by = 15)
      )
      p <- ggplot(investment_data, aes(x = Year, y = Investment)) +
        geom_line(color = "#1565c0", linewidth = 2) +
        geom_point(color = "#d32f2f", size = 4) +
        geom_area(alpha = 0.3, fill = "#2e7d32") +
        labs(title = "Investment Targets", y = "Investment (£M)") +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    # Company Alignment
    output$alignment_matrix <- renderPlotly({
      alignment_data <- data.frame(
        CCAV_Area = c("AV Act Implementation", "CAM Pathfinder", "Mass Transit", "Standards", "Horizon Europe", "Innovation"),
        Company_Capability = c("Regulatory Compliance", "AI Route Planning", "GIS Infrastructure", "Safety Assessment", "International Partnerships", "Technology Validation"),
        Alignment_Score = c(85, 95, 90, 80, 75, 88)
      )
      p <- ggplot(alignment_data, aes(x = CCAV_Area, y = Alignment_Score, fill = Company_Capability)) +
        geom_col() + coord_flip() +
        labs(title = "Technology Alignment Matrix", x = "CCAV Programme Area", y = "Alignment Score (%)") +
        scale_fill_manual(values = c("#1565c0", "#2e7d32", "#d32f2f", "#ff9800", "#9c27b0", "#00bcd4")) +
        theme_minimal() + theme(legend.position = "bottom",
                                plot.background = element_rect(fill = "white"),
                                panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$market_opportunity <- renderPlotly({
      market_data <- switch(input$market_segment,
                            "EV Infrastructure" = data.frame(
                              Metric = c("Market Size 2024", "Market Size 2030", "Growth Rate", "Your Capability"),
                              Value = c(15.2, 45.8, 20.1, 85)
                            ),
                            "Autonomous Vehicles" = data.frame(
                              Metric = c("Market Size 2024", "Market Size 2030", "Growth Rate", "Your Capability"),
                              Value = c(68.1, 214.3, 19.9, 90)
                            ),
                            "Mass Transit" = data.frame(
                              Metric = c("Market Size 2024", "Market Size 2030", "Growth Rate", "Your Capability"),
                              Value = c(120.7, 311.2, 14.7, 82)
                            ),
                            "Fleet Operations" = data.frame(
                              Metric = c("Market Size 2024", "Market Size 2030", "Growth Rate", "Your Capability"),
                              Value = c(25.3, 78.4, 17.5, 88)
                            )
      )
      
      p <- ggplot(market_data, aes(x = Metric, y = Value)) +
        geom_col(fill = green_palette[1:4]) +
        labs(title = paste(input$market_segment, "Market Opportunity"), y = "Value (£B or %)") +
        theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1),
                                plot.background = element_rect(fill = "white"),
                                panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$programme_synergies <- renderPlotly({
      synergy_data <- data.frame(
        Programme = c("CAM Pathfinder", "Mass Transit Studies", "Horizon Europe", "Zenzic Testbeds", "Standards Development"),
        Your_Platform = c("AI Route Planning", "GIS Assessment", "International Expansion", "Technology Validation", "Safety Compliance"),
        Synergy_Score = c(95, 90, 85, 88, 82),
        Impact = c("High", "High", "Medium", "High", "Medium")
      )
      
      p <- ggplot(synergy_data, aes(x = reorder(Programme, Synergy_Score), y = Synergy_Score, fill = Impact)) +
        geom_col() + coord_flip() +
        labs(title = "CCAV Programme Synergies", x = "Programme", y = "Synergy Score (%)") +
        scale_fill_manual(values = c("High" = "#1565c0", "Medium" = "#2e7d32")) +
        theme_minimal() +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$climate_impact <- renderPlotly({
      impact_multiplier <- (input$impact_year - 2024) / 6
      climate_data <- data.frame(
        Metric = c("CO2 Reduction (Mt)", "EV Adoption (%)", "Energy Efficiency (%)", "Grid Integration (%)"),
        Current = c(0.34, 15, 28, 35),
        Projected = c(0.34 + (2.1 * impact_multiplier), 15 + (60 * impact_multiplier), 28 + (15 * impact_multiplier), 35 + (25 * impact_multiplier))
      )
      
      climate_long <- melt(climate_data, id.vars = "Metric")
      
      p <- ggplot(climate_long, aes(x = Metric, y = value, fill = variable)) +
        geom_col(position = "dodge") +
        labs(title = paste("Climate Impact Projections", input$impact_year), y = "Impact Value") +
        scale_fill_manual(values = c("Current" = "#ff9800", "Projected" = "#1565c0")) +
        theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1),
                                plot.background = element_rect(fill = "white"),
                                panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    # Silverstone Opportunity
    output$testing_scenarios <- renderPlotly({
      scenario_data <- switch(input$test_scenario,
                              "AV Route Optimization" = data.frame(
                                Parameter = c("Path Efficiency", "Safety Margin", "Speed Optimization", "Predictive Accuracy"),
                                Current = c(75, 85, 70, 80),
                                Target = c(90, 95, 85, 92)
                              ),
                              "EV Charging Strategy" = data.frame(
                                Parameter = c("Grid Integration", "Demand Prediction", "Energy Efficiency", "Cost Optimization"),
                                Current = c(70, 75, 82, 78),
                                Target = c(88, 90, 95, 85)
                              ),
                              "Predictive Maintenance" = data.frame(
                                Parameter = c("Failure Prediction", "Maintenance Scheduling", "Cost Reduction", "Uptime Improvement"),
                                Current = c(80, 75, 65, 85),
                                Target = c(95, 90, 80, 95)
                              ),
                              "Energy Grid Integration" = data.frame(
                                Parameter = c("Load Balancing", "Renewable Integration", "Grid Stability", "Demand Response"),
                                Current = c(72, 68, 80, 75),
                                Target = c(88, 85, 92, 88)
                              )
      )
      
      scenario_long <- melt(scenario_data, id.vars = "Parameter")
      
      p <- ggplot(scenario_long, aes(x = Parameter, y = value, fill = variable)) +
        geom_col(position = "dodge") +
        labs(title = paste(input$test_scenario, "at Silverstone"), y = "Performance (%)") +
        scale_fill_manual(values = c("Current" = "#ff9800", "Target" = "#1565c0")) +
        theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1),
                                plot.background = element_rect(fill = "white"),
                                panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$tech_applications <- renderPlotly({
      tech_data <- data.frame(
        Technology = c("GIS Mapping", "AI Route Planning", "Energy Forecasting", "Infrastructure Assessment", "Predictive Analytics"),
        Silverstone_Relevance = c(95, 90, 85, 88, 82),
        Implementation_Ease = c(80, 85, 75, 90, 78)
      )
      
      p <- ggplot(tech_data, aes(x = Silverstone_Relevance, y = Implementation_Ease, size = 10)) +
        geom_point(color = blue_palette[1:5], alpha = 0.7, size = 6) +
        geom_text(aes(label = Technology), hjust = 0, vjust = 0, size = 3, color = "#333333") +
        labs(title = "Technology Applications at Silverstone", 
             x = "Silverstone Relevance (%)", y = "Implementation Ease (%)") +
        theme_minimal() + guides(size = "none") +
        theme(plot.background = element_rect(fill = "white"),
              panel.background = element_rect(fill = "white"))
      ggplotly(p)
    })
    
    output$validation_metrics <- renderPlotly({
      if(length(input$metrics_select) > 0) {
        metrics_data <- data.frame(
          Metric = input$metrics_select,
          Baseline = c(70, 75, 85, 80)[1:length(input$metrics_select)],
          Silverstone_Target = c(90, 88, 95, 92)[1:length(input$metrics_select)]
        )
        
        metrics_long <- melt(metrics_data, id.vars = "Metric")
        
        p <- ggplot(metrics_long, aes(x = Metric, y = value, fill = variable)) +
          geom_col(position = "dodge") +
          labs(title = "Validation Metrics at Silverstone", y = "Performance (%)") +
          scale_fill_manual(values = c("Baseline" = "#ff9800", "Silverstone_Target" = "#1565c0")) +
          theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1),
                                  plot.background = element_rect(fill = "white"),
                                  panel.background = element_rect(fill = "white"))
        ggplotly(p)
      } else {
        ggplotly(ggplot() + theme_void())
      }
    })
  }
  
  # Run the application
  shinyApp(ui = ui, server = server)