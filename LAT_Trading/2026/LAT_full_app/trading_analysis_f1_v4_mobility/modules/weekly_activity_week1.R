# modules/weekly_activity_week1.R
# Covers every point in Step 1 — Support & Resistance (4 assets x
# 3 timeframes), Trend Lines/Channels/Countertrend Lines (10 examples), and Japanese
# Candlesticks (9 patterns x confirmed/failed + 2 Marubozu breakout examples = 20).
# All charts use synthetic OHLC data, deterministically shaped and seeded to exhibit
# the requested feature — see R/utils_synthetic.R for the generation engine.

# ══════════════════════════════════════════════════════════════════════════
# GENERATORS
# ══════════════════════════════════════════════════════════════════════════

# -- Support & Resistance: one chart per asset, 3 nested timeframes shown together.
# Built as 3 chained confined-path phases (Monthly band -> Weekly band -> Daily band,
# each nested inside the last) so every level gets multiple genuine touches via the
# same reflecting-boundary mechanism used for trendlines below, and none of them are
# ever broken by construction (close is hard-clamped inside its band at all times) —
# directly fixing "only 1 bounce" / "recently broken" feedback.
w1_support_resistance <- function(asset_label, seed) {
  set.seed(seed)
  mid <- 100
  d_half <- 3.2; w_half <- 6.5; m_half <- 10.5
  res_d <- mid + d_half; sup_d <- mid - d_half
  res_w <- mid + w_half; sup_w <- mid - w_half
  res_m <- mid + m_half; sup_m <- mid - m_half

  # Phase 1 (24 bars): tests the Monthly band early, bouncing off res_m/sup_m.
  p1 <- syn_confined_path(24, start = mid, lo_fn = function(i) sup_m, hi_fn = function(i) res_m, vol = 1.35, seed = seed)
  # Phase 2 (24 bars): narrows to the Weekly band, bouncing off res_w/sup_w.
  p2 <- syn_confined_path(24, start = tail(p1$Close, 1), lo_fn = function(i) sup_w, hi_fn = function(i) res_w, vol = 1.0, seed = seed + 20)
  # Phase 3 (22 bars): narrows further to the Daily band — the most current/relevant levels.
  p3 <- syn_confined_path(22, start = tail(p2$Close, 1), lo_fn = function(i) sup_d, hi_fn = function(i) res_d, vol = 0.7, seed = seed + 40)

  p1$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = 24)
  p2$Date <- seq(tail(p1$Date, 1) + 1, by = "day", length.out = 24)
  p3$Date <- seq(tail(p2$Date, 1) + 1, by = "day", length.out = 22)
  df <- bind_rows(p1, p2, p3)

  shapes <- list(
    syn_hline(df$Date[1], tail(df$Date, 1), res_d, "#e74c3c", "dash", 2),
    syn_hline(df$Date[1], tail(df$Date, 1), sup_d, "#27ae60", "dash", 2),
    syn_hline(df$Date[1], tail(df$Date, 1), res_w, "#c0392b", "dot", 1.5),
    syn_hline(df$Date[1], tail(df$Date, 1), sup_w, "#1e8449", "dot", 1.5),
    syn_hline(df$Date[1], tail(df$Date, 1), res_m, "#7b241c", "solid", 1),
    syn_hline(df$Date[1], tail(df$Date, 1), sup_m, "#145a32", "solid", 1)
  )
  ann <- list(
    syn_tag(df$Date[50], res_d, "Daily R (multiple touches, unbroken)", "#e74c3c", 8),
    syn_tag(df$Date[50], sup_d, "Daily S (multiple touches, unbroken)", "#27ae60", 8),
    syn_tag(df$Date[28], res_w, "Weekly R", "#c0392b", 8),
    syn_tag(df$Date[28], sup_w, "Weekly S", "#1e8449", 8),
    syn_tag(df$Date[4], res_m, "Monthly R", "#7b241c", 8),
    syn_tag(df$Date[4], sup_m, "Monthly S", "#145a32", 8)
  )
  syn_chart(df, paste0(asset_label, " — S/R across Daily / Weekly / Monthly"), shapes, ann)
}

# Wraps a "global bar-index" line function so it can be passed as lo_fn/hi_fn to
# syn_confined_path(), which always calls its bound functions with a LOCAL index
# (1..n) for whichever segment is currently being generated — this converts that
# local index back to the correct point on the shared line.
w1_offset_fn <- function(f, global_start) function(i) f(i + global_start - 1)

# -- Trend lines, channels, countertrend lines --
# Every "valid" line below is drawn EXACTLY along the boundary that price was
# generated to respect: syn_confined_path() is given the trendline's own linear
# formula as its lo_fn (uptrend/support) or hi_fn (downtrend/resistance), so the
# candle CLOSES are mathematically guaranteed to never cross it (hard-clamped), and
# the natural reflecting-boundary behaviour produces multiple genuine touches over
# the course of the series — this directly fixes "drawn through the candlesticks" /
# "needs 3 bounces, not cutting through candle bodies" structurally, not cosmetically.
# Wicks may briefly poke past the line on a touch (realistic — real S/R wicks do
# this too); bodies stay on the correct side except for the rare small open-price
# jitter, exactly matching how a valid trendline should be drawn.
w1_trendline <- function(kind, seed) {
  set.seed(seed)
  n <- 60
  line_at <- function(x0, y0, slope) function(x) y0 + slope * (x - x0)
  
  if (kind %in% c("uptrend1", "uptrend2")) {
    y0 <- 96; slope <- 0.55
    up_line <- line_at(1, y0, slope)
    ceil_line <- function(i) up_line(i) + 9
    df <- syn_confined_path(n, start = y0 + 3, lo_fn = up_line, hi_fn = ceil_line, vol = 1.1, seed = seed)
    df$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = n)
    shapes <- list(syn_line(df$Date[1], tail(df$Date, 1), up_line(1), up_line(n), "#27ae60", "solid", 2.5))
    ann <- list(syn_tag(df$Date[round(n * 0.55)], up_line(round(n * 0.55)) + 1.6,
                         "Uptrend Line (Support) \u2014 Connects Rising Swing Lows (HLs)", "#27ae60", 9))
    title <- paste0("Valid Uptrend Line (Example ", ifelse(kind == "uptrend1", 1, 2), ")")
    return(syn_chart(df, title, shapes, ann))
    
  } else if (kind %in% c("downtrend1", "downtrend2")) {
    y0 <- 144; slope <- -0.55
    down_line <- line_at(1, y0, slope)
    floor_line <- function(i) down_line(i) - 9
    df <- syn_confined_path(n, start = y0 - 3, lo_fn = floor_line, hi_fn = down_line, vol = 1.1, seed = seed)
    df$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = n)
    shapes <- list(syn_line(df$Date[1], tail(df$Date, 1), down_line(1), down_line(n), "#e74c3c", "solid", 2.5))
    ann <- list(syn_tag(df$Date[round(n * 0.55)], down_line(round(n * 0.55)) - 1.6,
                         "Downtrend Line (Resistance) \u2014 Connects Falling Swing Highs (LHs)", "#e74c3c", 9))
    title <- paste0("Valid Downtrend Line (Example ", ifelse(kind == "downtrend1", 1, 2), ")")
    return(syn_chart(df, title, shapes, ann))
    
  } else if (kind == "broken_uptrend") {
    y0 <- 100; slope <- 0.6
    up_line <- line_at(1, y0, slope)
    ceil_line <- function(i) up_line(i) + 9
    valid <- syn_confined_path(38, start = y0 + 3, lo_fn = up_line, hi_fn = ceil_line, vol = 1.1, seed = seed)
    break_leg <- syn_path(22, start = up_line(38) - 1.5, drift = -1.3, vol = 1.2, seed = seed + 50)
    valid$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = 38)
    break_leg$Date <- seq(tail(valid$Date, 1) + 1, by = "day", length.out = 22)
    df <- bind_rows(valid, break_leg)
    shapes <- list(syn_line(df$Date[1], valid$Date[38], up_line(1), up_line(38), "#27ae60", "solid", 2.5))
    ann <- list(syn_tag(break_leg$Date[3], max(df$High), "Line Broken \u2014 Closes Through the Trendline", "#e74c3c", 10))
    return(syn_chart(df, "Broken Uptrend Line", shapes, ann))
    
  } else if (kind == "broken_downtrend") {
    y0 <- 140; slope <- -0.6
    down_line <- line_at(1, y0, slope)
    floor_line <- function(i) down_line(i) - 9
    valid <- syn_confined_path(38, start = y0 - 3, lo_fn = floor_line, hi_fn = down_line, vol = 1.1, seed = seed)
    break_leg <- syn_path(22, start = down_line(38) + 1.5, drift = 1.3, vol = 1.2, seed = seed + 50)
    valid$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = 38)
    break_leg$Date <- seq(tail(valid$Date, 1) + 1, by = "day", length.out = 22)
    df <- bind_rows(valid, break_leg)
    shapes <- list(syn_line(df$Date[1], valid$Date[38], down_line(1), down_line(38), "#e74c3c", "solid", 2.5))
    ann <- list(syn_tag(break_leg$Date[3], min(df$Low), "Line Broken \u2014 Closes Through the Trendline", "#27ae60", 10))
    return(syn_chart(df, "Broken Downtrend Line", shapes, ann))
    
  } else if (kind == "ctr_break_uptrend") {
    # Primary uptrend line (drawn across the FULL series) stays valid throughout. A
    # shorter countertrend (correction) line resists the pullback from above, sloping
    # against the primary trend, then gets broken as leg2 resumes the uptrend — same
    # "line = confinement boundary" construction as above, chained across 2 segments.
    y0 <- 96; slope <- 0.5
    up_line <- line_at(1, y0, slope)
    ceil_line <- function(i) up_line(i) + 12
    leg1 <- syn_confined_path(24, start = y0 + 3, lo_fn = up_line, hi_fn = ceil_line, vol = 1.0, seed = seed)
    
    pull_y0 <- up_line(24) + 6; pull_slope <- -0.45
    ctr_line <- line_at(1, pull_y0, pull_slope)  # LOCAL to the pull segment (bar 1 = start of pull)
    pull_floor <- w1_offset_fn(up_line, 25)       # primary uptrend line, offset to pull's local index
    pull <- syn_confined_path(14, start = pull_y0 - 2, lo_fn = pull_floor, hi_fn = ctr_line, vol = 0.7, seed = seed + 20)
    
    leg2 <- syn_path(22, start = ctr_line(14) + 1.5, drift = 0.9, vol = 1.1, seed = seed + 40)
    leg1$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = 24)
    pull$Date <- seq(tail(leg1$Date, 1) + 1, by = "day", length.out = 14)
    leg2$Date <- seq(tail(pull$Date, 1) + 1, by = "day", length.out = 22)
    df <- bind_rows(leg1, pull, leg2)
    
    shapes <- list(
      syn_line(leg1$Date[1], tail(df$Date, 1), up_line(1), up_line(60), "#27ae60", "solid", 2.5),
      syn_line(pull$Date[1], pull$Date[14], ctr_line(1), ctr_line(14), "#9b59b6", "dash", 2)
    )
    ann <- list(syn_tag(leg2$Date[4], max(df$High) * 0.98, "Countertrend Line Broken \u2192 Uptrend Resumes", "#27ae60", 10))
    return(syn_chart(df, "Broken Countertrend Line — Uptrend Continues", shapes, ann))
    
  } else if (kind == "ctr_break_downtrend") {
    y0 <- 144; slope <- -0.5
    down_line <- line_at(1, y0, slope)
    floor_line <- function(i) down_line(i) - 12
    leg1 <- syn_confined_path(24, start = y0 - 3, lo_fn = floor_line, hi_fn = down_line, vol = 1.0, seed = seed)
    
    pull_y0 <- down_line(24) - 6; pull_slope <- 0.45
    ctr_line <- line_at(1, pull_y0, pull_slope)
    pull_ceiling <- w1_offset_fn(down_line, 25)
    pull <- syn_confined_path(14, start = pull_y0 + 2, lo_fn = ctr_line, hi_fn = pull_ceiling, vol = 0.7, seed = seed + 20)
    
    leg2 <- syn_path(22, start = ctr_line(14) - 1.5, drift = -0.9, vol = 1.1, seed = seed + 40)
    leg1$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = 24)
    pull$Date <- seq(tail(leg1$Date, 1) + 1, by = "day", length.out = 14)
    leg2$Date <- seq(tail(pull$Date, 1) + 1, by = "day", length.out = 22)
    df <- bind_rows(leg1, pull, leg2)
    
    shapes <- list(
      syn_line(leg1$Date[1], tail(df$Date, 1), down_line(1), down_line(60), "#e74c3c", "solid", 2.5),
      syn_line(pull$Date[1], pull$Date[14], ctr_line(1), ctr_line(14), "#9b59b6", "dash", 2)
    )
    ann <- list(syn_tag(leg2$Date[4], min(df$Low) * 1.02, "Countertrend Line Broken \u2192 Downtrend Resumes", "#e74c3c", 10))
    return(syn_chart(df, "Broken Countertrend Line — Downtrend Continues", shapes, ann))
    
  } else if (kind == "bull_channel") {
    # A free-trading lead-in (no lines yet) settles into a well-defined ascending
    # channel for the rest of the chart — matching the reference image, where the
    # channel only occupies part of the chart's history, not the whole series.
    n_lead <- 16; n_chan <- 44
    lead_in <- syn_path(n_lead, start = 110, drift = -0.6, vol = 1.1, seed = seed)
    chan_start <- tail(lead_in$Close, 1)
    trend_line <- line_at(1, chan_start - 2, 0.45)  # local to the channel segment
    channel_line <- function(i) trend_line(i) + 7
    chan <- syn_confined_path(n_chan, start = chan_start, lo_fn = trend_line, hi_fn = channel_line, vol = 1.0, seed = seed + 30)
    lead_in$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = n_lead)
    chan$Date <- seq(tail(lead_in$Date, 1) + 1, by = "day", length.out = n_chan)
    df <- bind_rows(lead_in, chan)
    shapes <- list(
      syn_line(chan$Date[1], tail(chan$Date, 1), trend_line(1), trend_line(n_chan), "#27ae60", "solid", 2.5),
      syn_line(chan$Date[1], tail(chan$Date, 1), channel_line(1), channel_line(n_chan), "#27ae60", "solid", 2.5)
    )
    ann <- list(syn_tag(chan$Date[round(n_chan * 0.5)], (trend_line(round(n_chan * 0.5)) + channel_line(round(n_chan * 0.5))) / 2,
                         "Channel Line \u2014 Parallel Duplicate of the Trendline", "#1e8449", 8))
    return(syn_chart(df, "Bullish (Ascending) Channel", shapes, ann))
    
  } else if (kind == "bear_channel") {
    n_lead <- 16; n_chan <- 44
    lead_in <- syn_path(n_lead, start = 130, drift = 0.6, vol = 1.1, seed = seed)
    chan_start <- tail(lead_in$Close, 1)
    trend_line <- line_at(1, chan_start + 2, -0.45)
    channel_line <- function(i) trend_line(i) - 7
    chan <- syn_confined_path(n_chan, start = chan_start, lo_fn = channel_line, hi_fn = trend_line, vol = 1.0, seed = seed + 30)
    lead_in$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = n_lead)
    chan$Date <- seq(tail(lead_in$Date, 1) + 1, by = "day", length.out = n_chan)
    df <- bind_rows(lead_in, chan)
    shapes <- list(
      syn_line(chan$Date[1], tail(chan$Date, 1), trend_line(1), trend_line(n_chan), "#e74c3c", "solid", 2.5),
      syn_line(chan$Date[1], tail(chan$Date, 1), channel_line(1), channel_line(n_chan), "#e74c3c", "solid", 2.5)
    )
    ann <- list(syn_tag(chan$Date[round(n_chan * 0.5)], (trend_line(round(n_chan * 0.5)) + channel_line(round(n_chan * 0.5))) / 2,
                         "Channel Line \u2014 Parallel Duplicate of the Trendline", "#c0392b", 8))
    return(syn_chart(df, "Bearish (Descending) Channel", shapes, ann))
  }
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

# ══════════════════════════════════════════════════════════════════════════
# CANONICAL SECTION/SPEC DEFINITIONS — single source of truth for the UI boxes,
# the interactive renders, and the PDF export (each spec carries id+title+desc+gen).
# ══════════════════════════════════════════════════════════════════════════

w1_sections <- function() {
  sr_specs <- list(
    list(id = "sr1", title = "FX Pair 1 — EUR/USD (simulated)", desc = "Support & Resistance across Daily/Weekly/Monthly timeframes.",
         gen = function() w1_support_resistance("EUR/USD", 101)),
    list(id = "sr2", title = "FX Pair 2 — GBP/USD (simulated)", desc = "Support & Resistance across Daily/Weekly/Monthly timeframes.",
         gen = function() w1_support_resistance("GBP/USD", 102)),
    list(id = "sr3", title = "Stock Market Index (simulated)", desc = "Support & Resistance across Daily/Weekly/Monthly timeframes.",
         gen = function() w1_support_resistance("Stock Index", 103)),
    list(id = "sr4", title = "Commodity — Gold (simulated)",   desc = "Support & Resistance across Daily/Weekly/Monthly timeframes.",
         gen = function() w1_support_resistance("Gold", 104))
  )
  
  tl_specs <- list(
    list(id = "tl1", title = "Uptrend Line — Example 1", desc = "A valid uptrend line connecting at least two rising swing lows.",
         gen = function() w1_trendline("uptrend1", 111)),
    list(id = "tl2", title = "Uptrend Line — Example 2", desc = "A second valid uptrend line, different asset/period.",
         gen = function() w1_trendline("uptrend2", 112)),
    list(id = "tl3", title = "Downtrend Line — Example 1", desc = "A valid downtrend line connecting at least two falling swing highs.",
         gen = function() w1_trendline("downtrend1", 113)),
    list(id = "tl4", title = "Downtrend Line — Example 2", desc = "A second valid downtrend line, different asset/period.",
         gen = function() w1_trendline("downtrend2", 114)),
    list(id = "tl5", title = "Broken Uptrend Line", desc = "Price closes decisively through the uptrend line, signalling the uptrend has ended.",
         gen = function() w1_trendline("broken_uptrend", 115)),
    list(id = "tl6", title = "Broken Downtrend Line", desc = "Price closes decisively through the downtrend line, signalling the downtrend has ended.",
         gen = function() w1_trendline("broken_downtrend", 116)),
    list(id = "tl7", title = "Broken Countertrend Line (Uptrend Continues)", desc = "A short corrective countertrend line within a longer uptrend gets broken, confirming the primary uptrend resumes.",
         gen = function() w1_trendline("ctr_break_uptrend", 117)),
    list(id = "tl8", title = "Broken Countertrend Line (Downtrend Continues)", desc = "A short corrective countertrend line within a longer downtrend gets broken, confirming the primary downtrend resumes.",
         gen = function() w1_trendline("ctr_break_downtrend", 118)),
    list(id = "tl9", title = "Bullish Channel", desc = "Parallel ascending trend and channel lines containing price action.",
         gen = function() w1_trendline("bull_channel", 119)),
    list(id = "tl10", title = "Bearish Channel", desc = "Parallel descending trend and channel lines containing price action.",
         gen = function() w1_trendline("bear_channel", 120))
  )
  
  candle_defs <- list(
    list(key = "shooting_star",     label = "Shooting Star"),
    list(key = "dark_cloud",        label = "Dark Cloud Cover"),
    list(key = "inverted_hammer",   label = "Inverted Hammer"),
    list(key = "long_legged_doji",  label = "Long-Legged Doji in a Downtrend"),
    list(key = "dragonfly_doji",    label = "Dragonfly Doji"),
    list(key = "hammer_support",    label = "Hammer at a Support Level"),
    list(key = "bearish_engulfing", label = "Bearish Engulfing Pattern"),
    list(key = "piercing",          label = "Piercing Pattern"),
    list(key = "hanging_man",       label = "Hanging Man")
  )
  cs_specs <- list()
  seed_i <- 130
  for (cd in candle_defs) {
    seed_i <- seed_i + 1
    local({
      kk <- cd$key; lbl <- cd$label; s1 <- seed_i
      cs_specs[[length(cs_specs) + 1]] <<- list(
        id = paste0("cs_", kk, "_c"), title = paste0(lbl, " — Confirmed"),
        desc = "Pattern confirmed: price follows through in the implied reversal direction.",
        gen = function() w1_candle(kk, TRUE, s1)
      )
      cs_specs[[length(cs_specs) + 1]] <<- list(
        id = paste0("cs_", kk, "_f"), title = paste0(lbl, " — Failed"),
        desc = "Pattern failed: the prior trend resumes instead of reversing.",
        gen = function() w1_candle(kk, FALSE, s1 + 500)
      )
    })
  }
  cs_specs[[length(cs_specs) + 1]] <- list(
    id = "marubozu_res", title = "Marubozu — Resistance Breakout",
    desc = "A strong bullish Marubozu candle confirms the breakout of a resistance level.",
    gen = function() w1_marubozu("resistance", 190)
  )
  cs_specs[[length(cs_specs) + 1]] <- list(
    id = "marubozu_trend", title = "Marubozu — Uptrend Line Breakout",
    desc = "A strong bearish Marubozu candle confirms the breakout (violation) of an uptrend line.",
    gen = function() w1_marubozu("trend", 191)
  )
  
  list(
    list(title = "Support & Resistance", specs = sr_specs),
    list(title = "Trend Lines, Channels & Countertrend Lines", specs = tl_specs),
    list(title = "Japanese Candlesticks", specs = cs_specs)
  )
}

# ══════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════

weekly_activity_week1_ui <- function(id) {
  ns <- NS(id)
  sections <- w1_sections()
  
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
              "feature requested in Step 1 — Support & Resistance, Trend Lines/Channels/",
              "Countertrend Lines, and Japanese Candlestick patterns (34 examples in total). This is for ",
              "practising pattern recognition, not a claim about real market history."
            ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    weekly_download_ui(ns),
    lapply(sections, function(sec) weekly_grid_ui(ns, sec$specs, sec$title))
  )
}

weekly_activity_week1_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    sections <- w1_sections()
    for (sec in sections) weekly_grid_server(output, sec$specs)
    weekly_download_server(output, "Step 1", sections, "step1_activity")
    session$onSessionEnded(function() {})
  })
}

