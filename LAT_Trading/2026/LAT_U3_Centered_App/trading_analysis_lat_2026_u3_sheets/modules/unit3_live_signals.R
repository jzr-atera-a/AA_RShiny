# modules/unit3_live_signals.R
#
# "Unit 3 - Live Market Signals" - a genuine live trading tool, scoped
# deliberately to stop short of the assessed deliverable itself:
#
#   INCLUDED (pure trading/technical-analysis functionality):
#     - Regime detection (ADX/DI) on whatever asset/resolution is currently
#       selected in the sidebar (same shared data_manager every other tab uses)
#     - Trigger flags for the three named Unit 2/3 strategies: Pivot Point
#       Bounce, Straddle breakout, Holy Grail pullback
#     - A price chart overlaying pivot levels and the moving average used by
#       the Holy Grail check
#     - An "Active Alerts" list summarising which triggers are live right now
#
#   DELIBERATELY EXCLUDED:
#     - No trade log, no computed Task 2 performance metrics (win rate, R:R
#       achieved, drawdown, adherence), no Task 3 SWOT auto-population. Task 2
#       and Task 3 ask the student to evaluate their OWN performance and OWN
#       reasoning - including explaining deviations psychologically - which a
#       tool cannot do on their behalf without removing the very judgement
#       being assessed. Trade logging already exists, unchanged, in the
#       Trade Journal group (modules/trade_sheet.R).
#
#   This tab flags a condition and lets the student decide; it never places a
#   trade, never writes a performance narrative, and never drafts a strategy
#   evaluation. The "How to Use This Tool & Approach Unit 3" section below is
#   guidance on process, not a source of answer text.

# ===========================================================================
# PURE LOGIC - no Shiny reactivity, kept separate and testable on their own.
# ===========================================================================

# Signal logic comes from R/utils_unit3_rules.R (LAT course rules). These wrappers keep this tab's
# active / detail format. Plan regime rule: ADX above 30 trend, below 20 range, 20 to 30 no trade.
u3ls_regime <- function(data, n = 14) u3r_regime(data, n)

u3ls_pivot_levels <- function(data, fx = FALSE) {
  pr <- u3r_prior_session(data, fx); if (is.null(pr)) return(NULL)
  u3r_pivots(pr$high, pr$low, pr$close)
}

u3ls_is_intraday <- function(data, res) inherits(data$Date, "POSIXct") && !is.null(res) && !identical(res, "1d")

u3ls_trigger_pivot_bounce <- function(data, res = "1d", fx = FALSE) {
  lv <- u3ls_pivot_levels(data, fx)
  if (is.null(lv)) return(list(active = FALSE, detail = "No prior session to build pivot levels from."))
  if (!u3ls_is_intraday(data, res)) return(list(active = FALSE, detail = "The pivot bounce needs intraday bars (the course suggests 5-minute). Switch Data Resolution in the sidebar."))
  ids <- u3r_session_id(data$Date, fx); today <- data[ids == ids[length(ids)], , drop = FALSE]
  r <- u3r_pivot_bounce(if (nrow(today) >= 20) today else tail(data, 60), lv)
  reg <- u3r_regime(data)
  if (isTRUE(reg$ok) && reg$regime != "Range-bound" && (isTRUE(r$ready) || isTRUE(r$watch)))
    return(list(active = FALSE, detail = paste0("Plan rule: the bounce is used only when ADX is below 20 (now ", reg$adx, "). ", r$reason)))
  list(active = isTRUE(r$ready), detail = r$reason)
}

u3ls_trigger_straddle <- function(data, res = "1d", pip = 0.0001, spread = 1, buffer = 1) {
  r <- u3wb_straddle(data, res, pip, spread, buffer)
  list(active = isTRUE(r$ready), detail = r$reason)
}

u3ls_trigger_holy_grail <- function(data) {
  r <- u3r_holy_grail(data)
  list(active = isTRUE(r$ready), detail = r$reason)
}

# ===========================================================================
# GUIDANCE SECTION HELPER
# ===========================================================================

u3ls_step <- function(title, ...) {
  tags$div(class = "ua-task",
    style = "background: #ffffff; border: 1px solid #e2e8f0; border-left: 5px solid #008A82; border-radius: 10px; padding: 16px 20px; margin-bottom: 18px; box-shadow: 0 1px 4px rgba(0,44,60,0.06);",
    tags$div(class = "ua-task-head",
      style = "margin-bottom: 10px; padding-bottom: 8px; border-bottom: 1px solid #e2e8f0;",
      tags$div(class = "ua-task-title", style = "font-size: 16px; font-weight: 800; color: #002C3C;", title)
    ),
    tags$div(class = "ua-task-body", style = "font-size: 13.5px; line-height: 1.75; color: #2c3e50;", ...)
  )
}

# ===========================================================================
# UI
# ===========================================================================

unit3_live_signals_ui <- function(id) {
  ns <- NS(id)

  tagList(
    ua_intro("Unit 3", "Live Market Signals", "\u2014", "\u2014",
             "A live regime/trigger tool for the strategies in your trading plan. It flags a condition when it's met \u2014 it never places a trade, and it never writes any part of your Task 2 or Task 3 answer for you."),

    fluidRow(
      valueBoxOutput(ns("regimeBox"), width = 3),
      valueBoxOutput(ns("adxBox"),    width = 3),
      valueBoxOutput(ns("diPosBox"),  width = 3),
      valueBoxOutput(ns("diNegBox"),  width = 3)
    ),

    fluidRow(
      box(title = "Price Chart \u2014 Pivot Levels & 20-Period EMA", status = "primary", solidHeader = TRUE, width = 12,
          withSpinner(plotlyOutput(ns("priceChart"), height = "420px")))
    ),

    fluidRow(
      box(title = "Active Alerts", status = "warning", solidHeader = TRUE, width = 12,
          uiOutput(ns("alertsList")))
    ),

    fluidRow(
      box(title = "Strategy Trigger Status", status = "info", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4, tags$h5("Pivot Point Bounce"), uiOutput(ns("triggerPivotUi"))),
            column(4, tags$h5("Straddle Breakout"),  uiOutput(ns("triggerStraddleUi"))),
            column(4, tags$h5("Holy Grail"),         uiOutput(ns("triggerHolyGrailUi")))
          ))
    ),

    fluidRow(
      box(title = "Calendar Data for Analysis", status = "danger", solidHeader = TRUE, width = 12,
          tags$p("Populated by clicking \u201cSend to Live Signals\u201d on Economic Calendars \u2192 Visualisation \u2014 whatever date range/asset class/asset was loaded there arrives here automatically, no separate query. Rows matching your currently selected trading asset are highlighted.",
                 style = "font-size:11.5px; color:#888; margin-top:-4px;"),
          uiOutput(ns("calStatus")),
          uiOutput(ns("calEventsList"))
      )
    ),

    tags$div(style = "margin-top:24px; padding:10px 14px; background:#ffffff; border-left:4px solid #008A82; border-radius:4px; font-size:12.5px; color:#2c3e50;",
      tags$b("Guidance moved. "), "The guide to approaching Unit 3 (what these tools do and what you still write yourself), the course rules and the Trading Plan Guide are now in ", tags$b("Unit Assignments \u2192 Unit 3 \u2013 Workbench"), ".")
  )
}

# Guidance on approaching Unit 3 (process only, no answer text). Shown in Unit 3 - Workbench > How to Use.
u3ls_guidance_section <- function() {
  tagList(
    u3ls_step("What Task 1 needs \u2014 and how this tool supports it",
      tags$p("Task 1 asks for a structured trading plan: asset justification, objective, decision process, trigger events, profit targets, and trade management. The Live Signals tabs operationalise two of those pieces \u2014 decision process and trigger events \u2014 by showing the live regime (ADX/DI) and flagging exactly when one of your plan's named strategies meets its entry condition."),
      tags$p("It does not decide for you. Sizing the trade, setting the actual stop and target, and choosing whether to act on a flagged trigger all remain your call \u2014 write your plan's rules first, then use this tool to watch for them.")
    ),

    u3ls_step("How to use the Economic Calendar alongside this tool",
      tags$p("On Economic Calendars \u2192 Visualisation, set the date range and asset class/asset you're about to trade, click Load / Refresh, then click Send to Live Signals \u2014 that exact filtered dataset appears in the \u201cCalendar Data for Analysis\u201d panel on Unit 3 \u2013 Live Signals automatically. Rows matching your currently selected trading asset are highlighted, so you can see at a glance whether a major release is relevant to the instrument you're about to trade."),
      tags$p("Use this before the trading week to decide in advance \u2014 as part of your plan, not in the moment \u2014 whether to trade through a known event, widen a stop, or sit it out. If a trigger fires here that looks unusual, check whether a sent-over calendar event lines up with that date and asset. That's a real, checkable fact you can cite in Task 2 when explaining a deviation \u2014 for example, \u201cI widened my stop ahead of the NFP release logged for that day\u201d is a specific, evidenced statement rather than a vague one.")
    ),

    u3ls_step("What you still need to do yourself for Task 2",
      tags$p("This tool and the calendar give you context and triggers \u2014 not your performance write-up. For Task 2 you still need to:"),
      tags$ul(
        tags$li("Log every trade yourself, with your reasoning, in the Trade Journal \u2192 Individual Trade Sheet."),
        tags$li("Calculate your own performance figures from your own log \u2014 win rate, risk:reward achieved versus planned, drawdown, how often you actually followed your plan's rules."),
        tags$li("Write your own honest account of where you deviated from the plan and why \u2014 using anything you noticed here (a trigger that fired, a calendar event you checked) as supporting evidence, not as a substitute for your own analysis of the deviation.")
      )
    ),

    u3ls_step("What you still need to do yourself for Task 3",
      tags$p("Task 3 asks you to evaluate the strategy you actually used \u2014 its strengths and weaknesses, based on your own experience running it. The Live Signals tabs can show you when a trigger fired accurately versus when it gave a false signal, but you need to:"),
      tags$ul(
        tags$li("Reflect on how your chosen strategy actually performed for you over the period \u2014 not in the abstract, but in the specific market conditions you traded through."),
        tags$li("Write your own strengths/weaknesses assessment, citing specific instances \u2014 for example, noting that a Holy Grail trigger worked well during a clearly trending week but produced false signals during a choppier period, and explaining why that pattern makes sense given what ADX was showing at the time.")
      )
    )
  )
}

u3ls_asset_aliases <- function(ticker, asset_class) {
  # Maps this app's ticker-style current_asset (Yahoo Finance style, e.g.
  # "EURUSD=X", "GC=F", "BTC-USD") to fragments likely to appear in the
  # calendar's free-text specific_asset field (Claude-written, e.g. "Gold",
  # "EUR/USD", "Bitcoin"). Matching is fuzzy on purpose - the calendar's
  # asset names aren't a fixed enum, so this errs toward a short list of
  # known aliases plus the asset class name itself, rather than an exact map.
  t <- toupper(ticker %||% "")
  known <- list(
    "EURUSD" = c("EUR/USD", "EURUSD"), "GBPUSD" = c("GBP/USD", "GBPUSD"),
    "USDJPY" = c("USD/JPY", "USDJPY"), "GC=F"   = c("GOLD", "XAU"),
    "CL=F"   = c("CRUDE", "WTI", "OIL"), "BZ=F"  = c("BRENT", "CRUDE OIL"),
    "HG=F"   = c("COPPER"), "NG=F"    = c("NATURAL GAS"),
    "BTC-USD"= c("BITCOIN", "BTC"), "ETH-USD" = c("ETHEREUM", "ETH"),
    "^NDX"   = c("NASDAQ"), "QQQ"     = c("NASDAQ"), "^GSPC" = c("S&P 500", "S&P500"),
    "DX-Y.NYB" = c("DXY", "DOLLAR INDEX")
  )
  aliases <- character(0)
  for (key in names(known)) if (grepl(key, t, fixed = TRUE)) aliases <- c(aliases, known[[key]])
  # Fall back to the asset class name itself (e.g. "forex", "commodities")
  # so at least a class-level match is possible when no specific alias hits.
  c(aliases, toupper(asset_class %||% ""))
}

u3ls_row_matches_asset <- function(specific_asset, asset_class_col, aliases) {
  hay <- toupper(paste(specific_asset %||% "", asset_class_col %||% ""))
  any(vapply(aliases[nchar(aliases) > 0], function(a) grepl(a, hay, fixed = TRUE), logical(1)))
}

# ===========================================================================
# SERVER
# ===========================================================================

unit3_live_signals_server <- function(id, data_manager, api_manager, shared_econ_state) {
  moduleServer(id, function(input, output, session) {

    observe({
      data_manager$state_trigger()
    })

    is_fx <- reactive({ data_manager$state_trigger(); u3wb_is_fx(data_manager$current_asset_class, data_manager$current_asset) })

    get_signal_data <- reactive({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      tail(data, 600)
    })

    # Fires whenever Visualisation's "Send to Live Signals" button is
    # clicked (transfer_ts increments on every send) - not tied to any
    # independent query here, so there's no separate date-window filter
    # to fall out of sync with what's actually in the table.
    observeEvent(shared_econ_state$transfer_ts, {
      d <- shared_econ_state$transfer_df
      if (is.null(d) || nrow(d) == 0) return()

      d <- d[order(d$event_date), ]
      aliases <- u3ls_asset_aliases(data_manager$current_asset, data_manager$current_asset_class)

      event_ids <- unique(d$event_id)
      cards <- lapply(event_ids, function(eid) {
        rows <- d[d$event_id == eid, , drop = FALSE]
        ev <- rows[1, ]
        is_relevant <- any(mapply(u3ls_row_matches_asset, rows$specific_asset, rows$asset_class, MoreArgs = list(aliases = aliases)))
        affected <- paste(unique(rows$specific_asset), collapse = ", ")

        border_col <- if (is_relevant) "#e74c3c" else "#d0d7de"
        bg_col     <- if (is_relevant) "#fdf2f1" else "#ffffff"

        tags$div(style = sprintf("border-left: 4px solid %s; background:%s; border-radius:6px; padding:10px 14px; margin-bottom:8px;", border_col, bg_col),
          tags$div(style = "display:flex; justify-content:space-between; align-items:baseline; flex-wrap:wrap; gap:8px;",
            tags$strong(style = "color:#002C3C; font-size:13.5px;", as.character(ev$event_date), " \u2014 ", ev$event_name),
            tagList(
              tags$span(style = sprintf("background:%s; color:#fff; font-size:10px; font-weight:700; padding:2px 8px; border-radius:10px;",
                                          if (identical(ev$event_role, "MAIN")) "#008A82" else "#95a5a6"), ev$event_role),
              if (is_relevant) tags$span(style = "background:#e74c3c; color:#fff; font-size:10px; font-weight:700; padding:2px 8px; border-radius:10px; margin-left:6px;", "RELEVANT TO YOUR ASSET")
            )
          ),
          tags$p(style = "margin:6px 0 0 0; font-size:12px; color:#2c3e50;", ev$event_description),
          tags$p(style = "margin:4px 0 0 0; font-size:11px; color:#64748b;", tags$strong("Affects: "), affected,
                 " \u00b7 ", tags$strong("Importance: "), ev$event_importance)
        )
      })

      output$calStatus <- renderUI(tags$div(style="color:#27ae60; margin-top:6px;",
        icon("check-circle"), sprintf(" Received %d row(s) / %d event(s) for asset class \u201c%s\u201d from Visualisation.",
                                       nrow(d), length(event_ids), shared_econ_state$transfer_asset_class %||% "All")))
      output$calEventsList <- renderUI(tagList(cards))
    }, ignoreInit = TRUE)

    output$calStatus <- renderUI(tags$div())
    output$calEventsList <- renderUI(tags$div(style = "color:#7f8c8d; padding:10px;",
      "No data yet \u2014 go to Economic Calendars \u2192 Visualisation, load what you want to analyse, then click \u201cSend to Live Signals\u201d."))

    output$regimeBox <- renderValueBox({
      data <- get_signal_data()
      r <- u3ls_regime(data)
      valueBox(r$regime, "Current Regime", icon = icon("wave-square"),
                color = if (isTRUE(r$regime == "Trending")) "green" else if (isTRUE(r$regime == "Range-bound")) "aqua" else "yellow")
    })
    output$adxBox <- renderValueBox({
      data <- get_signal_data()
      r <- u3ls_regime(data)
      valueBox(if (is.na(r$adx)) "\u2014" else r$adx, "ADX (14)", icon = icon("gauge-high"), color = "aqua")
    })
    output$diPosBox <- renderValueBox({
      data <- get_signal_data()
      r <- u3ls_regime(data)
      valueBox(if (is.na(r$di_pos)) "\u2014" else r$di_pos, "+DI", icon = icon("arrow-trend-up"), color = "teal")
    })
    output$diNegBox <- renderValueBox({
      data <- get_signal_data()
      r <- u3ls_regime(data)
      valueBox(if (is.na(r$di_neg)) "\u2014" else r$di_neg, "-DI", icon = icon("arrow-trend-down"), color = "purple")
    })

    render_trigger_ui <- function(trig) {
      col <- if (isTRUE(trig$active)) "#27ae60" else "#95a5a6"
      icn <- if (isTRUE(trig$active)) "bolt" else "circle-pause"
      tags$div(style = paste0("border-left: 4px solid ", col, "; padding: 8px 12px; background: #f6f8fb; border-radius: 6px;"),
        tags$strong(style = paste0("color:", col, ";"), icon(icn), if (isTRUE(trig$active)) " ACTIVE" else " Not active"),
        tags$p(style = "margin: 6px 0 0 0; font-size: 12.5px; color:#2c3e50;", trig$detail)
      )
    }

    output$triggerPivotUi <- renderUI({
      render_trigger_ui(u3ls_trigger_pivot_bounce(get_signal_data(), data_manager$resolution, is_fx()))
    })
    output$triggerStraddleUi <- renderUI({
      render_trigger_ui(u3ls_trigger_straddle(get_signal_data(), data_manager$resolution, u3wb_default_pip(data_manager$current_asset)))
    })
    output$triggerHolyGrailUi <- renderUI({
      render_trigger_ui(u3ls_trigger_holy_grail(get_signal_data()))
    })

    output$alertsList <- renderUI({
      data <- get_signal_data()
      triggers <- list(
        "Pivot Point Bounce" = u3ls_trigger_pivot_bounce(data, data_manager$resolution, is_fx()),
        "Straddle Breakout"  = u3ls_trigger_straddle(data, data_manager$resolution, u3wb_default_pip(data_manager$current_asset)),
        "Holy Grail"         = u3ls_trigger_holy_grail(data)
      )
      active <- triggers[sapply(triggers, function(t) isTRUE(t$active))]
      if (length(active) == 0) {
        return(tags$p(style = "color:#7f8c8d;", "No triggers are currently active for the selected asset/resolution."))
      }
      tagList(lapply(names(active), function(nm) {
        tags$div(style = "padding:8px 0; border-bottom:1px solid #e2e8f0;",
          tags$strong(style = "color:#27ae60;", icon("bolt"), paste0(" ", nm)),
          tags$span(style = "color:#2c3e50; margin-left:8px; font-size:12.5px;", active[[nm]]$detail)
        )
      }))
    })

    output$priceChart <- renderPlotly({
      data <- get_signal_data()
      req(nrow(data) > 5)
      levels <- u3ls_pivot_levels(data, is_fx())
      ma <- as.numeric(TTR::EMA(data$Close, 20))

      p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                    line = list(color = "#002C3C", width = 2), name = "Close") %>%
        add_trace(y = ma, name = "EMA(20)", line = list(color = "#008A82", width = 1.5, dash = "dot"))

      if (!is.null(levels)) {
        for (nm in names(levels)) {
          p <- p %>% add_lines(x = range(data$Date), y = rep(levels[[nm]], 2), name = nm,
                                 line = list(color = "#e67e22", width = 1, dash = "dash"),
                                 showlegend = FALSE, inherit = FALSE)
        }
      }

      p %>% layout(title = "Live Price with Pivot Levels & 20-Period EMA",
                    xaxis = list(title = ""), yaxis = list(title = "Price"),
                    plot_bgcolor = "white", paper_bgcolor = "white")
    })

    session$onSessionEnded(function() {})
  })
}
