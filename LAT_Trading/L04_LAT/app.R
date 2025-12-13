# Trading Psychology & Technical Indicators Dashboard
# Professional Teal Gradient Theme

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(lubridate)
library(shinycssloaders)
library(TTR)
library(tidyr)
library(zoo)

# Generate sample price data
generate_price_data <- function(days = 180, start_price = 100) {
  dates <- seq(Sys.Date() - days, Sys.Date(), by = "day")
  
  # Generate price with trend and noise
  trend <- seq(0, 20, length.out = length(dates))
  noise <- cumsum(rnorm(length(dates), 0, 1.5))
  price <- start_price + trend + noise
  
  # Add some volatility clusters
  volatility <- abs(rnorm(length(dates), 1, 0.3))
  price <- price + cumsum(rnorm(length(dates), 0, volatility))
  
  data.frame(
    Date = dates,
    Close = price,
    High = price + abs(rnorm(length(dates), 2, 1)),
    Low = price - abs(rnorm(length(dates), 2, 1)),
    Volume = abs(rnorm(length(dates), 1000000, 200000))
  )
}

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "W4-T.Psychology & Technical Analysis"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Trade Plan (S-T-E-M)", tabName = "stem", icon = icon("list-check")),
      menuItem("Trading Psychology", tabName = "psychology", icon = icon("brain")),
      menuItem("Behavioral Biases", tabName = "biases", icon = icon("user-tie")),
      menuItem("Loss Aversion", tabName = "loss_aversion", icon = icon("chart-line")),
      menuItem("Risk Management", tabName = "risk", icon = icon("shield-halved")),
      menuItem("Momentum Indicators", tabName = "momentum", icon = icon("gauge-high")),
      menuItem("RSI Analysis", tabName = "rsi", icon = icon("wave-square")),
      menuItem("Stochastic Oscillator", tabName = "stochastic", icon = icon("chart-area")),
      menuItem("Divergence Analysis", tabName = "divergence", icon = icon("code-compare")),
      menuItem("Trading Signals", tabName = "signals", icon = icon("bell"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Main body background with teal gradient */
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          min-height: 100vh;
        }
        
        /* Sidebar styling with teal gradient */
        .sidebar, .main-sidebar {
          background: linear-gradient(180deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
        }
        
        .sidebar .sidebar-menu > li > a {
          color: #ffffff !important;
          border-left: 3px solid transparent;
          transition: all 0.3s ease;
        }
        
        .sidebar .sidebar-menu > li.active > a,
        .sidebar .sidebar-menu > li:hover > a {
          background: rgba(255, 255, 255, 0.15) !important;
          border-left: 3px solid #00A39A !important;
          color: #ffffff !important;
        }
        
        /* Header with matching gradient */
        .main-header, .main-header .navbar {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          border-bottom: none;
        }
        
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
        }
        
        /* Box styling */
        .box {
          background: rgba(255, 255, 255, 0.98) !important;
          border: none !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2) !important;
          margin-bottom: 20px;
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        
        .box:hover {
          transform: translateY(-2px);
          box-shadow: 0 12px 35px rgba(0, 44, 60, 0.3) !important;
        }
        
        .box-header {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
          border-radius: 12px 12px 0 0 !important;
          padding: 15px 20px;
        }
        
        .box-header > .box-title {
          color: #ffffff !important;
          font-weight: 600;
          font-size: 18px;
        }
        
        .box-body {
          background-color: #ffffff !important;
          color: #2c3e50 !important;
          padding: 20px;
        }
        
        /* Info boxes */
        .info-box {
          background: rgba(255, 255, 255, 0.98) !important;
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 44, 60, 0.15) !important;
          border-left: 4px solid #008A82;
          min-height: 90px;
        }
        
        .info-box-icon {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
        }
        
        /* Value boxes */
        .small-box {
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15) !important;
        }
        
        .small-box.bg-blue { 
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important; 
        }
        
        .small-box.bg-green { 
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important; 
        }
        
        .small-box.bg-yellow { 
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; 
        }
        
        .small-box.bg-red { 
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; 
        }
        
        /* Concept cards */
        .concept-card {
          background: white;
          border-radius: 12px;
          padding: 20px;
          margin: 15px 0;
          box-shadow: 0 4px 15px rgba(0, 44, 60, 0.15);
          border-left: 4px solid #008A82;
        }
        
        .concept-card h3 {
          color: #002C3C;
          margin-top: 0;
          font-weight: 600;
        }
        
        .concept-card ul {
          color: #2c3e50;
          line-height: 1.8;
        }
        
        /* Buttons */
        .btn-primary {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          border-radius: 8px !important;
        }
        
        .btn-primary:hover {
          background: linear-gradient(135deg, #006b63 0%, #007d75 100%) !important;
        }

        /* Alert boxes */
        .alert-success {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          border-left: 4px solid #00A39A !important;
          border-radius: 8px;
          color: #155724 !important;
        }
        
        .alert-success * {
          color: #155724 !important;
        }
        
        .alert-warning {
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
          border-left: 4px solid #f39c12 !important;
          border-radius: 8px;
          color: #856404 !important;
        }
        
        .alert-warning * {
          color: #856404 !important;
        }
        
        .alert-danger {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          border-left: 4px solid #e74c3c !important;
          border-radius: 8px;
          color: #721c24 !important;
        }
        
        .alert-danger * {
          color: #721c24 !important;
        }
        
        /* Tables */
        .dataTables_wrapper {
          background: transparent !important;
        }
        
        table.dataTable thead th {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
        }
      "))
    ),
    
    tabItems(
      # Tab 1: Trade Plan (S-T-E-M)
      tabItem(tabName = "stem",
              fluidRow(
                box(
                  title = "Structured Trade Plan: S-T-E-M Framework",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("What is S-T-E-M?"),
                      p("A structured trading plan helps maintain discipline and control by creating a set of fixed rules for each step of your trading process:"),
                      tags$ul(
                        tags$li(tags$b("SET-UP:"), "Define the market conditions needed before considering a trade"),
                        tags$li(tags$b("TRIGGER:"), "Specify the exact price action that puts your finger on the trigger"),
                        tags$li(tags$b("EXECUTION:"), "Determine when to pull the trigger (time/price filters)"),
                        tags$li(tags$b("MANAGEMENT:"), "Plan how to manage the trade (stops, targets, position sizing)")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "SET-UP",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Define Your Set-Up Rules"),
                      p("Example set-up criteria:"),
                      tags$ul(
                        tags$li("Established uptrend (higher highs and higher lows)"),
                        tags$li("Price hits short-term resistance"),
                        tags$li("Upward pressure is increasing (volume, momentum)"),
                        tags$li("Look to buy if price breaks out above resistance")
                      ),
                      div(class = "alert alert-success",
                          icon("lightbulb"),
                          " Make rules specific and objective to eliminate emotion!"
                      )
                  )
                ),
                
                box(
                  title = "TRIGGER",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("What Puts Your Finger on the Trigger?"),
                      p("Common trigger events:"),
                      tags$ul(
                        tags$li("Support/resistance breakout"),
                        tags$li("Trend line breakout"),
                        tags$li("Price pattern completion"),
                        tags$li("Technical indicator signal")
                      ),
                      div(class = "alert alert-warning",
                          icon("exclamation-triangle"),
                          " Don't pull the trigger until your criteria are met!"
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "EXECUTION",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("When to Pull the Trigger"),
                      p(tags$b("Time Filters:")),
                      tags$ul(
                        tags$li("Wait for price to close above resistance"),
                        tags$li("Choose your timeframe (15-min, hourly, daily)")
                      ),
                      p(tags$b("Price Filters (Buffer):")),
                      tags$ul(
                        tags$li("Wait for price to move 'far enough'"),
                        tags$li("Fixed amount: 5 pips, 10 pips"),
                        tags$li("Percentage of range: 5-10% of Daily True Range"),
                        tags$li("Different buffers for different markets")
                      )
                  )
                ),
                
                box(
                  title = "MANAGEMENT",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Trade Management Rules"),
                      p(tags$b("Stop Loss:")),
                      tags$ul(
                        tags$li("Set BEFORE entering the trade"),
                        tags$li("At what price do you NOT want to be in this trade?"),
                        tags$li("Calculate pip risk from the charts"),
                        tags$li("Fixed monetary risk per trade (e.g., £100)")
                      ),
                      p(tags$b("Position Sizing:")),
                      tags$div(
                        style = "background: #f8f9fa; padding: 10px; border-radius: 5px; margin: 10px 0;",
                        "Lot Size = Actual Risk ÷ Pip Risk"
                      ),
                      p(tags$b("Targets:")),
                      tags$ul(
                        tags$li(tags$b("S"),"pecific - From the charts"),
                        tags$li(tags$b("M"),"easurable - From the charts"),
                        tags$li(tags$b("A"),"chievable - Not beyond recent high/low"),
                        tags$li(tags$b("R"),"ealistic - Likely to be reached"),
                        tags$li(tags$b("T"),"ime-bound - Expected trade duration")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Position Sizing Calculator",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(4,
                           numericInput("entry_price", "Entry Price:", value = 1.1520, step = 0.0001),
                           numericInput("stop_price", "Stop Loss Price:", value = 1.1480, step = 0.0001)
                    ),
                    column(4,
                           numericInput("risk_amount", "Risk Amount (£):", value = 100, step = 10),
                           numericInput("pip_value", "Pip Value (£):", value = 1, step = 0.1)
                    ),
                    column(4,
                           h4("Calculated Position Size:"),
                           verbatimTextOutput("position_size"),
                           h4("Pip Risk:"),
                           verbatimTextOutput("pip_risk")
                    )
                  )
                )
              )
      ),
      
      # Tab 2: Trading Psychology
      tabItem(tabName = "psychology",
              fluidRow(
                box(
                  title = "Trading Psychology & Behavioral Finance",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("The Efficient Market Hypothesis (EMH) is Wrong"),
                      p("Traditional finance assumes:"),
                      tags$ul(
                        tags$li("People act rationally and consider all available information - ", tags$b("WRONG!")),
                        tags$li("People are unbiased in their predictions - ", tags$b("WRONG!"))
                      ),
                      div(class = "alert alert-danger",
                          icon("quote-left"),
                          " 'Evidence reveals repeated patterns of irrationality, inconsistency and incompetence in the ways human beings arrive at decisions and choices when faced with uncertainty.' - Peter L. Bernstein"
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "How Markets Really Move",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Individual Emotions"),
                      tags$ul(
                        tags$li(tags$b("Hope:"), "Expecting positive outcomes despite evidence"),
                        tags$li(tags$b("Fear:"), "Anxiety about potential losses"),
                        tags$li(tags$b("Greed:"), "Excessive desire for profits"),
                        tags$li(tags$b("Panic:"), "Irrational response to market movements")
                      ),
                      p(style = "margin-top: 20px; font-style: italic; color: #008A82;",
                        "Financial markets are not directly moved by news, but by the reactions of traders to news")
                  )
                ),
                
                box(
                  title = "Herd Mentality",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Collective Behavior"),
                      tags$ul(
                        tags$li(tags$b("Peer Pressure:"), "Following what others are doing"),
                        tags$li(tags$b("Fear of Missing Out (FOMO):"), "Jumping into trades because others are"),
                        tags$li(tags$b("Fear of Looking Stupid:"), "Not wanting to be contrarian"),
                        tags$li(tags$b("Confirmation Bias:"), "Seeking information that confirms existing beliefs")
                      ),
                      div(class = "alert alert-warning",
                          icon("users"),
                          " The crowd is often wrong at market turning points!"
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Hope vs Fear Simulation",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  p("Imagine you bought a stock at 100 and it's now trading at 98.20. What is your stronger emotion?"),
                  
                  withSpinner(plotlyOutput("hope_fear_chart", height = "400px"), color = "#008A82"),
                  
                  div(class = "alert alert-success", style = "margin-top: 20px;",
                      icon("check-circle"),
                      tags$b(" Answer: HOPE."), 
                      " At this stage, you consider your unrealized loss as 'just a profit waiting to happen.' You're prepared to take risk to avoid realizing the pain of the loss."
                  )
                )
              )
      ),
      
      # Tab 3: Behavioral Biases
      tabItem(tabName = "biases",
              fluidRow(
                box(
                  title = "Three Key Psychological Biases Affecting Trading",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(4,
                           div(class = "concept-card",
                               h3("1. Mental Accounting"),
                               tags$ul(
                                 tags$li(tags$b("House Money Effect:"), "After wins, becoming overconfident and taking excessive risks"),
                                 tags$li(tags$b("Snake Bite Effect:"), "After losses, becoming too conservative and missing opportunities")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-card",
                               h3("2. Prospect Theory"),
                               tags$ul(
                                 tags$li(tags$b("Loss Aversion:"), "The pain of loss is 2.5x stronger than joy of equivalent gain"),
                                 tags$li("Reluctance to realize losses"),
                                 tags$li("Taking profits too early")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-card",
                               h3("3. Overconfidence"),
                               tags$ul(
                                 tags$li(tags$b("Illusion of Knowledge:"), "Thinking you know more than you do"),
                                 tags$li(tags$b("Illusion of Control:"), "Believing you have more control than you actually do")
                               )
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "House Money Effect",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Symptoms"),
                      p(tags$b("CAUSE:"), "A big win or series of wins"),
                      p(tags$b("EFFECT:"), "Overconfidence leading to:"),
                      tags$ul(
                        tags$li("Bigger trades / more risk"),
                        tags$li("Less analysis before trading"),
                        tags$li("Gambling mindset ('I can afford it')"),
                        tags$li("Abandoning your trade plan")
                      ),
                      div(class = "alert alert-success",
                          icon("lightbulb"),
                          tags$b(" SOLUTION:"), " Integrate profits immediately into your overall fund and stick to your Trade Plan!"
                      )
                  )
                ),
                
                box(
                  title = "Snake Bite Effect",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Symptoms"),
                      p(tags$b("CAUSE:"), "A big loss or series of losses"),
                      p(tags$b("EFFECT:"), "Fear of losing again:"),
                      tags$ul(
                        tags$li("Refusing to take trades despite good set-ups"),
                        tags$li("Reducing position size excessively"),
                        tags$li("Trading shorter term with tighter stops"),
                        tags$li("Second-guessing your analysis")
                      ),
                      div(class = "alert alert-success",
                          icon("lightbulb"),
                          tags$b(" SOLUTION:"), " Don't abandon your Trade Plan. Aim to bounce back psychologically after losses."
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Overconfidence: Illusion of Control",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("Three Situations That Create Illusion of Control"),
                      
                      fluidRow(
                        column(4,
                               h4("1. Outcome of Sequence"),
                               p("Early positive outcomes make you feel in control"),
                               tags$ul(
                                 tags$li("First 5 trades are winners"),
                                 tags$li("You feel like you're in control"),
                                 tags$li("But is it skill or luck?")
                               ),
                               div(class = "alert alert-warning",
                                   "This often leads to bigger trades and less analysis"
                               )
                        ),
                        column(4,
                               h4("2. Task Familiarity"),
                               p("Comfort with the process ≠ Better decisions"),
                               tags$ul(
                                 tags$li("Easy online trading platforms"),
                                 tags$li("Quick execution feels professional"),
                                 tags$li("But doesn't improve decision-making")
                               ),
                               div(class = "alert alert-warning",
                                   "Familiarity breeds false confidence"
                               )
                        ),
                        column(4,
                               h4("3. Information"),
                               p("More information ≠ Better understanding"),
                               tags$ul(
                                 tags$li("Vast amounts of data available"),
                                 tags$li("May lack skills to interpret correctly"),
                                 tags$li("News may be outdated or inaccurate")
                               ),
                               div(class = "alert alert-warning",
                                   "Information overload creates illusion of knowledge"
                               )
                        )
                      )
                  )
                )
              )
      ),
      
      # Tab 4: Loss Aversion
      tabItem(tabName = "loss_aversion",
              fluidRow(
                box(
                  title = "Loss Aversion: The Most Powerful Trading Bias",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("The Pain of Loss vs Joy of Gain"),
                      p(tags$b("Key Insight:"), "The pain of loss is 2.5 times stronger than the joy of an equivalent gain"),
                      p("This asymmetry leads to:"),
                      tags$ul(
                        tags$li("Holding losing positions too long (hoping they'll recover)"),
                        tags$li("Taking profits too early (fear of losing unrealized gains)"),
                        tags$li("Risk-seeking behavior to avoid losses"),
                        tags$li("Risk-averse behavior when sitting on profits")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Loss Aversion Value Function",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  withSpinner(plotlyOutput("loss_aversion_chart", height = "500px"), color = "#008A82"),
                  
                  div(class = "alert alert-danger", style = "margin-top: 20px;",
                      icon("exclamation-triangle"),
                      " Notice how the curve is steeper for losses than gains - this is why we feel losses more intensely!"
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Common Mistakes from Loss Aversion",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Holding Losers Too Long"),
                      p("Trader thinks:"),
                      tags$ul(
                        tags$li("'It's gone down so far, I can't sell now'"),
                        tags$li("'I'll get out flat when it rebounds to 100'"),
                        tags$li("'It's just a temporary dip'")
                      ),
                      p(tags$b("Reality:"), "The potential pain of realizing the loss causes you to run bad trades too long"),
                      div(class = "alert alert-danger",
                          "This often results in even larger losses!"
                      )
                  )
                ),
                
                box(
                  title = "Taking Profits Too Early",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Fear of Losing Gains"),
                      p("Trader thinks:"),
                      tags$ul(
                        tags$li("'Better take profits while I can'"),
                        tags$li("'You can't go broke taking a profit'"),
                        tags$li("'What if it reverses?'")
                      ),
                      p(tags$b("Reality:"), "Fear of losing unrealized gains causes premature exits"),
                      div(class = "alert alert-warning",
                          "Missing out on larger moves that your analysis predicted!"
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Solutions to Loss Aversion",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("Practical Strategies"),
                      
                      fluidRow(
                        column(6,
                               h4("1. Forget Your Entry Price"),
                               tags$ul(
                                 tags$li("Evaluate positions based on CURRENT potential"),
                                 tags$li("Ask: 'Would I buy this TODAY at this price?'"),
                                 tags$li("If not, you should probably exit"),
                                 tags$li("Don't let sunk costs influence decisions")
                               )
                        ),
                        column(6,
                               h4("2. Set Rules Before Trading"),
                               tags$ul(
                                 tags$li("Work out stop loss BEFORE entering"),
                                 tags$li("Identify honest, realistic targets"),
                                 tags$li("Calculate position size based on risk"),
                                 tags$li("Write it down - make it concrete")
                               )
                        )
                      ),
                      
                      fluidRow(
                        column(6,
                               h4("3. Learn to Love Taking Losses"),
                               tags$ul(
                                 tags$li("Small losses protect your capital"),
                                 tags$li("Cutting losses quickly keeps you in the game"),
                                 tags$li("Focus on the next opportunity"),
                                 tags$li("Good traders take many small losses")
                               )
                        ),
                        column(6,
                               h4("4. Pay Less Attention"),
                               tags$ul(
                                 tags$li("Don't check positions constantly"),
                                 tags$li("Trust your analysis and plan"),
                                 tags$li("Reduces emotional reactions to noise"),
                                 tags$li("Allows trends to develop")
                               )
                        )
                      )
                  )
                )
              )
      ),
      
      # Tab 5: Risk Management
      tabItem(tabName = "risk",
              fluidRow(
                box(
                  title = "Risk Management: The Foundation of Trading Success",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("Warren Buffett's Two Rules"),
                      div(style = "background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 15px 0;",
                          h2(style = "color: #e74c3c; margin: 0;", "RULE 1:"),
                          h3(style = "color: #2c3e50;", "Don't risk more than you can afford"),
                          h2(style = "color: #e74c3c; margin: 20px 0 0 0;", "RULE 2:"),
                          h3(style = "color: #2c3e50;", "Don't forget rule 1!")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Key Risk Management Principles",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("George Soros: Survive First"),
                      p(style = "font-size: 18px; font-style: italic; color: #008A82;",
                        '"My principle is to survive first and make money afterwards"'),
                      tags$ul(
                        tags$li("Calculate potential LOSS before entering"),
                        tags$li("Never risk more than you can afford to lose"),
                        tags$li("Capital preservation is paramount"),
                        tags$li("You can't trade if you're out of money")
                      )
                  )
                ),
                
                box(
                  title = "Risk & Reward Relationship",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Understanding the Balance"),
                      tags$ul(
                        tags$li(tags$b("More risk = More potential reward"), "But also more potential loss"),
                        tags$li(tags$b("Less risk = Less potential reward"), "But capital preservation is assured"),
                        tags$li(tags$b("Risk level must be appropriate for YOU:"),
                                tags$ul(
                                  tags$li("Your risk tolerance"),
                                  tags$li("Your financial situation"),
                                  tags$li("Your life circumstances"),
                                  tags$li("Your experience level")
                                )
                        )
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "When NOT to Trade",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("Your State of Mind Matters"),
                      p(tags$b("Deciding NOT to trade is still making a trading decision!")),
                      
                      fluidRow(
                        column(3,
                               div(class = "alert alert-danger",
                                   h4("Don't Trade When:"),
                                   tags$ul(
                                     tags$li("High (drink, drugs, medication)"),
                                     tags$li("Low (depressed, fed up)"),
                                     tags$li("Angry or vengeful"),
                                     tags$li("Tired or exhausted")
                                   )
                               )
                        ),
                        column(9,
                               h4("Why Emotional State Affects Trading:"),
                               tags$ul(
                                 tags$li("Impaired judgment and decision-making"),
                                 tags$li("Reduced ability to follow your plan"),
                                 tags$li("Increased impulsiveness"),
                                 tags$li("Higher risk of revenge trading after losses"),
                                 tags$li("Poor risk assessment")
                               ),
                               div(class = "alert alert-success",
                                   icon("check-circle"),
                                   " Take a break, clear your head, and come back when you're ready to trade rationally"
                               )
                        )
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Set Process Goals, Not Monetary Goals",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("Focus on What You Can Control"),
                      
                      fluidRow(
                        column(6,
                               div(style = "background: #f8d7da; padding: 15px; border-radius: 8px; border-left: 4px solid #e74c3c;",
                                   h4(style = "color: #721c24;", "❌ Bad Goals (Monetary)"),
                                   tags$ul(
                                     tags$li("'Make £500 today'"),
                                     tags$li("'Earn 10% this week'"),
                                     tags$li("'Never have a losing day'")
                                   ),
                                   p(style = "color: #721c24; font-weight: 600;",
                                     "These add pressure and lead to poor decisions!")
                               )
                        ),
                        column(6,
                               div(style = "background: #d4edda; padding: 15px; border-radius: 8px; border-left: 4px solid #00A39A;",
                                   h4(style = "color: #155724;", "✓ Good Goals (Process)"),
                                   tags$ul(
                                     tags$li("'Never trade without a valid set-up'"),
                                     tags$li("'Always stay within risk limits'"),
                                     tags$li("'Wait for valid trigger before trading'"),
                                     tags$li("'Always protect positions with stops'"),
                                     tags$li("'Review every trade in my journal'")
                                   ),
                                   p(style = "color: #155724; font-weight: 600;",
                                     "These keep you disciplined and improve results!")
                               )
                        )
                      )
                  )
                )
              )
      ),
      
      # Tab 6: Momentum Indicators
      tabItem(tabName = "momentum",
              fluidRow(
                box(
                  title = "Momentum & Rate of Change Indicators",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("What are Momentum Indicators?"),
                      p("Momentum indicators measure the speed and strength of price movements. They are:"),
                      tags$ul(
                        tags$li(tags$b("Leading indicators:"), "Provide advanced warning of potential price moves"),
                        tags$li(tags$b("Oscillators:"), "Fluctuate between fixed bounds or around a zero line"),
                        tags$li(tags$b("Secondary indicators:"), "Should be used with primary indicators for confirmation")
                      ),
                      
                      h4("Key Concepts:"),
                      tags$ul(
                        tags$li("Market momentum LEADS price"),
                        tags$li("Can identify overbought/oversold conditions"),
                        tags$li("Reveal divergences that warn of reversals"),
                        tags$li("Generate objective buy/sell signals")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Momentum Formula",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Momentum (10)"),
                      div(style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0; text-align: center;",
                          h4("Momentum = Current Price - Price n periods ago"),
                          p("Example: Momentum(10) = Close - Close[10]")
                      ),
                      p("Where:"),
                      tags$ul(
                        tags$li("Current Price = Latest close"),
                        tags$li("n = Number of periods (typically 10)"),
                        tags$li("Result oscillates around zero line")
                      )
                  )
                ),
                
                box(
                  title = "Rate of Change Formula",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Rate of Change (10)"),
                      div(style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0; text-align: center;",
                          h4("ROC = (Momentum ÷ Old Price) × 100"),
                          p("Example: ROC(10) = [(Close - Close[10]) / Close[10]] × 100")
                      ),
                      p("Advantages of ROC:"),
                      tags$ul(
                        tags$li("Expressed as percentage"),
                        tags$li("Easier to compare across different price levels"),
                        tags$li("More intuitive interpretation"),
                        tags$li("Also oscillates around zero line")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Momentum/ROC Chart Example",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           selectInput("mom_period", "Momentum Period:", 
                                       choices = c(5, 10, 14, 20), selected = 10),
                           checkboxInput("show_roc", "Show ROC instead of Momentum", FALSE),
                           checkboxInput("show_signals", "Show Trading Signals", TRUE)
                    ),
                    column(9,
                           div(class = "concept-card",
                               h4("Interpretation:"),
                               tags$ul(
                                 tags$li(tags$b("Positive Momentum:"), "Price is higher than n periods ago (uptrend)"),
                                 tags$li(tags$b("Negative Momentum:"), "Price is lower than n periods ago (downtrend)"),
                                 tags$li(tags$b("Zero Line Cross:"), "Potential trend change signal"),
                                 tags$li(tags$b("Rising Momentum:"), "Increasing buying pressure"),
                                 tags$li(tags$b("Falling Momentum:"), "Increasing selling pressure")
                               )
                           )
                    )
                  ),
                  
                  withSpinner(plotlyOutput("momentum_chart", height = "600px"), color = "#008A82"),
                  
                  div(class = "alert alert-success", style = "margin-top: 20px;",
                      icon("lightbulb"),
                      tags$b(" Trading Signals:"),
                      tags$ul(
                        tags$li(tags$b("BUY:"), "When momentum crosses above zero line"),
                        tags$li(tags$b("SELL:"), "When momentum crosses below zero line"),
                        tags$li("Provides early signals at start of trends"),
                        tags$li("Many false signals in sideways markets - always confirm with price action!")
                      )
                  )
                )
              )
      ),
      
      # Tab 7: RSI Analysis
      tabItem(tabName = "rsi",
              fluidRow(
                box(
                  title = "Relative Strength Index (RSI)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("What is RSI?"),
                      p("RSI is one of the most popular momentum oscillators:"),
                      tags$ul(
                        tags$li("Developed by J. Welles Wilder"),
                        tags$li("Plotted on a fixed scale from 0 to 100%"),
                        tags$li("Takes into account ALL price moves in the period (not just two prices)"),
                        tags$li("Compares average gains to average losses"),
                        tags$li("More sophisticated than simple Momentum/ROC")
                      ),
                      
                      div(style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0;",
                          h4("RSI Formula:"),
                          p(style = "text-align: center; font-size: 16px;",
                            "RSI = 100 - [100 / (1 + RS)]"),
                          p(style = "text-align: center;",
                            "where RS = Average Gain / Average Loss")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "RSI Interpretation",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(4,
                           div(class = "concept-card",
                               h4("Overbought Zone (>70)"),
                               tags$ul(
                                 tags$li("Strong upward momentum"),
                                 tags$li("Price rising rapidly"),
                                 tags$li(tags$b("NOT necessarily:"), "Time to sell!"),
                                 tags$li("Strong trends stay overbought")
                               ),
                               div(class = "alert alert-warning",
                                   "Wait for confirmation before trading OB/OS!"
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-card",
                               h4("Neutral Zone (30-70)"),
                               tags$ul(
                                 tags$li("Normal price fluctuations"),
                                 tags$li("No extreme momentum"),
                                 tags$li("Waiting for signals"),
                                 tags$li("Use with trend analysis")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-card",
                               h4("Oversold Zone (<30)"),
                               tags$ul(
                                 tags$li("Strong downward momentum"),
                                 tags$li("Price falling rapidly"),
                                 tags$li(tags$b("NOT necessarily:"), "Time to buy!"),
                                 tags$li("Strong downtrends stay oversold")
                               ),
                               div(class = "alert alert-warning",
                                   "Always consider the major trend direction!"
                               )
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "RSI Chart Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           numericInput("rsi_period", "RSI Period:", value = 14, min = 5, max = 50, step = 1),
                           numericInput("rsi_ob", "Overbought Level:", value = 70, min = 60, max = 80, step = 5),
                           numericInput("rsi_os", "Oversold Level:", value = 30, min = 20, max = 40, step = 5),
                           checkboxInput("show_rsi_signals", "Show Trading Signals", TRUE)
                    ),
                    column(9,
                           div(class = "concept-card",
                               h4("RSI Trading Signals:"),
                               tags$ul(
                                 tags$li(tags$b("BUY Signal:"), "RSI rises OUT OF oversold zone (crosses above 30)"),
                                 tags$li(tags$b("SELL Signal:"), "RSI falls OUT OF overbought zone (crosses below 70)"),
                                 tags$li("Signals are EARLIER than Momentum zero-line crosses"),
                                 tags$li(tags$b("Critical:"), "Always consider the major trend direction!"),
                                 tags$li("Focus on BUY signals in uptrends, SELL signals in downtrends")
                               )
                           )
                    )
                  ),
                  
                  withSpinner(plotlyOutput("rsi_chart", height = "700px"), color = "#008A82"),
                  
                  div(class = "alert alert-danger", style = "margin-top: 20px;",
                      icon("exclamation-triangle"),
                      tags$b(" Common Mistake:"),
                      " Don't automatically sell just because RSI is overbought! Strong uptrends can stay overbought for extended periods. Similarly, don't automatically buy just because RSI is oversold - strong downtrends can stay oversold for long periods."
                  )
                )
              )
      ),
      
      # Tab 8: Stochastic Oscillator
      tabItem(tabName = "stochastic",
              fluidRow(
                box(
                  title = "Stochastic Oscillator",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("What is the Stochastic Oscillator?"),
                      p("The Stochastic oscillator compares the current price to its recent trading range:"),
                      tags$ul(
                        tags$li("Developed by George Lane"),
                        tags$li("Requires more data than Momentum or RSI (uses High, Low, Close)"),
                        tags$li("Based on observation that in uptrends, closes are near the high of recent range"),
                        tags$li("In downtrends, closes are near the low of recent range"),
                        tags$li("Plotted on scale of 0-100%")
                      ),
                      
                      div(style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0;",
                          h4("Slow Stochastic Formula (5-3-3):"),
                          p(style = "font-family: monospace;",
                            "%K = [(Close - L5) / (H5 - L5)] × 100"),
                          p(style = "font-family: monospace;",
                            "%D = 3-day sum of (Close - L5) / 3-day sum of (H5 - L5) × 100"),
                          p(style = "font-family: monospace;",
                            "%Dn = 3-day SMA of %D"),
                          p(style = "font-size: 12px; color: #666;",
                            "Where: L5 = Lowest Low of last 5 days, H5 = Highest High of last 5 days")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Stochastic Trading Signals",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("How to Trade with Stochastics"),
                      
                      fluidRow(
                        column(6,
                               h4("Buy Signals:"),
                               tags$ul(
                                 tags$li("%D crosses ABOVE %Dn"),
                                 tags$li("Occurs in oversold zone (<20)"),
                                 tags$li("Near support in trading range"),
                                 tags$li("Confirms bullish divergence")
                               ),
                               div(class = "alert alert-success",
                                   icon("arrow-up"),
                                   " Best in established uptrends or at support levels"
                               )
                        ),
                        column(6,
                               h4("Sell Signals:"),
                               tags$ul(
                                 tags$li("%D crosses BELOW %Dn"),
                                 tags$li("Occurs in overbought zone (>80)"),
                                 tags$li("Near resistance in trading range"),
                                 tags$li("Confirms bearish divergence")
                               ),
                               div(class = "alert alert-danger",
                                   icon("arrow-down"),
                                   " Best in established downtrends or at resistance levels"
                               )
                        )
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Stochastic Chart Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           numericInput("stoch_k", "%K Period:", value = 5, min = 3, max = 21, step = 1),
                           numericInput("stoch_d", "%D Period:", value = 3, min = 2, max = 10, step = 1),
                           numericInput("stoch_dn", "%Dn Period:", value = 3, min = 2, max = 10, step = 1),
                           checkboxInput("show_stoch_signals", "Show Trading Signals", TRUE)
                    ),
                    column(9,
                           div(class = "concept-card",
                               h4("Stochastics in Sideways Markets:"),
                               p("Stochastics excel in trading ranges:"),
                               tags$ul(
                                 tags$li("Buy near support when %D crosses above %Dn in OS zone"),
                                 tags$li("Sell near resistance when %D crosses below %Dn in OB zone"),
                                 tags$li("Wait for price to be in buying/selling zone"),
                                 tags$li("Multiple profitable trades in same range")
                               ),
                               div(class = "alert alert-warning",
                                   "Range must be established first - look for clear support and resistance"
                               )
                           )
                    )
                  ),
                  
                  withSpinner(plotlyOutput("stochastic_chart", height = "700px"), color = "#008A82"),
                  
                  div(class = "alert alert-success", style = "margin-top: 20px;",
                      icon("check-circle"),
                      tags$b(" Key Advantages:"),
                      " Stochastics can generate profits in sideways markets where trend-following strategies fail. The crossover signals provide clear entry and exit points. However, always confirm with support/resistance levels!"
                  )
                )
              )
      ),
      
      # Tab 9: Divergence Analysis
      tabItem(tabName = "divergence",
              fluidRow(
                box(
                  title = "Divergence: Advanced Warning of Reversals",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("What is Divergence?"),
                      p(tags$b("Divergence occurs when price and momentum move in opposite directions")),
                      p("This is one of the most powerful uses of oscillators because:"),
                      tags$ul(
                        tags$li("Gives ADVANCED warning of potential trend reversals"),
                        tags$li("Momentum leads price, so momentum changes first"),
                        tags$li("Price makes new high/low but momentum doesn't confirm"),
                        tags$li("Suggests weakening trend strength")
                      ),
                      
                      div(class = "alert alert-warning",
                          icon("exclamation-triangle"),
                          tags$b(" Important:"), " Always wait for confirmation from primary indicators (trend lines, support/resistance, price patterns) before trading divergence!"
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Types of Divergence",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Bullish Divergence"),
                      p(tags$b("Warning of potential upward reversal")),
                      tags$ul(
                        tags$li("Price makes LOWER lows"),
                        tags$li("Oscillator makes HIGHER lows"),
                        tags$li("Suggests selling pressure weakening"),
                        tags$li("Often occurs at support levels")
                      ),
                      div(style = "background: #d4edda; padding: 15px; border-radius: 8px; margin: 10px 0;",
                          p(style = "color: #155724; margin: 0;",
                            icon("chart-line"),
                            " Look for: Downtrend losing momentum, potential reversal up")
                      )
                  )
                ),
                
                box(
                  title = "Types of Divergence",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Bearish Divergence"),
                      p(tags$b("Warning of potential downward reversal")),
                      tags$ul(
                        tags$li("Price makes HIGHER highs"),
                        tags$li("Oscillator makes LOWER highs"),
                        tags$li("Suggests buying pressure weakening"),
                        tags$li("Often occurs at resistance levels")
                      ),
                      div(style = "background: #f8d7da; padding: 15px; border-radius: 8px; margin: 10px 0;",
                          p(style = "color: #721c24; margin: 0;",
                            icon("chart-line"),
                            " Look for: Uptrend losing momentum, potential reversal down")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Divergence Example Charts",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           selectInput("div_indicator", "Select Indicator:",
                                       choices = c("RSI" = "rsi", 
                                                   "Momentum" = "momentum",
                                                   "Stochastic" = "stochastic"),
                                       selected = "rsi"),
                           selectInput("div_type", "Divergence Type:",
                                       choices = c("Bullish Divergence" = "bullish",
                                                   "Bearish Divergence" = "bearish"),
                                       selected = "bullish"),
                           checkboxInput("show_div_lines", "Show Divergence Lines", TRUE)
                    ),
                    column(9,
                           div(class = "concept-card",
                               h4("Divergence Confirmation Steps:"),
                               tags$ol(
                                 tags$li(tags$b("Warning:"), "Notice divergence forming (price vs oscillator)"),
                                 tags$li(tags$b("Wait:"), "Don't trade immediately - divergence can continue"),
                                 tags$li(tags$b("Confirmation:"), "Wait for trend line break or key level break"),
                                 tags$li(tags$b("Entry:"), "Enter after confirmation with appropriate stop loss"),
                                 tags$li(tags$b("Target:"), "Set target at next key support/resistance level")
                               )
                           )
                    )
                  ),
                  
                  withSpinner(plotlyOutput("divergence_chart", height = "700px"), color = "#008A82"),
                  
                  div(class = "alert alert-success", style = "margin-top: 20px;",
                      icon("lightbulb"),
                      tags$b(" Pro Tip:"), " Divergence works best when combined with price patterns (Double Tops/Bottoms, Head & Shoulders, Rising/Falling Wedges). The divergence warns you to watch for these patterns, and the pattern breakout gives you the confirmation to trade!"
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Not Divergence vs True Divergence",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("Learn to Identify True Divergence"),
                      
                      fluidRow(
                        column(6,
                               div(style = "background: #f8d7da; padding: 15px; border-radius: 8px;",
                                   h4(style = "color: #721c24;", "❌ NOT Divergence"),
                                   p("When price and momentum both move in the same direction:"),
                                   tags$ul(
                                     tags$li("Both making higher highs → Trend accelerating"),
                                     tags$li("Both making lower lows → Downtrend accelerating"),
                                     tags$li("Momentum confirms price → Trend is healthy"),
                                     tags$li("No warning of reversal")
                                   )
                               )
                        ),
                        column(6,
                               div(style = "background: #d4edda; padding: 15px; border-radius: 8px;",
                                   h4(style = "color: #155724;", "✓ TRUE Divergence"),
                                   p("When price and momentum move in opposite directions:"),
                                   tags$ul(
                                     tags$li("Price higher highs BUT momentum lower highs → Bearish"),
                                     tags$li("Price lower lows BUT momentum higher lows → Bullish"),
                                     tags$li("Momentum NOT confirming price → Warning!"),
                                     tags$li("Potential reversal ahead")
                                   )
                               )
                        )
                      ),
                      
                      div(class = "alert alert-warning", style = "margin-top: 20px;",
                          icon("exclamation-triangle"),
                          " Remember: Compare price HIGHS with momentum HIGHS (or LOWS with LOWS). Don't compare trend lines - compare the actual peaks and troughs!"
                      )
                  )
                )
              )
      ),
      
      # Tab 10: Trading Signals Summary
      tabItem(tabName = "signals",
              fluidRow(
                box(
                  title = "Complete Trading Signals Framework",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-card",
                      h3("Integrating Psychology and Technical Analysis"),
                      p("Successful trading requires combining multiple elements:"),
                      tags$ol(
                        tags$li(tags$b("Trade Plan (S-T-E-M):"), "Fixed rules for each trading step"),
                        tags$li(tags$b("Risk Management:"), "Position sizing, stop losses, targets"),
                        tags$li(tags$b("Psychology Awareness:"), "Recognize and counter biases"),
                        tags$li(tags$b("Primary Indicators:"), "Trend lines, support/resistance, patterns"),
                        tags$li(tags$b("Secondary Indicators:"), "Oscillators for timing and confirmation")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Oscillator Comparison",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  DTOutput("indicator_comparison")
                )
              ),
              
              fluidRow(
                box(
                  title = "Trading Signal Checklist",
                  status = "success",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Before Entering Any Trade:"),
                      tags$ol(
                        tags$li(
                          tags$b("✓ Check Your Psychology:"),
                          tags$ul(
                            tags$li("Am I calm and rational?"),
                            tags$li("Am I following my plan or chasing?"),
                            tags$li("Am I influenced by recent wins/losses?")
                          )
                        ),
                        tags$li(
                          tags$b("✓ Confirm Primary Indicators:"),
                          tags$ul(
                            tags$li("Clear trend or trading range?"),
                            tags$li("Key support/resistance levels identified?"),
                            tags$li("Valid price pattern or breakout?")
                          )
                        ),
                        tags$li(
                          tags$b("✓ Check Secondary Indicators:"),
                          tags$ul(
                            tags$li("Momentum confirming or diverging?"),
                            tags$li("Oscillator in appropriate zone?"),
                            tags$li("Clear signal or just noise?")
                          )
                        ),
                        tags$li(
                          tags$b("✓ Risk Management:"),
                          tags$ul(
                            tags$li("Stop loss level defined?"),
                            tags$li("Position size calculated?"),
                            tags$li("Risk within my limits?"),
                            tags$li("Realistic target identified?")
                          )
                        )
                      )
                  )
                ),
                
                box(
                  title = "Common Trading Mistakes to Avoid",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "concept-card",
                      h3("Don't Make These Errors:"),
                      
                      div(style = "background: #f8d7da; padding: 10px; border-radius: 8px; margin: 10px 0; border-left: 4px solid #e74c3c;",
                          h4(style = "color: #721c24;", "❌ Psychology Errors:"),
                          tags$ul(
                            tags$li("Trading while emotional"),
                            tags$li("Revenge trading after losses"),
                            tags$li("Overconfidence after wins"),
                            tags$li("Holding losers too long (loss aversion)"),
                            tags$li("Taking profits too early (fear)")
                          )
                      ),
                      
                      div(style = "background: #f8d7da; padding: 10px; border-radius: 8px; margin: 10px 0; border-left: 4px solid #e74c3c;",
                          h4(style = "color: #721c24;", "❌ Technical Errors:"),
                          tags$ul(
                            tags$li("Selling just because 'overbought'"),
                            tags$li("Buying just because 'oversold'"),
                            tags$li("Trading divergence without confirmation"),
                            tags$li("Ignoring the major trend direction"),
                            tags$li("Using oscillators alone without price action")
                          )
                      ),
                      
                      div(style = "background: #f8d7da; padding: 10px; border-radius: 8px; margin: 10px 0; border-left: 4px solid #e74c3c;",
                          h4(style = "color: #721c24;", "❌ Risk Management Errors:"),
                          tags$ul(
                            tags$li("No stop loss or moving it further away"),
                            tags$li("Position size too large for account"),
                            tags$li("Unrealistic profit targets"),
                            tags$li("Not following the trade plan")
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Complete Trading Example",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  withSpinner(plotlyOutput("complete_example_chart", height = "600px"), color = "#008A82"),
                  
                  div(class = "concept-card", style = "margin-top: 20px;",
                      h3("Trade Analysis Walkthrough:"),
                      
                      tags$ol(
                        tags$li(
                          tags$b("SET-UP:"), 
                          "Established uptrend with higher highs and higher lows. Price pulled back to support at 1.2100."
                        ),
                        tags$li(
                          tags$b("Warning Sign:"), 
                          "RSI showing bullish divergence - price made lower low but RSI made higher low. Momentum weakening in downward correction."
                        ),
                        tags$li(
                          tags$b("TRIGGER:"), 
                          "Price breaks above short-term resistance at 1.2120. RSI rises above 30 (out of oversold zone)."
                        ),
                        tags$li(
                          tags$b("EXECUTION:"), 
                          "Wait for hourly candle to close above 1.2120 + 10 pip buffer = Enter at 1.2130"
                        ),
                        tags$li(
                          tags$b("MANAGEMENT:"),
                          tags$ul(
                            tags$li("Stop Loss: Below recent low at 1.2095 (35 pip risk)"),
                            tags$li("Risk: £100 / Position Size: £100 ÷ 35 = £2.86 per pip"),
                            tags$li("Target: Next resistance at 1.2200 (70 pip target)"),
                            tags$li("Risk:Reward = 1:2 ratio")
                          )
                        ),
                        tags$li(
                          tags$b("OUTCOME:"), 
                          "Price rallies to target at 1.2200 for 70 pip gain = £200 profit. Stop loss was never threatened."
                        )
                      ),
                      
                      div(class = "alert alert-success", style = "margin-top: 20px;",
                          icon("check-circle"),
                          tags$b(" Key Success Factors:"),
                          tags$ul(
                            tags$li("Followed complete S-T-E-M process"),
                            tags$li("Used divergence as warning, not immediate signal"),
                            tags$li("Waited for confirmation from price breakout"),
                            tags$li("Proper position sizing based on risk"),
                            tags$li("Realistic target at next resistance level"),
                            tags$li("Stayed disciplined and followed the plan")
                          )
                      )
                  )
                )
              )
      )
    )
  )
)

# Server Definition
server <- function(input, output, session) {
  
  # Generate price data
  price_data <- generate_price_data(180, 100)
  
  # Position sizing calculator
  output$position_size <- renderText({
    pip_risk <- abs(input$entry_price - input$stop_price) * 10000  # Convert to pips
    if (pip_risk > 0) {
      lot_size <- input$risk_amount / (pip_risk * input$pip_value)
      paste0("£", format(round(lot_size, 2), nsmall = 2), " per pip")
    } else {
      "Enter valid prices"
    }
  })
  
  output$pip_risk <- renderText({
    pip_risk <- abs(input$entry_price - input$stop_price) * 10000
    paste0(round(pip_risk, 1), " pips")
  })
  
  # Hope vs Fear Chart
  output$hope_fear_chart <- renderPlotly({
    days <- 1:20
    prices <- c(100, 99.5, 99.2, 98.8, 98.5, 98.2, 98.0, 98.1, 98.3, 98.2,
                98.0, 97.8, 97.5, 97.3, 97.0, 96.8, 96.5, 96.3, 96.0, 95.8)
    
    plot_ly() %>%
      add_lines(x = days, y = prices, name = "Stock Price",
                line = list(color = "#e74c3c", width = 3)) %>%
      add_lines(x = days, y = rep(100, 20), name = "Entry Price",
                line = list(color = "#008A82", width = 2, dash = "dash")) %>%
      layout(
        title = list(text = "Hope vs Fear: You Bought at 100, Now at 98.20",
                     font = list(size = 16, color = "#002C3C")),
        xaxis = list(title = "Days", color = "#2c3e50"),
        yaxis = list(title = "Price", color = "#2c3e50"),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        annotations = list(
          list(x = 6, y = 98.2, text = "Current: 98.20<br>Stronger emotion: HOPE",
               showarrow = TRUE, arrowhead = 2, arrowcolor = "#f39c12",
               font = list(size = 12, color = "#f39c12"))
        )
      )
  })
  
  # Loss Aversion Chart
  output$loss_aversion_chart <- renderPlotly({
    gains <- seq(0, 500, by = 10)
    losses <- seq(-500, 0, by = 10)
    
    # Value function: v(x) = x^0.88 for gains, -2.5*(-x)^0.88 for losses
    value_gains <- gains^0.88
    value_losses <- -2.5 * (abs(losses)^0.88)
    
    plot_ly() %>%
      add_lines(x = gains, y = value_gains, name = "Gains",
                line = list(color = "#00A39A", width = 3)) %>%
      add_lines(x = losses, y = value_losses, name = "Losses",
                line = list(color = "#e74c3c", width = 3)) %>%
      add_lines(x = c(-500, 500), y = c(0, 0), name = "Zero",
                line = list(color = "#95a5a6", width = 1, dash = "dot")) %>%
      layout(
        title = list(text = "Loss Aversion: Pain of Loss is 2.5x Stronger than Joy of Gain",
                     font = list(size = 16, color = "#002C3C")),
        xaxis = list(title = "Gains/Losses (£)", zeroline = FALSE, color = "#2c3e50"),
        yaxis = list(title = "Psychological Value (Joy/Pain)", color = "#2c3e50"),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        annotations = list(
          list(x = 200, y = 200, text = "Joy of Gains",
               showarrow = FALSE, font = list(size = 14, color = "#00A39A")),
          list(x = -200, y = -400, text = "Pain of Losses<br>(2.5x stronger!)",
               showarrow = FALSE, font = list(size = 14, color = "#e74c3c"))
        )
      )
  })
  
  # Momentum Chart
  output$momentum_chart <- renderPlotly({
    data <- price_data
    period <- as.numeric(input$mom_period)
    
    if (input$show_roc) {
      data$momentum <- ROC(data$Close, n = period) * 100
      y_title <- "Rate of Change (%)"
    } else {
      data$momentum <- momentum(data$Close, n = period)
      y_title <- "Momentum"
    }
    
    # Create main price chart
    p1 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~Close, name = "Price", line = list(color = "#008A82", width = 2)) %>%
      layout(
        xaxis = list(title = "", color = "#2c3e50"),
        yaxis = list(title = "Price", color = "#2c3e50"),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    # Add trading signals if enabled
    if (input$show_signals) {
      # Buy signals (momentum crosses above zero)
      buy_signals <- which(data$momentum > 0 & lag(data$momentum, default = -1) <= 0)
      if (length(buy_signals) > 0) {
        p1 <- p1 %>%
          add_markers(x = data$Date[buy_signals], y = data$Close[buy_signals],
                      name = "Buy Signal", marker = list(color = "#00A39A", size = 10, symbol = "triangle-up"))
      }
      
      # Sell signals (momentum crosses below zero)
      sell_signals <- which(data$momentum < 0 & lag(data$momentum, default = 1) >= 0)
      if (length(sell_signals) > 0) {
        p1 <- p1 %>%
          add_markers(x = data$Date[sell_signals], y = data$Close[sell_signals],
                      name = "Sell Signal", marker = list(color = "#e74c3c", size = 10, symbol = "triangle-down"))
      }
    }
    
    # Create momentum chart
    p2 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~momentum, name = "Momentum", line = list(color = "#9b59b6", width = 2)) %>%
      add_lines(y = 0, name = "Zero Line", line = list(color = "#95a5a6", width = 1, dash = "dot")) %>%
      layout(
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = y_title, color = "#2c3e50"),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    subplot(p1, p2, nrows = 2, shareX = TRUE, heights = c(0.6, 0.4)) %>%
      layout(title = list(text = paste("Price with", ifelse(input$show_roc, "Rate of Change", "Momentum"), 
                                       "Indicator (Period:", period, ")"),
                          font = list(size = 16, color = "#002C3C")))
  })
  
  # RSI Chart
  output$rsi_chart <- renderPlotly({
    data <- price_data
    period <- input$rsi_period
    
    data$rsi <- RSI(data$Close, n = period)
    
    # Create main price chart
    p1 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~Close, name = "Price", line = list(color = "#008A82", width = 2)) %>%
      layout(
        xaxis = list(title = "", color = "#2c3e50"),
        yaxis = list(title = "Price", color = "#2c3e50"),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    # Add trading signals if enabled
    if (input$show_rsi_signals) {
      # Buy signals (RSI crosses above oversold)
      buy_signals <- which(data$rsi > input$rsi_os & lag(data$rsi, default = 0) <= input$rsi_os)
      if (length(buy_signals) > 0) {
        p1 <- p1 %>%
          add_markers(x = data$Date[buy_signals], y = data$Close[buy_signals],
                      name = "Buy Signal", marker = list(color = "#00A39A", size = 10, symbol = "triangle-up"))
      }
      
      # Sell signals (RSI crosses below overbought)
      sell_signals <- which(data$rsi < input$rsi_ob & lag(data$rsi, default = 100) >= input$rsi_ob)
      if (length(sell_signals) > 0) {
        p1 <- p1 %>%
          add_markers(x = data$Date[sell_signals], y = data$Close[sell_signals],
                      name = "Sell Signal", marker = list(color = "#e74c3c", size = 10, symbol = "triangle-down"))
      }
    }
    
    # Create RSI chart
    p2 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~rsi, name = "RSI", line = list(color = "#9b59b6", width = 2)) %>%
      add_lines(y = input$rsi_ob, name = "Overbought", line = list(color = "#e74c3c", width = 1, dash = "dash")) %>%
      add_lines(y = input$rsi_os, name = "Oversold", line = list(color = "#00A39A", width = 1, dash = "dash")) %>%
      add_lines(y = 50, name = "Midline", line = list(color = "#95a5a6", width = 1, dash = "dot")) %>%
      layout(
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = "RSI", range = c(0, 100), color = "#2c3e50"),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          list(type = "rect", x0 = min(data$Date), x1 = max(data$Date),
               y0 = input$rsi_ob, y1 = 100, fillcolor = "rgba(231, 76, 60, 0.1)", 
               line = list(width = 0), layer = "below"),
          list(type = "rect", x0 = min(data$Date), x1 = max(data$Date),
               y0 = 0, y1 = input$rsi_os, fillcolor = "rgba(0, 163, 154, 0.1)", 
               line = list(width = 0), layer = "below")
        )
      )
    
    subplot(p1, p2, nrows = 2, shareX = TRUE, heights = c(0.6, 0.4)) %>%
      layout(title = list(text = paste("Price with RSI Indicator (Period:", period, ")"),
                          font = list(size = 16, color = "#002C3C")))
  })
  
  # Stochastic Chart
  output$stochastic_chart <- renderPlotly({
    data <- price_data
    
    # Calculate stochastic
    stoch <- stoch(HLC(data.frame(High = data$High, Low = data$Low, Close = data$Close)),
                   nFastK = input$stoch_k, nFastD = input$stoch_d, nSlowD = input$stoch_dn)
    
    data$stoch_k <- stoch[, "fastK"]
    data$stoch_d <- stoch[, "fastD"]
    data$stoch_dn <- stoch[, "slowD"]
    
    # Create main price chart
    p1 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~Close, name = "Price", line = list(color = "#008A82", width = 2)) %>%
      layout(
        xaxis = list(title = "", color = "#2c3e50"),
        yaxis = list(title = "Price", color = "#2c3e50"),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    # Add trading signals if enabled
    if (input$show_stoch_signals) {
      # Buy signals (%D crosses above %Dn in oversold zone)
      buy_signals <- which(data$stoch_d > data$stoch_dn & 
                             lag(data$stoch_d, default = 0) <= lag(data$stoch_dn, default = 0) &
                             data$stoch_d < 20)
      if (length(buy_signals) > 0) {
        p1 <- p1 %>%
          add_markers(x = data$Date[buy_signals], y = data$Close[buy_signals],
                      name = "Buy Signal", marker = list(color = "#00A39A", size = 10, symbol = "triangle-up"))
      }
      
      # Sell signals (%D crosses below %Dn in overbought zone)
      sell_signals <- which(data$stoch_d < data$stoch_dn & 
                              lag(data$stoch_d, default = 100) >= lag(data$stoch_dn, default = 100) &
                              data$stoch_d > 80)
      if (length(sell_signals) > 0) {
        p1 <- p1 %>%
          add_markers(x = data$Date[sell_signals], y = data$Close[sell_signals],
                      name = "Sell Signal", marker = list(color = "#e74c3c", size = 10, symbol = "triangle-down"))
      }
    }
    
    # Create Stochastic chart
    p2 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~stoch_d, name = "%D", line = list(color = "#9b59b6", width = 2)) %>%
      add_lines(y = ~stoch_dn, name = "%Dn", line = list(color = "#e74c3c", width = 2)) %>%
      add_lines(y = 80, name = "Overbought", line = list(color = "#e74c3c", width = 1, dash = "dash")) %>%
      add_lines(y = 20, name = "Oversold", line = list(color = "#00A39A", width = 1, dash = "dash")) %>%
      layout(
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = "Stochastic (%)", range = c(0, 100), color = "#2c3e50"),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          list(type = "rect", x0 = min(data$Date), x1 = max(data$Date),
               y0 = 80, y1 = 100, fillcolor = "rgba(231, 76, 60, 0.1)", 
               line = list(width = 0), layer = "below"),
          list(type = "rect", x0 = min(data$Date), x1 = max(data$Date),
               y0 = 0, y1 = 20, fillcolor = "rgba(0, 163, 154, 0.1)", 
               line = list(width = 0), layer = "below")
        )
      )
    
    subplot(p1, p2, nrows = 2, shareX = TRUE, heights = c(0.6, 0.4)) %>%
      layout(title = list(text = paste("Price with Stochastic Oscillator (", 
                                       input$stoch_k, "-", input$stoch_d, "-", input$stoch_dn, ")"),
                          font = list(size = 16, color = "#002C3C")))
  })
  
  # Divergence Chart
  output$divergence_chart <- renderPlotly({
    data <- price_data
    
    # Generate data with divergence
    if (input$div_type == "bullish") {
      # Create bullish divergence: price lower lows, indicator higher lows
      # Modify last 40 days to show divergence
      idx <- (nrow(data)-40):nrow(data)
      data$Close[idx] <- data$Close[idx[1]] - (1:length(idx)) * 0.05 + rnorm(length(idx), 0, 0.1)
      data$Close[(nrow(data)-10):nrow(data)] <- data$Close[nrow(data)-10] + (1:11) * 0.03
    } else {
      # Create bearish divergence: price higher highs, indicator lower highs
      idx <- (nrow(data)-40):nrow(data)
      data$Close[idx] <- data$Close[idx[1]] + (1:length(idx)) * 0.05 + rnorm(length(idx), 0, 0.1)
      data$Close[(nrow(data)-10):nrow(data)] <- data$Close[nrow(data)-10] - (1:11) * 0.03
    }
    
    # Calculate indicator
    if (input$div_indicator == "rsi") {
      data$indicator <- RSI(data$Close, n = 14)
      ind_name <- "RSI"
      ind_range <- c(0, 100)
    } else if (input$div_indicator == "momentum") {
      data$indicator <- momentum(data$Close, n = 10)
      ind_name <- "Momentum"
      ind_range <- c(min(data$indicator, na.rm = TRUE), max(data$indicator, na.rm = TRUE))
    } else {
      stoch <- stoch(HLC(data.frame(High = data$High, Low = data$Low, Close = data$Close)),
                     nFastK = 5, nFastD = 3, nSlowD = 3)
      data$indicator <- stoch[, "fastD"]
      ind_name <- "Stochastic %D"
      ind_range <- c(0, 100)
    }
    
    # Create price chart
    p1 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~Close, name = "Price", line = list(color = "#008A82", width = 2)) %>%
      layout(
        xaxis = list(title = "", color = "#2c3e50"),
        yaxis = list(title = "Price", color = "#2c3e50"),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    # Add divergence lines if enabled
    if (input$show_div_lines && input$div_type == "bullish") {
      # Price lower lows
      low1_idx <- nrow(data) - 30
      low2_idx <- nrow(data) - 10
      
      p1 <- p1 %>%
        add_segments(x = data$Date[low1_idx], xend = data$Date[low2_idx],
                     y = data$Close[low1_idx], yend = data$Close[low2_idx],
                     name = "Price Trend", line = list(color = "#e74c3c", width = 2, dash = "dash"))
    } else if (input$show_div_lines && input$div_type == "bearish") {
      # Price higher highs
      high1_idx <- nrow(data) - 30
      high2_idx <- nrow(data) - 10
      
      p1 <- p1 %>%
        add_segments(x = data$Date[high1_idx], xend = data$Date[high2_idx],
                     y = data$Close[high1_idx], yend = data$Close[high2_idx],
                     name = "Price Trend", line = list(color = "#e74c3c", width = 2, dash = "dash"))
    }
    
    # Create indicator chart
    p2 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~indicator, name = ind_name, line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = ind_name, range = ind_range, color = "#2c3e50"),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    # Add divergence lines to indicator if enabled
    if (input$show_div_lines && input$div_type == "bullish") {
      # Indicator higher lows
      low1_idx <- nrow(data) - 30
      low2_idx <- nrow(data) - 10
      
      p2 <- p2 %>%
        add_segments(x = data$Date[low1_idx], xend = data$Date[low2_idx],
                     y = data$indicator[low1_idx], yend = data$indicator[low2_idx],
                     name = "Indicator Trend", line = list(color = "#00A39A", width = 2, dash = "dash"))
    } else if (input$show_div_lines && input$div_type == "bearish") {
      # Indicator lower highs
      high1_idx <- nrow(data) - 30
      high2_idx <- nrow(data) - 10
      
      p2 <- p2 %>%
        add_segments(x = data$Date[high1_idx], xend = data$Date[high2_idx],
                     y = data$indicator[high1_idx], yend = data$indicator[high2_idx],
                     name = "Indicator Trend", line = list(color = "#00A39A", width = 2, dash = "dash"))
    }
    
    subplot(p1, p2, nrows = 2, shareX = TRUE, heights = c(0.6, 0.4)) %>%
      layout(title = list(text = paste(ifelse(input$div_type == "bullish", "Bullish", "Bearish"),
                                       "Divergence Example with", ind_name),
                          font = list(size = 16, color = "#002C3C")))
  })
  
  # Indicator Comparison Table
  output$indicator_comparison <- renderDT({
    comparison_data <- data.frame(
      Indicator = c("Momentum", "Rate of Change", "RSI", "Stochastic"),
      Scale = c("Zero Line", "Zero Line", "0-100%", "0-100%"),
      Best_Use = c(
        "Simple trend changes",
        "Percentage-based momentum",
        "Overbought/Oversold + Divergence",
        "Sideways markets + Crossover signals"
      ),
      Calculation = c(
        "Close - Close[n]",
        "(Close - Close[n])/Close[n] × 100",
        "100 - [100/(1 + RS)]",
        "(Close - Low[n])/(High[n] - Low[n]) × 100"
      ),
      Typical_Period = c("10", "10", "14", "5-3-3 or 10-6-6"),
      Signals = c(
        "Zero line crosses",
        "Zero line crosses",
        "OB/OS exits + Divergence",
        "%D/%Dn crosses in OB/OS zones"
      ),
      Advantages = c(
        "Simple, early signals",
        "Easy to compare across markets",
        "Fixed scale, popular, reliable",
        "Good for ranging markets"
      ),
      Disadvantages = c(
        "Scale varies, many false signals",
        "Scale varies, false signals",
        "Signals come later",
        "Complex calculation, whipsaw in trends"
      ),
      stringsAsFactors = FALSE
    )
    
    datatable(comparison_data,
              options = list(
                pageLength = 10,
                dom = 't',
                scrollX = TRUE,
                columnDefs = list(
                  list(width = '100px', targets = 0),
                  list(width = '80px', targets = 1),
                  list(width = '150px', targets = 2),
                  list(width = '150px', targets = 3),
                  list(width = '100px', targets = 4),
                  list(width = '150px', targets = 5),
                  list(width = '150px', targets = 6),
                  list(width = '150px', targets = 7)
                )
              ),
              rownames = FALSE,
              class = 'cell-border stripe') %>%
      formatStyle(
        columns = 1:8,
        backgroundColor = 'white',
        color = '#2c3e50'
      ) %>%
      formatStyle(
        columns = 1,
        fontWeight = 'bold',
        color = '#008A82'
      )
  })
  
  # Complete Trading Example Chart
  output$complete_example_chart <- renderPlotly({
    # Generate example trade data
    set.seed(123)
    dates <- seq(Sys.Date() - 60, Sys.Date(), by = "day")
    
    # Create uptrend with pullback and reversal
    trend <- seq(1.2000, 1.2150, length.out = length(dates))
    noise <- cumsum(rnorm(length(dates), 0, 0.002))
    
    # Add deliberate pullback in middle
    pullback_start <- 25
    pullback_end <- 40
    pullback_depth <- seq(0, -0.015, length.out = pullback_end - pullback_start + 1)
    noise[pullback_start:pullback_end] <- noise[pullback_start] + pullback_depth
    
    # Recovery after pullback
    recovery <- seq(noise[pullback_end], noise[pullback_end] + 0.02, 
                    length.out = length(dates) - pullback_end)
    noise[(pullback_end + 1):length(dates)] <- recovery
    
    price <- trend + noise
    
    data <- data.frame(
      Date = dates,
      Close = price,
      High = price + abs(rnorm(length(dates), 0.001, 0.0005)),
      Low = price - abs(rnorm(length(dates), 0.001, 0.0005))
    )
    
    # Calculate RSI
    data$rsi <- RSI(data$Close, n = 14)
    
    # Key levels
    support <- 1.2100
    resistance_short <- 1.2120
    target <- 1.2200
    entry <- 1.2130
    stop <- 1.2095
    
    # Create price chart with annotations
    p1 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~Close, name = "Price", line = list(color = "#008A82", width = 2)) %>%
      
      # Support and resistance lines
      add_lines(y = support, name = "Support", 
                line = list(color = "#00A39A", width = 2, dash = "dash")) %>%
      add_lines(y = resistance_short, name = "Short-term Resistance", 
                line = list(color = "#e74c3c", width = 2, dash = "dash")) %>%
      add_lines(y = target, name = "Target", 
                line = list(color = "#f39c12", width = 2, dash = "dot")) %>%
      
      # Entry, stop, target markers
      add_markers(x = data$Date[42], y = entry, name = "Entry Point",
                  marker = list(color = "#00A39A", size = 15, symbol = "triangle-up")) %>%
      add_markers(x = data$Date[42], y = stop, name = "Stop Loss",
                  marker = list(color = "#e74c3c", size = 12, symbol = "x")) %>%
      add_markers(x = data$Date[55], y = target, name = "Target Hit",
                  marker = list(color = "#f39c12", size = 15, symbol = "star")) %>%
      
      # Uptrend line
      add_segments(x = data$Date[1], xend = data$Date[50],
                   y = 1.2020, yend = 1.2140,
                   name = "Uptrend", line = list(color = "#3498db", width = 2)) %>%
      
      layout(
        xaxis = list(title = "", color = "#2c3e50"),
        yaxis = list(title = "Price (EUR/USD)", color = "#2c3e50", 
                     range = c(1.2050, 1.2210)),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        annotations = list(
          list(x = data$Date[30], y = 1.2085, text = "Pullback to Support",
               showarrow = TRUE, arrowhead = 2, arrowcolor = "#e74c3c",
               font = list(size = 11, color = "#e74c3c")),
          list(x = data$Date[35], y = 1.2075, text = "Bullish Divergence<br>(see RSI below)",
               showarrow = TRUE, arrowhead = 2, arrowcolor = "#9b59b6",
               font = list(size = 11, color = "#9b59b6")),
          list(x = data$Date[42], y = 1.2140, text = "Breakout + Entry",
               showarrow = TRUE, arrowhead = 2, arrowcolor = "#00A39A",
               font = list(size = 11, color = "#00A39A")),
          list(x = data$Date[55], y = 1.2205, text = "Target Reached!",
               showarrow = TRUE, arrowhead = 2, arrowcolor = "#f39c12",
               font = list(size = 11, color = "#f39c12"))
        )
      )
    
    # Create RSI chart with divergence
    p2 <- plot_ly(data, x = ~Date) %>%
      add_lines(y = ~rsi, name = "RSI", line = list(color = "#9b59b6", width = 2)) %>%
      add_lines(y = 70, name = "Overbought", line = list(color = "#e74c3c", width = 1, dash = "dash")) %>%
      add_lines(y = 30, name = "Oversold", line = list(color = "#00A39A", width = 1, dash = "dash")) %>%
      
      # Divergence lines
      add_segments(x = data$Date[28], xend = data$Date[38],
                   y = 25, yend = 35,
                   name = "RSI Higher Lows", 
                   line = list(color = "#00A39A", width = 2, dash = "dash")) %>%
      
      # RSI buy signal
      add_markers(x = data$Date[41], y = data$rsi[41], name = "RSI Buy Signal",
                  marker = list(color = "#00A39A", size = 12, symbol = "triangle-up")) %>%
      
      layout(
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = "RSI", range = c(0, 100), color = "#2c3e50"),
        showlegend = TRUE,
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          list(type = "rect", x0 = min(data$Date), x1 = max(data$Date),
               y0 = 70, y1 = 100, fillcolor = "rgba(231, 76, 60, 0.1)", 
               line = list(width = 0), layer = "below"),
          list(type = "rect", x0 = min(data$Date), x1 = max(data$Date),
               y0 = 0, y1 = 30, fillcolor = "rgba(0, 163, 154, 0.1)", 
               line = list(width = 0), layer = "below")
        ),
        annotations = list(
          list(x = data$Date[33], y = 20, text = "Bullish Divergence:<br>Price ↓ RSI ↑",
               showarrow = FALSE, font = list(size = 11, color = "#9b59b6",
                                              weight = "bold"))
        )
      )
    
    subplot(p1, p2, nrows = 2, shareX = TRUE, heights = c(0.65, 0.35)) %>%
      layout(
        title = list(
          text = "Complete Trading Example: EUR/USD with S-T-E-M Process",
          font = list(size = 16, color = "#002C3C", weight = "bold")
        )
      )
  })
}

# Run the application
shinyApp(ui = ui, server = server)