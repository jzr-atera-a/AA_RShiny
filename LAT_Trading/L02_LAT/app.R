# FX Technical Analysis Learning Dashboard
# Based on Week 2 Lectures - Level 5 Diploma in Applied Financial Trading

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
generate_sample_data <- function(days = 365, pattern = "uptrend") {
  dates <- seq(Sys.Date() - days, Sys.Date(), by = "day")
  n <- length(dates)
  
  # Base price with trend
  if (pattern == "uptrend") {
    base_price <- 100 + cumsum(rnorm(n, mean = 0.05, sd = 0.5))
  } else if (pattern == "downtrend") {
    base_price <- 150 - cumsum(rnorm(n, mean = 0.05, sd = 0.5))
  } else if (pattern == "sideways") {
    base_price <- 100 + cumsum(rnorm(n, mean = 0, sd = 0.3))
  } else if (pattern == "triangle") {
    # Create converging highs and lows
    trend <- seq(0, 0, length.out = n)
    volatility <- seq(5, 0.5, length.out = n)
    base_price <- 100 + trend + cumsum(rnorm(n, 0, 1)) * volatility / 5
  } else if (pattern == "head_shoulders") {
    # Create H&S pattern
    shoulder1 <- c(rep(0, n/6), seq(0, 5, length.out = n/6))
    head <- c(seq(5, 10, length.out = n/6), seq(10, 5, length.out = n/6))
    shoulder2 <- c(seq(5, 0, length.out = n/6), rep(0, n/6))
    pattern_shape <- c(shoulder1, head, shoulder2)
    if (length(pattern_shape) > n) pattern_shape <- pattern_shape[1:n]
    if (length(pattern_shape) < n) pattern_shape <- c(pattern_shape, rep(0, n - length(pattern_shape)))
    base_price <- 100 + pattern_shape + cumsum(rnorm(n, 0, 0.3))
  } else if (pattern == "double_top") {
    # Create double top pattern
    peak1 <- c(rep(0, n/5), seq(0, 8, length.out = n/5), seq(8, 3, length.out = n/5))
    peak2 <- c(seq(3, 8, length.out = n/5), seq(8, 0, length.out = n/5))
    pattern_shape <- c(peak1, peak2)
    if (length(pattern_shape) > n) pattern_shape <- pattern_shape[1:n]
    if (length(pattern_shape) < n) pattern_shape <- c(pattern_shape, rep(0, n - length(pattern_shape)))
    base_price <- 100 + pattern_shape + cumsum(rnorm(n, 0, 0.3))
  } else if (pattern == "wedge_rising") {
    # Rising wedge
    lower_line <- seq(0, 8, length.out = n)
    upper_line <- seq(0, 10, length.out = n)
    range_width <- upper_line - lower_line
    base_price <- 100 + lower_line + runif(n) * range_width + cumsum(rnorm(n, 0, 0.2))
  } else if (pattern == "wedge_falling") {
    # Falling wedge
    upper_line <- seq(10, 2, length.out = n)
    lower_line <- seq(8, 0, length.out = n)
    range_width <- upper_line - lower_line
    base_price <- 100 + lower_line + runif(n) * range_width + cumsum(rnorm(n, 0, 0.2))
  } else {
    base_price <- 100 + cumsum(rnorm(n, 0, 0.5))
  }
  
  # Add OHLC structure
  data <- data.frame(
    Date = dates,
    Open = base_price + rnorm(n, 0, 0.2),
    High = base_price + abs(rnorm(n, 0.3, 0.2)),
    Low = base_price - abs(rnorm(n, 0.3, 0.2)),
    Close = base_price + rnorm(n, 0, 0.2),
    Volume = abs(rnorm(n, 1000000, 200000))
  )
  
  # Ensure High is highest and Low is lowest
  data$High <- pmax(data$High, data$Open, data$Close)
  data$Low <- pmin(data$Low, data$Open, data$Close)
  
  return(data)
}

# Generate bull/bear market cycle data
generate_market_cycle <- function() {
  dates <- seq(as.Date("2015-01-01"), as.Date("2024-12-31"), by = "day")
  n <- length(dates)
  
  # Create bull/bear cycle
  # Bull Phase 1 (Accumulation)
  phase1_len <- round(n * 0.15)
  phase1 <- 5000 + cumsum(rnorm(phase1_len, 0.3, 2))
  
  # Bull Phase 2 (Trending)
  phase2_len <- round(n * 0.25)
  phase2 <- tail(phase1, 1) + cumsum(rnorm(phase2_len, 0.8, 3))
  
  # Bull Phase 3 (Distribution)
  phase3_len <- round(n * 0.15)
  phase3 <- tail(phase2, 1) + cumsum(rnorm(phase3_len, 0.2, 4))
  
  # Bear Phase 1 (Initial decline)
  phase4_len <- round(n * 0.15)
  phase4 <- tail(phase3, 1) + cumsum(rnorm(phase4_len, -0.5, 3))
  
  # Bear Phase 2 (Panic)
  phase5_len <- round(n * 0.15)
  phase5 <- tail(phase4, 1) + cumsum(rnorm(phase5_len, -1.2, 5))
  
  # Bear Phase 3 (Capitulation)
  phase6_len <- n - (phase1_len + phase2_len + phase3_len + phase4_len + phase5_len)
  phase6 <- tail(phase5, 1) + cumsum(rnorm(phase6_len, -0.3, 2))
  
  prices <- c(phase1, phase2, phase3, phase4, phase5, phase6)
  
  # Create phases indicator
  phases <- c(
    rep("Bull Phase 1: Accumulation", phase1_len),
    rep("Bull Phase 2: Trending", phase2_len),
    rep("Bull Phase 3: Distribution", phase3_len),
    rep("Bear Phase 1: Initial Decline", phase4_len),
    rep("Bear Phase 2: Panic", phase5_len),
    rep("Bear Phase 3: Capitulation", phase6_len)
  )
  
  data.frame(
    Date = dates,
    Price = prices,
    Phase = phases,
    stringsAsFactors = FALSE
  )
}

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "W2-TA Learning Platform"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Introduction", tabName = "intro", icon = icon("info-circle")),
      menuItem("Price/Time Filters", tabName = "filters", icon = icon("filter")),
      menuItem("Support & Resistance", tabName = "sr_reversal", icon = icon("arrows-alt-v")),
      menuItem("Timeframe Analysis", tabName = "timeframe", icon = icon("clock")),
      menuItem("Fibonacci Tools", tabName = "fibonacci", icon = icon("calculator")),
      menuItem("Continuation Patterns", tabName = "continuation", icon = icon("chart-line")),
      menuItem("Reversal Patterns", tabName = "reversal", icon = icon("exchange-alt")),
      menuItem("Wedges", tabName = "wedges", icon = icon("compress-alt")),
      menuItem("Dow Theory", tabName = "dow", icon = icon("university")),
      menuItem("Market Cycles", tabName = "cycles", icon = icon("sync"))
    )
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
          background: rgba(255, 255, 255, 0.98) !important;
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 44, 60, 0.15) !important;
          border-left: 4px solid #008A82;
        }
        
        /* Concept boxes */
        .concept-box {
          background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%) !important;
          padding: 20px;
          border-left: 4px solid #008A82;
          margin: 15px 0;
          border-radius: 8px;
          box-shadow: 0 4px 15px rgba(0, 138, 130, 0.1);
        }
        
        .example-box {
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
          padding: 20px;
          border-left: 4px solid #f39c12;
          margin: 15px 0;
          border-radius: 8px;
          box-shadow: 0 4px 15px rgba(243, 156, 18, 0.1);
        }
        
        .key-point {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          padding: 15px;
          border-left: 4px solid #00A39A;
          margin: 15px 0;
          border-radius: 8px;
          box-shadow: 0 4px 15px rgba(0, 163, 154, 0.1);
        }
        
        /* Status message styling */
        .connection-success {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          color: #155724 !important;
          padding: 15px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #00A39A !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(0, 163, 154, 0.2);
        }
        
        .connection-error {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 15px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #e74c3c !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(231, 76, 60, 0.2);
        }
        
        .data-warning {
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
          color: #856404 !important;
          padding: 15px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #f39c12 !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(243, 156, 18, 0.2);
        }
        
        .error-message {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 25px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #e74c3c !important;
          margin: 20px;
          text-align: center;
          font-size: 16px;
          box-shadow: 0 6px 20px rgba(231, 76, 60, 0.2);
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
        .dataTables_wrapper {
          background: transparent !important;
        }
        
        .dataTables_wrapper .dataTables_paginate .paginate_button.current {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          color: white !important;
        }
        
        /* Ensure all chart backgrounds remain white */
        .plotly, .plotly .plot-container, .plotly .plot-container .svg-container {
          background: white !important;
        }
        
        /* Spinner styling */
        .spinner-border {
          color: #008A82 !important;
        }
        
        /* Navigation and content width maintenance */
        .content-wrapper {
          margin-left: 230px !important;
        }
        
        .main-sidebar {
          width: 230px !important;
        }
        
        /* Global text improvements */
        body, .content-wrapper {
          font-family: 'Segoe UI', 'Arial', sans-serif;
        }
        
        h1, h2, h3, h4, h5, h6 {
          color: #002C3C;
          font-weight: 600;
        }
        
        /* Tab content styling */
        .tab-content {
          background: transparent;
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
        
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          border-bottom: none !important;
          font-weight: 600;
        }
        
        .main-header .logo:hover {
          background: linear-gradient(135deg, #001f2a 0%, #006b63 50%, #007d75 100%) !important;
        }
        
        /* Dashboard header brand text */
        .main-header .logo .logo-lg,
        .main-header .logo .logo-mini {
          color: #ffffff !important;
          font-weight: 600;
        }
        
        /* Navbar toggle button */
        .main-header .navbar .sidebar-toggle {
          background: rgba(255, 255, 255, 0.1) !important;
          color: #ffffff !important;
          border: none !important;
        }
        
        .main-header .navbar .sidebar-toggle:hover {
          background: rgba(255, 255, 255, 0.2) !important;
        }
      "))
    ),
    
    tabItems(
      # Introduction Tab
      tabItem(
        tabName = "intro",
        fluidRow(
          box(
            title = "Welcome to Technical Analysis Learning Platform",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            h3("Level 5 Diploma in Applied Financial Trading - Week 2"),
            br(),
            div(class = "concept-box",
                h4("Course Overview"),
                p("This interactive platform covers essential technical analysis concepts including:"),
                tags$ul(
                  tags$li("Price and Time Filters for trade confirmation"),
                  tags$li("Support and Resistance role reversal"),
                  tags$li("Multi-timeframe analysis strategies"),
                  tags$li("Fibonacci retracements and extensions"),
                  tags$li("Chart pattern recognition (Continuation & Reversal)"),
                  tags$li("Dow Theory and market phases"),
                  tags$li("Bull/Bear market cycle psychology")
                )
            )
          )
        ),
        
        fluidRow(
          valueBox(
            value = "10",
            subtitle = "Interactive Modules",
            icon = icon("book"),
            color = "blue",
            width = 3
          ),
          valueBox(
            value = "7",
            subtitle = "Chart Patterns",
            icon = icon("chart-area"),
            color = "green",
            width = 3
          ),
          valueBox(
            value = "Real-time",
            subtitle = "Interactive Charts",
            icon = icon("chart-line"),
            color = "yellow",
            width = 3
          ),
          valueBox(
            value = "Expert",
            subtitle = "Technical Analysis",
            icon = icon("graduation-cap"),
            color = "purple",
            width = 3
          )
        ),
        
        fluidRow(
          box(
            title = "Key Learning Objectives",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            div(class = "key-point",
                tags$ul(
                  tags$li("Master price and time filter techniques"),
                  tags$li("Identify and trade chart patterns"),
                  tags$li("Apply Fibonacci analysis effectively"),
                  tags$li("Understand market cycle psychology"),
                  tags$li("Develop multi-timeframe strategies")
                )
            )
          ),
          box(
            title = "How to Use This Platform",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            p("Navigate through the sidebar menu to explore different topics."),
            p("Each section contains:"),
            tags$ul(
              tags$li(strong("Theoretical concepts"), " - Core principles explained"),
              tags$li(strong("Interactive charts"), " - Visualize patterns and indicators"),
              tags$li(strong("Practical examples"), " - Real-world applications"),
              tags$li(strong("Key takeaways"), " - Summary points for quick reference")
            )
          )
        )
      ),
      
      # Price/Time Filters Tab
      tabItem(
        tabName = "filters",
        fluidRow(
          box(
            title = "Price and Time Filters Explained",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("What Are Filters?"),
                p("Filters are essential tools that help traders determine when a support or resistance 
                  level has been broken sufficiently to take action. They help avoid false breakouts 
                  and improve trade timing.")
            ),
            
            fluidRow(
              column(6,
                     div(class = "key-point",
                         h4("Time Filters"),
                         tags$ul(
                           tags$li("Wait for candle close (15-min, 1-hour, daily)"),
                           tags$li("Confirm breakout persistence over time"),
                           tags$li("Avoid false breakouts from quick reversals"),
                           tags$li("Set specific rules for your timeframe")
                         )
                     )
              ),
              column(6,
                     div(class = "key-point",
                         h4("Price Filters"),
                         tags$ul(
                           tags$li("Wait for penetration by predetermined amount"),
                           tags$li("Set parameters based on timeframe"),
                           tags$li("Consider risk appetite and asset traded"),
                           tags$li("Example: 0.5% or 10 pips beyond level")
                         )
                     )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Filter Configuration",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            selectInput("filter_type", "Filter Type:",
                        choices = c("Time Filter", "Price Filter", "Combination Filter"),
                        selected = "Combination Filter"),
            conditionalPanel(
              condition = "input.filter_type == 'Time Filter' || input.filter_type == 'Combination Filter'",
              selectInput("time_filter", "Candle Close:",
                          choices = c("15-minute", "1-hour", "4-hour", "Daily"),
                          selected = "1-hour")
            ),
            conditionalPanel(
              condition = "input.filter_type == 'Price Filter' || input.filter_type == 'Combination Filter'",
              numericInput("price_filter", "Price Penetration (%):", 
                           value = 0.5, min = 0.1, max = 2, step = 0.1)
            ),
            
            div(class = "example-box",
                h4("Impulsive Breakout Criteria"),
                p("Look for 2+ of the following:"),
                tags$ul(
                  tags$li("Long candlestick body"),
                  tags$li("Close at/near high or low"),
                  tags$li("High volume"),
                  tags$li("Gap")
                )
            )
          ),
          
          box(
            title = "Breakout Visualization with Filters",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            withSpinner(plotlyOutput("filterChart", height = "450px"))
          )
        ),
        
        fluidRow(
          box(
            title = "Pros and Cons of Filters",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(6,
                     div(class = "key-point",
                         h4(icon("check-circle"), " Benefits"),
                         tags$ul(
                           tags$li("Helps avoid entering trades on false breakouts"),
                           tags$li("Increases trade confidence"),
                           tags$li("Reduces whipsaw losses"),
                           tags$li("Provides clear entry rules")
                         )
                     )
              ),
              column(6,
                     div(class = "example-box",
                         h4(icon("exclamation-triangle"), " Drawbacks"),
                         tags$ul(
                           tags$li("Gives later entry into profitable trades"),
                           tags$li("May miss fast-moving opportunities"),
                           tags$li("No perfect solution exists"),
                           tags$li("Balance needed between confirmation and timeliness")
                         )
                     )
              )
            )
          )
        )
      ),
      
      # Support/Resistance Role Reversal Tab
      tabItem(
        tabName = "sr_reversal",
        fluidRow(
          box(
            title = "Support & Resistance Role Reversal",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("The Principle of Role Reversal"),
                p("When a resistance level is broken to the upside, it often becomes a support level. 
                  Conversely, when support is broken to the downside, it often becomes resistance. 
                  This is one of the most reliable concepts in technical analysis.")
            ),
            
            div(class = "key-point",
                h4("Why Does This Happen?"),
                tags$ul(
                  tags$li(strong("Memory Effect:"), " Traders remember significant price levels"),
                  tags$li(strong("Trapped Traders:"), " Those who sold at old resistance may buy back at breakeven"),
                  tags$li(strong("New Support:"), " Breakout buyers see old resistance as logical support"),
                  tags$li(strong("Self-Fulfilling:"), " Many traders watch these levels, making them powerful")
                )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Chart Controls",
            status = "info",
            solidHeader = TRUE,
            width = 3,
            selectInput("sr_pattern", "Select Pattern:",
                        choices = c("Resistance to Support" = "res_to_sup",
                                    "Support to Resistance" = "sup_to_res"),
                        selected = "res_to_sup"),
            checkboxInput("show_sr_lines", "Show S/R Lines", value = TRUE),
            checkboxInput("show_breakout", "Highlight Breakout", value = TRUE),
            checkboxInput("show_retest", "Show Retest", value = TRUE),
            
            div(class = "example-box",
                h4("Trading Strategy"),
                p("1. Identify key S/R level"),
                p("2. Wait for impulsive breakout"),
                p("3. Look for retest (return move)"),
                p("4. Enter on confirmation"),
                p("5. Place stop beyond new S/R")
            )
          ),
          
          box(
            title = "Role Reversal Demonstration",
            status = "primary",
            solidHeader = TRUE,
            width = 9,
            withSpinner(plotlyOutput("srReversalChart", height = "500px"))
          )
        ),
        
        fluidRow(
          box(
            title = "Key Concepts for Role Reversal",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            div(class = "key-point",
                h4("Characteristics to Look For:"),
                tags$ol(
                  tags$li("Multiple touches at the original level"),
                  tags$li("Clear, decisive breakout (preferably impulsive)"),
                  tags$li("Return move that respects the new level"),
                  tags$li("Volume confirmation on breakout"),
                  tags$li("Time spent at the level (the longer, the stronger)")
                )
            )
          ),
          
          box(
            title = "Common Mistakes to Avoid",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            div(class = "example-box",
                h4(icon("exclamation-triangle"), " Watch Out For:"),
                tags$ul(
                  tags$li("Trading before breakout confirmation"),
                  tags$li("Ignoring the strength of the original level"),
                  tags$li("Not using proper filters"),
                  tags$li("Forgetting that not all levels reverse roles"),
                  tags$li("Over-relying on a single indicator")
                )
            )
          )
        )
      ),
      
      # Timeframe Analysis Tab
      tabItem(
        tabName = "timeframe",
        fluidRow(
          box(
            title = "Multi-Timeframe Analysis",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("Why Multiple Timeframes Matter"),
                p("Depending on your timeframe, prices can appear to move in different directions 
                  simultaneously. A proper multi-timeframe approach helps you:"),
                tags$ul(
                  tags$li("Identify the dominant trend direction"),
                  tags$li("Find better entry and exit points"),
                  tags$li("Reduce conflicting signals"),
                  tags$li("Align with larger market forces")
                )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Timeframe Selection Guide",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("timeframeTable")
          )
        ),
        
        fluidRow(
          box(
            title = "Your Trading Timeframe",
            status = "warning",
            solidHeader = TRUE,
            width = 4,
            selectInput("holding_period", "Average Holding Period:",
                        choices = c("5 minutes", "1 hour", "4 hours", 
                                    "1 day", "1 week", "1 month"),
                        selected = "1 day"),
            
            uiOutput("recommended_timeframes"),
            
            div(class = "key-point",
                h4("Golden Rules:"),
                tags$ul(
                  tags$li("Identify YOUR holding period first"),
                  tags$li("Long-term trend = 10x holding period"),
                  tags$li("Trade WITH the long-term trend"),
                  tags$li("Don't switch timeframes mid-trade")
                )
            )
          ),
          
          box(
            title = "Multi-Timeframe Chart Example",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            withSpinner(plotlyOutput("timeframeChart", height = "450px"))
          )
        ),
        
        fluidRow(
          box(
            title = "The Most Powerful Setup",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            div(class = "example-box",
                h4(icon("star"), " Maximum Confluence"),
                p(strong("The most powerful moves occur when long, medium, and short-term trends 
                         are moving in the SAME direction.")),
                br(),
                fluidRow(
                  column(4,
                         div(style = "text-align: center; padding: 20px; background: linear-gradient(135deg, #d4edda, #c3e6cb); border-radius: 8px;",
                             h4("Long-Term: UP"),
                             p("Monthly/Weekly trend")
                         )
                  ),
                  column(4,
                         div(style = "text-align: center; padding: 20px; background: linear-gradient(135deg, #d4edda, #c3e6cb); border-radius: 8px;",
                             h4("Medium-Term: UP"),
                             p("Daily trend")
                         )
                  ),
                  column(4,
                         div(style = "text-align: center; padding: 20px; background: linear-gradient(135deg, #d4edda, #c3e6cb); border-radius: 8px;",
                             h4("Short-Term: UP"),
                             p("Intraday trend")
                         )
                  )
                ),
                br(),
                p(style = "text-align: center; font-size: 18px;",
                  strong("= HIGH PROBABILITY TRADE SETUP"))
            )
          )
        )
      ),
      
      # Fibonacci Tab
      tabItem(
        tabName = "fibonacci",
        fluidRow(
          box(
            title = "Fibonacci Analysis in Trading",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("The Fibonacci Sequence"),
                p("Discovered by Leonardo Fibonacci (1175-1250), the Fibonacci sequence appears 
                  throughout nature and financial markets:"),
                p(strong("1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144...")),
                p("Each number is the sum of the previous two numbers.")
            ),
            
            fluidRow(
              column(4,
                     div(class = "key-point",
                         h4("Key Fibonacci Ratios"),
                         tags$ul(
                           tags$li(strong("61.8%"), " - Golden Ratio"),
                           tags$li(strong("50.0%"), " - Half retracement"),
                           tags$li(strong("38.2%"), " - First key level"),
                           tags$li(strong("23.6%"), " - Minor level"),
                           tags$li(strong("76.4%"), " - Minor level")
                         )
                     )
              ),
              column(4,
                     div(class = "example-box",
                         h4("Retracement Levels"),
                         p("Used to identify potential support/resistance during pullbacks"),
                         tags$ul(
                           tags$li("38.2% - 61.8% = ", strong("Buying/Selling Zone")),
                           tags$li("50% = Common retracement"),
                           tags$li("Wait for confirmation")
                         )
                     )
              ),
              column(4,
                     div(class = "example-box",
                         h4("Extension Levels"),
                         p("Used to project price targets"),
                         tags$ul(
                           tags$li("127.2% - First target"),
                           tags$li("161.8% - Second target"),
                           tags$li("200% - Extended target")
                         )
                     )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Fibonacci Tool Settings",
            status = "info",
            solidHeader = TRUE,
            width = 3,
            selectInput("fib_tool", "Tool Type:",
                        choices = c("Retracement", "Extension"),
                        selected = "Retracement"),
            selectInput("fib_trend", "Trend Direction:",
                        choices = c("Uptrend", "Downtrend"),
                        selected = "Uptrend"),
            checkboxGroupInput("fib_levels", "Show Levels:",
                               choices = c("23.6%" = "23.6",
                                           "38.2%" = "38.2",
                                           "50.0%" = "50.0",
                                           "61.8%" = "61.8",
                                           "76.4%" = "76.4"),
                               selected = c("38.2", "50.0", "61.8")),
            
            div(class = "key-point",
                h4("Trading Strategy"),
                p("1. Identify major trend"),
                p("2. Wait for pullback"),
                p("3. Look for support in 38.2-61.8% zone"),
                p("4. Confirm with price pattern"),
                p("5. Enter with stop below 61.8%"),
                p("6. Target Fibonacci extensions")
            )
          ),
          
          box(
            title = "Fibonacci Analysis Chart",
            status = "primary",
            solidHeader = TRUE,
            width = 9,
            withSpinner(plotlyOutput("fibonacciChart", height = "500px"))
          )
        ),
        
        fluidRow(
          box(
            title = "Why Fibonacci Works",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("The Psychology Behind Fibonacci"),
                p("Financial markets exhibit typical crowd behavior. Different asset prices tend to 
                  retrace similar amounts on each pullback because:"),
                tags$ul(
                  tags$li(strong("Self-fulfilling prophecy:"), " Many traders watch these levels"),
                  tags$li(strong("Natural rhythm:"), " Markets breathe in and out"),
                  tags$li(strong("Profit-taking:"), " Traders naturally take profits at predictable levels"),
                  tags$li(strong("Risk management:"), " Common stop-loss placement creates support/resistance")
                ),
                br(),
                div(class = "example-box",
                    h4(icon("lightbulb"), " Pro Tip"),
                    p("Fibonacci levels work best when combined with other technical tools like:"),
                    tags$ul(
                      tags$li("Previous support/resistance levels"),
                      tags$li("Trendlines and channels"),
                      tags$li("Chart patterns"),
                      tags$li("Volume analysis")
                    )
                )
            )
          )
        )
      ),
      
      # Continuation Patterns Tab
      tabItem(
        tabName = "continuation",
        fluidRow(
          box(
            title = "Continuation Chart Patterns",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("What Are Continuation Patterns?"),
                p("Continuation patterns are formed when a prevailing trend pauses briefly before 
                  continuing in the same direction. They represent a temporary equilibrium between 
                  buyers and sellers before the dominant force reasserts itself.")
            ),
            
            fluidRow(
              column(4,
                     div(class = "key-point",
                         h4("Triangles"),
                         tags$ul(
                           tags$li("Symmetrical Triangle"),
                           tags$li("Ascending Triangle"),
                           tags$li("Descending Triangle")
                         ),
                         p("Most common continuation pattern")
                     )
              ),
              column(4,
                     div(class = "key-point",
                         h4("Flags"),
                         tags$ul(
                           tags$li("Bullish Flag"),
                           tags$li("Bearish Flag"),
                           tags$li("Short-term pattern (hours)")
                         ),
                         p("Explosive, high-momentum moves")
                     )
              ),
              column(4,
                     div(class = "key-point",
                         h4("Pennants"),
                         tags$ul(
                           tags$li("Similar to flags"),
                           tags$li("Triangular shape"),
                           tags$li("Very short duration")
                         ),
                         p("High probability continuations")
                     )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Pattern Selection",
            status = "info",
            solidHeader = TRUE,
            width = 3,
            selectInput("cont_pattern", "Select Pattern:",
                        choices = c("Symmetrical Triangle" = "triangle_sym",
                                    "Ascending Triangle" = "triangle_asc",
                                    "Descending Triangle" = "triangle_desc",
                                    "Bullish Flag" = "flag_bull",
                                    "Bearish Flag" = "flag_bear"),
                        selected = "triangle_sym"),
            
            checkboxInput("show_pattern_lines", "Show Pattern Lines", value = TRUE),
            checkboxInput("show_mpo", "Show MPO (Target)", value = TRUE),
            checkboxInput("show_entry", "Show Entry Point", value = TRUE),
            
            uiOutput("pattern_description")
          ),
          
          box(
            title = "Continuation Pattern Visualization",
            status = "primary",
            solidHeader = TRUE,
            width = 9,
            withSpinner(plotlyOutput("continuationChart", height = "500px"))
          )
        ),
        
        fluidRow(
          box(
            title = "Triangle Pattern Rules",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            div(class = "key-point",
                h4("7 Key Rules for Triangle Trading:"),
                tags$ol(
                  tags$li("Expect continuation of prior trend"),
                  tags$li("Only buy/sell AFTER the breakout"),
                  tags$li("MPO = height of triangle base"),
                  tags$li("Breakout typically ½ to ¾ through pattern"),
                  tags$li("Look for increased volume on breakout"),
                  tags$li("Use price/time filters for confirmation"),
                  tags$li("Watch for return move (retest)")
                )
            )
          ),
          
          box(
            title = "Flag/Pennant Characteristics",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            div(class = "example-box",
                h4("Identifying Flags & Pennants:"),
                tags$ul(
                  tags$li(strong("Short-term:"), " Up to a few hours duration"),
                  tags$li(strong("Fast move:"), " Almost vertical price action before"),
                  tags$li(strong("Consolidation:"), " Brief pause/pullback"),
                  tags$li(strong("Explosive:"), " Strong breakout continuation"),
                  tags$li(strong("Target:"), " Height of flagpole projected from breakout")
                ),
                br(),
                p(strong("Warning:"), " Flags and pennants can reverse! Watch for breakout direction.")
            )
          )
        )
      ),
      
      # Reversal Patterns Tab
      tabItem(
        tabName = "reversal",
        fluidRow(
          box(
            title = "Reversal Chart Patterns",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("What Are Reversal Patterns?"),
                p("Reversal patterns signal that the balance of power is shifting from buyers to sellers 
                  (or vice versa). Prices are about to reverse their previous directional trend. These 
                  patterns are crucial for identifying major turning points.")
            ),
            
            fluidRow(
              column(4,
                     div(class = "key-point",
                         h4("Head & Shoulders"),
                         tags$ul(
                           tags$li("Most reliable reversal pattern"),
                           tags$li("Bearish: Top reversal"),
                           tags$li("Inverse H&S: Bottom reversal"),
                           tags$li("Requires prior trend")
                         )
                     )
              ),
              column(4,
                     div(class = "key-point",
                         h4("Double Tops/Bottoms"),
                         tags$ul(
                           tags$li("'M' or 'W' formation"),
                           tags$li("Two peaks/troughs at similar levels"),
                           tags$li("Common and reliable"),
                           tags$li("Clear target calculation")
                         )
                     )
              ),
              column(4,
                     div(class = "key-point",
                         h4("Triple Tops/Bottoms"),
                         tags$ul(
                           tags$li("Three peaks/troughs"),
                           tags$li("Less common than double"),
                           tags$li("Very reliable when confirmed"),
                           tags$li("Stronger signal")
                         )
                     )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Pattern Selection",
            status = "info",
            solidHeader = TRUE,
            width = 3,
            selectInput("rev_pattern", "Select Pattern:",
                        choices = c("Head & Shoulders" = "head_shoulders",
                                    "Inverse H&S" = "inv_head_shoulders",
                                    "Double Top" = "double_top",
                                    "Double Bottom" = "double_bottom"),
                        selected = "head_shoulders"),
            
            checkboxInput("show_neckline", "Show Neckline", value = TRUE),
            checkboxInput("show_rev_mpo", "Show MPO Target", value = TRUE),
            checkboxInput("show_divergence", "Show Momentum Divergence", value = FALSE),
            
            uiOutput("reversal_description")
          ),
          
          box(
            title = "Reversal Pattern Visualization",
            status = "primary",
            solidHeader = TRUE,
            width = 9,
            withSpinner(plotlyOutput("reversalChart", height = "500px"))
          )
        ),
        
        fluidRow(
          box(
            title = "Head & Shoulders Trading Rules",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            div(class = "key-point",
                h4("Key Characteristics:"),
                tags$ul(
                  tags$li(strong("Prior Trend:"), " Must have uptrend before H&S top"),
                  tags$li(strong("Head:"), " Must be highest point"),
                  tags$li(strong("Neckline:"), " Drawn through shoulder lows"),
                  tags$li(strong("Breakout:"), " Sell when neckline breaks"),
                  tags$li(strong("Return Move:"), " Often retests neckline"),
                  tags$li(strong("Target:"), " Height of pattern from neckline")
                ),
                br(),
                div(class = "example-box",
                    h4("Confirmation Signals:"),
                    tags$ul(
                      tags$li("Price fails to reach top of channel"),
                      tags$li("Bearish momentum divergence"),
                      tags$li("Lower high on right shoulder"),
                      tags$li("Volume decreases on right shoulder")
                    )
                )
            )
          ),
          
          box(
            title = "Double Top/Bottom Strategy",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            div(class = "example-box",
                h4("Trading Double Tops/Bottoms:"),
                tags$ol(
                  tags$li(strong("Identify:"), " Two peaks/troughs at similar levels"),
                  tags$li(strong("Confirm:"), " Break of support/resistance between peaks"),
                  tags$li(strong("Enter:"), " On breakout with filter confirmation"),
                  tags$li(strong("Return Move:"), " Often provides 2nd entry chance"),
                  tags$li(strong("Target:"), " Height of pattern from breakout point"),
                  tags$li(strong("Stop:"), " Beyond the second peak/trough")
                ),
                br(),
                div(class = "key-point",
                    h4(icon("star"), " Pro Tip:"),
                    p("Double tops/bottoms within a larger trend correction often provide 
                      excellent continuation trades. The pattern confirms the end of the 
                      correction and resumption of the main trend.")
                )
            )
          )
        )
      ),
      
      # Wedges Tab
      tabItem(
        tabName = "wedges",
        fluidRow(
          box(
            title = "Wedge Patterns",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("Understanding Wedges"),
                p("Wedges are powerful patterns where price action converges between two trendlines, 
                  but unlike triangles, both lines slope in the same direction. Wedges can act as either 
                  continuation or reversal patterns depending on context.")
            ),
            
            fluidRow(
              column(6,
                     div(class = "key-point",
                         h4("Rising Wedge (Bearish)"),
                         tags$ul(
                           tags$li("Price makes higher highs and higher lows"),
                           tags$li("Range narrows as it rises"),
                           tags$li("Momentum typically falling"),
                           tags$li("Usually breaks DOWN"),
                           tags$li("Can be reversal or continuation")
                         )
                     )
              ),
              column(6,
                     div(class = "key-point",
                         h4("Falling Wedge (Bullish)"),
                         tags$ul(
                           tags$li("Price makes lower highs and lower lows"),
                           tags$li("Range narrows as it falls"),
                           tags$li("Momentum typically rising"),
                           tags$li("Usually breaks UP"),
                           tags$li("Can be reversal or continuation")
                         )
                     )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Wedge Configuration",
            status = "info",
            solidHeader = TRUE,
            width = 3,
            selectInput("wedge_type", "Wedge Type:",
                        choices = c("Rising Wedge (Bearish)" = "rising",
                                    "Falling Wedge (Bullish)" = "falling"),
                        selected = "falling"),
            selectInput("wedge_context", "Context:",
                        choices = c("In Uptrend (Continuation)" = "up_cont",
                                    "In Downtrend (Reversal)" = "down_rev",
                                    "After Uptrend (Reversal)" = "up_rev",
                                    "In Downtrend (Continuation)" = "down_cont"),
                        selected = "up_cont"),
            
            checkboxInput("show_wedge_lines", "Show Wedge Lines", value = TRUE),
            checkboxInput("show_wedge_target", "Show Target", value = TRUE),
            checkboxInput("show_wedge_breakout", "Highlight Breakout", value = TRUE),
            
            div(class = "example-box",
                h4("Key Points:"),
                tags$ul(
                  tags$li("Wedges show loss of momentum"),
                  tags$li("Breakout opposite to wedge angle"),
                  tags$li("Return moves common"),
                  tags$li("Target = height of wedge base")
                )
            )
          ),
          
          box(
            title = "Wedge Pattern Visualization",
            status = "primary",
            solidHeader = TRUE,
            width = 9,
            withSpinner(plotlyOutput("wedgeChart", height = "500px"))
          )
        ),
        
        fluidRow(
          box(
            title = "Rising Wedge Characteristics",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            div(class = "example-box",
                h4("Rising Wedge as Bear Market Rally"),
                p("When appearing in a downtrend, a rising wedge represents a weak rally where:"),
                tags$ul(
                  tags$li("Buyers struggle to push higher"),
                  tags$li("Each rally is weaker (converging lines)"),
                  tags$li("Momentum divergence appears"),
                  tags$li("Eventually breaks down to continue downtrend")
                ),
                br(),
                h4("Rising Wedge as Uptrend Reversal"),
                p("When appearing after an uptrend:"),
                tags$ul(
                  tags$li("Final push higher by exhausted bulls"),
                  tags$li("Narrowing range shows weakening"),
                  tags$li("Volume typically decreases"),
                  tags$li("Breaks down to reverse the trend")
                )
            )
          ),
          
          box(
            title = "Falling Wedge Characteristics",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            div(class = "key-point",
                h4("Falling Wedge as Uptrend Correction"),
                p("When appearing in an uptrend, a falling wedge represents a pause where:"),
                tags$ul(
                  tags$li("Sellers unable to push much lower"),
                  tags$li("Each decline is shallower (converging lines)"),
                  tags$li("Momentum starts rising (bullish divergence)"),
                  tags$li("Eventually breaks up to continue uptrend")
                ),
                br(),
                h4("Falling Wedge as Downtrend Reversal"),
                p("When appearing after a downtrend:"),
                tags$ul(
                  tags$li("Final washout by exhausted bears"),
                  tags$li("Narrowing range shows weakening selling"),
                  tags$li("Bullish divergence common"),
                  tags$li("Breaks up to reverse the trend")
                )
            )
          )
        )
      ),
      
      # Dow Theory Tab
      tabItem(
        tabName = "dow",
        fluidRow(
          box(
            title = "Dow Theory - The Foundation of Technical Analysis",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("Charles Dow (1851-1902)"),
                p("Charles Dow invented the most famous method of identifying major trends 
                  in the stock market. He was concerned with market direction as a barometer 
                  of economic business conditions, not specifically to forecast stock prices."),
                br(),
                h4("The Dow Jones Indices"),
                tags$ul(
                  tags$li(strong("Dow Jones Industrial Index:"), " Health of companies that make goods"),
                  tags$li(strong("Dow Jones Transportation Index:"), " Health of companies that distribute goods")
                ),
                p("Dow needed to see BOTH indices performing well to confirm economic health.")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Six Tenets of Dow Theory",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(6,
                     div(class = "key-point",
                         tags$ol(
                           tags$li(strong("The averages discount everything"), 
                                   " (except acts of God)"),
                           tags$li(strong("Three types of trend"), 
                                   " (Primary, Secondary, Minor)"),
                           tags$li(strong("Major trends have three phases"), 
                                   " (Accumulation, Trending, Distribution)")
                         )
                     )
              ),
              column(6,
                     div(class = "key-point",
                         tags$ol(start = 4,
                                 tags$li(strong("Volume should confirm the trend")),
                                 tags$li(strong("Price action determines the trend")),
                                 tags$li(strong("The averages must confirm each other"))
                         ),
                         br(),
                         p(em("A trend remains in place until it shows a definite sign of reversal."))
                     )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Three Trend Types",
            status = "success",
            solidHeader = TRUE,
            width = 4,
            div(class = "concept-box",
                h4("Primary Trend"),
                p(strong("Duration:"), " More than a year"),
                p(strong("Character:"), " The main direction"),
                p("Like the tide in the ocean"),
                br(),
                h4("Secondary Trend"),
                p(strong("Duration:"), " 3 weeks to 3 months"),
                p(strong("Character:"), " Corrections"),
                p("Like waves in the tide"),
                br(),
                h4("Minor Trend"),
                p(strong("Duration:"), " Less than 3 weeks"),
                p(strong("Character:"), " Short-term fluctuations"),
                p("Like ripples on the waves")
            )
          ),
          
          box(
            title = "Three Market Phases",
            status = "warning",
            solidHeader = TRUE,
            width = 8,
            div(class = "key-point",
                h4("Bull Market Phases:"),
                tags$ol(
                  tags$li(strong("Accumulation Phase"), 
                          " - Informed investors buy at bargain prices while the public is pessimistic"),
                  tags$li(strong("Trending Phase"), 
                          " - Public participation increases, prices advance steadily, fundamentals improve"),
                  tags$li(strong("Distribution Phase"), 
                          " - Public is most bullish, informed investors sell to them at high prices")
                )
            ),
            br(),
            div(class = "example-box",
                h4("Bear Market Phases:"),
                tags$ol(
                  tags$li(strong("Distribution Phase"), 
                          " - Informed investors sell while public is still optimistic"),
                  tags$li(strong("Panic Phase"), 
                          " - Sharp declines, public rushes to sell, fear dominates"),
                  tags$li(strong("Capitulation Phase"), 
                          " - Final washout, discouraged investors give up, prices stabilize")
                )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Dow Theory Pros and Cons",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(6,
                     div(class = "key-point",
                         h4(icon("check-circle"), " Advantages"),
                         tags$ul(
                           tags$li("Identifies major trends early"),
                           tags$li("Captures large middle section of moves"),
                           tags$li("Larger profits from long-term trends"),
                           tags$li("Strong weight of evidence before signals"),
                           tags$li("Reduces noise from minor fluctuations")
                         )
                     )
              ),
              column(6,
                     div(class = "example-box",
                         h4(icon("exclamation-triangle"), " Limitations"),
                         tags$ul(
                           tags$li("Signals generated after 20-25% of trend complete"),
                           tags$li("Not designed to pick exact tops/bottoms"),
                           tags$li("Requires patience and discipline"),
                           tags$li("May miss short-term opportunities"),
                           tags$li("Both indices must confirm (original approach)")
                         )
                     )
              )
            )
          )
        )
      ),
      
      # Market Cycles Tab
      tabItem(
        tabName = "cycles",
        fluidRow(
          box(
            title = "Bull and Bear Market Cycles",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "concept-box",
                h4("Understanding Market Psychology"),
                p("Stock markets move in predictable psychological cycles. Many retail investors - 
                  and even some professionals - behave in predictable ways during the formation of 
                  bull (upward) and bear (downward) markets. Understanding these cycles is crucial 
                  for successful long-term investing.")
            ),
            
            div(class = "key-point",
                h4(icon("lightbulb"), " Key Insight"),
                p(strong("Equity prices tend to ANTICIPATE economic cycles by 3-6 months."), 
                  " The stock market is a leading indicator, not a lagging one. This is why markets 
                  often bottom while economic news is still terrible, and top while news is still positive.")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Market Cycle Visualization",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            withSpinner(plotlyOutput("cycleChart", height = "500px"))
          )
        ),
        
        fluidRow(
          box(
            title = "Bull Market Phase 1: Accumulation",
            status = "success",
            solidHeader = TRUE,
            width = 4,
            div(class = "concept-box",
                h4("Characteristics:"),
                p(strong("Market:"), " Prices recover after long decline"),
                p(strong("Emotions:"), " Scepticism, suspicion"),
                p(strong("Retail:"), " Stay away, don't trust rally"),
                p(strong("Professionals:"), " Buy at bargain prices"),
                p(strong("Economy:"), " Bad news continues"),
                br(),
                div(class = "key-point",
                    p(strong("Duration:"), " ~15% of cycle"),
                    p(strong("Dow Theory:"), " Accumulation Phase")
                )
            )
          ),
          
          box(
            title = "Bull Market Phase 2: Trending",
            status = "success",
            solidHeader = TRUE,
            width = 4,
            div(class = "concept-box",
                h4("Characteristics:"),
                p(strong("Market:"), " Strong rise on increasing volume"),
                p(strong("Emotions:"), " Growing recognition, confidence"),
                p(strong("Retail:"), " Start buying, realize recovery"),
                p(strong("Professionals:"), " Accelerate buying"),
                p(strong("Economy:"), " Fundamentals improving"),
                br(),
                div(class = "key-point",
                    p(strong("Duration:"), " ~25% of cycle"),
                    p(strong("Dow Theory:"), " Trending Phase"),
                    p(em("This is the sweet spot!"))
                )
            )
          ),
          
          box(
            title = "Bull Market Phase 3: Distribution",
            status = "success",
            solidHeader = TRUE,
            width = 4,
            div(class = "concept-box",
                h4("Characteristics:"),
                p(strong("Market:"), " Rising but slowing, volume drops"),
                p(strong("Emotions:"), " (Over)enthusiasm, conviction"),
                p(strong("Retail:"), " Over-excited, keep buying"),
                p(strong("Professionals:"), " Selling at high prices"),
                p(strong("Economy:"), " Looks extremely positive"),
                br(),
                div(class = "example-box",
                    p(strong("Duration:"), " ~15% of cycle"),
                    p(strong("Dow Theory:"), " Distribution Phase"),
                    p(strong("Warning sign!"))
                )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Bear Market Phase 1: Initial Decline",
            status = "danger",
            solidHeader = TRUE,
            width = 4,
            div(class = "concept-box",
                h4("Characteristics:"),
                p(strong("Market:"), " Clear technical deterioration"),
                p(strong("Emotions:"), " Disbelief"),
                p(strong("Retail:"), " Keep buying, think it's a bargain"),
                p(strong("Professionals:"), " Accelerate selling"),
                p(strong("Economy:"), " Profit warnings increasing"),
                br(),
                div(class = "example-box",
                    p(strong("Duration:"), " ~15% of cycle"),
                    p(em("'This can't be happening'"))
                )
            )
          ),
          
          box(
            title = "Bear Market Phase 2: Panic",
            status = "danger",
            solidHeader = TRUE,
            width = 4,
            div(class = "concept-box",
                h4("Characteristics:"),
                p(strong("Market:"), " Prices accelerate lower"),
                p(strong("Emotions:"), " Panic, shock, fear"),
                p(strong("Retail:"), " Mood shifts from hope to fear"),
                p(strong("Professionals:"), " Panic sell too"),
                p(strong("Economy:"), " Much worse than expected"),
                br(),
                div(class = "example-box",
                    p(strong("Duration:"), " ~15% of cycle"),
                    p(strong("Character:"), " Steepest declines"),
                    p(em("Maximum pain!"))
                )
            )
          ),
          
          box(
            title = "Bear Market Phase 3: Capitulation",
            status = "danger",
            solidHeader = TRUE,
            width = 4,
            div(class = "concept-box",
                h4("Characteristics:"),
                p(strong("Market:"), " Still falling but slowing"),
                p(strong("Emotions:"), " Disgust, disillusionment"),
                p(strong("Retail:"), " Finally sell at big losses"),
                p(strong("Professionals:"), " Continue selling into rallies"),
                p(strong("Economy:"), " Outlook still bleak"),
                br(),
                div(class = "key-point",
                    p(strong("Duration:"), " ~15% of cycle"),
                    p(em("'I'm never investing again'")),
                    p(strong("...then cycle repeats!"))
                )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "The Emotional Cycle of Investing",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            div(class = "example-box",
                h4(icon("brain"), " Investor Psychology Through the Cycle"),
                br(),
                fluidRow(
                  column(6,
                         h5(style = "color: #28a745;", "BULL MARKET EMOTIONS:"),
                         p("Optimism → Excitement → Thrill → Euphoria"),
                         p(strong("At market top:"), " Maximum confidence, everyone's an expert")
                  ),
                  column(6,
                         h5(style = "color: #dc3545;", "BEAR MARKET EMOTIONS:"),
                         p("Anxiety → Denial → Fear → Desperation → Panic → Capitulation"),
                         p(strong("At market bottom:"), " Maximum pessimism, total loss of confidence")
                  )
                ),
                br(),
                div(class = "key-point",
                    h4("The Professional's Advantage:"),
                    p(strong("Buy when others are fearful, sell when others are greedy."), 
                      " - Warren Buffett"),
                    p("Professional investors succeed by controlling emotions and acting 
                      counter to the crowd at extremes.")
                )
            )
          )
        )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Filters Tab - Breakout Chart
  output$filterChart <- renderPlotly({
    data <- generate_sample_data(120, "uptrend")
    
    # Add resistance level
    resistance <- 107
    
    # Simulate breakout
    breakout_point <- 90
    data$Close[breakout_point:nrow(data)] <- data$Close[breakout_point:nrow(data)] + 3
    
    p <- plot_ly(data, x = ~Date, type = "scatter", mode = "lines") %>%
      add_lines(y = ~Close, name = "Price", line = list(color = "#2c3e50", width = 2))
    
    # Add resistance line
    p <- p %>% add_lines(x = data$Date, y = rep(resistance, nrow(data)), 
                         name = "Resistance", line = list(color = "#e74c3c", width = 2, dash = "dash"))
    
    # Highlight breakout
    if (input$filter_type %in% c("Time Filter", "Combination Filter")) {
      # Mark candle close confirmation
      p <- p %>% add_markers(x = data$Date[breakout_point + 1], y = data$Close[breakout_point + 1],
                             name = "Time Filter Confirmation", 
                             marker = list(size = 12, color = "#27ae60", symbol = "circle"))
    }
    
    if (input$filter_type %in% c("Price Filter", "Combination Filter")) {
      price_level <- resistance * (1 + input$price_filter/100)
      p <- p %>% add_lines(x = data$Date, y = rep(price_level, nrow(data)),
                           name = paste0("Price Filter (", input$price_filter, "%)"),
                           line = list(color = "#f39c12", width = 1, dash = "dot"))
    }
    
    # Impulsive candle
    p <- p %>% add_markers(x = data$Date[breakout_point], y = data$Close[breakout_point],
                           name = "Impulsive Breakout",
                           marker = list(size = 15, color = "#9b59b6", symbol = "star"))
    
    p %>% layout(
      title = paste("Breakout Confirmation with", input$filter_type),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price"),
      hovermode = "x unified",
      showlegend = TRUE,
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  # S/R Role Reversal Chart
  output$srReversalChart <- renderPlotly({
    if (input$sr_pattern == "res_to_sup") {
      data <- generate_sample_data(150, "uptrend")
      level <- 105
      breakout_point <- 100
      
      p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                   name = "Price", line = list(color = "#2c3e50", width = 2))
      
      if (input$show_sr_lines) {
        # Old resistance
        p <- p %>% add_lines(x = data$Date[1:breakout_point], 
                             y = rep(level, breakout_point),
                             name = "Old Resistance", 
                             line = list(color = "#e74c3c", width = 2, dash = "dash"))
        
        # New support
        p <- p %>% add_lines(x = data$Date[breakout_point:nrow(data)], 
                             y = rep(level, nrow(data) - breakout_point + 1),
                             name = "New Support", 
                             line = list(color = "#27ae60", width = 2, dash = "dash"))
      }
      
      if (input$show_breakout) {
        p <- p %>% add_markers(x = data$Date[breakout_point], y = data$Close[breakout_point],
                               name = "Breakout", marker = list(size = 15, color = "#9b59b6"))
      }
      
      if (input$show_retest) {
        retest_point <- breakout_point + 15
        p <- p %>% add_markers(x = data$Date[retest_point], y = level,
                               name = "Return Move/Retest", 
                               marker = list(size = 12, color = "#f39c12", symbol = "diamond"))
      }
      
    } else {
      data <- generate_sample_data(150, "downtrend")
      level <- 140
      breakout_point <- 100
      
      p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                   name = "Price", line = list(color = "#2c3e50", width = 2))
      
      if (input$show_sr_lines) {
        p <- p %>% add_lines(x = data$Date[1:breakout_point], 
                             y = rep(level, breakout_point),
                             name = "Old Support", 
                             line = list(color = "#27ae60", width = 2, dash = "dash"))
        
        p <- p %>% add_lines(x = data$Date[breakout_point:nrow(data)], 
                             y = rep(level, nrow(data) - breakout_point + 1),
                             name = "New Resistance", 
                             line = list(color = "#e74c3c", width = 2, dash = "dash"))
      }
      
      if (input$show_breakout) {
        p <- p %>% add_markers(x = data$Date[breakout_point], y = data$Close[breakout_point],
                               name = "Breakout", marker = list(size = 15, color = "#9b59b6"))
      }
      
      if (input$show_retest) {
        retest_point <- breakout_point + 15
        p <- p %>% add_markers(x = data$Date[retest_point], y = level,
                               name = "Return Move/Retest", 
                               marker = list(size = 12, color = "#f39c12", symbol = "diamond"))
      }
    }
    
    p %>% layout(
      title = "Support/Resistance Role Reversal",
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  # Timeframe Table
  output$timeframeTable <- DT::renderDataTable({
    df <- data.frame(
      "Holding Period" = c("5 minutes", "1 hour", "4 hours", "1 day", "1 week", "1 month"),
      "Long Term Trend" = c("30-60 minutes", "6-12 hours", "24-48 hours", "1-2 weeks", "1-3 months", "6-12 months"),
      "Chart Timeframe" = c("Tick/1-minute", "5/10-minute", "15/30-minute", "30/60-minute", "60/120-minute", "6/12-hour or Daily"),
      stringsAsFactors = FALSE
    )
    
    datatable(df, 
              options = list(dom = 't', pageLength = 10),
              rownames = FALSE) %>%
      formatStyle(columns = 1:3, fontSize = '14px')
  })
  
  # Recommended Timeframes
  output$recommended_timeframes <- renderUI({
    multiplier <- switch(input$holding_period,
                         "5 minutes" = 10,
                         "1 hour" = 10,
                         "4 hours" = 10,
                         "1 day" = 10,
                         "1 week" = 10,
                         "1 month" = 10)
    
    chart_tf <- switch(input$holding_period,
                       "5 minutes" = "1-minute chart",
                       "1 hour" = "5 or 10-minute chart",
                       "4 hours" = "30-minute chart",
                       "1 day" = "1-hour chart",
                       "1 week" = "2-hour chart",
                       "1 month" = "Daily chart")
    
    long_term <- switch(input$holding_period,
                        "5 minutes" = "30-60 minutes",
                        "1 hour" = "6-12 hours",
                        "4 hours" = "1-2 days",
                        "1 day" = "1-2 weeks",
                        "1 week" = "2-3 months",
                        "1 month" = "6-12 months")
    
    div(class = "example-box",
        h4("Recommended Setup:"),
        p(strong("Your holding period:"), input$holding_period),
        p(strong("Long-term trend:"), long_term),
        p(strong("Chart to use:"), chart_tf),
        br(),
        p(em("Trade with the long-term trend for best results!"))
    )
  })
  
  # Timeframe Chart
  output$timeframeChart <- renderPlotly({
    # Generate data for different timeframes
    daily_data <- generate_sample_data(180, "uptrend")
    
    # Aggregate to weekly
    weekly_data <- daily_data %>%
      mutate(Week = floor_date(Date, "week")) %>%
      group_by(Week) %>%
      summarise(Close = last(Close), .groups = "drop")
    
    p <- plot_ly() %>%
      add_lines(data = daily_data, x = ~Date, y = ~Close, 
                name = "Daily (Short-term)", 
                line = list(color = "#3498db", width = 1)) %>%
      add_lines(data = weekly_data, x = ~Week, y = ~Close,
                name = "Weekly (Long-term)",
                line = list(color = "#e74c3c", width = 3))
    
    p %>% layout(
      title = "Multiple Timeframe View",
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  # Fibonacci Chart
  output$fibonacciChart <- renderPlotly({
    if (input$fib_trend == "Uptrend") {
      data <- generate_sample_data(120, "uptrend")
    } else {
      data <- generate_sample_data(120, "downtrend")
    }
    
    # Find swing points
    swing_low <- min(data$Close[1:40])
    swing_high <- max(data$Close[1:80])
    swing_low_idx <- which.min(data$Close[1:40])
    swing_high_idx <- which.max(data$Close[1:80])
    
    range <- swing_high - swing_low
    
    p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                 name = "Price", line = list(color = "#2c3e50", width = 2))
    
    if (input$fib_tool == "Retracement") {
      # Draw Fibonacci retracement levels
      levels <- as.numeric(input$fib_levels) / 100
      
      for (level in levels) {
        if (input$fib_trend == "Uptrend") {
          price_level <- swing_high - (range * level)
        } else {
          price_level <- swing_low + (range * level)
        }
        
        color <- if (level == 0.382) "#e74c3c" 
        else if (level == 0.5) "#f39c12" 
        else if (level == 0.618) "#27ae60"
        else "#95a5a6"
        
        p <- p %>% add_lines(x = data$Date, y = rep(price_level, nrow(data)),
                             name = paste0(level * 100, "% Fib"),
                             line = list(color = color, width = 1, dash = "dash"))
      }
      
      # Highlight buying/selling zone
      if ("38.2" %in% input$fib_levels && "61.8" %in% input$fib_levels) {
        if (input$fib_trend == "Uptrend") {
          zone_top <- swing_high - (range * 0.382)
          zone_bottom <- swing_high - (range * 0.618)
        } else {
          zone_top <- swing_low + (range * 0.618)
          zone_bottom <- swing_low + (range * 0.382)
        }
        
        p <- p %>% add_ribbons(x = data$Date,
                               ymin = rep(zone_bottom, nrow(data)),
                               ymax = rep(zone_top, nrow(data)),
                               name = "Buying/Selling Zone",
                               fillcolor = "rgba(52, 152, 219, 0.2)",
                               line = list(width = 0))
      }
      
    } else {
      # Extension levels
      if (input$fib_trend == "Uptrend") {
        ext_1272 <- swing_high + (range * 0.272)
        ext_1618 <- swing_high + (range * 0.618)
        
        p <- p %>%
          add_lines(x = data$Date, y = rep(ext_1272, nrow(data)),
                    name = "127.2% Target", 
                    line = list(color = "#27ae60", width = 2, dash = "dot")) %>%
          add_lines(x = data$Date, y = rep(ext_1618, nrow(data)),
                    name = "161.8% Target",
                    line = list(color = "#e74c3c", width = 2, dash = "dot"))
      } else {
        ext_1272 <- swing_low - (range * 0.272)
        ext_1618 <- swing_low - (range * 0.618)
        
        p <- p %>%
          add_lines(x = data$Date, y = rep(ext_1272, nrow(data)),
                    name = "127.2% Target",
                    line = list(color = "#27ae60", width = 2, dash = "dot")) %>%
          add_lines(x = data$Date, y = rep(ext_1618, nrow(data)),
                    name = "161.8% Target",
                    line = list(color = "#e74c3c", width = 2, dash = "dot"))
      }
    }
    
    # Mark swing points
    p <- p %>%
      add_markers(x = data$Date[swing_low_idx], y = swing_low,
                  name = "Swing Low", marker = list(size = 12, color = "#27ae60")) %>%
      add_markers(x = data$Date[swing_high_idx], y = swing_high,
                  name = "Swing High", marker = list(size = 12, color = "#e74c3c"))
    
    p %>% layout(
      title = paste("Fibonacci", input$fib_tool, "Analysis"),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  # Pattern Description for Continuation Patterns
  output$pattern_description <- renderUI({
    description <- switch(input$cont_pattern,
                          "triangle_sym" = div(class = "key-point",
                                               h4("Symmetrical Triangle"),
                                               p("Converging trendlines, breakout direction confirms trend continuation."),
                                               p("Target = height of base")),
                          "triangle_asc" = div(class = "key-point",
                                               h4("Ascending Triangle"),
                                               p("Flat top resistance, rising support. Usually breaks UP."),
                                               p("Bullish pattern")),
                          "triangle_desc" = div(class = "key-point",
                                                h4("Descending Triangle"),
                                                p("Flat bottom support, declining resistance. Usually breaks DOWN."),
                                                p("Bearish pattern")),
                          "flag_bull" = div(class = "key-point",
                                            h4("Bullish Flag"),
                                            p("After sharp rise, brief downward consolidation."),
                                            p("High probability continuation UP")),
                          "flag_bear" = div(class = "key-point",
                                            h4("Bearish Flag"),
                                            p("After sharp decline, brief upward consolidation."),
                                            p("High probability continuation DOWN"))
    )
    description
  })
  
  # Continuation Pattern Chart
  output$continuationChart <- renderPlotly({
    pattern_type <- switch(input$cont_pattern,
                           "triangle_sym" = "triangle",
                           "triangle_asc" = "triangle",
                           "triangle_desc" = "triangle",
                           "flag_bull" = "uptrend",
                           "flag_bear" = "downtrend")
    
    data <- generate_sample_data(100, pattern_type)
    
    p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                 name = "Price", line = list(color = "#2c3e50", width = 2))
    
    if (input$show_pattern_lines) {
      if (grepl("triangle", input$cont_pattern)) {
        # Draw triangle lines
        mid_point <- nrow(data) / 2
        upper_start <- max(data$Close[1:30])
        lower_start <- min(data$Close[1:30])
        convergence <- mean(data$Close[40:60])
        
        upper_line <- c(rep(upper_start, 30), 
                        seq(upper_start, convergence, length.out = 30),
                        rep(convergence, nrow(data) - 60))
        lower_line <- c(rep(lower_start, 30),
                        seq(lower_start, convergence, length.out = 30),
                        rep(convergence, nrow(data) - 60))
        
        p <- p %>%
          add_lines(x = data$Date, y = upper_line, name = "Upper Line",
                    line = list(color = "#e74c3c", width = 2, dash = "dash")) %>%
          add_lines(x = data$Date, y = lower_line, name = "Lower Line",
                    line = list(color = "#27ae60", width = 2, dash = "dash"))
      } else {
        # Draw flag lines
        flag_start <- 60
        flag_end <- 80
        if (input$cont_pattern == "flag_bull") {
          upper <- data$Close[flag_start] - 2
          lower <- data$Close[flag_start] - 4
        } else {
          upper <- data$Close[flag_start] + 4
          lower <- data$Close[flag_start] + 2
        }
        
        p <- p %>%
          add_segments(x = data$Date[flag_start], xend = data$Date[flag_end],
                       y = upper, yend = upper - 0.5,
                       name = "Flag Upper", line = list(color = "#e74c3c", width = 2)) %>%
          add_segments(x = data$Date[flag_start], xend = data$Date[flag_end],
                       y = lower, yend = lower - 0.5,
                       name = "Flag Lower", line = list(color = "#27ae60", width = 2))
      }
    }
    
    if (input$show_entry) {
      entry_point <- 65
      p <- p %>% add_markers(x = data$Date[entry_point], y = data$Close[entry_point],
                             name = "Entry Point", marker = list(size = 12, color = "#9b59b6"))
    }
    
    if (input$show_mpo) {
      base_height <- max(data$Close[1:40]) - min(data$Close[1:40])
      target <- data$Close[70] + base_height
      p <- p %>% add_lines(x = data$Date[70:nrow(data)], 
                           y = rep(target, nrow(data) - 69),
                           name = "Target (MPO)",
                           line = list(color = "#f39c12", width = 2, dash = "dot"))
    }
    
    p %>% layout(
      title = "Continuation Pattern Example",
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  # Reversal Pattern Description
  output$reversal_description <- renderUI({
    description <- switch(input$rev_pattern,
                          "head_shoulders" = div(class = "key-point",
                                                 h4("Head & Shoulders Top"),
                                                 p("Bearish reversal after uptrend."),
                                                 p("Head = highest point, neckline break = sell signal")),
                          "inv_head_shoulders" = div(class = "key-point",
                                                     h4("Inverse Head & Shoulders"),
                                                     p("Bullish reversal after downtrend."),
                                                     p("Head = lowest point, neckline break = buy signal")),
                          "double_top" = div(class = "key-point",
                                             h4("Double Top"),
                                             p("'M' pattern, bearish reversal."),
                                             p("Two peaks at similar levels")),
                          "double_bottom" = div(class = "key-point",
                                                h4("Double Bottom"),
                                                p("'W' pattern, bullish reversal."),
                                                p("Two troughs at similar levels"))
    )
    description
  })
  
  # Reversal Pattern Chart
  output$reversalChart <- renderPlotly({
    pattern_type <- switch(input$rev_pattern,
                           "head_shoulders" = "head_shoulders",
                           "inv_head_shoulders" = "head_shoulders",
                           "double_top" = "double_top",
                           "double_bottom" = "double_top")
    
    data <- generate_sample_data(120, pattern_type)
    
    # Flip for inverse patterns
    if (input$rev_pattern %in% c("inv_head_shoulders", "double_bottom")) {
      data$Close <- max(data$Close) + min(data$Close) - data$Close
    }
    
    p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                 name = "Price", line = list(color = "#2c3e50", width = 2))
    
    if (input$show_neckline) {
      if (grepl("head", input$rev_pattern)) {
        # H&S neckline
        neckline <- mean(data$Close[30:35])
        p <- p %>% add_lines(x = data$Date, y = rep(neckline, nrow(data)),
                             name = "Neckline", 
                             line = list(color = "#e74c3c", width = 2, dash = "dash"))
      } else {
        # Double top/bottom middle level
        middle <- mean(c(max(data$Close[1:60]), min(data$Close[1:60])))
        p <- p %>% add_lines(x = data$Date, y = rep(middle, nrow(data)),
                             name = "Support/Resistance",
                             line = list(color = "#e74c3c", width = 2, dash = "dash"))
      }
    }
    
    if (input$show_rev_mpo) {
      if (grepl("head", input$rev_pattern)) {
        neckline <- mean(data$Close[30:35])
        height <- max(data$Close) - neckline
        if (input$rev_pattern == "head_shoulders") {
          target <- neckline - height
        } else {
          target <- neckline + height
        }
      } else {
        height <- max(data$Close[1:60]) - min(data$Close[1:60])
        middle <- mean(c(max(data$Close[1:60]), min(data$Close[1:60])))
        if (grepl("top", input$rev_pattern)) {
          target <- middle - height
        } else {
          target <- middle + height
        }
      }
      
      p <- p %>% add_lines(x = data$Date[70:nrow(data)], y = rep(target, nrow(data) - 69),
                           name = "Target (MPO)",
                           line = list(color = "#f39c12", width = 2, dash = "dot"))
    }
    
    p %>% layout(
      title = paste(input$rev_pattern, "Pattern"),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  # Wedge Chart
  output$wedgeChart <- renderPlotly({
    if (input$wedge_type == "rising") {
      data <- generate_sample_data(90, "wedge_rising")
    } else {
      data <- generate_sample_data(90, "wedge_falling")
    }
    
    p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                 name = "Price", line = list(color = "#2c3e50", width = 2))
    
    if (input$show_wedge_lines) {
      if (input$wedge_type == "rising") {
        lower_line <- seq(data$Close[1], data$Close[70], length.out = 70)
        upper_line <- seq(data$Close[1] + 3, data$Close[70] + 1.5, length.out = 70)
      } else {
        upper_line <- seq(data$Close[1], data$Close[70], length.out = 70)
        lower_line <- seq(data$Close[1] - 3, data$Close[70] - 1.5, length.out = 70)
      }
      
      p <- p %>%
        add_lines(x = data$Date[1:70], y = upper_line, name = "Upper Line",
                  line = list(color = "#e74c3c", width = 2, dash = "dash")) %>%
        add_lines(x = data$Date[1:70], y = lower_line, name = "Lower Line",
                  line = list(color = "#27ae60", width = 2, dash = "dash"))
    }
    
    if (input$show_wedge_breakout) {
      breakout_point <- 72
      p <- p %>% add_markers(x = data$Date[breakout_point], y = data$Close[breakout_point],
                             name = "Breakout", marker = list(size = 12, color = "#9b59b6"))
    }
    
    if (input$show_wedge_target) {
      if (input$wedge_type == "rising") {
        base_height <- 3
        target <- data$Close[72] - base_height
      } else {
        base_height <- 3
        target <- data$Close[72] + base_height
      }
      
      p <- p %>% add_lines(x = data$Date[72:nrow(data)], y = rep(target, nrow(data) - 71),
                           name = "Target",
                           line = list(color = "#f39c12", width = 2, dash = "dot"))
    }
    
    p %>% layout(
      title = paste(input$wedge_type, "Wedge Pattern"),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  # Market Cycle Chart
  output$cycleChart <- renderPlotly({
    cycle_data <- generate_market_cycle()
    
    # Color by phase
    colors <- c(
      "Bull Phase 1: Accumulation" = "#90EE90",
      "Bull Phase 2: Trending" = "#228B22",
      "Bull Phase 3: Distribution" = "#FFD700",
      "Bear Phase 1: Initial Decline" = "#FFA500",
      "Bear Phase 2: Panic" = "#FF6347",
      "Bear Phase 3: Capitulation" = "#8B0000"
    )
    
    p <- plot_ly(cycle_data, x = ~Date, y = ~Price, 
                 color = ~Phase, colors = colors,
                 type = "scatter", mode = "lines",
                 line = list(width = 3)) %>%
      layout(
        title = "Bull and Bear Market Cycle (2015-2024)",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Market Index"),
        hovermode = "x unified",
        showlegend = TRUE,
        legend = list(orientation = "h", x = 0, y = -0.2),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    # Add phase annotations
    phase_midpoints <- cycle_data %>%
      group_by(Phase) %>%
      summarise(
        Date = median(Date),
        Price = max(Price),
        .groups = "drop"
      )
    
    for (i in 1:nrow(phase_midpoints)) {
      p <- p %>% add_annotations(
        x = phase_midpoints$Date[i],
        y = phase_midpoints$Price[i],
        text = gsub("^[^:]+: ", "", phase_midpoints$Phase[i]),
        showarrow = FALSE,
        font = list(size = 10, color = "white"),
        bgcolor = "rgba(0,0,0,0.6)",
        borderpad = 4
      )
    }
    
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)