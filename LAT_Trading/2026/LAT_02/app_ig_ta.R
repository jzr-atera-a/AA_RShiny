# Multi-Asset Analysis Dashboard - Cryptocurrencies, Private Equity & Commodities
# Real-time data fetching with quantmod for stocks and crypto data sources
# Enhanced with Sharpe Ratio, Sortino Ratio, and Hedging Strategy Indicators

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
library(corrplot)
library(httr)        # direct Yahoo Finance intraday chart API calls
library(jsonlite)    # parsing Yahoo intraday JSON responses
library(igfetchr)   # IG Trading REST API wrapper (CRAN) — install.packages("igfetchr")

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "IG Trading & Technical Analysis"),
  
  dashboardSidebar(
    # Asset class selector
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        selectInput("assetClass", 
                    "Select Asset Class:",
                    choices = c("Cryptocurrencies" = "crypto", 
                                "Equities" = "equity",
                                "Commodities" = "commodity",
                                "Forex" = "forex",
                                "IG (CFDs)" = "ig"),
                    selected = "crypto",
                    width = "100%")
    ),
    
    # Data resolution selector (Yahoo Finance sources only — IG stays daily for now)
    conditionalPanel(
      condition = "input.assetClass != 'ig'",
      div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
          selectInput("dataResolution", "Data Resolution:",
                      choices = c("1 Minute (last ~7 days)"    = "1m",
                                  "5 Minutes (last ~60 days)"   = "5m",
                                  "15 Minutes (last ~60 days)"  = "15m",
                                  "30 Minutes (last ~60 days)"  = "30m",
                                  "1 Hour (last ~2 years)"      = "60m",
                                  "Daily (full history)"        = "1d"),
                      selected = "1m",
                      width = "100%"),
          tags$p(HTML(paste0(
                   "Finer resolutions have much shorter available history &mdash; this is a Yahoo Finance ",
                   "limit, not an app limit. If a fetch fails, try a coarser resolution or Daily."
                 )), style = "font-size:10.5px; color:#b2e0db; font-style:italic; margin-top:4px; line-height:1.5;")
      )
    ),
    
    # Asset instance selector
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        conditionalPanel(
          condition = "input.assetClass == 'crypto'",
          selectInput("cryptoAsset", 
                      "Select Cryptocurrency:",
                      choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                  "Ethereum (ETH-USD)" = "ETH-USD",
                                  "Cardano (ADA-USD)" = "ADA-USD"),
                      selected = "BTC-USD",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.assetClass == 'equity'",
          selectInput("equityAsset", 
                      "Select Equity Stock:",
                      choices = c("NVIDIA (NVDA)" = "NVDA",
                                  "Microsoft (MSFT)" = "MSFT",
                                  "Apple (AAPL)" = "AAPL"),
                      selected = "NVDA",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.assetClass == 'commodity'",
          selectInput("commodityAsset", 
                      "Select Commodity:",
                      choices = c("Gold (GC=F)" = "GC=F",
                                  "Crude Oil (CL=F)" = "CL=F",
                                  "Natural Gas (NG=F)" = "NG=F"),
                      selected = "GC=F",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.assetClass == 'forex'",
          selectInput("forexAsset", 
                      "Select Currency Pair:",
                      choices = c("EUR/USD (EURUSD=X)" = "EURUSD=X",
                                  "GBP/USD (GBPUSD=X)" = "GBPUSD=X",
                                  "USD/JPY (JPY=X)"     = "JPY=X"),
                      selected = "EURUSD=X",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.assetClass == 'ig'",
          selectInput("igEpicPreset",
                      "Preset IG Instrument:",
                      choices = c("FTSE 100 (IX.D.FTSE.CFD.IP)"      = "IX.D.FTSE.CFD.IP",
                                  "Wall Street (IX.D.DOW.CFD.IP)"    = "IX.D.DOW.CFD.IP",
                                  "US Tech 100 (IX.D.NASDAQ.CFD.IP)" = "IX.D.NASDAQ.CFD.IP",
                                  "EUR/USD (CS.D.EURUSD.CFD.IP)"     = "CS.D.EURUSD.CFD.IP",
                                  "GBP/USD (CS.D.GBPUSD.CFD.IP)"     = "CS.D.GBPUSD.CFD.IP",
                                  "USD/JPY (CS.D.USDJPY.CFD.IP)"     = "CS.D.USDJPY.CFD.IP",
                                  "Spot Gold (CS.D.CFDGOLD.CFM.IP)"  = "CS.D.CFDGOLD.CFM.IP",
                                  "US Crude Oil (CC.D.CL.UNC.IP)"    = "CC.D.CL.UNC.IP"),
                      selected = "IX.D.FTSE.CFD.IP",
                      width = "100%"),
          textInput("igEpicCustom", "Or enter a custom EPIC:", value = "", placeholder = "e.g. IX.D.FTSE.CFD.IP"),
          tags$p(HTML(paste0(
                   "Custom EPIC overrides the preset if filled in. Preset codes are commonly-cited examples ",
                   "and may not match your account/region exactly &mdash; verify or find EPICs using the ",
                   "market search tool on the <strong>IG Login</strong> tab before relying on them."
                 )), style = "font-size:10.5px; color:#b2e0db; font-style:italic; margin-top:8px; line-height:1.5;")
        )
    ),
    
    sidebarMenu(
      id = "main_menu",
      menuItem("IG Login",             tabName = "ig_login",  icon = icon("key"), selected = TRUE),
      menuItem("Market Overview",      tabName = "overview",  icon = icon("chart-line")),
      menuItem("Price Analysis",       tabName = "price",     icon = icon("chart-simple")),
      menuItem("Technical Indicators", tabName = "technical", icon = icon("chart-bar"))
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
        
        .small-box.bg-teal { 
          background: linear-gradient(135deg, #1abc9c 0%, #16a085 100%) !important; 
        }
        
        .small-box.bg-orange { 
          background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%) !important; 
        }
        
        /* Info boxes styling */
        .info-box {
          background: rgba(255, 255, 255, 0.98) !important;
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 44, 60, 0.15) !important;
          border-left: 4px solid #008A82;
        }
        
        /* Status message styling */
        .data-info {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          color: #155724 !important;
          padding: 15px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #00A39A !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(0, 163, 154, 0.2);
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
        
        /* Logo styling */
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          border-bottom: none !important;
          font-weight: 600;
        }
        
        /* Scrollbar styling */
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
      "))
    ),
    
    tabItems(
      
      # ── IG LOGIN / API CREDENTIALS TAB ────────────────────────────────────────
      tabItem(tabName = "ig_login",
        
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "primary",
            title = NULL,
            div(
              style = paste0(
                "background: linear-gradient(135deg, #002C3C 0%, #005f5a 60%, #00A39A 100%);",
                "border-radius: 10px; padding: 26px 32px; color: #ffffff;"
              ),
              fluidRow(
                column(9,
                  tags$h2(HTML(paste0(icon("key"), " IG Trading API — Login & Credentials")),
                          style = "font-size:24px; font-weight:700; margin:0 0 8px 0; color:#ffffff;"),
                  tags$p(HTML(paste0(
                    "Authenticate against IG's REST API to pull live CFD market data (indices, FX, commodities) ",
                    "directly into this dashboard alongside the existing Yahoo Finance-sourced assets. Once ",
                    "logged in here, select <strong>IG (CFDs)</strong> as the Asset Class in the sidebar to feed ",
                    "IG-sourced OHLC data into every tab in the app — technical indicators, hedging, composite ",
                    "analysis, all of it."
                  )), style = "font-size:13.5px; line-height:1.7; color:#e8f8f6; margin:0;")
                ),
                column(3,
                  div(style = "text-align:center; padding-top:6px;",
                      icon("shield-halved", style = "font-size:40px; color:#7fffd4;"),
                      tags$p("Session held in memory only", style = "font-size:11px; color:#b2e0db; margin-top:8px;")
                  )
                )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            width = 12, solidHeader = FALSE, status = "warning",
            div(style = "display:flex; align-items:flex-start; gap:14px;",
              icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
              div(
                tags$strong("Before you start:", style = "color:#7d4a00; font-size:14px;"),
                tags$p(HTML(paste0(
                  "You need an IG <strong>live</strong> account to generate an API key (a standalone demo account ",
                  "cannot create one) &mdash; go to <em>My Account &gt; Settings &gt; API Keys</em> on IG's web ",
                  "platform, generate a key, then switch the account selector to Demo and generate a second key ",
                  "for safe testing. This tab talks to <code>demo-api.ig.com</code> or <code>api.ig.com</code> ",
                  "depending on the Environment selected below."
                )), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "IG API Credentials", status = "primary", solidHeader = TRUE, width = 5,
            radioButtons("igEnv", "Environment:",
                         choices = c("Demo" = "DEMO", "Live" = "LIVE"),
                         selected = "DEMO", inline = TRUE),
            passwordInput("igApiKey", "API Key:", value = Sys.getenv("IG_SERVICE_API_KEY"), width = "100%"),
            textInput("igUsername", "Username:", value = Sys.getenv("IG_SERVICE_USERNAME"), width = "100%"),
            passwordInput("igPassword", "Password:", value = Sys.getenv("IG_SERVICE_PASSWORD"), width = "100%"),
            textInput("igAccNumber", "Account Number (optional):",
                      value = Sys.getenv("IG_SERVICE_ACC_NUMBER"), width = "100%"),
            div(style = "display:flex; gap:10px; margin-top:6px;",
              actionButton("igLoginBtn",  "Login",  icon = icon("right-to-bracket"), class = "btn-primary", width = "50%"),
              actionButton("igLogoutBtn", "Logout", icon = icon("right-from-bracket"), width = "50%")
            ),
            tags$p(HTML(paste0(
              "If the <code>IG_SERVICE_USERNAME</code>, <code>IG_SERVICE_PASSWORD</code>, ",
              "<code>IG_SERVICE_API_KEY</code>, and <code>IG_SERVICE_ACC_NUMBER</code> environment variables ",
              "are set on the server (e.g. via <code>.Renviron</code> on shinyapps.io), this form pre-fills from ",
              "them automatically. Credentials are held only in this session's server-side memory for the ",
              "duration of your session and are never written to disk or logged."
            )), style = "font-size:11px; color:#888; font-style:italic; margin-top:12px; line-height:1.5;")
          ),
          box(
            title = "Session Status", status = "info", solidHeader = TRUE, width = 7,
            uiOutput("igStatusUI"),
            tags$hr(),
            actionButton("igTestConnection", "Test Connection (Fetch Accounts)",
                         icon = icon("plug"), class = "btn-primary"),
            br(), br(),
            withSpinner(DT::dataTableOutput("igAccountsTable"))
          )
        ),
        
        fluidRow(
          box(
            title = "Find an EPIC (Market Search)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(8, textInput("igSearchTerm", "Search term:", value = "",
                                   placeholder = "e.g. 'FTSE', 'EUR/USD', 'Gold'", width = "100%")),
              column(4, div(style = "padding-top:24px;",
                            actionButton("igSearchBtn", "Search Markets", icon = icon("magnifying-glass"),
                                         class = "btn-primary", width = "100%")))
            ),
            withSpinner(DT::dataTableOutput("igSearchResultsTable")),
            tags$p(paste0(
              "Use this to find the correct EPIC code for any instrument available on your account, then paste ",
              "it into the 'Or enter a custom EPIC' field under the IG (CFDs) asset selector in the sidebar."
            ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
          )
        ),
        
        fluidRow(
          box(
            title = "How the Authentication Flow Works", status = "info", solidHeader = TRUE, width = 12,
            fluidRow(
              column(3,
                div(style = "text-align:center; padding:12px;",
                    tags$div("1", style = "background:#008A82; color:#fff; border-radius:50%; width:32px; height:32px; line-height:32px; margin:0 auto 8px auto; font-weight:700;"),
                    tags$strong("POST /session", style = "display:block; color:#002C3C; font-size:13px;"),
                    tags$p("API key + username + password sent to the demo or live gateway.", style = "font-size:11.5px; color:#666; margin-top:4px;")
                )
              ),
              column(3,
                div(style = "text-align:center; padding:12px;",
                    tags$div("2", style = "background:#008A82; color:#fff; border-radius:50%; width:32px; height:32px; line-height:32px; margin:0 auto 8px auto; font-weight:700;"),
                    tags$strong("CST + X-SECURITY-TOKEN", style = "display:block; color:#002C3C; font-size:13px;"),
                    tags$p("Returned in response headers and identify the client and current account.", style = "font-size:11.5px; color:#666; margin-top:4px;")
                )
              ),
              column(3,
                div(style = "text-align:center; padding:12px;",
                    tags$div("3", style = "background:#008A82; color:#fff; border-radius:50%; width:32px; height:32px; line-height:32px; margin:0 auto 8px auto; font-weight:700;"),
                    tags$strong("Tokens on every request", style = "display:block; color:#002C3C; font-size:13px;"),
                    tags$p("Passed as headers on subsequent calls, alongside X-IG-API-KEY.", style = "font-size:11.5px; color:#666; margin-top:4px;")
                )
              ),
              column(3,
                div(style = "text-align:center; padding:12px;",
                    tags$div("4", style = "background:#008A82; color:#fff; border-radius:50%; width:32px; height:32px; line-height:32px; margin:0 auto 8px auto; font-weight:700;"),
                    tags$strong("Auto-extending session", style = "display:block; color:#002C3C; font-size:13px;"),
                    tags$p("Tokens stay valid while in active use; re-login if a call is rejected.", style = "font-size:11.5px; color:#666; margin-top:4px;")
                )
              )
            ),
            tags$hr(),
            tags$p(HTML(paste0(
              "This app authenticates via the <strong>igfetchr</strong> R package (CRAN), which implements this ",
              "exact CST / X-SECURITY-TOKEN flow against IG's REST gateway. Default rate limits: <strong>60</strong> ",
              "non-trading requests/minute per app, <strong>30</strong> non-trading requests/minute per account, ",
              "and <strong>10,000</strong> historical price datapoints/week &mdash; keep this in mind if you wire up ",
              "auto-refresh timers against IG data."
            )), style = "font-size:12px; color:#666; line-height:1.6; margin:0;")
          )
        )
        
      ), # end tabItem ig_login
# end tabItem about
# end tabItem derivatives
# end tabItem extra_ta
# end tabItem psych_macro
      
      # ── MARKET OVERVIEW TAB ──────────────────────────────────────────────────
      # Market Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Data Information & Chart Controls",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           div(class = "data-info",
                               uiOutput("dataSourceInfo"))
                    ),
                    column(3,
                           checkboxGroupInput("overviewComponents", "Show Components:",
                                              choices = c("Close Price" = "close",
                                                          "Volume" = "volume",
                                                          "Moving Averages" = "ma"),
                                              selected = c("close", "volume"),
                                              inline = FALSE)
                    ),
                    column(3,
                           numericInput("overviewMA", "Moving Average Period:",
                                        value = 20, min = 5, max = 200, step = 5)
                    ),
                    column(3,
                           actionButton("refreshData", "Refresh Data", 
                                        class = "btn-primary", width = "100%")
                    )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("currentPrice", width = 3),
                valueBoxOutput("dailyChange", width = 3),
                valueBoxOutput("volumeInfo", width = 3),
                valueBoxOutput("dataRange", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Price Chart with Volume", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(plotlyOutput("overviewChart", height = "500px")),
                  tags$p(paste0(
                    "Combined price and volume chart for the selected asset. The main line shows the daily ",
                    "closing price over the full loaded history. Volume bars at the bottom indicate how many ",
                    "units were traded each session; high-volume sessions accompanied by large price moves ",
                    "are generally considered more significant signals than low-volume moves. ",
                    "The optional moving average overlay helps identify whether the asset is in an uptrend, ",
                    "downtrend, or sideways range."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Market Statistics", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  withSpinner(DT::dataTableOutput("marketStats")),
                  tags$p(paste0(
                    "Key price level statistics across the full loaded data range, including average, ",
                    "minimum, and maximum closing prices. These anchor values provide context for where ",
                    "the current price sits relative to the asset's historical range."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Price Movement Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  withSpinner(DT::dataTableOutput("priceMovementStats")),
                  tags$p(paste0(
                    "Breakdown of daily price behaviour patterns: average daily range, frequency of gap ",
                    "opens, and session-level directional statistics. Useful for understanding the typical ",
                    "intraday volatility character of the asset and identifying any systematic patterns."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Volume Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  withSpinner(DT::dataTableOutput("volumeStats")),
                  tags$p(paste0(
                    "Summary of trading volume across the data range. Mean, median, and standard deviation ",
                    "of daily volume reveal whether liquidity is consistent or episodic. ",
                    "Note: volume data is not available for commodity futures or certain crypto feeds ",
                    "and will display as N/A for those instruments."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Returns Distribution", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("returnsDistribution", height = "300px")),
                  tags$p(paste0(
                    "Histogram of all daily returns over the full loaded history. A symmetrical bell shape ",
                    "centred near zero is consistent with a random walk. A distribution with fat tails ",
                    "indicates more frequent extreme moves than a normal distribution would predict, ",
                    "which is characteristic of crypto and commodity markets. Skew to one side reveals ",
                    "an asymmetric return profile."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Price Distribution", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("priceDistribution", height = "300px")),
                  tags$p(paste0(
                    "Histogram of all closing price levels over the full loaded history. Price distributions ",
                    "are typically not bell-shaped for financial assets; they often show peaks at key ",
                    "support and resistance levels where the asset spent extended periods of time. ",
                    "Multiple peaks indicate a ranging market; a single peak suggests a trending period."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              )
      ),
      
      # Price Analysis Tab
      tabItem(tabName = "price",
              fluidRow(
                box(
                  title = "Price Analysis Controls", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  fluidRow(
                    column(3,
                           dateRangeInput("priceRange", "Analysis Period:",
                                          start = Sys.Date() - months(6),
                                          end = Sys.Date(),
                                          format = "yyyy-mm-dd")
                    ),
                    column(3,
                           checkboxGroupInput("priceComponents", "Show Components:",
                                              choices = c("Close" = "close",
                                                          "High/Low" = "highlow",
                                                          "Open" = "open"),
                                              selected = c("close", "highlow"))
                    ),
                    column(3,
                           numericInput("priceMAPeriod", "MA Periods:",
                                        value = 20, min = 5, max = 200),
                           checkboxInput("showBollingerBands", "Bollinger Bands", FALSE)
                    ),
                    column(3,
                           verbatimTextOutput("priceStats")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Detailed Price Chart", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(plotlyOutput("detailedPriceChart", height = "500px")),
                  tags$p(paste0(
                    "Price series for the selected asset and date range. Toggle Close, High/Low, and Open ",
                    "in the controls above to show or hide each component. The moving average line ",
                    "smooths short-term fluctuations to reveal the underlying trend direction. ",
                    "Bollinger Bands, when enabled, form an upper and lower envelope two standard deviations ",
                    "either side of the moving average: price touching the upper band signals potential overbought ",
                    "conditions, while touching the lower band signals potential oversold conditions."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              # OHLC chart full-width to prevent overlap
              fluidRow(
                box(
                  title = "OHLC Candlestick Chart", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(plotlyOutput("ohlcChart", height = "450px")),
                  tags$p(paste0(
                    "Each candlestick represents one trading session. A green candle means the price closed ",
                    "higher than it opened (bullish session); a red candle means the price closed lower than ",
                    "it opened (bearish session). The body shows the Open-to-Close range; the thin wicks above ",
                    "and below extend to the session High and Low. Wide bodies indicate strong directional ",
                    "conviction; long wicks suggest price rejection at the extremes."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              # ── Candlestick Pattern Detection ──────────────────────────────────
              fluidRow(
                box(
                  title = "Candlestick Pattern Detection", status = "primary", solidHeader = TRUE, width = 4,
                  tags$p(HTML(paste0(
                    "Scans the candlestick data for classic Japanese candlestick patterns within the time window ",
                    "you select below. Detected patterns are marked directly on the chart and listed in the ",
                    "results table, each tagged Bullish, Bearish, or Neutral based on the pattern's textbook ",
                    "interpretation."
                  )), style = "font-size:12px; color:#444; line-height:1.6;"),
                  sliderInput("patternWindow", "Time Window (bar range):",
                              min = 1, max = 100, value = c(1, 100), step = 1, width = "100%"),
                  uiOutput("patternWindowDates"),
                  tags$hr(),
                  div(style = "display:flex; gap:8px; margin-bottom:10px;",
                      actionButton("patternSelectAll",  "Select All",  class = "btn-default btn-sm"),
                      actionButton("patternSelectNone", "Select None", class = "btn-default btn-sm")
                  ),
                  checkboxGroupInput("patternsToDetect", "Patterns to Detect:",
                                     choices = c("Doji"                  = "doji",
                                                 "Hammer"                = "hammer",
                                                 "Inverted Hammer"       = "inverted_hammer",
                                                 "Hanging Man"           = "hanging_man",
                                                 "Shooting Star"         = "shooting_star",
                                                 "Bullish Engulfing"     = "bullish_engulfing",
                                                 "Bearish Engulfing"     = "bearish_engulfing",
                                                 "Morning Star"          = "morning_star",
                                                 "Evening Star"          = "evening_star",
                                                 "Piercing Line"         = "piercing_line",
                                                 "Dark Cloud Cover"      = "dark_cloud_cover",
                                                 "Three White Soldiers"  = "three_white_soldiers",
                                                 "Three Black Crows"     = "three_black_crows",
                                                 "Bullish Harami"        = "bullish_harami",
                                                 "Bearish Harami"        = "bearish_harami",
                                                 "Spinning Top"          = "spinning_top",
                                                 "Marubozu"              = "marubozu",
                                                 "Tweezer Top"           = "tweezer_top",
                                                 "Tweezer Bottom"        = "tweezer_bottom",
                                                 "Abandoned Baby"        = "abandoned_baby"),
                                     selected = c("doji", "hammer", "inverted_hammer", "hanging_man", "shooting_star",
                                                  "bullish_engulfing", "bearish_engulfing",
                                                  "morning_star", "evening_star")),
                  numericInput("patternTrendLookback", "Trend Context Lookback (bars):",
                               value = 5, min = 2, max = 30, step = 1),
                  actionButton("detectPatterns", "Detect Patterns", icon = icon("magnifying-glass-chart"),
                               class = "btn-primary", width = "100%")
                ),
                box(
                  title = "Annotated Candlestick Chart", status = "primary", solidHeader = TRUE, width = 8,
                  withSpinner(plotlyOutput("patternChart", height = "500px")),
                  tags$p(paste0(
                    "Green triangles (pointing up) mark bullish signals; red triangles (pointing down) mark ",
                    "bearish signals; orange diamonds mark neutral/indecision signals. Hover over any marker to ",
                    "see which pattern was detected there."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Detected Patterns", status = "info", solidHeader = TRUE, width = 12,
                  withSpinner(DT::dataTableOutput("patternResultsTable")),
                  tags$p(paste0(
                    "Every match found in the selected window, most recent first. 'Signal' reflects the pattern's ",
                    "classic textbook interpretation, not a guarantee of future price direction — always confirm ",
                    "with other analysis before acting on any single pattern."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              # ── End Candlestick Pattern Detection ──────────────────────────────
              
              # Stats table full-width below the chart
              fluidRow(
                box(
                  title = "OHLC Statistics", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(DT::dataTableOutput("ohlcStats")),
                  tags$p(paste0(
                    "Summary statistics computed across all sessions in the selected period. ",
                    "Avg Range (High minus Low) is the typical daily price swing, a direct measure of intraday ",
                    "volatility. Max Range identifies the most extreme single-session swing. ",
                    "Bullish Days and Bearish Days express the proportion of sessions where price closed ",
                    "above or below its open, indicating the directional bias of the period."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Returns Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("returnsTimeSeries", height = "320px")),
                  tags$p(paste0(
                    "Daily log returns expressed as a percentage. Each bar or spike represents a single ",
                    "session's percentage gain or loss relative to the prior close. Spikes far from zero ",
                    "identify extreme event days. The distribution of these returns around the zero line ",
                    "reveals whether the asset has a positive or negative return bias over the period."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Cumulative Returns", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("cumulativeReturns", height = "320px")),
                  tags$p(paste0(
                    "The compounded growth of a hypothetical investment in the selected asset over the period, ",
                    "expressed as a cumulative percentage. A rising line indicates the investment has grown in ",
                    "value; a declining line indicates loss of capital. Steep drops reveal drawdown periods. ",
                    "The final value on the right-hand side is the total return over the entire date range shown."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              )
      ),
      
      # Technical Indicators Tab
      tabItem(tabName = "technical",
              fluidRow(
                box(
                  title = "Technical Analysis Settings", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 3,
                  
                  checkboxGroupInput("technicalIndicators", "Select Indicators:",
                                     choices = c("Simple Moving Average" = "sma",
                                                 "Exponential Moving Average" = "ema",
                                                 "RSI" = "rsi",
                                                 "MACD" = "macd",
                                                 "Bollinger Bands" = "bb",
                                                 "Stochastic" = "stoch"),
                                     selected = c("sma", "rsi")),
                  
                  numericInput("smaLength", "SMA Length:", value = 20, min = 5, max = 200),
                  numericInput("emaLength", "EMA Length:", value = 20, min = 5, max = 200),
                  numericInput("rsiLength", "RSI Length:", value = 14, min = 5, max = 50),
                  numericInput("bbLength", "BB Length:", value = 20, min = 5, max = 100),
                  numericInput("bbSd", "BB Std Dev:", value = 2, min = 1, max = 3, step = 0.1),
                  
                  br(),
                  h5("Current Signals:"),
                  verbatimTextOutput("technicalSignals")
                ),
                
                box(
                  title = "Technical Chart", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 9,
                  withSpinner(plotlyOutput("technicalChart", height = "600px")),
                  tags$p(paste0(
                    "Price chart with the selected technical indicator overlays. SMA and EMA lines track ",
                    "the trend: when price is above the line the asset is in an uptrend relative to that ",
                    "period; below signals a downtrend. EMA reacts faster than SMA to recent price changes. ",
                    "Bollinger Bands form a volatility envelope; a squeeze (bands narrowing) often precedes ",
                    "a significant price move. Use the Current Signals panel on the left for a plain-language ",
                    "interpretation of the active indicators."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              conditionalPanel(
                condition = "input.technicalIndicators.includes('rsi')",
                fluidRow(
                  box(
                    title = "RSI Oscillator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    withSpinner(plotlyOutput("rsiChart", height = "300px")),
                    tags$p(paste0(
                      "The Relative Strength Index oscillates between 0 and 100. Readings above 70 (red dashed line) ",
                      "indicate the asset may be overbought and due for a pullback. Readings below 30 (green dashed line) ",
                      "suggest oversold conditions and a potential bounce. The RSI crossing back through these thresholds ",
                      "is often used as an entry or exit signal. In strong trending markets the RSI can remain in ",
                      "overbought or oversold territory for extended periods."
                    ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                  )
                )
              ),
              
              conditionalPanel(
                condition = "input.technicalIndicators.includes('macd')",
                fluidRow(
                  box(
                    title = "MACD Indicator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    withSpinner(plotlyOutput("macdChart", height = "300px")),
                    tags$p(paste0(
                      "The MACD line (blue) is the difference between the 12-period and 26-period EMAs. ",
                      "The Signal line (red) is a 9-period EMA of the MACD line. When MACD crosses above ",
                      "the Signal line it is considered a bullish signal; crossing below is bearish. ",
                      "The histogram bars show the gap between the two lines: growing green bars indicate ",
                      "strengthening upward momentum; growing red bars indicate strengthening downward momentum."
                    ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                  )
                )
              ),
              
              conditionalPanel(
                condition = "input.technicalIndicators.includes('stoch')",
                fluidRow(
                  box(
                    title = "Stochastic Oscillator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    withSpinner(plotlyOutput("stochChart", height = "300px")),
                    tags$p(paste0(
                      "The Stochastic Oscillator compares the closing price to the High-Low range over the ",
                      "lookback period. The %K line (blue) is the raw reading; the %D line (red) is a ",
                      "smoothed signal line. Readings above 80 (red dashed line) indicate overbought conditions; ",
                      "below 20 (green dashed line) indicate oversold. A %K crossover above %D near the 20 level ",
                      "is a classic buy signal; a crossover below %D near 80 is a sell signal."
                    ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                  )
                )
              )
      )
      
    ) # end tabItems
  ) # end dashboardBody
) # end dashboardPage

# Define Server
server <- function(input, output, session) {
  
  # Reactive values
  values <- reactiveValues(
    asset_data = NULL,
    data_loaded = FALSE,
    last_update = NULL,
    ig_auth = NULL,        # auth list returned by igfetchr::ig_auth() — cst, security, base_url, api_key, acc_number
    ig_login_time = NULL,
    pattern_matches = NULL # results of the candlestick pattern scan (Price Analysis tab)
  )
  
  # Function to fetch data from Yahoo Finance
  # Fixed for shinyapps.io: URL-encodes special chars in tickers (= ^ for futures/indices),
  # uses browser User-Agent to avoid bot-detection for crypto, safely handles
  # missing Volume/Adjusted columns common in futures and crypto feeds.
  fetch_asset_data <- function(symbol, months_back = 24) {
    
    # Set network timeout and browser-like User-Agent before any Yahoo request
    old_timeout <- getOption("timeout")
    old_ua     <- getOption("HTTPUserAgent")
    on.exit({
      options(timeout = old_timeout)
      options(HTTPUserAgent = old_ua)
    }, add = TRUE)
    options(timeout = 60)
    options(HTTPUserAgent = paste0(
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ",
      "AppleWebKit/537.36 (KHTML, like Gecko) ",
      "Chrome/120.0.0.0 Safari/537.36"
    ))
    
    tryCatch({
      start_date <- Sys.Date() - months(months_back)
      end_date   <- Sys.Date()
      
      # quantmod's Yahoo URL builder breaks on literal '=' (futures e.g. GC=F)
      # and '^' (indices e.g. ^GSPC). Use the encoded form as the env var name
      # but pass the raw symbol to getSymbols.
      safe_name <- gsub("[^A-Za-z0-9]", "_", symbol)   # used only as env key
      
      env <- new.env()
      withCallingHandlers(
        getSymbols(
          symbol,
          src          = "yahoo",
          from         = start_date,
          to           = end_date,
          auto.assign  = TRUE,
          env          = env,
          warnings     = FALSE
        ),
        warning = function(w) invokeRestart("muffleWarning")
      )
      
      # getSymbols stores the result under the sanitised ticker name
      stored_name <- ls(env)[1]
      if (length(stored_name) == 0 || is.null(env[[stored_name]])) {
        showNotification(paste("No data returned for", symbol), type = "warning")
        return(NULL)
      }
      raw <- env[[stored_name]]
      
      # ── Safe column extraction (futures lack Adjusted; crypto often lacks Volume) ──
      safe_col <- function(fn, xts_obj) {
        tryCatch({
          v <- as.numeric(fn(xts_obj))
          if (all(is.na(v))) NA_real_ else v
        }, error = function(e) NA_real_)
      }
      
      close_prices <- safe_col(Cl, raw)
      vol_raw      <- safe_col(Vo, raw)
      adj_raw      <- safe_col(Ad, raw)
      
      # Futures have no meaningful Adjusted close — fall back to Close
      if (length(adj_raw) == 1 && is.na(adj_raw)) adj_raw <- close_prices
      
      # Replace NA / NaN / negative volume with 0 (futures, crypto weekends, etc.)
      if (length(vol_raw) == 1 && is.na(vol_raw)) {
        vol_raw <- rep(0, nrow(raw))
      } else {
        vol_raw[is.na(vol_raw) | is.nan(vol_raw) | vol_raw < 0] <- 0
      }
      
      df <- data.frame(
        Date     = index(raw),
        Open     = safe_col(Op, raw),
        High     = safe_col(Hi, raw),
        Low      = safe_col(Lo, raw),
        Close    = close_prices,
        Volume   = vol_raw,
        Adjusted = adj_raw
      )
      
      # Remove rows where Close is NA (can happen at roll dates for futures)
      df <- df[!is.na(df$Close), ]
      
      if (nrow(df) == 0) {
        showNotification(paste("Empty dataset returned for", symbol), type = "warning")
        return(NULL)
      }
      
      # Calculate returns
      df <- df %>%
        arrange(Date) %>%
        mutate(
          returns     = c(NA, diff(log(Close))),
          returns_pct = c(NA, diff(Close) / head(Close, -1) * 100)
        )
      
      return(df)
      
    }, error = function(e) {
      msg <- conditionMessage(e)
      showNotification(
        paste0("Error fetching ", symbol, ": ", msg,
               ". Try refreshing or switching assets."),
        type = "error", duration = 8
      )
      return(NULL)
    })
  }
  
  # Function to fetch INTRADAY data directly from Yahoo Finance's public chart API.
  # Bypasses quantmod (whose intraday support varies by installed version) and calls
  # https://query1.finance.yahoo.com/v8/finance/chart/{symbol} directly, matching what
  # IG's own resolution-based pricing offers, subject to Yahoo's own lookback limits per
  # interval (finer resolution = much shorter available history):
  #   1m -> ~7 days, 5m/15m/30m -> ~60 days, 60m -> ~2 years.
  # Produces the exact same schema as fetch_asset_data() so it slots into every existing
  # tab unmodified. Date is POSIXct (not Date) here since bars are sub-daily.
  fetch_asset_data_intraday <- function(symbol, interval = "1m") {
    tryCatch({
      range_map <- c("1m" = "7d", "5m" = "60d", "15m" = "60d", "30m" = "60d", "60m" = "730d")
      rng <- if (!is.na(range_map[interval])) range_map[[interval]] else "60d"
      
      url <- paste0(
        "https://query1.finance.yahoo.com/v8/finance/chart/", utils::URLencode(symbol, reserved = TRUE),
        "?range=", rng, "&interval=", interval, "&includePrePost=false"
      )
      
      resp <- httr::GET(url, httr::add_headers(`User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"))
      
      if (httr::status_code(resp) != 200) {
        showNotification(
          paste0("Yahoo intraday request failed (HTTP ", httr::status_code(resp), ") for ", symbol,
                 ". Try a coarser resolution."),
          type = "error", duration = 8
        )
        return(NULL)
      }
      
      parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
      result <- parsed$chart$result
      
      if (is.null(result) || length(result) == 0) {
        err_msg <- parsed$chart$error$description
        showNotification(
          paste0("No intraday data for ", symbol,
                 if (!is.null(err_msg)) paste0(": ", err_msg) else ". Market may be closed or symbol unsupported."),
          type = "warning", duration = 8
        )
        return(NULL)
      }
      
      r1 <- result[[1]]
      ts <- unlist(r1$timestamp)
      quote <- r1$indicators$quote[[1]]
      
      if (is.null(ts) || length(ts) == 0) {
        showNotification(paste0("Empty intraday series for ", symbol, " at ", interval, " resolution."),
                          type = "warning", duration = 6)
        return(NULL)
      }
      
      # NULL-safe unlist: preserves alignment with timestamps (missing bars -> NA, not dropped)
      to_num_vec <- function(x, na_fill = NA_real_) {
        as.numeric(unlist(lapply(x, function(v) if (is.null(v)) na_fill else v)))
      }
      
      df <- data.frame(
        Date   = as.POSIXct(ts, origin = "1970-01-01", tz = "UTC"),
        Open   = to_num_vec(quote$open),
        High   = to_num_vec(quote$high),
        Low    = to_num_vec(quote$low),
        Close  = to_num_vec(quote$close),
        Volume = to_num_vec(quote$volume, na_fill = 0)
      )
      
      df$Adjusted <- df$Close
      df <- df[!is.na(df$Close) & !is.na(df$Date), ]
      
      if (nrow(df) < 2) {
        showNotification(
          paste0("Not enough intraday data points for ", symbol,
                 " at this resolution — try a coarser one."),
          type = "warning", duration = 6
        )
        return(NULL)
      }
      
      df <- df %>%
        arrange(Date) %>%
        mutate(
          returns     = c(NA, diff(log(Close))),
          returns_pct = c(NA, diff(Close) / head(Close, -1) * 100)
        )
      
      return(df)
      
    }, error = function(e) {
      showNotification(
        paste0("Intraday fetch error for ", symbol, ": ", conditionMessage(e)),
        type = "error", duration = 8
      )
      return(NULL)
    })
  }
  
  # Dispatcher: routes to the existing daily fetcher (quantmod, unchanged/proven) or the
  # new intraday fetcher, based on the sidebar's Data Resolution selector.
  fetch_yahoo_data <- function(symbol, interval = "1d") {
    if (is.null(interval) || interval == "1d") {
      fetch_asset_data(symbol)
    } else {
      fetch_asset_data_intraday(symbol, interval)
    }
  }
  
  # Produces the exact same Date/Open/High/Low/Close/Volume/Adjusted/returns/returns_pct
  # schema as fetch_asset_data(), so IG-sourced assets work transparently across every
  # existing tab (technical indicators, hedging, composite analysis, etc.).
  # Column names are detected defensively rather than hardcoded, since igfetchr's tibble
  # output naming can evolve between package versions — verify against a live pull.
  fetch_ig_data <- function(epic, auth, months_back = 24) {
    tryCatch({
      from_date <- format(Sys.Date() - months(months_back), "%Y-%m-%d")
      to_date   <- format(Sys.Date(), "%Y-%m-%d")
      
      raw <- igfetchr::ig_get_historical(
        epic       = epic,
        from       = from_date,
        to         = to_date,
        resolution = "D",
        page_size  = 20,
        auth       = auth
      )
      
      if (is.null(raw) || nrow(raw) == 0) {
        showNotification(paste("No IG data returned for", epic), type = "warning")
        return(NULL)
      }
      
      raw <- as.data.frame(raw)
      nm  <- names(raw)
      
      find_col <- function(patterns) {
        for (p in patterns) {
          hit <- grep(p, nm, ignore.case = TRUE, value = TRUE)
          if (length(hit) > 0) return(hit[1])
        }
        NA_character_
      }
      
      col_time  <- find_col(c("snapshotTime", "snapshot_time", "^date$", "^time$"))
      col_o_bid <- find_col(c("open.*bid", "open_bid"))
      col_o_ask <- find_col(c("open.*ask", "open_ask"))
      col_o     <- find_col(c("^open$", "^openPrice$"))
      col_h_bid <- find_col(c("high.*bid", "high_bid"))
      col_h_ask <- find_col(c("high.*ask", "high_ask"))
      col_h     <- find_col(c("^high$", "^highPrice$"))
      col_l_bid <- find_col(c("low.*bid", "low_bid"))
      col_l_ask <- find_col(c("low.*ask", "low_ask"))
      col_l     <- find_col(c("^low$", "^lowPrice$"))
      col_c_bid <- find_col(c("close.*bid", "close_bid"))
      col_c_ask <- find_col(c("close.*ask", "close_ask"))
      col_c     <- find_col(c("^close$", "^closePrice$"))
      col_vol   <- find_col(c("lastTradedVolume", "^volume$"))
      
      # Mid-price of bid/ask where both exist (CFDs quote two-sided); falls back to
      # whichever single price column is available.
      mid_or_single <- function(bid_col, ask_col, single_col) {
        if (!is.na(bid_col) && !is.na(ask_col)) {
          (as.numeric(raw[[bid_col]]) + as.numeric(raw[[ask_col]])) / 2
        } else if (!is.na(single_col)) {
          as.numeric(raw[[single_col]])
        } else if (!is.na(bid_col)) {
          as.numeric(raw[[bid_col]])
        } else if (!is.na(ask_col)) {
          as.numeric(raw[[ask_col]])
        } else {
          rep(NA_real_, nrow(raw))
        }
      }
      
      dates <- if (!is.na(col_time)) {
        suppressWarnings(as.Date(raw[[col_time]]))
      } else {
        showNotification("Could not detect a date/time column in IG response — using row order.",
                          type = "warning", duration = 6)
        Sys.Date() - rev(seq_len(nrow(raw))) + 1
      }
      
      df <- data.frame(
        Date  = dates,
        Open  = mid_or_single(col_o_bid, col_o_ask, col_o),
        High  = mid_or_single(col_h_bid, col_h_ask, col_h),
        Low   = mid_or_single(col_l_bid, col_l_ask, col_l),
        Close = mid_or_single(col_c_bid, col_c_ask, col_c)
      )
      
      df$Volume <- if (!is.na(col_vol)) as.numeric(raw[[col_vol]]) else 0
      df$Volume[is.na(df$Volume) | df$Volume < 0] <- 0
      df$Adjusted <- df$Close   # no dividend-adjustment concept for CFDs
      
      df <- df[!is.na(df$Close) & !is.na(df$Date), ]
      if (nrow(df) == 0) {
        showNotification(paste("Empty/unparseable IG dataset for", epic), type = "warning")
        return(NULL)
      }
      
      df <- df %>%
        arrange(Date) %>%
        mutate(
          returns     = c(NA, diff(log(Close))),
          returns_pct = c(NA, diff(Close) / head(Close, -1) * 100)
        )
      
      return(df)
      
    }, error = function(e) {
      showNotification(
        paste0("IG data error for ", epic, ": ", conditionMessage(e)),
        type = "error", duration = 8
      )
      return(NULL)
    })
  }
  
  # Get current asset symbol / EPIC
  current_asset <- reactive({
    if (input$assetClass == "crypto") {
      return(input$cryptoAsset)
    } else if (input$assetClass == "equity") {
      return(input$equityAsset)
    } else if (input$assetClass == "commodity") {
      return(input$commodityAsset)
    } else if (input$assetClass == "forex") {
      return(input$forexAsset)
    } else if (input$assetClass == "ig") {
      custom <- input$igEpicCustom
      if (!is.null(custom) && nzchar(trimws(custom))) {
        return(trimws(custom))
      }
      return(input$igEpicPreset)
    }
  })
  
  # Load data when asset selection, resolution, or refresh changes.
  # Uses list() not c() to ensure all reactives trigger reliably on shinyapps.io.
  # Retries once on failure to handle transient Yahoo Finance rate-limits.
  # Branches to the IG fetcher (always daily) or the resolution-aware Yahoo dispatcher.
  observeEvent(list(current_asset(), input$refreshData, input$dataResolution), {
    symbol <- current_asset()
    req(symbol)
    
    if (input$assetClass == "ig") {
      if (is.null(values$ig_auth)) {
        showNotification(
          "Please log in on the 'IG Login' tab before selecting an IG (CFD) instrument.",
          type = "warning", duration = 6
        )
        values$data_loaded <- FALSE
        return(invisible(NULL))
      }
      showNotification("Fetching data from IG...", type = "message", duration = 2)
      data <- fetch_ig_data(symbol, auth = values$ig_auth)
    } else {
      resolution <- if (is.null(input$dataResolution)) "1d" else input$dataResolution
      showNotification(
        paste0("Fetching ", if (resolution == "1d") "daily" else paste0(resolution, "-resolution"), " data..."),
        type = "message", duration = 2
      )
      data <- fetch_yahoo_data(symbol, resolution)
      
      # One automatic retry after a short pause (handles transient Yahoo 429s)
      if (is.null(data)) {
        Sys.sleep(2)
        data <- fetch_yahoo_data(symbol, resolution)
      }
    }
    
    if (!is.null(data) && nrow(data) > 0) {
      values$asset_data  <- data
      values$data_loaded <- TRUE
      values$last_update <- Sys.time()
      showNotification(
        paste("Loaded", nrow(data), "records for", symbol),
        type = "message", duration = 3
      )
    } else {
      values$data_loaded <- FALSE
      showNotification(
        paste0("Failed to load data for ", symbol,
               if (input$assetClass == "ig") ". Check your IG login and EPIC code."
               else ". Try a coarser Data Resolution, or Yahoo Finance may be temporarily unavailable — please try Refresh."),
        type = "error", duration = 8
      )
    }
  }, ignoreNULL = FALSE)
  
  # ══════════════════════════════════════════════════════════════════════════
  # CANDLESTICK PATTERN DETECTION (Price Analysis tab)
  # ══════════════════════════════════════════════════════════════════════════
  
  # Detects the 20 classic Japanese candlestick patterns in an OHLC data.frame.
  # Thresholds are standard, commonly-cited rule-of-thumb definitions (body as a
  # % of the session range, shadow-to-body ratios, etc.) rather than a specific
  # vendor's proprietary implementation — treat matches as a starting point for
  # further analysis, not a black-box signal.
  #   df       : data.frame with Date, Open, High, Low, Close (row order = time order)
  #   patterns : character vector of pattern keys to check (see checkboxGroupInput choices)
  #   trend_lookback : bars looked back to classify the prior trend as up/down, used to
  #                    distinguish e.g. Hammer (after a downtrend) from Hanging Man (after an uptrend)
  # Returns a data.frame: BarIndex (row number within df), Date, Pattern, Signal, Note
  detect_candlestick_patterns <- function(df, patterns, trend_lookback = 5) {
    n <- nrow(df)
    if (n < 3 || length(patterns) == 0) return(data.frame())
    
    Open  <- df$Open;  High <- df$High;  Low <- df$Low;  Close <- df$Close
    body   <- abs(Close - Open)
    rng    <- High - Low
    rng_safe <- ifelse(rng == 0 | is.na(rng), NA, rng)
    upper_shadow <- High - pmax(Open, Close)
    lower_shadow <- pmin(Open, Close) - Low
    is_bull <- Close > Open
    is_bear <- Close < Open
    body_pct <- ifelse(is.na(rng_safe), 0, body / rng_safe)
    
    prior_trend <- function(ref) {
      look <- ref - trend_lookback
      if (look < 1 || is.na(Close[ref]) || is.na(Close[look])) return("flat")
      d <- Close[ref] - Close[look]
      if (is.na(d)) "flat" else if (d > 0) "up" else if (d < 0) "down" else "flat"
    }
    
    results <- list()
    add_match <- function(i, pattern_label, signal, note) {
      results[[length(results) + 1]] <<- data.frame(
        BarIndex = i, Date = df$Date[i], Pattern = pattern_label, Signal = signal, Note = note,
        stringsAsFactors = FALSE
      )
    }
    
    for (i in seq_len(n)) {
      
      # ---- Single-candle patterns ----
      if (!is.na(body_pct[i])) {
        if ("doji" %in% patterns && body_pct[i] < 0.10 && !is.na(rng_safe[i])) {
          add_match(i, "Doji", "Neutral", "Open approx. equals Close; market indecision")
        }
        if ("marubozu" %in% patterns && body_pct[i] >= 0.70 && body[i] > 0 &&
            !is.na(upper_shadow[i]) && !is.na(lower_shadow[i]) &&
            upper_shadow[i] <= 0.10 * body[i] && lower_shadow[i] <= 0.10 * body[i]) {
          add_match(i, "Marubozu", if (is_bull[i]) "Bullish" else "Bearish",
                     "Long body, minimal shadows — strong one-sided conviction")
        }
        if ("spinning_top" %in% patterns && body_pct[i] < 0.30 && !is.na(rng_safe[i]) &&
            !is.na(upper_shadow[i]) && !is.na(lower_shadow[i]) &&
            upper_shadow[i] > 0.20 * rng_safe[i] && lower_shadow[i] > 0.20 * rng_safe[i]) {
          add_match(i, "Spinning Top", "Neutral", "Small body, long wicks both sides — indecision")
        }
        
        hammer_shape <- body_pct[i] < 0.35 && body[i] > 0 && !is.na(rng_safe[i]) &&
                        !is.na(lower_shadow[i]) && !is.na(upper_shadow[i]) &&
                        lower_shadow[i] >= 2 * body[i] && upper_shadow[i] <= 0.15 * rng_safe[i]
        if (hammer_shape && i > trend_lookback) {
          tr <- prior_trend(i - 1)
          if (tr == "down" && "hammer" %in% patterns) {
            add_match(i, "Hammer", "Bullish", "Small body, long lower wick after a downtrend")
          } else if (tr == "up" && "hanging_man" %in% patterns) {
            add_match(i, "Hanging Man", "Bearish", "Small body, long lower wick after an uptrend")
          }
        }
        
        inv_hammer_shape <- body_pct[i] < 0.35 && body[i] > 0 && !is.na(rng_safe[i]) &&
                            !is.na(upper_shadow[i]) && !is.na(lower_shadow[i]) &&
                            upper_shadow[i] >= 2 * body[i] && lower_shadow[i] <= 0.15 * rng_safe[i]
        if (inv_hammer_shape && i > trend_lookback) {
          tr <- prior_trend(i - 1)
          if (tr == "down" && "inverted_hammer" %in% patterns) {
            add_match(i, "Inverted Hammer", "Bullish", "Small body, long upper wick after a downtrend")
          } else if (tr == "up" && "shooting_star" %in% patterns) {
            add_match(i, "Shooting Star", "Bearish", "Small body, long upper wick after an uptrend")
          }
        }
      }
      
      # ---- Two-candle patterns ----
      if (i >= 2) {
        p <- i - 1
        if (!is.na(body_pct[p]) && !is.na(body_pct[i])) {
          
          if ("bullish_engulfing" %in% patterns && is_bear[p] && is_bull[i] &&
              Open[i] <= Close[p] && Close[i] >= Open[p] && body[i] > body[p]) {
            add_match(i, "Bullish Engulfing", "Bullish", "Bullish body fully engulfs the prior bearish body")
          }
          if ("bearish_engulfing" %in% patterns && is_bull[p] && is_bear[i] &&
              Open[i] >= Close[p] && Close[i] <= Open[p] && body[i] > body[p]) {
            add_match(i, "Bearish Engulfing", "Bearish", "Bearish body fully engulfs the prior bullish body")
          }
          
          mid_p <- (Open[p] + Close[p]) / 2
          if ("piercing_line" %in% patterns && is_bear[p] && body_pct[p] > 0.5 &&
              is_bull[i] && Open[i] < Close[p] && Close[i] > mid_p && Close[i] < Open[p]) {
            add_match(i, "Piercing Line", "Bullish", "Opens below prior close, closes above its midpoint")
          }
          if ("dark_cloud_cover" %in% patterns && is_bull[p] && body_pct[p] > 0.5 &&
              is_bear[i] && Open[i] > Close[p] && Close[i] < mid_p && Close[i] > Open[p]) {
            add_match(i, "Dark Cloud Cover", "Bearish", "Opens above prior close, closes below its midpoint")
          }
          
          if ("bullish_harami" %in% patterns && is_bear[p] && body_pct[p] > 0.5 &&
              is_bull[i] && Open[i] >= Close[p] && Close[i] <= Open[p]) {
            add_match(i, "Bullish Harami", "Bullish", "Small bullish body contained within the prior bearish body")
          }
          if ("bearish_harami" %in% patterns && is_bull[p] && body_pct[p] > 0.5 &&
              is_bear[i] && Open[i] <= Close[p] && Close[i] >= Open[p]) {
            add_match(i, "Bearish Harami", "Bearish", "Small bearish body contained within the prior bullish body")
          }
        }
        
        if (i > trend_lookback && !is.na(High[i]) && !is.na(High[p]) && !is.na(Low[i]) && !is.na(Low[p])) {
          window_start <- max(1, i - trend_lookback)
          avg_range <- mean(rng[window_start:i], na.rm = TRUE)
          tol <- if (!is.na(avg_range) && avg_range > 0) 0.10 * avg_range else 0
          tr <- prior_trend(p)
          if ("tweezer_top" %in% patterns && tr == "up" && abs(High[i] - High[p]) <= tol) {
            add_match(i, "Tweezer Top", "Bearish", "Matching highs after an uptrend")
          }
          if ("tweezer_bottom" %in% patterns && tr == "down" && abs(Low[i] - Low[p]) <= tol) {
            add_match(i, "Tweezer Bottom", "Bullish", "Matching lows after a downtrend")
          }
        }
      }
      
      # ---- Three-candle patterns ----
      if (i >= 3) {
        p2 <- i - 2; p1 <- i - 1
        if (!is.na(body_pct[p2]) && !is.na(body_pct[p1]) && !is.na(body_pct[i])) {
          
          if ("morning_star" %in% patterns && is_bear[p2] && body_pct[p2] > 0.5 &&
              body_pct[p1] < 0.30 && max(Open[p1], Close[p1]) < Close[p2] &&
              is_bull[i] && body_pct[i] > 0.5 && Close[i] > (Open[p2] + Close[p2]) / 2) {
            add_match(i, "Morning Star", "Bullish",
                       "Long bearish candle, small-bodied star, long bullish close into prior body")
          }
          if ("evening_star" %in% patterns && is_bull[p2] && body_pct[p2] > 0.5 &&
              body_pct[p1] < 0.30 && min(Open[p1], Close[p1]) > Close[p2] &&
              is_bear[i] && body_pct[i] > 0.5 && Close[i] < (Open[p2] + Close[p2]) / 2) {
            add_match(i, "Evening Star", "Bearish",
                       "Long bullish candle, small-bodied star, long bearish close into prior body")
          }
          
          if ("three_white_soldiers" %in% patterns && is_bull[p2] && is_bull[p1] && is_bull[i] &&
              body_pct[p2] > 0.4 && body_pct[p1] > 0.4 && body_pct[i] > 0.4 &&
              Close[p2] < Close[p1] && Close[p1] < Close[i] &&
              Open[p1] > Open[p2] && Open[p1] < Close[p2] &&
              Open[i] > Open[p1] && Open[i] < Close[p1]) {
            add_match(i, "Three White Soldiers", "Bullish", "Three consecutive long bullish candles, higher closes")
          }
          if ("three_black_crows" %in% patterns && is_bear[p2] && is_bear[p1] && is_bear[i] &&
              body_pct[p2] > 0.4 && body_pct[p1] > 0.4 && body_pct[i] > 0.4 &&
              Close[p2] > Close[p1] && Close[p1] > Close[i] &&
              Open[p1] < Open[p2] && Open[p1] > Close[p2] &&
              Open[i] < Open[p1] && Open[i] > Close[p1]) {
            add_match(i, "Three Black Crows", "Bearish", "Three consecutive long bearish candles, lower closes")
          }
          
          if ("abandoned_baby" %in% patterns) {
            if (is_bear[p2] && body_pct[p2] > 0.5 && body_pct[p1] < 0.10 &&
                !is.na(High[p1]) && !is.na(Low[p2]) && High[p1] < Low[p2] &&
                is_bull[i] && body_pct[i] > 0.5 && !is.na(Low[i]) && !is.na(High[p1]) && Low[i] > High[p1]) {
              add_match(i, "Abandoned Baby", "Bullish", "Doji gaps away from both neighbouring long candles")
            }
            if (is_bull[p2] && body_pct[p2] > 0.5 && body_pct[p1] < 0.10 &&
                !is.na(Low[p1]) && !is.na(High[p2]) && Low[p1] > High[p2] &&
                is_bear[i] && body_pct[i] > 0.5 && !is.na(High[i]) && !is.na(Low[p1]) && High[i] < Low[p1]) {
              add_match(i, "Abandoned Baby", "Bearish", "Doji gaps away from both neighbouring long candles")
            }
          }
        }
      }
    }
    
    if (length(results) == 0) return(data.frame())
    do.call(rbind, results)
  }
  
  # Keep the time-window slider's bounds in sync with whatever data is currently loaded,
  # defaulting to the most recent 100 bars.
  observeEvent(values$asset_data, {
    req(values$asset_data)
    n <- nrow(values$asset_data)
    updateSliderInput(session, "patternWindow", min = 1, max = n, value = c(max(1, n - 99), n))
  })
  
  output$patternWindowDates <- renderUI({
    req(values$asset_data, input$patternWindow)
    n <- nrow(values$asset_data)
    rng <- input$patternWindow
    i1 <- max(1, min(rng[1], n)); i2 <- max(1, min(rng[2], n))
    d1 <- values$asset_data$Date[i1]; d2 <- values$asset_data$Date[i2]
    tags$p(paste0("Window: ", format(d1, "%Y-%m-%d %H:%M"), " \u2192 ", format(d2, "%Y-%m-%d %H:%M"),
                  "  (", i2 - i1 + 1, " bars)"),
           style = "font-size:11px; color:#888; margin-top:4px;")
  })
  
  all_pattern_choices <- c("doji", "hammer", "inverted_hammer", "hanging_man", "shooting_star",
                            "bullish_engulfing", "bearish_engulfing", "morning_star", "evening_star",
                            "piercing_line", "dark_cloud_cover", "three_white_soldiers", "three_black_crows",
                            "bullish_harami", "bearish_harami", "spinning_top", "marubozu",
                            "tweezer_top", "tweezer_bottom", "abandoned_baby")
  
  observeEvent(input$patternSelectAll, {
    updateCheckboxGroupInput(session, "patternsToDetect", selected = all_pattern_choices)
  })
  observeEvent(input$patternSelectNone, {
    updateCheckboxGroupInput(session, "patternsToDetect", selected = character(0))
  })
  
  # Runs the detection algorithm over the selected window when "Detect Patterns" is clicked.
  # Pulls in a small lookback buffer before the window start so patterns beginning right at
  # the edge of the window still have correct trend/multi-bar context, then discards matches
  # whose final bar falls outside the user's actual selected window.
  pattern_scan_results <- eventReactive(input$detectPatterns, {
    req(values$asset_data, input$patternWindow, input$patternsToDetect)
    data <- values$asset_data
    n <- nrow(data)
    rng <- input$patternWindow
    start_i <- max(1, min(rng[1], n)); end_i <- max(1, min(rng[2], n))
    if (start_i > end_i) { tmp <- start_i; start_i <- end_i; end_i <- tmp }
    
    lookback_bars <- if (is.null(input$patternTrendLookback)) 5 else input$patternTrendLookback
    buffer_start <- max(1, start_i - (lookback_bars + 3))
    
    window_data <- data[buffer_start:end_i, , drop = FALSE]
    
    matches <- tryCatch(
      detect_candlestick_patterns(window_data, input$patternsToDetect, trend_lookback = lookback_bars),
      error = function(e) {
        showNotification(paste("Pattern detection error:", conditionMessage(e)), type = "error", duration = 8)
        data.frame()
      }
    )
    
    if (is.null(matches) || nrow(matches) == 0) {
      showNotification("No patterns matched in this window/selection.", type = "message", duration = 4)
      return(data.frame())
    }
    
    matches$BarIndex <- matches$BarIndex + buffer_start - 1
    matches <- matches[matches$BarIndex >= start_i & matches$BarIndex <= end_i, , drop = FALSE]
    matches <- matches[order(matches$BarIndex, decreasing = TRUE), , drop = FALSE]
    
    showNotification(paste0("Found ", nrow(matches), " pattern match(es)."), type = "message", duration = 4)
    matches
  })
  
  output$patternChart <- renderPlotly({
    req(values$asset_data, input$patternWindow)
    data <- values$asset_data
    n <- nrow(data)
    rng <- input$patternWindow
    start_i <- max(1, min(rng[1], n)); end_i <- max(1, min(rng[2], n))
    if (start_i > end_i) { tmp <- start_i; start_i <- end_i; end_i <- tmp }
    window_data <- data[start_i:end_i, , drop = FALSE]
    
    p <- plot_ly(window_data, x = ~Date, type = "candlestick",
                 open = ~Open, high = ~High, low = ~Low, close = ~Close,
                 increasing = list(line = list(color = "#27ae60")),
                 decreasing = list(line = list(color = "#e74c3c")),
                 name = current_asset())
    
    matches <- tryCatch(pattern_scan_results(), error = function(e) NULL)
    if (!is.null(matches) && is.data.frame(matches) && nrow(matches) > 0) {
      bulls    <- matches[matches$Signal == "Bullish", ]
      bears    <- matches[matches$Signal == "Bearish", ]
      neutrals <- matches[matches$Signal == "Neutral", ]
      
      if (nrow(bulls) > 0) {
        p <- p %>% add_trace(x = bulls$Date, y = data$Low[bulls$BarIndex] * 0.995,
                              type = "scatter", mode = "markers",
                              marker = list(symbol = "triangle-up", size = 12, color = "#27ae60"),
                              text = paste0(bulls$Pattern, "<br>", bulls$Note),
                              hoverinfo = "text", name = "Bullish Pattern")
      }
      if (nrow(bears) > 0) {
        p <- p %>% add_trace(x = bears$Date, y = data$High[bears$BarIndex] * 1.005,
                              type = "scatter", mode = "markers",
                              marker = list(symbol = "triangle-down", size = 12, color = "#e74c3c"),
                              text = paste0(bears$Pattern, "<br>", bears$Note),
                              hoverinfo = "text", name = "Bearish Pattern")
      }
      if (nrow(neutrals) > 0) {
        p <- p %>% add_trace(x = neutrals$Date, y = data$High[neutrals$BarIndex] * 1.005,
                              type = "scatter", mode = "markers",
                              marker = list(symbol = "diamond", size = 10, color = "#f39c12"),
                              text = paste0(neutrals$Pattern, "<br>", neutrals$Note),
                              hoverinfo = "text", name = "Neutral Pattern")
      }
    }
    
    p %>% layout(
      title = paste("Candlestick Pattern Detection —", current_asset()),
      xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
      yaxis = list(title = "Price"),
      plot_bgcolor = "white", paper_bgcolor = "white"
    )
  })
  
  output$patternResultsTable <- renderDT({
    matches <- pattern_scan_results()
    if (is.null(matches) || nrow(matches) == 0) {
      return(datatable(data.frame(Message = "No patterns matched in this window/selection — try widening the window or selecting more patterns."),
                        options = list(dom = 't'), rownames = FALSE, colnames = ""))
    }
    display <- data.frame(
      Date    = format(matches$Date, "%Y-%m-%d %H:%M"),
      Pattern = matches$Pattern,
      Signal  = matches$Signal,
      Note    = matches$Note,
      stringsAsFactors = FALSE
    )
    datatable(display, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE) %>%
      formatStyle("Signal",
                  backgroundColor = styleEqual(
                    c("Bullish", "Bearish", "Neutral"),
                    c("#d5f5e3", "#fadbd8", "#fdebd0")
                  ))
  })
  
  # ══════════════════════════════════════════════════════════════════════════
  # IG LOGIN TAB — authentication, session status, accounts, market search
  # ══════════════════════════════════════════════════════════════════════════
  
  observeEvent(input$igLoginBtn, {
    req(input$igApiKey, input$igUsername, input$igPassword)
    tryCatch({
      auth <- igfetchr::ig_auth(
        username   = input$igUsername,
        password   = input$igPassword,
        api_key    = input$igApiKey,
        acc_type   = input$igEnv,
        acc_number = if (!is.null(input$igAccNumber) && nzchar(trimws(input$igAccNumber))) trimws(input$igAccNumber) else NULL
      )
      values$ig_auth       <- auth
      values$ig_login_time <- Sys.time()
      showNotification("IG login successful.", type = "message", duration = 4)
    }, error = function(e) {
      showNotification(paste("IG login failed:", conditionMessage(e)), type = "error", duration = 8)
    })
  })
  
  observeEvent(input$igLogoutBtn, {
    req(values$ig_auth)
    tryCatch(igfetchr::ig_close_session(values$ig_auth), error = function(e) NULL)
    values$ig_auth       <- NULL
    values$ig_login_time <- NULL
    showNotification("Logged out of IG.", type = "message", duration = 3)
  })
  
  output$igStatusUI <- renderUI({
    if (is.null(values$ig_auth)) {
      div(style = "text-align:center; padding:20px;",
          icon("circle-xmark", style = "font-size:32px; color:#e74c3c;"),
          tags$h4("Not connected", style = "color:#e74c3c; margin-top:10px;"),
          tags$p("Enter your credentials on the left and click Login.", style = "color:#888; font-size:12px;")
      )
    } else {
      div(style = "text-align:center; padding:20px;",
          icon("circle-check", style = "font-size:32px; color:#27ae60;"),
          tags$h4("Connected", style = "color:#27ae60; margin-top:10px;"),
          tags$p(paste("Environment:", input$igEnv), style = "font-size:12px; color:#444; margin:2px 0;"),
          tags$p(paste("Logged in at:", format(values$ig_login_time, "%Y-%m-%d %H:%M:%S")),
                 style = "font-size:12px; color:#444; margin:2px 0;")
      )
    }
  })
  
  ig_accounts_data <- eventReactive(input$igTestConnection, {
    req(values$ig_auth)
    tryCatch({
      igfetchr::ig_get_accounts(values$ig_auth)
    }, error = function(e) {
      showNotification(paste("Could not fetch accounts:", conditionMessage(e)), type = "error", duration = 8)
      NULL
    })
  })
  
  output$igAccountsTable <- renderDT({
    req(ig_accounts_data())
    datatable(as.data.frame(ig_accounts_data()), options = list(dom = 't', scrollX = TRUE), rownames = FALSE)
  })
  
  ig_search_data <- eventReactive(input$igSearchBtn, {
    req(values$ig_auth, input$igSearchTerm)
    tryCatch({
      igfetchr::ig_search_markets(search_term = input$igSearchTerm, auth = values$ig_auth)
    }, error = function(e) {
      showNotification(paste("IG market search failed:", conditionMessage(e)), type = "error", duration = 8)
      NULL
    })
  })
  
  output$igSearchResultsTable <- renderDT({
    req(ig_search_data())
    datatable(as.data.frame(ig_search_data()),
              options = list(dom = 'tp', scrollX = TRUE, pageLength = 10), rownames = FALSE)
  })
  
  # Data source info
  output$dataSourceInfo <- renderUI({
    if (!values$data_loaded) {
      return(div("No data loaded. Select an asset to begin."))
    }
    
    asset_name <- if (input$assetClass == "crypto") {
      paste("Cryptocurrency:", current_asset())
    } else if (input$assetClass == "equity") {
      paste("Equities:", current_asset())
    } else {
      paste("Commodity:", current_asset())
    }
    
    div(
      h6(asset_name),
      p(paste("Records:", nrow(values$asset_data)), style = "margin: 0; font-size: 12px;"),
      p(paste("Last Updated:", format(values$last_update, "%Y-%m-%d %H:%M")), 
        style = "margin: 0; font-size: 12px;"),
      p(paste("Date Range:", min(values$asset_data$Date), "to", max(values$asset_data$Date)), 
        style = "margin: 0; font-size: 12px;")
    )
  })
  
  # MARKET OVERVIEW OUTPUTS
  
  output$currentPrice <- renderValueBox({
    req(values$asset_data)
    current_price <- tail(values$asset_data$Close, 1)
    
    price_display <- if (is.na(current_price) || is.nan(current_price)) {
      "N/A"
    } else {
      paste0("$", format(round(current_price, 2), big.mark = ",", nsmall = 2))
    }
    
    valueBox(
      value    = price_display,
      subtitle = paste("Current Price -", current_asset()),
      icon     = icon("dollar-sign"),
      color    = "blue"
    )
  })
  
  output$dailyChange <- renderValueBox({
    req(values$asset_data)
    data <- values$asset_data
    
    if (nrow(data) >= 2) {
      recent <- tail(data, 2)
      change <- (recent$Close[2] - recent$Close[1]) / recent$Close[1] * 100
      color <- ifelse(change > 0, "green", "red")
      icon_name <- ifelse(change > 0, "arrow-up", "arrow-down")
    } else {
      change <- 0
      color <- "yellow"
      icon_name <- "minus"
    }
    
    valueBox(
      value = paste0(ifelse(change > 0, "+", ""), format(round(change, 2), nsmall = 2), "%"),
      subtitle = "Daily Change",
      icon = icon(icon_name),
      color = color
    )
  })
  
  output$volumeInfo <- renderValueBox({
    req(values$asset_data)
    avg_volume <- mean(values$asset_data$Volume, na.rm = TRUE)
    
    # Futures and some crypto feeds return 0 or NA volume — display gracefully
    has_volume  <- !is.nan(avg_volume) && !is.na(avg_volume) && avg_volume > 0
    vol_display <- if (has_volume) format(round(avg_volume, 0), big.mark = ",") else "N/A"
    vol_label   <- if (has_volume) "Average Daily Volume" else "Volume Not Available"
    
    valueBox(
      value    = vol_display,
      subtitle = vol_label,
      icon     = icon("chart-bar"),
      color    = "yellow"
    )
  })
  
  output$dataRange <- renderValueBox({
    req(values$asset_data)
    data <- values$asset_data
    days <- as.numeric(max(data$Date) - min(data$Date))
    
    valueBox(
      value = paste(nrow(data), "days"),
      subtitle = paste(days, "days of data"),
      icon = icon("calendar"),
      color = "purple"
    )
  })
  
  output$overviewChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data
    
    p <- plot_ly()
    
    # Add close price
    if ("close" %in% input$overviewComponents) {
      p <- p %>% add_lines(data = data, x = ~Date, y = ~Close, name = "Close Price",
                           line = list(color = "#2c3e50", width = 2))
    }
    
    # Add moving average
    if ("ma" %in% input$overviewComponents && nrow(data) >= input$overviewMA) {
      ma <- SMA(data$Close, n = input$overviewMA)
      p <- p %>% add_lines(data = data, x = ~Date, y = ma, 
                           name = paste("MA(", input$overviewMA, ")"),
                           line = list(color = "#e74c3c", width = 2, dash = "dash"))
    }
    
    # Add volume — skip silently when the asset has no volume data (futures, crypto)
    if ("volume" %in% input$overviewComponents) {
      has_vol <- any(!is.na(data$Volume) & data$Volume > 0, na.rm = TRUE)
      if (has_vol) {
        p <- p %>% add_bars(data = data, x = ~Date, y = ~Volume, name = "Volume",
                            yaxis = "y2", marker = list(color = "#95a5a6", opacity = 0.3))
      }
    }
    
    p <- p %>% layout(
      title = paste(current_asset(), "- Price & Volume"),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price (USD)", side = "left"),
      yaxis2 = list(title = "Volume", overlaying = "y", side = "right"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
    
    p
  })
  
  output$marketStats <- renderDT({
    req(values$asset_data)
    data <- values$asset_data
    
    stats <- data.frame(
      Metric = c("Current", "Mean", "Median", "Min", "Max", "Range", "Std Dev"),
      Value = c(
        format(round(tail(data$Close, 1), 2), big.mark = ","),
        format(round(mean(data$Close), 2), big.mark = ","),
        format(round(median(data$Close), 2), big.mark = ","),
        format(round(min(data$Close), 2), big.mark = ","),
        format(round(max(data$Close), 2), big.mark = ","),
        format(round(max(data$Close) - min(data$Close), 2), big.mark = ","),
        format(round(sd(data$Close), 2), big.mark = ",")
      )
    )
    
    datatable(stats, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  output$priceMovementStats <- renderDT({
    req(values$asset_data)
    data <- values$asset_data
    
    returns <- data$returns[!is.na(data$returns)]
    
    stats <- data.frame(
      Metric = c("Valid Returns", "Mean Return (%)", "Volatility (%)", 
                 "Max Gain (%)", "Max Loss (%)", "Annualized Vol (%)"),
      Value = c(
        length(returns),
        round(mean(returns) * 100, 4),
        round(sd(returns) * 100, 4),
        round(max(returns) * 100, 4),
        round(min(returns) * 100, 4),
        round(sd(returns) * sqrt(252) * 100, 2)
      )
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$volumeStats <- renderDT({
    req(values$asset_data)
    data <- values$asset_data
    
    vol <- data$Volume
    has_vol <- any(!is.na(vol) & vol > 0, na.rm = TRUE)
    
    safe_fmt <- function(x) {
      if (is.na(x) || is.nan(x) || is.infinite(x)) "N/A"
      else format(round(x), big.mark = ",")
    }
    
    stats <- data.frame(
      Metric = c("Mean Volume", "Median Volume", "Max Volume", "Min Volume", "Std Dev"),
      Value  = if (has_vol) {
        c(safe_fmt(mean(vol, na.rm = TRUE)),
          safe_fmt(median(vol, na.rm = TRUE)),
          safe_fmt(max(vol,  na.rm = TRUE)),
          safe_fmt(min(vol,  na.rm = TRUE)),
          safe_fmt(sd(vol,   na.rm = TRUE)))
      } else {
        rep("N/A (no volume data)", 5)
      }
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$returnsDistribution <- renderPlotly({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)] * 100
    
    plot_ly(x = returns, type = "histogram", nbinsx = 40,
            marker = list(color = "#8e44ad", opacity = 0.7)) %>%
      layout(
        title = "Returns Distribution",
        xaxis = list(title = "Returns (%)"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$priceDistribution <- renderPlotly({
    req(values$asset_data)
    
    plot_ly(x = values$asset_data$Close, type = "histogram", nbinsx = 40,
            marker = list(color = "#3498db", opacity = 0.7)) %>%
      layout(
        title = "Price Distribution",
        xaxis = list(title = "Price (USD)"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # PRICE ANALYSIS OUTPUTS
  
  output$priceStats <- renderText({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
    
    if (nrow(data) == 0) return("No data in range")
    
    paste(
      paste("Period:", input$priceRange[1], "to", input$priceRange[2]),
      paste("Records:", nrow(data)),
      paste("Current:", round(tail(data$Close, 1), 2)),
      paste("High:", round(max(data$High), 2)),
      paste("Low:", round(min(data$Low), 2)),
      sep = "\n"
    )
  })
  
  output$detailedPriceChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data in selected range"))
    }
    
    p <- plot_ly(data, x = ~Date)
    
    if ("close" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Close, name = "Close", line = list(color = "#2c3e50", width = 2))
    }
    
    if ("highlow" %in% input$priceComponents) {
      p <- p %>% 
        add_lines(y = ~High, name = "High", line = list(color = "#27ae60", width = 1)) %>%
        add_lines(y = ~Low, name = "Low", line = list(color = "#e74c3c", width = 1))
    }
    
    if ("open" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Open, name = "Open", line = list(color = "#95a5a6", width = 1))
    }
    
    # Add MA
    if (nrow(data) >= input$priceMAPeriod) {
      ma <- SMA(data$Close, n = input$priceMAPeriod)
      p <- p %>% add_lines(y = ma, name = paste("MA(", input$priceMAPeriod, ")"),
                           line = list(color = "#9b59b6", width = 2, dash = "dash"))
    }
    
    # Add Bollinger Bands
    if (input$showBollingerBands && nrow(data) >= 20) {
      bb <- BBands(data$Close, n = 20)
      p <- p %>%
        add_lines(y = bb[,"up"], name = "BB Upper", line = list(color = "#95a5a6", dash = "dot")) %>%
        add_lines(y = bb[,"dn"], name = "BB Lower", line = list(color = "#95a5a6", dash = "dot"))
    }
    
    p %>% layout(
      title = paste("Detailed Price Analysis -", current_asset()),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price (USD)"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  output$ohlcChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2]) %>%
      tail(200)
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data in selected range"))
    }
    
    plot_ly(data, x = ~Date, type = "candlestick",
            open = ~Open, high = ~High, low = ~Low, close = ~Close) %>%
      layout(
        title = paste("Candlestick Chart -", current_asset()),
        xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
        yaxis = list(title = "Price (USD)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$ohlcStats <- renderDT({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(datatable(data.frame(Message = "No data")))
    }
    
    stats <- data.frame(
      Metric = c("Avg Open", "Avg High", "Avg Low", "Avg Close", 
                 "Avg Range", "Max Range", "Bullish Days", "Bearish Days"),
      Value = c(
        round(mean(data$Open), 2),
        round(mean(data$High), 2),
        round(mean(data$Low), 2),
        round(mean(data$Close), 2),
        round(mean(data$High - data$Low), 2),
        round(max(data$High - data$Low), 2),
        paste0(round(sum(data$Close > data$Open) / nrow(data) * 100, 1), "%"),
        paste0(round(sum(data$Close < data$Open) / nrow(data) * 100, 1), "%")
      )
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$returnsTimeSeries <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2], !is.na(returns))
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data available"))
    }
    
    plot_ly(data, x = ~Date, y = ~returns * 100, type = "scatter", mode = "lines",
            line = list(color = "#8e44ad", width = 1)) %>%
      layout(
        title = "Returns Time Series",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Returns (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$cumulativeReturns <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2], !is.na(returns))
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data available"))
    }
    
    data$cumulative_returns <- cumprod(1 + data$returns) - 1
    
    plot_ly(data, x = ~Date, y = ~cumulative_returns * 100, type = "scatter", mode = "lines",
            line = list(color = "#27ae60", width = 2)) %>%
      layout(
        title = "Cumulative Returns",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # TECHNICAL INDICATORS OUTPUTS
  
  output$technicalSignals <- renderText({
    req(values$asset_data)
    data <- values$asset_data %>% tail(200)
    
    signals <- c()
    
    # RSI
    if ("rsi" %in% input$technicalIndicators && nrow(data) >= input$rsiLength) {
      rsi_values <- RSI(data$Close, n = input$rsiLength)
      rsi <- tail(rsi_values[!is.na(rsi_values)], 1)
      if (length(rsi) > 0) {
        if (rsi > 70) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Overbought"))
        else if (rsi < 30) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Oversold"))
        else signals <- c(signals, paste("RSI:", round(rsi, 2), "- Neutral"))
      }
    }
    
    # Price vs SMA
    if ("sma" %in% input$technicalIndicators && nrow(data) >= input$smaLength) {
      sma <- tail(SMA(data$Close, n = input$smaLength), 1)
      current <- tail(data$Close, 1)
      if (!is.na(sma)) {
        pct <- (current - sma) / sma * 100
        signals <- c(signals, paste("Price vs SMA:", ifelse(current > sma, "Above", "Below"), 
                                    paste0("(", round(pct, 2), "%)")))
      }
    }
    
    paste(if (length(signals) > 0) signals else "Select indicators to see signals", collapse = "\n")
  })
  
  output$technicalChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(500)
    
    p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                 name = "Close", line = list(color = "#2c3e50", width = 2))
    
    if ("sma" %in% input$technicalIndicators && nrow(data) >= input$smaLength) {
      p <- p %>% add_lines(y = SMA(data$Close, n = input$smaLength),
                           name = paste("SMA(", input$smaLength, ")"),
                           line = list(color = "#e74c3c", width = 2))
    }
    
    if ("ema" %in% input$technicalIndicators && nrow(data) >= input$emaLength) {
      p <- p %>% add_lines(y = EMA(data$Close, n = input$emaLength),
                           name = paste("EMA(", input$emaLength, ")"),
                           line = list(color = "#27ae60", width = 2))
    }
    
    if ("bb" %in% input$technicalIndicators && nrow(data) >= input$bbLength) {
      bb <- BBands(data$Close, n = input$bbLength, sd = input$bbSd)
      p <- p %>%
        add_lines(y = bb[,"up"], name = "BB Upper", line = list(color = "#95a5a6", dash = "dash")) %>%
        add_lines(y = bb[,"dn"], name = "BB Lower", line = list(color = "#95a5a6", dash = "dash"))
    }
    
    p %>% layout(
      title = paste("Technical Analysis -", current_asset()),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price (USD)"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  output$rsiChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(200)
    
    if (nrow(data) < input$rsiLength) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rsi_values <- RSI(data$Close, n = input$rsiLength)
    plot_data <- data[!is.na(rsi_values),]
    rsi_values <- rsi_values[!is.na(rsi_values)]
    
    plot_ly(plot_data, x = ~Date, y = rsi_values, type = "scatter", mode = "lines",
            line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        title = paste("RSI(", input$rsiLength, ")"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "RSI", range = c(0, 100)),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
               y0 = 70, y1 = 70, line = list(color = "#e74c3c", dash = "dash")),
          list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
               y0 = 30, y1 = 30, line = list(color = "#27ae60", dash = "dash"))
        )
      )
  })
  
  output$macdChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(200)
    
    if (nrow(data) < 50) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    macd <- MACD(data$Close, nFast = 12, nSlow = 26, nSig = 9)
    plot_data <- data.frame(
      Date = data$Date,
      macd = macd[,"macd"],
      signal = macd[,"signal"]
    ) %>% filter(complete.cases(.))
    
    plot_data$histogram <- plot_data$macd - plot_data$signal
    
    plot_ly(plot_data, x = ~Date) %>%
      add_lines(y = ~macd, name = "MACD", line = list(color = "#3498db", width = 2)) %>%
      add_lines(y = ~signal, name = "Signal", line = list(color = "#e74c3c", width = 1)) %>%
      add_bars(y = ~histogram, name = "Histogram",
               marker = list(color = ifelse(plot_data$histogram > 0, "#27ae60", "#e74c3c"))) %>%
      layout(
        title = "MACD",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Value"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$stochChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(200)
    
    if (nrow(data) < 30) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    k_period <- 14
    d_period <- 3
    
    rolling_low <- rollapply(data$Low, width = k_period, FUN = min, align = "right", fill = NA)
    rolling_high <- rollapply(data$High, width = k_period, FUN = max, align = "right", fill = NA)
    
    stoch_k <- ifelse(rolling_high - rolling_low != 0,
                      (data$Close - rolling_low) / (rolling_high - rolling_low) * 100, 50)
    stoch_d <- SMA(stoch_k, n = d_period)
    
    plot_data <- data.frame(Date = data$Date, stoch_k = stoch_k, stoch_d = stoch_d) %>%
      filter(complete.cases(.))
    
    plot_ly(plot_data, x = ~Date) %>%
      add_lines(y = ~stoch_k, name = "%K", line = list(color = "#3498db", width = 2)) %>%
      add_lines(y = ~stoch_d, name = "%D", line = list(color = "#e74c3c", width = 1)) %>%
      layout(
        title = "Stochastic Oscillator",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Stochastic (%)", range = c(0, 100)),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
               y0 = 80, y1 = 80, line = list(color = "#e74c3c", dash = "dash")),
          list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
               y0 = 20, y1 = 20, line = list(color = "#27ae60", dash = "dash"))
        )
      )
  })
  
  # VOLATILITY ANALYSIS OUTPUTS
  
    
    
    
    
    
  # RISK METRICS OUTPUTS
  
    
    
    
    
    
    
  # ADVANCED METRICS OUTPUTS (NEW)
  
  # Helper function to calculate Sharpe Ratio
  calculate_sharpe <- function(returns, rf_rate, annualize = TRUE) {
    rf_daily <- rf_rate / 100 / 252
    excess_returns <- returns - rf_daily
    sharpe <- mean(excess_returns, na.rm = TRUE) / sd(excess_returns, na.rm = TRUE)
    if (annualize) sharpe <- sharpe * sqrt(252)
    return(sharpe)
  }
  
  # Helper function to calculate Sortino Ratio
  # Denominator = annualised downside deviation (returns below the risk-free hurdle).
  # Using the same rf_rate as Sharpe ensures the two ratios are directly comparable:
  # the only difference is that Sharpe penalises ALL volatility while Sortino penalises
  # only DOWNSIDE volatility.  Assets whose upside volatility >> downside will show
  # a materially higher Sortino than Sharpe; assets with symmetric returns will show
  # Sortino ~ sqrt(2) * Sharpe (approx 1.41x).
  calculate_sortino <- function(returns, rf_rate, annualize = TRUE) {
    rf_daily      <- rf_rate / 100 / 252
    excess        <- returns - rf_daily
    downside      <- pmin(excess, 0)
    # Annualised mean excess return (numerator)
    ann_mean      <- mean(excess, na.rm = TRUE) * 252
    # Annualised downside deviation (denominator)
    # sqrt(252) scales daily semi-deviation to annual, matching the numerator's scale
    ann_dd        <- sqrt(mean(downside^2, na.rm = TRUE)) * sqrt(252)
    if (ann_dd == 0 || is.nan(ann_dd)) return(NA)
    sortino       <- ann_mean / ann_dd
    # If caller requests non-annualised, de-scale back
    if (!annualize) sortino <- sortino / sqrt(252)
    return(sortino)
  }
  
  # Helper function to calculate Calmar Ratio
  calculate_calmar <- function(returns, annualize = TRUE) {
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max
    max_dd <- min(drawdown, na.rm = TRUE)
    if (max_dd == 0) return(NA)
    
    ann_return <- mean(returns, na.rm = TRUE) * 252
    calmar <- ann_return / abs(max_dd)
    return(calmar)
  }
  
  # Helper function to calculate Omega Ratio
  calculate_omega <- function(returns, threshold = 0) {
    threshold_daily <- threshold / 252
    gains <- sum(pmax(returns - threshold_daily, 0), na.rm = TRUE)
    losses <- sum(abs(pmin(returns - threshold_daily, 0)), na.rm = TRUE)
    if (losses == 0) return(Inf)
    return(gains / losses)
  }
  
    
    
    
    
    
    
    
    
    
    
    
  # HEDGING STRATEGIES OUTPUTS (NEW)
  
    
    
    
    
    
    
    
    
    
  # COMPOSITE ANALYSIS OUTPUTS
  
    
    
    
    
    
    
    
    
    
  }

# Run the application
shinyApp(ui = ui, server = server)
