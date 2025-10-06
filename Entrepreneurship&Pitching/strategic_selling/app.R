# AI Fleet Optimization Platform - Sales Journey App
# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(shinyWidgets)
library(shinycssloaders)
library(htmltools)

# Define UI
ui <- dashboardPage(
  dashboardHeader(
    title = "AI Fleet Optimization - Sales Journey",
    titleWidth = 350
  ),
  
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      menuItem("Customer Discovery", tabName = "discovery", icon = icon("search")),
      menuItem("Product Validation", tabName = "validation", icon = icon("thumbs-up")),
      menuItem("Client Commitment", tabName = "commitment", icon = icon("handshake")),
      menuItem("Letters of Intent", tabName = "intent", icon = icon("file-contract")),
      menuItem("Product Testing", tabName = "testing", icon = icon("cogs")),
      menuItem("Customer Conversion", tabName = "conversion", icon = icon("dollar-sign")),
      menuItem("Network Growth", tabName = "network", icon = icon("share-alt")),
      menuItem("Investor Evidence", tabName = "investor", icon = icon("chart-line"))
    )
  ),
  
  dashboardBody(
    # Custom CSS
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f8f9fa;
        }
        
        .main-header .navbar {
          background-color: #1f2937 !important;
        }
        
        .main-header .logo {
          background-color: #374151 !important;
          border-bottom: 0;
        }
        
        .main-sidebar {
          background-color: #374151 !important;
        }
        
        .sidebar-menu > li > a {
          color: #d1d5db !important;
          border-left: 3px solid transparent;
        }
        
        .sidebar-menu > li:hover > a,
        .sidebar-menu > li.active > a {
          background-color: #4b5563 !important;
          border-left-color: #3b82f6 !important;
          color: #ffffff !important;
        }
        
        .box {
          border-top: 3px solid #3b82f6;
          box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
        }
        
        .box-header {
          background-color: #ffffff;
          color: #1f2937;
        }
        
        .btn-primary {
          background-color: #3b82f6;
          border-color: #3b82f6;
        }
        
        .btn-success {
          background-color: #10b981;
          border-color: #10b981;
        }
        
        .progress-bar {
          background-color: #3b82f6;
        }
        
        .info-box {
          background: #ffffff;
          box-shadow: 0 1px 3px rgba(0,0,0,0.12);
        }
        
        .references-box {
          background-color: #f3f4f6;
          border: 1px solid #d1d5db;
          border-radius: 8px;
          padding: 15px;
          margin-top: 20px;
          font-size: 12px;
          color: #374151;
        }
        
        .metric-card {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 20px;
          border-radius: 10px;
          margin: 10px 0;
        }
      "))
    ),
    
    tabItems(
      # Tab 1: Customer Discovery
      tabItem(tabName = "discovery",
              fluidRow(
                box(
                  title = "Customer Discovery & Needs Assessment", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  h3("AI-Powered Customer Understanding"),
                  p("Leverage technology to understand customer transport needs efficiently and systematically."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Survey System",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             p("Automated intelligent surveys that adapt based on responses:"),
                             tags$ul(
                               tags$li("Fleet size and composition analysis"),
                               tags$li("Route optimization challenges"),
                               tags$li("Fuel/energy consumption patterns"),
                               tags$li("Maintenance scheduling issues"),
                               tags$li("Regulatory compliance requirements")
                             ),
                             actionButton("launch_survey", "Launch Smart Survey", class = "btn-primary")
                           )
                    ),
                    column(4,
                           box(
                             title = "Interactive Polls",
                             status = "info", 
                             solidHeader = TRUE,
                             width = 12,
                             p("Real-time polling for quick insights:"),
                             sliderInput("fleet_size", "Current Fleet Size:", 
                                         min = 1, max = 1000, value = 50),
                             selectInput("transport_type", "Primary Transport Type:",
                                         choices = list("Delivery Vans" = "vans",
                                                        "Heavy Trucks" = "trucks", 
                                                        "Passenger Vehicles" = "cars",
                                                        "Mixed Fleet" = "mixed")),
                             checkboxGroupInput("pain_points", "Main Challenges:",
                                                choices = list("High Fuel Costs" = "fuel",
                                                               "Inefficient Routes" = "routes",
                                                               "Maintenance Issues" = "maintenance",
                                                               "Regulatory Compliance" = "compliance"))
                           )
                    ),
                    column(4,
                           box(
                             title = "Video Consultation",
                             status = "info",
                             solidHeader = TRUE, 
                             width = 12,
                             p("Scheduled video calls for deep-dive analysis:"),
                             tags$ul(
                               tags$li("Technical requirements assessment"),
                               tags$li("Integration capability review"),
                               tags$li("ROI projection discussions"),
                               tags$li("Timeline and implementation planning")
                             ),
                             dateInput("consult_date", "Schedule Consultation:"),
                             actionButton("schedule_call", "Book Video Call", class = "btn-success")
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Eisenhardt, K. M. (1989). Building theories from case study research. Academy of Management Review, 14(4), 532-550."),
                      p("Osterwalder, A., & Pigneur, Y. (2010). Business model generation: a handbook for visionaries, game changers, and challengers. John Wiley & Sons."),
                      p("Ries, E. (2011). The lean startup: How today's entrepreneurs use continuous innovation to create radically successful businesses. Crown Business.")
                  )
                )
              )
      ),
      
      # Tab 2: Product Validation
      tabItem(tabName = "validation",
              fluidRow(
                box(
                  title = "AI Product Portfolio Validation",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Product-Market Fit Assessment"),
                  p("Validate specific AI solutions against customer requirements using structured feedback mechanisms."),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Core AI Products",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Route Optimization Engine"),
                             p("Real-time AI-driven route planning considering traffic, weather, and delivery windows."),
                             radioButtons("route_interest", "Interest Level:",
                                          choices = list("High Priority" = "high",
                                                         "Medium Priority" = "medium", 
                                                         "Low Priority" = "low")),
                             
                             h4("Predictive Maintenance AI"),
                             p("Machine learning models for vehicle maintenance scheduling and failure prediction."),
                             radioButtons("maintenance_interest", "Interest Level:",
                                          choices = list("High Priority" = "high",
                                                         "Medium Priority" = "medium",
                                                         "Low Priority" = "low")),
                             
                             h4("EV Charging Optimization"),
                             p("Smart charging network management and battery optimization algorithms."),
                             radioButtons("ev_interest", "Interest Level:",
                                          choices = list("High Priority" = "high",
                                                         "Medium Priority" = "medium",
                                                         "Low Priority" = "low"))
                           )
                    ),
                    column(6,
                           box(
                             title = "Validation Metrics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("validation_chart")),
                             hr(),
                             h4("Expected Benefits Assessment"),
                             numericInput("cost_savings", "Expected Cost Savings (%):", 
                                          value = 15, min = 0, max = 50),
                             numericInput("efficiency_gain", "Expected Efficiency Gain (%):",
                                          value = 20, min = 0, max = 100),
                             sliderInput("implementation_timeline", "Acceptable Implementation Timeline (months):",
                                         min = 1, max = 24, value = 6)
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Cooper, R. G. (2017). Winning at new products: Creating value through innovation. Basic Books."),
                      p("Blank, S. (2013). The four steps to the epiphany: successful strategies for products that win. K&S Ranch."),
                      p("Christensen, C. M. (1997). The innovator's dilemma: when new technologies cause great firms to fail. Harvard Business Review Press.")
                  )
                )
              )
      ),
      
      # Tab 3: Client Commitment
      tabItem(tabName = "commitment",
              fluidRow(
                box(
                  title = "Securing Client Testing Commitment",
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  h3("Pilot Program Engagement Strategy"),
                  p("Convert interest into concrete commitments for product testing and validation."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Commitment Framework",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Phase 1: Proof of Concept (30 days)"),
                             tags$ul(
                               tags$li("Limited fleet subset (5-10 vehicles)"),
                               tags$li("Single use case focus"),
                               tags$li("Basic performance metrics"),
                               tags$li("Weekly progress reviews")
                             ),
                             
                             h4("Phase 2: Extended Pilot (90 days)"),
                             tags$ul(
                               tags$li("Expanded fleet coverage"),
                               tags$li("Multiple AI modules"),
                               tags$li("Integration with existing systems"),
                               tags$li("ROI measurement and validation")
                             ),
                             checkboxInput("poc_commit", "Phase 1 Commitment", FALSE),
                             checkboxInput("pilot_commit", "Phase 2 Commitment", FALSE)
                           )
                    ),
                    column(4,
                           box(
                             title = "Resource Allocation",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Client Requirements:"),
                             numericInput("dedicated_vehicles", "Vehicles for Testing:", 
                                          value = 10, min = 1, max = 100),
                             numericInput("data_access_level", "Data Access Level (1-5):",
                                          value = 3, min = 1, max = 5),
                             selectInput("integration_level", "System Integration:",
                                         choices = list("API Only" = "api",
                                                        "Dashboard Integration" = "dashboard",
                                                        "Full ERP Integration" = "erp")),
                             textAreaInput("success_criteria", "Success Criteria:",
                                           placeholder = "Define measurable outcomes..."),
                             actionButton("finalize_commitment", "Finalize Testing Agreement", class = "btn-success")
                           )
                    ),
                    column(4,
                           box(
                             title = "Risk Mitigation",
                             status = "danger",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Addressing Concerns:"),
                             tags$ul(
                               tags$li("Data security and privacy protocols"),
                               tags$li("Minimal disruption guarantees"),
                               tags$li("Exit strategy if results unsatisfactory"),
                               tags$li("IP protection agreements"),
                               tags$li("Performance benchmarking standards")
                             ),
                             h4("Success Incentives:"),
                             tags$ul(
                               tags$li("Early adopter pricing discounts"),
                               tags$li("Priority feature development"),
                               tags$li("Co-marketing opportunities"),
                               tags$li("Reference customer benefits")
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Moore, G. A. (2014). Crossing the chasm: Marketing and selling disruptive products to mainstream customers. HarperBusiness."),
                      p("Ulwick, A. W. (2005). What customers want: Using outcome-driven innovation to create breakthrough products and services. McGraw-Hill."),
                      p("Anthony, S. D., Johnson, M. W., Sinfield, J. V., & Altman, E. J. (2008). The innovator's guide to growth: Putting disruptive innovation to work. Harvard Business Review Press.")
                  )
                )
              )
      ),
      
      # Tab 4: Letters of Intent
      tabItem(tabName = "intent",
              fluidRow(
                box(
                  title = "Letters of Intent Generation",
                  status = "primary",
                  solidHeader = TRUE, 
                  width = 12,
                  h3("Formal Commitment Documentation"),
                  p("Secure written commitments that demonstrate market validation and future revenue potential."),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "LOI Template Generator", 
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Client Information:"),
                             textInput("company_name", "Company Name:"),
                             textInput("contact_person", "Primary Contact:"),
                             textInput("contact_title", "Title:"),
                             numericInput("annual_volume", "Annual Transport Volume:", value = 1000000),
                             
                             h4("Commitment Details:"),
                             numericInput("pilot_duration", "Pilot Duration (months):", value = 6, min = 1, max = 24),
                             numericInput("pilot_budget", "Pilot Budget ($):", value = 50000, min = 5000, max = 500000),
                             numericInput("full_contract_value", "Full Contract Value ($):", value = 250000, min = 25000),
                             
                             selectInput("deployment_timeline", "Expected Deployment:",
                                         choices = list("Q1 2024" = "q1_24", "Q2 2024" = "q2_24", 
                                                        "Q3 2024" = "q3_24", "Q4 2024" = "q4_24")),
                             
                             actionButton("generate_loi", "Generate LOI", class = "btn-primary")
                           )
                    ),
                    column(6,
                           box(
                             title = "LOI Tracking Dashboard",
                             status = "info", 
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(DT::dataTableOutput("loi_table")),
                             hr(),
                             h4("Pipeline Summary:"),
                             div(class = "metric-card",
                                 h3(textOutput("total_loi_value")),
                                 p("Total Pipeline Value")
                             ),
                             div(class = "metric-card", 
                                 h3(textOutput("loi_count")),
                                 p("Active LOIs")
                             )
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(12,
                           box(
                             title = "Sample LOI Content",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             verbatimTextOutput("loi_preview"),
                             downloadButton("download_loi", "Download LOI Template", class = "btn-success")
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Gans, J., Scott, E. L., & Stern, S. (2018). Strategy for start-ups. Harvard Business Review, 96(3), 44-52."),
                      p("Maurya, A. (2012). Running lean: Iterate from plan A to a plan that works. O'Reilly Media."),
                      p("Feld, B., & Mendelson, J. (2019). Venture deals: Be smarter than your lawyer and venture capitalist. John Wiley & Sons.")
                  )
                )
              )
      ),
      
      # Tab 5: Product Testing
      tabItem(tabName = "testing",
              fluidRow(
                box(
                  title = "Advanced Product Testing Phase",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Comprehensive Validation & Refinement"),
                  p("Execute sophisticated testing protocols to validate product performance and gather enhancement feedback."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Testing Modules",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             h4("AI Route Optimization"),
                             progressBar("route_progress", value = 75, status = "info", display_pct = TRUE),
                             p("Status: Advanced testing phase"),
                             
                             h4("Fleet Analytics Dashboard"),
                             progressBar("analytics_progress", value = 60, status = "warning", display_pct = TRUE),
                             p("Status: User feedback integration"),
                             
                             h4("Predictive Maintenance"),
                             progressBar("maintenance_progress", value = 45, status = "danger", display_pct = TRUE),
                             p("Status: Algorithm refinement"),
                             
                             h4("EV Charging Optimization"), 
                             progressBar("ev_progress", value = 30, status = "primary", display_pct = TRUE),
                             p("Status: Initial deployment")
                           )
                    ),
                    column(4,
                           box(
                             title = "Performance Metrics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("performance_metrics")),
                             hr(),
                             h4("Key Performance Indicators:"),
                             tags$ul(
                               tags$li("Route efficiency improvement: 18%"),
                               tags$li("Fuel cost reduction: 22%"),
                               tags$li("Delivery time optimization: 15%"),
                               tags$li("Maintenance cost savings: 12%"),
                               tags$li("Customer satisfaction: 4.6/5.0")
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Feedback Integration",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Client Feedback Processing:"),
                             textAreaInput("client_feedback", "Latest Client Feedback:",
                                           placeholder = "Enter client observations and suggestions..."),
                             
                             h4("Feature Requests:"),
                             checkboxGroupInput("feature_requests", "Priority Enhancements:",
                                                choices = list("Real-time tracking" = "tracking",
                                                               "Mobile app integration" = "mobile", 
                                                               "Advanced reporting" = "reporting",
                                                               "API extensions" = "api",
                                                               "Custom dashboards" = "dashboards")),
                             
                             actionButton("submit_feedback", "Process Feedback", class = "btn-primary"),
                             hr(),
                             h4("Testing Completion:"),
                             actionButton("complete_testing", "Mark Phase Complete", class = "btn-success")
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Koen, P. A., Ajamian, G. M., Boyce, S., Clamen, A., Fisher, E., Fountoulakis, S., ... & Seibert, R. (2002). Fuzzy front end: effective methods, tools, and techniques. The PDMA toolbook, 1, 5-35."),
                      p("Brown, T. (2008). Design thinking. Harvard Business Review, 86(6), 84-92."),
                      p("Thomke, S. H. (2003). Experimentation matters: unlocking the potential of new technologies for innovation. Harvard Business Review Press.")
                  )
                )
              )
      ),
      
      # Tab 6: Customer Conversion
      tabItem(tabName = "conversion",
              fluidRow(
                box(
                  title = "Customer Conversion Strategy",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("From Pilot to Paying Customer"),
                  p("Execute proven conversion strategies to transform successful pilots into long-term revenue relationships."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Conversion Pipeline",
                             status = "success", 
                             solidHeader = TRUE,
                             width = 12,
                             h4("Current Status:"),
                             div(style = "margin: 15px 0;",
                                 tags$strong("Active Pilots: "), span("12", style = "color: #3b82f6; font-size: 18px;")
                             ),
                             div(style = "margin: 15px 0;",
                                 tags$strong("Ready for Conversion: "), span("7", style = "color: #10b981; font-size: 18px;")
                             ),
                             div(style = "margin: 15px 0;",
                                 tags$strong("In Negotiation: "), span("4", style = "color: #f59e0b; font-size: 18px;")
                             ),
                             div(style = "margin: 15px 0;",
                                 tags$strong("Converted: "), span("3", style = "color: #059669; font-size: 18px;")
                             ),
                             
                             h4("Conversion Rate:"),
                             progressBar("conversion_rate", value = 65, status = "success", display_pct = TRUE)
                           )
                    ),
                    column(4,
                           box(
                             title = "Pricing Strategy",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Subscription Tiers:"),
                             
                             div(style = "border: 2px solid #e5e7eb; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Basic Plan - $2,500/month", style = "color: #6b7280;"),
                                 tags$ul(
                                   tags$li("Up to 50 vehicles"),
                                   tags$li("Route optimization"),
                                   tags$li("Basic reporting"),
                                   tags$li("Email support")
                                 )
                             ),
                             
                             div(style = "border: 2px solid #3b82f6; border-radius: 8px; padding: 15px; margin: 10px 0; background-color: #eff6ff;",
                                 h5("Professional Plan - $5,000/month", style = "color: #1e40af;"),
                                 tags$ul(
                                   tags$li("Up to 200 vehicles"),
                                   tags$li("All AI modules included"),
                                   tags$li("Advanced analytics"),
                                   tags$li("Priority support"),
                                   tags$li("API access")
                                 )
                             ),
                             
                             div(style = "border: 2px solid #10b981; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Enterprise Plan - Custom", style = "color: #047857;"),
                                 tags$ul(
                                   tags$li("Unlimited vehicles"),
                                   tags$li("Custom integrations"),
                                   tags$li("Dedicated support"),
                                   tags$li("On-premise deployment options")
                                 )
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Conversion Tactics",
                             status = "info",
                             solidHeader = TRUE, 
                             width = 12,
                             h4("Proven Strategies:"),
                             tags$ol(
                               tags$li(tags$strong("Results Presentation:"), " Quantified ROI from pilot"),
                               tags$li(tags$strong("Limited-Time Incentives:"), " Early adopter discounts"),
                               tags$li(tags$strong("Risk Mitigation:"), " Money-back guarantees"),
                               tags$li(tags$strong("Social Proof:"), " Reference customers and case studies"),
                               tags$li(tags$strong("Urgency Creation:"), " Competitive advantage timing"),
                               tags$li(tags$strong("Executive Buy-in:"), " C-level presentations"),
                               tags$li(tags$strong("Implementation Support:"), " Dedicated onboarding")
                             ),
                             
                             h4("Current Negotiations:"),
                             selectInput("negotiation_client", "Select Client:",
                                         choices = list("LogiTech Corp" = "logitech",
                                                        "FastFleet Solutions" = "fastfleet", 
                                                        "GreenTransport Inc" = "greentransport")),
                             numericInput("proposed_contract", "Contract Value ($):", value = 150000),
                             actionButton("update_negotiation", "Update Status", class = "btn-primary")
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Miller, R. B., Heiman, S. E., Tuleja, T., & Heiman, D. (2005). The new strategic selling: The unique sales system proven successful by the world's best companies. Grand Central Publishing."),
                      p("Rackham, N. (2017). SPIN selling. Routledge."),
                      p("Richardson, L. (2014). Selling to the C-suite: What every executive wants you to know about successfully selling to the top. McGraw-Hill Education.")
                  )
                )
              )
      ),
      
      # Tab 7: Network Growth
      tabItem(tabName = "network",
              fluidRow(
                box(
                  title = "Network Growth Through Word of Mouth",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Leveraging Customer Success for Organic Growth"),
                  p("Transform satisfied customers into active advocates and referral sources for sustainable business growth."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Referral Program",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Incentive Structure:"),
                             tags$ul(
                               tags$li(tags$strong("Tier 1 Referral:"), " 15% commission on first year contract"),
                               tags$li(tags$strong("Tier 2 Referral:"), " 10% ongoing annual commission"),
                               tags$li(tags$strong("Volume Bonuses:"), " Additional rewards for multiple referrals"),
                               tags$li(tags$strong("Mutual Benefits:"), " Service credits for referring clients")
                             ),
                             
                             h4("Referral Tracking:"),
                             numericInput("referrals_this_month", "This Month's Referrals:", value = 8),
                             numericInput("referrals_converted", "Converted Referrals:", value = 3),
                             
                             div(style = "background-color: #dcfce7; padding: 10px; border-radius: 5px; margin: 10px 0;",
                                 h5("Referral Success Rate:", style = "color: #166534; margin: 0;"),
                                 h3("37.5%", style = "color: #166534; margin: 5px 0;")
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Customer Advocacy",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Advocacy Programs:"),
                             
                             div(style = "background-color: #f0f9ff; border: 1px solid #0ea5e9; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Case Study Development", style = "color: #0c4a6e;"),
                                 p("Collaborative success stories highlighting measurable results", style = "margin: 5px 0; color: #075985;")
                             ),
                             
                             div(style = "background-color: #fefce8; border: 1px solid #eab308; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Speaking Opportunities", style = "color: #a16207;"),
                                 p("Industry conference presentations and panel discussions", style = "margin: 5px 0; color: #ca8a04;")
                             ),
                             
                             div(style = "background-color: #f3e8ff; border: 1px solid #a855f7; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Co-Marketing Initiatives", style = "color: #7c2d12;"),
                                 p("Joint marketing campaigns and thought leadership content", style = "margin: 5px 0; color: #92400e;")
                             ),
                             
                             checkboxGroupInput("advocacy_activities", "Active Programs:",
                                                choices = list("Case Studies" = "case_studies",
                                                               "Speaking Events" = "speaking",
                                                               "Co-Marketing" = "co_marketing",
                                                               "Reference Calls" = "references"))
                           )
                    ),
                    column(4,
                           box(
                             title = "Network Metrics",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("network_growth_chart")),
                             
                             h4("Growth Indicators:"),
                             div(style = "display: flex; justify-content: space-between; margin: 10px 0;",
                                 div(style = "text-align: center;",
                                     h4("24", style = "color: #3b82f6; margin: 0;"),
                                     p("Active Advocates", style = "margin: 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center;",
                                     h4("156%", style = "color: #10b981; margin: 0;"),
                                     p("Growth Rate", style = "margin: 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center;",
                                     h4("4.8", style = "color: #f59e0b; margin: 0;"),
                                     p("NPS Score", style = "margin: 0; font-size: 12px;")
                                 )
                             ),
                             actionButton("update_network", "Update Network Data", class = "btn-primary")
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(12,
                           box(
                             title = "Word-of-Mouth Strategy Implementation",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Systematic Approach to Network Growth:"),
                             
                             fluidRow(
                               column(3,
                                      div(style = "background: linear-gradient(135deg, #3b82f6, #1e40af); color: white; padding: 20px; border-radius: 10px; text-align: center; margin: 10px;",
                                          h5("Customer Success", style = "margin: 0;"),
                                          p("Ensure exceptional results and satisfaction", style = "margin: 5px 0; font-size: 14px;")
                                      )
                               ),
                               column(3,
                                      div(style = "background: linear-gradient(135deg, #10b981, #059669); color: white; padding: 20px; border-radius: 10px; text-align: center; margin: 10px;",
                                          h5("Story Development", style = "margin: 0;"),
                                          p("Document and quantify success stories", style = "margin: 5px 0; font-size: 14px;")
                                      )
                               ),
                               column(3,
                                      div(style = "background: linear-gradient(135deg, #f59e0b, #d97706); color: white; padding: 20px; border-radius: 10px; text-align: center; margin: 10px;",
                                          h5("Amplification", style = "margin: 0;"),
                                          p("Leverage multiple channels for visibility", style = "margin: 5px 0; font-size: 14px;")
                                      )
                               ),
                               column(3,
                                      div(style = "background: linear-gradient(135deg, #8b5cf6, #7c3aed); color: white; padding: 20px; border-radius: 10px; text-align: center; margin: 10px;",
                                          h5("Incentivization", style = "margin: 0;"),
                                          p("Reward advocates and referral sources", style = "margin: 5px 0; font-size: 14px;")
                                      )
                               )
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Reichheld, F. F. (2003). The one number you need to grow. Harvard Business Review, 81(12), 46-54."),
                      p("Silverman, G. (2001). The secrets of word-of-mouth marketing: How to trigger exponential sales through runaway word of mouth. AMACOM."),
                      p("Kumar, V., Aksoy, L., Donkers, B., Venkatesan, R., Wiesel, T., & Tillmanns, S. (2010). Undervalued or overvalued customers: capturing total customer engagement value. Journal of Service Research, 13(3), 297-310.")
                  )
                )
              )
      ),
      
      # Tab 8: Investor Evidence
      tabItem(tabName = "investor",
              fluidRow(
                box(
                  title = "Investor Evidence & Funding Preparation",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Market Validation Documentation for Investment"),
                  p("Compile comprehensive evidence of market traction, product-market fit, and growth potential for investor presentations."),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Traction Metrics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Key Performance Indicators:"),
                             
                             fluidRow(
                               column(6,
                                      div(class = "metric-card",
                                          h3("$2.4M"),
                                          p("Annual Recurring Revenue (ARR)")
                                      ),
                                      div(class = "metric-card",
                                          h3("24"),
                                          p("Paying Customers")
                                      ),
                                      div(class = "metric-card",
                                          h3("156%"),
                                          p("Net Revenue Retention")
                                      )
                               ),
                               column(6,
                                      div(class = "metric-card",
                                          h3("$100K"),
                                          p("Average Contract Value")
                                      ),
                                      div(class = "metric-card",
                                          h3("18 months"),
                                          p("Average Customer Lifetime")
                                      ),
                                      div(class = "metric-card",
                                          h3("4.8/5.0"),
                                          p("Customer Satisfaction Score")
                                      )
                               )
                             ),
                             
                             h4("Growth Trajectory:"),
                             withSpinner(plotlyOutput("investor_growth_chart"))
                           )
                    ),
                    column(6,
                           box(
                             title = "Market Validation Evidence",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Letters of Intent Summary:"),
                             tags$ul(
                               tags$li(tags$strong("Total Pipeline Value:"), " $8.7M over 24 months"),
                               tags$li(tags$strong("Number of LOIs:"), " 17 signed commitments"),
                               tags$li(tags$strong("Average Deal Size:"), " $512K per customer"),
                               tags$li(tags$strong("Conversion Timeline:"), " 6-12 months average")
                             ),
                             
                             h4("Customer Success Metrics:"),
                             tags$ul(
                               tags$li("Average cost savings achieved: 22%"),
                               tags$li("Route efficiency improvements: 18%"),
                               tags$li("Customer retention rate: 94%"),
                               tags$li("Referral rate: 38% of new customers"),
                               tags$li("Implementation success rate: 96%")
                             ),
                             
                             h4("Competitive Advantages:"),
                             tags$ul(
                               tags$li("Proprietary AI algorithms with 18-month development lead"),
                               tags$li("Industry-specific domain expertise and partnerships"),
                               tags$li("Proven ROI with measurable customer outcomes"),
                               tags$li("Scalable SaaS architecture with API-first design"),
                               tags$li("Strong customer advocacy and word-of-mouth growth")
                             )
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Financial Projections",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("3-Year Revenue Forecast:"),
                             div(style = "background-color: #f0fdf4; border: 1px solid #22c55e; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Year 1: $3.2M ARR", style = "color: #166534; margin: 0;"),
                                 p("32% growth from current base", style = "margin: 5px 0; color: #16a34a;")
                             ),
                             div(style = "background-color: #f0fdf4; border: 1px solid #22c55e; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Year 2: $8.1M ARR", style = "color: #166534; margin: 0;"),
                                 p("153% growth with market expansion", style = "margin: 5px 0; color: #16a34a;")
                             ),
                             div(style = "background-color: #f0fdf4; border: 1px solid #22c55e; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Year 3: $18.7M ARR", style = "color: #166534; margin: 0;"),
                                 p("131% growth with product expansion", style = "margin: 5px 0; color: #16a34a;")
                             ),
                             
                             h4("Funding Requirements:"),
                             numericInput("funding_amount", "Funding Round ($M):", value = 5.0, min = 1.0, max = 50.0, step = 0.5),
                             selectInput("funding_stage", "Funding Stage:",
                                         choices = list("Seed Round" = "seed",
                                                        "Series A" = "series_a",
                                                        "Series B" = "series_b"))
                           )
                    ),
                    column(4,
                           box(
                             title = "Use of Funds",
                             status = "danger",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Capital Allocation Strategy:"),
                             
                             div(style = "margin: 10px 0; padding: 10px; background-color: #fef3c7; border-radius: 5px;",
                                 h5("Product Development (40%)", style = "color: #92400e; margin: 0;"),
                                 p("AI algorithm enhancement, new feature development", style = "margin: 5px 0; font-size: 14px;")
                             ),
                             
                             div(style = "margin: 10px 0; padding: 10px; background-color: #ddd6fe; border-radius: 5px;",
                                 h5("Sales & Marketing (35%)", style = "color: #5b21b6; margin: 0;"),
                                 p("Team expansion, market penetration, customer acquisition", style = "margin: 5px 0; font-size: 14px;")
                             ),
                             
                             div(style = "margin: 10px 0; padding: 10px; background-color: #d1fae5; border-radius: 5px;",
                                 h5("Operations & Infrastructure (15%)", style = "color: #065f46; margin: 0;"),
                                 p("Cloud infrastructure, security, compliance", style = "margin: 5px 0; font-size: 14px;")
                             ),
                             
                             div(style = "margin: 10px 0; padding: 10px; background-color: #fecaca; border-radius: 5px;",
                                 h5("Working Capital (10%)", style = "color: #991b1b; margin: 0;"),
                                 p("General operations, legal, administrative", style = "margin: 5px 0; font-size: 14px;")
                             ),
                             
                             actionButton("generate_pitch_deck", "Generate Pitch Deck", class = "btn-success")
                           )
                    ),
                    column(4,
                           box(
                             title = "Investment Readiness",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Due Diligence Preparation:"),
                             checkboxGroupInput("dd_documents", "Ready Documents:",
                                                choices = list("Financial Statements" = "financials",
                                                               "Customer Contracts" = "contracts",
                                                               "IP Documentation" = "ip",
                                                               "Technical Architecture" = "tech",
                                                               "Market Analysis" = "market",
                                                               "Team Resumes" = "team",
                                                               "Legal Structure" = "legal",
                                                               "Customer References" = "references"),
                                                selected = c("financials", "contracts", "ip", "tech")),
                             
                             h4("Investor Targeting:"),
                             selectInput("investor_type", "Primary Focus:",
                                         choices = list("VC Firms (B2B SaaS)" = "vc_b2b",
                                                        "Strategic Investors (Logistics)" = "strategic",
                                                        "Growth Equity" = "growth",
                                                        "Corporate VC" = "corporate")),
                             
                             numericInput("target_investors", "Target Investors to Contact:", value = 25, min = 5, max = 100),
                             
                             actionButton("prepare_outreach", "Prepare Investor Outreach", class = "btn-primary")
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(12,
                           box(
                             title = "Investment Case Summary",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Executive Summary for Investors:"),
                             div(style = "background-color: #f8fafc; border: 2px solid #3b82f6; border-radius: 10px; padding: 20px;",
                                 h5("Market Opportunity:", style = "color: #1e40af;"),
                                 p("The global fleet management market is valued at $34.9B and growing at 15.2% CAGR. Our AI-powered optimization platform addresses critical inefficiencies in transportation, targeting the $8.7B software segment with superior technology and proven ROI."),
                                 
                                 h5("Competitive Advantage:", style = "color: #1e40af;"),
                                 p("Proprietary AI algorithms delivering 22% average cost savings, 94% customer retention, and 156% net revenue retention. Strong word-of-mouth growth with 38% referral rate demonstrates product-market fit."),
                                 
                                 h5("Traction & Validation:", style = "color: #1e40af;"),
                                 p("$2.4M ARR with 24 paying customers, $8.7M pipeline with 17 signed LOIs, and clear path to $18.7M ARR within 3 years. Proven conversion from pilot to paying customer with 65% success rate."),
                                 
                                 h5("Funding Requirements:", style = "color: #1e40af;"),
                                 p("Seeking $5M Series A to accelerate product development (40%), expand sales & marketing (35%), scale operations (15%), and maintain working capital (10%). Clear roadmap to profitability and sustainable growth.")
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Feld, B., & Mendelson, J. (2019). Venture deals: Be smarter than your lawyer and venture capitalist. John Wiley & Sons."),
                      p("Chen, J. (2019). The fundraising field guide: A startup founder's handbook for venture capital. Self-published."),
                      p("Kupor, S. (2019). Secrets of sand hill road: Venture capital and how to get it. Portfolio."),
                      p("Wasserman, N. (2012). The founder's dilemmas: Anticipating and avoiding the pitfalls that can sink a startup. Princeton University Press.")
                  )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Tab 2: Product Validation Chart
  output$validation_chart <- renderPlotly({
    validation_data <- data.frame(
      Product = c("Route Optimization", "Predictive Maintenance", "EV Charging", "Fleet Analytics"),
      Interest_High = c(75, 60, 45, 80),
      Interest_Medium = c(20, 30, 35, 15),
      Interest_Low = c(5, 10, 20, 5)
    )
    
    p <- plot_ly(validation_data, x = ~Product, y = ~Interest_High, type = 'bar', name = 'High Interest',
                 marker = list(color = '#10b981')) %>%
      add_trace(y = ~Interest_Medium, name = 'Medium Interest', marker = list(color = '#f59e0b')) %>%
      add_trace(y = ~Interest_Low, name = 'Low Interest', marker = list(color = '#ef4444')) %>%
      layout(
        title = 'Product Interest Validation',
        yaxis = list(title = 'Interest Level (%)'),
        xaxis = list(title = 'AI Products'),
        barmode = 'stack',
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  # Tab 4: LOI Table
  output$loi_table <- DT::renderDataTable({
    loi_data <- data.frame(
      Company = c("LogiTech Corp", "FastFleet Solutions", "GreenTransport Inc", "EcoLogistics", "SmartFreight"),
      Status = c("Signed", "In Review", "Signed", "Negotiating", "Signed"),
      Value = c("$250K", "$180K", "$320K", "$150K", "$200K"),
      Timeline = c("Q2 2024", "Q3 2024", "Q1 2024", "Q4 2024", "Q2 2024"),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(loi_data, options = list(pageLength = 10, dom = 't'),
                  class = 'cell-border stripe') %>%
      formatStyle(
        'Status',
        backgroundColor = styleEqual(c('Signed', 'In Review', 'Negotiating'), 
                                     c('#dcfce7', '#fef3c7', '#fee2e2'))
      )
  })
  
  # LOI Summary Metrics
  output$total_loi_value <- renderText({
    "$1.1M"
  })
  
  output$loi_count <- renderText({
    "5"
  })
  
  # LOI Preview
  output$loi_preview <- renderText({
    if(input$company_name != "" && input$contact_person != "") {
      paste0(
        "LETTER OF INTENT\n\n",
        "Company: ", input$company_name, "\n",
        "Contact: ", input$contact_person, "\n",
        "Pilot Duration: ", input$pilot_duration, " months\n",
        "Pilot Budget: $", format(input$pilot_budget, big.mark = ","), "\n",
        "Full Contract Value: $", format(input$full_contract_value, big.mark = ","), "\n\n",
        "This Letter of Intent expresses our company's commitment to participate in a pilot program\n",
        "for AI Fleet Optimization Platform, with the intention to proceed to a full commercial\n",
        "agreement upon successful pilot completion..."
      )
    } else {
      "Please fill in company details to generate LOI preview..."
    }
  })
  
  # Tab 5: Performance Metrics Chart
  output$performance_metrics <- renderPlotly({
    metrics_data <- data.frame(
      Metric = c("Route Efficiency", "Fuel Savings", "Delivery Time", "Maintenance Cost", "Customer Satisfaction"),
      Improvement = c(18, 22, 15, 12, 92),
      Target = c(20, 25, 18, 15, 95)
    )
    
    p <- plot_ly(metrics_data, x = ~Metric, y = ~Improvement, type = 'bar', name = 'Current',
                 marker = list(color = '#3b82f6')) %>%
      add_trace(y = ~Target, name = 'Target', marker = list(color = '#10b981')) %>%
      layout(
        title = 'Performance Metrics vs Targets',
        yaxis = list(title = 'Improvement (%)'),
        xaxis = list(title = 'Performance Areas'),
        barmode = 'group',
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  # Tab 7: Network Growth Chart
  output$network_growth_chart <- renderPlotly({
    network_data <- data.frame(
      Month = c("Jan", "Feb", "Mar", "Apr", "May", "Jun"),
      New_Customers = c(2, 3, 4, 6, 8, 12),
      Referrals = c(0, 1, 2, 3, 5, 8),
      Advocates = c(1, 2, 4, 7, 12, 24)
    )
    
    p <- plot_ly(network_data, x = ~Month, y = ~New_Customers, type = 'scatter', mode = 'lines+markers',
                 name = 'New Customers', line = list(color = '#3b82f6')) %>%
      add_trace(y = ~Referrals, name = 'Referrals', line = list(color = '#10b981')) %>%
      add_trace(y = ~Advocates, name = 'Active Advocates', line = list(color = '#f59e0b')) %>%
      layout(
        title = 'Network Growth Trends',
        yaxis = list(title = 'Count'),
        xaxis = list(title = 'Month'),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  # Tab 8: Investor Growth Chart
  output$investor_growth_chart <- renderPlotly({
    growth_data <- data.frame(
      Quarter = c("Q1 2023", "Q2 2023", "Q3 2023", "Q4 2023", "Q1 2024", "Q2 2024"),
      ARR = c(0.3, 0.6, 1.1, 1.6, 2.1, 2.4),
      Customers = c(3, 6, 11, 16, 21, 24)
    )
    
    p <- plot_ly(growth_data, x = ~Quarter, y = ~ARR, type = 'scatter', mode = 'lines+markers',
                 name = 'ARR ($M)', line = list(color = '#3b82f6', width = 3),
                 yaxis = 'y1') %>%
      add_trace(y = ~Customers, name = 'Customers', line = list(color = '#10b981', width = 3),
                yaxis = 'y2') %>%
      layout(
        title = 'Growth Trajectory for Investors',
        xaxis = list(title = 'Quarter'),
        yaxis = list(side = 'left', title = 'ARR ($M)', color = '#3b82f6'),
        yaxis2 = list(side = 'right', overlaying = 'y', title = 'Customer Count', color = '#10b981'),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)',
        legend = list(x = 0.1, y = 0.9)
      )
    
    p
  })
  
  # Reactive event handlers
  observeEvent(input$launch_survey, {
    showNotification("Smart survey launched! Collecting customer transport needs data.", type = "success")
  })
  
  observeEvent(input$schedule_call, {
    showNotification("Video consultation scheduled successfully!", type = "success")
  })
  
  observeEvent(input$finalize_commitment, {
    showNotification("Testing agreement finalized with client!", type = "success")
  })
  
  observeEvent(input$generate_loi, {
    showNotification("Letter of Intent generated and ready for download.", type = "success")
  })
  
  observeEvent(input$complete_testing, {
    showNotification("Testing phase marked as complete. Ready for conversion!", type = "success")
  })
  
  observeEvent(input$update_negotiation, {
    showNotification("Negotiation status updated in CRM system.", type = "info")
  })
  
  observeEvent(input$update_network, {
    showNotification("Network metrics updated successfully.", type = "info")
  })
  
  observeEvent(input$generate_pitch_deck, {
    showNotification("Investor pitch deck generated with latest metrics!", type = "success")
  })
  
  observeEvent(input$prepare_outreach, {
    showNotification("Investor outreach materials prepared and ready.", type = "success")
  })
  
  # Download handler for LOI
  output$download_loi <- downloadHandler(
    filename = function() {
      paste0("LOI_", input$company_name, "_", Sys.Date(), ".txt")
    },
    content = function(file) {
      writeLines(c(
        "LETTER OF INTENT",
        "",
        paste("Company:", input$company_name),
        paste("Contact:", input$contact_person),
        paste("Pilot Duration:", input$pilot_duration, "months"),
        paste("Pilot Budget: $", format(input$pilot_budget, big.mark = ",")),
        paste("Full Contract Value: $", format(input$full_contract_value, big.mark = ",")),
        "",
        "This Letter of Intent expresses our company's commitment to participate",
        "in a pilot program for AI Fleet Optimization Platform..."
      ), file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)