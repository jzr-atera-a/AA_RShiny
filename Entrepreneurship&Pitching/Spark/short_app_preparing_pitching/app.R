# Startup Pitch Competition Preparation App
# Complete R Shiny Application for Business Startup Competition Success

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(shinycssloaders)
library(shinyWidgets)
library(visNetwork)
library(dplyr)
library(ggplot2)
library(leaflet)
library(wordcloud2)
library(htmlwidgets)

# Define color palette for consistent styling
primary_color <- "#667eea"
secondary_color <- "#764ba2"
accent_color <- "#f39c12"
success_color <- "#27AE60"
warning_color <- "#F39C12"
info_color <- "#4f46e5"

# Custom CSS styling
custom_css <- "
  .skin-blue .main-header .navbar { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important;
  }
  .skin-blue .main-header .logo { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    color: white !important; 
    font-weight: 700 !important; 
    font-size: 18px !important;
    border-right: none !important;
  }
  .skin-blue .main-header .logo:hover {
    background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
  }
  .skin-blue .main-sidebar { 
    background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%) !important; 
  }
  .skin-blue .sidebar-menu > li > a { 
    color: #ecf0f1 !important; 
    border-left: 3px solid transparent !important; 
    transition: all 0.3s ease !important;
    font-weight: 500 !important;
  }
  .skin-blue .sidebar-menu > li.active > a,
  .skin-blue .sidebar-menu > li.menu-open > a { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border-left: 3px solid #f39c12 !important; 
    color: white !important; 
    box-shadow: inset 0 0 10px rgba(0,0,0,0.2) !important;
  }
  .skin-blue .sidebar-menu > li > a:hover { 
    background-color: #3e5771 !important; 
    color: white !important; 
  }
  .content-wrapper,
  .right-side { 
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important; 
  }
  .box { 
    border: none !important; 
    border-radius: 12px !important; 
    box-shadow: 0 4px 20px rgba(0,0,0,0.08) !important;
    background: white !important;
    margin-bottom: 20px !important;
  }
  .box-header { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    color: white !important;
    border-radius: 12px 12px 0 0 !important; 
    font-weight: 600 !important;
    border-bottom: none !important;
  }
  .box.box-solid.box-primary > .box-header,
  .box.box-solid.box-info > .box-header,
  .box.box-solid.box-success > .box-header,
  .box.box-solid.box-warning > .box-header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    color: white !important;
  }
  .references {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%) !important;
    border: 1px solid #e3e8ff !important;
    border-left: 5px solid #4f46e5 !important;
    padding: 20px !important;
    margin-top: 25px !important;
    border-radius: 12px !important;
    box-shadow: 0 2px 10px rgba(79, 70, 229, 0.1) !important;
  }
  .references h5 {
    color: #4f46e5 !important;
    font-weight: 600 !important;
    margin-bottom: 15px !important;
    border-bottom: 2px solid #4f46e5 !important;
    padding-bottom: 5px !important;
  }
  .reference-item {
    margin-bottom: 12px !important;
    line-height: 1.5 !important;
    padding-left: 10px !important;
    border-left: 3px solid #e3e8ff !important;
  }
  .small-box { 
    border-radius: 12px !important; 
    box-shadow: 0 4px 15px rgba(0,0,0,0.1) !important;
  }
  .bg-blue,
  .bg-green,
  .bg-yellow,
  .bg-red {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  }
  .small-box .icon { 
    opacity: 0.8 !important; 
  }
  .academic-content {
    background: white;
    padding: 20px;
    border-radius: 8px;
    line-height: 1.6;
    font-size: 14px;
    color: #2c3e50;
    margin-bottom: 15px;
  }
  .academic-content h5 {
    color: #4f46e5;
    font-weight: 600;
    margin-bottom: 10px;
  }
  .concept-highlight {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
    border-left: 4px solid #667eea;
    padding: 15px;
    margin: 10px 0;
    border-radius: 5px;
  }
  .btn-primary { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    border-radius: 8px !important;
    font-weight: 600 !important;
  }
  .btn-success {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    border-radius: 8px !important;
    font-weight: 600 !important;
  }
  .form-control {
    border-radius: 8px !important;
    border: 1px solid #e3e8ff !important;
  }
  h4 { 
    color: #2c3e50 !important; 
    font-weight: 600 !important; 
  }
"

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Startup Pitch Success Platform"),
  dashboardSidebar(
    tags$head(tags$style(HTML(custom_css))),
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("tachometer-alt")),
      menuItem("Investor Research", tabName = "research", icon = icon("search")),
      menuItem("Audience Profiling", tabName = "profiling", icon = icon("users")),
      menuItem("Pitch Alignment", tabName = "alignment", icon = icon("bullseye")),
      menuItem("Networking Strategy", tabName = "networking", icon = icon("network-wired")),
      menuItem("Follow-up Tracker", tabName = "followup", icon = icon("calendar-check")),
      menuItem("Resources", tabName = "resources", icon = icon("book"))
    )
  ),
  dashboardBody(
    tabItems(
      # Dashboard Tab
      tabItem(tabName = "dashboard",
              fluidRow(
                valueBoxOutput("total_investors"),
                valueBoxOutput("research_progress"),
                valueBoxOutput("networking_score")
              ),
              fluidRow(
                box(
                  title = "Pitch Preparation Framework", status = "primary", solidHeader = TRUE,
                  width = 6, height = "400px",
                  div(class = "academic-content",
                      h5("Strategic Preparation Methodology"),
                      p("Successful pitch preparation requires a systematic approach grounded in entrepreneurship theory and evidence-based practices. According to Bussgang (2017), entrepreneurs must address five critical dimensions:"),
                      div(class = "concept-highlight",
                          HTML("<strong>1. Market Validation:</strong> Demonstrate deep understanding of target market size, growth potential, and customer pain points through primary research and data collection.")),
                      div(class = "concept-highlight",
                          HTML("<strong>2. Competitive Positioning:</strong> Clearly articulate unique value proposition and sustainable competitive advantages using Porter's Five Forces framework.")),
                      div(class = "concept-highlight",
                          HTML("<strong>3. Financial Modeling:</strong> Present realistic financial projections based on comparable company analysis and bottom-up market sizing methodologies.")),
                      p("The preparation process should follow the lean startup methodology (Ries, 2011), emphasizing iterative testing of key assumptions before the formal pitch presentation.")
                  )
                ),
                box(
                  title = "Investor Psychology & Decision Making", status = "info", solidHeader = TRUE,
                  width = 6, height = "400px",
                  div(class = "academic-content",
                      h5("Understanding Investor Behavior"),
                      p("Research by Kaplan and Lerner (2016) reveals that investor decision-making follows predictable patterns influenced by cognitive biases and heuristics:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Initial Screening:</strong> Investors spend an average of 3-4 minutes on initial pitch deck review, focusing primarily on market size, team credentials, and traction metrics.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Due Diligence Priorities:</strong> Technical feasibility, market timing, scalability potential, and management team execution capability represent the four pillars of investor evaluation.")),
                      p("Gompers et al. (2020) demonstrate that successful entrepreneurs adapt their pitch narrative to align with specific investor thesis and portfolio strategy, rather than using generic presentations.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Action Items Tracker", status = "success", solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("action_items")
                )
              ),
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = FALSE,
                  width = 12, class = "references",
                  h5("Academic and Industry References:"),
                  div(class = "reference-item", 
                      HTML("<strong>Books:</strong><br>
              • Bussgang, J. (2017). <em>Mastering the VC Game: A Venture Capital Insider Reveals How to Get from Start-up to IPO on Your Terms</em>. New York: Portfolio.<br>
              • Ries, E. (2011). <em>The Lean Startup: How Today's Entrepreneurs Use Continuous Innovation to Create Radically Successful Businesses</em>. New York: Crown Business.<br>
              • Kaplan, S.N. & Lerner, J. (2016). <em>Venture Capital Data: Opportunities and Challenges</em>. Cambridge: NBER Working Paper Series.")),
                  div(class = "reference-item",
                      HTML("<strong>Journal Articles:</strong><br>
              • Gompers, P., Gornall, W., Kaplan, S.N. & Strebulaev, I.A. (2020). 'How do venture capitalists make decisions?' <em>Journal of Financial Economics</em>, 135(1), pp. 169-190.<br>
              • Petty, J.S. & Gruber, M. (2011). 'In pursuit of the real deal: A longitudinal study of VC decision making.' <em>Journal of Business Venturing</em>, 26(2), pp. 172-188."))
                )
              )
      ),
      
      # Investor Research Tab
      tabItem(tabName = "research",
              fluidRow(
                box(
                  title = "Systematic Investor Research Framework", status = "primary", solidHeader = TRUE,
                  width = 6, height = "500px",
                  div(class = "academic-content",
                      h5("Due Diligence on Potential Investors"),
                      p("Effective investor research requires systematic analysis across multiple dimensions. Cumming and Johan (2013) identify key research categories:"),
                      checkboxGroupInput("research_categories",
                                         label = "Research Framework Components:",
                                         choices = list(
                                           "Investment Focus Areas" = "focus",
                                           "Portfolio Companies" = "portfolio",
                                           "Investment Thesis" = "thesis",
                                           "Deal Size Range" = "deal_size",
                                           "Stage Preferences" = "stage",
                                           "Geographic Focus" = "geography",
                                           "Industry Expertise" = "industry",
                                           "Decision-making Process" = "process"
                                         ),
                                         selected = c("focus", "portfolio", "thesis")
                      ),
                      br(),
                      div(class = "concept-highlight",
                          HTML("<strong>Research Methodology:</strong> Use primary sources including SEC filings, portfolio company press releases, and investor interviews to validate investment patterns and preferences.")),
                      actionButton("generate_research", "Generate Research Template", 
                                   class = "btn-primary btn-block")
                  )
                ),
                box(
                  title = "Investor Database Management", status = "info", solidHeader = TRUE,
                  width = 6, height = "500px",
                  DT::dataTableOutput("investor_database")
                )
              ),
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = FALSE,
                  width = 12, class = "references",
                  h5("Academic and Industry References:"),
                  div(class = "reference-item",
                      HTML("<strong>Books:</strong><br>
              • Cumming, D. & Johan, S. (2013). <em>Venture Capital and Private Equity Contracting: An International Perspective</em>. 2nd ed. Amsterdam: Elsevier Academic Press.<br>
              • Lerner, J. & Hardymon, F. (2012). <em>Venture Capital and Private Equity: A Casebook</em>. 5th ed. Hoboken: John Wiley & Sons.<br>
              • Metrick, A. & Yasuda, A. (2021). <em>Venture Capital and the Finance of Innovation</em>. 3rd ed. Hoboken: John Wiley & Sons.")),
                  div(class = "reference-item",
                      HTML("<strong>Journal Articles:</strong><br>
              • Da Rin, M., Hellmann, T. & Puri, M. (2013). 'A survey of venture capital research.' <em>Handbook of the Economics of Finance</em>, 2, pp. 573-648.<br>
              • Gompers, P. & Lerner, J. (2001). 'The venture capital revolution.' <em>Journal of Economic Perspectives</em>, 15(2), pp. 145-168."))
                )
              )
      ),
      
      # Audience Profiling Tab
      tabItem(tabName = "profiling",
              fluidRow(
                box(
                  title = "Investor Personality Assessment", status = "primary", solidHeader = TRUE,
                  width = 12, height = "400px",
                  div(class = "academic-content",
                      h5("Psychological Profiling Framework"),
                      p("Research by Zacharakis and Meyer (2000) identifies distinct investor personality types that influence decision-making processes:"),
                      fluidRow(
                        column(3,
                               div(class = "concept-highlight",
                                   HTML("<strong>Analytical Type:</strong> Prioritizes quantitative metrics, financial models, and data-driven decision making."))
                        ),
                        column(3,
                               div(class = "concept-highlight",
                                   HTML("<strong>Relationship-Focused:</strong> Emphasizes team dynamics, cultural fit, and long-term partnership potential."))
                        ),
                        column(3,
                               div(class = "concept-highlight",
                                   HTML("<strong>Growth-Oriented:</strong> Focuses on scalability potential, market opportunity size, and expansion strategies."))
                        ),
                        column(3,
                               div(class = "concept-highlight",
                                   HTML("<strong>Risk-Averse:</strong> Emphasizes market validation, proven business models, and clear path to profitability."))
                        )
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = FALSE,
                  width = 12, class = "references",
                  h5("Academic and Industry References:"),
                  div(class = "reference-item",
                      HTML("<strong>Books:</strong><br>
              • Zacharakis, A. & Meyer, G.D. (2000). 'The potential of actuarial decision models: Can they improve the venture capital investment decision?' <em>Journal of Business Venturing</em>, 15(4), pp. 323-346.<br>
              • Kotler, P. & Armstrong, G. (2017). <em>Principles of Marketing</em>. 17th ed. Boston: Pearson Education."))
                )
              )
      ),
      
      # Pitch Alignment Tab
      tabItem(tabName = "alignment",
              fluidRow(
                box(
                  title = "Strategic Alignment Framework", status = "primary", solidHeader = TRUE,
                  width = 12, height = "400px",
                  div(class = "academic-content",
                      h5("Investor-Startup Fit Analysis"),
                      p("Strategic alignment requires systematic analysis of multiple compatibility dimensions (Cumming & Johan, 2013):"),
                      div(class = "concept-highlight",
                          HTML("<strong>Strategic Fit Dimensions:</strong><br>
                    • <strong>Stage Alignment:</strong> Match funding stage with investor preferences<br>
                    • <strong>Sector Expertise:</strong> Leverage investor domain knowledge<br>
                    • <strong>Geographic Focus:</strong> Align with investor regional strategy<br>
                    • <strong>Value-Add Capability:</strong> Identify strategic support opportunities"))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = FALSE,
                  width = 12, class = "references",
                  h5("Academic and Industry References:"),
                  div(class = "reference-item",
                      HTML("<strong>Books:</strong><br>
              • Porter, M.E. (2008). <em>Competitive Strategy: Techniques for Analyzing Industries and Competitors</em>. New York: Free Press.<br>
              • Blank, S. & Dorf, B. (2012). <em>The Startup Owner's Manual: The Step-By-Step Guide for Building a Great Company</em>. Pescadero: K&S Ranch."))
                )
              )
      ),
      
      # Networking Strategy Tab
      tabItem(tabName = "networking",
              fluidRow(
                box(
                  title = "Evidence-Based Networking Framework", status = "primary", solidHeader = TRUE,
                  width = 6, height = "400px",
                  div(class = "academic-content",
                      h5("Strategic Network Development"),
                      p("Professional networking follows systematic principles derived from organizational behavior and social capital theory (Burt, 2005):"),
                      div(class = "concept-highlight",
                          HTML("<strong>Network Theory Principles:</strong><br>
                    • <strong>Weak Ties Advantage:</strong> Leverage distant connections for novel information access<br>
                    • <strong>Structural Holes:</strong> Position yourself as bridge between disconnected groups<br>
                    • <strong>Social Capital:</strong> Build reciprocal value relationships before seeking benefits"))
                  )
                ),
                box(
                  title = "Networking Targets Database", status = "info", solidHeader = TRUE,
                  width = 6, height = "400px",
                  DT::dataTableOutput("networking_targets")
                )
              ),
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = FALSE,
                  width = 12, class = "references",
                  h5("Academic and Industry References:"),
                  div(class = "reference-item",
                      HTML("<strong>Books:</strong><br>
              • Burt, R.S. (2005). <em>Brokerage and Closure: An Introduction to Social Capital</em>. Oxford: Oxford University Press.<br>
              • Carnegie, D. (2009). <em>How to Win Friends and Influence People</em>. New York: Simon & Schuster."))
                )
              )
      ),
      
      # Follow-up Tracker Tab
      tabItem(tabName = "followup",
              fluidRow(
                box(
                  title = "Strategic Follow-up Framework", status = "primary", solidHeader = TRUE,
                  width = 6, height = "400px",
                  div(class = "academic-content",
                      h5("Systematic Follow-up Methodology"),
                      p("Effective follow-up strategies are grounded in relationship marketing and sales process optimization (Rackham, 2017):"),
                      div(class = "concept-highlight",
                          HTML("<strong>Follow-up Principles:</strong><br>
                    • <strong>Persistence vs. Pestering:</strong> Maintain regular but respectful communication frequency<br>
                    • <strong>Value Addition:</strong> Each contact should provide new insights or relevant information<br>
                    • <strong>Personalization:</strong> Reference previous conversations and specific investor interests"))
                  )
                ),
                box(
                  title = "Follow-up Pipeline", status = "info", solidHeader = TRUE,
                  width = 6, height = "400px",
                  DT::dataTableOutput("followup_pipeline")
                )
              ),
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = FALSE,
                  width = 12, class = "references",
                  h5("Academic and Industry References:"),
                  div(class = "reference-item",
                      HTML("<strong>Books:</strong><br>
              • Rackham, N. (2017). <em>SPIN Selling</em>. Aldershot: Gower Publishing.<br>
              • Cialdini, R.B. (2016). <em>Influence: The Psychology of Persuasion</em>. Rev. ed. New York: Harper Business."))
                )
              )
      ),
      
      # Resources Tab
      tabItem(tabName = "resources",
              fluidRow(
                box(
                  title = "Academic Pitch Framework Templates", status = "primary", solidHeader = TRUE,
                  width = 12, height = "400px",
                  div(class = "academic-content",
                      h5("Evidence-Based Pitch Structure"),
                      p("Pitch deck templates based on academic research and successful fundraising case studies:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Guy Kawasaki 10/20/30 Rule:</strong><br>
                    • 10 slides maximum for core presentation<br>
                    • 20 minutes total presentation time<br>
                    • 30-point minimum font size for readability")),
                      div(class = "concept-highlight",
                          HTML("<strong>Sequoia Capital Framework:</strong><br>
                    Company Purpose → Problem & Opportunity → Solution → Market Size → Competition → Product → Business Model → Team → Financials → Funding"))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = FALSE,
                  width = 12, class = "references",
                  h5("Academic and Industry References:"),
                  div(class = "reference-item",
                      HTML("<strong>Books:</strong><br>
              • Kawasaki, G. (2015). <em>The Art of the Start 2.0: The Time-Tested, Battle-Hardened Guide for Anyone Starting Anything</em>. New York: Portfolio.<br>
              • Blank, S. & Dorf, B. (2012). <em>The Startup Owner's Manual: The Step-By-Step Guide for Building a Great Company</em>. Pescadero: K&S Ranch."))
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Dashboard Value Boxes
  output$total_investors <- renderValueBox({
    valueBox(
      value = 247,
      subtitle = "Investors Researched",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$research_progress <- renderValueBox({
    valueBox(
      value = "73%",
      subtitle = "Research Complete",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  output$networking_score <- renderValueBox({
    valueBox(
      value = 8.4,
      subtitle = "Networking Score",
      icon = icon("star"),
      color = "yellow"
    )
  })
  
  # Action Items Table
  output$action_items <- DT::renderDataTable({
    actions <- data.frame(
      Priority = c("High", "Medium", "High", "Low", "Medium"),
      Task = c("Complete investor personality assessment", "Conduct customer discovery interviews", 
               "Finalize financial model validation", "Update LinkedIn profile", "Schedule mentor meeting"),
      Due_Date = c("2025-09-17", "2025-09-18", "2025-09-19", "2025-09-20", "2025-09-21"),
      Status = c("Pending", "In Progress", "Pending", "Complete", "Pending")
    )
    
    DT::datatable(actions, options = list(pageLength = 5, dom = 't'), rownames = FALSE) %>%
      formatStyle("Priority",
                  backgroundColor = styleEqual(c("High", "Medium", "Low"), 
                                               c("#FFE6E6", "#FFF3E0", "#E8F5E8")))
  })
  
  # Investor Database
  output$investor_database <- DT::renderDataTable({
    investors <- data.frame(
      Name = c("Sarah Chen", "Mark Rodriguez", "Emily Watson", "David Kim", "Lisa Zhang"),
      Firm = c("TechVentures", "Innovation Capital", "Growth Partners", "Startup Fund", "NextGen VC"),
      Focus = c("B2B SaaS", "FinTech", "Healthcare Tech", "Consumer", "AI/ML"),
      Stage = c("Seed-A", "A-B", "Seed", "Seed-A", "A-C"),
      Research_Status = c("Complete", "In Progress", "Complete", "Pending", "In Progress")
    )
    
    DT::datatable(investors, options = list(pageLength = 10), rownames = FALSE) %>%
      formatStyle("Research_Status",
                  backgroundColor = styleEqual(c("Complete", "In Progress", "Pending"),
                                               c("#E8F5E8", "#FFF3E0", "#FFE6E6")))
  })
  
  # Networking Targets
  output$networking_targets <- DT::renderDataTable({
    networking_data <- data.frame(
      Priority = c("Primary", "Primary", "Secondary", "Secondary"),
      Contact = c("Sarah Chen", "Mark Rodriguez", "Emily Watson", "David Kim"),
      Company = c("TechVentures", "Innovation Capital", "Growth Partners", "Startup Fund"),
      Objective = c("Lead investor", "Co-investor", "Market validation", "Introduction"),
      Status = c("Scheduled", "Contacted", "Researching", "Planning")
    )
    
    DT::datatable(networking_data, options = list(pageLength = 10), rownames = FALSE) %>%
      formatStyle("Priority",
                  backgroundColor = styleEqual(c("Primary", "Secondary"),
                                               c("#FFE6E6", "#FFF3E0")))
  })
  
  # Follow-up Pipeline
  output$followup_pipeline <- DT::renderDataTable({
    pipeline_data <- data.frame(
      Contact = c("Sarah Chen", "Mark Rodriguez", "Emily Watson", "David Kim"),
      Company = c("TechVentures", "Innovation Capital", "Growth Partners", "Startup Fund"),
      Last_Contact = c("2025-09-14", "2025-09-12", "2025-09-10", "2025-09-08"),
      Next_Action = c("Thank you email", "Pitch deck", "Meeting request", "Update email"),
      Status = c("Scheduled", "Pending", "Drafted", "Planning")
    )
    
    DT::datatable(pipeline_data, options = list(pageLength = 10), rownames = FALSE) %>%
      formatStyle("Status",
                  backgroundColor = styleEqual(c("Scheduled", "Pending", "Drafted", "Planning"),
                                               c("#E8F5E8", "#FFF3E0", "#E3F2FD", "#F3E5F5")))
  })
}

# Run the application
shinyApp(ui = ui, server = server)