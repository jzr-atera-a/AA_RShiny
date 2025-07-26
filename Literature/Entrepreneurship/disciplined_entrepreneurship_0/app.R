library(shiny)
library(shinydashboard)
library(DT)
library(plotly)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Disciplined Entrepreneurship Framework"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Customer Identification", tabName = "customer", icon = icon("users")),
      menuItem("Value Proposition", tabName = "value", icon = icon("lightbulb")),
      menuItem("Customer Acquisition", tabName = "acquisition", icon = icon("handshake")),
      menuItem("Revenue Model", tabName = "revenue", icon = icon("dollar-sign")),
      menuItem("Product Development", tabName = "product", icon = icon("cogs")),
      menuItem("Business Scaling", tabName = "scaling", icon = icon("chart-line"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
       /* Header styling */
       .skin-blue .main-header .navbar {
         background-color: #FF8C00 !important;
       }
       .skin-blue .main-header .logo {
         background-color: #FF8C00 !important;
         color: #000000 !important;
         border-bottom: 0 solid transparent;
       }
       .skin-blue .main-header .logo:hover {
         background-color: #FF7F00 !important;
       }
       
       /* Sidebar styling */
       .skin-blue .main-sidebar {
         background-color: #B8860B !important;
       }
       .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
         background-color: #FFD700 !important;
         color: #000000 !important;
         font-weight: bold;
       }
       .skin-blue .main-sidebar .sidebar .sidebar-menu a {
         color: #000000 !important;
       }
       .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
         background-color: #DAA520 !important;
         color: #000000 !important;
       }
       
       /* Content wrapper styling */
       .content-wrapper {
         background-color: #FFF8DC !important;
       }
       
       /* Box styling */
       .box {
         background-color: #FFFFE0 !important;
         border: 2px solid #DAA520 !important;
         border-radius: 8px !important;
         box-shadow: 0 4px 8px rgba(218, 165, 32, 0.3) !important;
       }
       .box.box-primary {
         border-top-color: #FF8C00 !important;
         border-top-width: 4px !important;
       }
       .box.box-primary .box-header {
         color: #000000 !important;
         background: linear-gradient(135deg, #FF8C00, #FFD700) !important;
         border-radius: 6px 6px 0 0 !important;
         border-bottom: 2px solid #DAA520 !important;
       }
       .box.box-primary .box-header .box-title {
         font-size: 18px !important;
         font-weight: bold !important;
         text-shadow: 1px 1px 2px rgba(0,0,0,0.1) !important;
       }
       .box-body {
         background-color: #FFFACD !important;
         color: #333333 !important;
         padding: 20px !important;
       }
       
       /* Text styling */
       p {
         color: #2F4F4F !important;
         line-height: 1.6 !important;
       }
       strong {
         color: #B8860B !important;
       }
       li {
         color: #2F4F4F !important;
         margin-bottom: 5px !important;
       }
       
       /* Example box styling */
       .example-box {
         background-color: #F0E68C !important;
         border: 1px solid #DAA520 !important;
         border-radius: 5px !important;
         padding: 10px !important;
         margin: 10px 0 !important;
       }
       
       /* Benefits and disadvantages styling */
       .benefits {
         background-color: #E6FFE6 !important;
         border-left: 4px solid #228B22 !important;
         padding: 10px !important;
         margin: 10px 0 !important;
       }
       
       .disadvantages {
         background-color: #FFE6E6 !important;
         border-left: 4px solid #DC143C !important;
         padding: 10px !important;
         margin: 10px 0 !important;
       }
       
       /* Link styling */
       a {
         color: #FF8C00 !important;
         text-decoration: none !important;
       }
       a:hover {
         color: #FF7F00 !important;
         text-decoration: underline !important;
       }
       
       /* Page title styling */
       .main-header .navbar-brand {
         color: #000000 !important;
         font-weight: bold !important;
       }
       
       /* Scrollbar styling */
       ::-webkit-scrollbar {
         width: 12px;
       }
       ::-webkit-scrollbar-track {
         background: #FFF8DC;
       }
       ::-webkit-scrollbar-thumb {
         background: #DAA520;
         border-radius: 6px;
       }
       ::-webkit-scrollbar-thumb:hover {
         background: #B8860B;
       }"
      ))
    ),
    
    tabItems(
      # Customer Identification Tab
      tabItem(tabName = "customer",
              fluidRow(
                box(title = "Step 1: Market Segmentation", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Identify and evaluate potential markets systematically."),
                    p("Market segmentation involves dividing the total market into distinct groups based on characteristics like industry, geography, application, and buyer type. Research shows that startups focusing on well-defined segments are 3x more likely to succeed."),
                    div(class = "benefits",
                        h4("Key Benefits:"),
                        tags$ul(
                          tags$li("Reduces market confusion and resource waste"),
                          tags$li("Enables targeted marketing campaigns"),
                          tags$li("Improves product-market fit probability")
                        )
                    ),
                    div(class = "example-box",
                        h4("Industry Trend:"),
                        p("B2B SaaS companies that segment by company size see 40% better conversion rates than those using broad targeting.")
                    )
                ),
                box(title = "Step 2: Select a Beachhead Market", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Choose one initial target market to dominate completely."),
                    p("The beachhead strategy, popularized by Geoffrey Moore, suggests attacking a small, specific market segment first. Statistics show that 74% of high-growth startups focused on a single market initially."),
                    div(class = "benefits",
                        h4("Selection Criteria:"),
                        tags$ul(
                          tags$li("Market size: $20M-$100M annual revenue potential"),
                          tags$li("Customers have urgent, unmet needs"),
                          tags$li("Limited competition or inferior solutions"),
                          tags$li("Reachable through known channels")
                        )
                    ),
                    div(class = "example-box",
                        h4("Success Example:"),
                        p("Facebook started with college students before expanding globally - classic beachhead strategy.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 3: Build an End User Profile", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Create a detailed persona of your archetypal end user."),
                    p("Detailed user personas increase marketing effectiveness by 73% and improve product development focus. Include demographics, psychographics, behavior patterns, and pain points."),
                    div(class = "benefits",
                        h4("Essential Elements:"),
                        tags$ul(
                          tags$li("Demographics: Age, income, education, location"),
                          tags$li("Job role and responsibilities"),
                          tags$li("Daily workflow and challenges"),
                          tags$li("Technology adoption patterns"),
                          tags$li("Information consumption habits")
                        )
                    ),
                    div(class = "example-box",
                        h4("Research Insight:"),
                        p("Companies using detailed personas see 2-5x higher engagement rates and 3x better conversion rates.")
                    )
                ),
                box(title = "Step 4: Calculate TAM for Beachhead", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Quantify the total revenue opportunity in your beachhead market."),
                    p("TAM calculation helps validate market opportunity and attract investors. Use bottom-up analysis: Number of potential customers × Average Revenue Per User (ARPU)."),
                    div(class = "benefits",
                        h4("Calculation Framework:"),
                        tags$ul(
                          tags$li("Identify total addressable customers"),
                          tags$li("Estimate realistic pricing"),
                          tags$li("Account for market penetration limits"),
                          tags$li("Consider competitive landscape")
                        )
                    ),
                    div(class = "example-box",
                        h4("Benchmark:"),
                        p("Successful B2B startups typically target markets with $50M+ TAM to justify VC investment.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 5: Profile Persona for Beachhead", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Create a vivid, specific narrative of your ideal customer."),
                    p("Deep persona profiling enables precise targeting and message crafting. Research indicates that personalized marketing delivers 6x higher transaction rates."),
                    div(class = "benefits",
                        h4("Profiling Elements:"),
                        tags$ul(
                          tags$li("Motivations and goals"),
                          tags$li("Key influencers and information sources"),
                          tags$li("Decision-making process"),
                          tags$li("Budget authority and constraints"),
                          tags$li("Success metrics and KPIs")
                        )
                    )
                ),
                box(title = "Step 6: Full Life Cycle Use Case", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Map complete customer journey from awareness to renewal."),
                    p("Understanding the full lifecycle improves customer experience and reduces churn. Companies mapping complete customer journeys see 30% improvement in customer satisfaction."),
                    div(class = "benefits",
                        h4("Lifecycle Stages:"),
                        tags$ul(
                          tags$li("Awareness and research phase"),
                          tags$li("Evaluation and trial"),
                          tags$li("Purchase and onboarding"),
                          tags$li("Usage and optimization"),
                          tags$li("Renewal and expansion")
                        )
                    )
                )
              )
      ),
      
      # Value Proposition Tab
      tabItem(tabName = "value",
              fluidRow(
                box(title = "Step 7: High-Level Product Specification", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Define your product's visual and functional specifications."),
                    p("Clear product specifications reduce development time by 25% and improve team alignment. Focus on benefits rather than features to maintain customer-centric thinking."),
                    div(class = "benefits",
                        h4("Specification Components:"),
                        tags$ul(
                          tags$li("Visual mockups and wireframes"),
                          tags$li("Core functionality description"),
                          tags$li("User interface requirements"),
                          tags$li("Integration capabilities"),
                          tags$li("Performance benchmarks")
                        )
                    ),
                    div(class = "example-box",
                        h4("Best Practice:"),
                        p("Use the 'Jobs to be Done' framework - customers hire products to accomplish specific jobs.")
                    )
                ),
                box(title = "Step 8: Quantify Value Proposition", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Define measurable improvements your solution provides."),
                    p("Quantified value propositions increase sales effectiveness by 40%. Transform qualitative benefits into specific, measurable outcomes that customers can evaluate."),
                    div(class = "benefits",
                        h4("Value Metrics:"),
                        tags$ul(
                          tags$li("Cost reduction percentages"),
                          tags$li("Time savings (hours/week)"),
                          tags$li("Revenue increase potential"),
                          tags$li("Efficiency improvements"),
                          tags$li("Risk mitigation value")
                        )
                    ),
                    div(class = "example-box",
                        h4("Formula:"),
                        p("Value = (Current Cost - New Cost) + (New Benefits) - (Implementation Cost)")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 9: Identify Next 10 Customers", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Validate demand by identifying real potential customers."),
                    p("Customer validation reduces startup failure risk by 60%. Real customer conversations provide insights that surveys and market research cannot capture."),
                    div(class = "benefits",
                        h4("Validation Activities:"),
                        tags$ul(
                          tags$li("Conduct problem interviews"),
                          tags$li("Present solution concepts"),
                          tags$li("Test pricing sensitivity"),
                          tags$li("Identify decision makers"),
                          tags$li("Understand buying process")
                        )
                    ),
                    div(class = "example-box",
                        h4("Success Metric:"),
                        p("7 out of 10 target customers should confirm the problem exists and express purchase intent.")
                    )
                ),
                box(title = "Step 10: Define Your Core", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Identify your key competitive differentiator."),
                    p("Companies with strong core differentiators achieve 3x higher profit margins. Your core should be difficult for competitors to replicate and central to customer value."),
                    div(class = "benefits",
                        h4("Core Types:"),
                        tags$ul(
                          tags$li("Proprietary technology or algorithms"),
                          tags$li("Unique data assets"),
                          tags$li("Network effects"),
                          tags$li("Superior processes"),
                          tags$li("Exclusive partnerships")
                        )
                    ),
                    div(class = "example-box",
                        h4("Test Question:"),
                        p("Would your core advantage take competitors 12+ months and significant resources to replicate?")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 11: Chart Competitive Position", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("Objective:"), "Position your product uniquely in the competitive landscape."),
                    p("Effective competitive positioning increases market share by 25%. Use a two-axis matrix to show clear differentiation from existing alternatives."),
                    div(class = "benefits",
                        h4("Positioning Strategy:"),
                        tags$ul(
                          tags$li("Choose axes that matter to customers"),
                          tags$li("Position in unique quadrant"),
                          tags$li("Avoid overcrowded segments"),
                          tags$li("Highlight sustainable advantages"),
                          tags$li("Consider future competitive moves")
                        )
                    ),
                    plotlyOutput("competitiveMatrix", height = "300px")
                )
              )
      ),
      
      # Customer Acquisition Tab
      tabItem(tabName = "acquisition",
              fluidRow(
                box(title = "Step 12: Determine Decision-Making Unit", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Identify all stakeholders in the buying process."),
                    p("B2B purchases involve 6.8 people on average. Understanding the complete Decision-Making Unit (DMU) improves sales success rates by 50%."),
                    div(class = "benefits",
                        h4("DMU Roles:"),
                        tags$ul(
                          tags$li("Champion: Internal advocate"),
                          tags$li("Economic Buyer: Budget authority"),
                          tags$li("Technical Buyer: Evaluates specifications"),
                          tags$li("User Buyer: End users"),
                          tags$li("Coach: Provides inside information")
                        )
                    ),
                    div(class = "example-box",
                        h4("Enterprise Insight:"),
                        p("Enterprise sales cycles are 40% shorter when all DMU members are identified early.")
                    )
                ),
                box(title = "Step 13: Map Customer Acquisition Process", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Understand each step from awareness to purchase."),
                    p("Mapped acquisition processes reduce customer acquisition costs by 30%. Identify friction points, approval stages, and optimization opportunities."),
                    div(class = "benefits",
                        h4("Process Stages:"),
                        tags$ul(
                          tags$li("Problem recognition"),
                          tags$li("Solution research"),
                          tags$li("Vendor evaluation"),
                          tags$li("Proposal and negotiation"),
                          tags$li("Final approval and purchase")
                        )
                    ),
                    div(class = "example-box",
                        h4("Optimization Tip:"),
                        p("Remove one friction point to improve conversion rates by 15-25%.")
                    )
                )
              ),
              fluidRow(
                box(title = "Sales Funnel Analysis", status = "primary", solidHeader = TRUE, width = 12,
                    p("Interactive sales funnel showing conversion rates at each stage:"),
                    plotlyOutput("salesFunnel", height = "400px")
                )
              )
      ),
      
      # Revenue Model Tab
      tabItem(tabName = "revenue",
              fluidRow(
                box(title = "Step 14: Calculate Customer Acquisition Cost", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Determine the total cost to acquire one customer."),
                    p("CAC optimization can improve startup survival rates by 45%. Include all sales and marketing expenses: salaries, advertising, tools, travel, and overhead."),
                    div(class = "benefits",
                        h4("CAC Components:"),
                        tags$ul(
                          tags$li("Sales team salaries and commissions"),
                          tags$li("Marketing campaign costs"),
                          tags$li("Software tools and platforms"),
                          tags$li("Travel and entertainment"),
                          tags$li("Allocated overhead expenses")
                        )
                    ),
                    div(class = "example-box",
                        h4("Benchmark:"),
                        p("SaaS companies: CAC should be recovered within 12 months of customer acquisition.")
                    )
                ),
                box(title = "Step 15: Identify Key Assumptions", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Document major unknowns in your business model."),
                    p("Assumption validation reduces business model risk by 70%. Test critical assumptions early through experiments and customer feedback."),
                    div(class = "benefits",
                        h4("Common Assumptions:"),
                        tags$ul(
                          tags$li("Customer adoption rate"),
                          tags$li("Price sensitivity"),
                          tags$li("Market size estimates"),
                          tags$li("Competitive response"),
                          tags$li("Technology scalability")
                        )
                    ),
                    div(class = "example-box",
                        h4("Testing Framework:"),
                        p("Use hypothesis-driven experiments with clear success/failure criteria.")
                    )
                )
              ),
              fluidRow(
                box(title = "Financial Metrics Dashboard", status = "primary", solidHeader = TRUE, width = 12,
                    fluidRow(
                      column(width = 4,
                             numericInput("customerPrice", "Customer Price ($)", value = 100, min = 1),
                             numericInput("customerLifetime", "Customer Lifetime (months)", value = 24, min = 1),
                             numericInput("churnRate", "Monthly Churn Rate (%)", value = 5, min = 0, max = 100)
                      ),
                      column(width = 4,
                             numericInput("acquisitionCost", "Customer Acquisition Cost ($)", value = 200, min = 1),
                             numericInput("grossMargin", "Gross Margin (%)", value = 80, min = 0, max = 100)
                      ),
                      column(width = 4,
                             h4("Calculated Metrics:"),
                             verbatimTextOutput("ltvOutput"),
                             verbatimTextOutput("ltvCacRatio"),
                             verbatimTextOutput("paybackPeriod")
                      )
                    )
                )
              )
      ),
      
      # Product Development Tab
      tabItem(tabName = "product",
              fluidRow(
                box(title = "Step 16: Test Key Assumptions", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Validate critical business assumptions through experimentation."),
                    p("Assumption testing reduces product failure risk by 60%. Use lean startup methodology to run controlled experiments and gather data-driven insights."),
                    div(class = "benefits",
                        h4("Testing Methods:"),
                        tags$ul(
                          tags$li("Landing page conversion tests"),
                          tags$li("Prototype user testing"),
                          tags$li("Customer interviews"),
                          tags$li("A/B testing campaigns"),
                          tags$li("Pilot programs")
                        )
                    ),
                    div(class = "example-box",
                        h4("Success Rate:"),
                        p("Startups testing assumptions are 2.5x more likely to scale successfully.")
                    )
                ),
                box(title = "Step 17: Define MVBP", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Create Minimum Viable Business Product for market validation."),
                    p("MVBP goes beyond MVP to include business viability. It should generate revenue and provide enough value that customers pay and provide meaningful feedback."),
                    div(class = "benefits",
                        h4("MVBP Requirements:"),
                        tags$ul(
                          tags$li("Core value proposition delivery"),
                          tags$li("Basic customer support"),
                          tags$li("Billing and payment processing"),
                          tags$li("User onboarding process"),
                          tags$li("Feedback collection mechanism")
                        )
                    ),
                    div(class = "example-box",
                        h4("Timeline:"),
                        p("MVBP development typically takes 3-6 months for B2B products.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 18: Prove Market Demand", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Secure paying customers to validate genuine demand."),
                    p("Paying customers provide stronger validation than positive feedback alone. Revenue demonstrates real market demand and product-market fit progression."),
                    div(class = "benefits",
                        h4("Validation Metrics:"),
                        tags$ul(
                          tags$li("Customer acquisition rate"),
                          tags$li("Revenue growth trajectory"),
                          tags$li("Customer retention rates"),
                          tags$li("Product usage analytics"),
                          tags$li("Customer satisfaction scores")
                        )
                    ),
                    div(class = "example-box",
                        h4("Benchmark:"),
                        p("Aim for 10+ paying customers before major product investment.")
                    )
                ),
                box(title = "Step 19: Develop Product Plan", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Create comprehensive product development roadmap."),
                    p("Structured product planning improves development efficiency by 35%. Align roadmap with customer feedback, business goals, and technical constraints."),
                    div(class = "benefits",
                        h4("Plan Components:"),
                        tags$ul(
                          tags$li("Feature prioritization matrix"),
                          tags$li("Development timeline"),
                          tags$li("Resource requirements"),
                          tags$li("Technical architecture"),
                          tags$li("Go-to-market coordination")
                        )
                    ),
                    div(class = "example-box",
                        h4("Agile Approach:"),
                        p("Use 2-week sprints with regular customer feedback integration.")
                    )
                )
              )
      ),
      
      # Business Scaling Tab
      tabItem(tabName = "scaling",
              fluidRow(
                box(title = "Step 20: Choose Business Model", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Select optimal revenue generation model."),
                    p("The right business model can increase company valuation by 4-10x. Consider recurring revenue models for predictable growth and higher valuations."),
                    div(class = "benefits",
                        h4("Model Options:"),
                        tags$ul(
                          tags$li("Subscription (SaaS): Predictable recurring revenue"),
                          tags$li("Transaction: Revenue per transaction"),
                          tags$li("Marketplace: Commission on transactions"),
                          tags$li("Freemium: Free tier with paid upgrades"),
                          tags$li("Enterprise License: Annual contracts")
                        )
                    ),
                    div(class = "example-box",
                        h4("SaaS Advantage:"),
                        p("SaaS companies trade at 6-12x revenue vs 1-3x for traditional businesses.")
                    )
                ),
                box(title = "Step 21: Set Pricing Framework", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Establish value-based pricing strategy."),
                    p("Value-based pricing can increase profits by 25-50%. Price according to customer value received, not just costs or competition."),
                    div(class = "benefits",
                        h4("Pricing Strategies:"),
                        tags$ul(
                          tags$li("Value-based: Price reflects customer ROI"),
                          tags$li("Tiered: Multiple service levels"),
                          tags$li("Usage-based: Pay per consumption"),
                          tags$li("Freemium: Free tier drives adoption"),
                          tags$li("Bundled: Package multiple features")
                        )
                    ),
                    div(class = "example-box",
                        h4("Optimization:"),
                        p("A/B testing pricing can improve revenue by 10-30%.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 22: Calculate Customer LTV", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Determine lifetime value of acquired customers."),
                    p("LTV optimization guides customer acquisition strategy. High LTV:CAC ratios (3:1 or higher) indicate sustainable business models."),
                    div(class = "benefits",
                        h4("LTV Formula:"),
                        p("LTV = (ARPU × Gross Margin %) ÷ Churn Rate"),
                        tags$ul(
                          tags$li("ARPU: Average Revenue Per User"),
                          tags$li("Gross Margin: Revenue minus direct costs"),
                          tags$li("Churn Rate: Monthly customer loss rate")
                        )
                    ),
                    div(class = "example-box",
                        h4("Target Ratio:"),
                        p("LTV:CAC ratio should be 3:1 minimum, 5:1+ optimal.")
                    )
                ),
                box(title = "Step 23: Map Sales Process", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Define scalable sales operations."),
                    p("Optimized sales processes improve conversion rates by 30-50%. Document each stage, assign responsibilities, and implement tracking systems."),
                    div(class = "benefits",
                        h4("Sales Stages:"),
                        tags$ul(
                          tags$li("Lead generation and qualification"),
                          tags$li("Initial discovery calls"),
                          tags$li("Needs assessment and demo"),
                          tags$li("Proposal and negotiation"),
                          tags$li("Closing and onboarding")
                        )
                    ),
                    div(class = "example-box",
                        h4("CRM Implementation:"),
                        p("Sales CRM systems improve close rates by 20-30%.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 24: Scale-Up Strategy", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("Objective:"), "Prepare for sustainable business growth."),
                    p("Successful scaling requires systematic preparation. Identify operational bottlenecks, build scalable systems, and prepare organizational structure for growth."),
                    div(class = "benefits",
                        h4("Scaling Preparations:"),
                        tags$ul(
                          tags$li("Technology infrastructure scalability"),
                          tags$li("Customer support automation"),
                          tags$li("Sales and marketing process systematization"),
                          tags$li("Team structure and hiring plans"),
                          tags$li("Financial management systems")
                        )
                    ),
                    div(class = "example-box",
                        h4("Growth Metrics:"),
                        p("Monitor: Revenue growth rate, customer acquisition rate, team productivity, system performance, customer satisfaction.")
                    )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output) {
  
  # Competitive positioning matrix
  output$competitiveMatrix <- renderPlotly({
    competitors <- data.frame(
      Company = c("Your Product", "Competitor A", "Competitor B", "Competitor C", "Competitor D"),
      Price = c(3, 2, 4, 1, 3),
      Features = c(4, 3, 2, 2, 4),
      Type = c("You", "Competitor", "Competitor", "Competitor", "Competitor")
    )
    
    p <- plot_ly(competitors, x = ~Price, y = ~Features, text = ~Company, 
                 color = ~Type, colors = c("#FF8C00", "#DAA520"),
                 type = "scatter", mode = "markers+text", textposition = "top center",
                 marker = list(size = 15)) %>%
      layout(title = "Competitive Positioning Matrix",
             xaxis = list(title = "Price (Low to High)", range = c(0, 5)),
             yaxis = list(title = "Features (Basic to Advanced)", range = c(0, 5)),
             showlegend = TRUE)
    p
  })
  
  # Sales funnel visualization
  output$salesFunnel <- renderPlotly({
    funnel_data <- data.frame(
      Stage = c("Awareness", "Interest", "Consideration", "Intent", "Purchase"),
      Count = c(1000, 400, 200, 100, 50),
      Conversion = c(100, 40, 20, 10, 5)
    )
    
    p <- plot_ly(funnel_data, x = ~Count, y = ~Stage, type = "bar", orientation = "h",
                 marker = list(color = c("#FF8C00", "#FFD700", "#DAA520", "#B8860B", "#8B7D6B"))) %>%
      layout(title = "Sales Funnel Conversion Analysis",
             xaxis = list(title = "Number of Prospects"),
             yaxis = list(title = "", categoryorder = "array", 
                          categoryarray = rev(funnel_data$Stage)))
    p
  })
  
  # Financial calculations
  output$ltvOutput <- renderText({
    ltv <- (input$customerPrice * input$customerLifetime * input$grossMargin/100)
    paste("Customer LTV: $", round(ltv, 2))
  })
  
  output$ltvCacRatio <- renderText({
    ltv <- (input$customerPrice * input$customerLifetime * input$grossMargin/100)
    ratio <- ltv / input$acquisitionCost
    paste("LTV:CAC Ratio:", round(ratio, 2), ":1")
  })
  
  output$paybackPeriod <- renderText({
    monthly_profit <- input$customerPrice * input$grossMargin/100
    payback <- input$acquisitionCost / monthly_profit
    paste("Payback Period:", round(payback, 1), "months")
  })
}

# Run the application
shinyApp(ui = ui, server = server)