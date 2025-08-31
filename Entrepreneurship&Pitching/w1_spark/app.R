# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(leaflet)
library(dplyr)
library(shinydashboardPlus)
library(shinyWidgets)

# Define UI
ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(
    title = "ATERA ANALYTICS - NetZero Transport Through Advanced EV Tech and AI",
    titleWidth = 600
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      menuItem("Executive Summary", tabName = "executive", icon = icon("chart-line")),
      menuItem("Company Purpose", tabName = "purpose", icon = icon("lightbulb")),
      menuItem("Market Context", tabName = "context", icon = icon("globe")),
      menuItem("Product Portfolio", tabName = "product", icon = icon("cogs")),
      menuItem("Team & Leadership", tabName = "team", icon = icon("users")),
      menuItem("Market Size & Strategy", tabName = "market", icon = icon("chart-pie")),
      menuItem("Competitive Analysis", tabName = "competition", icon = icon("chess")),
      menuItem("Route to Market", tabName = "route", icon = icon("route")),
      menuItem("Live Demo", tabName = "demo", icon = icon("map"))
    )
  ),
  
  # Body
  dashboardBody(
    # Custom CSS
    tags$head(
      tags$style(HTML("
        .main-header .navbar { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          border: none !important; 
          box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important;
        }
        .main-header .navbar-brand { 
          color: white !important; 
          font-weight: 700 !important; 
          font-size: 18px !important;
        }
        .main-sidebar { 
          background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%) !important; 
        }
        .sidebar-menu > li > a { 
          color: #ecf0f1 !important; 
          border-left: 3px solid transparent; 
          transition: all 0.3s ease !important;
          font-weight: 500 !important;
        }
        .sidebar-menu > li.active > a { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          border-left: 3px solid #f39c12 !important; 
          color: white !important; 
          box-shadow: inset 0 0 10px rgba(0,0,0,0.2) !important;
        }
        .sidebar-menu > li:hover > a { 
          background-color: #3e5771 !important; 
          color: white !important; 
        }
        .content-wrapper { 
          background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important; 
        }
        .box { 
          border: none !important; 
          border-radius: 12px !important; 
          box-shadow: 0 4px 20px rgba(0,0,0,0.08) !important;
          background: white !important;
          margin-bottom: 25px !important;
        }
        .box-header { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          color: white !important;
          border-radius: 12px 12px 0 0 !important; 
          font-weight: 600 !important;
          padding: 20px !important;
          font-size: 16px !important;
        }
        .executive-summary-box { 
          background: linear-gradient(135deg, #ffffff 0%, #f8f9ff 100%);
          border: none;
          border-left: 5px solid #667eea; 
          padding: 30px; 
          margin-bottom: 30px; 
          border-radius: 12px; 
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.1);
        }
        .achievement-box {
          background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
          border: 1px solid #e3e8ff;
          border-left: 5px solid #4f46e5;
          padding: 25px;
          margin: 20px 0;
          border-radius: 12px;
          box-shadow: 0 2px 10px rgba(79, 70, 229, 0.1);
        }
        .leadership-highlight {
          background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
          border: 1px solid #e3e8ff;
          border-left: 5px solid #667eea;
          padding: 25px;
          margin: 20px 0;
          border-radius: 12px;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.1);
        }
        .small-box { 
          border-radius: 12px !important; 
          box-shadow: 0 4px 15px rgba(0,0,0,0.1) !important;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          margin-bottom: 25px !important;
        }
        .small-box .icon { opacity: 0.8 !important; font-size: 60px !important; }
        .small-box h3 { font-weight: 700 !important; font-size: 28px !important; }
        .small-box p { font-size: 14px !important; font-weight: 600 !important; }
        .plotly { 
          border-radius: 12px !important; 
          box-shadow: 0 2px 10px rgba(0,0,0,0.05) !important;
        }
        .dataTables_wrapper { 
          background: white; 
          border-radius: 12px; 
          padding: 20px; 
          box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }
        .btn-primary { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          border: none !important; 
          border-radius: 8px !important;
          font-weight: 600 !important;
          padding: 12px 25px !important;
          transition: all 0.3s ease !important;
        }
        .btn-primary:hover {
          transform: translateY(-2px) !important;
          box-shadow: 0 8px 20px rgba(102, 126, 234, 0.3) !important;
        }
        h3, h4 { color: #2c3e50; font-weight: 600; }
        .executive-title { 
          color: #667eea; 
          font-size: 24px; 
          font-weight: 800; 
          margin-bottom: 10px;
          text-transform: uppercase;
          letter-spacing: 1px;
        }
        .role-description { 
          color: #475569; 
          font-size: 16px; 
          font-style: italic; 
          margin-bottom: 20px;
          line-height: 1.6;
        }
        .metric-highlight {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 8px 15px;
          border-radius: 20px;
          font-weight: 700;
          display: inline-block;
          margin: 5px;
          box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
        }
        .team-size {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 10px 20px;
          border-radius: 25px;
          font-weight: 700;
          font-size: 18px;
          display: inline-block;
          box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }
        .ai-focus {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 8px 16px;
          border-radius: 20px;
          font-weight: 600;
          display: inline-block;
          margin: 5px;
        }
      "))
    ),
    
    tabItems(
      # Executive Summary Tab
      tabItem(
        tabName = "executive",
        fluidRow(
          box(
            title = "EXECUTIVE SUMMARY", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                div(class = "executive-title", "NetZero Transport Through Advanced EV Tech and AI"),
                div(class = "role-description", 
                    "Leading innovator in planning energy infrastructure for EVs and semi-autonomous vehicles"),
                p("Atera Analytics is transforming the transportation ecosystem through advanced AI-powered solutions 
                  for electric vehicle route optimization and infrastructure planning. Our comprehensive platform 
                  integrates real-time data analytics, machine learning algorithms, and GIS mapping to deliver 
                  unprecedented efficiency in EV fleet management."),
                br(),
                h4("Key Value Propositions:"),
                tags$ul(
                  tags$li(span(class = "metric-highlight", "Up to 25% operational cost reduction")),
                  tags$li(span(class = "metric-highlight", "Real-time route optimization with 1m resolution")),
                  tags$li(span(class = "metric-highlight", "Digital twin of UK charging infrastructure")),
                  tags$li(span(class = "metric-highlight", "AI-powered fleet management solutions"))
                )
            )
          )
        ),
        
        fluidRow(
          valueBox(
            value = "£24B",
            subtitle = "Global AI Logistics Market",
            icon = icon("globe"),
            color = "purple",
            width = 3
          ),
          valueBox(
            value = "42 Years",
            subtitle = "Cumulative Team Experience",
            icon = icon("users"),
            color = "blue",
            width = 3
          ),
          valueBox(
            value = "£120K+",
            subtitle = "Secured Funding",
            icon = icon("pound-sign"),
            color = "green",
            width = 3
          ),
          valueBox(
            value = "50K+",
            subtitle = "UK Charging Points Mapped",
            icon = icon("charging-station"),
            color = "yellow",
            width = 3
          )
        ),
        
        fluidRow(
          box(
            title = "Key Achievements & Recognition", status = "primary", solidHeader = TRUE, width = 6,
            div(class = "achievement-box",
                h4("🏆 Awards & Recognition"),
                p("• 3 Major recognitions from BridgeAI and UK Government entities"),
                p("• Innovate UK NetZero Living Grant recipient"),
                p("• Innovate UK Business Growth support program"),
                br(),
                h4("🔬 Technology & IP"),
                p("• Proprietary algorithms and technology developed"),
                p("• IP protection procedures secured"),
                p("• Advanced GIS integration with 1m resolution mapping")
            )
          ),
          box(
            title = "Market Position", status = "primary", solidHeader = TRUE, width = 6,
            div(class = "achievement-box",
                h4("📊 Market Opportunity"),
                p("• £500M Serviceable Obtainable Market (UK SMEs)"),
                p("• £2.5B Serviceable Addressable Market (Large Fleets)"),
                p("• £24B Total Addressable Market (Global AI Logistics)"),
                br(),
                h4("🚀 Growth Trajectory"),
                p("• Commercial partner secured since March 2023"),
                p("• MVP launched October 2024"),
                p("• Expanding to overseas markets in 2025")
            )
          )
        )
      ),
      
      # Company Purpose Tab
      tabItem(
        tabName = "purpose",
        fluidRow(
          box(
            title = "COMPANY PURPOSE & VISION", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                h3("Transforming Transportation Infrastructure"),
                p("Our startup is emerging as a leading innovator in planning energy infrastructure for EVs and 
                  semi-autonomous vehicles while optimizing the surrounding ecosystem. We are evolving from modeling 
                  EV charging points to encompassing all road infrastructure in the UK, with the goal of optimizing 
                  the national supply chain through integrated, multi-modal transport fleets."),
                br(),
                fluidRow(
                  column(6,
                         div(class = "leadership-highlight",
                             h4("🚗 Electric Vehicles"),
                             p("Advanced EV fleet management and route optimization solutions")
                         )
                  ),
                  column(6,
                         div(class = "leadership-highlight",
                             h4("⚡ EV Charging Infrastructure"),
                             p("Comprehensive charging point mapping and optimization")
                         )
                  )
                ),
                fluidRow(
                  column(6,
                         div(class = "leadership-highlight",
                             h4("🤖 AI Integration"),
                             p("Machine learning algorithms for predictive analytics and optimization")
                         )
                  ),
                  column(6,
                         div(class = "leadership-highlight",
                             h4("🔋 Renewable Energy"),
                             p("Integration with sustainable energy sources and smart grid systems")
                         )
                  )
                ),
                fluidRow(
                  column(12,
                         div(class = "leadership-highlight",
                             h4("🚙 Autonomous Vehicle Ready"),
                             p("Future-proof solutions designed for semi-autonomous and fully autonomous vehicle integration")
                         )
                  )
                )
            )
          )
        )
      ),
      
      # Market Context Tab
      tabItem(
        tabName = "context",
        fluidRow(
          box(
            title = "GLOBAL MARKET CONTEXT", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                h3("Market Dynamics & Opportunity"),
                p("The convergence of electric vehicle adoption, AI advancement, and sustainability imperatives 
                  creates an unprecedented market opportunity for intelligent transportation solutions.")
            )
          )
        ),
        
        fluidRow(
          valueBox(
            value = "30M",
            subtitle = "EVs in UK by 2030 (20x globally)",
            icon = icon("car-electric"),
            color = "blue",
            width = 3
          ),
          valueBox(
            value = "44%",
            subtitle = "Global Average CAGR",
            icon = icon("chart-line"),
            color = "green",
            width = 3
          ),
          valueBox(
            value = "$60B",
            subtitle = "Global AI Logistics Market 2025",
            icon = icon("robot"),
            color = "purple",
            width = 3
          ),
          valueBox(
            value = "20%",
            subtitle = "Cost Savings from AI Optimization",
            icon = icon("percentage"),
            color = "orange",
            width = 3
          )
        ),
        
        fluidRow(
          box(
            title = "Market Growth Projections", status = "primary", solidHeader = TRUE, width = 8,
            plotlyOutput("marketGrowthChart")
          ),
          box(
            title = "Key Market Drivers", status = "primary", solidHeader = TRUE, width = 4,
            div(class = "achievement-box",
                h4("🌍 Environmental Impact"),
                p("80% of vehicles to be free from fossil fuels by 2030"),
                br(),
                h4("💰 Economic Benefits"),
                p("Up to 20% savings on energy and idle time costs"),
                br(),
                h4("🚀 Technology Advancement"),
                p("AI-powered optimization becoming standard practice"),
                br(),
                h4("📈 Market Expansion"),
                p("Exponential growth in EV adoption globally")
            )
          )
        )
      ),
      
      # Product Portfolio Tab
      tabItem(
        tabName = "product",
        fluidRow(
          box(
            title = "ATERA EV SOLUTION PORTFOLIO", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                h3("AteraEV: End-to-End Real-Time Software Application"),
                p("Our comprehensive solution focuses on EV route planning and infrastructure development, 
                  integrating AI, APIs, and network optimization for maximum efficiency."),
                br(),
                span(class = "ai-focus", "AI-Powered"),
                span(class = "ai-focus", "Real-Time Analytics"),
                span(class = "ai-focus", "GIS Integration"),
                span(class = "ai-focus", "Fleet Management"),
                span(class = "ai-focus", "1m Resolution Mapping")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Core Product Features", status = "primary", solidHeader = TRUE, width = 6,
            div(class = "leadership-highlight",
                h4("🗺️ Multi-Objective Route Optimization"),
                p("• 1-meter resolution road mapping"),
                p("• Real-time traffic and charging point integration"),
                p("• Dynamic route adjustments based on battery levels"),
                br(),
                h4("📊 GIS Platform Analytics"),
                p("• Comprehensive UK road infrastructure mapping"),
                p("• 50,000+ charging points database"),
                p("• Candidate monitoring points identification"),
                br(),
                h4("🔌 Charging Infrastructure Management"),
                p("• Digital twin of UK charging network"),
                p("• Availability and reliability tracking"),
                p("• Cost optimization algorithms")
            )
          ),
          box(
            title = "Technical Specifications", status = "primary", solidHeader = TRUE, width = 6,
            div(class = "leadership-highlight",
                h4("🚗 Vehicle Integration"),
                p("• Kia Niro EV with multiple sensors"),
                p("• Autonomous driving sensor suite"),
                p("• Real-time performance monitoring"),
                br(),
                h4("📡 Data Collection Equipment"),
                p("• Advanced sensing equipment for EV performance"),
                p("• Geographical data collection systems"),
                p("• IoT integration capabilities"),
                br(),
                h4("🤖 AI & Machine Learning"),
                p("• Predictive analytics algorithms"),
                p("• Pattern recognition systems"),
                p("• Continuous learning optimization")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Operational Benefits", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(3,
                     div(style = "text-align: center; padding: 20px;",
                         h2(style = "color: #667eea; font-weight: bold;", "25%"),
                         h4("Cost Reduction")
                     )
              ),
              column(3,
                     div(style = "text-align: center; padding: 20px;",
                         h2(style = "color: #667eea; font-weight: bold;", "1m"),
                         h4("Resolution Accuracy")
                     )
              ),
              column(3,
                     div(style = "text-align: center; padding: 20px;",
                         h2(style = "color: #667eea; font-weight: bold;", "50K+"),
                         h4("Charging Points")
                     )
              ),
              column(3,
                     div(style = "text-align: center; padding: 20px;",
                         h2(style = "color: #667eea; font-weight: bold;", "Real-Time"),
                         h4("Optimization")
                     )
              )
            )
          )
        )
      ),
      
      # Team Tab
      tabItem(
        tabName = "team",
        fluidRow(
          box(
            title = "LEADERSHIP TEAM", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                div(class = "team-size", "42 Years Cumulative Experience"),
                br(), br(),
                p("Our diverse, experienced team combines deep technical expertise in AI, machine learning, 
                  and transportation with proven commercial and operational capabilities.")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Core Leadership Team", status = "primary", solidHeader = TRUE, width = 8,
            div(class = "leadership-highlight",
                h4("Joseph Francisco Zubizarreta - Founder & CEO"),
                div(class = "role-description", "16 years in AI product development"),
                p("• Postgraduate Research Degree in Machine Learning"),
                p("• Key projects: Robotics, Autonomous Vehicles, Cyber Security, Blockchain"),
                p("• Cloud Architecture, Mortgages & Fintech expertise"),
                br(),
                
                h4("Dr. Victor R Cano - CTO and Head of AI"),
                div(class = "role-description", "Postgraduate Research Degree in Machine Learning and AI"),
                p("• Key projects: Anomaly Detection, Autonomous Vehicles"),
                p("• Machine Learning and Automation specialist"),
                br(),
                
                h4("Sarai Mazu - COO"),
                div(class = "role-description", "12 years Customer Focus expertise in Americas"),
                p("• Diverse industries experience including SaaS"),
                p("• Front-End Web Developer and Bionic Tech Expert"),
                br(),
                
                h4("Ali Boloori - Head of Data Engineering"),
                div(class = "role-description", "MSc in Artificial Intelligence and Computer Science"),
                p("• Sophisticated tools for data engineering and modelling"),
                p("• Advanced data pipeline architecture expertise")
            )
          ),
          box(
            title = "Advisory Board", status = "primary", solidHeader = TRUE, width = 4,
            div(class = "achievement-box",
                h4("Michiel Boorsma"),
                p(strong("Senior Business Advisor")),
                p("Experienced advisor with multiple board roles across SMEs"),
                br(),
                
                h4("Krzysztof Kaszewski"),
                p(strong("Independent Cloud Advisor")),
                p("18+ years in Digital Transformation, Cloud and AI"),
                br(),
                
                h4("Carlos Rodriguez"),
                p(strong("Exited Founder & Banking Advisor")),
                p("40 years in Global Software Sales with world-class organizations")
            )
          )
        )
      ),
      
      # Market Size Tab
      tabItem(
        tabName = "market",
        fluidRow(
          box(
            title = "MARKET SIZE & PENETRATION STRATEGY", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                h3("Structured Market Approach"),
                p("Our go-to-market strategy follows a structured approach from UK SMEs to global fleet organizations, 
                  leveraging proven partnerships and government support.")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Market Size Visualization", status = "primary", solidHeader = TRUE, width = 8,
            plotlyOutput("marketSizeChart")
          ),
          box(
            title = "Market Segments", status = "primary", solidHeader = TRUE, width = 4,
            div(class = "achievement-box",
                h4("🎯 Total Addressable Market"),
                p(strong("£24B - Global AI Logistics")),
                br(),
                h4("🌍 Serviceable Addressable Market"),
                p(strong("£2.5B - Large Fleet Organizations")),
                br(),
                h4("🇬🇧 Serviceable Obtainable Market"),
                p(strong("£500M - UK SMEs with EV needs"))
            )
          )
        ),
        
        fluidRow(
          box(
            title = "18-Month Execution Roadmap", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "leadership-highlight",
                fluidRow(
                  column(3,
                         div(class = "achievement-box",
                             h4("Q1: Foundation"),
                             p("✅ First Sponsoring Client (March 2023)"),
                             p("• Commercial partner secured"),
                             p("• Data & business context established")
                         )
                  ),
                  column(3,
                         div(class = "achievement-box",
                             h4("Q2: Acceleration"),
                             p("⚡ Innovate UK NetZero Grant"),
                             p("• AI design acceleration"),
                             p("• Commercial network expansion")
                         )
                  ),
                  column(3,
                         div(class = "achievement-box",
                             h4("Q3: Launch"),
                             p("🚀 MVP Launch (Oct 2024)"),
                             p("• Innovate UK Business Growth"),
                             p("• UK market deployment")
                         )
                  ),
                  column(3,
                         div(class = "achievement-box",
                             h4("Q4: Expansion"),
                             p("🌍 Overseas Markets"),
                             p("• Platform integration"),
                             p("• International partnerships")
                         )
                  )
                )
            )
          )
        )
      ),
      
      # Competition Tab
      tabItem(
        tabName = "competition",
        fluidRow(
          box(
            title = "COMPETITIVE LANDSCAPE ANALYSIS", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                h3("Market Differentiation Strategy"),
                p("AteraEV distinguishes itself through comprehensive feature integration, advanced AI capabilities, 
                  and focus on autonomous vehicle readiness that competitors lack.")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Competitive Feature Matrix", status = "primary", solidHeader = TRUE, width = 12,
            DT::dataTableOutput("competitiveMatrix")
          )
        ),
        
        fluidRow(
          box(
            title = "Competitive Advantages", status = "primary", solidHeader = TRUE, width = 6,
            div(class = "leadership-highlight",
                h4("🎯 Unique Differentiators"),
                p("✅ GIS integration with 1m resolution"),
                p("✅ Comprehensive fleet management support"),
                p("✅ Total Cost of Ownership calculations"),
                p("✅ LLM Gen AI Integration"),
                p("✅ Route planning for autonomous vehicles"),
                br(),
                h4("🏆 Market Position"),
                p("Only solution offering complete integration of advanced features 
                  required for next-generation transportation management.")
            )
          ),
          box(
            title = "Competitor Analysis", status = "primary", solidHeader = TRUE, width = 6,
            div(class = "achievement-box",
                h4("ZapMap"),
                p("• Strong in route planning and fleet management"),
                p("• Limited GIS integration and AI capabilities"),
                br(),
                h4("Plug Share"),
                p("• Good visualization and route planning"),
                p("• No fleet management or autonomous vehicle support"),
                br(),
                h4("Charge Point"),
                p("• Cost calculation and AI integration"),
                p("• Limited route planning and GIS capabilities")
            )
          )
        )
      ),
      
      # Route to Market Tab
      tabItem(
        tabName = "route",
        fluidRow(
          box(
            title = "ROUTE TO MARKET STRATEGY", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                h3("Strategic Partnership & Investment Approach"),
                p("Our route to market leverages strategic client partnerships, government support, 
                  and international investor collaboration to achieve rapid scale and market penetration.")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Strategic Pillars", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(6,
                     div(class = "leadership-highlight",
                         h4("🤝 Strategic Partnerships"),
                         p("• Focus on multimodal transport integration"),
                         p("• Major UK organizations using EV fleets"),
                         p("• Commercial data and context sharing"),
                         br(),
                         h4("💼 Investment Strategy"),
                         p("• Angel and VC investors in UK, Europe, USA"),
                         p("• Funding for talent acquisition and tech development"),
                         p("• Commercialization acceleration programs")
                     )
              ),
              column(6,
                     div(class = "leadership-highlight",
                         h4("🎯 Value Proposition"),
                         p("• 10x value delivery through tech expertise"),
                         p("• Passionate team with proven track record"),
                         p("• Future-ready solutions for evolving market"),
                         br(),
                         h4("📈 Growth Enablers"),
                         p("• Government grant funding secured"),
                         p("• Award recognition and credibility"),
                         p("• Proprietary IP and technology assets")
                     )
              )
            )
          ),
          box(
            title = "Key Achievements", status = "primary", solidHeader = TRUE, width = 4,
            div(class = "achievement-box",
                h4("🔬 IP & Technology"),
                p("Proprietary algorithms developed with secured IP protection procedures"),
                br(),
                h4("🏆 Recognition"),
                p("3 major awards from BridgeAI and UK Government entities"),
                br(),
                h4("💰 Funding Secured"),
                p("£120K+ from reputable organizations for development and growth"),
                br(),
                h4("📊 Market Validation"),
                p("Commercial partnerships established with proven demand")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Investment Opportunity", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                fluidRow(
                  column(6,
                         h4("🎯 Support Needed"),
                         p("We are seeking support and advice for commercialization of AI solutions 
                           in Transport and Energy sectors. Our established partnerships and government 
                           backing provide a strong foundation for rapid growth."),
                         br(),
                         h4("📞 Contact Information"),
                         p("Email: joseph.zr@atera-analytics.co.uk"),
                         p("Web: www.atera-analytics.co.uk"),
                         p("Let's transform the EV and Transport Ecosystem with AI!")
                  ),
                  column(6,
                         h4("💼 Investment Focus"),
                         p("Funding required for:"),
                         tags$ul(
                           tags$li("Talent acquisition and team expansion"),
                           tags$li("Technology development and IP enhancement"),
                           tags$li("Commercialization and market penetration"),
                           tags$li("International expansion capabilities")
                         ),
                         br(),
                         h4("Return on Investment"),
                         p("Expected returns through:"),
                         tags$ul(
                           tags$li("Market leadership in growing EV sector"),
                           tags$li("Scalable SaaS revenue model"),
                           tags$li("International expansion opportunities"),
                           tags$li("Strategic acquisition potential")
                         )
                  )
                )
            )
          )
        )
      ),
      
      # Live Demo Tab
      tabItem(
        tabName = "demo",
        fluidRow(
          box(
            title = "LIVE ROUTE OPTIMIZATION DEMO", status = "primary", solidHeader = TRUE, width = 12,
            div(class = "executive-summary-box",
                h3("Interactive EV Route Planning System"),
                p("Experience our real-time route optimization system that reduces operational costs by up to 25% 
                  through intelligent charging point selection and traffic-aware routing.")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Route Configuration", status = "primary", solidHeader = TRUE, width = 4,
            selectInput("startLocation", "Start Location:", 
                        choices = c("Cambridge" = "cambridge", "London" = "london", 
                                    "Oxford" = "oxford", "Birmingham" = "birmingham")),
            selectInput("endLocation", "End Location:", 
                        choices = c("Manchester" = "manchester", "Leeds" = "leeds", 
                                    "Liverpool" = "liverpool", "Newcastle" = "newcastle")),
            sliderInput("batteryLevel", "Current Battery Level (%):", 
                        min = 10, max = 100, value = 65),
            sliderInput("vehicleRange", "Vehicle Range (miles):", 
                        min = 150, max = 400, value = 250),
            selectInput("chargingSpeed", "Preferred Charging Speed:", 
                        choices = c("Rapid (50kW+)" = "rapid", "Fast (7-22kW)" = "fast", 
                                    "Slow (3kW)" = "slow")),
            actionButton("optimizeRoute", "Optimize Route", class = "btn-primary")
          ),
          box(
            title = "Interactive Route Map", status = "primary", solidHeader = TRUE, width = 8,
            leafletOutput("routeMap", height = "500px")
          )
        ),
        
        fluidRow(
          box(
            title = "Route Analytics", status = "primary", solidHeader = TRUE, width = 6,
            div(class = "achievement-box",
                h4("Journey Summary"),
                verbatimTextOutput("routeSummary"),
                br(),
                h4("Charging Stops Recommended"),
                DT::dataTableOutput("chargingStops")
            )
          ),
          box(
            title = "Cost Analysis", status = "primary", solidHeader = TRUE, width = 6,
            plotlyOutput("costAnalysis")
          )
        )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Market Growth Chart
  output$marketGrowthChart <- renderPlotly({
    market_data <- data.frame(
      Year = c(2024, 2025, 2026, 2027, 2028, 2029, 2030),
      AI_Logistics = c(17.96, 26.35, 38.65, 56.67, 83.16, 122.02, 179.05),
      EV_Market = c(4.5, 5.53, 6.79, 8.34, 10.24, 12.58, 15.46),
      Total_Transport = c(12.91, 15.87, 19.52, 24.00, 29.52, 36.31, 44.67)
    )
    
    p <- plot_ly(market_data, x = ~Year) %>%
      add_lines(y = ~AI_Logistics, name = "AI in Logistics ($B)", 
                line = list(color = "#667eea", width = 3)) %>%
      add_lines(y = ~EV_Market, name = "AI in Transportation ($B)", 
                line = list(color = "#764ba2", width = 3)) %>%
      add_lines(y = ~Total_Transport, name = "Traffic Management ($B)", 
                line = list(color = "#f39c12", width = 3)) %>%
      layout(
        title = list(text = "Market Growth Projections", font = list(size = 16, color = "#2c3e50")),
        xaxis = list(title = "Year", titlefont = list(color = "#2c3e50")),
        yaxis = list(title = "Market Size (Billions USD)", titlefont = list(color = "#2c3e50")),
        legend = list(font = list(color = "#2c3e50")),
        plot_bgcolor = "rgba(0,0,0,0)",
        paper_bgcolor = "rgba(0,0,0,0)"
      )
    p
  })
  
  # Market Size Chart
  output$marketSizeChart <- renderPlotly({
    market_segments <- data.frame(
      Segment = c("UK SMEs", "Large Fleet Orgs", "Global AI Logistics"),
      Size = c(500, 2500, 24000),
      Category = c("SOM", "SAM", "TAM")
    )
    
    colors <- c("#667eea", "#764ba2", "#f39c12")
    
    p <- plot_ly(market_segments, x = ~Segment, y = ~Size, type = "bar",
                 marker = list(color = colors)) %>%
      layout(
        title = list(text = "Market Size Analysis", font = list(size = 16, color = "#2c3e50")),
        xaxis = list(title = "Market Segment", titlefont = list(color = "#2c3e50")),
        yaxis = list(title = "Market Size (£M)", titlefont = list(color = "#2c3e50"), type = "log"),
        plot_bgcolor = "rgba(0,0,0,0)",
        paper_bgcolor = "rgba(0,0,0,0)"
      )
    p
  })
  
  # Competitive Matrix
  output$competitiveMatrix <- DT::renderDataTable({
    competitive_data <- data.frame(
      Feature = c("Route Planning", "Interactive Visualizations", "GIS Integration", 
                  "Fleet Management Support", "Total Cost of Ownership", 
                  "Charging Network Integration", "LLM Gen AI Integration",
                  "Autonomous Vehicle Ready"),
      ZapMap = c("✓", "✓", "✗", "✓", "✗", "✓", "✗", "✗"),
      PlugShare = c("✓", "✓", "✗", "✗", "✗", "✓", "✗", "✗"),
      ChargePoint = c("✗", "✓", "✗", "✗", "✓", "✓", "✓", "✗"),
      AteraEV = c("✓", "✓", "✓", "✓", "✓", "✓", "✓", "✓")
    )
    
    DT::datatable(competitive_data, 
                  options = list(pageLength = 10, dom = 't', ordering = FALSE),
                  rownames = FALSE) %>%
      DT::formatStyle(columns = 1:5, backgroundColor = "white", color = "#2c3e50") %>%
      DT::formatStyle("AteraEV", backgroundColor = "#e8f4fd", fontWeight = "bold")
  })
  
  # Route Map
  output$routeMap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -2.5, lat = 53.5, zoom = 6) %>%
      addMarkers(lng = -0.1278, lat = 51.5074, popup = "London") %>%
      addMarkers(lng = -2.2426, lat = 53.4808, popup = "Manchester") %>%
      addMarkers(lng = -1.5491, lat = 53.8008, popup = "Leeds") %>%
      addMarkers(lng = 0.1215, lat = 52.2053, popup = "Cambridge") %>%
      addCircleMarkers(lng = c(-1.8904, -2.0781, -1.1397), 
                       lat = c(52.4862, 53.4084, 52.6309),
                       radius = 8, color = "#667eea", fillColor = "#667eea",
                       popup = c("Birmingham Charging Hub", "Liverpool Charging Station", "Milton Keynes Fast Charger"))
  })
  
  # Route Summary
  output$routeSummary <- renderText({
    if(input$optimizeRoute > 0) {
      paste("Optimized Route Analysis:\n",
            "Total Distance: 247 miles\n",
            "Estimated Journey Time: 4h 12m\n",
            "Charging Stops Required: 1\n",
            "Total Cost: £28.50\n",
            "CO2 Savings: 45.2kg vs petrol\n",
            "Efficiency Improvement: 22% vs standard route")
    } else {
      "Click 'Optimize Route' to generate analysis..."
    }
  })
  
  # Charging Stops Table
  output$chargingStops <- DT::renderDataTable({
    if(input$optimizeRoute > 0) {
      charging_stops <- data.frame(
        Location = c("Milton Keynes Services", "Birmingham North"),
        Provider = c("Ionity", "BP Pulse"),
        Power = c("350kW", "150kW"),
        Cost = c("£14.20", "£12.80"),
        Duration = c("18 min", "25 min"),
        Availability = c("4/6 Available", "2/4 Available")
      )
      
      DT::datatable(charging_stops, options = list(pageLength = 5, dom = 't'), rownames = FALSE)
    }
  })
  
  # Cost Analysis Chart
  output$costAnalysis <- renderPlotly({
    if(input$optimizeRoute > 0) {
      cost_data <- data.frame(
        Category = c("Electricity", "Charging Fees", "Route Optimization", "Time Savings"),
        Standard_Route = c(18.50, 15.20, 0, 0),
        Optimized_Route = c(16.20, 12.30, -8.50, -12.00),
        Savings = c(2.30, 2.90, 8.50, 12.00)
      )
      
      p <- plot_ly(cost_data, x = ~Category, y = ~Savings, type = "bar",
                   marker = list(color = "#667eea")) %>%
        layout(
          title = list(text = "Cost Savings Analysis", font = list(size = 14, color = "#2c3e50")),
          xaxis = list(title = "Cost Category", titlefont = list(color = "#2c3e50")),
          yaxis = list(title = "Savings (£)", titlefont = list(color = "#2c3e50")),
          plot_bgcolor = "rgba(0,0,0,0)",
          paper_bgcolor = "rgba(0,0,0,0)"
        )
      p
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)