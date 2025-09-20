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
primary_color <- "#2C3E50"
secondary_color <- "#3498DB"
accent_color <- "#E74C3C"
success_color <- "#27AE60"
warning_color <- "#F39C12"
info_color <- "#17A2B8"

# Custom CSS styling
# Custom CSS styling
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
  .plotly { 
    border-radius: 12px !important; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.05) !important;
  }
  .dataTables_wrapper { 
    background: white !important; 
    border-radius: 12px !important; 
    padding: 20px !important; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.05) !important;
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
  .btn-primary:hover,
  .btn-success:hover {
    background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
    transform: translateY(-1px) !important;
  }
  .nav-tabs-custom > .nav-tabs > li.active {
    border-top-color: #667eea !important;
  }
  .nav-tabs-custom > .nav-tabs > li.active > a {
    background-color: #ffffff !important;
    color: #2c3e50 !important;
    font-weight: bold !important;
  }
  .progress-bar {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  }
  .form-control {
    border-radius: 8px !important;
    border: 1px solid #e3e8ff !important;
    transition: border-color 0.3s ease !important;
  }
  .form-control:focus {
    border-color: #667eea !important;
    box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25) !important;
  }
  h4 { 
    color: #2c3e50 !important; 
    font-weight: 600 !important; 
  }
  .references h4 { 
    color: #4f46e5 !important; 
  }
  .box-body {
    border-radius: 0 0 12px 12px !important;
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
                  title = "Pitch Preparation Progress", status = "primary", solidHeader = TRUE,
                  width = 6, height = "350px",
                  plotlyOutput("progress_chart", height = "280px")
                ),
                box(
                  title = "Key Metrics Overview", status = "info", solidHeader = TRUE,
                  width = 6, height = "350px",
                  plotlyOutput("metrics_overview", height = "280px")
                )
              ),
              fluidRow(
                box(
                  title = "Upcoming Actions", status = "success", solidHeader = TRUE,
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
                • Feld, B. & Mendelson, J. (2019). <em>Venture Deals: Be Smarter Than Your Lawyer and Venture Capitalist</em>. 4th ed. Hoboken: John Wiley & Sons.<br>
                • Ries, E. (2011). <em>The Lean Startup: How Today's Entrepreneurs Use Continuous Innovation to Create Radically Successful Businesses</em>. New York: Crown Business.<br>
                • Bussgang, J. (2017). <em>Mastering the VC Game: A Venture Capital Insider Reveals How to Get from Start-up to IPO on Your Terms</em>. New York: Portfolio.")),
                  div(class = "reference-item",
                      HTML("<strong>Online Resources:</strong><br>
                • Kruze Consulting (2024). 'Best 10 VC Pitch Decks, Examples and Templates'. Available at: https://kruzeconsulting.com/blog/top-5-venture-capital-pitch-decks/ (Accessed: 16 Sept 2025).<br>
                • Visual Hackers (2025). 'How to build a successful Pitch Deck in 2024'. Available at: https://visualhackers.com/blog/how-to-build-a-successful-pitch-deck-in-2024/ (Accessed: 16 Sept 2025).<br>
                • Harvard Business School Online (2020). 'How to Pitch a Business Idea: 5 Steps'. Available at: https://online.hbs.edu/blog/post/how-to-pitch-a-business-idea (Accessed: 16 Sept 2025)."))
                )
              )
      ),
      
      # Investor Research Tab
      tabItem(tabName = "research",
              fluidRow(
                box(
                  title = "Investor Research Framework", status = "primary", solidHeader = TRUE,
                  width = 4,
                  h4("Research Categories", style = "color: #2C3E50;"),
                  checkboxGroupInput("research_categories",
                                     label = "Select research areas:",
                                     choices = list(
                                       "Investment Focus Areas" = "focus",
                                       "Portfolio Companies" = "portfolio",
                                       "Investment Thesis" = "thesis",
                                       "Deal Size Range" = "deal_size",
                                       "Stage Preferences" = "stage",
                                       "Geographic Focus" = "geography",
                                       "Industry Expertise" = "industry",
                                       "Past Founder Interactions" = "interactions"
                                     ),
                                     selected = c("focus", "portfolio", "thesis")
                  ),
                  br(),
                  actionButton("generate_research", "Generate Research Template", 
                               class = "btn-primary btn-block")
                ),
                box(
                  title = "Investor Database", status = "info", solidHeader = TRUE,
                  width = 8,
                  DT::dataTableOutput("investor_database")
                )
              ),
              fluidRow(
                box(
                  title = "Research Deep Dive", status = "warning", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Investment Patterns",
                             plotlyOutput("investment_patterns", height = "400px")
                    ),
                    tabPanel("Portfolio Analysis",
                             wordcloud2Output("portfolio_cloud", height = "400px")
                    ),
                    tabPanel("Geographic Distribution",
                             leafletOutput("investor_map", height = "400px")
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
                • Hoffman, R. & Yeh, C. (2018). <em>Blitzscaling: The Lightning-Fast Path to Building Massively Valuable Companies</em>. New York: Currency.<br>
                • Graham, P. (2020). <em>Hackers & Painters: Big Ideas from the Computer Age</em>. Sebastopol: O'Reilly Media.<br>
                • Thiel, P. & Masters, B. (2014). <em>Zero to One: Notes on Startups, or How to Build the Future</em>. New York: Crown Business.")),
                  div(class = "reference-item",
                      HTML("<strong>Online Resources:</strong><br>
                • Silicon Valley Bank (2025). 'How to create a pitch deck: Essential skills for early-stage and Series A funding'. Available at: https://www.svb.com/startup-insights/startup-strategy/how-to-create-investor-pitch-deck-vc-angels/ (Accessed: 16 Sept 2025).<br>
                • Bagchi Law (2024). 'Pitch Deck Best Practices'. Available at: https://bagchilaw.com/2024/03/19/pitch-deck-best-practices/ (Accessed: 16 Sept 2025).<br>
                • Slidebean (2024). 'Pitch Deck Examples from 35+ Killer Startups'. Available at: https://slidebean.com/pitch-deck-examples (Accessed: 16 Sept 2025)."))
                )
              )
      ),
      
      # Audience Profiling Tab
      tabItem(tabName = "profiling",
              fluidRow(
                box(
                  title = "Investor Profile Builder", status = "primary", solidHeader = TRUE,
                  width = 6,
                  h4("Individual Investor Analysis", style = "color: #2C3E50;"),
                  selectInput("selected_investor", "Select Investor:",
                              choices = c("Sarah Chen - TechVentures", "Mark Rodriguez - Innovation Capital",
                                          "Emily Watson - Growth Partners", "David Kim - Startup Fund")),
                  hr(),
                  h5("Key Characteristics:", style = "color: #3498DB;"),
                  tags$ul(
                    tags$li("Investment Range: $500K - $2M"),
                    tags$li("Focus: B2B SaaS, FinTech"),
                    tags$li("Stage: Seed to Series A"),
                    tags$li("Decision Style: Data-driven"),
                    tags$li("Communication: Direct, metrics-focused")
                  ),
                  br(),
                  h5("Previous Investments:", style = "color: #3498DB;"),
                  verbatimTextOutput("investor_portfolio")
                ),
                box(
                  title = "Audience Segmentation", status = "info", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("audience_segments", height = "350px")
                )
              ),
              fluidRow(
                box(
                  title = "Investor Personality Matrix", status = "success", solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("personality_matrix", height = "400px")
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
                • Moore, G. (2014). <em>Crossing the Chasm: Marketing and Selling Disruptive Products to Mainstream Customers</em>. 3rd ed. New York: HarperBusiness.<br>
                • Christensen, C. (2016). <em>The Innovator's Dilemma: When New Technologies Cause Great Firms to Fail</em>. Boston: Harvard Business Review Press.")),
                  div(class = "reference-item",
                      HTML("<strong>Online Resources:</strong><br>
                • Founder Institute (2025). 'How to Pitch Your Startup – Templates, Tips, and Real Examples'. Available at: https://fi.co/pitch-deck (Accessed: 16 Sept 2025).<br>
                • Stanford Graduate School of Business (2024). '10 Steps to Perfect Your Startup Pitch'. Available at: https://www.gsb.stanford.edu/insights/10-steps-perfect-your-startup-pitch (Accessed: 16 Sept 2025).<br>
                • Pitch (2024). '15 great pitch deck examples from successful startups'. Available at: https://pitch.com/blog/15-great-pitch-decks-from-successful-startups (Accessed: 16 Sept 2025)."))
                )
              )
      ),
      
      # Pitch Alignment Tab
      tabItem(tabName = "alignment",
              fluidRow(
                box(
                  title = "Organization Objective Mapping", status = "primary", solidHeader = TRUE,
                  width = 6,
                  h4("Alignment Strategy", style = "color: #2C3E50;"),
                  selectInput("alignment_org", "Select Organization:",
                              choices = c("TechVentures Capital", "Innovation Partners",
                                          "Growth Fund LLC", "Startup Accelerator")),
                  hr(),
                  h5("Organization Objectives:", style = "color: #3498DB;"),
                  tags$div(id = "org_objectives",
                           tags$ul(
                             tags$li("Portfolio diversification in emerging tech"),
                             tags$li("Strong ROI within 5-7 years"),
                             tags$li("Market disruption potential"),
                             tags$li("Scalable business models"),
                             tags$li("Experienced founding teams")
                           )
                  ),
                  br(),
                  textAreaInput("pitch_alignment", "How does your startup align?",
                                rows = 4, placeholder = "Describe alignment with objectives...")
                ),
                box(
                  title = "Pitch Customization Score", status = "warning", solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("alignment_score", height = "300px"))
                )
              ),
              fluidRow(
                box(
                  title = "Key Message Framework", status = "info", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Problem-Solution Fit",
                             h4("Tailor your problem statement to investor priorities"),
                             verbatimTextOutput("problem_framework")
                    ),
                    tabPanel("Market Opportunity",
                             h4("Connect market size to investor thesis"),
                             plotlyOutput("market_alignment", height = "300px")
                    ),
                    tabPanel("Competitive Advantage",
                             h4("Highlight differentiators that matter to this audience"),
                             DT::dataTableOutput("competitive_matrix")
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
                • Porter, M. (2008). <em>Competitive Strategy: Techniques for Analyzing Industries and Competitors</em>. New York: Free Press.<br>
                • Collins, J. (2001). <em>Good to Great: Why Some Companies Make the Leap... and Others Don't</em>. New York: HarperBusiness.<br>
                • Kim, W.C. & Mauborgne, R. (2015). <em>Blue Ocean Strategy: How to Create Uncontested Market Space and Make the Competition Irrelevant</em>. Boston: Harvard Business Review Press.")),
                  div(class = "reference-item",
                      HTML("<strong>Online Resources:</strong><br>
                • Cirrus Insight (2025). '25 Best Startup Pitch Deck Examples to Win Investors'. Available at: https://www.cirrusinsight.com/blog/startup-pitch-decks (Accessed: 16 Sept 2025).<br>
                • StoryDoc (2025). '25 Proven Pitch Decks & What They Teach Us (2025)'. Available at: https://www.storydoc.com/blog/pitch-deck-examples (Accessed: 16 Sept 2025).<br>
                • HSBC Innovation Banking (2024). 'How to Create An Investor Pitch Presentation'. Available at: https://www.hsbcinnovationbanking.com/us/en/resources/how-to-create-a-compelling-investor-pitch (Accessed: 16 Sept 2025)."))
                )
              )
      ),
      
      # Networking Strategy Tab
      tabItem(tabName = "networking",
              fluidRow(
                box(
                  title = "Pre-Event Networking Plan", status = "primary", solidHeader = TRUE,
                  width = 4,
                  h4("Event Preparation", style = "color: #2C3E50;"),
                  dateInput("event_date", "Event Date:", value = Sys.Date() + 7),
                  textInput("event_name", "Event Name:", placeholder = "e.g., TechCrunch Disrupt"),
                  numericInput("target_meetings", "Target Meetings:", value = 8, min = 1, max = 20),
                  hr(),
                  h5("Networking Goals:", style = "color: #3498DB;"),
                  checkboxGroupInput("networking_goals",
                                     label = "Select your networking goals:",
                                     choices = list(
                                       "Secure follow-up meetings" = "meetings",
                                       "Gather market feedback" = "feedback",
                                       "Build brand awareness" = "awareness",
                                       "Connect with mentors" = "mentors",
                                       "Identify partnerships" = "partnerships"
                                     ),
                                     selected = c("meetings", "feedback")
                  )
                ),
                box(
                  title = "Target Contact Strategy", status = "info", solidHeader = TRUE,
                  width = 8,
                  DT::dataTableOutput("networking_targets")
                )
              ),
              fluidRow(
                box(
                  title = "Networking Effectiveness Tracker", status = "success", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("networking_funnel", height = "350px")
                ),
                box(
                  title = "Connection Quality Score", status = "warning", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("connection_quality", height = "350px")
                )
              ),
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = FALSE,
                  width = 12, class = "references",
                  h5("Academic and Industry References:"),
                  div(class = "reference-item",
                      HTML("<strong>Books:</strong><br>
                • Carnegie, D. (2009). <em>How to Win Friends and Influence People</em>. New York: Simon & Schuster.<br>
                • Ferrazzi, K. & Raz, T. (2014). <em>Never Eat Alone: And Other Secrets to Success, One Relationship at a Time</em>. New York: Currency.<br>
                • Grant, A. (2013). <em>Give and Take: Why Helping Others Drives Our Success</em>. New York: Penguin Books.")),
                  div(class = "reference-item",
                      HTML("<strong>Online Resources:</strong><br>
                • Harvard Business Review (2016). 'Learn to Love Networking'. Available at: https://hbr.org/2016/05/learn-to-love-networking (Accessed: 16 Sept 2025).<br>
                • Harvard Business Review (2024). 'Tried-and-True Networking Tips from Decades of Experience'. Available at: https://hbr.org/podcast/2024/11/tried-and-true-networking-tips-from-decades-of-experience (Accessed: 16 Sept 2025).<br>
                • Harvard Catalyst (2024). 'Networking Best Practices'. Available at: https://catalyst.harvard.edu/writing-communication-center/networking-best-practices/ (Accessed: 16 Sept 2025)."))
                )
              )
      ),
      
      # Follow-up Tracker Tab
      tabItem(tabName = "followup",
              fluidRow(
                box(
                  title = "Follow-up Action Center", status = "primary", solidHeader = TRUE,
                  width = 4,
                  h4("Quick Actions", style = "color: #2C3E50;"),
                  selectInput("contact_select", "Select Contact:",
                              choices = c("Sarah Chen", "Mark Rodriguez", "Emily Watson")),
                  selectInput("followup_type", "Follow-up Type:",
                              choices = c("Thank you email", "Additional information",
                                          "Meeting request", "Progress update")),
                  dateInput("followup_date", "Follow-up Date:", value = Sys.Date() + 1),
                  textAreaInput("followup_notes", "Notes:", rows = 3),
                  br(),
                  actionButton("add_followup", "Schedule Follow-up", class = "btn-success btn-block")
                ),
                box(
                  title = "Follow-up Pipeline", status = "info", solidHeader = TRUE,
                  width = 8,
                  DT::dataTableOutput("followup_pipeline")
                )
              ),
              fluidRow(
                box(
                  title = "Response Rate Analytics", status = "warning", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("response_rates", height = "300px")
                ),
                box(
                  title = "Follow-up Timing Analysis", status = "success", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("timing_analysis", height = "300px")
                )
              ),
              fluidRow(
                box(
                  title = "Email Templates & Best Practices", status = "primary", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Thank You Template",
                             h4("Post-Event Thank You"),
                             verbatimTextOutput("thank_you_template")
                    ),
                    tabPanel("Information Follow-up",
                             h4("Additional Information Request"),
                             verbatimTextOutput("info_template")
                    ),
                    tabPanel("Meeting Request",
                             h4("Formal Meeting Request"),
                             verbatimTextOutput("meeting_template")
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
                • Heath, C. & Heath, D. (2007). <em>Made to Stick: Why Some Ideas Survive and Others Die</em>. New York: Random House.<br>
                • Cialdini, R. (2006). <em>Influence: The Psychology of Persuasion</em>. New York: Harper Business.<br>
                • Pink, D. (2012). <em>To Sell Is Human: The Surprising Truth About Moving Others</em>. New York: Riverhead Books.")),
                  div(class = "reference-item",
                      HTML("<strong>Online Resources:</strong><br>
                • Streak (2025). 'How to write a cold email to investors (sample emails + template included)'. Available at: https://www.streak.com/post/how-to-write-a-cold-email-to-an-investor-and-grab-their-attention (Accessed: 16 Sept 2025).<br>
                • Finmark (2023). 'How to Write Investor Emails That Get a Response (Templates Included)'. Available at: https://finmark.com/investor-email/ (Accessed: 16 Sept 2025).<br>
                • Startups.com (2023). 'The Investor Email Pitch'. Available at: https://www.startups.com/articles/email-pitch (Accessed: 16 Sept 2025)."))
                )
              )
      ),
      
      # Resources Tab
      tabItem(tabName = "resources",
              fluidRow(
                box(
                  title = "Pitch Deck Templates", status = "primary", solidHeader = TRUE,
                  width = 4,
                  h4("Industry-Standard Templates", style = "color: #2C3E50;"),
                  tags$ul(
                    tags$li(tags$a("Seed Stage Template", href = "#", style = "color: #3498DB;")),
                    tags$li(tags$a("Series A Template", href = "#", style = "color: #3498DB;")),
                    tags$li(tags$a("B2B SaaS Focused", href = "#", style = "color: #3498DB;")),
                    tags$li(tags$a("FinTech Specialized", href = "#", style = "color: #3498DB;")),
                    tags$li(tags$a("E-commerce Template", href = "#", style = "color: #3498DB;"))
                  ),
                  hr(),
                  h5("Key Slides Checklist:", style = "color: #3498DB;"),
                  checkboxInput("slide_problem", "Problem Statement"),
                  checkboxInput("slide_solution", "Solution Overview"),
                  checkboxInput("slide_market", "Market Size & Opportunity"),
                  checkboxInput("slide_business", "Business Model"),
                  checkboxInput("slide_traction", "Traction & Metrics"),
                  checkboxInput("slide_team", "Team Introduction"),
                  checkboxInput("slide_financials", "Financial Projections"),
                  checkboxInput("slide_funding", "Funding Request")
                ),
                box(
                  title = "Industry Benchmarks", status = "info", solidHeader = TRUE,
                  width = 8,
                  tabsetPanel(
                    tabPanel("Funding Statistics",
                             plotlyOutput("funding_benchmarks", height = "350px")
                    ),
                    tabPanel("Pitch Success Rates",
                             plotlyOutput("success_rates", height = "350px")
                    ),
                    tabPanel("Industry Multiples",
                             DT::dataTableOutput("industry_multiples")
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Learning Resources", status = "success", solidHeader = TRUE,
                  width = 6,
                  h4("Recommended Reading", style = "color: #2C3E50;"),
                  tags$ul(
                    tags$li("'Venture Deals' by Brad Feld & Jason Mendelson"),
                    tags$li("'The Lean Startup' by Eric Ries"),
                    tags$li("'Crossing the Chasm' by Geoffrey Moore"),
                    tags$li("'Blitzscaling' by Reid Hoffman"),
                    tags$li("'Zero to One' by Peter Thiel")
                  ),
                  hr(),
                  h5("Video Resources:", style = "color: #3498DB;"),
                  tags$ul(
                    tags$li(tags$a("Y Combinator Startup School", href = "#")),
                    tags$li(tags$a("Stanford Entrepreneurship Corner", href = "#")),
                    tags$li(tags$a("TED Talks on Innovation", href = "#"))
                  )
                ),
                box(
                  title = "Event Calendar", status = "warning", solidHeader = TRUE,
                  width = 6,
                  h4("Upcoming Networking Events", style = "color: #2C3E50;"),
                  DT::dataTableOutput("event_calendar")
                )
              ),
              fluidRow(
                box(
                  title = "References", status = "info", solidHeader = FALSE,
                  width = 12, class = "references",
                  h5("Academic and Industry References:"),
                  div(class = "reference-item",
                      HTML("<strong>Books:</strong><br>
                • Blank, S. & Dorf, B. (2012). <em>The Startup Owner's Manual: The Step-By-Step Guide for Building a Great Company</em>. Pescadero: K&S Ranch.<br>
                • Maurya, A. (2012). <em>Running Lean: Iterate from Plan A to a Plan That Works</em>. 2nd ed. Sebastopol: O'Reilly Media.<br>
                • Gans, J. (2016). <em>The Disruption Dilemma</em>. Cambridge: MIT Press.")),
                  div(class = "reference-item",
                      HTML("<strong>Online Resources:</strong><br>
                • MIT Sloan Management Review (2025). 'Investor relations'. Available at: https://sloanreview.mit.edu/harvard-keyword/investor-relations/ (Accessed: 16 Sept 2025).<br>
                • MIT Sloan (2025). 'Conferences and Competitions'. Available at: https://mitsloan.mit.edu/student-life/conferences-and-competitions (Accessed: 16 Sept 2025).<br>
                • OpenVC (2025). '13 cold email examples sent to VCs'. Available at: https://www.openvc.app/blog/cold-email-examples-investors (Accessed: 16 Sept 2025)."))
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
  
  # Progress Chart
  output$progress_chart <- renderPlotly({
    progress_data <- data.frame(
      Category = c("Investor Research", "Audience Profiling", "Pitch Alignment", 
                   "Networking Prep", "Follow-up System"),
      Progress = c(85, 67, 72, 45, 31)
    )
    
    p <- plot_ly(progress_data, x = ~Category, y = ~Progress, type = 'bar',
                 marker = list(color = c('#3498DB', '#27AE60', '#E74C3C', '#F39C12', '#9B59B6'))) %>%
      layout(title = "", xaxis = list(title = ""), yaxis = list(title = "Progress %"),
             showlegend = FALSE, margin = list(b = 100))
    p
  })
  
  # Metrics Overview
  output$metrics_overview <- renderPlotly({
    metrics_data <- data.frame(
      Week = 1:8,
      Contacts_Made = c(5, 12, 18, 25, 31, 38, 42, 47),
      Follow_ups = c(2, 8, 14, 19, 24, 29, 33, 37),
      Meetings_Scheduled = c(0, 1, 3, 5, 8, 11, 14, 16)
    )
    
    p <- plot_ly(metrics_data, x = ~Week) %>%
      add_trace(y = ~Contacts_Made, name = 'Contacts Made', type = 'scatter', mode = 'lines+markers',
                line = list(color = '#3498DB')) %>%
      add_trace(y = ~Follow_ups, name = 'Follow-ups', type = 'scatter', mode = 'lines+markers',
                line = list(color = '#27AE60')) %>%
      add_trace(y = ~Meetings_Scheduled, name = 'Meetings Scheduled', type = 'scatter', mode = 'lines+markers',
                line = list(color = '#E74C3C')) %>%
      layout(title = "", xaxis = list(title = "Week"), yaxis = list(title = "Count"),
             legend = list(x = 0, y = 1))
    p
  })
  
  # Action Items Table
  output$action_items <- DT::renderDataTable({
    actions <- data.frame(
      Priority = c("High", "Medium", "High", "Low", "Medium"),
      Task = c("Follow up with Sarah Chen", "Research TechVentures portfolio", 
               "Prepare pitch deck v3", "Update LinkedIn profile", "Schedule mentor meeting"),
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
      Ticket_Size = c("$500K-2M", "$1M-5M", "$250K-1M", "$300K-1.5M", "$2M-10M"),
      Research_Status = c("Complete", "In Progress", "Complete", "Pending", "In Progress")
    )
    
    DT::datatable(investors, options = list(pageLength = 10), rownames = FALSE,
                  filter = "top") %>%
      formatStyle("Research_Status",
                  backgroundColor = styleEqual(c("Complete", "In Progress", "Pending"),
                                               c("#E8F5E8", "#FFF3E0", "#FFE6E6")))
  })
  
  # Investment Patterns
  output$investment_patterns <- renderPlotly({
    pattern_data <- data.frame(
      Sector = c("SaaS", "FinTech", "HealthTech", "E-commerce", "AI/ML", "Consumer"),
      Investments_2023 = c(45, 32, 28, 22, 38, 18),
      Investments_2024 = c(52, 28, 35, 19, 47, 15)
    )
    
    p <- plot_ly(pattern_data, x = ~Sector, y = ~Investments_2023, type = 'bar', name = '2023',
                 marker = list(color = '#3498DB')) %>%
      add_trace(y = ~Investments_2024, name = '2024', marker = list(color = '#27AE60')) %>%
      layout(title = "Investment Patterns by Sector", barmode = 'group',
             xaxis = list(title = "Sector"), yaxis = list(title = "Number of Investments"))
    p
  })
  
  # Portfolio Cloud
  output$portfolio_cloud <- renderWordcloud2({
    portfolio_words <- data.frame(
      word = c("SaaS", "B2B", "Platform", "Analytics", "Cloud", "Mobile", "API", 
               "Data", "AI", "Security", "Automation", "Integration", "Scalable"),
      freq = c(45, 38, 32, 28, 35, 22, 18, 42, 33, 25, 19, 15, 12)
    )
    wordcloud2(portfolio_words, color = "random-light", backgroundColor = "white")
  })
  
  # Investor Map
  output$investor_map <- renderLeaflet({
    investor_locations <- data.frame(
      lat = c(37.7749, 40.7128, 42.3601, 47.6062, 33.4484),
      lng = c(-122.4194, -74.0060, -71.0589, -122.3321, -118.2437),
      name = c("San Francisco", "New York", "Boston", "Seattle", "Los Angeles"),
      count = c(89, 67, 34, 28, 19)
    )
    
    leaflet(investor_locations) %>%
      addTiles() %>%
      addCircleMarkers(
        ~lng, ~lat,
        popup = ~paste(name, "<br>Investors:", count),
        radius = ~sqrt(count) * 2,
        color = "#3498DB",
        fillOpacity = 0.7
      )
  })
  
  # Investor Portfolio Output
  output$investor_portfolio <- renderText({
    "Recent Investments:\n• DataFlow (Series A, $3M)\n• SecureAPI (Seed, $800K)\n• CloudSync (Series A, $2.5M)\n• AnalyticsPro (Seed, $1.2M)"
  })
  
  # Audience Segments
  output$audience_segments <- renderPlotly({
    segments <- data.frame(
      Investor_Type = c("Angel", "Micro VC", "Traditional VC", "Corporate VC", "Family Office"),
      Count = c(45, 67, 89, 32, 14),
      Avg_Check_Size = c(50, 250, 2000, 1500, 5000)
    )
    
    p <- plot_ly(segments, x = ~Investor_Type, y = ~Count, size = ~Avg_Check_Size,
                 color = ~Investor_Type, type = 'scatter', mode = 'markers',
                 colors = c('#3498DB', '#27AE60', '#E74C3C', '#F39C12', '#9B59B6')) %>%
      layout(title = "Investor Segments by Type and Check Size",
             xaxis = list(title = "Investor Type"),
             yaxis = list(title = "Number of Investors"),
             showlegend = FALSE)
    p
  })
  
  # Personality Matrix
  output$personality_matrix <- renderPlotly({
    personality_data <- data.frame(
      Investor = c("Sarah Chen", "Mark Rodriguez", "Emily Watson", "David Kim", "Lisa Zhang"),
      Risk_Tolerance = c(7, 5, 8, 4, 9),
      Decision_Speed = c(8, 6, 5, 9, 7),
      Data_Driven = c(9, 7, 6, 8, 8),
      Relationship_Focus = c(6, 9, 8, 5, 7)
    )
    
    p <- plot_ly(personality_data, x = ~Risk_Tolerance, y = ~Decision_Speed,
                 size = ~Data_Driven, color = ~Relationship_Focus,
                 text = ~Investor, type = 'scatter', mode = 'markers',
                 marker = list(sizemode = 'diameter', sizeref = 0.1)) %>%
      layout(title = "Investor Personality Matrix",
             xaxis = list(title = "Risk Tolerance (1-10)"),
             yaxis = list(title = "Decision Speed (1-10)"))
    p
  })
  
  # Alignment Score
  output$alignment_score <- renderPlotly({
    alignment_scores <- data.frame(
      Category = c("Market Focus", "Stage Match", "Ticket Size", "Industry Expertise", "Values Alignment"),
      Score = c(8.5, 7.2, 9.1, 6.8, 8.9)
    )
    
    p <- plot_ly(alignment_scores, x = ~Score, y = ~Category, type = 'bar',
                 orientation = 'h', marker = list(color = '#27AE60')) %>%
      layout(title = "Pitch Alignment Score",
             xaxis = list(title = "Alignment Score (0-10)"),
             yaxis = list(title = ""))
    p
  })
  
  # Problem Framework
  output$problem_framework <- renderText({
    "Framework for Problem Statement:\n\n1. Quantify the problem size\n2. Connect to investor's portfolio themes\n3. Show urgency and market timing\n4. Demonstrate personal connection\n5. Link to broader market trends"
  })
  
  # Market Alignment
  output$market_alignment <- renderPlotly({
    market_data <- data.frame(
      Market = c("TAM", "SAM", "SOM"),
      Size_Billion = c(120, 25, 2.5),
      Investor_Interest = c(85, 92, 78)
    )
    
    p <- plot_ly(market_data, x = ~Market, y = ~Size_Billion, type = 'bar',
                 name = 'Market Size ($B)', marker = list(color = '#3498DB')) %>%
      add_trace(y = ~Investor_Interest, name = 'Investor Interest (%)',
                yaxis = 'y2', type = 'scatter', mode = 'lines+markers',
                line = list(color = '#E74C3C')) %>%
      layout(title = "Market Size vs Investor Interest",
             xaxis = list(title = "Market Segment"),
             yaxis = list(title = "Market Size ($B)"),
             yaxis2 = list(overlaying = 'y', side = 'right', title = 'Interest Level (%)'))
    p
  })
  
  # Competitive Matrix
  output$competitive_matrix <- DT::renderDataTable({
    competitive_data <- data.frame(
      Feature = c("AI-Powered Analytics", "Real-time Processing", "Enterprise Security", 
                  "API Integration", "Mobile App", "Custom Dashboards"),
      Your_Startup = c("Advanced", "Yes", "SOC 2", "REST/GraphQL", "iOS/Android", "Unlimited"),
      Competitor_A = c("Basic", "No", "Basic", "REST Only", "Web Only", "Limited"),
      Competitor_B = c("None", "Yes", "Enterprise", "REST", "iOS Only", "Templates"),
      Investor_Priority = c("High", "Medium", "High", "Medium", "Low", "High")
    )
    
    DT::datatable(competitive_data, options = list(pageLength = 10), rownames = FALSE) %>%
      formatStyle("Investor_Priority",
                  backgroundColor = styleEqual(c("High", "Medium", "Low"),
                                               c("#FFE6E6", "#FFF3E0", "#E8F5E8")))
  })
  
  # Networking Targets
  output$networking_targets <- DT::renderDataTable({
    networking_data <- data.frame(
      Priority = c("1", "1", "2", "2", "3", "3"),
      Contact = c("Sarah Chen", "Mark Rodriguez", "Emily Watson", "David Kim", "Lisa Zhang", "Tom Wilson"),
      Company = c("TechVentures", "Innovation Capital", "Growth Partners", "Startup Fund", "NextGen VC", "Angel Group"),
      Goal = c("Pitch Meeting", "Pitch Meeting", "Feedback", "Introduction", "Mentorship", "Advice"),
      Strategy = c("Product demo", "Market analysis", "Industry insights", "Warm intro", "Experience sharing", "Network referral"),
      Status = c("Scheduled", "Contacted", "Researching", "Planning", "Planning", "Planning")
    )
    
    DT::datatable(networking_data, options = list(pageLength = 10), rownames = FALSE) %>%
      formatStyle("Priority",
                  backgroundColor = styleEqual(c("1", "2", "3"),
                                               c("#FFE6E6", "#FFF3E0", "#E8F5E8")))
  })
  
  # Networking Funnel
  output$networking_funnel <- renderPlotly({
    funnel_data <- data.frame(
      Stage = c("Initial Contact", "Response Received", "Meeting Scheduled", "Follow-up Meeting", "Investment Interest"),
      Count = c(100, 45, 18, 8, 3)
    )
    
    p <- plot_ly(funnel_data, x = ~Count, y = ~Stage, type = 'bar',
                 orientation = 'h', marker = list(color = '#3498DB')) %>%
      layout(title = "Networking Conversion Funnel",
             xaxis = list(title = "Count"),
             yaxis = list(title = "Stage"))
    p
  })
  
  # Connection Quality
  output$connection_quality <- renderPlotly({
    quality_data <- data.frame(
      Quality_Level = c("High Quality", "Medium Quality", "Low Quality", "Follow-up Needed"),
      Count = c(12, 23, 8, 15)
    )
    
    p <- plot_ly(quality_data, x = ~Quality_Level, y = ~Count, type = 'bar',
                 marker = list(color = c('#27AE60', '#F39C12', '#E74C3C', '#9B59B6'))) %>%
      layout(title = "Connection Quality Distribution",
             xaxis = list(title = "Quality Level"),
             yaxis = list(title = "Number of Connections"))
    p
  })
  
  # Follow-up Pipeline
  output$followup_pipeline <- DT::renderDataTable({
    pipeline_data <- data.frame(
      Contact = c("Sarah Chen", "Mark Rodriguez", "Emily Watson", "David Kim", "Lisa Zhang"),
      Company = c("TechVentures", "Innovation Capital", "Growth Partners", "Startup Fund", "NextGen VC"),
      Last_Contact = c("2025-09-14", "2025-09-12", "2025-09-10", "2025-09-08", "2025-09-06"),
      Next_Action = c("Thank you email", "Pitch deck", "Meeting request", "Update email", "Introduction"),
      Due_Date = c("2025-09-17", "2025-09-18", "2025-09-19", "2025-09-20", "2025-09-21"),
      Status = c("Scheduled", "Pending", "Drafted", "Planning", "Overdue")
    )
    
    DT::datatable(pipeline_data, options = list(pageLength = 10), rownames = FALSE) %>%
      formatStyle("Status",
                  backgroundColor = styleEqual(c("Scheduled", "Pending", "Drafted", "Planning", "Overdue"),
                                               c("#E8F5E8", "#FFF3E0", "#E3F2FD", "#F3E5F5", "#FFE6E6")))
  })
  
  # Response Rates
  output$response_rates <- renderPlotly({
    response_data <- data.frame(
      Email_Type = c("Thank You", "Follow-up", "Meeting Request", "Information", "Update"),
      Response_Rate = c(85, 45, 32, 58, 67)
    )
    
    p <- plot_ly(response_data, x = ~Email_Type, y = ~Response_Rate, type = 'bar',
                 marker = list(color = '#3498DB')) %>%
      layout(title = "Email Response Rates by Type",
             xaxis = list(title = "Email Type"),
             yaxis = list(title = "Response Rate (%)"))
    p
  })
  
  # Timing Analysis
  output$timing_analysis <- renderPlotly({
    timing_data <- data.frame(
      Days_After = c(1, 2, 3, 7, 14),
      Response_Rate = c(67, 45, 32, 23, 12)
    )
    
    p <- plot_ly(timing_data, x = ~Days_After, y = ~Response_Rate, type = 'scatter', mode = 'lines+markers',
                 line = list(color = '#E74C3C')) %>%
      layout(title = "Response Rate vs Follow-up Timing",
             xaxis = list(title = "Days After Initial Contact"),
             yaxis = list(title = "Response Rate (%)"))
    p
  })
  
  # Email Templates
  output$thank_you_template <- renderText({
    "Subject: Thank you for your time at [Event Name]\n\nDear [Investor Name],\n\nThank you for taking the time to speak with me at [Event Name] yesterday. I enjoyed our conversation about [specific topic discussed].\n\nAs mentioned, [Company Name] is [brief company description]. We're currently [current status/milestone] and would love to continue our conversation.\n\nI've attached our pitch deck for your review. Would you be available for a brief call next week to discuss how we might work together?\n\nBest regards,\n[Your Name]\n[Your Title]\n[Company Name]\n[Contact Information]"
  })
  
  output$info_template <- renderText({
    "Subject: Additional information about [Company Name]\n\nHi [Investor Name],\n\nFollowing up on our conversation about [specific topic], I wanted to share some additional information that might be helpful:\n\n• [Key metric or achievement]\n• [Recent development or milestone]\n• [Relevant market insight]\n\nI believe this addresses your question about [specific concern/interest]. Happy to discuss this further at your convenience.\n\nPlease let me know if you'd like to schedule a call to dive deeper.\n\nBest,\n[Your Name]"
  })
  
  output$meeting_template <- renderText({
    "Subject: Meeting request - [Company Name] investment opportunity\n\nHi [Investor Name],\n\nI hope this email finds you well. Following our initial conversation, I'd like to schedule a formal meeting to present [Company Name]'s investment opportunity.\n\nWe're raising a $[Amount] [Round Type] to [use of funds]. Based on your portfolio and investment thesis, I believe there's strong alignment with what we're building.\n\nWould you be available for a 30-minute meeting in the next two weeks? I'm flexible with timing and can accommodate your schedule.\n\nLooking forward to hearing from you.\n\nBest regards,\n[Your Name]"
  })
  
  # Funding Benchmarks
  output$funding_benchmarks <- renderPlotly({
    funding_data <- data.frame(
      Stage = c("Pre-Seed", "Seed", "Series A", "Series B", "Series C"),
      Median_Amount = c(0.5, 2.5, 8.0, 25.0, 50.0),
      Success_Rate = c(15, 8, 5, 3, 2)
    )
    
    p <- plot_ly(funding_data, x = ~Stage, y = ~Median_Amount, type = 'bar',
                 name = 'Median Amount ($M)', marker = list(color = '#3498DB')) %>%
      add_trace(y = ~Success_Rate, name = 'Success Rate (%)',
                yaxis = 'y2', type = 'scatter', mode = 'lines+markers',
                line = list(color = '#E74C3C')) %>%
      layout(title = "Funding Benchmarks by Stage",
             xaxis = list(title = "Funding Stage"),
             yaxis = list(title = "Median Amount ($M)"),
             yaxis2 = list(overlaying = 'y', side = 'right', title = 'Success Rate (%)'))
    p
  })
  
  # Success Rates
  output$success_rates <- renderPlotly({
    success_data <- data.frame(
      Metric = c("Cold Email Response", "Meeting Conversion", "Pitch to Term Sheet", "Due Diligence Success"),
      Rate = c(3.2, 15.6, 8.4, 65.3),
      Benchmark = c(2.8, 12.1, 6.9, 58.7)
    )
    
    p <- plot_ly(success_data, x = ~Metric, y = ~Rate, type = 'bar',
                 name = 'Your Performance', marker = list(color = '#27AE60')) %>%
      add_trace(y = ~Benchmark, name = 'Industry Benchmark',
                marker = list(color = '#95A5A6')) %>%
      layout(title = "Success Rates vs Industry Benchmarks",
             xaxis = list(title = "Metric"),
             yaxis = list(title = "Success Rate (%)"),
             barmode = 'group')
    p
  })
  
  # Industry Multiples
  output$industry_multiples <- DT::renderDataTable({
    multiples_data <- data.frame(
      Industry = c("SaaS", "FinTech", "HealthTech", "E-commerce", "AI/ML", "Consumer"),
      Revenue_Multiple = c("8-15x", "6-12x", "5-10x", "3-8x", "10-20x", "2-6x"),
      Growth_Rate = c("40-100%", "35-80%", "30-70%", "25-60%", "50-150%", "20-50%"),
      Typical_Valuation = c("$10-50M", "$8-40M", "$6-30M", "$5-25M", "$15-80M", "$3-20M")
    )
    
    DT::datatable(multiples_data, options = list(pageLength = 10), rownames = FALSE)
  })
  
  # Event Calendar
  output$event_calendar <- DT::renderDataTable({
    events_data <- data.frame(
      Date = c("2025-09-25", "2025-10-02", "2025-10-15", "2025-10-28", "2025-11-10"),
      Event = c("TechCrunch Disrupt", "Web Summit", "Slush Conference", "Stanford Demo Day", "MIT Innovation"),
      Location = c("San Francisco", "Lisbon", "Helsinki", "Palo Alto", "Cambridge"),
      Type = c("Conference", "Conference", "Conference", "Demo Day", "Competition"),
      Registration = c("Open", "Open", "Closing Soon", "Invite Only", "Open")
    )
    
    DT::datatable(events_data, options = list(pageLength = 10), rownames = FALSE) %>%
      formatStyle("Registration",
                  backgroundColor = styleEqual(c("Open", "Closing Soon", "Invite Only"),
                                               c("#E8F5E8", "#FFF3E0", "#FFE6E6")))
  })
}

# Run the application
shinyApp(ui = ui, server = server)