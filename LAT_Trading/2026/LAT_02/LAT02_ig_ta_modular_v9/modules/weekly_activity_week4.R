# modules/weekly_activity_week4.R
# Covers every point in Step 4 — Bull/Bear Stock Market Cycle (1),
# and Options Trading — chain highlighting (Premiums/Strikes/Buy Put/Sell Call/Long
# Call @ 12590 + breakeven), a straddle trade example, and the 5 payout diagrams
# (Long Call, Long Put, Short Call, Short Put, Straddle) = 9 examples total.
# All price charts use synthetic OHLC data — see R/utils_synthetic.R for the engine.
# Options payoff math reuses the same formulas as modules/options_pnl.R for consistency.

# ══════════════════════════════════════════════════════════════════════════
# OPTIONS PAYOFF HELPER (mirrors options_pnl.R's options_payoff(), kept local
# to this module since it's only needed for the 5 static payout diagrams here)
# ══════════════════════════════════════════════════════════════════════════

w4_options_payoff <- function(S, K, premium, type) {
  switch(type,
    long_call  = pmax(S - K, 0) - premium,
    short_call = premium - pmax(S - K, 0),
    long_put   = pmax(K - S, 0) - premium,
    short_put  = premium - pmax(K - S, 0),
    straddle   = pmax(S - K, 0) - premium + pmax(K - S, 0) - premium
  )
}

# Renders a single option-payoff line chart as a spec-like list compatible with
# spec_to_plotly()/base_candlestick_plot() would NOT fit (those are candlestick-
# specific), so payoff diagrams use their own small renderer pair below instead.
w4_payoff_chart_data <- function(type, K = 100, premium = 6) {
  S <- seq(K * 0.55, K * 1.45, length.out = 160)
  payoff <- w4_options_payoff(S, K, premium, type)
  breakeven <- switch(type,
    long_call = K + premium, short_call = K + premium,
    long_put = K - premium, short_put = K - premium,
    straddle = NA  # two breakevens for a straddle, handled separately below
  )
  list(S = S, payoff = payoff, K = K, premium = premium, breakeven = breakeven, type = type)
}

w4_payoff_plotly <- function(pd, title) {
  col <- c(long_call = "#27ae60", short_call = "#e74c3c", long_put = "#3498db",
           short_put = "#9b59b6", straddle = "#e67e22")[[pd$type]]
  shapes <- list(
    list(type = "line", x0 = min(pd$S), x1 = max(pd$S), y0 = 0, y1 = 0,
         line = list(color = "#bdc3c7", width = 1, dash = "dash")),
    list(type = "line", x0 = pd$K, x1 = pd$K, y0 = min(pd$payoff), y1 = max(pd$payoff),
         line = list(color = "#95a5a6", width = 1, dash = "dot"))
  )
  ann <- list(list(x = pd$K, y = max(pd$payoff) * 0.9, text = paste0("Strike ", pd$K), showarrow = FALSE,
                    font = list(size = 10, color = "#002C3C")))
  if (pd$type == "straddle") {
    be_lo <- pd$K - pd$premium; be_hi <- pd$K + pd$premium
    shapes[[length(shapes)+1]] <- list(type = "line", x0 = be_lo, x1 = be_lo, y0 = min(pd$payoff), y1 = max(pd$payoff),
                                        line = list(color = "#f39c12", width = 1.5, dash = "dot"))
    shapes[[length(shapes)+1]] <- list(type = "line", x0 = be_hi, x1 = be_hi, y0 = min(pd$payoff), y1 = max(pd$payoff),
                                        line = list(color = "#f39c12", width = 1.5, dash = "dot"))
    ann[[length(ann)+1]] <- list(x = be_lo, y = min(pd$payoff) * 0.9, text = "Lower BE", showarrow = FALSE,
                                  font = list(size = 9, color = "#f39c12"))
    ann[[length(ann)+1]] <- list(x = be_hi, y = min(pd$payoff) * 0.9, text = "Upper BE", showarrow = FALSE,
                                  font = list(size = 9, color = "#f39c12"))
  } else if (!is.na(pd$breakeven)) {
    shapes[[length(shapes)+1]] <- list(type = "line", x0 = pd$breakeven, x1 = pd$breakeven,
                                        y0 = min(pd$payoff), y1 = max(pd$payoff),
                                        line = list(color = "#f39c12", width = 1.5, dash = "dot"))
    ann[[length(ann)+1]] <- list(x = pd$breakeven, y = min(pd$payoff) * 0.9,
                                  text = paste0("Breakeven ", round(pd$breakeven, 1)), showarrow = FALSE,
                                  font = list(size = 9, color = "#f39c12"))
  }
  plot_ly(x = pd$S, y = pd$payoff, type = "scatter", mode = "lines",
          line = list(color = col, width = 3), showlegend = FALSE) %>%
    layout(title = list(text = title, font = list(size = 13)),
           xaxis = list(title = "Underlying Price at Expiry"),
           yaxis = list(title = "Profit / Loss"),
           shapes = shapes, annotations = ann,
           plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 40))
}

w4_payoff_base_plot <- function(pd, title, caption = NULL) {
  wrapped <- paste(strwrap(title, width = 30), collapse = "\n")
  n_lines <- length(strsplit(wrapped, "\n")[[1]])
  par(mar = c(2.4, 2.8, 1.3 + 1.05 * n_lines, 0.8))
  yr <- range(pd$payoff); pad <- diff(yr) * 0.12; yr <- c(yr[1]-pad, yr[2]+pad)
  col <- c(long_call = "#27ae60", short_call = "#e74c3c", long_put = "#3498db",
           short_put = "#9b59b6", straddle = "#e67e22")[[pd$type]]
  plot(pd$S, pd$payoff, type = "l", lwd = 2, col = col, xlab = "", ylab = "",
       main = wrapped, cex.main = 0.62, font.main = 2, col.main = "#002C3C",
       cex.axis = 0.55)
  abline(h = 0, col = "#bdc3c7", lty = 2)
  abline(v = pd$K, col = "#95a5a6", lty = 3)
  if (pd$type == "straddle") {
    abline(v = pd$K - pd$premium, col = "#f39c12", lty = 3)
    abline(v = pd$K + pd$premium, col = "#f39c12", lty = 3)
  } else if (!is.na(pd$breakeven)) {
    abline(v = pd$breakeven, col = "#f39c12", lty = 3)
  }
  if (!is.null(caption)) mtext(caption, side = 1, line = 0.3, cex = 0.36, col = "#666666")
}

# ══════════════════════════════════════════════════════════════════════════
# BULL/BEAR MARKET CYCLE
# ══════════════════════════════════════════════════════════════════════════

w4_market_cycle <- function(seed) {
  set.seed(seed)
  accum   <- syn_path(20, start = 100, drift = 0.05,  vol = 0.7, seed = seed)
  markup  <- syn_path(30, start = tail(accum$Close,1), drift = 1.3,  vol = 1.1, seed = seed + 10)
  distrib <- syn_path(18, start = tail(markup$Close,1), drift = 0.03, vol = 0.9, seed = seed + 20)
  markdn  <- syn_path(28, start = tail(distrib$Close,1), drift = -1.2, vol = 1.1, seed = seed + 30)
  reaccum <- syn_path(14, start = tail(markdn$Close,1), drift = 0.04, vol = 0.7, seed = seed + 40)

  df <- syn_concat(accum, markup, distrib, markdn, reaccum)
  d_accum <- syn_seg(df, 1); d_markup <- syn_seg(df, 2); d_distrib <- syn_seg(df, 3)
  d_markdn <- syn_seg(df, 4); d_reaccum <- syn_seg(df, 5)

  band <- function(dates, color) {
    list(type = "rect", x0 = dates[1], x1 = tail(dates, 1), y0 = 0, y1 = 1,
         xref = "x", yref = "paper", fillcolor = color, opacity = 0.10, line = list(width = 0))
  }
  shapes <- list(
    band(d_accum,   "#3498db"),
    band(d_markup,  "#27ae60"),
    band(d_distrib, "#e67e22"),
    band(d_markdn,  "#e74c3c"),
    band(d_reaccum, "#3498db")
  )
  mid_y <- function(dates) max(df$High) * 1.02
  ann <- list(
    syn_tag(d_accum[round(length(d_accum)/2)],   mid_y(d_accum),   "Accumulation", "#2980b9", 9),
    syn_tag(d_markup[round(length(d_markup)/2)], mid_y(d_markup), "Mark-Up (Bull Phase)", "#1e8449", 9),
    syn_tag(d_distrib[round(length(d_distrib)/2)], mid_y(d_distrib), "Distribution", "#af601a", 9),
    syn_tag(d_markdn[round(length(d_markdn)/2)], mid_y(d_markdn), "Mark-Down (Bear Phase)", "#c0392b", 9),
    syn_tag(d_reaccum[round(length(d_reaccum)/2)], mid_y(d_reaccum), "Re-Accumulation", "#2980b9", 9)
  )
  syn_chart(df, "Bull/Bear Stock Market Cycle — All Phases", shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# STRADDLE TRADE EXAMPLE (price-action chart, entry marked)
# ══════════════════════════════════════════════════════════════════════════

w4_straddle_trade <- function(seed) {
  set.seed(seed)
  lead <- syn_path(20, start = 100, drift = 0.02, vol = 0.6, seed = seed)
  entry_price <- tail(lead$Close, 1)
  # Post-entry: a sharp move in one direction (the straddle only needs A move, either way)
  breakout <- syn_path(20, start = entry_price, drift = 1.6, vol = 1.2, seed = seed + 40)
  df <- syn_concat(lead, breakout)
  breakout_dates <- syn_seg(df, 2)
  shapes <- list(
    syn_hline(df$Date[1], tail(df$Date,1), entry_price + 2, "#f39c12", "dash", 1.2),
    syn_hline(df$Date[1], tail(df$Date,1), entry_price - 2, "#f39c12", "dash", 1.2)
  )
  ann <- list(
    syn_tag(lead$Date[length(lead$Date)], entry_price, "Straddle Entry (Buy Call + Buy Put, same strike)", "#e67e22", 9),
    syn_tag(breakout_dates[round(length(breakout_dates)*0.7)], tail(breakout$Close,1),
            "Move Exceeds Combined Premium \u2192 Profit", "#27ae60", 9)
  )
  syn_chart(df, "Straddle Trade Example — Consolidation Then Breakout", shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# OPTIONS CHAIN — HIGHLIGHT EXERCISE (Premiums, Strikes, Buy Put, Sell Call, Long Call @ 12590)
# ══════════════════════════════════════════════════════════════════════════

w4_options_chain <- function() {
  strikes <- seq(12450, 12750, by = 50)
  underlying <- 12600
  # Simple synthetic premium curve: calls decay as strike rises above spot, puts decay
  # as strike falls below spot (illustrative, not a real pricing model).
  call_prem <- round(pmax(0.5, (underlying - strikes) * 0.42 + 55 - abs(underlying - strikes) * 0.05), 1)
  put_prem  <- round(pmax(0.5, (strikes - underlying) * 0.42 + 55 - abs(underlying - strikes) * 0.05), 1)
  df <- data.frame(Strike = strikes, `Call Premium` = call_prem, `Put Premium` = put_prem, check.names = FALSE)

  highlight_strike <- 12590
  # snap the highlighted long-call strike onto the nearest listed strike for display
  nearest <- strikes[which.min(abs(strikes - highlight_strike))]

  p <- plot_ly()
  p <- p %>% add_trace(x = strikes, y = call_prem, type = "scatter", mode = "lines+markers",
                        name = "Call Premium", line = list(color = "#27ae60", width = 2.5),
                        marker = list(color = "#27ae60", size = 7))
  p <- p %>% add_trace(x = strikes, y = put_prem, type = "scatter", mode = "lines+markers",
                        name = "Put Premium", line = list(color = "#e74c3c", width = 2.5),
                        marker = list(color = "#e74c3c", size = 7))
  p <- p %>% layout(
    title = list(text = "Options Chain — Premiums vs Strike Prices", font = list(size = 13)),
    xaxis = list(title = "Strike Price"), yaxis = list(title = "Premium"),
    shapes = list(
      list(type = "line", x0 = underlying, x1 = underlying, y0 = 0, y1 = max(c(call_prem, put_prem)) * 1.05,
           line = list(color = "#7f8c8d", width = 1, dash = "dash")),
      list(type = "line", x0 = nearest, x1 = nearest, y0 = 0, y1 = max(c(call_prem, put_prem)) * 1.05,
           line = list(color = "#f39c12", width = 2, dash = "solid"))
    ),
    annotations = list(
      list(x = underlying, y = max(c(call_prem, put_prem)) * 1.02, text = "Underlying Price", showarrow = FALSE,
           font = list(size = 9, color = "#7f8c8d")),
      list(x = nearest, y = max(c(call_prem, put_prem)) * 0.9, text = "Long Call \u2192 Strike 12590",
           showarrow = TRUE, ax = 40, ay = -20, font = list(size = 10, color = "#f39c12")),
      list(x = strikes[1], y = call_prem[1], text = "Buying a Put here (low strike)\n= paying this Put Premium",
           showarrow = TRUE, ax = 0, ay = -35, font = list(size = 8, color = "#e74c3c")),
      list(x = strikes[length(strikes)], y = call_prem[length(call_prem)],
           text = "Selling a Call here (high strike)\n= receiving this Call Premium",
           showarrow = TRUE, ax = 0, ay = 35, font = list(size = 8, color = "#27ae60"))
    ),
    plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 40)
  )
  list(plot = p, table = df, nearest = nearest,
       nearest_premium = call_prem[which(strikes == nearest)])
}

# ══════════════════════════════════════════════════════════════════════════
# CANONICAL SECTIONS
# ══════════════════════════════════════════════════════════════════════════

w4_sections <- function() {
  cycle_specs <- list(
    list(id = "cycle1", title = "Bull/Bear Market Cycle", desc = "One full cycle with Accumulation, Mark-Up (Bull), Distribution, Mark-Down (Bear), and Re-Accumulation phases labelled.",
         gen = function() w4_market_cycle(701))
  )

  straddle_trade_specs <- list(
    list(id = "straddle_trade", title = "Straddle Trade Example", desc = "A straddle (long call + long put, same strike) placed before a breakout; profit once the move exceeds the combined premium paid.",
         gen = function() w4_straddle_trade(710))
  )

  payoff_defs <- list(
    list(id = "po_lc", type = "long_call",  label = "Long Call",  K = 100, premium = 6),
    list(id = "po_lp", type = "long_put",   label = "Long Put",   K = 100, premium = 6),
    list(id = "po_sc", type = "short_call", label = "Short Call", K = 100, premium = 6),
    list(id = "po_sp", type = "short_put",  label = "Short Put",  K = 100, premium = 6),
    list(id = "po_st", type = "straddle",   label = "Straddle",   K = 100, premium = 6)
  )
  payoff_specs <- lapply(payoff_defs, function(d) {
    payoff_title <- paste0(d$label, " Payoff at Expiry")
    list(id = d$id, title = paste0(d$label, " Payoff"),
         desc = paste0("Profit/loss profile of a ", tolower(d$label), " at expiry, strike ", d$K, ", premium ", d$premium, "."),
         gen = function() w4_payoff_chart_data(d$type, d$K, d$premium),
         payoff_title = payoff_title,
         render_fn = function(cs, caption) w4_payoff_base_plot(cs, payoff_title, caption))
  })

  list(
    list(title = "Bull/Bear Stock Market Cycle", specs = cycle_specs),
    list(title = "Options Trading — Straddle Example", specs = straddle_trade_specs),
    list(title = "Options Payout Diagrams", specs = payoff_specs, is_payoff = TRUE)
  )
}

# ══════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════

weekly_activity_week4_ui <- function(id) {
  ns <- NS(id)
  sections <- w4_sections()
  chain <- w4_options_chain()

  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(paste0(
              "Covers Step 4: the Bull/Bear Stock Market Cycle, an options-chain highlighting ",
              "exercise (premiums, strikes, buying a put, selling a call, a long call at strike 12590 and its ",
              "breakeven), a straddle trade example, and the 5 basic options payout diagrams. Price charts use ",
              "simulated OHLC data; the options chain uses an illustrative premium curve, not live market pricing."
            ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    weekly_download_ui(ns),
    weekly_grid_ui(ns, sections[[1]]$specs, sections[[1]]$title),

    tags$h4("Options Trading — Chain Highlighting & Breakeven", style = "color:#002C3C; margin:18px 0 10px 0;"),
    fluidRow(
      column(6,
        box(title = "Options Chain — Premiums, Strikes, Long Call @ 12590", status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(plotlyOutput(ns("optionsChain"), height = "360px")),
            tags$p("Orange line marks the strike nearest 12590 for the Long Call. Left-edge annotation marks buying a Put; right-edge marks selling a Call.",
                   style = "font-size:11.5px; color:#666; margin-top:8px; line-height:1.5;")
        )
      ),
      column(6,
        box(title = "Long Call @ 12590 — Breakeven", status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(plotlyOutput(ns("chainBreakeven"), height = "360px")),
            tags$p("Breakeven = Strike + Premium Paid. Below this price at expiry the position is a net loss (capped at the premium); above it, profit is unlimited.",
                   style = "font-size:11.5px; color:#666; margin-top:8px; line-height:1.5;")
        )
      )
    ),
    fluidRow(
      box(title = "Options Chain — Strike Ladder", status = "info", solidHeader = TRUE, width = 12,
          withSpinner(DT::dataTableOutput(ns("chainTable"))))
    ),

    weekly_grid_ui(ns, sections[[2]]$specs, sections[[2]]$title),

    tags$h4("Options Payout Diagrams", style = "color:#002C3C; margin:18px 0 10px 0;"),
    fluidRow(lapply(sections[[3]]$specs, function(s) {
      column(6,
        box(title = s$title, status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(plotlyOutput(ns(s$id), height = "320px")),
            tags$p(s$desc, style = "font-size:11.5px; color:#666; margin-top:8px; line-height:1.5;")
        )
      )
    }))
  )
}

weekly_activity_week4_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    sections <- w4_sections()
    chain <- w4_options_chain()

    weekly_grid_server(output, sections[[1]]$specs)
    weekly_grid_server(output, sections[[2]]$specs)

    output$optionsChain <- renderPlotly({ chain$plot })
    output$chainTable <- DT::renderDataTable({
      DT::datatable(chain$table, options = list(dom = 't', pageLength = nrow(chain$table)), rownames = FALSE)
    })
    output$chainBreakeven <- renderPlotly({
      pd <- w4_payoff_chart_data("long_call", K = chain$nearest, premium = chain$nearest_premium)
      w4_payoff_plotly(pd, paste0("Long Call @ ", chain$nearest, " — Breakeven ", round(pd$breakeven, 1)))
    })

    for (s in sections[[3]]$specs) {
      local({
        spec <- s
        output[[spec$id]] <- renderPlotly({ w4_payoff_plotly(spec$gen(), spec$payoff_title) })
      })
    }

    weekly_download_server(output, "Step 4", sections, "step4_activity")
    session$onSessionEnded(function() {})
  })
}
