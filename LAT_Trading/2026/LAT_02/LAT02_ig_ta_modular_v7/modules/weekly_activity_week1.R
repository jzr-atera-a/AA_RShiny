# modules/weekly_activity_week1.R
# Covers every point in the Week 1 Activity Sheet: Support & Resistance (4 assets x
# 3 timeframes), Trend Lines/Channels/Countertrend Lines (10 examples), and Japanese
# Candlesticks (9 patterns x confirmed/failed + 2 Marubozu breakout examples = 20).
# All charts use synthetic OHLC data, deterministically shaped and seeded to exhibit
# the requested feature — see R/utils_synthetic.R for the generation engine.

# ══════════════════════════════════════════════════════════════════════════
# GENERATORS
# ══════════════════════════════════════════════════════════════════════════

# -- Support & Resistance: one chart per asset, 3 timeframes of S/R shown together --
w1_support_resistance <- function(asset_label, seed) {
  df <- syn_path(70, start = 100, drift = 0.05, vol = 1.3, seed = seed)
  rng <- max(df$High) - min(df$Low)
  res_d <- max(df$High[45:70]) - rng * 0.02
  sup_d <- min(df$Low[45:70]) + rng * 0.02
  res_w <- max(df$High) - rng * 0.05
  sup_w <- min(df$Low) + rng * 0.05
  res_m <- max(df$High) + rng * 0.03
  sup_m <- min(df$Low) - rng * 0.03
  
  shapes <- list(
    syn_hline(df$Date[1], df$Date[70], res_d, "#e74c3c", "dash", 2),
    syn_hline(df$Date[1], df$Date[70], sup_d, "#27ae60", "dash", 2),
    syn_hline(df$Date[1], df$Date[70], res_w, "#c0392b", "dot", 1.5),
    syn_hline(df$Date[1], df$Date[70], sup_w, "#1e8449", "dot", 1.5),
    syn_hline(df$Date[1], df$Date[70], res_m, "#7b241c", "solid", 1),
    syn_hline(df$Date[1], df$Date[70], sup_m, "#145a32", "solid", 1)
  )
  ann <- list(
    syn_tag(df$Date[5], res_d, "Daily R", "#e74c3c", 9),
    syn_tag(df$Date[5], sup_d, "Daily S", "#27ae60", 9),
    syn_tag(df$Date[20], res_w, "Weekly R", "#c0392b", 9),
    syn_tag(df$Date[20], sup_w, "Weekly S", "#1e8449", 9),
    syn_tag(df$Date[35], res_m, "Monthly R", "#7b241c", 9),
    syn_tag(df$Date[35], sup_m, "Monthly S", "#145a32", 9)
  )
  syn_chart(df, paste0(asset_label, " — S/R across Daily / Weekly / Monthly"), shapes, ann)
}

# -- Trend lines, channels, countertrend lines --
w1_trendline <- function(kind, seed) {
  set.seed(seed)
  n <- 60
  if (kind %in% c("uptrend1", "uptrend2")) {
    df <- syn_path(n, start = 100, drift = 0.55, vol = 1.1, seed = seed)
    lo_idx <- c(8, 30, 52)
    x0 <- df$Date[lo_idx[1]]; x1 <- df$Date[lo_idx[3]]
    y0 <- df$Low[lo_idx[1]] - 0.5; y1 <- df$Low[lo_idx[3]] - 0.5
    shapes <- list(syn_line(x0, x1, y0, y1, "#27ae60", "solid", 2.5))
    title <- paste0("Valid Uptrend Line (Example ", ifelse(kind == "uptrend1", 1, 2), ")")
    
  } else if (kind %in% c("downtrend1", "downtrend2")) {
    df <- syn_path(n, start = 140, drift = -0.55, vol = 1.1, seed = seed)
    hi_idx <- c(8, 30, 52)
    x0 <- df$Date[hi_idx[1]]; x1 <- df$Date[hi_idx[3]]
    y0 <- df$High[hi_idx[1]] + 0.5; y1 <- df$High[hi_idx[3]] + 0.5
    shapes <- list(syn_line(x0, x1, y0, y1, "#e74c3c", "solid", 2.5))
    title <- paste0("Valid Downtrend Line (Example ", ifelse(kind == "downtrend1", 1, 2), ")")
    
  } else if (kind == "broken_uptrend") {
    up <- syn_path(38, start = 100, drift = 0.6, vol = 1.1, seed = seed)
    down <- syn_path(22, start = tail(up$Close, 1), drift = -1.3, vol = 1.2, seed = seed + 50)
    down$Date <- seq(tail(up$Date, 1) + 1, by = "day", length.out = 22)
    df <- bind_rows(up, down)
    x0 <- df$Date[6]; x1 <- df$Date[36]
    y0 <- up$Low[6] - 0.5; slope <- (up$Low[34] - up$Low[6]) / 28
    y1 <- y0 + slope * 30
    shapes <- list(syn_line(x0, x1, y0, y1, "#27ae60", "solid", 2.5))
    ann <- list(syn_tag(df$Date[40], max(df$High), "Line Broken", "#e74c3c", 11))
    return(syn_chart(df, "Broken Uptrend Line", shapes, ann))
    
  } else if (kind == "broken_downtrend") {
    down <- syn_path(38, start = 140, drift = -0.6, vol = 1.1, seed = seed)
    up <- syn_path(22, start = tail(down$Close, 1), drift = 1.3, vol = 1.2, seed = seed + 50)
    up$Date <- seq(tail(down$Date, 1) + 1, by = "day", length.out = 22)
    df <- bind_rows(down, up)
    x0 <- df$Date[6]; x1 <- df$Date[36]
    y0 <- down$High[6] + 0.5; slope <- (down$High[34] - down$High[6]) / 28
    y1 <- y0 + slope * 30
    shapes <- list(syn_line(x0, x1, y0, y1, "#e74c3c", "solid", 2.5))
    ann <- list(syn_tag(df$Date[40], min(df$Low), "Line Broken", "#27ae60", 11))
    return(syn_chart(df, "Broken Downtrend Line", shapes, ann))
    
  } else if (kind == "ctr_break_uptrend") {
    # Longer-term uptrend, with a short countertrend (correction) line that gets broken,
    # confirming continuation of the primary uptrend.
    leg1 <- syn_path(24, start = 100, drift = 0.7, vol = 1.1, seed = seed)
    pull <- syn_path(14, start = tail(leg1$Close, 1), drift = -0.5, vol = 0.8, seed = seed + 20)
    pull$Date <- seq(tail(leg1$Date, 1) + 1, by = "day", length.out = 14)
    leg2 <- syn_path(22, start = tail(pull$Close, 1) + 1, drift = 0.9, vol = 1.1, seed = seed + 40)
    leg2$Date <- seq(tail(pull$Date, 1) + 1, by = "day", length.out = 22)
    df <- bind_rows(leg1, pull, leg2)
    x0 <- pull$Date[2]; x1 <- pull$Date[13]
    y0 <- pull$High[2] + 0.3; y1 <- pull$High[13] + 0.3
    shapes <- list(
      syn_line(leg1$Date[3], tail(leg2$Date,1), leg1$Low[3] - 0.3, leg1$Low[3] - 0.3 + 0.35 * 58, "#27ae60", "solid", 2.5),
      syn_line(x0, x1, y0, y1, "#9b59b6", "dash", 2)
    )
    ann <- list(syn_tag(leg2$Date[4], max(df$High) * 0.98, "Countertrend Line Broken \u2192 Uptrend Resumes", "#27ae60", 10))
    return(syn_chart(df, "Broken Countertrend Line — Uptrend Continues", shapes, ann))
    
  } else if (kind == "ctr_break_downtrend") {
    leg1 <- syn_path(24, start = 140, drift = -0.7, vol = 1.1, seed = seed)
    pull <- syn_path(14, start = tail(leg1$Close, 1), drift = 0.5, vol = 0.8, seed = seed + 20)
    pull$Date <- seq(tail(leg1$Date, 1) + 1, by = "day", length.out = 14)
    leg2 <- syn_path(22, start = tail(pull$Close, 1) - 1, drift = -0.9, vol = 1.1, seed = seed + 40)
    leg2$Date <- seq(tail(pull$Date, 1) + 1, by = "day", length.out = 22)
    df <- bind_rows(leg1, pull, leg2)
    x0 <- pull$Date[2]; x1 <- pull$Date[13]
    y0 <- pull$Low[2] - 0.3; y1 <- pull$Low[13] - 0.3
    shapes <- list(
      syn_line(leg1$Date[3], tail(leg2$Date,1), leg1$High[3] + 0.3, leg1$High[3] + 0.3 - 0.35 * 58, "#e74c3c", "solid", 2.5),
      syn_line(x0, x1, y0, y1, "#9b59b6", "dash", 2)
    )
    ann <- list(syn_tag(leg2$Date[4], min(df$Low) * 1.02, "Countertrend Line Broken \u2192 Downtrend Resumes", "#e74c3c", 10))
    return(syn_chart(df, "Broken Countertrend Line — Downtrend Continues", shapes, ann))
    
  } else if (kind == "bull_channel") {
    df <- syn_path(n, start = 100, drift = 0.5, vol = 1.0, seed = seed)
    x0 <- df$Date[6]; x1 <- df$Date[56]
    y0 <- df$Low[6] - 0.4; slope <- 0.5
    y1 <- y0 + slope * 50
    shapes <- list(
      syn_line(x0, x1, y0, y1, "#27ae60", "solid", 2.5),
      syn_line(x0, x1, y0 + 6, y1 + 6, "#27ae60", "solid", 2.5)
    )
    return(syn_chart(df, "Bullish (Ascending) Channel", shapes))
    
  } else if (kind == "bear_channel") {
    df <- syn_path(n, start = 140, drift = -0.5, vol = 1.0, seed = seed)
    x0 <- df$Date[6]; x1 <- df$Date[56]
    y0 <- df$High[6] + 0.4; slope <- -0.5
    y1 <- y0 + slope * 50
    shapes <- list(
      syn_line(x0, x1, y0, y1, "#e74c3c", "solid", 2.5),
      syn_line(x0, x1, y0 - 6, y1 - 6, "#e74c3c", "solid", 2.5)
    )
    return(syn_chart(df, "Bearish (Descending) Channel", shapes))
  }
  
  syn_chart(df, title, shapes)
}

# -- Japanese candlestick patterns: confirmed vs failed, via one dispatcher --
w1_candle <- function(pattern, confirmed, seed) {
  set.seed(seed)
  bearish_rev <- pattern %in% c("shooting_star", "dark_cloud", "hanging_man")
  two_candle  <- pattern %in% c("dark_cloud", "bearish_engulfing", "piercing")
  
  lead <- if (bearish_rev) syn_path(20, start = 92, drift = 0.85, vol = 1, seed = seed)
          else syn_path(20, start = 128, drift = -0.85, vol = 1, seed = seed)
  
  pivot <- tail(lead$Close, 1)
  vol <- 1.1
  cshape_type <- switch(pattern,
    shooting_star    = "shooting_star",
    inverted_hammer  = "inverted_hammer",
    hanging_man       = "hanging_man",
    hammer_support    = "hammer",
    long_legged_doji  = "doji_long_legged",
    dragonfly_doji    = "doji_dragonfly",
    NA
  )
  
  if (!two_candle) {
    cs <- syn_candle(pivot - 0.3, vol, cshape_type)
    candle_row <- data.frame(Date = tail(lead$Date, 1) + 1, Open = cs$o, High = cs$h, Low = cs$l, Close = cs$c)
    lead2 <- lead
    pattern_dates <- candle_row$Date
    after_price <- cs$c
    df_mid <- bind_rows(lead2, candle_row)
  } else if (pattern == "dark_cloud") {
    d1 <- data.frame(Date = tail(lead$Date,1)+1, Open = pivot - 2*vol, High = pivot + 0.3, Low = pivot - 2.1*vol, Close = pivot + 0.1)
    mid_body <- (d1$Open[1] + d1$Close[1]) / 2
    d2 <- data.frame(Date = tail(lead$Date,1)+2, Open = d1$Close[1] + 0.6, High = d1$Close[1] + 0.7,
                      Low = mid_body - 0.5, Close = mid_body - 0.3)
    df_mid <- bind_rows(lead, d1, d2)
    pattern_dates <- c(d1$Date, d2$Date); after_price <- d2$Close
  } else if (pattern == "bearish_engulfing") {
    d1 <- data.frame(Date = tail(lead$Date,1)+1, Open = pivot - 0.6, High = pivot + 0.9, Low = pivot - 0.7, Close = pivot + 0.8)
    d2 <- data.frame(Date = tail(lead$Date,1)+2, Open = d1$Close[1] + 0.4, High = d1$Close[1] + 0.5,
                      Low = d1$Open[1] - 0.8, Close = d1$Open[1] - 0.6)
    df_mid <- bind_rows(lead, d1, d2)
    pattern_dates <- c(d1$Date, d2$Date); after_price <- d2$Close
  } else if (pattern == "piercing") {
    d1 <- data.frame(Date = tail(lead$Date,1)+1, Open = pivot + 2*vol, High = pivot + 2.1*vol, Low = pivot - 0.2, Close = pivot)
    mid_body <- (d1$Open[1] + d1$Close[1]) / 2
    d2 <- data.frame(Date = tail(lead$Date,1)+2, Open = d1$Close[1] - 0.6, High = mid_body + 0.5,
                      Low = d1$Close[1] - 0.7, Close = mid_body + 0.3)
    df_mid <- bind_rows(lead, d1, d2)
    pattern_dates <- c(d1$Date, d2$Date); after_price <- d2$Close
  }
  
  n_tail <- 16
  tail_drift <- if (confirmed) {
    if (bearish_rev) -0.85 else 0.85
  } else {
    if (bearish_rev) 0.85 else -0.85
  }
  tail_df <- syn_path(n_tail, start = after_price, drift = tail_drift, vol = 1, seed = seed + 200)
  tail_df$Date <- seq(max(df_mid$Date) + 1, by = "day", length.out = n_tail)
  
  df <- bind_rows(df_mid, tail_df)
  outcome_label <- if (confirmed) "CONFIRMED" else "FAILED"
  outcome_color <- if (confirmed) "#27ae60" else "#e74c3c"
  
  ann <- list(syn_tag(pattern_dates[1], max(df$High) * 1.01, outcome_label, outcome_color, 11))
  
  pattern_labels <- c(
    shooting_star = "Shooting Star", dark_cloud = "Dark Cloud Cover", inverted_hammer = "Inverted Hammer",
    long_legged_doji = "Long-Legged Doji (in downtrend)", dragonfly_doji = "Dragonfly Doji",
    hammer_support = "Hammer at Support", bearish_engulfing = "Bearish Engulfing", piercing = "Piercing Pattern",
    hanging_man = "Hanging Man"
  )
  
  shapes <- list()
  if (pattern == "hammer_support") {
    shapes <- list(syn_hline(df$Date[1], tail(df$Date,1), pivot - 0.3, "#7f8c8d", "dash", 1.5))
  }
  
  syn_chart(df, paste0(pattern_labels[[pattern]], " (", outcome_label, ")"), shapes, ann)
}

# -- Marubozu breakout examples --
w1_marubozu <- function(kind, seed) {
  set.seed(seed)
  if (kind == "resistance") {
    lead <- syn_path(26, start = 95, drift = 0.35, vol = 1, seed = seed)
    res <- max(lead$High) - 0.2
    cs <- syn_candle(res - 0.5, 1.3, "marubozu_bull")
    mrow <- data.frame(Date = tail(lead$Date,1)+1, Open = cs$o, High = cs$h, Low = cs$l, Close = cs$c)
    tail_df <- syn_path(14, start = cs$c, drift = 0.9, vol = 1, seed = seed + 60)
    tail_df$Date <- seq(mrow$Date + 1, by = "day", length.out = 14)
    df <- bind_rows(lead, mrow, tail_df)
    shapes <- list(syn_hline(df$Date[1], tail(df$Date,1), res, "#e74c3c", "dash", 2))
    ann <- list(syn_tag(mrow$Date, cs$h * 1.01, "Bullish Marubozu Breaks Resistance", "#27ae60", 10))
    syn_chart(df, "Marubozu Confirming Breakout of Resistance", shapes, ann)
  } else {
    lead <- syn_path(26, start = 100, drift = 0.55, vol = 1, seed = seed)
    x0 <- lead$Date[4]; x1 <- lead$Date[26]
    y0 <- lead$Low[4] - 0.4; slope <- 0.5; y1 <- y0 + slope * 22
    line_end_y <- y1
    cs <- syn_candle(line_end_y - 2.8, 1.3, "marubozu_bear")
    mrow <- data.frame(Date = tail(lead$Date,1)+1, Open = cs$o, High = cs$h, Low = cs$l, Close = cs$c)
    tail_df <- syn_path(14, start = cs$c, drift = -0.9, vol = 1, seed = seed + 60)
    tail_df$Date <- seq(mrow$Date + 1, by = "day", length.out = 14)
    df <- bind_rows(lead, mrow, tail_df)
    shapes <- list(syn_line(x0, tail(df$Date,1), y0, y1 + slope * 15, "#27ae60", "solid", 2.5))
    ann <- list(syn_tag(mrow$Date, cs$l * 0.98, "Bearish Marubozu Breaks Uptrend Line", "#e74c3c", 10))
    syn_chart(df, "Marubozu Confirming Breakout of an Uptrend Line", shapes, ann)
  }
}

# ══════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════

weekly_activity_week1_ui <- function(id) {
  ns <- NS(id)
  
  sr_specs <- list(
    list(id = "sr1", title = "FX Pair 1 — EUR/USD (simulated)", desc = "Support & Resistance across Daily/Weekly/Monthly timeframes."),
    list(id = "sr2", title = "FX Pair 2 — GBP/USD (simulated)", desc = "Support & Resistance across Daily/Weekly/Monthly timeframes."),
    list(id = "sr3", title = "Stock Market Index (simulated)", desc = "Support & Resistance across Daily/Weekly/Monthly timeframes."),
    list(id = "sr4", title = "Commodity — Gold (simulated)",   desc = "Support & Resistance across Daily/Weekly/Monthly timeframes.")
  )
  
  tl_specs <- list(
    list(id = "tl1", title = "Uptrend Line — Example 1", desc = "A valid uptrend line connecting at least two rising swing lows."),
    list(id = "tl2", title = "Uptrend Line — Example 2", desc = "A second valid uptrend line, different asset/period."),
    list(id = "tl3", title = "Downtrend Line — Example 1", desc = "A valid downtrend line connecting at least two falling swing highs."),
    list(id = "tl4", title = "Downtrend Line — Example 2", desc = "A second valid downtrend line, different asset/period."),
    list(id = "tl5", title = "Broken Uptrend Line", desc = "Price closes decisively through the uptrend line, signalling the uptrend has ended."),
    list(id = "tl6", title = "Broken Downtrend Line", desc = "Price closes decisively through the downtrend line, signalling the downtrend has ended."),
    list(id = "tl7", title = "Broken Countertrend Line (Uptrend Continues)", desc = "A short corrective countertrend line within a longer uptrend gets broken, confirming the primary uptrend resumes."),
    list(id = "tl8", title = "Broken Countertrend Line (Downtrend Continues)", desc = "A short corrective countertrend line within a longer downtrend gets broken, confirming the primary downtrend resumes."),
    list(id = "tl9", title = "Bullish Channel", desc = "Parallel ascending trend and channel lines containing price action."),
    list(id = "tl10", title = "Bearish Channel", desc = "Parallel descending trend and channel lines containing price action.")
  )
  
  candle_defs <- list(
    list(key = "shooting_star",   label = "Shooting Star"),
    list(key = "dark_cloud",      label = "Dark Cloud Cover"),
    list(key = "inverted_hammer", label = "Inverted Hammer"),
    list(key = "long_legged_doji",label = "Long-Legged Doji in a Downtrend"),
    list(key = "dragonfly_doji",  label = "Dragonfly Doji"),
    list(key = "hammer_support",  label = "Hammer at a Support Level"),
    list(key = "bearish_engulfing", label = "Bearish Engulfing Pattern"),
    list(key = "piercing",        label = "Piercing Pattern"),
    list(key = "hanging_man",     label = "Hanging Man")
  )
  cs_specs <- list()
  for (cd in candle_defs) {
    cs_specs[[length(cs_specs)+1]] <- list(id = paste0("cs_", cd$key, "_c"), title = paste0(cd$label, " — Confirmed"),
                                             desc = "Pattern confirmed: price follows through in the implied reversal direction.")
    cs_specs[[length(cs_specs)+1]] <- list(id = paste0("cs_", cd$key, "_f"), title = paste0(cd$label, " — Failed"),
                                             desc = "Pattern failed: the prior trend resumes instead of reversing.")
  }
  cs_specs[[length(cs_specs)+1]] <- list(id = "marubozu_res", title = "Marubozu — Resistance Breakout", desc = "A strong bullish Marubozu candle confirms the breakout of a resistance level.")
  cs_specs[[length(cs_specs)+1]] <- list(id = "marubozu_trend", title = "Marubozu — Uptrend Line Breakout", desc = "A strong bearish Marubozu candle confirms the breakout (violation) of an uptrend line.")
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(paste0(
              "Every chart below uses simulated OHLC data, deterministically generated to exhibit the exact ",
              "feature requested in the Week 1 Activity Sheet — Support & Resistance, Trend Lines/Channels/",
              "Countertrend Lines, and Japanese Candlestick patterns (34 examples in total). This is for ",
              "practising pattern recognition, not a claim about real market history."
            ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    weekly_grid_ui(ns, sr_specs, "Support & Resistance"),
    weekly_grid_ui(ns, tl_specs, "Trend Lines, Channels & Countertrend Lines"),
    weekly_grid_ui(ns, cs_specs, "Japanese Candlesticks")
  )
}

weekly_activity_week1_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    sr_specs <- list(
      list(id = "sr1", gen = function() w1_support_resistance("EUR/USD", 101)),
      list(id = "sr2", gen = function() w1_support_resistance("GBP/USD", 102)),
      list(id = "sr3", gen = function() w1_support_resistance("Stock Index", 103)),
      list(id = "sr4", gen = function() w1_support_resistance("Gold", 104))
    )
    
    tl_specs <- list(
      list(id = "tl1", gen = function() w1_trendline("uptrend1", 111)),
      list(id = "tl2", gen = function() w1_trendline("uptrend2", 112)),
      list(id = "tl3", gen = function() w1_trendline("downtrend1", 113)),
      list(id = "tl4", gen = function() w1_trendline("downtrend2", 114)),
      list(id = "tl5", gen = function() w1_trendline("broken_uptrend", 115)),
      list(id = "tl6", gen = function() w1_trendline("broken_downtrend", 116)),
      list(id = "tl7", gen = function() w1_trendline("ctr_break_uptrend", 117)),
      list(id = "tl8", gen = function() w1_trendline("ctr_break_downtrend", 118)),
      list(id = "tl9", gen = function() w1_trendline("bull_channel", 119)),
      list(id = "tl10", gen = function() w1_trendline("bear_channel", 120))
    )
    
    candle_keys <- c("shooting_star","dark_cloud","inverted_hammer","long_legged_doji","dragonfly_doji",
                      "hammer_support","bearish_engulfing","piercing","hanging_man")
    cs_specs <- list()
    seed_i <- 130
    for (k in candle_keys) {
      seed_i <- seed_i + 1
      local({
        kk <- k; s1 <- seed_i
        cs_specs[[length(cs_specs)+1]] <<- list(id = paste0("cs_", kk, "_c"), gen = function() w1_candle(kk, TRUE, s1))
        cs_specs[[length(cs_specs)+1]] <<- list(id = paste0("cs_", kk, "_f"), gen = function() w1_candle(kk, FALSE, s1 + 500))
      })
    }
    cs_specs[[length(cs_specs)+1]] <- list(id = "marubozu_res", gen = function() w1_marubozu("resistance", 190))
    cs_specs[[length(cs_specs)+1]] <- list(id = "marubozu_trend", gen = function() w1_marubozu("trend", 191))
    
    weekly_grid_server(output, sr_specs)
    weekly_grid_server(output, tl_specs)
    weekly_grid_server(output, cs_specs)
    
    session$onSessionEnded(function() {})
  })
}
