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

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Multi-Asset Analysis Dashboard"),
  
  dashboardSidebar(
    # Asset class selector
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        selectInput("assetClass", 
                    "Select Asset Class:",
                    choices = c("Cryptocurrencies" = "crypto", 
                                "Equities" = "equity",
                                "Commodities" = "commodity"),
                    selected = "crypto",
                    width = "100%")
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
        )
    ),
    
    sidebarMenu(
      id = "main_menu",
      menuItem("About & Overview",     tabName = "about",     icon = icon("circle-info"), selected = TRUE),
      menuItem("Futures, Options & FX",tabName = "derivatives",icon = icon("right-left")),
      menuItem("Extended Indicators",  tabName = "extra_ta",  icon = icon("chart-area")),
      menuItem("Psychology & Macro",   tabName = "psych_macro",icon = icon("brain")),
      menuItem("Market Overview",      tabName = "overview",  icon = icon("chart-line")),
      menuItem("Price Analysis",       tabName = "price",     icon = icon("chart-simple")),
      menuItem("Technical Indicators", tabName = "technical", icon = icon("chart-bar")),
      menuItem("Volatility Analysis",  tabName = "volatility",icon = icon("wave-square")),
      menuItem("Risk Metrics",         tabName = "risk",      icon = icon("exclamation-triangle")),
      menuItem("Advanced Metrics",     tabName = "advanced",  icon = icon("star")),
      menuItem("Hedging Strategies",   tabName = "hedging",   icon = icon("shield-alt")),
      menuItem("Composite Analysis",   tabName = "composite", icon = icon("layer-group")),
      menuItem("Feedback",             tabName = "feedback",  icon = icon("envelope"))
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
      
      # ── ABOUT & OVERVIEW TAB ──────────────────────────────────────────────────
      tabItem(tabName = "about",
        
        # ── TOP BOX: Creator profile ────────────────────────────────────────────
        fluidRow(
          box(
            width = 12,
            solidHeader = TRUE,
            status = "primary",
            title = NULL,
            div(
              style = paste0(
                "background: linear-gradient(135deg, #002C3C 0%, #005f5a 60%, #00A39A 100%);",
                "border-radius: 10px; padding: 32px 36px; color: #ffffff;"
              ),
              fluidRow(
                column(8,
                  tags$h1(
                    "Joseph Francisco Zubizarreta",
                    style = "font-size:28px; font-weight:700; margin:0 0 6px 0; color:#ffffff;"
                  ),
                  tags$p(
                    HTML("<strong style='color:#7fffd4;'>MBA Alumni</strong> &nbsp;|&nbsp;
                          Judge Business School, University of Cambridge &nbsp;|&nbsp;
                          <strong style='color:#7fffd4;'>Founder</strong>, Atera Analytics"),
                    style = "font-size:15px; margin:0 0 18px 0; color:#d0f0ec;"
                  ),
                  tags$p(
                    HTML(paste0(
                      "Atera Analytics is an entrepreneurial platform built on the principle that ",
                      "complex, production-grade analytical applications should be accessible to ",
                      "domain experts — not just software engineers. This app is one artefact of that ",
                      "mission: a fully integrated, multi-asset financial analytics suite designed for ",
                      "rigorous quantitative analysis across <strong>Cryptocurrencies</strong>, ",
                      "<strong>Equities</strong>, and <strong>Commodities</strong>."
                    )),
                    style = "font-size:14px; line-height:1.7; color:#e8f8f6; margin:0 0 14px 0;"
                  ),
                  tags$p(
                    HTML(paste0(
                      "Combining real-time market data via Yahoo Finance, institutional-grade risk ",
                      "metrics, technical analysis, hedging strategy modelling, and cross-asset ",
                      "composite analysis — all within a single deployable Shiny application."
                    )),
                    style = "font-size:14px; line-height:1.7; color:#e8f8f6; margin:0;"
                  )
                ),
                column(4,
                  div(
                    style = paste0(
                      "background:rgba(255,255,255,0.08); border-radius:10px; ",
                      "padding:20px 22px; text-align:center; height:100%;"
                    ),
                    tags$div(
                      icon("graduation-cap", style = "font-size:38px; color:#7fffd4; margin-bottom:10px;"),
                      tags$h4("Judge Business School", style = "color:#ffffff; font-weight:600; margin:0 0 4px 0; font-size:15px;"),
                      tags$p("University of Cambridge", style = "color:#b2e0db; font-size:13px; margin:0 0 16px 0;"),
                      tags$hr(style = "border-color:rgba(255,255,255,0.2); margin:12px 0;"),
                      tags$div(
                        icon("building", style = "font-size:28px; color:#7fffd4; margin-bottom:8px;"),
                        tags$h4("Atera Analytics", style = "color:#ffffff; font-weight:600; margin:0 0 4px 0; font-size:15px;"),
                        tags$p("Entrepreneurial Analytics Platform", style = "color:#b2e0db; font-size:13px; margin:0;")
                      )
                    )
                  )
                )
              )
            )
          )
        ),
        
        # ── ASSET CLASS QUICK REFERENCE ─────────────────────────────────────────
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "primary",
            title = "Asset Classes Covered",
            fluidRow(
              column(4,
                div(style = "text-align:center; padding:16px;",
                  icon("bitcoin", style = "font-size:36px; color:#f39c12; margin-bottom:10px;"),
                  tags$h4("Cryptocurrencies", style = "color:#2c3e50; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML("Bitcoin (BTC-USD) &bull; Ethereum (ETH-USD) &bull; Cardano (ADA-USD)"),
                    style = "font-size:13px; color:#555; margin:0 0 8px 0;"),
                  tags$p("24/7 market data. Highest volatility class — ideal for testing tail-risk and drawdown metrics.",
                    style = "font-size:12px; color:#777; line-height:1.5;")
                )
              ),
              column(4,
                div(style = "text-align:center; padding:16px; border-left:1px solid #e8e8e8; border-right:1px solid #e8e8e8;",
                  icon("chart-line", style = "font-size:36px; color:#3498db; margin-bottom:10px;"),
                  tags$h4("Equities", style = "color:#2c3e50; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML("NVIDIA (NVDA) &bull; Microsoft (MSFT) &bull; Apple (AAPL)"),
                    style = "font-size:13px; color:#555; margin:0 0 8px 0;"),
                  tags$p("NYSE/NASDAQ large-cap equities. Full OHLCV data with adjusted close for accurate return calculations.",
                    style = "font-size:12px; color:#777; line-height:1.5;")
                )
              ),
              column(4,
                div(style = "text-align:center; padding:16px;",
                  icon("oil-well", style = "font-size:36px; color:#e67e22; margin-bottom:10px;"),
                  tags$h4("Commodities", style = "color:#2c3e50; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML("Gold (GC=F) &bull; Crude Oil (CL=F) &bull; Natural Gas (NG=F)"),
                    style = "font-size:13px; color:#555; margin:0 0 8px 0;"),
                  tags$p("Front-month continuous futures contracts. Key inflation hedges and macro regime indicators.",
                    style = "font-size:12px; color:#777; line-height:1.5;")
                )
              )
            )
          )
        ),
        
        # ── TAB-BY-TAB OVERVIEW ─────────────────────────────────────────────────
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "primary",
            title = "Application Modules — Detailed Overview",
            
            # Tab 1 — Market Overview
            div(style = "margin-bottom:28px;",
              fluidRow(
                column(1, div(style="text-align:center; padding-top:4px;",
                  icon("chart-line", style="font-size:28px; color:#008A82;"))),
                column(11,
                  tags$h4("1 · Market Overview", style="color:#002C3C; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML(paste0(
                    "The entry point for any asset. Displays a live price and volume chart for the selected ",
                    "instrument with optional moving-average overlay. Four summary value boxes report the ",
                    "<strong>current price</strong>, <strong>daily % change</strong>, ",
                    "<strong>average volume</strong>, and <strong>data range</strong> at a glance. ",
                    "Three statistics tables break down market statistics, price movement patterns, and volume ",
                    "behaviour. A returns histogram and price distribution chart complete the panel, giving an ",
                    "immediate statistical fingerprint of the asset before deeper analysis."
                  )), style="font-size:13px; color:#444; line-height:1.7; margin:0;")
                )
              )
            ),
            tags$hr(style="border-color:#e8eeee; margin:4px 0 20px 0;"),
            
            # Tab 2 — Price Analysis
            div(style = "margin-bottom:28px;",
              fluidRow(
                column(1, div(style="text-align:center; padding-top:4px;",
                  icon("chart-simple", style="font-size:28px; color:#2980b9;"))),
                column(11,
                  tags$h4("2 · Price Analysis", style="color:#002C3C; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML(paste0(
                    "A fully configurable deep-dive into price action. A <strong>date range selector</strong> ",
                    "focuses the analysis on any sub-period. Component toggles show/hide Close, High/Low, and Open. ",
                    "A configurable moving average and optional <strong>Bollinger Bands</strong> overlay are added ",
                    "directly to the price chart. The tab also contains a professional ",
                    "<strong>OHLC candlestick chart</strong> (last 200 bars) with a companion statistics table, ",
                    "plus separate panels for <strong>daily returns time series</strong> and ",
                    "<strong>cumulative returns</strong> — essential for visualising compounding over time."
                  )), style="font-size:13px; color:#444; line-height:1.7; margin:0;")
                )
              )
            ),
            tags$hr(style="border-color:#e8eeee; margin:4px 0 20px 0;"),
            
            # Tab 3 — Technical Indicators
            div(style = "margin-bottom:28px;",
              fluidRow(
                column(1, div(style="text-align:center; padding-top:4px;",
                  icon("chart-bar", style="font-size:28px; color:#8e44ad;"))),
                column(11,
                  tags$h4("3 · Technical Indicators", style="color:#002C3C; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML(paste0(
                    "Six configurable technical indicators applied to any asset class: ",
                    "<strong>SMA</strong> (Simple Moving Average), <strong>EMA</strong> (Exponential MA), ",
                    "<strong>RSI</strong> (Relative Strength Index), <strong>MACD</strong> ",
                    "(Moving Average Convergence Divergence), <strong>Bollinger Bands</strong>, and the ",
                    "<strong>Stochastic Oscillator</strong>. Each indicator has an independently configurable ",
                    "period parameter. The main chart overlays selected indicators on the price series, while ",
                    "RSI, MACD, and Stochastic each expand into a dedicated sub-chart with standard ",
                    "overbought/oversold reference lines. A live signals panel interprets current RSI level ",
                    "and price-vs-MA position in plain language."
                  )), style="font-size:13px; color:#444; line-height:1.7; margin:0;")
                )
              )
            ),
            tags$hr(style="border-color:#e8eeee; margin:4px 0 20px 0;"),
            
            # Tab 4 — Volatility Analysis
            div(style = "margin-bottom:28px;",
              fluidRow(
                column(1, div(style="text-align:center; padding-top:4px;",
                  icon("wave-square", style="font-size:28px; color:#16a085;"))),
                column(11,
                  tags$h4("4 · Volatility Analysis", style="color:#002C3C; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML(paste0(
                    "Three volatility estimation methodologies are offered: ",
                    "<strong>Realized (Close-to-Close)</strong>, ",
                    "<strong>Parkinson (High-Low range)</strong> — more efficient for assets with intraday extremes — ",
                    "and <strong>Garman-Klass (full OHLC)</strong>, the most statistically efficient estimator. ",
                    "Rolling volatility is plotted with a configurable window and confidence bands. ",
                    "A volatility distribution histogram reveals regime characteristics, while a ",
                    "<strong>volatility clustering</strong> chart visualises GARCH-type autocorrelation in absolute ",
                    "returns. The <strong>Regime Analysis</strong> panel colour-codes observations into Low / Normal / High ",
                    "volatility states using the 25th and 75th percentiles as boundaries — particularly ",
                    "informative for crypto and commodity assets."
                  )), style="font-size:13px; color:#444; line-height:1.7; margin:0;")
                )
              )
            ),
            tags$hr(style="border-color:#e8eeee; margin:4px 0 20px 0;"),
            
            # Tab 5 — Risk Metrics
            div(style = "margin-bottom:28px;",
              fluidRow(
                column(1, div(style="text-align:center; padding-top:4px;",
                  icon("exclamation-triangle", style="font-size:28px; color:#e74c3c;"))),
                column(11,
                  tags$h4("5 · Risk Metrics", style="color:#002C3C; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML(paste0(
                    "Institutional-grade downside risk quantification. ",
                    "<strong>Value at Risk (VaR)</strong> is computed via two methods — ",
                    "Historical Simulation and Parametric Normal — across a configurable portfolio value, ",
                    "confidence level (90–99.5%), and time horizon. Rolling VaR is plotted against daily P&amp;L ",
                    "to reveal periods of VaR breach. <strong>Expected Shortfall (CVaR)</strong> complements VaR by ",
                    "measuring the average loss beyond the VaR threshold. A full ",
                    "<strong>Drawdown Analysis</strong> chart shows the underwater equity curve. The ",
                    "<strong>Stress Test</strong> table quantifies 2σ through 4σ tail events and market crisis ",
                    "scenarios in dollar terms against the configured portfolio size."
                  )), style="font-size:13px; color:#444; line-height:1.7; margin:0;")
                )
              )
            ),
            tags$hr(style="border-color:#e8eeee; margin:4px 0 20px 0;"),
            
            # Tab 6 — Advanced Metrics
            div(style = "margin-bottom:28px;",
              fluidRow(
                column(1, div(style="text-align:center; padding-top:4px;",
                  icon("star", style="font-size:28px; color:#f39c12;"))),
                column(11,
                  tags$h4("6 · Advanced Metrics", style="color:#002C3C; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML(paste0(
                    "Four risk-adjusted performance ratios displayed as headline value boxes: ",
                    "<strong>Sharpe Ratio</strong> (excess return per unit of total risk), ",
                    "<strong>Sortino Ratio</strong> (excess return per unit of downside risk), ",
                    "<strong>Calmar Ratio</strong> (annualised return divided by maximum drawdown), and the ",
                    "<strong>Omega Ratio</strong> (probability-weighted ratio of gains to losses above a threshold). ",
                    "All metrics are configurable via risk-free rate, target return, and rolling window inputs. ",
                    "Rolling Sharpe and Sortino charts expose how risk-adjusted performance evolves through ",
                    "market cycles. Downside risk, upside vs downside capture, maximum drawdown detail, and ",
                    "recovery period analysis complete the tab."
                  )), style="font-size:13px; color:#444; line-height:1.7; margin:0;")
                )
              )
            ),
            tags$hr(style="border-color:#e8eeee; margin:4px 0 20px 0;"),
            
            # Tab 7 — Hedging Strategies
            div(style = "margin-bottom:28px;",
              fluidRow(
                column(1, div(style="text-align:center; padding-top:4px;",
                  icon("shield-alt", style="font-size:28px; color:#27ae60;"))),
                column(11,
                  tags$h4("7 · Hedging Strategies", style="color:#002C3C; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML(paste0(
                    "Models the effectiveness of hedging the selected asset against a second instrument. ",
                    "Four hedge construction methods are available: <strong>Static</strong> (fixed ratio), ",
                    "<strong>Dynamic Correlation-based</strong> (ratio updated using rolling correlation), ",
                    "<strong>Beta-Adjusted</strong> (market beta as the hedge multiplier), and ",
                    "<strong>Minimum Variance</strong> (ratio that minimises portfolio variance). ",
                    "The main performance chart overlays hedged vs unhedged cumulative returns. Rolling hedge ratio ",
                    "and correlation charts expose how the relationship between the two instruments evolves. A ",
                    "<strong>Cost-Benefit Analysis</strong> table estimates transaction costs against the volatility ",
                    "reduction achieved — directly answering whether the hedge pays for itself."
                  )), style="font-size:13px; color:#444; line-height:1.7; margin:0;")
                )
              )
            ),
            tags$hr(style="border-color:#e8eeee; margin:4px 0 20px 0;"),
            
            # Tab 8 — Composite Analysis
            div(style = "margin-bottom:8px;",
              fluidRow(
                column(1, div(style="text-align:center; padding-top:4px;",
                  icon("layer-group", style="font-size:28px; color:#9b59b6;"))),
                column(11,
                  tags$h4("8 · Composite Analysis", style="color:#002C3C; font-weight:700; margin:0 0 6px 0;"),
                  tags$p(HTML(paste0(
                    "The only tab that loads data for <em>multiple assets simultaneously</em>, enabling ",
                    "true cross-asset and cross-class comparison. Up to 9 instruments — spanning all three asset ",
                    "classes — can be selected together. Three normalisation modes are available: ",
                    "<strong>Index (Base 100)</strong> for return comparison, <strong>Cumulative %</strong>, or ",
                    "<strong>Raw Price</strong>. A <strong>Correlation Heatmap</strong> (using corrplot) reveals ",
                    "diversification potential between assets. A <strong>Risk-Return scatter</strong> plots ",
                    "annualised volatility against annualised return for every selected asset. A ",
                    "<strong>Rolling 60-day Correlation</strong> chart tracks how pairwise relationships evolve ",
                    "over time. The Asset Class Comparison panel summarises average returns and volatility by ",
                    "Crypto, Equity, and Commodity class, with a best-performer and most-volatile identifier."
                  )), style="font-size:13px; color:#444; line-height:1.7; margin:0;")
                )
              )
            )
          )
        ),
        
        # ── DATA FLOW DIAGRAM ────────────────────────────────────────────────────
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "info",
            title = "Data & Analysis Flow",
            div(style = "padding: 10px 0;",
              fluidRow(
                column(3,
                  div(style=paste0("background:linear-gradient(135deg,#002C3C,#005f5a);",
                    "color:#fff;border-radius:8px;padding:16px;text-align:center;height:90px;",
                    "display:flex;flex-direction:column;justify-content:center;"),
                    icon("database", style="font-size:20px; margin-bottom:6px;"),
                    tags$strong("Yahoo Finance API", style="display:block; font-size:13px;"),
                    tags$span("quantmod · real-time OHLCV", style="font-size:11px; color:#b2e0db;")
                  )
                ),
                column(1, div(style="display:flex;align-items:center;justify-content:center;height:90px;",
                  icon("arrow-right", style="font-size:22px; color:#008A82;")
                )),
                column(3,
                  div(style=paste0("background:linear-gradient(135deg,#005f5a,#008A82);",
                    "color:#fff;border-radius:8px;padding:16px;text-align:center;height:90px;",
                    "display:flex;flex-direction:column;justify-content:center;"),
                    icon("gears", style="font-size:20px; margin-bottom:6px;"),
                    tags$strong("R Processing Layer", style="display:block; font-size:13px;"),
                    tags$span("dplyr · TTR · zoo · quantmod", style="font-size:11px; color:#d0f0ec;")
                  )
                ),
                column(1, div(style="display:flex;align-items:center;justify-content:center;height:90px;",
                  icon("arrow-right", style="font-size:22px; color:#008A82;")
                )),
                column(4,
                  div(style=paste0("background:linear-gradient(135deg,#008A82,#00A39A);",
                    "color:#fff;border-radius:8px;padding:16px;text-align:center;height:90px;",
                    "display:flex;flex-direction:column;justify-content:center;"),
                    icon("display", style="font-size:20px; margin-bottom:6px;"),
                    tags$strong("Interactive Visualisation", style="display:block; font-size:13px;"),
                    tags$span("plotly · DT · shinydashboard", style="font-size:11px; color:#e8f8f6;")
                  )
                )
              )
            )
          )
        )
        
      ), # end tabItem about
      
      # ── FUTURES, OPTIONS & FX TAB ─────────────────────────────────────────────
      tabItem(tabName = "derivatives",
        
        fluidRow(
          box(
            width = 12, solidHeader = FALSE, status = "warning",
            div(style = "display:flex; align-items:flex-start; gap:14px;",
              icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
              div(
                tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
                tags$p(HTML(paste0(
                  "Covers the core derivatives concepts from the Futures &amp; Options and Introduction to FX ",
                  "reference manuals. Each sub-tab pairs a short explanation with a live, interactive calculator ",
                  "or chart. Numeric defaults are seeded from the currently selected asset's latest closing price ",
                  "where relevant, but every field can be edited freely to explore different scenarios."
                )), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
              )
            )
          )
        ),
        
        tabsetPanel(
          id = "derivativesSubTabs", type = "tabs",
          
          # -- Sub-tab: Futures Mechanics --
          tabPanel("Futures Mechanics",
            br(),
            fluidRow(
              box(
                title = "Long vs Short Futures Position", status = "primary", solidHeader = TRUE, width = 4,
                tags$p(HTML(paste0(
                  "A <strong>futures contract</strong> is a binding agreement to buy (long) or sell (short) an ",
                  "underlying asset at an agreed price on a future date. A <strong>long</strong> position profits ",
                  "if the price rises above the entry price at expiry; a <strong>short</strong> position profits ",
                  "if the price falls below it. The two profiles are exact mirror images — maximum gain for one ",
                  "equals maximum loss for the other, which is why futures are described as a zero-sum game."
                )), style = "font-size:13px; color:#444; line-height:1.7;"),
                numericInput("futuresEntryPrice", "Entry / Agreed Price:", value = 100, min = 0.01, step = 0.01),
                tags$p("Defaults to the current asset's latest close price and updates automatically when you change asset in the sidebar.",
                       style = "font-size:11px; color:#888; font-style:italic;")
              ),
              box(
                title = "Profit & Loss at Expiry", status = "primary", solidHeader = TRUE, width = 8,
                withSpinner(plotlyOutput("futuresPnLChart", height = "400px")),
                tags$p(paste0(
                  "The diagonal lines show profit/loss per unit at expiry across a range of underlying prices. ",
                  "Long (green) has unlimited upside and downside capped at the entry price; short (red) has the ",
                  "opposite profile — capped gain, unlimited loss."
                ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
              )
            ),
            fluidRow(
              box(
                title = "Position Summary", status = "info", solidHeader = TRUE, width = 12,
                withSpinner(DT::dataTableOutput("futuresPnLSummaryTable"))
              )
            )
          ),
          
          # -- Sub-tab: Futures Pricing & Basis --
          tabPanel("Pricing, Basis & Carry",
            br(),
            fluidRow(
              box(
                title = "Fair Value Calculator", status = "primary", solidHeader = TRUE, width = 4,
                tags$p(HTML(paste0(
                  "<strong>Fair value = Cash price + Net cost of carry.</strong> Cost of carry includes lost ",
                  "interest and storage/insurance costs, less any benefit of holding the asset (e.g. dividend or ",
                  "convenience yield). When a future trades above fair value, a <strong>Cash &amp; Carry</strong> ",
                  "arbitrage is possible; below fair value, a <strong>Reverse Cash &amp; Carry</strong> arbitrage ",
                  "is possible. As expiry nears, cost of carry shrinks to zero and cash/futures prices <em>converge</em>."
                )), style = "font-size:12px; color:#444; line-height:1.6;"),
                numericInput("fvCashPrice", "Cash / Spot Price:", value = 100, min = 0.01, step = 0.01),
                numericInput("fvInterestRate", "Interest Rate (% p.a.):", value = 5, min = 0, max = 30, step = 0.25),
                numericInput("fvStorageCost", "Storage/Insurance (absolute, over period):", value = 0, min = 0, step = 0.1),
                numericInput("fvDividendYield", "Dividend/Convenience Yield (% p.a.):", value = 0, min = 0, max = 30, step = 0.25),
                numericInput("fvDaysToExpiry", "Days to Expiry:", value = 90, min = 1, max = 720, step = 1)
              ),
              box(
                title = "Fair Value, Basis & Market State", status = "info", solidHeader = TRUE, width = 8,
                uiOutput("fairValueResult"),
                tags$hr(),
                withSpinner(plotlyOutput("convergenceChart", height = "300px")),
                tags$p(paste0(
                  "Convergence: as time to expiry falls to zero, the cost of carry falls to zero and the future's ",
                  "price converges onto the cash price. This chart assumes the cash price itself stays constant."
                ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
              )
            )
          ),
          
          # -- Sub-tab: Options P&L --
          tabPanel("Options P&L Profiles",
            br(),
            fluidRow(
              box(
                title = "Options Configuration", status = "primary", solidHeader = TRUE, width = 4,
                tags$p(HTML(paste0(
                  "An <strong>option</strong> gives the buyer the right, but not the obligation, to buy (call) or ",
                  "sell (put) the underlying at the <strong>strike price</strong> on or before expiry, in exchange ",
                  "for a <strong>premium</strong> paid to the seller (writer). The four basic positions — long call, ",
                  "short call, long put, short put — each carry a distinct risk/reward profile."
                )), style = "font-size:12px; color:#444; line-height:1.6;"),
                radioButtons("optType", "Position:",
                             choices = c("Long Call (Bullish)"          = "long_call",
                                         "Short Call (Bearish/Neutral)" = "short_call",
                                         "Long Put (Bearish)"           = "long_put",
                                         "Short Put (Bullish/Neutral)"  = "short_put",
                                         "All Four Positions"           = "all_four"),
                             selected = "long_call"),
                numericInput("optStrike", "Strike Price:", value = 100, min = 0.01, step = 0.01),
                numericInput("optPremium", "Premium:", value = 5, min = 0.01, step = 0.01)
              ),
              box(
                title = "Payoff Diagram at Expiry", status = "primary", solidHeader = TRUE, width = 8,
                withSpinner(plotlyOutput("optionsPnLChart", height = "400px")),
                tags$p(paste0(
                  "Buying options (long call/long put) caps the maximum loss at the premium paid, while the seller ",
                  "on the other side of the trade carries the mirror-image, and typically larger, risk."
                ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
              )
            ),
            fluidRow(
              box(
                title = "Max Gain / Max Loss / Breakeven", status = "info", solidHeader = TRUE, width = 12,
                withSpinner(DT::dataTableOutput("optionsSummaryTable"))
              )
            )
          ),
          
          # -- Sub-tab: FX Fundamentals --
          tabPanel("FX Fundamentals",
            br(),
            fluidRow(
              box(
                title = "Pip Value & Margin Calculator", status = "primary", solidHeader = TRUE, width = 4,
                tags$p(HTML(paste0(
                  "Currency pairs are quoted <strong>XXX/YYY</strong>, where XXX (the base currency) is priced in ",
                  "units of YYY (the counter currency). A <strong>pip</strong> is typically the fourth decimal ",
                  "place (second for JPY pairs). Retail FX is highly <strong>leveraged</strong> — margin is the ",
                  "deposit required to control a much larger notional position."
                )), style = "font-size:12px; color:#444; line-height:1.6;"),
                selectInput("fxPair", "Currency Pair:",
                            choices = c("EUR/USD", "GBP/USD", "USD/JPY", "AUD/USD",
                                        "USD/CHF", "USD/CAD", "EUR/GBP", "EUR/JPY"),
                            selected = "EUR/USD"),
                selectInput("fxLotType", "Position Size:",
                            choices = c("Standard Lot (100,000)" = "100000",
                                        "Mini Lot (10,000)"      = "10000",
                                        "Micro Lot (1,000)"      = "1000"),
                            selected = "100000"),
                numericInput("fxLeverage", "Leverage (e.g. 100 = 100:1):", value = 100, min = 1, max = 500, step = 1)
              ),
              box(
                title = "Calculated Exposure", status = "info", solidHeader = TRUE, width = 8,
                uiOutput("fxCalcResult"),
                tags$p(paste0(
                  "Pip value depends on which currency is the counter (quote) currency of the pair. Margin required ",
                  "= Notional Value / Leverage. Higher leverage reduces the margin needed to control the same ",
                  "notional exposure, but increases the impact of adverse price moves on the account."
                ), style = "font-size:12px; color:#666; margin:14px 0 0 0; line-height:1.5;")
              )
            ),
            fluidRow(
              box(
                title = "Global Trading Sessions (GMT)", status = "primary", solidHeader = TRUE, width = 12,
                withSpinner(plotlyOutput("fxSessionChart", height = "380px")),
                tags$p(paste0(
                  "FX trades 24 hours a day as the Asian, European, and North American sessions hand over to one ",
                  "another. Overlapping sessions (e.g. London/New York) typically see the highest liquidity and ",
                  "volatility."
                ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
              )
            )
          )
        )
      ), # end tabItem derivatives
      
      # ── EXTENDED TECHNICAL INDICATORS TAB ─────────────────────────────────────
      tabItem(tabName = "extra_ta",
        
        fluidRow(
          box(
            width = 12, solidHeader = FALSE, status = "warning",
            div(style = "display:flex; align-items:flex-start; gap:14px;",
              icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
              div(
                tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
                tags$p(HTML(paste0(
                  "Implements the indicator formulae from the Technical Analysis Indicator Formulae reference ",
                  "manual that are not already covered on the Technical Indicators tab (which has RSI, MACD, and ",
                  "Stochastic). Every chart below is computed live from the asset currently selected in the sidebar."
                )), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
              )
            )
          )
        ),
        
        tabsetPanel(
          id = "extraTASubTabs", type = "tabs",
          
          # -- Sub-tab: Moving Averages --
          tabPanel("Moving Averages",
            br(),
            fluidRow(
              box(
                title = "Configuration", status = "primary", solidHeader = TRUE, width = 3,
                tags$p(HTML(paste0(
                  "<strong>SMA</strong> weights every price in the window equally. <strong>WMA</strong> applies ",
                  "linearly increasing weights, favouring recent prices. <strong>EMA</strong> applies exponentially ",
                  "decaying weights via EMA<sub>t</sub> = EMA<sub>t-1</sub> + (C<sub>t</sub> &minus; EMA<sub>t-1</sub>) ",
                  "&times; 2/(n+1), making it the most responsive of the three to new information."
                )), style = "font-size:12px; color:#444; line-height:1.6;"),
                numericInput("maPeriod", "Period (n):", value = 20, min = 2, max = 200, step = 1),
                checkboxGroupInput("maTypes", "Show:",
                                   choices = c("SMA" = "sma", "WMA" = "wma", "EMA" = "ema"),
                                   selected = c("sma", "wma", "ema"))
              ),
              box(
                title = "Moving Average Comparison", status = "primary", solidHeader = TRUE, width = 9,
                withSpinner(plotlyOutput("maComparisonChart", height = "450px")),
                tags$p(paste0(
                  "All three moving averages use the same lookback period, so any separation between the lines is ",
                  "purely a function of how they weight recent versus older prices. EMA typically hugs price most ",
                  "closely; SMA the least."
                ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
              )
            )
          ),
          
          # -- Sub-tab: Momentum & ROC --
          tabPanel("Momentum & ROC",
            br(),
            fluidRow(
              box(
                title = "Configuration", status = "primary", solidHeader = TRUE, width = 3,
                tags$p(HTML(paste0(
                  "<strong>Momentum(n)</strong> = C<sub>t</sub> &minus; C<sub>t-n</sub>. <strong>Rate of Change(n)</strong> ",
                  "= [Momentum(n) / C<sub>t-n</sub>] &times; 100 — the same idea expressed as a percentage, which ",
                  "makes it comparable across assets trading at very different price levels."
                )), style = "font-size:12px; color:#444; line-height:1.6;"),
                numericInput("momPeriod", "Period (n):", value = 10, min = 1, max = 100, step = 1)
              ),
              box(
                title = "Momentum & Rate of Change", status = "primary", solidHeader = TRUE, width = 9,
                withSpinner(plotlyOutput("momentumROCChart", height = "450px")),
                tags$p(paste0(
                  "Both oscillate around zero. Positive values indicate the price is higher than n periods ago ",
                  "(upward momentum); negative values indicate the price has fallen over the period."
                ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
              )
            )
          ),
          
          # -- Sub-tab: Volume (OBV) --
          tabPanel("Volume Indicators",
            br(),
            fluidRow(
              box(
                title = "About On-Balance Volume", status = "primary", solidHeader = TRUE, width = 12,
                tags$p(HTML(paste0(
                  "<strong>On-Balance Volume (OBV)</strong> is a cumulative total: today's volume is added if the ",
                  "close is higher than yesterday's, subtracted if lower, and unchanged if equal. ",
                  "<strong>Weighted OBV (WOBV)</strong> scales each day's contribution by the size of the price move ",
                  "(WOBV<sub>t</sub> = WOBV<sub>t-1</sub> + V<sub>t</sub> &times; (C<sub>t</sub> &minus; C<sub>t-1</sub>)), ",
                  "so a large price move on high volume carries proportionally more weight than a small move on the ",
                  "same volume. Both indicators aim to reveal whether volume is confirming or diverging from price."
                )), style = "font-size:12px; color:#444; line-height:1.6;")
              )
            ),
            fluidRow(
              box(
                title = "OBV & Weighted OBV", status = "primary", solidHeader = TRUE, width = 12,
                withSpinner(plotlyOutput("obvChart", height = "450px")),
                tags$p(paste0(
                  "If volume data is unavailable or zero for the selected asset (common for some futures and crypto ",
                  "feeds), OBV and WOBV will be flat and are not meaningful — try switching to an equity ticker."
                ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
              )
            )
          ),
          
          # -- Sub-tab: Parabolic SAR --
          tabPanel("Parabolic SAR",
            br(),
            fluidRow(
              box(
                title = "Configuration", status = "primary", solidHeader = TRUE, width = 3,
                tags$p(HTML(paste0(
                  "Wilder's <strong>Parabolic SAR</strong> (Stop and Reverse) trails price to flag potential trend ",
                  "reversals. SAR<sub>t</sub> = SAR<sub>t-1</sub> + &alpha;(EP &minus; SAR<sub>t-1</sub>), where EP is ",
                  "the Extreme Point of the current trend and &alpha; is an acceleration factor that increases each ",
                  "time a new extreme is reached, up to a maximum."
                )), style = "font-size:12px; color:#444; line-height:1.6;"),
                numericInput("sarAccelStart", "Acceleration Start:", value = 0.02, min = 0.01, max = 0.2, step = 0.01),
                numericInput("sarAccelMax", "Acceleration Max:", value = 0.2, min = 0.05, max = 0.5, step = 0.01)
              ),
              box(
                title = "Price with Parabolic SAR", status = "primary", solidHeader = TRUE, width = 9,
                withSpinner(plotlyOutput("sarChart", height = "450px")),
                tags$p(paste0(
                  "SAR dots plotted below price indicate an uptrend (potential long bias); dots above price indicate ",
                  "a downtrend. A flip from below to above price (or vice versa) is the 'stop and reverse' signal."
                ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
              )
            )
          ),
          
          # -- Sub-tab: Pivot Points --
          tabPanel("Pivot Points",
            br(),
            fluidRow(
              box(
                title = "About Pivot Points", status = "primary", solidHeader = TRUE, width = 12,
                tags$p(HTML(paste0(
                  "Pivot Points are calculated from the <em>previous</em> period's High, Low, and Close: ",
                  "PP = (H + L + C) / 3. Resistance levels R1&ndash;R3 sit above the pivot and support levels ",
                  "S1&ndash;S3 sit below it, giving a full map of likely intraday support/resistance for the next session."
                )), style = "font-size:12px; color:#444; line-height:1.6;")
              )
            ),
            fluidRow(
              box(
                title = "Pivot Levels (most recent completed session)", status = "info", solidHeader = TRUE, width = 4,
                withSpinner(DT::dataTableOutput("pivotPointsTable"))
              ),
              box(
                title = "Recent Price vs Pivot Levels", status = "primary", solidHeader = TRUE, width = 8,
                withSpinner(plotlyOutput("pivotPointsChart", height = "420px")),
                tags$p(paste0(
                  "The last 30 sessions of closing price plotted against the pivot, resistance, and support levels ",
                  "derived from the most recently completed session."
                ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
              )
            )
          )
        )
      ), # end tabItem extra_ta
      
      # ── TRADER PSYCHOLOGY & MACRO CALENDAR TAB ────────────────────────────────
      tabItem(tabName = "psych_macro",
        
        tabsetPanel(
          id = "psychMacroSubTabs", type = "tabs",
          
          # -- Sub-tab: Ten Steps --
          tabPanel("Ten Steps to Successful Trading",
            br(),
            fluidRow(
              box(
                width = 12, solidHeader = TRUE, status = "primary",
                title = "Ten Steps to Becoming a Successful Trader",
                tags$p("Reference: London Academy of Trading — Ten Steps to Becoming a Successful Trader.",
                       style = "font-size:12px; color:#888; font-style:italic; margin-bottom:16px;"),
                uiOutput("tenStepsUI")
              )
            )
          ),
          
          # -- Sub-tab: Macro Calendar --
          tabPanel("US Macro Calendar",
            br(),
            fluidRow(
              box(
                width = 12, solidHeader = FALSE, status = "warning",
                div(style = "display:flex; align-items:flex-start; gap:14px;",
                  icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
                  div(
                    tags$strong("About this table:", style = "color:#7d4a00; font-size:14px;"),
                    tags$p(paste0(
                      "Reference data reproduced from the US Macro Crib Sheet, covering the highest-impact scheduled ",
                      "US economic releases. Expected outcomes are general historical tendencies, subject to prevailing ",
                      "financial conditions and monetary policy stance — not a guaranteed reaction."
                    ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
                  )
                )
              )
            ),
            fluidRow(
              box(
                title = "Reaction Simulator", status = "primary", solidHeader = TRUE, width = 4,
                selectInput("macroIndicator", "Select Release:", choices = NULL),
                radioButtons("macroDirection", "Scenario:",
                             choices = c("Actual beats Forecast"  = "beat",
                                         "Actual misses Forecast" = "miss"),
                             selected = "beat"),
                uiOutput("macroReactionResult")
              ),
              box(
                title = "Full Calendar Reference", status = "info", solidHeader = TRUE, width = 8,
                withSpinner(DT::dataTableOutput("macroCalendarTable"))
              )
            )
          )
        )
      ), # end tabItem psych_macro
      
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
      ),
      
      # Volatility Analysis Tab
      tabItem(tabName = "volatility",
              fluidRow(
                box(
                  title = "Volatility Analysis Controls", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  
                  radioButtons("volatilityType", "Volatility Method:",
                               choices = c("Realized (Close-to-Close)" = "realized",
                                           "Parkinson (High-Low)" = "parkinson",
                                           "Garman-Klass (OHLC)" = "gk"),
                               selected = "realized"),
                  
                  numericInput("volWindow", "Rolling Window:",
                               value = 30, min = 10, max = 252),
                  
                  sliderInput("volConfidence", "Confidence Level:",
                              min = 90, max = 99, value = 95),
                  
                  checkboxInput("annualizeVol", "Annualize Volatility", TRUE),
                  
                  br(),
                  h5("Volatility Metrics:"),
                  verbatimTextOutput("volatilityMetrics")
                ),
                
                box(
                  title = "Volatility Time Series", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 8,
                  withSpinner(plotlyOutput("volatilityChart", height = "450px")),
                  tags$p(paste0(
                    "Rolling volatility of the selected asset computed using the chosen method and window. ",
                    "The central line is the rolling estimate; the dashed upper and lower bands mark the ",
                    "confidence interval around the historical average. Peaks in this chart identify periods ",
                    "of elevated market stress. Sustained readings near the upper band suggest a high-volatility ",
                    "regime; readings near the lower band suggest a calm, low-risk environment."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Volatility Distribution", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("volatilityDist", height = "350px")),
                  tags$p(paste0(
                    "Histogram of all rolling volatility readings over the full history. A narrow, tall ",
                    "distribution means the asset spends most of its time at a consistent volatility level. ",
                    "A wide, flat distribution indicates highly variable volatility regimes. A right skew ",
                    "means occasional spikes to very high volatility are common, which is typical of crypto ",
                    "and commodity markets."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Volatility Clustering", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("volatilityClustering", height = "350px")),
                  tags$p(paste0(
                    "Absolute daily returns plotted as a time series. Volatility clustering is visible when ",
                    "tall spikes appear in groups rather than randomly distributed across time. This autocorrelation ",
                    "in volatility is the empirical basis for GARCH models and means that a volatile period today ",
                    "is statistically likely to be followed by another volatile period tomorrow."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Volatility Regime Analysis", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(plotlyOutput("volatilityRegimes", height = "300px")),
                  tags$p(paste0(
                    "Each observation is colour-coded into one of three volatility regimes based on historical ",
                    "percentile thresholds: Low (below the 25th percentile, green), Normal (between the 25th and ",
                    "75th percentile, blue), and High (above the 75th percentile, red). This chart makes it ",
                    "immediately clear which periods were unusually calm or turbulent and whether the asset is ",
                    "currently in an elevated-risk regime."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              )
      ),
      
      # Risk Metrics Tab
      tabItem(tabName = "risk",
              fluidRow(
                box(
                  title = "Risk Analysis Settings", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  
                  numericInput("portfolioValue", "Portfolio Value (USD):",
                               value = 1000000, min = 10000, max = 100000000, step = 10000),
                  
                  sliderInput("confidenceLevel", "VaR Confidence (%):",
                              min = 90, max = 99.5, value = 95, step = 0.5),
                  
                  numericInput("timeHorizon", "Time Horizon (days):",
                               value = 1, min = 1, max = 30),
                  
                  radioButtons("varMethod", "VaR Method:",
                               choices = c("Historical" = "historical",
                                           "Parametric" = "parametric",
                                           "Cornish-Fisher" = "modified"),
                               selected = "historical"),
                  
                  numericInput("varWindow", "VaR Window:",
                               value = 250, min = 100, max = 1000),
                  
                  br(),
                  h5("Risk Summary:"),
                  verbatimTextOutput("riskMetrics")
                ),
                
                box(
                  title = "Value at Risk Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 8,
                  withSpinner(plotlyOutput("varChart", height = "450px")),
                  tags$p(paste0(
                    "The red line shows the rolling Value at Risk in dollar terms for the configured portfolio size ",
                    "and confidence level. Blue bars represent the actual daily P&L. Any blue bar that extends ",
                    "below the red VaR line is a VaR breach, meaning the actual loss on that day exceeded the ",
                    "model's prediction. Under a 95% confidence level, you would statistically expect approximately ",
                    "one breach every 20 trading sessions."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Expected Shortfall", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("expectedShortfall", height = "350px")),
                  tags$p(paste0(
                    "Expected Shortfall (also called CVaR or Conditional Value at Risk) measures the average ",
                    "loss on the worst days beyond the VaR threshold. While VaR answers 'how bad could it get?', ",
                    "Expected Shortfall answers 'when things go wrong, how bad does it actually get on average?'. ",
                    "A rising ES line indicates that tail-event severity is increasing, even if the frequency of ",
                    "breaches remains the same."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Drawdown Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("drawdownAnalysis", height = "350px")),
                  tags$p(paste0(
                    "The drawdown chart shows how far the asset has fallen below its most recent all-time high ",
                    "at each point in time, expressed as a percentage. The shaded area fills the space between ",
                    "zero (at a new high) and the current underwater position. The depth of each trough is the ",
                    "maximum drawdown for that period; the width of the trough indicates how long recovery took. ",
                    "Frequent deep troughs characterise high-risk assets."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Risk Statistics", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(DT::dataTableOutput("riskStatsTable")),
                  tags$p(paste0(
                    "A consolidated table of key risk and performance statistics for the asset over the VaR window. ",
                    "Mean Return and Volatility are both time-horizon-adjusted. Sharpe Ratio above 1 is generally ",
                    "considered good; above 2 is very strong. Sortino Ratio above 1 is healthy. Max Loss and Max Gain ",
                    "are the single worst and best sessions within the window."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Stress Testing", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(DT::dataTableOutput("stressTestResults")),
                  tags$p(paste0(
                    "Hypothetical stress scenarios applied to the configured portfolio value. Each row multiplies ",
                    "a multiple of the historical daily volatility by the portfolio size to estimate the dollar ",
                    "impact. A 2-sigma event occurs roughly 4.5% of trading days; a 4-sigma event is extremely rare ",
                    "under a normal distribution but observed more frequently in financial markets due to fat tails."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              )
      ),
      
      # Advanced Metrics Tab (NEW)
      tabItem(tabName = "advanced",
              fluidRow(
                valueBoxOutput("sharpeRatioBox", width = 3),
                valueBoxOutput("sortinoRatioBox", width = 3),
                valueBoxOutput("calmarRatioBox", width = 3),
                valueBoxOutput("omegaRatioBox", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Advanced Metrics Configuration",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           numericInput("riskFreeRate", "Risk-Free Rate (%):",
                                        value = 4.5, min = 0, max = 10, step = 0.1)
                    ),
                    column(3,
                           numericInput("targetReturn", "Target Return for Omega/Downside Dev (%):",
                                        value = 0, min = -10, max = 20, step = 0.5)
                    ),
                    column(3,
                           numericInput("rollingWindow", "Rolling Window (days):",
                                        value = 50, min = 30, max = 500, step = 10)
                    ),
                    column(3,
                           checkboxInput("annualizeMetrics", "Annualize Metrics", TRUE)
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Risk-Adjusted Performance Metrics",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  withSpinner(DT::dataTableOutput("advancedMetricsTable")),
                  tags$p(paste0(
                    "Comprehensive table of risk-adjusted metrics computed over the full data history. ",
                    "Downside Deviation measures volatility on losing days only. Upside Potential Ratio compares ",
                    "average gains to downside deviation. Max Drawdown is the largest peak-to-trough decline. ",
                    "Annualised Return and Volatility are scaled to a 252 trading-day year for comparability ",
                    "across assets with different data lengths."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Rolling Sharpe Ratio",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("rollingSharpeChart", height = "400px")),
                  tags$p(paste0(
                    "The Sharpe Ratio computed over a rolling window of the configured length. Periods above zero ",
                    "indicate the asset is generating excess return above the risk-free rate per unit of risk. ",
                    "A trend from negative to positive Sharpe suggests improving risk-adjusted performance. ",
                    "Sharp drops identify periods where drawdowns overwhelmed returns relative to volatility."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Rolling Sortino Ratio",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("rollingSortinoChart", height = "400px")),
                  tags$p(paste0(
                    "The Sortino Ratio computed over a rolling window. Unlike the Sharpe, it only penalises ",
                    "downside volatility below the target return. This makes it a more appropriate metric for ",
                    "assets like crypto or commodities that can have large upside spikes alongside large drawdowns. ",
                    "A Sortino consistently above the Sharpe indicates the asset's volatility is predominantly upside."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Downside Risk Analysis",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("downsideRiskChart", height = "350px")),
                  tags$p(paste0(
                    "Focuses exclusively on the distribution and magnitude of negative return sessions. ",
                    "This chart reveals the frequency and depth of losing days, helping quantify the left-tail ",
                    "risk profile of the asset independently from upside volatility."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Upside vs Downside Capture",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("upsideDownsideChart", height = "350px")),
                  tags$p(paste0(
                    "Compares the asset's participation in positive versus negative market moves. ",
                    "An asset that captures more of the upside than the downside is considered asymmetrically ",
                    "attractive. A ratio greater than 1 on the upside and less than 1 on the downside is the ",
                    "ideal profile for a long-only investor."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Maximum Drawdown Details",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("maxDrawdownDetailChart", height = "350px")),
                  tags$p(paste0(
                    "Detailed view of the maximum drawdown episode: the full path from the prior peak, through ",
                    "the trough, and the subsequent recovery. The depth of the trough shows the maximum capital ",
                    "loss an investor holding through the period would have experienced before recovery began."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Recovery Period Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(DT::dataTableOutput("recoveryPeriodTable")),
                  tags$p(paste0(
                    "Table of significant drawdown episodes with their start date, trough date, recovery date, ",
                    "maximum depth, and recovery duration in trading days. Longer recovery periods indicate ",
                    "more persistent damage to the investment. Assets with short recovery periods are considered ",
                    "more resilient to drawdowns."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              )
      ),
      
      # Hedging Strategies Tab (NEW)
      tabItem(tabName = "hedging",
              fluidRow(
                box(
                  width = 12, solidHeader = FALSE, status = "warning",
                  div(style = "display:flex; align-items:flex-start; gap:14px;",
                    icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
                    div(
                      tags$strong("How to use this tab:", style = "color:#7d4a00; font-size:14px;"),
                      tags$p(HTML(paste0(
                        "1. Ensure you have selected your primary asset from the sidebar (e.g. Bitcoin or Gold). ",
                        "2. In the configuration panel on the left, choose a <strong>Hedge Instrument</strong> to hedge against ",
                        "(e.g. S&P 500 or Gold). ",
                        "3. Set the <strong>Initial Hedge Ratio</strong>, <strong>Rebalance Frequency</strong>, ",
                        "<strong>Hedge Method</strong>, and <strong>Lookback Period</strong> as required. ",
                        "4. Click the <strong>Run Hedge Analysis</strong> button to load the hedge instrument data and ",
                        "generate all charts and metrics below."
                      )), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Hedging Strategy Configuration",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  
                  selectInput("hedgeAsset", "Hedge Against:",
                              choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                          "Ethereum (ETH-USD)" = "ETH-USD",
                                          "Gold (GC=F)" = "GC=F",
                                          "Crude Oil (CL=F)" = "CL=F",
                                          "S&P 500 (^GSPC)" = "^GSPC"),
                              selected = "^GSPC"),
                  
                  numericInput("hedgeRatio", "Initial Hedge Ratio:",
                               value = 1.0, min = 0.1, max = 2.0, step = 0.1),
                  
                  numericInput("rebalanceFreq", "Rebalance Frequency (days):",
                               value = 30, min = 1, max = 90, step = 1),
                  
                  radioButtons("hedgeMethod", "Hedge Method:",
                               choices = c("Static Hedge" = "static",
                                           "Dynamic (Correlation-based)" = "dynamic",
                                           "Beta-Adjusted" = "beta",
                                           "Minimum Variance" = "minvar"),
                               selected = "dynamic"),
                  
                  numericInput("hedgeLookback", "Lookback Period (days):",
                               value = 60, min = 20, max = 250, step = 10),
                  
                  actionButton("runHedgeAnalysis", "Run Hedge Analysis", 
                               class = "btn-primary", width = "100%")
                ),
                
                box(
                  title = "Hedging Effectiveness Summary",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  fluidRow(
                    column(6,
                           h5("Without Hedge:"),
                           verbatimTextOutput("unhedgedStats")
                    ),
                    column(6,
                           h5("With Hedge:"),
                           verbatimTextOutput("hedgedStats")
                    )
                  ),
                  tags$p(paste0(
                    "Side-by-side comparison of the unhedged versus hedged portfolio statistics after clicking ",
                    "Run Hedge Analysis. Key metrics to compare are Volatility (a lower hedged volatility confirms ",
                    "the hedge is reducing risk) and Return (the cost of the hedge is visible as any reduction in ",
                    "return). An effective hedge significantly reduces volatility at an acceptable cost to return."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Portfolio Performance: Hedged vs Unhedged",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  withSpinner(plotlyOutput("hedgePerformanceChart", height = "500px")),
                  tags$p(paste0(
                    "Cumulative return of the unhedged position (holding the primary asset alone) plotted against ",
                    "the hedged portfolio (primary asset combined with the hedge instrument at the configured ratio). ",
                    "The gap between the two lines reveals the cost or benefit of the hedge at each point in time. ",
                    "A good hedge reduces the depth and duration of drawdowns even if it modestly reduces peak returns."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Rolling Hedge Ratio",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("hedgeRatioChart", height = "350px")),
                  tags$p(paste0(
                    "For dynamic hedge methods, this chart shows how the optimal hedge ratio changes over time. ",
                    "A rising ratio means a larger position in the hedge instrument is required to offset the ",
                    "primary asset's risk. Significant variation in the ratio over time indicates the relationship ",
                    "between the two assets is unstable, which is an important consideration for practical implementation."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Rolling Correlation",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("hedgeCorrelationChart", height = "350px")),
                  tags$p(paste0(
                    "The rolling correlation between the primary asset and the hedge instrument. A consistently ",
                    "negative correlation confirms the hedge instrument moves in the opposite direction to the ",
                    "primary asset, providing effective protection. Correlation drifting towards zero or positive ",
                    "values signals that the hedge is losing its effectiveness."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Hedge Effectiveness Metrics",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(DT::dataTableOutput("hedgeEffectivenessTable")),
                  tags$p(paste0(
                    "Quantitative measures of how well the hedge performed over the analysis period. ",
                    "Variance Reduction shows the percentage reduction in portfolio variance achieved by the hedge. ",
                    "Hedge Ratio Stability measures consistency of the optimal ratio over time. ",
                    "Higher values in these metrics indicate a more effective and reliable hedging relationship."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Beta Analysis",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("betaAnalysisChart", height = "350px")),
                  tags$p(paste0(
                    "Rolling beta of the primary asset relative to the hedge instrument. A beta of 1 means the ",
                    "asset moves in lockstep with the hedge; above 1 means it is more sensitive; below 1 means less. ",
                    "Negative beta confirms an inverse relationship. The beta is used directly as the hedge multiplier ",
                    "when the Beta-Adjusted method is selected."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Cost-Benefit Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  withSpinner(DT::dataTableOutput("hedgeCostBenefitTable")),
                  tags$p(paste0(
                    "Estimates the return given up to implement the hedge (the cost) against the volatility or ",
                    "drawdown reduction achieved (the benefit). The cost-benefit ratio answers directly whether the ",
                    "hedge is economically worthwhile: a ratio below 1 means the reduction in risk exceeds the ",
                    "reduction in return, indicating an efficient hedge."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              )
      ),
      
      # Composite Analysis Tab
      tabItem(tabName = "composite",
              fluidRow(
                box(
                  width = 12, solidHeader = FALSE, status = "warning",
                  div(style = "display:flex; align-items:flex-start; gap:14px;",
                    icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
                    div(
                      tags$strong("How to use this tab:", style = "color:#7d4a00; font-size:14px;"),
                      tags$p(HTML(paste0(
                        "1. Tick two or more assets from the <strong>Select Assets to Compare</strong> checklist ",
                        "(you may select across all three asset classes simultaneously). ",
                        "2. Set the <strong>Analysis Period</strong> date range to the window you wish to examine. ",
                        "3. Choose a <strong>Normalisation</strong> method: Index (Base 100) is recommended for ",
                        "comparing returns across assets with very different price levels. ",
                        "4. Click the <strong>Run Analysis</strong> button to fetch data for all selected assets and ",
                        "populate the comparison charts, correlation heatmap, risk-return scatter, and class summary panels below."
                      )), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Composite Analysis Settings", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  fluidRow(
                    column(4,
                           h5("Compare Multiple Assets:"),
                           checkboxGroupInput("compositeAssets", "Select Assets to Compare:",
                                              choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                                          "Ethereum (ETH-USD)" = "ETH-USD",
                                                          "Cardano (ADA-USD)" = "ADA-USD",
                                                          "NVIDIA (NVDA)" = "NVDA",
                                                          "Microsoft (MSFT)" = "MSFT",
                                                          "Apple (AAPL)" = "AAPL",
                                                          "Gold (GC=F)" = "GC=F",
                                                          "Crude Oil (CL=F)" = "CL=F",
                                                          "Natural Gas (NG=F)" = "NG=F"),
                                              selected = c("BTC-USD", "NVDA", "GC=F"))
                    ),
                    column(4,
                           h5("Analysis Period:"),
                           dateRangeInput("compositeRange", NULL,
                                          start = Sys.Date() - months(12),
                                          end = Sys.Date())
                    ),
                    column(4,
                           h5("Normalization:"),
                           radioButtons("normalizeMethod", NULL,
                                        choices = c("Index (Base 100)" = "index",
                                                    "Percentage Returns" = "returns",
                                                    "Raw Prices" = "raw"),
                                        selected = "index"),
                           actionButton("runComposite", "Run Analysis", 
                                        class = "btn-primary", width = "100%")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Comparative Performance Chart", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(plotlyOutput("compositePerformance", height = "500px")),
                  tags$p(paste0(
                    "All selected assets plotted together on a common scale determined by the chosen normalisation. ",
                    "Index (Base 100) mode is most useful for comparing returns: an asset at 130 has returned 30% ",
                    "since the start of the period regardless of its raw price level. Use this chart to identify ",
                    "which assets led and which lagged over the period, and to spot divergences where one asset ",
                    "decoupled from the others."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Correlation Heatmap", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotOutput("compositeCorrelation", height = "400px")),
                  tags$p(paste0(
                    "Pairwise return correlations between all selected assets over the analysis period. ",
                    "Dark blue cells indicate high positive correlation (assets move together). Dark red cells ",
                    "indicate negative correlation (assets move in opposite directions, providing diversification). ",
                    "Values near zero (white) indicate independence. Assets from different classes typically show ",
                    "lower correlations, confirming the diversification benefit of cross-class portfolios."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Risk-Return Scatter", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("riskReturnScatter", height = "400px")),
                  tags$p(paste0(
                    "Each dot represents one of the selected assets. The horizontal axis is annualised volatility ",
                    "(risk); the vertical axis is annualised return. Assets in the upper-left quadrant offer the ",
                    "best risk-adjusted profile: high return for low risk. Assets in the lower-right quadrant ",
                    "are the least efficient. The diagonal from lower-left to upper-right represents a consistent ",
                    "risk-return trade-off."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Performance Metrics Comparison", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(DT::dataTableOutput("compositeMetrics")),
                  tags$p(paste0(
                    "Side-by-side table of key metrics for every selected asset over the analysis period, ",
                    "including annualised return, volatility, Sharpe Ratio, and maximum drawdown. ",
                    "Sort any column to identify which asset ranks best on each dimension."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                ),
                box(
                  title = "Rolling Correlations", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("rollingCorrelations", height = "350px")),
                  tags$p(paste0(
                    "The 60-day rolling correlation between the first two selected assets over time. ",
                    "Stable correlations indicate a reliable long-run relationship. Rising correlation during ",
                    "market stress is a well-documented phenomenon and means diversification benefits can ",
                    "disappear exactly when they are most needed."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Asset Class Comparison", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  fluidRow(
                    column(3,
                           h5("Crypto Average Performance:"),
                           verbatimTextOutput("cryptoSummary")
                    ),
                    column(3,
                           h5("Equity Average Performance:"),
                           verbatimTextOutput("equitySummary")
                    ),
                    column(3,
                           h5("Commodity Average Performance:"),
                           verbatimTextOutput("commoditySummary")
                    ),
                    column(3,
                           h5("Class Comparison:"),
                           verbatimTextOutput("classComparison")
                    )
                  ),
                  tags$p(paste0(
                    "Average return and volatility grouped by asset class across all selected instruments. ",
                    "This panel is only populated for asset classes where at least one instrument has been ",
                    "selected. The Class Comparison column identifies the best-performing class by average return ",
                    "and the highest-volatility class, providing a top-level summary of cross-class dynamics ",
                    "in the selected period."
                  ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
                )
              )
      ), # end composite tabItem
      
      # ── FEEDBACK TAB ────────────────────────────────────────────────────────
      tabItem(tabName = "feedback",
        
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "primary", title = NULL,
            div(
              style = paste0(
                "background:linear-gradient(135deg,#002C3C 0%,#005f5a 60%,#00A39A 100%);",
                "border-radius:10px; padding:32px 36px; color:#ffffff; text-align:center;"
              ),
              icon("envelope-open-text", style = "font-size:52px; color:#7fffd4; margin-bottom:16px;"),
              tags$h2("We Would Love to Hear from You",
                style = "font-size:26px; font-weight:700; color:#ffffff; margin:0 0 10px 0;"),
              tags$p(HTML(paste0(
                "Your feedback is invaluable in helping us improve the Atera Analytics platform. ",
                "Whether you have suggestions for new features, additional asset classes or instruments, ",
                "improvements to existing analytics, or you are interested in a bespoke version of this application ",
                "tailored to your organisation, we want to hear from you.")),
                style = "font-size:15px; color:#d0f0ec; line-height:1.7; max-width:700px; margin:0 auto 24px auto;"),
              tags$a(
                href = "mailto:admin@atera-analytics.co.uk",
                HTML(paste0(
                  "<span style='font-size:20px; font-weight:700; color:#7fffd4;'>",
                  "admin@atera-analytics.co.uk</span>"
                )),
                style = paste0(
                  "display:inline-block; background:rgba(255,255,255,0.12); ",
                  "border:2px solid #7fffd4; border-radius:8px; ",
                  "padding:14px 32px; text-decoration:none;"
                )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            width = 4, solidHeader = TRUE, status = "primary",
            title = tagList(icon("lightbulb"), " Feature Suggestions"),
            tags$p(paste0(
              "Tell us which additional asset classes, instruments, or analytical modules you would find most ",
              "valuable. We are actively developing extensions to this platform including additional equity markets, ",
              "FX pairs, fixed income, and alternative assets."
            ), style = "font-size:13px; color:#444; line-height:1.6;"),
            tags$p(HTML(paste0(
              "Write to: <a href='mailto:admin@atera-analytics.co.uk' style='color:#008A82; font-weight:600;'>",
              "admin@atera-analytics.co.uk</a>"
            )), style = "font-size:13px; margin-top:12px;")
          ),
          box(
            width = 4, solidHeader = TRUE, status = "primary",
            title = tagList(icon("robot"), " AI and Algorithmic Trading"),
            tags$p(paste0(
              "Atera Analytics has the full capability to extend this platform into automated algorithmic ",
              "trading systems, AI-driven signal generation, and bespoke quantitative tools. If your organisation ",
              "is exploring these capabilities, we would be delighted to discuss how we can help."
            ), style = "font-size:13px; color:#444; line-height:1.6;"),
            tags$p(HTML(paste0(
              "Write to: <a href='mailto:admin@atera-analytics.co.uk' style='color:#008A82; font-weight:600;'>",
              "admin@atera-analytics.co.uk</a>"
            )), style = "font-size:13px; margin-top:12px;")
          ),
          box(
            width = 4, solidHeader = TRUE, status = "primary",
            title = tagList(icon("bug"), " Bug Reports and Improvements"),
            tags$p(paste0(
              "If you encounter any unexpected behaviour, errors, or charts that do not display as expected, ",
              "please let us know. Include the asset class and specific instrument you were analysing and a brief ",
              "description of what you observed. We aim to respond promptly."
            ), style = "font-size:13px; color:#444; line-height:1.6;"),
            tags$p(HTML(paste0(
              "Write to: <a href='mailto:admin@atera-analytics.co.uk' style='color:#008A82; font-weight:600;'>",
              "admin@atera-analytics.co.uk</a>"
            )), style = "font-size:13px; margin-top:12px;")
          )
        ),
        
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "info",
            title = "About Atera Analytics",
            fluidRow(
              column(8,
                tags$p(HTML(paste0(
                  "Atera Analytics is an entrepreneurial platform founded by ",
                  "<strong>Joseph Francisco Zubizarreta</strong>, MBA Alumni of the ",
                  "<strong>Judge Business School, University of Cambridge</strong>. ",
                  "The platform is dedicated to making complex, production-grade analytical applications ",
                  "accessible to domain experts across finance, investment management, and quantitative research. ",
                  "This multi-asset analytics suite is one of several applications developed under the Atera Analytics umbrella, ",
                  "with a growing portfolio of tools spanning financial markets, autonomous vehicle analytics, ",
                  "and AI-powered enterprise applications."
                )), style = "font-size:14px; color:#444; line-height:1.7; margin:0;")
              ),
              column(4,
                div(style = paste0(
                  "background:linear-gradient(135deg,#002C3C,#008A82);",
                  "border-radius:8px; padding:20px; text-align:center; color:#fff;"
                ),
                  icon("envelope", style = "font-size:28px; color:#7fffd4; margin-bottom:10px;"),
                  tags$h5("Get in Touch", style = "color:#fff; font-weight:700; margin:0 0 8px 0;"),
                  tags$a(
                    "admin@atera-analytics.co.uk",
                    href = "mailto:admin@atera-analytics.co.uk",
                    style = "color:#7fffd4; font-size:13px; font-weight:600; text-decoration:none;"
                  )
                )
              )
            )
          )
        )
        
      ) # end tabItem feedback
      
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
    composite_data = NULL,
    hedge_data = NULL,
    hedge_results = NULL
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
  
  # Get current asset symbol
  current_asset <- reactive({
    if (input$assetClass == "crypto") {
      return(input$cryptoAsset)
    } else if (input$assetClass == "equity") {
      return(input$equityAsset)
    } else {
      return(input$commodityAsset)
    }
  })
  
  # Load data when asset selection changes or refresh is clicked.
  # Uses list() not c() to ensure both reactives trigger reliably on shinyapps.io.
  # Retries once on failure to handle transient Yahoo Finance rate-limits.
  observeEvent(list(current_asset(), input$refreshData), {
    showNotification("Fetching data...", type = "message", duration = 2)
    
    symbol <- current_asset()
    data   <- fetch_asset_data(symbol)
    
    # One automatic retry after a short pause (handles transient Yahoo 429s)
    if (is.null(data)) {
      Sys.sleep(2)
      data <- fetch_asset_data(symbol)
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
               ". Yahoo Finance may be temporarily unavailable — please try Refresh."),
        type = "error", duration = 8
      )
    }
  }, ignoreNULL = FALSE)
  
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
  
  output$volatilityMetrics <- renderText({
    req(values$asset_data)
    data <- values$asset_data %>% tail(500)
    
    returns <- data$returns[!is.na(data$returns)]
    
    if (length(returns) < input$volWindow) return("Insufficient data")
    
    current_vol <- sd(tail(returns, input$volWindow))
    if (input$annualizeVol) current_vol <- current_vol * sqrt(252)
    
    all_vol <- sd(returns)
    if (input$annualizeVol) all_vol <- all_vol * sqrt(252)
    
    vol_unit <- ifelse(input$annualizeVol, "% (ann.)", "% (daily)")
    
    paste(
      paste("Current Volatility:", round(current_vol * 100, 3), vol_unit),
      paste("Historical Avg:", round(all_vol * 100, 3), vol_unit),
      paste("Data Points:", length(returns)),
      sep = "\n"
    )
  })
  
  output$volatilityChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(1000)
    
    returns <- data$returns
    
    if (sum(!is.na(returns)) < input$volWindow) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
    if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
    
    vol_mean <- mean(rolling_vol, na.rm = TRUE)
    vol_sd <- sd(rolling_vol, na.rm = TRUE)
    confidence_mult <- qnorm((100 + input$volConfidence) / 200)
    
    plot_data <- data.frame(
      Date = data$Date,
      vol = rolling_vol,
      upper = vol_mean + confidence_mult * vol_sd,
      lower = pmax(0, vol_mean - confidence_mult * vol_sd)
    ) %>% filter(!is.na(vol))
    
    plot_ly(plot_data, x = ~Date) %>%
      add_lines(y = ~vol * 100, name = "Volatility", line = list(color = "#2c3e50", width = 2)) %>%
      add_lines(y = ~upper * 100, name = "Upper Band", line = list(color = "#e74c3c", dash = "dash")) %>%
      add_lines(y = ~lower * 100, name = "Lower Band", line = list(color = "#27ae60", dash = "dash")) %>%
      layout(
        title = paste("Volatility Analysis -", current_asset()),
        xaxis = list(title = "Date"),
        yaxis = list(title = ifelse(input$annualizeVol, "Ann. Volatility (%)", "Daily Vol (%)")),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$volatilityDist <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data
    
    returns <- data$returns[!is.na(data$returns)]
    rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
    if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
    
    vol_data <- rolling_vol[!is.na(rolling_vol)]
    
    if (length(vol_data) < 20) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    plot_ly(x = vol_data * 100, type = "histogram", nbinsx = 30,
            marker = list(color = "#3498db", opacity = 0.7)) %>%
      layout(
        title = "Volatility Distribution",
        xaxis = list(title = ifelse(input$annualizeVol, "Ann. Vol (%)", "Daily Vol (%)")),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$volatilityClustering <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(500) %>% filter(!is.na(returns))
    
    if (nrow(data) < 20) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    data$abs_returns <- abs(data$returns) * 100
    
    plot_ly(data, x = ~Date, y = ~abs_returns, type = "scatter", mode = "lines",
            line = list(color = "#e74c3c", width = 1.5)) %>%
      layout(
        title = "Volatility Clustering",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Absolute Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$volatilityRegimes <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data
    
    returns <- data$returns[!is.na(data$returns)]
    rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
    if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
    
    vol_25 <- quantile(rolling_vol, 0.25, na.rm = TRUE)
    vol_75 <- quantile(rolling_vol, 0.75, na.rm = TRUE)
    
    regime_data <- data.frame(
      Date = tail(data$Date, length(rolling_vol)),
      vol = rolling_vol,
      regime = ifelse(rolling_vol <= vol_25, "Low",
                      ifelse(rolling_vol >= vol_75, "High", "Normal"))
    ) %>% filter(!is.na(vol))
    
    colors <- c("Low" = "#27ae60", "Normal" = "#3498db", "High" = "#e74c3c")
    
    plot_ly(regime_data, x = ~Date, y = ~vol * 100, color = ~regime, colors = colors,
            type = "scatter", mode = "markers") %>%
      layout(
        title = "Volatility Regimes",
        xaxis = list(title = "Date"),
        yaxis = list(title = ifelse(input$annualizeVol, "Ann. Vol (%)", "Daily Vol (%)")),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # RISK METRICS OUTPUTS
  
  output$riskMetrics <- renderText({
    req(values$asset_data)
    data <- values$asset_data %>% tail(input$varWindow)
    
    returns <- data$returns[!is.na(data$returns)]
    
    if (length(returns) < 30) return("Insufficient data")
    
    adjusted_returns <- returns * sqrt(input$timeHorizon)
    var_percentile <- (100 - input$confidenceLevel) / 100
    
    if (input$varMethod == "historical") {
      var_value <- quantile(adjusted_returns, var_percentile)
    } else {
      mean_ret <- mean(adjusted_returns)
      sd_ret <- sd(adjusted_returns)
      var_value <- mean_ret + qnorm(var_percentile) * sd_ret
    }
    
    var_dollar <- abs(var_value) * input$portfolioValue
    
    sharpe <- mean(returns) / sd(returns) * sqrt(252)
    
    paste(
      paste("Portfolio:", paste0("$", format(input$portfolioValue, big.mark = ","))),
      paste("Time Horizon:", input$timeHorizon, "day(s)"),
      "",
      paste("VaR:", paste0("$", format(round(var_dollar, 0), big.mark = ","))),
      paste("VaR %:", paste0(round(var_dollar / input$portfolioValue * 100, 3), "%")),
      paste("Sharpe Ratio:", round(sharpe, 3)),
      sep = "\n"
    )
  })
  
  output$varChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(min(1000, nrow(values$asset_data)))
    
    returns <- data$returns
    var_percentile <- (100 - input$confidenceLevel) / 100
    window_size <- min(input$varWindow, sum(!is.na(returns)) - 50)
    
    if (window_size < 50) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rolling_var <- rollapply(returns, window_size,
                             function(x) quantile(x * sqrt(input$timeHorizon), var_percentile, na.rm = TRUE),
                             fill = NA, align = "right")
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(rolling_var)),
      var_value = abs(rolling_var) * input$portfolioValue,
      daily_pnl = tail(returns, length(rolling_var)) * sqrt(input$timeHorizon) * input$portfolioValue
    ) %>% filter(!is.na(var_value))
    
    plot_ly(plot_data, x = ~Date) %>%
      add_lines(y = ~var_value, name = "VaR", line = list(color = "#e74c3c", width = 2)) %>%
      add_bars(y = ~daily_pnl, name = "Daily P&L", marker = list(color = "#3498db")) %>%
      layout(
        title = "Value at Risk",
        xaxis = list(title = "Date"),
        yaxis = list(title = "USD"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$expectedShortfall <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(800)
    
    returns <- data$returns
    var_percentile <- (100 - input$confidenceLevel) / 100
    window_size <- min(input$varWindow, sum(!is.na(returns)) - 50)
    
    if (window_size < 50) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rolling_es <- rollapply(returns, window_size,
                            function(x) {
                              adj_ret <- x * sqrt(input$timeHorizon)
                              var_threshold <- quantile(adj_ret, var_percentile, na.rm = TRUE)
                              mean(adj_ret[adj_ret <= var_threshold], na.rm = TRUE)
                            },
                            fill = NA, align = "right")
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(rolling_es)),
      es_value = abs(rolling_es) * input$portfolioValue
    ) %>% filter(!is.na(es_value))
    
    plot_ly(plot_data, x = ~Date, y = ~es_value, type = "scatter", mode = "lines",
            line = list(color = "#8e44ad", width = 2)) %>%
      layout(
        title = "Expected Shortfall",
        xaxis = list(title = "Date"),
        yaxis = list(title = "USD"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$drawdownAnalysis <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data
    
    returns <- data$returns[!is.na(data$returns)]
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max * 100
    
    dd_data <- data.frame(
      Date = tail(data$Date, length(drawdown)),
      drawdown = drawdown
    )
    
    plot_ly(dd_data, x = ~Date, y = ~drawdown, type = "scatter", mode = "lines",
            fill = "tonexty", fillcolor = "rgba(214, 39, 40, 0.3)",
            line = list(color = "#d62728", width = 2)) %>%
      layout(
        title = "Drawdown Analysis",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Drawdown (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$riskStatsTable <- renderDT({
    req(values$asset_data)
    data <- values$asset_data %>% tail(input$varWindow)
    
    returns <- data$returns[!is.na(data$returns)]
    
    if (length(returns) < 30) {
      return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
    }
    
    adj_returns <- returns * sqrt(input$timeHorizon)
    downside_returns <- returns[returns < 0]
    
    stats <- data.frame(
      Metric = c("Mean Return (%)", "Volatility (%)", "Sharpe Ratio", "Sortino Ratio",
                 "Max Loss (%)", "Max Gain (%)"),
      Value = c(
        round(mean(adj_returns) * 100, 4),
        round(sd(adj_returns) * 100, 4),
        round(mean(returns) / sd(returns) * sqrt(252), 3),
        round({
          rf_d   <- getOption("risk_free_daily", 0.045/252)
          exc    <- returns - rf_d
          ann_dd <- sqrt(mean(pmin(exc, 0)^2, na.rm = TRUE)) * sqrt(252)
          if (ann_dd == 0) NA else mean(exc, na.rm = TRUE) * 252 / ann_dd
        }, 3),
        round(min(adj_returns) * 100, 4),
        round(max(adj_returns) * 100, 4)
      )
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$stressTestResults <- renderDT({
    req(values$asset_data)
    
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    hist_vol <- sd(returns) * sqrt(input$timeHorizon)
    
    scenarios <- data.frame(
      Scenario = c("2 Sigma Event", "3 Sigma Event", "4 Sigma Event", 
                   "Flash Crash", "Market Crisis"),
      Probability = c("4.5%", "0.3%", "0.006%", "0.01%", "0.1%"),
      Impact_Pct = paste0(round(c(-2, -3, -4, -5, -3.5) * hist_vol * 100, 2), "%"),
      Portfolio_Impact = paste0("-$", format(round(abs(c(-2, -3, -4, -5, -3.5) * hist_vol * input$portfolioValue), 0), big.mark = ","))
    )
    
    datatable(scenarios, options = list(dom = 't'), rownames = FALSE)
  })
  
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
  
  output$sharpeRatioBox <- renderValueBox({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      sharpe <- NA
    } else {
      sharpe <- calculate_sharpe(returns, input$riskFreeRate, input$annualizeMetrics)
    }
    
    valueBox(
      value = ifelse(is.na(sharpe), "N/A", round(sharpe, 3)),
      subtitle = "Sharpe Ratio",
      icon = icon("chart-line"),
      color = "blue"
    )
  })
  
  output$sortinoRatioBox <- renderValueBox({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      sortino <- NA
    } else {
      sortino <- calculate_sortino(returns, input$riskFreeRate, input$annualizeMetrics)
    }
    
    valueBox(
      value = ifelse(is.na(sortino), "N/A", round(sortino, 3)),
      subtitle = "Sortino Ratio (hurdle = Rf rate)",
      icon = icon("arrow-trend-down"),
      color = "green"
    )
  })
  
  output$calmarRatioBox <- renderValueBox({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      calmar <- NA
    } else {
      calmar <- calculate_calmar(returns, input$annualizeMetrics)
    }
    
    valueBox(
      value = ifelse(is.na(calmar), "N/A", round(calmar, 3)),
      subtitle = "Calmar Ratio",
      icon = icon("shield-halved"),
      color = "teal"
    )
  })
  
  output$omegaRatioBox <- renderValueBox({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      omega <- NA
    } else {
      omega <- calculate_omega(returns, input$targetReturn)
    }
    
    valueBox(
      value = ifelse(is.na(omega) || is.infinite(omega), "N/A", round(omega, 3)),
      subtitle = "Omega Ratio",
      icon = icon("circle-notch"),
      color = "orange"
    )
  })
  
  output$advancedMetricsTable <- renderDT({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
    }
    
    # Calculate all metrics
    sharpe <- calculate_sharpe(returns, input$riskFreeRate, input$annualizeMetrics)
    sortino <- calculate_sortino(returns, input$riskFreeRate, input$annualizeMetrics)
    calmar <- calculate_calmar(returns)
    omega <- calculate_omega(returns, input$targetReturn)
    
    # Downside deviation
    downside_returns <- pmin(returns - input$targetReturn/100/252, 0)
    downside_dev <- sqrt(mean(downside_returns^2, na.rm = TRUE)) * sqrt(252) * 100
    
    # Upside potential ratio
    upside_returns <- pmax(returns - input$targetReturn/100/252, 0)
    upside_pot <- mean(upside_returns, na.rm = TRUE) / sqrt(mean(downside_returns^2, na.rm = TRUE))
    
    # Max drawdown
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max
    max_dd <- min(drawdown, na.rm = TRUE) * 100
    
    metrics <- data.frame(
      Metric = c("Sharpe Ratio", "Sortino Ratio", "Calmar Ratio", "Omega Ratio",
                 "Downside Deviation (%)", "Upside Potential Ratio", "Max Drawdown (%)",
                 "Annualized Return (%)", "Annualized Volatility (%)"),
      Value = c(
        ifelse(is.na(sharpe), "N/A", round(sharpe, 3)),
        ifelse(is.na(sortino), "N/A", round(sortino, 3)),
        ifelse(is.na(calmar), "N/A", round(calmar, 3)),
        ifelse(is.na(omega) || is.infinite(omega), "N/A", round(omega, 3)),
        round(downside_dev, 2),
        ifelse(is.na(upside_pot) || is.infinite(upside_pot), "N/A", round(upside_pot, 3)),
        round(max_dd, 2),
        round(mean(returns, na.rm = TRUE) * 252 * 100, 2),
        round(sd(returns, na.rm = TRUE) * sqrt(252) * 100, 2)
      )
    )
    
    datatable(metrics, options = list(dom = 't', pageLength = 20), rownames = FALSE)
  })
  
  output$rollingSharpeChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(1000)
    returns <- data$returns
    
    if (sum(!is.na(returns)) < input$rollingWindow) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rf_daily <- input$riskFreeRate / 100 / 252
    rolling_sharpe <- rollapply(returns, input$rollingWindow,
                                function(x) {
                                  excess <- x - rf_daily
                                  sharpe <- mean(excess, na.rm = TRUE) / sd(excess, na.rm = TRUE)
                                  if (input$annualizeMetrics) sharpe <- sharpe * sqrt(252)
                                  return(sharpe)
                                },
                                fill = NA, align = "right")
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(rolling_sharpe)),
      sharpe = rolling_sharpe
    ) %>% filter(!is.na(sharpe))
    
    plot_ly(plot_data, x = ~Date, y = ~sharpe, type = "scatter", mode = "lines",
            line = list(color = "#3498db", width = 2)) %>%
      layout(
        title = paste("Rolling Sharpe Ratio (", input$rollingWindow, " days)"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Sharpe Ratio"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$rollingSortinoChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(1000)
    returns <- data$returns
    
    if (sum(!is.na(returns)) < input$rollingWindow) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    target_daily <- input$riskFreeRate / 100 / 252
    rolling_sortino <- rollapply(returns, input$rollingWindow,
                                 function(x) {
                                   exc        <- x - target_daily
                                   downside   <- pmin(exc, 0)
                                   ann_dd     <- sqrt(mean(downside^2, na.rm = TRUE)) * sqrt(252)
                                   if (ann_dd == 0 || is.nan(ann_dd)) return(NA)
                                   ann_mean   <- mean(exc, na.rm = TRUE) * 252
                                   sortino    <- ann_mean / ann_dd
                                   if (!input$annualizeMetrics) sortino <- sortino / sqrt(252)
                                   return(sortino)
                                 },
                                 fill = NA, align = "right")
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(rolling_sortino)),
      sortino = rolling_sortino
    ) %>% filter(!is.na(sortino))
    
    plot_ly(plot_data, x = ~Date, y = ~sortino, type = "scatter", mode = "lines",
            line = list(color = "#27ae60", width = 2)) %>%
      layout(
        title = paste("Rolling Sortino Ratio (", input$rollingWindow, " days)"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Sortino Ratio"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$downsideRiskChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(500)
    returns <- data$returns[!is.na(data$returns)]
    
    if (length(returns) < 30) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    target_daily <- input$riskFreeRate / 100 / 252
    downside_returns <- pmin(returns - target_daily, 0) * 100
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(downside_returns)),
      downside = downside_returns
    )
    
    plot_ly(plot_data, x = ~Date, y = ~downside, type = "scatter", mode = "lines",
            fill = "tozeroy", fillcolor = "rgba(231, 76, 60, 0.3)",
            line = list(color = "#e74c3c", width = 1.5)) %>%
      layout(
        title = "Downside Risk (Below Target)",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Downside Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$upsideDownsideChart <- renderPlotly({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    target_daily <- input$riskFreeRate / 100 / 252
    upside <- mean(pmax(returns - target_daily, 0), na.rm = TRUE) * 252 * 100
    downside <- abs(mean(pmin(returns - target_daily, 0), na.rm = TRUE)) * 252 * 100
    
    plot_data <- data.frame(
      Type = c("Upside Capture", "Downside Capture"),
      Value = c(upside, downside),
      Color = c("#27ae60", "#e74c3c")
    )
    
    plot_ly(plot_data, x = ~Type, y = ~Value, type = "bar",
            marker = list(color = ~Color)) %>%
      layout(
        title = "Upside vs Downside Capture",
        xaxis = list(title = ""),
        yaxis = list(title = "Annualized (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = FALSE
      )
  })
  
  output$maxDrawdownDetailChart <- renderPlotly({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max * 100
    
    dd_data <- data.frame(
      Date = tail(values$asset_data$Date, length(drawdown)),
      drawdown = drawdown,
      cumulative = (cumulative - 1) * 100
    )
    
    plot_ly(dd_data, x = ~Date) %>%
      add_lines(y = ~cumulative, name = "Cumulative Return", 
                line = list(color = "#3498db", width = 2)) %>%
      add_lines(y = ~drawdown, name = "Drawdown", 
                line = list(color = "#e74c3c", width = 2)) %>%
      layout(
        title = "Drawdown from Peak",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Percentage (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$recoveryPeriodTable <- renderDT({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    dates <- tail(values$asset_data$Date, length(returns))
    
    if (length(returns) < 30) {
      return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
    }
    
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max
    
    # Find max drawdown
    max_dd_idx <- which.min(drawdown)
    max_dd_value <- drawdown[max_dd_idx] * 100
    max_dd_date <- dates[max_dd_idx]
    
    # Find recovery
    if (max_dd_idx < length(drawdown)) {
      recovery_idx <- which(drawdown[(max_dd_idx + 1):length(drawdown)] >= 0)[1]
      if (!is.na(recovery_idx)) {
        recovery_date <- dates[max_dd_idx + recovery_idx]
        recovery_days <- as.numeric(recovery_date - max_dd_date)
      } else {
        recovery_date <- "Not recovered"
        recovery_days <- NA
      }
    } else {
      recovery_date <- "Not recovered"
      recovery_days <- NA
    }
    
    recovery_data <- data.frame(
      Metric = c("Max Drawdown (%)", "Drawdown Date", "Recovery Date", "Recovery Period (days)",
                 "Current Drawdown (%)", "Days Since Peak"),
      Value = c(
        round(max_dd_value, 2),
        as.character(max_dd_date),
        as.character(recovery_date),
        ifelse(is.na(recovery_days), "N/A", recovery_days),
        round(tail(drawdown, 1) * 100, 2),
        as.numeric(tail(dates, 1) - dates[which.max(cumulative)])
      )
    )
    
    datatable(recovery_data, options = list(dom = 't'), rownames = FALSE)
  })
  
  # HEDGING STRATEGIES OUTPUTS (NEW)
  
  observeEvent(input$runHedgeAnalysis, {
    showNotification("Running hedge analysis...", type = "message", duration = 3)
    
    # fetch_asset_data already handles URL encoding for GC=F, ^GSPC, etc.
    hedge_data <- fetch_asset_data(input$hedgeAsset)
    
    if (is.null(hedge_data) || nrow(hedge_data) == 0) {
      showNotification(
        paste0("Could not load hedge asset '", input$hedgeAsset, "'. ",
               "Yahoo Finance may be rate-limiting — wait a moment and try again."),
        type = "error", duration = 8
      )
      return()
    }
    if (is.null(values$asset_data)) {
      showNotification("No primary asset data loaded yet", type = "warning")
      return()
    }
    
    # Align dates
    asset_data <- values$asset_data %>%
      filter(Date >= min(hedge_data$Date) & Date <= max(hedge_data$Date)) %>%
      select(Date, Close, returns) %>%
      filter(!is.na(returns))
    
    hedge_data <- hedge_data %>%
      filter(Date %in% asset_data$Date) %>%
      select(Date, Close, returns) %>%
      filter(!is.na(returns))
    
    # Merge data
    combined <- inner_join(
      asset_data %>% rename(asset_close = Close, asset_return = returns),
      hedge_data %>% rename(hedge_close = Close, hedge_return = returns),
      by = "Date"
    )
    
    if (nrow(combined) < 60) {
      showNotification("Insufficient overlapping data", type = "warning")
      return()
    }
    
    # Calculate hedge ratios based on method
    if (input$hedgeMethod == "static") {
      combined$hedge_ratio <- input$hedgeRatio
      
    } else if (input$hedgeMethod == "dynamic") {
      # Rolling correlation-based hedge
      combined$hedge_ratio <- rollapply(
        combined[, c("asset_return", "hedge_return")],
        width = input$hedgeLookback,
        FUN = function(x) {
          cor_val <- cor(x[,1], x[,2], use = "complete.obs")
          vol_ratio <- sd(x[,1], na.rm = TRUE) / sd(x[,2], na.rm = TRUE)
          return(cor_val * vol_ratio * input$hedgeRatio)
        },
        fill = NA,
        align = "right",
        by.column = FALSE
      )
      
    } else if (input$hedgeMethod == "beta") {
      # Beta-adjusted hedge
      combined$hedge_ratio <- rollapply(
        combined[, c("asset_return", "hedge_return")],
        width = input$hedgeLookback,
        FUN = function(x) {
          if (var(x[,2], na.rm = TRUE) == 0) return(input$hedgeRatio)
          beta <- cov(x[,1], x[,2], use = "complete.obs") / var(x[,2], na.rm = TRUE)
          return(beta * input$hedgeRatio)
        },
        fill = NA,
        align = "right",
        by.column = FALSE
      )
      
    } else if (input$hedgeMethod == "minvar") {
      # Minimum variance hedge
      combined$hedge_ratio <- rollapply(
        combined[, c("asset_return", "hedge_return")],
        width = input$hedgeLookback,
        FUN = function(x) {
          if (var(x[,2], na.rm = TRUE) == 0) return(input$hedgeRatio)
          h <- cov(x[,1], x[,2], use = "complete.obs") / var(x[,2], na.rm = TRUE)
          return(h * input$hedgeRatio)
        },
        fill = NA,
        align = "right",
        by.column = FALSE
      )
    }
    
    # Calculate hedged returns
    combined <- combined %>%
      filter(!is.na(hedge_ratio)) %>%
      mutate(
        hedged_return = asset_return - hedge_ratio * hedge_return,
        unhedged_cumulative = cumprod(1 + asset_return) - 1,
        hedged_cumulative = cumprod(1 + hedged_return) - 1
      )
    
    values$hedge_data <- combined
    
    # Calculate statistics
    unhedged_vol <- sd(combined$asset_return, na.rm = TRUE) * sqrt(252) * 100
    hedged_vol <- sd(combined$hedged_return, na.rm = TRUE) * sqrt(252) * 100
    vol_reduction <- (unhedged_vol - hedged_vol) / unhedged_vol * 100
    
    unhedged_sharpe <- calculate_sharpe(combined$asset_return, input$riskFreeRate, TRUE)
    hedged_sharpe <- calculate_sharpe(combined$hedged_return, input$riskFreeRate, TRUE)
    
    values$hedge_results <- list(
      unhedged_vol = unhedged_vol,
      hedged_vol = hedged_vol,
      vol_reduction = vol_reduction,
      unhedged_sharpe = unhedged_sharpe,
      hedged_sharpe = hedged_sharpe
    )
    
    showNotification("Hedge analysis complete", type = "message", duration = 3)
  })
  
  output$unhedgedStats <- renderText({
    req(values$hedge_results)
    
    paste(
      paste("Volatility:", round(values$hedge_results$unhedged_vol, 2), "%"),
      paste("Sharpe Ratio:", round(values$hedge_results$unhedged_sharpe, 3)),
      paste("Strategy: No hedge"),
      sep = "\n"
    )
  })
  
  output$hedgedStats <- renderText({
    req(values$hedge_results)
    
    paste(
      paste("Volatility:", round(values$hedge_results$hedged_vol, 2), "%"),
      paste("Sharpe Ratio:", round(values$hedge_results$hedged_sharpe, 3)),
      paste("Vol Reduction:", round(values$hedge_results$vol_reduction, 1), "%"),
      paste("Method:", input$hedgeMethod),
      sep = "\n"
    )
  })
  
  output$hedgePerformanceChart <- renderPlotly({
    req(values$hedge_data)
    
    plot_ly(values$hedge_data, x = ~Date) %>%
      add_lines(y = ~unhedged_cumulative * 100, name = "Unhedged",
                line = list(color = "#e74c3c", width = 2)) %>%
      add_lines(y = ~hedged_cumulative * 100, name = "Hedged",
                line = list(color = "#27ae60", width = 2)) %>%
      layout(
        title = "Hedged vs Unhedged Performance",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$hedgeRatioChart <- renderPlotly({
    req(values$hedge_data)
    
    plot_ly(values$hedge_data, x = ~Date, y = ~hedge_ratio, 
            type = "scatter", mode = "lines",
            line = list(color = "#3498db", width = 2)) %>%
      layout(
        title = "Rolling Hedge Ratio",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Hedge Ratio"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$hedgeCorrelationChart <- renderPlotly({
    req(values$hedge_data)
    
    rolling_corr <- rollapply(
      values$hedge_data[, c("asset_return", "hedge_return")],
      width = input$hedgeLookback,
      FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
      fill = NA,
      align = "right",
      by.column = FALSE
    )
    
    plot_data <- data.frame(
      Date = values$hedge_data$Date,
      correlation = rolling_corr
    ) %>% filter(!is.na(correlation))
    
    plot_ly(plot_data, x = ~Date, y = ~correlation,
            type = "scatter", mode = "lines",
            line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        title = "Rolling Correlation",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Correlation", range = c(-1, 1)),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$hedgeEffectivenessTable <- renderDT({
    req(values$hedge_data, values$hedge_results)
    
    data <- values$hedge_data
    
    # Calculate effectiveness metrics
    unhedged_ret <- mean(data$asset_return, na.rm = TRUE) * 252 * 100
    hedged_ret <- mean(data$hedged_return, na.rm = TRUE) * 252 * 100
    
    # Max drawdown
    unhedged_cum <- cumprod(1 + data$asset_return)
    unhedged_dd <- min((unhedged_cum - cummax(unhedged_cum)) / cummax(unhedged_cum), na.rm = TRUE) * 100
    
    hedged_cum <- cumprod(1 + data$hedged_return)
    hedged_dd <- min((hedged_cum - cummax(hedged_cum)) / cummax(hedged_cum), na.rm = TRUE) * 100
    
    # Hedge effectiveness ratio
    hedge_eff <- (values$hedge_results$unhedged_vol - values$hedge_results$hedged_vol) / 
      values$hedge_results$unhedged_vol * 100
    
    metrics <- data.frame(
      Metric = c("Annualized Return (%)", "Volatility (%)", "Sharpe Ratio", 
                 "Max Drawdown (%)", "Hedge Effectiveness (%)"),
      Unhedged = c(
        round(unhedged_ret, 2),
        round(values$hedge_results$unhedged_vol, 2),
        round(values$hedge_results$unhedged_sharpe, 3),
        round(unhedged_dd, 2),
        "Baseline"
      ),
      Hedged = c(
        round(hedged_ret, 2),
        round(values$hedge_results$hedged_vol, 2),
        round(values$hedge_results$hedged_sharpe, 3),
        round(hedged_dd, 2),
        paste0(round(hedge_eff, 1), "%")
      )
    )
    
    datatable(metrics, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$betaAnalysisChart <- renderPlotly({
    req(values$hedge_data)
    
    rolling_beta <- rollapply(
      values$hedge_data[, c("asset_return", "hedge_return")],
      width = input$hedgeLookback,
      FUN = function(x) {
        if (var(x[,2], na.rm = TRUE) == 0) return(NA)
        cov(x[,1], x[,2], use = "complete.obs") / var(x[,2], na.rm = TRUE)
      },
      fill = NA,
      align = "right",
      by.column = FALSE
    )
    
    plot_data <- data.frame(
      Date = values$hedge_data$Date,
      beta = rolling_beta
    ) %>% filter(!is.na(beta))
    
    plot_ly(plot_data, x = ~Date, y = ~beta,
            type = "scatter", mode = "lines",
            line = list(color = "#e67e22", width = 2)) %>%
      add_lines(y = 1, name = "Beta = 1", 
                line = list(color = "#95a5a6", dash = "dash", width = 1)) %>%
      layout(
        title = "Rolling Beta",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Beta"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$hedgeCostBenefitTable <- renderDT({
    req(values$hedge_data, values$hedge_results)
    
    # Estimate hedging costs (simplified)
    avg_hedge_ratio <- mean(abs(values$hedge_data$hedge_ratio), na.rm = TRUE)
    transaction_cost <- 0.001  # 0.1% per transaction
    rebalance_freq <- input$rebalanceFreq
    
    num_periods <- nrow(values$hedge_data)
    num_rebalances <- floor(num_periods / rebalance_freq)
    total_transaction_cost <- num_rebalances * avg_hedge_ratio * transaction_cost * 100
    
    # Benefits
    vol_reduction_benefit <- values$hedge_results$vol_reduction
    sharpe_improvement <- values$hedge_results$hedged_sharpe - values$hedge_results$unhedged_sharpe
    
    cost_benefit <- data.frame(
      Category = c("Cost", "Cost", "Benefit", "Benefit", "Net"),
      Item = c("Transaction Costs (%)", "Number of Rebalances", 
               "Volatility Reduction (%)", "Sharpe Improvement",
               "Net Benefit Score"),
      Value = c(
        round(total_transaction_cost, 3),
        num_rebalances,
        round(vol_reduction_benefit, 2),
        round(sharpe_improvement, 3),
        round(vol_reduction_benefit - total_transaction_cost, 2)
      )
    )
    
    datatable(cost_benefit, options = list(dom = 't'), rownames = FALSE)
  })
  
  # COMPOSITE ANALYSIS OUTPUTS
  
  observeEvent(input$runComposite, {
    showNotification("Loading composite data...", type = "message", duration = 3)
    
    selected_assets <- input$compositeAssets
    
    if (length(selected_assets) < 2) {
      showNotification("Please select at least 2 assets", type = "warning")
      return()
    }
    
    composite_list <- list()
    failed_assets  <- c()
    
    for (symbol in selected_assets) {
      data <- fetch_asset_data(symbol)
      if (!is.null(data) && nrow(data) > 0) {
        data <- data %>%
          filter(Date >= input$compositeRange[1] & Date <= input$compositeRange[2]) %>%
          select(Date, Close, returns) %>%
          mutate(asset = symbol)
        composite_list[[symbol]] <- data
      } else {
        failed_assets <- c(failed_assets, symbol)
      }
    }
    
    if (length(failed_assets) > 0) {
      showNotification(
        paste("Could not load:", paste(failed_assets, collapse = ", ")),
        type = "warning", duration = 6
      )
    }
    
    if (length(composite_list) >= 2) {
      values$composite_data <- bind_rows(composite_list)
      showNotification(paste("Loaded", length(composite_list), "assets"), type = "message")
    } else if (length(composite_list) == 1) {
      showNotification("Need at least 2 assets with data for composite analysis", type = "warning")
    } else {
      showNotification("Failed to load composite data — check your internet connection", type = "error")
    }
  })
  
  output$compositePerformance <- renderPlotly({
    req(values$composite_data)
    
    data <- values$composite_data
    
    if (input$normalizeMethod == "index") {
      # Normalize to base 100
      data <- data %>%
        group_by(asset) %>%
        arrange(Date) %>%
        mutate(indexed = Close / first(Close) * 100) %>%
        ungroup()
      
      p <- plot_ly(data, x = ~Date, y = ~indexed, color = ~asset, type = "scatter", mode = "lines")
      y_title <- "Indexed Value (Base 100)"
    } else if (input$normalizeMethod == "returns") {
      # Cumulative returns
      data <- data %>%
        group_by(asset) %>%
        arrange(Date) %>%
        mutate(cum_return = cumprod(1 + ifelse(is.na(returns), 0, returns)) - 1) %>%
        ungroup()
      
      p <- plot_ly(data, x = ~Date, y = ~cum_return * 100, color = ~asset, type = "scatter", mode = "lines")
      y_title <- "Cumulative Return (%)"
    } else {
      # Raw prices
      p <- plot_ly(data, x = ~Date, y = ~Close, color = ~asset, type = "scatter", mode = "lines")
      y_title <- "Price (USD)"
    }
    
    p %>% layout(
      title = "Comparative Performance",
      xaxis = list(title = "Date"),
      yaxis = list(title = y_title),
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  output$compositeCorrelation <- renderPlot({
    req(values$composite_data)
    
    corr_data <- values$composite_data %>%
      filter(!is.na(returns)) %>%
      select(Date, asset, returns) %>%
      pivot_wider(names_from = asset, values_from = returns) %>%
      select(-Date) %>%
      na.omit()
    
    if (ncol(corr_data) < 2) {
      plot.new()
      text(0.5, 0.5, "Insufficient data", cex = 1.5)
      return()
    }
    
    corr_matrix <- cor(corr_data, use = "complete.obs")
    
    corrplot(corr_matrix, method = "color", type = "upper",
             tl.cex = 1.0, tl.col = "#2c3e50",
             addCoef.col = "#2c3e50", number.cex = 1.0,
             col = colorRampPalette(c("#e74c3c", "white", "#3498db"))(200),
             title = "Correlation Matrix")
  })
  
  output$riskReturnScatter <- renderPlotly({
    req(values$composite_data)
    
    risk_return <- values$composite_data %>%
      filter(!is.na(returns)) %>%
      group_by(asset) %>%
      summarise(
        mean_return = mean(returns, na.rm = TRUE) * 252 * 100,
        volatility = sd(returns, na.rm = TRUE) * sqrt(252) * 100,
        .groups = 'drop'
      )
    
    plot_ly(risk_return, x = ~volatility, y = ~mean_return, text = ~asset,
            type = "scatter", mode = "markers+text",
            marker = list(size = 15, color = "#3498db"),
            textposition = "top center") %>%
      layout(
        title = "Risk-Return Profile",
        xaxis = list(title = "Annualized Volatility (%)"),
        yaxis = list(title = "Annualized Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$compositeMetrics <- renderDT({
    req(values$composite_data)
    
    metrics <- values$composite_data %>%
      filter(!is.na(returns)) %>%
      group_by(asset) %>%
      summarise(
        Total_Return = round((last(Close) / first(Close) - 1) * 100, 2),
        Ann_Return = round(mean(returns) * 252 * 100, 2),
        Ann_Vol = round(sd(returns) * sqrt(252) * 100, 2),
        Sharpe = round(mean(returns) / sd(returns) * sqrt(252), 3),
        Max_DD = round(min((Close / cummax(Close) - 1)) * 100, 2),
        .groups = 'drop'
      )
    
    datatable(metrics, options = list(dom = 't', scrollX = TRUE), rownames = FALSE) %>%
      formatStyle(columns = "Total_Return", 
                  backgroundColor = styleInterval(0, c("#f8d7da", "#d4edda")))
  })
  
  output$rollingCorrelations <- renderPlotly({
    req(values$composite_data)
    
    selected <- input$compositeAssets[1:min(2, length(input$compositeAssets))]
    
    if (length(selected) < 2) {
      return(plot_ly() %>% layout(title = "Select at least 2 assets"))
    }
    
    corr_data <- values$composite_data %>%
      filter(asset %in% selected, !is.na(returns)) %>%
      select(Date, asset, returns) %>%
      pivot_wider(names_from = asset, values_from = returns) %>%
      arrange(Date)
    
    if (nrow(corr_data) < 60) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rolling_corr <- rollapply(corr_data[, 2:3], width = 60,
                              FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
                              fill = NA, align = "right", by.column = FALSE)
    
    corr_df <- data.frame(
      Date = tail(corr_data$Date, length(rolling_corr)),
      correlation = rolling_corr
    ) %>% filter(!is.na(correlation))
    
    plot_ly(corr_df, x = ~Date, y = ~correlation, type = "scatter", mode = "lines",
            line = list(color = "#3498db", width = 2)) %>%
      layout(
        title = paste("Rolling Correlation:", paste(selected, collapse = " vs ")),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Correlation", range = c(-1, 1)),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$cryptoSummary <- renderText({
    req(values$composite_data)
    
    crypto_assets <- c("BTC-USD", "ETH-USD", "ADA-USD")
    crypto_data <- values$composite_data %>%
      filter(asset %in% crypto_assets, !is.na(returns))
    
    if (nrow(crypto_data) == 0) return("No crypto data")
    
    summary <- crypto_data %>%
      group_by(asset) %>%
      summarise(
        ret = mean(returns) * 252 * 100,
        vol = sd(returns) * sqrt(252) * 100,
        .groups = 'drop'
      )
    
    paste(
      "Cryptocurrency Class:",
      paste("Avg Return:", round(mean(summary$ret), 2), "%"),
      paste("Avg Volatility:", round(mean(summary$vol), 2), "%"),
      paste("Assets:", nrow(summary)),
      sep = "\n"
    )
  })
  
  output$equitySummary <- renderText({
    req(values$composite_data)
    
    equity_assets <- c("NVDA", "MSFT", "AAPL")
    equity_data <- values$composite_data %>%
      filter(asset %in% equity_assets, !is.na(returns))
    
    if (nrow(equity_data) == 0) return("No equity data")
    
    summary <- equity_data %>%
      group_by(asset) %>%
      summarise(
        ret = mean(returns) * 252 * 100,
        vol = sd(returns) * sqrt(252) * 100,
        .groups = 'drop'
      )
    
    paste(
      "Equity Class:",
      paste("Avg Return:", round(mean(summary$ret), 2), "%"),
      paste("Avg Volatility:", round(mean(summary$vol), 2), "%"),
      paste("Assets:", nrow(summary)),
      sep = "\n"
    )
  })
  
  output$commoditySummary <- renderText({
    req(values$composite_data)
    
    commodity_assets <- c("GC=F", "CL=F", "NG=F")
    commodity_data <- values$composite_data %>%
      filter(asset %in% commodity_assets, !is.na(returns))
    
    if (nrow(commodity_data) == 0) return("No commodity data")
    
    summary <- commodity_data %>%
      group_by(asset) %>%
      summarise(
        ret = mean(returns) * 252 * 100,
        vol = sd(returns) * sqrt(252) * 100,
        .groups = 'drop'
      )
    
    paste(
      "Commodity Class:",
      paste("Avg Return:", round(mean(summary$ret), 2), "%"),
      paste("Avg Volatility:", round(mean(summary$vol), 2), "%"),
      paste("Assets:", nrow(summary)),
      sep = "\n"
    )
  })
  
  output$classComparison <- renderText({
    req(values$composite_data)
    
    crypto_assets <- c("BTC-USD", "ETH-USD", "ADA-USD")
    equity_assets <- c("NVDA", "MSFT", "AAPL")
    commodity_assets <- c("GC=F", "CL=F", "NG=F")
    
    crypto_data <- values$composite_data %>%
      filter(asset %in% crypto_assets, !is.na(returns))
    
    equity_data <- values$composite_data %>%
      filter(asset %in% equity_assets, !is.na(returns))
    
    commodity_data <- values$composite_data %>%
      filter(asset %in% commodity_assets, !is.na(returns))
    
    if (nrow(crypto_data) == 0 && nrow(equity_data) == 0 && nrow(commodity_data) == 0) {
      return("Insufficient data for comparison")
    }
    
    crypto_ret <- if(nrow(crypto_data) > 0) mean(crypto_data$returns) * 252 * 100 else NA
    equity_ret <- if(nrow(equity_data) > 0) mean(equity_data$returns) * 252 * 100 else NA
    commodity_ret <- if(nrow(commodity_data) > 0) mean(commodity_data$returns) * 252 * 100 else NA
    
    crypto_vol <- if(nrow(crypto_data) > 0) sd(crypto_data$returns) * sqrt(252) * 100 else NA
    equity_vol <- if(nrow(equity_data) > 0) sd(equity_data$returns) * sqrt(252) * 100 else NA
    commodity_vol <- if(nrow(commodity_data) > 0) sd(commodity_data$returns) * sqrt(252) * 100 else NA
    
    # Find best performer
    returns <- c(Crypto = crypto_ret, Equity = equity_ret, Commodity = commodity_ret)
    returns <- returns[!is.na(returns)]
    best_return <- if(length(returns) > 0) names(which.max(returns)) else "N/A"
    
    # Find most volatile
    vols <- c(Crypto = crypto_vol, Equity = equity_vol, Commodity = commodity_vol)
    vols <- vols[!is.na(vols)]
    most_volatile <- if(length(vols) > 0) names(which.max(vols)) else "N/A"
    
    paste(
      "Class Comparison:",
      paste("Best Performer:", best_return),
      paste("Most Volatile:", most_volatile),
      "",
      if(!is.na(crypto_ret)) paste("Crypto Return:", round(crypto_ret, 2), "%") else NULL,
      if(!is.na(equity_ret)) paste("Equity Return:", round(equity_ret, 2), "%") else NULL,
      if(!is.na(commodity_ret)) paste("Commodity Return:", round(commodity_ret, 2), "%") else NULL,
      sep = "\n"
    )
  })
  
  # ══════════════════════════════════════════════════════════════════════════
  # NEW TAB 1: FUTURES, OPTIONS & FX
  # ══════════════════════════════════════════════════════════════════════════
  
  # Seed calculator defaults from the currently loaded asset's latest close
  observeEvent(values$asset_data, {
    req(values$asset_data)
    latest_close <- round(tail(values$asset_data$Close, 1), 4)
    if (!is.na(latest_close) && latest_close > 0) {
      updateNumericInput(session, "futuresEntryPrice", value = latest_close)
      updateNumericInput(session, "fvCashPrice", value = latest_close)
      updateNumericInput(session, "optStrike", value = latest_close)
      updateNumericInput(session, "optPremium", value = round(latest_close * 0.05, 4))
    }
  }, ignoreInit = FALSE)
  
  # -- Futures Mechanics --
  output$futuresPnLChart <- renderPlotly({
    req(input$futuresEntryPrice)
    entry <- input$futuresEntryPrice
    price_range <- seq(entry * 0.7, entry * 1.3, length.out = 100)
    long_pnl  <- price_range - entry
    short_pnl <- entry - price_range
    
    plot_ly() %>%
      add_trace(x = price_range, y = long_pnl, type = "scatter", mode = "lines",
                name = "Long Futures", line = list(color = "#27ae60", width = 3)) %>%
      add_trace(x = price_range, y = short_pnl, type = "scatter", mode = "lines",
                name = "Short Futures", line = list(color = "#e74c3c", width = 3)) %>%
      layout(
        title = "Futures P&L at Expiry",
        xaxis = list(title = "Underlying Price at Expiry"),
        yaxis = list(title = "Profit / Loss per Unit"),
        shapes = list(
          list(type = "line", x0 = min(price_range), x1 = max(price_range), y0 = 0, y1 = 0,
               line = list(color = "#bdc3c7", width = 1, dash = "dash")),
          list(type = "line", x0 = entry, x1 = entry,
               y0 = min(c(long_pnl, short_pnl)), y1 = max(c(long_pnl, short_pnl)),
               line = list(color = "#7f8c8d", width = 1, dash = "dot"))
        ),
        plot_bgcolor = "white", paper_bgcolor = "white"
      )
  })
  
  output$futuresPnLSummaryTable <- renderDT({
    req(input$futuresEntryPrice)
    entry <- round(input$futuresEntryPrice, 2)
    df <- data.frame(
      Position   = c("Long Futures", "Short Futures"),
      `Max Gain` = c("Unlimited", paste0("Limited to entry price (", entry, ")")),
      `Max Loss` = c(paste0("Limited to entry price (", entry, ")"), "Unlimited"),
      Breakeven  = c(entry, entry),
      check.names = FALSE
    )
    datatable(df, options = list(dom = 't'), rownames = FALSE)
  })
  
  # -- Futures Pricing & Basis --
  output$fairValueResult <- renderUI({
    req(input$fvCashPrice, input$fvInterestRate, input$fvDaysToExpiry)
    
    cash     <- input$fvCashPrice
    rate     <- input$fvInterestRate / 100
    storage  <- if (is.null(input$fvStorageCost)) 0 else input$fvStorageCost
    div_yld  <- (if (is.null(input$fvDividendYield)) 0 else input$fvDividendYield) / 100
    days     <- input$fvDaysToExpiry
    
    lost_interest     <- cash * rate * (days / 365)
    dividend_benefit  <- cash * div_yld * (days / 365)
    net_cost_of_carry <- lost_interest + storage - dividend_benefit
    fair_value        <- cash + net_cost_of_carry
    basis             <- cash - fair_value
    
    state <- if (net_cost_of_carry > 0) "Contango (basis negative)" else
             if (net_cost_of_carry < 0) "Backwardation (basis positive)" else "At Fair Value"
    state_color <- if (net_cost_of_carry > 0) "#008A82" else
                   if (net_cost_of_carry < 0) "#e67e22" else "#7f8c8d"
    
    tagList(
      fluidRow(
        column(4, div(style = "text-align:center;", tags$h5("Cost of Carry"),
                      tags$h3(round(net_cost_of_carry, 4), style = paste0("color:", state_color, ";")))),
        column(4, div(style = "text-align:center;", tags$h5("Fair Value"),
                      tags$h3(round(fair_value, 4), style = "color:#002C3C;"))),
        column(4, div(style = "text-align:center;", tags$h5("Basis"),
                      tags$h3(round(basis, 4), style = "color:#002C3C;")))
      ),
      div(style = paste0("text-align:center; margin-top:10px; padding:10px; border-radius:8px; background:", state_color, "22;"),
          tags$strong(paste("Market State:", state), style = paste0("color:", state_color, ";"))
      )
    )
  })
  
  output$convergenceChart <- renderPlotly({
    req(input$fvCashPrice, input$fvInterestRate, input$fvDaysToExpiry)
    cash       <- input$fvCashPrice
    rate       <- input$fvInterestRate / 100
    storage    <- if (is.null(input$fvStorageCost)) 0 else input$fvStorageCost
    div_yld    <- (if (is.null(input$fvDividendYield)) 0 else input$fvDividendYield) / 100
    total_days <- max(input$fvDaysToExpiry, 1)
    
    days_remaining <- seq(total_days, 0, length.out = 50)
    carry <- cash * rate * (days_remaining / 365) +
             storage * (days_remaining / total_days) -
             cash * div_yld * (days_remaining / 365)
    future_price <- cash + carry
    
    plot_ly() %>%
      add_trace(x = total_days - days_remaining, y = future_price, type = "scatter", mode = "lines",
                name = "Future's Fair Value", line = list(color = "#008A82", width = 3)) %>%
      add_trace(x = c(0, total_days), y = c(cash, cash), type = "scatter", mode = "lines",
                name = "Constant Cash Price", line = list(color = "#e67e22", width = 2, dash = "dash")) %>%
      layout(title = "Convergence to Expiry",
             xaxis = list(title = "Days Elapsed"), yaxis = list(title = "Price"),
             plot_bgcolor = "white", paper_bgcolor = "white")
  })
  
  # -- Options P&L --
  options_payoff <- function(S, K, premium, type) {
    switch(type,
      long_call  = pmax(S - K, 0) - premium,
      short_call = premium - pmax(S - K, 0),
      long_put   = pmax(K - S, 0) - premium,
      short_put  = premium - pmax(K - S, 0)
    )
  }
  
  output$optionsPnLChart <- renderPlotly({
    req(input$optStrike, input$optPremium, input$optType)
    K <- input$optStrike
    premium <- input$optPremium
    S <- seq(K * 0.5, K * 1.5, length.out = 150)
    
    types_to_plot <- if (input$optType == "all_four") {
      c("long_call", "short_call", "long_put", "short_put")
    } else {
      input$optType
    }
    
    labels <- c(long_call = "Long Call", short_call = "Short Call",
                long_put = "Long Put", short_put = "Short Put")
    colors <- c(long_call = "#27ae60", short_call = "#e74c3c",
                long_put = "#3498db", short_put = "#9b59b6")
    
    p <- plot_ly()
    for (t in types_to_plot) {
      payoff <- options_payoff(S, K, premium, t)
      p <- p %>% add_trace(x = S, y = payoff, type = "scatter", mode = "lines",
                            name = labels[[t]], line = list(color = colors[[t]], width = 3))
    }
    p %>% layout(
      title = "Option Payoff at Expiry",
      xaxis = list(title = "Underlying Price at Expiry"),
      yaxis = list(title = "Profit / Loss"),
      shapes = list(
        list(type = "line", x0 = min(S), x1 = max(S), y0 = 0, y1 = 0,
             line = list(color = "#bdc3c7", width = 1, dash = "dash")),
        list(type = "line", x0 = K, x1 = K, y0 = -premium * 3, y1 = premium * 3,
             line = list(color = "#95a5a6", width = 1, dash = "dot"))
      ),
      plot_bgcolor = "white", paper_bgcolor = "white"
    )
  })
  
  output$optionsSummaryTable <- renderDT({
    req(input$optStrike, input$optPremium, input$optType)
    K <- input$optStrike
    premium <- input$optPremium
    
    types_to_plot <- if (input$optType == "all_four") {
      c("long_call", "short_call", "long_put", "short_put")
    } else {
      input$optType
    }
    
    labels    <- c(long_call = "Long Call", short_call = "Short Call",
                   long_put = "Long Put", short_put = "Short Put")
    strategy  <- c(long_call = "Bullish", short_call = "Bearish/Neutral",
                   long_put = "Bearish", short_put = "Bullish/Neutral")
    max_loss  <- c(long_call = as.character(round(premium, 2)), short_call = "Unlimited",
                   long_put = as.character(round(premium, 2)), short_put = as.character(round(K - premium, 2)))
    max_gain  <- c(long_call = "Unlimited", short_call = as.character(round(premium, 2)),
                   long_put = as.character(round(K - premium, 2)), short_put = as.character(round(premium, 2)))
    breakeven <- c(long_call = as.character(round(K + premium, 2)), short_call = as.character(round(K + premium, 2)),
                   long_put = as.character(round(K - premium, 2)), short_put = as.character(round(K - premium, 2)))
    
    df <- data.frame(
      Position    = unname(labels[types_to_plot]),
      Strategy    = unname(strategy[types_to_plot]),
      `Max Loss`  = unname(max_loss[types_to_plot]),
      `Max Gain`  = unname(max_gain[types_to_plot]),
      Breakeven   = unname(breakeven[types_to_plot]),
      check.names = FALSE
    )
    datatable(df, options = list(dom = 't'), rownames = FALSE)
  })
  
  # -- FX Fundamentals --
  output$fxCalcResult <- renderUI({
    req(input$fxPair, input$fxLotType, input$fxLeverage)
    
    pair        <- input$fxPair
    lot_size    <- as.numeric(input$fxLotType)
    leverage    <- input$fxLeverage
    counter_ccy <- strsplit(pair, "/")[[1]][2]
    
    pip_size <- if (counter_ccy == "JPY") 0.01 else 0.0001
    pip_value_usd <- if (counter_ccy == "USD") {
      lot_size * pip_size
    } else if (counter_ccy == "JPY") {
      round(lot_size * pip_size / 150, 2)   # illustrative approx. USD/JPY conversion
    } else {
      round(lot_size * pip_size, 2)          # illustrative approximation
    }
    
    notional        <- lot_size
    margin_required <- notional / leverage
    
    tagList(
      fluidRow(
        column(4, div(style = "text-align:center;", tags$h5("Notional Value"),
                      tags$h3(format(notional, big.mark = ","), style = "color:#002C3C;"))),
        column(4, div(style = "text-align:center;", tags$h5("Margin Required"),
                      tags$h3(paste0("$", format(round(margin_required, 2), big.mark = ",")), style = "color:#008A82;"))),
        column(4, div(style = "text-align:center;", tags$h5("Approx. Pip Value"),
                      tags$h3(paste0("$", pip_value_usd), style = "color:#002C3C;")))
      ),
      tags$p(paste0(
        "At ", leverage, ":1 leverage on a ", format(lot_size, big.mark = ","), "-unit position in ", pair,
        ", you control $", format(notional, big.mark = ","), " of notional exposure for a deposit of $",
        format(round(margin_required, 2), big.mark = ","), ". Pip value is illustrative and approximated to USD."
      ), style = "font-size:11px; color:#888; text-align:center; margin-top:10px; font-style:italic;")
    )
  })
  
  output$fxSessionChart <- renderPlotly({
    sessions <- data.frame(
      Center = c("Sydney", "Tokyo", "Singapore/HK", "Bahrain", "Frankfurt",
                 "London", "New York", "Chicago", "San Francisco"),
      Start  = c(-2, 0, 0, 7, 7, 8, 13, 14, 15),
      End    = c(6, 9, 9, 16, 16, 17, 22, 23, 24)
    )
    sessions$Center   <- factor(sessions$Center, levels = rev(sessions$Center))
    sessions$Duration <- sessions$End - sessions$Start
    
    plot_ly(sessions, y = ~Center, x = ~Duration, base = ~Start, type = "bar", orientation = "h",
            marker = list(color = "#008A82")) %>%
      layout(
        title = "FX Trading Sessions Across GMT Hours",
        xaxis = list(title = "GMT Hour", range = c(-2, 24), dtick = 2),
        yaxis = list(title = ""),
        plot_bgcolor = "white", paper_bgcolor = "white"
      )
  })
  
  # ══════════════════════════════════════════════════════════════════════════
  # NEW TAB 2: EXTENDED TECHNICAL INDICATORS
  # ══════════════════════════════════════════════════════════════════════════
  
  output$maComparisonChart <- renderPlotly({
    req(values$asset_data, input$maPeriod)
    data <- values$asset_data %>% arrange(Date)
    n <- input$maPeriod
    req(nrow(data) > n)
    
    p <- plot_ly() %>%
      add_trace(x = data$Date, y = data$Close, type = "scatter", mode = "lines",
                name = "Close", line = list(color = "#95a5a6", width = 1.5))
    
    if ("sma" %in% input$maTypes) {
      p <- p %>% add_trace(x = data$Date, y = as.numeric(SMA(data$Close, n = n)), type = "scatter", mode = "lines",
                            name = paste0("SMA(", n, ")"), line = list(color = "#3498db", width = 2))
    }
    if ("wma" %in% input$maTypes) {
      p <- p %>% add_trace(x = data$Date, y = as.numeric(WMA(data$Close, n = n)), type = "scatter", mode = "lines",
                            name = paste0("WMA(", n, ")"), line = list(color = "#f39c12", width = 2))
    }
    if ("ema" %in% input$maTypes) {
      p <- p %>% add_trace(x = data$Date, y = as.numeric(EMA(data$Close, n = n)), type = "scatter", mode = "lines",
                            name = paste0("EMA(", n, ")"), line = list(color = "#e74c3c", width = 2))
    }
    
    p %>% layout(
      title = paste("Moving Average Comparison —", current_asset()),
      xaxis = list(title = "Date"), yaxis = list(title = "Price"),
      plot_bgcolor = "white", paper_bgcolor = "white"
    )
  })
  
  output$momentumROCChart <- renderPlotly({
    req(values$asset_data, input$momPeriod)
    n <- input$momPeriod
    data <- values$asset_data %>%
      arrange(Date) %>%
      mutate(
        MOM = Close - lag(Close, n),
        ROC = (MOM / lag(Close, n)) * 100
      )
    req(nrow(data) > n)
    
    p1 <- plot_ly(data, x = ~Date, y = ~MOM, type = "scatter", mode = "lines",
                  name = paste0("Momentum(", n, ")"), line = list(color = "#3498db", width = 2)) %>%
      layout(yaxis = list(title = "Momentum"))
    p2 <- plot_ly(data, x = ~Date, y = ~ROC, type = "scatter", mode = "lines",
                  name = paste0("ROC(", n, ")"), line = list(color = "#e67e22", width = 2)) %>%
      layout(yaxis = list(title = "ROC (%)"))
    
    subplot(p1, p2, nrows = 2, shareX = TRUE, titleY = TRUE) %>%
      layout(title = paste("Momentum & Rate of Change —", current_asset()),
             plot_bgcolor = "white", paper_bgcolor = "white")
  })
  
  output$obvChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% arrange(Date)
    
    delta <- c(0, diff(data$Close))
    obv_incr  <- ifelse(delta > 0, data$Volume, ifelse(delta < 0, -data$Volume, 0))
    data$OBV  <- cumsum(ifelse(is.na(obv_incr), 0, obv_incr))
    wobv_incr <- data$Volume * delta
    data$WOBV <- cumsum(ifelse(is.na(wobv_incr), 0, wobv_incr))
    
    p1 <- plot_ly(data, x = ~Date, y = ~OBV, type = "scatter", mode = "lines",
                  name = "OBV", line = list(color = "#3498db", width = 2)) %>%
      layout(yaxis = list(title = "OBV"))
    p2 <- plot_ly(data, x = ~Date, y = ~WOBV, type = "scatter", mode = "lines",
                  name = "Weighted OBV", line = list(color = "#9b59b6", width = 2)) %>%
      layout(yaxis = list(title = "Weighted OBV"))
    
    subplot(p1, p2, nrows = 2, shareX = TRUE, titleY = TRUE) %>%
      layout(title = paste("On-Balance Volume —", current_asset()),
             plot_bgcolor = "white", paper_bgcolor = "white")
  })
  
  output$sarChart <- renderPlotly({
    req(values$asset_data, input$sarAccelStart, input$sarAccelMax)
    data <- values$asset_data %>% arrange(Date)
    req(nrow(data) > 5)
    
    hl <- data.frame(High = data$High, Low = data$Low)
    sar_vals <- tryCatch(
      SAR(hl, accel = c(input$sarAccelStart, input$sarAccelMax)),
      error = function(e) rep(NA_real_, nrow(data))
    )
    data$SAR <- as.numeric(sar_vals)
    
    plot_ly() %>%
      add_trace(data = data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                name = "Close", line = list(color = "#002C3C", width = 1.5)) %>%
      add_trace(data = data, x = ~Date, y = ~SAR, type = "scatter", mode = "markers",
                name = "Parabolic SAR", marker = list(color = "#e67e22", size = 4)) %>%
      layout(
        title = paste("Parabolic SAR —", current_asset()),
        xaxis = list(title = "Date"), yaxis = list(title = "Price"),
        plot_bgcolor = "white", paper_bgcolor = "white"
      )
  })
  
  pivot_levels <- reactive({
    req(values$asset_data)
    data <- values$asset_data %>% arrange(Date)
    req(nrow(data) >= 1)
    
    last_row <- tail(data, 1)
    H <- last_row$High; L <- last_row$Low; C <- last_row$Close
    
    PP <- (H + L + C) / 3
    R1 <- (2 * PP) - L
    S1 <- (2 * PP) - H
    R2 <- PP + (H - L)
    S2 <- PP - (H - L)
    R3 <- H + 2 * (PP - L)
    S3 <- L - 2 * (H - PP)
    
    data.frame(
      Level = c("R3", "R2", "R1", "PP", "S1", "S2", "S3"),
      Value = round(c(R3, R2, R1, PP, S1, S2, S3), 4)
    )
  })
  
  output$pivotPointsTable <- renderDT({
    lv <- pivot_levels()
    datatable(lv, options = list(dom = 't', paging = FALSE), rownames = FALSE) %>%
      formatStyle("Level",
                  backgroundColor = styleEqual(
                    c("R3", "R2", "R1", "PP", "S1", "S2", "S3"),
                    c("#fadbd8", "#fadbd8", "#fadbd8", "#d6eaf8", "#d5f5e3", "#d5f5e3", "#d5f5e3")
                  ))
  })
  
  output$pivotPointsChart <- renderPlotly({
    req(values$asset_data)
    data <- tail(values$asset_data %>% arrange(Date), 30)
    lv <- pivot_levels()
    
    p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                 name = "Close", line = list(color = "#002C3C", width = 2))
    
    colors <- c(R3 = "#c0392b", R2 = "#e74c3c", R1 = "#e67e22", PP = "#2980b9",
                S1 = "#27ae60", S2 = "#16a085", S3 = "#1abc9c")
    for (i in seq_len(nrow(lv))) {
      lvl <- lv$Level[i]; val <- lv$Value[i]
      p <- p %>% add_trace(x = data$Date, y = rep(val, nrow(data)), type = "scatter", mode = "lines",
                            name = lvl, line = list(color = colors[[lvl]], width = 1, dash = "dot"))
    }
    
    p %>% layout(title = paste("Recent Price vs Pivot Levels —", current_asset()),
                 xaxis = list(title = "Date"), yaxis = list(title = "Price"),
                 plot_bgcolor = "white", paper_bgcolor = "white")
  })
  
  # ══════════════════════════════════════════════════════════════════════════
  # NEW TAB 3: TRADER PSYCHOLOGY & MACRO CALENDAR
  # ══════════════════════════════════════════════════════════════════════════
  
  output$tenStepsUI <- renderUI({
    steps <- list(
      list(n = 1,  title = "Hard Work!", icon = "dumbbell",
           text = "As with any skill, the harder you work, the better you get at it. Learn the skills, practise applying them, and only start trading with real money once you're really ready."),
      list(n = 2,  title = "Self-Confidence", icon = "hand-fist",
           text = "Believe in yourself and your ability. If you've taken time to learn about trading, don't be afraid of taking controlled risk or trying new approaches."),
      list(n = 3,  title = "Education", icon = "graduation-cap",
           text = "It's possible to get lucky without really knowing what you're doing — but nobody becomes a successful trader over a weekend. Commit time and effort to a proper education."),
      list(n = 4,  title = "Get a Mentor", icon = "user-tie",
           text = "Get feedback on your trading as you apply new knowledge and skills. Find a role model whose advice you trust and learn from their process."),
      list(n = 5,  title = "Honesty & Responsibility", icon = "scale-balanced",
           text = "All traders lose money from time to time — it doesn't make you a bad trader. Be honest with yourself about your decisions, or you'll keep repeating the same mistakes."),
      list(n = 6,  title = "Don't Just Copy Other Traders", icon = "user-slash",
           text = "Copying gives you no control over your trading decisions. If you want to be a trader, learn how to be a trader."),
      list(n = 7,  title = "Learn From Your Mistakes", icon = "rotate-left",
           text = "Go back and review each losing trade. Did you follow your process? Could you have avoided or reduced the loss? Would you do things differently next time?"),
      list(n = 8,  title = "Set 'Process' Goals, Not Monetary Goals", icon = "bullseye",
           text = "Monetary goals build emotional pressure after early losses. Process goals — always follow your rules, never exceed your risk limit, always use stop losses — bring discipline, and profits follow."),
      list(n = 9,  title = "Be Organised and Disciplined", icon = "list-check",
           text = "Work out a set of trading rules that suits your character and fits around your other life commitments — then stick to them."),
      list(n = 10, title = "Patience", icon = "hourglass-half",
           text = "By deciding not to take a trade, you are still making a decision. Don't enter trades just to feel like you're trading — wait for the right opportunity.")
    )
    
    card_color <- "#008A82"
    cards <- lapply(steps, function(s) {
      column(6,
        div(style = paste0(
              "background:#f7fbfb; border-left:4px solid ", card_color, "; border-radius:8px; ",
              "padding:14px 16px; margin-bottom:14px; display:flex; gap:12px; align-items:flex-start;"
            ),
            div(style = paste0(
                  "background:", card_color, "; color:#fff; border-radius:50%; width:34px; height:34px; ",
                  "min-width:34px; display:flex; align-items:center; justify-content:center; font-weight:700;"
                ),
                s$n
            ),
            div(
              tags$h5(HTML(paste0(as.character(icon(s$icon)), " ", s$title)),
                      style = "margin:0 0 4px 0; color:#002C3C; font-weight:700;"),
              tags$p(s$text, style = "margin:0; font-size:12.5px; color:#444; line-height:1.6;")
            )
        )
      )
    })
    
    fluidRow(cards)
  })
  
  macro_calendar_data <- data.frame(
    Release = c("ISM Manufacturing PMI", "ISM Services PMI", "ADP Employment Change",
                "Average Hourly Earnings m/m", "Non-Farm Payrolls", "Unemployment Rate",
                "PPI", "CPI", "Core CPI", "Core PCE Price Index", "Core Retail Sales m/m",
                "Retail Sales m/m", "FOMC Economic Projections", "FOMC Statement",
                "Federal Funds Rate", "FOMC Press Conference", "Advance GDP q/q"),
    Frequency = c("Monthly (1st/2nd business day)", "Monthly (3rd business day)", "Monthly (1st Wednesday)",
                  "Monthly (1st Friday)", "Monthly (1st Friday)", "Monthly (1st business day)",
                  "Monthly (mid-month)", "Monthly (mid-month)", "Monthly (mid-month)", "Monthly (end of month)",
                  "Monthly (mid-month)", "Monthly (mid-month)", "4x per year", "8x per year",
                  "8x per year", "8x per year", "Quarterly (~30 days after quarter end)"),
    WhatIsIt = c(
      "Diffusion index of surveyed manufacturing purchasing managers.",
      "Diffusion index of surveyed purchasing managers, excluding manufacturing.",
      "Estimated change in private-sector employment, excluding farming and government.",
      "Change in the price businesses pay for labour, excluding farming.",
      "Change in the number of employed people, excluding farming.",
      "Percentage of the workforce unemployed and actively seeking work.",
      "Change in the price of finished goods and services sold by producers.",
      "Change in the price of goods and services purchased by consumers.",
      "CPI excluding food and energy.",
      "Fed's preferred inflation gauge; consumer spending ex food & energy.",
      "Change in total retail sales value, excluding automobiles.",
      "Change in total retail sales value.",
      "FOMC's projections for growth, inflation, and individual members' rate forecasts ('dot plot').",
      "FOMC's statement on the interest rate decision and economic outlook.",
      "Rate at which depository institutions lend to each other overnight.",
      "Press conference following the FOMC statement; often the primary driver of volatility.",
      "Annualised, inflation-adjusted change in the value of all goods and services produced."
    ),
    WhyTradersCare = c(
      "Leading indicator of economic health; businesses react quickly to market conditions.",
      "Leading indicator of economic health in the (much larger) services sector.",
      "Leading indicator of consumer spending, which drives most of economic activity.",
      "Leading indicator of consumer inflation via labour cost pass-through.",
      "Leading indicator of consumer spending and overall economic activity.",
      "Signals overall economic health; heavily weighted in monetary policy decisions.",
      "Leading indicator of consumer inflation via producer cost pass-through.",
      "Central to currency valuation — drives central bank interest rate decisions.",
      "Removes volatile components to show the underlying inflation trend.",
      "Rumoured to be the Fed's favourite inflation measure.",
      "Considered a better gauge of underlying spending trends than headline retail sales.",
      "Primary gauge of consumer spending, the majority of economic activity.",
      "Primary tool for communicating the Fed's economic and rate projections to markets.",
      "Primary tool for communicating monetary policy outcomes and outlook.",
      "The paramount short-term interest rate driving currency valuation.",
      "Unscripted Q&A creates the heaviest volatility of any scheduled US release.",
      "Broadest single measure of economic activity and health."
    ),
    ExpectedOutcome = c(
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD down / Indices up. Actual < Forecast: USD up / Indices down.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "More hawkish than expected: USD up / Indices down. More dovish: USD down / Indices up.",
      "More hawkish than expected: USD up / Indices down. More dovish: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
      "More hawkish than expected: USD up / Indices down. More dovish: USD down / Indices up.",
      "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up."
    ),
    stringsAsFactors = FALSE
  )
  
  observe({
    updateSelectInput(session, "macroIndicator", choices = macro_calendar_data$Release)
  })
  
  output$macroCalendarTable <- renderDT({
    datatable(macro_calendar_data,
              colnames = c("Release", "Frequency", "What Is It?", "Why Traders Care", "Expected Outcome"),
              options = list(pageLength = 8, scrollX = TRUE), rownames = FALSE)
  })
  
  output$macroReactionResult <- renderUI({
    req(input$macroIndicator, input$macroDirection)
    row <- macro_calendar_data[macro_calendar_data$Release == input$macroIndicator, ]
    req(nrow(row) == 1)
    
    is_unemployment <- row$Release == "Unemployment Rate"
    is_narrative <- row$Release %in% c("FOMC Economic Projections", "FOMC Statement", "FOMC Press Conference")
    
    if (input$macroDirection == "beat") {
      usd_dir <- if (is_unemployment) "Down" else "Up"
      idx_dir <- if (is_unemployment) "Up" else "Down"
      scenario_label <- if (is_narrative) "More hawkish than expected" else "Actual beats Forecast"
    } else {
      usd_dir <- if (is_unemployment) "Up" else "Down"
      idx_dir <- if (is_unemployment) "Down" else "Up"
      scenario_label <- if (is_narrative) "More dovish than expected" else "Actual misses Forecast"
    }
    
    usd_color <- if (usd_dir == "Up") "#27ae60" else "#e74c3c"
    idx_color <- if (idx_dir == "Up") "#27ae60" else "#e74c3c"
    
    tagList(
      tags$p(tags$strong(row$Release), style = "margin-bottom:2px;"),
      tags$p(scenario_label, style = "font-size:12px; color:#888; margin-bottom:10px;"),
      div(style = "display:flex; gap:12px;",
        div(style = paste0("flex:1; text-align:center; padding:10px; border-radius:8px; background:", usd_color, "22;"),
            tags$div("USD", style = "font-size:12px; color:#666;"),
            tags$h4(usd_dir, style = paste0("color:", usd_color, "; margin:2px 0 0 0;"))
        ),
        div(style = paste0("flex:1; text-align:center; padding:10px; border-radius:8px; background:", idx_color, "22;"),
            tags$div("Indices", style = "font-size:12px; color:#666;"),
            tags$h4(idx_dir, style = paste0("color:", idx_color, "; margin:2px 0 0 0;"))
        )
      ),
      tags$p("General historical tendency only — actual reaction depends on prevailing financial conditions and monetary policy stance.",
             style = "font-size:11px; color:#999; font-style:italic; margin-top:10px;")
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)