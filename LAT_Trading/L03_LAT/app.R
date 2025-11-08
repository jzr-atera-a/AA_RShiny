# Volume Profile & Market Profile Analysis Dashboard
# Professional Teal Gradient Theme

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(lubridate)
library(shinycssloaders)
library(tidyr)
library(ggplot2)

# Generate sample market data with volume
generate_market_data <- function(days = 180) {
  dates <- seq(Sys.Date() - days, Sys.Date(), by = "day")
  
  data <- data.frame(
    date = dates,
    Timestamp = as.POSIXct(paste(dates, "12:00:00"))
  ) %>%
    mutate(
      Open = 100 + cumsum(rnorm(n(), 0, 2)),
      High = Open + abs(rnorm(n(), 2, 1)),
      Low = Open - abs(rnorm(n(), 2, 1)),
      Close = Open + rnorm(n(), 0, 1.5),
      Volume = sample(1000:5000, n(), replace = TRUE)
    )
  
  return(data)
}

# Generate intraday data for Market Profile
generate_intraday_data <- function(date_selected = Sys.Date()) {
  times <- seq(
    as.POSIXct(paste(date_selected, "09:00:00")),
    as.POSIXct(paste(date_selected, "16:00:00")),
    by = "30 min"
  )
  
  base_price <- 100
  data <- data.frame(
    Timestamp = times
  ) %>%
    mutate(
      period = row_number(),
      TPO_letter = LETTERS[ceiling(period/2)],
      Price = base_price + cumsum(rnorm(n(), 0, 0.5)),
      Volume = sample(100:500, n(), replace = TRUE)
    )
  
  return(data)
}

# Calculate Volume Profile
calculate_volume_profile <- function(data, price_bins = 50) {
  price_range <- range(c(data$High, data$Low), na.rm = TRUE)
  price_levels <- seq(price_range[1], price_range[2], length.out = price_bins)
  
  volume_at_price <- data.frame(
    price_level = price_levels[-length(price_levels)]
  ) %>%
    mutate(
      volume = sapply(price_level, function(p) {
        sum(data$Volume[data$Low <= p & data$High >= p], na.rm = TRUE)
      })
    )
  
  # Calculate POC (Point of Control)
  poc_idx <- which.max(volume_at_price$volume)
  poc_price <- volume_at_price$price_level[poc_idx]
  
  # Calculate Value Area (68% of volume)
  total_volume <- sum(volume_at_price$volume)
  target_volume <- total_volume * 0.68
  
  sorted_vol <- volume_at_price %>%
    arrange(desc(volume)) %>%
    mutate(cumvol = cumsum(volume))
  
  value_area_prices <- sorted_vol %>%
    filter(cumvol <= target_volume) %>%
    pull(price_level)
  
  vah <- max(value_area_prices)
  val <- min(value_area_prices)
  
  list(
    volume_profile = volume_at_price,
    poc = poc_price,
    vah = vah,
    val = val
  )
}

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "W3-Vol.Profile & Market Profile Analysis"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Introduction", tabName = "intro", icon = icon("info-circle")),
      menuItem("Volume Profile Basics", tabName = "vp_basics", icon = icon("chart-bar")),
      menuItem("VP Shapes", tabName = "vp_shapes", icon = icon("shapes")),
      menuItem("Low Volume Recovery", tabName = "lvr", icon = icon("arrow-trend-up")),
      menuItem("POC & Value Area", tabName = "poc_va", icon = icon("crosshairs")),
      menuItem("Support & Resistance", tabName = "support", icon = icon("layer-group")),
      menuItem("Initial Balance", tabName = "initial_balance", icon = icon("clock")),
      menuItem("Market Profile", tabName = "market_profile", icon = icon("table")),
      menuItem("Trading Strategies", tabName = "strategies", icon = icon("chess")),
      menuItem("Options Trading", tabName = "options", icon = icon("chart-line"))
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
          transition: transform 0.2s ease;
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
          font-size: 16px;
        }
        
        .box-body {
          background-color: #ffffff !important;
          color: #2c3e50 !important;
          padding: 20px;
        }
        
        /* Value boxes */
        .small-box {
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15) !important;
          transition: transform 0.2s ease;
        }
        
        .small-box:hover {
          transform: translateY(-3px);
        }
        
        .small-box.bg-aqua { 
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important; 
        }
        
        .small-box.bg-blue { 
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important; 
        }
        
        .small-box.bg-green { 
          background: linear-gradient(135deg, #27ae60 0%, #229954 100%) !important; 
        }
        
        .small-box.bg-yellow { 
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; 
        }
        
        /* Info styling */
        .info-box {
          background: rgba(255, 255, 255, 0.98) !important;
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 44, 60, 0.15) !important;
          border-left: 4px solid #008A82;
        }
        
        /* Concept explanation boxes */
        .concept-box {
          background: linear-gradient(135deg, #e8f6f5 0%, #d4efed 100%);
          border-left: 4px solid #008A82;
          padding: 20px;
          border-radius: 8px;
          margin: 15px 0;
          box-shadow: 0 4px 12px rgba(0, 138, 130, 0.1);
        }
        
        .concept-title {
          color: #002C3C;
          font-weight: 600;
          font-size: 18px;
          margin-bottom: 10px;
        }
        
        .concept-text {
          color: #2c3e50;
          line-height: 1.6;
          font-size: 14px;
        }
        
        /* Key point styling */
        .key-point {
          background: rgba(255, 255, 255, 0.9);
          border-left: 3px solid #00A39A;
          padding: 10px 15px;
          margin: 10px 0;
          border-radius: 5px;
        }
      "))
    ),
    
    tabItems(
      # Tab 1: Introduction
      tabItem(tabName = "intro",
              fluidRow(
                box(
                  title = "Volume Profile & Market Profile Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "What is Volume Profile?"),
                      div(class = "concept-text",
                          "Volume Profile is an advanced charting tool that displays trading activity (volume) 
                          over a specified period at specified price levels. It plots a histogram on the chart 
                          to show significant price levels based on volume."
                      )
                  ),
                  div(class = "concept-box",
                      div(class = "concept-title", "Why Volume Profile Matters"),
                      div(class = "concept-text",
                          "With 80% of market volume coming from 10 of the large financial institutions, 
                          it's important to understand their positioning. Volume at price tells us which 
                          price levels were most important to the smart money."
                      )
                  )
                )
              ),
              fluidRow(
                valueBoxOutput("intro_box1", width = 3),
                valueBoxOutput("intro_box2", width = 3),
                valueBoxOutput("intro_box3", width = 3),
                valueBoxOutput("intro_box4", width = 3)
              ),
              fluidRow(
                box(
                  title = "Key Volume Profile Metrics",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "key-point", "• Point of Control (POC) - Price level with maximum volume"),
                  div(class = "key-point", "• Value Area (VA) - 68% of traded volume"),
                  div(class = "key-point", "• High Volume Node (HVN) - Areas of price acceptance"),
                  div(class = "key-point", "• Low Volume Node (LVN) - Areas of price rejection"),
                  div(class = "key-point", "• Initial Balance (IB) - First hour of trading range"),
                  div(class = "key-point", "• Single Prints - Areas of rapid price movement")
                ),
                box(
                  title = "What We Use Volume Profile For",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "key-point", "• Identify overall market sentiment"),
                  div(class = "key-point", "• Find consolidation price areas"),
                  div(class = "key-point", "• Locate support and resistance levels"),
                  div(class = "key-point", "• Determine entry, stop, and target prices"),
                  div(class = "key-point", "• Understand fair value areas"),
                  div(class = "key-point", "• Identify trend continuation or reversal")
                )
              )
      ),
      
      # Tab 2: Volume Profile Basics
      tabItem(tabName = "vp_basics",
              fluidRow(
                box(
                  title = "Understanding Volume Profile Components",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "The Auction Process"),
                      div(class = "concept-text",
                          "Financial markets move higher or lower due to an imbalance between aggressive buyers 
                          and sellers. When price discovers a level where buying and selling is balanced, we have 
                          found 'fair value' and trade can be facilitated. The market will establish a trading range 
                          at these levels."
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Sample Volume Profile Chart",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("vp_basic_chart", height = "600px"), color = "#008A82")
                ),
                box(
                  title = "Volume Profile Metrics",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  verbatimTextOutput("vp_metrics"),
                  hr(),
                  div(class = "concept-text",
                      strong("POC (Point of Control):"), " The price level with the highest traded volume.",
                      br(), br(),
                      strong("Value Area High (VAH):"), " Upper boundary of the 68% volume area.",
                      br(), br(),
                      strong("Value Area Low (VAL):"), " Lower boundary of the 68% volume area.",
                      br(), br(),
                      strong("Fair Value:"), " Price levels attracting the greatest volume (price acceptance)."
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Volume Distribution Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("vp_distribution_table")
                )
              )
      ),
      
      # Tab 3: VP Shapes
      tabItem(tabName = "vp_shapes",
              fluidRow(
                box(
                  title = "Volume Profile Shapes & Market Structure",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "Understanding Profile Shapes"),
                      div(class = "concept-text",
                          "The shape of the volume profile tells us about market participant behavior and 
                          provides clues about future price movement. Different shapes indicate different 
                          market conditions: balance, trending, or transitioning."
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Profile Shape Types",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  selectInput("shape_type", "Select Profile Shape:",
                              choices = c("Balanced (D-Shape)" = "balanced",
                                          "P-Shape (Bullish)" = "p_shape",
                                          "b-Shape (Bearish)" = "b_shape",
                                          "Double Distribution" = "double",
                                          "Thin Volume" = "thin"),
                              selected = "balanced"),
                  hr(),
                  uiOutput("shape_description")
                ),
                box(
                  title = "Volume Profile Shape Visualization",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("shape_chart", height = "500px"), color = "#008A82")
                )
              ),
              fluidRow(
                box(
                  title = "Shape Interpretation Guide",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  column(6,
                         div(class = "key-point",
                             strong("Balanced (D-Shape):"), " Sideways price action, balance between buyers/sellers. 
                             Institutions accumulate positions before trending moves."
                         ),
                         div(class = "key-point",
                             strong("P-Shape (Bullish):"), " Strong buyers pushing price higher, creating new value area at top. 
                             In uptrend = continuation; in downtrend = reversal signal."
                         ),
                         div(class = "key-point",
                             strong("b-Shape (Bearish):"), " Strong sellers pushing price lower, creating new value area at bottom. 
                             In downtrend = continuation; in uptrend = reversal signal."
                         )
                  ),
                  column(6,
                         div(class = "key-point",
                             strong("Double Distribution:"), " Shows a trend day with two distinct value areas. 
                             Price accumulates at one level before rapid move to establish new value."
                         ),
                         div(class = "key-point",
                             strong("Thin Volume:"), " Rapid aggressive move with little volume at specific prices. 
                             Speed of move prevents heavy trading. Often retraces to fill the 'cave'."
                         )
                  )
                )
              )
      ),
      
      # Tab 4: Low Volume Recovery
      tabItem(tabName = "lvr",
              fluidRow(
                box(
                  title = "Low Volume Nodes & Recovery Trading",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "What are Low Volume Nodes?"),
                      div(class = "concept-text",
                          "Low volume areas are created when price is imbalanced and moves quickly through a level, 
                          suggesting a lack of price acceptance. These areas can act as magnets, attracting price back 
                          to explore whether current traded price represents fair value."
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Low Volume Node Identification",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("lvn_chart", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "Trading Low Volume Recovery",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "concept-text",
                      strong("Poor Volume Area Above:"), br(),
                      "• Signals lack of sellers stepping in", br(),
                      "• Price comfortable trading at highs", br(),
                      "• Supports long positioning", br(), br(),
                      strong("Poor Volume Area Below:"), br(),
                      "• Signals lack of buyers stepping in", br(),
                      "• Price comfortable trading at lows", br(),
                      "• Supports short positioning", br(), br(),
                      strong("Entry Signal:"), br(),
                      "First candlestick close outside the range confirms direction"
                  ),
                  hr(),
                  div(class = "key-point",
                      strong("Remember:"), " Price often retraces back through thin areas to find fair value. 
                      The market wants to understand if current price is acceptable."
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Low Volume Recovery Examples",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  withSpinner(plotlyOutput("lvr_example_chart", height = "400px"), color = "#008A82")
                )
              )
      ),
      
      # Tab 5: POC & Value Area
      tabItem(tabName = "poc_va",
              fluidRow(
                box(
                  title = "Point of Control (POC) & Value Area (VA)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "Point of Control (POC)"),
                      div(class = "concept-text",
                          "The POC is the price level with maximum volume traded. Market operators view the POC as 
                          'fair' price - the right value of the financial product. High volume at this level indicates 
                          that most market operators believe it to be the correct, fair price."
                      )
                  ),
                  div(class = "concept-box",
                      div(class = "concept-title", "Value Area (VA)"),
                      div(class = "concept-text",
                          "The Value Area contains 68.2% of the volume traded in a session (one standard deviation). 
                          This is where buyers and sellers agreed on prices. The VA High (VAH) and VA Low (VAL) 
                          define the boundaries of this acceptance zone."
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "POC & Value Area Visualization",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("poc_va_chart", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "Value Area Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  valueBoxOutput("poc_value", width = 12),
                  valueBoxOutput("vah_value", width = 12),
                  valueBoxOutput("val_value", width = 12),
                  hr(),
                  div(class = "concept-text",
                      strong("Using POC:"), br(),
                      "• Acts as support/resistance", br(),
                      "• 'Naked' POCs are stronger", br(),
                      "• Multiple POCs at same level = strong S/R", br(), br(),
                      strong("Using Value Area:"), br(),
                      "• Trade back to value after extension", br(),
                      "• Breakout = potential trend", br(),
                      "• Open outside VA = directional day likely"
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Value Area Trading Scenarios",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  column(4,
                         div(class = "key-point",
                             strong("Scenario 1:"), " Market opens above previous VA → VAH tested → 
                             Breakout higher = trend continuation"
                         )
                  ),
                  column(4,
                         div(class = "key-point",
                             strong("Scenario 2:"), " Market opens below previous VA → VAL tested → 
                             Breakout lower = trend continuation"
                         )
                  ),
                  column(4,
                         div(class = "key-point",
                             strong("Scenario 3:"), " Market opens inside VA above POC → VAH tested → 
                             Break VAH = bullish; rejection = range trade"
                         )
                  )
                )
              )
      ),
      
      # Tab 6: Support & Resistance
      tabItem(tabName = "support",
              fluidRow(
                box(
                  title = "Volume Profile Support & Resistance",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "Volume-Based Support & Resistance"),
                      div(class = "concept-text",
                          "Volume Profile provides multiple types of support and resistance levels that are more 
                          reliable than traditional technical analysis because they're based on actual trading activity. 
                          The key is to look for confluence - multiple volume-based levels aligning."
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Support & Resistance Levels",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("support_chart", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "S/R Types from Volume Profile",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "key-point", "1. Low Volume Nodes (LVN)"),
                  div(class = "concept-text", "Price rejected these levels; acts as resistance when approaching from below"),
                  hr(),
                  div(class = "key-point", "2. High Volume Nodes (HVN)"),
                  div(class = "concept-text", "Price accepted these levels; acts as support/resistance and often acts as magnet"),
                  hr(),
                  div(class = "key-point", "3. Previous Session High/Low"),
                  div(class = "concept-text", "Key levels watched by all traders"),
                  hr(),
                  div(class = "key-point", "4. POC Levels"),
                  div(class = "concept-text", "Fair value levels; strong S/R"),
                  hr(),
                  div(class = "key-point", "5. Value Area Boundaries"),
                  div(class = "concept-text", "VAH and VAL act as S/R")
                )
              ),
              fluidRow(
                box(
                  title = "Confluence Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "The Power of Confluence"),
                      div(class = "concept-text",
                          "The strongest support and resistance levels occur when multiple volume-based indicators align. 
                          For example: POC + Previous Session Low + Low Volume Node = very strong support. 
                          Always look for 2-3 confirming factors before entering a trade."
                      )
                  ),
                  withSpinner(plotlyOutput("confluence_chart", height = "400px"), color = "#008A82")
                )
              )
      ),
      
      # Tab 7: Initial Balance
      tabItem(tabName = "initial_balance",
              fluidRow(
                box(
                  title = "Initial Balance (IB) Trading",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "What is Initial Balance?"),
                      div(class = "concept-text",
                          "Initial Balance is the price range established during the first hour of trading (first two 30-minute periods). 
                          It represents where early market participants believe value exists. The width of the IB provides clues about 
                          the likely market behavior for the rest of the session."
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Initial Balance Width Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "concept-box",
                      div(class = "concept-title", "Wide Initial Balance"),
                      div(class = "concept-text",
                          "Large price range in first hour suggests:", br(),
                          "• Required business completed early", br(),
                          "• Likely range-bound day ahead", br(),
                          "• D-shape profile probable", br(),
                          "• Trade inside the range"
                      )
                  ),
                  div(class = "concept-box",
                      div(class = "concept-title", "Narrow Initial Balance"),
                      div(class = "concept-text",
                          "Small price range in first hour suggests:", br(),
                          "• Business still to be conducted", br(),
                          "• Likely trending day ahead", br(),
                          "• P or b-shape profile probable", br(),
                          "• Trade the breakout"
                      )
                  )
                ),
                box(
                  title = "Initial Balance Chart",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("ib_chart", height = "500px"), color = "#008A82")
                )
              ),
              fluidRow(
                box(
                  title = "IB Breakout Trading Rules",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "key-point",
                      strong("Long Setup:"), br(),
                      "• Price breaks above IB high", br(),
                      "• Look for narrow IB", br(),
                      "• Confirm with excess at lows", br(),
                      "• Target: 2x IB range", br(),
                      "• Stop: Below IB low"
                  )
                ),
                box(
                  title = "IB Trading Statistics",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "key-point",
                      strong("Short Setup:"), br(),
                      "• Price breaks below IB low", br(),
                      "• Look for narrow IB", br(),
                      "• Confirm with excess at highs", br(),
                      "• Target: 2x IB range", br(),
                      "• Stop: Above IB high"
                  )
                )
              )
      ),
      
      # Tab 8: Market Profile
      tabItem(tabName = "market_profile",
              fluidRow(
                box(
                  title = "Market Profile - Time Price Opportunity (TPO)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "Understanding Market Profile"),
                      div(class = "concept-text",
                          "Market Profile tracks both price AND time, showing how market activity developed throughout the session. 
                          Each TPO (Time Price Opportunity) represents a 30-minute period where price traded at a specific level. 
                          The profile reveals where market participants agreed (high volume) and disagreed (low volume) on fair value."
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Market Profile Chart",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("mp_chart", height = "600px"), color = "#008A82")
                ),
                box(
                  title = "Market Profile Components",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "key-point", strong("TPO (Time Price Opportunity)"), br(),
                      "Each letter represents a 30-min period at a price level"),
                  hr(),
                  div(class = "key-point", strong("Value Area"), br(),
                      "68% of TPOs (not volume) - where price spent most time"),
                  hr(),
                  div(class = "key-point", strong("POC"), br(),
                      "Price with most TPOs"),
                  hr(),
                  div(class = "key-point", strong("Single Prints"), br(),
                      "Lone TPOs indicating rapid price movement"),
                  hr(),
                  div(class = "key-point", strong("Excess"), br(),
                      "Tails at extremes showing rejection"),
                  hr(),
                  div(class = "key-point", strong("Poor High/Low"), br(),
                      "Multiple TPOs at extreme = lack of opposition")
                )
              ),
              fluidRow(
                box(
                  title = "Market Profile Key Concepts",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      div(class = "concept-title", "Excess"),
                      div(class = "concept-text",
                          "• Appears at tops/bottoms of profile", br(),
                          "• Indicates shift in momentum", br(),
                          "• Excess at lows = buying pressure", br(),
                          "• Excess at highs = selling pressure", br(),
                          "• Long wick on 30-min candle", br(),
                          "• Best used with context (key levels)"
                      )
                  )
                ),
                box(
                  title = "Market Profile Key Concepts",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      div(class = "concept-title", "Poor High/Low"),
                      div(class = "concept-text",
                          "• 2+ TPOs at extreme of profile", br(),
                          "• Shows lack of opposing pressure", br(),
                          "• Poor high = confident buyers", br(),
                          "• Poor low = confident sellers", br(),
                          "• Often revisited by price", br(),
                          "• Use as targets or support/resistance"
                      )
                  )
                )
              )
      ),
      
      # Tab 9: Trading Strategies
      tabItem(tabName = "strategies",
              fluidRow(
                box(
                  title = "Volume Profile Trading Strategies",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "Developing Your Trading Bias"),
                      div(class = "concept-text",
                          "Volume Profile helps you structure and build a trading day with a clear bias. 
                          Based on overnight action, opening price relative to previous value, and profile shape, 
                          you determine whether you'll be buying dips or selling rallies."
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Strategy 1: Value Area Breakout",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-text",
                      strong("Setup:"), br(),
                      "• Price opens above/below previous day's VA", br(),
                      "• VAH/VAL is tested", br(),
                      "• Price breaks out in direction of open", br(), br(),
                      strong("Entry:"), " Break of VAH (long) or VAL (short)", br(),
                      strong("Stop:"), " Below VAL (long) or above VAH (short)", br(),
                      strong("Target:"), " Previous session high/low", br(), br(),
                      strong("Confirmation:"), br(),
                      "• Narrow IB", br(),
                      "• Excess supporting direction", br(),
                      "• Volume increasing on breakout"
                  )
                ),
                box(
                  title = "Strategy 2: Poor Volume Recovery",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-text",
                      strong("Setup:"), br(),
                      "• Identify poor volume area from previous session", br(),
                      "• Price moves away from poor area", br(),
                      "• Double distribution suggests fill", br(), br(),
                      strong("Entry:"), " First close back into poor area", br(),
                      strong("Stop:"), " Beyond opposite end of poor area", br(),
                      strong("Target:"), " Opposite fair value area", br(), br(),
                      strong("Confirmation:"), br(),
                      "• Poor area within 3-5 days", br(),
                      "• Price acceptance at entry", br(),
                      "• Supporting trend structure"
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Strategy 3: Ledge Trading",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-text",
                      strong("Setup:"), br(),
                      "• Identify ledge in Market Profile (2+ TPO step)", br(),
                      "• Note if price approaching from above/below", br(),
                      "• Watch for rejection or breakout", br(), br(),
                      strong("Option 1 - Breakout:"), br(),
                      "Entry: Break through ledge", br(),
                      "Stop: Other side of ledge", br(),
                      "Target: 2x ledge width", br(), br(),
                      strong("Option 2 - Rejection:"), br(),
                      "Entry: Reversal at ledge", br(),
                      "Stop: Beyond ledge", br(),
                      "Target: Opposite fair value"
                  )
                ),
                box(
                  title = "Strategy 4: Excess Scalping",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-text",
                      strong("Setup:"), br(),
                      "• Rapid price move creates small VA at extreme", br(),
                      "• Temporary P-shape (move up) or b-shape (move down)", br(),
                      "• Small volume area suggests non-acceptance", br(), br(),
                      strong("Entry:"), " Break of small VA boundary", br(),
                      strong("Stop:"), " Other side of small VA", br(),
                      strong("Target:"), " Previous accepted fair value", br(), br(),
                      strong("Risk:Reward:"), " Typically 1:3 or better", br(), br(),
                      strong("Key:"), " Small VA at extreme = opportunity to fade"
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Strategy Comparison Table",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("strategy_comparison")
                )
              )
      ),
      
      # Tab 10: Options Trading
      tabItem(tabName = "options",
              fluidRow(
                box(
                  title = "Options Trading Basics",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      div(class = "concept-title", "What are Options?"),
                      div(class = "concept-text",
                          "An option gives the buyer the RIGHT to buy (call) or sell (put) a specified quantity 
                          of an underlying asset at a fixed price (strike) on or before a specified future date (expiry). 
                          The seller has the OBLIGATION to deliver if the buyer exercises their right."
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Option Payoff Profiles",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  selectInput("option_type", "Select Option Strategy:",
                              choices = c("Long Call" = "long_call",
                                          "Long Put" = "long_put",
                                          "Short Call" = "short_call",
                                          "Short Put" = "short_put",
                                          "Bull Call Spread" = "bull_spread",
                                          "Bear Put Spread" = "bear_spread",
                                          "Long Straddle" = "straddle",
                                          "Long Strangle" = "strangle"),
                              selected = "long_call"),
                  withSpinner(plotlyOutput("option_payoff", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "Option Strategy Details",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  uiOutput("option_description"),
                  hr(),
                  div(class = "concept-text",
                      strong("Key Terminology:"), br(),
                      "• Premium: Price paid for option", br(),
                      "• Strike: Exercise price", br(),
                      "• Intrinsic Value: In-the-money amount", br(),
                      "• Time Value: Premium - Intrinsic", br(),
                      "• ITM: In the money", br(),
                      "• ATM: At the money", br(),
                      "• OTM: Out of the money"
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Option Trading Strategies",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "key-point",
                      strong("Directional Strategies:"), br(),
                      "• Long Call: Bullish", br(),
                      "• Long Put: Bearish", br(),
                      "• Bull Spread: Moderately bullish", br(),
                      "• Bear Spread: Moderately bearish"
                  )
                ),
                box(
                  title = "Option Greeks",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "key-point",
                      strong("Volatility Strategies:"), br(),
                      "• Straddle: Expect big move either direction", br(),
                      "• Strangle: Cheaper straddle, need bigger move", br(),
                      "• Risks: Time decay, no movement"
                  )
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Generate sample data
  market_data <- generate_market_data(180)
  intraday_data <- generate_intraday_data()
  
  # Calculate volume profile
  vp_result <- calculate_volume_profile(market_data, price_bins = 50)
  
  # Tab 1: Introduction - Value Boxes
  output$intro_box1 <- renderValueBox({
    valueBox(
      value = "68%",
      subtitle = "Value Area Coverage",
      icon = icon("chart-area"),
      color = "aqua"
    )
  })
  
  output$intro_box2 <- renderValueBox({
    valueBox(
      value = "POC",
      subtitle = "Point of Control",
      icon = icon("crosshairs"),
      color = "blue"
    )
  })
  
  output$intro_box3 <- renderValueBox({
    valueBox(
      value = "HVN/LVN",
      subtitle = "Volume Nodes",
      icon = icon("layer-group"),
      color = "green"
    )
  })
  
  output$intro_box4 <- renderValueBox({
    valueBox(
      value = "IB",
      subtitle = "Initial Balance",
      icon = icon("clock"),
      color = "yellow"
    )
  })
  
  # Tab 2: Volume Profile Basics
  output$vp_basic_chart <- renderPlotly({
    # Create candlestick chart with volume profile
    recent_data <- tail(market_data, 60)
    vp <- calculate_volume_profile(recent_data, price_bins = 30)
    
    fig <- plot_ly()
    
    # Candlestick
    fig <- fig %>% add_trace(
      data = recent_data,
      x = ~Timestamp,
      open = ~Open,
      high = ~High,
      low = ~Low,
      close = ~Close,
      type = "candlestick",
      name = "Price",
      increasing = list(line = list(color = "#00A39A")),
      decreasing = list(line = list(color = "#e74c3c"))
    )
    
    # Volume Profile on right side
    max_vol <- max(vp$volume_profile$volume)
    fig <- fig %>% add_trace(
      x = max(recent_data$Timestamp) + vp$volume_profile$volume / max_vol * 5 * 24 * 3600,
      y = vp$volume_profile$price_level,
      type = "scatter",
      mode = "lines",
      fill = "tozerox",
      fillcolor = "rgba(0, 163, 154, 0.3)",
      line = list(color = "#008A82", width = 2),
      name = "Volume Profile"
    )
    
    # Add POC line
    fig <- fig %>% add_trace(
      x = c(min(recent_data$Timestamp), max(recent_data$Timestamp)),
      y = c(vp$poc, vp$poc),
      type = "scatter",
      mode = "lines",
      line = list(color = "#002C3C", width = 2, dash = "dash"),
      name = "POC"
    )
    
    # Add VA boundaries
    fig <- fig %>% add_trace(
      x = c(min(recent_data$Timestamp), max(recent_data$Timestamp)),
      y = c(vp$vah, vp$vah),
      type = "scatter",
      mode = "lines",
      line = list(color = "#f39c12", width = 1, dash = "dot"),
      name = "VAH"
    ) %>% add_trace(
      x = c(min(recent_data$Timestamp), max(recent_data$Timestamp)),
      y = c(vp$val, vp$val),
      type = "scatter",
      mode = "lines",
      line = list(color = "#f39c12", width = 1, dash = "dot"),
      name = "VAL"
    )
    
    fig <- fig %>% layout(
      title = "Price Chart with Volume Profile",
      xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white",
      paper_bgcolor = "white",
      hovermode = "x unified"
    )
    
    fig
  })
  
  output$vp_metrics <- renderText({
    recent_data <- tail(market_data, 60)
    vp <- calculate_volume_profile(recent_data, price_bins = 30)
    
    paste(
      "Volume Profile Metrics:\n\n",
      sprintf("POC: %.2f\n", vp$poc),
      sprintf("Value Area High: %.2f\n", vp$vah),
      sprintf("Value Area Low: %.2f\n", vp$val),
      sprintf("Value Area Range: %.2f\n", vp$vah - vp$val),
      sprintf("\nTotal Volume: %d\n", sum(recent_data$Volume)),
      sprintf("Volume in VA: %d (68%%)\n", sum(recent_data$Volume) * 0.68)
    )
  })
  
  output$vp_distribution_table <- DT::renderDataTable({
    recent_data <- tail(market_data, 60)
    vp <- calculate_volume_profile(recent_data, price_bins = 20)
    
    df <- vp$volume_profile %>%
      mutate(
        price_level = round(price_level, 2),
        volume = round(volume, 0),
        pct_total = round(volume / sum(volume) * 100, 2),
        in_value_area = ifelse(price_level >= vp$val & price_level <= vp$vah, "Yes", "No"),
        is_poc = ifelse(abs(price_level - vp$poc) < 0.5, "POC", "")
      ) %>%
      arrange(desc(volume)) %>%
      select(Price = price_level, Volume = volume, `% of Total` = pct_total, 
             `In VA` = in_value_area, Note = is_poc)
    
    datatable(df, 
              options = list(pageLength = 10, dom = 'tip'),
              rownames = FALSE) %>%
      formatStyle('In VA', 
                  backgroundColor = styleEqual(c("Yes", "No"), 
                                               c("#d4edda", "#f8d7da")))
  })
  
  # Tab 3: VP Shapes
  output$shape_description <- renderUI({
    description <- switch(input$shape_type,
                          "balanced" = div(
                            class = "concept-text",
                            strong("Balanced (D-Shape):"), br(), br(),
                            "Characteristics:", br(),
                            "• Sideways price action", br(),
                            "• Balance between buyers and sellers", br(),
                            "• Accumulation of positions", br(),
                            "• Bell-shaped volume profile", br(), br(),
                            "Interpretation:", br(),
                            "Institutions accumulating positions before initiating a trending move. 
                            Trade the eventual breakout in either direction."
                          ),
                          "p_shape" = div(
                            class = "concept-text",
                            strong("P-Shape (Bullish):"), br(), br(),
                            "Characteristics:", br(),
                            "• Volume concentrated at top", br(),
                            "• Price pushed higher during session", br(),
                            "• New area of balance created high", br(), br(),
                            "Interpretation:", br(),
                            "Strong buyers in control. In uptrend = continuation signal. 
                            In downtrend = potential reversal or pause."
                          ),
                          "b_shape" = div(
                            class = "concept-text",
                            strong("b-Shape (Bearish):"), br(), br(),
                            "Characteristics:", br(),
                            "• Volume concentrated at bottom", br(),
                            "• Price pushed lower during session", br(),
                            "• New area of balance created low", br(), br(),
                            "Interpretation:", br(),
                            "Strong sellers in control. In downtrend = continuation signal. 
                            In uptrend = potential reversal or pause."
                          ),
                          "double" = div(
                            class = "concept-text",
                            strong("Double Distribution:"), br(), br(),
                            "Characteristics:", br(),
                            "• Two distinct volume areas", br(),
                            "• Thin volume between areas", br(),
                            "• Shows trend day development", br(), br(),
                            "Interpretation:", br(),
                            "Price accumulated at one level before rapid move to new level. 
                            Thin area (cave) often gets filled later."
                          ),
                          "thin" = div(
                            class = "concept-text",
                            strong("Thin Volume:"), br(), br(),
                            "Characteristics:", br(),
                            "• Very little volume at specific prices", br(),
                            "• Rapid, aggressive move", br(),
                            "• Speed prevents heavy trading", br(), br(),
                            "Interpretation:", br(),
                            "Market moved too fast through area. Price often returns 
                            to fill the 'cave' and establish fair value."
                          )
    )
    description
  })
  
  output$shape_chart <- renderPlotly({
    # Generate data based on selected shape
    dates <- seq(Sys.Date() - 1, Sys.Date(), by = "hour")[1:14]
    
    shape_data <- switch(input$shape_type,
                         "balanced" = data.frame(
                           Timestamp = dates,
                           Open = 100 + rnorm(14, 0, 1),
                           High = 100 + rnorm(14, 0, 1) + 0.5,
                           Low = 100 + rnorm(14, 0, 1) - 0.5,
                           Close = 100 + rnorm(14, 0, 1),
                           Volume = 300 + rnorm(14, 0, 50)
                         ),
                         "p_shape" = data.frame(
                           Timestamp = dates,
                           Open = 100 + (1:14) * 0.3 + rnorm(14, 0, 0.5),
                           High = 100 + (1:14) * 0.3 + rnorm(14, 0, 0.5) + 0.5,
                           Low = 100 + (1:14) * 0.3 + rnorm(14, 0, 0.5) - 0.5,
                           Close = 100 + (1:14) * 0.3 + rnorm(14, 0, 0.5),
                           Volume = c(rep(200, 7), rep(400, 7))
                         ),
                         "b_shape" = data.frame(
                           Timestamp = dates,
                           Open = 105 - (1:14) * 0.3 + rnorm(14, 0, 0.5),
                           High = 105 - (1:14) * 0.3 + rnorm(14, 0, 0.5) + 0.5,
                           Low = 105 - (1:14) * 0.3 + rnorm(14, 0, 0.5) - 0.5,
                           Close = 105 - (1:14) * 0.3 + rnorm(14, 0, 0.5),
                           Volume = c(rep(400, 7), rep(200, 7))
                         ),
                         "double" = data.frame(
                           Timestamp = dates,
                           Open = c(rep(98, 4), 98:103, rep(103, 4)) + rnorm(14, 0, 0.3),
                           High = c(rep(98, 4), 98:103, rep(103, 4)) + rnorm(14, 0, 0.3) + 0.5,
                           Low = c(rep(98, 4), 98:103, rep(103, 4)) + rnorm(14, 0, 0.3) - 0.5,
                           Close = c(rep(98, 4), 98:103, rep(103, 4)) + rnorm(14, 0, 0.3),
                           Volume = c(rep(400, 4), rep(100, 6), rep(400, 4))
                         ),
                         "thin" = data.frame(
                           Timestamp = dates,
                           Open = c(rep(98, 3), 98:107, rep(107, 2)) + rnorm(14, 0, 0.2),
                           High = c(rep(98, 3), 98:107, rep(107, 2)) + rnorm(14, 0, 0.2) + 0.3,
                           Low = c(rep(98, 3), 98:107, rep(107, 2)) + rnorm(14, 0, 0.2) - 0.3,
                           Close = c(rep(98, 3), 98:107, rep(107, 2)) + rnorm(14, 0, 0.2),
                           Volume = c(rep(300, 3), rep(50, 10), rep(300, 1))
                         )
    )
    
    vp <- calculate_volume_profile(shape_data, price_bins = 20)
    
    fig <- plot_ly()
    
    # Candlestick
    fig <- fig %>% add_trace(
      data = shape_data,
      x = ~Timestamp,
      open = ~Open,
      high = ~High,
      low = ~Low,
      close = ~Close,
      type = "candlestick",
      name = "Price",
      increasing = list(line = list(color = "#00A39A")),
      decreasing = list(line = list(color = "#e74c3c"))
    )
    
    # Volume Profile
    max_vol <- max(vp$volume_profile$volume)
    fig <- fig %>% add_trace(
      x = max(shape_data$Timestamp) + vp$volume_profile$volume / max_vol * 3 * 3600,
      y = vp$volume_profile$price_level,
      type = "scatter",
      mode = "lines",
      fill = "tozerox",
      fillcolor = "rgba(0, 163, 154, 0.3)",
      line = list(color = "#008A82", width = 2),
      name = "Volume Profile"
    )
    
    fig <- fig %>% layout(
      title = paste(input$shape_type, "Profile Shape"),
      xaxis = list(title = "Time", rangeslider = list(visible = FALSE)),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
    
    fig
  })
  
  # Tab 4: Low Volume Recovery
  output$lvn_chart <- renderPlotly({
    # Create data with low volume node
    dates <- seq(Sys.Date() - 2, Sys.Date(), by = "hour")[1:48]
    
    lvn_data <- data.frame(
      Timestamp = dates,
      Open = c(rep(100, 12), 100:108, rep(108, 27)) + rnorm(48, 0, 0.3),
      High = c(rep(100, 12), 100:108, rep(108, 27)) + rnorm(48, 0, 0.3) + 0.5,
      Low = c(rep(100, 12), 100:108, rep(108, 27)) + rnorm(48, 0, 0.3) - 0.5,
      Close = c(rep(100, 12), 100:108, rep(108, 27)) + rnorm(48, 0, 0.3),
      Volume = c(rep(400, 12), rep(80, 9), rep(450, 27))
    )
    
    vp <- calculate_volume_profile(lvn_data, price_bins = 30)
    
    fig <- plot_ly()
    
    # Candlestick
    fig <- fig %>% add_trace(
      data = lvn_data,
      x = ~Timestamp,
      open = ~Open,
      high = ~High,
      low = ~Low,
      close = ~Close,
      type = "candlestick",
      name = "Price",
      increasing = list(line = list(color = "#00A39A")),
      decreasing = list(line = list(color = "#e74c3c"))
    )
    
    # Volume Profile
    max_vol <- max(vp$volume_profile$volume)
    fig <- fig %>% add_trace(
      x = max(lvn_data$Timestamp) + vp$volume_profile$volume / max_vol * 5 * 3600,
      y = vp$volume_profile$price_level,
      type = "scatter",
      mode = "lines",
      fill = "tozerox",
      fillcolor = "rgba(0, 163, 154, 0.3)",
      line = list(color = "#008A82", width = 2),
      name = "Volume Profile"
    )
    
    # Highlight low volume node
    lvn_prices <- vp$volume_profile %>%
      filter(volume < quantile(volume, 0.3)) %>%
      filter(price_level > 101 & price_level < 107)
    
    fig <- fig %>% add_trace(
      x = c(min(lvn_data$Timestamp), max(lvn_data$Timestamp)),
      y = c(min(lvn_prices$price_level), min(lvn_prices$price_level)),
      type = "scatter",
      mode = "lines",
      line = list(color = "#e74c3c", width = 2, dash = "dash"),
      name = "LVN Start"
    ) %>% add_trace(
      x = c(min(lvn_data$Timestamp), max(lvn_data$Timestamp)),
      y = c(max(lvn_prices$price_level), max(lvn_prices$price_level)),
      type = "scatter",
      mode = "lines",
      line = list(color = "#e74c3c", width = 2, dash = "dash"),
      name = "LVN End"
    )
    
    fig <- fig %>% layout(
      title = "Low Volume Node Example",
      xaxis = list(title = "Time", rangeslider = list(visible = FALSE)),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white",
      paper_bgcolor = "white",
      annotations = list(
        list(
          x = median(lvn_data$Timestamp),
          y = mean(c(min(lvn_prices$price_level), max(lvn_prices$price_level))),
          text = "Low Volume<br>Node",
          showarrow = TRUE,
          arrowhead = 2,
          arrowcolor = "#e74c3c",
          ax = 40,
          ay = -40
        )
      )
    )
    
    fig
  })
  
  output$lvr_example_chart <- renderPlotly({
    # Show price returning to fill LVN
    dates <- seq(Sys.Date() - 3, Sys.Date(), by = "hour")[1:72]
    
    recovery_data <- data.frame(
      Timestamp = dates,
      Price = c(rep(100, 12), 100:108, rep(108, 24), 108:104, rep(104, 20)) + rnorm(72, 0, 0.2)
    )
    
    fig <- plot_ly(recovery_data, x = ~Timestamp, y = ~Price, 
                   type = "scatter", mode = "lines",
                   line = list(color = "#008A82", width = 2),
                   name = "Price")
    
    # Highlight the recovery into LVN
    fig <- fig %>% add_trace(
      x = c(dates[48], dates[60]),
      y = c(108, 104),
      type = "scatter",
      mode = "lines",
      line = list(color = "#e74c3c", width = 3),
      name = "Recovery into LVN"
    )
    
    # Add shaded LVN region
    fig <- fig %>% add_trace(
      x = c(min(dates), max(dates), max(dates), min(dates)),
      y = c(101, 101, 107, 107),
      type = "scatter",
      mode = "lines",
      fill = "toself",
      fillcolor = "rgba(231, 76, 60, 0.2)",
      line = list(color = "rgba(231, 76, 60, 0.5)"),
      name = "Low Volume Area"
    )
    
    fig <- fig %>% layout(
      title = "Price Recovery into Low Volume Node",
      xaxis = list(title = "Time"),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white",
      paper_bgcolor = "white",
      annotations = list(
        list(
          x = dates[54],
          y = 106,
          text = "Price returns<br>to fill LVN",
          showarrow = TRUE,
          arrowhead = 2,
          arrowcolor = "#e74c3c"
        )
      )
    )
    
    fig
  })
  
  # Tab 5: POC & Value Area
  output$poc_va_chart <- renderPlotly({
    recent_data <- tail(market_data, 60)
    vp <- calculate_volume_profile(recent_data, price_bins = 30)
    
    fig <- plot_ly()
    
    # Candlestick
    fig <- fig %>% add_trace(
      data = recent_data,
      x = ~Timestamp,
      open = ~Open,
      high = ~High,
      low = ~Low,
      close = ~Close,
      type = "candlestick",
      name = "Price",
      increasing = list(line = list(color = "#00A39A")),
      decreasing = list(line = list(color = "#e74c3c"))
    )
    
    # Volume Profile
    max_vol <- max(vp$volume_profile$volume)
    fig <- fig %>% add_trace(
      x = max(recent_data$Timestamp) + vp$volume_profile$volume / max_vol * 5 * 24 * 3600,
      y = vp$volume_profile$price_level,
      type = "scatter",
      mode = "lines",
      fill = "tozerox",
      fillcolor = "rgba(0, 163, 154, 0.3)",
      line = list(color = "#008A82", width = 2),
      name = "Volume Profile"
    )
    
    # Highlight Value Area
    fig <- fig %>% add_shape(
      type = "rect",
      x0 = min(recent_data$Timestamp),
      x1 = max(recent_data$Timestamp),
      y0 = vp$val,
      y1 = vp$vah,
      fillcolor = "rgba(243, 156, 18, 0.2)",
      line = list(color = "rgba(243, 156, 18, 0.5)", width = 2),
      layer = "below"
    )
    
    # POC line
    fig <- fig %>% add_trace(
      x = c(min(recent_data$Timestamp), max(recent_data$Timestamp)),
      y = c(vp$poc, vp$poc),
      type = "scatter",
      mode = "lines",
      line = list(color = "#002C3C", width = 3),
      name = "POC"
    )
    
    # VAH line
    fig <- fig %>% add_trace(
      x = c(min(recent_data$Timestamp), max(recent_data$Timestamp)),
      y = c(vp$vah, vp$vah),
      type = "scatter",
      mode = "lines",
      line = list(color = "#f39c12", width = 2, dash = "dash"),
      name = "VAH"
    )
    
    # VAL line
    fig <- fig %>% add_trace(
      x = c(min(recent_data$Timestamp), max(recent_data$Timestamp)),
      y = c(vp$val, vp$val),
      type = "scatter",
      mode = "lines",
      line = list(color = "#f39c12", width = 2, dash = "dash"),
      name = "VAL"
    )
    
    fig <- fig %>% layout(
      title = "POC and Value Area Visualization",
      xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white",
      paper_bgcolor = "white",
      annotations = list(
        list(
          x = median(recent_data$Timestamp),
          y = (vp$vah + vp$val) / 2,
          text = "Value Area<br>(68% of Volume)",
          showarrow = FALSE,
          font = list(size = 12, color = "#f39c12")
        )
      )
    )
    
    fig
  })
  
  output$poc_value <- renderValueBox({
    recent_data <- tail(market_data, 60)
    vp <- calculate_volume_profile(recent_data, price_bins = 30)
    
    valueBox(
      value = sprintf("%.2f", vp$poc),
      subtitle = "Point of Control (POC)",
      icon = icon("crosshairs"),
      color = "blue"
    )
  })
  
  output$vah_value <- renderValueBox({
    recent_data <- tail(market_data, 60)
    vp <- calculate_volume_profile(recent_data, price_bins = 30)
    
    valueBox(
      value = sprintf("%.2f", vp$vah),
      subtitle = "Value Area High (VAH)",
      icon = icon("arrow-up"),
      color = "yellow"
    )
  })
  
  output$val_value <- renderValueBox({
    recent_data <- tail(market_data, 60)
    vp <- calculate_volume_profile(recent_data, price_bins = 30)
    
    valueBox(
      value = sprintf("%.2f", vp$val),
      subtitle = "Value Area Low (VAL)",
      icon = icon("arrow-down"),
      color = "yellow"
    )
  })
  
  # Tab 6: Support & Resistance
  output$support_chart <- renderPlotly({
    recent_data <- tail(market_data, 90)
    vp <- calculate_volume_profile(recent_data, price_bins = 30)
    
    # Find HVN and LVN
    threshold_high <- quantile(vp$volume_profile$volume, 0.75)
    threshold_low <- quantile(vp$volume_profile$volume, 0.25)
    
    hvn_levels <- vp$volume_profile %>% 
      filter(volume > threshold_high) %>% 
      pull(price_level)
    
    lvn_levels <- vp$volume_profile %>% 
      filter(volume < threshold_low) %>% 
      pull(price_level)
    
    fig <- plot_ly()
    
    # Candlestick
    fig <- fig %>% add_trace(
      data = recent_data,
      x = ~Timestamp,
      open = ~Open,
      high = ~High,
      low = ~Low,
      close = ~Close,
      type = "candlestick",
      name = "Price",
      increasing = list(line = list(color = "#00A39A")),
      decreasing = list(line = list(color = "#e74c3c"))
    )
    
    # Add HVN levels (support)
    for (level in hvn_levels[1:3]) {
      fig <- fig %>% add_trace(
        x = c(min(recent_data$Timestamp), max(recent_data$Timestamp)),
        y = c(level, level),
        type = "scatter",
        mode = "lines",
        line = list(color = "#27ae60", width = 2, dash = "dot"),
        showlegend = FALSE,
        hoverinfo = "text",
        text = paste("HVN Support:", round(level, 2))
      )
    }
    
    # Add LVN levels (resistance)
    for (level in lvn_levels[1:3]) {
      fig <- fig %>% add_trace(
        x = c(min(recent_data$Timestamp), max(recent_data$Timestamp)),
        y = c(level, level),
        type = "scatter",
        mode = "lines",
        line = list(color = "#e74c3c", width = 2, dash = "dot"),
        showlegend = FALSE,
        hoverinfo = "text",
        text = paste("LVN Resistance:", round(level, 2))
      )
    }
    
    # POC
    fig <- fig %>% add_trace(
      x = c(min(recent_data$Timestamp), max(recent_data$Timestamp)),
      y = c(vp$poc, vp$poc),
      type = "scatter",
      mode = "lines",
      line = list(color = "#002C3C", width = 3),
      name = "POC"
    )
    
    fig <- fig %>% layout(
      title = "Support & Resistance from Volume Profile",
      xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
    
    fig
  })
  
  output$confluence_chart <- renderPlotly({
    # Show example of confluence
    dates <- seq(Sys.Date() - 30, Sys.Date(), by = "day")
    
    confluence_data <- data.frame(
      Timestamp = dates,
      Price = 100 + cumsum(rnorm(31, 0, 1))
    )
    
    fig <- plot_ly(confluence_data, x = ~Timestamp, y = ~Price,
                   type = "scatter", mode = "lines",
                   line = list(color = "#008A82", width = 2),
                   name = "Price")
    
    # Add confluence zone
    confluence_price <- 102
    fig <- fig %>% add_shape(
      type = "rect",
      x0 = min(dates),
      x1 = max(dates),
      y0 = confluence_price - 0.5,
      y1 = confluence_price + 0.5,
      fillcolor = "rgba(231, 76, 60, 0.3)",
      line = list(color = "rgba(231, 76, 60, 0.7)", width = 2)
    )
    
    fig <- fig %>% layout(
      title = "Confluence Example: POC + Session Low + LVN",
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white",
      paper_bgcolor = "white",
      annotations = list(
        list(
          x = median(dates),
          y = confluence_price,
          text = "Strong Support<br>Confluence Zone",
          showarrow = TRUE,
          arrowhead = 2,
          arrowcolor = "#e74c3c"
        )
      )
    )
    
    fig
  })
  
  # Tab 7: Initial Balance
  output$ib_chart <- renderPlotly({
    # Generate intraday data
    times <- seq(
      as.POSIXct(paste(Sys.Date(), "09:00:00")),
      as.POSIXct(paste(Sys.Date(), "16:00:00")),
      by = "30 min"
    )
    
    ib_data <- data.frame(
      Timestamp = times
    ) %>%
      mutate(
        period = row_number(),
        Price = 100 + cumsum(rnorm(n(), 0, 0.3)),
        High = Price + abs(rnorm(n(), 0.2, 0.1)),
        Low = Price - abs(rnorm(n(), 0.2, 0.1))
      )
    
    # Initial Balance (first 2 periods = first hour)
    ib_high <- max(ib_data$High[1:2])
    ib_low <- min(ib_data$Low[1:2])
    
    fig <- plot_ly(ib_data, x = ~Timestamp, y = ~Price,
                   type = "scatter", mode = "lines",
                   line = list(color = "#008A82", width = 2),
                   name = "Price")
    
    # Add high/low range
    fig <- fig %>% add_ribbons(
      x = ~Timestamp,
      ymin = ~Low,
      ymax = ~High,
      fillcolor = "rgba(0, 138, 130, 0.2)",
      line = list(color = "transparent"),
      name = "Price Range"
    )
    
    # Highlight Initial Balance
    fig <- fig %>% add_shape(
      type = "rect",
      x0 = times[1],
      x1 = times[2],
      y0 = ib_low,
      y1 = ib_high,
      fillcolor = "rgba(243, 156, 18, 0.4)",
      line = list(color = "#f39c12", width = 2)
    )
    
    # IB High line
    fig <- fig %>% add_trace(
      x = c(times[1], times[length(times)]),
      y = c(ib_high, ib_high),
      type = "scatter",
      mode = "lines",
      line = list(color = "#f39c12", width = 2, dash = "dash"),
      name = "IB High"
    )
    
    # IB Low line
    fig <- fig %>% add_trace(
      x = c(times[1], times[length(times)]),
      y = c(ib_low, ib_low),
      type = "scatter",
      mode = "lines",
      line = list(color = "#f39c12", width = 2, dash = "dash"),
      name = "IB Low"
    )
    
    fig <- fig %>% layout(
      title = sprintf("Initial Balance: %.2f (Width: %.2f)", (ib_high + ib_low) / 2, ib_high - ib_low),
      xaxis = list(title = "Time"),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white",
      paper_bgcolor = "white",
      annotations = list(
        list(
          x = times[1],
          y = (ib_high + ib_low) / 2,
          text = "Initial<br>Balance",
          showarrow = FALSE,
          xanchor = "left",
          font = list(size = 12, color = "#f39c12")
        )
      )
    )
    
    fig
  })
  
  # Tab 8: Market Profile
  output$mp_chart <- renderPlotly({
    # Generate Market Profile data
    times <- seq(
      as.POSIXct(paste(Sys.Date(), "09:00:00")),
      as.POSIXct(paste(Sys.Date(), "16:00:00")),
      by = "30 min"
    )
    
    mp_data <- data.frame(
      Timestamp = times,
      Period = 1:length(times),
      TPO = LETTERS[ceiling((1:length(times)) / 2)]
    ) %>%
      mutate(
        Price = 100 + cumsum(rnorm(n(), 0, 0.3))
      )
    
    # Create TPO chart (simplified)
    price_levels <- seq(floor(min(mp_data$Price)), ceiling(max(mp_data$Price)), by = 0.5)
    
    tpo_counts <- data.frame(
      price = price_levels
    ) %>%
      mutate(
        count = sapply(price, function(p) {
          sum(abs(mp_data$Price - p) < 0.25)
        })
      )
    
    fig <- plot_ly()
    
    # Price line
    fig <- fig %>% add_trace(
      data = mp_data,
      x = ~Timestamp,
      y = ~Price,
      type = "scatter",
      mode = "lines+markers",
      line = list(color = "#008A82", width = 2),
      marker = list(size = 8),
      name = "Price"
    )
    
    # TPO histogram on right
    fig <- fig %>% add_trace(
      x = max(mp_data$Timestamp) + tpo_counts$count * 1800,
      y = tpo_counts$price,
      type = "scatter",
      mode = "lines",
      fill = "tozerox",
      fillcolor = "rgba(0, 163, 154, 0.3)",
      line = list(color = "#008A82", width = 2),
      name = "TPO Count"
    )
    
    fig <- fig %>% layout(
      title = "Market Profile (TPO Chart)",
      xaxis = list(title = "Time"),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
    
    fig
  })
  
  # Tab 9: Trading Strategies
  output$strategy_comparison <- DT::renderDataTable({
    strategies <- data.frame(
      Strategy = c("VA Breakout", "Poor Volume Recovery", "Ledge Trading", "Excess Scalping"),
      `Win Rate` = c("65%", "70%", "60%", "55%"),
      `Risk:Reward` = c("1:2", "1:3", "1:2", "1:3"),
      `Best Market` = c("Trending", "Range", "Either", "Range"),
      `Time Horizon` = c("Intraday", "1-3 days", "Intraday", "Scalp"),
      Difficulty = c("Medium", "Medium", "Hard", "Medium")
    )
    
    datatable(strategies,
              options = list(dom = 't', pageLength = 10),
              rownames = FALSE) %>%
      formatStyle('Win Rate',
                  backgroundColor = styleInterval(c(60, 65, 70), 
                                                  c("#f8d7da", "#fff3cd", "#d4edda", "#c3e6cb")))
  })
  
  # Tab 10: Options Trading
  output$option_description <- renderUI({
    description <- switch(input$option_type,
                          "long_call" = div(
                            class = "concept-text",
                            strong("Long Call"), br(), br(),
                            "Strategy: Bullish", br(), br(),
                            "Max Loss: Premium paid", br(),
                            "Max Gain: Unlimited", br(),
                            "Breakeven: Strike + Premium", br(), br(),
                            "Use when you expect price to rise significantly."
                          ),
                          "long_put" = div(
                            class = "concept-text",
                            strong("Long Put"), br(), br(),
                            "Strategy: Bearish", br(), br(),
                            "Max Loss: Premium paid", br(),
                            "Max Gain: Strike - Premium", br(),
                            "Breakeven: Strike - Premium", br(), br(),
                            "Use when you expect price to fall significantly."
                          ),
                          "short_call" = div(
                            class = "concept-text",
                            strong("Short Call"), br(), br(),
                            "Strategy: Bearish/Neutral", br(), br(),
                            "Max Loss: Unlimited", br(),
                            "Max Gain: Premium received", br(),
                            "Breakeven: Strike + Premium", br(), br(),
                            "High risk - only for experienced traders."
                          ),
                          "short_put" = div(
                            class = "concept-text",
                            strong("Short Put"), br(), br(),
                            "Strategy: Bullish/Neutral", br(), br(),
                            "Max Loss: Strike - Premium", br(),
                            "Max Gain: Premium received", br(),
                            "Breakeven: Strike - Premium", br(), br(),
                            "Obligation to buy if exercised."
                          ),
                          "bull_spread" = div(
                            class = "concept-text",
                            strong("Bull Call Spread"), br(), br(),
                            "Strategy: Moderately Bullish", br(), br(),
                            "Buy lower strike call", br(),
                            "Sell higher strike call", br(), br(),
                            "Max Loss: Net premium", br(),
                            "Max Gain: (Strikes difference) - Premium", br(), br(),
                            "Lower cost than long call, but capped gains."
                          ),
                          "bear_spread" = div(
                            class = "concept-text",
                            strong("Bear Put Spread"), br(), br(),
                            "Strategy: Moderately Bearish", br(), br(),
                            "Buy higher strike put", br(),
                            "Sell lower strike put", br(), br(),
                            "Max Loss: Net premium", br(),
                            "Max Gain: (Strikes difference) - Premium", br(), br(),
                            "Lower cost than long put, but capped gains."
                          ),
                          "straddle" = div(
                            class = "concept-text",
                            strong("Long Straddle"), br(), br(),
                            "Strategy: Expect volatility", br(), br(),
                            "Buy ATM call + ATM put", br(),
                            "Same strike price", br(), br(),
                            "Max Loss: Total premium", br(),
                            "Max Gain: Unlimited", br(), br(),
                            "Profit if price moves significantly either direction."
                          ),
                          "strangle" = div(
                            class = "concept-text",
                            strong("Long Strangle"), br(), br(),
                            "Strategy: Expect volatility", br(), br(),
                            "Buy OTM call + OTM put", br(),
                            "Different strikes", br(), br(),
                            "Max Loss: Total premium", br(),
                            "Max Gain: Unlimited", br(), br(),
                            "Cheaper than straddle, needs bigger move."
                          )
    )
    description
  })
  
  output$option_payoff <- renderPlotly({
    # Generate option payoff diagram
    spot <- 100
    strike1 <- 100
    strike2 <- 105
    premium1 <- 5
    premium2 <- 3
    
    prices <- seq(85, 115, by = 0.5)
    
    payoff <- switch(input$option_type,
                     "long_call" = pmax(prices - strike1, 0) - premium1,
                     "long_put" = pmax(strike1 - prices, 0) - premium1,
                     "short_call" = premium1 - pmax(prices - strike1, 0),
                     "short_put" = premium1 - pmax(strike1 - prices, 0),
                     "bull_spread" = pmax(prices - strike1, 0) - pmax(prices - strike2, 0) - (premium1 - premium2),
                     "bear_spread" = pmax(strike2 - prices, 0) - pmax(strike1 - prices, 0) - (premium1 - premium2),
                     "straddle" = pmax(prices - strike1, 0) + pmax(strike1 - prices, 0) - (premium1 + premium1),
                     "strangle" = pmax(prices - strike2, 0) + pmax((strike1 - 5) - prices, 0) - (premium2 + premium2)
    )
    
    payoff_data <- data.frame(
      Price = prices,
      Payoff = payoff
    )
    
    fig <- plot_ly(payoff_data, x = ~Price, y = ~Payoff,
                   type = "scatter", mode = "lines",
                   line = list(color = "#008A82", width = 3),
                   fill = "tozeroy",
                   fillcolor = ifelse(payoff_data$Payoff > 0,
                                      "rgba(39, 174, 96, 0.3)",
                                      "rgba(231, 76, 60, 0.3)"),
                   name = "Payoff")
    
    # Add zero line
    fig <- fig %>% add_trace(
      x = c(min(prices), max(prices)),
      y = c(0, 0),
      type = "scatter",
      mode = "lines",
      line = list(color = "#2c3e50", width = 1, dash = "dash"),
      showlegend = FALSE
    )
    
    # Add current spot line
    fig <- fig %>% add_trace(
      x = c(spot, spot),
      y = c(min(payoff), max(payoff)),
      type = "scatter",
      mode = "lines",
      line = list(color = "#f39c12", width = 2, dash = "dot"),
      name = "Current Spot"
    )
    
    fig <- fig %>% layout(
      title = paste(input$option_type, "Payoff Diagram"),
      xaxis = list(title = "Underlying Price at Expiry"),
      yaxis = list(title = "Profit/Loss"),
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
    
    fig
  })
}

# Run the application
shinyApp(ui = ui, server = server)