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
                  p(strong("Reference:"), "Pyzdek, T. (2003). The Six Sigma revolution. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Harry, M. & Schroeder, R. (2000). Six Sigma roles and responsibilities. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Six Sigma Framework (DMAIC/DMADV)", status = "primary", solidHeader = TRUE, width = 6,
                  p("Six Sigma employs two primary methodologies:"),
                  p(strong("DMAIC"), "(Define, Measure, Analyse, Improve, Control) - Used for existing process improvement"),
                  p(strong("DMADV"), "(Define, Measure, Analyse, Design, Verify) - Used for new product or process design"),
                  p("DMAIC focuses on incremental improvements to existing processes, whilst DMADV is employed when creating new processes or products from scratch."),
                  p(strong("Reference:"), "Brue, G. (2002). Six Sigma methodologies. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Process Owners/Project Champions", status = "primary", solidHeader = TRUE, width = 6,
                  p("Process owners are individuals responsible for the end-to-end performance of specific business processes. They ensure processes meet customer requirements and organisational objectives. Project champions are senior leaders who provide resources, remove barriers, and ensure project alignment with strategic goals."),
                  p("Champions typically hold executive positions and possess authority to allocate resources and drive organisational change necessary for project success."),
                  p(strong("Reference:"), "Snee, R. (2004). Process ownership in Six Sigma. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Quality Management and Gurus", status = "primary", solidHeader = TRUE, width = 12,
                  p("Six Sigma builds upon the foundational work of quality management pioneers including W. Edwards Deming (Plan-Do-Check-Act cycle), Joseph Juran (Quality Trilogy), Philip Crosby (Zero Defects), and Walter Shewhart (Statistical Process Control). These quality gurus established the theoretical framework upon which modern Six Sigma practices are built."),
                  p("Their collective contributions emphasise statistical thinking, customer focus, continuous improvement, and management commitment as essential elements of quality excellence."),
                  p(strong("Reference:"), "Evans, J. & Lindsay, W. (2005). Quality gurus and Six Sigma foundations. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "George, M. (2003). Project charter development. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Stakeholder Analysis", status = "primary", solidHeader = TRUE, width = 6,
                  p("Stakeholder analysis identifies all parties affected by or influencing the project. This systematic assessment evaluates stakeholder interests, influence levels, and potential impact on project success. Understanding stakeholder dynamics enables effective communication strategies and change management approaches."),
                  p("Stakeholders are typically categorised by their level of influence and interest in the project outcomes."),
                  p(strong("Reference:"), "Keller, P. (2004). Stakeholder management in Six Sigma. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Breyfogle, F. (2003). Quality metrics fundamentals. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "SIPOC/COPIS", status = "primary", solidHeader = TRUE, width = 6,
                  p("SIPOC (Suppliers, Inputs, Process, Outputs, Customers) is a high-level process mapping tool that provides a structured view of process boundaries and key elements. COPIS reverses the order for customer-focused analysis."),
                  p("This tool helps teams understand process scope, identify key stakeholders, and establish process boundaries before detailed analysis begins."),
                  p(strong("Reference:"), "Siviy, J. (2004). SIPOC diagram applications. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Voice of the Customer", status = "primary", solidHeader = TRUE, width = 6,
                  p("Voice of the Customer (VOC) represents customer needs, expectations, and requirements expressed in their own language. VOC data is collected through surveys, interviews, focus groups, and direct observation to understand what customers truly value."),
                  p("This information drives project prioritisation and ensures solutions address genuine customer pain points rather than assumed problems."),
                  p(strong("Reference:"), "Ulwick, A. (2005). Customer voice capture methods. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Critical to Quality Trees", status = "primary", solidHeader = TRUE, width = 6,
                  p("Critical to Quality (CTQ) Trees translate broad customer requirements into specific, measurable characteristics. They provide a hierarchical breakdown from customer needs to actionable metrics, ensuring project teams focus on factors that directly impact customer satisfaction."),
                  p("CTQ Trees bridge the gap between qualitative customer feedback and quantitative process measurements."),
                  p(strong("Reference:"), "Watson, G. (2004). CTQ tree methodology. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Pande, P. (2003). Financial benefits classification. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Breakthrough Equation & Kaizen/Kaikaku", status = "primary", solidHeader = TRUE, width = 6,
                  p("The Breakthrough Equation: Y = f(X) + ε represents that outcomes (Y) are functions of process inputs (X) plus error (ε)."),
                  p(strong("Kaizen:"), "Continuous, incremental improvement philosophy"),
                  p(strong("Kaikaku:"), "Radical, breakthrough improvement requiring fundamental process redesign"),
                  p("Both approaches are essential for comprehensive process improvement strategies."),
                  p(strong("Reference:"), "Imai, M. (2004). Improvement methodologies. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Ishikawa, K. (2003). Basic quality tools application. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "House of Quality", status = "primary", solidHeader = TRUE, width = 6,
                  p("The House of Quality is the primary tool in Quality Function Deployment (QFD). It systematically translates customer requirements into technical specifications and design targets. The matrix structure correlates customer needs with engineering characteristics, enabling teams to prioritise development efforts."),
                  p("This tool ensures customer voice remains central throughout product development whilst managing technical trade-offs."),
                  p(strong("Reference:"), "Akao, Y. (2004). Quality Function Deployment principles. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Gage R&R", status = "primary", solidHeader = TRUE, width = 6,
                  p("Gage Repeatability and Reproducibility (R&R) studies assess measurement system capability. Repeatability examines variation when the same operator measures the same part multiple times. Reproducibility evaluates variation between different operators measuring the same parts."),
                  p("A capable measurement system should contribute less than 10% of total process variation. Gage R&R ensures data reliability before process improvement efforts begin."),
                  p(strong("Reference:"), "Wheeler, D. (2004). Measurement system analysis. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Campanella, J. (2003). Cost of quality framework. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Capability Analysis", status = "primary", solidHeader = TRUE, width = 12,
                  p("Process capability analysis evaluates how well a process meets specifications. It compares process variation to specification limits, providing indices that quantify process performance. Capability studies require stable processes and normally distributed data."),
                  p("Key capability indices include Cp (potential capability), Cpk (actual capability considering centering), Pp (performance), and Ppk (performance with centering). These metrics guide improvement priorities and help predict defect rates."),
                  p(strong("Reference:"), "Montgomery, D. (2005). Statistical process capability. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Rother, M. & Shook, J. (2003). Value stream mapping techniques. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Wilson, P. (2004). Root cause analysis methods. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Pareto Analysis", status = "primary", solidHeader = TRUE, width = 6,
                  p("Pareto Analysis applies the 80/20 rule, identifying the vital few factors causing most problems. By ranking issues by frequency or impact, teams focus improvement efforts on the most significant contributors. Pareto charts provide visual representation of relative problem importance."),
                  p("This prioritisation tool ensures resources are directed toward the highest-impact improvement opportunities."),
                  p(strong("Reference:"), "Juran, J. (2003). Pareto principle applications. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Spaghetti Diagrams", status = "primary", solidHeader = TRUE, width = 6,
                  p("Spaghetti Diagrams track movement patterns of people, materials, or information through a workspace. These visual tools reveal inefficient layouts, excessive travel distances, and opportunities for workflow optimisation. The resulting diagram often resembles tangled spaghetti, hence the name."),
                  p("By mapping actual movement patterns, teams can redesign layouts to minimise waste and improve efficiency."),
                  p(strong("Reference:"), "Womack, J. (2004). Workflow analysis techniques. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Business Impact Analysis & FMEA", status = "primary", solidHeader = TRUE, width = 6,
                  p("Business Impact Analysis quantifies potential consequences of process failures, helping prioritise improvement efforts. Failure Mode and Effects Analysis (FMEA) systematically examines potential failure modes, their causes, and effects."),
                  p("FMEA uses Risk Priority Numbers (RPN) calculated from Severity × Occurrence × Detection ratings to prioritise improvement actions."),
                  p(strong("Reference:"), "Stamatis, D. (2003). FMEA methodology. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Seven Deadly Wastes & Five Lean Principles", status = "primary", solidHeader = TRUE, width = 6,
                  p(strong("Seven Wastes:"), "Transport, Inventory, Motion, Waiting, Overproduction, Over-processing, Defects"),
                  p(strong("Five Lean Principles:"), "Value identification, Value stream mapping, Flow creation, Pull systems, Perfection pursuit"),
                  p("These frameworks guide systematic waste elimination and flow optimisation efforts."),
                  p(strong("Reference:"), "Womack, J. & Jones, D. (2003). Lean principles and waste identification. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Pugh, S. (2004). Solution evaluation methodology. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Poka Yoke", status = "primary", solidHeader = TRUE, width = 6,
                  p("Poka Yoke (mistake-proofing) designs error prevention directly into processes and products. These mechanisms make it impossible or immediately obvious when mistakes occur. Types include prevention devices that stop errors and detection devices that highlight them."),
                  p("Effective Poka Yoke solutions are simple, inexpensive, and eliminate human error through design rather than training or procedures."),
                  p(strong("Reference:"), "Shingo, S. (2003). Error-proofing techniques. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Hirano, H. (2004). Workplace organisation methods. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "SMED", status = "primary", solidHeader = TRUE, width = 6,
                  p("Single-Minute Exchange of Dies (SMED) reduces setup and changeover times through systematic analysis and improvement. The methodology distinguishes between internal activities (requiring machine shutdown) and external activities (performed during operation)."),
                  p("SMED enables smaller batch sizes, improved flexibility, and reduced inventory whilst maintaining efficiency."),
                  p(strong("Reference:"), "Shingo, S. (2004). Setup reduction techniques. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Chaku-Chaku & Brainstorming", status = "primary", solidHeader = TRUE, width = 6,
                  p("Chaku-Chaku creates continuous flow manufacturing where operators move between stations, loading and unloading parts in sequence. This eliminates waiting time and reduces work-in-progress inventory."),
                  p("Brainstorming generates creative solutions through structured group ideation, encouraging quantity over quality initially, building on others' ideas, and deferring judgement until evaluation phases."),
                  p(strong("Reference:"), "Monden, Y. (2004). Flow manufacturing principles. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Design of Experiments", status = "primary", solidHeader = TRUE, width = 6,
                  p("Design of Experiments (DOE) systematically varies process inputs to determine their effects on outputs. This statistical approach efficiently identifies optimal operating conditions whilst minimising experimental effort. DOE reveals main effects, interactions, and optimal factor combinations."),
                  p("Proper experimental design provides maximum information with minimum resources whilst controlling for confounding variables."),
                  p(strong("Reference:"), "Box, G. & Hunter, J. (2005). Experimental design principles. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Liker, J. (2004). Visual management systems. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Dashboard", status = "primary", solidHeader = TRUE, width = 6,
                  p("Performance dashboards provide real-time visibility into key process metrics through visual displays. Effective dashboards present critical information at-a-glance, using traffic light systems, trend charts, and exception reporting to highlight areas requiring attention."),
                  p("Dashboards enable data-driven decision making and rapid response to process variations or performance gaps."),
                  p(strong("Reference:"), "Few, S. (2004). Dashboard design principles. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Balanced Scorecard", status = "primary", solidHeader = TRUE, width = 6,
                  p("Balanced Scorecards translate strategy into action through four perspectives: Financial, Customer, Internal Process, and Learning & Growth. This framework ensures organisations maintain balanced focus across all critical success factors rather than optimising individual metrics in isolation."),
                  p("The scorecard links strategic objectives to operational metrics, enabling strategy execution monitoring and adjustment."),
                  p(strong("Reference:"), "Kaplan, R. & Norton, D. (2004). Strategic measurement systems. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Control/Run Charts", status = "primary", solidHeader = TRUE, width = 6,
                  p("Control charts monitor process stability over time by plotting data points against calculated control limits. These statistical tools distinguish between common cause variation (inherent to the process) and special cause variation (requiring investigation and action)."),
                  p("Run charts provide simpler trend analysis without statistical limits, helping identify patterns, shifts, and trends in process performance."),
                  p(strong("Reference:"), "Shewhart, W. (2003). Statistical process control. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "DeVore, J. (2004). Probability and statistics foundations. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Data Collection Methods", status = "primary", solidHeader = TRUE, width = 6,
                  p("Effective data collection requires understanding data types and appropriate sampling methods:"),
                  tags$ul(
                    tags$li(strong("Count Data:"), "Discrete attributes (defects, errors)"),
                    tags$li(strong("Continuous Data:"), "Measurable variables (time, temperature, weight)")
                  ),
                  p("Sampling strategies include random, systematic, stratified, and cluster sampling. Proper sampling ensures representative data whilst managing collection costs and time constraints."),
                  p(strong("Reference:"), "Cochran, W. (2003). Sampling methodology. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Sigma Level & Process Capability", status = "primary", solidHeader = TRUE, width = 6,
                  p("Sigma Level quantifies process capability in terms of standard deviations between process mean and nearest specification limit. Higher sigma levels indicate better capability and lower defect rates. Six Sigma represents 3.4 DPMO when accounting for 1.5σ shift."),
                  p("Process capability indices (Cp, Cpk) provide standardised measures comparing process variation to specification width and centering."),
                  p(strong("Reference:"), "Harry, M. (2003). Sigma level calculations. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Cp, Cpk & Graphical Methods", status = "primary", solidHeader = TRUE, width = 6,
                  p("Capability indices quantify process performance:"),
                  tags$ul(
                    tags$li(strong("Cp:"), "Potential capability = (USL - LSL) / (6σ)"),
                    tags$li(strong("Cpk:"), "Actual capability considering centering = min[(USL - μ)/3σ, (μ - LSL)/3σ]")
                  ),
                  p("Graphical methods include histograms with specification limits, normal probability plots, and capability plots providing visual assessment of process performance."),
                  p(strong("Reference:"), "Kane, V. (2004). Process capability analysis. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Montgomery, D. (2004). Statistical process control charts. iSixSigma. Available at: http://www.isixsigma.com")
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
                  p(strong("Reference:"), "Snee, R. & Hoerl, R. (2005). Six Sigma implementation challenges. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Implementation Limitations", status = "primary", solidHeader = TRUE, width = 6,
                  p("Six Sigma limitations include potential over-emphasis on statistical analysis at the expense of innovation, high implementation costs, lengthy project cycles, and unsuitability for all process types. The methodology works best for repetitive, measurable processes with clear specifications."),
                  p("Service processes and creative activities may require modified approaches or alternative improvement methodologies. Cultural fit and organisational readiness significantly influence implementation success."),
                  p(strong("Reference:"), "Bendell, T. (2006). Six Sigma limitations and applications. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Implementation Benefits", status = "primary", solidHeader = TRUE, width = 6,
                  p("Six Sigma implementation delivers multiple organisational benefits including significant cost reduction, improved customer satisfaction, enhanced process capability, reduced cycle times, and stronger data-driven decision making culture."),
                  p("Long-term benefits include improved employee engagement, enhanced problem-solving capabilities, standardised improvement methodology, and sustainable competitive advantage through operational excellence."),
                  p(strong("Reference:"), "Pande, P., Neuman, R. & Cavanagh, R. (2000). Six Sigma implementation benefits. iSixSigma. Available at: http://www.isixsigma.com")
                )
              ),
              fluidRow(
                box(
                  title = "Success Factors", status = "primary", solidHeader = TRUE, width = 6,
                  p("Critical success factors for Six Sigma implementation include visible senior leadership commitment, adequate resource allocation, proper Belt training and certification, strategic project selection aligned with business objectives, and robust measurement systems."),
                  p("Organisational readiness, cultural alignment, effective communication, and sustained focus on customer value creation determine long-term implementation success."),
                  p(strong("Reference:"), "Antony, J. & Banuelas, R. (2002). Critical success factors. iSixSigma. Available at: http://www.isixsigma.com")
                ),
                box(
                  title = "Sustainability Strategies", status = "primary", solidHeader = TRUE, width = 6,
                  p("Sustaining Six Sigma requires embedding the methodology into organisational DNA through performance management systems, reward structures, hiring criteria, and ongoing training programmes. Regular programme reviews and refresher training prevent methodology drift."),
                  p("Integration with other improvement initiatives, continuous project pipeline management, and celebration of success stories maintain momentum and engagement over time."),
                  p(strong("Reference:"), "Eckes, G. (2003). Six Sigma sustainability. iSixSigma. Available at: http://www.isixsigma.com")
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