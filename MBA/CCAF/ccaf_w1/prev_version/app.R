# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(visNetwork)
library(shinyWidgets)
library(shinycssloaders)

# Sample data generation for demonstration
set.seed(42)
providers <- c("AWS", "OpenAI", "Google", "Azure", "CoreWeave", "Lambda", "Meta", "Oracle OCI", "IBM", "Equinix", "Digital Realty")

# Generate sample AIEEI data
aieei_data <- data.frame(
  Provider = providers,
  CapEx_Million = runif(11, 5000, 25000),
  Capacity_MW = runif(11, 500, 2500),
  Inference_Share = runif(11, 0.2, 0.9),
  Utilization = runif(11, 0.6, 0.8),
  PUE = runif(11, 1.1, 1.3),
  GPU_Count = round(runif(11, 50000, 200000)),
  GPU_Hours_Month = round(runif(11, 1000000, 5000000)),
  Total_Tokens = round(runif(11, 1e9, 1e11)),
  Energy_kWh_Month = runif(11, 500000, 2500000),
  Carbon_Intensity = runif(11, 0.2, 0.8),
  PPA_Renewable = runif(11, 0.1, 0.9),
  Region = sample(c("North America", "Europe", "Asia-Pacific"), 11, replace = TRUE),
  stringsAsFactors = FALSE
)

# Calculate derived metrics
aieei_data$Inference_Capacity <- aieei_data$Capacity_MW * aieei_data$Inference_Share
aieei_data$Active_Power <- aieei_data$Inference_Capacity * 1000 * aieei_data$Utilization
aieei_data$Base_Energy <- aieei_data$Active_Power * 730
aieei_data$Total_Energy <- aieei_data$Base_Energy * aieei_data$PUE
aieei_data$GPU_Energy_Check <- aieei_data$GPU_Hours_Month * 0.7  # Avg 700W per GPU
aieei_data$Inference_Efficiency <- aieei_data$Total_Tokens / (aieei_data$Total_Energy * 3.6e6)

# Normalize AIEEI components
normalize_metric <- function(x) {
  clipped <- pmax(pmin(x, quantile(x, 0.95, na.rm = TRUE)), quantile(x, 0.05, na.rm = TRUE))
  (clipped - min(clipped, na.rm = TRUE)) / (max(clipped, na.rm = TRUE) - min(clipped, na.rm = TRUE))
}

aieei_data$PUE_Norm <- normalize_metric(1/aieei_data$PUE)
aieei_data$InfEff_Norm <- normalize_metric(aieei_data$Inference_Efficiency)
aieei_data$AIEEI <- 0.5 * sqrt(aieei_data$PUE_Norm) + 0.5 * sqrt(aieei_data$InfEff_Norm)

# Network data for ecosystem mapping
network_nodes <- data.frame(
  id = 1:length(providers),
  label = providers,
  group = c("Cloud", "AI Service", "Cloud", "Cloud", "Specialized", "Specialized", "Tech Giant", "Cloud", "Enterprise", "Infrastructure", "Infrastructure"),
  value = aieei_data$Capacity_MW / 100,
  title = paste("Provider:", providers, "<br>Capacity:", round(aieei_data$Capacity_MW), "MW"),
  stringsAsFactors = FALSE
)

# Generate edges for provider relationships
network_edges <- data.frame(
  from = c(2, 2, 5, 6),  # OpenAI, CoreWeave, Lambda connections
  to = c(4, 1, 10, 11),  # to Azure, AWS, Equinix, Digital Realty
  width = c(3, 2, 2, 2),
  label = c("Primary Host", "Secondary", "Hosting", "Hosting"),
  stringsAsFactors = FALSE
)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "AIEEI Analytics Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Energy Analysis", tabName = "energy", icon = icon("bolt")),
      menuItem("Provider Comparison", tabName = "comparison", icon = icon("chart-bar")),
      menuItem("Ecosystem Mapping", tabName = "ecosystem", icon = icon("network-wired")),
      menuItem("Methodology", tabName = "methodology", icon = icon("calculator"))
    )
  ),
  
  dashboardBody(
    # Custom CSS styling
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
      ")),
    
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                valueBoxOutput("total_capacity"),
                valueBoxOutput("avg_aieei"),
                valueBoxOutput("total_energy")
              ),
              
              fluidRow(
                box(title = "AIEEI Distribution by Provider", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("aieei_distribution"))
                ),
                box(title = "Energy Efficiency vs Carbon Intensity", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("efficiency_carbon"))
                )
              ),
              
              fluidRow(
                box(title = "Key Metrics Summary", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("summary_table")
                )
              )
      ),
      
      # Energy Analysis Tab
      tabItem(tabName = "energy",
              fluidRow(
                box(title = "Energy Analysis Controls", status = "primary", solidHeader = TRUE, width = 4,
                    selectInput("energy_metric", "Select Energy Metric:",
                                choices = c("Total Energy (kWh)" = "Total_Energy",
                                            "Base Energy" = "Base_Energy",
                                            "GPU Energy Check" = "GPU_Energy_Check")),
                    sliderInput("pue_range", "PUE Range:",
                                min = 1.0, max = 2.0, value = c(1.1, 1.3), step = 0.1),
                    checkboxGroupInput("regions", "Select Regions:",
                                       choices = unique(aieei_data$Region),
                                       selected = unique(aieei_data$Region))
                ),
                
                box(title = "Energy Consumption Analysis", status = "primary", solidHeader = TRUE, width = 8,
                    withSpinner(plotlyOutput("energy_analysis"))
                )
              ),
              
              fluidRow(
                box(title = "PUE vs Utilization Correlation", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("pue_utilization"))
                ),
                box(title = "Energy Validation: CapEx vs GPU-Hours Method", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("energy_validation"))
                )
              ),
              
              fluidRow(
                box(title = "Regional Energy Patterns", status = "primary", solidHeader = TRUE, width = 12,
                    withSpinner(plotlyOutput("regional_energy"))
                )
              )
      ),
      
      # Provider Comparison Tab
      tabItem(tabName = "comparison",
              fluidRow(
                box(title = "Provider Selection", status = "primary", solidHeader = TRUE, width = 3,
                    checkboxGroupInput("selected_providers", "Select Providers:",
                                       choices = providers,
                                       selected = providers[1:5]),
                    radioButtons("comparison_metric", "Comparison Metric:",
                                 choices = c("AIEEI Score" = "AIEEI",
                                             "Inference Efficiency" = "Inference_Efficiency",
                                             "Total Energy" = "Total_Energy",
                                             "Capacity" = "Capacity_MW"))
                ),
                
                box(title = "Provider Performance Comparison", status = "primary", solidHeader = TRUE, width = 9,
                    withSpinner(plotlyOutput("provider_comparison"))
                )
              ),
              
              fluidRow(
                box(title = "Multi-Metric Radar Chart", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("radar_chart"))
                ),
                box(title = "Capacity vs Energy Efficiency", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("capacity_efficiency"))
                )
              ),
              
              fluidRow(
                box(title = "Provider Rankings", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("provider_rankings")
                )
              )
      ),
      
      # Ecosystem Mapping Tab
      tabItem(tabName = "ecosystem",
              fluidRow(
                box(title = "Ecosystem Network Controls", status = "primary", solidHeader = TRUE, width = 3,
                    selectInput("network_metric", "Node Size by:",
                                choices = c("Capacity (MW)" = "Capacity_MW",
                                            "AIEEI Score" = "AIEEI",
                                            "Energy Consumption" = "Total_Energy")),
                    checkboxInput("show_dependencies", "Show Dependencies", value = TRUE),
                    sliderInput("min_capacity", "Minimum Capacity (MW):",
                                min = 0, max = 3000, value = 0, step = 100)
                ),
                
                box(title = "AI Infrastructure Ecosystem Map", status = "primary", solidHeader = TRUE, width = 9,
                    div(class = "network-container",
                        withSpinner(visNetworkOutput("ecosystem_network", height = "580px"))
                    )
                )
              ),
              
              fluidRow(
                box(title = "Provider Dependencies Matrix", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("dependency_matrix"))
                ),
                box(title = "Market Concentration Analysis", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("market_concentration"))
                )
              )
      ),
      
      # Methodology Tab
      tabItem(tabName = "methodology",
              fluidRow(
                box(title = "AIEEI Calculation Parameters", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        h4("Key Parameters"),
                        p("CapEx→MW: $10M/MW ± 20%"),
                        p("Inference Share: 20-100% ± 5%"),
                        p("Utilization: 60-70% ± 10%"),
                        p("PUE: 1.10-1.20 ± 5%"),
                        p("Hours/month: 730")
                    ),
                    
                    numericInput("capex_mw", "CapEx per MW ($M):", value = 10, min = 5, max = 20, step = 0.5),
                    sliderInput("alpha_beta", "AIEEI Weights (α, β):", 
                                min = 0, max = 1, value = c(0.5, 0.5), step = 0.1),
                    actionButton("recalculate", "Recalculate AIEEI", class = "btn-primary")
                ),
                
                box(title = "Formula Visualization", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "reference-box",
                        h5("AIEEI Calculation Steps:"),
                        p("1. Capacity = CapEx($) / ($10M/MW)"),
                        p("2. Inference Capacity = Capacity × Inference Share"),
                        p("3. Active Power = Inference Capacity × 1000 × Utilization"),
                        p("4. Base Energy = Active Power × 730h"),
                        p("5. Total Energy = Base Energy × PUE"),
                        p("6. Inference Efficiency = Tokens / (Energy × 3.6×10⁶)"),
                        p("7. AIEEI = α√(Norm(1/PUE)) + β√(Norm(InfEff))")
                    ),
                    withSpinner(plotlyOutput("formula_flow"))
                )
              ),
              
              fluidRow(
                box(title = "Sensitivity Analysis", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("sensitivity_analysis"))
                ),
                box(title = "Parameter Impact on AIEEI", status = "primary", solidHeader = TRUE, width = 6,
                    withSpinner(plotlyOutput("parameter_impact"))
                )
              ),
              
              fluidRow(
                box(title = "Data Quality Assessment", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("data_quality")
                )
              )
      )
    )
  ),
  skin = "blue"
)

# Server
server <- function(input, output, session) {
  
  # Reactive data based on filters
  filtered_data <- reactive({
    data <- aieei_data
    
    if("regions" %in% names(input) && !is.null(input$regions)) {
      data <- data[data$Region %in% input$regions, ]
    }
    
    if("pue_range" %in% names(input)) {
      data <- data[data$PUE >= input$pue_range[1] & data$PUE <= input$pue_range[2], ]
    }
    
    if("min_capacity" %in% names(input)) {
      data <- data[data$Capacity_MW >= input$min_capacity, ]
    }
    
    data
  })
  
  # Value boxes
  output$total_capacity <- renderValueBox({
    valueBox(
      value = paste0(round(sum(aieei_data$Capacity_MW)/1000, 1), "GW"),
      subtitle = "Total Infrastructure Capacity",
      icon = icon("server"),
      color = "green"
    )
  })
  
  output$avg_aieei <- renderValueBox({
    valueBox(
      value = round(mean(aieei_data$AIEEI), 3),
      subtitle = "Average AIEEI Score",
      icon = icon("chart-line"),
      color = "blue"
    )
  })
  
  output$total_energy <- renderValueBox({
    valueBox(
      value = paste0(round(sum(aieei_data$Total_Energy)/1e6, 1), "TWh"),
      subtitle = "Total Monthly Energy",
      icon = icon("bolt"),
      color = "yellow"
    )
  })
  
  # Overview plots
  output$aieei_distribution <- renderPlotly({
    p <- ggplot(aieei_data, aes(x = reorder(Provider, AIEEI), y = AIEEI, fill = Region)) +
      geom_col() +
      coord_flip() +
      scale_fill_manual(values = c("#008A82", "#00A39A", "#002C3C")) +
      labs(title = "AIEEI Scores by Provider", x = "Provider", y = "AIEEI Score") +
      theme_minimal()
    
    ggplotly(p, tooltip = c("x", "y", "fill"))
  })
  
  output$efficiency_carbon <- renderPlotly({
    p <- ggplot(aieei_data, aes(x = Inference_Efficiency, y = Carbon_Intensity, 
                                size = Capacity_MW, color = Provider)) +
      geom_point(alpha = 0.7) +
      scale_color_manual(values = rainbow(11)) +
      labs(title = "Efficiency vs Carbon Intensity", 
           x = "Inference Efficiency (tokens/kWh)", 
           y = "Carbon Intensity") +
      theme_minimal()
    
    ggplotly(p, tooltip = c("colour", "x", "y", "size"))
  })
  
  output$summary_table <- DT::renderDataTable({
    summary_data <- aieei_data %>%
      select(Provider, AIEEI, Capacity_MW, Total_Energy, Inference_Efficiency, PUE, Region) %>%
      mutate(
        AIEEI = round(AIEEI, 3),
        Capacity_MW = round(Capacity_MW, 0),
        Total_Energy = round(Total_Energy/1000, 0),
        Inference_Efficiency = round(Inference_Efficiency, 2),
        PUE = round(PUE, 2)
      )
    
    DT::datatable(summary_data, 
                  options = list(pageLength = 11, scrollX = TRUE),
                  colnames = c("Provider", "AIEEI", "Capacity (MW)", "Energy (GWh)", "Inf. Eff.", "PUE", "Region"))
  })
  
  # Energy analysis plots
  output$energy_analysis <- renderPlotly({
    if(is.null(input$energy_metric)) return(NULL)
    
    data <- filtered_data()
    
    p <- ggplot(data, aes_string(x = "Provider", y = input$energy_metric, fill = "Region")) +
      geom_col() +
      coord_flip() +
      scale_fill_manual(values = c("#008A82", "#00A39A", "#002C3C")) +
      labs(title = paste("Energy Analysis:", input$energy_metric), 
           x = "Provider", y = input$energy_metric) +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$pue_utilization <- renderPlotly({
    p <- ggplot(aieei_data, aes(x = PUE, y = Utilization, color = Provider, size = Capacity_MW)) +
      geom_point(alpha = 0.7) +
      scale_color_manual(values = rainbow(11)) +
      labs(title = "PUE vs Utilization", x = "PUE", y = "Utilization") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$energy_validation <- renderPlotly({
    p <- ggplot(aieei_data, aes(x = Total_Energy, y = GPU_Energy_Check, color = Provider)) +
      geom_point(size = 3, alpha = 0.7) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
      scale_color_manual(values = rainbow(11)) +
      labs(title = "Energy Validation: CapEx vs GPU-Hours Method",
           x = "CapEx Method (kWh)", y = "GPU-Hours Method (kWh)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$regional_energy <- renderPlotly({
    regional_summary <- aieei_data %>%
      group_by(Region) %>%
      summarise(
        Total_Capacity = sum(Capacity_MW),
        Total_Energy = sum(Total_Energy),
        Avg_PUE = mean(PUE),
        Avg_AIEEI = mean(AIEEI),
        .groups = 'drop'
      )
    
    p <- ggplot(regional_summary, aes(x = Total_Capacity, y = Total_Energy, 
                                      size = Avg_AIEEI, color = Region)) +
      geom_point(alpha = 0.8) +
      scale_color_manual(values = c("#008A82", "#00A39A", "#002C3C")) +
      labs(title = "Regional Energy Patterns", 
           x = "Total Capacity (MW)", y = "Total Energy (kWh)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Provider comparison plots
  output$provider_comparison <- renderPlotly({
    if(is.null(input$selected_providers) || is.null(input$comparison_metric)) return(NULL)
    
    data <- aieei_data[aieei_data$Provider %in% input$selected_providers, ]
    
    p <- ggplot(data, aes_string(x = "Provider", y = input$comparison_metric, fill = "Region")) +
      geom_col() +
      coord_flip() +
      scale_fill_manual(values = c("#008A82", "#00A39A", "#002C3C")) +
      labs(title = paste("Provider Comparison:", input$comparison_metric),
           x = "Provider", y = input$comparison_metric) +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$radar_chart <- renderPlotly({
    if(is.null(input$selected_providers)) return(NULL)
    
    data <- aieei_data[aieei_data$Provider %in% input$selected_providers[1:3], ]
    
    # Normalize metrics for radar chart
    metrics <- c("AIEEI", "Inference_Efficiency", "Utilization", "PUE")
    radar_data <- data[, c("Provider", metrics)]
    
    for(metric in metrics) {
      radar_data[[metric]] <- (radar_data[[metric]] - min(aieei_data[[metric]])) / 
        (max(aieei_data[[metric]]) - min(aieei_data[[metric]]))
    }
    
    # Create radar chart using plotly
    fig <- plot_ly(type = 'scatterpolar', mode = 'lines+markers')
    
    for(i in 1:nrow(radar_data)) {
      fig <- fig %>% add_trace(
        r = as.numeric(radar_data[i, metrics]),
        theta = metrics,
        name = radar_data$Provider[i],
        line = list(color = rainbow(nrow(radar_data))[i])
      )
    }
    
    fig %>% layout(
      polar = list(
        radialaxis = list(visible = TRUE, range = c(0, 1))
      ),
      title = "Multi-Metric Comparison (Normalized)"
    )
  })
  
  output$capacity_efficiency <- renderPlotly({
    p <- ggplot(aieei_data, aes(x = Capacity_MW, y = Inference_Efficiency, 
                                color = Provider, size = AIEEI)) +
      geom_point(alpha = 0.7) +
      scale_color_manual(values = rainbow(11)) +
      labs(title = "Capacity vs Inference Efficiency",
           x = "Capacity (MW)", y = "Inference Efficiency") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$provider_rankings <- DT::renderDataTable({
    rankings <- aieei_data %>%
      arrange(desc(AIEEI)) %>%
      mutate(Rank = row_number()) %>%
      select(Rank, Provider, AIEEI, Capacity_MW, Total_Energy, Inference_Efficiency) %>%
      mutate(
        AIEEI = round(AIEEI, 3),
        Capacity_MW = round(Capacity_MW, 0),
        Total_Energy = round(Total_Energy/1000, 0),
        Inference_Efficiency = round(Inference_Efficiency, 2)
      )
    
    DT::datatable(rankings, options = list(pageLength = 11))
  })
  
  # Ecosystem mapping
  output$ecosystem_network <- renderVisNetwork({
    if(is.null(input$network_metric)) return(NULL)
    
    nodes <- network_nodes
    if(input$network_metric %in% names(aieei_data)) {
      metric_values <- aieei_data[[input$network_metric]][match(nodes$label, aieei_data$Provider)]
      nodes$value <- metric_values / max(metric_values, na.rm = TRUE) * 50
    }
    
    edges <- if(input$show_dependencies) network_edges else data.frame()
    
    visNetwork(nodes, edges) %>%
      visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
      visPhysics(enabled = FALSE) %>%
      visInteraction(navigationButtons = TRUE) %>%
      visGroups(groupname = "Cloud", color = "#008A82") %>%
      visGroups(groupname = "AI Service", color = "#00A39A") %>%
      visGroups(groupname = "Specialized", color = "#002C3C") %>%
      visGroups(groupname = "Tech Giant", color = "#7f8c8d") %>%
      visGroups(groupname = "Enterprise", color = "#e74c3c") %>%
      visGroups(groupname = "Infrastructure", color = "#f39c12") %>%
      visLegend()
  })
  
  output$dependency_matrix <- renderPlotly({
    # Create a simple dependency heatmap
    dependency_data <- expand.grid(Provider = providers, Dependent = providers)
    dependency_data$Relationship <- sample(c(0, 0.2, 0.5, 0.8, 1), nrow(dependency_data), 
                                           replace = TRUE, prob = c(0.7, 0.1, 0.1, 0.05, 0.05))
    
    p <- ggplot(dependency_data, aes(x = Provider, y = Dependent, fill = Relationship)) +
      geom_tile() +
      scale_fill_gradient(low = "white", high = "#008A82") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      labs(title = "Provider Dependencies Matrix")
    
    ggplotly(p)
  })
  
  output$market_concentration <- renderPlotly({
    concentration_data <- aieei_data %>%
      arrange(desc(Capacity_MW)) %>%
      mutate(
        Cumulative_Share = cumsum(Capacity_MW) / sum(Capacity_MW),
        Provider_Rank = row_number()
      )
    
    p <- ggplot(concentration_data, aes(x = Provider_Rank, y = Cumulative_Share)) +
      geom_line(color = "#008A82", size = 2) +
      geom_point(color = "#00A39A", size = 3) +
      geom_hline(yintercept = 0.8, linetype = "dashed", color = "red") +
      labs(title = "Market Concentration (80/20 Rule)",
           x = "Provider Rank", y = "Cumulative Market Share") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Methodology tab outputs
  output$formula_flow <- renderPlotly({
    steps <- data.frame(
      Step = 1:7,
      Value = c(100, 80, 60, 45, 50, 0.8, 0.75),
      Label = c("CapEx", "Capacity", "Inf.Cap", "Active Power", "Base Energy", "Total Energy", "AIEEI")
    )
    
    p <- ggplot(steps, aes(x = Step, y = Value, fill = Label)) +
      geom_col() +
      scale_fill_manual(values = rainbow(7)) +
      labs(title = "AIEEI Calculation Flow", x = "Calculation Step", y = "Relative Value") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$sensitivity_analysis <- renderPlotly({
    # Sensitivity analysis for key parameters
    sensitivity_data <- data.frame(
      Parameter = rep(c("CapEx/MW", "Inference Share", "Utilization", "PUE"), each = 5),
      Change = rep(c(-20, -10, 0, 10, 20), 4),
      AIEEI_Impact = c(
        c(-0.15, -0.08, 0, 0.08, 0.15),
        c(-0.12, -0.06, 0, 0.06, 0.12),  # Inference Share
        c(-0.10, -0.05, 0, 0.05, 0.10),  # Utilization
        c(0.08, 0.04, 0, -0.04, -0.08)   # PUE (inverse relationship)
      )
    )
    
    p <- ggplot(sensitivity_data, aes(x = Change, y = AIEEI_Impact, color = Parameter)) +
      geom_line(size = 1.5) +
      geom_point(size = 3) +
      scale_color_manual(values = c("#008A82", "#00A39A", "#002C3C", "#e74c3c")) +
      labs(title = "Parameter Sensitivity Analysis",
           x = "Parameter Change (%)", y = "AIEEI Impact") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$parameter_impact <- renderPlotly({
    # Create correlation matrix for parameter impacts
    params <- aieei_data[, c("Capacity_MW", "Inference_Share", "Utilization", "PUE", "AIEEI")]
    cor_matrix <- cor(params)
    
    # Convert correlation matrix to long format
    cor_data <- expand.grid(Var1 = rownames(cor_matrix), Var2 = colnames(cor_matrix))
    cor_data$Correlation <- as.vector(cor_matrix)
    
    p <- ggplot(cor_data, aes(x = Var1, y = Var2, fill = Correlation)) +
      geom_tile() +
      scale_fill_gradient2(low = "#002C3C", mid = "white", high = "#008A82", 
                           midpoint = 0, limits = c(-1, 1)) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      labs(title = "Parameter Correlation Matrix", x = "", y = "")
    
    ggplotly(p)
  })
  
  output$data_quality <- DT::renderDataTable({
    # Create data quality assessment
    quality_metrics <- aieei_data %>%
      summarise(
        Total_Providers = n(),
        Missing_Values = sum(is.na(.)),
        Min_AIEEI = round(min(AIEEI, na.rm = TRUE), 3),
        Max_AIEEI = round(max(AIEEI, na.rm = TRUE), 3),
        Std_Dev_AIEEI = round(sd(AIEEI, na.rm = TRUE), 3),
        Avg_PUE = round(mean(PUE, na.rm = TRUE), 2),
        PUE_Range = paste(round(min(PUE), 2), "-", round(max(PUE), 2)),
        Data_Completeness = paste0(round((1 - Missing_Values/(n()*ncol(.)))*100, 1), "%")
      )
    
    # Transpose for better display
    quality_display <- data.frame(
      Metric = names(quality_metrics),
      Value = as.character(unlist(quality_metrics[1,]))
    )
    
    DT::datatable(quality_display, 
                  options = list(pageLength = 10, dom = 't'),
                  colnames = c("Quality Metric", "Value"))
  })
  
  # Reactive recalculation when parameters change
  observeEvent(input$recalculate, {
    if(!is.null(input$capex_mw) && !is.null(input$alpha_beta)) {
      # Recalculate capacity with new CapEx/MW ratio
      aieei_data$Capacity_MW <<- aieei_data$CapEx_Million / input$capex_mw
      aieei_data$Inference_Capacity <<- aieei_data$Capacity_MW * aieei_data$Inference_Share
      aieei_data$Active_Power <<- aieei_data$Inference_Capacity * 1000 * aieei_data$Utilization
      aieei_data$Base_Energy <<- aieei_data$Active_Power * 730
      aieei_data$Total_Energy <<- aieei_data$Base_Energy * aieei_data$PUE
      aieei_data$Inference_Efficiency <<- aieei_data$Total_Tokens / (aieei_data$Total_Energy * 3.6e6)
      
      # Recalculate AIEEI with new weights
      alpha <- input$alpha_beta[1]
      beta <- input$alpha_beta[2]
      # Normalize beta to ensure alpha + beta = 1
      beta <- 1 - alpha
      
      aieei_data$PUE_Norm <<- normalize_metric(1/aieei_data$PUE)
      aieei_data$InfEff_Norm <<- normalize_metric(aieei_data$Inference_Efficiency)
      aieei_data$AIEEI <<- alpha * sqrt(aieei_data$PUE_Norm) + beta * sqrt(aieei_data$InfEff_Norm)
      
      showNotification("AIEEI recalculated with new parameters!", type = "success")
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)