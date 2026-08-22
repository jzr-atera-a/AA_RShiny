# app.R - IG Trading & Technical Analysis Dashboard
# Multi-Asset Analysis Dashboard - Modular (single-file-per-module) Architecture

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
library(httr)        # direct Yahoo Finance intraday chart API calls
library(jsonlite)    # parsing Yahoo intraday JSON responses
library(igfetchr)    # IG Trading REST API wrapper (CRAN) — install.packages("igfetchr")

source("global.R", local = TRUE)
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

ui <- dashboardPage(
  dashboardHeader(
    title = "IG Trading & Technical Analysis",
    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        icon("refresh"),
        "Refresh Data",
        onclick = "Shiny.onInputChange('global_refresh', Math.random())"
      )
    )
  ),
  
  dashboardSidebar(
    # Asset class selector — 5 classes: 3 Yahoo Finance built-ins, Forex, and IG (CFDs)
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        selectInput("global_asset_class", 
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
      condition = "input.global_asset_class != 'ig'",
      div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
          selectInput("global_data_resolution", "Data Resolution:",
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
    
    # Asset instance selector — one conditionalPanel per class
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        conditionalPanel(
          condition = "input.global_asset_class == 'crypto'",
          selectInput("global_crypto_asset", 
                      "Select Cryptocurrency:",
                      choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                  "Ethereum (ETH-USD)" = "ETH-USD",
                                  "Cardano (ADA-USD)" = "ADA-USD"),
                      selected = "BTC-USD",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.global_asset_class == 'equity'",
          selectInput("global_equity_asset", 
                      "Select Equity Stock:",
                      choices = c("NVIDIA (NVDA)" = "NVDA",
                                  "Microsoft (MSFT)" = "MSFT",
                                  "Apple (AAPL)" = "AAPL"),
                      selected = "NVDA",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.global_asset_class == 'commodity'",
          selectInput("global_commodity_asset", 
                      "Select Commodity:",
                      choices = c("Gold (GC=F)" = "GC=F",
                                  "Crude Oil (CL=F)" = "CL=F",
                                  "Natural Gas (NG=F)" = "NG=F"),
                      selected = "GC=F",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.global_asset_class == 'forex'",
          selectInput("global_forex_asset", 
                      "Select Currency Pair:",
                      choices = c("EUR/USD (EURUSD=X)" = "EURUSD=X",
                                  "GBP/USD (GBPUSD=X)" = "GBPUSD=X",
                                  "USD/JPY (JPY=X)"     = "JPY=X"),
                      selected = "EURUSD=X",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.global_asset_class == 'ig'",
          selectInput("global_ig_epic_preset",
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
          textInput("global_ig_epic_custom", "Or enter a custom EPIC:", value = "",
                    placeholder = "e.g. IX.D.FTSE.CFD.IP"),
          tags$p(HTML(paste0(
                   "Custom EPIC overrides the preset if filled in. Preset codes are commonly-cited examples ",
                   "and may not match your account/region exactly &mdash; verify or find EPICs using the ",
                   "market search tool on the <strong>IG Login</strong> tab (bottom of the sidebar) before ",
                   "relying on them."
                 )), style = "font-size:10.5px; color:#b2e0db; font-style:italic; margin-top:8px; line-height:1.5;")
        )
    ),
    
    # Tab order: Price Analysis is the default landing tab. IG Login sits at the bottom
    # of the list (not selected by default) since it's a one-time setup step, not
    # something to see on every app load.
    sidebarMenu(
      id = "sidebar_menu",
      menuItem("Price Analysis",       tabName = "price_analysis",       icon = icon("chart-simple"), selected = TRUE),
      menuItem("Market Overview",      tabName = "market_overview",      icon = icon("chart-line")),
      menuItem("Technical Indicators", tabName = "technical_indicators", icon = icon("chart-bar")),
      menuItem("IG Login",             tabName = "ig_login",             icon = icon("key"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
      tags$meta(charset = "UTF-8"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
    ),
    
    tabItems(
      tabItem(tabName = "price_analysis",       price_analysis_ui("price_analysis")),
      tabItem(tabName = "market_overview",      market_overview_ui("market_overview")),
      tabItem(tabName = "technical_indicators", technical_indicators_ui("technical_indicators")),
      tabItem(tabName = "ig_login",             ig_login_ui("ig_login"))
    )
  )
)

server <- function(input, output, session) {
  
  # Global asset selection observer — resolves the active symbol/EPIC across all
  # 5 asset classes (including the custom-EPIC override for IG) and pushes it,
  # along with the resolution, into the shared DataManager.
  observe({
    asset_class <- input$global_asset_class
    req(asset_class)
    
    current_asset <- if (asset_class == "crypto") {
      input$global_crypto_asset
    } else if (asset_class == "equity") {
      input$global_equity_asset
    } else if (asset_class == "commodity") {
      input$global_commodity_asset
    } else if (asset_class == "forex") {
      input$global_forex_asset
    } else if (asset_class == "ig") {
      custom <- input$global_ig_epic_custom
      if (!is.null(custom) && nzchar(trimws(custom))) trimws(custom) else input$global_ig_epic_preset
    } else {
      NULL
    }
    
    resolution <- if (asset_class == "ig") "1d" else (input$global_data_resolution %||% "1d")
    
    if (!is.null(current_asset) && current_asset != "") {
      data_manager$set_current_asset(current_asset, asset_class, resolution)
    }
  })
  
  # Global refresh observer
  observeEvent(input$global_refresh, {
    data_manager$trigger_refresh()
  })
  
  # Module servers — every module takes (id, data_manager); ig_login reaches
  # IG-specific state via data_manager$ig internally.
  price_analysis_server("price_analysis", data_manager)
  market_overview_server("market_overview", data_manager)
  technical_indicators_server("technical_indicators", data_manager)
  ig_login_server("ig_login", data_manager)
  
  session$onSessionEnded(function() {
    tryCatch({
      if (!is.null(ig_manager) && ig_manager$is_logged_in()) {
        ig_manager$logout()
      }
    }, error = function(e) {})
  })
}

shinyApp(ui, server)
