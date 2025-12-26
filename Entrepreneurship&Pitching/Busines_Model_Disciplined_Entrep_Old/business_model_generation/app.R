
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(htmltools)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Business Model Generation - Interactive Guide"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Canvas Foundation", tabName = "canvas", icon = icon("paint-brush")),
      menuItem("Patterns", tabName = "patterns", icon = icon("th-large")),
      menuItem("Design Process", tabName = "design", icon = icon("lightbulb")),
      menuItem("Strategy", tabName = "strategy", icon = icon("chess")),
      menuItem("Implementation Process", tabName = "process", icon = icon("cogs")),
      menuItem("Business Model Canvas", tabName = "bmc_template", icon = icon("table"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
        .box {
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .canvas-section {
          border: 2px solid;
          border-radius: 10px;
          padding: 15px;
          margin: 5px;
          min-height: 200px;
          position: relative;
        }
        .section-title {
          font-weight: bold;
          font-size: 16px;
          margin-bottom: 10px;
          display: flex;
          align-items: center;
        }
        .section-icon {
          margin-right: 8px;
          font-size: 20px;
        }
        .section-content {
          font-size: 12px;
          line-height: 1.4;
        }
        .key-partners { background: linear-gradient(135deg, #FF6B6B, #FF8E8E); border-color: #FF4757; color: white; }
        .key-activities { background: linear-gradient(135deg, #4ECDC4, #26D0CE); border-color: #00A8A8; color: white; }
        .value-propositions { background: linear-gradient(135deg, #45B7D1, #74C0FC); border-color: #3742FA; color: white; }
        .customer-relationships { background: linear-gradient(135deg, #96CEB4, #DDA0DD); border-color: #6C5CE7; color: white; }
        .customer-segments { background: linear-gradient(135deg, #FECA57, #FD79A8); border-color: #FDCB6E; color: black; }
        .key-resources { background: linear-gradient(135deg, #A29BFE, #6C5CE7); border-color: #5F27CD; color: white; }
        .channels { background: linear-gradient(135deg, #FD79A8, #E17055); border-color: #E84393; color: white; }
        .cost-structure { background: linear-gradient(135deg, #636E72, #2D3436); border-color: #636E72; color: white; }
        .revenue-streams { background: linear-gradient(135deg, #00B894, #55A3FF); border-color: #00B894; color: white; }
        .canvas-grid {
          display: grid;
          grid-template-columns: 1fr 1fr 1fr 1fr 1fr;
          grid-template-rows: 1fr 1fr 1fr;
          gap: 10px;
          height: 700px;
          margin: 20px 0;
        }
        .partners { grid-column: 1; grid-row: 1 / 3; }
        .activities { grid-column: 2; grid-row: 1; }
        .resources { grid-column: 2; grid-row: 2; }
        .value-prop { grid-column: 3; grid-row: 1 / 3; }
        .relationships { grid-column: 4; grid-row: 1; }
        .channels-grid { grid-column: 4; grid-row: 2; }
        .segments { grid-column: 5; grid-row: 1 / 3; }
        .costs { grid-column: 1 / 3; grid-row: 3; }
        .revenue { grid-column: 4 / 6; grid-row: 3; }
      "))
    ),
    
    tabItems(
      # Canvas Foundation Tab
      tabItem(
        tabName = "canvas",
        fluidRow(
          box(
            title = "Definition of a Business Model", status = "primary", solidHeader = TRUE, width = 6,
            p("A business model describes the rationale of how an organization creates, delivers, and captures value."),
            h4("Key Components:"),
            tags$ul(
              tags$li("Value Creation: How the organization develops and produces its offerings"),
              tags$li("Value Delivery: How the organization brings its offerings to customers"),
              tags$li("Value Capture: How the organization generates revenue and profit")
            ),
            h4("Purpose:"),
            p("The business model serves as a blueprint for strategy implementation and provides a framework for understanding, analyzing, and communicating business logic.")
          ),
          
          box(
            title = "The 9 Building Blocks", status = "info", solidHeader = TRUE, width = 6,
            h4("Customer-Focused Blocks:"),
            tags$ul(
              tags$li(strong("Customer Segments:"), " Different groups of people or organizations"),
              tags$li(strong("Value Propositions:"), " Bundle of products/services creating value"),
              tags$li(strong("Channels:"), " How company communicates and delivers value"),
              tags$li(strong("Customer Relationships:"), " Types of relationships with customers")
            ),
            h4("Infrastructure-Focused Blocks:"),
            tags$ul(
              tags$li(strong("Key Resources:"), " Most important assets required"),
              tags$li(strong("Key Activities:"), " Most important actions for success"),
              tags$li(strong("Key Partnerships:"), " Network of suppliers and partners")
            ),
            h4("Financial Blocks:"),
            tags$ul(
              tags$li(strong("Cost Structure:"), " All costs incurred in operations"),
              tags$li(strong("Revenue Streams:"), " Cash generated from customer segments")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "The Business Model Canvas", status = "success", solidHeader = TRUE, width = 12,
            h4("Canvas Benefits:"),
            fluidRow(
              column(4,
                h5("Visual Thinking"),
                p("Enables teams to jointly construct and discuss business model designs through visual tools and prototyping techniques.")
              ),
              column(4,
                h5("Strategic Focus"),
                p("Shifts focus from writing lengthy business plans to understanding business model design and customer development.")
              ),
              column(4,
                h5("Collaboration"),
                p("Creates a shared language for describing, visualizing, assessing, and changing business models.")
              )
            ),
            h4("How to Use:"),
            tags$ol(
              tags$li("Print the canvas on a large surface"),
              tags$li("Use sticky notes and markers"),
              tags$li("Involve your team in the design process"),
              tags$li("Iterate and refine continuously"),
              tags$li("Test assumptions with customers")
            )
          )
        )
      ),
      
      # Patterns Tab
      tabItem(
        tabName = "patterns",
        fluidRow(
          box(
            title = "Unbundling Business Models", status = "warning", solidHeader = TRUE, width = 6,
            h4("Three Core Business Types:"),
            tags$ul(
              tags$li(strong("Customer Relationship Businesses:"), " Focus on finding and acquiring customers"),
              tags$li(strong("Product Innovation Businesses:"), " Focus on developing new products/services"),
              tags$li(strong("Infrastructure Businesses:"), " Focus on building and managing platforms")
            ),
            h4("Benefits of Unbundling:"),
            p("Allows companies to focus on their core competencies while partnering with specialists for other functions."),
            h4("Examples:"),
            p("Private banking (relationship) + Asset management (innovation) + Transaction processing (infrastructure)")
          ),
          
          box(
            title = "The Long Tail", status = "info", solidHeader = TRUE, width = 6,
            h4("Concept:"),
            p("Selling less of more - offering a large number of niche products, each selling relatively small quantities."),
            h4("Key Requirements:"),
            tags$ul(
              tags$li("Low inventory costs"),
              tags$li("Strong recommendation systems"),
              tags$li("Easy access to niche content")
            ),
            h4("Success Factors:"),
            tags$ul(
              tags$li("Democratize production tools"),
              tags$li("Reduce distribution costs"),
              tags$li("Connect supply and demand")
            ),
            h4("Examples:"),
            p("Amazon, Netflix, Spotify - platforms that offer vast catalogs of products/content.")
          )
        ),
        
        fluidRow(
          box(
            title = "Multi-Sided Platforms", status = "primary", solidHeader = TRUE, width = 6,
            h4("Definition:"),
            p("Business models that bring together two or more distinct but interdependent groups of customers."),
            h4("Key Characteristics:"),
            tags$ul(
              tags$li("Network effects: Value increases with more users"),
              tags$li("Cross-side network effects: More users on one side attract users on the other"),
              tags$li("Subsidization: One side may be subsidized to attract the other")
            ),
            h4("Challenges:"),
            tags$ul(
              tags$li("Chicken and egg problem"),
              tags$li("Platform governance"),
              tags$li("Competition for platform dominance")
            ),
            h4("Examples:"),
            p("Credit cards, Operating systems, Video game consoles, App stores")
          ),
          
          box(
            title = "FREE as a Business Model", status = "success", solidHeader = TRUE, width = 6,
            h4("Four FREE Patterns:"),
            tags$ul(
              tags$li(strong("Freemium:"), " Free basic version, premium paid features"),
              tags$li(strong("Advertising:"), " Free service supported by advertising"),
              tags$li(strong("Cross-subsidization:"), " Free product drives sales of paid products"),
              tags$li(strong("Open Source:"), " Free software with paid services/support")
            ),
            h4("Success Requirements:"),
            tags$ul(
              tags$li("Very low marginal costs"),
              tags$li("Clear monetization strategy"),
              tags$li("Strong conversion funnel from free to paid")
            ),
            h4("Risk Management:"),
            p("Ensure the 'free' offering creates sufficient value to support conversion to paid services or attracts advertisers.")
          )
        ),
        
        fluidRow(
          box(
            title = "Open Business Models", status = "warning", solidHeader = TRUE, width = 12,
            h4("Types of Open Innovation:"),
            fluidRow(
              column(6,
                h5("Outside-In Innovation"),
                p("Integrate external ideas, technology, and intellectual property into internal innovation processes."),
                strong("Examples:"), p("P&G Connect + Develop, Lego Ideas")
              ),
              column(6,
                h5("Inside-Out Innovation"),
                p("Allow unused internal ideas and assets to go outside for others to use in their business models."),
                strong("Examples:"), p("IBM's patent licensing, Xerox PARC spin-offs")
              )
            ),
            h4("Benefits:"),
            tags$ul(
              tags$li("Reduced R&D costs and risks"),
              tags$li("Faster time to market"),
              tags$li("Access to external capabilities"),
              tags$li("New revenue streams from IP licensing")
            ),
            h4("Implementation:"),
            p("Requires new organizational capabilities, cultural changes, and appropriate IP management strategies.")
          )
        )
      ),
      
      # Design Process Tab
      tabItem(
        tabName = "design",
        fluidRow(
          box(
            title = "Customer Insights", status = "primary", solidHeader = TRUE, width = 6,
            h4("Understanding Your Customers:"),
            tags$ul(
              tags$li(strong("Customer Jobs:"), " What functional, emotional, and social jobs are customers trying to get done?"),
              tags$li(strong("Pain Points:"), " What frustrates customers before, during, and after getting the job done?"),
              tags$li(strong("Gain Creators:"), " What outcomes and benefits do customers want?")
            ),
            h4("Research Methods:"),
            tags$ul(
              tags$li("Customer interviews and observations"),
              tags$li("Journey mapping"),
              tags$li("Persona development"),
              tags$li("Jobs-to-be-done analysis")
            ),
            h4("Key Questions:"),
            tags$ul(
              tags$li("What are customers trying to accomplish?"),
              tags$li("What prevents them from getting the job done?"),
              tags$li("How do they currently solve this problem?")
            )
          ),
          
          box(
            title = "Ideation", status = "info", solidHeader = TRUE, width = 6,
            h4("Ideation Techniques:"),
            tags$ul(
              tags$li(strong("Brainstorming:"), " Generate many ideas without judgment"),
              tags$li(strong("What-if scenarios:"), " Explore alternative possibilities"),
              tags$li(strong("Constraint removal:"), " Imagine unlimited resources"),
              tags$li(strong("Analogies:"), " Learn from other industries")
            ),
            h4("Ideation Process:"),
            tags$ol(
              tags$li("Define the challenge clearly"),
              tags$li("Generate ideas individually first"),
              tags$li("Share and build on ideas as a group"),
              tags$li("Organize and prioritize concepts"),
              tags$li("Select promising ideas for development")
            ),
            h4("Best Practices:"),
            p("Encourage wild ideas, defer judgment, build on others' ideas, stay focused on topic, and be visual.")
          )
        ),
        
        fluidRow(
          box(
            title = "Visual Thinking", status = "success", solidHeader = TRUE, width = 6,
            h4("Benefits of Visual Tools:"),
            tags$ul(
              tags$li("Improve understanding and communication"),
              tags$li("Facilitate collaboration and engagement"),
              tags$li("Make complex concepts tangible"),
              tags$li("Enable rapid iteration and refinement")
            ),
            h4("Visual Techniques:"),
            tags$ul(
              tags$li("Sketching and diagramming"),
              tags$li("Mind mapping"),
              tags$li("Process flows"),
              tags$li("Journey maps"),
              tags$li("System maps")
            ),
            h4("Implementation:"),
            p("Use whiteboards, sticky notes, and simple drawing tools. Focus on clarity over artistic quality.")
          ),
          
          box(
            title = "Prototyping", status = "warning", solidHeader = TRUE, width = 6,
            h4("Types of Prototypes:"),
            tags$ul(
              tags$li(strong("Napkin sketches:"), " Quick concept visualization"),
              tags$li(strong("Business model canvas:"), " Structured hypothesis testing"),
              tags$li(strong("Storyboards:"), " Customer experience sequences"),
              tags$li(strong("Mock-ups:"), " Product/service representations"),
              tags$li(strong("Pilot programs:"), " Small-scale implementations")
            ),
            h4("Prototyping Process:"),
            tags$ol(
              tags$li("Start with low-fidelity prototypes"),
              tags$li("Test core assumptions quickly"),
              tags$li("Gather feedback from stakeholders"),
              tags$li("Iterate based on learning"),
              tags$li("Increase fidelity as confidence grows")
            ),
            h4("Key Principles:"),
            p("Fail fast, fail cheap, and learn quickly from each iteration.")
          )
        ),
        
        fluidRow(
          box(
            title = "Storytelling", status = "primary", solidHeader = TRUE, width = 12,
            h4("Power of Stories in Business Models:"),
            p("Stories help stakeholders understand, remember, and emotionally connect with business model concepts."),
            fluidRow(
              column(4,
                h5("Customer Stories"),
                p("Describe how customers experience value through specific scenarios and use cases."),
                strong("Elements:"), 
                tags$ul(
                  tags$li("Customer persona"),
                  tags$li("Situation/context"),
                  tags$li("Challenge/need"),
                  tags$li("Solution experience"),
                  tags$li("Outcome/value")
                )
              ),
              column(4,
                h5("Vision Stories"),
                p("Paint a picture of the future state and impact of the business model."),
                strong("Components:"),
                tags$ul(
                  tags$li("Market transformation"),
                  tags$li("Customer benefits"),
                  tags$li("Competitive advantage"),
                  tags$li("Growth potential"),
                  tags$li("Social impact")
                )
              ),
              column(4,
                h5("Implementation Stories"),
                p("Explain how the business model will be executed and scaled."),
                strong("Focus areas:"),
                tags$ul(
                  tags$li("Resource mobilization"),
                  tags$li("Partnership development"),
                  tags$li("Capability building"),
                  tags$li("Risk mitigation"),
                  tags$li("Success metrics")
                )
              )
            )
          )
        )
      ),
      
      # Strategy Tab
      tabItem(
        tabName = "strategy",
        fluidRow(
          box(
            title = "Scenarios", status = "primary", solidHeader = TRUE, width = 6,
            h4("Scenario Planning Process:"),
            tags$ol(
              tags$li(strong("Identify key uncertainties:"), " What major factors could impact your business model?"),
              tags$li(strong("Develop scenario frameworks:"), " Create 2-4 distinct future scenarios"),
              tags$li(strong("Assess business model fit:"), " How would your model perform in each scenario?"),
              tags$li(strong("Identify adaptations:"), " What changes would be needed for each scenario?"),
              tags$li(strong("Build flexibility:"), " Design adaptability into your business model")
            ),
            h4("Common Scenario Dimensions:"),
            tags$ul(
              tags$li("Economic conditions (growth vs. recession)"),
              tags$li("Technology adoption (fast vs. slow)"),
              tags$li("Regulatory environment (restrictive vs. permissive)"),
              tags$li("Customer behavior (traditional vs. innovative)")
            )
          ),
          
          box(
            title = "Business Model Environment", status = "info", solidHeader = TRUE, width = 6,
            h4("Environmental Forces:"),
            tags$ul(
              tags$li(strong("Market Forces:"), " Market segments, needs, market issues, costs"),
              tags$li(strong("Industry Forces:"), " Competitors, new entrants, substitute products, suppliers, stakeholders"),
              tags$li(strong("Key Trends:"), " Technology, regulatory, societal, socioeconomic trends"),
              tags$li(strong("Macroeconomic Forces:"), " Global market conditions, capital markets, commodities, economic infrastructure")
            ),
            h4("Analysis Framework:"),
            tags$ol(
              tags$li("Map current environment"),
              tags$li("Identify emerging changes"),
              tags$li("Assess impact on business model"),
              tags$li("Develop response strategies"),
              tags$li("Monitor and adapt continuously")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Evaluating Business Models", status = "success", solidHeader = TRUE, width = 6,
            h4("Evaluation Criteria:"),
            tags$ul(
              tags$li(strong("Feasibility:"), " Can the business model work technically and operationally?"),
              tags$li(strong("Viability:"), " Can it generate sustainable profits?"),
              tags$li(strong("Desirability:"), " Do customers want what's offered?"),
              tags$li(strong("Adaptability:"), " Can it evolve with changing conditions?")
            ),
            h4("Assessment Methods:"),
            tags$ul(
              tags$li("SWOT analysis"),
              tags$li("Financial modeling"),
              tags$li("Customer validation"),
              tags$li("Competitive analysis"),
              tags$li("Risk assessment")
            ),
            h4("Key Metrics:"),
            p("Customer acquisition cost, lifetime value, churn rate, unit economics, market size, and competitive positioning.")
          ),
          
          box(
            title = "Blue Ocean Strategy", status = "warning", solidHeader = TRUE, width = 6,
            h4("Blue Ocean Principles:"),
            tags$ul(
              tags$li(strong("Value Innovation:"), " Simultaneously pursue differentiation and low cost"),
              tags$li(strong("Four Actions Framework:"), " Eliminate, Reduce, Raise, Create"),
              tags$li(strong("Strategic Canvas:"), " Visualize current and future value curves"),
              tags$li(strong("Six Paths Framework:"), " Systematic approach to finding blue oceans")
            ),
            h4("Implementation Steps:"),
            tags$ol(
              tags$li("Map the current competitive landscape"),
              tags$li("Identify factors to eliminate, reduce, raise, and create"),
              tags$li("Develop new value proposition"),
              tags$li("Test with target customers"),
              tags$li("Align business model with blue ocean strategy")
            ),
            h4("Success Factors:"),
            p("Focus on non-customers, look across strategic groups, and redefine industry boundaries.")
          )
        ),
        
        fluidRow(
          box(
            title = "Managing Multiple Business Models", status = "primary", solidHeader = TRUE, width = 12,
            h4("Why Multiple Business Models?"),
            fluidRow(
              column(6,
                h5("Reasons for Multiple Models:"),
                tags$ul(
                  tags$li("Serve different customer segments"),
                  tags$li("Exploit different value propositions"),
                  tags$li("Diversify revenue streams"),
                  tags$li("Hedge against market risks"),
                  tags$li("Experiment with new opportunities")
                )
              ),
              column(6,
                h5("Management Challenges:"),
                tags$ul(
                  tags$li("Resource allocation conflicts"),
                  tags$li("Cultural tensions between models"),
                  tags$li("Complexity in operations"),
                  tags$li("Brand confusion"),
                  tags$li("Cannibalization risks")
                )
              )
            ),
            h4("Management Strategies:"),
            tags$ul(
              tags$li(strong("Separation:"), " Keep business models organizationally separate"),
              tags$li(strong("Integration:"), " Find synergies between models"),
              tags$li(strong("Transformation:"), " Gradually transition from old to new models"),
              tags$li(strong("Portfolio approach:"), " Manage as a portfolio of business models")
            ),
            h4("Success Factors:"),
            p("Clear governance structures, appropriate performance metrics, cultural alignment, and strong leadership coordination.")
          )
        )
      ),
      
      # Process Tab
      tabItem(
        tabName = "process",
        fluidRow(
          box(
            title = "Business Model Design Process", status = "primary", solidHeader = TRUE, width = 12,
            h4("Five-Phase Design Process:"),
            fluidRow(
              column(4,
                div(style = "background-color: #e8f4fd; padding: 15px; border-radius: 10px; margin: 5px;",
  h5(style = "color: #1e88e5;", "1. Mobilize"),
p("Prepare for successful business model design effort"),
tags$ul(
  tags$li("Set up design team"),
  tags$li("Define project scope"),
  tags$li("Gather initial insights"),
  tags$li("Establish success criteria")
)
)
),
column(4,
       div(style = "background-color: #fff3e0; padding: 15px; border-radius: 10px; margin: 5px;",
           h5(style = "color: #f57c00;", "2. Understand"),
           p("Research and analyze the design context"),
           tags$ul(
             tags$li("Study customers and context"),
             tags$li("Analyze existing business models"),
             tags$li("Identify opportunities and constraints"),
             tags$li("Map stakeholder ecosystem")
           )
       )
),
column(4,
       div(style = "background-color: #f3e5f5; padding: 15px; border-radius: 10px; margin: 5px;",
           h5(style = "color: #8e24aa;", "3. Design"),
           p("Generate and develop business model options"),
           tags$ul(
             tags$li("Ideate business model concepts"),
             tags$li("Prototype promising options"),
             tags$li("Test key assumptions"),
             tags$li("Refine based on feedback")
           )
       )
)
),
br(),
fluidRow(
  column(6,
         div(style = "background-color: #e8f5e8; padding: 15px; border-radius: 10px; margin: 5px;",
             h5(style = "color: #2e7d32;", "4. Implement"),
             p("Execute the designed business model"),
             tags$ul(
               tags$li("Plan implementation roadmap"),
               tags$li("Pilot and test in market"),
               tags$li("Scale successful elements"),
               tags$li("Build required capabilities")
             )
         )
  ),
  column(6,
         div(style = "background-color: #ffebee; padding: 15px; border-radius: 10px; margin: 5px;",
             h5(style = "color: #c62828;", "5. Manage"),
             p("Adapt and evolve the business model over time"),
             tags$ul(
               tags$li("Monitor performance metrics"),
               tags$li("Identify improvement opportunities"),
               tags$li("Adapt to changing conditions"),
               tags$li("Innovate continuously")
             )
         )
  )
)
)
),

fluidRow(
  box(
    title = "Implementation Success Factors", status = "info", solidHeader = TRUE, width = 6,
    h4("Critical Success Elements:"),
    tags$ul(
      tags$li(strong("Leadership Commitment:"), " Strong sponsorship and visible support"),
      tags$li(strong("Cross-functional Teams:"), " Diverse skills and perspectives"),
      tags$li(strong("Customer Focus:"), " Continuous customer feedback and validation"),
      tags$li(strong("Iterative Approach:"), " Learn and adapt through experimentation"),
      tags$li(strong("Change Management:"), " Address organizational and cultural barriers")
    ),
    h4("Common Pitfalls:"),
    tags$ul(
      tags$li("Falling in love with first idea"),
      tags$li("Insufficient customer research"),
      tags$li("Over-planning without testing"),
      tags$li("Ignoring implementation challenges"),
      tags$li("Lack of measurement and learning")
    )
  ),
  
  box(
    title = "Organizational Capabilities", status = "success", solidHeader = TRUE, width = 6,
    h4("Required Capabilities:"),
    tags$ul(
      tags$li(strong("Design Thinking:"), " Human-centered approach to innovation"),
      tags$li(strong("Systems Thinking:"), " Understanding interconnections and dependencies"),
      tags$li(strong("Experimentation:"), " Rapid testing and learning capabilities"),
      tags$li(strong("Partnership Management:"), " Building and managing ecosystem relationships"),
      tags$li(strong("Digital Fluency:"), " Leveraging technology for business model innovation")
    ),
    h4("Building Capabilities:"),
    tags$ol(
      tags$li("Assess current capability gaps"),
      tags$li("Develop training programs"),
      tags$li("Create communities of practice"),
      tags$li("Hire external expertise"),
      tags$li("Partner with specialists")
    ),
    h4("Culture Requirements:"),
    p("Innovation mindset, tolerance for failure, customer obsession, collaboration, and continuous learning.")
  )
),

fluidRow(
  box(
    title = "Metrics and KPIs", status = "warning", solidHeader = TRUE, width = 12,
    h4("Business Model Metrics Framework:"),
    fluidRow(
      column(3,
             h5("Customer Metrics"),
             tags$ul(
               tags$li("Customer acquisition cost (CAC)"),
               tags$li("Customer lifetime value (CLV)"),
               tags$li("Net Promoter Score (NPS)"),
               tags$li("Churn rate"),
               tags$li("Customer satisfaction")
             )
      ),
      column(3,
             h5("Financial Metrics"),
             tags$ul(
               tags$li("Revenue growth"),
               tags$li("Gross margin"),
               tags$li("Unit economics"),
               tags$li("Return on investment (ROI)"),
               tags$li("Cash flow"),
               tags$li("Break-even time")
             )
      ),
      column(3,
             h5("Operational Metrics"),
             tags$ul(
               tags$li("Process efficiency"),
               tags$li("Quality measures"),
               tags$li("Delivery time"),
               tags$li("Resource utilization"),
               tags$li("Partner performance")
             )
      ),
      column(3,
             h5("Innovation Metrics"),
             tags$ul(
               tags$li("Experiment velocity"),
               tags$li("Learning rate"),
               tags$li("Adaptation speed"),
               tags$li("New opportunity identification"),
               tags$li("Innovation pipeline health")
             )
      )
    ),
    h4("Measurement Best Practices:"),
    p("Focus on leading indicators, use balanced scorecards, implement regular review cycles, and ensure metrics align with strategic objectives.")
  )
)
),

# Business Model Canvas Template Tab
tabItem(
  tabName = "bmc_template",
  fluidRow(
    column(12,
           h2("Interactive Business Model Canvas", style = "text-align: center; margin-bottom: 30px;"),
           div(class = "canvas-grid",
               # Key Partners
               div(class = "canvas-section key-partners partners",
                   div(class = "section-title",
                       span(class = "section-icon", "🤝"),
                       "Key Partners"
                   ),
                   div(class = "section-content",
                       p(strong("Who are our Key Partners?")),
                       p(strong("Who are our key suppliers?")),  
                       p(strong("Which Key Resources are we acquiring from partners?")),
                       p(strong("Which Key Activities do partners perform?")),
                       hr(),
                       p(strong("Motivations for partnerships:")),
                       tags$ul(
                         tags$li("Optimization and economy of scale"),
                         tags$li("Reduction of risk and uncertainty"),
                         tags$li("Acquisition of particular resources and activities")
                       )
                   )
               ),
               
               # Key Activities
               div(class = "canvas-section key-activities activities",
                   div(class = "section-title",
                       span(class = "section-icon", "⚡"),
                       "Key Activities"
                   ),
                   div(class = "section-content",
                       p(strong("What Key Activities does our Value Proposition require?")),
                       p(strong("Our Distribution Channels?")),
                       p(strong("Customer Relationships?")),
                       p(strong("Revenue Streams?")),
                       hr(),
                       p(strong("Categories:")),
                       tags$ul(
                         tags$li("Production"),
                         tags$li("Problem Solving"),
                         tags$li("Platform/Network")
                       )
                   )
               ),
               
               # Key Resources
               div(class = "canvas-section key-resources resources",
                   div(class = "section-title",
                       span(class = "section-icon", "🏗️"),
                       "Key Resources"
                   ),
                   div(class = "section-content",
                       p(strong("What Key Resources does our Value Proposition require?")),
                       p(strong("Our Distribution Channels?")),
                       p(strong("Customer Relationships?")),
                       p(strong("Revenue Streams?")),
                       hr(),
                       p(strong("Types of resources:")),
                       tags$ul(
                         tags$li("Physical"),
                         tags$li("Intellectual (brand patents, copyrights, data)"),
                         tags$li("Human"),
                         tags$li("Financial")
                       )
                   )
               ),
               
               # Value Propositions
               div(class = "canvas-section value-propositions value-prop",
                   div(class = "section-title",
                       span(class = "section-icon", "🎁"),
                       "Value Propositions"
                   ),
                   div(class = "section-content",
                       p(strong("What value do we deliver to the customer?")),
                       p(strong("Which one of our customer's problems are we helping to solve?")),
                       p(strong("What bundles of products and services are we offering to each Customer Segment?")),
                       p(strong("Which customer needs are we satisfying?")),
                       hr(),
                       p(strong("Characteristics:")),
                       tags$ul(
                         tags$li("Newness"),
                         tags$li("Performance"),
                         tags$li("Customization"),
                         tags$li("'Getting the Job Done'"),
                         tags$li("Design"),
                         tags$li("Brand/Status"),
                         tags$li("Price"),
                         tags$li("Cost Reduction"),
                         tags$li("Risk Reduction"),
                         tags$li("Accessibility"),
                         tags$li("Convenience/Usability")
                       )
                   )
               ),
               
               # Customer Relationships
               div(class = "canvas-section customer-relationships relationships",
                   div(class = "section-title",
                       span(class = "section-icon", "💝"),
                       "Customer Relationships"
                   ),
                   div(class = "section-content",
                       p(strong("What type of relationship does each of our Customer Segments expect us to establish and maintain with them?")),
                       p(strong("Which ones have we established?")),
                       p(strong("How are they integrated with the rest of our business model?")),
                       p(strong("How costly are they?")),
                       hr(),
                       p(strong("Categories:")),
                       tags$ul(
                         tags$li("Personal assistance"),
                         tags$li("Dedicated personal assistance"),
                         tags$li("Self-service"),
                         tags$li("Automated services"),
                         tags$li("Communities"),
                         tags$li("Co-creation")
                       )
                   )
               ),
               
               # Channels
               div(class = "canvas-section channels channels-grid",
                   div(class = "section-title",
                       span(class = "section-icon", "📢"),
                       "Channels"
                   ),
                   div(class = "section-content",
                       p(strong("Through which Channels do our Customer Segments want to be reached?")),
                       p(strong("How are we reaching them now?")),
                       p(strong("How are our Channels integrated?")),
                       p(strong("Which ones work best?")),
                       p(strong("Which ones are most cost-efficient?")),
                       p(strong("How are we integrating them with customer routines?")),
                       hr(),
                       p(strong("Channel phases:")),
                       tags$ul(
                         tags$li("1. Awareness: How do we raise awareness about our company's products and services?"),
                         tags$li("2. Evaluation: How do we help customers evaluate our organization's Value Proposition?"),
                         tags$li("3. Purchase: How do we allow customers to purchase specific products and services?"),
                         tags$li("4. Delivery: How do we deliver a Value Proposition to customers?"),
                         tags$li("5. After sales: How do we provide post-purchase customer support?")
                       )
                   )
               ),
               
               # Customer Segments
               div(class = "canvas-section customer-segments segments",
                   div(class = "section-title",
                       span(class = "section-icon", "👥"),
                       "Customer Segments"
                   ),
                   div(class = "section-content",
                       p(strong("For whom are we creating value?")),
                       p(strong("Who are our most important customers?")),
                       hr(),
                       p(strong("Groups of people or organizations:")),
                       tags$ul(
                         tags$li("Mass market"),
                         tags$li("Niche market"),
                         tags$li("Segmented"),
                         tags$li("Diversified"),
                         tags$li("Multi-sided platforms")
                       ),
                       hr(),
                       p(strong("Customer characteristics:")),
                       tags$ul(
                         tags$li("Common needs"),
                         tags$li("Common behaviors"),
                         tags$li("Common attributes"),
                         tags$li("Profitability"),
                         tags$li("Distribution channels"),
                         tags$li("Relationship types")
                       )
                   )
               ),
               
               # Cost Structure
               div(class = "canvas-section cost-structure costs",
                   div(class = "section-title",
                       span(class = "section-icon", "💰"),
                       "Cost Structure"
                   ),
                   div(class = "section-content",
                       p(strong("What are the most important costs inherent in our business model?")),
                       p(strong("Which Key Resources are most expensive?")),
                       p(strong("Which Key Activities are most expensive?")),
                       hr(),
                       p(strong("Is your business more:")),
                       tags$ul(
                         tags$li("Cost Driven (leanest cost structure, low price value proposition, maximum automation, extensive outsourcing)"),
                         tags$li("Value Driven (focused on value creation, premium value propositions)")
                       ),
                       hr(),
                       p(strong("Sample characteristics:")),
                       tags$ul(
                         tags$li("Fixed Costs (salaries, rents, utilities)"),
                         tags$li("Variable costs"),
                         tags$li("Economies of scale"),
                         tags$li("Economies of scope")
                       )
                   )
               ),
               
               # Revenue Streams
               div(class = "canvas-section revenue-streams revenue",
                   div(class = "section-title",
                       span(class = "section-icon", "💵"),
                       "Revenue Streams"
                   ),
                   div(class = "section-content",
                       p(strong("What value are our customers really willing to pay for?")),
                       p(strong("For what do they currently pay?")),
                       p(strong("How are they currently paying?")),
                       p(strong("How would they prefer to pay?")),
                       p(strong("How much does each Revenue Stream contribute to overall revenues?")),
                       hr(),
                       p(strong("Types:")),
                       tags$ul(
                         tags$li("Asset sale"),
                         tags$li("Usage fee"),
                         tags$li("Subscription fees"),
                         tags$li("Lending/Renting/Leasing"),
                         tags$li("Licensing"),
                         tags$li("Brokerage fees"),
                         tags$li("Advertising")
                       ),
                       hr(),
                       p(strong("Fixed Menu Pricing:")),
                       tags$ul(
                         tags$li("List price"),
                         tags$li("Product feature dependent"),
                         tags$li("Customer segment dependent"),
                         tags$li("Volume dependent")
                       ),
                       hr(),
                       p(strong("Dynamic Pricing:")),
                       tags$ul(
                         tags$li("Negotiation (bargaining)"),
                         tags$li("Yield management"),
                         tags$li("Real-time-market")
                       )
                   )
               )
           )
    )
  )
)
)
)
)

# Define server logic
server <- function(input, output, session) {
  
  # Server logic can be added here for any interactive features
  # For now, the dashboard is primarily content-based
  
  # You could add functionality like:
  # - Editable canvas sections
  # - Export functionality
  # - Template saving/loading
  # - Business model analysis tools
  # - Comparison features
  
}

# Run the application
shinyApp(ui = ui, server = server)