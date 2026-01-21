library(shiny)
library(shinydashboard)
library(DT)
library(plotly)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Disciplined Entrepreneurship: 24 Steps Framework"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Who is Your Customer?", tabName = "customer", icon = icon("users")),
      menuItem("What Can You Do?", tabName = "value", icon = icon("lightbulb")),
      menuItem("How Customer Acquires?", tabName = "acquisition", icon = icon("handshake")),
      menuItem("How Make Money?", tabName = "revenue", icon = icon("dollar-sign")),
      menuItem("How Design & Build?", tabName = "product", icon = icon("cogs")),
      menuItem("How Scale Business?", tabName = "scaling", icon = icon("chart-line"))
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
      # WHO IS YOUR CUSTOMER? (Steps 1-5, 9)
      tabItem(tabName = "customer",
              fluidRow(
                box(title = "Theme Overview: Who is Your Customer?", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("This theme focuses on understanding your target market and customers."), 
                      "Research shows that", strong("42% of startups fail due to no market need."), 
                      "These steps help you systematically identify and validate your ideal customers before building your product."),
                    div(class = "benefits",
                        h4("Theme Objectives:"),
                        tags$ul(
                          tags$li("Segment markets systematically"),
                          tags$li("Select optimal beachhead market"),
                          tags$li("Create detailed customer personas"),
                          tags$li("Validate customer demand early")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Step 1: Market Segmentation", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Divide the total market into distinct, actionable segments."),
                    p("Effective segmentation is the foundation of successful marketing. Companies with advanced segmentation strategies achieve", 
                      strong("10% higher profits"), "than those with basic segmentation."),
                    div(class = "benefits",
                        h4("Segmentation Criteria:"),
                        tags$ul(
                          tags$li(strong("Geographic:"), "Region, country, city size"),
                          tags$li(strong("Demographic:"), "Age, income, company size"),
                          tags$li(strong("Psychographic:"), "Values, lifestyle, personality"),
                          tags$li(strong("Behavioral:"), "Usage patterns, loyalty, benefits sought")
                        )
                    ),
                    div(class = "example-box",
                        h4("Success Metric:"),
                        p("Aim for 5-7 distinct segments that are measurable, accessible, and actionable.")
                    )
                ),
                box(title = "Step 2: Select a Beachhead Market", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Choose one specific market segment to attack first and dominate."),
                    p("The beachhead strategy helps startups focus limited resources for maximum impact.", 
                      strong("Focused startups are 3x more likely"), "to achieve significant scale than those pursuing multiple markets simultaneously."),
                    div(class = "benefits",
                        h4("Selection Criteria:"),
                        tags$ul(
                          tags$li("Customers have urgent, compelling needs"),
                          tags$li("You can reach customers through known channels"),
                          tags$li("Market size: $10M-$100M (large enough to matter)"),
                          tags$li("Limited or weak competition"),
                          tags$li("Potential for word-of-mouth marketing")
                        )
                    ),
                    div(class = "example-box",
                        h4("Common Mistake:"),
                        p("Trying to serve everyone serves no one. Focus beats breadth in early stages.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 3: Build an End User Profile", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Create a detailed profile of the person who will actually use your product."),
                    p("Detailed user profiles improve product development efficiency by", strong("67%"), 
                      "and increase marketing campaign effectiveness significantly."),
                    div(class = "benefits",
                        h4("Profile Components:"),
                        tags$ul(
                          tags$li(strong("Demographics:"), "Age, education, job title, experience level"),
                          tags$li(strong("Goals & Motivations:"), "What they're trying to achieve"),
                          tags$li(strong("Pain Points:"), "Current frustrations and challenges"),
                          tags$li(strong("Behavior Patterns:"), "How they work, learn, and make decisions"),
                          tags$li(strong("Technology Adoption:"), "Comfort with new tools and platforms")
                        )
                    ),
                    div(class = "example-box",
                        h4("Research Method:"),
                        p("Conduct 10-15 interviews with real potential users to validate assumptions.")
                    )
                ),
                box(title = "Step 4: Calculate TAM for Beachhead Market", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Quantify the total revenue opportunity in your chosen beachhead market."),
                    p("Accurate TAM calculation helps validate market opportunity and is essential for fundraising.", 
                      strong("Bottom-up TAM calculations"), "are 5x more credible to investors than top-down estimates."),
                    div(class = "benefits",
                        h4("Calculation Method:"),
                        tags$ul(
                          tags$li(strong("Step 1:"), "Count total potential customers in beachhead"),
                          tags$li(strong("Step 2:"), "Estimate realistic annual revenue per customer"),
                          tags$li(strong("Step 3:"), "Multiply: # Customers × Annual Revenue = TAM"),
                          tags$li(strong("Step 4:"), "Validate with primary research and data sources")
                        )
                    ),
                    div(class = "example-box",
                        h4("Investor Benchmark:"),
                        p("VCs typically want to see $1B+ TAM for significant investment consideration.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 5: Profile Persona for Beachhead Market", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Create a vivid, specific persona of your ideal customer in the beachhead market."),
                    p("Detailed personas enable precise targeting and messaging.", strong("Personalized campaigns"), 
                      "deliver 6x higher transaction rates than generic marketing."),
                    div(class = "benefits",
                        h4("Persona Elements:"),
                        tags$ul(
                          tags$li(strong("Personal Background:"), "Name, photo, personal story"),
                          tags$li(strong("Professional Context:"), "Role, responsibilities, reporting structure"),
                          tags$li(strong("Goals & Challenges:"), "What success looks like, current obstacles"),
                          tags$li(strong("Information Sources:"), "Where they learn about solutions"),
                          tags$li(strong("Decision Process:"), "How they evaluate and purchase products")
                        )
                    ),
                    div(class = "example-box",
                        h4("Validation Test:"),
                        p("Your team should be able to predict persona responses to product features 80% accurately.")
                    )
                ),
                box(title = "Step 9: Identify Your Next 10 Customers", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Move beyond personas to identify 10 real, specific potential customers."),
                    p("Real customer identification validates market demand and provides feedback for product development.", 
                      strong("Customer development"), "reduces startup failure risk by up to 60%."),
                    div(class = "benefits",
                        h4("Identification Process:"),
                        tags$ul(
                          tags$li("Use your persona to identify real people/companies"),
                          tags$li("Conduct customer interviews to validate pain points"),
                          tags$li("Test initial product concepts and pricing"),
                          tags$li("Assess their willingness to pay for a solution"),
                          tags$li("Understand their purchasing timeline and process")
                        )
                    ),
                    div(class = "example-box",
                        h4("Success Criteria:"),
                        p("At least 7 of 10 customers should confirm the problem and express strong purchase intent.")
                    )
                )
              ),
              fluidRow(
                box(title = "Customer Segmentation Analysis", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("segmentationChart", height = "400px")
                )
              )
      ),
      
      # WHAT CAN YOU DO FOR YOUR CUSTOMER? (Steps 6-8, 10-11)
      tabItem(tabName = "value",
              fluidRow(
                box(title = "Theme Overview: What Can You Do for Your Customer?", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("This theme focuses on defining your value proposition and competitive advantage."), 
                      "Clear value propositions increase sales effectiveness by", strong("30-50%"), 
                      "and help teams stay focused on what matters most to customers."),
                    div(class = "benefits",
                        h4("Theme Objectives:"),
                        tags$ul(
                          tags$li("Map complete customer lifecycle"),
                          tags$li("Define clear product specifications"),
                          tags$li("Quantify your value proposition"),
                          tags$li("Identify sustainable competitive advantages")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Step 6: Full Life Cycle Use Case", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Map every step of the customer's journey with your product."),
                    p("Understanding the complete lifecycle improves customer experience and reduces churn by", 
                      strong("25-30%."), "Companies that map customer journeys see significantly higher satisfaction scores."),
                    div(class = "benefits",
                        h4("Lifecycle Stages:"),
                        tags$ul(
                          tags$li(strong("Awareness:"), "How customers discover your product"),
                          tags$li(strong("Evaluation:"), "Research and comparison process"),
                          tags$li(strong("Purchase:"), "Buying experience and onboarding"),
                          tags$li(strong("Implementation:"), "Setup, training, and initial usage"),
                          tags$li(strong("Ongoing Use:"), "Daily workflows and support needs"),
                          tags$li(strong("Renewal/Expansion:"), "Upgrade paths and loyalty")
                        )
                    ),
                    div(class = "example-box",
                        h4("Optimization Opportunity:"),
                        p("Every friction point removal can improve conversion rates by 10-20%.")
                    )
                ),
                box(title = "Step 7: High-Level Product Specification", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Define what your product looks like and how it functions."),
                    p("Clear specifications reduce development time by", strong("20-30%"), 
                      "and improve team coordination. Focus on customer benefits, not just technical features."),
                    div(class = "benefits",
                        h4("Specification Elements:"),
                        tags$ul(
                          tags$li(strong("Visual Design:"), "User interface mockups and wireframes"),
                          tags$li(strong("Core Features:"), "Essential functionality that delivers value"),
                          tags$li(strong("User Experience:"), "How customers interact with your product"),
                          tags$li(strong("Technical Requirements:"), "Performance, security, scalability needs"),
                          tags$li(strong("Integration Points:"), "How it connects with existing systems")
                        )
                    ),
                    div(class = "example-box",
                        h4("Design Principle:"),
                        p("Make it simple enough that customers can understand the value in 30 seconds.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 8: Quantify the Value Proposition", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Express your value in specific, measurable terms."),
                    p("Quantified value propositions are", strong("3x more effective"), 
                      "in B2B sales than generic benefit statements. Put dollar amounts on customer improvements."),
                    div(class = "benefits",
                        h4("Value Quantification:"),
                        tags$ul(
                          tags$li(strong("Time Savings:"), "Hours saved per week/month"),
                          tags$li(strong("Cost Reduction:"), "Percentage or dollar savings"),
                          tags$li(strong("Revenue Increase:"), "Additional income generated"),
                          tags$li(strong("Risk Mitigation:"), "Potential losses avoided"),
                          tags$li(strong("Efficiency Gains:"), "Productivity improvements")
                        )
                    ),
                    div(class = "example-box",
                        h4("ROI Formula:"),
                        p("ROI = (Benefit - Cost) / Cost × 100%. Target 300%+ ROI for easy customer decisions.")
                    )
                ),
                box(title = "Step 10: Define Your Core", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Identify the unique capabilities that competitors cannot easily replicate."),
                    p("Strong competitive cores enable", strong("40-60% higher profit margins"), 
                      "and provide sustainable competitive advantages that protect market position."),
                    div(class = "benefits",
                        h4("Types of Core:"),
                        tags$ul(
                          tags$li(strong("Technology:"), "Proprietary algorithms, patents, IP"),
                          tags$li(strong("Data:"), "Unique datasets, network effects"),
                          tags$li(strong("Process:"), "Superior operational methods"),
                          tags$li(strong("Relationships:"), "Exclusive partnerships, customer loyalty"),
                          tags$li(strong("Brand:"), "Reputation, trust, market position")
                        )
                    ),
                    div(class = "example-box",
                        h4("Durability Test:"),
                        p("Your core should take competitors 12+ months and significant investment to replicate.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 11: Chart Your Competitive Position", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("Objective:"), "Position your product uniquely versus alternatives in the market."),
                    p("Effective positioning increases market share by", strong("20-25%"), 
                      "and helps customers understand why they should choose you over alternatives."),
                    div(class = "benefits",
                        h4("Positioning Strategy:"),
                        tags$ul(
                          tags$li("Choose two axes that matter most to customers"),
                          tags$li("Position yourself in a unique, valuable quadrant"),
                          tags$li("Avoid overcrowded competitive spaces"),
                          tags$li("Highlight your core differentiators"),
                          tags$li("Consider where market is heading, not just where it is")
                        )
                    ),
                    plotlyOutput("competitivePositioning", height = "400px")
                )
              )
      ),
      
      # HOW DOES YOUR CUSTOMER ACQUIRE YOUR PRODUCT? (Steps 12-13, 18)
      tabItem(tabName = "acquisition",
              fluidRow(
                box(title = "Theme Overview: How Does Your Customer Acquire Your Product?", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("This theme focuses on understanding and optimizing the customer acquisition process."), 
                      "Optimized acquisition processes can", strong("reduce sales cycles by 30-40%"), 
                      "and improve conversion rates significantly."),
                    div(class = "benefits",
                        h4("Theme Objectives:"),
                        tags$ul(
                          tags$li("Map the complete decision-making unit"),
                          tags$li("Understand the customer acquisition process"),
                          tags$li("Optimize sales and marketing efficiency")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Step 12: Determine the Decision-Making Unit (DMU)", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Identify everyone involved in the purchasing decision."),
                    p("B2B purchases now involve", strong("6.8 people on average."), 
                      "Understanding the complete DMU improves sales success rates by 40-50%."),
                    div(class = "benefits",
                        h4("DMU Roles:"),
                        tags$ul(
                          tags$li(strong("Economic Buyer:"), "Has budget authority, signs contracts"),
                          tags$li(strong("Technical Buyer:"), "Evaluates product specifications"),
                          tags$li(strong("User Buyer:"), "Will actually use the product daily"),
                          tags$li(strong("Coach:"), "Provides insider information and guidance"),
                          tags$li(strong("Champion:"), "Actively promotes your solution internally")
                        )
                    ),
                    div(class = "example-box",
                        h4("Sales Insight:"),
                        p("Enterprise deals are 50% more likely to close when you identify the complete DMU early.")
                    )
                ),
                box(title = "Step 13: Map Process to Acquire a Paying Customer", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Document each step from initial awareness to signed contract."),
                    p("Mapped acquisition processes reduce", strong("customer acquisition costs by 25-35%"), 
                      "and help identify optimization opportunities."),
                    div(class = "benefits",
                        h4("Acquisition Stages:"),
                        tags$ul(
                          tags$li(strong("Problem Recognition:"), "Customer realizes they have an issue"),
                          tags$li(strong("Solution Research:"), "Exploring potential approaches"),
                          tags$li(strong("Vendor Identification:"), "Creating shortlist of providers"),
                          tags$li(strong("Evaluation:"), "Demos, trials, reference calls"),
                          tags$li(strong("Negotiation:"), "Pricing, terms, implementation"),
                          tags$li(strong("Approval:"), "Internal sign-offs and contracts")
                        )
                    ),
                    div(class = "example-box",
                        h4("Optimization Goal:"),
                        p("Remove one major friction point to improve conversion by 15-25%.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 18: Map Sales Process to Acquire a Customer", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("Objective:"), "Define your sales methodology and process stages."),
                    p("Structured sales processes improve", strong("win rates by 35%"), 
                      "and reduce sales cycle length. Align your sales process with how customers buy."),
                    div(class = "benefits",
                        h4("Sales Process Elements:"),
                        tags$ul(
                          tags$li(strong("Lead Generation:"), "How you find potential customers"),
                          tags$li(strong("Qualification:"), "Determining if prospect is a good fit"),
                          tags$li(strong("Discovery:"), "Understanding needs and decision process"),
                          tags$li(strong("Presentation:"), "Demonstrating value and capabilities"),
                          tags$li(strong("Proposal:"), "Formal offer with pricing and terms"),
                          tags$li(strong("Closing:"), "Securing commitment and signatures")
                        )
                    ),
                    plotlyOutput("salesProcess", height = "350px")
                )
              )
      ),
      
      # HOW DO YOU MAKE MONEY OFF YOUR PRODUCT? (Steps 15-17, 19)
      tabItem(tabName = "revenue",
              fluidRow(
                box(title = "Theme Overview: How Do You Make Money Off Your Product?", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("This theme focuses on business model design and financial sustainability."), 
                      "The right business model can", strong("increase company valuation by 4-10x"), 
                      "and dramatically improve long-term success probability."),
                    div(class = "benefits",
                        h4("Theme Objectives:"),
                        tags$ul(
                          tags$li("Design sustainable business model"),
                          tags$li("Set optimal pricing framework"),
                          tags$li("Calculate unit economics"),
                          tags$li("Understand customer acquisition costs")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Step 15: Design a Business Model", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Choose how you will generate revenue and create value."),
                    p("SaaS business models trade at", strong("6-12x revenue multiples"), 
                      "compared to 1-3x for traditional businesses due to recurring revenue predictability."),
                    div(class = "benefits",
                        h4("Business Model Options:"),
                        tags$ul(
                          tags$li(strong("Subscription:"), "Recurring monthly/annual payments"),
                          tags$li(strong("Transaction:"), "Fee per transaction or usage"),
                          tags$li(strong("Marketplace:"), "Commission on transactions"),
                          tags$li(strong("Freemium:"), "Free tier with premium upgrades"),
                          tags$li(strong("Enterprise:"), "Large annual contracts"),
                          tags$li(strong("Advertising:"), "Revenue from ad placements")
                        )
                    ),
                    div(class = "example-box",
                        h4("Model Selection:"),
                        p("Choose based on customer preference, value delivery, and scalability requirements.")
                    )
                ),
                box(title = "Step 16: Set Your Pricing Framework", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Establish pricing strategy based on value, not cost."),
                    p("Value-based pricing can increase profits by", strong("25-50%"), 
                      "compared to cost-plus or competitive pricing approaches."),
                    div(class = "benefits",
                        h4("Pricing Strategies:"),
                        tags$ul(
                          tags$li(strong("Value-Based:"), "Price according to customer ROI"),
                          tags$li(strong("Tiered:"), "Multiple service levels and price points"),
                          tags$li(strong("Usage-Based:"), "Pay per consumption or volume"),
                          tags$li(strong("Penetration:"), "Low price to gain market share"),
                          tags$li(strong("Premium:"), "High price for premium positioning"),
                          tags$li(strong("Bundle:"), "Package multiple products together")
                        )
                    ),
                    div(class = "example-box",
                        h4("Pricing Optimization:"),
                        p("A/B test pricing to optimize revenue - can improve by 10-30%.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 17: Calculate Lifetime Value (LTV)", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Determine the total value of a customer relationship."),
                    p("High LTV businesses are", strong("5x more valuable"), 
                      "to investors and enable higher customer acquisition spending."),
                    div(class = "benefits",
                        h4("LTV Calculation:"),
                        p(strong("LTV = (ARPU × Gross Margin %) ÷ Churn Rate")),
                        tags$ul(
                          tags$li(strong("ARPU:"), "Average Revenue Per User per month"),
                          tags$li(strong("Gross Margin:"), "Revenue minus direct costs"),
                          tags$li(strong("Churn Rate:"), "Monthly customer loss percentage")
                        )
                    ),
                    div(class = "example-box",
                        h4("Target Metrics:"),
                        p("SaaS: LTV > $10k, Churn < 5% monthly, Gross Margin > 80%")
                    )
                ),
                box(title = "Step 19: Calculate Customer Acquisition Cost (CAC)", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Determine total cost to acquire one new customer."),
                    p("Optimizing CAC is crucial for scalability.", strong("Best-in-class companies"), 
                      "recover CAC within 12 months and maintain LTV:CAC ratios of 3:1 or higher."),
                    div(class = "benefits",
                        h4("CAC Components:"),
                        tags$ul(
                          tags$li("Sales team salaries and commissions"),
                          tags$li("Marketing campaign costs and advertising"),
                          tags$li("Software tools and technology platforms"),
                          tags$li("Travel and entertainment expenses"),
                          tags$li("Allocated overhead and administrative costs")
                        )
                    ),
                    div(class = "example-box",
                        h4("CAC Formula:"),
                        p("CAC = Total Sales & Marketing Costs ÷ New Customers Acquired")
                    )
                )
              ),
              fluidRow(
                box(title = "Financial Metrics Calculator", status = "primary", solidHeader = TRUE, width = 12,
                    fluidRow(
                      column(width = 3,
                             h4("Customer Inputs:"),
                             numericInput("monthlyPrice", "Monthly Price ($)", value = 100, min = 1),
                             numericInput("annualChurn", "Annual Churn (%)", value = 20, min = 0, max = 100),
                             numericInput("grossMarginPct", "Gross Margin (%)", value = 80, min = 0, max = 100)
                      ),
                      column(width = 3,
                             h4("Cost Inputs:"),
                             numericInput("salesCost", "Sales Cost ($)", value = 150, min = 0),
                             numericInput("marketingCost", "Marketing Cost ($)", value = 50, min = 0),
                             numericInput("newCustomers", "New Customers", value = 100, min = 1)
                      ),
                      column(width = 6,
                             h4("Calculated Metrics:"),
                             div(style = "background-color: #E6FFE6; padding: 15px; border-radius: 5px; margin: 5px 0;",
                                 verbatimTextOutput("ltvCalculation")
                             ),
                             div(style = "background-color: #FFE6E6; padding: 15px; border-radius: 5px; margin: 5px 0;",
                                 verbatimTextOutput("cacCalculation")
                             ),
                             div(style = "background-color: #E6F3FF; padding: 15px; border-radius: 5px; margin: 5px 0;",
                                 verbatimTextOutput("ltvCacRatio")
                             ),
                             div(style = "background-color: #FFF8DC; padding: 15px; border-radius: 5px; margin: 5px 0;",
                                 verbatimTextOutput("paybackMonths")
                             )
                      )
                    )
                )
              )
      ),
      
      # HOW DO YOU DESIGN & BUILD YOUR PRODUCT? (Steps 20-23)
      tabItem(tabName = "product",
              fluidRow(
                box(title = "Theme Overview: How Do You Design & Build Your Product?", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("This theme focuses on product development methodology and validation."), 
                      "Systematic product development reduces", strong("time-to-market by 30-40%"), 
                      "and increases product-market fit probability."),
                    div(class = "benefits",
                        h4("Theme Objectives:"),
                        tags$ul(
                          tags$li("Test key business assumptions"),
                          tags$li("Build minimum viable business product"),
                          tags$li("Prove genuine market demand"),
                          tags$li("Develop comprehensive product roadmap")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Step 20: Test Key Assumptions", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Validate critical business assumptions through experimentation."),
                    p("Assumption testing reduces startup failure risk by", strong("60-70%."), 
                      "Use lean startup methodology to run controlled experiments and gather data-driven insights."),
                    div(class = "benefits",
                        h4("Testing Methods:"),
                        tags$ul(
                          tags$li(strong("Landing Pages:"), "Test demand with signup conversion rates"),
                          tags$li(strong("Prototypes:"), "Validate user experience and functionality"),
                          tags$li(strong("Customer Interviews:"), "Confirm problem and solution fit"),
                          tags$li(strong("A/B Testing:"), "Compare different approaches"),
                          tags$li(strong("Pilot Programs:"), "Small-scale implementation tests")
                        )
                    ),
                    div(class = "example-box",
                        h4("Success Rate:"),
                        p("Startups that test assumptions systematically are 2.5x more likely to scale successfully.")
                    )
                ),
                box(title = "Step 21: Test Key Assumptions", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Continue assumption validation with iterative testing."),
                    p("Iterative assumption testing is the foundation of lean startup methodology.", 
                      strong("Companies that pivot"), "based on validated learning have 70% higher success rates."),
                    div(class = "benefits",
                        h4("Assumption Categories:"),
                        tags$ul(
                          tags$li(strong("Market Assumptions:"), "Size, growth, customer behavior"),
                          tags$li(strong("Product Assumptions:"), "Features, usability, performance"),
                          tags$li(strong("Business Model:"), "Pricing, revenue streams, costs"),
                          tags$li(strong("Technical Assumptions:"), "Feasibility, scalability, integration"),
                          tags$li(strong("Competitive Assumptions:"), "Response, barriers to entry")
                        )
                    ),
                    div(class = "example-box",
                        h4("Testing Framework:"),
                        p("Use hypothesis-driven experiments with clear success/failure criteria and timelines.")
                    )
                )
              ),
              fluidRow(
                box(title = "Step 22: Define Minimum Viable Business Product (MVBP)", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Create the simplest version that can generate revenue and validate business model."),
                    p("MVBP goes beyond MVP to include business viability.", strong("Revenue-generating MVBPs"), 
                      "provide stronger validation than feature-complete products without paying customers."),
                    div(class = "benefits",
                        h4("MVBP Requirements:"),
                        tags$ul(
                          tags$li(strong("Core Value Delivery:"), "Solves primary customer problem"),
                          tags$li(strong("Revenue Generation:"), "Customers pay for value received"),
                          tags$li(strong("Business Operations:"), "Billing, support, onboarding"),
                          tags$li(strong("Feedback Mechanisms:"), "Customer input collection"),
                          tags$li(strong("Basic Analytics:"), "Usage and performance tracking")
                        )
                    ),
                    div(class = "example-box",
                        h4("Development Timeline:"),
                        p("B2B MVBP typically takes 3-6 months; B2C products 1-3 months.")
                    )
                ),
                box(title = "Step 23: Show 'Dogs Will Eat the Dog Food'", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Prove genuine customer demand through paying customers."),
                    p("Paying customers provide the strongest validation of product-market fit.", 
                      strong("Revenue validation"), "is 10x more predictive of success than positive feedback alone."),
                    div(class = "benefits",
                        h4("Validation Metrics:"),
                        tags$ul(
                          tags$li(strong("Customer Acquisition:"), "Steady flow of new paying customers"),
                          tags$li(strong("Usage Analytics:"), "Active engagement with core features"),
                          tags$li(strong("Retention Rates:"), "Customers continue using and paying"),
                          tags$li(strong("Referrals:"), "Customers recommend to others"),
                          tags$li(strong("Expansion:"), "Customers increase usage or upgrade")
                        )
                    ),
                    div(class = "example-box",
                        h4("Success Benchmark:"),
                        p("Target: 10+ paying customers with 80%+ satisfaction and <10% churn.")
                    )
                )
              ),
              fluidRow(
                box(title = "Assumption Testing Tracker", status = "primary", solidHeader = TRUE, width = 12,
                    p("Track and validate your key business assumptions systematically:"),
                    DT::dataTableOutput("assumptionTracker")
                )
              )
      ),
      
      # HOW DO YOU SCALE YOUR BUSINESS? (Steps 14, 24)
      tabItem(tabName = "scaling",
              fluidRow(
                box(title = "Theme Overview: How Do You Scale Your Business?", status = "primary", solidHeader = TRUE, width = 12,
                    p(strong("This theme focuses on preparing for and managing business growth."), 
                      "Systematic scaling preparation increases", strong("success probability by 4-5x"), 
                      "and helps avoid common growth-related failures."),
                    div(class = "benefits",
                        h4("Theme Objectives:"),
                        tags$ul(
                          tags$li("Calculate addressable market for expansion"),
                          tags$li("Develop comprehensive product roadmap"),
                          tags$li("Build scalable operations and systems"),
                          tags$li("Prepare organizational structure for growth")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Step 14: Calculate TAM Size for Follow-on Markets", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Quantify expansion opportunities beyond your beachhead market."),
                    p("Follow-on market analysis guides expansion strategy and attracts growth capital.", 
                      strong("Multi-market strategies"), "can increase company valuation by 3-8x when executed properly."),
                    div(class = "benefits",
                        h4("Expansion Analysis:"),
                        tags$ul(
                          tags$li(strong("Adjacent Markets:"), "Similar customer segments, different use cases"),
                          tags$li(strong("Geographic Expansion:"), "Same solution, different regions"),
                          tags$li(strong("Vertical Markets:"), "Industry-specific adaptations"),
                          tags$li(strong("Product Extensions:"), "Additional features or products"),
                          tags$li(strong("Partnership Channels:"), "Indirect sales and distribution")
                        )
                    ),
                    div(class = "example-box",
                        h4("Sequencing Strategy:"),
                        p("Attack markets in order of: customer similarity, go-to-market efficiency, and competitive advantage.")
                    )
                ),
                box(title = "Step 24: Develop a Product Plan", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Objective:"), "Create comprehensive roadmap for product evolution and scaling."),
                    p("Structured product planning improves", strong("development efficiency by 35%"), 
                      "and helps coordinate across engineering, sales, and marketing teams."),
                    div(class = "benefits",
                        h4("Product Plan Elements:"),
                        tags$ul(
                          tags$li(strong("Feature Roadmap:"), "Prioritized development timeline"),
                          tags$li(strong("Technical Architecture:"), "Scalability and performance requirements"),
                          tags$li(strong("Resource Planning:"), "Team size and skill requirements"),
                          tags$li(strong("Integration Strategy:"), "Third-party platforms and APIs"),
                          tags$li(strong("Quality Assurance:"), "Testing and reliability standards"),
                          tags$li(strong("Go-to-Market:"), "Launch and adoption strategies")
                        )
                    ),
                    div(class = "example-box",
                        h4("Planning Horizon:"),
                        p("Maintain detailed 6-month plan with high-level 18-month vision.")
                    )
                )
              ),
              fluidRow(
                box(title = "Market Expansion Strategy", status = "primary", solidHeader = TRUE, width = 6,
                    p(strong("Expansion Readiness Checklist:")),
                    div(class = "benefits",
                        tags$ul(
                          tags$li("✓ Proven product-market fit in beachhead"),
                          tags$li("✓ Sustainable unit economics (LTV:CAC > 3:1)"),
                          tags$li("✓ Scalable go-to-market processes"),
                          tags$li("✓ Strong team and operational foundation"),
                          tags$li("✓ Clear competitive positioning"),
                          tags$li("✓ Adequate funding for expansion")
                        )
                    ),
                    div(class = "example-box",
                        h4("Expansion Timeline:"),
                        p("Most successful companies wait 12-18 months after beachhead success before major expansion.")
                    )
                ),
                box(title = "Scaling Challenges & Solutions", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "benefits",
                        h4("Common Scaling Challenges:"),
                        tags$ul(
                          tags$li(strong("Quality Control:"), "Maintain standards as volume increases"),
                          tags$li(strong("Team Coordination:"), "Communication across growing organization"),
                          tags$li(strong("Customer Support:"), "Maintain service levels with more customers"),
                          tags$li(strong("Technology Performance:"), "System scalability and reliability"),
                          tags$li(strong("Cash Flow:"), "Managing growth capital requirements")
                        )
                    ),
                    div(class = "example-box",
                        h4("Scaling Success Factor:"),
                        p("Companies that scale successfully invest in systems and processes before they're needed.")
                    )
                )
              ),
              fluidRow(
                box(title = "Business Scaling Dashboard", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("scalingMetrics", height = "400px")
                )
              )
      )
    )
  )
)

# Server function
server <- function(input, output, session) {
  
  # Customer Segmentation Chart
  output$segmentationChart <- renderPlotly({
    segments <- data.frame(
      Segment = c("Enterprise", "Mid-Market", "Small Business", "Startups"),
      Market_Size = c(25, 35, 45, 15),
      Competition = c(4, 3, 2, 1),
      Ease_of_Access = c(1, 2, 4, 5),
      Revenue_Potential = c(5, 4, 2, 1)
    )
    
    p <- plot_ly(segments, x = ~Ease_of_Access, y = ~Revenue_Potential, 
                 size = ~Market_Size, color = ~Segment,
                 colors = c("#FF8C00", "#FFD700", "#DAA520", "#B8860B"),
                 type = "scatter", mode = "markers+text",
                 text = ~Segment, textposition = "top center",
                 marker = list(sizemode = 'diameter', opacity = 0.7)) %>%
      layout(title = "Market Segmentation Analysis",
             xaxis = list(title = "Ease of Access (1=Hard, 5=Easy)"),
             yaxis = list(title = "Revenue Potential (1=Low, 5=High)"),
             paper_bgcolor = '#FFF8DC',
             plot_bgcolor = '#FFFACD')
    p
  })
  
  # Competitive Positioning Chart
  output$competitivePositioning <- renderPlotly({
    competitors <- data.frame(
      Company = c("Your Product", "Competitor A", "Competitor B", "Competitor C", "Legacy Solution"),
      Price = c(3, 2, 4, 1, 2),
      Innovation = c(5, 3, 2, 2, 1),
      Type = c("You", "Direct", "Direct", "Indirect", "Legacy")
    )
    
    p <- plot_ly(competitors, x = ~Price, y = ~Innovation, 
                 text = ~Company, color = ~Type,
                 colors = c("#FF8C00", "#DAA520", "#B8860B", "#8B7D6B"),
                 type = "scatter", mode = "markers+text",
                 textposition = "top center",
                 marker = list(size = 15)) %>%
      layout(title = "Competitive Positioning Matrix",
             xaxis = list(title = "Price (1=Low, 5=High)", range = c(0, 6)),
             yaxis = list(title = "Innovation (1=Basic, 5=Advanced)", range = c(0, 6)),
             paper_bgcolor = '#FFF8DC',
             plot_bgcolor = '#FFFACD')
    p
  })
  
  # Sales Process Visualization
  output$salesProcess <- renderPlotly({
    process_data <- data.frame(
      Stage = c("Lead Gen", "Qualification", "Discovery", "Demo", "Proposal", "Negotiation", "Close"),
      Leads = c(1000, 400, 200, 150, 100, 75, 50),
      Conversion = c(40, 50, 75, 67, 75, 67, 100),
      Days = c(0, 7, 14, 28, 42, 56, 70)
    )
    
    p <- plot_ly(process_data, x = ~Stage, y = ~Leads, type = "bar",
                 marker = list(color = "#FF8C00"),
                 text = ~paste(Conversion, "%"), textposition = "outside") %>%
      layout(title = "Sales Process Funnel",
             xaxis = list(title = "Sales Stage"),
             yaxis = list(title = "Number of Prospects"),
             paper_bgcolor = '#FFF8DC',
             plot_bgcolor = '#FFFACD')
    p
  })
  
  # Financial Calculations
  output$ltvCalculation <- renderText({
    monthly_churn <- input$annualChurn / 100 / 12
    ltv <- (input$monthlyPrice * input$grossMarginPct / 100) / monthly_churn
    paste("Customer LTV: $", format(round(ltv, 0), big.mark = ","))
  })
  
  output$cacCalculation <- renderText({
    total_cost <- input$salesCost + input$marketingCost
    cac <- (total_cost * input$newCustomers) / input$newCustomers
    paste("Customer CAC: $", format(round(cac, 0), big.mark = ","))
  })
  
  output$ltvCacRatio <- renderText({
    monthly_churn <- input$annualChurn / 100 / 12
    ltv <- (input$monthlyPrice * input$grossMarginPct / 100) / monthly_churn
    total_cost <- input$salesCost + input$marketingCost
    cac <- (total_cost * input$newCustomers) / input$newCustomers
    ratio <- ltv / cac
    
    status <- if(ratio >= 3) "✓ Healthy" else if(ratio >= 2) "⚠ Acceptable" else "✗ Poor"
    paste("LTV:CAC Ratio:", round(ratio, 1), ":1 (", status, ")")
  })
  
  output$paybackMonths <- renderText({
    monthly_profit <- input$monthlyPrice * input$grossMarginPct / 100
    total_cost <- input$salesCost + input$marketingCost
    cac <- (total_cost * input$newCustomers) / input$newCustomers
    payback <- cac / monthly_profit
    
    status <- if(payback <= 12) "✓ Good" else if(payback <= 18) "⚠ Acceptable" else "✗ Too Long"
    paste("Payback Period:", round(payback, 1), "months (", status, ")")
  })
  
  # Assumption Tracker
  output$assumptionTracker <- renderDT({
    assumptions <- data.frame(
      Assumption = c(
        "Target market size is $50M+",
        "Customers will pay $100/month",
        "Product can be built in 6 months",
        "Customer acquisition cost < $200",
        "Monthly churn rate will be < 5%",
        "Competitors won't respond quickly",
        "Technical solution is feasible",
        "Go-to-market channels are accessible"
      ),
      Category = c("Market", "Pricing", "Product", "Marketing", "Product", "Competition", "Technical", "Sales"),
      Risk_Level = c("High", "High", "Medium", "High", "High", "Medium", "Low", "Medium"),
      Test_Method = c(
        "Market research + customer interviews",
        "Landing page pricing test",
        "Technical feasibility study",
        "Marketing channel experiments",
        "Beta customer retention analysis",
        "Competitive intelligence",
        "Proof of concept development",
        "Channel partner discussions"
      ),
      Status = c("Validated", "Testing", "Validated", "Testing", "Untested", "Untested", "Validated", "Testing"),
      Priority = c(1, 1, 2, 1, 1, 3, 2, 2),
      stringsAsFactors = FALSE
    )
    
    datatable(assumptions, options = list(
      pageLength = 8,
      searching = TRUE,
      dom = 'tp'
    )) %>% formatStyle(
      'Status',
      backgroundColor = styleEqual(
        c('Validated', 'Testing', 'Untested'),
        c('#E6FFE6', '#FFF8DC', '#FFE6E6')
      )
    ) %>% formatStyle(
      'Risk_Level',
      backgroundColor = styleEqual(
        c('High', 'Medium', 'Low'),
        c('#FFE6E6', '#FFF8DC', '#E6FFE6')
      )
    )
  })
  
  # Scaling Metrics Dashboard
  output$scalingMetrics <- renderPlotly({
    months <- 1:24
    revenue <- cumsum(c(10, rep(15, 11), rep(25, 12))) * 1000
    customers <- cumsum(c(5, rep(8, 11), rep(15, 12)))
    team_size <- c(rep(5, 6), rep(8, 6), rep(12, 6), rep(18, 6))
    
    scaling_data <- data.frame(
      Month = months,
      Revenue = revenue,
      Customers = customers,
      Team_Size = team_size
    )
    
    p1 <- plot_ly(scaling_data, x = ~Month, y = ~Revenue, type = "scatter", mode = "lines",
                  name = "Monthly Revenue", line = list(color = "#FF8C00", width = 3))
    
    p2 <- plot_ly(scaling_data, x = ~Month, y = ~Customers, type = "scatter", mode = "lines",
                  name = "Total Customers", yaxis = "y2", line = list(color = "#DAA520", width = 3))
    
    p <- subplot(p1, p2, nrows = 1, shareX = TRUE) %>%
      layout(title = "Business Scaling Trajectory",
             xaxis = list(title = "Months from Launch"),
             yaxis = list(title = "Monthly Revenue ($)", side = "left"),
             yaxis2 = list(title = "Customer Count", side = "right", overlaying = "y"),
             paper_bgcolor = '#FFF8DC',
             plot_bgcolor = '#FFFACD',
             showlegend = TRUE)
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)