# app.R - Energy & Trading Analytics Suite
# A selection of main tabs from Trading Analysis F1, plus a new
# "External Sources" group (Satellite Data energy-demand map).

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
library(bigrquery)   # Economic Calendars: BigQuery storage
library(curl)        # Economic Calendars: streaming Claude API calls

source("global.R", local = TRUE)
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

ui <- dashboardPage(
  dashboardHeader(
    title = "Energy & Trading Analytics",
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
                    choices = c("Forex" = "forex",
                                "Cryptocurrencies" = "crypto",
                                "Equities" = "equity",
                                "Commodities" = "commodity",
                                "IG (CFDs)" = "ig"),
                    selected = "forex",
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
                   "market search tool on the <strong>IG Login</strong> tab before relying on them."
                 )), style = "font-size:10.5px; color:#b2e0db; font-style:italic; margin-top:8px; line-height:1.5;")
        )
    ),

    sidebarMenu(
      id = "sidebar_menu",

      menuItem("API Configuration", icon = icon("key"),
        menuSubItem("BigQuery",       tabName = "econ_bigquery_auth", icon = icon("database")),
        menuSubItem("Claude API",     tabName = "econ_claude_config", icon = icon("robot")),
        menuSubItem("Trello & Jira",  tabName = "trello_jira_config", icon = icon("trello")),
        menuSubItem("Debug Console",  tabName = "debug_console",      icon = icon("terminal"))
      ),

      menuItem("Economic Calendars", icon = icon("calendar-days"),
        menuSubItem("Trading Economics",             tabName = "economic_calendar_te",   icon = icon("calendar-days")),
        menuSubItem("Financial Modeling Prep",       tabName = "economic_calendar_fmp",  icon = icon("calendar-week")),
        menuSubItem("Daily/Weekly Trend Summary",    tabName = "econ_trend_summary",     icon = icon("bolt")),
        menuSubItem("Parse & Export to BigQuery",    tabName = "econ_calendar_export",   icon = icon("cloud-arrow-up")),
        menuSubItem("Visualisation",                 tabName = "econ_calendar_viz",      icon = icon("chart-line")),
        menuSubItem("Link to Live Trading",          tabName = "econ_calendar_live_link", icon = icon("link"))
      ),

      menuItem("Intro Tabs", icon = icon("house"), startExpanded = TRUE,
        menuSubItem("Price Analysis",       tabName = "price_analysis",       icon = icon("chart-simple"), selected = TRUE),
        menuSubItem("Market Overview",      tabName = "market_overview",      icon = icon("chart-line")),
        menuSubItem("Technical Indicators", tabName = "technical_indicators", icon = icon("chart-bar")),
        menuSubItem("IG Login",             tabName = "ig_login",             icon = icon("key"))
      ),

      menuItem("Futures, Options & FX", icon = icon("right-left"),
        menuSubItem("Futures Mechanics",     tabName = "futures_mechanics",    icon = icon("scale-balanced")),
        menuSubItem("Pricing, Basis & Carry",tabName = "pricing_basis_carry",  icon = icon("coins")),
        menuSubItem("Yield Curves",          tabName = "yield_curves",         icon = icon("chart-line")),
        menuSubItem("Options P&L Profiles",  tabName = "options_pnl",          icon = icon("chart-area")),
        menuSubItem("FX Fundamentals",       tabName = "fx_fundamentals",      icon = icon("money-bill-transfer"))
      ),

      menuItem("Hedging Strategies", icon = icon("shield-halved"),
        menuSubItem("Hedge Ratio Calculator", tabName = "hedge_ratio_calculator", icon = icon("calculator")),
        menuSubItem("Basis Risk Simulator",   tabName = "basis_risk_simulator",   icon = icon("wheat-awn")),
        menuSubItem("Long Hedge Concept",     tabName = "long_hedge_concept",     icon = icon("book-open"))
      ),

      menuItem("Extended Indicators", icon = icon("chart-area"),
        menuSubItem("Moving Averages",    tabName = "moving_averages",    icon = icon("chart-line")),
        menuSubItem("Momentum & ROC",     tabName = "momentum_roc",       icon = icon("gauge-high")),
        menuSubItem("Volume Indicators",  tabName = "volume_indicators",  icon = icon("chart-column")),
        menuSubItem("Parabolic SAR",      tabName = "parabolic_sar",      icon = icon("arrows-turn-to-dots")),
        menuSubItem("Pivot Points",       tabName = "pivot_points",       icon = icon("map-pin"))
      ),

      menuItem("Psychology & Macro", icon = icon("brain"),
        menuSubItem("Ten Steps to Successful Trading", tabName = "ten_steps",                icon = icon("list-ol")),
        menuSubItem("US Macro Calendar",                tabName = "macro_calendar_reference", icon = icon("calendar-check"))
      ),

      menuItem("Risk & Portfolio Analytics", icon = icon("triangle-exclamation"),
        menuSubItem("Volatility Analysis",   tabName = "volatility_analysis", icon = icon("wave-square")),
        menuSubItem("Risk Metrics",          tabName = "risk_metrics",        icon = icon("triangle-exclamation")),
        menuSubItem("Advanced Metrics",      tabName = "advanced_metrics",    icon = icon("star")),
        menuSubItem("Composite Analysis",    tabName = "composite_analysis",  icon = icon("layer-group"))
      ),

      menuItem("Commodities for Mobility", icon = icon("car-battery"),
        menuSubItem("Copper",                        tabName = "mobility_copper",   icon = icon("industry")),
        menuSubItem("Lithium Hydroxide",              tabName = "mobility_lithium", icon = icon("car-battery")),
        menuSubItem("Brent Crude Oil",                tabName = "mobility_oil",     icon = icon("oil-can")),
        menuSubItem("Approaching the Unit 1 Questions", tabName = "mobility_approach", icon = icon("route"))
      ),

      menuItem("External Sources", icon = icon("satellite"),
        menuSubItem("Satellite Data",             tabName = "energy_satellite_map", icon = icon("earth-americas")),
        menuSubItem("Data Enrichment (Energy)",   tabName = "data_enrichment",      icon = icon("layer-group"))
      ),

      menuItem("Strategy for Business", icon = icon("briefcase"),
        menuSubItem("Hedge Fund / Wealth",              tabName = "hedge_fund_strategy",        icon = icon("chart-pie")),
        menuSubItem("Portfolio Optimisation Lab",       tabName = "portfolio_lab",              icon = icon("layer-group")),
        menuSubItem("Family Office Platform Architecture", tabName = "family_office_architecture", icon = icon("sitemap"))
      ),

      menuItem("Research and Academia", icon = icon("landmark"),
        menuSubItem("Prof. Riddiough (U of T)", tabName = "research_riddiough", icon = icon("book-open-reader")),
        menuSubItem("AlgoDynamiX", tabName = "research_algodynamix", icon = icon("handshake"))
      )
    )
  ),

  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
      tags$meta(charset = "UTF-8"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
    ),

    tabItems(
      # -- Intro Tabs --
      tabItem(tabName = "price_analysis",       price_analysis_ui("price_analysis")),
      tabItem(tabName = "market_overview",      market_overview_ui("market_overview")),
      tabItem(tabName = "technical_indicators", technical_indicators_ui("technical_indicators")),
      tabItem(tabName = "ig_login",             ig_login_ui("ig_login")),

      # -- Futures, Options & FX --
      tabItem(tabName = "futures_mechanics",     futures_mechanics_ui("futures_mechanics")),
      tabItem(tabName = "pricing_basis_carry",   pricing_basis_carry_ui("pricing_basis_carry")),
      tabItem(tabName = "yield_curves",          yield_curves_ui("yield_curves")),
      tabItem(tabName = "options_pnl",           options_pnl_ui("options_pnl")),
      tabItem(tabName = "fx_fundamentals",       fx_fundamentals_ui("fx_fundamentals")),

      # -- Hedging Strategies --
      tabItem(tabName = "hedge_ratio_calculator", hedge_ratio_calculator_ui("hedge_ratio_calculator")),
      tabItem(tabName = "basis_risk_simulator",   basis_risk_simulator_ui("basis_risk_simulator")),
      tabItem(tabName = "long_hedge_concept",     long_hedge_concept_ui("long_hedge_concept")),

      # -- Extended Indicators --
      tabItem(tabName = "moving_averages",   moving_averages_ui("moving_averages")),
      tabItem(tabName = "momentum_roc",      momentum_roc_ui("momentum_roc")),
      tabItem(tabName = "volume_indicators", volume_indicators_ui("volume_indicators")),
      tabItem(tabName = "parabolic_sar",     parabolic_sar_ui("parabolic_sar")),
      tabItem(tabName = "pivot_points",      pivot_points_ui("pivot_points")),

      # -- Psychology & Macro --
      tabItem(tabName = "ten_steps",                ten_steps_ui("ten_steps")),
      tabItem(tabName = "macro_calendar_reference",  macro_calendar_reference_ui("macro_calendar_reference")),

      # -- Economic Calendars --
      tabItem(tabName = "economic_calendar_te",  economic_calendar_te_ui("economic_calendar_te")),
      tabItem(tabName = "economic_calendar_fmp", economic_calendar_fmp_ui("economic_calendar_fmp")),
      tabItem(tabName = "econ_trend_summary",     econ_trend_summary_ui("econ_trend_summary")),
      tabItem(tabName = "econ_calendar_export",   econ_calendar_export_ui("econ_calendar_export")),
      tabItem(tabName = "econ_calendar_viz",      econ_calendar_viz_ui("econ_calendar_viz")),
      tabItem(tabName = "econ_calendar_live_link", econ_calendar_live_link_ui("econ_calendar_live_link")),

      # -- API Configuration --
      tabItem(tabName = "econ_bigquery_auth", econ_bigquery_auth_ui("econ_bigquery_auth")),
      tabItem(tabName = "econ_claude_config", econ_claude_config_ui("econ_claude_config")),
      tabItem(tabName = "trello_jira_config", trello_jira_config_ui("trello_jira_config")),
      tabItem(tabName = "debug_console", debug_console_ui("debug_console")),

      # -- Risk & Portfolio Analytics --
      tabItem(tabName = "volatility_analysis", volatility_analysis_ui("volatility_analysis")),
      tabItem(tabName = "risk_metrics",        risk_metrics_ui("risk_metrics")),
      tabItem(tabName = "advanced_metrics",    advanced_metrics_ui("advanced_metrics")),
      tabItem(tabName = "composite_analysis",  composite_analysis_ui("composite_analysis")),

      # -- Commodities for Mobility --
      tabItem(tabName = "mobility_copper",   mobility_copper_ui("mobility_commodities")),
      tabItem(tabName = "mobility_lithium",  mobility_lithium_ui("mobility_commodities")),
      tabItem(tabName = "mobility_oil",      mobility_oil_ui("mobility_commodities")),
      tabItem(tabName = "mobility_approach", mobility_approach_ui("mobility_commodities")),

      # -- External Sources --
      tabItem(tabName = "energy_satellite_map", energy_satellite_map_ui("energy_satellite_map")),
      tabItem(tabName = "data_enrichment",      data_enrichment_ui("data_enrichment")),

      # -- Strategy for Business --
      tabItem(tabName = "hedge_fund_strategy", hedge_fund_strategy_ui("hedge_fund_strategy")),
      tabItem(tabName = "portfolio_lab",       portfolio_lab_ui("portfolio_lab")),
      tabItem(tabName = "family_office_architecture", family_office_architecture_ui("family_office_architecture")),

      # -- Research and Academia --
      tabItem(tabName = "research_riddiough", research_riddiough_ui("research_riddiough")),
      tabItem(tabName = "research_algodynamix", research_algodynamix_ui("research_algodynamix"))
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

  # -- Intro Tabs --
  price_analysis_server("price_analysis", data_manager)
  market_overview_server("market_overview", data_manager)
  technical_indicators_server("technical_indicators", data_manager)
  ig_login_server("ig_login", data_manager)

  # -- Futures, Options & FX --
  futures_mechanics_server("futures_mechanics", data_manager)
  pricing_basis_carry_server("pricing_basis_carry", data_manager)
  yield_curves_server("yield_curves", data_manager)
  options_pnl_server("options_pnl", data_manager)
  fx_fundamentals_server("fx_fundamentals", data_manager)

  # -- Hedging Strategies --
  hedge_ratio_calculator_server("hedge_ratio_calculator", data_manager)
  basis_risk_simulator_server("basis_risk_simulator", data_manager)
  long_hedge_concept_server("long_hedge_concept", data_manager)

  # -- Extended Indicators --
  moving_averages_server("moving_averages", data_manager)
  momentum_roc_server("momentum_roc", data_manager)
  volume_indicators_server("volume_indicators", data_manager)
  parabolic_sar_server("parabolic_sar", data_manager)
  pivot_points_server("pivot_points", data_manager)

  # -- Psychology & Macro --
  ten_steps_server("ten_steps", data_manager)
  macro_calendar_reference_server("macro_calendar_reference", data_manager)

  # -- Economic Calendars --
  economic_calendar_te_server("economic_calendar_te", data_manager)
  economic_calendar_fmp_server("economic_calendar_fmp", data_manager)
  econ_trend_summary_server("econ_trend_summary", api_manager)
  econ_calendar_export_server("econ_calendar_export", api_manager)
  econ_calendar_viz_server("econ_calendar_viz", api_manager)
  econ_calendar_live_link_server("econ_calendar_live_link", api_manager)

  # -- API Configuration --
  econ_bigquery_auth_server("econ_bigquery_auth", api_manager)
  econ_claude_config_server("econ_claude_config", api_manager)
  trello_jira_config_server("trello_jira_config", api_manager)
  debug_console_server("debug_console")

  # -- Risk & Portfolio Analytics --
  volatility_analysis_server("volatility_analysis", data_manager)
  risk_metrics_server("risk_metrics", data_manager)
  advanced_metrics_server("advanced_metrics", data_manager)
  composite_analysis_server("composite_analysis", data_manager)

  # -- Commodities for Mobility --
  mobility_commodities_server("mobility_commodities", data_manager)

  # -- External Sources --
  energy_satellite_map_server("energy_satellite_map")
  data_enrichment_server("data_enrichment")

  # -- Strategy for Business --
  hedge_fund_strategy_server("hedge_fund_strategy")
  portfolio_lab_server("portfolio_lab")
  family_office_architecture_server("family_office_architecture")

  # -- Research and Academia --
  research_riddiough_server("research_riddiough")
  research_algodynamix_server("research_algodynamix")
}

shinyApp(ui, server)
