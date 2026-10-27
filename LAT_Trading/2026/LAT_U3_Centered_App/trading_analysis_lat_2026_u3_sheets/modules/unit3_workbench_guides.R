# modules/unit3_workbench_guides.R
# Reference/guidance content for the "Unit 3 - Workbench" tab, written from the London Academy of Trading
# course material (paraphrased and organised; read the originals for the full text):
#   Trade Plan Template; How to Develop a Structured Trading Plan; The Holy Grail Trade;
#   Short Term Trader's Pivot Point System; Reference Manual: Straddle Trade; The Rule of Five (Week 7).
# Nothing here is answer text for the assessed tasks: it explains the course rules, lists what each plan
# section asks for, and offers calculators. The plan itself, and every reason in it, is the student's own.

u3wb_gx <- function(...) tags$div(style = "font-size:12.5px; color:#2c3e50; line-height:1.7;", ...)
u3wb_gul <- function(...) tags$ul(style = "font-size:12.5px; color:#2c3e50; line-height:1.75; padding-left:20px; margin-bottom:6px;", ...)
u3wb_gbox <- function(title, ..., status = "primary", collapsed = FALSE) box(width = 12, status = status, solidHeader = TRUE, title = title, collapsible = TRUE, collapsed = collapsed, ...)
u3wb_gsrc <- function(...) tags$div(style = "font-size:11px; color:#64748b; margin-top:6px;", "Source: ", ...)

# ---------------------------------------------------------------- Tab: Trading Plan Guide
u3wb_plan_guide_tab <- function(ns) {
  tmpl <- data.frame(
    Section = c("Name", "Broad Objectives", "Risk Management", "Markets Traded", "Timeframes", "Data Sources", "Indicators Used",
                "Trade Setup", "Trigger", "Execution", "Target placement", "Stop loss placement", "Trade Management", "Pros and Cons"),
    `What the template asks you to write` = c(
      "Your name.",
      "What you aim to achieve by trading and by developing the strategy (the template's examples include sticking to a structured process and controlling emotions, and a monthly return range).",
      "Your risk limits: maximum risk per trade, daily, weekly and monthly, and a minimum reward-to-risk ratio.",
      "The assets you trade.",
      "Your average or target holding period for successful trades, and the chart timeframes you use.",
      "Where you source news and macro data.",
      "Each indicator, defined precisely (timeframe, period, what you look for). The template suggests rating each one out of 10 for importance.",
      "Your step-by-step process for finding a new trade, written separately for each strategy.",
      "The event that tells you to act.",
      "How you enter: time filters, price filters, what counts as an impulsive candle.",
      "Where you place targets and why; one target or several.",
      "Where you place the stop and why.",
      "What you do as the trade progresses: closing, trailing stops, manual exits, adding to winners, action before big news, overnight risk.",
      "What is easy or useful about the strategy so far, and what is hard to manage."),
    `Where this app helps` = c(
      "Trading Records &rarr; Connection &amp; Setup.",
      "Trading Records &rarr; Plan Spec (Objectives). Your own wording.",
      "Trading Records &rarr; Plan Spec (global): per trade, daily, weekly and monthly limits, combined cap, minimum RRR. Execution Plan has the position-size and combined-risk calculators.",
      "Morning Sheet instruments; Trading Records &rarr; Plan Spec.",
      "The Rule of Five table and selector on the Strategy Rules tab; Plan Spec timeframes.",
      "Plan Spec (Data sources); Economic Calendars group.",
      "Plan Spec (Indicators). The Strategy Rules tab states the exact settings the course uses for each strategy.",
      "Plan Spec per strategy (Set-up rule).",
      "Plan Spec per strategy (Trigger rule). The Live Signals tab flags when the course trigger conditions are met.",
      "Plan Spec per strategy (Execution rule). The straddle calculator shows entry buffers.",
      "Plan Spec per strategy (Target rule).",
      "Plan Spec per strategy (Stop rule).",
      "Plan Spec per strategy (Management rule); the Trades tab records every stop move and exit.",
      "Reviews tab (what worked, what did not). Your own judgement."),
    check.names = FALSE, stringsAsFactors = FALSE)
  tagList(
    u3wb_gbox("About this guide", status = "warning",
      u3wb_gx("The Trade Plan Template asks you to replace its worked examples with your own rules. This tab collects the course's guidance on building and keeping a plan, so that what you write in Trading Records and in your Task 1 plan is consistent with it. It does not write any part of your plan for you.")),
    u3wb_gbox("Trade Plan Template: section by section",
      ua_table(tmpl),
      u3wb_gsrc("Trade Plan Template (LAT). The template's example numbers (for instance 1% per trade, 2% daily, 5% weekly, 10% monthly, minimum reward-to-risk 1.0) are examples only: set limits that match your own plan.")),
    u3wb_gbox("S-T-E-M: the four parts of every trade",
      u3wb_gul(
        tags$li(tags$b("Set-up: "), "the conditions that must be in place before you look for an entry (regime, timeframe, indicator readings)."),
        tags$li(tags$b("Trigger: "), "the specific event that says act now (for example a Holy Grail 2-bar break, a pivot bounce break of Candle 1, a straddle order being hit)."),
        tags$li(tags$b("Execution: "), "how you enter once triggered: time filter, price filter, order type, and what counts as an impulsive candle."),
        tags$li(tags$b("Management: "), "what you do once in the trade: stop moves, trailing, partial exits, manual exits, action before news, overnight risk.")),
      u3wb_gsrc("How to Develop a Structured Trading Plan (LAT).")),
    u3wb_gbox("Plan building blocks from the course",
      u3wb_gul(
        tags$li(tags$b("Instruments and horizon: "), "decide what to trade and your time horizon, then develop a standard method for identifying trades."),
        tags$li(tags$b("Profit targets: "), "be realistic and honest. Unrealistic targets are never reached and only cause frustration."),
        tags$li(tags$b("Goals: "), "every business plan needs a goal; a trading career is a marathon. Enjoy bursts of profit but do not depend on them. Align goals with profit targets so you know where you should be after a month, a year or five years."),
        tags$li(tags$b("Risk limits: "), "before entering any trade know how many pips you will risk and how many dollars; keep the dollar risk consistent within a pre-set range. Only then calculate the size."),
        tags$li(tags$b("Position size (USD-based FX): "), "Trade size = $ risk x 10,000 / pip risk, and $ risk = trade size x pip risk / 10,000. Example from the slides: $800 risk with a 40-pip stop is a $200,000 trade; $100,000 with a 65-pip stop is $650 of risk. The calculator on the Strategy Rules tab does this."),
        tags$li(tags$b("Trade not going to plan: "), "never let a loser drift down to the stop. If you lose patience, either close manually at a small profit or loss, or move the stop aggressively toward the price."),
        tags$li(tags$b("Attitude: "), "after a winner ask whether you could have done better; after a loser take a lesson from it. Take something positive from every trade."),
        tags$li(tags$b("Review: "), "compare your execution with your strategy and goals. Are you following your rules? How are you tracking against weekly, monthly and yearly goals? The slides call this ten-minute review possibly the most useful ten minutes of your day.")),
      u3wb_gsrc("How to Develop a Structured Trading Plan (LAT).")),
    u3wb_gbox("When not to trade",
      u3wb_gx("Your state of mind affects performance. The course says to avoid trading when you are high (drink, medication, drugs), low (fed up, depressed), angry or tired. Your Morning Sheet has a stand-aside option for exactly this; record the reason in your own words."),
      u3wb_gsrc("How to Develop a Structured Trading Plan (LAT).")),
    u3wb_gbox("Straddle: points your tutor raised, and what the manual says",
      u3wb_gx("Define your straddle rules fully: the range you use, the distance of the resting orders, what happens if both sides fill, and how you allow for slippage and spread. The Reference Manual covers buffers (1 or 2 pips), the spread added to the overnight high, one-cancels-other orders, whipsaw, false breakouts and spread widening around news. See the Strategy Rules tab.")),
    u3wb_gbox("Correlated markets", collapsed = TRUE,
      u3wb_gx("Decide in advance how you treat setups that fire together in correlated markets (for example trade only the strongest, or split risk). Plan Spec has a field for this and the Execution Plan tab has a combined-risk calculator. The course material supplied does not prescribe a rule, so this is your own decision."))
  )
}

# ---------------------------------------------------------------- Tab: Strategy Rules (LAT)
u3wb_rules_tab <- function(ns) {
  tagList(
    u3wb_gbox("About this tab", status = "warning",
      u3wb_gx("The rules below are the course's, paraphrased. Live Signals applies them exactly as written, except where the course says a step is subjective (marked as your judgement). Compare with the original slides and the manual before you freeze your own plan.")),
    u3wb_gbox("Holy Grail (Linda Bradford Raschke, as taught by LAT)",
      u3wb_gx(tags$b("Idea: "), "a pullback from a recent momentum high will probably retest that high; the slides put the chance that a top is in place at around 10%. Trade only in the direction of the prevailing trend."),
      u3wb_gul(
        tags$li(tags$b("Sell rules: "), "(1) be in a downtrend; (2) 14-period ADX above 30; (3) a slow and corrective retracement to the 20-period ", tags$b("exponential"), " moving average, accompanied by a downturn in the ADX. The slides stress that you do not want an impulsive pullback; a rising wedge, triangle or flag is what you look for."),
        tags$li(tags$b("Entry (the subjective part): "), "sell into the retracement with half the position, or sell the break below the price pattern, or place a sell order below the 2-bar low once price reaches the 20 EMA."),
        tags$li(tags$b("Stop: "), "just above the retracement high (trailing just above the 2-bar high), or above the 20 EMA. If the 20 EMA fails to stop the rebound the set-up has failed: exit quickly."),
        tags$li(tags$b("Target: "), "the previous low, or run the trade with a trailing stop."),
        tags$li(tags$b("Buy rules (mirror): "), "ADX above 30, retracement to the 20 EMA with the ADX turning down, a buy order above the 2-bar high, a stop below the new 2-bar low (trailing at the 2-bar low) or just below the 20 EMA.")),
      u3wb_gx("You know early that you are wrong (the 20 EMA breaks, or price makes a new high in a downtrend), so cut quickly: the pattern is common and another will come."),
      u3wb_gsrc("The Holy Grail Trade (LAT slides).")),
    u3wb_gbox("Pivot points (floor-trader levels)",
      u3wb_gx("Seven levels from yesterday's high, low and close: the main pivot (PP), three supports and three resistances. For FX the close is taken at 5 pm New York, which the slides give as 10 pm GMT. They are predictive, not lagging, and many traders watch them, so markets often pause or reverse there, especially on the first approach in each direction."),
      ua_table(data.frame(Level = c("PP", "S1 / R1", "S2 / R2", "S3 / R3"),
        Formula = c("(H + L + C) / 3", "S1 = PP - (H - PP);  R1 = PP - (L - PP)", "S2 = PP - (R1 - S1);  R2 = PP + (R1 - S1)", "S3 = L - 2(H - PP);  R3 = H + 2(PP - L)"), stringsAsFactors = FALSE)),
      u3wb_gul(
        tags$li(tags$b("Bounce system (5-minute bars suggested, best when the market is active): "), "for a sell, price rises to touch a pivot; a later candle fails to make a new high (Candle 1); a later candle breaks the low of Candle 1. That generates the sell, with the next lower pivot as the target and the stop above the most recent high. A buy is the mirror image. If the bounce is insufficient and the entry level is not hit, do nothing."),
        tags$li(tags$b("Breakout system: "), "if price opens above PP and builds an early range, expect an upward break; the slides note this gives poor risk-to-reward but a high probability of short-term success. Targets are the next pivot levels."),
        tags$li(tags$b("Running trend days: "), "days when R3 or S3 is broken. Follow the move to the close at least, and consider holding overnight."),
        tags$li(tags$b("Confirmation: "), "the signal is the break or bounce off a pivot; moving averages, MACD, RSI or stochastics are used only to confirm.")),
      u3wb_gsrc("Short Term Trader's Pivot Point System (LAT slides). The slides' worked example (H 1.5438, L 1.5332, C 1.5413) gives PP 1.5394, R1 1.5457, R2 1.5500, R3 1.5563, S1 1.5351, S2 1.5288, S3 1.5245; this app reproduces it.")),
    u3wb_gbox("Straddle trade (Reference Manual)",
      u3wb_gx("A short-term breakout strategy: one buy stop order and one sell stop order either side of a tight range. It is not directional. It assumes that a break out of a recent range means one side has taken control, at least for a while. Duration runs from seconds to a few hours."),
      u3wb_gul(
        tags$li(tags$b("When to use: "), "early morning when the market wakes up (EUR/USD, GBP/USD and EUR/GBP historically best); around a significant news release; as price approaches the edges of a tight range."),
        tags$li(tags$b("Morning set-up: "), "(1) find the overnight high and low, 22:00 to 06:00 London time. Charts are built from the bid, so add the spread to the overnight high to get the highest ask. (2) Buy stop 1 or 2 pips above that high. (3) Its stop at the sell order's level, 1 or 2 pips below the overnight low. (4) Risk in pips = overnight range + buy buffer + stop buffer. (5) Target = risk, so the standard reward-to-risk is 1.0. (6) Mirror for the sell leg. Keep the buffer consistent."),
        tags$li(tags$b("Worked example from the manual: "), "high 1.18587 bid plus a 1-pip spread = 1.18597; low 1.18368; range 22.9 pips; risk 22.9 + 1 + 1 = 24.9 pips (the manual rounds this to 24). The calculator below reproduces it."),
        tags$li(tags$b("Management options: "), "take only the first trade and cancel the other (one-cancels-other, if your broker allows it; otherwise cancel by hand), or keep both live, which can recoup a first loss but can also double it."),
        tags$li(tags$b("Edge: "), "it relies on a hit rate above 50%, not a high reward-to-risk. You may tilt the ratio, for example a target of 1.5 times the stop, or a bigger target in the direction of a longer trend."),
        tags$li(tags$b("Drawbacks the manual lists: "), "whipsaw (mostly just after announcements; narrower targets are one option), false breakouts (time or price filters, applied the same way every time; waiting several minutes can miss the move), spread widening around news (a spread wider than the range can trigger entry and stop together; the only sure fix is not to straddle big news), and a low reward-to-risk."),
        tags$li(tags$b("When not to use: "), "no clear tight range; no obvious trigger level; volatility already high so orders fire before the event; or you already have a good idea of direction (use a simple buy or sell order). Check how your broker quotes prices around releases; some freeze or widen quotes.")),
      u3wb_gsrc("Reference Manual: Straddle Trade (LAT).")),
    u3wb_gbox("Rule of Five (choosing timeframes)",
      u3wb_gx("Markets move in different directions on different timeframes. Start from your average holding period for successful trades; that is your base timeframe (losing trades should be shorter). Then pick a major and a minor timeframe. The table is a guide, not a rule. Position yourself with the major trend and avoid counter-trend trades when all timeframes agree. Trigger entries and exits on the base timeframe, use the major timeframe for the bigger trend and the minor one for timing and confirmation."),
      selectInput(ns("r5_base"), tags$span(style = "color:#2c3e50; font-weight:600;", "Your base timeframe"), choices = u3r_rule_of_five$Base, selected = "2 hours", width = "260px"),
      uiOutput(ns("r5_out")),
      ua_table(u3r_rule_of_five),
      u3wb_gsrc("The Rule of Five, Week 7 (LAT).")),
    u3wb_gbox("Calculators",
      fluidRow(
        column(4, tags$h5(style = "color:#002C3C; font-weight:800;", "Pivot levels"),
          numericInput(ns("pv_h"), "Prior high", NA, step = 0.0001), numericInput(ns("pv_l"), "Prior low", NA, step = 0.0001), numericInput(ns("pv_c"), "Prior close", NA, step = 0.0001),
          uiOutput(ns("pv_out"))),
        column(4, tags$h5(style = "color:#002C3C; font-weight:800;", "Straddle levels"),
          numericInput(ns("sd_h"), "Range high (bid chart)", NA, step = 0.0001), numericInput(ns("sd_l"), "Range low (bid chart)", NA, step = 0.0001),
          fluidRow(column(4, numericInput(ns("sd_spread"), "Spread (pips)", 1, step = 0.1)), column(4, numericInput(ns("sd_buffer"), "Buffer (pips)", 1, step = 0.5)), column(4, numericInput(ns("sd_pip"), "Pip size", 0.0001, step = 0.0001))),
          numericInput(ns("sd_rrr"), "Reward : risk", 1, step = 0.25),
          actionButton(ns("sd_example"), "Load the manual's example", class = "btn-sm btn-default"),
          uiOutput(ns("sd_out"))),
        column(4, tags$h5(style = "color:#002C3C; font-weight:800;", "Trade size (USD-based FX, LAT method)"),
          numericInput(ns("ls_risk"), "$ you will risk", NA, step = 10), numericInput(ns("ls_pips"), "Stop distance (pips)", NA, step = 1),
          uiOutput(ns("ls_out")), tags$hr(),
          numericInput(ns("ls_size"), "Or: trade size ($ units)", NA, step = 1000), numericInput(ns("ls_pips2"), "Stop distance (pips)", NA, step = 1),
          uiOutput(ns("ls_out2")))),
      u3wb_gx(style = "color:#64748b; font-size:11.5px;", "Spread-bet platforms size in pounds per point: the same risk gives stake per pip = risk in pounds / stop pips. The Execution Plan tab has that version."))
  )
}

# ---------------------------------------------------------------- server pieces (call inside the module server)
u3wb_guides_server <- function(input, output, session) {
  cell <- function(txt, val) tags$div(style = "display:flex; justify-content:space-between; font-family:monospace; font-size:12px; padding:2px 0; border-bottom:1px solid #eef2f6; color:#2c3e50;", tags$span(txt), tags$span(val))
  output$pv_out <- renderUI({
    v <- c(input$pv_h, input$pv_l, input$pv_c); if (length(v) < 3 || any(!is.finite(v)) || input$pv_h < input$pv_l) return(tags$div(style = "color:#64748b; font-size:12px;", "Enter the prior session's high, low and close."))
    p <- u3r_pivots(input$pv_h, input$pv_l, input$pv_c); tags$div(style = "margin-top:6px;", lapply(names(p), function(n) cell(n, format(round(p[[n]], 5), nsmall = 4))))
  })
  observeEvent(input$sd_example, { updateNumericInput(session, "sd_h", value = 1.18587); updateNumericInput(session, "sd_l", value = 1.18368); updateNumericInput(session, "sd_spread", value = 1); updateNumericInput(session, "sd_buffer", value = 1); updateNumericInput(session, "sd_pip", value = 0.0001); updateNumericInput(session, "sd_rrr", value = 1) })
  output$sd_out <- renderUI({
    pip <- if (is.finite(input$sd_pip) && input$sd_pip > 0) input$sd_pip else NA
    st <- if (is.na(pip)) NULL else u3r_straddle(input$sd_h, input$sd_l, spread = input$sd_spread, buffer = input$sd_buffer, pip = pip, rrr = if (is.finite(input$sd_rrr)) input$sd_rrr else 1)
    if (is.null(st)) return(tags$div(style = "color:#64748b; font-size:12px; margin-top:8px;", "Enter the range high and low (the high must be above the low)."))
    f <- function(x) format(round(x, 5), nsmall = 4)
    tags$div(style = "margin-top:8px;", cell("Range incl. spread (pips)", sprintf("%.1f", st$range_pips)), cell("Risk (pips)", sprintf("%.1f", st$risk_pips)),
      cell("Buy stop", f(st$buy_entry)), cell("  stop loss", f(st$buy_stop)), cell("  target", f(st$buy_target)),
      cell("Sell stop", f(st$sell_entry)), cell("  stop loss", f(st$sell_stop)), cell("  target", f(st$sell_target)),
      tags$div(style = "font-size:11px; color:#64748b; margin-top:6px;", "Each leg's stop is the other leg's entry. Check the spread your platform quotes; around news it can exceed the whole range."))
  })
  output$ls_out <- renderUI({
    if (!is.finite(input$ls_risk) || !is.finite(input$ls_pips) || input$ls_pips <= 0) return(NULL)
    tags$div(style = "margin-top:6px; font-family:monospace; font-size:13px; color:#002C3C; font-weight:700;", sprintf("Trade size = $%s", formatC(u3r_trade_size_usd(input$ls_risk, input$ls_pips), format = "f", digits = 0, big.mark = ",")))
  })
  output$ls_out2 <- renderUI({
    if (!is.finite(input$ls_size) || !is.finite(input$ls_pips2)) return(NULL)
    tags$div(style = "margin-top:6px; font-family:monospace; font-size:13px; color:#002C3C; font-weight:700;", sprintf("$ risk = $%s", formatC(u3r_risk_usd(input$ls_size, input$ls_pips2), format = "f", digits = 2, big.mark = ",")))
  })
  output$r5_out <- renderUI({
    r <- u3r_rule_of_five[u3r_rule_of_five$Base == input$r5_base, ]; req(nrow(r) == 1)
    tags$div(style = "margin:6px 0 10px 0; padding:8px 12px; background:#f4f8f7; border-left:3px solid #008A82; font-size:12.5px; color:#2c3e50;",
      sprintf("Minor (timing and confirmation): %s. Base (trigger entries and exits): %s. Major (the bigger trend): %s.", r$Minor, r$Base, r$Major))
  })
}
