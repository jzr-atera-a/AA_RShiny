# Atera Analytics Customer Profiling Dashboard
# Install required packages if not already installed
# install.packages(c("shiny", "shinydashboard", "DT", "plotly", "dplyr"))

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Atera Analytics - Customer Understanding Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Customer Users DMU", tabName = "customer_users", icon = icon("users")),
      menuItem("Positioning + Comms", tabName = "positioning", icon = icon("bullseye")),
      menuItem("Distribution Sales", tabName = "distribution", icon = icon("share-alt")),
      menuItem("Value Pricing", tabName = "value_pricing", icon = icon("pound-sign"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
        .box {
          border-radius: 8px;
        }
        .profile-box {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
        }
        .positioning-box {
          background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
          color: white;
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
        }
        .jtbd-tag {
          background: rgba(255,255,255,0.2);
          padding: 5px 10px;
          border-radius: 15px;
          margin: 2px;
          display: inline-block;
          font-size: 12px;
        }
      "))
    ),
    
    tabItems(
      # Tab 1: Customer Users DMU
      tabItem(tabName = "customer_users",
              fluidRow(
                box(
                  title = "EXERCISE 1", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Description of customer segment", style = "color: #666; margin-bottom: 20px;"),
                  
                  # Profile 01: Fleet Manager
                  div(class = "profile-box",
                      fluidRow(
                        column(2, h2("01", style = "font-size: 48px; margin: 0;")),
                        column(4, 
                               h4("FLEET MANAGER", style = "margin: 0; color: #FFE066;"),
                               p("Job title", style = "margin: 0; font-size: 14px; opacity: 0.8;")
                        ),
                        column(6, 
                               div(class = "jtbd-tag", "Optimize vehicle utilization"),
                               div(class = "jtbd-tag", "Reduce fuel/energy costs"),
                               div(class = "jtbd-tag", "Minimize vehicle downtime"),
                               div(class = "jtbd-tag", "Ensure regulatory compliance")
                        )
                      )
                  ),
                  
                  # Profile 02: Transport Logistics Manager
                  div(class = "profile-box",
                      fluidRow(
                        column(2, h2("02", style = "font-size: 48px; margin: 0;")),
                        column(4, 
                               h4("TRANSPORT LOGISTICS MANAGER", style = "margin: 0; color: #FFE066;"),
                               p("Job title", style = "margin: 0; font-size: 14px; opacity: 0.8;")
                        ),
                        column(6, 
                               div(class = "jtbd-tag", "Optimize delivery routes"),
                               div(class = "jtbd-tag", "Reduce operational costs"),
                               div(class = "jtbd-tag", "Improve delivery performance"),
                               div(class = "jtbd-tag", "Manage multi-modal transport")
                        )
                      )
                  ),
                  
                  # Profile 03: Chief Operations Manager
                  div(class = "profile-box",
                      fluidRow(
                        column(2, h2("03", style = "font-size: 48px; margin: 0;")),
                        column(4, 
                               h4("CHIEF OPERATIONS MANAGER", style = "margin: 0; color: #FFE066;"),
                               p("Job title", style = "margin: 0; font-size: 14px; opacity: 0.8;")
                        ),
                        column(6, 
                               div(class = "jtbd-tag", "Drive digital transformation"),
                               div(class = "jtbd-tag", "Achieve sustainability targets"),
                               div(class = "jtbd-tag", "Improve operational efficiency"),
                               div(class = "jtbd-tag", "Reduce total cost of ownership")
                        )
                      )
                  ),
                  
                  # Profile 04: Related Departments
                  div(class = "profile-box", style = "background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); color: #333;",
                      fluidRow(
                        column(2, h2("04", style = "font-size: 48px; margin: 0;")),
                        column(4, 
                               h4("RELATED DEPARTMENTS", style = "margin: 0; color: #333;"),
                               p("Departments & Dept Lead job title", style = "margin: 0; font-size: 14px; opacity: 0.7;")
                        ),
                        column(6, 
                               div(class = "jtbd-tag", style = "background: rgba(51,51,51,0.1); color: #333;", "IT/Technology Director"),
                               div(class = "jtbd-tag", style = "background: rgba(51,51,51,0.1); color: #333;", "Sustainability Manager"),
                               div(class = "jtbd-tag", style = "background: rgba(51,51,51,0.1); color: #333;", "Finance Director"),
                               div(class = "jtbd-tag", style = "background: rgba(51,51,51,0.1); color: #333;", "Customer Service Manager")
                        )
                      )
                  )
                )
              )
      ),
      
      # Tab 2: Positioning + Communications
      tabItem(tabName = "positioning",
              fluidRow(
                box(
                  title = "", status = "primary", solidHeader = FALSE, width = 12,
                  div(style = "text-align: center; margin-bottom: 20px;",
                      img(src = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==", 
                          width = "50", height = "50", style = "background: #667eea; border-radius: 50%;"),
                      h3("Offering true-to-life AI-powered route optimization for transport", style = "color: #333; margin: 10px 0;"),
                      h4("brands and fleet operators who want to transition to EV fleets and", style = "color: #666; margin: 0;"),
                      h4("reduce operational costs through intelligent logistics technology.", style = "color: #666; margin: 0;")
                  ),
                  
                  hr(),
                  
                  # Feature 01
                  div(class = "positioning-box",
                      fluidRow(
                        column(2, 
                               div(style = "background: rgba(255,255,255,0.2); padding: 15px; border-radius: 8px; text-align: center;",
                                   h3("01", style = "margin: 0; color: white;")
                               )
                        ),
                        column(10,
                               h4("Transform fleet operations into intelligent EV logistics networks in under 10 minutes", style = "margin: 0 0 10px 0;"),
                               p("All done through our AI-powered platform that integrates seamlessly with existing fleet management systems!", style = "margin: 0; opacity: 0.9;")
                        )
                      )
                  ),
                  
                  # Feature 02
                  div(class = "positioning-box",
                      fluidRow(
                        column(2, 
                               div(style = "background: rgba(255,255,255,0.2); padding: 15px; border-radius: 8px; text-align: center;",
                                   h3("02", style = "margin: 0; color: white;")
                               )
                        ),
                        column(10,
                               h4("Get comprehensive route optimization covering all major operational challenges", style = "margin: 0 0 10px 0;"),
                               p("esp. complex multi-modal transport scenarios like last-mile delivery optimization", style = "margin: 0; opacity: 0.9;")
                        )
                      )
                  ),
                  
                  # Feature 03
                  div(class = "positioning-box",
                      fluidRow(
                        column(2, 
                               div(style = "background: rgba(255,255,255,0.2); padding: 15px; border-radius: 8px; text-align: center;",
                                   h3("03", style = "margin: 0; color: white;")
                               )
                        ),
                        column(10,
                               h4("Monitor your EV fleets with real-time data and predictive analytics", style = "margin: 0 0 10px 0;"),
                               p("instead of relying on outdated manual planning and reactive maintenance schedules", style = "margin: 0; opacity: 0.9;")
                        )
                      )
                  ),
                  
                  # Feature 04
                  div(class = "positioning-box",
                      fluidRow(
                        column(2, 
                               div(style = "background: rgba(255,255,255,0.2); padding: 15px; border-radius: 8px; text-align: center;",
                                   h3("04", style = "margin: 0; color: white;")
                               )
                        ),
                        column(10,
                               h4("Deliver intelligent logistics optimization for multiple business applications", style = "margin: 0 0 10px 0;"),
                               p("Supply Chain Optimization, B2B Fleet Management, Last-Mile Delivery, Autonomous Vehicle Integration, Sustainability Reporting & ESG Compliance", style = "margin: 0; opacity: 0.9;")
                        )
                      )
                  )
                )
              ),
              
              # Additional insights section
              fluidRow(
                box(
                  title = "Key Market Insights", status = "info", solidHeader = TRUE, width = 6,
                  h5("Primary Decision Makers:"),
                  tags$ul(
                    tags$li("Fleet Managers (day-to-day operations)"),
                    tags$li("Transport Logistics Managers (strategic planning)"),
                    tags$li("Chief Operations Managers (business transformation)")
                  ),
                  h5("Key Pain Points:"),
                  tags$ul(
                    tags$li("25% operational cost losses from inefficient routing"),
                    tags$li("Range anxiety and charging infrastructure complexity"),
                    tags$li("Regulatory pressure for fleet electrification"),
                    tags$li("Need for real-time optimization capabilities")
                  )
                ),
                
                box(
                  title = "Competitive Differentiation", status = "success", solidHeader = TRUE, width = 6,
                  h5("Our Unique Value Proposition:"),
                  tags$ul(
                    tags$li("Only solution combining GIS, AI, and EV-specific optimization"),
                    tags$li("1-meter resolution mapping with 50k+ charging points"),
                    tags$li("Autonomous vehicle ready infrastructure"),
                    tags$li("Total cost of ownership calculations"),
                    tags$li("Real-time multi-modal transport integration")
                  ),
                  h5("Proven Results:"),
                  tags$ul(
                    tags$li("20-25% reduction in operational costs"),
                    tags$li("Government awards and validation"),
                    tags$li("£120k+ secured funding"),
                    tags$li("Commercial client since March 2023")
                  )
                )
              )
      ),
      
      # Tab 3: Distribution Sales
      tabItem(tabName = "distribution",
              fluidRow(
                box(
                  title = "EXERCISE 3: DISTRIBUTION AND SALES CHANNELS", status = "primary", solidHeader = TRUE, width = 12,
                  h4("How will you get your product (V1) into the users/customers hands?", style = "color: #666; margin-bottom: 30px;"),
                  
                  # Channel 01
                  fluidRow(
                    column(12,
                           div(style = "background: #f8f9fa; border-left: 4px solid #007bff; padding: 20px; margin: 15px 0; border-radius: 5px;",
                               h4("01", style = "color: #007bff; margin-bottom: 10px;"),
                               h5("Direct B2B Sales & Strategic Partnerships", style = "margin-bottom: 10px;"),
                               p("Leverage existing commercial client relationships and government connections (Innovate UK network) to establish pilot programs with fleet operators. Target logistics companies with 50+ vehicle fleets through industry events and transport associations.", style = "margin: 0;")
                           )
                    )
                  ),
                  
                  # Channel 02
                  fluidRow(
                    column(12,
                           div(style = "background: #f8f9fa; border-left: 4px solid #28a745; padding: 20px; margin: 15px 0; border-radius: 5px;",
                               h4("02", style = "color: #28a745; margin-bottom: 10px;"),
                               h5("Integration with Fleet Management Software Providers", style = "margin-bottom: 10px;"),
                               p("Partner with existing fleet management platforms (Teletrac Navman, Verizon Connect, Geotab) as a plug-in solution. This provides immediate access to established customer bases while reducing customer acquisition costs.", style = "margin: 0;")
                           )
                    )
                  ),
                  
                  # Channel 03
                  fluidRow(
                    column(12,
                           div(style = "background: #f8f9fa; border-left: 4px solid #ffc107; padding: 20px; margin: 15px 0; border-radius: 5px;",
                               h4("03", style = "color: #ffc107; margin-bottom: 10px;"),
                               h5("Government & Public Sector Procurement", style = "margin-bottom: 10px;"),
                               p("Utilize BridgeAI awards and Innovate UK recognition to access public sector fleet tenders. Local councils, NHS trusts, and government agencies transitioning to electric fleets represent a significant early adoption market.", style = "margin: 0;")
                           )
                    )
                  ),
                  
                  # Channel 04
                  fluidRow(
                    column(12,
                           div(style = "background: #f8f9fa; border-left: 4px solid #dc3545; padding: 20px; margin: 15px 0; border-radius: 5px;",
                               h4("04", style = "color: #dc3545; margin-bottom: 10px;"),
                               h5("EV Charging Network Partnerships", style = "margin-bottom: 10px;"),
                               p("Collaborate with major charging networks (BP Pulse, Shell Recharge, Pod Point) to offer route optimization as a value-added service to their commercial customers, creating a direct channel to fleet operators already investing in EV infrastructure.", style = "margin: 0;")
                           )
                    )
                  )
                )
              )
      ),
      
      # Tab 4: Value Pricing
      tabItem(tabName = "value_pricing",
              fluidRow(
                box(
                  title = "So that (JTBD) + So what? (Critical Outcomes)", status = "primary", solidHeader = TRUE, width = 12,
                  
                  # Business Owner Section
                  fluidRow(
                    column(12,
                           div(style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; padding: 20px; margin: 15px 0;",
                               fluidRow(
                                 column(2, h2("01", style = "font-size: 48px; margin: 0;")),
                                 column(4, 
                                        h4("BUSINESS OWNER", style = "margin: 0; color: #FFE066;"),
                                        p("Job title", style = "margin: 0; font-size: 14px; opacity: 0.8;")
                                 ),
                                 column(6,
                                        h5("JTBD + Critical Outcomes:", style = "margin-bottom: 10px; color: #FFE066;"),
                                        tags$ul(
                                          tags$li("Reduce fleet operational costs by 20-25%"),
                                          tags$li("Achieve net-zero transport targets and ESG compliance"),
                                          tags$li("Improve company competitiveness through operational efficiency"),
                                          tags$li("Generate ROI of £50-100k annually per 100 vehicles"),
                                          style = "margin: 0; font-size: 14px;"
                                        )
                                 )
                               )
                           )
                    )
                  ),
                  
                  # Manager/BU Leader Section
                  fluidRow(
                    column(12,
                           div(style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; padding: 20px; margin: 15px 0;",
                               fluidRow(
                                 column(2, h2("02", style = "font-size: 48px; margin: 0;")),
                                 column(4, 
                                        h4("MANAGER/BU LEADER", style = "margin: 0; color: #FFE066;"),
                                        p("Job title", style = "margin: 0; font-size: 14px; opacity: 0.8;")
                                 ),
                                 column(6,
                                        h5("JTBD + Critical Outcomes:", style = "margin-bottom: 10px; color: #FFE066;"),
                                        tags$ul(
                                          tags$li("Eliminate manual route planning inefficiencies"),
                                          tags$li("Reduce vehicle downtime and improve utilization"),
                                          tags$li("Meet departmental KPIs for cost reduction"),
                                          tags$li("Demonstrate digital transformation leadership"),
                                          style = "margin: 0; font-size: 14px;"
                                        )
                                 )
                               )
                           )
                    )
                  ),
                  
                  # User Section
                  fluidRow(
                    column(12,
                           div(style = "background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; border-radius: 8px; padding: 20px; margin: 15px 0;",
                               fluidRow(
                                 column(2, h2("03", style = "font-size: 48px; margin: 0;")),
                                 column(4, 
                                        h4("USER", style = "margin: 0; color: #FFE066;"),
                                        p("Job title", style = "margin: 0; font-size: 14px; opacity: 0.8;")
                                 ),
                                 column(6,
                                        h5("JTBD + Critical Outcomes:", style = "margin-bottom: 10px; color: #FFE066;"),
                                        tags$ul(
                                          tags$li("Simplify daily route planning and optimization tasks"),
                                          tags$li("Access real-time charging station availability"),
                                          tags$li("Reduce stress from range anxiety and charging uncertainty"),
                                          tags$li("Improve driver satisfaction and productivity"),
                                          style = "margin: 0; font-size: 14px;"
                                        )
                                 )
                               )
                           )
                    )
                  ),
                  
                  # Related Departments Section
                  fluidRow(
                    column(12,
                           div(style = "background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); color: #333; border-radius: 8px; padding: 20px; margin: 15px 0;",
                               fluidRow(
                                 column(2, h2("04", style = "font-size: 48px; margin: 0;")),
                                 column(4, 
                                        h4("RELATED DEPARTMENTS", style = "margin: 0;"),
                                        p("Departments & Dept Lead job title", style = "margin: 0; font-size: 14px; opacity: 0.7;")
                                 ),
                                 column(6,
                                        h5("JTBD + Critical Outcomes:", style = "margin-bottom: 10px;"),
                                        tags$ul(
                                          tags$li("IT: Seamless system integration without disruption"),
                                          tags$li("Finance: Clear ROI tracking and cost attribution"),
                                          tags$li("Sustainability: Measurable carbon footprint reduction"),
                                          tags$li("Customer Service: Improved delivery reliability"),
                                          style = "margin: 0; font-size: 14px;"
                                        )
                                 )
                               )
                           )
                    )
                  )
                )
              ),
              
              # Pricing Strategy Section
              fluidRow(
                box(
                  title = "Value-Based Pricing Strategy", status = "success", solidHeader = TRUE, width = 12,
                  fluidRow(
                    column(6,
                           h4("Pricing Tiers:"),
                           div(style = "background: #e7f3ff; padding: 15px; border-radius: 5px; margin: 10px 0;",
                               h5("Starter: £25/vehicle/month"),
                               p("Basic route optimization for fleets of 10-50 vehicles", style = "margin: 5px 0;"),
                               tags$ul(
                                 tags$li("Route planning & charging optimization"),
                                 tags$li("Basic analytics dashboard"),
                                 tags$li("Email support")
                               )
                           ),
                           div(style = "background: #e8f5e8; padding: 15px; border-radius: 5px; margin: 10px 0;",
                               h5("Professional: £45/vehicle/month"),
                               p("Advanced optimization for fleets of 50-200 vehicles", style = "margin: 5px 0;"),
                               tags$ul(
                                 tags$li("All Starter features"),
                                 tags$li("Multi-modal transport integration"),
                                 tags$li("Real-time optimization"),
                                 tags$li("API access & integrations")
                               )
                           ),
                           div(style = "background: #fff2e8; padding: 15px; border-radius: 5px; margin: 10px 0;",
                               h5("Enterprise: Custom Pricing"),
                               p("Full platform for fleets of 200+ vehicles", style = "margin: 5px 0;"),
                               tags$ul(
                                 tags$li("All Professional features"),
                                 tags$li("Custom AI model training"),
                                 tags$li("Dedicated account management"),
                                 tags$li("White-label options")
                               )
                           )
                    ),
                    column(6,
                           h4("ROI Justification:"),
                           div(style = "background: #f0f8ff; padding: 15px; border-radius: 5px;",
                               tags$ul(
                                 tags$li(strong("20-25% operational cost reduction"), " (proven with existing client)"),
                                 tags$li(strong("£500-1,000 savings per vehicle annually"), " through route optimization"),
                                 tags$li(strong("Break-even in 3-6 months"), " for most fleet sizes"),
                                 tags$li(strong("Regulatory compliance value"), " for net-zero mandates"),
                                 tags$li(strong("Competitive advantage"), " through operational efficiency")
                               )
                           ),
                           h5("Payment Model:", style = "margin-top: 20px;"),
                           p("Monthly SaaS subscription with annual discounts. Implementation fee waived for 12-month commitments.")
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
  # Server logic can be expanded here for interactive features
  # For now, the dashboard is primarily static content
  
  # You could add reactive elements like:
  # - Customer segment filtering
  # - Interactive charts showing market data
  # - Dynamic JTBD updates based on user input
}

# Run the application
shinyApp(ui = ui, server = server)