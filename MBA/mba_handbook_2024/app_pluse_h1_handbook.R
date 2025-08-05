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
      menuItem("Term Dates & Key Events", tabName = "term_dates", icon = icon("clock")),
      menuItem("Grades & Assessment", tabName = "grades", icon = icon("chart-line")),
      menuItem("Experiential Learning", tabName = "projects", icon = icon("project-diagram")),
      menuItem("Electives & Concentrations", tabName = "electives", icon = icon("bookmark")),
      menuItem("Summer Term Options", tabName = "summer", icon = icon("sun")),
      menuItem("Attendance & Conduct", tabName = "conduct", icon = icon("user-check")),
      menuItem("Academic Integrity", tabName = "integrity", icon = icon("shield-alt")),
      menuItem("Student Support", tabName = "support", icon = icon("hands-helping")),
      menuItem("Policies & Procedures", tabName = "policies", icon = icon("file-text")),
      menuItem("Study Groups & Streams", tabName = "groups", icon = icon("users")),
      menuItem("Contact Information", tabName = "contact", icon = icon("phone"))
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
                    HTML("<p>The Cambridge MBA is a <strong>one-year, full-time programme</strong> with <strong>123 assessed credits</strong>, 
                   structured across four terms with progressive learning.</p>
                   <p><strong>Pass Requirements:</strong></p>
                   <ul>
                   <li>Achieve <strong>50% overall</strong> in your 123 assessed credits</li>
                   <li>Have <strong>diligently attended</strong> all courses for credit</li>
                   </ul>
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
                box(title = "Complete Course Structure by Term", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("full_course_structure")
                )
              )
      ),
      
      # Tab 2: Academic Calendar Overview
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
                box(title = "Key Academic Dates", status = "primary", solidHeader = TRUE, width = 4,
                    DT::dataTableOutput("key_dates")
                )
              )
      ),
      
      # Tab 3: Term Dates & Key Events
      tabItem(tabName = "term_dates",
              fluidRow(
                box(title = "Term Dates 2024/2025", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p><strong>Important:</strong> The dates for the MBA terms may differ from those quoted 
                   in University of Cambridge or College publications. Students are required to be available for 
                   classes and group work during term time, and the GCP project period.</p>")
                )
              ),
              fluidRow(
                box(title = "Michaelmas Term", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>16 September - 13 December 2024</h4>
                   <ul>
                   <li><strong>Professional Development:</strong> 4-8 November</li>
                   <li><strong>CVP Presentations:</strong> Week commencing 2 December</li>
                   <li><strong>Examinations:</strong> Week commencing 9 December</li>
                   </ul>
                   </div>")
                ),
                box(title = "Lent Term", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>13 January - 14 March 2025</h4>
                   <ul>
                   <li><strong>Core Teaching:</strong> Strategy, Marketing, Ethics</li>
                   <li><strong>Examinations:</strong> Week commencing 10 March</li>
                   <li><strong>Global Consulting Project:</strong> 17 March - 18 April</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Easter Term", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>22 April - 20 June 2025</h4>
                   <ul>
                   <li><strong>Examinations:</strong> Week commencing 9 June</li>
                   <li><strong>Concentration Presentations:</strong> Week commencing 16 June</li>
                   <li><strong>Capstone Week:</strong> 16-20 June 2025</li>
                   </ul>
                   </div>")
                ),
                box(title = "Summer Term", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>30 June - 12 September 2025</h4>
                   <ul>
                   <li><strong>Individual Projects/Work Placements</strong></li>
                   <li><strong>Research Papers</strong></li>
                   <li><strong>International Business Study Trips</strong></li>
                   <li><strong>Final Report Deadline:</strong> 12 September 2025</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Important Selection Windows", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("selection_windows")
                )
              )
      ),
      
      # Tab 4: Grades & Assessment
      tabItem(tabName = "grades",
              fluidRow(
                box(title = "Assessment System", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Cambridge MBA maintains high academic standards with a minimum <strong>50% overall pass threshold</strong>.</p>
                   <p><strong>Key Requirements:</strong></p>
                   <ul>
                   <li>Achieve 50% overall in your 123 assessed credits</li>
                   <li>Diligently attend all courses for credit</li>
                   <li>Complete all course requirements before the end of academic year</li>
                   </ul>
                   <p>Learn about academic regulations: <a href='https://www.jbs.cam.ac.uk/programmes/mba/student-experience/' target='_blank'>
                   Student Experience</a></p>")
                )
              ),
              fluidRow(
                box(title = "Cambridge Marking Standards", status = "primary", solidHeader = TRUE, width = 8,
                    DT::dataTableOutput("marking_standards")
                ),
                box(title = "GPA Conversion Guide", status = "primary", solidHeader = TRUE, width = 4,
                    DT::dataTableOutput("gpa_conversion")
                )
              ),
              fluidRow(
                box(title = "Assessment Types", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("assessment_types")
                ),
                box(title = "Assessment Policies", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>Key Assessment Policies:</h4>
                   <ul>
                   <li><strong>Late Submission:</strong> ≤24 hrs late: capped at 40%, >5 days late: 0% grade</li>
                   <li><strong>Re-marking:</strong> Must request within 5 working days for individual work only</li>
                   <li><strong>Mitigating Circumstances:</strong> Formal process for extensions due to emergencies</li>
                   <li><strong>Plagiarism Checks:</strong> All submissions checked via Turnitin</li>
                   <li><strong>Word Count:</strong> Penalties apply for exceeding limits</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 5: Experiential Learning
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
                   • Work with startups/SMEs from Cambridge/London area<br>
                   • Market research & analysis projects<br>
                   • 5-6 student teams (study groups)<br>
                   • Deliverables: PID + Final presentation<br>
                   • Links to Management Praxis course<br>
                   • Client presentation in December
                   </div>")
                ),
                box(title = "Global Consulting Project (GCP)", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <strong>12 Credits | Lent Term</strong><br>
                   • Corporate/NGO clients worldwide<br>
                   • 4-week full-time project (17 Mar - 18 Apr)<br>
                   • Strategic reviews, benchmarking, market analysis<br>
                   • Deliverables: PID, Risk Assessment, Final Report<br>
                   • Career pipeline potential<br>
                   • Expenses often covered by client
                   </div>")
                ),
                box(title = "Summer Activity Options", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <strong>6 Credits | Summer Term</strong><br>
                   • Individual Project (IP)<br>
                   • Work Placement (WP)<br>
                   • Research Paper<br>
                   • Case Writing<br>
                   • Lean Six Sigma Green Belt<br>
                   • International Study Trip (IBST)
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Project Requirements & Policies", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<div class='example-box'>
                   <h4>Important Requirements:</h4>
                   <ul>
                   <li><strong>Risk Assessments:</strong> Required for all external work, individual and student-specific</li>
                   <li><strong>Project Initiation Document (PID):</strong> Must be signed off by client and supervisor</li>
                   <li><strong>Confidentiality:</strong> General NDA applies to all projects</li>
                   <li><strong>Student Visa Holders:</strong> WP/IP must be credit-bearing part of course</li>
                   <li><strong>Insurance:</strong> University travel insurance available for international projects</li>
                   <li><strong>Summer Projects:</strong> Minimum 6 weeks, student-sourced, final deadline 12 Sept 2025</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 6: Electives & Concentrations
      tabItem(tabName = "electives",
              fluidRow(
                box(title = "Electives & Concentrations Overview", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Over <strong>40 elective courses</strong> available to customize your MBA experience.</p>
                   <p><strong>Requirements:</strong> 6 electives total (3 in Lent Term, 3 in Easter Term)</p>
                   <p>Browse course offerings: <a href='https://www.jbs.cam.ac.uk/programmes/mba/curriculum/electives/' target='_blank'>
                   MBA Electives</a></p>")
                )
              ),
              fluidRow(
                box(title = "Elective Selection Process", status = "primary", solidHeader = TRUE, width = 8,
                    HTML("<div class='example-box'>
                   <h4>Step-by-step Elective Selection:</h4>
                   <ol>
                   <li><strong>Read materials</strong> on MBA Programme Site</li>
                   <li><strong>Attend mandatory</strong> elective information session</li>
                   <li><strong>Review clash grid</strong> and subject information</li>
                   <li><strong>Note capped classes</strong> that require early selection</li>
                   <li><strong>Approach faculty</strong> with subject-specific questions</li>
                   <li><strong>Choose backup options</strong> where required</li>
                   <li><strong>Mark selection windows</strong> in calendar</li>
                   <li><strong>Make selections</strong> when window opens (first-come, first-served)</li>
                   </ol>
                   <p><strong>Important:</strong> No changes permitted after window closes!</p>
                   </div>")
                ),
                box(title = "Available Concentrations", status = "primary", solidHeader = TRUE, width = 4,
                    DT::dataTableOutput("concentrations_table")
                )
              ),
              fluidRow(
                box(title = "Concentration Requirements", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='benefits'>
                   <h4>For Each Concentration (6 Credits):</h4>
                   <ul>
                   <li><strong>Choose appropriate electives</strong> (at least 2 out of 6 must be in concentration area)</li>
                   <li><strong>Attend Coach Night sessions</strong> during Easter Term</li>
                   <li><strong>Complete Concentration Project</strong> (~40 hours per person)</li>
                   <li><strong>Present to mock panel/board</strong> during Capstone Week</li>
                   </ul>
                   <p><strong>Note:</strong> Concentrations with fewer than 10 students will be cancelled</p>
                   </div>")
                ),
                box(title = "Auditing Policy", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='disadvantages'>
                   <h4>Auditing Classes (Optional):</h4>
                   <ul>
                   <li>Maximum <strong>one audit class per term</strong></li>
                   <li><strong>Take full and active part</strong> in class</li>
                   <li><strong>Attend all sessions</strong> in full</li>
                   <li><strong>No assessment submission</strong></li>
                   <li><strong>Will not appear on transcript</strong></li>
                   <li><strong>Cannot switch to credit</strong> after selection</li>
                   </ul>
                   <p><strong>Note:</strong> Not all electives permit auditors</p>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Sample Electives by Concentration", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("electives_sample")
                )
              )
      ),
      
      # Tab 7: Summer Term Options
      tabItem(tabName = "summer",
              fluidRow(
                box(title = "Summer Term Activity Options", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>The Summer Term (June-September) allows you to choose an area of interest to explore more closely.</p>
                   <p><strong>Selection Window:</strong> 2 May - 30 May 2025</p>
                   <p><strong>Final Deadline:</strong> All reports due Friday 12 September 2025 at 14:00 UK time</p>")
                )
              ),
              fluidRow(
                box(title = "Work Placement (WP)", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <h4>Internship with Client Firm</h4>
                   <ul>
                   <li><strong>Minimum 6 weeks</strong> full-time</li>
                   <li><strong>Student-sourced</strong> opportunities</li>
                   <li><strong>Expenses often covered</strong> by client</li>
                   <li><strong>Career pipeline potential</strong></li>
                   <li><strong>Reflective report</strong> (max 4000 words)</li>
                   </ul>
                   </div>")
                ),
                box(title = "Individual Project (IP)", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <h4>Bespoke Study for Client</h4>
                   <ul>
                   <li><strong>Minimum 6 weeks</strong> full-time</li>
                   <li><strong>Any commercial/NGO</strong> organization</li>
                   <li><strong>Strategic reviews, analysis</strong></li>
                   <li><strong>Student-sourced</strong> projects</li>
                   <li><strong>Reflective report</strong> (max 4000 words)</li>
                   </ul>
                   </div>")
                ),
                box(title = "Research Paper", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <h4>Independent Academic Research</h4>
                   <ul>
                   <li><strong>General management</strong> or concentration focus</li>
                   <li><strong>Business audience</strong> style (HBR, Sloan)</li>
                   <li><strong>In-depth research</strong> for full summer</li>
                   <li><strong>Academic frameworks</strong> basis</li>
                   <li><strong>Research paper</strong> (max 4000 words)</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Other Summer Options", status = "primary", solidHeader = TRUE, width = 8,
                    HTML("<div class='example-box'>
                   <h4>Additional Summer Activities:</h4>
                   <ul>
                   <li><strong>Case Writing:</strong> Develop pedagogical case study of organization facing business challenge</li>
                   <li><strong>Lean Six Sigma Green Belt:</strong> Professional certification course (open to auditors)</li>
                   <li><strong>International Business Study Trip (IBST):</strong> Group travel for business learning</li>
                   </ul>
                   <p><strong>All options:</strong> Reflective report required (max 4000 words)</p>
                   </div>")
                ),
                box(title = "Important Considerations", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='disadvantages'>
                   <h4>Key Requirements:</h4>
                   <ul>
                   <li><strong>Student visa holders:</strong> Must select credit option</li>
                   <li><strong>No funding</strong> provided by CJBS</li>
                   <li><strong>No deadline extensions</strong> permitted</li>
                   <li><strong>PID required</strong> for WP/IP options</li>
                   <li><strong>Risk assessment</strong> mandatory</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 8: Attendance & Conduct
      tabItem(tabName = "conduct",
              fluidRow(
                box(title = "Attendance & Professional Conduct", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>High standards for attendance, conduct, and teamwork are essential to MBA success.</p>
                   <p><strong>'Diligent Attendance' Requirement:</strong> Absence must not exceed 25% of any credit-bearing course</p>
                   <p>Student handbook: <a href='https://www.jbs.cam.ac.uk/programmes/mba/student-experience/student-handbook/' target='_blank'>
                   MBA Student Handbook</a></p>")
                )
              ),
              fluidRow(
                box(title = "Attendance Policy", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>Diligent Attendance Requirements:</h4>
                   <ul>
                   <li><strong>All compulsory credited classes</strong> must be attended</li>
                   <li><strong>Maximum 25% absence</strong> per course permitted</li>
                   <li><strong>Pre-approval required</strong> for absences (24hrs+ in advance)</li>
                   <li><strong>Medical certificate</strong> or verification needed</li>
                   <li><strong>Extra-curricular activities</strong> not considered exceptional</li>
                   <li><strong>Automatic attendance tracking</strong> in place</li>
                   </ul>
                   </div>")
                ),
                box(title = "MBA Teamwork Promise", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='benefits'>
                   <h4>Key Commitments:</h4>
                   <ul>
                   <li><strong>Active participation</strong> in team decision-making</li>
                   <li><strong>Equal or exceeding contribution</strong> in time and effort</li>
                   <li><strong>Complete assigned tasks</strong> punctually</li>
                   <li><strong>Attend all team meetings</strong> on time</li>
                   <li><strong>Stay current</strong> with class material</li>
                   <li><strong>No plagiarism</strong> and proper sourcing</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Professional Standards", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='benefits'>
                   <h4>Expected Professional Behavior:</h4>
                   <ul>
                   <li><strong>Courtesy and respect</strong> for all community members</li>
                   <li><strong>Business attire</strong> for events and presentations</li>
                   <li><strong>Punctuality</strong> for all sessions</li>
                   <li><strong>Mobile phones off</strong> in lectures and labs</li>
                   <li><strong>Proper preparation</strong> for all classes</li>
                   <li><strong>Camera on</strong> for online sessions</li>
                   </ul>
                   </div>")
                ),
                box(title = "Commitment Rating System", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='disadvantages'>
                   <h4>Poor Commitment Rating Consequences:</h4>
                   <ul>
                   <li><strong>Maintained throughout year</strong> with termly reviews</li>
                   <li><strong>Used for employer recommendations</strong></li>
                   <li><strong>Affects event participation</strong> permissions</li>
                   <li><strong>No financial support</strong> for competitions</li>
                   <li><strong>Unlikely to receive distinction</strong> or Director's Award</li>
                   <li><strong>Based on:</strong> Disengagement, late submissions, poor attendance</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 9: Academic Integrity
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
                   <h4>Plagiarism Violations:</h4>
                   <ul>
                   <li><strong>Using others' work</strong> without proper citation</li>
                   <li><strong>Recycling past work</strong> without disclosure</li>
                   <li><strong>Unauthorized collaboration</strong> on individual work</li>
                   <li><strong>Unfair means in examinations</strong></li>
                   <li><strong>All submissions checked</strong> via Turnitin</li>
                   </ul>
                   </div>")
                ),
                box(title = "AI Usage Policy", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='disadvantages'>
                   <h4>Generative AI Restrictions:</h4>
                   <ul>
                   <li><strong>ChatGPT, Gemini, Copilot</strong> prohibited for coursework</li>
                   <li><strong>No AI content generation</strong> allowed</li>
                   <li><strong>No AI editing or review</strong> permitted</li>
                   <li><strong>Must disclose any AI assistance</strong> if used</li>
                   <li><strong>Violation considered plagiarism</strong></li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Consequences & Appeals Process", status = "primary", solidHeader = TRUE, width = 12,
                    plotlyOutput("integrity_consequences")
                )
              ),
              fluidRow(
                box(title = "University Code of Conduct", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<div class='example-box'>
                   <h4>All students must observe University Statutes and Ordinances, including:</h4>
                   <ul>
                   <li><strong>No disruption</strong> of University activities or functions</li>
                   <li><strong>No impedance</strong> of freedom of speech or lawful assembly</li>
                   <li><strong>No unauthorized use</strong> of University or College property</li>
                   <li><strong>No damage or misappropriation</strong> of property</li>
                   <li><strong>No endangerment</strong> of safety, health, or property</li>
                   <li><strong>No harassment</strong> of any University community member</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 10: Student Support
      tabItem(tabName = "support",
              fluidRow(
                box(title = "Comprehensive Student Support System", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Cambridge provides extensive support for student wellbeing, career development, and academic success.</p>
                   <p>Student services: <a href='https://www.studentwellbeing.admin.cam.ac.uk/' target='_blank'>
                   Student Wellbeing</a> | <a href='https://www.careers.cam.ac.uk/' target='_blank'>Careers Service</a></p>")
                )
              ),
              fluidRow(
                box(title = "College Support (31 Colleges)", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <h4>College-Based Support:</h4>
                   <ul>
                   <li><strong>Personal tutors</strong> for academic guidance</li>
                   <li><strong>Healthcare and nursing</strong> services</li>
                   <li><strong>Counselling referrals</strong> and mental health support</li>
                   <li><strong>Accommodation support</strong> and housing</li>
                   <li><strong>Social and cultural</strong> activities</li>
                   </ul>
                   </div>")
                ),
                box(title = "CJBS MBA Office", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <h4>Direct MBA Programme Support:</h4>
                   <ul>
                   <li><strong>Academic administration</strong> and course coordination</li>
                   <li><strong>Project coordination</strong> (CVP, GCP, Summer)</li>
                   <li><strong>Student experience team</strong> for day-to-day issues</li>
                   <li><strong>Diversity & inclusion lead</strong></li>
                   <li><strong>Academic Student Representatives</strong> liaison</li>
                   </ul>
                   </div>")
                ),
                box(title = "University-Wide Services", status = "primary", solidHeader = TRUE, width = 4,
                    HTML("<div class='benefits'>
                   <h4>Campus Resources:</h4>
                   <ul>
                   <li><strong>Counselling services</strong> (24/7 availability)</li>
                   <li><strong>Accessibility and Disability</strong> Resource Centre (ADRC)</li>
                   <li><strong>Student advice service</strong> for various issues</li>
                   <li><strong>Mental health support</strong> and crisis intervention</li>
                   <li><strong>International student</strong> visa and immigration advice</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Career Services & Alumni Network", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<div class='example-box'>
                   <h3>Comprehensive Career Development Support:</h3>
                   <ul>
                   <li><strong>One-on-one Career Coaching:</strong> Personalized career guidance, planning, and strategy development</li>
                   <li><strong>Skills Development Workshops:</strong> CV/resume optimization, interview preparation, case study practice</li>
                   <li><strong>Industry-Specific Support:</strong> Dedicated support for consulting, technology, finance, and impact careers</li>
                   <li><strong>Global Career Opportunities:</strong> Career treks to London, Berlin, Dubai, Hong Kong, and other major cities</li>
                   <li><strong>Lifelong Alumni Network:</strong> Access to extensive CJBS and University of Cambridge alumni networks worldwide</li>
                   <li><strong>Entrepreneurship Support:</strong> Angel investing connections and startup ecosystem access through alumni</li>
                   <li><strong>Recruitment Events:</strong> Regular company presentations, networking events, and career fairs</li>
                   <li><strong>Industry Panels:</strong> Insights from professionals across various sectors and functions</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 11: Policies & Procedures
      tabItem(tabName = "policies",
              fluidRow(
                box(title = "Key Policies & Procedures", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Important policies governing your MBA experience at Cambridge Judge Business School.</p>")
                )
              ),
              fluidRow(
                box(title = "Data Protection & Privacy", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>GDPR Compliance & Data Handling:</h4>
                   <ul>
                   <li><strong>Personal information confidentiality</strong> must be respected</li>
                   <li><strong>No unauthorized use/transfer</strong> of classmate/staff data</li>
                   <li><strong>Written consent required</strong> for sharing information</li>
                   <li><strong>Bulk email restrictions</strong> - no spamming from University servers</li>
                   <li><strong>University collects data</strong> in accordance with GDPR</li>
                   </ul>
                   </div>")
                ),
                box(title = "Intellectual Property Rights", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>Student IP Ownership:</h4>
                   <ul>
                   <li><strong>Student owns IP</strong> they create (with exceptions)</li>
                   <li><strong>Sponsored students:</strong> Sponsor may own IP</li>
                   <li><strong>Sponsored projects:</strong> Check research contract</li>
                   <li><strong>Collaborative work:</strong> May require IP assignment</li>
                   <li><strong>Confidentiality agreements</strong> may apply for 3 months</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Copyright & Learning Materials", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='disadvantages'>
                   <h4>Strict Copyright Protections:</h4>
                   <ul>
                   <li><strong>All learning materials</strong> are copyrighted</li>
                   <li><strong>Personal use only</strong> - no sharing/distribution</li>
                   <li><strong>No recording</strong> of lectures without permission</li>
                   <li><strong>Include copyright notice</strong> on any copies made</li>
                   <li><strong>Destroy/delete when required</strong> by University</li>
                   </ul>
                   </div>")
                ),
                box(title = "Lecture Recording Policy", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='disadvantages'>
                   <h4>Limited Recording Access:</h4>
                   <ul>
                   <li><strong>Only for students with additional support needs</strong> (via ADRC)</li>
                   <li><strong>Exceptional circumstances only</strong> (bereavement, medical emergency)</li>
                   <li><strong>No recording for:</strong> Work commitments, interviews, conferences, holidays</li>
                   <li><strong>Participation required:</strong> Consent assumed for class participation assessments</li>
                   <li><strong>No sharing permitted</strong> - disciplinary action for breaches</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 12: Study Groups & Streams
      tabItem(tabName = "groups",
              fluidRow(
                box(title = "Streams and Study Groups Organization", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>The MBA cohort is organized into teaching streams and 6-person study groups optimized for diversity and collaborative learning.</p>")
                )
              ),
              fluidRow(
                box(title = "Stream Structure", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='benefits'>
                   <h4>Teaching Streams:</h4>
                   <ul>
                   <li><strong>Divided by term</strong> - streams altered each term</li>
                   <li><strong>Core course teaching</strong> conducted in assigned streams</li>
                   <li><strong>Attend assigned stream only</strong> - no switching permitted</li>
                   <li><strong>Attendance not recorded</strong> if in wrong stream</li>
                   <li><strong>Optimized for class size</strong> and teaching effectiveness</li>
                   </ul>
                   </div>")
                ),
                box(title = "Study Group Composition", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='benefits'>
                   <h4>6-Person Study Groups:</h4>
                   <ul>
                   <li><strong>Optimized for diversity</strong> - backgrounds and experiences</li>
                   <li><strong>Set for Michaelmas</strong> then revised for Lent/Easter</li>
                   <li><strong>Two main purposes:</strong> Teamwork training & maximize learning</li>
                   <li><strong>Knowledge sharing expected</strong> - leverage diverse skills</li>
                   <li><strong>Collaborative culture</strong> central to MBA experience</li>
                   </ul>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "Group Dynamics Management", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>Managing Study Group Challenges:</h4>
                   <ul>
                   <li><strong>Apply learning</strong> to resolve group issues</li>
                   <li><strong>Consult teaching faculty</strong> for guidance</li>
                   <li><strong>Review Teamwork Promise</strong> each term</li>
                   <li><strong>Contact MBA Programme Team</strong> if assistance needed</li>
                   <li><strong>Core part of MBA learning</strong> experience</li>
                   </ul>
                   </div>")
                ),
                box(title = "Practical Requirements", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='example-box'>
                   <h4>Study Group Practicalities:</h4>
                   <ul>
                   <li><strong>Nameplates required</strong> in ALL classes for identification</li>
                   <li><strong>Name badges provided</strong> - replacements charged after first</li>
                   <li><strong>Online sessions:</strong> Camera on, professional background</li>
                   <li><strong>Clear name display</strong> on all platforms</li>
                   <li><strong>Contact MBA Office</strong> for lost nameplates/badges</li>
                   </ul>
                   </div>")
                )
              )
      ),
      
      # Tab 13: Contact Information
      tabItem(tabName = "contact",
              fluidRow(
                box(title = "Key Contact Information", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<p>Primary contacts for various aspects of your MBA experience at Cambridge Judge Business School.</p>")
                )
              ),
              fluidRow(
                box(title = "Primary Contacts", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='benefits'>
                   <h4>MBA Programme Office:</h4>
                   <p><strong>Email:</strong> mbahelpdesk@jbs.cam.ac.uk</p>
                   <p><strong>Purpose:</strong> Primary email for MBA Programme Team - course-related issues, general enquiries</p>
                   
                   <h4>MBA Assessment Queries:</h4>
                   <p><strong>Email:</strong> mba-assessment@jbs.cam.ac.uk</p>
                   <p><strong>Purpose:</strong> Specific assessment concerns and marking queries</p>

                   <h4>Careers Office:</h4>
                   <p><strong>Email:</strong> careersoffice@jbs.cam.ac.uk</p>
                   <p><strong>Purpose:</strong> Career and job search enquiries, SIG support</p>
                   </div>")
                ),
                box(title = "Specialized Support", status = "primary", solidHeader = TRUE, width = 6,
                    HTML("<div class='benefits'>
                   <h4>Projects Team:</h4>
                   <p><strong>Email:</strong> mbaprojects@jbs.cam.ac.uk</p>
                   <p><strong>Purpose:</strong> CVP, GCP, and Summer projects coordination</p>

                   <h4>Timetabling Help:</h4>
                   <p><strong>Email:</strong> timetablinghelp@jbs.cam.ac.uk</p>
                   <p><strong>Purpose:</strong> Technical timetable issues and downloads</p>

                   <h4>IT Services:</h4>
                   <p><strong>Access:</strong> IT Hub on SharePoint</p>
                   <p><strong>Purpose:</strong> IT and AV services, technical support</p>
                   </div>")
                )
              ),
              fluidRow(
                box(title = "University Support Services", status = "primary", solidHeader = TRUE, width = 12,
                    HTML("<div class='example-box'>
                   <h4>Additional University Resources:</h4>
                   <ul>
                   <li><strong>Student Support:</strong> <a href='https://support.anthropic.com' target='_blank'>https://support.anthropic.com</a></li>
                   <li><strong>Student Wellbeing:</strong> <a href='https://www.studentwellbeing.admin.cam.ac.uk/' target='_blank'>Student Wellbeing Services</a></li>
                   <li><strong>Accessibility & Disability Resource Centre (ADRC):</strong> Additional support requirements</li>
                   <li><strong>International Student Office:</strong> Visa and immigration support</li>
                   <li><strong>University Counselling:</strong> 24/7 mental health support available</li>
                   <li><strong>Academic Student Representatives:</strong> Elected by cohort for formal feedback</li>
                   </ul>
                   <p><strong>Emergency Support:</strong> Contact your College for urgent personal or academic issues.</p>
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
  
  output$full_course_structure <- DT::renderDataTable({
    full_structure <- data.frame(
      Term = c(rep("Michaelmas", 9), rep("Lent", 8), rep("Easter", 7), "Summer"),
      Course_Code = c("MBA1", "MBA2", "MBA4", "MBA5", "MBA7", "MBA8", "MBA108", "MBA117", "MBA9",
                      "MBA10", "MBA11", "MBA12", "MBA33", "MBA116", "MBA34", "Elective 1", "Elective 2",
                      "MBA15", "MBA54", "MBA98", "Elective 4", "Elective 5", "Elective 6", "MBA35", "MBA36"),
      Course_Name = c("Microeconomics", "Management Science", "Corporate Finance", "Financial Reporting and Analysis",
                      "Organisational Behaviour & Leadership", "Management Praxis", "Business and Sustainable Development",
                      "Organisations vs Markets: Designs and Incentives", "Cambridge Venture Project",
                      "Strategy", "Marketing", "Corporate Governance & Ethics", "The Negotiations Lab", "Digital Business",
                      "Global Consulting Project", "Elective Choice 1", "Elective Choice 2",
                      "Operations Management", "Macroeconomics", "Advanced Strategy", "Elective Choice 4",
                      "Elective Choice 5", "Elective Choice 6", "Concentration Project", "Summer Term Activity"),
      Credits = c(3, 6, 6, 6, 6, 6, 3, 3, 6, 6, 6, 3, 6, 3, 12, 3, 3, 6, 3, 3, 3, 3, 3, 6, 6),
      Assessment_Type = c("Exam", "Mixed", "Exam", "Exam", "Mixed", "Coursework", "Coursework", "Exam", "Project",
                          "Exam", "Mixed", "Coursework", "Mixed", "Mixed", "Project", "Varies", "Varies",
                          "Exam", "Exam", "Mixed", "Varies", "Varies", "Varies", "Project", "Report")
    )
    DT::datatable(full_structure, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
  })
  
  # Tab 3: Term Dates
  output$selection_windows <- DT::renderDataTable({
    selection_data <- data.frame(
      Selection_Type = c("Lent Electives", "Easter Electives & Concentrations", "Summer Activity"),
      Window_Dates = c("13-19 November 2024", "18-24 February 2025", "2-30 May 2025"),
      Notes = c("First come, first served", "Concentration coach nights in Easter", "No changes after 11 July 2025")
    )
    DT::datatable(selection_data, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  # Tab 2: Academic Calendar
  output$calendar_plot <- renderPlotly({
    calendar_events <- data.frame(
      Date = as.Date(c("2024-09-16", "2024-11-04", "2024-12-02", "2024-12-09", "2024-12-13", 
                       "2025-01-13", "2025-03-10", "2025-03-14", "2025-03-17", "2025-04-18",
                       "2025-04-22", "2025-06-09", "2025-06-16", "2025-06-20", "2025-06-30", "2025-09-12")),
      Event = c("Michaelmas Start", "Professional Development", "CVP Presentations", "Michaelmas Exams", "Michaelmas End",
                "Lent Start", "Lent Exams", "Lent End", "GCP Start", "GCP End",
                "Easter Start", "Easter Exams", "Capstone Week", "Easter End", "Summer Start", "Final Reports Due"),
      Type = c("Term", "Special", "Project", "Exam", "Term", "Term", "Exam", "Term", "Project", "Project",
               "Term", "Exam", "Special", "Term", "Term", "Deadline")
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
      Date = c("16 Sep 2024", "4-8 Nov 2024", "13 Dec 2024", "13 Jan 2025", "17 Mar 2025", "22 Apr 2025", "16-20 Jun 2025", "12 Sep 2025"),
      Event = c("Michaelmas Start", "Professional Development", "Michaelmas End", "Lent Start", "GCP Start", "Easter Start", "Capstone Week", "Summer Reports Due")
    )
    DT::datatable(key_dates_data, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  # Tab 4: Grades & Assessment
  output$marking_standards <- DT::renderDataTable({
    marking_data <- data.frame(
      Grade_Range = c("80%+", "70-79%", "60-69%", "50-59%", "40-49%", "<40%"),
      Description = c("Exceptional - Genuine flair and originality", 
                      "Distinguished - Special features, originality, depth",
                      "Good - Considerable fluency, critical thinking",
                      "Pass - Competence with core ideas, limited analysis", 
                      "Fail - Significant shortcomings, poor understanding",
                      "Serious Fail - Chronic weaknesses in all aspects"),
      Typical_Characteristics = c("Outstanding precision, comprehensive research",
                                  "Well written, wide reading, thorough referencing",
                                  "Clear application to scenarios, critical analysis",
                                  "General/descriptive, less thorough referencing",
                                  "Failure to understand concepts, rudimentary application",
                                  "Poor referencing, major conceptual errors")
    )
    DT::datatable(marking_data, options = list(pageLength = 6, scrollX = TRUE), rownames = FALSE)
  })
  
  output$gpa_conversion <- DT::renderDataTable({
    gpa_data <- data.frame(
      GPA = c("4.0", "3.7", "3.3", "3.0", "2.7", "2.3", "2.0", "1.0", "0"),
      UK_Marks = c("70+", "65-69", "60-64", "55-59", "50-54", "45-49", "40-44", "35-39", "Below 35")
    )
    DT::datatable(gpa_data, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  output$assessment_types <- renderPlotly({
    assessment_data <- data.frame(
      Type = c("Examinations", "Group Projects", "Individual Assignments", "Class Participation", "Presentations"),
      Percentage = c(35, 30, 25, 5, 5)
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
  
  # Tab 5: Experiential Learning
  output$projects_timeline <- renderPlotly({
    projects_data <- data.frame(
      Project = c("CVP", "GCP", "Summer Activity"),
      Start = as.Date(c("2024-09-16", "2025-03-17", "2025-06-30")),
      End = as.Date(c("2024-12-13", "2025-04-18", "2025-09-12")),
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
  
  # Tab 6: Electives & Concentrations
  output$concentrations_table <- DT::renderDataTable({
    concentrations <- data.frame(
      Concentration = c("Strategy", "Marketing", "Finance", "Energy & Environment", "Healthcare Strategies", 
                        "Cultural Arts & Media", "Digital Transformation", "Sustainable Business", "Entrepreneurship"),
      Focus = c("Competitive advantage & strategic planning", 
                "Consumer behavior & brand management", 
                "Investment analysis & financial markets", 
                "Sustainability & renewable energy", 
                "Health systems & medical technology",
                "Creative industries & media management", 
                "Technology disruption & digital business models", 
                "ESG strategies & impact investing", 
                "Startup ventures & innovation management"),
      Requirements = rep("2+ electives in area, Coach Nights, Group Project", 9)
    )
    DT::datatable(concentrations, options = list(pageLength = 5, scrollY = "300px", scrollX = TRUE), rownames = FALSE)
  })
  
  output$electives_sample <- DT::renderDataTable({
    electives_sample <- data.frame(
      Course = c("Financial Modelling", "Entrepreneurial Finance", "Behavioural Economics", "Sustainable Business",
                 "Innovation Management", "Private Equity", "Health Strategy", "Digital Transformation",
                 "Creative Industries", "International Marketing", "Energy Economics", "Impact Investing"),
      Credits = rep(3, 12),
      Term = c("Lent", "Easter", "Lent", "Easter", "Lent", "Easter", "Lent", "Easter", 
               "Lent", "Easter", "Lent", "Easter"),
      Concentration = c("Finance", "Entrepreneurship", "Strategy", "Sustainable Business",
                        "Entrepreneurship", "Finance", "Healthcare", "Digital Transformation",
                        "Cultural Arts & Media", "Marketing", "Energy & Environment", "Sustainable Business"),
      Description = c("Advanced Excel & financial analysis techniques", 
                      "Startup funding strategies & venture capital", 
                      "Psychology in economics & decision-making",
                      "ESG frameworks & sustainable business models", 
                      "R&D management & product development", 
                      "Investment fund operations & portfolio management",
                      "Healthcare industry analysis & strategy", 
                      "Digital business models & platform strategy",
                      "Media management & creative industry dynamics",
                      "Global marketing strategies & cultural adaptation",
                      "Energy markets & policy analysis",
                      "Impact measurement & social finance")
    )
    DT::datatable(electives_sample, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
  })
  
  # Tab 9: Academic Integrity
  output$integrity_consequences <- renderPlotly({
    consequences_data <- data.frame(
      Violation = c("First Offense", "Repeated Plagiarism", "Severe Misconduct", "Exam Cheating", "AI Usage"),
      Consequence = c("Zero Grade/Warning", "Module Failure", "Suspension Review", "Possible Expulsion", "Plagiarism Sanctions"),
      Severity = c(1, 2, 3, 4, 2)
    )
    
    colors <- c('#FFD700', '#FF8C00', '#FF4500', '#DC143C', '#FF6347')
    
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