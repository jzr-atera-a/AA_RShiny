library(shiny)
library(shinydashboard)
library(htmltools)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Business Model Canvas"),
  
  dashboardSidebar(
    sidebarMenu(
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
        .costs { grid-column: 1 / 3.5; grid-row: 3; }
        .revenue { grid-column: 3.5 / 6; grid-row: 3; }
      "))
    ),
    
    tabItems(
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
  # Server logic can be added here for interactive features
}

# Run the application
shinyApp(ui = ui, server = server)
