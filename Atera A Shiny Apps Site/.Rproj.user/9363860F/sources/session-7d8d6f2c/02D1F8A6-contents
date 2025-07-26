library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(lubridate)
library(htmltools)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Cambridge MBA 2024/2025 Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Course Structure", tabName = "structure", icon = icon("graduation-cap")),
      menuItem("Academic Calendar", tabName = "calendar", icon = icon("calendar")),
      menuItem("Grades & Assessment", tabName = "grades", icon = icon("chart-line")),
      menuItem("Experiential Learning", tabName = "projects", icon = icon("project-diagram")),
      menuItem("Electives & Concentrations", tabName = "electives", icon = icon("bookmark")),
      menuItem("Attendance & Conduct", tabName = "conduct", icon = icon("user-check")),
      menuItem("Academic Integrity", tabName = "integrity", icon = icon("shield-alt")),
      menuItem("Student Support", tabName = "support", icon = icon("hands-helping"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
       /* Header styling */
       .skin-blue .main-header .navbar {
         background-color: #FF8C00 !important;
       }
       .skin-blue .main-header .logo {
         background-color: #FF8C00 !important;
         color: #000000 !important;
         border-bottom: 0 solid transparent;
       }
       .skin-blue .main-header .logo:hover {
         background-color: #FF7F00 !important;
       }
       
       /* Sidebar styling */
       .skin-blue .main-sidebar {
         background-color: #B8860B !important;
       }
       .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
         background-color: #FFD700 !important;
         color: #000000 !important;
         font-weight: bold;
       }
       .skin-blue .main-sidebar .sidebar .sidebar-menu a {
         color: #000000 !important;
       }
       .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
         background-color: #DAA520 !important;
         color: #000000 !important;
       }
       
       /* Content wrapper styling */
       .content-wrapper {
         background-color: #FFF8DC !important;
       }
       
       /* Box styling */
       .box {
         background-color: #FFFFE0 !important;
         border: 2px solid #DAA520 !important;
         border-radius: 8px !important;
         box-shadow: 0 4px 8px rgba(218, 165, 32, 0.3) !important;
       }
       .box.box-primary {
         border-top-color: #FF8C00 !important;
         border-top-width: 4px !important;
       }
       .box.box-primary .box-header {
         color: #000000 !important;
         background: linear-gradient(135deg, #FF8C00, #FFD700) !important;
         border-radius: 6px 6px 0 0 !important;
         border-bottom: 2px solid #DAA520 !important;
       }
       .box.box-primary .box-header .box-title {
         font-size: 18px !important;
         font-weight: bold !important;
         text-shadow: 1px 1px 2px rgba(0,0,0,0.1) !important;
       }
       .box-body {
         background-color: #FFFACD !important;
         color: #333333 !important;
         padding: 20px !important;
       }
       
       /* Text styling */
       p {
         color: #2F4F4F !important;
         line-height: 1.6 !important;
       }
       strong {
         color: #B8860B !important;
       }
       li {
         color: #2F4F4F !important;
         margin-bottom: 5px !important;
       }
       
       /* Example box styling */
       .example-box {
         background-color: #F0E68C !important;
         border: 1px solid #DAA520 !important;
         border-radius: 5px !important;
         padding: 10px !important;
         margin: 10px 0 !important;
       }
       
       /* Benefits and disadvantages styling */
       .benefits {
         background-color: #E6FFE6 !important;
         border-left: 4px solid #228B22 !important;
         padding: 10px !important;
         margin: 10px 0 !important;
       }
       
       .disadvantages {
         background-color: #FFE6E6 !important;
         border-left: 4px solid #DC143C !important;
         padding: 10px !important;
         margin: 10px 0 !important;
       }
       
       /* Link styling */
       a {
         color: #FF8C00 !important;
         text-decoration: none !important;
       }
       a:hover {
         color: #FF7F00 !important;
         text-decoration: underline !important;
       }
       
       /* Page title styling */
       .main-header .navbar-brand {
         color: #000000 !important;
         font-weight: bold !important;
       }
       
       /* Scrollbar styling */
       ::-webkit-scrollbar {
         width: 12px;
       }
       ::-webkit-scrollbar-track {
         background: #FFF8DC;
       }
       ::-webkit-scrollbar-thumb {
         background: #DAA520;
         border-radius: 6px;
       }
       ::-webkit-scrollbar-thumb:hover {
         background: #B8860B;
       }
     "))
    ),
    
    tabItems(
      # Tab 1: Course Structure
      tabItem(tabName = "structure",
              fluidRow(
                box(title = "Cambridge MBA Course Overview", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>The Cambridge MBA is a <strong>one-year, full-time programme</strong> with 123 assessed credits, 
                   structured across four terms with progressive learning.</p>
                   <p>Learn more at: <a href='https://www.jbs.cam.ac.uk/programmes/mba/' target='_blank'>
                   Cambridge Judge Business School MBA</a></p>")
                )
              ),
              fluidRow(
                box(title = "Credits Distribution", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("credits_chart")
                ),
                box(title = "Credit Summary Table", status = "primary", solidHeader = TRUE, width = 6,
                    DT::dataTableOutput("credits_table")
                )
              ),
              fluidRow(
                box(title = "Term Structure", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("term_structure")
                )
              )
      ),
      
      # Tab 2: Academic Calendar
      tabItem(tabName = "calendar",
              fluidRow(
                box(title = "Academic Year Calendar", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Academic year runs from <strong>mid-September 2024 to mid-September 2025</strong>.</p>
                   <p>View full academic calendar: <a href='https://www.jbs.cam.ac.uk/programmes/mba/admissions/key-dates/' target='_blank'>
                   MBA Key Dates</a></p>")
                )
              ),
              fluidRow(
                box(title = "Calendar View", status = "primary", solidHeader = TRUE, width = 8,
                    selectInput("month_select", "Select Month:", 
                                choices = c("September 2024" = "2024-09",
                                            "October 2024" = "2024-10",
                                            "November 2024" = "2024-11",
                                            "December 2024" = "2024-12",
                                            "January 2025" = "2025-01",
                                            "February 2025" = "2025-02",
                                            "March 2025" = "2025-03",
                                            "April 2025" = "2025-04",
                                            "May 2025" = "2025-05",
                                            "June 2025" = "2025-06",
                                            "July 2025" = "2025-07",
                                            "August 2025" = "2025-08",
                                            "September 2025" = "2025-09"),
                                selected = "2024-09"),
                    plotlyOutput("calendar_plot")
                ),
                box(title = "Key Dates", status = "primary", solidHeader = TRUE, width = 4,
                    DT::dataTableOutput("key_dates")
                )
              )
      ),
      
      # Tab 3: Grades & Assessment
      tabItem(tabName = "grades",
              fluidRow(
                box(title = "Assessment System", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Cambridge MBA maintains high academic standards with a minimum <strong>50% overall pass threshold</strong>.</p>
                   <p>Learn about academic regulations: <a href='https://www.jbs.cam.ac.uk/programmes/mba/student-experience/' target='_blank'>
                   Student Experience</a></p>")
                )
              ),
              fluidRow(
                box(title = "Grading Scale", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("grading_scale")
                ),
                box(title = "Assessment Types", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("assessment_types")
                )
              ),
              fluidRow(
                box(title = "Assessment Policies", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<div class='example-box'>
                   <h4>Key Policies:</h4>
                   <ul>
                   <li><strong>Late Submission:</strong> ≤24 hrs late: capped at 40%, 5 days late: 0% grade</li>
                   <li><strong>Re-marking:</strong> Must request within 5 working days for individual work only</li>
                   <li><strong>Mitigating Circumstances:</strong> Formal process for extensions due to emergencies</li>
                   <li><strong>Plagiarism Checks:</strong> All submissions checked via Turnitin</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 4: Experiential Learning
      tabItem(tabName = "projects",
              fluidRow(
                box(title = "Experiential Learning Projects", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Three flagship projects define the applied learning experience at Cambridge.</p>
                   <p>Explore project opportunities: <a href='https://www.jbs.cam.ac.uk/programmes/mba/curriculum/experiential-learning/' target='_blank'>
                   Experiential Learning</a></p>")
                )
              ),
              fluidRow(
                box(title = "Project Timeline", status = "primary", solidHeader = TRUE, width = 8,
                    plotlyOutput("projects_timeline")
                ),
                box(title = "Project Credits", status = "primary", solidHeader = TRUE, width = 4,
                    plotlyOutput("project_credits")
                )
              ),
              fluidRow(
                box(title = "Cambridge Venture Project (CVP)", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <strong>6 Credits | Michaelmas Term</strong><br>
                   • Work with startups/SMEs<br>
                   • Market research & analysis<br>
                   • 5-6 student teams<br>
                   • Client presentation required
                   </div>")
                ),
                box(title = "Global Consulting Project (GCP)", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <strong>12 Credits | Lent Term</strong><br>
                   • Corporate/NGO clients<br>
                   • 4-week full-time project<br>
                   • International opportunities<br>
                   • Career pipeline potential
                   </div>")
                ),
                box(title = "Summer Activity", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <strong>6 Credits | Summer Term</strong><br>
                   • Individual Project (IP)<br>
                   • Work Placement (WP)<br>
                   • Lean Six Sigma Certification<br>
                   • International Study Trip
                   </div>")
                )
              )
      ),
      
      # Tab 5: Electives & Concentrations
      tabItem(tabName = "electives",
              fluidRow(
                box(title = "Electives & Concentrations Overview", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Over <strong>40 elective courses</strong> available to customize your MBA experience.</p>
                   <p>Browse course offerings: <a href='https://www.jbs.cam.ac.uk/programmes/mba/curriculum/electives/' target='_blank'>
                   MBA Electives</a></p>")
                )
              ),
              fluidRow(
                box(title = "Elective Distribution", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("electives_chart")
                ),
                box(title = "Available Concentrations", status = "primary", solidHeader = TRUE, width = 6,
                    DT::dataTableOutput("concentrations_table")
                )
              ),
              fluidRow(
                box(title = "Sample Electives", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("electives_sample")
                )
              )
      ),
      
      # Tab 6: Attendance & Conduct
      tabItem(tabName = "conduct",
              fluidRow(
                box(title = "Attendance & Professional Conduct", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>High standards for attendance, conduct, and teamwork are essential to MBA success.</p>
                   <p>Student handbook: <a href='https://www.jbs.cam.ac.uk/programmes/mba/student-experience/student-handbook/' target='_blank'>
                   MBA Student Handbook</a></p>")
                )
              ),
              fluidRow(
                box(title = "Attendance Requirements", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>Minimum 75% Attendance Required</h4>
                   <ul>
                   <li>All lectures and workshops</li>
                   <li>Electives and coach nights</li>
                   <li>Team meetings and projects</li>
                   <li>Pre-approved leave only for emergencies</li>
                   </ul>
                   </div>")
                ),
                box(title = "Professional Conduct Standards", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='benefits'>
                   <h4>Expected Behaviors</h4>
                   <ul>
                   <li>Respect for peers and faculty</li>
                   <li>Business etiquette compliance</li>
                   <li>Punctuality and preparation</li>
                   <li>Appropriate dress code</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Team Promise Framework", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<div class='example-box'>
                   <h3>Key Teamwork Commitments:</h3>
                   <ul>
                   <li><strong>Equal Participation:</strong> Fair distribution of tasks and responsibilities</li>
                   <li><strong>Clear Communication:</strong> Respectful and constructive dialogue</li>
                   <li><strong>Team Success Focus:</strong> Prioritizing collective achievement</li>
                   <li><strong>Constructive Feedback:</strong> Supporting growth and improvement</li>
                   <li><strong>Conflict Resolution:</strong> Internal resolution before escalation</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 7: Academic Integrity
      tabItem(tabName = "integrity",
              fluidRow(
                box(title = "Academic Integrity Standards", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Cambridge maintains world-class standards for academic integrity and ethical conduct.</p>
                   <p>Academic integrity guidelines: <a href='https://www.plagiarism.admin.cam.ac.uk/' target='_blank'>
                   Cambridge Plagiarism Guidelines</a></p>")
                )
              ),
              fluidRow(
                box(title = "Prohibited Practices", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='disadvantages'>
                   <h4>Plagiarism Violations</h4>
                   <ul>
                   <li>Using others' work without citation</li>
                   <li>Recycling past work without disclosure</li>
                   <li>AI-generated content submission</li>
                   <li>Unauthorized collaboration</li>
                   </ul>
                   </div>")
                ),
                box(title = "AI Usage Policy", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='disadvantages'>
                   <h4>Generative AI Restrictions</h4>
                   <ul>
                   <li>ChatGPT, Gemini, Copilot prohibited</li>
                   <li>No AI content generation allowed</li>
                   <li>No AI editing or review permitted</li>
                   <li>Must disclose any AI assistance</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Consequences & Appeals", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("integrity_consequences")
                )
              )
      ),
      
      # Tab 8: Student Support
      tabItem(tabName = "support",
              fluidRow(
                box(title = "Comprehensive Student Support System", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Cambridge provides extensive support for student wellbeing, career development, and academic success.</p>
                   <p>Student services: <a href='https://www.studentwellbeing.admin.cam.ac.uk/' target='_blank'>
                   Student Wellbeing</a> | <a href='https://www.careers.cam.ac.uk/' target='_blank'>Careers Service</a></p>")
                )
              ),
              fluidRow(
                box(title = "College Support", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <h4>31 Cambridge Colleges Provide:</h4>
                   <ul>
                   <li>Personal tutors for guidance</li>
                   <li>Healthcare and nursing</li>
                   <li>Counselling referrals</li>
                   <li>Accommodation support</li>
                   </ul>
                   </div>")
                ),
                box(title = "CJBS MBA Office", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <h4>Direct MBA Support:</h4>
                   <ul>
                   <li>Academic administration</li>
                   <li>Project coordination</li>
                   <li>Student experience team</li>
                   <li>Diversity & inclusion lead</li>
                   </ul>
                   </div>")
                ),
                box(title = "University Services", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <h4>Campus-wide Resources:</h4>
                   <ul>
                   <li>Counselling services (24/7)</li>
                   <li>Disability resource centre</li>
                   <li>Student advice service</li>
                   <li>Mental health support</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Career Services & Alumni Network", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<div class='example-box'>
                   <h3>Career Development Support:</h3>
                   <ul>
                   <li><strong>One-on-one Coaching:</strong> Personalized career guidance and planning</li>
                   <li><strong>Skills Development:</strong> CV/resume workshops, interview preparation, case study practice</li>
                   <li><strong>Industry Access:</strong> Sector-specific support for consulting, tech, finance, and impact careers</li>
                   <li><strong>Global Opportunities:</strong> Career treks to London, Berlin, Dubai, and Hong Kong</li>
                   <li><strong>Lifelong Network:</strong> Access to CJBS and Cambridge University alumni networks</li>
                   <li><strong>Entrepreneurship:</strong> Angel investing and startup support through alumni connections</li>
                   </ul>
                   </div>")
                )
              )
      )
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Tab 1: Course Structure
  output$credits_chart <- renderPlotly({
    credits_data <- data.frame(
      Component = c("Core Courses", "Electives", "CVP", "GCP", "Concentration", "Summer Activity"),
      Credits = c(69, 18, 6, 12, 6, 6)
    )
    
    p <- plot_ly(credits_data, x = ~Component, y = ~Credits, type = 'bar',
                 marker = list(color = c('#FF8C00', '#FFD700', '#DAA520', '#B8860B', '#F0E68C', '#DEB887'))) %>%
      layout(title = "Credit Distribution by Component",
             xaxis = list(title = "Components"),
             yaxis = list(title = "Credits"),
             plot_bgcolor = '#FFF8DC',
             paper_bgcolor = '#FFF8DC')
    p
  })
  
  output$credits_table <- DT::renderDataTable({
    credits_summary <- data.frame(
      Component = c("Core Courses (Michaelmas-Lent)", "Electives (6 x 3)", "CVP", "GCP", "Concentration Project", "Summer Activity", "TOTAL"),
      Credits = c(69, 18, 6, 12, 6, 6, 123)
    )
    DT::datatable(credits_summary, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  output$term_structure <- DT::renderDataTable({
    terms_data <- data.frame(
      Term = c("Michaelmas (Sep-Dec)", "Lent (Jan-Mar)", "Easter (Apr-Jun)", "Summer (Jun-Sep)"),
      Focus = c("Foundations", "Strategic Application", "Advanced Practice", "Integration & Reflection"),
      KeyCourses = c("Microeconomics, Finance, Management Science", "Strategy, Marketing, Digital Business", "Operations, Advanced Strategy", "Individual Projects, Placements"),
      Credits = c("42 (incl. CVP)", "33 (incl. GCP)", "24", "6")
    )
    DT::datatable(terms_data, options = list(pageLength = 4, scrollX = TRUE), rownames = FALSE)
  })
  
  # Tab 2: Academic Calendar
  output$calendar_plot <- renderPlotly({
    calendar_events <- data.frame(
      Date = as.Date(c("2024-09-16", "2024-12-09", "2024-12-13", "2025-01-13", "2025-03-10", "2025-03-14", 
                       "2025-04-22", "2025-06-09", "2025-06-16", "2025-06-20", "2025-09-12")),
      Event = c("Term Start", "Michaelmas Exams", "Michaelmas End", "Lent Start", "Lent Exams", "Lent End",
                "Easter Start", "Easter Exams", "Capstone Week", "Easter End", "Final Report Due"),
      Type = c("Term", "Exam", "Term", "Term", "Exam", "Term", "Term", "Exam", "Special", "Term", "Deadline")
    )
    
    selected_month <- input$month_select
    month_start <- as.Date(paste0(selected_month, "-01"))
    month_end <- month_start + months(1) - days(1)
    
    month_events <- calendar_events[calendar_events$Date >= month_start & calendar_events$Date <= month_end, ]
    
    if(nrow(month_events) > 0) {
      p <- plot_ly(month_events, x = ~Date, y = ~Event, type = 'scatter', mode = 'markers+text',
                   text = ~Event, textposition = 'middle right',
                   marker = list(size = 12, color = ~Type, 
                                 colorscale = list(c(0, '#FF8C00'), c(0.5, '#FFD700'), c(1, '#B8860B')))) %>%
        layout(title = paste("Events for", format(month_start, "%B %Y")),
               xaxis = list(title = "Date"),
               yaxis = list(title = "Events"),
               plot_bgcolor = '#FFF8DC',
               paper_bgcolor = '#FFF8DC')
    } else {
      p <- plot_ly() %>%
        add_text(x = 0.5, y = 0.5, text = "No events this month", 
                 showarrow = FALSE, xref = "paper", yref = "paper") %>%
        layout(title = paste("Events for", format(month_start, "%B %Y")),
               plot_bgcolor = '#FFF8DC',
               paper_bgcolor = '#FFF8DC')
    }
    p
  })
  
  output$key_dates <- DT::renderDataTable({
    key_dates_data <- data.frame(
      Date = c("16 Sep 2024", "13 Dec 2024", "13 Jan 2025", "14 Mar 2025", "22 Apr 2025", "20 Jun 2025"),
      Event = c("Michaelmas Start", "Michaelmas End", "Lent Start", "Lent End", "Easter Start", "Easter End")
    )
    DT::datatable(key_dates_data, options = list(dom = 't', pageLength = 6), rownames = FALSE)
  })
  
  # Tab 3: Grades & Assessment
  output$grading_scale <- renderPlotly({
    grade_data <- data.frame(
      Grade = c("80%+", "70-79%", "60-69%", "50-59%", "<50%"),
      Description = c("Exceptional", "High Performance", "Good", "Pass", "Fail"),
      Count = c(5, 15, 35, 35, 10)  # Representative distribution
    )
    
    p <- plot_ly(grade_data, labels = ~Grade, values = ~Count, type = 'pie',
                 marker = list(colors = c('#228B22', '#32CD32', '#FFD700', '#FF8C00', '#DC143C'))) %>%
      layout(title = "Grade Distribution (Typical)",
             plot_bgcolor = '#FFF8DC',
             paper_bgcolor = '#FFF8DC')
    p
  })
  
  output$assessment_types <- renderPlotly({
    assessment_data <- data.frame(
      Type = c("Examinations", "Group Projects", "Individual Assignments", "Participation", "Quizzes"),
      Percentage = c(30, 35, 25, 5, 5)
    )
    
    p <- plot_ly(assessment_data, x = ~Type, y = ~Percentage, type = 'bar',
                 marker = list(color = '#FF8C00')) %>%
      layout(title = "Assessment Types Distribution",
             xaxis = list(title = "Assessment Type"),
             yaxis = list(title = "Percentage"),
             plot_bgcolor = '#FFF8DC',
             paper_bgcolor = '#FFF8DC')
    p
  })
  
  # Tab 4: Experiential Learning
  output$projects_timeline <- renderPlotly({
    projects_data <- data.frame(
      Project = c("CVP", "GCP", "Summer Activity"),
      Start = as.Date(c("2024-09-16", "2025-01-13", "2025-06-30")),
      End = as.Date(c("2024-12-13", "2025-03-14", "2025-09-12")),
      Credits = c(6, 12, 6)
    )
    
    p <- plot_ly(projects_data, x = ~Start, xend = ~End, y = ~Project, yend = ~Project,
                 type = 'scatter', mode = 'lines',
                 line = list(width = 10, color = ~Credits, colorscale = 'Viridis')) %>%
      layout(title = "Project Timeline",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Projects"),
             plot_bgcolor = '#FFF8DC',
             paper_bgcolor = '#FFF8DC')
    p
  })
  
  output$project_credits <- renderPlotly({
    project_credits <- data.frame(
      Project = c("CVP", "GCP", "Summer"),
      Credits = c(6, 12, 6)
    )
    
    p <- plot_ly(project_credits, labels = ~Project, values = ~Credits, type = 'pie',
                 marker = list(colors = c('#FF8C00', '#FFD700', '#DAA520'))) %>%
      layout(title = "Project Credits Distribution",
             plot_bgcolor = '#FFF8DC',
             paper_bgcolor = '#FFF8DC')
    p
  })
  
  # Tab 5: Electives & Concentrations
  output$electives_chart <- renderPlotly({
    elective_terms <- data.frame(
      Term = c("Lent", "Easter"),
      Electives = c(3, 3),
      Credits = c(9, 9)
    )
    
    p <- plot_ly(elective_terms, x = ~Term, y = ~Electives, type = 'bar', name = 'Number of Electives',
                 marker = list(color = '#FF8C00')) %>%
      add_trace(y = ~Credits, name = 'Credits', marker = list(color = '#FFD700')) %>%
      layout(title = "Electives by Term",
             xaxis = list(title = "Term"),
             yaxis = list(title = "Count/Credits"),
             plot_bgcolor = '#FFF8DC',
             paper_bgcolor = '#FFF8DC')
    p
  })
  
  output$concentrations_table <- DT::renderDataTable({
    concentrations <- data.frame(
      Concentration = c("Strategy", "Marketing", "Finance", "Energy & Environment", "Healthcare", 
                        "Cultural Arts & Media", "Digital Transformation", "Sustainable Business", "Entrepreneurship"),
      Focus = c("Competitive advantage", "Consumer behavior", "Investment analysis", "Sustainability", "Health systems",
                "Creative industries", "Technology disruption", "ESG strategies", "Startup ventures")
    )
    DT::datatable(concentrations, options = list(pageLength = 5, scrollY = "200px"), rownames = FALSE)
  })
  
  output$electives_sample <- DT::renderDataTable({
    electives_sample <- data.frame(
      Course = c("Financial Modelling", "Entrepreneurial Finance", "Behavioural Economics", "Sustainable Business",
                 "Innovation Management", "Private Equity", "Health Strategy", "Digital Transformation"),
      Credits = rep(3, 8),
      Term = c("Lent", "Easter", "Lent", "Easter", "Lent", "Easter", "Lent", "Easter"),
      Description = c("Advanced Excel & financial analysis", "Startup funding strategies", "Psychology in economics",
                      "ESG and impact investing", "R&D and product development", "Investment fund operations",
                      "Healthcare industry analysis", "Digital business models")
    )
    DT::datatable(electives_sample, options = list(pageLength = 8, scrollX = TRUE), rownames = FALSE)
  })
  
  # Tab 7: Academic Integrity
  output$integrity_consequences <- renderPlotly({
    consequences_data <- data.frame(
      Violation = c("First Offense", "Repeated Plagiarism", "Severe Misconduct", "Exam Cheating"),
      Consequence = c("Zero Grade", "Module Failure", "Suspension", "Expulsion"),
      Severity = c(1, 2, 3, 4)
    )
    
    colors <- c('#FFD700', '#FF8C00', '#FF4500', '#DC143C')
    
    p <- plot_ly(consequences_data, x = ~Violation, y = ~Severity, type = 'bar',
                 marker = list(color = colors)) %>%
      layout(title = "Academic Integrity Violation Consequences",
             xaxis = list(title = "Type of Violation"),
             yaxis = list(title = "Severity Level (1-4)"),
             plot_bgcolor = '#FFF8DC',
             paper_bgcolor = '#FFF8DC')
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)