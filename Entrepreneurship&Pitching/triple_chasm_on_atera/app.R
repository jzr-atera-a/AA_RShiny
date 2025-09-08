# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Triple Chasm Model: Atera Analytics"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Crossing the Chasm", tabName = "chasm", icon = icon("chart-line")),
      menuItem("Triple Chasm Overview", tabName = "overview", icon = icon("industry")),
      menuItem("Market Assessment", tabName = "market", icon = icon("map")),
      menuItem("Technology Readiness", tabName = "technology", icon = icon("microchip")),
      menuItem("Business Model", tabName = "business", icon = icon("business-time")),
      menuItem("Commercial Strategy", tabName = "commercial", icon = icon("rocket")),
      menuItem("Investment & Growth", tabName = "investment", icon = icon("pound-sign")),
      menuItem("Risk Assessment", tabName = "risk", icon = icon("exclamation-triangle"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          min-height: 100vh;
        }
        .main-sidebar {
          background: linear-gradient(180deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
        }
        .box {
          background: rgba(255, 255, 255, 0.98) !important;
          border: none !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2) !important;
        }
        .box-header {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
          border-radius: 12px 12px 0 0 !important;
        }
        .small-box {
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15) !important;
        }
        .small-box.bg-blue { 
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important; 
        }
        .small-box.bg-green { 
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important; 
        }
        .small-box.bg-yellow { 
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; 
        }
        .small-box.bg-red { 
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; 
        }
      "))
    ),
    
    tabItems(
      # Tab 1: Crossing the Chasm
      tabItem(tabName = "chasm",
              fluidRow(
                box(
                  title = "Crossing the Chasm: Strategic Framework", status = "primary", solidHeader = TRUE, width = 12,
                  h3("Geoffrey Moore's Technology Adoption Lifecycle"),
                  p("The Crossing the Chasm model identifies critical barriers technology companies face when transitioning from early adopters to mainstream markets. This framework is particularly relevant for Atera Analytics as we navigate the autonomous vehicle infrastructure assessment market."),
                  
                  h4("The Five Customer Segments:"),
                  tags$ul(
                    tags$li(strong("Innovators (2.5%):"), "Technology enthusiasts who adopt new solutions first"),
                    tags$li(strong("Early Adopters (13.5%):"), "Visionaries seeking competitive advantage"),
                    tags$li(strong("Early Majority (34%):"), "Pragmatists requiring proven solutions"),
                    tags$li(strong("Late Majority (34%):"), "Conservatives adopting established technologies"),
                    tags$li(strong("Laggards (16%):"), "Skeptics resistant to change")
                  ),
                  
                  h4("The Chasm Challenge:"),
                  p("The critical gap exists between Early Adopters and Early Majority. Early adopters are visionary risk-takers, while the early majority are pragmatic and require:"),
                  tags$ul(
                    tags$li("Proven track record and references"),
                    tags$li("Complete solution ecosystem"),
                    tags$li("Reliable support infrastructure"),
                    tags$li("Industry standards compliance"),
                    tags$li("Risk mitigation strategies")
                  ),
                  
                  h4("Crossing Strategy - The Bowling Pin Approach:"),
                  p("Success requires focusing on one specific market segment, creating a complete solution, and using that success as a reference for adjacent markets.")
                )
              ),
              
              fluidRow(
                valueBoxOutput("chasmSuccess"),
                valueBoxOutput("marketTiming"),
                valueBoxOutput("wholeProduct")
              ),
              
              fluidRow(
                box(
                  title = "Moore's Whole Product Concept", status = "success", solidHeader = TRUE, width = 6,
                  p("The Whole Product includes:"),
                  tags$ul(
                    tags$li(strong("Core Product:"), "Basic functionality"),
                    tags$li(strong("Expected Product:"), "Minimum market expectations"),
                    tags$li(strong("Augmented Product:"), "Additional services and support"),
                    tags$li(strong("Potential Product:"), "Future enhancement possibilities")
                  )
                ),
                
                box(
                  title = "Technology Adoption Challenges", status = "warning", solidHeader = TRUE, width = 6,
                  p("Common failure patterns:"),
                  tags$ul(
                    tags$li("Targeting too broad a market initially"),
                    tags$li("Insufficient focus on complete solutions"),
                    tags$li("Lack of compelling use cases"),
                    tags$li("Inadequate reference customer development"),
                    tags$li("Premature scaling before product-market fit")
                  )
                )
              )
      ),
      
      # Tab 2: Triple Chasm Overview
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Triple Chasm Model Overview", status = "primary", solidHeader = TRUE, width = 12,
                  h3("Evidence-Based Commercialisation Framework"),
                  p("The Triple Chasm Model, developed by Dr. Uday Phadke and team, provides a data-driven approach to understanding commercialisation challenges. Based on analysis of over 3,000 global companies, it identifies three critical transition points where startups commonly fail."),
                  
                  h4("The Three Chasms:"),
                  tags$ol(
                    tags$li(strong("Concept to Demonstrator:"), "Proving technical feasibility"),
                    tags$li(strong("Demonstrator to Early Product:"), "Achieving market validation"),
                    tags$li(strong("Early Product to Volume Products:"), "Scaling for mass market")
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("chasmOne"),
                valueBoxOutput("chasmTwo"),
                valueBoxOutput("chasmThree")
              ),
              
              fluidRow(
                box(
                  title = "12 Meso-Economic Vectors", status = "info", solidHeader = TRUE, width = 6,
                  h4("External Vectors:"),
                  tags$ul(
                    tags$li("E1: Market Spaces"),
                    tags$li("E2: Proposition Framing & Competition"),
                    tags$li("E3: Customer Definition"),
                    tags$li("E4: Distribution, Marketing & Sales")
                  ),
                  h4("Composite Vectors:"),
                  tags$ul(
                    tags$li("C1: Strategic Positioning"),
                    tags$li("C2: Business Model")
                  )
                ),
                
                box(
                  title = "Internal Vectors", status = "success", solidHeader = TRUE, width = 6,
                  h4("Internal Capabilities:"),
                  tags$ul(
                    tags$li("I1: Technology Development"),
                    tags$li("I2: IP Management"),
                    tags$li("I3: Product & Service Synthesis"),
                    tags$li("I4: Manufacturing & Deployment"),
                    tags$li("I5: Human Capital"),
                    tags$li("I6: Financial Capital")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Commercialisation Readiness Level (CRL)", status = "primary", solidHeader = TRUE, width = 12,
                  p("The CRL framework provides quantitative assessment of commercialisation maturity, moving beyond traditional Technology Readiness Levels (TRL) to encompass market readiness factors."),
                  div(style = "text-align: center; margin-top: 20px;",
                      tags$p(style = "font-size: 12px; color: #666;",
                             "Source: Phadke, U. (2019). The Triple Chasm Approach to Commercialising Innovation. Available at: ",
                             tags$a(href = "https://www.triplechasm.com/how-we-help/triple-chasm-model", 
                                    "https://www.triplechasm.com/how-we-help/triple-chasm-model", 
                                    target = "_blank"),
                             br(),
                             "Main Author: ",
                             tags$a(href = "https://www.linkedin.com/in/uday-phadke-194392/", 
                                    "Dr. Uday Phadke", 
                                    target = "_blank")
                      )
                  )
                )
              )
      ),
      
      # Tab 3: Market Assessment
      tabItem(tabName = "market",
              fluidRow(
                box(
                  title = "E1: Market Spaces Analysis - Autonomous Vehicle Infrastructure", status = "primary", solidHeader = TRUE, width = 12,
                  h3("UK Smart Mobility Market Assessment"),
                  p("Atera Analytics operates in the £2B UK smart mobility market, focusing on infrastructure readiness assessment for Connected and Autonomous Vehicles (CAV).")
                )
              ),
              
              fluidRow(
                valueBoxOutput("marketSize"),
                valueBoxOutput("camMarket"),
                valueBoxOutput("readinessScore")
              ),
              
              fluidRow(
                box(
                  title = "Market Space Positioning", status = "info", solidHeader = TRUE, width = 6,
                  h4("Primary Market Space:"),
                  tags$ul(
                    tags$li("CAV Infrastructure Assessment"),
                    tags$li("Route Optimisation Analytics"),
                    tags$li("Safety & Compliance Monitoring"),
                    tags$li("Fleet Management Solutions")
                  ),
                  h4("Adjacent Markets:"),
                  tags$ul(
                    tags$li("Smart Cities Infrastructure"),
                    tags$li("Transport Planning"),
                    tags$li("Environmental Impact Assessment"),
                    tags$li("Insurance Risk Analytics")
                  )
                ),
                
                box(
                  title = "Competitive Landscape", status = "warning", solidHeader = TRUE, width = 6,
                  h4("Market Gaps Identified:"),
                  tags$ul(
                    tags$li("Lack of standardised AV readiness metrics"),
                    tags$li("Limited real-time infrastructure assessment"),
                    tags$li("Fragmented data sources"),
                    tags$li("Insufficient route-specific analysis")
                  ),
                  h4("Our Differentiation:"),
                  tags$ul(
                    tags$li("AI-driven assessment algorithms"),
                    tags$li("Real-time data integration"),
                    tags$li("Comprehensive safety scoring"),
                    tags$li("Government partnership validation")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "E3: Customer Definition", status = "success", solidHeader = TRUE, width = 12,
                  h4("Primary Customer Segments:"),
                  div(style = "display: flex; justify-content: space-between;",
                      div(style = "width: 22%;",
                          h5("Logistics Providers"),
                          tags$ul(style = "font-size: 12px;",
                                  tags$li("Fleet operators"),
                                  tags$li("Delivery companies"),
                                  tags$li("Transport consortiums")
                          )
                      ),
                      div(style = "width: 22%;",
                          h5("Government Bodies"),
                          tags$ul(style = "font-size: 12px;",
                                  tags$li("CCAV"),
                                  tags$li("Local councils"),
                                  tags$li("Transport authorities")
                          )
                      ),
                      div(style = "width: 22%;",
                          h5("Technology Partners"),
                          tags$ul(style = "font-size: 12px;",
                                  tags$li("AV manufacturers"),
                                  tags$li("Tech integrators"),
                                  tags$li("Infrastructure providers")
                          )
                      ),
                      div(style = "width: 22%;",
                          h5("Insurance & Finance"),
                          tags$ul(style = "font-size: 12px;",
                                  tags$li("Risk assessors"),
                                  tags$li("Investment funds"),
                                  tags$li("Insurance companies")
                          )
                      )
                  )
                )
              )
      ),
      
      # Tab 4: Technology Readiness
      tabItem(tabName = "technology",
              fluidRow(
                box(
                  title = "I1: Technology Development & Deployment", status = "primary", solidHeader = TRUE, width = 12,
                  h3("CAV Infrastructure Assessment Platform"),
                  p("Atera Analytics has developed a comprehensive AI-driven platform for assessing UK road infrastructure readiness for autonomous vehicles, integrating multiple data sources and advanced analytics.")
                )
              ),
              
              fluidRow(
                valueBoxOutput("techReadiness"),
                valueBoxOutput("dataIntegration"),
                valueBoxOutput("aiCapability")
              ),
              
              fluidRow(
                box(
                  title = "Core Technology Stack", status = "info", solidHeader = TRUE, width = 6,
                  h4("Platform Components:"),
                  tags$ul(
                    tags$li(strong("Cloud Infrastructure:"), "Google Cloud Platform"),
                    tags$li(strong("Data Sources:"), "DAFNI, ArcGIS, Real-time APIs"),
                    tags$li(strong("AI/ML Engine:"), "Route 10 AI algorithms"),
                    tags$li(strong("Visualization:"), "Interactive dashboards"),
                    tags$li(strong("APIs:"), "RESTful service architecture")
                  ),
                  h4("Key Capabilities:"),
                  tags$ul(
                    tags$li("Real-time infrastructure analysis"),
                    tags$li("Predictive safety scoring"),
                    tags$li("Route optimization algorithms"),
                    tags$li("Multi-modal data fusion")
                  )
                ),
                
                box(
                  title = "Technical Achievements", status = "success", solidHeader = TRUE, width = 6,
                  h4("Q1 2025 Deliverables:"),
                  tags$ul(
                    tags$li("✓ Foundation infrastructure completed"),
                    tags$li("✓ Route 10 AI integration delivered"),
                    tags$li("🔄 Front-end dashboard (in progress)"),
                    tags$li("🔄 Data architecture implementation")
                  ),
                  h4("Validation Results:"),
                  tags$ul(
                    tags$li("50 route segments analyzed"),
                    tags$li("68% average compatibility score"),
                    tags$li("54% deployment readiness"),
                    tags$li("9 critical risk segments identified")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "I2: IP Management Strategy", status = "warning", solidHeader = TRUE, width = 6,
                  p("Our intellectual property strategy focuses on protecting core algorithmic innovations while maintaining collaborative partnerships."),
                  h4("IP Portfolio:"),
                  tags$ul(
                    tags$li("Route assessment algorithms"),
                    tags$li("Safety scoring methodologies"),
                    tags$li("Data fusion techniques"),
                    tags$li("Dashboard visualization innovations")
                  )
                ),
                
                box(
                  title = "I3: Product & Service Synthesis", status = "info", solidHeader = TRUE, width = 6,
                  p("Integration of technology components into market-ready solutions."),
                  h4("Product Integration:"),
                  tags$ul(
                    tags$li("Unified assessment platform"),
                    tags$li("SaaS delivery model"),
                    tags$li("Custom reporting services"),
                    tags$li("Training and support programs")
                  )
                )
              )
      ),
      
      # Tab 5: Business Model
      tabItem(tabName = "business",
              fluidRow(
                box(
                  title = "C2: Business Model Architecture", status = "primary", solidHeader = TRUE, width = 12,
                  h3("SaaS-Based Revenue Model"),
                  p("Atera Analytics operates a Software-as-a-Service model targeting the £2B UK smart mobility market through scalable cloud-based infrastructure assessment solutions.")
                )
              ),
              
              fluidRow(
                valueBoxOutput("revenueModel"),
                valueBoxOutput("customerBase"),
                valueBoxOutput("scalability")
              ),
              
              fluidRow(
                box(
                  title = "Revenue Streams", status = "success", solidHeader = TRUE, width = 6,
                  h4("Primary Revenue Sources:"),
                  tags$ul(
                    tags$li(strong("Platform Licensing:"), "Monthly/annual SaaS subscriptions"),
                    tags$li(strong("Assessment Services:"), "Custom infrastructure evaluations"),
                    tags$li(strong("Data Analytics:"), "Advanced reporting and insights"),
                    tags$li(strong("Consulting:"), "Implementation and training services")
                  ),
                  h4("Pricing Strategy:"),
                  tags$ul(
                    tags$li("Tiered subscription models"),
                    tags$li("Usage-based analytics"),
                    tags$li("Enterprise custom pricing"),
                    tags$li("Government partnership rates")
                  )
                ),
                
                box(
                  title = "Value Proposition", status = "info", solidHeader = TRUE, width = 6,
                  h4("Customer Value Drivers:"),
                  tags$ul(
                    tags$li("Reduced deployment risk"),
                    tags$li("Faster route validation"),
                    tags$li("Compliance assurance"),
                    tags$li("Cost optimization insights")
                  ),
                  h4("Competitive Advantages:"),
                  tags$ul(
                    tags$li("Government validation partnership"),
                    tags$li("Real-time data integration"),
                    tags$li("AI-driven predictive analytics"),
                    tags$li("Comprehensive UK coverage")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "E4: Distribution, Marketing & Sales Strategy", status = "warning", solidHeader = TRUE, width = 12,
                  h4("Go-to-Market Approach:"),
                  div(style = "display: flex; justify-content: space-between;",
                      div(style = "width: 30%;",
                          h5("Direct Sales"),
                          tags$ul(style = "font-size: 12px;",
                                  tags$li("Government partnerships"),
                                  tags$li("Enterprise accounts"),
                                  tags$li("Strategic partnerships")
                          )
                      ),
                      div(style = "width: 30%;",
                          h5("Channel Partners"),
                          tags$ul(style = "font-size: 12px;",
                                  tags$li("Systems integrators"),
                                  tags$li("Consulting firms"),
                                  tags$li("Technology resellers")
                          )
                      ),
                      div(style = "width: 30%;",
                          h5("Digital Channels"),
                          tags$ul(style = "font-size: 12px;",
                                  tags$li("Online platform access"),
                                  tags$li("API marketplace"),
                                  tags$li("Developer ecosystem")
                          )
                      )
                  ),
                  h4("Market Entry Strategy:"),
                  p("Following the bowling pin approach, we're targeting logistics providers first, using government validation as proof of concept, then expanding to adjacent markets including insurance, urban planning, and international markets.")
                )
              )
      ),
      
      # Tab 6: Commercial Strategy
      tabItem(tabName = "commercial",
              fluidRow(
                box(
                  title = "C1: Strategic Positioning & Commercial Deployment", status = "primary", solidHeader = TRUE, width = 12,
                  h3("Market Leadership in CAV Infrastructure Assessment"),
                  p("Atera Analytics is positioned as the leading provider of AI-driven infrastructure readiness assessment for autonomous vehicles in the UK, with expansion plans across Europe.")
                )
              ),
              
              fluidRow(
                valueBoxOutput("marketPosition"),
                valueBoxOutput("partnerships"),
                valueBoxOutput("expansion")
              ),
              
              fluidRow(
                box(
                  title = "Atera Analytics: Triple Chasm Assessment", status = "info", solidHeader = TRUE, width = 6,
                  plotlyOutput("ateraRadarChart", height = "400px")
                ),
                
                box(
                  title = "Commercialisation Intensity Analysis", status = "success", solidHeader = TRUE, width = 6,
                  DT::dataTableOutput("intensityTable")
                )
              ),
              
              fluidRow(
                box(
                  title = "Customer Growth Trajectory", status = "warning", solidHeader = TRUE, width = 12,
                  plotlyOutput("customerGrowthChart", height = "400px"),
                  p("Atera Analytics is currently navigating Chasm II (Demonstrator to Early Product), having successfully completed government validation and moving toward commercial deployment.")
                )
              ),
              
              fluidRow(
                box(
                  title = "E2: Proposition Framing & Competition", status = "info", solidHeader = TRUE, width = 6,
                  h4("Market Positioning:"),
                  tags$ul(
                    tags$li(strong("Category Creation:"), "Defining AV infrastructure readiness standards"),
                    tags$li(strong("Thought Leadership:"), "Research partnerships with academia"),
                    tags$li(strong("Government Validation:"), "CCAV and Zenzic partnerships"),
                    tags$li(strong("Industry Standards:"), "Contributing to regulatory frameworks")
                  ),
                  h4("Competitive Differentiation:"),
                  tags$ul(
                    tags$li("First-mover advantage in AV readiness"),
                    tags$li("Comprehensive UK infrastructure coverage"),
                    tags$li("Real-time assessment capabilities"),
                    tags$li("Government-validated methodologies")
                  )
                ),
                
                box(
                  title = "Commercial Milestones", status = "success", solidHeader = TRUE, width = 6,
                  h4("2025 Achievements:"),
                  tags$ul(
                    tags$li("✓ Secured Innovate UK funding"),
                    tags$li("✓ Established CCAV partnership"),
                    tags$li("✓ Completed technical proof-of-concept"),
                    tags$li("🔄 Platform beta deployment")
                  ),
                  h4("2026 Targets:"),
                  tags$ul(
                    tags$li("Commercial platform launch"),
                    tags$li("10+ enterprise customers"),
                    tags$li("£500K ARR milestone"),
                    tags$li("European market entry")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Route to Market Strategy", status = "warning", solidHeader = TRUE, width = 12,
                  h4("Phase 1: Proof of Concept (Complete)"),
                  p("Government partnership validation, technical feasibility demonstration, initial customer feedback collection."),
                  
                  h4("Phase 2: Market Entry (Current)"),
                  p("Platform commercialization, initial customer acquisition, partnership development, revenue generation."),
                  
                  h4("Phase 3: Scale & Expansion (2026+)"),
                  p("Market leadership establishment, international expansion, adjacent market penetration, strategic acquisitions."),
                  
                  h4("Key Success Metrics:"),
                  tags$ul(
                    tags$li("Customer acquisition cost < £10K"),
                    tags$li("Customer lifetime value > £100K"),
                    tags$li("Platform utilization > 75%"),
                    tags$li("Net promoter score > 50")
                  )
                )
              )
      ),
      
      # Tab 7: Investment & Growth
      tabItem(tabName = "investment",
              fluidRow(
                box(
                  title = "I6: Financial Capital & Investment Strategy", status = "primary", solidHeader = TRUE, width = 12,
                  h3("Government-Backed Growth Strategy"),
                  p("Atera Analytics has secured initial funding through UK government innovation programs and is positioned for private investment to scale operations and expand market reach.")
                )
              ),
              
              fluidRow(
                valueBoxOutput("currentFunding"),
                valueBoxOutput("projectedRevenue"),
                valueBoxOutput("growthRate")
              ),
              
              fluidRow(
                box(
                  title = "Current Investment Position", status = "success", solidHeader = TRUE, width = 6,
                  h4("Secured Funding:"),
                  tags$ul(
                    tags$li(strong("Innovate UK:"), "Project 10153306 funding"),
                    tags$li(strong("Zenzic Partnership:"), "CAM testbed access"),
                    tags$li(strong("CCAV Collaboration:"), "Regulatory framework support"),
                    tags$li(strong("Google Cloud Credits:"), "Infrastructure cost reduction")
                  ),
                  h4("Investment Utilization:"),
                  tags$ul(
                    tags$li("Platform development: 60%"),
                    tags$li("Team expansion: 25%"),
                    tags$li("Market development: 10%"),
                    tags$li("IP protection: 5%")
                  )
                ),
                
                box(
                  title = "Growth Projections", status = "info", solidHeader = TRUE, width = 6,
                  h4("Revenue Forecast:"),
                  tags$ul(
                    tags$li("2025: £150K (pilot customers)"),
                    tags$li("2026: £500K (commercial launch)"),
                    tags$li("2027: £1.5M (market expansion)"),
                    tags$li("2028: £4M (European markets)")
                  ),
                  h4("Team Growth:"),
                  tags$ul(
                    tags$li("Current: 6 team members"),
                    tags$li("2025 end: 10 members"),
                    tags$li("2026 end: 18 members"),
                    tags$li("2027 end: 30 members")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "I5: Human Capital Development", status = "warning", solidHeader = TRUE, width = 6,
                  h4("Core Team Expertise:"),
                  tags$ul(
                    tags$li("Transport data modelling"),
                    tags$li("AI/ML algorithm development"),
                    tags$li("Government partnership management"),
                    tags$li("Cloud infrastructure deployment")
                  ),
                  h4("Planned Recruitment:"),
                  tags$ul(
                    tags$li("Senior data scientists"),
                    tags$li("Business development managers"),
                    tags$li("Customer success specialists"),
                    tags$li("International expansion leads")
                  )
                ),
                
                box(
                  title = "Investment Requirements", status = "primary", solidHeader = TRUE, width = 6,
                  h4("Next Funding Round (2026):"),
                  tags$ul(
                    tags$li(strong("Target:"), "£2M Series A"),
                    tags$li(strong("Use Cases:"), "Platform scaling, team expansion"),
                    tags$li(strong("Timeline:"), "Q2 2026"),
                    tags$li(strong("Investors:"), "VC funds, strategic partners")
                  ),
                  h4("Long-term Capital Strategy:"),
                  tags$ul(
                    tags$li("Series B: £5M (2027)"),
                    tags$li("International expansion funding"),
                    tags$li("Strategic acquisition opportunities"),
                    tags$li("Potential IPO pathway (2030+)")
                  )
                )
              )
      ),
      
      # Tab 8: Risk Assessment
      tabItem(tabName = "risk",
              fluidRow(
                box(
                  title = "Risk Assessment & Mitigation Strategy", status = "primary", solidHeader = TRUE, width = 12,
                  h3("Comprehensive Risk Management Framework"),
                  p("Atera Analytics faces typical technology commercialization risks alongside sector-specific challenges related to autonomous vehicle adoption and regulatory changes.")
                )
              ),
              
              fluidRow(
                valueBoxOutput("riskLevel"),
                valueBoxOutput("mitigationScore"),
                valueBoxOutput("regulatory")
              ),
              
              fluidRow(
                box(
                  title = "Technology Risks", status = "warning", solidHeader = TRUE, width = 6,
                  h4("Key Technology Risks:"),
                  tags$ul(
                    tags$li(strong("Platform Scalability:"), "System performance under load"),
                    tags$li(strong("Data Quality:"), "Inconsistent infrastructure data"),
                    tags$li(strong("AI Accuracy:"), "Model performance degradation"),
                    tags$li(strong("Integration Complexity:"), "Third-party system dependencies")
                  ),
                  h4("Mitigation Strategies:"),
                  tags$ul(
                    tags$li("Cloud-native architecture design"),
                    tags$li("Multiple data source validation"),
                    tags$li("Continuous model retraining"),
                    tags$li("API-first integration approach")
                  )
                ),
                
                box(
                  title = "Market Risks", status = "danger", solidHeader = TRUE, width = 6,
                  h4("Market & Commercial Risks:"),
                  tags$ul(
                    tags$li(strong("AV Adoption Delays:"), "Slower than expected market growth"),
                    tags$li(strong("Regulatory Changes:"), "Shifting compliance requirements"),
                    tags$li(strong("Competition:"), "Large tech companies entering market"),
                    tags$li(strong("Customer Concentration:"), "Over-reliance on key accounts")
                  ),
                  h4("Risk Mitigation:"),
                  tags$ul(
                    tags$li("Diversified customer portfolio"),
                    tags$li("Regulatory relationship building"),
                    tags$li("Continuous competitive monitoring"),
                    tags$li("Adjacent market development")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Financial & Operational Risks", status = "info", solidHeader = TRUE, width = 6,
                  h4("Financial Risks:"),
                  tags$ul(
                    tags$li("Funding gap between rounds"),
                    tags$li("Longer sales cycles than projected"),
                    tags$li("Currency exposure (international)"),
                    tags$li("Cash flow management")
                  ),
                  h4("Operational Risks:"),
                  tags$ul(
                    tags$li("Key person dependency"),
                    tags$li("Talent acquisition challenges"),
                    tags$li("Intellectual property protection"),
                    tags$li("Partnership dependencies")
                  )
                ),
                
                box(
                  title = "Strategic Risk Management", status = "success", solidHeader = TRUE, width = 6,
                  h4("Risk Monitoring Framework:"),
                  tags$ul(
                    tags$li("Monthly risk register reviews"),
                    tags$li("Quarterly scenario planning"),
                    tags$li("Customer feedback loops"),
                    tags$li("Market intelligence tracking")
                  ),
                  h4("Contingency Planning:"),
                  tags$ul(
                    tags$li("Alternative revenue streams"),
                    tags$li("Partnership diversification"),
                    tags$li("Technology pivot capabilities"),
                    tags$li("Emergency funding strategies")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Triple Chasm Risk Assessment", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Chasm-Specific Risk Analysis:"),
                  p(strong("Chasm 1 (Concept to Demonstrator): "), "LOW RISK - Successfully completed with government validation and technical proof-of-concept."),
                  p(strong("Chasm 2 (Demonstrator to Early Product): "), "MEDIUM RISK - Currently navigating with beta customers and platform refinement."),
                  p(strong("Chasm 3 (Early Product to Volume): "), "HIGH RISK - Future challenge requiring scale, standardization, and market education."),
                  
                  h4("Success Probability Assessment:"),
                  p("Based on Triple Chasm research showing 8% overall success rate for startups, Atera Analytics demonstrates above-average success indicators through government backing, technical validation, and clear market need. Current estimated success probability: 35-45%.")
                )
              )
      )
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Tab 1: Crossing the Chasm value boxes
  output$chasmSuccess <- renderValueBox({
    valueBox(
      value = "8%",
      subtitle = "Overall Startup Success Rate",
      icon = icon("chart-line"),
      color = "red"
    )
  })
  
  output$marketTiming <- renderValueBox({
    valueBox(
      value = "16%",
      subtitle = "Technology Market Failure Rate",
      icon = icon("clock"),
      color = "yellow"
    )
  })
  
  output$wholeProduct <- renderValueBox({
    valueBox(
      value = "4 Layers",
      subtitle = "Whole Product Components",
      icon = icon("layer-group"),
      color = "blue"
    )
  })
  
  #
  # Tab 2: Triple Chasm Overview value boxes
  output$chasmOne <- renderValueBox({
    valueBox(
      value = "Concept→Demo",
      subtitle = "First Critical Transition",
      icon = icon("lightbulb"),
      color = "blue"
    )
  })
  
  output$chasmTwo <- renderValueBox({
    valueBox(
      value = "Demo→Product",
      subtitle = "Market Validation Phase",
      icon = icon("cogs"),
      color = "yellow"
    )
  })
  
  output$chasmThree <- renderValueBox({
    valueBox(
      value = "Product→Scale",
      subtitle = "Mass Market Transition",
      icon = icon("rocket"),
      color = "green"
    )
  })
  
  # Tab 3: Market Assessment value boxes
  output$marketSize <- renderValueBox({
    valueBox(
      value = "£2B",
      subtitle = "UK Smart Mobility Market",
      icon = icon("map"),
      color = "blue"
    )
  })
  
  output$camMarket <- renderValueBox({
    valueBox(
      value = "2027",
      subtitle = "Commercial AV Deployment",
      icon = icon("car"),
      color = "green"
    )
  })
  
  output$readinessScore <- renderValueBox({
    valueBox(
      value = "54%",
      subtitle = "Current UK AV Readiness",
      icon = icon("road"),
      color = "yellow"
    )
  })
  
  # Tab 4: Technology Readiness value boxes
  output$techReadiness <- renderValueBox({
    valueBox(
      value = "TRL 7",
      subtitle = "Technology Readiness Level",
      icon = icon("microchip"),
      color = "green"
    )
  })
  
  output$dataIntegration <- renderValueBox({
    valueBox(
      value = "5+",
      subtitle = "Integrated Data Sources",
      icon = icon("database"),
      color = "blue"
    )
  })
  
  output$aiCapability <- renderValueBox({
    valueBox(
      value = "68%",
      subtitle = "Average Route Compatibility",
      icon = icon("brain"),
      color = "yellow"
    )
  })
  
  # Tab 5: Business Model value boxes
  output$revenueModel <- renderValueBox({
    valueBox(
      value = "SaaS",
      subtitle = "Primary Revenue Model",
      icon = icon("cloud"),
      color = "blue"
    )
  })
  
  output$customerBase <- renderValueBox({
    valueBox(
      value = "4",
      subtitle = "Target Customer Segments",
      icon = icon("users"),
      color = "green"
    )
  })
  
  output$scalability <- renderValueBox({
    valueBox(
      value = "Cloud-Native",
      subtitle = "Scalability Architecture",
      icon = icon("expand-arrows-alt"),
      color = "purple"
    )
  })
  
  # Tab 6: Commercial Strategy value boxes (CORRECTED)
  output$marketPosition <- renderValueBox({
    valueBox(
      value = "First-Mover",
      subtitle = "UK AV Assessment Market",
      icon = icon("trophy"),
      color = "yellow"  # Changed from "gold" to "yellow"
    )
  })
  
  output$partnerships <- renderValueBox({
    valueBox(
      value = "CCAV",
      subtitle = "Government Partnership",
      icon = icon("handshake"),
      color = "blue"
    )
  })
  
  output$expansion <- renderValueBox({
    valueBox(
      value = "2026",
      subtitle = "European Market Entry",
      icon = icon("globe-europe"),
      color = "green"
    )
  })
  
  # Atera Analytics Radar Chart
  output$ateraRadarChart <- renderPlotly({
    # Data based on Atera Analytics assessment
    vectors <- c("E1. Market Spaces", "E2. Proposition Framing", "E3. Customer Definition",
                 "E4. Distribution, Marketing & Sales", "I1. Tech. Development", "I2. IP Management",
                 "I3. Product & Service Synthesis", "I4. Manufacturing & Deployment", 
                 "I5. Talent, Leadership & Culture", "I6. Funding & Investment",
                 "C1. Strategic Positioning", "C2. Business Models")
    
    # Atera Analytics scores (estimated based on current position)
    atera_scores <- c(70, 85, 60, 45, 90, 35, 65, 25, 75, 40, 45, 55)
    
    # Create radar chart
    fig <- plot_ly(
      type = 'scatterpolar',
      r = atera_scores,
      theta = vectors,
      fill = 'toself',
      name = 'Atera Analytics',
      line = list(color = '#008A82', width = 3),
      fillcolor = 'rgba(0, 138, 130, 0.3)'
    ) %>%
      layout(
        polar = list(
          radialaxis = list(
            visible = TRUE,
            range = c(0, 100),
            tickfont = list(size = 10)
          ),
          angularaxis = list(
            tickfont = list(size = 11)
          )
        ),
        title = list(text = "Atera Analytics: 12 Meso-Economic Vectors", font = list(size = 14)),
        showlegend = FALSE
      )
    
    fig
  })
  
  # Commercialisation Intensity Table
  output$intensityTable <- DT::renderDataTable({
    intensity_data <- data.frame(
      Vector = c("E1. Market Spaces", "E2. Proposition Framing", "E3. Customer Definition",
                 "E4. Distribution, Marketing & Sales", "I1. Tech. Development", "I2. IP Management",
                 "I3. Product & Service Synthesis", "I4. Manufacturing & Deployment", 
                 "I5. Talent, Leadership & Culture", "I6. Funding & Investment",
                 "C1. Strategic Positioning", "C2. Business Models"),
      Relevance = c(7, 9, 4, 1, 10, 4, 6, 1, 5, 1, 1, 2),
      Execution = c(5, 7, 4, 2, 9, 1, 5, 1, 5, 1, 1, 1),
      Intensity = c(35, 63, 16, 2, 90, 4, 30, 1, 25, 1, 1, 2)
    )
    
    DT::datatable(intensity_data, 
                  options = list(pageLength = 12, dom = 't', scrollY = "350px"),
                  rownames = FALSE
    ) %>%
      DT::formatStyle('Intensity',
                      backgroundColor = DT::styleInterval(c(20, 50), c('#ffcccc', '#ffffcc', '#ccffcc'))
      )
  })
  
  # Customer Growth Chart
  output$customerGrowthChart <- renderPlotly({
    # Create time series for three chasms
    time_points <- seq(0, 1, length.out = 100)
    
    # Sigmoid function for customer growth
    customer_growth <- 1 / (1 + exp(-10 * (time_points - 0.5)))
    
    # Mark the three chasms
    chasm_points <- data.frame(
      x = c(0.12, 0.33, 0.75),
      y = c(0.01, 0.15, 0.85),
      labels = c("Chasm I", "Chasm II", "Chasm III")
    )
    
    fig <- plot_ly() %>%
      add_trace(
        x = time_points, 
        y = customer_growth,
        type = 'scatter',
        mode = 'lines',
        line = list(color = '#c0392b', width = 3),
        name = 'Customer Growth'
      ) %>%
      add_markers(
        x = chasm_points$x,
        y = chasm_points$y,
        marker = list(size = 15, color = '#008A82'),
        text = chasm_points$labels,
        textposition = "top center",
        name = 'Chasms'
      ) %>%
      add_annotations(
        x = 0.25, y = 0.5,
        text = "Atera Analytics<br>Current Position",
        showarrow = TRUE,
        arrowhead = 2,
        arrowsize = 1,
        arrowcolor = "#008A82",
        font = list(color = "#008A82", size = 12)
      ) %>%
      layout(
        title = "Triple Chasm Customer Growth Model",
        xaxis = list(title = "Time / Time to Max Customers", range = c(0, 1)),
        yaxis = list(title = "Cumulative Customer Growth", range = c(0, 1)),
        showlegend = FALSE
      )
    
    fig
  })
  
  # Tab 7: Investment & Growth value boxes
  output$currentFunding <- renderValueBox({
    valueBox(
      value = "IUK",
      subtitle = "Current Funding Source",
      icon = icon("pound-sign"),
      color = "green"
    )
  })
  
  output$projectedRevenue <- renderValueBox({
    valueBox(
      value = "£4M",
      subtitle = "2028 Revenue Target",
      icon = icon("chart-line"),
      color = "blue"
    )
  })
  
  output$growthRate <- renderValueBox({
    valueBox(
      value = "300%",
      subtitle = "Projected Annual Growth",
      icon = icon("trending-up"),
      color = "purple"
    )
  })
  
  # Tab 8: Risk Assessment value boxes
  output$riskLevel <- renderValueBox({
    valueBox(
      value = "Medium",
      subtitle = "Overall Risk Assessment",
      icon = icon("shield-alt"),
      color = "yellow"
    )
  })
  
  output$mitigationScore <- renderValueBox({
    valueBox(
      value = "75%",
      subtitle = "Risk Mitigation Coverage",
      icon = icon("check-shield"),
      color = "green"
    )
  })
  
  output$regulatory <- renderValueBox({
    valueBox(
      value = "Active",
      subtitle = "Regulatory Engagement",
      icon = icon("balance-scale"),
      color = "blue"
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)