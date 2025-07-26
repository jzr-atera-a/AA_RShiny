# Load required libraries
library(shiny)
library(shinydashboard)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Lean Six Sigma Green Belt Body of Knowledge"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Six Sigma Framework", tabName = "framework", icon = icon("cogs")),
      menuItem("Define Phase", tabName = "define", icon = icon("flag")),
      menuItem("Measure Phase", tabName = "measure", icon = icon("ruler")),
      menuItem("Analyse Phase", tabName = "analyse", icon = icon("search")),
      menuItem("Improve Phase", tabName = "improve", icon = icon("arrow-up")),
      menuItem("Control Phase", tabName = "control", icon = icon("shield-alt")),
      menuItem("Data Analysis", tabName = "data", icon = icon("chart-bar")),
      menuItem("Implementation", tabName = "implementation", icon = icon("rocket"))
    )
  ),
  
  dashboardBody(
    # Custom CSS for dark yellow-orange theme
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
      # Six Sigma Framework Tab
      tabItem(tabName = "framework",
              fluidRow(
                box(
                  title = "History of Six Sigma", status = "primary", solidHeader = TRUE, width = 6,
                  p("Six Sigma was developed by Motorola in 1986 as a quality management methodology aimed at reducing defects to 3.4 parts per million opportunities. The approach was pioneered by engineer Bill Smith and further developed by Mikel Harry. Six Sigma combines statistical analysis with systematic problem-solving methodologies to achieve operational excellence and customer satisfaction."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Motorola's semiconductor manufacturing division reduced defects from thousands per million to less than 3.4 per million, saving billions in warranty costs and improving customer satisfaction by 95%."),
                      p(a(href = "https://www.motorolasolutions.com/en_us/about/company-overview/history/explore-motorola-heritage.html", target = "_blank", "Learn about Motorola's Six Sigma origins")),
                      p(a(href = "https://www.isixsigma.com/implementation/basics/history-six-sigma/", target = "_blank", "Comprehensive Six Sigma history"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Dramatic reduction in defects and waste"),
                        tags$li("Significant cost savings and improved profitability"),
                        tags$li("Enhanced customer satisfaction and loyalty")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("High initial implementation costs and training requirements"),
                        tags$li("May stifle innovation through excessive focus on standardisation"),
                        tags$li("Requires sustained leadership commitment over several years")
                      )
                  ),
                  
                  p(strong("Reference:"), "Pyzdek, T. (2003). The Six Sigma Handbook. McGraw-Hill Professional.")
                ),
                
                box(
                  title = "Six Sigma Roles and Responsibilities", status = "primary", solidHeader = TRUE, width = 6,
                  p("Six Sigma employs a hierarchical structure with defined roles:"),
                  tags$ul(
                    tags$li(strong("Champions:"), "Senior executives who drive strategic implementation"),
                    tags$li(strong("Master Black Belts:"), "Technical experts and mentors"),
                    tags$li(strong("Black Belts:"), "Full-time project leaders"),
                    tags$li(strong("Green Belts:"), "Part-time practitioners supporting projects"),
                    tags$li(strong("Yellow Belts:"), "Team members with basic Six Sigma knowledge")
                  ),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("At General Electric, Black Belts lead major projects saving £150,000+ annually, whilst Green Belts support projects in their departments, achieving collective savings of millions through coordinated improvement efforts."),
                      p(a(href = "https://www.ge.com/news/reports/150-years-of-ge-innovation", target = "_blank", "GE's Six Sigma implementation")),
                      p(a(href = "https://www.asq.org/quality-resources/six-sigma/belt-system", target = "_blank", "ASQ Six Sigma Belt System guide"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Clear accountability and structured approach to improvement"),
                        tags$li("Develops internal expertise and capability"),
                        tags$li("Creates career development pathways for employees")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Significant training investment required for certification"),
                        tags$li("Risk of creating organisational silos between belt levels"),
                        tags$li("Potential for role confusion without clear definitions")
                      )
                  ),
                  
                  p(strong("Reference:"), "Harry, M. & Schroeder, R. (2000). Six Sigma: The Breakthrough Management Strategy. Currency Books.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Six Sigma Framework (DMAIC/DMADV)", status = "primary", solidHeader = TRUE, width = 6,
                  p("Six Sigma employs two primary methodologies:"),
                  p(strong("DMAIC"), "(Define, Measure, Analyse, Improve, Control) - Used for existing process improvement"),
                  p(strong("DMADV"), "(Define, Measure, Analyse, Design, Verify) - Used for new product or process design"),
                  p("DMAIC focuses on incremental improvements to existing processes, whilst DMADV is employed when creating new processes or products from scratch."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("A hospital used DMAIC to reduce patient waiting times from 45 to 15 minutes, whilst a software company used DMADV to design a new customer onboarding process achieving 99% satisfaction rates."),
                      p(a(href = "https://www.isixsigma.com/methodology/dmaic/", target = "_blank", "Complete DMAIC methodology guide")),
                      p(a(href = "https://www.asq.org/quality-resources/dfss", target = "_blank", "Design for Six Sigma (DMADV) overview"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Structured problem-solving approach reduces project risk"),
                        tags$li("Data-driven decisions improve solution effectiveness"),
                        tags$li("Standardised methodology enables knowledge transfer")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be overly rigid for creative or innovative projects"),
                        tags$li("Time-intensive process may delay urgent improvements"),
                        tags$li("Requires significant data collection and analysis capability")
                      )
                  ),
                  
                  p(strong("Reference:"), "Brue, G. (2002). Six Sigma for Managers. McGraw-Hill Professional.")
                ),
                
                box(
                  title = "Process Owners/Project Champions", status = "primary", solidHeader = TRUE, width = 6,
                  p("Process owners are individuals responsible for the end-to-end performance of specific business processes. They ensure processes meet customer requirements and organisational objectives. Project champions are senior leaders who provide resources, remove barriers, and ensure project alignment with strategic goals."),
                  p("Champions typically hold executive positions and possess authority to allocate resources and drive organisational change necessary for project success."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("At Toyota, the Chief Quality Officer champions all Six Sigma initiatives, whilst individual process owners (like the Head of Supply Chain) ensure their processes meet quality standards, resulting in industry-leading reliability."),
                      p(a(href = "https://www.toyota-global.com/company/vision_philosophy/toyota_production_system/", target = "_blank", "Toyota Production System overview")),
                      p(a(href = "https://www.isixsigma.com/implementation/leadership/role-of-champions-in-six-sigma/", target = "_blank", "Six Sigma Champions role guide"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Ensures senior leadership commitment and resource allocation"),
                        tags$li("Provides clear accountability for process performance"),
                        tags$li("Facilitates cross-functional collaboration and barrier removal")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May create competing priorities if not well coordinated"),
                        tags$li("Risk of projects failing without strong champion support"),
                        tags$li("Potential for micromanagement if roles not clearly defined")
                      )
                  ),
                  
                  p(strong("Reference:"), "Snee, R. (2004). Six Sigma: The Evolution of 100 Years of Business Improvement Methodology. Pearson Education.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Quality Management and Gurus", status = "primary", solidHeader = TRUE, width = 12,
                  p("Six Sigma builds upon the foundational work of quality management pioneers including W. Edwards Deming (Plan-Do-Check-Act cycle), Joseph Juran (Quality Trilogy), Philip Crosby (Zero Defects), and Walter Shewhart (Statistical Process Control). These quality gurus established the theoretical framework upon which modern Six Sigma practices are built."),
                  p("Their collective contributions emphasise statistical thinking, customer focus, continuous improvement, and management commitment as essential elements of quality excellence."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Deming's PDCA cycle is used in every DMAIC project: Define (Plan), Measure (Do), Analyse (Check), Improve/Control (Act), whilst Juran's focus on 'fitness for use' drives customer-centric improvements in companies like Amazon."),
                      p(a(href = "https://deming.org/explore/fourteen-points/", target = "_blank", "Deming's 14 Points for Management")),
                      p(a(href = "https://www.asq.org/quality-resources/quality-glossary/j", target = "_blank", "Joseph Juran Quality Institute"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides proven theoretical foundation for improvement methods"),
                        tags$li("Combines multiple perspectives for comprehensive quality approach"),
                        tags$li("Offers time-tested principles applicable across industries")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Some concepts may seem outdated in modern digital environments"),
                        tags$li("Can create confusion when different guru philosophies conflict"),
                        tags$li("Risk of over-reliance on historical approaches vs innovation")
                      )
                  ),
                  
                  p(strong("Reference:"), "Evans, J. & Lindsay, W. (2005). The Management and Control of Quality. Thomson South-Western."),
                  p(strong("Dashboard Created and Edited by"), "J. Francisco Zubizarreta  @JBS University of Cambridge")
                )
              )
      ),
      
      
      
      
      # Define Phase Tab
      tabItem(tabName = "define",
              fluidRow(
                box(
                  title = "Project Charter", status = "primary", solidHeader = TRUE, width = 6,
                  p("A Project Charter is a foundational document that formally authorises a Six Sigma project. It defines the project scope, objectives, timeline, resources, and expected benefits. The charter serves as a contract between the project team and leadership, ensuring clear expectations and accountability."),
                  p("Key components include problem statement, goal statement, scope definition, team members, timeline, and success metrics."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Charter for reducing customer complaint resolution time: Problem - 72-hour average response time causing customer dissatisfaction. Goal - Reduce to 24 hours within 3 months. Expected savings - £200,000 annually through improved retention."),
                      p(a(href = "https://www.isixsigma.com/tools-templates/project-charter/", target = "_blank", "Six Sigma Project Charter template")),
                      p(a(href = "https://www.asq.org/quality-resources/project-charter", target = "_blank", "ASQ Project Charter guidelines"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides clear project direction and prevents scope creep"),
                        tags$li("Secures leadership commitment and resource allocation"),
                        tags$li("Establishes measurable success criteria upfront")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be time-consuming to develop and gain approval"),
                        tags$li("May become outdated if project requirements change"),
                        tags$li("Risk of over-specification limiting project flexibility")
                      )
                  ),
                  
                  p(strong("Reference:"), "George, M. (2003). Lean Six Sigma for Service. McGraw-Hill Professional.")
                ),
                
                box(
                  title = "Stakeholder Analysis", status = "primary", solidHeader = TRUE, width = 6,
                  p("Stakeholder analysis identifies all parties affected by or influencing the project. This systematic assessment evaluates stakeholder interests, influence levels, and potential impact on project success. Understanding stakeholder dynamics enables effective communication strategies and change management approaches."),
                  p("Stakeholders are typically categorised by their level of influence and interest in the project outcomes."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("For an IT system upgrade: High influence/High interest - IT Director, Users; High influence/Low interest - CEO; Low influence/High interest - End users. Each group receives tailored communication addressing their specific concerns."),
                      p(a(href = "https://www.pmi.org/learning/library/stakeholder-analysis-pivotal-practice-projects-8905", target = "_blank", "PMI Stakeholder Analysis guide")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/stakeholder-analysis/", target = "_blank", "Six Sigma stakeholder mapping tools"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Identifies potential resistance early in the project"),
                        tags$li("Enables targeted communication and engagement strategies"),
                        tags$li("Improves project buy-in and implementation success")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be complex and time-consuming for large organisations"),
                        tags$li("Stakeholder positions may change throughout the project"),
                        tags$li("Risk of analysis paralysis if too detailed")
                      )
                  ),
                  
                  p(strong("Reference:"), "Keller, P. (2004). Six Sigma Deployment. Quality Publishing.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Defect/Defective/DPMO", status = "primary", solidHeader = TRUE, width = 6,
                  p("Key quality metrics in Six Sigma:"),
                  tags$ul(
                    tags$li(strong("Defect:"), "Any instance where a product or service fails to meet specifications"),
                    tags$li(strong("Defective:"), "A unit containing one or more defects"),
                    tags$li(strong("DPMO:"), "Defects Per Million Opportunities - a normalised metric allowing comparison across different processes")
                  ),
                  p("DPMO calculation: (Number of Defects × 1,000,000) ÷ (Number of Units × Opportunities per Unit)"),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("In a call centre with 1,000 calls, 20 defects (wrong information), 5 opportunities per call: DPMO = (20 × 1,000,000) ÷ (1,000 × 5) = 4,000 DPMO, indicating approximately 4.1 sigma level performance."),
                      p(a(href = "https://www.isixsigma.com/dictionary/dpmo-defects-per-million-opportunities/", target = "_blank", "DPMO calculation guide")),
                      p(a(href = "https://www.asq.org/quality-resources/sigma-level", target = "_blank", "ASQ Sigma Level calculator"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides standardised quality metrics across different processes"),
                        tags$li("Enables benchmarking and comparison between departments"),
                        tags$li("Directly links to sigma level and capability assessment")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be difficult to define opportunities consistently"),
                        tags$li("May not capture customer perception of quality"),
                        tags$li("Requires significant data collection and validation effort")
                      )
                  ),
                  
                  p(strong("Reference:"), "Breyfogle, F. (2003). Implementing Six Sigma. John Wiley & Sons.")
                ),
                
                box(
                  title = "SIPOC/COPIS", status = "primary", solidHeader = TRUE, width = 6,
                  p("SIPOC (Suppliers, Inputs, Process, Outputs, Customers) is a high-level process mapping tool that provides a structured view of process boundaries and key elements. COPIS reverses the order for customer-focused analysis."),
                  p("This tool helps teams understand process scope, identify key stakeholders, and establish process boundaries before detailed analysis begins."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("For invoice processing: Suppliers (Finance, Vendors), Inputs (Purchase orders, receipts), Process (Verify, approve, pay), Outputs (Payments, reports), Customers (Vendors, management). Maps the complete payment cycle."),
                      p(a(href = "https://www.isixsigma.com/tools-templates/sipoc-copis/", target = "_blank", "SIPOC diagram templates")),
                      p(a(href = "https://www.asq.org/quality-resources/sipoc", target = "_blank", "ASQ SIPOC methodology"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides clear process boundaries and scope definition"),
                        tags$li("Identifies all key stakeholders early in the project"),
                        tags$li("Simple tool that promotes team understanding")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May oversimplify complex processes with multiple paths"),
                        tags$li("Doesn't show process flow or decision points"),
                        tags$li("Limited value for detailed process analysis")
                      )
                  ),
                  
                  p(strong("Reference:"), "Siviy, J. (2004). Six Sigma Software Development. Auerbach Publications.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Voice of the Customer", status = "primary", solidHeader = TRUE, width = 6,
                  p("Voice of the Customer (VOC) represents customer needs, expectations, and requirements expressed in their own language. VOC data is collected through surveys, interviews, focus groups, and direct observation to understand what customers truly value."),
                  p("This information drives project prioritisation and ensures solutions address genuine customer pain points rather than assumed problems."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Restaurant VOC analysis reveals customers want 'quick service' (translated to <5 minute wait), 'fresh food' (prepared within 30 minutes), and 'fair prices' (competitive with similar establishments). Drives operational improvements."),
                      p(a(href = "https://www.isixsigma.com/tools-templates/voice-customer-voc/", target = "_blank", "Voice of Customer collection methods")),
                      p(a(href = "https://www.asq.org/quality-resources/voice-of-the-customer", target = "_blank", "ASQ VOC techniques"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Ensures improvements align with actual customer needs"),
                        tags$li("Provides objective basis for project prioritisation"),
                        tags$li("Increases customer satisfaction and loyalty")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be expensive and time-consuming to collect properly"),
                        tags$li("Customer needs may conflict or be unclear"),
                        tags$li("Risk of over-reliance on vocal minority opinions")
                      )
                  ),
                  
                  p(strong("Reference:"), "Ulwick, A. (2005). What Customers Want. McGraw-Hill Professional.")
                ),
                
                box(
                  title = "Critical to Quality Trees", status = "primary", solidHeader = TRUE, width = 6,
                  p("Critical to Quality (CTQ) Trees translate broad customer requirements into specific, measurable characteristics. They provide a hierarchical breakdown from customer needs to actionable metrics, ensuring project teams focus on factors that directly impact customer satisfaction."),
                  p("CTQ Trees bridge the gap between qualitative customer feedback and quantitative process measurements."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Customer need: 'Reliable delivery' breaks down to: On-time delivery (>95%), Correct items (>99%), Undamaged goods (>99.5%). Each CTQ becomes a measurable project metric with specific targets."),
                      p(a(href = "https://www.isixsigma.com/tools-templates/ctq/", target = "_blank", "CTQ Tree construction guide")),
                      p(a(href = "https://www.asq.org/quality-resources/critical-to-quality", target = "_blank", "ASQ Critical to Quality methodology"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Translates vague customer needs into measurable requirements"),
                        tags$li("Ensures project focus on customer-impacting factors"),
                        tags$li("Provides clear metrics for project success")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can become overly complex with too many branches"),
                        tags$li("May miss interdependencies between CTQ characteristics"),
                        tags$li("Requires careful validation to ensure accuracy")
                      )
                  ),
                  
                  p(strong("Reference:"), "Watson, G. (2004). Design for Six Sigma. Academic Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Hard and Soft Savings", status = "primary", solidHeader = TRUE, width = 6,
                  p("Six Sigma projects generate two types of financial benefits:"),
                  tags$ul(
                    tags$li(strong("Hard Savings:"), "Quantifiable cost reductions that directly impact the bottom line (reduced material costs, labour savings)"),
                    tags$li(strong("Soft Savings:"), "Intangible benefits that create value but are difficult to quantify precisely (improved customer satisfaction, employee morale)")
                  ),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Manufacturing improvement: Hard savings - £500,000 reduced waste costs, £200,000 lower rework expenses. Soft savings - Improved worker safety, enhanced customer confidence, better supplier relationships."),
                      p(a(href = "https://www.isixsigma.com/implementation/financial-analysis/", target = "_blank", "Six Sigma financial benefits analysis")),
                      p(a(href = "https://www.asq.org/quality-resources/roi", target = "_blank", "ASQ ROI calculation methods"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Hard savings provide clear ROI justification for projects"),
                        tags$li("Soft savings capture broader organisational value"),
                        tags$li("Combined approach gives complete picture of project impact")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Soft savings difficult to validate and defend"),
                        tags$li("May lead to disputes over actual vs claimed savings"),
                        tags$li("Risk of double-counting benefits across projects")
                      )
                  ),
                  
                  p(strong("Reference:"), "Pande, P. (2003). The Six Sigma Way. McGraw-Hill Professional.")
                ),
                
                box(
                  title = "Breakthrough Equation & Kaizen/Kaikaku", status = "primary", solidHeader = TRUE, width = 6,
                  p("The Breakthrough Equation: Y = f(X) + ε represents that outcomes (Y) are functions of process inputs (X) plus error (ε)."),
                  p(strong("Kaizen:"), "Continuous, incremental improvement philosophy"),
                  p(strong("Kaikaku:"), "Radical, breakthrough improvement requiring fundamental process redesign"),
                  p("Both approaches are essential for comprehensive process improvement strategies."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Kaizen: Daily 5-minute team meetings reducing errors by 2% monthly. Kaikaku: Complete order processing system redesign reducing cycle time from 5 days to 2 hours. Y=cycle time, X=process steps, technology."),
                      p(a(href = "https://www.lean.org/lexicon-terms/kaizen/", target = "_blank", "Lean Enterprise Institute Kaizen")),
                      p(a(href = "https://www.isixsigma.com/methodology/breakthrough-equation/", target = "_blank", "Six Sigma Breakthrough Equation"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides framework for understanding process relationships"),
                        tags$li("Combines incremental and breakthrough improvement approaches"),
                        tags$li("Enables systematic identification of improvement opportunities")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May oversimplify complex multivariate relationships"),
                        tags$li("Requires careful balance between Kaizen and Kaikaku efforts"),
                        tags$li("Risk of neglecting one approach in favour of the other")
                      )
                  ),
                  
                  p(strong("Reference:"), "Imai, M. (2004). Kaizen: The Key to Japan's Competitive Success. McGraw-Hill Education."),
                  p(strong("Dashboard Created and Edited by"), "J. Francisco Zubizarreta  @JBS University of Cambridge")
                )
              )
      ),
      
      # Measure Phase Tab  
      tabItem(tabName = "measure",
              fluidRow(
                box(
                  title = "Basic Quality Tools", status = "primary", solidHeader = TRUE, width = 6,
                  p("The seven basic quality tools form the foundation of quality analysis:"),
                  tags$ul(
                    tags$li("Check sheets for data collection"),
                    tags$li("Histograms for data distribution"),
                    tags$li("Pareto charts for prioritisation"),
                    tags$li("Cause-and-effect diagrams for root cause analysis"),
                    tags$li("Scatter plots for correlation analysis"),
                    tags$li("Control charts for process monitoring"),
                    tags$li("Flowcharts for process mapping")
                  ),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Hospital emergency department uses check sheets to collect wait time data, creates histograms showing distribution patterns, applies Pareto analysis to identify top 3 causes of delays (20% of causes = 80% of wait time)."),
                      p(a(href = "https://www.asq.org/quality-resources/seven-basic-quality-tools", target = "_blank", "ASQ Seven Basic Quality Tools")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/seven-basic-quality-tools/", target = "_blank", "Complete quality tools library"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Simple, accessible tools requiring minimal training"),
                        tags$li("Provide visual representation of data and problems"),
                        tags$li("Enable systematic problem-solving approach")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May be too basic for complex statistical analysis"),
                        tags$li("Limited ability to handle multiple variables simultaneously"),
                        tags$li("Risk of misinterpretation without proper statistical knowledge")
                      )
                  ),
                  
                  p(strong("Reference:"), "Ishikawa, K. (2003). Guide to Quality Control. Quality Resources.")
                ),
                
                box(
                  title = "House of Quality", status = "primary", solidHeader = TRUE, width = 6,
                  p("The House of Quality is the primary tool in Quality Function Deployment (QFD). It systematically translates customer requirements into technical specifications and design targets. The matrix structure correlates customer needs with engineering characteristics, enabling teams to prioritise development efforts."),
                  p("This tool ensures customer voice remains central throughout product development whilst managing technical trade-offs."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Car manufacturer translates customer need for 'fuel efficiency' into technical requirements: engine displacement <2.0L, weight <1,500kg, aerodynamic coefficient <0.30. Matrix shows correlations and trade-offs between requirements."),
                      p(a(href = "https://www.asq.org/quality-resources/qfd-quality-function-deployment", target = "_blank", "ASQ Quality Function Deployment")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/qfd-house-of-quality/", target = "_blank", "House of Quality templates"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Ensures customer needs drive technical decisions"),
                        tags$li("Identifies conflicts between requirements early"),
                        tags$li("Provides structured approach to product development")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can become overly complex for simple products"),
                        tags$li("Time-intensive to complete properly"),
                        tags$li("Requires significant cross-functional collaboration")
                      )
                  ),
                  
                  p(strong("Reference:"), "Akao, Y. (2004). Quality Function Deployment: Integrating Customer Requirements. Productivity Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Gage R&R", status = "primary", solidHeader = TRUE, width = 6,
                  p("Gage Repeatability and Reproducibility (R&R) studies assess measurement system capability. Repeatability examines variation when the same operator measures the same part multiple times. Reproducibility evaluates variation between different operators measuring the same parts."),
                  p("A capable measurement system should contribute less than 10% of total process variation. Gage R&R ensures data reliability before process improvement efforts begin."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Manufacturing precision parts: 3 operators measure 10 parts 3 times each. Results show 15% measurement variation vs 85% part variation. Gage R&R = 15% indicates measurement system needs improvement before process analysis."),
                      p(a(href = "https://www.asq.org/quality-resources/measurement-systems-analysis", target = "_blank", "ASQ Measurement Systems Analysis")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/measurement-systems-analysis-msa/", target = "_blank", "Gage R&R study templates"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Validates measurement system reliability before analysis"),
                        tags$li("Identifies operator training needs"),
                        tags$li("Prevents incorrect conclusions from poor measurement data")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be time-consuming and expensive to conduct"),
                        tags$li("Requires skilled personnel to interpret results properly"),
                        tags$li("May delay project progress whilst measurement issues resolved")
                      )
                  ),
                  
                  p(strong("Reference:"), "Wheeler, D. (2004). Advanced Topics in Statistical Process Control. SPC Press.")
                ),
                
                box(
                  title = "Cost of Quality", status = "primary", solidHeader = TRUE, width = 6,
                  p("Cost of Quality categorises quality-related expenses into four categories:"),
                  tags$ul(
                    tags$li(strong("Prevention costs:"), "Proactive quality activities"),
                    tags$li(strong("Appraisal costs:"), "Inspection and testing"),
                    tags$li(strong("Internal failure costs:"), "Defects found before customer delivery"),
                    tags$li(strong("External failure costs:"), "Defects reaching customers")
                  ),
                  p("Optimal quality investment minimises total cost whilst maximising customer satisfaction."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Software company: Prevention (£200k training), Appraisal (£300k testing), Internal failure (£150k rework), External failure (£500k support calls). Total CoQ = £1.15M, focusing prevention reduces overall costs."),
                      p(a(href = "https://www.asq.org/quality-resources/cost-of-quality", target = "_blank", "ASQ Cost of Quality framework")),
                      p(a(href = "https://www.isixsigma.com/methodology/cost-of-quality/", target = "_blank", "Cost of Quality calculation tools"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides comprehensive view of quality-related expenses"),
                        tags$li("Guides investment decisions towards prevention"),
                        tags$li("Enables tracking of quality improvement ROI")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Difficult to capture all hidden quality costs"),
                        tags$li("May discourage necessary short-term quality investments"),
                        tags$li("Requires sophisticated cost accounting systems")
                      )
                  ),
                  
                  p(strong("Reference:"), "Campanella, J. (2003). Principles of Quality Costs. ASQ Quality Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Capability Analysis", status = "primary", solidHeader = TRUE, width = 12,
                  p("Process capability analysis evaluates how well a process meets specifications. It compares process variation to specification limits, providing indices that quantify process performance. Capability studies require stable processes and normally distributed data."),
                  p("Key capability indices include Cp (potential capability), Cpk (actual capability considering centering), Pp (performance), and Ppk (performance with centering). These metrics guide improvement priorities and help predict defect rates."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Machining process with specification 100±5mm shows mean=101mm, σ=1.5mm. Cp=(110-90)/(6×1.5)=2.22 (excellent potential), Cpk=min[(110-101)/(3×1.5), (101-90)/(3×1.5)]=2.00 (very good actual capability)."),
                      p(a(href = "https://www.asq.org/quality-resources/process-capability", target = "_blank", "ASQ Process Capability guide")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/capability-analysis/", target = "_blank", "Capability analysis tools"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides quantitative assessment of process performance"),
                        tags$li("Enables prediction of defect rates and yield"),
                        tags$li("Guides process improvement prioritisation decisions")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Requires normally distributed, stable process data"),
                        tags$li("May not reflect customer perception of quality"),
                        tags$li("Can give false confidence if assumptions not met")
                      )
                  ),
                  
                  p(strong("Reference:"), "Montgomery, D. (2005). Introduction to Statistical Quality Control. John Wiley & Sons."),
                  p(strong("Dashboard Created and Edited by"), "J. Francisco Zubizarreta  @JBS University of Cambridge")
        
                )
              )
      ),
      
      # Analyse Phase Tab
      tabItem(tabName = "analyse",
              fluidRow(
                box(
                  title = "Value Stream Mapping", status = "primary", solidHeader = TRUE, width = 6,
                  p("Value Stream Mapping visualises the flow of materials and information through a process from customer order to delivery. This lean tool identifies value-added and non-value-added activities, highlighting improvement opportunities. Current state maps document existing conditions whilst future state maps design improved processes."),
                  p("VSM reveals hidden waste, bottlenecks, and opportunities for flow improvement across the entire value stream."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Electronics manufacturer maps 21-day order-to-delivery cycle, discovering only 3 hours add value. VSM reveals 15 days inventory wait time, 2 days transport delays, 4 days approval queues - targets for elimination."),
                      p(a(href = "https://www.lean.org/lexicon-terms/value-stream-mapping/", target = "_blank", "Lean Enterprise Institute VSM")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/value-stream-mapping/", target = "_blank", "Value Stream Mapping templates"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides end-to-end view of process flow and waste"),
                        tags$li("Enables identification of improvement opportunities"),
                        tags$li("Facilitates cross-functional understanding and collaboration")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be time-consuming to create accurate current state"),
                        tags$li("May become outdated quickly in dynamic environments"),
                        tags$li("Requires significant cross-functional coordination")
                      )
                  ),
                  
                  p(strong("Reference:"), "Rother, M. & Shook, J. (2003). Learning to See: Value Stream Mapping. Lean Enterprise Institute.")
                ),
                
                box(
                  title = "Root Cause Analysis", status = "primary", solidHeader = TRUE, width = 6,
                  p("Root Cause Analysis employs multiple techniques to identify underlying problem causes:"),
                  tags$ul(
                    tags$li(strong("Current Reality Tree:"), "Logic-based cause-and-effect analysis"),
                    tags$li(strong("Five Whys:"), "Iterative questioning technique"),
                    tags$li(strong("Fishbone Diagram:"), "Categorical cause identification")
                  ),
                  p("These tools help teams move beyond symptoms to address fundamental issues, preventing problem recurrence."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Machine breakdown analysis: Why broken? (bearings failed) Why? (lack of lubrication) Why? (maintenance missed) Why? (no reminder system) Why? (no preventive maintenance schedule). Root cause: inadequate maintenance system."),
                      p(a(href = "https://www.asq.org/quality-resources/root-cause-analysis", target = "_blank", "ASQ Root Cause Analysis methods")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/cause-effect-fishbone-ishikawa-diagram/", target = "_blank", "Fishbone diagram templates"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Addresses root causes rather than symptoms"),
                        tags$li("Prevents problem recurrence through systematic analysis"),
                        tags$li("Provides multiple analytical approaches for different situations")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be time-intensive for complex problems"),
                        tags$li("May lead to analysis paralysis without action"),
                        tags$li("Risk of oversimplifying multi-causal problems")
                      )
                  ),
                  
                  p(strong("Reference:"), "Wilson, P. (2004). Root Cause Analysis: A Tool for Total Quality Management. ASQ Quality Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Pareto Analysis", status = "primary", solidHeader = TRUE, width = 6,
                  p("Pareto Analysis applies the 80/20 rule, identifying the vital few factors causing most problems. By ranking issues by frequency or impact, teams focus improvement efforts on the most significant contributors. Pareto charts provide visual representation of relative problem importance."),
                  p("This prioritisation tool ensures resources are directed toward the highest-impact improvement opportunities."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Customer complaints analysis: Delivery delays (45%), Product defects (25%), Poor service (15%), Billing errors (10%), Other (5%). Focusing on top 2 categories addresses 70% of all complaints with targeted improvements."),
                      p(a(href = "https://www.asq.org/quality-resources/pareto", target = "_blank", "ASQ Pareto Analysis guide")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/pareto-analysis-charts/", target = "_blank", "Pareto chart templates"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Focuses efforts on highest-impact improvement opportunities"),
                        tags$li("Provides clear visual prioritisation of problems"),
                        tags$li("Enables efficient resource allocation decisions")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May overlook important but infrequent critical issues"),
                        tags$li("Assumes all categories have equal improvement difficulty"),
                        tags$li("Can lead to neglect of emerging or systemic problems")
                      )
                  ),
                  
                  p(strong("Reference:"), "Juran, J. (2003). Juran on Quality by Design. Free Press.")
                ),
                
                box(
                  title = "Spaghetti Diagrams", status = "primary", solidHeader = TRUE, width = 6,
                  p("Spaghetti Diagrams track movement patterns of people, materials, or information through a workspace. These visual tools reveal inefficient layouts, excessive travel distances, and opportunities for workflow optimisation. The resulting diagram often resembles tangled spaghetti, hence the name."),
                  p("By mapping actual movement patterns, teams can redesign layouts to minimise waste and improve efficiency."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Nurse tracking in hospital ward reveals 3.2km daily walking distance. Spaghetti diagram shows frequent trips between distant supply rooms and patient rooms. Relocating supplies reduces walking to 1.8km, saving 90 minutes per shift."),
                      p(a(href = "https://www.lean.org/lexicon-terms/spaghetti-chart/", target = "_blank", "Lean Enterprise Institute Spaghetti Charts")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/spaghetti-diagram/", target = "_blank", "Spaghetti diagram templates"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Visualises waste in movement and transportation"),
                        tags$li("Identifies layout improvement opportunities"),
                        tags$li("Simple tool requiring minimal training or resources")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May not capture all movement patterns or variations"),
                        tags$li("Limited value for processes without physical movement"),
                        tags$li("Requires physical observation and measurement")
                      )
                  ),
                  
                  p(strong("Reference:"), "Womack, J. (2004). Lean Thinking. Free Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Business Impact Analysis & FMEA", status = "primary", solidHeader = TRUE, width = 6,
                  p("Business Impact Analysis quantifies potential consequences of process failures, helping prioritise improvement efforts. Failure Mode and Effects Analysis (FMEA) systematically examines potential failure modes, their causes, and effects."),
                  p("FMEA uses Risk Priority Numbers (RPN) calculated from Severity × Occurrence × Detection ratings to prioritise improvement actions."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("IT system FMEA: Server failure mode with Severity=9 (critical), Occurrence=3 (occasional), Detection=2 (high detection). RPN=54. Compare to password breach: S=8, O=5, D=7, RPN=280 - higher priority for prevention."),
                      p(a(href = "https://www.asq.org/quality-resources/fmea", target = "_blank", "ASQ FMEA methodology")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/fmea/", target = "_blank", "FMEA templates and guides"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Proactively identifies potential failure modes"),
                        tags$li("Provides systematic risk assessment and prioritisation"),
                        tags$li("Enables preventive action planning")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be subjective in rating severity and occurrence"),
                        tags$li("Time-intensive for complex systems"),
                        tags$li("May create false sense of security if incomplete")
                      )
                  ),
                  
                  p(strong("Reference:"), "Stamatis, D. (2003). Failure Mode and Effect Analysis: FMEA From Theory to Execution. ASQ Quality Press.")
                ),
                
                box(
                  title = "Seven Deadly Wastes & Five Lean Principles", status = "primary", solidHeader = TRUE, width = 6,
                  p(strong("Seven Wastes:"), "Transport, Inventory, Motion, Waiting, Overproduction, Over-processing, Defects"),
                  p(strong("Five Lean Principles:"), "Value identification, Value stream mapping, Flow creation, Pull systems, Perfection pursuit"),
                  p("These frameworks guide systematic waste elimination and flow optimisation efforts."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Manufacturing cell eliminates transport waste (conveyors), inventory waste (JIT delivery), motion waste (ergonomic design), waiting waste (balanced line), overproduction waste (pull signals), achieving 40% productivity improvement."),
                      p(a(href = "https://www.lean.org/explore-lean/what-is-lean/", target = "_blank", "Lean Enterprise Institute principles")),
                      p(a(href = "https://www.isixsigma.com/methodology/lean/seven-wastes-original-seven-wastes/", target = "_blank", "Seven Wastes identification guide"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides systematic framework for waste identification"),
                        tags$li("Enables comprehensive process improvement approach"),
                        tags$li("Focuses on customer value creation")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May require significant cultural change to implement"),
                        tags$li("Can be overwhelming to address all wastes simultaneously"),
                        tags$li("Requires sustained management commitment")
                      )
                  ),
                  
                  p(strong("Reference:"), "Womack, J. & Jones, D. (2003). Lean Thinking: Banish Waste and Create Wealth. Free Press."),
                  p(strong("Dashboard Created and Edited by"), "J. Francisco Zubizarreta  @JBS University of Cambridge")
                )
              )
      ),
      
      # Improve Phase Tab
      tabItem(tabName = "improve",
              fluidRow(
                box(
                  title = "Pugh Matrix", status = "primary", solidHeader = TRUE, width = 6,
                  p("The Pugh Matrix systematically evaluates and compares solution alternatives against established criteria. Each option is rated as better (+), worse (-), or same (S) compared to a baseline solution. This structured approach ensures objective decision-making based on predetermined requirements."),
                  p("The matrix helps teams select optimal solutions whilst considering multiple evaluation criteria simultaneously."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Selecting customer service software: 5 options evaluated against criteria (cost, features, training). Current system baseline. Option A: Cost(-), Features(+), Training(S) = 0. Option B: Cost(+), Features(+), Training(+) = +3. Choose Option B."),
                      p(a(href = "https://www.asq.org/quality-resources/decision-matrix", target = "_blank", "ASQ Decision Matrix methods")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/pugh-matrix/", target = "_blank", "Pugh Matrix templates"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides structured, objective decision-making process"),
                        tags$li("Enables consideration of multiple criteria simultaneously"),
                        tags$li("Reduces bias in solution selection")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May oversimplify complex decision factors"),
                        tags$li("Doesn't weight criteria by importance"),
                        tags$li("Subjective in rating better/worse/same")
                      )
                  ),
                  
                  p(strong("Reference:"), "Pugh, S. (2004). Total Design: Integrated Methods for Successful Product Engineering. Addison-Wesley.")
                ),
                
                box(
                  title = "Poka Yoke", status = "primary", solidHeader = TRUE, width = 6,
                  p("Poka Yoke (mistake-proofing) designs error prevention directly into processes and products. These mechanisms make it impossible or immediately obvious when mistakes occur. Types include prevention devices that stop errors and detection devices that highlight them."),
                  p("Effective Poka Yoke solutions are simple, inexpensive, and eliminate human error through design rather than training or procedures."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Car manufacturer: Fuel cap tethered to prevent loss (prevention), different diesel/petrol nozzle sizes prevent wrong fuel (prevention), dashboard warning light for unfastened seatbelt (detection). Errors reduced 99%."),
                      p(a(href = "https://www.lean.org/lexicon-terms/poka-yoke/", target = "_blank", "Lean Enterprise Institute Poka Yoke")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/poka-yoke/", target = "_blank", "Poka Yoke examples and templates"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Eliminates human error through design"),
                        tags$li("Reduces inspection and rework costs"),
                        tags$li("Improves quality and customer satisfaction")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May require initial investment in design changes"),
                        tags$li("Can be difficult to implement in service processes"),
                        tags$li("Risk of over-engineering simple solutions")
                      )
                  ),
                  
                  p(strong("Reference:"), "Shingo, S. (2003). Zero Quality Control: Source Inspection and the Poka-yoke System. Productivity Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Five S", status = "primary", solidHeader = TRUE, width = 6,
                  p("Five S creates organised, efficient workplaces through systematic implementation:"),
                  tags$ul(
                    tags$li(strong("Sort (Seiri):"), "Remove unnecessary items"),
                    tags$li(strong("Set in Order (Seiton):"), "Organise remaining items"),
                    tags$li(strong("Shine (Seiso):"), "Clean and inspect regularly"),
                    tags$li(strong("Standardise (Seiketsu):"), "Establish consistent practices"),
                    tags$li(strong("Sustain (Shitsuke):"), "Maintain improvements long-term")
                  ),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Machine shop implements 5S: Removes unused tools (Sort), creates tool shadows boards (Set in Order), daily cleaning routine (Shine), standard procedures posted (Standardise), monthly audits (Sustain). 30% productivity increase."),
                      p(a(href = "https://www.lean.org/lexicon-terms/5s/", target = "_blank", "Lean Enterprise Institute 5S")),
                      p(a(href = "https://www.isixsigma.com/methodology/workplace-organization-5s/", target = "_blank", "5S implementation guides"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Improves workplace efficiency and safety"),
                        tags$li("Reduces time searching for tools and materials"),
                        tags$li("Creates foundation for other improvement initiatives")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Requires ongoing commitment and discipline"),
                        tags$li("May be seen as housekeeping rather than improvement"),
                        tags$li("Can become bureaucratic without proper implementation")
                      )
                  ),
                  
                  p(strong("Reference:"), "Hirano, H. (2004). 5 Pillars of the Visual Workplace. Productivity Press.")
                ),
                
                box(
                  title = "SMED", status = "primary", solidHeader = TRUE, width = 6,
                  p("Single-Minute Exchange of Dies (SMED) reduces setup and changeover times through systematic analysis and improvement. The methodology distinguishes between internal activities (requiring machine shutdown) and external activities (performed during operation)."),
                  p("SMED enables smaller batch sizes, improved flexibility, and reduced inventory whilst maintaining efficiency."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Injection moulding changeover reduced from 4 hours to 12 minutes: Pre-stage next die (external), quick-release clamps replace bolts (internal), standardise die heights (internal), pre-heat dies (external). 95% improvement."),
                      p(a(href = "https://www.lean.org/lexicon-terms/smed/", target = "_blank", "Lean Enterprise Institute SMED")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/smed/", target = "_blank", "SMED implementation guides"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Dramatically reduces changeover times"),
                        tags$li("Enables smaller batch production and flexibility"),
                        tags$li("Reduces inventory and improves cash flow")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May require significant equipment modifications"),
                        tags$li("Needs extensive operator training and practice"),
                        tags$li("Initial investment may be substantial")
                      )
                  ),
                  
                  p(strong("Reference:"), "Shingo, S. (2004). A Revolution in Manufacturing: The SMED System. Productivity Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Chaku-Chaku & Brainstorming", status = "primary", solidHeader = TRUE, width = 6,
                  p("Chaku-Chaku creates continuous flow manufacturing where operators move between stations, loading and unloading parts in sequence. This eliminates waiting time and reduces work-in-progress inventory."),
                  p("Brainstorming generates creative solutions through structured group ideation, encouraging quantity over quality initially, building on others' ideas, and deferring judgement until evaluation phases."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Assembly line redesign: Single operator manages 6 stations in sequence, parts flow automatically between stations. Chaku-Chaku reduces staffing 60% whilst maintaining output. Brainstorming session generates 150 ideas for improvement."),
                      p(a(href = "https://www.lean.org/lexicon-terms/chaku-chaku/", target = "_blank", "Lean Enterprise Institute Chaku-Chaku")),
                      p(a(href = "https://www.asq.org/quality-resources/brainstorming", target = "_blank", "ASQ Brainstorming techniques"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Eliminates waiting time and improves flow"),
                        tags$li("Reduces staffing requirements and costs"),
                        tags$li("Generates numerous creative solution options")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Requires significant process redesign and investment"),
                        tags$li("May increase operator stress and fatigue"),
                        tags$li("Brainstorming can generate impractical ideas requiring filtering")
                      )
                  ),
                  
                  p(strong("Reference:"), "Monden, Y. (2004). Toyota Production System: An Integrated Approach to Just-In-Time. Engineering & Management Press.")
                ),
                
                box(
                  title = "Design of Experiments", status = "primary", solidHeader = TRUE, width = 6,
                  p("Design of Experiments (DOE) systematically varies process inputs to determine their effects on outputs. This statistical approach efficiently identifies optimal operating conditions whilst minimising experimental effort. DOE reveals main effects, interactions, and optimal factor combinations."),
                  p("Proper experimental design provides maximum information with minimum resources whilst controlling for confounding variables."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Chemical process optimisation: 3 factors (temperature, pressure, catalyst) at 2 levels each. 2³ factorial design with 8 experiments identifies optimal conditions: 180°C, 15 bar, Catalyst A yields 95% vs 78% baseline."),
                      p(a(href = "https://www.asq.org/quality-resources/design-of-experiments", target = "_blank", "ASQ Design of Experiments")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/design-of-experiments-doe/", target = "_blank", "DOE planning and analysis tools"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Efficiently identifies optimal process conditions"),
                        tags$li("Reveals factor interactions not found through one-at-a-time testing"),
                        tags$li("Provides statistical confidence in results")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Requires statistical expertise to design and interpret"),
                        tags$li("May be expensive and time-consuming to execute"),
                        tags$li("Assumes linear relationships between factors")
                      )
                  ),
                  
                  p(strong("Reference:"), "Box, G. & Hunter, J. (2005). Statistics for Experimenters: Design, Innovation, and Discovery. John Wiley & Sons."),
                  p(strong("Dashboard Created and Edited by"), "J. Francisco Zubizarreta  @JBS University of Cambridge")
                )
              )
      ),
                  
                  
      
      # Control Phase Tab
      tabItem(tabName = "control",
              fluidRow(
                box(
                  title = "Andon", status = "primary", solidHeader = TRUE, width = 6,
                  p("Andon systems provide immediate visual and audible alerts when problems occur, enabling rapid response and problem resolution. These systems empower operators to stop production when quality issues arise, preventing defect propagation downstream."),
                  p("Andon promotes transparency, accountability, and continuous improvement culture by making problems visible to all stakeholders immediately."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Automotive assembly line: Red lights and alarms activate when quality issues detected. Production stops automatically, supervisors respond within 60 seconds. System prevents 2,000 defective units daily, saving £1.2M annually."),
                      p(a(href = "https://www.lean.org/lexicon-terms/andon/", target = "_blank", "Lean Enterprise Institute Andon")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/andon/", target = "_blank", "Andon system implementation"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Enables immediate problem detection and response"),
                        tags$li("Prevents defect propagation throughout the system"),
                        tags$li("Empowers operators to stop production for quality")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May cause frequent production stoppages initially"),
                        tags$li("Requires cultural change to accept production stops"),
                        tags$li("Can create stress and pressure on operators")
                      )
                  ),
                  
                  p(strong("Reference:"), "Liker, J. (2004). The Toyota Way. McGraw-Hill Professional.")
                ),
                
                box(
                  title = "Dashboard", status = "primary", solidHeader = TRUE, width = 6,
                  p("Performance dashboards provide real-time visibility into key process metrics through visual displays. Effective dashboards present critical information at-a-glance, using traffic light systems, trend charts, and exception reporting to highlight areas requiring attention."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Manufacturing dashboard displays real-time OEE (85% green), quality metrics (2.1% defects amber), production rate (102% target green), downtime alerts. Enables immediate response to performance variations and trend analysis."),
                      p(a(href = "https://www.asq.org/quality-resources/visual-management", target = "_blank", "ASQ Visual Management systems")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/dashboard/", target = "_blank", "Performance dashboard templates"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides real-time visibility into critical metrics"),
                        tags$li("Enables rapid response to performance variations"),
                        tags$li("Facilitates data-driven decision making")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can become overwhelming with too many metrics"),
                        tags$li("Requires reliable data collection systems"),
                        tags$li("May focus attention on metrics rather than improvement")
                      )
                  ),
                  
                  p(strong("Reference:"), "Few, S. (2004). Show Me the Numbers: Designing Tables and Graphs. Analytics Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Balanced Scorecard", status = "primary", solidHeader = TRUE, width = 6,
                  p("Balanced Scorecards translate strategy into action through four perspectives: Financial, Customer, Internal Process, and Learning & Growth. This framework ensures organisations maintain balanced focus across all critical success factors rather than optimising individual metrics in isolation."),
                  p("The scorecard links strategic objectives to operational metrics, enabling strategy execution monitoring and adjustment."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Retail company scorecard: Financial (15% ROI), Customer (Net Promoter Score 65), Internal Process (inventory turns 12x), Learning & Growth (employee satisfaction 4.2/5). Balanced approach drives sustainable performance."),
                      p(a(href = "https://www.balancedscorecard.org/bsc-basics/", target = "_blank", "Balanced Scorecard Institute")),
                      p(a(href = "https://www.asq.org/quality-resources/balanced-scorecard", target = "_blank", "ASQ Balanced Scorecard guide"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Links strategy to operational metrics"),
                        tags$li("Provides balanced view across multiple perspectives"),
                        tags$li("Prevents sub-optimisation of individual metrics")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can become complex with too many metrics"),
                        tags$li("Requires significant effort to maintain and update"),
                        tags$li("May dilute focus if not properly prioritised")
                      )
                  ),
                  
                  p(strong("Reference:"), "Kaplan, R. & Norton, D. (2004). Strategy Maps: Converting Intangible Assets into Tangible Outcomes. Harvard Business Review Press.")
                ),
                
                box(
                  title = "Control/Run Charts", status = "primary", solidHeader = TRUE, width = 6,
                  p("Control charts monitor process stability over time by plotting data points against calculated control limits. These statistical tools distinguish between common cause variation (inherent to the process) and special cause variation (requiring investigation and action)."),
                  p("Run charts provide simpler trend analysis without statistical limits, helping identify patterns, shifts, and trends in process performance."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Call centre response time control chart shows process in control with UCL=45sec, LCL=15sec, mean=30sec. Point at 50sec indicates special cause requiring investigation. Reveals training impact reducing variation."),
                      p(a(href = "https://www.asq.org/quality-resources/control-chart", target = "_blank", "ASQ Control Charts guide")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/control-charts/", target = "_blank", "Control chart templates and interpretation"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Distinguishes between common and special cause variation"),
                        tags$li("Provides early warning of process changes"),
                        tags$li("Enables objective process monitoring and control")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Requires understanding of statistical principles"),
                        tags$li("May give false signals if assumptions not met"),
                        tags$li("Can be complex to implement for multivariate processes")
                      )
                  ),
                  
                  p(strong("Reference:"), "Shewhart, W. (2003). Economic Control of Quality of Manufactured Product. ASQ Quality Press."),
                  p(strong("Dashboard Created and Edited by"), "J. Francisco Zubizarreta  @JBS University of Cambridge")
                  
                )
              )
      ),
      
      # Data Analysis Tab
      tabItem(tabName = "data",
              fluidRow(
                box(
                  title = "Central Limit Theorem & Normal Distribution", status = "primary", solidHeader = TRUE, width = 6,
                  p("The Central Limit Theorem states that sampling distributions of means approach normality regardless of population distribution shape, provided sufficient sample size (typically n≥30). This fundamental principle enables statistical inference and hypothesis testing in Six Sigma applications."),
                  p("Normal distribution characteristics (bell curve, symmetrical, defined by mean and standard deviation) underpin many Six Sigma statistical tools and capability analyses."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Manufacturing process with skewed individual measurements still produces normally distributed sample means (n=50). Enables confidence intervals: mean±1.96σ contains 95% of sample means, supporting capability analysis."),
                      p(a(href = "https://www.asq.org/quality-resources/central-limit-theorem", target = "_blank", "ASQ Central Limit Theorem")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/normality/", target = "_blank", "Normal distribution in Six Sigma"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Enables statistical inference regardless of population shape"),
                        tags$li("Provides foundation for capability analysis and control charts"),
                        tags$li("Allows confidence interval construction for decision making")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Requires adequate sample size for theorem to apply"),
                        tags$li("May not apply to extremely skewed or discrete distributions"),
                        tags$li("Can lead to incorrect conclusions if assumptions violated")
                      )
                  ),
                  
                  p(strong("Reference:"), "DeVore, J. (2004). Probability and Statistics for Engineering and the Sciences. Thomson Brooks/Cole.")
                ),
                
                box(
                  title = "Data Collection Methods", status = "primary", solidHeader = TRUE, width = 6,
                  p("Effective data collection requires understanding data types and appropriate sampling methods:"),
                  tags$ul(
                    tags$li(strong("Count Data:"), "Discrete attributes (defects, errors)"),
                    tags$li(strong("Continuous Data:"), "Measurable variables (time, temperature, weight)")
                  ),
                  p("Sampling strategies include random, systematic, stratified, and cluster sampling. Proper sampling ensures representative data whilst managing collection costs and time constraints."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Quality survey uses stratified sampling: 100 customers each from retail (continuous data: satisfaction 1-10) and online (count data: complaints yes/no) channels. Ensures representative sample across customer segments."),
                      p(a(href = "https://www.asq.org/quality-resources/sampling", target = "_blank", "ASQ Sampling methods")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/data-collection/", target = "_blank", "Data collection planning guides"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Ensures data quality and representativeness"),
                        tags$li("Optimises resource allocation for data collection"),
                        tags$li("Enables appropriate statistical analysis selection")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Can be time-consuming and expensive to implement properly"),
                        tags$li("Sampling bias may occur if not carefully designed"),
                        tags$li("May miss important but rare events or conditions")
                      )
                  ),
                  
                  p(strong("Reference:"), "Cochran, W. (2003). Sampling Techniques. John Wiley & Sons.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Sigma Level & Process Capability", status = "primary", solidHeader = TRUE, width = 6,
                  p("Sigma Level quantifies process capability in terms of standard deviations between process mean and nearest specification limit. Higher sigma levels indicate better capability and lower defect rates. Six Sigma represents 3.4 DPMO when accounting for 1.5σ shift."),
                  p("Process capability indices (Cp, Cpk) provide standardised measures comparing process variation to specification width and centering."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Process with specification 100±10, mean=102, σ=2.5 has sigma level = min[(110-102)/2.5, (102-90)/2.5] = 3.2σ, predicting ~1,350 DPMO. Improvement target: 4σ level (63 DPMO)."),
                      p(a(href = "https://www.asq.org/quality-resources/sigma-level", target = "_blank", "ASQ Sigma Level calculations")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/capability-analysis/", target = "_blank", "Process capability tools"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides universal metric for process performance comparison"),
                        tags$li("Predicts defect rates and customer impact"),
                        tags$li("Enables benchmarking across different processes and industries")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Assumes normal distribution and stable process"),
                        tags$li("1.5σ shift assumption may not apply to all processes"),
                        tags$li("Focus on sigma level may overshadow customer requirements")
                      )
                  ),
                  
                  p(strong("Reference:"), "Harry, M. (2003). Six Sigma: The Breakthrough Management Strategy Revolutionizing. Currency Books.")
                ),
                
                box(
                  title = "Cp, Cpk & Graphical Methods", status = "primary", solidHeader = TRUE, width = 6,
                  p("Capability indices quantify process performance:"),
                  tags$ul(
                    tags$li(strong("Cp:"), "Potential capability = (USL - LSL) / (6σ)"),
                    tags$li(strong("Cpk:"), "Actual capability considering centering = min[(USL - μ)/3σ, (μ - LSL)/3σ]")
                  ),
                  p("Graphical methods include histograms with specification limits, normal probability plots, and capability plots providing visual assessment of process performance."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Machining process: USL=50, LSL=40, μ=44, σ=1.5. Cp=(50-40)/(6×1.5)=1.11 (adequate potential). Cpk=min[(50-44)/(3×1.5), (44-40)/(3×1.5)]=min[1.33,0.89]=0.89 (needs centering)."),
                      p(a(href = "https://www.asq.org/quality-resources/process-capability", target = "_blank", "ASQ Process Capability indices")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/capability-analysis/", target = "_blank", "Capability analysis tools"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Quantifies both potential and actual process performance"),
                        tags$li("Identifies whether centering or variation reduction needed"),
                        tags$li("Provides graphical confirmation of numerical results")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Requires stable, normally distributed process data"),
                        tags$li("May not reflect customer perception of capability"),
                        tags$li("Can be misleading if process not in statistical control")
                      )
                  ),
                  
                  p(strong("Reference:"), "Kane, V. (2004). Defect Prevention: Use of Simple Statistical Tools. CRC Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Control Charts - X-bar, R, p Charts", status = "primary", solidHeader = TRUE, width = 12,
                  p("Statistical Process Control charts monitor process stability:"),
                  tags$ul(
                    tags$li(strong("X-bar charts:"), "Monitor process centre (subgroup means)"),
                    tags$li(strong("R charts:"), "Monitor process spread (subgroup ranges)"),
                    tags$li(strong("p charts:"), "Monitor proportion defective (attribute data)")
                  ),
                  p("Chart interpretation focuses on identifying out-of-control signals: points beyond control limits, runs, trends, and patterns. These signals indicate special causes requiring investigation and corrective action to restore process stability."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Production line X-bar chart shows 7 consecutive points above centerline (run test failure). Investigation reveals new operator needs training. R chart stable, indicating centering issue not variation problem."),
                      p(a(href = "https://www.asq.org/quality-resources/control-chart", target = "_blank", "ASQ Control Chart fundamentals")),
                      p(a(href = "https://www.isixsigma.com/tools-templates/control-charts/", target = "_blank", "Control chart construction and interpretation"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Provides early detection of process changes"),
                        tags$li("Distinguishes assignable causes from random variation"),
                        tags$li("Enables proactive process management and control")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Requires training to interpret signals correctly"),
                        tags$li("May produce false alarms or miss real signals"),
                        tags$li("Assumes rational subgrouping and normal distribution")
                      )
                  ),
                  
                  p(strong("Reference:"), "Montgomery, D. (2004). Introduction to Statistical Quality Control. John Wiley & Sons."),
                  p(strong("Dashboard Created and Edited by"), "J. Francisco Zubizarreta  @JBS University of Cambridge")
                )
              )
      ),
      
      
      # Implementation Tab
      tabItem(tabName = "implementation",
              fluidRow(
                box(
                  title = "Implementation Challenges", status = "primary", solidHeader = TRUE, width = 12,
                  p("Common Six Sigma implementation challenges include resistance to change, insufficient leadership commitment, inadequate training, poor project selection, lack of data discipline, and failure to link projects to strategic objectives. Cultural barriers often present the greatest obstacles, requiring sustained change management efforts."),
                  p("Successful implementation requires addressing both technical and human factors through comprehensive change management, clear communication, and visible leadership support."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Healthcare system struggled with physician resistance to standardised protocols. Success achieved through physician champions, clinical evidence presentations, and gradual implementation with quick wins demonstrating patient outcome improvements."),
                      p(a(href = "https://www.asq.org/quality-resources/change-management", target = "_blank", "ASQ Change Management in Quality")),
                      p(a(href = "https://www.isixsigma.com/implementation/change-management/", target = "_blank", "Six Sigma change management strategies"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Identifying challenges enables proactive mitigation strategies"),
                        tags$li("Learning from common pitfalls improves success probability"),
                        tags$li("Structured approach to change management reduces resistance")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Change management requires significant time and resources"),
                        tags$li("Some resistance may persist despite best efforts"),
                        tags$li("Cultural change is slow and difficult to measure")
                      )
                  ),
                  
                  p(strong("Reference:"), "Snee, R. & Hoerl, R. (2005). Leading Six Sigma: A Step-by-Step Guide. FT Press.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Implementation Limitations", status = "primary", solidHeader = TRUE, width = 6,
                  p("Six Sigma limitations include potential over-emphasis on statistical analysis at the expense of innovation, high implementation costs, lengthy project cycles, and unsuitability for all process types. The methodology works best for repetitive, measurable processes with clear specifications."),
                  p("Service processes and creative activities may require modified approaches or alternative improvement methodologies. Cultural fit and organisational readiness significantly influence implementation success."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Software development company found traditional DMAIC unsuitable for agile development. Adopted modified approach combining Six Sigma tools with agile principles, focusing on defect reduction rather than process standardisation."),
                      p(a(href = "https://www.asq.org/quality-resources/lean-six-sigma", target = "_blank", "ASQ Lean Six Sigma adaptations")),
                      p(a(href = "https://www.isixsigma.com/implementation/basics/six-sigma-limitations/", target = "_blank", "Understanding Six Sigma limitations"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Realistic expectations prevent disappointment and failure"),
                        tags$li("Enables appropriate methodology selection for different contexts"),
                        tags$li("Guides resource allocation decisions")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("May discourage organisations from attempting implementation"),
                        tags$li("Can create excuse for poor implementation efforts"),
                        tags$li("Limits application scope and potential benefits")
                      )
                  ),
                  
                  p(strong("Reference:"), "Bendell, T. (2006). A review and comparison of six sigma and the lean organisations. The TQM Magazine.")
                ),
                
                box(
                  title = "Implementation Benefits", status = "primary", solidHeader = TRUE, width = 6,
                  p("Six Sigma implementation delivers multiple organisational benefits including significant cost reduction, improved customer satisfaction, enhanced process capability, reduced cycle times, and stronger data-driven decision making culture."),
                  p("Long-term benefits include improved employee engagement, enhanced problem-solving capabilities, standardised improvement methodology, and sustainable competitive advantage through operational excellence."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("General Electric achieved $12 billion cumulative savings over 5 years, improved customer satisfaction scores 25%, reduced cycle times 50%, and developed 15,000 trained Black and Green Belts creating lasting capability."),
                      p(a(href = "https://www.ge.com/news/taxonomy/term/3036", target = "_blank", "GE Six Sigma success stories")),
                      p(a(href = "https://www.asq.org/quality-resources/benefits-of-quality", target = "_blank", "ASQ Benefits of Quality programs"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Quantifiable financial returns justify investment"),
                        tags$li("Builds sustainable improvement capability"),
                        tags$li("Creates competitive advantage through operational excellence")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Benefits may take 2-3 years to fully materialise"),
                        tags$li("Requires sustained investment and commitment"),
                        tags$li("Success depends on proper implementation and cultural fit")
                      )
                  ),
                  
                  p(strong("Reference:"), "Pande, P., Neuman, R. & Cavanagh, R. (2000). The Six Sigma Way. McGraw-Hill Professional.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Success Factors", status = "primary", solidHeader = TRUE, width = 6,
                  p("Critical success factors for Six Sigma implementation include visible senior leadership commitment, adequate resource allocation, proper Belt training and certification, strategic project selection aligned with business objectives, and robust measurement systems."),
                  p("Organisational readiness, cultural alignment, effective communication, and sustained focus on customer value creation determine long-term implementation success."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("Motorola's successful implementation featured CEO personal involvement, 4% salary allocation to quality training, projects tied to business strategy, comprehensive measurement systems, and 10-year sustained commitment achieving 100x quality improvement."),
                      p(a(href = "https://www.motorolasolutions.com/en_us/about/company-overview/history.html", target = "_blank", "Motorola Six Sigma history")),
                      p(a(href = "https://www.asq.org/quality-resources/six-sigma/implementation", target = "_blank", "ASQ Six Sigma implementation guide"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Proven factors increase probability of successful implementation"),
                        tags$li("Provides roadmap for implementation planning"),
                        tags$li("Enables early identification and correction of problems")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Success factors may conflict with organisational constraints"),
                        tags$li("Requires significant leadership commitment and resources"),
                        tags$li("One weak factor can undermine entire implementation")
                      )
                  ),
                  
                  p(strong("Reference:"), "Antony, J. & Banuelas, R. (2002). Key ingredients for the effective implementation of Six Sigma program. Measuring Business Excellence.")
                ),
                
                box(
                  title = "Sustainability Strategies", status = "primary", solidHeader = TRUE, width = 6,
                  p("Sustaining Six Sigma requires embedding the methodology into organisational DNA through performance management systems, reward structures, hiring criteria, and ongoing training programmes. Regular programme reviews and refresher training prevent methodology drift."),
                  p("Integration with other improvement initiatives, continuous project pipeline management, and celebration of success stories maintain momentum and engagement over time."),
                  
                  div(class = "example-box",
                      h4("Example:"),
                      p("3M integrated Six Sigma into performance reviews (20% weighting), hiring criteria (Belt certification preferred), reward systems (project savings bonuses), and annual recognition programmes, achieving 15+ years sustained implementation."),
                      p(a(href = "https://www.3m.com/3M/en_US/company-us/about-3m/", target = "_blank", "3M operational excellence")),
                      p(a(href = "https://www.asq.org/quality-resources/sustainability", target = "_blank", "ASQ Sustainability in Quality"))
                  ),
                  
                  div(class = "benefits",
                      h4("Benefits:"),
                      tags$ul(
                        tags$li("Prevents programme decay and maintains momentum"),
                        tags$li("Embeds improvement culture permanently"),
                        tags$li("Maximises long-term return on implementation investment")
                      )
                  ),
                  
                  div(class = "disadvantages",
                      h4("Disadvantages:"),
                      tags$ul(
                        tags$li("Requires ongoing resource allocation and attention"),
                        tags$li("May become bureaucratic without proper management"),
                        tags$li("Competing priorities can undermine sustainability efforts")
                      )
                  ),
                  
                  p(strong("Reference:"), "Eckes, G. (2003). Six Sigma for Everyone. John Wiley & Sons."),
                  p(strong("Dashboard Created and Edited by"), "J. Francisco Zubizarreta  @JBS University of Cambridge")
                  
                )
              )
      )
   )
 )
)

# Define server logic
server <- function(input, output) {
 # Server logic can be added here for interactive elements if needed
 # Currently, the dashboard is primarily informational
}

# Run the application
shinyApp(ui = ui, server = server)