# Trading Strategies Dashboard - Based on Week 5 Lectures
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
library(quantmod)
library(zoo)

# Sample data generation function
generate_sample_data <- function(days = 180) {
  dates <- seq(Sys.Date() - days, Sys.Date(), by = "day")
  
  # Generate realistic price data with trends
  base_price <- 1.10
  trend <- cumsum(rnorm(length(dates), 0, 0.002))
  noise <- rnorm(length(dates), 0, 0.001)
  
  data <- data.frame(
    date = dates,
    Timestamp = as.POSIXct(paste(dates, "12:00:00")),
    Mid = base_price + trend + noise
  ) %>%
    mutate(
      Bid = Mid * 0.9995,
      Ask = Mid * 1.0005,
      High = Mid * (1 + abs(rnorm(n(), 0, 0.002))),
      Low = Mid * (1 - abs(rnorm(n(), 0, 0.002))),
      Close = Mid,
      Volume = abs(rnorm(n(), 10000, 3000))
    )
  
  return(data)
}

# Generate intraday data for straddle strategy
generate_intraday_data <- function() {
  hours <- seq(from = as.POSIXct("2024-01-15 17:00:00"), 
               to = as.POSIXct("2024-01-16 16:00:00"), 
               by = "hour")
  
  # Simulate overnight consolidation then breakout
  n <- length(hours)
  base_price <- 1.0850
  
  # Create tight range overnight (17:00-07:00)
  overnight_hours <- 15
  overnight_range <- rnorm(overnight_hours, 0, 0.0005)
  
  # Morning breakout
  breakout_move <- cumsum(c(0, rnorm(n - overnight_hours - 1, 0.0015, 0.001)))
  
  prices <- c(base_price + cumsum(overnight_range), 
              base_price + max(cumsum(overnight_range)) + breakout_move)
  
  data.frame(
    Timestamp = hours,
    Hour = hour(hours),
    Mid = prices,
    High = prices * 1.0003,
    Low = prices * 0.9997,
    Close = prices
  )
}

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "W5-T.Strategies Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("home")),
      menuItem("Straddle Trading", tabName = "straddle", icon = icon("arrows-alt-h")),
      menuItem("Pivot Points", tabName = "pivot", icon = icon("crosshairs")),
      menuItem("DMI & ADX", tabName = "dmi", icon = icon("chart-line")),
      menuItem("Holy Grail Trade", tabName = "holygrail", icon = icon("star")),
      menuItem("Bollinger Bands", tabName = "bollinger", icon = icon("wave-square")),
      menuItem("Volume & OBV", tabName = "volume", icon = icon("chart-bar")),
      menuItem("Parabolic SAR", tabName = "parabolic", icon = icon("sync"))
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
        
        /* Header/navbar with matching gradient */
        .main-header, .main-header .navbar {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          border-bottom: none;
        }
        
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          border-bottom: none !important;
          font-weight: 600;
        }
        
        /* Box styling with enhanced gradients */
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
        
        /* Box headers with gradients */
        .box-header {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
          border-radius: 12px 12px 0 0 !important;
          padding: 15px 20px;
          border-bottom: none !important;
        }
        
        .box-header > .box-title {
          color: #ffffff !important;
          font-weight: 600;
          font-size: 16px;
        }
        
        /* Box body styling */
        .box-body {
          background-color: #ffffff !important;
          color: #2c3e50 !important;
          padding: 20px;
          border-radius: 0 0 12px 12px;
        }
        
        /* Value boxes with enhanced gradients */
        .small-box {
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15) !important;
          transition: transform 0.2s ease;
        }
        
        .small-box:hover {
          transform: translateY(-3px);
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
        
        .small-box.bg-purple { 
          background: linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%) !important; 
        }
        
        /* Info boxes styling */
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
        
        /* Concept explanation boxes */
        .concept-box {
          background: linear-gradient(135deg, #e8f5f4 0%, #d4edda 100%) !important;
          color: #155724 !important;
          padding: 20px;
          border-radius: 12px !important;
          border-left: 4px solid #00A39A !important;
          margin: 15px 0;
          box-shadow: 0 4px 15px rgba(0, 163, 154, 0.2);
        }
        
        .concept-box h4 {
          color: #008A82 !important;
          font-weight: 600;
          margin-top: 0;
        }
        
        .concept-box ul {
          margin-bottom: 5px;
        }
        
        .concept-box li {
          margin-bottom: 8px;
        }
        
        /* Strategy rules box */
        .strategy-rules {
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
          color: #856404 !important;
          padding: 20px;
          border-radius: 12px !important;
          border-left: 4px solid #f39c12 !important;
          margin: 15px 0;
          box-shadow: 0 4px 15px rgba(243, 156, 18, 0.2);
        }
        
        .strategy-rules h4 {
          color: #f39c12 !important;
          font-weight: 600;
          margin-top: 0;
        }
        
        /* Warning box */
        .warning-box {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 20px;
          border-radius: 12px !important;
          border-left: 4px solid #e74c3c !important;
          margin: 15px 0;
          box-shadow: 0 4px 15px rgba(231, 76, 60, 0.2);
        }
        
        /* Button styling with gradients */
        .btn-primary {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          padding: 10px 20px;
          font-weight: 600;
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        
        .btn-primary:hover {
          background: linear-gradient(135deg, #006b63 0%, #007d75 100%) !important;
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(0, 138, 130, 0.3);
        }
        
        /* Custom scrollbar */
        .box-body::-webkit-scrollbar {
          width: 6px;
        }
        
        .box-body::-webkit-scrollbar-track {
          background: #f1f1f1;
          border-radius: 3px;
        }
        
        .box-body::-webkit-scrollbar-thumb {
          background: linear-gradient(135deg, #008A82, #00A39A);
          border-radius: 3px;
        }
        
        /* Tabs styling */
        .nav-tabs-custom > .nav-tabs > li.active {
          border-top-color: #00A39A;
        }
        
        .nav-tabs-custom > .nav-tabs > li.active > a {
          border-left-color: #00A39A;
          border-right-color: #00A39A;
        }
        
        h1, h2, h3, h4, h5, h6 {
          color: #002C3C;
          font-weight: 600;
        }
      "))
    ),
    
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Trading Strategies - Week 5 Overview",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("Welcome to Advanced Trading Strategies"),
                      p("This dashboard covers key short-term and technical trading strategies from the London Academy of Trading curriculum:"),
                      tags$ul(
                        tags$li(tags$b("Straddle Trading:"), " Market-neutral strategy for trading breakouts from defined ranges"),
                        tags$li(tags$b("Pivot Points:"), " Daily support and resistance levels calculated from previous day's H/L/C"),
                        tags$li(tags$b("DMI & ADX:"), " Directional Movement Index for identifying and measuring trend strength"),
                        tags$li(tags$b("Holy Grail Trade:"), " Systematic approach combining trend, reaction, pattern, and risk"),
                        tags$li(tags$b("Bollinger Bands:"), " Volatility-based bands for identifying overbought/oversold conditions"),
                        tags$li(tags$b("Volume & OBV:"), " On-Balance Volume for confirming price movements"),
                        tags$li(tags$b("Parabolic SAR:"), " Trailing stop system for trending markets")
                      ),
                      p(tags$b("Note:"), " Each tab contains interactive visualizations and detailed explanations of the strategy concepts.")
                  )
                )
              ),
              
              fluidRow(
                valueBox(
                  "7", "Trading Strategies", icon = icon("chart-line"),
                  color = "blue", width = 3
                ),
                valueBox(
                  "30%", "Market Trending Time", icon = icon("arrow-trend-up"),
                  color = "green", width = 3
                ),
                valueBox(
                  "70%", "Market Ranging Time", icon = icon("arrows-left-right"),
                  color = "yellow", width = 3
                ),
                valueBox(
                  "24/7", "FX Market Hours", icon = icon("clock"),
                  color = "purple", width = 3
                )
              ),
              
              fluidRow(
                box(
                  title = "Key Trading Principles",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "strategy-rules",
                      h4("General Best Practices"),
                      tags$ul(
                        tags$li("Always use stop losses to manage risk"),
                        tags$li("Different strategies work in different market conditions"),
                        tags$li("Trending strategies: Use when ADX > 30"),
                        tags$li("Range trading: Use when ADX < 25"),
                        tags$li("Confirm signals with multiple indicators"),
                        tags$li("Practice proper position sizing"),
                        tags$li("Keep detailed trading records")
                      )
                  )
                ),
                box(
                  title = "Market Conditions",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Understanding Market States"),
                      tags$ul(
                        tags$li(tags$b("Trending Markets:"), " Price making higher highs/lower lows consistently"),
                        tags$li(tags$b("Range-bound Markets:"), " Price oscillating between support/resistance"),
                        tags$li(tags$b("Volatile Markets:"), " Large price swings, wide candles"),
                        tags$li(tags$b("Quiet Markets:"), " Small price movements, consolidation"),
                        tags$li(tags$b("Active Hours:"), " Major market overlaps (London/NY)"),
                        tags$li(tags$b("Quiet Hours:"), " Asian session, holiday periods")
                      )
                  )
                )
              )
      ),
      
      # Straddle Trading Tab
      tabItem(tabName = "straddle",
              fluidRow(
                box(
                  title = "Straddle Trading Strategy Concept",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("What is Straddle Trading?"),
                      p("A short-term, market-neutral trading strategy designed to capture breakouts from pre-defined trading ranges."),
                      tags$ul(
                        tags$li(tags$b("Core Assumption:"), " When price breaks out from a range, the initial move typically continues in that direction"),
                        tags$li(tags$b("Market Type:"), " Best suited for FX markets with clear consolidation periods"),
                        tags$li(tags$b("Setup:"), " Place OCO (One-Cancels-Other) orders above and below the range"),
                        tags$li(tags$b("Timeframe:"), " Typically uses overnight ranges (22:00 - 06:00 GMT) for morning breakouts")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Morning Straddle - Overnight Range",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("straddleChart", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "Strategy Rules",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "strategy-rules",
                      h4("Entry Setup"),
                      tags$ol(
                        tags$li("Identify overnight high and low (22:00-06:00)"),
                        tags$li("Calculate range = High(Ask) - Low(Bid)"),
                        tags$li("Place stop buy order 1-2 pips above overnight high"),
                        tags$li("Place stop sell order 1-2 pips below overnight low"),
                        tags$li("Orders are OCO - first triggered cancels the other")
                      ),
                      h4("Exit Rules"),
                      tags$ul(
                        tags$li(tags$b("Target:"), " Typically equal to overnight range"),
                        tags$li(tags$b("Stop Loss:"), " Opposite side of range"),
                        tags$li(tags$b("Risk:Reward:"), " Usually 1:1, can extend to 1.5:1")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Straddle Variations",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Advanced Straddle Techniques"),
                      tags$ul(
                        tags$li(tags$b("Non-OCO Approach:"), " Take both trades if both sides trigger (second trade when first stopped out)"),
                        tags$li(tags$b("Extended Targets:"), " Set targets at 1.5x or 2x risk when strong momentum expected"),
                        tags$li(tags$b("Trade with Trend:"), " Increase position size on side aligned with 1-week trend"),
                        tags$li(tags$b("News Straddle:"), " Use 1-3 hours before major news events instead of overnight range"),
                        tags$li(tags$b("Trailing Stops:"), " Move stops to breakeven quickly, then trail behind 2-bar lows/highs")
                      )
                  )
                ),
                box(
                  title = "When NOT to Use Straddle",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "warning-box",
                      h4("Avoid Straddle Trading When:"),
                      tags$ul(
                        tags$li("No clear, tight consolidation range exists"),
                        tags$li("No obvious trigger level for breakout"),
                        tags$li("Volatility is already high (orders may trigger prematurely)"),
                        tags$li("You have a strong directional bias (use outright trade instead)"),
                        tags$li("Wide spreads during news events (reduce profit potential)"),
                        tags$li("Low liquidity periods (risk of whipsaw)")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Example Calculation",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  verbatimTextOutput("straddleCalculation")
                )
              )
      ),
      
      # Pivot Points Tab
      tabItem(tabName = "pivot",
              fluidRow(
                box(
                  title = "Pivot Point Trading System",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("Understanding Pivot Points"),
                      p("Originally used by floor traders, pivot points are predictive (not lagging) support and resistance levels calculated from the previous day's High, Low, and Close."),
                      tags$ul(
                        tags$li(tags$b("Advantage:"), " Calculated before the trading day begins - predictive rather than reactive"),
                        tags$li(tags$b("Components:"), " 7 levels total - 1 Main Pivot, 3 Resistance levels (R1, R2, R3), 3 Support levels (S1, S2, S3)"),
                        tags$li(tags$b("For FX:"), " Use 5pm EST (10pm GMT) as the daily close"),
                        tags$li(tags$b("Key Principle:"), " Price tends to pause or reverse at these levels"),
                        tags$li(tags$b("Self-fulfilling:"), " Many traders watch these levels, creating actual support/resistance")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Pivot Points Chart",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("pivotChart", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "Pivot Calculations",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "strategy-rules",
                      h4("Formula"),
                      tags$pre("PP = (H + L + C) / 3
R3 = PP + (H - L) + (PP - L)
R2 = PP + (H - L)
R1 = PP + (PP - L)
S1 = PP - (H - PP)
S2 = PP - (H - L)
S3 = PP - (H - L) - (H - PP)"),
                      tags$hr(),
                      h4("Current Pivot Levels"),
                      verbatimTextOutput("pivotLevels")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Pivot Point Bounce System",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Mechanical Reversal Trading"),
                      p("Best used on 5-minute charts with daily pivot points during active market hours."),
                      tags$b("Sell Signal:"),
                      tags$ol(
                        tags$li("Price moves up to touch a resistance pivot"),
                        tags$li("Subsequent candle fails to make new high (Candle 1)"),
                        tags$li("Next candle breaks below Candle 1's low"),
                        tags$li(tags$b("Enter:"), " Sell at break of Candle 1 low"),
                        tags$li(tags$b("Stop:"), " Above most recent high"),
                        tags$li(tags$b("Target:"), " Next lower pivot point")
                      ),
                      tags$b("Buy Signal:"),
                      tags$ol(
                        tags$li("Price moves down to touch a support pivot"),
                        tags$li("Subsequent candle fails to make new low (Candle 1)"),
                        tags$li("Next candle breaks above Candle 1's high"),
                        tags$li(tags$b("Enter:"), " Buy at break of Candle 1 high"),
                        tags$li(tags$b("Stop:"), " Below most recent low"),
                        tags$li(tags$b("Target:"), " Next higher pivot point")
                      )
                  )
                ),
                box(
                  title = "Combining with Other Indicators",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "strategy-rules",
                      h4("Enhanced Confirmation"),
                      p("Pivot points provide the trade signals, but other indicators can confirm:"),
                      tags$ul(
                        tags$li(tags$b("Moving Averages:"), " Confirm trend direction before taking pivot bounce"),
                        tags$li(tags$b("MACD:"), " Look for divergence at pivot levels"),
                        tags$li(tags$b("RSI:"), " Confirm overbought at resistance / oversold at support"),
                        tags$li(tags$b("Stochastics:"), " Additional momentum confirmation"),
                        tags$li(tags$b("Price Patterns:"), " Flags, wedges, triangles at pivot levels")
                      ),
                      tags$hr(),
                      h4("Best Practices"),
                      tags$ul(
                        tags$li("Most reliable on first touch of each pivot"),
                        tags$li("Use time filters to avoid choppy markets"),
                        tags$li("Consider the major trend before taking counter-trend pivots"),
                        tags$li("Can use pivot breakouts instead of bounces in strong trends")
                      )
                  )
                )
              )
      ),
      
      # DMI & ADX Tab
      tabItem(tabName = "dmi",
              fluidRow(
                box(
                  title = "Directional Movement Index (DMI) & Average Directional Index (ADX)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("Identifying and Measuring Trends"),
                      p("Developed by Welles Wilder, this system helps determine if a market is trending and how strong that trend is."),
                      tags$ul(
                        tags$li(tags$b("ADX (Average Directional Index):"), " Measures trend strength (not direction)"),
                        tags$li(tags$b("+DI (Positive Directional Indicator):"), " Measures upward price movement"),
                        tags$li(tags$b("-DI (Negative Directional Indicator):"), " Measures downward price movement"),
                        tags$li(tags$b("Key Advantage:"), " Helps identify when to use trend-following vs. range-trading strategies"),
                        tags$li(tags$b("Lagging Indicator:"), " ADX lags price, but DMI crossovers can provide earlier signals")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "ADX Trend Strength Indicator",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("adxChart", height = "450px"), color = "#008A82")
                ),
                box(
                  title = "ADX Interpretation",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "strategy-rules",
                      h4("ADX Values"),
                      tags$ul(
                        tags$li(tags$b("ADX > 40:"), " Very strong trend"),
                        tags$li(tags$b("ADX 25-40:"), " Strong trend"),
                        tags$li(tags$b("ADX < 25:"), " Weak trend / ranging market"),
                        tags$li(tags$b("Rising ADX:"), " Trend strengthening"),
                        tags$li(tags$b("Falling ADX:"), " Trend weakening")
                      ),
                      tags$hr(),
                      h4("Strategy Selection"),
                      tags$ul(
                        tags$li(tags$b("ADX > 30:"), " Use trend-following strategies (MA, Parabolic, Holy Grail)"),
                        tags$li(tags$b("ADX < 25:"), " Use oscillators and range strategies (RSI, Stochastic, Pivot Bounce)")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "DMI Trading Signals",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("dmiChart", height = "450px"), color = "#008A82")
                ),
                box(
                  title = "DMI Signal Rules",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "concept-box",
                      h4("Trading Signals"),
                      tags$b("Buy Signal:"),
                      tags$ul(
                        tags$li("+DI crosses above -DI"),
                        tags$li("Confirm: ADX > 25 or ADX rising"),
                        tags$li("Best in uptrends")
                      ),
                      tags$b("Sell Signal:"),
                      tags$ul(
                        tags$li("-DI crosses above +DI"),
                        tags$li("Confirm: ADX > 25 or ADX rising"),
                        tags$li("Best in downtrends")
                      ),
                      tags$hr(),
                      h4("Extreme Points"),
                      p("When +DI and -DI cross, the extreme point of the trigger event provides additional confirmation:"),
                      tags$ul(
                        tags$li(tags$b("Sell:"), " Break below the low of trigger event"),
                        tags$li(tags$b("Buy:"), " Break above the high of trigger event")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Benefits & Limitations",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Benefits"),
                      tags$ul(
                        tags$li("Helps identify trending vs. ranging markets"),
                        tags$li("Prevents using wrong strategy in wrong conditions"),
                        tags$li("Works across all timeframes"),
                        tags$li("DMI provides early trend signals"),
                        tags$li("Quantifies trend strength")
                      )
                  )
                ),
                box(
                  title = "",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "warning-box",
                      h4("Limitations"),
                      tags$ul(
                        tags$li("ADX is a lagging indicator"),
                        tags$li("Can give false signals in choppy markets"),
                        tags$li("DMI signals need confirmation from other indicators"),
                        tags$li("Whipsaws common when ADX < 25"),
                        tags$li("Does not indicate trend direction (only strength)")
                      )
                  )
                )
              )
      ),
      
      # Holy Grail Trade Tab
      tabItem(tabName = "holygrail",
              fluidRow(
                box(
                  title = "The Holy Grail Trade",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("A Systematic Trend-Following Approach"),
                      p("Originally developed by Linda Bradford Raschke, this strategy combines four critical elements for high-probability trades:"),
                      tags$ul(
                        tags$li(tags$b("1. Trend:"), " Strong short-term directional movement"),
                        tags$li(tags$b("2. Reaction:"), " Slow, corrective pullback to moving average"),
                        tags$li(tags$b("3. Pattern:"), " Rising wedge, flag, or triangle consolidation"),
                        tags$li(tags$b("4. Risk:"), " Well-defined stop loss with favorable risk:reward")
                      ),
                      p(tags$b("Core Principle:"), " When price hits a new momentum high/low and pulls back, it will likely retest the recent extreme. Most traders fear buying pullbacks, but with this pattern, odds of reversal are only ~10%.")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Holy Grail Setup - Downtrend Example",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("holygrailChart", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "Setup Criteria (Sell Signal)",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "strategy-rules",
                      h4("Entry Criteria"),
                      tags$ol(
                        tags$li(tags$b("Strong downtrend:"), " Clear lower lows/highs"),
                        tags$li(tags$b("ADX > 30:"), " Confirms strong trend"),
                        tags$li(tags$b("Slow pullback:"), " Price retraces to 20 EMA"),
                        tags$li(tags$b("ADX declining:"), " During pullback"),
                        tags$li(tags$b("Pattern forms:"), " Rising wedge, flag, or consolidation at 20 EMA")
                      ),
                      tags$hr(),
                      h4("Trigger Options"),
                      tags$ul(
                        tags$li(tags$b("Option A:"), " Sell breakout below pattern"),
                        tags$li(tags$b("Option B:"), " Sell 1-2 pips below 2-event low")
                      ),
                      p(tags$b("Note:"), " Use time/price filter for confirmation")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Trade Management",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Stop Loss & Targets"),
                      tags$b("Stop Loss:"),
                      tags$ul(
                        tags$li("Place a few pips above recent reaction high"),
                        tags$li("Use aggressive trailing stop above 2-event high"),
                        tags$li("Move to breakeven once Target 1 hit")
                      ),
                      tags$b("Target 1:"),
                      tags$ul(
                        tags$li("At or slightly beyond previous downtrend low"),
                        tags$li("Typically close 50% of position here")
                      ),
                      tags$b("Target 2:"),
                      tags$ul(
                        tags$li("Use Fibonacci extension from previous leg"),
                        tags$li("Project 1.27 or 1.618 extension"),
                        tags$li("Trail remaining position aggressively")
                      )
                  )
                ),
                box(
                  title = "Buy Signal Setup",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "strategy-rules",
                      h4("Uptrend Criteria"),
                      tags$ol(
                        tags$li(tags$b("Strong uptrend:"), " Clear higher highs/lows"),
                        tags$li(tags$b("ADX > 30:"), " Confirms strong trend"),
                        tags$li(tags$b("Slow pullback:"), " Price retraces to 20 EMA"),
                        tags$li(tags$b("ADX declining:"), " During pullback"),
                        tags$li(tags$b("Pattern forms:"), " Falling wedge or flag")
                      ),
                      tags$hr(),
                      h4("Entry & Management"),
                      tags$ul(
                        tags$li(tags$b("Entry:"), " Buy 1-2 pips above 2-event high"),
                        tags$li(tags$b("Stop:"), " Below recent reaction low"),
                        tags$li(tags$b("Trail:"), " Below 2-event low as trade develops")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Key Success Factors",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("What Makes This Work"),
                      tags$ul(
                        tags$li(tags$b("Retracement Type:"), " Must be slow/corrective, not impulsive"),
                        tags$li(tags$b("Pattern Quality:"), " Look for clear consolidation patterns"),
                        tags$li(tags$b("Trend Strength:"), " ADX > 30 is essential"),
                        tags$li(tags$b("Entry Timing:"), " Wait for confirmed breakout"),
                        tags$li(tags$b("Quick Stop:"), " Know quickly if wrong (price breaks opposite way)"),
                        tags$li(tags$b("Patience:"), " Don't chase - another setup will come")
                      )
                  )
                ),
                box(
                  title = "Common Mistakes to Avoid",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "warning-box",
                      h4("What NOT To Do"),
                      tags$ul(
                        tags$li("Trading impulsive (sharp) pullbacks"),
                        tags$li("Entering before confirmed breakout"),
                        tags$li("Ignoring ADX < 30 (weak trend)"),
                        tags$li("Taking counter-trend setups"),
                        tags$li("Not using proper stop loss"),
                        tags$li("Missing the pattern requirement"),
                        tags$li("Forcing trades when setup isn't perfect")
                      )
                  )
                )
              )
      ),
      
      # Bollinger Bands Tab
      tabItem(tabName = "bollinger",
              fluidRow(
                box(
                  title = "Bollinger Bands",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("Volatility-Based Trading Bands"),
                      p("Developed by John Bollinger, these bands adapt to market volatility and always contain approximately 96% of price action."),
                      tags$ul(
                        tags$li(tags$b("Components:"), " 20-period Simple Moving Average (middle), Upper Band (+2 SD), Lower Band (-2 SD)"),
                        tags$li(tags$b("Key Feature:"), " Bands expand in volatile markets and contract in calm markets"),
                        tags$li(tags$b("Advantage over Fixed Bands:"), " Adapts automatically to changing market conditions"),
                        tags$li(tags$b("Standard Deviation:"), " Measures volatility - wider bands = more volatility"),
                        tags$li(tags$b("Best Use:"), " Short-term trading, especially in ranging markets")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Bollinger Bands Chart",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("bollingerChart", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "Band Interpretation",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "strategy-rules",
                      h4("Basic Signals"),
                      tags$ul(
                        tags$li(tags$b("Upper Band:"), " Overbought area"),
                        tags$li(tags$b("Lower Band:"), " Oversold area"),
                        tags$li(tags$b("Middle (20 SMA):"), " Equilibrium / mean"),
                        tags$li(tags$b("Band Width:"), " Narrow = low volatility, Wide = high volatility")
                      ),
                      tags$hr(),
                      h4("Settings"),
                      tags$ul(
                        tags$li("Period: 20 (standard)"),
                        tags$li("Standard Deviations: 2"),
                        tags$li("Moving Average: Simple")
                      ),
                      p(tags$b("Note:"), " These settings contain ~96% of price action")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Range Trading Strategy",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Trading Between Bands"),
                      p(tags$b("When to Use:"), " ADX < 30 and ideally falling (ranging market)"),
                      tags$b("Sell Signals:"),
                      tags$ul(
                        tags$li("Price touches or approaches upper band"),
                        tags$li("Take profit at middle band and/or lower band"),
                        tags$li("Stop loss above recent high")
                      ),
                      tags$b("Buy Signals:"),
                      tags$ul(
                        tags$li("Price touches or approaches lower band"),
                        tags$li("Take profit at middle band and/or upper band"),
                        tags$li("Stop loss below recent low")
                      ),
                      p(tags$b("Principle:"), " In sideways markets, moves starting at one band often reach the other band")
                  )
                ),
                box(
                  title = "The Bollinger Squeeze (Pinch)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "strategy-rules",
                      h4("Volatility Breakout Setup"),
                      p("Sharp price changes tend to occur after bands tighten significantly."),
                      tags$b("Setup:"),
                      tags$ol(
                        tags$li("Bands narrow to defined tight width"),
                        tags$li("Low volatility consolidation period"),
                        tags$li("Price compressed between bands")
                      ),
                      tags$b("Execution:"),
                      tags$ul(
                        tags$li("Place buy order above upper band"),
                        tags$li("Place sell order below lower band"),
                        tags$li("Stop loss at opposite band level"),
                        tags$li("Use time/price filter for confirmation")
                      ),
                      p(tags$b("Advantage:"), " Can catch the start of new trends")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Walking the Bands (Trending Market)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Riding Strong Trends"),
                      p("In strong trends, price can \"walk\" along the outer band without touching the opposite band."),
                      tags$ul(
                        tags$li(tags$b("Uptrend:"), " Price repeatedly touches upper band while staying above middle"),
                        tags$li(tags$b("Downtrend:"), " Price repeatedly touches lower band while staying below middle"),
                        tags$li(tags$b("Strategy:"), " Don't fade the band touch in strong trends - wait for pullback to middle"),
                        tags$li(tags$b("Confirmation:"), " Look for ADX > 30 before assuming \"walking\" behavior")
                      )
                  )
                ),
                box(
                  title = "W-Bottoms and M-Tops",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "strategy-rules",
                      h4("Reversal Patterns"),
                      tags$b("W-Bottom (Bullish):"),
                      tags$ol(
                        tags$li("First low touches/breaks lower band"),
                        tags$li("Pullback toward middle band"),
                        tags$li("Second low holds INSIDE lower band"),
                        tags$li("Price breaks above middle band = Buy signal")
                      ),
                      tags$b("M-Top (Bearish):"),
                      tags$ol(
                        tags$li("First high touches/breaks upper band"),
                        tags$li("Pullback toward middle band"),
                        tags$li("Second high holds INSIDE upper band"),
                        tags$li("Price breaks below middle band = Sell signal")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Best Practices",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("Using Bollinger Bands Effectively"),
                      tags$ul(
                        tags$li(tags$b("Combine with other indicators:"), " Use RSI, Stochastic, or volume for confirmation"),
                        tags$li(tags$b("Check ADX:"), " Range strategies when ADX < 25, breakout strategies during squeezes"),
                        tags$li(tags$b("Don't rely solely on bands:"), " They indicate overbought/oversold but not necessarily reversal"),
                        tags$li(tags$b("Adjust for market:"), " Can modify periods or standard deviations for different instruments"),
                        tags$li(tags$b("Watch for false signals:"), " Band touches can be false in strong trends"),
                        tags$li(tags$b("Best timeframes:"), " Works well on hourly, 4-hour, and daily charts")
                      )
                  )
                )
              )
      ),
      
      # Volume & OBV Tab
      tabItem(tabName = "volume",
              fluidRow(
                box(
                  title = "Volume Analysis & On-Balance Volume (OBV)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("Volume: The \"Fuel\" Behind Price Movement"),
                      p("Volume is a key confirmation indicator that measures market conviction and aggression."),
                      tags$ul(
                        tags$li(tags$b("Core Principle:"), " Volume should confirm trend - increasing volume in direction of trend is bullish"),
                        tags$li(tags$b("Volume precedes price:"), " Smart money accumulation/distribution shows up in volume first"),
                        tags$li(tags$b("Divergence:"), " When price makes new highs/lows but volume doesn't, trend may be weakening"),
                        tags$li(tags$b("OBV Solution:"), " On-Balance Volume creates a cumulative indicator from volume data"),
                        tags$li(tags$b("OBV Direction:"), " More important than OBV value - look for trend and divergence")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Price and Volume Chart",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("volumeChart", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "Volume Principles",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "strategy-rules",
                      h4("Key Concepts"),
                      tags$ul(
                        tags$li(tags$b("Confirmation:"), " Rising volume confirms trend"),
                        tags$li(tags$b("Exhaustion:"), " Climax volume can signal reversal"),
                        tags$li(tags$b("Breakouts:"), " High volume breakouts more reliable"),
                        tags$li(tags$b("Low volume:"), " Suggests lack of conviction")
                      ),
                      tags$hr(),
                      h4("Volume Patterns"),
                      tags$ul(
                        tags$li("Volume spike on up day = bullish"),
                        tags$li("Volume spike on down day = bearish"),
                        tags$li("Declining volume in trend = weakening"),
                        tags$li("Volume surge at support/resistance = significant level")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "On-Balance Volume (OBV)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("obvChart", height = "450px"), color = "#008A82")
                ),
                box(
                  title = "OBV Calculation",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "concept-box",
                      h4("How OBV Works"),
                      p("OBV creates a cumulative total of volume based on price direction:"),
                      tags$pre("If Close > Previous Close:
  OBV = Previous OBV + Volume

If Close < Previous Close:
  OBV = Previous OBV - Volume

If Close = Previous Close:
  OBV = Previous OBV"),
                      tags$hr(),
                      p(tags$b("Key Point:"), " OBV value doesn't matter - only direction and divergence")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "OBV Interpretation",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Using OBV Effectively"),
                      tags$b("Confirmation:"),
                      tags$ul(
                        tags$li("OBV rising with rising price = healthy uptrend"),
                        tags$li("OBV falling with falling price = healthy downtrend")
                      ),
                      tags$b("Divergence (Most Important):"),
                      tags$ul(
                        tags$li("Price makes new high but OBV doesn't = bearish divergence"),
                        tags$li("Price makes new low but OBV doesn't = bullish divergence"),
                        tags$li("OBV breakout before price = advance warning")
                      ),
                      tags$b("Historical Comparison:"),
                      tags$ul(
                        tags$li("\"Where was OBV last time price was here?\""),
                        tags$li("Higher OBV now = bullish"),
                        tags$li("Lower OBV now = bearish")
                      )
                  )
                ),
                box(
                  title = "OBV in Ranging Markets",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "strategy-rules",
                      h4("Predicting Breakout Direction"),
                      p("When price is ranging but OBV is trending, it predicts breakout direction:"),
                      tags$ul(
                        tags$li(tags$b("Rising OBV:"), " Expect upward breakout"),
                        tags$li(tags$b("Falling OBV:"), " Expect downward breakout"),
                        tags$li(tags$b("Reason:"), " Shows where \"smart money\" is accumulating")
                      ),
                      tags$hr(),
                      h4("OBV with Patterns"),
                      tags$ul(
                        tags$li("OBV can form its own patterns (triangles, H&S, etc.)"),
                        tags$li("OBV trend line breaks often precede price breaks"),
                        tags$li("OBV breakout from pattern confirms price pattern validity")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Practical Applications",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("How to Use Volume & OBV in Trading"),
                      tags$ul(
                        tags$li(tags$b("Entry Confirmation:"), " Look for volume surge on breakouts - adds conviction"),
                        tags$li(tags$b("Trend Health:"), " Monitor OBV along with price - divergence warns of weakening trend"),
                        tags$li(tags$b("Pattern Reliability:"), " Patterns with OBV confirmation are more reliable"),
                        tags$li(tags$b("False Breakout Filter:"), " Low volume breakouts are more likely to fail"),
                        tags$li(tags$b("Accumulation/Distribution:"), " Rising OBV in sideways market shows accumulation (bullish)"),
                        tags$li(tags$b("Early Warning:"), " OBV often leads price - watch for divergence"),
                        tags$li(tags$b("Support/Resistance:"), " High volume at levels makes them more significant")
                      )
                  )
                )
              )
      ),
      
      # Parabolic SAR Tab
      tabItem(tabName = "parabolic",
              fluidRow(
                box(
                  title = "Wilder's Parabolic SAR (Stop And Reverse)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("An Accelerating Trailing Stop System"),
                      p("Developed by Welles Wilder (creator of RSI and ADX), the Parabolic SAR provides continuous trailing stops that accelerate toward price."),
                      tags$ul(
                        tags$li(tags$b("Stop And Reverse:"), " When price touches SAR, close position and open opposite position"),
                        tags$li(tags$b("Acceleration:"), " SAR moves faster toward price as trend develops"),
                        tags$li(tags$b("Acceleration Factor (AF):"), " Starts at 0.02, increases by 0.02 each time new extreme price reached (max 0.20)"),
                        tags$li(tags$b("Best For:"), " Strong trending markets (Wilder estimates ~30% of time)"),
                        tags$li(tags$b("Visual:"), " Appears as dots below price in uptrend, above price in downtrend")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Parabolic SAR Chart",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("parabolicChart", height = "500px"), color = "#008A82")
                ),
                box(
                  title = "Parabolic SAR Formula",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  div(class = "strategy-rules",
                      h4("Calculation"),
                      tags$pre("SARn+1 = SARn + α(EP - SARn)

Where:
- SARn = Current SAR
- SARn+1 = Next SAR
- EP = Extreme Point
  (highest high in uptrend,
   lowest low in downtrend)
- α = Acceleration Factor
  (starts 0.02, max 0.20)"),
                      tags$hr(),
                      h4("On Reversal"),
                      p("When price touches SAR:"),
                      tags$ul(
                        tags$li("Close existing position"),
                        tags$li("Open opposite position"),
                        tags$li("New SAR = Last EP"),
                        tags$li("Reset AF to 0.02")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Trading Rules",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Long Position Rules"),
                      tags$ul(
                        tags$li(tags$b("Entry:"), " When price closes above SAR (SAR flips to below price)"),
                        tags$li(tags$b("Hold:"), " While price remains above SAR"),
                        tags$li(tags$b("Exit:"), " When price touches/closes below SAR"),
                        tags$li(tags$b("Reverse:"), " Immediately open short position")
                      ),
                      tags$hr(),
                      h4("Short Position Rules"),
                      tags$ul(
                        tags$li(tags$b("Entry:"), " When price closes below SAR (SAR flips to above price)"),
                        tags$li(tags$b("Hold:"), " While price remains below SAR"),
                        tags$li(tags$b("Exit:"), " When price touches/closes above SAR"),
                        tags$li(tags$b("Reverse:"), " Immediately open long position")
                      )
                  )
                ),
                box(
                  title = "Best Practices",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "strategy-rules",
                      h4("Optimal Use"),
                      tags$ul(
                        tags$li(tags$b("Pre-Filter with ADX:"), " Only use when ADX > 30 (trending market)"),
                        tags$li(tags$b("Timeframes:"), " Works on all timeframes; shorter = faster signals"),
                        tags$li(tags$b("Not for ranging:"), " Generates whipsaws in sideways markets"),
                        tags$li(tags$b("Always in market:"), " System requires always having a position"),
                        tags$li(tags$b("Trend confirmation:"), " Combine with moving averages or trend lines")
                      ),
                      tags$hr(),
                      h4("Timeframe Effects"),
                      tags$ul(
                        tags$li("5-15 min: Very quick signals, many reversals"),
                        tags$li("Hourly: Balanced approach"),
                        tags$li("Daily/Weekly: Fewer signals, longer holds")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Advantages",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "concept-box",
                      h4("Why Use Parabolic SAR"),
                      tags$ul(
                        tags$li(tags$b("Clear signals:"), " Objective entry/exit points"),
                        tags$li(tags$b("Trailing stop:"), " Automatically protects profits"),
                        tags$li(tags$b("Acceleration:"), " Locks in gains quickly in strong trends"),
                        tags$li(tags$b("Captures trends:"), " Stays with move until clear reversal"),
                        tags$li(tags$b("No discretion:"), " Mechanical system reduces emotion"),
                        tags$li(tags$b("Always positioned:"), " Never misses a trend"),
                        tags$li(tags$b("Works across markets:"), " Forex, stocks, commodities")
                      )
                  )
                ),
                box(
                  title = "Limitations",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  div(class = "warning-box",
                      h4("Watch Out For"),
                      tags$ul(
                        tags$li(tags$b("Whipsaws:"), " Many false signals in ranging markets"),
                        tags$li(tags$b("Always in:"), " Must always have a position"),
                        tags$li(tags$b("Not predictive:"), " Doesn't forecast - only reacts"),
                        tags$li(tags$b("Late entries:"), " Often enters after move has started"),
                        tags$li(tags$b("Gives back profits:"), " Can surrender gains in choppy conditions"),
                        tags$li(tags$b("Requires trending:"), " Only ~30% of time are markets truly trending"),
                        tags$li(tags$b("Quick acceleration:"), " Can exit prematurely if spike against trend")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Combining with Other Indicators",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "concept-box",
                      h4("Enhanced Parabolic SAR Trading"),
                      tags$ul(
                        tags$li(tags$b("Parabolic + ADX:"), " Only take Parabolic signals when ADX > 30 (filters ranging markets)"),
                        tags$li(tags$b("Parabolic + Moving Average:"), " Only take Parabolic signals in direction of MA (filters counter-trend)"),
                        tags$li(tags$b("Parabolic + DMI:"), " Confirm trend direction with +DI/-DI position"),
                        tags$li(tags$b("Parabolic + Support/Resistance:"), " Look for SAR flips at key levels for added confirmation"),
                        tags$li(tags$b("Don't reverse:"), " Instead of automatic reverse, can choose to go flat and wait for ADX confirmation"),
                        tags$li(tags$b("Partial positions:"), " Scale in/out around SAR points rather than all-or-nothing")
                      )
                  )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Generate base data
  base_data <- reactive({
    generate_sample_data(180)
  })
  
  # Straddle Tab Outputs
  output$straddleChart <- renderPlotly({
    data <- generate_intraday_data()
    
    # Identify overnight period and range
    overnight_data <- data %>% filter(Hour >= 17 | Hour <= 6)
    overnight_high <- max(overnight_data$High)
    overnight_low <- min(overnight_data$Low)
    
    # Morning session starts at 7am
    morning_start <- min(data$Timestamp[data$Hour == 7])
    
    plot_ly(data, x = ~Timestamp) %>%
      add_lines(y = ~Mid, name = "Price", line = list(color = "#008A82", width = 2)) %>%
      # Overnight range box
      add_trace(
        x = c(min(overnight_data$Timestamp), max(overnight_data$Timestamp), 
              max(overnight_data$Timestamp), min(overnight_data$Timestamp)),
        y = c(overnight_high, overnight_high, overnight_low, overnight_low),
        type = "scatter",
        mode = "lines",
        fill = "toself",
        fillcolor = "rgba(0, 163, 154, 0.1)",
        line = list(color = "rgba(0, 163, 154, 0.3)", dash = "dash"),
        name = "Overnight Range",
        showlegend = TRUE
      ) %>%
      # Buy order line
      add_trace(
        x = c(morning_start, max(data$Timestamp)),
        y = c(overnight_high * 1.0001, overnight_high * 1.0001),
        type = "scatter",
        mode = "lines",
        line = list(color = "#00A39A", width = 2, dash = "dot"),
        name = "Buy Order",
        showlegend = TRUE
      ) %>%
      # Sell order line
      add_trace(
        x = c(morning_start, max(data$Timestamp)),
        y = c(overnight_low * 0.9999, overnight_low * 0.9999),
        type = "scatter",
        mode = "lines",
        line = list(color = "#e74c3c", width = 2, dash = "dot"),
        name = "Sell Order",
        showlegend = TRUE
      ) %>%
      layout(
        title = list(
          text = "Morning Straddle - EUR/USD Hourly",
          font = list(color = "#002C3C", size = 16, weight = 600)
        ),
        xaxis = list(title = "Time", color = "#2c3e50"),
        yaxis = list(title = "Exchange Rate", tickformat = ".4f", color = "#2c3e50"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = TRUE,
        legend = list(x = 0.02, y = 0.98)
      )
  })
  
  output$straddleCalculation <- renderText({
    paste(
      "Example: EUR/USD Overnight Range (22:00 - 06:00 GMT)",
      "=================================================",
      "",
      "Overnight High (Bid):    1.0865",
      "Overnight Low (Bid):     1.0843",
      "Spread:                  0.0002 (2 pips)",
      "",
      "Overnight High (Ask):    1.0865 + 0.0002 = 1.0867",
      "",
      "Overnight Range:         1.0867 - 1.0843 = 0.0024 = 24 pips",
      "",
      "Order Placement:",
      "----------------",
      "Stop Buy Order:          1.0868 (1 pip above overnight Ask high)",
      "Stop Sell Order:         1.0842 (1 pip below overnight Bid low)",
      "",
      "Trade Management:",
      "-----------------",
      "Buy Stop Loss:           1.0842 (same as Sell Order level)",
      "Buy Target:              1.0892 (24 pips profit = overnight range)",
      "",
      "Sell Stop Loss:          1.0868 (same as Buy Order level)",
      "Sell Target:             1.0818 (24 pips profit = overnight range)",
      "",
      "Risk = 24 + 2 = 26 pips (range + buffer)",
      "Reward = 24 pips",
      "Risk:Reward Ratio = 1:0.92 (close to 1:1)",
      sep = "\n"
    )
  })
  
  # Pivot Points Tab Outputs
  output$pivotChart <- renderPlotly({
    data <- base_data()
    
    # Calculate pivot points from previous day
    prev_day <- data %>% slice_head(n = 1)
    high <- prev_day$High
    low <- prev_day$Low
    close <- prev_day$Close
    
    # Pivot calculations
    pp <- (high + low + close) / 3
    r1 <- pp + (pp - low)
    r2 <- pp + (high - low)
    r3 <- pp + (high - low) + (pp - low)
    s1 <- pp - (high - pp)
    s2 <- pp - (high - low)
    s3 <- pp - (high - low) - (high - pp)
    
    plot_ly(data, x = ~Timestamp, y = ~Mid, type = "scatter", mode = "lines",
            name = "Price", line = list(color = "#008A82", width = 2)) %>%
      # Pivot lines
      add_trace(y = pp, name = "PP", mode = "lines", 
                line = list(color = "#9b59b6", width = 2, dash = "solid")) %>%
      add_trace(y = r1, name = "R1", mode = "lines",
                line = list(color = "#e74c3c", width = 1, dash = "dash")) %>%
      add_trace(y = r2, name = "R2", mode = "lines",
                line = list(color = "#e74c3c", width = 1, dash = "dot")) %>%
      add_trace(y = r3, name = "R3", mode = "lines",
                line = list(color = "#e74c3c", width = 1, dash = "dashdot")) %>%
      add_trace(y = s1, name = "S1", mode = "lines",
                line = list(color = "#00A39A", width = 1, dash = "dash")) %>%
      add_trace(y = s2, name = "S2", mode = "lines",
                line = list(color = "#00A39A", width = 1, dash = "dot")) %>%
      add_trace(y = s3, name = "S3", mode = "lines",
                line = list(color = "#00A39A", width = 1, dash = "dashdot")) %>%
      layout(
        title = list(
          text = "Daily Pivot Points",
          font = list(color = "#002C3C", size = 16, weight = 600)
        ),
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = "Price Level", tickformat = ".4f", color = "#2c3e50"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = TRUE,
        legend = list(x = 1.02, y = 1)
      )
  })
  
  output$pivotLevels <- renderText({
    data <- base_data()
    prev_day <- data %>% slice_head(n = 1)
    
    high <- prev_day$High
    low <- prev_day$Low
    close <- prev_day$Close
    
    pp <- (high + low + close) / 3
    r1 <- pp + (pp - low)
    r2 <- pp + (high - low)
    r3 <- pp + (high - low) + (pp - low)
    s1 <- pp - (high - pp)
    s2 <- pp - (high - low)
    s3 <- pp - (high - low) - (high - pp)
    
    paste(
      sprintf("Previous Day:\nH: %.4f\nL: %.4f\nC: %.4f\n", high, low, close),
      "\nToday's Pivots:",
      sprintf("R3: %.4f", r3),
      sprintf("R2: %.4f", r2),
      sprintf("R1: %.4f", r1),
      sprintf("PP: %.4f", pp),
      sprintf("S1: %.4f", s1),
      sprintf("S2: %.4f", s2),
      sprintf("S3: %.4f", s3),
      sep = "\n"
    )
  })
  
  # DMI & ADX Tab Outputs
  output$adxChart <- renderPlotly({
    data <- base_data()
    
    # Calculate ADX
    adx_data <- ADX(data[, c("High", "Low", "Close")], n = 14)
    data$ADX <- adx_data[, "ADX"]
    
    plot_ly(data, x = ~Timestamp) %>%
      add_lines(y = ~Mid, name = "Price", yaxis = "y1",
                line = list(color = "#008A82", width = 2)) %>%
      add_lines(y = ~ADX, name = "ADX", yaxis = "y2",
                line = list(color = "#9b59b6", width = 2)) %>%
      add_trace(
        x = c(min(data$Timestamp), max(data$Timestamp)),
        y = c(25, 25),
        type = "scatter",
        mode = "lines",
        line = list(color = "#f39c12", width = 1, dash = "dash"),
        name = "ADX 25",
        yaxis = "y2",
        showlegend = TRUE
      ) %>%
      add_trace(
        x = c(min(data$Timestamp), max(data$Timestamp)),
        y = c(30, 30),
        type = "scatter",
        mode = "lines",
        line = list(color = "#e74c3c", width = 1, dash = "dash"),
        name = "ADX 30",
        yaxis = "y2",
        showlegend = TRUE
      ) %>%
      layout(
        title = list(
          text = "Price with ADX Indicator",
          font = list(color = "#002C3C", size = 16, weight = 600)
        ),
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(
          title = "Price",
          side = "left",
          color = "#2c3e50"
        ),
        yaxis2 = list(
          title = "ADX Value",
          overlaying = "y",
          side = "right",
          color = "#9b59b6",
          range = c(0, 60)
        ),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = TRUE
      )
  })
  
  output$dmiChart <- renderPlotly({
    data <- base_data()
    
    # Calculate DMI
    adx_data <- ADX(data[, c("High", "Low", "Close")], n = 14)
    data$DIp <- adx_data[, "DIp"]
    data$DIn <- adx_data[, "DIn"]
    data$ADX <- adx_data[, "ADX"]
    
    plot_ly(data, x = ~Timestamp) %>%
      add_lines(y = ~DIp, name = "+DI", line = list(color = "#00A39A", width = 2)) %>%
      add_lines(y = ~DIn, name = "-DI", line = list(color = "#e74c3c", width = 2)) %>%
      add_lines(y = ~ADX, name = "ADX", line = list(color = "#9b59b6", width = 2, dash = "dot")) %>%
      add_trace(
        x = c(min(data$Timestamp), max(data$Timestamp)),
        y = c(25, 25),
        type = "scatter",
        mode = "lines",
        line = list(color = "#f39c12", width = 1, dash = "dash"),
        name = "Level 25",
        showlegend = TRUE
      ) %>%
      layout(
        title = list(
          text = "DMI (+DI / -DI) with ADX",
          font = list(color = "#002C3C", size = 16, weight = 600)
        ),
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = "Indicator Value", color = "#2c3e50", range = c(0, 60)),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = TRUE
      )
  })
  
  # Holy Grail Tab Outputs
  output$holygrailChart <- renderPlotly({
    data <- base_data() %>% slice_tail(n = 100)
    
    # Calculate EMA and ADX
    data$EMA20 <- EMA(data$Close, n = 20)
    adx_data <- ADX(data[, c("High", "Low", "Close")], n = 14)
    data$ADX <- adx_data[, "ADX"]
    
    # Simulate a Holy Grail setup
    # Find a point where price pulls back to EMA in downtrend with ADX > 30
    setup_idx <- which(data$ADX > 30 & abs(data$Close - data$EMA20) < 0.003)[1]
    
    if (!is.na(setup_idx) && setup_idx > 10) {
      entry_price <- data$Close[setup_idx] * 0.998
      stop_price <- data$Close[setup_idx] * 1.002
      target1_price <- data$Close[setup_idx] * 0.990
      target2_price <- data$Close[setup_idx] * 0.980
    } else {
      entry_price <- NA
      stop_price <- NA
      target1_price <- NA
      target2_price <- NA
    }
    
    p <- plot_ly(data, x = ~Timestamp) %>%
      add_lines(y = ~Close, name = "Price", line = list(color = "#008A82", width = 2)) %>%
      add_lines(y = ~EMA20, name = "20 EMA", line = list(color = "#f39c12", width = 2)) %>%
      layout(
        title = list(
          text = "Holy Grail Setup - Downtrend Example",
          font = list(color = "#002C3C", size = 16, weight = 600)
        ),
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = "Price", tickformat = ".4f", color = "#2c3e50"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    # Add trade levels if setup found
    if (!is.na(entry_price)) {
      p <- p %>%
        add_trace(
          x = c(data$Timestamp[setup_idx], max(data$Timestamp)),
          y = c(entry_price, entry_price),
          type = "scatter",
          mode = "lines",
          line = list(color = "#e74c3c", width = 2, dash = "solid"),
          name = "Entry (Sell)"
        ) %>%
        add_trace(
          x = c(data$Timestamp[setup_idx], max(data$Timestamp)),
          y = c(stop_price, stop_price),
          type = "scatter",
          mode = "lines",
          line = list(color = "#c0392b", width = 1, dash = "dot"),
          name = "Stop Loss"
        ) %>%
        add_trace(
          x = c(data$Timestamp[setup_idx], max(data$Timestamp)),
          y = c(target1_price, target1_price),
          type = "scatter",
          mode = "lines",
          line = list(color = "#00A39A", width = 1, dash = "dash"),
          name = "Target 1"
        ) %>%
        add_trace(
          x = c(data$Timestamp[setup_idx], max(data$Timestamp)),
          y = c(target2_price, target2_price),
          type = "scatter",
          mode = "lines",
          line = list(color = "#00A39A", width = 1, dash = "dashdot"),
          name = "Target 2"
        )
    }
    
    p
  })
  
  # Bollinger Bands Tab Outputs
  output$bollingerChart <- renderPlotly({
    data <- base_data()
    
    # Calculate Bollinger Bands
    bb <- BBands(data$Close, n = 20, sd = 2)
    data$BB_Upper <- bb[, "up"]
    data$BB_Mid <- bb[, "mavg"]
    data$BB_Lower <- bb[, "dn"]
    
    plot_ly(data, x = ~Timestamp) %>%
      add_lines(y = ~Close, name = "Price", line = list(color = "#008A82", width = 2)) %>%
      add_lines(y = ~BB_Upper, name = "Upper Band", 
                line = list(color = "#e74c3c", width = 1, dash = "dash")) %>%
      add_lines(y = ~BB_Mid, name = "Middle (20 SMA)", 
                line = list(color = "#9b59b6", width = 2)) %>%
      add_lines(y = ~BB_Lower, name = "Lower Band", 
                line = list(color = "#00A39A", width = 1, dash = "dash")) %>%
      # Fill between bands
      add_trace(
        x = c(data$Timestamp, rev(data$Timestamp)),
        y = c(data$BB_Upper, rev(data$BB_Lower)),
        type = "scatter",
        fill = "toself",
        fillcolor = "rgba(0, 163, 154, 0.1)",
        line = list(color = "transparent"),
        name = "Band Range",
        showlegend = FALSE,
        hoverinfo = "skip"
      ) %>%
      layout(
        title = list(
          text = "Bollinger Bands (20, 2)",
          font = list(color = "#002C3C", size = 16, weight = 600)
        ),
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = "Price", tickformat = ".4f", color = "#2c3e50"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # Volume & OBV Tab Outputs
  output$volumeChart <- renderPlotly({
    data <- base_data()
    
    plot_ly(data, x = ~Timestamp) %>%
      add_lines(y = ~Close, name = "Price", yaxis = "y1",
                line = list(color = "#008A82", width = 2)) %>%
      add_bars(y = ~Volume, name = "Volume", yaxis = "y2",
               marker = list(color = ifelse(data$Close > lag(data$Close), "#00A39A", "#e74c3c"))) %>%
      layout(
        title = list(
          text = "Price with Volume",
          font = list(color = "#002C3C", size = 16, weight = 600)
        ),
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(
          title = "Price",
          side = "left",
          color = "#2c3e50"
        ),
        yaxis2 = list(
          title = "Volume",
          overlaying = "y",
          side = "right",
          color = "#9b59b6"
        ),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = TRUE
      )
  })
  
  output$obvChart <- renderPlotly({
    data <- base_data()
    
    # Calculate OBV
    data$OBV <- OBV(data$Close, data$Volume)
    
    plot_ly(data, x = ~Timestamp) %>%
      add_lines(y = ~Close, name = "Price", yaxis = "y1",
                line = list(color = "#008A82", width = 2)) %>%
      add_lines(y = ~OBV, name = "OBV", yaxis = "y2",
                line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        title = list(
          text = "Price with On-Balance Volume (OBV)",
          font = list(color = "#002C3C", size = 16, weight = 600)
        ),
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(
          title = "Price",
          side = "left",
          color = "#2c3e50"
        ),
        yaxis2 = list(
          title = "OBV",
          overlaying = "y",
          side = "right",
          color = "#9b59b6"
        ),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = TRUE
      )
  })
  
  # Parabolic SAR Tab Outputs
  output$parabolicChart <- renderPlotly({
    data <- base_data()
    
    # Calculate Parabolic SAR
    sar <- SAR(data[, c("High", "Low")], accel = c(0.02, 0.2))
    data$SAR <- sar
    
    # Determine position (long when SAR below price, short when above)
    data$Position <- ifelse(data$Close > data$SAR, "Long", "Short")
    
    plot_ly(data, x = ~Timestamp) %>%
      add_lines(y = ~Close, name = "Price", line = list(color = "#008A82", width = 2)) %>%
      add_markers(
        y = ~SAR,
        name = "Parabolic SAR",
        marker = list(
          size = 4,
          color = ifelse(data$Position == "Long", "#00A39A", "#e74c3c")
        ),
        text = ~paste("SAR:", round(SAR, 4), "<br>Position:", Position),
        hoverinfo = "text"
      ) %>%
      layout(
        title = list(
          text = "Parabolic SAR - Stop And Reverse System",
          font = list(color = "#002C3C", size = 16, weight = 600)
        ),
        xaxis = list(title = "Date", color = "#2c3e50"),
        yaxis = list(title = "Price", tickformat = ".4f", color = "#2c3e50"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        annotations = list(
          list(
            x = 0.5, y = 1.05,
            text = "Green dots = Long position | Red dots = Short position",
            showarrow = FALSE,
            xref = "paper", yref = "paper",
            xanchor = "center",
            font = list(size = 12, color = "#2c3e50")
          )
        )
      )
  })
}

# Run the application
shinyApp(ui = ui, server = server)