# FX Markets & Technical Analysis Educational Dashboard
# Based on Week 1 Lectures - London Academy of Trading

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

# Generate sample FX data
generate_fx_data <- function(days = 365, pair = "EURUSD") {
  dates <- seq(Sys.Date() - days, Sys.Date(), by = "day")
  
  # Base prices for different pairs
  base_prices <- list(
    EURUSD = 1.10,
    GBPUSD = 1.25,
    USDJPY = 110,
    USDCHF = 0.92,
    AUDUSD = 0.75
  )
  
  base <- base_prices[[pair]]
  volatility <- ifelse(pair == "USDJPY", 0.3, 0.003)
  
  price <- base + cumsum(rnorm(length(dates), 0, volatility))
  
  data.frame(
    Date = dates,
    Open = price + rnorm(length(dates), 0, volatility/4),
    High = price + abs(rnorm(length(dates), volatility/2, volatility/4)),
    Low = price - abs(rnorm(length(dates), volatility/2, volatility/4)),
    Close = price,
    Volume = sample(1000000:5000000, length(dates), replace = TRUE)
  ) %>%
    mutate(
      Bid = Close * 0.9998,
      Ask = Close * 1.0002,
      Spread = Ask - Bid,
      Returns = c(NA, diff(log(Close))) * 100
    )
}

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "W1 FX Markets & Technical Analysis Learning Platform"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("FX Market Overview", tabName = "overview", icon = icon("globe")),
      menuItem("Market Structure", tabName = "structure", icon = icon("building")),
      menuItem("Price Construction", tabName = "pricing", icon = icon("calculator")),
      menuItem("Support & Resistance", tabName = "support", icon = icon("chart-line")),
      menuItem("Trend Analysis", tabName = "trends", icon = icon("chart-area")),
      menuItem("Candlestick Patterns", tabName = "candles", icon = icon("candle-holder")),
      menuItem("Technical Indicators", tabName = "indicators", icon = icon("chart-bar")),
      menuItem("Trading Psychology", tabName = "psychology", icon = icon("brain")),
      menuItem("Risk Management", tabName = "risk", icon = icon("shield-alt")),
      menuItem("Interactive Trading", tabName = "trading", icon = icon("hand-holding-usd"))
    ),
    
    hr(),
    
    selectInput("currency_pair", "Select Currency Pair:",
                choices = c("EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD"),
                selected = "EURUSD"),
    
    sliderInput("time_period", "Time Period (Days):",
                min = 30, max = 730, value = 180, step = 30)
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Main body background with original teal gradient */
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
        
        .main-header .navbar-nav > li > a {
          color: #ffffff !important;
        }
        
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          border-bottom: none !important;
          font-weight: 600;
        }
        
        .main-header .logo:hover {
          background: linear-gradient(135deg, #001f2a 0%, #006b63 50%, #007d75 100%) !important;
        }
        
        .main-header .logo .logo-lg,
        .main-header .logo .logo-mini {
          color: #ffffff !important;
          font-weight: 600;
        }
        
        .main-header .navbar .sidebar-toggle {
          background: rgba(255, 255, 255, 0.1) !important;
          color: #ffffff !important;
          border: none !important;
        }
        
        .main-header .navbar .sidebar-toggle:hover {
          background: rgba(255, 255, 255, 0.2) !important;
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
        
        .box-header.with-border {
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
          background: linear-gradient(135deg, #e8f5e9, #c8e6c9);
          border-left: 4px solid #00A39A;
          padding: 15px;
          margin: 15px 0;
          border-radius: 8px;
        }
        
        .concept-box {
          background: linear-gradient(135deg, #fff3e0, #ffe0b2);
          border-left: 4px solid #ff9800;
          padding: 15px;
          margin: 15px 0;
          border-radius: 8px;
        }
        
        .warning-box {
          background: linear-gradient(135deg, #ffebee, #ffcdd2);
          border-left: 4px solid #f44336;
          padding: 15px;
          margin: 15px 0;
          border-radius: 8px;
        }
        
        .key-point {
          background: #f8f9fa;
          padding: 10px;
          margin: 10px 0;
          border-left: 3px solid #008A82;
          border-radius: 4px;
        }
        
        /* Input and form styling */
        .form-control {
          border-radius: 8px !important;
          border: 2px solid #ddd !important;
          transition: border-color 0.3s ease, box-shadow 0.3s ease;
        }
        
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 3px rgba(0, 138, 130, 0.1) !important;
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
        
        .btn-success {
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important;
          border: none !important;
          border-radius: 8px !important;
        }
        
        .btn-warning {
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
          border: none !important;
          border-radius: 8px !important;
        }
        
        /* DataTable styling */
        .dataTables_wrapper .dataTables_paginate .paginate_button.current {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          color: white !important;
        }
        
        /* Spinner styling */
        .spinner-border {
          color: #008A82 !important;
        }
        
        /* Global text improvements */
        body, .content-wrapper {
          font-family: 'Segoe UI', 'Arial', sans-serif;
        }
        
        h1, h2, h3, h4, h5, h6 {
          color: #002C3C;
          font-weight: 600;
        }
        
        /* Custom scrollbar for boxes */
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
        
        .box-body::-webkit-scrollbar-thumb:hover {
          background: linear-gradient(135deg, #006b63, #007d75);
        }
      "))
    ),
    
    tabItems(
      # Tab 1: FX Market Overview
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Foreign Exchange Market Overview",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      h4("What is Foreign Exchange (FX)?"),
                      p("A market to exchange one currency for another for immediate or future delivery.")
                  ),
                  
                  fluidRow(
                    column(6,
                           h4("Key Market Features"),
                           tags$ul(
                             tags$li("Largest financial market globally - $6.6 trillion daily turnover"),
                             tags$li("True 24-hour, global market"),
                             tags$li("Traded Over-The-Counter (OTC) and on exchanges"),
                             tags$li("No central exchange or global regulator"),
                             tags$li("Extremely high liquidity"),
                             tags$li("Low transaction costs (tight spreads)")
                           )
                    ),
                    column(6,
                           h4("Market Evolution"),
                           tags$ul(
                             tags$li(strong("Pre-1973:"), "Bretton Woods - Fixed exchange rates"),
                             tags$li(strong("1973:"), "Bretton Woods collapsed - FX market born"),
                             tags$li(strong("1980s:"), "Computer trading revolutionized the market"),
                             tags$li(strong("1999:"), "Euro introduction"),
                             tags$li(strong("Today:"), "Algorithmic and high-frequency trading")
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("dailyTurnover", width = 3),
                valueBoxOutput("marketShare", width = 3),
                valueBoxOutput("tradingHours", width = 3),
                valueBoxOutput("currencies", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "FX Turnover by Instrument",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("turnoverByInstrument", height = "400px")
                ),
                box(
                  title = "Currency Distribution",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("currencyDistribution", height = "400px")
                )
              ),
              
              fluidRow(
                box(
                  title = "Market Trading Hours & Activity",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("tradingHoursChart", height = "300px"),
                  div(class = "key-point",
                      strong("Active Trading Time:"), " 07:00 - 18:00 London Time (peak liquidity when London and New York overlap)"
                  )
                )
              )
      ),
      
      # Tab 2: Market Structure
      tabItem(tabName = "structure",
              fluidRow(
                box(
                  title = "FX Market Participants",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-box",
                      h4("Market Structure"),
                      p("The FX market consists of various participants with different roles and objectives.")
                  ),
                  
                  fluidRow(
                    column(6,
                           h4("Sell-Side Institutions"),
                           div(class = "key-point",
                               tags$ul(
                                 tags$li(strong("Investment Banks:"), " Provide liquidity, make markets"),
                                 tags$li(strong("Commercial Banks:"), " Facilitate client transactions"),
                                 tags$li(strong("Market Makers:"), " Quote bid/ask prices continuously")
                               )
                           ),
                           br(),
                           h4("Top 10 FX Providers (2022)"),
                           tags$ol(
                             tags$li("JPMorgan - 10.8%"),
                             tags$li("UBS - 8.9%"),
                             tags$li("Deutsche Bank - 8.2%"),
                             tags$li("XTX Markets - 7.1%"),
                             tags$li("Citi - 6.8%"),
                             tags$li("Jump Trading - 4.8%"),
                             tags$li("Goldman Sachs - 4.5%"),
                             tags$li("Bank of America - 4.3%"),
                             tags$li("State Street - 4.2%"),
                             tags$li("HSBC - 4.1%")
                           )
                    ),
                    column(6,
                           h4("Buy-Side Institutions"),
                           div(class = "key-point",
                               tags$ul(
                                 tags$li(strong("Hedge Funds:"), " Speculative trading for returns"),
                                 tags$li(strong("Asset Managers:"), " Currency overlay & hedging"),
                                 tags$li(strong("Corporations:"), " Hedging commercial transactions"),
                                 tags$li(strong("Retail Traders:"), " Individual speculation")
                               )
                           ),
                           br(),
                           h4("Central Banks"),
                           div(class = "warning-box",
                               p(strong("Role:"), " Implement monetary policy, manage currency reserves, intervene in FX markets"),
                               p("Major central banks: Fed (US), ECB (Europe), BoE (UK), BoJ (Japan), RBA (Australia)")
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Market Share by Institution Type",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("institutionShare", height = "400px")
                ),
                box(
                  title = "FX Reserves by Country (Top 10)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("fxReserves", height = "400px")
                )
              ),
              
              fluidRow(
                box(
                  title = "Central Bank Intervention",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  h4("Central Bank Tools & Objectives"),
                  fluidRow(
                    column(6,
                           div(class = "key-point",
                               h5("Actions"),
                               tags$ul(
                                 tags$li("Quantitative Easing (QE)"),
                                 tags$li("Direct currency intervention"),
                                 tags$li("Interest rate adjustments"),
                                 tags$li("Forward guidance")
                               )
                           )
                    ),
                    column(6,
                           div(class = "key-point",
                               h5("Aims"),
                               tags$ul(
                                 tags$li("Stimulate economic growth"),
                                 tags$li("Control inflation"),
                                 tags$li("Stabilize currency"),
                                 tags$li("Support employment")
                               )
                           )
                    )
                  ),
                  
                  div(class = "concept-box",
                      h5("Historical Example: Bank of Japan (2012-2014)"),
                      p("Prime Minister Shinzo Abe implemented Abenomics to weaken the yen:"),
                      tags$ul(
                        tags$li("Massive quantitative easing program"),
                        tags$li("Fiscal stimulus to boost employment"),
                        tags$li("Structural economic reforms")
                      ),
                      p(strong("Result:"), " USD/JPY moved from 80 to 110 (37.5% yen depreciation)")
                  )
                )
              )
      ),
      
      # Tab 3: Price Construction
      tabItem(tabName = "pricing",
              fluidRow(
                box(
                  title = "FX Price Construction & Market Mechanics",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      h4("Understanding FX Quotes"),
                      p("FX prices are quoted as currency pairs with a Base currency and Term (Quote) currency.")
                  ),
                  
                  fluidRow(
                    column(6,
                           h4("Price Components"),
                           div(class = "key-point",
                               h5("EUR/USD 1.1865"),
                               tags$ul(
                                 tags$li(strong("EUR"), " = Base Currency"),
                                 tags$li(strong("USD"), " = Term (Quote) Currency"),
                                 tags$li(strong("1.18"), " = Big Figure"),
                                 tags$li(strong("65"), " = Pips (points)")
                               ),
                               p("This is read as: 'One euro, eighteen sixty-five'")
                           ),
                           
                           br(),
                           
                           div(class = "concept-box",
                               h5("Currency Pair Types"),
                               p(strong("Dollar-based pairs:"), " USD is base currency"),
                               tags$ul(
                                 tags$li("USD/CHF, USD/JPY, USD/CAD")
                               ),
                               p(strong("Dollar-term pairs:"), " USD is term currency"),
                               tags$ul(
                                 tags$li("EUR/USD, GBP/USD, AUD/USD")
                               )
                           )
                    ),
                    
                    column(6,
                           h4("Bid-Ask Spread"),
                           div(class = "key-point",
                               p(strong("Bid:"), " Price at which market maker buys"),
                               p(strong("Ask (Offer):"), " Price at which market maker sells"),
                               p(strong("Spread:"), " Difference between Ask and Bid")
                           ),
                           
                           br(),
                           
                           div(class = "warning-box",
                               h5("Important Concepts"),
                               tags$ul(
                                 tags$li(strong("Price Maker:"), " Has obligation to trade"),
                                 tags$li(strong("Price Taker:"), " Has choice to trade"),
                                 tags$li("Price maker buys on BID, sells on ASK"),
                                 tags$li("Price taker sells on BID, buys on ASK"),
                                 tags$li("Price taker always 'pays the spread'")
                               )
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Live FX Quotes",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("liveQuotes")
                )
              ),
              
              fluidRow(
                box(
                  title = "Spread Comparison: Trading vs Bureau de Change",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h5("GBP/USD Spread Comparison"),
                  div(class = "key-point",
                      p(strong("Inter-bank Trading:"), " 1.43344 / 1.43352"),
                      p("Spread: 0.8 pips (0.006%)"),
                      br(),
                      p(strong("Holiday Money Exchange:"), " 1.6314 / 1.1912"),
                      p("Spread: 4,963 pips (37%)"),
                      br(),
                      p(tags$span(style = "color: red; font-size: 18px;", 
                                  "That's 6,200 times wider!"))
                  )
                ),
                
                box(
                  title = "FX Jargon",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h5("Common Market Terms"),
                  tags$ul(
                    tags$li(strong("CABLE:"), " GBP/USD"),
                    tags$li(strong("EURO:"), " EUR/USD"),
                    tags$li(strong("AUSSIE:"), " AUD or AUD/USD"),
                    tags$li(strong("KIWI:"), " NZD or NZD/USD"),
                    tags$li(strong("LOONIE:"), " CAD"),
                    tags$li(strong("SWISSIE:"), " CHF"),
                    tags$li(strong("YEN:"), " JPY"),
                    tags$li(strong("FIGURE:"), " 00 level (e.g., 1.2000)")
                  )
                )
              )
      ),
      
      # Tab 4: Support & Resistance
      tabItem(tabName = "support",
              fluidRow(
                box(
                  title = "Support and Resistance Levels",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-box",
                      h4("Core Concepts"),
                      p(strong("Support:"), " A price level where buying pressure overcomes selling pressure, preventing the price from falling further."),
                      p(strong("Resistance:"), " A price level where selling pressure overcomes buying pressure, preventing the price from rising further.")
                  ),
                  
                  fluidRow(
                    column(6,
                           h4("Support Levels"),
                           div(class = "key-point",
                               p("Formed when many buyers want to buy at the same (low) price"),
                               p(strong("Characteristics:")),
                               tags$ul(
                                 tags$li("Demand satisfies supply"),
                                 tags$li("Buying pressure controls the level"),
                                 tags$li("Price bounces up from this level")
                               )
                           )
                    ),
                    column(6,
                           h4("Resistance Levels"),
                           div(class = "key-point",
                               p("Formed when many sellers want to sell at the same (high) price"),
                               p(strong("Characteristics:")),
                               tags$ul(
                                 tags$li("Supply overcomes demand"),
                                 tags$li("Selling pressure controls the level"),
                                 tags$li("Price bounces down from this level")
                               )
                           )
                    )
                  ),
                  
                  div(class = "warning-box",
                      h4("Level Strength Factors"),
                      tags$ul(
                        tags$li(strong("Number of touches:"), " More touches = stronger level"),
                        tags$li(strong("Time validity:"), " Longer time in place = stronger level"),
                        tags$li(strong("Volume:"), " High volume at level = more significant")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Interactive Support & Resistance Chart",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           checkboxInput("show_support", "Show Support Levels", value = TRUE)
                    ),
                    column(3,
                           checkboxInput("show_resistance", "Show Resistance Levels", value = TRUE)
                    ),
                    column(3,
                           checkboxInput("show_breaks", "Highlight Breakouts", value = TRUE)
                    ),
                    column(3,
                           numericInput("lookback_sr", "Lookback Period:", value = 20, min = 10, max = 50)
                    )
                  ),
                  
                  withSpinner(plotlyOutput("supportResistanceChart", height = "500px")),
                  
                  div(class = "info-box",
                      h5("Trading Strategy"),
                      p(strong("Entry:"), " Buy at support / Sell at resistance"),
                      p(strong("Stop Loss:"), " Below support (long) / Above resistance (short)"),
                      p(strong("Breakout:"), " When level is broken, it often becomes the opposite (support becomes resistance)")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Stop Loss Placement",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "warning-box",
                      h4("Critical Rule: Stop Loss at Price Levels That Disprove the Trade"),
                      p("Traders often make the mistake of choosing stops as pain thresholds rather than price levels that disprove the trade. - Colm O'Shea (Market Wizard)")
                  ),
                  
                  fluidRow(
                    column(6,
                           div(class = "key-point",
                               h5("Correct Stop Placement"),
                               tags$ul(
                                 tags$li("Place stop beyond support/resistance"),
                                 tags$li("Allow for normal market volatility"),
                                 tags$li("If risk is too large, reduce position size"),
                                 tags$li("NEVER move stop closer to reduce risk")
                               )
                           )
                    ),
                    column(6,
                           div(class = "key-point",
                               h5("Why This Matters"),
                               tags$ul(
                                 tags$li("Stop at key level = invalidates your thesis"),
                                 tags$li("Stop too close = gets hit by noise"),
                                 tags$li("Moving stop toward price = gambling"),
                                 tags$li("Proper stop = capital preservation")
                               )
                           )
                    )
                  )
                )
              )
      ),
      
      # Tab 5: Trend Analysis
      tabItem(tabName = "trends",
              fluidRow(
                box(
                  title = "Trend Analysis & Trendlines",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-box",
                      h4("Trend Philosophy"),
                      p("Prices move in trends and trends persist - Core principle of technical analysis"),
                      p("Technical analysts aim to identify directional trends early and trade in that direction.")
                  ),
                  
                  fluidRow(
                    column(4,
                           div(class = "key-point",
                               h4("Uptrend"),
                               p("Series of higher highs AND higher lows"),
                               tags$ul(
                                 tags$li("Each peak higher than previous"),
                                 tags$li("Each trough higher than previous"),
                                 tags$li("Trendline connects higher lows")
                               )
                           )
                    ),
                    column(4,
                           div(class = "key-point",
                               h4("Downtrend"),
                               p("Series of lower highs AND lower lows"),
                               tags$ul(
                                 tags$li("Each peak lower than previous"),
                                 tags$li("Each trough lower than previous"),
                                 tags$li("Trendline connects lower highs")
                               )
                           )
                    ),
                    column(4,
                           div(class = "key-point",
                               h4("Sideways"),
                               p("No clear trend direction"),
                               tags$ul(
                                 tags$li("Price oscillates in range"),
                                 tags$li("Series of higher highs AND lower lows"),
                                 tags$li("Support and resistance horizontal")
                               )
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Trend Identification Chart",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           checkboxInput("show_trendlines", "Show Trendlines", value = TRUE)
                    ),
                    column(3,
                           checkboxInput("show_channels", "Show Channels", value = TRUE)
                    ),
                    column(3,
                           checkboxInput("show_swings", "Mark Swing Points", value = TRUE)
                    ),
                    column(3,
                           selectInput("trend_type", "Trend Detection:",
                                       choices = c("Auto", "Uptrend", "Downtrend", "Sideways"),
                                       selected = "Auto")
                    )
                  ),
                  
                  withSpinner(plotlyOutput("trendChart", height = "500px")),
                  
                  div(class = "info-box",
                      h5("Trendline Rules"),
                      tags$ul(
                        tags$li(strong("Valid trendline:"), " Requires minimum 3 touches"),
                        tags$li(strong("Strong trendline:"), " More touches, longer duration, sustainable gradient"),
                        tags$li(strong("Trendline break:"), " Signals potential trend reversal"),
                        tags$li(strong("Channel:"), " Drawn parallel to trendline to contain price action")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Trend Definitions & Confirmation",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Critical Levels for Trend Continuation"),
                  
                  div(class = "warning-box",
                      h5("Uptrend Maintenance"),
                      p(strong("Must Break:"), " Previous higher high (red level)"),
                      p(strong("Must NOT Break:"), " Previous higher low (green level)"),
                      p("If higher low breaks, end of uptrend")
                  ),
                  
                  div(class = "warning-box",
                      h5("Downtrend Maintenance"),
                      p(strong("Must Break:"), " Previous lower low (red level)"),
                      p(strong("Must NOT Break:"), " Previous lower high (green level)"),
                      p("If lower high breaks, end of downtrend")
                  )
                ),
                
                box(
                  title = "Price vs Confirmation Trade-Off",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Entry Timing Strategies"),
                  
                  tags$ol(
                    tags$li(
                      strong("Best Price (Least Confirmation)"),
                      p("- Bounce off trendline"),
                      p("- Bounce off support"),
                      p("- Highest risk, best reward")
                    ),
                    tags$li(
                      strong("Moderate Confirmation"),
                      p("- Break of counter-trendline"),
                      p("- Balanced risk/reward")
                    ),
                    tags$li(
                      strong("Most Confirmation (Worst Price)"),
                      p("- Break of previous high/low"),
                      p("- Break of resistance/support"),
                      p("- Lowest risk, worst reward")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Trend Channels",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(6,
                           h4("Channel Construction"),
                           div(class = "key-point",
                               tags$ul(
                                 tags$li("Draw trendline first (connecting lows/highs)"),
                                 tags$li("Draw channel line parallel to trendline"),
                                 tags$li("Channel should contain all price action"),
                                 tags$li("Not vice versa - trendline is primary")
                               )
                           )
                    ),
                    column(6,
                           h4("Channel Uses"),
                           div(class = "key-point",
                               tags$ul(
                                 tags$li(strong("Profit targets:"), " Take profit at channel top/bottom"),
                                 tags$li(strong("Trend strength:"), " Failure to reach channel = weakness"),
                                 tags$li(strong("Breakout targets:"), " Project channel width after break"),
                                 tags$li(strong("Risk management:"), " Tighten stops as price nears channel")
                               )
                           )
                    )
                  )
                )
              )
      ),
      
      # Tab 6: Candlestick Patterns
      tabItem(tabName = "candles",
              fluidRow(
                box(
                  title = "Japanese Candlestick Charting",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      h4("Candlestick Philosophy"),
                      p("Candlestick patterns identify short-term market sentiment and potential reversals."),
                      p("Developed in 18th century Japan by rice traders, adapted for modern financial markets.")
                  ),
                  
                  fluidRow(
                    column(6,
                           h4("Candlestick Anatomy"),
                           div(class = "key-point",
                               tags$ul(
                                 tags$li(strong("Real Body:"), " Area between open and close"),
                                 tags$li(strong("Upper Shadow:"), " High above real body"),
                                 tags$li(strong("Lower Shadow:"), " Low below real body"),
                                 tags$li(strong("Color:"), " White/Green = up, Black/Red = down")
                               )
                           ),
                           br(),
                           h4("Key Principles"),
                           tags$ul(
                             tags$li("Maximum 9-candle patterns"),
                             tags$li("Mostly reversal patterns"),
                             tags$li("Require confirmation"),
                             tags$li("More effective at support/resistance")
                           )
                    ),
                    column(6,
                           h4("What to Look For"),
                           div(class = "key-point",
                               tags$ul(
                                 tags$li(strong("Real body size:"), " Large = strong sentiment"),
                                 tags$li(strong("Shadow length:"), " Long shadow = rejection"),
                                 tags$li(strong("Body color:"), " White = bulls, Black = bears"),
                                 tags$li(strong("Pattern location:"), " At key levels matters")
                               )
                           ),
                           br(),
                           div(class = "warning-box",
                               p(strong("Confirmation Required!"), 
                                 " Wait for next candle or support/resistance break before trading")
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Single Candlestick Patterns",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           div(class = "key-point",
                               h5("Doji"),
                               p("Open = Close"),
                               p(strong("Types:")),
                               tags$ul(
                                 tags$li("Long-legged: Indecision"),
                                 tags$li("Gravestone: Bearish reversal"),
                                 tags$li("Dragonfly: Bullish reversal"),
                                 tags$li("Doji Star: Strong reversal")
                               )
                           )
                    ),
                    column(3,
                           div(class = "key-point",
                               h5("Hammer / Hanging Man"),
                               p("Small body, long lower shadow"),
                               p(strong("Hammer:"), " Bullish at support"),
                               p(strong("Hanging Man:"), " Bearish at resistance"),
                               p("Shadow 2-3x body length")
                           )
                    ),
                    column(3,
                           div(class = "key-point",
                               h5("Shooting Star / Inverted Hammer"),
                               p("Small body, long upper shadow"),
                               p(strong("Shooting Star:"), " Bearish at new high"),
                               p(strong("Inverted Hammer:"), " Bullish at support"),
                               p("Shows rejection of higher prices")
                           )
                    ),
                    column(3,
                           div(class = "key-point",
                               h5("Marubozu"),
                               p("No shadows at all"),
                               p("Very strong continuation"),
                               p("50% level becomes critical"),
                               p("Most common in trending markets")
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Double Candlestick Patterns",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(4,
                           div(class = "warning-box",
                               h5("Engulfing Patterns"),
                               p(strong("Strongest reversal pattern")),
                               p(strong("Bullish:"), " White candle engulfs previous black"),
                               p(strong("Bearish:"), " Black candle engulfs previous white"),
                               p("Second candle body completely contains first")
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h5("Piercing Pattern"),
                               p("Bullish reversal at support"),
                               p("Opens below previous low"),
                               p("Closes >50% into previous body"),
                               p("Shows strong buying pressure")
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h5("Dark Cloud Cover"),
                               p("Bearish reversal at resistance"),
                               p("Opens above previous high"),
                               p("Closes >50% into previous body"),
                               p("Shows strong selling pressure")
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Live Candlestick Pattern Detection",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(4,
                           checkboxGroupInput("pattern_types", "Pattern Types to Highlight:",
                                              choices = c("Doji", "Hammer", "Shooting Star", 
                                                          "Engulfing", "Piercing/Dark Cloud"),
                                              selected = c("Doji", "Engulfing"))
                    ),
                    column(4,
                           checkboxInput("show_stochastic", "Show Stochastic Confirmation", value = TRUE)
                    ),
                    column(4,
                           checkboxInput("highlight_patterns", "Highlight Detected Patterns", value = TRUE)
                    )
                  ),
                  
                  withSpinner(plotlyOutput("candlestickChart", height = "500px")),
                  
                  DTOutput("detectedPatterns")
                )
              )
      ),
      
      # Tab 7: Technical Indicators
      tabItem(tabName = "indicators",
              fluidRow(
                box(
                  title = "Technical Indicators Overview",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "concept-box",
                      h4("What are Technical Indicators?"),
                      p("Mathematical calculations based on price, volume, or open interest that help predict future price movements.")
                  ),
                  
                  fluidRow(
                    column(6,
                           h4("Indicator Categories"),
                           div(class = "key-point",
                               p(strong("Trend Indicators")),
                               tags$ul(
                                 tags$li("Moving Averages (SMA, EMA)"),
                                 tags$li("MACD"),
                                 tags$li("ADX")
                               ),
                               br(),
                               p(strong("Momentum Oscillators")),
                               tags$ul(
                                 tags$li("RSI (Relative Strength Index)"),
                                 tags$li("Stochastic"),
                                 tags$li("CCI, Williams %R")
                               )
                           )
                    ),
                    column(6,
                           h4("Using Indicators Effectively"),
                           div(class = "warning-box",
                               tags$ul(
                                 tags$li("No indicator is perfect"),
                                 tags$li("Use multiple indicators for confirmation"),
                                 tags$li("Combine with support/resistance"),
                                 tags$li("Indicators lag price - they don't predict"),
                                 tags$li("Adjust parameters for your timeframe")
                               )
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Moving Averages",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Simple Moving Average (SMA)"),
                  p("Average price over specific period"),
                  
                  div(class = "key-point",
                      p(strong("Common Periods:")),
                      tags$ul(
                        tags$li("20 SMA - Short term trend"),
                        tags$li("50 SMA - Medium term trend"),
                        tags$li("200 SMA - Long term trend")
                      ),
                      br(),
                      p(strong("Trading Signals:")),
                      tags$ul(
                        tags$li("Price above MA = Bullish"),
                        tags$li("Price below MA = Bearish"),
                        tags$li("MA crossovers = Trend change")
                      )
                  )
                ),
                
                box(
                  title = "RSI (Relative Strength Index)",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("RSI (14-period standard)"),
                  p("Measures momentum on 0-100 scale"),
                  
                  div(class = "key-point",
                      p(strong("Interpretation:")),
                      tags$ul(
                        tags$li("RSI > 70 = Overbought (potential sell)"),
                        tags$li("RSI < 30 = Oversold (potential buy)"),
                        tags$li("RSI 40-60 = Neutral zone")
                      ),
                      br(),
                      p(strong("Advanced Signals:")),
                      tags$ul(
                        tags$li("Divergence: Price vs RSI direction"),
                        tags$li("Failure swings: RSI pattern reversals"),
                        tags$li("Centerline crossovers: 50 level")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Multi-Indicator Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           checkboxGroupInput("indicators", "Select Indicators:",
                                              choices = c("SMA 20", "SMA 50", "EMA 20", 
                                                          "Bollinger Bands", "MACD"),
                                              selected = c("SMA 20", "Bollinger Bands"))
                    ),
                    column(3,
                           numericInput("sma_period", "SMA Period:", value = 20, min = 5, max = 200)
                    ),
                    column(3,
                           numericInput("rsi_period", "RSI Period:", value = 14, min = 5, max = 50)
                    ),
                    column(3,
                           numericInput("bb_sd", "Bollinger Bands SD:", value = 2, min = 1, max = 3, step = 0.5)
                    )
                  ),
                  
                  withSpinner(plotlyOutput("indicatorChart", height = "400px")),
                  
                  fluidRow(
                    column(6,
                           withSpinner(plotlyOutput("rsiChart", height = "200px"))
                    ),
                    column(6,
                           withSpinner(plotlyOutput("macdChart", height = "200px"))
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Current Signal Summary",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("signalSummary")
                )
              )
      ),
      
      # Tab 8: Trading Psychology
      tabItem(tabName = "psychology",
              fluidRow(
                box(
                  title = "Trading Psychology & Behavioral Finance",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "warning-box",
                      h3("The Most Important Factor in Trading Success"),
                      p(style = "font-size: 18px;", 
                        "No matter how good your trading strategy, if you cannot control your emotions, then you will fail as a trader.")
                  ),
                  
                  fluidRow(
                    column(6,
                           h4("Key Psychological Concepts"),
                           div(class = "key-point",
                               tags$ul(
                                 tags$li(strong("Fear & Greed:"), " Primary emotions driving markets"),
                                 tags$li(strong("Loss Aversion:"), " Losses hurt ~2x more than gains feel good"),
                                 tags$li(strong("Confirmation Bias:"), " Seeking info that confirms beliefs"),
                                 tags$li(strong("Recency Bias:"), " Overweighting recent events"),
                                 tags$li(strong("Overconfidence:"), " Believing you know more than you do")
                               )
                           )
                    ),
                    column(6,
                           h4("Famous Trader Quotes"),
                           div(class = "concept-box",
                               p("Markets reflect human nature and human nature does not change"),
                               p(style = "text-align: right;", "- Jack Schwager"),
                               br(),
                               p("Markets invariably move to undervalued and overvalued extremes because human nature falls victim to greed and/or fear."),
                               p(style = "text-align: right;", "- William Gross")
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "The Role of Emotions in Trading",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Emotional Cycle of Trading"),
                  plotlyOutput("emotionalCycle", height = "400px"),
                  
                  div(class = "info-box",
                      h5("Breaking the Cycle"),
                      tags$ul(
                        tags$li("Follow your trading plan rigorously"),
                        tags$li("Use proper position sizing"),
                        tags$li("Set stops before entering trades"),
                        tags$li("Take breaks after losses"),
                        tags$li("Keep a trading journal")
                      )
                  )
                ),
                
                box(
                  title = "Common Trading Mistakes",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Top 10 Psychological Traps"),
                  tags$ol(
                    tags$li("Moving stops to avoid taking a loss"),
                    tags$li("Revenge trading after a loss"),
                    tags$li("Overtrading (too many positions)"),
                    tags$li("Position sizing too large"),
                    tags$li("Not taking profits at targets"),
                    tags$li("Adding to losing positions"),
                    tags$li("Trading without a plan"),
                    tags$li("Ignoring risk management rules"),
                    tags$li("Letting winners turn into losers"),
                    tags$li("Trading based on hope, not analysis")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Market Sentiment vs Fundamentals",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  h4("Price Leads Fundamentals"),
                  
                  div(class = "concept-box",
                      p("Buy the rumor, sell the fact - Market prices often move before news is released, as traders anticipate and position accordingly."),
                      br(),
                      p("Example: French Elections 2017 (Macron vs Le Pen)"),
                      tags$ul(
                        tags$li("EUR/USD rallied strongly after 1st round (unexpected Macron lead)"),
                        tags$li("Small gap up on final victory - already priced in"),
                        tags$li("Immediate profit-taking once confirmed")
                      )
                  ),
                  
                  fluidRow(
                    column(6,
                           div(class = "key-point",
                               h5("Why This Happens"),
                               tags$ul(
                                 tags$li("Smart money acts on expectations"),
                                 tags$li("Information leaks before official release"),
                                 tags$li("Traders position ahead of events"),
                                 tags$li("Price discounts all known information")
                               )
                           )
                    ),
                    column(6,
                           div(class = "key-point",
                               h5("How to Trade It"),
                               tags$ul(
                                 tags$li("Watch for price action before news"),
                                 tags$li("Fade the initial reaction if overdone"),
                                 tags$li("Use technical levels for entries"),
                                 tags$li("Don't fight the tape")
                               )
                           )
                    )
                  )
                )
              )
      ),
      
      # Tab 9: Risk Management
      tabItem(tabName = "risk",
              fluidRow(
                box(
                  title = "Risk Management: The Key to Long-Term Success",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "warning-box",
                      h3("Golden Rule"),
                      p(style = "font-size: 18px;", 
                        "It is not whether you are right or wrong, but how much money you make when you are right and how much you lose when you are wrong. - George Soros")
                  ),
                  
                  fluidRow(
                    column(6,
                           h4("Core Principles"),
                           div(class = "key-point",
                               tags$ul(
                                 tags$li(strong("Capital Preservation:"), " Protect your trading capital above all"),
                                 tags$li(strong("Position Sizing:"), " Risk only 1-2% per trade"),
                                 tags$li(strong("Stop Losses:"), " Always use them, never move them"),
                                 tags$li(strong("Reward:Risk Ratio:"), " Target minimum 2:1"),
                                 tags$li(strong("Diversification:"), " Don't put all eggs in one basket")
                               )
                           )
                    ),
                    column(6,
                           h4("The Mathematics of Losses"),
                           div(class = "warning-box",
                               p("Recovery needed after drawdown:"),
                               tags$ul(
                                 tags$li("10% loss needs 11% gain"),
                                 tags$li("20% loss needs 25% gain"),
                                 tags$li("30% loss needs 43% gain"),
                                 tags$li("50% loss needs 100% gain"),
                                 tags$li("75% loss needs 300% gain")
                               )
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Drawdown vs Recovery Analysis",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("drawdownRecovery", height = "400px")
                ),
                
                box(
                  title = "Hit Rate vs Reward:Risk Ratio",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("hitRateRRR", height = "400px")
                )
              ),
              
              fluidRow(
                box(
                  title = "Position Sizing Calculator",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Calculate Proper Position Size"),
                  
                  numericInput("account_size", "Account Size ($):", value = 50000, min = 1000, step = 1000),
                  numericInput("risk_percent", "Risk per Trade (%):", value = 1, min = 0.5, max = 5, step = 0.5),
                  numericInput("stop_pips", "Stop Loss (pips):", value = 50, min = 10, max = 200),
                  numericInput("pip_value", "Pip Value ($):", value = 10, min = 1, max = 100),
                  
                  br(),
                  
                  div(class = "key-point",
                      h4("Recommended Position Size"),
                      verbatimTextOutput("position_size"),
                      br(),
                      p("This ensures you only risk the specified percentage of your account on this trade.")
                  )
                ),
                
                box(
                  title = "Risk Management Scenarios",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Comparing Two Traders"),
                  
                  div(class = "concept-box",
                      h5("Trader A: Poor Risk Management"),
                      tags$ul(
                        tags$li("20 wins at 2% each = +40%"),
                        tags$li("20 losses at 2% each = -40%"),
                        tags$li(strong("Net Result: -0.8%"))
                      )
                  ),
                  
                  div(class = "key-point",
                      h5("Trader B: Good Risk Management"),
                      tags$ul(
                        tags$li("20 wins at 3% each = +60%"),
                        tags$li("20 losses at 1% each = -20%"),
                        tags$li(strong("Net Result: +47.7%"))
                      )
                  ),
                  
                  div(class = "warning-box",
                      p(strong("Same win rate (50%), dramatically different results!"),
                        " Risk management is everything.")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Maximum Drawdown Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(4,
                           h4("What is Drawdown?"),
                           div(class = "key-point",
                               p("Drawdown is the decline in account equity from a peak to a trough."),
                               p(strong("Formula:")),
                               p("DD% = (Trough Value - Peak Value) / Peak Value x 100")
                           )
                    ),
                    column(4,
                           h4("Managing Drawdowns"),
                           div(class = "key-point",
                               tags$ul(
                                 tags$li("Set maximum drawdown limit (e.g., 20%)"),
                                 tags$li("Reduce position size after losses"),
                                 tags$li("Take a break at drawdown limit"),
                                 tags$li("Review strategy if DD exceeds threshold"),
                                 tags$li("Keep drawdowns small and infrequent")
                               )
                           )
                    ),
                    column(4,
                           h4("Professional Standards"),
                           div(class = "concept-box",
                               p(strong("Hedge Fund Typical Limits:")),
                               tags$ul(
                                 tags$li("Max DD: 10-15%"),
                                 tags$li("Daily loss limit: 2-3%"),
                                 tags$li("Position sizing: 1-2% risk"),
                                 tags$li("Stop trading at limit")
                               )
                           )
                    )
                  )
                )
              )
      ),
      
      # Tab 10: Interactive Trading
      tabItem(tabName = "trading",
              fluidRow(
                box(
                  title = "Interactive Trading Simulator",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "info-box",
                      h4("Practice Your Trading Skills"),
                      p("Use this simulator to practice identifying trade setups and managing positions. All concepts from the course are integrated here.")
                  ),
                  
                  fluidRow(
                    column(3,
                           numericInput("sim_capital", "Starting Capital ($):", 
                                        value = 100000, min = 10000, step = 10000)
                    ),
                    column(3,
                           numericInput("sim_risk", "Risk per Trade (%):", 
                                        value = 1, min = 0.5, max = 5, step = 0.5)
                    ),
                    column(3,
                           selectInput("trade_direction", "Trade Direction:",
                                       choices = c("Select" = "", "Long (Buy)", "Short (Sell)"))
                    ),
                    column(3,
                           actionButton("place_trade", "Place Trade", 
                                        class = "btn-success btn-lg", style = "margin-top: 25px;")
                    )
                  ),
                  
                  fluidRow(
                    column(4,
                           numericInput("entry_price", "Entry Price:", value = 0, step = 0.0001)
                    ),
                    column(4,
                           numericInput("stop_loss", "Stop Loss:", value = 0, step = 0.0001)
                    ),
                    column(4,
                           numericInput("take_profit", "Take Profit:", value = 0, step = 0.0001)
                    )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("sim_equity", width = 3),
                valueBoxOutput("sim_trades", width = 3),
                valueBoxOutput("sim_winrate", width = 3),
                valueBoxOutput("sim_pnl", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Live Chart with Trade Levels",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  
                  checkboxGroupInput("chart_overlays", "Chart Overlays:",
                                     choices = c("Support/Resistance", "Trendlines", 
                                                 "Moving Averages", "Candlestick Patterns"),
                                     selected = c("Support/Resistance", "Moving Averages"),
                                     inline = TRUE),
                  
                  withSpinner(plotlyOutput("tradingChart", height = "500px"))
                ),
                
                box(
                  title = "Trade Analysis",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  
                  h4("Current Setup Analysis"),
                  verbatimTextOutput("setup_analysis"),
                  
                  br(),
                  
                  h4("Risk/Reward Calculation"),
                  verbatimTextOutput("rrr_calc"),
                  
                  br(),
                  
                  div(class = "key-point",
                      h5("Trade Checklist"),
                      tags$ul(
                        tags$li(icon("square"), " Identified trend direction"),
                        tags$li(icon("square"), " Located support/resistance"),
                        tags$li(icon("square"), " Found entry trigger"),
                        tags$li(icon("square"), " Set stop loss at logical level"),
                        tags$li(icon("square"), " Target has R:R > 2:1"),
                        tags$li(icon("square"), " Position size calculated"),
                        tags$li(icon("square"), " Confirmed with indicators")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Trade History",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("trade_history")
                )
              ),
              
              fluidRow(
                box(
                  title = "Equity Curve",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("equity_curve", height = "300px")
                ),
                
                box(
                  title = "Performance Metrics",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Trading Statistics"),
                  verbatimTextOutput("performance_stats"),
                  
                  br(),
                  
                  actionButton("reset_sim", "Reset Simulator", 
                               class = "btn-warning", style = "width: 100%;")
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive data
  fx_data <- reactive({
    generate_fx_data(days = input$time_period, pair = input$currency_pair)
  })
  
  # Tab 1: FX Market Overview - Value Boxes
  output$dailyTurnover <- renderValueBox({
    valueBox(
      "$6.6T",
      "Daily FX Turnover",
      icon = icon("dollar-sign"),
      color = "blue"
    )
  })
  
  output$marketShare <- renderValueBox({
    valueBox(
      "54.2%",
      "UK Market Share",
      icon = icon("chart-pie"),
      color = "green"
    )
  })
  
  output$tradingHours <- renderValueBox({
    valueBox(
      "24/5",
      "Trading Hours",
      icon = icon("clock"),
      color = "purple"
    )
  })
  
  output$currencies <- renderValueBox({
    valueBox(
      "180+",
      "Global Currencies",
      icon = icon("globe"),
      color = "yellow"
    )
  })
  
  # Turnover by Instrument
  output$turnoverByInstrument <- renderPlotly({
    data <- data.frame(
      Instrument = c("Spot", "FX Swaps", "Forwards", "Currency Swaps", "Options"),
      Volume = c(2000, 3200, 900, 100, 400)
    )
    
    plot_ly(data, x = ~Instrument, y = ~Volume, type = 'bar',
            marker = list(color = c('#3498db', '#2ecc71', '#f39c12', '#e74c3c', '#9b59b6'))) %>%
      layout(title = "Daily FX Turnover by Instrument ($billions)",
             yaxis = list(title = "Volume ($billions)"),
             xaxis = list(title = ""),
             plot_bgcolor = '#ffffff',
             paper_bgcolor = '#ffffff')
  })
  
  # Currency Distribution
  output$currencyDistribution <- renderPlotly({
    data <- data.frame(
      Currency = c("USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "Other"),
      Share = c(88.3, 32.3, 16.8, 12.8, 6.8, 6.6, 5.2, 30.2)
    )
    
    plot_ly(data, labels = ~Currency, values = ~Share, type = 'pie',
            marker = list(colors = c('#3498db', '#2ecc71', '#f39c12', '#e74c3c', 
                                     '#9b59b6', '#1abc9c', '#34495e', '#95a5a6'))) %>%
      layout(title = "Currency Share (% of daily turnover)")
  })
  
  # Trading Hours Chart
  output$tradingHoursChart <- renderPlotly({
    hours <- 0:23
    volume <- c(50, 40, 35, 30, 25, 30, 100, 250, 450, 500, 480, 460, 
                450, 420, 480, 520, 550, 450, 300, 200, 150, 120, 80, 60)
    
    data <- data.frame(Hour = hours, Volume = volume)
    
    plot_ly(data, x = ~Hour, y = ~Volume, type = 'scatter', mode = 'lines',
            fill = 'tozeroy', fillcolor = 'rgba(52, 152, 219, 0.3)',
            line = list(color = '#3498db', width = 3)) %>%
      add_segments(x = 7, xend = 18, y = 0, yend = 0,
                   line = list(color = '#27ae60', width = 8),
                   name = "Peak Trading") %>%
      layout(title = "FX Market Intraday Activity",
             xaxis = list(title = "Hour (London Time)"),
             yaxis = list(title = "Volume ($billions)"),
             plot_bgcolor = '#ffffff',
             paper_bgcolor = '#ffffff',
             showlegend = TRUE)
  })
  
  # Tab 2: Market Structure
  output$institutionShare <- renderPlotly({
    data <- data.frame(
      Type = c("Investment Banks", "Market Makers", "Hedge Funds", 
               "Asset Managers", "Corporations", "Retail"),
      Share = c(40, 25, 15, 10, 7, 3)
    )
    
    plot_ly(data, labels = ~Type, values = ~Share, type = 'pie',
            hole = 0.4) %>%
      layout(title = "FX Market Participants")
  })
  
  output$fxReserves <- renderPlotly({
    data <- data.frame(
      Country = c("China", "Japan", "Switzerland", "India", "Russia", 
                  "Taiwan", "Hong Kong", "Saudi Arabia", "S. Korea", "Singapore"),
      Reserves = c(3301, 1322, 1064, 593, 585, 545, 465, 451, 449, 365)
    )
    
    plot_ly(data, x = ~reorder(Country, Reserves), y = ~Reserves, type = 'bar',
            marker = list(color = '#3498db')) %>%
      layout(title = "FX Currency Reserves 2022 ($billions)",
             xaxis = list(title = ""),
             yaxis = list(title = "Reserves ($billions)"),
             plot_bgcolor = '#ffffff',
             paper_bgcolor = '#ffffff')
  })
  
  # Tab 3: Live FX Quotes
  output$liveQuotes <- renderDT({
    data <- data.frame(
      Pair = c("EUR/USD", "GBP/USD", "USD/JPY", "USD/CHF", "AUD/USD", "USD/CAD"),
      Bid = c(1.18650, 1.34065, 110.145, 0.91998, 0.76802, 1.30358),
      Ask = c(1.18668, 1.34082, 110.162, 0.92015, 0.76819, 1.30375),
      Spread = c(1.8, 1.7, 1.7, 1.7, 1.7, 1.7),
      Change = c("+0.23%", "-0.15%", "+0.08%", "-0.12%", "+0.31%", "-0.09%")
    )
    
    datatable(data, 
              options = list(dom = 't', pageLength = 10),
              rownames = FALSE) %>%
      formatRound(c('Bid', 'Ask'), digits = 5) %>%
      formatRound('Spread', digits = 1)
  })
  
  # Tab 4: Support & Resistance Chart
  output$supportResistanceChart <- renderPlotly({
    data <- fx_data()
    
    # Calculate support and resistance
    lookback <- input$lookback_sr
    highs <- rollapply(data$High, width = lookback, FUN = max, align = "center", fill = NA)
    lows <- rollapply(data$Low, width = lookback, FUN = min, align = "center", fill = NA)
    
    p <- plot_ly(data, x = ~Date, type = 'candlestick',
                 open = ~Open, high = ~High, low = ~Low, close = ~Close,
                 name = input$currency_pair,
                 increasing = list(line = list(color = '#27ae60')),
                 decreasing = list(line = list(color = '#e74c3c')))
    
    if (input$show_support) {
      support_level <- quantile(data$Low, 0.2, na.rm = TRUE)
      p <- p %>% add_segments(x = min(data$Date), xend = max(data$Date),
                              y = support_level, yend = support_level,
                              line = list(color = '#27ae60', width = 2, dash = 'dash'),
                              name = "Support")
    }
    
    if (input$show_resistance) {
      resistance_level <- quantile(data$High, 0.8, na.rm = TRUE)
      p <- p %>% add_segments(x = min(data$Date), xend = max(data$Date),
                              y = resistance_level, yend = resistance_level,
                              line = list(color = '#e74c3c', width = 2, dash = 'dash'),
                              name = "Resistance")
    }
    
    p %>% layout(title = paste("Support & Resistance -", input$currency_pair),
                 xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
                 yaxis = list(title = "Price"),
                 plot_bgcolor = '#ffffff',
                 paper_bgcolor = '#ffffff')
  })
  
  # Tab 5: Trend Analysis Chart
  output$trendChart <- renderPlotly({
    data <- fx_data()
    
    p <- plot_ly(data, x = ~Date, type = 'candlestick',
                 open = ~Open, high = ~High, low = ~Low, close = ~Close,
                 name = input$currency_pair,
                 increasing = list(line = list(color = '#27ae60')),
                 decreasing = list(line = list(color = '#e74c3c')))
    
    if (input$show_trendlines) {
      # Simple trendline using linear regression
      x_numeric <- as.numeric(data$Date)
      y <- data$Close
      model <- lm(y ~ x_numeric)
      trend_line <- predict(model)
      
      p <- p %>% add_lines(x = data$Date, y = trend_line,
                           line = list(color = '#3498db', width = 2),
                           name = "Trendline")
    }
    
    if (input$show_channels) {
      x_numeric <- as.numeric(data$Date)
      model <- lm(data$Close ~ x_numeric)
      residuals <- residuals(model)
      upper_channel <- predict(model) + 2 * sd(residuals)
      lower_channel <- predict(model) - 2 * sd(residuals)
      
      p <- p %>%
        add_lines(x = data$Date, y = upper_channel,
                  line = list(color = '#95a5a6', width = 1, dash = 'dot'),
                  name = "Upper Channel") %>%
        add_lines(x = data$Date, y = lower_channel,
                  line = list(color = '#95a5a6', width = 1, dash = 'dot'),
                  name = "Lower Channel")
    }
    
    if (input$show_swings) {
      # Mark local maxima and minima
      swing_high_idx <- which(diff(sign(diff(data$High))) == -2) + 1
      swing_low_idx <- which(diff(sign(diff(data$Low))) == 2) + 1
      
      if (length(swing_high_idx) > 0) {
        p <- p %>% add_markers(x = data$Date[swing_high_idx], 
                               y = data$High[swing_high_idx],
                               marker = list(color = '#e74c3c', size = 10, symbol = 'triangle-down'),
                               name = "Swing High")
      }
      
      if (length(swing_low_idx) > 0) {
        p <- p %>% add_markers(x = data$Date[swing_low_idx], 
                               y = data$Low[swing_low_idx],
                               marker = list(color = '#27ae60', size = 10, symbol = 'triangle-up'),
                               name = "Swing Low")
      }
    }
    
    p %>% layout(title = paste("Trend Analysis -", input$currency_pair),
                 xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
                 yaxis = list(title = "Price"),
                 plot_bgcolor = '#ffffff',
                 paper_bgcolor = '#ffffff')
  })
  
  # Tab 6: Candlestick Pattern Chart
  output$candlestickChart <- renderPlotly({
    data <- fx_data() %>% tail(100)
    
    p <- plot_ly(data, x = ~Date, type = 'candlestick',
                 open = ~Open, high = ~High, low = ~Low, close = ~Close,
                 name = input$currency_pair,
                 increasing = list(line = list(color = '#27ae60')),
                 decreasing = list(line = list(color = '#e74c3c')))
    
    if (input$show_stochastic) {
      # Calculate Stochastic
      stoch_k <- (data$Close - rollapply(data$Low, 14, min, fill = NA, align = "right")) /
        (rollapply(data$High, 14, max, fill = NA, align = "right") - 
           rollapply(data$Low, 14, min, fill = NA, align = "right")) * 100
      
      # Highlight when stochastic is in extreme zones
      extreme_high <- which(stoch_k > 75)
      extreme_low <- which(stoch_k < 25)
      
      if (length(extreme_high) > 0) {
        p <- p %>% add_markers(x = data$Date[extreme_high], y = data$High[extreme_high],
                               marker = list(color = '#e74c3c', size = 8, symbol = 'circle'),
                               name = "Overbought")
      }
      
      if (length(extreme_low) > 0) {
        p <- p %>% add_markers(x = data$Date[extreme_low], y = data$Low[extreme_low],
                               marker = list(color = '#27ae60', size = 8, symbol = 'circle'),
                               name = "Oversold")
      }
    }
    
    p %>% layout(title = paste("Candlestick Patterns -", input$currency_pair),
                 xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
                 yaxis = list(title = "Price"),
                 plot_bgcolor = '#ffffff',
                 paper_bgcolor = '#ffffff')
  })
  
  # Detected Patterns Table
  output$detectedPatterns <- renderDT({
    patterns <- data.frame(
      Date = as.Date(c("2025-11-05", "2025-11-03", "2025-10-28")),
      Pattern = c("Bullish Engulfing", "Doji Star", "Hammer"),
      Confirmation = c("Confirmed", "Pending", "Confirmed"),
      Signal = c("Buy", "Neutral", "Buy")
    )
    
    datatable(patterns, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  # Tab 7: Technical Indicators
  output$indicatorChart <- renderPlotly({
    data <- fx_data()
    
    p <- plot_ly(data, x = ~Date, y = ~Close, type = 'scatter', mode = 'lines',
                 line = list(color = '#2c3e50', width = 2),
                 name = input$currency_pair)
    
    if ("SMA 20" %in% input$indicators) {
      sma20 <- SMA(data$Close, n = input$sma_period)
      p <- p %>% add_lines(x = data$Date, y = sma20,
                           line = list(color = '#3498db', width = 2),
                           name = paste("SMA", input$sma_period))
    }
    
    if ("SMA 50" %in% input$indicators) {
      sma50 <- SMA(data$Close, n = 50)
      p <- p %>% add_lines(x = data$Date, y = sma50,
                           line = list(color = '#e74c3c', width = 2),
                           name = "SMA 50")
    }
    
    if ("EMA 20" %in% input$indicators) {
      ema20 <- EMA(data$Close, n = input$sma_period)
      p <- p %>% add_lines(x = data$Date, y = ema20,
                           line = list(color = '#27ae60', width = 2),
                           name = paste("EMA", input$sma_period))
    }
    
    if ("Bollinger Bands" %in% input$indicators) {
      bb <- BBands(data$Close, n = input$sma_period, sd = input$bb_sd)
      if (!is.null(bb)) {
        p <- p %>%
          add_lines(x = data$Date, y = bb[, "up"],
                    line = list(color = '#95a5a6', width = 1, dash = 'dot'),
                    name = "BB Upper") %>%
          add_lines(x = data$Date, y = bb[, "dn"],
                    line = list(color = '#95a5a6', width = 1, dash = 'dot'),
                    name = "BB Lower") %>%
          add_lines(x = data$Date, y = bb[, "mavg"],
                    line = list(color = '#f39c12', width = 1),
                    name = "BB Middle")
      }
    }
    
    p %>% layout(title = paste("Technical Indicators -", input$currency_pair),
                 xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
                 yaxis = list(title = "Price"),
                 plot_bgcolor = '#ffffff',
                 paper_bgcolor = '#ffffff')
  })
  
  # RSI Chart
  output$rsiChart <- renderPlotly({
    data <- fx_data()
    rsi <- RSI(data$Close, n = input$rsi_period)
    
    plot_ly(data, x = ~Date, y = rsi, type = 'scatter', mode = 'lines',
            line = list(color = '#9b59b6', width = 2),
            name = "RSI") %>%
      add_segments(x = min(data$Date), xend = max(data$Date),
                   y = 70, yend = 70,
                   line = list(color = '#e74c3c', width = 1, dash = 'dash'),
                   name = "Overbought") %>%
      add_segments(x = min(data$Date), xend = max(data$Date),
                   y = 30, yend = 30,
                   line = list(color = '#27ae60', width = 1, dash = 'dash'),
                   name = "Oversold") %>%
      layout(title = paste("RSI", input$rsi_period),
             xaxis = list(title = "Date"),
             yaxis = list(title = "RSI", range = c(0, 100)),
             plot_bgcolor = '#ffffff',
             paper_bgcolor = '#ffffff')
  })
  
  # MACD Chart
  output$macdChart <- renderPlotly({
    data <- fx_data()
    macd <- MACD(data$Close, nFast = 12, nSlow = 26, nSig = 9)
    
    if (!is.null(macd)) {
      macd_line <- macd[, "macd"]
      signal_line <- macd[, "signal"]
      histogram <- macd_line - signal_line
      
      plot_ly() %>%
        add_bars(x = data$Date, y = histogram,
                 marker = list(color = ifelse(histogram > 0, '#27ae60', '#e74c3c')),
                 name = "Histogram") %>%
        add_lines(x = data$Date, y = macd_line,
                  line = list(color = '#3498db', width = 2),
                  name = "MACD") %>%
        add_lines(x = data$Date, y = signal_line,
                  line = list(color = '#e74c3c', width = 2),
                  name = "Signal") %>%
        layout(title = "MACD",
               xaxis = list(title = "Date"),
               yaxis = list(title = "MACD"),
               plot_bgcolor = '#ffffff',
               paper_bgcolor = '#ffffff')
    }
  })
  
  # Signal Summary Table
  output$signalSummary <- renderDT({
    data <- fx_data()
    current_price <- tail(data$Close, 1)
    
    sma20 <- tail(SMA(data$Close, n = 20), 1)
    rsi <- tail(RSI(data$Close, n = input$rsi_period), 1)
    
    signals <- data.frame(
      Indicator = c("Price vs SMA20", "RSI", "Trend"),
      Value = c(
        sprintf("%.5f", (current_price - sma20) / sma20 * 100),
        sprintf("%.2f", rsi),
        ifelse(current_price > sma20, "Uptrend", "Downtrend")
      ),
      Signal = c(
        ifelse(current_price > sma20, "Bullish", "Bearish"),
        ifelse(rsi > 70, "Overbought", ifelse(rsi < 30, "Oversold", "Neutral")),
        ifelse(current_price > sma20, "Buy", "Sell")
      )
    )
    
    datatable(signals, options = list(dom = 't'), rownames = FALSE)
  })
  
  # Tab 8: Trading Psychology
  output$emotionalCycle <- renderPlotly({
    stages <- c("Optimism", "Excitement", "Thrill", "Euphoria", "Anxiety", 
                "Denial", "Fear", "Desperation", "Panic", "Capitulation", 
                "Despondency", "Depression", "Hope", "Relief")
    values <- c(2, 4, 6, 8, 7, 5, 3, 1, -2, -5, -7, -8, -6, -3)
    
    data <- data.frame(
      Stage = factor(stages, levels = stages),
      Value = values,
      x = 1:length(stages)
    )
    
    plot_ly(data, x = ~x, y = ~Value, type = 'scatter', mode = 'lines+markers',
            text = ~Stage, hoverinfo = 'text',
            line = list(color = '#3498db', width = 3),
            marker = list(size = 10, color = '#e74c3c')) %>%
      layout(title = "Emotional Cycle of a Trader",
             xaxis = list(title = "Time", showticklabels = FALSE),
             yaxis = list(title = "Emotional State", range = c(-10, 10)),
             plot_bgcolor = '#ffffff',
             paper_bgcolor = '#ffffff',
             annotations = list(
               list(x = 4, y = 8, text = "GREED", showarrow = FALSE, font = list(size = 16, color = '#27ae60')),
               list(x = 10, y = -5, text = "FEAR", showarrow = FALSE, font = list(size = 16, color = '#e74c3c'))
             ))
  })
  
  # Tab 9: Risk Management
  output$drawdownRecovery <- renderPlotly({
    drawdown <- seq(5, 95, by = 5)
    recovery <- (100 / (100 - drawdown) - 1) * 100
    
    data <- data.frame(Drawdown = drawdown, Recovery = recovery)
    
    plot_ly(data, x = ~Drawdown, y = ~Recovery, type = 'scatter', mode = 'lines+markers',
            line = list(color = '#e74c3c', width = 3),
            marker = list(size = 8, color = '#3498db')) %>%
      layout(title = "Recovery % Required After Drawdown",
             xaxis = list(title = "Drawdown (%)"),
             yaxis = list(title = "Recovery Required (%)"),
             plot_bgcolor = '#ffffff',
             paper_bgcolor = '#ffffff')
  })
  
  output$hitRateRRR <- renderPlotly({
    hit_rates <- seq(0.2, 0.8, by = 0.05)
    rrr_values <- c(0.5, 1.0, 1.5, 2.0, 2.5, 3.0)
    
    data <- expand.grid(HitRate = hit_rates, RRR = rrr_values)
    data$Expectancy <- data$HitRate * data$RRR - (1 - data$HitRate)
    
    plot_ly(data, x = ~HitRate, y = ~Expectancy, color = ~as.factor(RRR),
            type = 'scatter', mode = 'lines',
            line = list(width = 3)) %>%
      add_segments(x = 0.2, xend = 0.8, y = 0, yend = 0,
                   line = list(color = 'black', width = 2, dash = 'dash'),
                   name = "Break-even") %>%
      layout(title = "Hit Rate vs Reward:Risk Ratio",
             xaxis = list(title = "Hit Rate (Win %)"),
             yaxis = list(title = "Expected Return per Trade"),
             plot_bgcolor = '#ffffff',
             paper_bgcolor = '#ffffff',
             legend = list(title = list(text = "R:R Ratio")))
  })
  
  # Position Size Calculator
  output$position_size <- renderText({
    risk_amount <- input$account_size * (input$risk_percent / 100)
    pip_risk <- input$stop_pips
    position_units <- risk_amount / (pip_risk * input$pip_value)
    lot_size <- position_units / 100000
    
    paste0(
      "Maximum Position Size:\n\n",
      sprintf("Units: %.0f\n", position_units),
      sprintf("Lot Size: %.2f lots\n", lot_size),
      sprintf("\nRisk Amount: $%.2f\n", risk_amount),
      sprintf("Per Pip Value: $%.2f", input$pip_value)
    )
  })
  
  # Tab 10: Interactive Trading
  sim_state <- reactiveValues(
    equity = 100000,
    trades = list(),
    trade_count = 0,
    wins = 0,
    pnl = 0
  )
  
  observeEvent(input$place_trade, {
    if (input$trade_direction != "" && input$entry_price > 0 && 
        input$stop_loss > 0 && input$take_profit > 0) {
      
      # Calculate position size
      risk_amount <- sim_state$equity * (input$sim_risk / 100)
      pip_risk <- abs(input$entry_price - input$stop_loss) * 10000
      position_size <- risk_amount / pip_risk
      
      # Create trade record
      trade <- list(
        id = sim_state$trade_count + 1,
        direction = input$trade_direction,
        entry = input$entry_price,
        stop = input$stop_loss,
        target = input$take_profit,
        size = position_size,
        date = Sys.time(),
        status = "Open"
      )
      
      sim_state$trades <- c(sim_state$trades, list(trade))
      sim_state$trade_count <- sim_state$trade_count + 1
      
      showNotification("Trade placed successfully!", type = "message")
    } else {
      showNotification("Please fill all trade fields", type = "warning")
    }
  })
  
  output$sim_equity <- renderValueBox({
    valueBox(
      paste0("$", format(round(sim_state$equity, 2), big.mark = ",")),
      "Current Equity",
      icon = icon("wallet"),
      color = ifelse(sim_state$equity >= input$sim_capital, "green", "red")
    )
  })
  
  output$sim_trades <- renderValueBox({
    valueBox(
      sim_state$trade_count,
      "Total Trades",
      icon = icon("exchange-alt"),
      color = "blue"
    )
  })
  
  output$sim_winrate <- renderValueBox({
    win_rate <- if (sim_state$trade_count > 0) {
      (sim_state$wins / sim_state$trade_count) * 100
    } else {
      0
    }
    
    valueBox(
      paste0(round(win_rate, 1), "%"),
      "Win Rate",
      icon = icon("percentage"),
      color = ifelse(win_rate >= 50, "green", "yellow")
    )
  })
  
  output$sim_pnl <- renderValueBox({
    pnl_pct <- ((sim_state$equity - input$sim_capital) / input$sim_capital) * 100
    
    valueBox(
      paste0(ifelse(pnl_pct > 0, "+", ""), round(pnl_pct, 2), "%"),
      "Total P&L",
      icon = icon("chart-line"),
      color = ifelse(pnl_pct > 0, "green", "red")
    )
  })
  
  output$tradingChart <- renderPlotly({
    data <- fx_data()
    
    p <- plot_ly(data, x = ~Date, type = 'candlestick',
                 open = ~Open, high = ~High, low = ~Low, close = ~Close,
                 name = input$currency_pair,
                 increasing = list(line = list(color = '#27ae60')),
                 decreasing = list(line = list(color = '#e74c3c')))
    
    if ("Support/Resistance" %in% input$chart_overlays) {
      support <- quantile(data$Low, 0.2, na.rm = TRUE)
      resistance <- quantile(data$High, 0.8, na.rm = TRUE)
      
      p <- p %>%
        add_segments(x = min(data$Date), xend = max(data$Date),
                     y = support, yend = support,
                     line = list(color = '#27ae60', width = 2, dash = 'dash'),
                     name = "Support") %>%
        add_segments(x = min(data$Date), xend = max(data$Date),
                     y = resistance, yend = resistance,
                     line = list(color = '#e74c3c', width = 2, dash = 'dash'),
                     name = "Resistance")
    }
    
    if ("Moving Averages" %in% input$chart_overlays) {
      sma20 <- SMA(data$Close, n = 20)
      p <- p %>% add_lines(x = data$Date, y = sma20,
                           line = list(color = '#3498db', width = 2),
                           name = "SMA 20")
    }
    
    # Show trade entry levels
    if (input$entry_price > 0) {
      p <- p %>%
        add_segments(x = max(data$Date) - 30, xend = max(data$Date),
                     y = input$entry_price, yend = input$entry_price,
                     line = list(color = '#f39c12', width = 3),
                     name = "Entry")
    }
    
    if (input$stop_loss > 0) {
      p <- p %>%
        add_segments(x = max(data$Date) - 30, xend = max(data$Date),
                     y = input$stop_loss, yend = input$stop_loss,
                     line = list(color = '#e74c3c', width = 2, dash = 'dot'),
                     name = "Stop Loss")
    }
    
    if (input$take_profit > 0) {
      p <- p %>%
        add_segments(x = max(data$Date) - 30, xend = max(data$Date),
                     y = input$take_profit, yend = input$take_profit,
                     line = list(color = '#27ae60', width = 2, dash = 'dot'),
                     name = "Take Profit")
    }
    
    p %>% layout(title = paste("Trading Chart -", input$currency_pair),
                 xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
                 yaxis = list(title = "Price"),
                 plot_bgcolor = '#ffffff',
                 paper_bgcolor = '#ffffff')
  })
  
  output$setup_analysis <- renderText({
    data <- fx_data()
    current_price <- tail(data$Close, 1)
    sma20 <- tail(SMA(data$Close, n = 20), 1)
    rsi <- tail(RSI(data$Close, n = 14), 1)
    
    trend <- ifelse(current_price > sma20, "UPTREND", "DOWNTREND")
    rsi_state <- ifelse(rsi > 70, "OVERBOUGHT", ifelse(rsi < 30, "OVERSOLD", "NEUTRAL"))
    
    paste0(
      "Current Price: ", sprintf("%.5f", current_price), "\n",
      "Trend: ", trend, "\n",
      "RSI: ", sprintf("%.2f", rsi), " (", rsi_state, ")\n\n",
      "Analysis:\n",
      ifelse(current_price > sma20,
             "Price is above the 20 SMA, indicating bullish momentum.",
             "Price is below the 20 SMA, indicating bearish momentum."), "\n",
      ifelse(rsi > 70,
             "RSI is overbought - watch for potential reversal.",
             ifelse(rsi < 30,
                    "RSI is oversold - potential buying opportunity.",
                    "RSI is in neutral territory."))
    )
  })
  
  output$rrr_calc <- renderText({
    if (input$entry_price > 0 && input$stop_loss > 0 && input$take_profit > 0) {
      risk_pips <- abs(input$entry_price - input$stop_loss) * 10000
      reward_pips <- abs(input$take_profit - input$entry_price) * 10000
      rrr <- reward_pips / risk_pips
      
      risk_amount <- sim_state$equity * (input$sim_risk / 100)
      potential_profit <- risk_amount * rrr
      
      assessment <- if (rrr >= 2) {
        "GOOD - Meets minimum 2:1 ratio"
      } else if (rrr >= 1.5) {
        "ACCEPTABLE - Close to 2:1 target"
      } else {
        "POOR - Below recommended 2:1 ratio"
      }
      
      paste0(
        "Risk: ", sprintf("%.1f", risk_pips), " pips ($", sprintf("%.2f", risk_amount), ")\n",
        "Reward: ", sprintf("%.1f", reward_pips), " pips ($", sprintf("%.2f", potential_profit), ")\n\n",
        "Reward:Risk Ratio: ", sprintf("%.2f", rrr), ":1\n\n",
        "Assessment: ", assessment
      )
    } else {
      "Enter trade levels to calculate R:R ratio"
    }
  })
  
  output$trade_history <- renderDT({
    if (length(sim_state$trades) > 0) {
      trades_df <- do.call(rbind, lapply(sim_state$trades, function(x) {
        data.frame(
          ID = x$id,
          Date = format(x$date, "%Y-%m-%d %H:%M"),
          Direction = x$direction,
          Entry = sprintf("%.5f", x$entry),
          Stop = sprintf("%.5f", x$stop),
          Target = sprintf("%.5f", x$target),
          Size = sprintf("%.2f", x$size),
          Status = x$status,
          stringsAsFactors = FALSE
        )
      }))
      
      datatable(trades_df, options = list(pageLength = 10, order = list(list(0, 'desc'))), 
                rownames = FALSE)
    } else {
      datatable(data.frame(Message = "No trades yet. Place your first trade above!"),
                options = list(dom = 't'), rownames = FALSE)
    }
  })
  
  output$equity_curve <- renderPlotly({
    if (sim_state$trade_count > 0) {
      equity_history <- c(input$sim_capital, sim_state$equity)
      dates <- seq(Sys.Date() - sim_state$trade_count, Sys.Date(), 
                   length.out = length(equity_history))
      
      plot_ly(x = dates, y = equity_history, type = 'scatter', mode = 'lines',
              fill = 'tozeroy',
              fillcolor = ifelse(sim_state$equity >= input$sim_capital, 
                                 'rgba(39, 174, 96, 0.3)', 'rgba(231, 76, 60, 0.3)'),
              line = list(color = ifelse(sim_state$equity >= input$sim_capital, 
                                         '#27ae60', '#e74c3c'), width = 3)) %>%
        layout(title = "Equity Curve",
               xaxis = list(title = "Date"),
               yaxis = list(title = "Equity ($)"),
               plot_bgcolor = '#ffffff',
               paper_bgcolor = '#ffffff')
    } else {
      plot_ly() %>%
        layout(title = "Equity Curve (No trades yet)",
               xaxis = list(title = "Date"),
               yaxis = list(title = "Equity ($)"),
               plot_bgcolor = '#ffffff',
               paper_bgcolor = '#ffffff',
               annotations = list(
                 list(text = "Place trades to see equity curve",
                      x = 0.5, y = 0.5, showarrow = FALSE,
                      xref = 'paper', yref = 'paper',
                      font = list(size = 16, color = '#95a5a6'))
               ))
    }
  })
  
  output$performance_stats <- renderText({
    if (sim_state$trade_count > 0) {
      win_rate <- (sim_state$wins / sim_state$trade_count) * 100
      total_pnl <- sim_state$equity - input$sim_capital
      pnl_pct <- (total_pnl / input$sim_capital) * 100
      avg_win <- if (sim_state$wins > 0) total_pnl / sim_state$wins else 0
      avg_loss <- if ((sim_state$trade_count - sim_state$wins) > 0) {
        total_pnl / (sim_state$trade_count - sim_state$wins)
      } else {
        0
      }
      
      paste0(
        "Total Trades: ", sim_state$trade_count, "\n",
        "Winning Trades: ", sim_state$wins, "\n",
        "Losing Trades: ", sim_state$trade_count - sim_state$wins, "\n",
        "Win Rate: ", sprintf("%.1f%%", win_rate), "\n\n",
        "Total P&L: $", sprintf("%.2f", total_pnl), " (", 
        sprintf("%.2f%%", pnl_pct), ")\n",
        "Avg Win: $", sprintf("%.2f", avg_win), "\n",
        "Avg Loss: $", sprintf("%.2f", avg_loss), "\n\n",
        "Current Equity: $", format(round(sim_state$equity, 2), big.mark = ","), "\n",
        "Max Drawdown: ", sprintf("%.1f%%", 
                                  max(0, ((input$sim_capital - sim_state$equity) / input$sim_capital) * 100))
      )
    } else {
      "No trading statistics available yet.\n\nPlace some trades to see your performance metrics."
    }
  })
  
  observeEvent(input$reset_sim, {
    sim_state$equity <- input$sim_capital
    sim_state$trades <- list()
    sim_state$trade_count <- 0
    sim_state$wins <- 0
    sim_state$pnl <- 0
    
    showNotification("Simulator reset successfully!", type = "message")
  })
  
  # Update entry price to current price on load
  observe({
    data <- fx_data()
    current_price <- tail(data$Close, 1)
    
    updateNumericInput(session, "entry_price", value = round(current_price, 5))
    
    # Suggest stop loss and take profit
    if (input$trade_direction == "Long (Buy)") {
      suggested_stop <- current_price * 0.995  # 0.5% below
      suggested_target <- current_price * 1.01  # 1% above
      
      updateNumericInput(session, "stop_loss", value = round(suggested_stop, 5))
      updateNumericInput(session, "take_profit", value = round(suggested_target, 5))
    } else if (input$trade_direction == "Short (Sell)") {
      suggested_stop <- current_price * 1.005  # 0.5% above
      suggested_target <- current_price * 0.99  # 1% below
      
      updateNumericInput(session, "stop_loss", value = round(suggested_stop, 5))
      updateNumericInput(session, "take_profit", value = round(suggested_target, 5))
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)