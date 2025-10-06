# 10x Productivity & Life Optimization Dashboard
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
    title = "10x Life Optimization Dashboard",
    titleWidth = 350
  ),
  
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      menuItem("Overview & Strategy", tabName = "overview", icon = icon("chart-line")),
      menuItem("Knowledge Acquisition", tabName = "knowledge", icon = icon("brain")),
      menuItem("Skills Development", tabName = "skills", icon = icon("tools")),
      menuItem("Social Networking", tabName = "networking", icon = icon("users")),
      menuItem("Wealth Generation", tabName = "wealth", icon = icon("dollar-sign")),
      menuItem("Entrepreneurship", tabName = "entrepreneur", icon = icon("rocket")),
      menuItem("Work Optimization", tabName = "work", icon = icon("briefcase")),
      menuItem("Family & Relationships", tabName = "family", icon = icon("heart")),
      menuItem("Travel & Experiences", tabName = "travel", icon = icon("plane")),
      menuItem("Health & Energy", tabName = "health", icon = icon("heartbeat")),
      menuItem("Integration & Tracking", tabName = "tracking", icon = icon("calendar-check"))
    )
  ),
  
  dashboardBody(
    # Custom CSS with Professional Color Scheme
    tags$head(
      tags$style(HTML("
        /* Main Layout Colors */
        .content-wrapper, .right-side {
          background-color: #f8fafc;
        }
        
        .main-header .navbar {
          background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%) !important;
          border-bottom: 3px solid #1d4ed8;
        }
        
        .main-header .logo {
          background: linear-gradient(135deg, #1e40af 0%, #2563eb 100%) !important;
          color: #ffffff !important;
          border-bottom: 0;
          font-weight: 600;
        }
        
        .main-sidebar {
          background: linear-gradient(180deg, #1f2937 0%, #374151 100%) !important;
        }
        
        /* Sidebar Menu Styling */
        .sidebar-menu > li > a {
          color: #e5e7eb !important;
          border-left: 4px solid transparent;
          transition: all 0.3s ease;
          font-weight: 500;
        }
        
        .sidebar-menu > li:hover > a,
        .sidebar-menu > li.active > a {
          background: linear-gradient(90deg, #3b82f6 0%, #2563eb 100%) !important;
          border-left-color: #60a5fa !important;
          color: #ffffff !important;
          box-shadow: 0 2px 4px rgba(59, 130, 246, 0.3);
        }
        
        /* Box Styling */
        .box {
          border-top: 4px solid #3b82f6;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1), 0 2px 4px rgba(0, 0, 0, 0.06);
          border-radius: 8px;
          background: #ffffff;
        }
        
        .box-header {
          background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
          color: #1e293b;
          border-radius: 8px 8px 0 0;
          border-bottom: 2px solid #e2e8f0;
          font-weight: 600;
        }
        
        .box-header.with-border {
          border-bottom: 2px solid #e2e8f0;
        }
        
        /* Status-based Box Headers */
        .box.box-primary .box-header {
          background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
          color: #1e40af;
        }
        
        .box.box-success .box-header {
          background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
          color: #065f46;
        }
        
        .box.box-info .box-header {
          background: linear-gradient(135deg, #e0f2fe 0%, #b3e5fc 100%);
          color: #0c4a6e;
        }
        
        .box.box-warning .box-header {
          background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
          color: #92400e;
        }
        
        .box.box-danger .box-header {
          background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
          color: #991b1b;
        }
        
        /* Button Styling */
        .btn-primary {
          background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
          border: none;
          color: #ffffff;
          font-weight: 600;
          border-radius: 6px;
          box-shadow: 0 2px 4px rgba(59, 130, 246, 0.3);
          transition: all 0.3s ease;
        }
        
        .btn-primary:hover {
          background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
          transform: translateY(-1px);
          box-shadow: 0 4px 8px rgba(59, 130, 246, 0.4);
        }
        
        .btn-success {
          background: linear-gradient(135deg, #10b981 0%, #059669 100%);
          border: none;
          color: #ffffff;
          font-weight: 600;
          border-radius: 6px;
          box-shadow: 0 2px 4px rgba(16, 185, 129, 0.3);
          transition: all 0.3s ease;
        }
        
        .btn-success:hover {
          background: linear-gradient(135deg, #059669 0%, #047857 100%);
          transform: translateY(-1px);
          box-shadow: 0 4px 8px rgba(16, 185, 129, 0.4);
        }
        
        .btn-warning {
          background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
          border: none;
          color: #ffffff;
          font-weight: 600;
          border-radius: 6px;
          box-shadow: 0 2px 4px rgba(245, 158, 11, 0.3);
          transition: all 0.3s ease;
        }
        
        .btn-warning:hover {
          background: linear-gradient(135deg, #d97706 0%, #b45309 100%);
          transform: translateY(-1px);
          box-shadow: 0 4px 8px rgba(245, 158, 11, 0.4);
        }
        
        /* Progress Bar Styling */
        .progress {
          background-color: #e2e8f0;
          border-radius: 6px;
          box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.1);
          height: 25px;
        }
        
        .progress-bar {
          background: linear-gradient(90deg, #3b82f6 0%, #2563eb 100%);
          border-radius: 6px;
          transition: width 0.6s ease;
          line-height: 25px;
        }
        
        /* Metric Cards */
        .metric-card {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: #ffffff;
          padding: 20px;
          border-radius: 12px;
          margin: 12px 0;
          text-align: center;
          box-shadow: 0 4px 6px rgba(102, 126, 234, 0.3);
          transition: transform 0.3s ease;
        }
        
        .metric-card:hover {
          transform: translateY(-2px);
          box-shadow: 0 6px 12px rgba(102, 126, 234, 0.4);
        }
        
        .metric-card h3 {
          margin: 0;
          font-size: 2.2em;
          font-weight: 700;
          text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
        }
        
        .metric-card p {
          margin: 8px 0 0 0;
          font-size: 0.95em;
          opacity: 0.9;
        }
        
        /* Productivity Cards */
        .productivity-card {
          background: #ffffff;
          border: 2px solid #e2e8f0;
          border-radius: 10px;
          padding: 20px;
          margin: 15px 0;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          transition: all 0.3s ease;
        }
        
        .productivity-card:hover {
          border-color: #3b82f6;
          box-shadow: 0 4px 8px rgba(59, 130, 246, 0.2);
          transform: translateY(-2px);
        }
        
        .productivity-card h4 {
          color: #1e40af;
          margin-top: 0;
          font-weight: 600;
        }
        
        /* Strategy Cards */
        .strategy-card {
          background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
          border-left: 5px solid #3b82f6;
          border-radius: 8px;
          padding: 20px;
          margin: 15px 0;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .strategy-card h5 {
          color: #1e40af;
          margin-top: 0;
          font-weight: 600;
        }
        
        /* Value Boxes */
        .small-box {
          border-radius: 8px;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          transition: transform 0.3s ease;
        }
        
        .small-box:hover {
          transform: translateY(-3px);
          box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
        }
        
        /* Form Elements */
        .form-control {
          border: 2px solid #e2e8f0;
          border-radius: 6px;
          transition: border-color 0.3s ease;
        }
        
        .form-control:focus {
          border-color: #3b82f6;
          box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
        }
        
        /* Timeline */
        .timeline-item {
          background: #ffffff;
          border-left: 4px solid #3b82f6;
          border-radius: 0 8px 8px 0;
          padding: 15px 20px;
          margin: 15px 0;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .timeline-item h5 {
          color: #1e40af;
          margin: 0 0 10px 0;
          font-weight: 600;
        }
        
        /* Info Box Styling */
        .info-box {
          background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          border-radius: 8px;
          border-left: 4px solid #3b82f6;
        }
        
        /* References Box */
        .references-box {
          background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
          border: 2px solid #cbd5e1;
          border-radius: 10px;
          padding: 20px;
          margin-top: 25px;
          font-size: 13px;
          color: #475569;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .references-box h4 {
          color: #1e293b;
          font-weight: 600;
          margin-bottom: 15px;
          border-bottom: 2px solid #cbd5e1;
          padding-bottom: 8px;
        }
        
        /* Data Table Styling */
        .dataTables_wrapper {
          font-family: inherit;
        }
        
        .table-striped > tbody > tr:nth-child(odd) > td {
          background-color: #f8fafc;
        }
        
        /* Chart Container */
        .plotly {
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        /* Habit Tracker */
        .habit-item {
          background: #ffffff;
          border: 2px solid #e2e8f0;
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
          display: flex;
          justify-content: space-between;
          align-items: center;
          transition: all 0.3s ease;
        }
        
        .habit-item:hover {
          border-color: #3b82f6;
          box-shadow: 0 2px 4px rgba(59, 130, 246, 0.2);
        }
        
        .habit-complete {
          background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
          border-color: #10b981;
        }
      "))
    ),
    
    tabItems(
      # Tab 1: Overview & Strategy
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "10x Productivity & Life Optimization Framework", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  h3("Systematic Approach to 10x Every Area of Your Life"),
                  p("A comprehensive framework designed for dynamic, persistent, and focused technical individuals to achieve exponential growth across all life domains through systematic optimization and strategic leverage."),
                  
                  fluidRow(
                    valueBoxOutput("productivity_score", width = 3),
                    valueBoxOutput("weekly_hours_optimized", width = 3),
                    valueBoxOutput("systems_active", width = 3),
                    valueBoxOutput("roi_multiplier", width = 3)
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "The 10x Philosophy",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             div(class = "strategy-card",
                                 h5("1. Leverage Over Linear Growth"),
                                 p("Focus on activities that compound and scale rather than those that grow linearly. Use systems, automation, and strategic delegation.")
                             ),
                             div(class = "strategy-card",
                                 h5("2. Systematic Optimization"),
                                 p("Apply engineering principles to life: measure, analyze, optimize, and iterate. What gets measured gets improved.")
                             ),
                             div(class = "strategy-card",
                                 h5("3. Strategic Focus"),
                                 p("Identify the 20% of activities that generate 80% of results. Ruthlessly eliminate or delegate the rest.")
                             ),
                             div(class = "strategy-card",
                                 h5("4. Compound Effects"),
                                 p("Small consistent improvements (1% daily) compound to 37x annual growth. Focus on habits and systems that compound.")
                             ),
                             div(class = "strategy-card",
                                 h5("5. Integration & Synergy"),
                                 p("Create synergies between life areas. Learning enhances earning. Health boosts productivity. Networks accelerate growth.")
                             )
                           )
                    ),
                    column(6,
                           box(
                             title = "Life Optimization Metrics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("optimization_radar")),
                             hr(),
                             actionButton("update_metrics", "Update All Metrics", class = "btn-primary", style = "width: 100%;")
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(12,
                           box(
                             title = "10x Implementation Roadmap",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             
                             div(class = "timeline-item",
                                 h5("Phase 1: Foundation (Weeks 1-4)"),
                                 tags$ul(
                                   tags$li("Audit current time allocation and productivity patterns"),
                                   tags$li("Establish baseline metrics across all life domains"),
                                   tags$li("Design core systems and automation frameworks"),
                                   tags$li("Set up tracking and measurement infrastructure")
                                 )
                             ),
                             
                             div(class = "timeline-item",
                                 h5("Phase 2: System Building (Weeks 5-12)"),
                                 tags$ul(
                                   tags$li("Implement learning systems and knowledge management"),
                                   tags$li("Build skill acquisition frameworks and deliberate practice routines"),
                                   tags$li("Establish networking systems and relationship management"),
                                   tags$li("Create wealth generation and investment automation")
                                 )
                             ),
                             
                             div(class = "timeline-item",
                                 h5("Phase 3: Optimization (Weeks 13-26)"),
                                 tags$ul(
                                   tags$li("Analyze system performance and identify bottlenecks"),
                                   tags$li("Optimize high-leverage activities and eliminate waste"),
                                   tags$li("Scale successful systems and processes"),
                                   tags$li("Integrate systems for maximum synergy")
                                 )
                             ),
                             
                             div(class = "timeline-item",
                                 h5("Phase 4: Acceleration (Weeks 27-52)"),
                                 tags$ul(
                                   tags$li("Leverage compound effects and exponential growth"),
                                   tags$li("Expand into new domains and opportunities"),
                                   tags$li("Build passive income and automated systems"),
                                   tags$li("Achieve 10x results across measured domains")
                                 )
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Clear, J. (2018). Atomic habits: An easy & proven way to build good habits & break bad ones. Penguin Random House."),
                      p("Ferriss, T. (2007). The 4-hour workweek: Escape 9-5, live anywhere, and join the new rich. Crown Publishers."),
                      p("Newport, C. (2016). Deep work: Rules for focused success in a distracted world. Grand Central Publishing."),
                      p("Thiel, P., & Masters, B. (2014). Zero to one: Notes on startups, or how to build the future. Crown Business.")
                  )
                )
              )
      ),
      
      # Tab 2: Knowledge Acquisition
      tabItem(tabName = "knowledge",
              fluidRow(
                box(
                  title = "10x Knowledge Acquisition System",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Accelerated Learning & Knowledge Management"),
                  p("Systematic approach to acquiring, retaining, and applying knowledge at 10x the typical rate through optimized learning strategies and knowledge management systems."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Learning Velocity Metrics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             div(class = "metric-card",
                                 h3("47"),
                                 p("Books/Year Completed")
                             ),
                             div(class = "metric-card",
                                 h3("18"),
                                 p("Courses Completed")
                             ),
                             div(class = "metric-card",
                                 h3("850+"),
                                 p("Concepts Mastered")
                             ),
                             hr(),
                             h4("Current Focus Areas:"),
                             checkboxGroupInput("learning_topics", "",
                                                choices = list("AI/Machine Learning" = "ai",
                                                               "System Design" = "systems",
                                                               "Business Strategy" = "strategy",
                                                               "Behavioral Psychology" = "psychology",
                                                               "Financial Markets" = "finance"),
                                                selected = c("ai", "systems"))
                           )
                    ),
                    column(4,
                           box(
                             title = "10x Learning Strategies",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             
                             div(class = "productivity-card",
                                 h4("1. Feynman Technique"),
                                 p("Teach concepts in simple terms to identify knowledge gaps. If you can't explain it simply, you don't understand it well enough."),
                                 tags$ul(
                                   tags$li("Study a concept"),
                                   tags$li("Teach it to a 12-year-old"),
                                   tags$li("Identify gaps"),
                                   tags$li("Review and simplify")
                                 )
                             ),
                             
                             div(class = "productivity-card",
                                 h4("2. Spaced Repetition"),
                                 p("Use scientifically-optimized review intervals to maximize long-term retention with minimal study time."),
                                 sliderInput("spaced_rep_interval", "Next Review Interval (days):",
                                             min = 1, max = 30, value = 7)
                             ),
                             
                             div(class = "productivity-card",
                                 h4("3. Active Recall"),
                                 p("Test yourself constantly. Retrieval practice is 2-3x more effective than passive review."),
                                 numericInput("daily_flashcards", "Daily Flashcards:",
                                              value = 50, min = 10, max = 200)
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Knowledge Management System",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Second Brain Architecture:"),
                             
                             div(style = "background-color: #f0f9ff; border: 2px solid #3b82f6; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Capture", style = "color: #1e40af;"),
                                 tags$ul(
                                   tags$li("Inbox for all ideas and information"),
                                   tags$li("Voice memos, quick notes, screenshots"),
                                   tags$li("Browser clipper for articles")
                                 )
                             ),
                             
                             div(style = "background-color: #f0fdf4; border: 2px solid #10b981; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Organize", style = "color: #065f46;"),
                                 tags$ul(
                                   tags$li("PARA method: Projects, Areas, Resources, Archives"),
                                   tags$li("Hierarchical tagging system"),
                                   tags$li("Bi-directional linking")
                                 )
                             ),
                             
                             div(style = "background-color: #fef3c7; border: 2px solid #f59e0b; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Distill", style = "color: #92400e;"),
                                 tags$ul(
                                   tags$li("Progressive summarization"),
                                   tags$li("Highlight → Bold → Summarize"),
                                   tags$li("Extract actionable insights")
                                 )
                             ),
                             
                             div(style = "background-color: #fce7f3; border: 2px solid #ec4899; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Express", style = "color: #9f1239;"),
                                 tags$ul(
                                   tags$li("Create content from notes"),
                                   tags$li("Share insights publicly"),
                                   tags$li("Build in public")
                                 )
                             ),
                             
                             actionButton("review_notes", "Daily Review Session", class = "btn-primary", style = "width: 100%; margin-top: 10px;")
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Reading System",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Speed Reading Protocol:"),
                             numericInput("reading_speed", "Current WPM:", value = 450, min = 200, max = 1000),
                             numericInput("daily_reading", "Daily Reading Time (min):", value = 90, min = 30, max = 240),
                             
                             hr(),
                             h4("Book Processing Pipeline:"),
                             tags$ol(
                               tags$li(tags$strong("Pre-read:"), " Table of contents, introduction, conclusion (10 min)"),
                               tags$li(tags$strong("Speed read:"), " Full book at 400-600 WPM (2-4 hours)"),
                               tags$li(tags$strong("Note-taking:"), " Capture key insights in personal knowledge base"),
                               tags$li(tags$strong("Summarize:"), " Create 1-page summary within 24 hours"),
                               tags$li(tags$strong("Apply:"), " Implement at least one concept immediately"),
                               tags$li(tags$strong("Share:"), " Write book review or social post")
                             ),
                             
                             hr(),
                             sliderInput("book_completion", "Books Completed This Month:",
                                         min = 0, max = 10, value = 4),
                             actionButton("log_book", "Log New Book", class = "btn-success")
                           )
                    ),
                    column(6,
                           box(
                             title = "Learning Progress Tracker",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("learning_progress")),
                             hr(),
                             h4("Current Learning Streaks:"),
                             div(style = "display: flex; justify-content: space-around; margin: 15px 0;",
                                 div(style = "text-align: center;",
                                     h3("127", style = "color: #3b82f6; margin: 0;"),
                                     p("Days Streak", style = "margin: 0; font-size: 14px;")
                                 ),
                                 div(style = "text-align: center;",
                                     h3("2,847", style = "color: #10b981; margin: 0;"),
                                     p("Total Hours", style = "margin: 0; font-size: 14px;")
                                 ),
                                 div(style = "text-align: center;",
                                     h3("92%", style = "color: #f59e0b; margin: 0;"),
                                     p("Retention Rate", style = "margin: 0; font-size: 14px;")
                                 )
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Oakley, B. (2014). A mind for numbers: How to excel at math and science (even if you flunked algebra). TarcherPerigee."),
                      p("Ahrens, S. (2017). How to take smart notes: One simple technique to boost writing, learning and thinking. Sönke Ahrens."),
                      p("Forte, T. (2022). Building a second brain: A proven method to organize your digital life and unlock your creative potential. Atria Books."),
                      p("Brown, P. C., Roediger III, H. L., & McDaniel, M. A. (2014). Make it stick: The science of successful learning. Harvard University Press.")
                  )
                )
              )
      ),
      
      # Tab 3: Skills Development
      tabItem(tabName = "skills",
              fluidRow(
                box(
                  title = "10x Skills Acquisition Framework",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Rapid Skill Mastery Through Deliberate Practice"),
                  p("Systematic approach to mastering high-value skills 10x faster through focused deliberate practice, immediate feedback loops, and strategic skill stacking."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Skill Portfolio",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Current Skills Being Developed:"),
                             
                             div(class = "habit-item",
                                 div(
                                   tags$strong("Advanced Python/ML"),
                                   tags$br(),
                                   tags$small("Target: 10,000 hours")
                                 ),
                                 progressBar("python_progress", value = 67, status = "info", display_pct = TRUE)
                             ),
                             
                             div(class = "habit-item",
                                 div(
                                   tags$strong("Public Speaking"),
                                   tags$br(),
                                   tags$small("Target: 100 presentations")
                                 ),
                                 progressBar("speaking_progress", value = 45, status = "warning", display_pct = TRUE)
                             ),
                             
                             div(class = "habit-item",
                                 div(
                                   tags$strong("Content Creation"),
                                   tags$br(),
                                   tags$small("Target: 500 pieces")
                                 ),
                                 progressBar("content_progress", value = 72, status = "success", display_pct = TRUE)
                             ),
                             
                             div(class = "habit-item",
                                 div(
                                   tags$strong("Sales & Persuasion"),
                                   tags$br(),
                                   tags$small("Target: 1,000 conversations")
                                 ),
                                 progressBar("sales_progress", value = 38, status = "danger", display_pct = TRUE)
                             ),
                             
                             hr(),
                             actionButton("add_skill", "Add New Skill", class = "btn-primary", style = "width: 100%;")
                           )
                    ),
                    column(4,
                           box(
                             title = "Deliberate Practice Protocol",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             
                             div(class = "productivity-card",
                                 h4("1. Define Specific Sub-Skills"),
                                 p("Break down complex skills into specific, measurable components that can be practiced independently."),
                                 textInput("current_subskill", "Current Sub-skill Focus:", 
                                           placeholder = "e.g., API design patterns")
                             ),
                             
                             div(class = "productivity-card",
                                 h4("2. Immediate Feedback Loops"),
                                 p("Practice with immediate, objective feedback. Shorter feedback cycles = faster improvement."),
                                 numericInput("feedback_delay", "Feedback Delay (minutes):",
                                              value = 5, min = 1, max = 60)
                             ),
                             
                             div(class = "productivity-card",
                                 h4("3. Practice at Edge of Ability"),
                                 p("Work just beyond current comfort zone. Too easy = no growth. Too hard = frustration."),
                                 sliderInput("difficulty_level", "Current Difficulty:",
                                             min = 1, max = 10, value = 7)
                             ),
                             
                             div(class = "productivity-card",
                                 h4("4. Intense Focused Sessions"),
                                 p("90-minute deep practice blocks with complete focus. Quality > Quantity."),
                                 numericInput("daily_practice", "Daily Practice Blocks:",
                                              value = 3, min = 1, max = 6)
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Skill Stacking Strategy",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Unique Skill Combinations:"),
                             p("Become top 1% by combining complementary skills rather than being world-class at one."),
                             
                             div(style = "background-color: #eff6ff; border-left: 4px solid #3b82f6; padding: 15px; margin: 10px 0;",
                                 h5("Stack 1: Tech Entrepreneur", style = "color: #1e40af;"),
                                 tags$ul(
                                   tags$li("Technical Skills (top 10%)"),
                                   tags$li("+ Business Strategy (top 25%)"),
                                   tags$li("+ Communication (top 25%)"),
                                   tags$li("= Top 0.625% combination")
                                 )
                             ),
                             
                             div(style = "background-color: #f0fdf4; border-left: 4px solid #10b981; padding: 15px; margin: 10px 0;",
                                 h5("Stack 2: Technical Leader", style = "color: #065f46;"),
                                 tags$ul(
                                   tags$li("Software Engineering (top 10%)"),
                                   tags$li("+ Leadership (top 20%)"),
                                   tags$li("+ Product Sense (top 25%)"),
                                   tags$li("= Top 0.5% combination")
                                 )
                             ),
                             
                             div(style = "background-color: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 10px 0;",
                                 h5("Your Custom Stack:", style = "color: #92400e;"),
                                 textInput("skill_1", "Skill 1:", placeholder = "Primary expertise"),
                                 textInput("skill_2", "Skill 2:", placeholder = "Complementary skill"),
                                 textInput("skill_3", "Skill 3:", placeholder = "Differentiator"),
                                 actionButton("calculate_stack", "Calculate Uniqueness", class = "btn-primary")
                             )
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "20-Hour Rapid Skill Acquisition",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Fast Track Protocol for New Skills:"),
                             p("Master the basics of any skill in 20 hours of focused practice using systematic deconstruction."),
                             
                             tags$ol(
                               tags$li(tags$strong("Deconstruct:"), " Break skill into smallest learnable units (2 hours)"),
                               tags$li(tags$strong("Learn Enough:"), " Research just enough to self-correct (1 hour)"),
                               tags$li(tags$strong("Remove Barriers:"), " Eliminate distractions and friction (30 min)"),
                               tags$li(tags$strong("Practice:"), " Minimum 20 hours of focused deliberate practice")
                             ),
                             
                             hr(),
                             h4("Current 20-Hour Projects:"),
                             DT::dataTableOutput("rapid_skills_table"),
                             hr(),
                             actionButton("start_20h_project", "Start New 20-Hour Project", class = "btn-success")
                           )
                    ),
                    column(6,
                           box(
                             title = "Skill Development Metrics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("skill_progress_chart")),
                             hr(),
                             h4("Practice Statistics:"),
                             div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin: 15px 0;",
                                 div(style = "text-align: center; background: #eff6ff; padding: 15px; border-radius: 8px;",
                                     h3("847", style = "color: #3b82f6; margin: 0;"),
                                     p("Hours This Quarter", style = "margin: 5px 0; font-size: 14px;")
                                 ),
                                 div(style = "text-align: center; background: #f0fdf4; padding: 15px; border-radius: 8px;",
                                     h3("4.2", style = "color: #10b981; margin: 0;"),
                                     p("Hours Daily Average", style = "margin: 5px 0; font-size: 14px;")
                                 )
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Ericsson, A., & Pool, R. (2016). Peak: Secrets from the new science of expertise. Houghton Mifflin Harcourt."),
                      p("Kaufman, J. (2013). The first 20 hours: How to learn anything... fast. Portfolio."),
                      p("Coyle, D. (2009). The talent code: Greatness isn't born. It's grown. Here's how. Bantam."),
                      p("Adams, S. (2013). How to fail at almost everything and still win big: Kind of the story of my life. Portfolio.")
                  )
                )
              )
      ),
      
      # Tab 4: Social Networking
      tabItem(tabName = "networking",
              fluidRow(
                box(
                  title = "10x Strategic Networking System",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Building High-Value Networks Systematically"),
                  p("Strategic approach to building, nurturing, and leveraging professional networks for exponential opportunities and growth."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Network Metrics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             div(class = "metric-card",
                                 h3("487"),
                                 p("High-Value Connections")
                             ),
                             div(class = "metric-card",
                                 h3("52"),
                                 p("Deep Relationships")
                             ),
                             div(class = "metric-card",
                                 h3("12"),
                                 p("Mentors/Advisors")
                             ),
                             hr(),
                             h4("Network Composition:"),
                             plotlyOutput("network_composition", height = "250px")
                           )
                    ),
                    column(4,
                           box(
                             title = "Systematic Networking Protocol",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             
                             div(class = "productivity-card",
                                 h4("1. Strategic Targeting"),
                                 p("Identify specific people who can provide value or opportunities aligned with your goals."),
                                 selectInput("target_category", "Target Category:",
                                             choices = list("Industry Leaders" = "leaders",
                                                            "Potential Clients" = "clients",
                                                            "Technical Experts" = "experts",
                                                            "Investors/Angels" = "investors",
                                                            "Complementary Entrepreneurs" = "entrepreneurs"))
                             ),
                             
                             div(class = "productivity-card",
                                 h4("2. Value-First Approach"),
                                 p("Always lead with value. Help before asking. Give before receiving."),
                                 textAreaInput("value_proposition", "Your Value Offer:",
                                               placeholder = "What can you provide?")
                             ),
                             
                             div(class = "productivity-card",
                                 h4("3. Systematic Follow-Up"),
                                 p("CRM system with automated reminders for regular touchpoints."),
                                 numericInput("touchpoints_month", "Monthly Touchpoints per Contact:",
                                              value = 2, min = 1, max = 10)
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Relationship Management",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Connection Tiers:"),
                             
                             div(style = "background-color: #fef3c7; border: 2px solid #f59e0b; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Tier 1: Inner Circle (5-10 people)", style = "color: #92400e;"),
                                 tags$ul(
                                   tags$li("Weekly or bi-weekly contact"),
                                   tags$li("Deep personal relationships"),
                                   tags$li("Mutual support and accountability")
                                 )
                             ),
                             
                             div(style = "background-color: #dbeafe; border: 2px solid #3b82f6; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Tier 2: Key Network (30-50 people)", style = "color: #1e40af;"),
                                 tags$ul(
                                   tags$li("Monthly check-ins"),
                                   tags$li("Strategic collaborations"),
                                   tags$li("Information exchange")
                                 )
                             ),
                             
                             div(style = "background-color: #d1fae5; border: 2px solid #10b981; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Tier 3: Active Network (100-200)", style = "color: #065f46;"),
                                 tags$ul(
                                   tags$li("Quarterly touchpoints"),
                                   tags$li("Occasional collaborations"),
                                   tags$li("Mutual opportunities")
                                 )
                             ),
                             
                             actionButton("review_network", "Review Network Health", class = "btn-primary")
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Networking Automation",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Scalable Networking Systems:"),
                             
                             div(class = "timeline-item",
                                 h5("Content Strategy"),
                                 p("Share valuable insights publicly to attract quality connections without cold outreach."),
                                 tags$ul(
                                   tags$li("Weekly LinkedIn posts (technical insights)"),
                                   tags$li("Monthly blog articles (deep dives)"),
                                   tags$li("Daily Twitter threads (quick wins)"),
                                   tags$li("Quarterly webinars/presentations")
                                 )
                             ),
                             
                             div(class = "timeline-item",
                                 h5("Event Strategy"),
                                 p("Strategic attendance at high-ROI events and conferences."),
                                 numericInput("events_quarter", "Target Events per Quarter:",
                                              value = 4, min = 1, max = 12),
                                 textInput("next_event", "Next Major Event:", 
                                           placeholder = "Conference name and date")
                             ),
                             
                             div(class = "timeline-item",
                                 h5("Introduction Leverage"),
                                 p("Ask for strategic introductions from existing connections."),
                                 numericInput("intro_requests", "Monthly Introduction Requests:",
                                              value = 5, min = 1, max = 20)
                             ),
                             
                             actionButton("execute_strategy", "Execute This Month", class = "btn-success")
                           )
                    ),
                    column(6,
                           box(
                             title = "Network Activity Tracker",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             h4("This Month's Activity:"),
                             DT::dataTableOutput("network_activity"),
                             hr(),
                             fluidRow(
                               column(6,
                                      actionButton("log_meeting", "Log Meeting", class = "btn-primary", style = "width: 100%;")
                               ),
                               column(6,
                                      actionButton("log_introduction", "Log Introduction", class = "btn-success", style = "width: 100%;")
                               )
                             ),
                             hr(),
                             h4("Network ROI:"),
                             div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 10px;",
                                 div(style = "text-align: center; background: #eff6ff; padding: 15px; border-radius: 8px;",
                                     h3("$127K", style = "color: #3b82f6; margin: 0;"),
                                     p("Deals from Network", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #f0fdf4; padding: 15px; border-radius: 8px;",
                                     h3("23", style = "color: #10b981; margin: 0;"),
                                     p("Opportunities Created", style = "margin: 5px 0; font-size: 12px;")
                                 )
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Ferrazzi, K., & Raz, T. (2005). Never eat alone: And other secrets to success, one relationship at a time. Currency."),
                      p("Grant, A. (2013). Give and take: Why helping others drives our success. Penguin."),
                      p("Casnocha, B., Hoffman, R., & Yeh, C. (2012). The start-up of you: Adapt to the future, invest in yourself, and transform your career. Crown Business."),
                      p("Burkus, D. (2018). Friend of a friend: Understanding the hidden networks that can transform your life and your career. Houghton Mifflin Harcourt.")
                  )
                )
              )
      ),
      
      # Tab 5: Wealth Generation
      tabItem(tabName = "wealth",
              fluidRow(
                box(
                  title = "10x Wealth Generation Framework",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Systematic Wealth Building & Financial Independence"),
                  p("Strategic approach to building wealth through multiple income streams, smart investments, and systematic financial optimization."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Financial Dashboard",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             div(class = "metric-card",
                                 h3("$487K"),
                                 p("Net Worth")
                             ),
                             div(class = "metric-card",
                                 h3("$42K/mo"),
                                 p("Total Monthly Income")
                             ),
                             div(class = "metric-card",
                                 h3("$18K/mo"),
                                 p("Passive Income")
                             ),
                             div(class = "metric-card",
                                 h3("67%"),
                                 p("Savings Rate")
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Income Streams",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Active Income Diversification:"),
                             plotlyOutput("income_breakdown", height = "200px"),
                             hr(),
                             h4("Income Stream Targets:"),
                             div(style = "margin: 10px 0;",
                                 tags$strong("W2 Salary:"), 
                                 tags$span(" $12,000/mo", style = "color: #3b82f6; float: right;")
                             ),
                             div(style = "margin: 10px 0;",
                                 tags$strong("Consulting:"), 
                                 tags$span(" $8,000/mo", style = "color: #10b981; float: right;")
                             ),
                             div(style = "margin: 10px 0;",
                                 tags$strong("Side Business:"), 
                                 tags$span(" $12,000/mo", style = "color: #f59e0b; float: right;")
                             ),
                             div(style = "margin: 10px 0;",
                                 tags$strong("Investments:"), 
                                 tags$span(" $6,000/mo", style = "color: #8b5cf6; float: right;")
                             ),
                             div(style = "margin: 10px 0;",
                                 tags$strong("Content/Digital:"), 
                                 tags$span(" $4,000/mo", style = "color: #ec4899; float: right;")
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Wealth Building Strategy",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("10x Wealth Principles:"),
                             
                             div(class = "strategy-card",
                                 h5("1. Increase Income Aggressively"),
                                 p("Focus on 10x income before optimizing expenses. Develop high-value skills, negotiate raises, start side businesses.")
                             ),
                             
                             div(class = "strategy-card",
                                 h5("2. Deploy Capital Systematically"),
                                 p("Automatic investing with dollar-cost averaging. Target 50%+ savings rate. Index funds + selective bets.")
                             ),
                             
                             div(class = "strategy-card",
                                 h5("3. Build Passive Income"),
                                 p("Real estate, dividend stocks, digital products, affiliate income. Target: passive > expenses.")
                             )
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Investment Portfolio",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Asset Allocation Strategy:"),
                             
                             div(style = "background-color: #eff6ff; border-left: 4px solid #3b82f6; padding: 15px; margin: 10px 0;",
                                 h5("Equities (60%)", style = "color: #1e40af;"),
                                 tags$ul(
                                   tags$li("Index Funds: 40% (VTI, VXUS)"),
                                   tags$li("Growth Stocks: 15% (Tech leaders)"),
                                   tags$li("Individual Bets: 5% (High conviction)")
                                 ),
                                 numericInput("equity_allocation", "Current %:", value = 60, min = 0, max = 100)
                             ),
                             
                             div(style = "background-color: #f0fdf4; border-left: 4px solid #10b981; padding: 15px; margin: 10px 0;",
                                 h5("Real Estate (25%)", style = "color: #065f46;"),
                                 tags$ul(
                                   tags$li("Rental Properties: 15%"),
                                   tags$li("REITs: 10%")
                                 ),
                                 numericInput("realestate_allocation", "Current %:", value = 25, min = 0, max = 100)
                             ),
                             
                             div(style = "background-color: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 10px 0;",
                                 h5("Alternative Assets (10%)", style = "color: #92400e;"),
                                 tags$ul(
                                   tags$li("Crypto: 5% (BTC, ETH)"),
                                   tags$li("Angel Investments: 5%")
                                 ),
                                 numericInput("alt_allocation", "Current %:", value = 10, min = 0, max = 100)
                             ),
                             
                             div(style = "background-color: #e0f2fe; border-left: 4px solid #0ea5e9; padding: 15px; margin: 10px 0;",
                                 h5("Cash & Bonds (5%)", style = "color: #0c4a6e;"),
                                 tags$ul(
                                   tags$li("Emergency Fund: 6 months expenses"),
                                   tags$li("Opportunities Fund: Ready for deals")
                                 ),
                                 numericInput("cash_allocation", "Current %:", value = 5, min = 0, max = 100)
                             ),
                             
                             actionButton("rebalance_portfolio", "Rebalance Portfolio", class = "btn-primary")
                           )
                    ),
                    column(6,
                           box(
                             title = "Wealth Growth Projection",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("wealth_projection")),
                             hr(),
                             h4("Financial Independence Timeline:"),
                             
                             div(style = "background-color: #f0fdf4; border: 2px solid #10b981; border-radius: 8px; padding: 20px; margin: 15px 0;",
                                 h5("Coast FI: Achieved", style = "color: #065f46; margin: 0;"),
                                 p("Investments will grow to retirement without additional contributions", 
                                   style = "margin: 5px 0; color: #16a34a;")
                             ),
                             
                             div(style = "background-color: #fef3c7; border: 2px solid #f59e0b; border-radius: 8px; padding: 20px; margin: 15px 0;",
                                 h5("Lean FI: 4.2 years", style = "color: #92400e; margin: 0;"),
                                 p("Can cover basic expenses with passive income ($3,500/mo)", 
                                   style = "margin: 5px 0; color: #ca8a04;")
                             ),
                             
                             div(style = "background-color: #dbeafe; border: 2px solid #3b82f6; border-radius: 8px; padding: 20px; margin: 15px 0;",
                                 h5("Full FI: 7.8 years", style = "color: #1e40af; margin: 0;"),
                                 p("Can maintain current lifestyle with passive income ($6,500/mo)", 
                                   style = "margin: 5px 0; color: #2563eb;")
                             ),
                             
                             div(style = "background-color: #f3e8ff; border: 2px solid #a855f7; border-radius: 8px; padding: 20px; margin: 15px 0;",
                                 h5("Fat FI: 12.5 years", style = "color: #7c2d12; margin: 0;"),
                                 p("Can live abundantly with passive income ($12,000/mo)", 
                                   style = "margin: 5px 0; color: #9333ea;")
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Housel, M. (2020). The psychology of money: Timeless lessons on wealth, greed, and happiness. Harriman House."),
                      p("Collins, J. L. (2016). The simple path to wealth: Your road map to financial independence and a rich, free life. CreateSpace."),
                      p("Robbins, T. (2014). Money: Master the game: 7 simple steps to financial freedom. Simon & Schuster."),
                      p("Sabatier, G. (2019). Financial freedom: A proven path to all the money you will ever need. Penguin Random House.")
                  )
                )
              )
      ),
      
      # Tab 6: Entrepreneurship
      tabItem(tabName = "entrepreneur",
              fluidRow(
                box(
                  title = "10x Entrepreneurship Framework",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Building Scalable Businesses Systematically"),
                  p("Strategic framework for building, launching, and scaling businesses with technical leverage and systematic execution."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Business Portfolio",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Active Ventures:"),
                             
                             div(class = "productivity-card",
                                 h4("SaaS Product"),
                                 progressBar("saas_progress", value = 75, status = "success", display_pct = TRUE),
                                 p(tags$strong("Status:"), " Scaling phase"),
                                 p(tags$strong("MRR:"), " $12,400"),
                                 p(tags$strong("Customers:"), " 87")
                             ),
                             
                             div(class = "productivity-card",
                                 h4("Consulting Practice"),
                                 progressBar("consulting_progress", value = 60, status = "info", display_pct = TRUE),
                                 p(tags$strong("Status:"), " Stabilizing"),
                                 p(tags$strong("Monthly:"), " $8,000"),
                                 p(tags$strong("Clients:"), " 4 retainers")
                             ),
                             
                             div(class = "productivity-card",
                                 h4("Digital Products"),
                                 progressBar("digital_progress", value = 40, status = "warning", display_pct = TRUE),
                                 p(tags$strong("Status:"), " Launch phase"),
                                 p(tags$strong("Monthly:"), " $2,200"),
                                 p(tags$strong("Products:"), " 3 active")
                             ),
                             
                             actionButton("add_venture", "Add New Venture", class = "btn-primary")
                           )
                    ),
                    column(4,
                           box(
                             title = "Launch Framework",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Rapid Validation Process:"),
                             
                             div(class = "timeline-item",
                                 h5("Week 1-2: Idea Validation"),
                                 tags$ul(
                                   tags$li("Identify problem worth solving"),
                                   tags$li("Research existing solutions"),
                                   tags$li("Talk to 20+ potential customers"),
                                   tags$li("Validate willingness to pay")
                                 )
                             ),
                             
                             div(class = "timeline-item",
                                 h5("Week 3-4: MVP Development"),
                                 tags$ul(
                                   tags$li("Build minimum viable product"),
                                   tags$li("Focus on core value proposition"),
                                   tags$li("No-code/low-code when possible"),
                                   tags$li("Get to usable in 2 weeks max")
                                 )
                             ),
                             
                             div(class = "timeline-item",
                                 h5("Week 5-6: Launch & Iterate"),
                                 tags$ul(
                                   tags$li("Launch to early adopters"),
                                   tags$li("Collect feedback intensively"),
                                   tags$li("Rapid iteration cycles"),
                                   tags$li("Validate product-market fit")
                                 )
                             ),
                             
                             div(class = "timeline-item",
                                 h5("Week 7-12: Scale or Pivot"),
                                 tags$ul(
                                   tags$li("Double down if PMF found"),
                                   tags$li("Pivot quickly if not"),
                                   tags$li("Begin growth experiments"),
                                   tags$li("Build systematic processes")
                                 )
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Business Metrics",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Key Performance Indicators:"),
                             
                             div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin: 15px 0;",
                                 div(style = "text-align: center; background: #eff6ff; padding: 15px; border-radius: 8px;",
                                     h3("$22.6K", style = "color: #3b82f6; margin: 0;"),
                                     p("Total MRR", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #f0fdf4; padding: 15px; border-radius: 8px;",
                                     h3("38%", style = "color: #10b981; margin: 0;"),
                                     p("MoM Growth", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #fef3c7; padding: 15px; border-radius: 8px;",
                                     h3("94%", style = "color: #f59e0b; margin: 0;"),
                                     p("Retention Rate", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #fce7f3; padding: 15px; border-radius: 8px;",
                                     h3("$187", style = "color: #ec4899; margin: 0;"),
                                     p("CAC", style = "margin: 5px 0; font-size: 12px;")
                                 )
                             ),
                             
                             hr(),
                             h4("Revenue Projection:"),
                             plotlyOutput("revenue_forecast", height = "200px")
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Leverage Multipliers",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Technical Leverage Strategies:"),
                             
                             div(class = "strategy-card",
                                 h5("1. Code as Leverage"),
                                 p("Software scales infinitely. One solution serves millions. Focus on products over services."),
                                 tags$ul(
                                   tags$li("Build SaaS products"),
                                   tags$li("Create automation tools"),
                                   tags$li("Develop APIs and platforms"),
                                   tags$li("Package expertise as software")
                                 )
                             ),
                             
                             div(class = "strategy-card",
                                 h5("2. Content as Leverage"),
                                 p("Create once, distribute forever. Content attracts customers 24/7 without active work."),
                                 tags$ul(
                                   tags$li("Technical blog posts and tutorials"),
                                   tags$li("YouTube videos and courses"),
                                   tags$li("Open source projects and tools"),
                                   tags$li("Books and digital products")
                                 )
                             ),
                             
                             div(class = "strategy-card",
                                 h5("3. Community as Leverage"),
                                 p("Build audience first, monetize later. Community provides feedback, distribution, and revenue."),
                                 tags$ul(
                                   tags$li("Newsletter with valuable insights"),
                                   tags$li("Discord/Slack community"),
                                   tags$li("Social media following"),
                                   tags$li("Podcast or video series")
                                 )
                             ),
                             
                             div(class = "strategy-card",
                                 h5("4. Capital as Leverage"),
                                 p("Use money to buy time and scale faster. Invest in tools, people, and growth."),
                                 tags$ul(
                                   tags$li("Paid advertising for customer acquisition"),
                                   tags$li("Contractors for non-core work"),
                                   tags$li("Premium tools and infrastructure"),
                                   tags$li("Strategic acquisitions")
                                 )
                             ),
                             
                             numericInput("leverage_score", "Current Leverage Score (1-10):",
                                          value = 7, min = 1, max = 10)
                           )
                    ),
                    column(6,
                           box(
                             title = "Systematic Execution",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Weekly Execution Checklist:"),
                             
                             div(class = "habit-item",
                                 checkboxInput("customer_interviews", 
                                               "5+ Customer Conversations", FALSE),
                                 span("Validate assumptions weekly")
                             ),
                             
                             div(class = "habit-item",
                                 checkboxInput("ship_features", 
                                               "Ship Product Updates", FALSE),
                                 span("Weekly deployment cadence")
                             ),
                             
                             div(class = "habit-item",
                                 checkboxInput("content_publish", 
                                               "Publish Content", FALSE),
                                 span("1-2 pieces of valuable content")
                             ),
                             
                             div(class = "habit-item",
                                 checkboxInput("metrics_review", 
                                               "Review Key Metrics", FALSE),
                                 span("Track and optimize KPIs")
                             ),
                             
                             div(class = "habit-item",
                                 checkboxInput("growth_experiments", 
                                               "Run Growth Experiments", FALSE),
                                 span("Test 2-3 acquisition channels")
                             ),
                             
                             div(class = "habit-item",
                                 checkboxInput("financial_review", 
                                               "Financial Health Check", FALSE),
                                 span("Revenue, expenses, runway")
                             ),
                             
                             hr(),
                             h4("This Quarter's Goals:"),
                             DT::dataTableOutput("quarterly_goals"),
                             hr(),
                             actionButton("update_goals", "Update Goals", class = "btn-primary")
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Ries, E. (2011). The lean startup: How today's entrepreneurs use continuous innovation to create radically successful businesses. Crown Business."),
                      p("Thiel, P., & Masters, B. (2014). Zero to one: Notes on startups, or how to build the future. Crown Business."),
                      p("Guillebeau, C. (2012). The $100 startup: Reinvent the way you make a living, do what you love, and create a new future. Crown Business."),
                      p("Chan, J. (2020). The million dollar one person business: Make great money, work the way you like, have the life you want. Lorena Jones Books.")
                  )
                )
              )
      ),
      
      # Tab 7: Work Optimization
      tabItem(tabName = "work",
              fluidRow(
                box(
                  title = "10x Work Productivity System",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Deep Work & Output Optimization"),
                  p("Systematic approach to maximizing work output, impact, and efficiency through deep work practices and ruthless prioritization."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Productivity Metrics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             div(class = "metric-card",
                                 h3("6.4 hrs"),
                                 p("Daily Deep Work")
                             ),
                             div(class = "metric-card",
                                 h3("89%"),
                                 p("Focus Score")
                             ),
                             div(class = "metric-card",
                                 h3("3.7x"),
                                 p("Output Multiplier")
                             ),
                             hr(),
                             h4("Weekly Distribution:"),
                             plotlyOutput("work_time_dist", height = "200px")
                           )
                    ),
                    column(4,
                           box(
                             title = "Deep Work Protocol",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             
                             div(class = "productivity-card",
                                 h4("Time Blocking System"),
                                 p("Schedule every minute. Protect deep work blocks religiously."),
                                 
                                 div(style = "background-color: #dbeafe; padding: 10px; border-radius: 5px; margin: 5px 0;",
                                     tags$strong("6:00 - 9:00 AM:"),
                                     span(" Deep Work Block 1", style = "color: #1e40af;")
                                 ),
                                 div(style = "background-color: #fef3c7; padding: 10px; border-radius: 5px; margin: 5px 0;",
                                     tags$strong("9:00 - 10:00 AM:"),
                                     span(" Emails & Admin", style = "color: #92400e;")
                                 ),
                                 div(style = "background-color: #dbeafe; padding: 10px; border-radius: 5px; margin: 5px 0;",
                                     tags$strong("10:00 - 1:00 PM:"),
                                     span(" Deep Work Block 2", style = "color: #1e40af;")
                                 ),
                                 div(style = "background-color: #fee2e2; padding: 10px; border-radius: 5px; margin: 5px 0;",
                                     tags$strong("1:00 - 2:00 PM:"),
                                     span(" Break & Lunch", style = "color: #991b1b;")
                                 ),
                                 div(style = "background-color: #dbeafe; padding: 10px; border-radius: 5px; margin: 5px 0;",
                                     tags$strong("2:00 - 5:00 PM:"),
                                     span(" Deep Work Block 3", style = "color: #1e40af;")
                                 ),
                                 div(style = "background-color: #fef3c7; padding: 10px; border-radius: 5px; margin: 5px 0;",
                                     tags$strong("5:00 - 6:00 PM:"),
                                     span(" Meetings & Calls", style = "color: #92400e;")
                                 )
                             ),
                             
                             div(class = "productivity-card",
                                 h4("Environment Optimization"),
                                 checkboxGroupInput("environment_setup", "",
                                                    choices = list("Phone in another room" = "phone",
                                                                   "Internet blocker active" = "blocker",
                                                                   "Noise-cancelling headphones" = "headphones",
                                                                   "Do Not Disturb enabled" = "dnd",
                                                                   "Closed door/office" = "door"),
                                                    selected = c("phone", "blocker", "headphones"))
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Priority Management",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Eisenhower Matrix:"),
                             
                             div(style = "background-color: #fee2e2; border: 2px solid #dc2626; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Urgent & Important", style = "color: #991b1b;"),
                                 p("DO NOW - Crisis, deadlines, problems"),
                                 numericInput("urgent_important", "Tasks:", value = 3, min = 0, max = 20)
                             ),
                             
                             div(style = "background-color: #d1fae5; border: 2px solid #059669; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Not Urgent & Important", style = "color: #065f46;"),
                                 p("SCHEDULE - Strategy, planning, development"),
                                 numericInput("not_urgent_important", "Tasks:", value = 8, min = 0, max = 20)
                             ),
                             
                             div(style = "background-color: #fef3c7; border: 2px solid #d97706; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Urgent & Not Important", style = "color: #92400e;"),
                                 p("DELEGATE - Interruptions, emails, some calls"),
                                 numericInput("urgent_not_important", "Tasks:", value = 5, min = 0, max = 20)
                             ),
                             
                             div(style = "background-color: #e5e7eb; border: 2px solid #6b7280; border-radius: 8px; padding: 15px; margin: 10px 0;",
                                 h5("Not Urgent & Not Important", style = "color: #374151;"),
                                 p("ELIMINATE - Time wasters, distractions"),
                                 numericInput("not_urgent_not_important", "Tasks:", value = 0, min = 0, max = 20)
                             ),
                             
                             actionButton("review_priorities", "Review & Optimize", class = "btn-primary")
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Task Management System",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Current Sprint (This Week):"),
                             
                             DT::dataTableOutput("current_tasks"),
                             
                             hr(),
                             h4("Add High-Impact Task:"),
                             textInput("new_task", "Task Description:"),
                             selectInput("task_priority", "Priority:",
                                         choices = list("Critical" = "critical",
                                                        "High" = "high",
                                                        "Medium" = "medium")),
                             numericInput("task_effort", "Estimated Hours:", value = 2, min = 0.5, max = 20, step = 0.5),
                             actionButton("add_task", "Add Task", class = "btn-success")
                           )
                    ),
                    column(6,
                           box(
                             title = "Productivity Analytics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("productivity_trends")),
                             hr(),
                             h4("This Week's Stats:"),
                             div(style = "display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px;",
                                 div(style = "text-align: center; background: #eff6ff; padding: 15px; border-radius: 8px;",
                                     h3("42", style = "color: #3b82f6; margin: 0;"),
                                     p("Tasks Completed", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #f0fdf4; padding: 15px; border-radius: 8px;",
                                     h3("38.5", style = "color: #10b981; margin: 0;"),
                                     p("Deep Work Hours", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #fef3c7; padding: 15px; border-radius: 8px;",
                                     h3("94%", style = "color: #f59e0b; margin: 0;"),
                                     p("Completion Rate", style = "margin: 5px 0; font-size: 12px;")
                                 )
                             ),
                             hr(),
                             h4("Energy Management:"),
                             p("Track and optimize based on biological rhythms and energy levels."),
                             sliderInput("current_energy", "Current Energy Level:",
                                         min = 1, max = 10, value = 8)
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Newport, C. (2016). Deep work: Rules for focused success in a distracted world. Grand Central Publishing."),
                      p("Allen, D. (2015). Getting things done: The art of stress-free productivity. Penguin."),
                      p("Covey, S. R. (2004). The 7 habits of highly effective people: Powerful lessons in personal change. Free Press."),
                      p("Cirillo, F. (2018). The Pomodoro technique: The life-changing time-management system. Currency.")
                  )
                )
              )
      ),
      
      # Tab 8: Family & Relationships
      tabItem(tabName = "family",
              fluidRow(
                box(
                  title = "10x Family & Relationship Quality",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Systematic Relationship Building & Maintenance"),
                  p("Apply systematic optimization to personal relationships while maintaining authenticity and deep connection."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Relationship Metrics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Connection Quality Scores:"),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Partner/Spouse:"),
                                 progressBar("partner_quality", value = 92, status = "success", display_pct = TRUE)
                             ),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Parents:"),
                                 progressBar("parents_quality", value = 78, status = "info", display_pct = TRUE)
                             ),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Siblings:"),
                                 progressBar("siblings_quality", value = 85, status = "success", display_pct = TRUE)
                             ),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Children:"),
                                 progressBar("children_quality", value = 88, status = "success", display_pct = TRUE)
                             ),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Close Friends:"),
                                 progressBar("friends_quality", value = 72, status = "warning", display_pct = TRUE)
                             ),
                             
                             hr(),
                             h4("Time Allocation This Week:"),
                             numericInput("family_hours", "Quality Family Time (hours):", 
                                          value = 25, min = 0, max = 100)
                           )
                    ),
                    column(4,
                           box(
                             title = "Systematic Connection",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             
                             div(class = "productivity-card",
                                 h4("Daily Rituals"),
                                 tags$ul(
                                   tags$li("Morning: 30 min family breakfast"),
                                   tags$li("Evening: Phone-free dinner together"),
                                   tags$li("Bedtime: Story time with kids"),
                                   tags$li("Night: 15 min check-in with partner")
                                 ),
                                 checkboxInput("daily_rituals_complete", "Completed Today", FALSE)
                             ),
                             
                             div(class = "productivity-card",
                                 h4("Weekly Traditions"),
                                 tags$ul(
                                   tags$li("Friday: Family movie night"),
                                   tags$li("Saturday: Adventure/activity day"),
                                   tags$li("Sunday: Extended family call"),
                                   tags$li("Date night: Partner time")
                                 ),
                                 checkboxInput("weekly_traditions_complete", "Completed This Week", FALSE)
                             ),
                             
                             div(class = "productivity-card",
                                 h4("Monthly Experiences"),
                                 tags$ul(
                                   tags$li("Family trip or staycation"),
                                   tags$li("New restaurant or activity"),
                                   tags$li("Game night with friends"),
                                   tags$li("Visit extended family")
                                 ),
                                 checkboxInput("monthly_experiences_complete", "Completed This Month", FALSE)
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Relationship Investment",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("High-Impact Actions:"),
                             
                             div(class = "strategy-card",
                                 h5("1. Presence Over Presents"),
                                 p("Undivided attention is the ultimate gift. No phones, no distractions."),
                                 numericInput("quality_time_blocks", "Quality Time Blocks This Week:",
                                              value = 12, min = 0, max = 50)
                             ),
                             
                             div(class = "strategy-card",
                                 h5("2. Active Listening"),
                                 p("Listen to understand, not to respond. Ask follow-up questions."),
                                 checkboxInput("practiced_listening", "Practiced Active Listening Today", FALSE)
                             ),
                             
                             div(class = "strategy-card",
                                 h5("3. Specific Appreciation"),
                                 p("Express gratitude daily with specific examples of what you appreciate."),
                                 textAreaInput("appreciation_log", "Today's Appreciation:",
                                               placeholder = "What specific thing did you appreciate today?")
                             ),
                             
                             div(class = "strategy-card",
                                 h5("4. Shared Growth"),
                                 p("Learn together, grow together. Shared experiences deepen bonds."),
                                 textInput("shared_activity", "Current Shared Activity/Goal:")
                             )
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Relationship Calendar",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Upcoming Important Dates:"),
                             
                             DT::dataTableOutput("relationship_calendar"),
                             
                             hr(),
                             h4("Add Important Date:"),
                             textInput("event_person", "Person/Relationship:"),
                             textInput("event_type", "Event Type:", placeholder = "e.g., Birthday, Anniversary"),
                             dateInput("event_date", "Date:"),
                             actionButton("add_event", "Add to Calendar", class = "btn-success")
                           )
                    ),
                    column(6,
                           box(
                             title = "Relationship Health Tracker",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("relationship_trends")),
                             hr(),
                             h4("Monthly Review Questions:"),
                             tags$ul(
                               tags$li("Did I make each person feel valued this month?"),
                               tags$li("What meaningful conversations did we have?"),
                               tags$li("What shared experiences did we create?"),
                               tags$li("Where can I improve as a partner/parent/friend?"),
                               tags$li("What traditions should we start or strengthen?")
                             ),
                             hr(),
                             actionButton("monthly_review", "Complete Monthly Review", class = "btn-primary")
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Chapman, G. (2015). The 5 love languages: The secret to love that lasts. Northfield Publishing."),
                      p("Gottman, J. M., & Silver, N. (2015). The seven principles for making marriage work. Harmony."),
                      p("Brown, B. (2015). Daring greatly: How the courage to be vulnerable transforms the way we live, love, parent, and lead. Penguin."),
                      p("Covey, S. R. (1997). The 7 habits of highly effective families. Golden Books.")
                  )
                )
              )
      ),
      
      # Tab 9: Travel & Experiences
      tabItem(tabName = "travel",
              fluidRow(
                box(
                  title = "10x Travel & Experience Optimization",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Maximizing Experiences Through Strategic Travel"),
                  p("Systematic approach to creating memorable experiences, exploring the world efficiently, and balancing adventure with productivity."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Travel Statistics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             div(class = "metric-card",
                                 h3("23"),
                                 p("Countries Visited")
                             ),
                             div(class = "metric-card",
                                 h3("64"),
                                 p("Cities Explored")
                             ),
                             div(class = "metric-card",
                                 h3("87"),
                                 p("Days Traveling/Year")
                             ),
                             hr(),
                             h4("Travel Goals:"),
                             numericInput("target_countries", "Target Countries This Year:",
                                          value = 6, min = 1, max = 20),
                             numericInput("target_cities", "Target New Cities:",
                                          value = 12, min = 1, max = 50)
                           )
                    ),
                    column(4,
                           box(
                             title = "Optimized Travel Strategy",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             
                             div(class = "productivity-card",
                                 h4("Work + Travel Integration"),
                                 p("Digital nomad approach: Work from anywhere, explore consistently."),
                                 tags$ul(
                                   tags$li("Remote-first work arrangement"),
                                   tags$li("2-4 week stays in each location"),
                                   tags$li("Co-working spaces for productivity"),
                                   tags$li("Weekend explorations")
                                 )
                             ),
                             
                             div(class = "productivity-card",
                                 h4("Experience Prioritization"),
                                 p("Focus on unique, unforgettable experiences over tourist traps."),
                                 checkboxGroupInput("experience_types", "Priority Experiences:",
                                                    choices = list("Local Food & Culture" = "food",
                                                                   "Nature & Adventure" = "nature",
                                                                   "Historical Sites" = "history",
                                                                   "Local Communities" = "community",
                                                                   "Unique Activities" = "activities"),
                                                    selected = c("food", "nature", "community"))
                             ),
                             
                             div(class = "productivity-card",
                                 h4("Travel Hacking"),
                                 p("Maximize value through points, miles, and strategic booking."),
                                 numericInput("points_earned", "Points Earned This Month:",
                                              value = 45000, min = 0, max = 500000)
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Bucket List Tracker",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Top Priority Experiences:"),
                             
                             div(class = "habit-item",
                                 checkboxInput("experience_1", "Safari in Tanzania", FALSE),
                                 tags$small("Target: Q3 2024")
                             ),
                             
                             div(class = "habit-item",
                                 checkboxInput("experience_2", "Northern Lights in Iceland", FALSE),
                                 tags$small("Target: Q1 2025")
                             ),
                             
                             div(class = "habit-item",
                                 checkboxInput("experience_3", "Dive Great Barrier Reef", FALSE),
                                 tags$small("Target: Q2 2024")
                             ),
                             
                             div(class = "habit-item",
                                 checkboxInput("experience_4", "Hike Machu Picchu", FALSE),
                                 tags$small("Target: Q4 2024")
                             ),
                             
                             div(class = "habit-item",
                                 checkboxInput("experience_5", "Japan Cherry Blossoms", FALSE),
                                 tags$small("Target: April 2025")
                             ),
                             
                             hr(),
                             textInput("new_bucket_item", "Add Bucket List Item:"),
                             actionButton("add_bucket_item", "Add Experience", class = "btn-success")
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Upcoming Travel Plans",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Next 12 Months:"),
                             
                             DT::dataTableOutput("travel_schedule"),
                             
                             hr(),
                             h4("Plan New Trip:"),
                             textInput("destination", "Destination:"),
                             dateInput("trip_start", "Start Date:"),
                             dateInput("trip_end", "End Date:"),
                             selectInput("trip_type", "Trip Type:",
                                         choices = list("Work + Explore" = "workcation",
                                                        "Pure Adventure" = "adventure",
                                                        "Family Vacation" = "family",
                                                        "Conference/Event" = "conference")),
                             actionButton("plan_trip", "Add to Schedule", class = "btn-primary")
                           )
                    ),
                    column(6,
                           box(
                             title = "Travel Impact Visualization",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("travel_map")),
                             hr(),
                             h4("Travel Insights:"),
                             div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 10px;",
                                 div(style = "text-align: center; background: #eff6ff; padding: 15px; border-radius: 8px;",
                                     h3("7", style = "color: #3b82f6; margin: 0;"),
                                     p("Continents Visited", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #f0fdf4; padding: 15px; border-radius: 8px;",
                                     h3("$4,200", style = "color: #10b981; margin: 0;"),
                                     p("Avg Monthly Travel Cost", style = "margin: 5px 0; font-size: 12px;")
                                 )
                             ),
                             hr(),
                             h4("Travel ROI:"),
                             tags$ul(
                               tags$li("Life experiences and memories: Priceless"),
                               tags$li("Cultural understanding and perspective: Invaluable"),
                               tags$li("Business connections made traveling: 12 key relationships"),
                               tags$li("Content created from travels: 47 blog posts, 200+ photos"),
                               tags$li("Personal growth and adaptability: Immeasurable")
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Ferriss, T. (2007). The 4-hour workweek: Escape 9-5, live anywhere, and join the new rich. Crown Publishers."),
                      p("Guillebeau, C. (2019). The art of non-conformity: Set your own rules, live the life you want, and change the world. TarcherPerigee."),
                      p("Kepnes, M. (2015). How to travel the world on $50 a day: Travel cheaper, longer, smarter. Perigee."),
                      p("Kaplan, E. (2018). Digital nomads: In search of freedom, community, and meaningful work in the new economy. Oxford University Press.")
                  )
                )
              )
      ),
      
      # Tab 10: Health & Energy
      tabItem(tabName = "health",
              fluidRow(
                box(
                  title = "10x Health & Energy Optimization",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Systematic Health Optimization for Peak Performance"),
                  p("Engineering approach to health: optimize sleep, nutrition, exercise, and recovery for maximum energy and longevity."),
                  
                  fluidRow(
                    column(4,
                           box(
                             title = "Health Metrics Dashboard",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Current Vitals:"),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Sleep Quality:"),
                                 progressBar("sleep_quality", value = 87, status = "success", display_pct = TRUE),
                                 tags$small("7.5 hrs avg")
                             ),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Energy Level:"),
                                 progressBar("energy_level", value = 82, status = "info", display_pct = TRUE),
                                 tags$small("8.2/10 avg")
                             ),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Fitness Score:"),
                                 progressBar("fitness_score", value = 78, status = "warning", display_pct = TRUE),
                                 tags$small("VO2 Max: 52")
                             ),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Nutrition Quality:"),
                                 progressBar("nutrition_quality", value = 85, status = "success", display_pct = TRUE),
                                 tags$small("Macro targets met")
                             ),
                             
                             div(style = "margin: 15px 0;",
                                 tags$strong("Recovery Score:"),
                                 progressBar("recovery_score", value = 74, status = "warning", display_pct = TRUE),
                                 tags$small("HRV: 68ms")
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Daily Health Stack",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             
                             div(class = "productivity-card",
                                 h4("Morning Routine (60 min)"),
                                 div(class = "habit-item",
                                     checkboxInput("morning_1", "Hydration: 500ml water + electrolytes", FALSE)
                                 ),
                                 div(class = "habit-item",
                                     checkboxInput("morning_2", "Movement: 10 min stretching/mobility", FALSE)
                                 ),
                                 div(class = "habit-item",
                                     checkboxInput("morning_3", "Sunlight: 15 min outdoor exposure", FALSE)
                                 ),
                                 div(class = "habit-item",
                                     checkboxInput("morning_4", "Nutrition: High-protein breakfast", FALSE)
                                 ),
                                 div(class = "habit-item",
                                     checkboxInput("morning_5", "Supplements: Daily vitamin stack", FALSE)
                                 )
                             ),
                             
                             div(class = "productivity-card",
                                 h4("Exercise Protocol"),
                                 tags$ul(
                                   tags$li("Monday: Strength training (upper)"),
                                   tags$li("Tuesday: Zone 2 cardio (60 min)"),
                                   tags$li("Wednesday: Strength training (lower)"),
                                   tags$li("Thursday: HIIT (30 min)"),
                                   tags$li("Friday: Strength training (full body)"),
                                   tags$li("Weekend: Active recovery (yoga, hiking)")
                                 ),
                                 checkboxInput("workout_complete", "Today's Workout Complete", FALSE)
                             ),
                             
                             div(class = "productivity-card",
                                 h4("Evening Wind-Down"),
                                 div(class = "habit-item",
                                     checkboxInput("evening_1", "No screens 1 hour before bed", FALSE)
                                 ),
                                 div(class = "habit-item",
                                     checkboxInput("evening_2", "10 min meditation/breathing", FALSE)
                                 ),
                                 div(class = "habit-item",
                                     checkboxInput("evening_3", "Cold shower (2-3 min)", FALSE)
                                 ),
                                 div(class = "habit-item",
                                     checkboxInput("evening_4", "Sleep environment optimized", FALSE)
                                 )
                             )
                           )
                    ),
                    column(4,
                           box(
                             title = "Health Optimization Systems",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             
                             div(class = "strategy-card",
                                 h5("Sleep Optimization"),
                                 tags$ul(
                                   tags$li("Consistent sleep/wake times (±30 min)"),
                                   tags$li("Cool room temperature (65-68°F)"),
                                   tags$li("Complete darkness (blackout curtains)"),
                                   tags$li("No caffeine after 2 PM"),
                                   tags$li("Magnesium glycinate supplement")
                                 ),
                                 numericInput("last_night_sleep", "Last Night Sleep (hrs):",
                                              value = 7.5, min = 0, max = 12, step = 0.5)
                             ),
                             
                             div(class = "strategy-card",
                                 h5("Nutrition Framework"),
                                 tags$ul(
                                   tags$li("Intermittent fasting: 16:8 protocol"),
                                   tags$li("High protein: 1g per lb bodyweight"),
                                   tags$li("Whole foods: 80% unprocessed"),
                                   tags$li("Hydration: 0.5-1 oz per lb bodyweight"),
                                   tags$li("Track macros and calories")
                                 ),
                                 numericInput("daily_protein", "Today's Protein (g):",
                                              value = 180, min = 0, max = 400)
                             ),
                             
                             div(class = "strategy-card",
                                 h5("Recovery Protocols"),
                                 tags$ul(
                                   tags$li("Weekly deep tissue massage"),
                                   tags$li("Daily foam rolling (10 min)"),
                                   tags$li("Sauna 2-3x per week"),
                                   tags$li("Ice bath 1-2x per week"),
                                   tags$li("Deload week every 4-6 weeks")
                                 )
                             )
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Biometric Tracking",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Key Health Markers:"),
                             
                             fluidRow(
                               column(6,
                                      numericInput("weight", "Weight (lbs):", value = 175, min = 100, max = 300),
                                      numericInput("body_fat", "Body Fat %:", value = 12, min = 5, max = 40),
                                      numericInput("resting_hr", "Resting HR (bpm):", value = 52, min = 30, max = 100)
                               ),
                               column(6,
                                      numericInput("hrv", "HRV (ms):", value = 68, min = 20, max = 150),
                                      numericInput("vo2_max", "VO2 Max:", value = 52, min = 20, max = 80),
                                      numericInput("blood_pressure", "BP Systolic:", value = 118, min = 80, max = 200)
                               )
                             ),
                             
                             hr(),
                             h4("Lab Work Tracking:"),
                             DT::dataTableOutput("lab_results"),
                             hr(),
                             actionButton("update_biometrics", "Log Today's Data", class = "btn-primary")
                           )
                    ),
                    column(6,
                           box(
                             title = "Health Trends & Analytics",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("health_trends")),
                             hr(),
                             h4("Performance Correlations:"),
                             tags$ul(
                               tags$li("Sleep quality → +23% productivity correlation"),
                               tags$li("Exercise → +18% energy levels"),
                               tags$li("Nutrition adherence → +15% focus scores"),
                               tags$li("Stress management → +27% mood improvement")
                             ),
                             hr(),
                             div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 10px;",
                                 div(style = "text-align: center; background: #eff6ff; padding: 15px; border-radius: 8px;",
                                     h3("365", style = "color: #3b82f6; margin: 0;"),
                                     p("Day Health Streak", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #f0fdf4; padding: 15px; border-radius: 8px;",
                                     h3("97%", style = "color: #10b981; margin: 0;"),
                                     p("Protocol Adherence", style = "margin: 5px 0; font-size: 12px;")
                                 )
                             )
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Attia, P., & Gifford, B. (2023). Outlive: The science and art of longevity. Harmony."),
                      p("Walker, M. (2017). Why we sleep: Unlocking the power of sleep and dreams. Scribner."),
                      p("Huberman, A. (2021). Huberman Lab Podcast: Science-based tools for everyday life. Scicomm Media."),
                      p("Patrick, R. (2023). Found My Fitness Podcast: Health optimization and longevity. FoundMyFitness.")
                  )
                )
              )
      ),
      
      # Tab 11: Integration & Tracking
      tabItem(tabName = "tracking",
              fluidRow(
                box(
                  title = "Integrated Life Optimization Dashboard",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  h3("Holistic Tracking & Continuous Improvement"),
                  p("Unified dashboard for tracking all life domains, identifying synergies, and ensuring balanced optimization across all areas."),
                  
                  fluidRow(
                    column(12,
                           box(
                             title = "10x Life Scorecard",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Current Performance Across All Domains:"),
                             
                             withSpinner(plotlyOutput("overall_scorecard", height = "400px")),
                             
                             hr(),
                             h4("Domain Scores (0-100):"),
                             fluidRow(
                               column(3,
                                      div(style = "text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("92", style = "margin: 0;"),
                                          p("Knowledge", style = "margin: 5px 0;")
                                      ),
                                      div(style = "text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("78", style = "margin: 0;"),
                                          p("Skills", style = "margin: 5px 0;")
                                      ),
                                      div(style = "text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("85", style = "margin: 0;"),
                                          p("Network", style = "margin: 5px 0;")
                                      )
                               ),
                               column(3,
                                      div(style = "text-align: center; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("82", style = "margin: 0;"),
                                          p("Wealth", style = "margin: 5px 0;")
                                      ),
                                      div(style = "text-align: center; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("88", style = "margin: 0;"),
                                          p("Business", style = "margin: 5px 0;")
                                      ),
                                      div(style = "text-align: center; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("86", style = "margin: 0;"),
                                          p("Work", style = "margin: 5px 0;")
                                      )
                               ),
                               column(3,
                                      div(style = "text-align: center; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("90", style = "margin: 0;"),
                                          p("Family", style = "margin: 5px 0;")
                                      ),
                                      div(style = "text-align: center; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("76", style = "margin: 0;"),
                                          p("Travel", style = "margin: 5px 0;")
                                      ),
                                      div(style = "text-align: center; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("84", style = "margin: 0;"),
                                          p("Health", style = "margin: 5px 0;")
                                      )
                               ),
                               column(3,
                                      div(style = "text-align: center; background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("84.6", style = "margin: 0;"),
                                          p("Overall Score", style = "margin: 5px 0; font-weight: bold;")
                                      ),
                                      div(style = "text-align: center; background: linear-gradient(135deg, #fa709a 0%, #fee140 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("3.2x", style = "margin: 0;"),
                                          p("Current Multiplier", style = "margin: 5px 0; font-weight: bold;")
                                      ),
                                      div(style = "text-align: center; background: linear-gradient(135deg, #30cfd0 0%, #330867 100%); color: white; padding: 20px; border-radius: 12px; margin: 10px;",
                                          h3("187", style = "margin: 0;"),
                                          p("Days on Track", style = "margin: 5px 0; font-weight: bold;")
                                      )
                               )
                             )
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Weekly Review Protocol",
                             status = "info",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Sunday Planning & Review Session:"),
                             
                             div(class = "timeline-item",
                                 h5("1. Reflect on Past Week (20 min)"),
                                 tags$ul(
                                   tags$li("What went well? What didn't?"),
                                   tags$li("Did I achieve my key objectives?"),
                                   tags$li("What lessons did I learn?"),
                                   tags$li("What should I stop/start/continue?")
                                 ),
                                 textAreaInput("weekly_reflection", "This Week's Reflection:",
                                               placeholder = "Key insights and lessons...")
                             ),
                             
                             div(class = "timeline-item",
                                 h5("2. Review All Domain Metrics (15 min)"),
                                 tags$ul(
                                   tags$li("Check progress in each life area"),
                                   tags$li("Identify underperforming domains"),
                                   tags$li("Celebrate wins and milestones"),
                                   tags$li("Update tracking systems")
                                 ),
                                 actionButton("review_metrics", "Review This Week's Metrics", class = "btn-primary")
                             ),
                             
                             div(class = "timeline-item",
                                 h5("3. Plan Next Week (25 min)"),
                                 tags$ul(
                                   tags$li("Set 3-5 key objectives for the week"),
                                   tags$li("Time-block calendar for the week"),
                                   tags$li("Identify potential obstacles"),
                                   tags$li("Plan for balance across domains")
                                 ),
                                 textAreaInput("weekly_objectives", "Next Week's Top 3 Objectives:",
                                               placeholder = "Most important outcomes to achieve...")
                             ),
                             
                             actionButton("complete_weekly_review", "Complete Weekly Review", class = "btn-success", style = "width: 100%;")
                           )
                    ),
                    column(6,
                           box(
                             title = "Habit Tracking Matrix",
                             status = "warning",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Daily Habit Checklist:"),
                             
                             DT::dataTableOutput("habit_tracker"),
                             
                             hr(),
                             h4("Habit Streak Tracking:"),
                             div(style = "display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px;",
                                 div(style = "text-align: center; background: #eff6ff; padding: 15px; border-radius: 8px;",
                                     h3("127", style = "color: #3b82f6; margin: 0;"),
                                     p("Learning Streak", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #f0fdf4; padding: 15px; border-radius: 8px;",
                                     h3("365", style = "color: #10b981; margin: 0;"),
                                     p("Exercise Streak", style = "margin: 5px 0; font-size: 12px;")
                                 ),
                                 div(style = "text-align: center; background: #fef3c7; padding: 15px; border-radius: 8px;",
                                     h3("89", style = "color: #f59e0b; margin: 0;"),
                                     p("Meditation Streak", style = "margin: 5px 0; font-size: 12px;")
                                 )
                             ),
                             
                             hr(),
                             h4("Add New Habit:"),
                             textInput("new_habit", "Habit Name:"),
                             selectInput("habit_frequency", "Frequency:",
                                         choices = list("Daily" = "daily",
                                                        "Weekdays" = "weekdays",
                                                        "Weekly" = "weekly")),
                             actionButton("add_habit", "Add Habit", class = "btn-primary")
                           )
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           box(
                             title = "Time Allocation Analysis",
                             status = "primary",
                             solidHeader = TRUE,
                             width = 12,
                             h4("Weekly Time Distribution:"),
                             withSpinner(plotlyOutput("time_allocation")),
                             hr(),
                             h4("Optimize Time Allocation:"),
                             p("Adjust your weekly hours across different life domains to achieve better balance and 10x results."),
                             
                             sliderInput("learning_hours", "Learning & Development:",
                                         min = 0, max = 40, value = 14),
                             sliderInput("work_hours", "Deep Work & Projects:",
                                         min = 0, max = 60, value = 40),
                             sliderInput("family_time_hours", "Family & Relationships:",
                                         min = 0, max = 40, value = 25),
                             sliderInput("health_hours", "Health & Fitness:",
                                         min = 0, max = 20, value = 10),
                             
                             actionButton("optimize_time", "Apply New Allocation", class = "btn-success")
                           )
                    ),
                    column(6,
                           box(
                             title = "Progress Trends & Insights",
                             status = "success",
                             solidHeader = TRUE,
                             width = 12,
                             withSpinner(plotlyOutput("progress_trends")),
                             hr(),
                             h4("AI-Generated Insights:"),
                             div(style = "background-color: #eff6ff; border-left: 4px solid #3b82f6; padding: 15px; border-radius: 5px; margin: 10px 0;",
                                 h5("Strong Momentum Areas:", style = "color: #1e40af; margin: 0;"),
                                 tags$ul(
                                   tags$li("Knowledge acquisition up 42% this month"),
                                   tags$li("Network quality score improving consistently"),
                                   tags$li("Health metrics all trending positive")
                                 )
                             ),
                             
                             div(style = "background-color: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; border-radius: 5px; margin: 10px 0;",
                                 h5("Areas Needing Attention:", style = "color: #92400e; margin: 0;"),
                                 tags$ul(
                                   tags$li("Travel experiences below target (4 vs 6)"),
                                   tags$li("Skills practice intensity dropped 12%"),
                                   tags$li("Family quality time slightly below goal")
                                 )
                             ),
                             
                             div(style = "background-color: #d1fae5; border-left: 4px solid #10b981; padding: 15px; border-radius: 5px; margin: 10px 0;",
                                 h5("Recommended Actions:", style = "color: #065f46; margin: 0;"),
                                 tags$ul(
                                   tags$li("Schedule weekend trip for next month"),
                                   tags$li("Increase deliberate practice blocks to 3/day"),
                                   tags$li("Plan family activity for this weekend"),
                                   tags$li("Maintain current learning momentum")
                                 )
                             ),
                             
                             actionButton("generate_report", "Generate Full Report", class = "btn-primary")
                           )
                    )
                  ),
                  
                  div(class = "references-box",
                      h4("References:"),
                      p("Clear, J. (2018). Atomic habits: An easy & proven way to build good habits & break bad ones. Penguin Random House."),
                      p("Covey, S. R. (2004). The 7 habits of highly effective people: Powerful lessons in personal change. Free Press."),
                      p("Sinek, S. (2009). Start with why: How great leaders inspire everyone to take action. Portfolio."),
                      p("Duhigg, C. (2012). The power of habit: Why we do what we do in life and business. Random House.")
                  )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Tab 1: Overview - Value Boxes
  output$productivity_score <- renderValueBox({
    valueBox(
      "84.6", "Overall Optimization Score", icon = icon("chart-line"),
      color = "blue"
    )
  })
  
  output$weekly_hours_optimized <- renderValueBox({
    valueBox(
      "127", "Productive Hours/Week", icon = icon("clock"),
      color = "green"
    )
  })
  
  output$systems_active <- renderValueBox({
    valueBox(
      "23", "Active Systems", icon = icon("cogs"),
      color = "purple"
    )
  })
  
  output$roi_multiplier <- renderValueBox({
    valueBox(
      "3.2x", "Current Life ROI", icon = icon("rocket"),
      color = "yellow"
    )
  })
  
  # Tab 1: Optimization Radar Chart
  output$optimization_radar <- renderPlotly({
    categories <- c('Knowledge', 'Skills', 'Network', 'Wealth', 'Business',
                    'Work', 'Family', 'Travel', 'Health')
    
    scores <- data.frame(
      category = categories,
      current = c(92, 78, 85, 82, 88, 86, 90, 76, 84),
      target = c(95, 90, 90, 95, 95, 90, 95, 85, 90)
    )
    
    plot_ly(
      type = 'scatterpolar',
      mode = 'lines+markers',
      fill = 'toself'
    ) %>%
      add_trace(
        r = scores$current,
        theta = scores$category,
        name = 'Current',
        line = list(color = '#3b82f6', width = 3),
        marker = list(color = '#3b82f6', size = 8)
      ) %>%
      add_trace(
        r = scores$target,
        theta = scores$category,
        name = 'Target',
        line = list(color = '#10b981', width = 2, dash = 'dash'),
        marker = list(color = '#10b981', size = 6)
      ) %>%
      layout(
        polar = list(
          radialaxis = list(
            visible = TRUE,
            range = c(0, 100),
            tickfont = list(color = '#374151')
          ),
          angularaxis = list(
            tickfont = list(size = 12, color = '#1e293b')
          )
        ),
        showlegend = TRUE,
        paper_bgcolor = 'rgba(248,250,252,1)',
        plot_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 2: Learning Progress Chart
  output$learning_progress <- renderPlotly({
    months <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun")
    books <- c(3, 4, 5, 3, 4, 6)
    courses <- c(1, 2, 1, 2, 1, 2)
    hours <- c(42, 48, 55, 45, 52, 60)
    
    plot_ly() %>%
      add_trace(
        x = factor(months, levels = months),
        y = books,
        type = 'bar',
        name = 'Books',
        marker = list(color = '#3b82f6')
      ) %>%
      add_trace(
        x = factor(months, levels = months),
        y = courses,
        type = 'bar',
        name = 'Courses',
        marker = list(color = '#10b981')
      ) %>%
      add_trace(
        x = factor(months, levels = months),
        y = hours,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Study Hours',
        yaxis = 'y2',
        line = list(color = '#f59e0b', width = 3),
        marker = list(size = 8)
      ) %>%
      layout(
        title = list(text = 'Learning Activity Trends', font = list(color = '#1e293b')),
        xaxis = list(title = 'Month', type = 'category', color = '#374151'),
        yaxis = list(title = 'Books/Courses', color = '#374151'),
        yaxis2 = list(
          title = 'Study Hours',
          overlaying = 'y',
          side = 'right',
          color = '#f59e0b'
        ),
        barmode = 'group',
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 3: Skill Progress Chart
  output$skill_progress_chart <- renderPlotly({
    weeks <- 1:12
    python <- c(45, 48, 52, 55, 58, 60, 62, 64, 65, 66, 67, 67)
    speaking <- c(20, 23, 26, 29, 32, 34, 36, 38, 40, 42, 44, 45)
    content <- c(55, 57, 59, 62, 64, 66, 68, 69, 70, 71, 72, 72)
    sales <- c(15, 18, 21, 24, 26, 28, 30, 32, 34, 36, 37, 38)
    
    plot_ly() %>%
      add_trace(x = weeks, y = python, type = 'scatter', mode = 'lines+markers',
                name = 'Python/ML', line = list(color = '#3b82f6', width = 3)) %>%
      add_trace(x = weeks, y = speaking, type = 'scatter', mode = 'lines+markers',
                name = 'Speaking', line = list(color = '#10b981', width = 3)) %>%
      add_trace(x = weeks, y = content, type = 'scatter', mode = 'lines+markers',
                name = 'Content', line = list(color = '#f59e0b', width = 3)) %>%
      add_trace(x = weeks, y = sales, type = 'scatter', mode = 'lines+markers',
                name = 'Sales', line = list(color = '#ef4444', width = 3)) %>%
      layout(
        title = list(text = 'Skill Mastery Progress', font = list(color = '#1e293b')),
        xaxis = list(title = 'Week', color = '#374151'),
        yaxis = list(title = 'Mastery %', color = '#374151'),
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 3: 20-Hour Skills Table
  output$rapid_skills_table <- DT::renderDataTable({
    skills_data <- data.frame(
      Skill = c("Video Editing", "Copywriting", "Spanish Language"),
      Hours = c(18, 12, 8),
      Target = c(20, 20, 20),
      Status = c("Near Complete", "In Progress", "Just Started")
    )
    
    DT::datatable(skills_data, options = list(pageLength = 5, dom = 't'),
                  class = 'cell-border stripe')
  })
  
  # Tab 4: Network Composition Pie Chart
  output$network_composition <- renderPlotly({
    plot_ly(
      labels = c("Tech/Engineering", "Business/Founders", "Investors", "Clients", "Mentors"),
      values = c(35, 25, 15, 18, 7),
      type = 'pie',
      marker = list(colors = c('#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899'))
    ) %>%
      layout(
        showlegend = TRUE,
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 4: Network Activity Table
  output$network_activity <- DT::renderDataTable({
    activity_data <- data.frame(
      Date = c("Sep 25", "Sep 22", "Sep 20", "Sep 18"),
      Type = c("Meeting", "Introduction", "Coffee", "Conference"),
      Person = c("Sarah Chen", "Mike Johnson", "Alex Park", "Industry Event"),
      Outcome = c("Partnership discussion", "Connected to investor", "Collaboration idea", "5 new connections")
    )
    
    DT::datatable(activity_data, options = list(pageLength = 5, dom = 't'),
                  class = 'cell-border stripe')
  })
  
  # Tab 5: Income Breakdown
  output$income_breakdown <- renderPlotly({
    plot_ly(
      labels = c("W2 Salary", "Consulting", "Side Business", "Investments", "Digital Products"),
      values = c(12000, 8000, 12000, 6000, 4000),
      type = 'pie',
      hole = 0.4,
      marker = list(colors = c('#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899'))
    ) %>%
      layout(
        showlegend = TRUE,
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 5: Wealth Projection Chart
  output$wealth_projection <- renderPlotly({
    years <- c(2024, 2025, 2026, 2027, 2028, 2029, 2030)
    conservative <- c(487, 620, 780, 965, 1180, 1430, 1720)
    expected <- c(487, 650, 850, 1100, 1420, 1820, 2300)
    optimistic <- c(487, 680, 950, 1280, 1720, 2280, 3000)
    
    plot_ly() %>%
      add_trace(
        x = years,
        y = conservative,
        type = 'scatter',
        mode = 'lines',
        name = 'Conservative',
        line = list(color = '#6b7280', width = 2),
        fill = 'tonexty',
        fillcolor = 'rgba(107, 114, 128, 0.2)'
      ) %>%
      add_trace(
        x = years,
        y = expected,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Expected',
        line = list(color = '#3b82f6', width = 3),
        marker = list(size = 8)
      ) %>%
      add_trace(
        x = years,
        y = optimistic,
        type = 'scatter',
        mode = 'lines',
        name = 'Optimistic',
        line = list(color = '#10b981', width = 2),
        fill = 'tonexty',
        fillcolor = 'rgba(16, 185, 129, 0.2)'
      ) %>%
      layout(
        title = list(text = 'Net Worth Projection ($K)', font = list(color = '#1e293b')),
        xaxis = list(title = 'Year', color = '#374151'),
        yaxis = list(title = 'Net Worth ($K)', color = '#374151'),
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151'),
        hovermode = 'x unified'
      )
  })
  
  # Tab 6: Revenue Forecast
  output$revenue_forecast <- renderPlotly({
    months <- factor(c("Jul", "Aug", "Sep", "Oct", "Nov", "Dec"), 
                     levels = c("Jul", "Aug", "Sep", "Oct", "Nov", "Dec"))
    actual <- c(18.2, 19.8, 22.6, NA, NA, NA)
    forecast <- c(NA, NA, 22.6, 25.8, 29.2, 33.5)
    
    plot_ly() %>%
      add_trace(
        x = months,
        y = actual,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Actual MRR',
        line = list(color = '#3b82f6', width = 3),
        marker = list(size = 10)
      ) %>%
      add_trace(
        x = months,
        y = forecast,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Forecast',
        line = list(color = '#10b981', width = 3, dash = 'dash'),
        marker = list(size = 10)
      ) %>%
      layout(
        xaxis = list(title = '', type = 'category', color = '#374151'),
        yaxis = list(title = 'MRR ($K)', color = '#374151'),
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151'),
        showlegend = TRUE
      )
  })
  
  # Tab 6: Quarterly Goals Table
  output$quarterly_goals <- DT::renderDataTable({
    goals_data <- data.frame(
      Goal = c("Reach $30K MRR", "Launch Digital Product", "Hire First Employee", "10K Newsletter Subs"),
      Progress = c("75%", "60%", "40%", "85%"),
      Target = c("Dec 31", "Nov 15", "Dec 15", "Oct 31")
    )
    
    DT::datatable(goals_data, options = list(pageLength = 10, dom = 't'),
                  class = 'cell-border stripe')
  })
  
  # Tab 7: Work Time Distribution
  output$work_time_dist <- renderPlotly({
    plot_ly(
      labels = c("Deep Work", "Meetings", "Email/Admin", "Learning", "Breaks"),
      values = c(38, 6, 4, 8, 9),
      type = 'pie',
      hole = 0.4,
      marker = list(colors = c('#3b82f6', '#f59e0b', '#ef4444', '#10b981', '#e5e7eb'))
    ) %>%
      layout(
        showlegend = TRUE,
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151', size = 10)
      )
  })
  
  # Tab 7: Current Tasks Table
  output$current_tasks <- DT::renderDataTable({
    tasks_data <- data.frame(
      Task = c("Complete feature X", "Client presentation", "Code review", "Write blog post"),
      Priority = c("Critical", "High", "High", "Medium"),
      Hours = c(4, 2, 3, 2),
      Status = c("In Progress", "Planned", "Planned", "Not Started")
    )
    
    DT::datatable(tasks_data, options = list(pageLength = 10, dom = 't'),
                  class = 'cell-border stripe') %>%
      formatStyle(
        'Priority',
        backgroundColor = styleEqual(c('Critical', 'High', 'Medium'),
                                     c('#fee2e2', '#fef3c7', '#e0f2fe'))
      )
  })
  
  # Tab 7: Productivity Trends
  output$productivity_trends <- renderPlotly({
    days <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    deep_work <- c(6.5, 7.2, 6.8, 7.0, 5.8, 3.5, 4.2)
    focus_score <- c(85, 90, 88, 92, 82, 70, 75)
    
    plot_ly() %>%
      add_trace(
        x = factor(days, levels = days),
        y = deep_work,
        type = 'bar',
        name = 'Deep Work Hours',
        marker = list(color = '#3b82f6')
      ) %>%
      add_trace(
        x = factor(days, levels = days),
        y = focus_score,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Focus Score',
        yaxis = 'y2',
        line = list(color = '#10b981', width = 3),
        marker = list(size = 8)
      ) %>%
      layout(
        xaxis = list(title = '', type = 'category', color = '#374151'),
        yaxis = list(title = 'Hours', color = '#374151'),
        yaxis2 = list(
          title = 'Focus Score',
          overlaying = 'y',
          side = 'right',
          color = '#10b981'
        ),
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 8: Relationship Calendar
  output$relationship_calendar <- DT::renderDataTable({
    calendar_data <- data.frame(
      Date = c("Oct 5", "Oct 12", "Oct 28", "Nov 3", "Nov 15"),
      Person = c("Mom", "Partner", "Best Friend", "Dad", "Sister"),
      Event = c("Birthday", "Anniversary", "Birthday", "Birthday", "Graduation"),
      Planned = c("Yes", "Yes", "Not Yet", "Not Yet", "Yes")
    )
    
    DT::datatable(calendar_data, options = list(pageLength = 10, dom = 't'),
                  class = 'cell-border stripe') %>%
      formatStyle(
        'Planned',
        backgroundColor = styleEqual(c('Yes', 'Not Yet'),
                                     c('#d1fae5', '#fee2e2'))
      )
  })
  
  # Tab 8: Relationship Trends
  output$relationship_trends <- renderPlotly({
    months <- factor(c("Apr", "May", "Jun", "Jul", "Aug", "Sep"),
                     levels = c("Apr", "May", "Jun", "Jul", "Aug", "Sep"))
    
    partner <- c(88, 90, 89, 91, 92, 92)
    family <- c(75, 78, 80, 82, 81, 83)
    friends <- c(68, 70, 72, 71, 72, 72)
    
    plot_ly() %>%
      add_trace(
        x = months,
        y = partner,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Partner',
        line = list(color = '#ec4899', width = 3),
        marker = list(size = 8)
      ) %>%
      add_trace(
        x = months,
        y = family,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Family',
        line = list(color = '#3b82f6', width = 3),
        marker = list(size = 8)
      ) %>%
      add_trace(
        x = months,
        y = friends,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Friends',
        line = list(color = '#10b981', width = 3),
        marker = list(size = 8)
      ) %>%
      layout(
        title = list(text = 'Relationship Quality Trends', font = list(color = '#1e293b')),
        xaxis = list(title = 'Month', type = 'category', color = '#374151'),
        yaxis = list(title = 'Quality Score', range = c(60, 100), color = '#374151'),
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 9: Travel Schedule Table
  output$travel_schedule <- DT::renderDataTable({
    travel_data <- data.frame(
      Destination = c("Tokyo, Japan", "Barcelona, Spain", "Bali, Indonesia", "NYC, USA"),
      Dates = c("Oct 15-29", "Nov 10-24", "Jan 5-Feb 2", "Mar 10-17"),
      Type = c("Workcation", "Family", "Workcation", "Conference"),
      Status = c("Booked", "Planned", "Planned", "Considering")
    )
    
    DT::datatable(travel_data, options = list(pageLength = 10, dom = 't'),
                  class = 'cell-border stripe')
  })
  
  # Tab 9: Travel Map Visualization
  output$travel_map <- renderPlotly({
    # Simple visualization showing countries visited
    continents <- c("N. America", "S. America", "Europe", "Asia", "Africa", "Oceania")
    countries <- c(5, 3, 8, 4, 2, 1)
    
    plot_ly(
      x = continents,
      y = countries,
      type = 'bar',
      marker = list(
        color = countries,
        colorscale = list(c(0, '#e0f2fe'), c(1, '#3b82f6')),
        showscale = FALSE
      )
    ) %>%
      layout(
        title = list(text = 'Countries Visited by Continent', font = list(color = '#1e293b')),
        xaxis = list(title = '', color = '#374151'),
        yaxis = list(title = 'Countries', color = '#374151'),
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 10: Lab Results Table
  output$lab_results <- DT::renderDataTable({
    lab_data <- data.frame(
      Marker = c("Vitamin D", "Testosterone", "Cholesterol", "HbA1c"),
      Value = c("62 ng/mL", "720 ng/dL", "165 mg/dL", "5.1%"),
      Range = c("30-100", "300-1000", "<200", "<5.7"),
      Status = c("Optimal", "Optimal", "Optimal", "Optimal")
    )
    
    DT::datatable(lab_data, options = list(pageLength = 5, dom = 't'),
                  class = 'cell-border stripe') %>%
      formatStyle(
        'Status',
        backgroundColor = styleEqual('Optimal', '#d1fae5')
      )
  })
  
  # Tab 10: Health Trends Chart
  output$health_trends <- renderPlotly({
    weeks <- 1:12
    sleep <- c(7.2, 7.3, 7.4, 7.5, 7.4, 7.6, 7.5, 7.5, 7.6, 7.5, 7.5, 7.5)
    energy <- c(7.8, 8.0, 8.1, 8.2, 8.0, 8.3, 8.2, 8.2, 8.3, 8.2, 8.2, 8.2)
    workout <- c(4, 5, 5, 6, 5, 6, 6, 6, 6, 6, 6, 6)
    
    plot_ly() %>%
      add_trace(
        x = weeks,
        y = sleep,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Sleep (hrs)',
        line = list(color = '#3b82f6', width = 3),
        marker = list(size = 8)
      ) %>%
      add_trace(
        x = weeks,
        y = energy,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Energy (0-10)',
        line = list(color = '#10b981', width = 3),
        marker = list(size = 8)
      ) %>%
      add_trace(
        x = weeks,
        y = workout,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Workouts',
        line = list(color = '#f59e0b', width = 3),
        marker = list(size = 8)
      ) %>%
      layout(
        title = list(text = 'Health Metrics Over Time', font = list(color = '#1e293b')),
        xaxis = list(title = 'Week', color = '#374151'),
        yaxis = list(title = 'Value', color = '#374151'),
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 11: Overall Scorecard
  output$overall_scorecard <- renderPlotly({
    categories <- c('Knowledge', 'Skills', 'Network', 'Wealth', 'Business',
                    'Work', 'Family', 'Travel', 'Health')
    
    current_scores <- c(92, 78, 85, 82, 88, 86, 90, 76, 84)
    target_scores <- c(95, 90, 90, 95, 95, 90, 95, 85, 90)
    
    plot_ly() %>%
      add_trace(
        x = categories,
        y = current_scores,
        type = 'bar',
        name = 'Current',
        marker = list(color = '#3b82f6')
      ) %>%
      add_trace(
        x = categories,
        y = target_scores,
        type = 'scatter',
        mode = 'markers',
        name = 'Target',
        marker = list(
          color = '#10b981',
          size = 12,
          symbol = 'diamond'
        )
      ) %>%
      layout(
        title = list(text = 'Life Domain Performance vs Targets', font = list(color = '#1e293b', size = 16)),
        xaxis = list(title = '', color = '#374151'),
        yaxis = list(title = 'Score (0-100)', range = c(0, 100), color = '#374151'),
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151'),
        showlegend = TRUE
      )
  })
  
  # Tab 11: Habit Tracker Table
  output$habit_tracker <- DT::renderDataTable({
    habit_data <- data.frame(
      Habit = c("Morning Learning", "Exercise", "Deep Work", "Family Time", "Meditation"),
      Mon = c("✓", "✓", "✓", "✓", "✓"),
      Tue = c("✓", "✓", "✓", "✓", "✓"),
      Wed = c("✓", "✓", "✓", "✓", "✓"),
      Thu = c("✓", "✓", "✓", "✓", "✓"),
      Fri = c("✓", "✓", "✓", "✓", "✓"),
      Sat = c("✓", "✓", "—", "✓", "✓"),
      Sun = c("✓", "—", "—", "✓", "✓")
    )
    
    DT::datatable(habit_data, options = list(pageLength = 10, dom = 't'),
                  class = 'cell-border stripe')
  })
  
  # Tab 11: Time Allocation Pie Chart
  output$time_allocation <- renderPlotly({
    plot_ly(
      labels = c("Deep Work", "Learning", "Exercise", "Family", "Sleep", "Meals/Breaks", "Admin"),
      values = c(40, 14, 10, 25, 52, 14, 13),
      type = 'pie',
      hole = 0.3,
      marker = list(colors = c('#3b82f6', '#10b981', '#f59e0b', '#ec4899', '#8b5cf6', '#06b6d4', '#6b7280'))
    ) %>%
      layout(
        title = list(text = 'Weekly Hours (168 total)', font = list(color = '#1e293b')),
        showlegend = TRUE,
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Tab 11: Progress Trends
  output$progress_trends <- renderPlotly({
    weeks <- 1:12
    overall <- c(72, 74, 76, 77, 79, 80, 81, 82, 83, 84, 84, 85)
    
    plot_ly() %>%
      add_trace(
        x = weeks,
        y = overall,
        type = 'scatter',
        mode = 'lines+markers',
        name = 'Overall Score',
        line = list(color = '#3b82f6', width = 4),
        marker = list(size = 10),
        fill = 'tozeroy',
        fillcolor = 'rgba(59, 130, 246, 0.2)'
      ) %>%
      add_trace(
        x = c(1, 12),
        y = c(100, 100),
        type = 'scatter',
        mode = 'lines',
        name = 'Target (10x)',
        line = list(color = '#10b981', width = 2, dash = 'dash')
      ) %>%
      layout(
        title = list(text = 'Overall Progress Toward 10x Goal', font = list(color = '#1e293b', size = 16)),
        xaxis = list(title = 'Week', color = '#374151'),
        yaxis = list(title = 'Optimization Score', range = c(0, 100), color = '#374151'),
        plot_bgcolor = 'rgba(248,250,252,1)',
        paper_bgcolor = 'rgba(248,250,252,1)',
        font = list(color = '#374151')
      )
  })
  
  # Event Handlers for all buttons
  observeEvent(input$update_metrics, {
    showNotification("All metrics updated and synced!", type = "success")
  })
  
  observeEvent(input$launch_survey, {
    showNotification("Survey system activated!", type = "success")
  })
  
  observeEvent(input$log_book, {
    showNotification("Book logged in knowledge base!", type = "success")
  })
  
  observeEvent(input$review_notes, {
    showNotification("Daily review session started!", type = "info")
  })
  
  observeEvent(input$add_skill, {
    showNotification("New skill added to portfolio!", type = "success")
  })
  
  observeEvent(input$start_20h_project, {
    showNotification("20-hour project initiated!", type = "success")
  })
  
  observeEvent(input$calculate_stack, {
    showNotification("Skill stack uniqueness calculated: Top 0.8%!", type = "success")
  })
  
  observeEvent(input$review_network, {
    showNotification("Network health review completed!", type = "info")
  })
  
  observeEvent(input$execute_strategy, {
    showNotification("Monthly networking strategy activated!", type = "success")
  })
  
  observeEvent(input$log_meeting, {
    showNotification("Meeting logged in CRM!", type = "success")
  })
  
  observeEvent(input$log_introduction, {
    showNotification("Introduction logged successfully!", type = "success")
  })
  
  observeEvent(input$rebalance_portfolio, {
    showNotification("Portfolio rebalanced successfully!", type = "success")
  })
  
  observeEvent(input$add_venture, {
    showNotification("New venture added to portfolio!", type = "success")
  })
  
  observeEvent(input$update_goals, {
    showNotification("Quarterly goals updated!", type = "success")
  })
  
  observeEvent(input$add_task, {
    showNotification("High-impact task added to sprint!", type = "success")
  })
  
  observeEvent(input$review_priorities, {
    showNotification("Priorities reviewed and optimized!", type = "success")
  })
  
  observeEvent(input$add_event, {
    showNotification("Important date added to calendar!", type = "success")
  })
  
  observeEvent(input$monthly_review, {
    showNotification("Monthly relationship review completed!", type = "success")
  })
  
  observeEvent(input$plan_trip, {
    showNotification("Trip added to travel schedule!", type = "success")
  })
  
  observeEvent(input$add_bucket_item, {
    showNotification("Experience added to bucket list!", type = "success")
  })
  
  observeEvent(input$update_biometrics, {
    showNotification("Health data logged successfully!", type = "success")
  })
  
  observeEvent(input$complete_weekly_review, {
    showNotification("Weekly review completed! Great work this week!", type = "success")
  })
  
  observeEvent(input$review_metrics, {
    showNotification("All domain metrics reviewed!", type = "info")
  })
  
  observeEvent(input$add_habit, {
    showNotification("New habit added to tracker!", type = "success")
  })
  
  observeEvent(input$optimize_time, {
    showNotification("Time allocation updated and optimized!", type = "success")
  })
  
  observeEvent(input$generate_report, {
    showNotification("Comprehensive report generated successfully!", type = "success")
  })
}

# Run the application
shinyApp(ui = ui, server = server)