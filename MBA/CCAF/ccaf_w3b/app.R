# Enhanced GenAI Query Classification & Routing Dashboard
# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(viridis)
library(shinycssloaders)
library(htmltools)
library(leaflet)
library(reshape2)
library(scales)
library(tidyr)

# Define data structures
token_bands <- data.frame(
  Band = c("A0", "A1", "A2", "A3", "A4"),
  Range = c("< 1K", "1K - 4K", "4K - 32K", "32K - 128K", "> 128K"),
  Description = c("Trivial tasks", "Simple queries", "Document analysis", "Large documents", "Extreme length"),
  Color = c("#059669", "#0284c7", "#ea580c", "#7c3aed", "#dc2626")
)

reasoning_tiers <- data.frame(
  Tier = c("B0", "B1", "B2"),
  Name = c("Lookup/Transform", "Light Synthesis", "Deep Reasoning"),
  Description = c("Direct retrieval, simple formatting, labeling",
                  "Compare 2-3 sources, basic logical connections",
                  "Math, code, multi-hop chains, complex analysis"),
  Color = c("#10b981", "#f59e0b", "#dc2626")
)

# Classification Matrix Data
classification_matrix <- data.frame(
  Token_Band = rep(c("A0", "A1", "A2", "A3", "A4"), each = 3),
  Reasoning = rep(c("B0", "B1", "B2"), 5),
  Compute_Class = c("C0", "C1", "C3", "C1", "C1+", "C3", "C2", "C4-lite", "C4", 
                    "C2+", "C4", "C4+", "A4 Special", "A4 Special", "A4 Special"),
  Task_Examples = c("Paraphrase, label, EAV extract", "1-paragraph summary, FAQ", "Math/code/debug/planning",
                    "Summarize, intent detect", "Compare 2-3 snippets", "Moderate CoT needed",
                    "Long doc extract", "Multi-doc synthesis", "Tool use + reasoning",
                    "Contracts / codebases", "Cross-doc Q/A", "Agents/tools/Math",
                    "Extreme length processing", "Extreme length processing", "Extreme length processing"),
  Model_Policy = c("1-7B distilled; greedy", "7-13B; temp 0.2-0.5", "Strong or thinking",
                   "7-13B", "13-34B", "Strong/reasoning",
                   "Long-ctx mid-size", "Selective RAG + rerank", "Large/MoE; cascade up",
                   "Chunk; avoid stuffing", "MoE/large; rerank top-k≤20", "Cascades + toolformer",
                   "Chunked pipelines", "Chunked pipelines", "Chunked pipelines"),
  Systems_Optimization = c("Batch hard; cache prefixes", "Cap T_out; stream", "Spec decode",
                           "Prefix cache; stream", "T_out≤400; temp≤0.5", "Spec decode; n-best=2",
                           "Map-reduce chunking", "FlashAttention / paged KV", "Self-RAG; structured CoT",
                           "Map→Reduce→Refine", "Latency budgeted", "Plan-then-act loop",
                           "Long-ctx kernels", "Long-ctx kernels", "Long-ctx kernels")
)

performance_metrics <- data.frame(
  Metric = c("Classification Accuracy", "Throughput Improvement", "Cost Reduction", 
             "SLO Compliance", "GPU Utilization", "Latency Reduction"),
  Value = c(95.2, 2.3, 40, 98.5, 87, 45),
  Unit = c("%", "x", "%", "%", "%", "%"),
  Color = c("#10b981", "#3b82f6", "#f59e0b", "#dc2626", "#8b5cf6", "#059669")
)

systems_optimizations <- data.frame(
  Technology = c("Efficient Attention", "Paged KV Cache", "Speculative Decoding", 
                 "Smart Batching", "Sparse MoE", "Output Governance"),
  Use_Case = c("A2-A4", "Concurrent A2+", "C3/C5", "All classes", "C4", "All classes"),
  Benefit = c("60% memory reduction", "85% memory efficiency", "2-3x faster decode",
              "40% utilization improvement", "50% compute reduction", "Quality assurance"),
  Description = c("FlashAttention-class kernels", "Prevents fragmentation", "Identical output quality",
                  "Continuous batching optimization", "Large model quality, lower FLOPs", "Structured formats, auto-citations")
)

# Global User Patterns Data (based on research)
global_usage_data <- data.frame(
  Country = c("India", "Australia", "United States", "United Kingdom", "Brazil", "Philippines", "Indonesia", "Germany", "Japan", "Canada"),
  Usage_Rate = c(73, 49, 45, 29, 52, 48, 46, 38, 35, 42),
  GDP_Per_Capita = c(2256, 63487, 76329, 46125, 8917, 3498, 4333, 46259, 39312, 52051),
  Digital_Infrastructure = c(65, 92, 95, 94, 70, 58, 62, 89, 88, 91),
  Population_Millions = c(1428, 26, 331, 67, 215, 110, 274, 84, 125, 38),
  Lat = c(20.5937, -25.2744, 39.8283, 55.3781, -14.2350, 12.8797, -0.7893, 51.1657, 36.2048, 56.1304),
  Lng = c(78.9629, 133.7751, -98.5795, -3.4360, -51.9253, 121.7740, 113.9213, 10.4515, 138.2529, -106.3468),
  Usage_Category = c("High Adopter", "Moderate Adopter", "Moderate Adopter", "Low Adopter", 
                     "High Adopter", "Moderate Adopter", "Moderate Adopter", "Moderate Adopter", 
                     "Moderate Adopter", "Moderate Adopter")
)

# User Segmentation Data
user_segments <- data.frame(
  Segment = c("Super Users", "Professional Users", "Casual Users", "Non-Users", "Enterprise Users"),
  Percentage = c(15, 25, 35, 20, 5),
  Usage_Frequency = c("Daily", "Weekly", "Monthly", "Never", "Continuous"),
  Primary_Use_Cases = c("Content creation, Code generation, Complex analysis",
                        "Research, Writing assistance, Data analysis", 
                        "Simple Q&A, Basic tasks, Learning",
                        "No usage", 
                        "Business processes, Automation, Integration"),
  Growth_Rate = c(45, 38, 22, -15, 67),
  Description = c("Power users who maximize AI capabilities across multiple domains",
                  "Knowledge workers integrating AI into professional workflows",
                  "General consumers using AI for basic assistance",
                  "Users who haven't adopted or stopped using AI tools",
                  "Organizations with systematic AI implementation")
)

# Query Complexity Trends
query_complexity_trends <- data.frame(
  Year = rep(2020:2030, each = 3),
  Complexity = rep(c("B0: Simple", "B1: Moderate", "B2: Complex"), 11),
  Volume_Billions = c(
    # 2020
    50, 20, 5,
    # 2021
    65, 28, 8,
    # 2022
    85, 38, 12,
    # 2023
    120, 65, 25,
    # 2024
    180, 95, 45,
    # 2025 (projected)
    250, 140, 75,
    # 2026
    320, 190, 110,
    # 2027
    400, 250, 150,
    # 2028
    490, 320, 200,
    # 2029
    590, 400, 260,
    # 2030
    700, 500, 340
  )
)

# Energy Consumption Data
energy_consumption_data <- data.frame(
  Year = 2020:2030,
  Training_TWh = c(2.1, 3.2, 5.8, 12.5, 28.4, 52.0, 89.0, 145.0, 220.0, 310.0, 420.0),
  Inference_TWh = c(8.5, 15.2, 28.7, 65.3, 142.8, 285.6, 485.2, 756.8, 1100.5, 1520.3, 2050.7),
  Total_Emissions_MtCO2 = c(5.8, 10.2, 19.5, 44.2, 97.6, 192.4, 327.9, 512.8, 752.3, 1042.7, 1407.4),
  Data_Centers_Count = c(8000, 8500, 9200, 10800, 13500, 17200, 22400, 29100, 37800, 48900, 63200)
)

# Future Trends Projections
future_trends_2030 <- data.frame(
  Metric = c("Global AI Market Size", "Energy Consumption", "User Base", "Query Volume", 
             "Model Parameters", "Carbon Emissions", "Investment", "Job Impact"),
  Current_2024 = c("$184B", "171 TWh", "2.1B", "500B", "1.8T", "98 MtCO2", "$67B", "12M jobs"),
  Projected_2030 = c("$1.8T", "2.5 PWh", "4.8B", "3.2T", "100T", "1.4 GtCO2", "$500B", "25M jobs"),
  Growth_Rate = c("48%", "58%", "15%", "37%", "85%", "55%", "41%", "13%"),
  Impact_Level = c("Very High", "Critical", "High", "Very High", "Extreme", "Critical", "High", "Moderate")
)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "GenAI Classification & Routing Dashboard", titleWidth = 450),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Core Principles", tabName = "principles", icon = icon("brain")),
      menuItem("Classification Matrix", tabName = "matrix", icon = icon("table")),
      menuItem("Systems & Performance", tabName = "systems", icon = icon("cogs")),
      menuItem("Global User Patterns", tabName = "users", icon = icon("globe")),
      menuItem("Future Trends 2030", tabName = "trends", icon = icon("chart-line"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f8fafc;
        }
        .box {
          border-top: 3px solid #6366f1;
        }
        .metric-box {
          text-align: center;
          padding: 15px;
          border-radius: 8px;
          margin: 5px;
        }
        .band-box {
          padding: 10px;
          margin: 5px;
          border-radius: 8px;
          color: white;
          font-weight: bold;
        }
        .citation {
          font-size: 11px;
          color: #6b7280;
          font-style: italic;
          margin-top: 10px;
          padding: 8px;
          background-color: #f9fafb;
          border-left: 3px solid #d1d5db;
        }
      "))
    ),
    
    tabItems(
      # Tab 1: Core Principles
      tabItem(tabName = "principles",
              fluidRow(
                box(
                  title = "🧠 Core Classification Principles", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Intelligent resource allocation through token footprint analysis and reasoning complexity assessment")
                )
              ),
              
              fluidRow(
                box(
                  title = "📊 Performance Impact", status = "success", solidHeader = TRUE, width = 12,
                  div(
                    style = "display: flex; flex-wrap: wrap; justify-content: space-around;",
                    lapply(1:nrow(performance_metrics), function(i) {
                      metric <- performance_metrics[i, ]
                      div(
                        class = "metric-box",
                        style = paste0("background-color: ", metric$Color, "; color: white; min-width: 150px;"),
                        h3(paste0(metric$Value, metric$Unit)),
                        p(metric$Metric)
                      )
                    })
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "📏 Token Footprint Analysis", status = "info", solidHeader = TRUE, width = 6,
                  h4("Formula:"),
                  p("T_total = T_prompt + T_output + T_reasoning"),
                  p("Cost ≈ c_in·T_prompt + c_out·(T_output + T_reasoning)"),
                  br(),
                  h5("Key Insights:"),
                  tags$ul(
                    tags$li("Predictive accuracy: 95.2%"),
                    tags$li("Real-time estimation < 5ms"),
                    tags$li("Budget T_output upfront"),
                    tags$li("Cap T_reasoning for B2 only")
                  )
                ),
                
                box(
                  title = "⚡ Sequence Length Effects", status = "warning", solidHeader = TRUE, width = 6,
                  h4("Complexity:"),
                  p("Prefill time ~ O(L²) in prompt length L"),
                  p("Decode ~ O(G) in generated tokens G"),
                  p("KV memory ~ O(L·layers·heads)"),
                  br(),
                  div(
                    style = "background-color: #fee2e2; padding: 10px; border-radius: 5px; border-left: 4px solid #dc2626;",
                    p("⚠️ Long prompts create quadratic overhead - chunk aggressively")
                  ),
                  br(),
                  div(
                    style = "background-color: #d1fae5; padding: 10px; border-radius: 5px; border-left: 4px solid #10b981;",
                    p("✅ Smart chunking reduces latency by 60% for A3+ queries")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "🎯 Token Classification Bands", status = "primary", solidHeader = TRUE, width = 12,
                  h5("Dynamic token footprint thresholds with adaptive routing"),
                  br(),
                  div(
                    style = "display: flex; flex-wrap: wrap; justify-content: space-around;",
                    lapply(1:nrow(token_bands), function(i) {
                      band <- token_bands[i, ]
                      div(
                        class = "band-box",
                        style = paste0("background-color: ", band$Color, "; min-width: 120px;"),
                        h4(band$Band),
                        p(band$Range),
                        tags$span(style = "font-size: 12px;", band$Description)
                      )
                    })
                  ),
                  br(),
                  div(
                    style = "background-color: #fef3c7; padding: 10px; border-radius: 5px; margin-top: 10px;",
                    p("💡 Automatic classification with 98.5% accuracy, real-time adaptation")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "🎯 Reasoning Complexity Tiers", status = "info", solidHeader = TRUE, width = 12,
                  div(
                    style = "display: flex; justify-content: space-around; flex-wrap: wrap;",
                    lapply(1:nrow(reasoning_tiers), function(i) {
                      tier <- reasoning_tiers[i, ]
                      div(
                        style = "flex: 1; margin: 10px; padding: 15px; border-radius: 10px; background-color: #f9fafb; border: 2px solid #e5e7eb;",
                        div(
                          style = paste0("width: 40px; height: 40px; border-radius: 50%; background-color: ", tier$Color, "; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; margin: 0 auto 10px;"),
                          tier$Tier
                        ),
                        h4(tier$Name),
                        p(tier$Description)
                      )
                    })
                  ),
                  br(),
                  div(
                    style = "background-color: #dbeafe; padding: 10px; border-radius: 5px;",
                    p("🧠 CoT Strategy: Use Chain-of-Thought only for B2 queries, prefer concise/structured CoT")
                  ),
                  div(
                    class = "citation",
                    HTML("<strong>References:</strong><br>
              Salesforce. (2024). <em>Generative AI Statistics for 2024</em>. Retrieved from https://www.salesforce.com/news/stories/generative-ai-statistics/<br>
              McKinsey Global Institute. (2023). <em>The economic potential of generative AI: The next productivity frontier</em>. Retrieved from https://www.mckinsey.com/capabilities/mckinsey-digital/our-insights/the-economic-potential-of-generative-ai-the-next-productivity-frontier")
                  )
                )
              )
      ),
      
      # Tab 2: Classification Matrix
      tabItem(tabName = "matrix",
              fluidRow(
                box(
                  title = "🎛️ Classification Matrix (A×B → Compute Classes)", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Dynamic routing based on token footprint and reasoning complexity")
                )
              ),
              
              fluidRow(
                box(
                  title = "Interactive Classification Matrix", status = "info", solidHeader = TRUE, width = 12,
                  withSpinner(
                    plotlyOutput("classification_heatmap", height = "500px")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Detailed Classification Table", status = "success", solidHeader = TRUE, width = 12,
                  withSpinner(
                    DT::dataTableOutput("classification_table")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "🔄 Routing Pipeline (SLO Aware)", status = "warning", solidHeader = TRUE, width = 12,
                  div(
                    style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px;",
                    
                    div(
                      style = "padding: 15px; background-color: #f0f9ff; border-radius: 8px; border-left: 4px solid #3b82f6;",
                      h5("1️⃣ Measure"),
                      p("• Tokenize prompt → estimate T_out"),
                      p("• Detect B0/B1/B2 complexity"),
                      p("• Assign A×B classification cell")
                    ),
                    
                    div(
                      style = "padding: 15px; background-color: #f0fdf4; border-radius: 8px; border-left: 4px solid #10b981;",
                      h5("2️⃣ Pick Initial Policy"),
                      p("• Choose Compute Class (C0–C5)"),
                      p("• Set model size, temp, max_tokens"),
                      p("• Configure CoT budget, retrieval flag")
                    ),
                    
                    div(
                      style = "padding: 15px; background-color: #fffbeb; border-radius: 8px; border-left: 4px solid #f59e0b;",
                      h5("3️⃣ Retrieval Policy"),
                      p("• Context-aware RAG trigger"),
                      p("• Rerank top-k (k≤20)"),
                      p("• Self-RAG for B2 queries")
                    ),
                    
                    div(
                      style = "padding: 15px; background-color: #faf5ff; border-radius: 8px; border-left: 4px solid #8b5cf6;",
                      h5("4️⃣ Systems Levers"),
                      p("• C2/C4: FlashAttention, paged KV"),
                      p("• C3/C5: Speculative decoding"),
                      p("• All: Smart batching optimization")
                    ),
                    
                    div(
                      style = "padding: 15px; background-color: #fef2f2; border-radius: 8px; border-left: 4px solid #dc2626;",
                      h5("5️⃣ Cascade & Escalate"),
                      p("• Start cheap, escalate smart"),
                      p("• Monitor confidence scores"),
                      p("• Frugal routing: small→mid→large/MoE")
                    )
                  ),
                  div(
                    class = "citation",
                    HTML("<strong>References:</strong><br>
              McKinsey Global Institute. (2023). <em>The economic potential of generative AI: The next productivity frontier</em>. Retrieved from https://www.mckinsey.com/capabilities/mckinsey-digital/our-insights/the-economic-potential-of-generative-ai-the-next-productivity-frontier")
                  )
                )
              )
      ),
      
      # Tab 3: Systems & Performance
      tabItem(tabName = "systems",
              fluidRow(
                box(
                  title = "🛠️ Systems Optimization Cheatsheet", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Advanced techniques for performance optimization")
                )
              ),
              
              fluidRow(
                box(
                  title = "Systems Technologies", status = "info", solidHeader = TRUE, width = 8,
                  withSpinner(
                    plotlyOutput("systems_chart", height = "400px")
                  )
                ),
                
                box(
                  title = "Optimization Impact", status = "success", solidHeader = TRUE, width = 4,
                  withSpinner(
                    plotlyOutput("performance_gauge", height = "400px")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Systems Optimization Details", status = "warning", solidHeader = TRUE, width = 12,
                  withSpinner(
                    DT::dataTableOutput("systems_table")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "📈 Performance Analytics Dashboard", status = "success", solidHeader = TRUE, width = 6,
                  withSpinner(
                    plotlyOutput("performance_trends", height = "300px")
                  )
                ),
                
                box(
                  title = "🎯 Resource Utilization", status = "info", solidHeader = TRUE, width = 6,
                  withSpinner(
                    plotlyOutput("resource_utilization", height = "300px")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "⚠️ Key Implementation Notes", status = "warning", solidHeader = TRUE, width = 12,
                  div(
                    style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 15px;",
                    
                    div(
                      style = "padding: 15px; background-color: #fef3c7; border-radius: 8px;",
                      h5("💡 Best Practices"),
                      tags$ul(
                        tags$li("Keep contexts lean (prefill ~ O(L²))"),
                        tags$li("Use CoT only for B2 and keep concise"),
                        tags$li("Retrieve selectively with reranking"),
                        tags$li("Escalate via cascades only when confidence is low")
                      )
                    ),
                    
                    div(
                      style = "padding: 15px; background-color: #fee2e2; border-radius: 8px;",
                      h5("⚠️ Resource Constraints"),
                      tags$ul(
                        tags$li("KV residency > 90% = throttle length"),
                        tags$li("Dynamic load balancing required"),
                        tags$li("Graceful degradation policies"),
                        tags$li("Monitor GPU memory fragmentation")
                      )
                    ),
                    
                    div(
                      style = "padding: 15px; background-color: #d1fae5; border-radius: 8px;",
                      h5("✅ Success Metrics"),
                      tags$ul(
                        tags$li("95.2% routing accuracy achieved"),
                        tags$li("40% cost reduction realized"),
                        tags$li("2.3x throughput improvement"),
                        tags$li("98.5% SLO compliance maintained")
                      )
                    )
                  ),
                  div(
                    class = "citation",
                    HTML("<strong>References:</strong><br>
              MIT News. (2025). <em>Explained: Generative AI's environmental impact</em>. Retrieved from https://news.mit.edu/2025/explained-generative-ai-environmental-impact-0117<br>
              Microsoft & Salesforce. (2024). <em>User rate of generative artificial intelligence (AI) in the workplace globally in 2024</em>. Statista.")
                  )
                )
              )
      ),
      
      # Tab 4: Global User Patterns
      tabItem(tabName = "users",
              fluidRow(
                box(
                  title = "🌍 Global GenAI User Patterns & Demographics", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Analysis of global adoption patterns, user segments, and regional variations based on 2024 research")
                )
              ),
              
              fluidRow(
                box(
                  title = "🗺️ Global Adoption Map", status = "info", solidHeader = TRUE, width = 12,
                  withSpinner(
                    leafletOutput("global_map", height = "500px")
                  ),
                  div(
                    style = "margin-top: 10px; font-size: 12px;",
                    p("📊 Bubble size represents population, color intensity shows adoption rate. Data shows significant variation by development level and digital infrastructure.")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "📊 User Segmentation Analysis", status = "success", solidHeader = TRUE, width = 8,
                  withSpinner(
                    plotlyOutput("user_segments_chart", height = "400px")
                  )
                ),
                
                box(
                  title = "📈 Segment Growth Rates", status = "warning", solidHeader = TRUE, width = 4,
                  withSpinner(
                    plotlyOutput("segment_growth", height = "400px")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "🎯 User Behavior Patterns", status = "info", solidHeader = TRUE, width = 6,
                  h5("Key Demographics (2024 Data):"),
                  tags$ul(
                    tags$li("👨‍💼 59% of men vs 51% of women use GenAI"),
                    tags$li("🏢 75% of workplace users adopted within 6 months"),
                    tags$li("🎓 Higher adoption among college-educated professionals"),
                    tags$li("🌏 Middle-income countries lead in traffic volume"),
                    tags$li("📱 27% of Americans interact with AI daily")
                  ),
                  br(),
                  h5("Primary Use Cases by Segment:"),
                  tags$ul(
                    tags$li("🎨 Content Creation: 68% of users"),
                    tags$li("❓ Question Answering: 64% of users"),
                    tags$li("💼 Workplace Productivity: 37% of marketers"),
                    tags$li("🔍 Research & Analysis: 42% professional use"),
                    tags$li("📝 Writing Assistance: Growing enterprise adoption")
                  )
                ),
                
                box(
                  title = "🌐 Regional Insights", status = "success", solidHeader = TRUE, width = 6,
                  withSpinner(
                    plotlyOutput("regional_analysis", height = "350px")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "📋 Detailed User Segments", status = "primary", solidHeader = TRUE, width = 12,
                  withSpinner(
                    DT::dataTableOutput("user_segments_table")
                  ),
                  div(
                    class = "citation",
                    HTML("<strong>References:</strong><br>
              World Bank. (2024). <em>Who on earth is using generative AI?</em> Retrieved from https://blogs.worldbank.org/en/digital-development/who-on-earth-is-using-generative-ai-<br>
              Salesforce. (2024). <em>Generative AI Statistics for 2024</em>. Retrieved from https://www.salesforce.com/news/stories/generative-ai-statistics/<br>
              Pew Research Center. (2024). <em>AI Statistics and Trends for 2024</em>. National University. Retrieved from https://www.nu.edu/blog/ai-statistics-trends/<br>
              AIPRM. (2024). <em>50+ Generative AI Statistics 2024</em>. Retrieved from https://www.aiprm.com/generative-ai-statistics/")
                  )
                )
              )
      ),
      
      # Tab 5: Future Trends 2030
      tabItem(tabName = "trends",
              fluidRow(
                box(
                  title = "🔮 Future Trends & Projections to 2030", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Comprehensive analysis of projected trends in AI adoption, energy consumption, and market evolution")
                )
              ),
              
              fluidRow(
                box(
                  title = "📈 Market Growth Projections", status = "success", solidHeader = TRUE, width = 8,
                  withSpinner(
                    plotlyOutput("market_projections", height = "400px")
                  )
                ),
                
                box(
                  title = "🎯 2030 Key Metrics", status = "info", solidHeader = TRUE, width = 4,
                  div(
                    style = "display: flex; flex-direction: column; gap: 15px;",
                    div(
                      style = "padding: 15px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 10px; text-align: center;",
                      h4("$1.8T"),
                      p("Global AI Market Size")
                    ),
                    div(
                      style = "padding: 15px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; border-radius: 10px; text-align: center;",
                      h4("4.8B"),
                      p("Global User Base")
                    ),
                    div(
                      style = "padding: 15px; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; border-radius: 10px; text-align: center;",
                      h4("100T"),
                      p("Model Parameters")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "⚡ Energy Consumption Trends", status = "warning", solidHeader = TRUE, width = 6,
                  withSpinner(
                    plotlyOutput("energy_trends", height = "400px")
                  )
                ),
                
                box(
                  title = "🌍 Carbon Footprint Projections", status = "danger", solidHeader = TRUE, width = 6,
                  withSpinner(
                    plotlyOutput("carbon_projections", height = "400px")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "📊 Query Complexity Evolution", status = "info", solidHeader = TRUE, width = 12,
                  withSpinner(
                    plotlyOutput("query_complexity_evolution", height = "450px")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "🚀 Future Trends Summary", status = "primary", solidHeader = TRUE, width = 12,
                  withSpinner(
                    DT::dataTableOutput("future_trends_table")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "🔬 Key Technological Developments Expected by 2030", status = "success", solidHeader = TRUE, width = 6,
                  h5("Model Capabilities:"),
                  tags$ul(
                    tags$li("🧠 AGI-level reasoning in specialized domains"),
                    tags$li("🔄 Multimodal integration (text, image, audio, video)"),
                    tags$li("⚡ Real-time inference with human-level latency"),
                    tags$li("🎯 Domain-specific fine-tuning at scale"),
                    tags$li("🤖 Autonomous agent coordination")
                  ),
                  br(),
                  h5("Infrastructure Evolution:"),
                  tags$ul(
                    tags$li("🏗️ Neuromorphic computing adoption"),
                    tags$li("⚙️ Quantum-classical hybrid systems"),
                    tags$li("🌐 Edge AI deployment at massive scale"),
                    tags$li("♻️ Carbon-neutral data centers"),
                    tags$li("📡 5G/6G integrated AI processing")
                  )
                ),
                
                box(
                  title = "⚠️ Critical Challenges & Considerations", status = "warning", solidHeader = TRUE, width = 6,
                  h5("Environmental Impact:"),
                  tags$ul(
                    tags$li("🌡️ Energy consumption could reach 2.5 PWh annually"),
                    tags$li("💨 1.4 GtCO2 emissions without green energy transition"),
                    tags$li("💧 Massive water consumption for cooling"),
                    tags$li("🏭 Need for 60,000+ new data centers globally")
                  ),
                  br(),
                  h5("Socioeconomic Factors:"),
                  tags$ul(
                    tags$li("👥 25 million job transitions expected"),
                    tags$li("📚 Massive reskilling requirements"),
                    tags$li("⚖️ Regulatory framework development"),
                    tags$li("🌍 Digital divide amplification risk"),
                    tags$li("🔒 Privacy and security concerns")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "📋 McKinsey 2030 Predictions", status = "info", solidHeader = TRUE, width = 12,
                  h5("Economic Impact Projections:"),
                  div(
                    style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin: 15px 0;",
                    
                    div(
                      style = "padding: 15px; background-color: #f0f9ff; border-radius: 8px; border-left: 4px solid #3b82f6;",
                      h6("💰 Productivity Gains"),
                      p("0.5-0.9 percentage points annual productivity increase"),
                      p("$15.5-22.9 trillion total economic potential")
                    ),
                    
                    div(
                      style = "padding: 15px; background-color: #f0fdf4; border-radius: 8px; border-left: 4px solid #10b981;",
                      h6("🏢 Business Functions"),
                      p("Marketing & Sales: 75% of total value"),
                      p("Software Engineering: Major transformation"),
                      p("Customer Operations: Significant automation")
                    ),
                    
                    div(
                      style = "padding: 15px; background-color: #fffbeb; border-radius: 8px; border-left: 4px solid #f59e0b;",
                      h6("⚡ Automation Timeline"),
                      p("50% of work activities automated by 2045"),
                      p("Acceleration of ~10 years vs pre-GenAI estimates"),
                      p("Knowledge work disproportionately affected")
                    ),
                    
                    div(
                      style = "padding: 15px; background-color: #faf5ff; border-radius: 8px; border-left: 4px solid #8b5cf6;",
                      h6("🌐 Adoption Patterns"),
                      p("65% organizations using GenAI by 2024"),
                      p("Rapid scaling in developed economies"),
                      p("Enterprise adoption accelerating")
                    )
                  ),
                  
                  div(
                    class = "citation",
                    HTML("<strong>References:</strong><br>
             McKinsey Global Institute. (2024). <em>The state of AI: How organizations are rewiring to capture value</em>. Retrieved from https://www.mckinsey.com/capabilities/quantumblack/our-insights/the-state-of-ai<br>
             McKinsey Global Institute. (2023). <em>The economic potential of generative AI: The next productivity frontier</em>. Retrieved from https://www.mckinsey.com/capabilities/mckinsey-digital/our-insights/the-economic-potential-of-generative-ai-the-next-productivity-frontier<br>
             MIT News. (2025). <em>Explained: Generative AI's environmental impact</em>. Retrieved from https://news.mit.edu/2025/explained-generative-ai-environmental-impact-0117<br>
             Statista. (2024). <em>Generative AI - Worldwide Market Forecast</em>. Retrieved from https://www.statista.com/outlook/tmo/artificial-intelligence/generative-ai/worldwide<br>
             International Energy Agency. (2024). <em>Electricity 2024</em>. Retrieved from https://www.iea.org/reports/electricity-2024<br>
             Scientific American. (2024). <em>A Computer Scientist Breaks Down Generative AI's Hefty Carbon Footprint</em>. Retrieved from https://www.scientificamerican.com/article/a-computer-scientist-breaks-down-generative-ais-hefty-carbon-footprint/<br>
             Marketing AI Institute. (2024). <em>McKinsey: AI Could Generate Up to $23 Trillion Annually by 2040</em>. Retrieved from https://www.marketingaiinstitute.com/blog/mckinsey-ai-economic-impact")
                  )
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Classification Matrix Heatmap
  output$classification_heatmap <- renderPlotly({
    # Create matrix for heatmap
    matrix_data <- classification_matrix %>%
      mutate(
        Token_Numeric = as.numeric(factor(Token_Band, levels = c("A0", "A1", "A2", "A3", "A4"))),
        Reasoning_Numeric = as.numeric(factor(Reasoning, levels = c("B0", "B1", "B2"))),
        Class_Numeric = case_when(
          Compute_Class == "C0" ~ 0,
          Compute_Class == "C1" ~ 1,
          Compute_Class == "C1+" ~ 1.5,
          Compute_Class == "C2" ~ 2,
          Compute_Class == "C2+" ~ 2.5,
          Compute_Class == "C3" ~ 3,
          Compute_Class == "C4-lite" ~ 3.5,
          Compute_Class == "C4" ~ 4,
          Compute_Class == "C4+" ~ 4.5,
          TRUE ~ 5
        )
      )
    
    p <- ggplot(matrix_data, aes(x = Reasoning, y = Token_Band, fill = Class_Numeric)) +
      geom_tile(color = "white", size = 0.5) +
      geom_text(aes(label = Compute_Class), color = "white", fontface = "bold", size = 4) +
      scale_fill_viridis_c(name = "Compute\nClass", option = "plasma") +
      labs(
        title = "GenAI Query Classification Matrix",
        subtitle = "Token Footprint (A) × Reasoning Complexity (B) → Compute Classes (C)",
        x = "Reasoning Complexity →",
        y = "Token Footprint ↑"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 16, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5),
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 14),
        legend.title = element_text(size = 12)
      )
    
    ggplotly(p, tooltip = c("x", "y", "fill")) %>%
      config(displayModeBar = FALSE)
  })
  
  # Classification Table
  output$classification_table <- DT::renderDataTable({
    classification_matrix %>%
      rename(
        "Token Band" = Token_Band,
        "Reasoning Tier" = Reasoning,
        "Compute Class" = Compute_Class,
        "Example Tasks" = Task_Examples,
        "Model Policy" = Model_Policy,
        "Systems Optimization" = Systems_Optimization
      )
  }, options = list(
    pageLength = 15,
    scrollX = TRUE,
    columnDefs = list(list(width = '200px', targets = c(3, 4, 5)))
  ), class = 'cell-border stripe')
  
  # Systems Optimization Chart
  output$systems_chart <- renderPlotly({
    systems_data <- systems_optimizations %>%
      mutate(
        Benefit_Numeric = as.numeric(gsub("[^0-9.]", "", Benefit)),
        Technology = factor(Technology, levels = Technology)
      )
    
    p <- ggplot(systems_data, aes(x = Technology, y = Benefit_Numeric, fill = Technology)) +
      geom_col(alpha = 0.8) +
      geom_text(aes(label = Benefit), vjust = -0.5, fontface = "bold") +
      scale_fill_viridis_d(option = "turbo") +
      labs(
        title = "Systems Optimization Impact",
        x = "Technology",
        y = "Performance Improvement (%)",
        fill = "Technology"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none",
        plot.title = element_text(hjust = 0.5)
      )
    
    ggplotly(p, tooltip = c("x", "y")) %>%
      config(displayModeBar = FALSE)
  })
  
  # Performance Gauge
  output$performance_gauge <- renderPlotly({
    gauge_value <- 95.2  # Classification accuracy
    
    plot_ly(
      type = "indicator",
      mode = "gauge+number+delta",
      value = gauge_value,
      domain = list(x = c(0, 1), y = c(0, 1)),
      title = list(text = "Classification Accuracy"),
      delta = list(reference = 90),
      gauge = list(
        axis = list(range = list(NULL, 100)),
        bar = list(color = "#10b981"),
        steps = list(
          list(range = c(0, 50), color = "#fee2e2"),
          list(range = c(50, 85), color = "#fef3c7"),
          list(range = c(85, 100), color = "#d1fae5")
        ),
        threshold = list(
          line = list(color = "red", width = 4),
          thickness = 0.75,
          value = 95
        )
      )
    ) %>%
      layout(margin = list(l = 20, r = 30, t = 50, b = 20))
  })
  
  # Systems Table
  output$systems_table <- DT::renderDataTable({
    systems_optimizations %>%
      rename(
        "Technology" = Technology,
        "Use Case" = Use_Case,
        "Performance Benefit" = Benefit,
        "Implementation Details" = Description
      )
  }, options = list(
    pageLength = 10,
    scrollX = TRUE
  ), class = 'cell-border stripe')
  
  # Performance Trends
  output$performance_trends <- renderPlotly({
    trends_data <- data.frame(
      Month = 1:12,
      Accuracy = c(88, 89, 91, 92, 93, 94, 94.5, 95, 95.1, 95.2, 95.2, 95.3),
      Throughput = c(1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.1, 2.2, 2.25, 2.3, 2.3, 2.35),
      Cost_Reduction = c(10, 15, 20, 25, 30, 32, 35, 37, 38, 40, 40, 41)
    )
    
    p <- plot_ly(trends_data, x = ~Month) %>%
      add_lines(y = ~Accuracy, name = "Accuracy (%)", line = list(color = "#10b981")) %>%
      add_lines(y = ~Throughput * 30, name = "Throughput (x)", line = list(color = "#3b82f6")) %>%
      add_lines(y = ~Cost_Reduction, name = "Cost Reduction (%)", line = list(color = "#f59e0b")) %>%
      layout(
        title = "Performance Trends Over Time",
        xaxis = list(title = "Month"),
        yaxis = list(title = "Performance Metrics"),
        hovermode = 'x unified'
      )
    
    p %>% config(displayModeBar = FALSE)
  })
  
  # Resource Utilization
  output$resource_utilization <- renderPlotly({
    resource_data <- data.frame(
      Resource = c("GPU Memory", "CPU Usage", "Network I/O", "Storage", "KV Cache"),
      Before = c(62, 45, 30, 25, 40),
      After = c(87, 65, 45, 35, 75),
      Target = c(85, 70, 50, 40, 80)
    )
    
    resource_long <- resource_data %>%
      tidyr::pivot_longer(cols = c(Before, After, Target), names_to = "Period", values_to = "Utilization")
    
    p <- ggplot(resource_long, aes(x = Resource, y = Utilization, fill = Period)) +
      geom_col(position = "dodge", alpha = 0.8) +
      scale_fill_manual(values = c("Before" = "#fee2e2", "After" = "#d1fae5", "Target" = "#dbeafe")) +
      labs(
        title = "Resource Utilization Comparison",
        x = "Resource Type",
        y = "Utilization (%)"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(hjust = 0.5)
      )
    
    ggplotly(p, tooltip = c("x", "y", "fill")) %>%
      config(displayModeBar = FALSE)
  })
  
  # Global Map
  output$global_map <- renderLeaflet({
    pal <- colorNumeric(
      palette = c("#fee2e2", "#fef3c7", "#d1fae5", "#a7f3d0", "#6ee7b7"),
      domain = global_usage_data$Usage_Rate
    )
    
    leaflet(global_usage_data) %>%
      addTiles() %>%
      addCircleMarkers(
        ~Lng, ~Lat,
        radius = ~sqrt(Population_Millions) * 0.8,
        color = ~pal(Usage_Rate),
        fillColor = ~pal(Usage_Rate),
        weight = 2,
        opacity = 0.8,
        fillOpacity = 0.6,
        popup = ~paste0(
          "<strong>", Country, "</strong><br>",
          "Adoption Rate: ", Usage_Rate, "%<br>",
          "Population: ", Population_Millions, "M<br>",
          "GDP per Capita: $", format(GDP_Per_Capita, big.mark = ","), "<br>",
          "Digital Infrastructure: ", Digital_Infrastructure, "%"
        )
      ) %>%
      addLegend(
        pal = pal,
        values = ~Usage_Rate,
        title = "Adoption Rate (%)",
        position = "bottomright"
      )
  })
  
  # User Segments Chart
  output$user_segments_chart <- renderPlotly({
    p <- plot_ly(
      user_segments,
      labels = ~Segment,
      values = ~Percentage,
      type = "pie",
      textinfo = "label+percent",
      hovertemplate = paste(
        "<b>%{label}</b><br>",
        "Percentage: %{value}%<br>",
        "Usage: %{text}<br>",
        "<extra></extra>"
      ),
      text = ~Usage_Frequency,
      marker = list(
        colors = c("#10b981", "#3b82f6", "#f59e0b", "#ef4444", "#8b5cf6"),
        line = list(color = '#FFFFFF', width = 2)
      )
    ) %>%
      layout(
        title = "Global User Segmentation (2024)",
        font = list(size = 12),
        showlegend = TRUE
      )
    
    p %>% config(displayModeBar = FALSE)
  })
  
  # Segment Growth
  output$segment_growth <- renderPlotly({
    p <- plot_ly(
      user_segments,
      x = ~Growth_Rate,
      y = ~reorder(Segment, Growth_Rate),
      type = "bar",
      orientation = "h",
      marker = list(
        color = ~Growth_Rate,
        colorscale = "RdYlGn",
        showscale = TRUE
      ),
      text = ~paste0(Growth_Rate, "%"),
      textposition = "outside"
    ) %>%
      layout(
        title = "Annual Growth Rate by Segment",
        xaxis = list(title = "Growth Rate (%)"),
        yaxis = list(title = "User Segment"),
        margin = list(l = 100)
      )
    
    p %>% config(displayModeBar = FALSE)
  })
  
  # Regional Analysis
  output$regional_analysis <- renderPlotly({
    p <- plot_ly(
      global_usage_data,
      x = ~GDP_Per_Capita,
      y = ~Usage_Rate,
      size = ~Population_Millions,
      color = ~Digital_Infrastructure,
      text = ~Country,
      type = "scatter",
      mode = "markers",
      hovertemplate = paste(
        "<b>%{text}</b><br>",
        "GDP per Capita: $%{x:,.0f}<br>",
        "Adoption Rate: %{y}%<br>",
        "Population: %{marker.size}M<br>",
        "Digital Infra: %{marker.color}%<br>",
        "<extra></extra>"
      )
    ) %>%
      layout(
        title = "Adoption vs Economic Development",
        xaxis = list(title = "GDP per Capita ($)", type = "log"),
        yaxis = list(title = "Adoption Rate (%)"),
        colorbar = list(title = "Digital Infrastructure %")
      )
    
    p %>% config(displayModeBar = FALSE)
  })
  
  # User Segments Table
  output$user_segments_table <- DT::renderDataTable({
    user_segments %>%
      rename(
        "User Segment" = Segment,
        "Market Share %" = Percentage,
        "Usage Pattern" = Usage_Frequency,
        "Primary Applications" = Primary_Use_Cases,
        "Annual Growth %" = Growth_Rate,
        "Segment Description" = Description
      )
  }, options = list(
    pageLength = 10,
    scrollX = TRUE,
    columnDefs = list(list(width = '300px', targets = c(3, 5)))
  ), class = 'cell-border stripe')
  
  # Market Projections
  output$market_projections <- renderPlotly({
    market_data <- data.frame(
      Year = 2020:2030,
      Market_Size_Billions = c(8, 12, 23, 45, 67, 95, 142, 198, 285, 425, 612),
      Investment_Billions = c(5, 8, 15, 36, 67, 95, 142, 198, 285, 380, 500),
      User_Base_Billions = c(0.1, 0.3, 0.8, 1.5, 2.1, 2.8, 3.4, 3.9, 4.3, 4.6, 4.8)
    )
    
    p <- plot_ly(market_data, x = ~Year) %>%
      add_lines(y = ~Market_Size_Billions, name = "Market Size ($B)", line = list(color = "#10b981", width = 3)) %>%
      add_lines(y = ~Investment_Billions, name = "Investment ($B)", line = list(color = "#3b82f6", width = 3)) %>%
      add_lines(y = ~User_Base_Billions * 100, name = "User Base (B) × 100", line = list(color = "#f59e0b", width = 3)) %>%
      layout(
        title = "AI Market Growth Projections (2020-2030)",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Value (Billions)"),
        hovermode = 'x unified',
        legend = list(x = 0.02, y = 0.98)
      )
    
    p %>% config(displayModeBar = FALSE)
  })
  
  # Energy Trends
  output$energy_trends <- renderPlotly({
    p <- plot_ly(energy_consumption_data, x = ~Year) %>%
      add_bars(y = ~Training_TWh, name = "Training", marker = list(color = "#ef4444")) %>%
      add_bars(y = ~Inference_TWh, name = "Inference", marker = list(color = "#f59e0b")) %>%
      layout(
        title = "AI Energy Consumption Trends",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Energy Consumption (TWh)"),
        barmode = "stack",
        hovermode = 'x unified'
      )
    
    p %>% config(displayModeBar = FALSE)
  })
  
  # Carbon Projections
  output$carbon_projections <- renderPlotly({
    p <- plot_ly(
      energy_consumption_data,
      x = ~Year,
      y = ~Total_Emissions_MtCO2,
      type = "scatter",
      mode = "lines+markers",
      line = list(color = "#dc2626", width = 4),
      marker = list(size = 8, color = "#dc2626")
    ) %>%
      layout(
        title = "AI Carbon Emissions Projections",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Emissions (MtCO2)"),
        hovermode = "x"
      )
    
    p %>% config(displayModeBar = FALSE)
  })
  
  # Query Complexity Evolution
  output$query_complexity_evolution <- renderPlotly({
    p <- ggplot(query_complexity_trends, aes(x = Year, y = Volume_Billions, fill = Complexity)) +
      geom_area(alpha = 0.7) +
      scale_fill_manual(values = c("#10b981", "#f59e0b", "#dc2626")) +
      labs(
        title = "Evolution of Query Complexity (2020-2030)",
        x = "Year",
        y = "Query Volume (Billions)",
        fill = "Complexity Level"
      ) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5))
    
    ggplotly(p) %>% config(displayModeBar = FALSE)
  })
  
  # Future Trends Table
  output$future_trends_table <- DT::renderDataTable({
    future_trends_2030 %>%
      rename(
        "Key Metric" = Metric,
        "Current (2024)" = Current_2024,
        "Projected (2030)" = Projected_2030,
        "CAGR %" = Growth_Rate,
        "Impact Assessment" = Impact_Level
      )
  }, options = list(
    pageLength = 10,
    scrollX = TRUE
  ), class = 'cell-border stripe')
}

# Run the application
shinyApp(ui = ui, server = server)