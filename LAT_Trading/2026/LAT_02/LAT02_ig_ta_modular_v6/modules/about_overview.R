# modules/about_overview.R

about_overview_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = TRUE, status = "primary", title = NULL,
        div(
          style = paste0(
            "background: linear-gradient(135deg, #002C3C 0%, #005f5a 60%, #00A39A 100%);",
            "border-radius: 10px; padding: 32px 36px; color: #ffffff;"
          ),
          fluidRow(
            column(8,
              tags$h1("Joseph Francisco Zubizarreta", style = "font-size:28px; font-weight:700; margin:0 0 6px 0; color:#ffffff;"),
              tags$p(
                HTML("<strong style='color:#7fffd4;'>MBA Alumni</strong> &nbsp;|&nbsp;
                      Judge Business School, University of Cambridge &nbsp;|&nbsp;
                      <strong style='color:#7fffd4;'>Technical &amp; Commercial Director</strong>, Atera Analytics"),
                style = "font-size:15px; margin:0 0 18px 0; color:#d0f0ec;"
              ),
              tags$p(HTML(paste0(
                "Atera Analytics is an entrepreneurial platform built on the principle that complex, ",
                "production-grade analytical applications should be accessible to domain experts — not just ",
                "software engineers. This app is one artefact of that mission: a multi-asset trading and ",
                "technical analysis suite spanning <strong>Cryptocurrencies</strong>, <strong>Equities</strong>, ",
                "<strong>Commodities</strong>, <strong>Forex</strong>, and <strong>IG (CFDs)</strong>, built ",
                "around the Level 5 Diploma in Applied Financial Trading reference curriculum."
              )), style = "font-size:14px; line-height:1.7; color:#e8f8f6; margin:0 0 14px 0;"),
              tags$p(HTML(paste0(
                "Combining live market data (Yahoo Finance and the IG REST API), live economic calendars ",
                "(Trading Economics and Financial Modeling Prep), course-aligned derivatives calculators, ",
                "candlestick pattern detection, and institutional-grade risk metrics — all within a single ",
                "deployable Shiny application. The sidebar is organised into topic groups &mdash; click a ",
                "group to expand its individual tabs."
              )), style = "font-size:14px; line-height:1.7; color:#e8f8f6; margin:0;")
            ),
            column(4,
              div(style = "background:rgba(255,255,255,0.08); border-radius:10px; padding:20px 22px; text-align:center; height:100%;",
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
    
    fluidRow(
      box(
        width = 12, solidHeader = TRUE, status = "primary", title = "Asset Classes Covered",
        fluidRow(
          column(2, div(style = "text-align:center; padding:12px;",
            icon("bitcoin", style = "font-size:32px; color:#f39c12; margin-bottom:8px;"),
            tags$h5("Cryptocurrencies", style = "color:#2c3e50; font-weight:700; margin:0 0 4px 0; font-size:13px;"),
            tags$p("BTC, ETH, ADA. 24/7 data.", style = "font-size:11px; color:#777;")
          )),
          column(2, div(style = "text-align:center; padding:12px; border-left:1px solid #e8e8e8;",
            icon("chart-line", style = "font-size:32px; color:#3498db; margin-bottom:8px;"),
            tags$h5("Equities", style = "color:#2c3e50; font-weight:700; margin:0 0 4px 0; font-size:13px;"),
            tags$p("NVDA, MSFT, AAPL.", style = "font-size:11px; color:#777;")
          )),
          column(2, div(style = "text-align:center; padding:12px; border-left:1px solid #e8e8e8;",
            icon("oil-well", style = "font-size:32px; color:#e67e22; margin-bottom:8px;"),
            tags$h5("Commodities", style = "color:#2c3e50; font-weight:700; margin:0 0 4px 0; font-size:13px;"),
            tags$p("Gold, Oil, Nat Gas.", style = "font-size:11px; color:#777;")
          )),
          column(3, div(style = "text-align:center; padding:12px; border-left:1px solid #e8e8e8;",
            icon("money-bill-transfer", style = "font-size:32px; color:#16a085; margin-bottom:8px;"),
            tags$h5("Forex", style = "color:#2c3e50; font-weight:700; margin:0 0 4px 0; font-size:13px;"),
            tags$p("EUR/USD, GBP/USD, USD/JPY.", style = "font-size:11px; color:#777;")
          )),
          column(3, div(style = "text-align:center; padding:12px; border-left:1px solid #e8e8e8;",
            icon("key", style = "font-size:32px; color:#9b59b6; margin-bottom:8px;"),
            tags$h5("IG (CFDs)", style = "color:#2c3e50; font-weight:700; margin:0 0 4px 0; font-size:13px;"),
            tags$p("Indices, FX, commodities via IG's live API.", style = "font-size:11px; color:#777;")
          ))
        )
      )
    ),
    
    fluidRow(
      box(
        width = 12, solidHeader = TRUE, status = "primary", title = "Sidebar Groups — Overview",
        tags$p(paste0(
          "Grouped by topic in the sidebar: Intro Tabs (Price Analysis, Market Overview, Technical Indicators, ",
          "IG Login), Futures/Options & FX, Hedging Strategies, Extended Indicators, Psychology & Macro, ",
          "Economic Calendars (Trading Economics + Financial Modeling Prep), Risk & Portfolio Analytics, and ",
          "About & Feedback (this group). Click any group name to expand its individual tabs."
        ), style = "font-size:12.5px; color:#666; line-height:1.6; margin-bottom:16px;"),
        
        lapply(list(
          list(icon = "chart-simple", title = "Price Analysis", color = "#2980b9",
               text = "Configurable price chart, OHLC candlestick chart, and a 20-pattern candlestick detection engine that boxes and labels each detected pattern (Doji, Hammer, Engulfing, Morning/Evening Star, and 15 others) directly on the chart."),
          list(icon = "chart-line", title = "Market Overview", color = "#008A82",
               text = "The entry point for any asset: value boxes for price/change/volume/range, a combined price-volume chart, and summary statistics."),
          list(icon = "chart-bar", title = "Technical Indicators", color = "#8e44ad",
               text = "SMA, EMA, Bollinger Bands, RSI, MACD, and Stochastic Oscillator, each independently configurable, with a plain-language signals panel."),
          list(icon = "key", title = "IG Login", color = "#e67e22",
               text = "Authenticate against IG's REST API (Demo or Live), test the connection, and search for EPIC codes to use as an asset class elsewhere in the app."),
          list(icon = "right-left", title = "Futures, Options & FX", color = "#2c3e50",
               text = "Five tabs: Futures Mechanics, Pricing/Basis/Carry, Yield Curves, Options P&L (with a contingent liability classifier), and FX Fundamentals (pip/margin & cross-rate calculators) — closely following the Futures & Options and Introduction to FX reference manuals."),
          list(icon = "shield-halved", title = "Hedging Strategies", color = "#27ae60",
               text = "A hedge ratio calculator and a basis risk simulator that reproduce the reference manual's FTSE 100 portfolio hedge and wheat/barley farmer worked examples exactly, plus a conceptual Long Hedge tab."),
          list(icon = "chart-area", title = "Extended Indicators", color = "#16a085",
               text = "Five tabs: Moving Averages (SMA/WMA/EMA), Momentum & ROC, Volume Indicators (OBV/WOBV), Parabolic SAR, and Pivot Points — the Technical Analysis Formulae manual in full."),
          list(icon = "brain", title = "Psychology & Macro", color = "#f39c12",
               text = "The Ten Steps to Becoming a Successful Trader as reference cards, plus a US Macro Calendar reference table with a beat/miss reaction simulator."),
          list(icon = "calendar-days", title = "Economic Calendars", color = "#3498db",
               text = "Two independent live economic calendar sources — Trading Economics (guest or registered access) and Financial Modeling Prep — for cross-checking actual/forecast/previous/importance data."),
          list(icon = "triangle-exclamation", title = "Risk & Portfolio Analytics", color = "#e74c3c",
               text = "Four tabs of general quantitative tooling: Volatility (rolling vol, clustering, regimes), Risk Metrics (VaR, Expected Shortfall, stress tests), Advanced Metrics (Sharpe/Sortino/Calmar/Omega), and Composite Analysis (multi-asset correlation and comparison).")
        ), function(m) {
          div(style = "margin-bottom:20px;",
            fluidRow(
              column(1, div(style = "text-align:center; padding-top:4px;", icon(m$icon, style = paste0("font-size:26px; color:", m$color, ";")))),
              column(11,
                tags$h5(m$title, style = paste0("color:#002C3C; font-weight:700; margin:0 0 4px 0;")),
                tags$p(m$text, style = "font-size:12.5px; color:#444; line-height:1.6; margin:0;")
              )
            ),
            tags$hr(style = "border-color:#e8eeee; margin:14px 0 0 0;")
          )
        })
      )
    ),
    
    fluidRow(
      box(
        width = 12, solidHeader = TRUE, status = "info", title = "Data & Analysis Flow",
        div(style = "padding: 10px 0;",
          fluidRow(
            column(4,
              div(style = paste0("background:linear-gradient(135deg,#002C3C,#005f5a); color:#fff;border-radius:8px;",
                "padding:16px;text-align:center;height:100px;display:flex;flex-direction:column;justify-content:center;"),
                icon("database", style = "font-size:20px; margin-bottom:6px;"),
                tags$strong("Multi-Source Data Layer", style = "display:block; font-size:13px;"),
                tags$span("Yahoo Finance \u00b7 IG REST API \u00b7 TE/FMP Calendars", style = "font-size:11px; color:#b2e0db;")
              )
            ),
            column(1, div(style = "display:flex;align-items:center;justify-content:center;height:100px;",
              icon("arrow-right", style = "font-size:22px; color:#008A82;"))),
            column(3,
              div(style = paste0("background:linear-gradient(135deg,#005f5a,#008A82); color:#fff;border-radius:8px;",
                "padding:16px;text-align:center;height:100px;display:flex;flex-direction:column;justify-content:center;"),
                icon("gears", style = "font-size:20px; margin-bottom:6px;"),
                tags$strong("R Processing Layer", style = "display:block; font-size:13px;"),
                tags$span("dplyr \u00b7 TTR \u00b7 zoo \u00b7 quantmod \u00b7 httr", style = "font-size:11px; color:#d0f0ec;")
              )
            ),
            column(1, div(style = "display:flex;align-items:center;justify-content:center;height:100px;",
              icon("arrow-right", style = "font-size:22px; color:#008A82;"))),
            column(3,
              div(style = paste0("background:linear-gradient(135deg,#008A82,#00A39A); color:#fff;border-radius:8px;",
                "padding:16px;text-align:center;height:100px;display:flex;flex-direction:column;justify-content:center;"),
                icon("display", style = "font-size:20px; margin-bottom:6px;"),
                tags$strong("Interactive Visualisation", style = "display:block; font-size:13px;"),
                tags$span("plotly \u00b7 DT \u00b7 shinydashboard", style = "font-size:11px; color:#e8f8f6;")
              )
            )
          )
        )
      )
    )
  )
}

about_overview_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    # Fully static content — no server-side outputs needed.
    session$onSessionEnded(function() {})
  })
}
