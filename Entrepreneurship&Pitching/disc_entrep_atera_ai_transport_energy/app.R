library(shiny)
library(shinydashboard)
library(DT)
library(plotly)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Disciplined Entrepreneurship: AI & Mobility Tech Startup"),
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
      .skin-blue .main-header .navbar { background-color: #FF8C00 !important; }
      .skin-blue .main-header .logo { background-color: #FF8C00 !important; color: #000000 !important; }
      .skin-blue .main-sidebar { background-color: #B8860B !important; }
      .skin-blue .main-sidebar .sidebar .sidebar-menu .active a { background-color: #FFD700 !important; color: #000000 !important; }
      .skin-blue .main-sidebar .sidebar .sidebar-menu a { color: #000000 !important; }
      .content-wrapper { background-color: #FFF8DC !important; }
      .box { background-color: #FFFFE0 !important; border: 2px solid #DAA520 !important; border-radius: 8px !important; }
      .box.box-primary { border-top-color: #FF8C00 !important; }
      .box.box-primary .box-header { background: linear-gradient(135deg, #FF8C00, #FFD700) !important; color: #000000 !important; }
      .box-body { background-color: #FFFACD !important; color: #333333 !important; }
      .test-box { background-color: #E6F3FF !important; border: 1px solid #4A90E2 !important; padding: 15px !important; margin: 10px 0 !important; border-radius: 5px !important; }
      .analysis-box { background-color: #FFF0E6 !important; border: 1px solid #FF8C00 !important; padding: 15px !important; margin: 10px 0 !important; border-radius: 5px !important; }
      .framework-box { background-color: #F0E68C !important; border: 1px solid #DAA520 !important; padding: 15px !important; margin: 10px 0 !important; border-radius: 5px !important; }
      .ai-application { background-color: #E8F5E8 !important; border: 2px solid #4CAF50 !important; padding: 15px !important; margin: 10px 0 !important; border-radius: 8px !important; }
      .decision-matrix { background-color: #F3E5F5 !important; border: 2px solid #9C27B0 !important; padding: 15px !important; margin: 10px 0 !important; border-radius: 8px !important; }
     "))
    ),
    
    tabItems(
      # WHO IS YOUR CUSTOMER?
      tabItem(tabName = "customer",
              tabsetPanel(
                tabPanel("Market Segmentation",
                         box(title = "Step 1: Market Segmentation", status = "primary", solidHeader = TRUE, width = 12,
                             p(strong("Objective:"), "Systematically break down your total addressable market into distinct, homogeneous segments."),
                             
                             div(class = "framework-box",
                                 h4("Aulet's Segmentation Framework:"),
                                 p("Effective segmentation requires identifying groups that are similar enough that they will adopt your product for the same reasons. Each segment should have distinct characteristics affecting purchasing behavior.")
                             ),
                             
                             div(class = "test-box",
                                 h4("Required Tests:"),
                                 tags$ul(
                                   tags$li(strong("Demographic Analysis:"), "Survey 100+ potential customers across segments"),
                                   tags$li(strong("Needs Assessment:"), "Conduct 20+ interviews per segment"),
                                   tags$li(strong("Channel Research:"), "Map discovery and evaluation methods"),
                                   tags$li(strong("Price Sensitivity:"), "Test willingness-to-pay across segments")
                                 )
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI/Mobility Tech Segmentation Strategy:"),
                                 tags$ul(
                                   tags$li(strong("Fleet Operators:"), "Logistics companies (10K+ vehicles), delivery services, ride-sharing"),
                                   tags$li(strong("Smart Cities:"), "Municipal transport authorities, urban planning departments"),
                                   tags$li(strong("Energy Companies:"), "Utilities planning EV infrastructure, renewable energy optimizers"),
                                   tags$li(strong("Automotive OEMs:"), "Manufacturers developing autonomous/EV vehicles"),
                                   tags$li(strong("Supply Chain:"), "Warehousing, last-mile delivery, freight optimization")
                                 ),
                                 p(strong("Primary Focus:"), "Fleet operators with 500+ vehicles showing 20%+ annual growth in EV adoption")
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Segment Selection Decision Matrix:"),
                                 DT::dataTableOutput("segmentMatrix")
                             ),
                             
                             plotlyOutput("segmentationChart", height = "300px")
                         )
                ),
                
                tabPanel("Beachhead Market",
                         box(title = "Step 2: Select a Beachhead Market", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Beachhead Selection Criteria:"),
                                 tags$ol(
                                   tags$li("Target customers have compelling reason to buy"),
                                   tags$li("There's a sales process to reach economic buyer"),
                                   tags$li("You can deliver whole product solution"),
                                   tags$li("No entrenched competition"),
                                   tags$li("Success enables leverage to adjacent markets")
                                 )
                             ),
                             
                             div(class = "test-box",
                                 h4("Validation Tests:"),
                                 tags$ul(
                                   tags$li(strong("Market Size:"), "Confirm $20M-$100M TAM"),
                                   tags$li(strong("Customer Access:"), "Contact 50+ potential customers"),
                                   tags$li(strong("Competition:"), "Map all competitors"),
                                   tags$li(strong("References:"), "Secure 3+ reference customers")
                                 )
                             ),
                             
                             div(class = "ai-application",
                                 h4("Recommended Beachhead: Last-Mile Delivery Fleet Optimization"),
                                 tags$ul(
                                   tags$li(strong("Market Size:"), "$2.8B US market, growing 15% annually"),
                                   tags$li(strong("Pain Point:"), "30-40% route inefficiency, rising fuel costs, driver shortage"),
                                   tags$li(strong("AI Advantage:"), "Real-time optimization, predictive analytics, autonomous readiness"),
                                   tags$li(strong("Target Customers:"), "Regional delivery companies (100-1000 vehicles)"),
                                   tags$li(strong("Competition Gap:"), "Existing solutions lack AI-powered real-time optimization")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Beachhead Market Analysis:"),
                                 plotlyOutput("beachheadAnalysis", height = "300px")
                             )
                         )
                ),
                
                tabPanel("End User Profile",
                         box(title = "Step 3: Build an End User Profile", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("End User Research Process:"),
                                 p("Spend 60+ hours with end users observing workflows, pain points, and decision criteria. Document day-in-the-life scenarios.")
                             ),
                             
                             div(class = "test-box",
                                 h4("Profile Validation:"),
                                 tags$ul(
                                   tags$li("Shadow 10+ end users for full work sessions"),
                                   tags$li("Survey 50+ users on workflows and frustrations"),
                                   tags$li("Test profile accuracy with user predictions"),
                                   tags$li("Validate technical skill levels and adoption patterns")
                                 )
                             ),
                             
                             div(class = "ai-application",
                                 h4("Primary End User: Fleet Operations Manager"),
                                 tags$ul(
                                   tags$li(strong("Demographics:"), "35-50 years, logistics/supply chain background, manages 100-500 vehicles"),
                                   tags$li(strong("Daily Challenges:"), "Route planning (2-3 hours), driver coordination, fuel cost management"),
                                   tags$li(strong("Tech Comfort:"), "Moderate - uses Excel, fleet management software, mobile apps"),
                                   tags$li(strong("Success Metrics:"), "Cost per delivery, on-time performance, fuel efficiency"),
                                   tags$li(strong("Decision Factors:"), "ROI proof, implementation ease, integration with existing systems")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("User Journey Optimization Points:"),
                                 tags$ul(
                                   tags$li(strong("Morning Planning:"), "AI suggests optimal routes considering traffic, weather, deliveries"),
                                   tags$li(strong("Real-time Adjustments:"), "Dynamic re-routing based on delays, new orders, vehicle issues"),
                                   tags$li(strong("Performance Analysis:"), "Daily efficiency reports with improvement recommendations"),
                                   tags$li(strong("Predictive Insights:"), "Maintenance alerts, demand forecasting, capacity planning")
                                 )
                             )
                         )
                ),
                
                tabPanel("TAM Calculation",
                         box(title = "Step 4: Calculate TAM for Beachhead Market", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Bottom-Up TAM Method:"),
                                 p("TAM = # of potential customers × Annual revenue per customer. Use primary research, not top-down estimates.")
                             ),
                             
                             div(class = "test-box",
                                 h4("TAM Validation Process:"),
                                 tags$ul(
                                   tags$li("Count actual potential customers through research"),
                                   tags$li("Interview 30+ customers on current spending"),
                                   tags$li("Analyze competitor pricing and customer spend"),
                                   tags$li("Cross-validate with industry reports")
                                 )
                             ),
                             
                             div(class = "ai-application",
                                 h4("Last-Mile Delivery TAM Calculation:"),
                                 tags$ul(
                                   tags$li(strong("Target Companies:"), "2,500 regional delivery companies (100-1000 vehicles)"),
                                   tags$li(strong("Annual Software Spend:"), "$50,000-$200,000 per company on fleet management"),
                                   tags$li(strong("AI Premium:"), "30-50% premium for AI-powered optimization"),
                                   tags$li(strong("Penetration Rate:"), "15% adoption in first 5 years"),
                                   tags$li(strong("TAM Calculation:"), "2,500 × $75,000 × 15% = $28M serviceable addressable market")
                                 )
                             ),
                             
                             fluidRow(
                               column(6, numericInput("potential_customers", "Potential Customers:", 2500)),
                               column(6, numericInput("annual_revenue", "Annual Revenue per Customer ($):", 75000))
                             ),
                             verbatimTextOutput("tamCalculation"),
                             
                             div(class = "decision-matrix",
                                 h4("Market Expansion Path:"),
                                 p("Beachhead → Regional carriers → National fleets → Smart cities → Autonomous vehicle networks")
                             )
                         )
                ),
                
                tabPanel("Persona Development",
                         box(title = "Step 5: Profile Persona for Beachhead Market", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Persona Elements:"),
                                 tags$ul(
                                   tags$li("Demographics, role, responsibilities"),
                                   tags$li("Goals, motivations, success metrics"),
                                   tags$li("Pain points, frustrations, challenges"),
                                   tags$li("Information sources and decision process")
                                 )
                             ),
                             
                             div(class = "ai-application",
                                 h4("'Sarah' - Fleet Operations Manager Persona:"),
                                 tags$ul(
                                   tags$li(strong("Background:"), "42, MBA, 8 years at MidSize Logistics (350 delivery vehicles)"),
                                   tags$li(strong("Goals:"), "Reduce delivery costs 15%, improve on-time performance to 95%"),
                                   tags$li(strong("Daily Routine:"), "6 AM route planning, driver briefings, performance monitoring"),
                                   tags$li(strong("Frustrations:"), "Manual route optimization, unexpected delays, fuel cost volatility"),
                                   tags$li(strong("Tech Stack:"), "Excel, Telogis fleet management, WhatsApp for driver communication")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Persona-Driven Product Features:"),
                                 tags$ul(
                                   tags$li(strong("One-click Planning:"), "AI generates optimal routes in <5 minutes vs 2 hours manual"),
                                   tags$li(strong("Mobile Dashboard:"), "Real-time fleet visibility on smartphone/tablet"),
                                   tags$li(strong("Predictive Alerts:"), "Proactive notifications for delays, maintenance, capacity issues"),
                                   tags$li(strong("ROI Tracking:"), "Daily reports showing cost savings and efficiency gains")
                                 )
                             )
                         )
                ),
                
                tabPanel("Next 10 Customers",
                         box(title = "Step 9: Identify Your Next 10 Customers", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Customer Identification Process:"),
                                 p("Move from personas to real, named prospects. This validates market demand and provides development feedback.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("Target Customer Criteria for AI Fleet Optimization:"),
                                 tags$ul(
                                   tags$li(strong("Fleet Size:"), "100-1000 vehicles (sweet spot for AI ROI)"),
                                   tags$li(strong("Growth Rate:"), "15%+ annual growth in delivery volume"),
                                   tags$li(strong("Tech Readiness:"), "Already using fleet management software"),
                                   tags$li(strong("Pain Severity:"), "Rising fuel costs >20% of operating expenses"),
                                   tags$li(strong("Decision Authority:"), "Operations manager has budget influence")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Customer Prioritization Framework:"),
                                 DT::dataTableOutput("nextCustomersTable")
                             )
                         )
                )
              )
      ),
      
      # WHAT CAN YOU DO FOR YOUR CUSTOMER?
      tabItem(tabName = "value",
              tabsetPanel(
                tabPanel("Use Case Mapping",
                         box(title = "Step 6: Full Life Cycle Use Case", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Complete Customer Journey:"),
                                 p("Map every touchpoint from awareness through renewal. Identify all stakeholders and their needs at each stage.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI Fleet Optimization Customer Journey:"),
                                 tags$ul(
                                   tags$li(strong("Problem Recognition:"), "Rising fuel costs, customer complaints about delays"),
                                   tags$li(strong("Research Phase:"), "Google searches, industry reports, peer recommendations"),
                                   tags$li(strong("Vendor Evaluation:"), "Demo requests, ROI calculations, reference calls"),
                                   tags$li(strong("Pilot Program:"), "30-day trial with subset of fleet"),
                                   tags$li(strong("Implementation:"), "Data integration, staff training, system go-live"),
                                   tags$li(strong("Optimization:"), "Performance tuning, feature adoption, expansion discussions")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Journey Stage Optimization:"),
                                 plotlyOutput("customerJourney", height = "300px")
                             )
                         )
                ),
                
                tabPanel("Product Specification",
                         box(title = "Step 7: High-Level Product Specification", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Specification Framework:"),
                                 p("Define minimum viable features that deliver core value. Focus on customer outcomes, not technical features.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI Fleet Optimization Platform Specification:"),
                                 tags$ul(
                                   tags$li(strong("Core AI Engine:"), "Real-time route optimization using traffic, weather, delivery constraints"),
                                   tags$li(strong("Predictive Analytics:"), "Demand forecasting, maintenance scheduling, capacity planning"),
                                   tags$li(strong("Mobile Interface:"), "Driver app with turn-by-turn navigation and delivery updates"),
                                   tags$li(strong("Dashboard:"), "Operations view with KPIs, alerts, and performance analytics"),
                                   tags$li(strong("Integration APIs:"), "Connect with existing ERP, WMS, and telematics systems")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Technical Architecture Decision:"),
                                 tags$ul(
                                   tags$li(strong("Cloud-Native:"), "AWS/Azure for scalability and AI model deployment"),
                                   tags$li(strong("Real-time Processing:"), "Event streaming for live traffic and order updates"),
                                   tags$li(strong("Machine Learning:"), "Continuous learning from historical delivery data"),
                                   tags$li(strong("Mobile-First:"), "Progressive web app for cross-platform compatibility")
                                 )
                             )
                         )
                ),
                
                tabPanel("Value Quantification",
                         box(title = "Step 8: Quantify the Value Proposition", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Value Measurement Framework:"),
                                 p("Quantify customer benefits in dollars and time. Create ROI calculators based on real customer data.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI Fleet Optimization Value Drivers:"),
                                 tags$ul(
                                   tags$li(strong("Fuel Savings:"), "15-25% reduction through optimized routing"),
                                   tags$li(strong("Time Efficiency:"), "20-30% more deliveries per day"),
                                   tags$li(strong("Labor Optimization:"), "Reduce planning time from 3 hours to 15 minutes"),
                                   tags$li(strong("Customer Satisfaction:"), "95% on-time delivery vs 80% industry average"),
                                   tags$li(strong("Maintenance Reduction:"), "Predictive maintenance reduces breakdowns 40%")
                                 )
                             ),
                             
                             fluidRow(
                               column(3, numericInput("fleet_size", "Fleet Size:", 200)),
                               column(3, numericInput("daily_fuel", "Daily Fuel Cost ($):", 50)),
                               column(3, numericInput("planning_hours", "Planning Hours/Day:", 3)),
                               column(3, verbatimTextOutput("roiCalculation"))
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("ROI Calculation for 200-Vehicle Fleet:"),
                                 verbatimTextOutput("detailedROI")
                             )
                         )
                ),
                
                tabPanel("Core Definition",
                         box(title = "Step 10: Define Your Core", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Sustainable Competitive Advantage:"),
                                 p("Identify unique capabilities that create barriers to competition and enable premium pricing.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI/Mobility Tech Competitive Core:"),
                                 tags$ul(
                                   tags$li(strong("Proprietary Algorithms:"), "Multi-objective optimization considering traffic, energy, time"),
                                   tags$li(strong("Real-time Learning:"), "AI models that improve with each delivery"),
                                   tags$li(strong("Network Effects:"), "More users = better traffic predictions = higher value"),
                                   tags$li(strong("Domain Expertise:"), "Deep understanding of logistics, energy, and autonomous systems"),
                                   tags$li(strong("Data Moat:"), "Unique datasets from fleet operations and infrastructure modeling")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Competitive Moat Strategy:"),
                                 tags$ul(
                                   tags$li(strong("Patent Portfolio:"), "File IP on key algorithms and optimization methods"),
                                   tags$li(strong("Exclusive Partnerships:"), "Strategic alliances with telematics and mapping providers"),
                                   tags$li(strong("Continuous Innovation:"), "R&D investment in autonomous and EV integration"),
                                   tags$li(strong("Customer Lock-in:"), "High switching costs due to data integration and workflow optimization")
                                 )
                             )
                         )
                ),
                
                tabPanel("Competitive Position",
                         box(title = "Step 11: Chart Your Competitive Position", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Positioning Strategy:"),
                                 p("Position in unique market space where you can win. Choose axes that matter to customers and favor your strengths.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("Competitive Positioning: AI-First Fleet Optimization"),
                                 p("Position as the only solution combining real-time AI optimization with future autonomous/EV readiness")
                             ),
                             
                             plotlyOutput("competitivePosition", height = "400px")
                         )
                )
              )
      ),
      
      # HOW DOES YOUR CUSTOMER ACQUIRE YOUR PRODUCT?
      tabItem(tabName = "acquisition",
              tabsetPanel(
                tabPanel("Decision Making Unit",
                         box(title = "Step 12: Determine the Decision-Making Unit (DMU)", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("DMU Mapping Process:"),
                                 p("Identify all people involved in purchase decision. B2B sales now involve 6.8 people on average.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("Fleet Management Software DMU:"),
                                 tags$ul(
                                   tags$li(strong("Economic Buyer:"), "COO/VP Operations (budget authority $50K+)"),
                                   tags$li(strong("Technical Buyer:"), "IT Director (integration and security concerns)"),
                                   tags$li(strong("User Buyer:"), "Fleet Operations Manager (daily user, performance impact)"),
                                   tags$li(strong("Coach:"), "Industry consultant or peer reference"),
                                   tags$li(strong("Champion:"), "Operations manager who sees competitive advantage")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("DMU Influence and Messaging Strategy:"),
                                 DT::dataTableOutput("dmuTable")
                             )
                         )
                ),
                
                tabPanel("Customer Acquisition Process",
                         box(title = "Step 13: Map Process to Acquire a Paying Customer", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Acquisition Process Framework:"),
                                 p("Document how customers move from problem awareness to signed contract. Identify all friction points and optimization opportunities.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI Fleet Optimization Sales Process:"),
                                 tags$ul(
                                   tags$li(strong("Lead Generation:"), "Industry events, LinkedIn outreach, partner referrals"),
                                   tags$li(strong("Qualification:"), "Fleet size, growth rate, current technology, budget timeline"),
                                   tags$li(strong("Discovery:"), "Pain point analysis, current process mapping, ROI potential"),
                                   tags$li(strong("Demo:"), "Live demonstration with customer's actual data"),
                                   tags$li(strong("Pilot:"), "30-day trial with 50-vehicle subset"),
                                   tags$li(strong("Negotiation:"), "Pricing, implementation timeline, success metrics")
                                 )
                             ),
                             
                             plotlyOutput("acquisitionFunnel", height = "300px")
                         )
                ),
                
                tabPanel("Sales Process",
                         box(title = "Step 18: Map Sales Process to Acquire a Customer", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Sales Methodology:"),
                                 p("Align your sales process with how customers buy. Focus on customer value, not product features.")
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("AI-Driven Sales Enablement:"),
                                 tags$ul(
                                   tags$li(strong("ROI Calculator:"), "Interactive tool showing savings based on customer data"),
                                   tags$li(strong("Demo Environment:"), "Sandbox with realistic delivery scenarios"),
                                   tags$li(strong("Reference Network:"), "Customer success stories with quantified results"),
                                   tags$li(strong("Pilot Framework:"), "Structured 30-day trial with success metrics")
                                 )
                             )
                         )
                )
              )
      ),
      
      # HOW DO YOU MAKE MONEY?
      tabItem(tabName = "revenue",
              tabsetPanel(
                tabPanel("Business Model",
                         box(title = "Step 15: Design a Business Model", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Business Model Selection:"),
                                 p("Choose revenue model that aligns with customer value delivery and enables sustainable growth.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI Fleet Optimization Business Model:"),
                                 tags$ul(
                                   tags$li(strong("SaaS Subscription:"), "$200/vehicle/month for AI optimization platform"),
                                   tags$li(strong("Performance-Based:"), "Share of savings model - 30% of documented fuel savings"),
                                   tags$li(strong("Freemium:"), "Basic route optimization free, AI features premium"),
                                   tags$li(strong("Enterprise:"), "Annual contracts $100K+ for large fleets with custom features"),
                                   tags$li(strong("Marketplace:"), "Commission on EV charging optimization and energy trading")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Revenue Model Decision Matrix:"),
                                 p(strong("Recommended:"), "Hybrid SaaS + Performance-based for risk reduction and value alignment")
                             )
                         )
                ),
                
                tabPanel("Pricing Framework",
                         box(title = "Step 16: Set Your Pricing Framework", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Value-Based Pricing:"),
                                 p("Price based on customer value, not cost. Test pricing with real customers before launch.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI Fleet Optimization Pricing Tiers:"),
                                 tags$ul(
                                   tags$li(strong("Starter:"), "$150/vehicle/month - Route optimization, basic analytics"),
                                   tags$li(strong("Professional:"), "$250/vehicle/month - AI optimization, predictive maintenance"),
                                   tags$li(strong("Enterprise:"), "$400/vehicle/month - Custom models, API access, dedicated support"),
                                   tags$li(strong("Performance:"), "25% of documented savings - Risk-free for customers")
                                 )
                             )
                         )
                ),
                
                tabPanel("LTV Calculation",
                         box(title = "Step 17: Calculate Lifetime Value (LTV)", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("LTV Formula:"),
                                 p("LTV = (ARPU × Gross Margin %) ÷ Churn Rate")
                             ),
                             
                             fluidRow(
                               column(3, numericInput("arpu", "ARPU ($):", 50000)),
                               column(3, numericInput("margin", "Margin (%):", 85)),
                               column(3, numericInput("churn", "Annual Churn (%):", 15)),
                               column(3, verbatimTextOutput("ltvResult"))
                             ),
                             
                             div(class = "ai-application",
                                 h4("Fleet Customer LTV Analysis:"),
                                 p("200-vehicle fleet paying $250/vehicle/month = $50K annual revenue. With 85% margins and 15% churn, LTV = $283K")
                             )
                         )
                ),
                
                tabPanel("CAC Calculation",
                         box(title = "Step 19: Calculate Customer Acquisition Cost (CAC)", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("CAC Components:"),
                                 p("Include all sales and marketing costs: salaries, advertising, tools, travel, overhead.")
                             ),
                             
                             fluidRow(
                               column(4, numericInput("sales_cost", "Sales Costs ($):", 15000)),
                               column(4, numericInput("marketing_cost", "Marketing Costs ($):", 8000)),
                               column(4, numericInput("new_customers", "New Customers:", 2))
                             ),
                             verbatimTextOutput("cacResult"),
                             verbatimTextOutput("ltvCacRatio"),
                             
                             div(class = "ai-application",
                                 h4("Fleet Customer Acquisition Strategy:"),
                                 p("Target CAC of $11.5K per customer with LTV:CAC ratio of 25:1, enabling profitable growth")
                             )
                         )
                )
              )
      ),
      
      # HOW DO YOU DESIGN & BUILD?
      tabItem(tabName = "product",
              tabsetPanel(
                tabPanel("Assumption Testing",
                         box(title = "Step 20-21: Test Key Assumptions", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Lean Startup Methodology:"),
                                 p("Test riskiest assumptions first. Use minimum viable experiments to validate or invalidate hypotheses.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI Fleet Optimization Key Assumptions:"),
                                 tags$ul(
                                   tags$li(strong("Technical:"), "AI can achieve 20%+ fuel savings in real-world conditions"),
                                   tags$li(strong("Market:"), "Fleet managers will pay $200+/vehicle/month for optimization"),
                                   tags$li(strong("Adoption:"), "Drivers will follow AI-generated routes consistently"),
                                   tags$li(strong("Integration:"), "Can integrate with major fleet management systems"),
                                   tags$li(strong("Scalability:"), "Algorithm performance maintains with 10K+ vehicles")
                                 )
                             ),
                             
                             DT::dataTableOutput("assumptionTable")
                         )
                ),
                
                tabPanel("MVBP Definition",
                         box(title = "Step 22: Define Minimum Viable Business Product", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("MVBP vs MVP:"),
                                 p("MVBP includes business operations (billing, support) not just core features. Must generate revenue to validate business model.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI Fleet Optimization MVBP:"),
                                 tags$ul(
                                   tags$li(strong("Core Algorithm:"), "Basic route optimization for 50-vehicle pilot"),
                                   tags$li(strong("Web Dashboard:"), "Fleet manager view with route plans and performance metrics"),
                                   tags$li(strong("Mobile App:"), "Driver navigation with delivery updates"),
                                   tags$li(strong("Billing System:"), "Monthly subscription with usage tracking"),
                                   tags$li(strong("Support Portal:"), "Help desk and onboarding resources")
                                 )
                             )
                         )
                ),
                tabPanel("Market Validation",
                         box(title = "Step 23: Show Dogs Will Eat the Dog Food", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Revenue Validation:"),
                                 p("Paying customers provide strongest validation. Target 10+ customers with high satisfaction and low churn.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("Fleet Optimization Market Validation:"),
                                 tags$ul(
                                   tags$li(strong("Pilot Success:"), "3 customers achieve 18%+ fuel savings in 30-day trials"),
                                   tags$li(strong("Paying Customers:"), "5 customers convert to paid subscriptions"),
                                   tags$li(strong("Usage Metrics:"), "85% of drivers follow AI recommendations daily"),
                                   tags$li(strong("Customer Satisfaction:"), "Net Promoter Score of 70+ from pilot customers"),
                                   tags$li(strong("Reference Willingness:"), "80% of customers willing to provide references")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Validation Success Metrics:"),
                                 tags$ul(
                                   tags$li("Monthly recurring revenue growth >20%"),
                                   tags$li("Customer churn rate <10% annually"),
                                   tags$li("Product usage >80% driver adoption"),
                                   tags$li("Sales pipeline >3x current revenue")
                                 )
                             )
                         )
                )
              )
      ),
      
      # HOW DO YOU SCALE?
      tabItem(tabName = "scaling",
              tabsetPanel(
                tabPanel("Follow-on Markets",
                         box(title = "Step 14: Calculate TAM Size for Follow-on Markets", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Market Expansion Strategy:"),
                                 p("Identify adjacent markets after dominating beachhead. Prioritize by customer similarity and go-to-market efficiency.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI/Mobility Tech Expansion Markets:"),
                                 tags$ul(
                                   tags$li(strong("Smart Cities ($8B):"), "Municipal transport optimization, traffic management"),
                                   tags$li(strong("Autonomous Fleets ($12B):"), "Self-driving vehicle coordination and routing"),
                                   tags$li(strong("EV Infrastructure ($15B):"), "Charging network optimization, energy management"),
                                   tags$li(strong("Supply Chain ($25B):"), "Warehouse automation, freight optimization"),
                                   tags$li(strong("Personal Mobility ($30B):"), "Ride-sharing optimization, personal EV routing")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Market Expansion Timeline:"),
                                 tags$ul(
                                   tags$li(strong("Year 1-2:"), "Dominate last-mile delivery optimization"),
                                   tags$li(strong("Year 2-3:"), "Expand to freight and long-haul trucking"),
                                   tags$li(strong("Year 3-4:"), "Enter smart city and municipal markets"),
                                   tags$li(strong("Year 4-5:"), "Launch autonomous vehicle coordination"),
                                   tags$li(strong("Year 5+:"), "Global expansion and platform ecosystem")
                                 )
                             ),
                             
                             plotlyOutput("expansionChart", height = "300px")
                         )
                ),
                
                tabPanel("Product Roadmap",
                         box(title = "Step 24: Develop a Product Plan", status = "primary", solidHeader = TRUE, width = 12,
                             div(class = "framework-box",
                                 h4("Product Planning Framework:"),
                                 p("Balance customer requests, technical debt, and strategic initiatives. Maintain 6-month detailed plan with 18-month vision.")
                             ),
                             
                             div(class = "ai-application",
                                 h4("AI Fleet Optimization Product Roadmap:"),
                                 tags$ul(
                                   tags$li(strong("Q1-Q2 2024:"), "Core optimization engine, pilot customer deployment"),
                                   tags$li(strong("Q3-Q4 2024:"), "Predictive maintenance, mobile driver app, API integrations"),
                                   tags$li(strong("Q1-Q2 2025:"), "EV-specific optimization, charging network integration"),
                                   tags$li(strong("Q3-Q4 2025:"), "Autonomous vehicle readiness, smart city partnerships"),
                                   tags$li(strong("2026+:"), "AI platform for mobility ecosystem, international expansion")
                                 )
                             ),
                             
                             div(class = "decision-matrix",
                                 h4("Technical Architecture Evolution:"),
                                 tags$ul(
                                   tags$li(strong("Foundation:"), "Cloud-native microservices, real-time processing"),
                                   tags$li(strong("AI/ML:"), "Continuous learning, multi-objective optimization"),
                                   tags$li(strong("Integration:"), "API-first design, ecosystem partnerships"),
                                   tags$li(strong("Scalability:"), "Edge computing, distributed algorithms"),
                                   tags$li(strong("Innovation:"), "Quantum computing readiness, 5G/6G integration")
                                 )
                             ),
                             
                             plotlyOutput("productRoadmap", height = "300px")
                         )
                )
              )
      )
    )
  )
)

# Server function
server <- function(input, output, session) {
  
  # TAM Calculation
  output$tamCalculation <- renderText({
    tam <- input$potential_customers * input$annual_revenue
    paste("Total Addressable Market: $", format(tam, big.mark = ","))
  })
  
  # ROI Calculation
  output$roiCalculation <- renderText({
    annual_fuel_savings <- input$fleet_size * input$daily_fuel * 365 * 0.20  # 20% savings
    planning_time_savings <- input$planning_hours * 250 * 50  # 250 days, $50/hour
    total_savings <- annual_fuel_savings + planning_time_savings
    paste("Annual Savings: $", format(round(total_savings, 0), big.mark = ","))
  })
  
  # Detailed ROI
  output$detailedROI <- renderText({
    fleet_size <- input$fleet_size
    software_cost <- fleet_size * 250 * 12  # $250/vehicle/month
    fuel_savings <- fleet_size * input$daily_fuel * 365 * 0.20
    efficiency_gains <- fleet_size * 100 * 12  # $100/vehicle/month efficiency
    total_benefits <- fuel_savings + efficiency_gains
    roi <- ((total_benefits - software_cost) / software_cost) * 100
    paste("Software Cost: $", format(software_cost, big.mark = ","), 
          "\nTotal Benefits: $", format(round(total_benefits, 0), big.mark = ","),
          "\nROI: ", round(roi, 0), "%")
  })
  
  # LTV Calculation
  output$ltvResult <- renderText({
    ltv <- (input$arpu * input$margin / 100) / (input$churn / 100)
    paste("LTV: $", format(round(ltv, 0), big.mark = ","))
  })
  
  # CAC Calculation
  output$cacResult <- renderText({
    cac <- (input$sales_cost + input$marketing_cost) / input$new_customers
    paste("CAC: $", format(round(cac, 0), big.mark = ","))
  })
  
  # LTV:CAC Ratio
  output$ltvCacRatio <- renderText({
    ltv <- (input$arpu * input$margin / 100) / (input$churn / 100)
    cac <- (input$sales_cost + input$marketing_cost) / input$new_customers
    ratio <- ltv / cac
    status <- if(ratio >= 3) "✓ Excellent" else if(ratio >= 2) "⚠ Good" else "✗ Poor"
    paste("LTV:CAC Ratio:", round(ratio, 1), ":1", status)
  })
  
  # Segment Matrix
  output$segmentMatrix <- renderDT({
    data.frame(
      Segment = c("Last-Mile Delivery", "Long-Haul Freight", "Smart Cities", "Ride Sharing"),
      Market_Size_B = c(2.8, 4.2, 1.5, 3.1),
      Competition = c("Medium", "High", "Low", "High"),
      Access = c("High", "Medium", "Low", "Medium"),
      AI_Advantage = c("High", "Medium", "High", "High"),
      Recommended = c("PRIMARY", "Secondary", "Future", "Future")
    )
  }, options = list(pageLength = 5, searching = FALSE))
  
  # Next Customers Table
  output$nextCustomersTable <- renderDT({
    data.frame(
      Company = c("RegionalExpress", "CityDelivery Pro", "FastTrack Logistics", "GreenFleet Co", "MetroCarriers"),
      Fleet_Size = c(180, 350, 120, 90, 280),
      Industry = c("E-commerce", "Food Delivery", "B2B Freight", "Retail", "Healthcare"),
      Growth_Rate = c("25%", "30%", "15%", "20%", "18%"),
      Tech_Readiness = c("High", "Medium", "High", "Low", "Medium"),
      Priority = c("High", "High", "Medium", "Low", "Medium")
    )
  }, options = list(pageLength = 5, searching = FALSE))
  
  # DMU Table
  output$dmuTable <- renderDT({
    data.frame(
      Role = c("Economic Buyer", "Technical Buyer", "User Buyer", "Coach", "Champion"),
      Title = c("COO", "IT Director", "Fleet Manager", "Industry Consultant", "Operations Manager"),
      Influence = c("High", "Medium", "High", "Medium", "High"),
      Key_Message = c("ROI & Growth", "Security & Integration", "Ease of Use", "Best Practices", "Competitive Advantage")
    )
  }, options = list(pageLength = 5, searching = FALSE))
  
  # Assumption Table
  output$assumptionTable <- renderDT({
    data.frame(
      Assumption = c("20% fuel savings achievable", "Customers pay $250/vehicle/mo", "85% driver adoption rate", "Integration possible", "AI scales to 1000+ vehicles"),
      Risk = c("High", "High", "Medium", "Medium", "High"),
      Test_Method = c("Pilot study with GPS tracking", "Customer interviews & pricing tests", "Driver behavior analysis", "Technical integration tests", "Performance benchmarking"),
      Status = c("VALIDATED", "TESTING", "VALIDATED", "IN PROGRESS", "PLANNED"),
      Evidence = c("18% savings in 3 pilots", "8/10 customers accept pricing", "87% adoption in pilot", "2/3 integrations successful", "Not yet tested")
    )
  }, options = list(pageLength = 5, searching = FALSE))
  
  # Charts
  output$segmentationChart <- renderPlotly({
    data <- data.frame(
      Segment = c("Last-Mile", "Freight", "Smart Cities", "Ride Share"),
      Size = c(28, 42, 15, 31),
      Access = c(4, 2, 1, 3),
      Revenue = c(4, 3, 2, 3)
    )
    plot_ly(data, x = ~Access, y = ~Revenue, size = ~Size, color = ~Segment,
            colors = c("#FF8C00", "#FFD700", "#DAA520", "#B8860B"),
            type = "scatter", mode = "markers+text", text = ~Segment) %>%
      layout(title = "AI/Mobility Market Segments",
             xaxis = list(title = "Market Access Difficulty (1=Hard, 5=Easy)"),
             yaxis = list(title = "Revenue Potential (1=Low, 5=High)"),
             paper_bgcolor = '#FFF8DC', plot_bgcolor = '#FFFACD')
  })
  
  output$beachheadAnalysis <- renderPlotly({
    data <- data.frame(
      Market = c("Last-Mile Delivery", "Long-Haul Freight", "Smart Cities", "Ride Sharing"),
      Market_Size = c(2.8, 4.2, 1.5, 3.1),
      Competitive_Intensity = c(2, 4, 1, 5),
      Strategic_Value = c(5, 3, 4, 3)
    )
    plot_ly(data, x = ~Competitive_Intensity, y = ~Strategic_Value, 
            size = ~Market_Size, color = ~Market,
            type = "scatter", mode = "markers+text", text = ~Market) %>%
      layout(title = "Beachhead Market Selection",
             xaxis = list(title = "Competitive Intensity (1=Low, 5=High)"),
             yaxis = list(title = "Strategic Value (1=Low, 5=High)"))
  })
  
  output$customerJourney <- renderPlotly({
    stages <- c("Awareness", "Research", "Evaluation", "Trial", "Purchase", "Onboarding")
    conversion <- c(100, 40, 25, 15, 10, 9)
    data <- data.frame(Stage = factor(stages, levels = stages), Conversion = conversion)
    
    plot_ly(data, x = ~Stage, y = ~Conversion, type = "bar",
            marker = list(color = "#FF8C00")) %>%
      layout(title = "Customer Journey Conversion Funnel",
             xaxis = list(title = "Journey Stage"),
             yaxis = list(title = "Prospects (%)"))
  })
  
  output$competitivePosition <- renderPlotly({
    competitors <- data.frame(
      Company = c("Our AI Platform", "Traditional Fleet Mgmt", "Route Optimizer", "Telematics Provider"),
      AI_Capability = c(5, 1, 3, 2),
      Market_Share = c(1, 4, 3, 4),
      Type = c("Us", "Legacy", "Competitor", "Adjacent")
    )
    
    plot_ly(competitors, x = ~Market_Share, y = ~AI_Capability,
            text = ~Company, color = ~Type,
            type = "scatter", mode = "markers+text") %>%
      layout(title = "Competitive Positioning Matrix",
             xaxis = list(title = "Current Market Share (1=Low, 5=High)"),
             yaxis = list(title = "AI Capability (1=Basic, 5=Advanced)"))
  })
  
  output$acquisitionFunnel <- renderPlotly({
    stages <- c("Leads", "Qualified", "Demo", "Pilot", "Proposal", "Closed")
    prospects <- c(1000, 200, 100, 40, 25, 10)
    data <- data.frame(Stage = factor(stages, levels = stages), Prospects = prospects)
    
    plot_ly(data, x = ~Stage, y = ~Prospects, type = "bar",
            marker = list(color = "#DAA520")) %>%
      layout(title = "Sales Acquisition Funnel",
             xaxis = list(title = "Sales Stage"),
             yaxis = list(title = "Number of Prospects"))
  })
  
  output$expansionChart <- renderPlotly({
    markets <- data.frame(
      Market = c("Last-Mile Delivery", "Smart Cities", "Autonomous Fleets", "EV Infrastructure", "Supply Chain"),
      TAM_Billions = c(2.8, 8, 12, 15, 25),
      Timeline_Years = c(1, 3, 4, 3, 5),
      Strategic_Fit = c(5, 4, 5, 4, 3)
    )
    
    plot_ly(markets, x = ~Timeline_Years, y = ~TAM_Billions,
            size = ~Strategic_Fit, color = ~Market,
            type = "scatter", mode = "markers+text", text = ~Market) %>%
      layout(title = "Market Expansion Roadmap",
             xaxis = list(title = "Years to Market Entry"),
             yaxis = list(title = "TAM ($ Billions)"))
  })
  
  output$productRoadmap <- renderPlotly({
    quarters <- c("Q1'24", "Q2'24", "Q3'24", "Q4'24", "Q1'25", "Q2'25")
    features <- c("Core AI", "Mobile App", "Predictive Analytics", "EV Integration", "Autonomous Ready", "Platform API")
    completion <- c(90, 70, 40, 20, 10, 5)
    
    data <- data.frame(Quarter = factor(quarters, levels = quarters), 
                       Feature = features, Completion = completion)
    
    plot_ly(data, x = ~Quarter, y = ~Completion, color = ~Feature,
            type = "scatter", mode = "lines+markers") %>%
      layout(title = "Product Development Roadmap",
             xaxis = list(title = "Timeline"),
             yaxis = list(title = "Completion %"))
  })
}

# Run the application
shinyApp(ui = ui, server = server)