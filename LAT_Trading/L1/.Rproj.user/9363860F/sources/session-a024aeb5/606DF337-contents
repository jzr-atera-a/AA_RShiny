# M&A Integration Dashboard
# Based on "M&A Integration How to Do It" by Danny A. Davis

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(visNetwork)
library(dplyr)
library(ggplot2)
library(shinycssloaders)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "M&A Integration Management Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Strategic Foundation", tabName = "strategic", icon = icon("bullseye")),
      menuItem("Planning & Governance", tabName = "planning", icon = icon("cogs")),
      menuItem("Execution & Management", tabName = "execution", icon = icon("tasks")),
      menuItem("Functional Workstreams", tabName = "functional", icon = icon("sitemap")),
      menuItem("Tools & Lessons", tabName = "tools", icon = icon("graduation-cap"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .skin-blue .main-header .navbar {
          background-color: #008A82 !important;
        }
        
        .skin-blue .main-header .logo {
          background-color: #002C3C !important;
        }
        
        .skin-blue .main-header .logo:hover {
          background-color: #008A82 !important;
        }
        
        .skin-blue .main-sidebar {
          background-color: #00A39A !important;
        }
        
        .skin-blue .sidebar-menu > li.header {
          background: #008A82 !important;
          color: white !important;
        }
        
        .skin-blue .sidebar-menu > li > a {
          color: white !important;
        }
        
        .skin-blue .sidebar-menu > li:hover > a,
        .skin-blue .sidebar-menu > li.active > a {
          background-color: #008A82 !important;
          color: white !important;
        }
        
        .content-wrapper, .right-side {
          background-color: #002C3C !important;
        }
        
        .box {
          background: #00A39A !important;
          border-top: none !important;
          color: white !important;
        }
        
        .box-header {
          background: #00A39A !important;
          color: white !important;
        }
        
        .box-body {
          background: white !important;
          color: #2c3e50 !important;
        }
        
        .box-title {
          color: white !important;
        }
        
        .metric-box {
          background: white;
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
          border-left: 4px solid #00A39A;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          color: #2c3e50 !important;
        }
        
        .network-container {
          height: 600px;
          border: 1px solid #ddd;
          border-radius: 8px;
          background: white;
        }
        
        .form-control {
          background-color: rgba(255,255,255,0.9) !important;
          border: 1px solid #bdc3c7 !important;
          color: #2c3e50 !important;
        }
        
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 0.2rem rgba(0, 163, 154, 0.25) !important;
        }
        
        .reference-box {
          background: #f8f9fa;
          border: 1px solid #dee2e6;
          border-radius: 8px;
          padding: 15px;
          margin: 20px 0;
          font-size: 0.9em;
          color: #495057;
        }
        
        .reference-box h5 {
          color: #00A39A;
          margin-bottom: 10px;
          font-weight: bold;
        }
      "))
    ),
    
    tabItems(
      # Strategic Foundation Tab
      tabItem(tabName = "strategic",
              fluidRow(
                box(title = "Strategic Foundation & Deal Rationale", status = "primary", solidHeader = TRUE, width = 12,
                    p("This cluster addresses the 'why' and 'what' of the M&A deal", style = "font-size: 16px; margin-bottom: 20px;")
                )
              ),
              
              fluidRow(
                box(title = "M&A Overview", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        h4("Key Statistics"),
                        p("• 70-90% of M&A deals fail to create value"),
                        p("• Only 30% achieve their strategic objectives"),
                        p("• Average integration takes 12-24 months"),
                        p("• Cultural integration is the #1 failure factor")
                    ),
                    br(),
                    h4("Strategic Drivers"),
                    p("• Revenue synergies through market expansion"),
                    p("• Cost synergies via economies of scale"),
                    p("• Technology and capability acquisition"),
                    p("• Competitive positioning and market share"),
                    p("• Access to new customer segments")
                ),
                
                box(title = "Integration Overview", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        h4("Integration Success Factors"),
                        p("• Clear strategic rationale and objectives"),
                        p("• Strong leadership and governance"),
                        p("• Comprehensive planning and communication"),
                        p("• Cultural alignment and change management"),
                        p("• Retention of key talent and customers")
                    ),
                    br(),
                    h4("Common Failure Points"),
                    p("• Lack of integration planning during due diligence"),
                    p("• Poor communication and change management"),
                    p("• Underestimating cultural differences"),
                    p("• Key talent and customer attrition"),
                    p("• Technology integration challenges")
                )
              ),
              
              fluidRow(
                box(title = "Deal Types & Synergy Analysis", status = "primary", solidHeader = TRUE, width = 12,
                    tabsetPanel(
                      tabPanel("Deal Types",
                               br(),
                               plotlyOutput("deal_types_chart")
                      ),
                      tabPanel("Synergy Tracker",
                               br(),
                               DT::dataTableOutput("synergy_table")
                      )
                    )
                )
              )
      ),
      
      # Planning & Governance Tab
      tabItem(tabName = "planning",
              fluidRow(
                box(title = "Integration Planning & Governance", status = "primary", solidHeader = TRUE, width = 12,
                    p("Focuses on designing the integration engine before executing anything", style = "font-size: 16px;")
                )
              ),
              
              fluidRow(
                box(title = "Planning for Integration", status = "primary", solidHeader = TRUE, width = 4,
                    div(class = "metric-box",
                        h4("100-Day Planning"),
                        p("• Day 1 readiness assessment"),
                        p("• Critical path identification"),
                        p("• Resource allocation planning"),
                        p("• Risk mitigation strategies")
                    ),
                    br(),
                    h4("Key Deliverables"),
                    p("• Integration master plan"),
                    p("• Day 1 operational readiness"),
                    p("• Communication strategy"),
                    p("• Stakeholder engagement plan")
                ),
                
                box(title = "Integration Drivers", status = "primary", solidHeader = TRUE, width = 4,
                    div(class = "metric-box",
                        h4("Value Creation Drivers"),
                        p("• Revenue enhancement opportunities"),
                        p("• Cost reduction initiatives"),
                        p("• Operational efficiency gains"),
                        p("• Technology and process improvements")
                    ),
                    br(),
                    h4("Critical Dependencies"),
                    p("• Legal and regulatory approvals"),
                    p("• IT systems integration"),
                    p("• Customer contract transitions"),
                    p("• Supplier relationship management")
                ),
                
                box(title = "Governance Structure", status = "primary", solidHeader = TRUE, width = 4,
                    div(class = "metric-box",
                        h4("Integration Management Office (IMO)"),
                        p("• Steering committee oversight"),
                        p("• Functional workstream leads"),
                        p("• Project management office"),
                        p("• Change management team")
                    ),
                    br(),
                    h4("Governance Principles"),
                    p("• Clear decision-making authority"),
                    p("• Regular progress reporting"),
                    p("• Issue escalation procedures"),
                    p("• Stakeholder communication protocols")
                )
              ),
              
              fluidRow(
                box(title = "Integration Timeline & Milestones", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("timeline_chart")
                )
              ),
              
              fluidRow(
                box(title = "Risk Management Dashboard", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("risk_table")
                )
              )
      ),
      
      # Execution & Management Tab
      tabItem(tabName = "execution",
              fluidRow(
                box(title = "Integration Execution & Management", status = "primary", solidHeader = TRUE, width = 12,
                    p("Covers how to execute across the organization once the plan is made", style = "font-size: 16px;")
                )
              ),
              
              fluidRow(
                box(title = "Team Mobilization", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        h4("Integration Teams"),
                        p("• Dedicated integration resources: 60%"),
                        p("• Part-time business resources: 30%"),
                        p("• External consultants: 10%"),
                        p("• Average team size: 15-25 people")
                    ),
                    br(),
                    h4("Key Activities"),
                    p("• Team formation and role clarity"),
                    p("• Integration procedures implementation"),
                    p("• Progress tracking and reporting"),
                    p("• Issue identification and resolution")
                ),
                
                box(title = "Managing the Dip", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        h4("Productivity Impact"),
                        p("• Expected 10-20% productivity decline"),
                        p("• Duration: 3-6 months typically"),
                        p("• Recovery timeline: 6-12 months"),
                        p("• Mitigation through communication")
                    ),
                    br(),
                    h4("Momentum Strategies"),
                    p("• Quick wins identification and delivery"),
                    p("• Regular communication and updates"),
                    p("• Employee engagement initiatives"),
                    p("• Performance monitoring and support")
                )
              ),
              
              fluidRow(
                box(title = "Execution Metrics Dashboard", status = "primary", solidHeader = TRUE, width = 12,
                    tabsetPanel(
                      tabPanel("Progress Tracking",
                               br(),
                               plotlyOutput("progress_chart")
                      ),
                      tabPanel("Performance Metrics",
                               br(),
                               fluidRow(
                                 valueBoxOutput("synergy_progress"),
                                 valueBoxOutput("milestone_completion"),
                                 valueBoxOutput("employee_satisfaction")
                               )
                      )
                    )
                )
              )
      ),
      
      # Functional Workstreams Tab
      tabItem(tabName = "functional",
              fluidRow(
                box(title = "Functional Workstreams", status = "primary", solidHeader = TRUE, width = 12,
                    p("Department-by-department integration with specific risks, timelines, and dependencies", style = "font-size: 16px;")
                )
              ),
              
              fluidRow(
                box(title = "Finance Integration", status = "primary", solidHeader = TRUE, width = 4,
                    div(class = "metric-box",
                        h4("Key Objectives"),
                        p("• Financial systems consolidation"),
                        p("• Reporting standardization"),
                        p("• Cost accounting alignment"),
                        p("• Treasury and cash management")
                    ),
                    h4("Critical Tasks"),
                    p("• Chart of accounts mapping"),
                    p("• ERP system integration"),
                    p("• Financial controls implementation"),
                    p("• Audit and compliance alignment")
                ),
                
                box(title = "IT Integration", status = "primary", solidHeader = TRUE, width = 4,
                    div(class = "metric-box",
                        h4("Integration Approaches"),
                        p("• Lift and shift: 40%"),
                        p("• Best of breed: 35%"),
                        p("• Complete replacement: 25%"),
                        p("• Average duration: 18-24 months")
                    ),
                    h4("Priority Systems"),
                    p("• Email and communication"),
                    p("• ERP and financial systems"),
                    p("• Customer-facing applications"),
                    p("• Security and access controls")
                ),
                
                box(title = "Human Resources", status = "primary", solidHeader = TRUE, width = 4,
                    div(class = "metric-box",
                        h4("Talent Retention"),
                        p("• Key talent identification"),
                        p("• Retention bonus programs"),
                        p("• Career development planning"),
                        p("• Cultural integration programs")
                    ),
                    h4("HR Process Integration"),
                    p("• Compensation and benefits alignment"),
                    p("• Performance management systems"),
                    p("• Learning and development programs"),
                    p("• Employee communication strategies")
                )
              ),
              
              fluidRow(
                box(title = "Sales & Marketing", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        h4("Revenue Protection"),
                        p("• Customer retention strategies"),
                        p("• Sales team integration"),
                        p("• Product portfolio optimization"),
                        p("• Brand and messaging alignment")
                    ),
                    h4("Go-to-Market Strategy"),
                    p("• Channel conflict resolution"),
                    p("• Pricing strategy harmonization"),
                    p("• Cross-selling opportunities"),
                    p("• Market expansion planning")
                ),
                
                box(title = "Supply Chain & Operations", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        h4("Operational Efficiency"),
                        p("• Supplier consolidation"),
                        p("• Manufacturing optimization"),
                        p("• Distribution network design"),
                        p("• Quality system integration")
                    ),
                    h4("Procurement Integration"),
                    p("• Spend analysis and categorization"),
                    p("• Supplier relationship management"),
                    p("• Contract renegotiation"),
                    p("• Purchasing power leverage")
                )
              ),
              
              fluidRow(
                box(title = "Functional Integration Network", status = "primary", solidHeader = TRUE, width = 12,
                    div(class = "network-container",
                        visNetworkOutput("functional_network", height = "550px")
                    )
                )
              )
      ),
      
      # Tools & Lessons Tab
      tabItem(tabName = "tools",
              fluidRow(
                box(title = "Integration Tools & Lessons Learned", status = "primary", solidHeader = TRUE, width = 12,
                    p("Integration frameworks, cultural tools, and real-world learnings", style = "font-size: 16px;")
                )
              ),
              
              fluidRow(
                box(title = "Integration Maturity Assessment", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        h4("Maturity Levels"),
                        p("• Level 1: Ad-hoc (20% of companies)"),
                        p("• Level 2: Developing (40% of companies)"),
                        p("• Level 3: Defined (25% of companies)"),
                        p("• Level 4: Managed (10% of companies)"),
                        p("• Level 5: Optimized (5% of companies)")
                    ),
                    br(),
                    selectInput("maturity_level", "Select Your Maturity Level:",
                                choices = c("Ad-hoc" = 1, "Developing" = 2, "Defined" = 3, "Managed" = 4, "Optimized" = 5),
                                selected = 2
                    ),
                    verbatimTextOutput("maturity_feedback")
                ),
                
                box(title = "Cultural Integration Tools", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        h4("Assessment Tools"),
                        p("• Cultural values mapping"),
                        p("• Leadership style analysis"),
                        p("• Communication preferences"),
                        p("• Decision-making processes")
                    ),
                    h4("Integration Strategies"),
                    p("• Cultural bridge-building sessions"),
                    p("• Cross-functional team formation"),
                    p("• Shared values development"),
                    p("• Change champion networks")
                )
              ),
              
              fluidRow(
                box(title = "Lessons Learned Database", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("lessons_table")
                )
              ),
              
              fluidRow(
                box(title = "Integration Playbook Framework", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "reference-box",
                        h5("Key Framework Components"),
                        p("1. **Strategic Assessment**: Clear rationale, value creation thesis, and success metrics"),
                        p("2. **Planning Phase**: 100-day plan, governance structure, and resource allocation"),
                        p("3. **Execution Phase**: Team mobilization, progress tracking, and issue resolution"),
                        p("4. **Functional Integration**: Department-specific playbooks and interdependencies"),
                        p("5. **Cultural Integration**: Values alignment, communication, and change management"),
                        p("6. **Performance Management**: KPI tracking, synergy realization, and continuous improvement")
                    )
                ),
                
                box(title = "Reference Citation", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "reference-box",
                        h5("Primary Source"),
                        p(strong("Davis, D. A. (2012). "), em("M&A Integration: How to Do It - Planning and Delivering M&A Integration for Business Success."), "Ed. John Wiley & Sons."),
                        br(),
                        h5("Additional References"),
                        p("• Cartwright, S. & Cooper, C. L. (2014). ", em("Mergers and Acquisitions: The Human Factor. "), "Butterworth-Heinemann."),
                        p("• DePamphilis, D. M. (2019). ", em("Mergers, Acquisitions, and Other Restructuring Activities. "), "10th ed. Academic Press."),
                        p("• Galpin, T. J. & Herndon, M. (2014). ", em("The Complete Guide to Mergers and Acquisitions. "), "3rd ed. Jossey-Bass."),
                        br(),
                        p(em("Note: This dashboard synthesizes best practices from the primary source and industry standards for M&A integration management."))
                    )
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Strategic Foundation outputs
  output$deal_types_chart <- renderPlotly({
    deal_data <- data.frame(
      Type = c("Horizontal", "Vertical", "Conglomerate", "Market Extension", "Product Extension"),
      Percentage = c(35, 25, 15, 15, 10),
      Success_Rate = c(45, 55, 30, 40, 50)
    )
    
    p <- ggplot(deal_data, aes(x = Type, y = Percentage, fill = Success_Rate)) +
      geom_bar(stat = "identity") +
      scale_fill_gradient(low = "#FF6B6B", high = "#00A39A") +
      labs(title = "M&A Deal Types Distribution", x = "Deal Type", y = "Percentage of Deals") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$synergy_table <- DT::renderDataTable({
    synergy_data <- data.frame(
      Category = c("Revenue Synergies", "Cost Synergies", "Tax Synergies", "Financial Synergies"),
      Target = c("$50M", "$75M", "$15M", "$25M"),
      Achieved = c("$35M", "$85M", "$12M", "$30M"),
      Status = c("Behind", "Ahead", "On Track", "Ahead"),
      Timeline = c("Month 18", "Month 12", "Month 6", "Month 24")
    )
    DT::datatable(synergy_data, options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # Planning & Governance outputs
  output$timeline_chart <- renderPlotly({
    timeline_data <- data.frame(
      Phase = c("Pre-Close", "Day 1", "100 Days", "6 Months", "12 Months", "18 Months"),
      Completion = c(100, 85, 70, 55, 40, 25),
      Planned = c(100, 90, 80, 70, 60, 50)
    )
    
    p <- ggplot(timeline_data, aes(x = Phase)) +
      geom_line(aes(y = Completion, group = 1, color = "Actual"), size = 1.2) +
      geom_line(aes(y = Planned, group = 1, color = "Planned"), size = 1.2) +
      geom_point(aes(y = Completion, color = "Actual"), size = 3) +
      geom_point(aes(y = Planned, color = "Planned"), size = 3) +
      scale_color_manual(values = c("Actual" = "#00A39A", "Planned" = "#008A82")) +
      labs(title = "Integration Timeline Progress", y = "Completion %") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$risk_table <- DT::renderDataTable({
    risk_data <- data.frame(
      Risk = c("Key talent departure", "Customer attrition", "IT system failures", "Cultural resistance", "Regulatory delays"),
      Probability = c("High", "Medium", "Medium", "High", "Low"),
      Impact = c("High", "High", "Medium", "Medium", "High"),
      Mitigation = c("Retention bonuses", "Customer communication", "Phased approach", "Change management", "Legal support"),
      Owner = c("HR", "Sales", "IT", "Change Mgmt", "Legal")
    )
    DT::datatable(risk_data, options = list(pageLength = 10, scrollX = TRUE))
  })
  
  # Execution outputs
  output$progress_chart <- renderPlotly({
    progress_data <- data.frame(
      Workstream = c("Finance", "IT", "HR", "Sales", "Operations", "Legal"),
      Progress = c(75, 60, 85, 70, 65, 90)
    )
    
    p <- ggplot(progress_data, aes(x = reorder(Workstream, Progress), y = Progress, fill = Progress)) +
      geom_bar(stat = "identity") +
      scale_fill_gradient(low = "#FF6B6B", high = "#00A39A") +
      coord_flip() +
      labs(title = "Workstream Progress", x = "Functional Area", y = "Completion %") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$synergy_progress <- renderValueBox({
    valueBox(
      value = "68%",
      subtitle = "Synergy Realization",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  output$milestone_completion <- renderValueBox({
    valueBox(
      value = "23/30",
      subtitle = "Milestones Completed",
      icon = icon("check-circle"),
      color = "blue"
    )
  })
  
  output$employee_satisfaction <- renderValueBox({
    valueBox(
      value = "3.2/5",
      subtitle = "Employee Satisfaction",
      icon = icon("users"),
      color = "yellow"
    )
  })
  
  # Fixed Functional Workstreams network output
  output$functional_network <- renderVisNetwork({
    nodes <- data.frame(
      id = 1:8,
      label = c("Finance", "IT", "HR", "Sales", "Marketing", "Operations", "Legal", "Procurement"),
      group = c("Core", "Core", "Core", "Revenue", "Revenue", "Operations", "Support", "Support"),
      color = c("#00A39A", "#00A39A", "#00A39A", "#008A82", "#008A82", "#FF6B6B", "#FFA500", "#FFA500")
    )
    
    # Fixed edges to match the number of nodes
    edges <- data.frame(
      from = c(1, 1, 2, 2, 3, 4, 5, 6),
      to = c(2, 3, 3, 6, 4, 5, 6, 8),
      label = c("Systems", "Reporting", "Access", "CRM", "Customers", "Pricing", "Contracts", "Suppliers")
    )
    
    visNetwork(nodes, edges) %>%
      visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
      visPhysics(stabilization = FALSE) %>%
      visInteraction(navigationButtons = TRUE)
  })
  
  # Tools & Lessons outputs
  output$maturity_feedback <- renderText({
    level <- as.numeric(input$maturity_level)
    feedback <- switch(level,
                       "1" = "Focus on establishing basic integration processes and governance structures.",
                       "2" = "Develop standardized integration methodologies and improve project management.",
                       "3" = "Implement comprehensive integration frameworks and measurement systems.",
                       "4" = "Optimize integration processes and develop advanced capabilities.",
                       "5" = "Continuously innovate and share best practices across the organization."
    )
    paste("Recommendation:", feedback)
  })
  
  output$lessons_table <- DT::renderDataTable({
    lessons_data <- data.frame(
      Lesson = c("Start integration planning during due diligence", "Communicate early and often", "Retain key talent at all costs", "Don't underestimate cultural differences", "Plan for the productivity dip"),
      Category = c("Planning", "Communication", "HR", "Culture", "Operations"),
      Impact = c("High", "High", "Critical", "High", "Medium"),
      Implementation = c("Pre-close", "Day 1", "Pre-announce", "Day 1", "Month 1"),
      Success_Rate = c("85%", "78%", "92%", "65%", "70%")
    )
    DT::datatable(lessons_data, options = list(pageLength = 10, scrollX = TRUE))
  })
}

# Run the application
shinyApp(ui = ui, server = server)