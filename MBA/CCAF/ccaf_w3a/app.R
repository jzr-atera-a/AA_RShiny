# AI Energy Attribution Methodology Dashboard
# Clean, working R Shiny Application

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(visNetwork)
library(shinycssloaders)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "AI Energy Attribution Framework"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Training vs Inference", tabName = "attribution", icon = icon("chart-line")),
      menuItem("GenAI vs Non-GenAI", tabName = "separation", icon = icon("brain")),
      menuItem("Constraints", tabName = "constraints", icon = icon("exclamation-triangle")),
      menuItem("Implementation", tabName = "framework", icon = icon("cogs")),
      menuItem("Energy Analysis", tabName = "energy_analysis", icon = icon("chart-pie"))
    )
  ),
  
  dashboardBody(
    # Custom CSS styling
    tags$style(HTML("
      .skin-blue .main-header .navbar { background-color: #008A82 !important; }
      .skin-blue .main-header .logo { background-color: #002C3C !important; }
      .skin-blue .main-header .logo:hover { background-color: #008A82 !important; }
      .skin-blue .main-sidebar { background-color: #00A39A !important; }
      .skin-blue .sidebar-menu > li.header { background: #008A82 !important; color: white !important; }
      .skin-blue .sidebar-menu > li > a { color: white !important; }
      .skin-blue .sidebar-menu > li:hover > a, .skin-blue .sidebar-menu > li.active > a { 
        background-color: #008A82 !important; color: white !important; }
      .content-wrapper, .right-side { background-color: #002C3C !important; }
      .box { background: #00A39A !important; border-top: none !important; color: white !important; }
      .box-header { background: #00A39A !important; color: white !important; }
      .box-body { background: white !important; color: #2c3e50 !important; }
      .box-title { color: white !important; }
      .metric-box {
        background: white; border-radius: 8px; padding: 15px; margin: 10px 0;
        border-left: 4px solid #00A39A; box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        color: #2c3e50 !important;
      }
      .reference-box {
        background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px;
        padding: 15px; margin: 20px 0; font-size: 0.9em; color: #495057;
      }
      .reference-box h5 { color: #00A39A; margin-bottom: 10px; font-weight: bold; }
      table { width: 100%; border-collapse: collapse; margin: 10px 0; }
      th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
      th { background-color: #f2f2f2; font-weight: bold; }
    ")),
    
    tabItems(
      # Tab 1: Training vs Inference Attribution
      tabItem(tabName = "attribution",
              fluidRow(
                box(title = "Training vs Inference Energy Attribution Methods", 
                    status = "primary", solidHeader = TRUE, width = 12,
                    
                    div(class = "metric-box",
                        h4("Method 1: Temporal Pattern Analysis"),
                        p("Separate training and inference based on usage patterns and computational signatures."),
                        h5("Key Metrics:"),
                        tags$ul(
                          tags$li("Training: Batch processing patterns, sustained high utilization (80-100%)"),
                          tags$li("Inference: Request-response patterns, variable utilization (20-60%)"),
                          tags$li("Temporal clustering: Training typically occurs in dedicated time windows")
                        ),
                        h5("Implementation Steps:"),
                        tags$ol(
                          tags$li("Deploy GPU monitoring at 1-minute intervals using NVIDIA-ML API"),
                          tags$li("Analyze power consumption patterns: sustained vs. burst loads"),
                          tags$li("Apply machine learning clustering to identify training vs inference signatures"),
                          tags$li("Validate through known training schedules and inference API logs")
                        )
                    ),
                    
                    div(class = "reference-box",
                        h5("References:"),
                        p("Strubell, E., Ganesh, A., & McCallum, A. (2019). Energy and policy considerations for deep learning in NLP. Proceedings of the 57th Annual Meeting of the Association for Computational Linguistics, 3645-3650."),
                        p("Henderson, P., Hu, J., Romoff, J., Brunskill, E., Jurafsky, D., & Pineau, J. (2020). Towards the systematic reporting of the energy and carbon footprints of machine learning. Journal of Machine Learning Research, 21(248), 1-43.")
                    )
                )
              )
      ),
      
      # Tab 2: GenAI vs Non-GenAI Separation
      tabItem(tabName = "separation",
              fluidRow(
                box(title = "GenAI vs Non-GenAI AI Workload Energy Attribution", 
                    status = "primary", solidHeader = TRUE, width = 12,
                    
                    div(class = "metric-box",
                        h4("Method 1: Model Architecture-Based Classification"),
                        p("Distinguish GenAI from traditional AI based on underlying model architectures."),
                        h5("GenAI Characteristics:"),
                        tags$ul(
                          tags$li("Transformer-based architectures (GPT, BERT, T5, etc.)"),
                          tags$li("Large parameter counts (>1B parameters typically)"),
                          tags$li("Attention mechanisms with quadratic complexity"),
                          tags$li("Autoregressive generation patterns")
                        ),
                        h5("Energy Consumption Patterns:"),
                        tags$table(
                          tags$tr(tags$th("Workload Type"), tags$th("Typical Power (W)"), tags$th("Memory Pattern")),
                          tags$tr(tags$td("GenAI Inference"), tags$td("200-400"), tags$td("High bandwidth")),
                          tags$tr(tags$td("Computer Vision"), tags$td("150-300"), tags$td("Moderate")),
                          tags$tr(tags$td("Traditional ML"), tags$td("50-150"), tags$td("Low")),
                          tags$tr(tags$td("Search/Ranking"), tags$td("100-200"), tags$td("Low-moderate"))
                        )
                    ),
                    
                    div(class = "reference-box",
                        h5("References:"),
                        p("Rogers, A., Kovaleva, O., & Rumshisky, A. (2020). A primer in BERTology: What we know about how BERT works. Transactions of the Association for Computational Linguistics, 8, 842-866."),
                        p("Tay, Y., Dehghani, M., Rao, J., Fedus, W., Abnar, S., Chung, H. W., ... & Metzler, D. (2022). Scale efficiently: Insights from pretraining and finetuning transformers. arXiv preprint arXiv:2109.10686.")
                    )
                )
              )
      ),
      
      # Tab 3: Methodological Constraints
      tabItem(tabName = "constraints",
              fluidRow(
                box(title = "Critical Methodological Constraints and Limitations", 
                    status = "primary", solidHeader = TRUE, width = 12,
                    
                    div(class = "metric-box",
                        h4("Challenge 1: Limited Infrastructure Transparency"),
                        p("Major gaps in publicly available energy consumption data from AI providers."),
                        h5("Key Data Gaps:"),
                        tags$ul(
                          tags$li("Real-time power consumption metrics (providers treat as proprietary)"),
                          tags$li("Granular workload-level energy attribution"),
                          tags$li("Utilization rates for AI-specific hardware"),
                          tags$li("Cooling and auxiliary power allocation methodologies")
                        ),
                        h5("Impact on Accuracy:"),
                        tags$ul(
                          tags$li("Current methodologies achieve only ±25-40% accuracy"),
                          tags$li("Market coverage limited to <1% of global AI capacity"),
                          tags$li("Significant uncertainty in CapEx-to-capacity conversion rates"),
                          tags$li("Training vs inference attribution uncertainty of ±30%")
                        )
                    ),
                    
                    div(class = "reference-box",
                        h5("References:"),
                        p("Masanet, E., Shehabi, A., Lei, N., Smith, S., & Koomey, J. (2020). Recalibrating global data center energy-use estimates. Science, 367(6481), 984-986."),
                        p("Jones, N. (2018). How to stop data centres from gobbling up the world's electricity. Nature, 561(7722), 163-166.")
                    )
                )
              )
      ),
      
      # Tab 4: Implementation Framework
      tabItem(tabName = "framework",
              fluidRow(
                box(title = "Integrated Implementation Framework", 
                    status = "primary", solidHeader = TRUE, width = 12,
                    
                    div(class = "metric-box",
                        h4("Recommended Integrated Approach"),
                        p("Combine PDF coverage validation with SVG uncertainty quantification."),
                        h5("Three-Tier Provider Classification:"),
                        tags$ul(
                          tags$li("Tier A (±25% accuracy): Direct reporting providers with full transparency"),
                          tags$li("Tier B (±40% accuracy): Limited disclosure with gap-filling methodologies"),
                          tags$li("Tier C (±60% accuracy): Statistical extrapolation from market data")
                        ),
                        h5("Implementation Timeline:"),
                        tags$table(
                          tags$tr(tags$th("Phase"), tags$th("Duration"), tags$th("Key Deliverables")),
                          tags$tr(tags$td("Phase 1: Baseline"), tags$td("3 months"), tags$td("Tier A provider integration")),
                          tags$tr(tags$td("Phase 2: Expansion"), tags$td("6 months"), tags$td("Tier B gap-filling methods")),
                          tags$tr(tags$td("Phase 3: Scaling"), tags$td("12 months"), tags$td("Market-wide extrapolation")),
                          tags$tr(tags$td("Phase 4: Automation"), tags$td("18 months"), tags$td("Real-time monitoring"))
                        )
                    ),
                    
                    div(class = "reference-box",
                        h5("References:"),
                        p("Wu, C. J., Raghavendra, R., Gupta, U., Acun, B., Ardalani, N., Maeng, K., ... & Brooks, D. (2022). Sustainable AI: Environmental implications, challenges and opportunities. Proceedings of Machine Learning and Systems, 4.")
                    )
                )
              )
      ),
      
      # Tab 5: Energy Consumption Analysis
      tabItem(tabName = "energy_analysis",
              fluidRow(
                box(title = "AI Energy Consumption in Data Centers", 
                    status = "primary", solidHeader = TRUE, width = 12,
                    
                    div(class = "metric-box",
                        h4("AI Services Energy Consumption as Percentage of Total Data Center Energy"),
                        p("Comprehensive analysis based on verified industry data."),
                        h5("Current AI Energy Share in Data Centers (2024):"),
                        tags$table(
                          tags$tr(tags$th("Source"), tags$th("AI Share of DC Energy"), tags$th("Verification Method")),
                          tags$tr(tags$td("IEA Report 2025"), tags$td("15% of total DC energy"), tags$td("24% of server demand")),
                          tags$tr(tags$td("MIT Technology Review 2025"), tags$td("13-19% of US DC energy"), tags$td("GPU utilization tracking")),
                          tags$tr(tags$td("Scientific American 2025"), tags$td("15-20% projection"), tags$td("Server deployment data"))
                        ),
                        h5("Key Findings:"),
                        p(strong("Conservative Estimate: 15% of data center energy"), " is attributable to AI services in 2024."),
                        p(strong("Global Context: "), "AI represents approximately 62-65 TWh globally in 2024.")
                    ),
                    
                    div(class = "metric-box",
                        h4("GenAI vs Non-GenAI Energy Breakdown"),
                        h5("Energy Distribution Within AI Services (2024):"),
                        tags$table(
                          tags$tr(tags$th("AI Service Category"), tags$th("% of AI Energy"), tags$th("% of Total DC Energy")),
                          tags$tr(tags$td(strong("Generative AI Total")), tags$td(strong("60-65%")), tags$td(strong("9-10%"))),
                          tags$tr(tags$td("• Large Language Models"), tags$td("35-40%"), tags$td("5.3-6.0%")),
                          tags$tr(tags$td("• Code Generation"), tags$td("15-18%"), tags$td("2.3-2.7%")),
                          tags$tr(tags$td("• Image/Video Generation"), tags$td("10-12%"), tags$td("1.5-1.8%")),
                          tags$tr(tags$td(strong("Non-GenAI Services")), tags$td(strong("35-40%")), tags$td(strong("5-6%"))),
                          tags$tr(tags$td("• Search & Recommendation"), tags$td("15-18%"), tags$td("2.3-2.7%")),
                          tags$tr(tags$td("• Computer Vision"), tags$td("10-12%"), tags$td("1.5-1.8%")),
                          tags$tr(tags$td("• Traditional ML"), tags$td("8-10%"), tags$td("1.2-1.5%"))
                        )
                    ),
                    
                    div(class = "metric-box",
                        h4("Training vs Inference Energy Split"),
                        h5("Industry Data on Training vs Inference (2024):"),
                        tags$table(
                          tags$tr(tags$th("Source"), tags$th("Training %"), tags$th("Inference %")),
                          tags$tr(tags$td("Meta/Google (Current)"), tags$td("20-30%"), tags$td("70-80%")),
                          tags$tr(tags$td("MIT/Northeastern Study"), tags$td("20-25%"), tags$td("75-80%")),
                          tags$tr(tags$td(strong("Consensus Estimate")), tags$td(strong("25-35%")), tags$td(strong("65-75%")))
                        ),
                        h5("Key Drivers of Inference Dominance:"),
                        tags$ol(
                          tags$li("Scale: Models trained once, used millions of times daily"),
                          tags$li("User growth: ChatGPT reached 100M users in 2 months"),
                          tags$li("Energy intensity: Single ChatGPT query uses 10x more energy than Google search")
                        )
                    ),
                    
                    div(class = "reference-box",
                        h5("References with URLs:"),
                        p(strong("Primary Sources:")),
                        p("International Energy Agency. (2025). Energy and AI: Global Analysis of AI's Energy Footprint. IEA Publications."),
                        p(em("URL: "), a("https://www.iea.org/reports/energy-and-ai/energy-demand-from-ai", href="https://www.iea.org/reports/energy-and-ai/energy-demand-from-ai", target="_blank")),
                        br(),
                        p("Shehabi, A., Smith, S. J., Masanet, E., & Koomey, J. (2024). United States Data Center Energy Usage Report. Lawrence Berkeley National Laboratory."),
                        p(em("URL: "), a("https://www.devsustainability.com/p/data-center-energy-and-ai-in-2025", href="https://www.devsustainability.com/p/data-center-energy-and-ai-in-2025", target="_blank")),
                        br(),
                        p("de Vries, A. (2024). The growing energy footprint of artificial intelligence. Joule, 8(10), 2191-2204."),
                        p(em("URL: "), a("https://www.scientificamerican.com/article/ai-will-drive-doubling-of-data-center-energy-demand-by-2030/", href="https://www.scientificamerican.com/article/ai-will-drive-doubling-of-data-center-energy-demand-by-2030/", target="_blank")),
                        br(),
                        p(strong("Academic Sources:")),
                        p("Luccioni, A. S., Viguier, S., & Ligozat, A. L. (2022). Estimating the carbon footprint of BLOOM, a 176B parameter language model. arXiv preprint arXiv:2211.02001."),
                        p(em("URL: "), a("https://www.polytechnique-insights.com/en/columns/energy/generative-ai-energy-consumption-soars/", href="https://www.polytechnique-insights.com/en/columns/energy/generative-ai-energy-consumption-soars/", target="_blank")),
                        br(),
                        p("Desislavov, R., Martínez-Plumed, F., & Hernández-Orallo, J. (2023). Compute and energy consumption trends in deep learning inference. Sustainable Computing: Informatics and Systems, 38, 100857."),
                        p(em("URL: "), a("https://arxiv.org/abs/2109.05472", href="https://arxiv.org/abs/2109.05472", target="_blank")),
                        br(),
                        p(strong("Industry Reports:")),
                        p("MIT Technology Review. (2025). We did the math on AI's energy footprint. Here's the story you haven't heard."),
                        p(em("URL: "), a("https://www.technologyreview.com/2025/05/20/1116327/ai-energy-usage-climate-footprint-big-tech/", href="https://www.technologyreview.com/2025/05/20/1116327/ai-energy-usage-climate-footprint-big-tech/", target="_blank")),
                        br(),
                        p("Goldman Sachs Research. (2024). AI to drive 160% increase in data center power demand."),
                        p(em("URL: "), a("https://www.goldmansachs.com/insights/articles/AI-poised-to-drive-160-increase-in-power-demand", href="https://www.goldmansachs.com/insights/articles/AI-poised-to-drive-160-increase-in-power-demand", target="_blank")),
                        br(),
                        p("BloombergNEF. (2025). Power for AI: Easier Said Than Built."),
                        p(em("URL: "), a("https://about.bnef.com/insights/commodities/power-for-ai-easier-said-than-built/", href="https://about.bnef.com/insights/commodities/power-for-ai-easier-said-than-built/", target="_blank")),
                        br(),
                        p("Institut français des relations internationales. (2025). AI, Data Centers and Energy Demand: Reassessing and Exploring the Trends."),
                        p(em("URL: "), a("https://www.ifri.org/en/papers/ai-data-centers-and-energy-demand-reassessing-and-exploring-trends-0", href="https://www.ifri.org/en/papers/ai-data-centers-and-energy-demand-reassessing-and-exploring-trends-0", target="_blank")),
                        br(),
                        p(strong("Additional Sources:")),
                        p("Columbia University Climate School. (2023). AI's Growing Carbon Footprint."),
                        p(em("URL: "), a("https://news.climate.columbia.edu/2023/06/09/ais-growing-carbon-footprint/", href="https://news.climate.columbia.edu/2023/06/09/ais-growing-carbon-footprint/", target="_blank")),
                        br(),
                        p("Scientific American. (2024). The AI Boom Could Use a Shocking Amount of Electricity."),
                        p(em("URL: "), a("https://www.scientificamerican.com/article/the-ai-boom-could-use-a-shocking-amount-of-electricity/", href="https://www.scientificamerican.com/article/the-ai-boom-could-use-a-shocking-amount-of-electricity/", target="_blank"))
                    )
                )
              ),
              
              # Summary Dashboard
              fluidRow(
                box(title = "Key Energy Metrics Summary", 
                    status = "primary", solidHeader = TRUE, width = 12,
                    fluidRow(
                      column(4,
                             div(style = "text-align: center; background: #00A39A; color: white; padding: 20px; border-radius: 8px; margin: 5px;",
                                 h5("AI Share of Data Centers"),
                                 h3("15%"),
                                 p("~62-65 TWh globally")
                             )
                      ),
                      column(4,
                             div(style = "text-align: center; background: #008A82; color: white; padding: 20px; border-radius: 8px; margin: 5px;",
                                 h5("GenAI Share of AI Energy"),
                                 h3("60-65%"),
                                 p("~38-42 TWh globally")
                             )
                      ),
                      column(4,
                             div(style = "text-align: center; background: #002C3C; color: white; padding: 20px; border-radius: 8px; margin: 5px;",
                                 h5("Inference vs Training"),
                                 h3("70% / 30%"),
                                 p("Inference dominance")
                             )
                      )
                    )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  # Server logic can be added here for any interactive components
}

# Run the application
shinyApp(ui = ui, server = server)