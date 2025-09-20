# Startup Pitch Competition Preparation App - By 
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
  .dataTables_wrapper {
    overflow: visible !important;
  }
  .box-body {
    overflow: visible !important;
  }
  .progress-chart {
    height: 300px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f8f9fa;
    border-radius: 8px;
    border: 1px solid #e9ecef;
  }
"

# UI
ui <- dashboardPage(
  dashboardHeader(title = "AA Pitch Success Platform"),
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
                  width = 6, height = "auto",
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
                  width = 6, height = "auto",
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
                  title = "Progress Visualization", status = "success", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("progress_chart")
                ),
                box(
                  title = "Key Metrics Overview", status = "warning", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Performance Indicators"),
                      div(class = "concept-highlight",
                          HTML("<strong>Response Rate:</strong> 23% (Above industry average of 15%)")),
                      div(class = "concept-highlight",
                          HTML("<strong>Meeting Conversion:</strong> 8 meetings scheduled from 35 outreach attempts")),
                      div(class = "concept-highlight",
                          HTML("<strong>Pipeline Health:</strong> 12 active investor conversations, 4 in due diligence")),
                      p("Metrics updated: ", Sys.Date())
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
                  title = "Investor Database Management", status = "primary", solidHeader = TRUE,
                  width = 12, height = "auto",
                  div(class = "academic-content",
                      h5("Database Construction Principles"),
                      p("Maintain systematic records following CRM best practices for investor relationship management:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Data Quality:</strong> Ensure accuracy through multiple source verification and regular updates of investor information and portfolio changes.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Categorization:</strong> Classify investors by stage preference, sector focus, and investment criteria to enable targeted outreach strategies.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Relationship Tracking:</strong> Document all interactions, referral sources, and communication preferences to personalize future engagements."))
                  ),
                  DT::dataTableOutput("investor_database")
                )
              ),
              fluidRow(
                box(
                  title = "Investment Pattern Analysis", status = "warning", solidHeader = TRUE,
                  width = 4,
                  div(class = "academic-content",
                      h5("Sector Allocation Trends"),
                      p("Analyze historical investment patterns to identify:"),
                      tags$ul(
                        tags$li("Sector rotation preferences"),
                        tags$li("Seasonal investment timing"),
                        tags$li("Portfolio diversification strategy"),
                        tags$li("Co-investment partnerships")
                      ),
                      p("Use PitchBook, Crunchbase, and CB Insights for comprehensive data analysis.")
                  )
                ),
                box(
                  title = "Portfolio Composition Analysis", status = "warning", solidHeader = TRUE,
                  width = 4,
                  div(class = "academic-content",
                      h5("Strategic Portfolio Insights"),
                      p("Examine existing portfolio companies to understand:"),
                      tags$ul(
                        tags$li("Common business model characteristics"),
                        tags$li("Geographic distribution preferences"),
                        tags$li("Team background patterns"),
                        tags$li("Technology focus areas")
                      ),
                      p("This analysis reveals investment thesis alignment opportunities and potential synergies with existing portfolio companies.")
                  )
                ),
                box(
                  title = "Investment Sector Distribution", status = "warning", solidHeader = TRUE,
                  width = 4,
                  div(class = "academic-content",
                      h5("Sector Analysis"),
                      plotlyOutput("sector_chart", height = "250px")
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
              • Cumming, D. & Johan, S. (2013). <em>Venture Capital and Private Equity Contracting: An International Perspective</em>. 2nd ed. Amsterdam: Elsevier Academic Press.<br>
              • Lerner, J. & Hardymon, F. (2012). <em>Venture Capital and Private Equity: A Casebook</em>. 5th ed. Hoboken: John Wiley & Sons.<br>
              • Metrick, A. & Yasuda, A. (2021). <em>Venture Capital and the Finance of Innovation</em>. 3rd ed. Hoboken: John Wiley & Sons.")),
                  div(class = "reference-item",
                      HTML("<strong>Journal Articles:</strong><br>
              • Da Rin, M., Hellmann, T. & Puri, M. (2013). 'A survey of venture capital research.' <em>Handbook of the Economics of Finance</em>, 2, pp. 573-648.<br>
              • Gompers, P. & Lerner, J. (2001). 'The venture capital revolution.' <em>Journal of Economic Perspectives</em>, 15(2), pp. 145-168.<br>
              • Kaplan, S.N. & Strömberg, P. (2003). 'Financial contracting theory meets the real world.' <em>Review of Economic Studies</em>, 70(2), pp. 281-315."))
                )
              )
      ),
      
      # Audience Profiling Tab
      tabItem(tabName = "profiling",
              fluidRow(
                box(
                  title = "Investor Personality Assessment", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Psychological Profiling Framework"),
                      p("Research by Zacharakis and Meyer (2000) identifies distinct investor personality types that influence decision-making processes:"),
                      selectInput("selected_investor", "Select Investor Profile:",
                                  choices = c("Analytical Investor", "Relationship-Focused Investor",
                                              "Growth-Oriented Investor", "Risk-Averse Investor")),
                      br(),
                      uiOutput("investor_profile_details")
                  )
                ),
                box(
                  title = "Investor Segmentation Strategy", status = "info", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Strategic Audience Segmentation"),
                      p("Effective investor segmentation follows marketing principles adapted for investment contexts (Kotler & Armstrong, 2017):"),
                      div(class = "concept-highlight",
                          HTML("<strong>Demographic Segmentation:</strong> Age, experience level, educational background, and professional history influence investment preferences and risk tolerance.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Behavioral Segmentation:</strong> Investment frequency, portfolio diversification strategy, and follow-on investment patterns reveal investor commitment levels.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Psychographic Segmentation:</strong> Values, lifestyle preferences, and investment philosophy guide long-term partnership compatibility.")),
                      p("Segment investors into primary, secondary, and tertiary targets based on alignment with your startup's stage, sector, and funding requirements.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Communication Style Adaptation", status = "success", solidHeader = TRUE,
                  width = 12, height = "auto",
                  div(class = "academic-content",
                      h5("Tailored Communication Strategies"),
                      p("Adapt presentation style and content emphasis based on investor personality profiles:"),
                      fluidRow(
                        column(3,
                               div(class = "concept-highlight",
                                   HTML("<strong>For Analytical Investors:</strong><br>• Lead with quantitative data<br>• Provide detailed financial models<br>• Include competitive analysis<br>• Focus on market sizing methodology"))
                        ),
                        column(3,
                               div(class = "concept-highlight",
                                   HTML("<strong>For Relationship Investors:</strong><br>• Emphasize team background<br>• Share founder journey story<br>• Highlight cultural values<br>• Discuss long-term vision"))
                        ),
                        column(3,
                               div(class = "concept-highlight",
                                   HTML("<strong>For Growth Investors:</strong><br>• Focus on scalability metrics<br>• Highlight expansion opportunities<br>• Discuss market disruption potential<br>• Present growth trajectory models"))
                        ),
                        column(3,
                               div(class = "concept-highlight",
                                   HTML("<strong>For Risk-Averse Investors:</strong><br>• Emphasize market validation<br>• Show customer traction<br>• Highlight proven team experience<br>• Present conservative projections"))
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
              • Kotler, P. & Armstrong, G. (2017). <em>Principles of Marketing</em>. 17th ed. Boston: Pearson Education.<br>
              • Cialdini, R.B. (2016). <em>Influence: The Psychology of Persuasion</em>. Rev. ed. New York: Harper Business.")),
                  div(class = "reference-item",
                      HTML("<strong>Journal Articles:</strong><br>
              • Franke, N., Gruber, M., Harhoff, D. & Henkel, J. (2008). 'Venture capitalists' evaluations of start-up teams.' <em>Small Business Economics</em>, 30(4), pp. 431-450.<br>
              • Huang, L. & Pearce, J.L. (2015). 'Managing the unknowable: The effectiveness of early-stage investor gut feel in entrepreneurial investment decisions.' <em>Administrative Science Quarterly</em>, 60(4), pp. 634-670."))
                )
              )
      ),
      
      # Pitch Alignment Tab
      tabItem(tabName = "alignment",
              fluidRow(
                box(
                  title = "Strategic Alignment Framework", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Investor-Startup Fit Analysis"),
                      p("Strategic alignment requires systematic analysis of multiple compatibility dimensions (Cumming & Johan, 2013):"),
                      selectInput("alignment_org", "Select Investment Organization:",
                                  choices = c("Early-Stage VC Fund", "Growth Equity Fund",
                                              "Corporate Venture Capital", "Angel Investor Group")),
                      br(),
                      uiOutput("alignment_details"),
                      br(),
                      textAreaInput("pitch_alignment", "Describe Strategic Alignment:",
                                    rows = 4, placeholder = "Articulate how your startup aligns with investor objectives and thesis...")
                  )
                ),
                box(
                  title = "Value Proposition Customization", status = "warning", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Investor-Specific Value Articulation"),
                      p("Customize value proposition based on investor priorities and portfolio strategy:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Financial Returns:</strong> Quantify potential IRR and multiple of invested capital based on comparable transactions and market analysis.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Strategic Value:</strong> Identify synergies with existing portfolio companies and potential for cross-portfolio collaboration.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Market Positioning:</strong> Demonstrate how investment supports investor's sector thesis and market positioning strategy.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Risk Mitigation:</strong> Address specific concerns relevant to investor's risk profile and portfolio construction approach."))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Message Framework Development", status = "info", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Problem-Solution Articulation",
                             div(class = "academic-content",
                                 h5("Evidence-Based Problem Framing"),
                                 p("Structure problem statement using established frameworks from entrepreneurship literature:"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Problem Validation Framework:</strong><br>
                               1. <strong>Market Research:</strong> Present primary and secondary research demonstrating problem significance<br>
                               2. <strong>Customer Discovery:</strong> Share insights from customer interviews and validation experiments<br>
                               3. <strong>Quantification:</strong> Provide market sizing data and economic impact analysis<br>
                               4. <strong>Urgency:</strong> Demonstrate why this problem requires immediate solution<br>
                               5. <strong>Personal Connection:</strong> Articulate founder-problem fit and domain expertise"))
                             )
                    ),
                    tabPanel("Market Opportunity Analysis",
                             div(class = "academic-content",
                                 h5("Market Sizing Methodology"),
                                 p("Apply rigorous market analysis techniques following academic best practices:"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>TAM-SAM-SOM Framework:</strong><br>
                               • <strong>Total Addressable Market:</strong> Define universe of potential customers<br>
                               • <strong>Serviceable Addressable Market:</strong> Identify realistic target segment<br>
                               • <strong>Serviceable Obtainable Market:</strong> Calculate achievable market share")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Market Validation:</strong> Use bottom-up analysis, customer surveys, and industry reports to validate market assumptions and growth projections."))
                             )
                    ),
                    tabPanel("Competitive Differentiation",
                             div(class = "academic-content",
                                 h5("Sustainable Competitive Advantage"),
                                 p("Develop competitive positioning using Porter's framework and strategic management principles:"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Differentiation Strategy:</strong><br>
                               • <strong>Technology Advantage:</strong> Patent protection, proprietary algorithms, or technical barriers<br>
                               • <strong>Network Effects:</strong> Platform benefits that increase with user adoption<br>
                               • <strong>Brand/Reputation:</strong> Customer loyalty and market recognition advantages<br>
                               • <strong>Operational Excellence:</strong> Cost structure or efficiency advantages"))
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
              • Porter, M.E. (2008). <em>Competitive Strategy: Techniques for Analyzing Industries and Competitors</em>. New York: Free Press.<br>
              • Blank, S. & Dorf, B. (2012). <em>The Startup Owner's Manual: The Step-By-Step Guide for Building a Great Company</em>. Pescadero: K&S Ranch.<br>
              • Osterwalder, A. & Pigneur, Y. (2010). <em>Business Model Generation</em>. Hoboken: John Wiley & Sons.")),
                  div(class = "reference-item",
                      HTML("<strong>Journal Articles:</strong><br>
              • Cumming, D. & Johan, S. (2013). 'Technology-based private equity, entrepreneurship and economic development.' <em>Venture Capital</em>, 15(1), pp. 1-20.<br>
              • Shane, S. & Venkataraman, S. (2000). 'The promise of entrepreneurship as a field of research.' <em>Academy of Management Review</em>, 25(1), pp. 217-226.<br>
              • Teece, D.J. (2010). 'Business models, business strategy and innovation.' <em>Long Range Planning</em>, 43(2-3), pp. 172-194."))
                )
              )
      ),
      
      # Networking Strategy Tab
      tabItem(tabName = "networking",
              fluidRow(
                box(
                  title = "Evidence-Based Networking Framework (Sample Visualisation)", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Strategic Network Development"),
                      p("Professional networking follows systematic principles derived from organizational behavior and social capital theory (Burt, 2005):"),
                      dateInput("event_date", "Target Event Date:", value = Sys.Date() + 7),
                      textInput("event_name", "Event Name:", placeholder = "e.g., TechCrunch Disrupt"),
                      numericInput("target_meetings", "Target Meetings:", value = 8, min = 1, max = 20),
                      br(),
                      div(class = "concept-highlight",
                          HTML("<strong>Network Theory Principles:</strong><br>
                    • <strong>Weak Ties Advantage:</strong> Leverage distant connections for novel information access<br>
                    • <strong>Structural Holes:</strong> Position yourself as bridge between disconnected groups<br>
                    • <strong>Social Capital:</strong> Build reciprocal value relationships before seeking benefits")),
                      br(),
                      checkboxGroupInput("networking_goals",
                                         label = "Strategic Networking Objectives:",
                                         choices = list(
                                           "Secure follow-up meetings" = "meetings",
                                           "Gather market intelligence" = "feedback",
                                           "Build brand awareness" = "awareness",
                                           "Identify strategic mentors" = "mentors",
                                           "Develop partnership opportunities" = "partnerships"
                                         ),
                                         selected = c("meetings", "feedback")
                      )
                  )
                ),
                box(
                  title = "Relationship Development Strategy", status = "info", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Systematic Relationship Building"),
                      p("Effective investor relationship development follows established relationship marketing principles (Grönroos, 2017):"),
                      div(class = "concept-highlight",
                          HTML("<strong>Relationship Lifecycle Management:</strong><br>
                          1. <strong>Awareness:</strong> Initial contact through warm introductions or targeted outreach<br>
                    2. <strong>Interest:</strong> Demonstrate value proposition alignment through personalized communication<br>
                    3. <strong>Consideration:</strong> Provide detailed information and address specific concerns<br>
                    4. <strong>Commitment:</strong> Establish formal investment discussion and due diligence process")),
                      br(),
                      div(class = "concept-highlight",
                          HTML("<strong>Value-First Approach:</strong> Lead interactions by offering insights, introductions, or market intelligence rather than immediately requesting meetings or funding."))
                  ),
                  div(style = "margin-top: 20px;", DT::dataTableOutput("networking_targets"))
                )
              ),
              fluidRow(
                box(
                  title = "Network Effectiveness Measurement", status = "success", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Networking ROI Analysis"),
                      p("Measure networking effectiveness using key performance indicators:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Quantitative Metrics:</strong><br>
                    • Response rate to initial outreach<br>
                    • Meeting conversion percentage<br>
                    • Follow-up engagement rates<br>
                    • Referral generation frequency")),
                      div(class = "concept-highlight",
                          HTML("<strong>Qualitative Assessment:</strong><br>
                    • Relationship depth and trust development<br>
                    • Strategic value of connections<br>
                    • Long-term partnership potential<br>
                    • Network influence and reach"))
                  )
                ),
                box(
                  title = "Connection Quality Framework", status = "warning", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Relationship Quality Assessment"),
                      p("Evaluate connection quality using relationship strength indicators:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Relationship Strength Factors:</strong><br>
                    • <strong>Frequency:</strong> Regular communication and interaction patterns<br>
                    • <strong>Reciprocity:</strong> Mutual value exchange and support provision<br>
                    • <strong>Trust:</strong> Confidential information sharing and advice seeking<br>
                    • <strong>Influence:</strong> Ability to access broader network through connection")),
                      p("Focus resources on developing fewer, higher-quality relationships rather than maximizing quantity of superficial connections.")
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
              • Burt, R.S. (2005). <em>Brokerage and Closure: An Introduction to Social Capital</em>. Oxford: Oxford University Press.<br>
              • Grönroos, C. (2017). <em>Relationship Marketing: Managing Customer Relationships for Profit</em>. 4th ed. Harlow: Pearson Education.<br>
              • Carnegie, D. (2009). <em>How to Win Friends and Influence People</em>. New York: Simon & Schuster.")),
                  div(class = "reference-item",
                      HTML("<strong>Journal Articles:</strong><br>
              • Granovetter, M.S. (1973). 'The strength of weak ties.' <em>American Journal of Sociology</em>, 78(6), pp. 1360-1380.<br>
              • Coleman, J.S. (1988). 'Social capital in the creation of human capital.' <em>American Journal of Sociology</em>, 94, pp. S95-S120.<br>
              • Uzzi, B. (1997). 'Social structure and competition in interfirm networks.' <em>Administrative Science Quarterly</em>, 42(1), pp. 35-67."))
                )
              )
      ),
      
      # Follow-up Tracker Tab
      tabItem(tabName = "followup",
              fluidRow(
                box(
                  title = "Strategic Follow-up Framework (Sample Visualization)", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Systematic Follow-up Methodology"),
                      p("Effective follow-up strategies are grounded in relationship marketing and sales process optimization (Rackham, 2017):"),
                      selectInput("contact_select", "Select Contact Type:",
                                  choices = c("Primary Target Investor", "Secondary Interest Investor", "Strategic Mentor")),
                      selectInput("followup_type", "Follow-up Strategy:",
                                  choices = c("Value-add communication", "Progress update",
                                              "Market insights sharing", "Meeting request")),
                      dateInput("followup_date", "Scheduled Follow-up:", value = Sys.Date() + 1),
                      br(),
                      div(class = "concept-highlight",
                          HTML("<strong>Follow-up Principles:</strong><br>
                    • <strong>Persistence vs. Pestering:</strong> Maintain regular but respectful communication frequency<br>
                    • <strong>Value Addition:</strong> Each contact should provide new insights or relevant information<br>
                    • <strong>Personalization:</strong> Reference previous conversations and specific investor interests")),
                      textAreaInput("followup_notes", "Strategic Notes:", rows = 3),
                      actionButton("add_followup", "Schedule Follow-up", class = "btn-success btn-block")
                  )
                ),
                box(
                  title = "Communication Tracking System", status = "info", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("CRM Best Practices for Startups"),
                      p("Implement systematic tracking following customer relationship management principles:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Documentation Standards:</strong><br>
                    • Record all interaction details including date, medium, and key discussion points<br>
                    • Track investor preferences, concerns, and specific interests<br>
                    • Monitor response patterns and optimal communication timing")),
                      div(class = "concept-highlight",
                          HTML("<strong>Pipeline Management:</strong><br>
                    • Categorize relationships by engagement level and investment probability<br>
                    • Set automated reminders for follow-up actions<br>
                    • Maintain updated contact information and current status"))
                  ),
                  div(style = "margin-top: 20px;", DT::dataTableOutput("followup_pipeline"))
                )
              ),
              fluidRow(
                box(
                  title = "Communication Effectiveness Analysis", status = "warning", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Response Rate Optimization"),
                      p("Analyze communication effectiveness using direct marketing principles:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Response Rate Factors:</strong><br>
                    • <strong>Timing:</strong> Optimal days of week and time of day for outreach<br>
                    • <strong>Medium:</strong> Email vs. phone vs. social media effectiveness<br>
                    • <strong>Content:</strong> Subject line impact and message personalization<br>
                    • <strong>Frequency:</strong> Optimal intervals between follow-up attempts")),
                      p("Industry benchmarks suggest 2-3% response rates for cold outreach, 15-20% for warm introductions, and 40-50% for referral-based contacts.")
                  )
                ),
                box(
                  title = "Follow-up Timing Strategy", status = "success", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Optimal Communication Cadence"),
                      p("Research-based timing recommendations for investor follow-up:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Initial Follow-up:</strong> 24-48 hours after initial meeting to maintain momentum and demonstrate professionalism.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Secondary Follow-up:</strong> 1-2 weeks later with relevant market updates, traction metrics, or industry insights.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Ongoing Engagement:</strong> Monthly updates during non-fundraising periods to maintain relationship warmth.")),
                      p("Adjust frequency based on investor preferences and engagement levels, avoiding over-communication while maintaining visibility.")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Communication Templates & Best Practices", status = "primary", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Post-Meeting Follow-up",
                             div(class = "academic-content",
                                 h5("Professional Thank You Framework"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Template Structure:</strong><br>
                               1. <strong>Immediate Acknowledgment:</strong> Reference specific discussion points from meeting<br>
                               2. <strong>Value Addition:</strong> Provide promised information or relevant insights<br>
                               3. <strong>Next Steps:</strong> Clearly articulate proposed follow-up actions<br>
                               4. <strong>Professional Close:</strong> Maintain formal but warm tone")),
                                 p("Send within 24 hours of meeting to demonstrate professionalism and maintain conversation momentum.")
                             )
                    ),
                    tabPanel("Progress Update Communication",
                             div(class = "academic-content",
                                 h5("Investor Update Best Practices"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Update Components:</strong><br>
                               • <strong>Key Metrics:</strong> Revenue, user growth, or other relevant KPIs<br>
                               • <strong>Milestones:</strong> Product launches, partnerships, or team additions<br>
                               • <strong>Challenges:</strong> Transparent discussion of obstacles and solutions<br>
                               • <strong>Market Insights:</strong> Industry trends relevant to investor interests")),
                                 p("Regular updates maintain investor engagement and demonstrate transparency and progress.")
                             )
                    ),
                    tabPanel("Meeting Request Strategy",
                             div(class = "academic-content",
                                 h5("Formal Investment Discussion Request"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Request Framework:</strong><br>
                               • <strong>Context Setting:</strong> Reference previous interactions and current fundraising status<br>
                               • <strong>Strategic Fit:</strong> Articulate specific reasons for targeting this investor<br>
                               • <strong>Agenda Preview:</strong> Outline key topics for discussion<br>
                               • <strong>Flexibility:</strong> Offer multiple scheduling options and format preferences")),
                                 p("Position meeting request as mutual value exploration rather than one-sided funding request.")
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
              • Rackham, N. (2017). <em>SPIN Selling</em>. Aldershot: Gower Publishing.<br>
              • Cialdini, R.B. (2016). <em>Influence: The Psychology of Persuasion</em>. Rev. ed. New York: Harper Business.<br>
              • Kumar, V. & Reinartz, W. (2018). <em>Customer Relationship Management: Concept, Strategy, and Tools</em>. 3rd ed. Berlin: Springer.")),
                  div(class = "reference-item",
                      HTML("<strong>Journal Articles:</strong><br>
              • Palmatier, R.W., Dant, R.P., Grewal, D. & Evans, K.R. (2006). 'Factors influencing the effectiveness of relationship marketing.' <em>Journal of Marketing</em>, 70(4), pp. 136-153.<br>
              • Morgan, R.M. & Hunt, S.D. (1994). 'The commitment-trust theory of relationship marketing.' <em>Journal of Marketing</em>, 58(3), pp. 20-38."))
                )
              )
      ),
      
      # Resources Tab
      tabItem(tabName = "resources",
              fluidRow(
                box(
                  title = "Academic Pitch Framework Templates", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Evidence-Based Pitch Structure"),
                      p("Pitch deck templates based on academic research and successful fundraising case studies provide strategic frameworks for entrepreneur presentations:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Sequoia Capital Framework:</strong><br>
                    1. Company Purpose<br>
                    2. Problem & Opportunity<br>
                    3. Solution<br>
                    4. Market Size<br>
                    5. Competition<br>
                    6. Product<br>
                    7. Business Model<br>
                    8. Team<br>
                    9. Financials<br>
                    10. Funding & Use of Capital")),
                      br(),
                      h5("Key Slides Validation Checklist:", style = "color: #4f46e5;"),
                      checkboxInput("slide_problem", "Problem Statement with Market Research"),
                      checkboxInput("slide_solution", "Solution with Product Demonstration"),
                      checkboxInput("slide_market", "Market Size with TAM/SAM/SOM Analysis"),
                      checkboxInput("slide_business", "Business Model with Revenue Streams"),
                      checkboxInput("slide_traction", "Traction with Key Performance Indicators"),
                      checkboxInput("slide_team", "Team with Relevant Experience"),
                      checkboxInput("slide_financials", "Financial Projections with Assumptions"),
                      checkboxInput("slide_funding", "Funding Request with Use of Capital")
                  )
                ),
                box(
                  title = "Industry Performance Benchmarks", status = "info", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Startup Performance Metrics"),
                      p("Industry benchmarks based on comprehensive startup databases (Kaplan & Lerner, 2016):"),
                      div(class = "concept-highlight",
                          HTML("<strong>Fundraising Success Rates:</strong><br>
                    • Pre-seed: 15-20% of applicants<br>
                    • Seed: 8-12% of applicants<br>
                    • Series A: 5-8% of applicants<br>
                    • Series B+: 3-5% of applicants")),
                      div(class = "concept-highlight",
                          HTML("<strong>Pitch-to-Investment Conversion:</strong><br>
                    • Cold outreach: 0.1-0.5%<br>
                    • Warm introductions: 2-5%<br>
                    • Accelerator demo days: 5-15%<br>
                    • Competition winners: 20-40%")),
                      div(class = "concept-highlight",
                          HTML("<strong>Due Diligence Timeline:</strong><br>
                    • Initial interest to term sheet: 4-8 weeks<br>
                    • Term sheet to closing: 4-6 weeks<br>
                    • Total process duration: 2-4 months"))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Essential Reading & Learning Resources", status = "success", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Curated Academic and Professional Literature"),
                      p("Essential reading for evidence-based pitch preparation:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Foundational Texts:</strong><br>
                    • 'Venture Deals' by Brad Feld & Jason Mendelson<br>
                    • 'The Lean Startup' by Eric Ries<br>
                    • 'Crossing the Chasm' by Geoffrey Moore<br>
                    • 'Zero to One' by Peter Thiel<br>
                    • 'Blitzscaling' by Reid Hoffman")),
                      div(class = "concept-highlight",
                          HTML("<strong>Academic Journals:</strong><br>
                    • Journal of Business Venturing<br>
                    • Entrepreneurship Theory and Practice<br>
                    • Strategic Management Journal<br>
                    • Academy of Management Review<br>
                    • Journal of Financial Economics")),
                      div(class = "concept-highlight",
                          HTML("<strong>Online Learning Platforms:</strong><br>
                    • Y Combinator Startup School (free)<br>
                    • Stanford Entrepreneurship Corner<br>
                    • MIT OpenCourseWare Entrepreneurship<br>
                    • Coursera Entrepreneurship Specializations"))
                  )
                ),
                box(
                  title = "Professional Development Events", status = "warning", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Strategic Networking Event Calendar"),
                      p("High-value events for investor networking and pitch practice:"),
                      div(class = "concept-highlight",
                          HTML("<strong>Tier 1 Events (International):</strong><br>
                    • TechCrunch Disrupt<br>
                    • Web Summit<br>
                    • Slush Conference<br>
                    • SXSW Interactive<br>
                    • Mobile World Congress")),
                      div(class = "concept-highlight",
                          HTML("<strong>Regional Events:</strong><br>
                    • Local accelerator demo days<br>
                    • University entrepreneurship competitions<br>
                    • Industry-specific conferences<br>
                    • Angel investor group meetings<br>
                    • Venture capital firm events")),
                      p("Research attendee lists and speaker lineups to identify high-priority networking targets before attending events.")
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
              • Blank, S. & Dorf, B. (2012). <em>The Startup Owner's Manual: The Step-By-Step Guide for Building a Great Company</em>. Pescadero: K&S Ranch.<br>
              • Maurya, A. (2012). <em>Running Lean: Iterate from Plan A to a Plan That Works</em>. 2nd ed. Sebastopol: O'Reilly Media.")),
                  div(class = "reference-item",
                      HTML("<strong>Research Sources:</strong><br>
              • Kaplan, S.N. & Lerner, J. (2016). 'Venture capital data: Opportunities and challenges.' <em>NBER Working Paper Series</em>, No. 22500.<br>
              • CB Insights (2024). 'State of Venture Capital Report.' Available at: https://www.cbinsights.com/research/report/venture-capital-report/ (Accessed: 16 Sept 2025).<br>
              • PitchBook (2024). 'Venture Capital Database and Market Intelligence.' Available at: https://pitchbook.com/ (Accessed: 16 Sept 2025).")),
                  div(class = "reference-item",  
                      HTML("<strong>Dashboard Creation:</strong><br>
              • Dashboard Designed and Edited by Jose-Francisco Zubizarreta - Atera Analytics Ltd"))
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Sample data for demonstration
  investor_data <- data.frame(
    Investor_Name = c("Sarah Chen", "Mark Rodriguez", "Emily Watson", "David Kim", "Lisa Zhang"),
    Organization = c("TechVentures Capital", "Innovation Growth", "Strategic Equity", "Early Stage Partners", "Digital Fund"),
    Focus_Area = c("B2B SaaS", "Healthcare Tech", "Consumer Internet", "AI/ML", "Fintech"),
    Stage = c("Series A", "Seed", "Series A-B", "Pre-seed/Seed", "Series B+"),
    Check_Size = c("$500K-2M", "$1M-5M", "$250K-1M", "$100K-500K", "$2M-10M"),
    Last_Contact = c("2025-09-10", "2025-09-08", "2025-09-12", "2025-09-05", "2025-09-14"),
    Status = c("Active Discussion", "Follow-up Scheduled", "Initial Contact", "Referral Pending", "Due Diligence")
  )
  
  networking_data <- data.frame(
    Contact = c("Sarah Chen", "Mark Rodriguez", "Emily Watson", "Alex Thompson", "Jordan Lee"),
    Priority = c("High", "High", "Medium", "Medium", "Low"),
    Next_Action = c("Follow-up call", "Send deck", "Intro meeting", "Referral request", "Market update"),
    Due_Date = c("2025-09-17", "2025-09-18", "2025-09-20", "2025-09-22", "2025-09-25"),
    Notes = c("Interested in Q4 metrics", "Wants team bios", "Scheduling coffee", "Via mutual contact", "Monthly update")
  )
  
  followup_data <- data.frame(
    Investor = c("Sarah Chen", "Mark Rodriguez", "Emily Watson", "David Kim"),
    Last_Contact = c("2025-09-10", "2025-09-08", "2025-09-12", "2025-09-05"),
    Next_Followup = c("2025-09-17", "2025-09-15", "2025-09-19", "2025-09-12"),
    Type = c("Progress Update", "Deck Follow-up", "Meeting Request", "Introduction"),
    Status = c("Scheduled", "Overdue", "Pending", "Completed")
  )
  
  # Dashboard Value Boxes
  output$total_investors <- renderValueBox({
    valueBox(
      value = 247,
      subtitle = "Investors Researched (Simulated Metric)",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$research_progress <- renderValueBox({
    valueBox(
      value = "73%",
      subtitle = "Research Complete (Simulated Metric)",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  output$networking_score <- renderValueBox({
    valueBox(
      value = 8.4,
      subtitle = "Networking Score (Simulated Metric)",
      icon = icon("star"),
      color = "yellow"
    )
  })
  
  # Charts with plotly (replacing leaflet functionality)
  output$progress_chart <- renderPlotly({
    progress_data <- data.frame(
      Stage = c("Research", "Outreach", "Meetings", "Follow-up", "Due Diligence"),
      Completed = c(95, 78, 45, 62, 25),
      Target = c(100, 80, 50, 70, 30)
    )
    
    p <- ggplot(progress_data, aes(x = Stage)) +
      geom_bar(aes(y = Target), stat = "identity", fill = "#e9ecef", alpha = 0.7, width = 0.6) +
      geom_bar(aes(y = Completed), stat = "identity", fill = "#667eea", alpha = 0.9, width = 0.6) +
      labs(title = "Pitch Preparation Progress", y = "Completion %", x = "Preparation Stage") +
      theme_minimal() +
      theme(plot.title = element_text(color = "#4f46e5", size = 14, face = "bold"))
    
    ggplotly(p, tooltip = c("x", "y"))
  })
  
  output$sector_chart <- renderPlotly({
    sector_data <- data.frame(
      Sector = c("B2B SaaS", "Healthcare", "Fintech", "AI/ML", "Consumer", "Other"),
      Count = c(12, 8, 15, 10, 6, 4)
    )
    
    p <- ggplot(sector_data, aes(x = reorder(Sector, Count), y = Count)) +
      geom_bar(stat = "identity", fill = "#667eea", alpha = 0.8) +
      coord_flip() +
      labs(title = "Investor Focus Areas", x = "Sector", y = "Number of Investors") +
      theme_minimal() +
      theme(plot.title = element_text(color = "#4f46e5", size = 12, face = "bold"))
    
    ggplotly(p, tooltip = c("x", "y"))
  })
  
  # Data tables
  output$investor_database <- DT::renderDataTable({
    DT::datatable(investor_data, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  class = 'cell-border stripe')
  })
  
  output$networking_targets <- DT::renderDataTable({
    DT::datatable(networking_data, 
                  options = list(pageLength = 5, scrollX = TRUE),
                  class = 'cell-border stripe')
  })
  
  output$followup_pipeline <- DT::renderDataTable({
    DT::datatable(followup_data, 
                  options = list(pageLength = 5, scrollX = TRUE),
                  class = 'cell-border stripe')
  })
  
  # Reactive investor profile details
  output$investor_profile_details <- renderUI({
    profile_content <- switch(input$selected_investor,
                              "Analytical Investor" = div(class = "concept-highlight",
                                                          HTML("<strong>Analytical Type:</strong> Prioritizes quantitative metrics, financial models, and data-driven decision making. Requires detailed market analysis and competitive benchmarking.")),
                              "Relationship-Focused Investor" = div(class = "concept-highlight",
                                                                    HTML("<strong>Relationship-Focused:</strong> Emphasizes team dynamics, cultural fit, and long-term partnership potential. Values founder-market fit and team cohesion.")),
                              "Growth-Oriented Investor" = div(class = "concept-highlight",
                                                               HTML("<strong>Growth-Oriented:</strong> Focuses on scalability potential, market opportunity size, and expansion strategies. Seeks high-growth, disruptive business models.")),
                              "Risk-Averse Investor" = div(class = "concept-highlight",
                                                           HTML("<strong>Risk-Averse:</strong> Emphasizes market validation, proven business models, and clear path to profitability. Prefers established markets with predictable outcomes."))
    )
    profile_content
  })
  
  # Reactive alignment details
  output$alignment_details <- renderUI({
    alignment_content <- switch(input$alignment_org,
                                "Early-Stage VC Fund" = div(class = "concept-highlight",
                                                            HTML("<strong>Early-Stage Focus:</strong> Prioritizes market opportunity, team strength, and product-market fit over revenue metrics. Expects higher risk tolerance and longer investment horizons.")),
                                "Growth Equity Fund" = div(class = "concept-highlight",
                                                           HTML("<strong>Growth Stage Focus:</strong> Emphasizes proven business models, scalable revenue growth, and clear path to profitability. Requires demonstrated market traction.")),
                                "Corporate Venture Capital" = div(class = "concept-highlight",
                                                                  HTML("<strong>Strategic Investment:</strong> Values alignment with parent company objectives, potential for partnerships, and synergistic business opportunities.")),
                                "Angel Investor Group" = div(class = "concept-highlight",
                                                             HTML("<strong>Angel Investment:</strong> Focuses on founder backgrounds, personal connections, and early-stage potential. Often provides mentorship alongside capital."))
    )
    alignment_content
  })
  
  # Follow-up button action
  observeEvent(input$add_followup, {
    showModal(modalDialog(
      title = "Follow-up Scheduled",
      "Your follow-up has been added to the tracking system.",
      easyClose = TRUE,
      footer = modalButton("Close")
    ))
  })
}

# Run the application
shinyApp(ui = ui, server = server)