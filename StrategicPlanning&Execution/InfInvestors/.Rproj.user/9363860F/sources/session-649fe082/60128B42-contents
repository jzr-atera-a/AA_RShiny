library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(leaflet)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "LLM Energy Benchmarking Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Model Provider Benchmarking", tabName = "provider", icon = icon("chart-line")),
      menuItem("Cross-Provider Comparison", tabName = "cross_provider", icon = icon("exchange-alt")),
      menuItem("Query Complexity Analysis", tabName = "complexity", icon = icon("brain")),
      menuItem("Hardware Perspective", tabName = "hardware", icon = icon("microchip")),
      menuItem("Cloud & Geolocation", tabName = "cloud", icon = icon("cloud")),
      menuItem("Energy Efficiency Case", tabName = "efficiency", icon = icon("leaf")),
      menuItem("Cost Optimisation Case", tabName = "cost", icon = icon("pound-sign")),
      menuItem("Sustainability Case", tabName = "sustainability", icon = icon("recycle")),
      menuItem("Regional Deployment Case", tabName = "regional", icon = icon("globe")),
      menuItem("Best Practices Case", tabName = "practices", icon = icon("star"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f5f5f5;
        }
        .box {
          background-color: #ffffff;
          border: 1px solid #d2d6de;
          border-radius: 3px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
        }
        .box-header {
          background-color: #6c757d;
          color: white;
        }
        .nav-tabs-custom > .nav-tabs > li.active > a {
          background-color: #6c757d;
          color: white;
        }
      "))
    ),
    
    tabItems(
      # Tab 1: Model Provider Benchmarking
      tabItem(tabName = "provider",
              fluidRow(
                box(
                  title = "Key Ideas: Model Provider Benchmarking", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("Standardised Testing:"), "Implement consistent inference tasks across GPT-3.5, GPT-4, and GPT-4o to measure performance variations. Use APIs with energy tracking capabilities to capture real-world usage patterns across different model architectures."),
                    tags$p(strong("Latency Optimisation:"), "Measure time per token and query response times to identify efficiency bottlenecks. Focus on practical applications like summarisation, question-answering, and code generation to reflect typical usage scenarios."),
                    tags$p(strong("Cost-Energy Correlation:"), "Utilise cost per 1000 tokens as proxy for energy consumption when direct measurements aren't available. Establish clear relationships between pricing tiers and computational requirements across model variants.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Model Performance Comparison", status = "primary", solidHeader = TRUE, width = 12,
                  plotlyOutput("provider_plot")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("OpenAI. (2024). GPT-4 Technical Report. Available at: https://openai.com/research/gpt-4"),
                    tags$p("Strubell, E., Ganesh, A., & McCallum, A. (2019). Energy and policy considerations for deep learning in NLP. Proceedings of the 57th Annual Meeting of the Association for Computational Linguistics."),
                    tags$p("Patterson, D., et al. (2021). Carbon emissions and large neural network training. arXiv preprint arXiv:2104.10350."),
                    tags$p("Azure OpenAI Service. (2024). Monitoring and telemetry. Available at: https://docs.microsoft.com/en-us/azure/cognitive-services/openai/")
                  )
                )
              )
      ),
      
      # Tab 2: Cross-Provider Comparison
      tabItem(tabName = "cross_provider",
              fluidRow(
                box(
                  title = "Key Ideas: Cross-Provider Comparison", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("Equivalent Task Analysis:"), "Compare GPT-4, Claude 3 Opus, and Gemini 1.5 Pro using identical prompts and expected outputs. Ensure fair comparison by normalising query complexity and expected response quality across different architectures."),
                    tags$p(strong("Telemetry Integration:"), "Leverage AWS CloudWatch, Azure Monitor, and Google Cloud monitoring to capture energy consumption patterns. Use billing metrics and resource utilisation data to estimate computational overhead per provider."),
                    tags$p(strong("Architectural Efficiency:"), "Account for different model architectures and optimisation strategies when comparing energy usage. Consider factors like attention mechanisms, parameter efficiency, and inference acceleration techniques across providers.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Provider Energy Efficiency", status = "primary", solidHeader = TRUE, width = 12,
                  plotlyOutput("cross_provider_plot")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("Anthropic. (2024). Claude 3 Model Card. Available at: https://www.anthropic.com/claude"),
                    tags$p("Google DeepMind. (2024). Gemini: A Family of Highly Capable Multimodal Models. arXiv preprint arXiv:2312.11805."),
                    tags$p("AWS CloudWatch. (2024). Monitoring machine learning workloads. Available at: https://docs.aws.amazon.com/cloudwatch/"),
                    tags$p("Henderson, P., et al. (2020). Towards the systematic reporting of the energy and carbon footprints of machine learning. Journal of Machine Learning Research, 21(248), 1-43.")
                  )
                )
              )
      ),
      
      # Tab 3: Query Complexity Analysis
      tabItem(tabName = "complexity",
              fluidRow(
                box(
                  title = "Key Ideas: Query Complexity Analysis", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("Prompt Length Impact:"), "Analyse energy consumption differences between short prompts (under 100 tokens) versus long-form prompts (over 1000 tokens). Measure how context window utilisation affects computational requirements and response generation efficiency."),
                    tags$p(strong("Task Complexity Tiers:"), "Categorise queries into low complexity (simple Q&A), medium complexity (summarisation), and high complexity (multi-step reasoning). Establish energy consumption baselines for each category to predict computational costs."),
                    tags$p(strong("Output Length Correlation:"), "Examine relationship between requested output length and energy consumption. Track how generation of longer responses impacts overall system efficiency and resource allocation patterns.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Complexity vs Energy Consumption", status = "primary", solidHeader = TRUE, width = 12,
                  plotlyOutput("complexity_plot")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("Qiu, J., et al. (2020). Pre-trained models for natural language processing: A survey. Science China Technological Sciences, 63(10), 1872-1897."),
                    tags$p("Rogers, A., Kovaleva, O., & Rumshisky, A. (2020). A primer on neural network models for natural language processing. Journal of Artificial Intelligence Research, 57, 615-717."),
                    tags$p("Tay, Y., et al. (2022). Efficient transformers: A survey. ACM Computing Surveys, 55(6), 1-28."),
                    tags$p("Schwartz, R., et al. (2020). Green AI. Communications of the ACM, 63(12), 54-63.")
                  )
                )
              )
      ),
      
      # Tab 4: Hardware Perspective
      tabItem(tabName = "hardware",
              fluidRow(
                box(
                  title = "Key Ideas: Hardware Perspective", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("GPU Architecture Comparison:"), "Compare energy efficiency across NVIDIA A100, H100, and TPU v4 architectures for LLM inference. Analyse performance per watt metrics and thermal efficiency characteristics under sustained workloads."),
                    tags$p(strong("Precision Mode Optimisation:"), "Evaluate energy savings from FP32 to FP16 and INT8 quantisation whilst maintaining model accuracy. Assess trade-offs between computational precision and energy consumption for different inference scenarios."),
                    tags$p(strong("Batch Processing Efficiency:"), "Examine how different batch sizes and concurrency levels affect energy usage per token. Optimise throughput whilst minimising energy overhead through intelligent workload scheduling and resource allocation.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Hardware Energy Efficiency Comparison", status = "primary", solidHeader = TRUE, width = 12,
                  plotlyOutput("hardware_plot")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("NVIDIA. (2024). NVIDIA Management Library (NVML) Documentation. Available at: https://developer.nvidia.com/nvidia-management-library-nvml"),
                    tags$p("Google Cloud. (2024). TPU performance and energy efficiency. Available at: https://cloud.google.com/tpu"),
                    tags$p("Jouppi, N. P., et al. (2021). Ten lessons from three generations of TPUs. Communications of the ACM, 64(4), 46-51."),
                    tags$p("Kubernetes. (2024). KubeGreen: Energy-aware workload scheduling. Available at: https://github.com/kube-green/kube-green")
                  )
                )
              )
      ),
      
      # Tab 5: Cloud & Geolocation
      tabItem(tabName = "cloud",
              fluidRow(
                box(
                  title = "Key Ideas: Cloud & Geolocation", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("Data Centre Efficiency:"), "Compare Power Usage Effectiveness (PUE) ratings across AWS, Azure, and Google Cloud facilities. Evaluate cooling efficiency, renewable energy usage, and infrastructure optimisation strategies affecting overall energy consumption."),
                    tags$p(strong("Grid Energy Mix:"), "Analyse regional electricity sources (renewable vs fossil fuels) to determine carbon intensity per inference operation. Prioritise deployment in regions with high renewable energy percentages for reduced environmental impact."),
                    tags$p(strong("Regional Optimisation:"), "Select deployment regions based on combination of latency requirements, energy efficiency, and carbon footprint. Consider time-zone optimisation for batch processing during periods of peak renewable energy availability.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Global Data Centre Energy Sources", status = "primary", solidHeader = TRUE, width = 12,
                  leafletOutput("cloud_map")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("Google Cloud. (2024). Carbon Footprint Dashboard. Available at: https://cloud.google.com/carbon-footprint"),
                    tags$p("Microsoft. (2024). Azure Sustainability Calculator. Available at: https://azure.microsoft.com/en-gb/solutions/sustainability/"),
                    tags$p("AWS. (2024). Customer Carbon Footprint Tool. Available at: https://aws.amazon.com/aws-cost-management/aws-customer-carbon-footprint-tool/"),
                    tags$p("IEA. (2024). Data Centres and Data Transmission Networks. Available at: https://www.iea.org/reports/data-centres-and-data-transmission-networks")
                  )
                )
              )
      ),
      
      # Tab 6: Energy Efficiency Case Study
      tabItem(tabName = "efficiency",
              fluidRow(
                box(
                  title = "Key Ideas: Energy Efficiency Case Study", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("Model Pruning Benefits:"), "Demonstrate 40% energy reduction through systematic removal of less critical neural network parameters whilst maintaining 95% of original performance. Showcase practical implementation in production environments."),
                    tags$p(strong("Inference Acceleration:"), "Implement GPU memory optimisation and batch processing techniques achieving 3x throughput improvement. Utilise model quantisation and caching strategies to reduce computational overhead per query."),
                    tags$p(strong("Dynamic Scaling:"), "Deploy auto-scaling infrastructure that adjusts computational resources based on demand patterns. Implement smart load balancing to minimise idle time and optimise energy usage during peak and off-peak periods.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Energy Savings Over Time", status = "primary", solidHeader = TRUE, width = 12,
                  plotlyOutput("efficiency_plot")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("Han, S., Mao, H., & Dally, W. J. (2016). Deep compression: Compressing deep neural networks with pruning, trained quantization and huffman coding. arXiv preprint arXiv:1510.00149."),
                    tags$p("Zhu, M., & Gupta, S. (2017). To prune, or not to prune: exploring the efficacy of pruning for model compression. arXiv preprint arXiv:1710.01878."),
                    tags$p("Jacob, B., et al. (2018). Quantization and training of neural networks for efficient integer-arithmetic-only inference. Proceedings of the IEEE conference on computer vision and pattern recognition."),
                    tags$p("Kubernetes. (2024). Horizontal Pod Autoscaler. Available at: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/")
                  )
                )
              )
      ),
      
      # Tab 7: Cost Optimisation Case Study
      tabItem(tabName = "cost",
              fluidRow(
                box(
                  title = "Key Ideas: Cost Optimisation Case Study", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("Token Usage Analytics:"), "Implement comprehensive tracking of token consumption patterns across different use cases. Identify opportunities for prompt optimisation and response length control to reduce unnecessary computational costs."),
                    tags$p(strong("Model Selection Strategy:"), "Develop intelligent routing system that selects appropriate model size based on query complexity. Use GPT-3.5 for simple tasks and reserve GPT-4 for complex reasoning, achieving 60% cost reduction."),
                    tags$p(strong("Caching Implementation:"), "Deploy semantic caching system that identifies similar queries and reuses previous responses. Implement time-based cache invalidation and similarity scoring to maintain response quality whilst reducing redundant processing.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Cost Reduction Analysis", status = "primary", solidHeader = TRUE, width = 12,
                  plotlyOutput("cost_plot")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("OpenAI. (2024). Pricing and Usage Guidelines. Available at: https://openai.com/pricing"),
                    tags$p("Chen, M., et al. (2021). Evaluating large language models trained on code. arXiv preprint arXiv:2107.03374."),
                    tags$p("Redis Labs. (2024). Semantic Caching for AI Applications. Available at: https://redis.io/solutions/ai/"),
                    tags$p("Liu, P., et al. (2023). Pre-train, Prompt, and Predict: A Systematic Survey of Prompting Methods in Natural Language Processing. ACM Computing Surveys, 55(9), 1-35.")
                  )
                )
              )
      ),
      
      # Tab 8: Sustainability Case Study
      tabItem(tabName = "sustainability",
              fluidRow(
                box(
                  title = "Key Ideas: Sustainability Case Study", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("Carbon Offset Integration:"), "Implement automated carbon footprint calculation for each inference operation. Partner with verified carbon offset programmes to achieve net-zero emissions for AI workloads through renewable energy investments."),
                    tags$p(strong("Green Computing Practices:"), "Schedule non-urgent batch processing during periods of high renewable energy availability. Utilise weather forecasting data to optimise computational workloads when solar and wind generation peaks."),
                    tags$p(strong("Lifecycle Assessment:"), "Conduct comprehensive analysis including manufacturing, deployment, operation, and disposal phases of AI infrastructure. Implement circular economy principles through hardware refurbishment and responsible recycling programmes.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Carbon Footprint Reduction", status = "primary", solidHeader = TRUE, width = 12,
                  plotlyOutput("sustainability_plot")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("Lacoste, A., et al. (2019). Quantifying the carbon emissions of machine learning. arXiv preprint arXiv:1910.09700."),
                    tags$p("Strubell, E., Ganesh, A., & McCallum, A. (2019). Energy and policy considerations for deep learning in NLP. Proceedings of the 57th Annual Meeting of the Association for Computational Linguistics."),
                    tags$p("Green Software Foundation. (2024). Software Carbon Intensity Specification. Available at: https://greensoftware.foundation/"),
                    tags$p("Carbon Trust. (2024). Carbon Footprinting Guide. Available at: https://www.carbontrust.com/our-work-and-position/measurement-and-reporting")
                  )
                )
              )
      ),
      
      # Tab 9: Regional Deployment Case Study
      tabItem(tabName = "regional",
              fluidRow(
                box(
                  title = "Key Ideas: Regional Deployment Case Study", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("Latency-Energy Balance:"), "Optimise deployment across global regions to minimise both response latency and energy consumption. Analyse trade-offs between proximity to users and availability of renewable energy sources in different geographical locations."),
                    tags$p(strong("Regulatory Compliance:"), "Navigate data sovereignty requirements whilst maintaining energy efficiency goals. Implement region-specific optimisation strategies that comply with GDPR, local data protection laws, and environmental regulations."),
                    tags$p(strong("Multi-Region Orchestration:"), "Deploy intelligent load balancing that considers both computational capacity and energy source cleanliness. Implement failover mechanisms that prioritise sustainable regions whilst maintaining service availability and performance standards.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Regional Energy Efficiency Comparison", status = "primary", solidHeader = TRUE, width = 12,
                  leafletOutput("regional_map")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("European Commission. (2024). European Green Deal and Digital Strategy. Available at: https://ec.europa.eu/info/strategy/priorities-2019-2024/european-green-deal"),
                    tags$p("IEA. (2024). Global Energy & CO2 Status Report. Available at: https://www.iea.org/reports/global-energy-co2-status-report-2024"),
                    tags$p("Amazon Web Services. (2024). Global Infrastructure Regions. Available at: https://aws.amazon.com/about-aws/global-infrastructure/"),
                    tags$p("GDPR.eu. (2024). General Data Protection Regulation Guide. Available at: https://gdpr.eu/")
                  )
                )
              )
      ),
      
      # Tab 10: Best Practices Case Study
      tabItem(tabName = "practices",
              fluidRow(
                box(
                  title = "Key Ideas: Best Practices Case Study", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p(strong("Holistic Monitoring:"), "Implement comprehensive energy monitoring across entire AI pipeline including data preprocessing, model inference, and result processing. Establish baseline metrics and continuous improvement targets for energy efficiency performance."),
                    tags$p(strong("Stakeholder Engagement:"), "Develop cross-functional teams including data scientists, infrastructure engineers, and sustainability officers. Create governance frameworks that balance performance requirements with environmental responsibility and cost management."),
                    tags$p(strong("Continuous Optimisation:"), "Establish regular review cycles for energy efficiency improvements and emerging green computing technologies. Implement A/B testing frameworks for comparing energy impact of different architectural choices and optimisation strategies.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Best Practices Implementation Timeline", status = "primary", solidHeader = TRUE, width = 12,
                  DT::dataTableOutput("practices_table")
                )
              ),
              fluidRow(
                box(
                  title = "References & Resources", status = "primary", solidHeader = TRUE, width = 12,
                  tags$div(
                    tags$p("MLOps Community. (2024). Sustainable AI Practices Guide. Available at: https://mlops.community/sustainable-ai/"),
                    tags$p("IEEE. (2024). IEEE Standard for Green Computing. Available at: https://standards.ieee.org/"),
                    tags$p("Linux Foundation. (2024). Green Software Development Practices. Available at: https://www.linuxfoundation.org/"),
                    tags$p("ACM. (2024). Computing and Climate Change. Communications of the ACM, 67(3), 42-49.")
                  )
                )
              )
      )
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Provider benchmarking plot
  output$provider_plot <- renderPlotly({
    data <- data.frame(
      Model = c("GPT-3.5", "GPT-4", "GPT-4o"),
      Energy_per_Token = c(0.8, 2.1, 1.2),
      Latency_ms = c(150, 350, 200),
      Cost_per_1K_tokens = c(0.002, 0.03, 0.015)
    )
    
    p <- ggplot(data, aes(x = Model, y = Energy_per_Token, fill = Model)) +
      geom_bar(stat = "identity", fill = c("#6c757d", "#868e96", "#adb5bd")) +
      labs(title = "Energy Consumption per Token by Model",
           x = "Model", y = "Energy (Arbitrary Units)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  # Cross-provider comparison plot
  output$cross_provider_plot <- renderPlotly({
    data <- data.frame(
      Provider = c("OpenAI", "Anthropic", "Google", "OpenAI", "Anthropic", "Google"),
      Task = c("Summarisation", "Summarisation", "Summarisation", "Reasoning", "Reasoning", "Reasoning"),
      Energy_Efficiency = c(85, 92, 78, 88, 95, 82)
    )
    
    p <- ggplot(data, aes(x = Provider, y = Energy_Efficiency, fill = Task)) +
      geom_bar(stat = "identity", position = "dodge") +
      scale_fill_manual(values = c("Summarisation" = "#6c757d", "Reasoning" = "#adb5bd")) +
      labs(title = "Energy Efficiency Across Providers",
           x = "Provider", y = "Efficiency Score") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Query complexity plot
  output$complexity_plot <- renderPlotly({
    data <- data.frame(
      Complexity = c("Low", "Medium", "High"),
      Energy_Consumption = c(1.2, 2.8, 5.1),
      Query_Count = c(1500, 800, 200)
    )
    
    p <- ggplot(data, aes(x = Complexity, y = Energy_Consumption)) +
      geom_point(size = data$Query_Count/100, colour = "#6c757d") +
      geom_line(group = 1, colour = "#868e96", size = 1) +
      labs(title = "Energy Consumption by Query Complexity",
           x = "Query Complexity", y = "Energy (kWh)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Hardware comparison plot
  output$hardware_plot <- renderPlotly({
    data <- data.frame(
      Hardware = c("A100", "H100", "TPU v4", "A100", "H100", "TPU v4"),
      Precision = c("FP32", "FP32", "FP32", "INT8", "INT8", "INT8"),
      Performance_per_Watt = c(12, 18, 22, 25, 32, 38)
    )
    
    p <- ggplot(data, aes(x = Hardware, y = Performance_per_Watt, fill = Precision)) +
      geom_bar(stat = "identity", position = "dodge") +
      scale_fill_manual(values = c("#6c757d", "#adb5bd")) +
      labs(title = "Hardware Performance per Watt",
           x = "Hardware Type", y = "Performance/Watt") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Cloud geolocation map
  output$cloud_map <- renderLeaflet({
    locations <- data.frame(
      lat = c(51.5074, 37.7749, 53.3498, 35.6762),
      lng = c(-0.1278, -122.4194, -6.2603, 139.6503),
      city = c("London", "San Francisco", "Dublin", "Tokyo"),
      renewable_percent = c(45, 85, 70, 25),
      provider = c("AWS", "Google", "Azure", "AWS")
    )
    
    leaflet(locations) %>%
      addTiles() %>%
      addCircleMarkers(
        ~lng, ~lat,
        radius = ~renewable_percent/5,
        color = "#6c757d",
        fillOpacity = 0.7,
        popup = ~paste(city, "<br>Renewable: ", renewable_percent, "%<br>Provider: ", provider)
      ) %>%
      setView(lng = 0, lat = 30, zoom = 2)
  })
  
  # Energy efficiency case study plot
  output$efficiency_plot <- renderPlotly({
    months <- seq.Date(from = as.Date("2024-01-01"), to = as.Date("2024-12-01"), by = "month")
    data <- data.frame(
      Month = months,
      Baseline_Energy = rep(100, 12),
      Optimised_Energy = c(100, 95, 88, 82, 75, 70, 65, 62, 60, 58, 57, 56)
    )
    
    p <- ggplot(data, aes(x = Month)) +
      geom_line(aes(y = Baseline_Energy, colour = "Baseline"), size = 1) +
      geom_line(aes(y = Optimised_Energy, colour = "Optimised"), size = 1) +
      scale_colour_manual(values = c("Baseline" = "#adb5bd", "Optimised" = "#6c757d")) +
      labs(title = "Energy Efficiency Improvements Over Time",
           x = "Month", y = "Energy Consumption (%)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Cost optimisation plot
  output$cost_plot <- renderPlotly({
    strategies <- c("Baseline", "Model Selection", "Caching", "Combined")
    costs <- c(1000, 750, 650, 400)
    
    data <- data.frame(Strategy = strategies, Monthly_Cost = costs)
    
    p <- ggplot(data, aes(x = Strategy, y = Monthly_Cost, fill = Strategy)) +
      geom_bar(stat = "identity", fill = c("#adb5bd", "#868e96", "#6c757d", "#495057")) +
      labs(title = "Cost Reduction Through Optimisation Strategies",
           x = "Strategy", y = "Monthly Cost (£)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  # Sustainability plot
  output$sustainability_plot <- renderPlotly({
    quarters <- c("Q1 2024", "Q2 2024", "Q3 2024", "Q4 2024")
    carbon_footprint <- c(100, 85, 65, 40)
    
    data <- data.frame(Quarter = quarters, Carbon_Footprint = carbon_footprint)
    
    p <- ggplot(data, aes(x = Quarter, y = Carbon_Footprint, group = 1)) +
      geom_line(colour = "#6c757d", size = 2) +
      geom_point(colour = "#495057", size = 4) +
      labs(title = "Carbon Footprint Reduction Progress",
           x = "Quarter", y = "Carbon Footprint (%)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Regional deployment map
  output$regional_map <- renderLeaflet({
    regions <- data.frame(
      lat = c(54.5260, 39.8283, -33.8688, 1.3521),
      lng = c(-105.2551, -98.5795, 151.2093, 103.8198),
      region = c("Canada", "USA", "Australia", "Singapore"),
      energy_efficiency = c(95, 75, 85, 65),
      latency_ms = c(120, 80, 150, 90)
    )
    
    leaflet(regions) %>%
      addTiles() %>%
      addCircleMarkers(
        ~lng, ~lat,
        radius = ~energy_efficiency/8,
        color = "#6c757d",
        fillOpacity = 0.7,
        popup = ~paste(region, "<br>Efficiency: ", energy_efficiency, "%<br>Latency: ", latency_ms, "ms")
      ) %>%
      setView(lng = 0, lat = 20, zoom = 2)
  })
  
  # Best practices table
  output$practices_table <- DT::renderDataTable({
    practices_data <- data.frame(
      Phase = c("Assessment", "Planning", "Implementation", "Monitoring", "Optimisation"),
      Timeline = c("Month 1", "Month 2", "Months 3-6", "Ongoing", "Quarterly"),
      Key_Activities = c(
        "Baseline energy audit and stakeholder mapping",
        "Develop sustainability framework and KPIs",
        "Deploy monitoring tools and optimisation strategies",
        "Continuous tracking and reporting",
        "Review and iterate on best practices"
      ),
      Expected_Outcomes = c(
        "Current state assessment",
        "Implementation roadmap",
        "Operational improvements",
        "Performance metrics",
        "Continuous improvement"
      ),
      Success_Metrics = c(
        "Energy consumption baseline",
        "Approved sustainability plan",
        "30% efficiency improvement",
        "Monthly reporting cadence",
        "Quarterly optimisation cycles"
      )
    )
    
    DT::datatable(practices_data, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  style = "bootstrap",
                  class = "table-striped")
  })
}

# Run the application
shinyApp(ui = ui, server = server)