# ====================================================================================================
# (was modules/weekly_activity_week1.R)
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

# ====================================================================================================
# (was modules/weekly_activity_week2.R)
# modules/weekly_activity_week2.R
# Covers every point in Step 2 — Fibonacci retracements/expansions
# (8 examples) and 14 named Price Patterns x hit-target/failed (28 examples) = 36 total.
# All charts use synthetic OHLC data — see R/utils_synthetic.R for the generation engine.

# ══════════════════════════════════════════════════════════════════════════
# FIBONACCI GENERATORS
# ══════════════════════════════════════════════════════════════════════════

# direction: "down" or "up" (the primary trend). touch_level: 0.5 or 0.618.
w2_fib_retracement <- function(direction, touch_level, seed) {
  set.seed(seed)
  down <- direction == "down"
  line_at <- function(x0, y0, slope) function(x) y0 + slope * (x - x0)
  trend_color <- if (down) "#e74c3c" else "#27ae60"
  
  # The trend line is defined FIRST and leg1 is generated confined to respect it (same
  # technique as Step 1's trend lines) — this guarantees leg1's candles can never cut
  # through the line and produces several genuine touches, rather than drawing a line
  # reactively over an unconfined random walk.
  n1 <- 26
  y0 <- if (down) 140 else 100
  slope <- if (down) -1.5 else 1.5
  trend_line <- line_at(1, y0, slope)
  opp_bound <- function(i) trend_line(i) + (if (down) -14 else 14)
  leg1 <- if (down) syn_confined_path(n1, start = y0 - 3, lo_fn = opp_bound, hi_fn = trend_line, vol = 1.1, seed = seed)
          else syn_confined_path(n1, start = y0 + 3, lo_fn = trend_line, hi_fn = opp_bound, vol = 1.1, seed = seed)
  leg1$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = n1)
  
  top <- max(leg1$Close); bottom <- min(leg1$Close)
  rng <- top - bottom
  fib_price <- if (down) bottom + rng * touch_level else top - rng * touch_level
  
  # Retrace toward the fib level, touch it, then resume the primary trend
  retr <- syn_path(14, start = tail(leg1$Close, 1), drift = ((fib_price - tail(leg1$Close, 1)) / 14), vol = 0.5, seed = seed + 30)
  cont_drift <- if (down) -1.0 else 1.0
  cont <- syn_path(18, start = tail(retr$Close, 1), drift = cont_drift, vol = 1, seed = seed + 60)
  
  df <- syn_concat(leg1, retr, cont)
  retr_dates <- syn_seg(df, 2); cont_dates <- syn_seg(df, 3)
  
  # Locate the retracement's actual extreme (closest approach to the fib level) and its
  # corrected post-concat date for the Fib-touch annotation.
  touch_idx <- if (down) which.max(retr$Close) else which.min(retr$Close)
  touch_price <- retr$Close[touch_idx]
  touch_date <- retr_dates[touch_idx]
  
  fib_levels <- c(0, 0.236, 0.382, 0.5, 0.618, 0.786, 1)
  shapes <- lapply(fib_levels, function(l) {
    y <- if (down) bottom + rng * l else top - rng * l
    col <- if (abs(l - touch_level) < 0.001) "#f39c12" else "#bdc3c7"
    syn_hline(df$Date[1], tail(df$Date, 1), y, col, if (abs(l - touch_level) < 0.001) "solid" else "dot",
              if (abs(l - touch_level) < 0.001) 2 else 1)
  })
  
  # The trend line is drawn exactly across leg1's span — where price was actually
  # generated to respect it — extended a little into the retracement so it's visibly
  # the level the pullback approaches.
  ext_idx <- n1 + 6
  shapes[[length(shapes) + 1]] <- syn_line(leg1$Date[1], retr_dates[min(6, length(retr_dates))],
                                            trend_line(1), trend_line(ext_idx), trend_color, "solid", 2)
  
  ann <- list(
    syn_tag(touch_date, touch_price,
            paste0(touch_level * 100, "% Fib Touch \u2192 ", ifelse(down, "Downtrend", "Uptrend"), " Resumes"),
            trend_color, 9),
    syn_tag(leg1$Date[round(n1 * 0.4)], trend_line(round(n1 * 0.4)) + (if (down) 1.8 else -1.8),
            paste0(ifelse(down, "Downtrend", "Uptrend"), " Line \u2014 Multiple Touches"), trend_color, 8)
  )
  
  title <- paste0(ifelse(down, "Downtrend", "Uptrend"), " Retracement to ", touch_level * 100,
                   "% Fibonacci, Then ", ifelse(down, "Continues Down", "Continues Up"))
  syn_chart(df, title, shapes, ann)
}

w2_fib_expansion <- function(direction, seed) {
  set.seed(seed)
  down <- direction == "down"
  legA <- if (down) syn_path(22, start = 130, drift = -1.1, vol = 1, seed = seed)
          else syn_path(22, start = 100, drift = 1.1, vol = 1, seed = seed)
  legA_size <- abs(legA$Close[1] - tail(legA$Close, 1))
  
  retr_drift <- if (down) 0.6 else -0.6
  retr <- syn_path(12, start = tail(legA$Close, 1), drift = retr_drift, vol = 0.6, seed = seed + 30)
  retr_end <- tail(retr$Close, 1)
  
  target_price <- if (down) retr_end - legA_size else retr_end + legA_size
  legB_drift <- if (down) -1.1 else 1.1
  legB <- syn_path(20, start = retr_end, drift = legB_drift * 1.05, vol = 1, seed = seed + 60)
  
  df <- syn_concat(legA, retr, legB)
  retr_dates <- syn_seg(df, 2); legB_dates <- syn_seg(df, 3)
  shapes <- list(
    syn_hline(retr_dates[1], tail(df$Date, 1), retr_end, "#7f8c8d", "dot", 1),
    syn_hline(legB_dates[1], tail(df$Date, 1), target_price, "#f39c12", "dash", 2)
  )
  ann <- list(syn_tag(legB_dates[round(nrow(legB) * 0.6)], target_price,
                       "100% Fib Expansion Target", "#f39c12", 10))
  title <- paste0(ifelse(down, "Downtrend", "Uptrend"), " — 100% Fibonacci Expansion of Prior ", ifelse(down, "Downward", "Upward"), " Leg")
  syn_chart(df, title, shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# PRICE PATTERN GENERATORS
# ══════════════════════════════════════════════════════════════════════════

# -- Triangles: symmetrical (with up/down context) and ascending --
w2_triangle <- function(kind, context, hit, seed) {
  set.seed(seed)
  n_lead <- 16
  lead <- if (context == "down") syn_path(n_lead, start = 140, drift = -1.0, vol = 1, seed = seed)
          else if (context == "up") syn_path(n_lead, start = 100, drift = 1.0, vol = 1, seed = seed)
          else syn_path(n_lead, start = 100, drift = 0.3, vol = 1, seed = seed)
  
  mid <- tail(lead$Close, 1)
  n_pat <- 24
  height0 <- 8
  # Narrowing envelope for the triangle: symmetrical converges from both sides;
  # ascending keeps a flat top with rising lows.
  hi_fn <- function(i) { frac <- i / n_pat; if (kind == "symmetrical") mid + height0 * (1 - 0.85 * frac) else mid + height0 * 0.35 }
  lo_fn <- function(i) { frac <- i / n_pat; mid - height0 * (1 - 0.85 * frac) }
  # Continuous confined random walk — each candle's Open derives from the prior candle's
  # Close (like syn_path), while staying inside the narrowing hi/lo envelope, instead of
  # independent per-bar draws (which produced disconnected, jumpy candles).
  pat <- syn_confined_path(n_pat, start = tail(lead$Close, 1), lo_fn = lo_fn, hi_fn = hi_fn, vol = 1, seed = seed + 10)
  pat$Date <- seq(tail(lead$Date, 1) + 1, by = "day", length.out = n_pat)
  
  breakout_dir <- if (context == "down") -1 else 1
  target_dist <- height0 * 1.9
  breakout_price <- mid + breakout_dir * height0 * 0.35
  outc <- syn_outcome_tail(breakout_price, breakout_dir, target_dist, hit, seed + 200)
  
  df <- syn_concat(lead, pat, outc$df)
  pat_dates <- syn_seg(df, 2); outc_dates <- syn_seg(df, 3)
  
  # boundary lines over the pattern segment — drawn from the EXACT hi_fn/lo_fn values
  # at bar 1 and bar n_pat (hi_fn already branches on kind), so they align precisely
  # with the envelope pat was confined to.
  x0 <- pat_dates[1]; x1 <- pat_dates[n_pat]
  shapes <- list(
    syn_line(x0, x1, hi_fn(1), hi_fn(n_pat), "#e67e22", "solid", 2),
    syn_line(x0, x1, lo_fn(1), lo_fn(n_pat), "#e67e22", "solid", 2)
  )
  shapes[[length(shapes)+1]] <- syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5)
  ann <- list(syn_tag(outc_dates[1], breakout_price, ifelse(hit, "Breakout \u2192 Target Hit", "Breakout \u2192 Target Missed"),
                       ifelse(hit, "#27ae60", "#e74c3c"), 10))
  
  label <- if (kind == "symmetrical") paste0("Symmetrical Triangle in a ", ifelse(context == "down", "Downtrend", "Uptrend"))
           else "Ascending Triangle"
  syn_chart(df, paste0(label, " — ", ifelse(hit, "Hit Target", "Failed to Reach Target")), shapes, ann)
}

# -- Wedges: rising/falling, each with up/down context --
w2_wedge <- function(kind, context, hit, seed) {
  set.seed(seed)
  rising <- kind == "rising"
  lead <- if (context == "down") syn_path(14, start = 140, drift = -1.0, vol = 1, seed = seed)
          else syn_path(14, start = 100, drift = 1.0, vol = 1, seed = seed)
  mid <- tail(lead$Close, 1)
  
  n_pat <- 22
  width0 <- 7
  slope_dir <- if (rising) 0.35 else -0.35
  center_fn <- function(i) mid + slope_dir * (i / n_pat) * 12
  half_w_fn <- function(i) width0 * (1 - 0.75 * (i / n_pat))
  hi_fn <- function(i) center_fn(i) + half_w_fn(i)
  lo_fn <- function(i) center_fn(i) - half_w_fn(i)
  # Continuous confined random walk (Open chains from prior Close) inside the same
  # converging envelope used to draw the boundary lines below, instead of independent
  # per-bar draws (which produced disconnected, jumpy candles not tracking the wedge).
  pat <- syn_confined_path(n_pat, start = mid, lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.9, seed = seed + 10)
  pat$Date <- seq(tail(lead$Date, 1) + 1, by = "day", length.out = n_pat)
  
  # Wedges typically break AGAINST their own slope direction
  breakout_dir <- if (rising) -1 else 1
  target_dist <- width0 * 1.7
  final_center <- center_fn(n_pat)
  breakout_price <- final_center
  outc <- syn_outcome_tail(breakout_price, breakout_dir, target_dist, hit, seed + 200)
  
  df <- syn_concat(lead, pat, outc$df)
  pat_dates <- syn_seg(df, 2); outc_dates <- syn_seg(df, 3)
  x0 <- pat_dates[1]; x1 <- pat_dates[n_pat]
  upper0 <- hi_fn(1); upper1 <- hi_fn(n_pat)
  lower0 <- lo_fn(1); lower1 <- lo_fn(n_pat)
  shapes <- list(
    syn_line(x0, x1, upper0, upper1, "#9b59b6", "solid", 2),
    syn_line(x0, x1, lower0, lower1, "#9b59b6", "solid", 2),
    syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5)
  )
  ann <- list(syn_tag(outc_dates[1], breakout_price, ifelse(hit, "Breakout \u2192 Target Hit", "Breakout \u2192 Target Missed"),
                       ifelse(hit, "#27ae60", "#e74c3c"), 10))
  
  label <- paste0(ifelse(rising, "Rising", "Falling"), " Wedge in a ", ifelse(context == "down", "Downtrend", "Uptrend"))
  syn_chart(df, paste0(label, " — ", ifelse(hit, "Hit Target", "Failed to Reach Target")), shapes, ann)
}

# -- Flags & Pennant: sharp pole then a small consolidation, breakout continues the pole --
w2_flag_pennant <- function(kind, hit, seed) {
  set.seed(seed)
  bullish <- kind == "bull_flag"
  pole_drift <- if (bullish) 2.2 else -2.2
  pole <- syn_path(10, start = if (bullish) 95 else 135, drift = pole_drift, vol = 1.1, seed = seed)
  pole_size <- abs(tail(pole$Close,1) - pole$Close[1])
  mid <- tail(pole$Close, 1)
  
  n_pat <- 14
  width0 <- 3.2
  cons_drift <- if (kind == "bull_flag") -0.25 else if (kind == "bear_flag") 0.25 else 0
  # The consolidation channel bounds are defined FIRST, and cons is generated confined
  # between them (same technique as the triangle/wedge above), so the drawn boundary
  # lines are guaranteed to actually contain every candle rather than being fitted to
  # an already-generated unconfined random walk after the fact.
  if (kind == "pennant") {
    hi_fn <- function(i) mid + width0 * (1 - 0.7 * (i / n_pat))
    lo_fn <- function(i) mid - width0 * (1 - 0.7 * (i / n_pat))
  } else {
    hi_fn <- function(i) mid + width0 + cons_drift * i
    lo_fn <- function(i) mid - width0 + cons_drift * i
  }
  cons <- syn_confined_path(n_pat, start = mid, lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.7, seed = seed + 10)
  cons$Date <- seq(tail(pole$Date, 1) + 1, by = "day", length.out = n_pat)
  
  breakout_dir <- if (bullish) 1 else -1
  outc <- syn_outcome_tail(tail(cons$Close,1), breakout_dir, pole_size * 0.95, hit, seed + 200)
  
  df <- syn_concat(pole, cons, outc$df)
  cons_dates <- syn_seg(df, 2); outc_dates <- syn_seg(df, 3)
  x0 <- cons_dates[1]; x1 <- cons_dates[n_pat]
  shapes <- list(
    syn_line(x0, x1, hi_fn(1), hi_fn(n_pat), "#3498db", "solid", 2),
    syn_line(x0, x1, lo_fn(1), lo_fn(n_pat), "#3498db", "solid", 2)
  )
  shapes[[length(shapes)+1]] <- syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5)
  ann <- list(syn_tag(outc_dates[1], tail(cons$Close,1), ifelse(hit, "Breakout \u2192 Target Hit", "Breakout \u2192 Target Missed"),
                       ifelse(hit, "#27ae60", "#e74c3c"), 10))
  
  label <- switch(kind, bull_flag = "Bullish Flag", bear_flag = "Bearish Flag", pennant = "Bearish Pennant")
  syn_chart(df, paste0(label, " — ", ifelse(hit, "Hit Target", "Failed to Reach Target")), shapes, ann)
}

# -- Head & Shoulders (regular / inverse) --
w2_hs <- function(inverse, hit, seed) {
  set.seed(seed)
  lead <- if (inverse) syn_path(14, start = 130, drift = -0.9, vol = 1, seed = seed)
          else syn_path(14, start = 100, drift = 0.9, vol = 1, seed = seed)
  base <- tail(lead$Close, 1)
  sgn <- if (inverse) -1 else 1  # peaks point down (inverse) or up (regular)
  
  shoulder1 <- syn_path(8, start = base, drift = sgn * 1.0, vol = 0.5, seed = seed + 5)
  s1_peak <- tail(shoulder1$Close, 1)
  dip1 <- syn_path(6, start = s1_peak, drift = -sgn * 0.9, vol = 0.4, seed = seed + 15)
  neckline_l <- tail(dip1$Close, 1)
  head <- syn_path(8, start = neckline_l, drift = sgn * 1.6, vol = 0.5, seed = seed + 25)
  h_peak <- tail(head$Close, 1)
  dip2 <- syn_path(6, start = h_peak, drift = -sgn * 1.5, vol = 0.4, seed = seed + 35)
  neckline_r <- tail(dip2$Close, 1)
  shoulder2 <- syn_path(8, start = neckline_r, drift = sgn * 0.95, vol = 0.5, seed = seed + 45)
  s2_peak <- tail(shoulder2$Close, 1)
  down2 <- syn_path(6, start = s2_peak, drift = -sgn * 1.5, vol = 0.5, seed = seed + 55)
  
  neckline <- mean(c(neckline_l, neckline_r))
  head_dist <- abs(h_peak - neckline)
  breakout_price <- tail(down2$Close, 1)
  breakout_dir <- -sgn
  outc <- syn_outcome_tail(breakout_price, breakout_dir, head_dist, hit, seed + 200)
  
  df <- syn_concat(lead, shoulder1, dip1, head, dip2, shoulder2, down2, outc$df)
  head_dates <- syn_seg(df, 4); outc_dates <- syn_seg(df, 8)
  # neckline hline spans the full chart width for clarity, so it doesn't need segment dates
  shapes <- list(
    syn_hline(df$Date[1], tail(df$Date,1), neckline, "#9b59b6", "solid", 2),
    syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5)
  )
  ann <- list(
    syn_tag(head_dates[round(nrow(head)/2)], h_peak, "Head", "#002C3C", 10),
    syn_tag(outc_dates[1], breakout_price, ifelse(hit, "Neckline Break \u2192 Target Hit", "Neckline Break \u2192 Target Missed"),
            ifelse(hit, "#27ae60", "#e74c3c"), 10)
  )
  label <- if (inverse) "Inverse Head & Shoulders" else "Head & Shoulders"
  syn_chart(df, paste0(label, " — ", ifelse(hit, "Hit Target", "Failed to Reach Target")), shapes, ann)
}

# -- Double Top / Double Bottom --
w2_double <- function(kind, hit, seed) {
  set.seed(seed)
  top <- kind == "top"
  lead <- if (top) syn_path(14, start = 100, drift = 0.9, vol = 1, seed = seed)
          else syn_path(14, start = 130, drift = -0.9, vol = 1, seed = seed)
  sgn <- if (top) 1 else -1
  peak1 <- syn_path(8, start = tail(lead$Close,1), drift = sgn * 1.1, vol = 0.5, seed = seed + 5)
  p1 <- tail(peak1$Close, 1)
  trough <- syn_path(10, start = p1, drift = -sgn * 1.3, vol = 0.5, seed = seed + 15)
  mid_level <- tail(trough$Close, 1)
  peak2 <- syn_path(8, start = mid_level, drift = sgn * 1.15, vol = 0.5, seed = seed + 25)
  p2 <- tail(peak2$Close, 1)
  # optional retest bounce back toward peak level before breaking down (double top only, per doc)
  retest <- syn_path(6, start = p2, drift = -sgn * 0.6, vol = 0.4, seed = seed + 35)
  
  height <- abs(p1 - mid_level)
  breakout_price <- tail(retest$Close, 1)
  breakout_dir <- -sgn
  outc <- syn_outcome_tail(breakout_price, breakout_dir, height, hit, seed + 200)
  
  df <- syn_concat(lead, peak1, trough, peak2, retest, outc$df)
  peak1_dates <- syn_seg(df, 2); trough_dates <- syn_seg(df, 3)
  peak2_dates <- syn_seg(df, 4); outc_dates <- syn_seg(df, 6)
  shapes <- list(
    syn_hline(trough_dates[nrow(trough)], tail(df$Date,1), mid_level, "#9b59b6", "solid", 2),
    syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5)
  )
  ann <- list(
    syn_tag(peak1_dates[nrow(peak1)], p1, "Peak/Trough 1", "#002C3C", 9),
    syn_tag(peak2_dates[nrow(peak2)], p2, "Peak/Trough 2", "#002C3C", 9),
    syn_tag(outc_dates[1], breakout_price, ifelse(hit, "Breakdown \u2192 Target Hit", "Breakdown \u2192 Target Missed"),
            ifelse(hit, "#27ae60", "#e74c3c"), 10)
  )
  label <- if (top) "Double Top (with Retest)" else "Double Bottom"
  syn_chart(df, paste0(label, " — ", ifelse(hit, "Hit Target", "Failed to Reach Target")), shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# CANONICAL SECTIONS
# ══════════════════════════════════════════════════════════════════════════

w2_sections <- function() {
  fib_specs <- list(
    list(id = "fib1", title = "Downtrend Retracement to 50% Fib", desc = "Retraces to the 50% Fibonacci level, coinciding with a bounce off the downtrend line, then the downtrend resumes.",
         gen = function() w2_fib_retracement("down", 0.5, 301)),
    list(id = "fib2", title = "Downtrend Retracement to 61.8% Fib", desc = "Retraces to the 61.8% Fibonacci level, coinciding with a bounce off the downtrend line, then the downtrend resumes.",
         gen = function() w2_fib_retracement("down", 0.618, 302)),
    list(id = "fib3", title = "Uptrend Retracement to 50% Fib", desc = "Retraces to the 50% Fibonacci level, coinciding with a bounce off the uptrend line, then the uptrend resumes.",
         gen = function() w2_fib_retracement("up", 0.5, 303)),
    list(id = "fib4", title = "Uptrend Retracement to 61.8% Fib", desc = "Retraces to the 61.8% Fibonacci level, coinciding with a bounce off the uptrend line, then the uptrend resumes.",
         gen = function() w2_fib_retracement("up", 0.618, 304)),
    list(id = "fib5", title = "Downtrend — 100% Fib Expansion (Ex. 1)", desc = "100% expansion of the prior downward leg, projected from the retracement high.",
         gen = function() w2_fib_expansion("down", 305)),
    list(id = "fib6", title = "Downtrend — 100% Fib Expansion (Ex. 2)", desc = "A second downtrend expansion example.",
         gen = function() w2_fib_expansion("down", 306)),
    list(id = "fib7", title = "Uptrend — 100% Fib Expansion (Ex. 1)", desc = "100% expansion of the prior upward leg, projected from the retracement low.",
         gen = function() w2_fib_expansion("up", 307)),
    list(id = "fib8", title = "Uptrend — 100% Fib Expansion (Ex. 2)", desc = "A second uptrend expansion example.",
         gen = function() w2_fib_expansion("up", 308))
  )
  
  pp_defs <- list(
    list(id = "pp_symdown", gen = function(hit, seed) w2_triangle("symmetrical", "down", hit, seed), label = "Symmetrical Triangle in a Downtrend"),
    list(id = "pp_symup",   gen = function(hit, seed) w2_triangle("symmetrical", "up",   hit, seed), label = "Symmetrical Triangle in an Uptrend"),
    list(id = "pp_asc",     gen = function(hit, seed) w2_triangle("ascending", "flat",   hit, seed), label = "Ascending Triangle"),
    list(id = "pp_ihs",     gen = function(hit, seed) w2_hs(TRUE, hit, seed),                        label = "Inverse Head & Shoulders"),
    list(id = "pp_dtop",    gen = function(hit, seed) w2_double("top", hit, seed),                   label = "Double Top (with Retest)"),
    list(id = "pp_bearflag",gen = function(hit, seed) w2_flag_pennant("bear_flag", hit, seed),       label = "Bearish Flag"),
    list(id = "pp_bullflag",gen = function(hit, seed) w2_flag_pennant("bull_flag", hit, seed),       label = "Bullish Flag"),
    list(id = "pp_pennant", gen = function(hit, seed) w2_flag_pennant("pennant", hit, seed),         label = "Bearish Pennant"),
    list(id = "pp_rwdown",  gen = function(hit, seed) w2_wedge("rising", "down", hit, seed),         label = "Rising Wedge in a Downtrend"),
    list(id = "pp_rwup",    gen = function(hit, seed) w2_wedge("rising", "up",   hit, seed),         label = "Rising Wedge in an Uptrend"),
    list(id = "pp_fwdown",  gen = function(hit, seed) w2_wedge("falling", "down",hit, seed),         label = "Falling Wedge in a Downtrend"),
    list(id = "pp_fwup",    gen = function(hit, seed) w2_wedge("falling", "up",  hit, seed),         label = "Falling Wedge in an Uptrend"),
    list(id = "pp_hs",      gen = function(hit, seed) w2_hs(FALSE, hit, seed),                       label = "Head & Shoulders"),
    list(id = "pp_dbot",    gen = function(hit, seed) w2_double("bottom", hit, seed),                label = "Double Bottom")
  )
  pp_specs <- list()
  seed_i <- 400
  for (pd in pp_defs) {
    seed_i <- seed_i + 1
    local({
      d <- pd; s1 <- seed_i
      pp_specs[[length(pp_specs) + 1]] <<- list(
        id = paste0(d$id, "_hit"), title = paste0(d$label, " — Hit Target"),
        desc = "Pattern breaks out and reaches its measured-move price objective (MPO).",
        gen = function() d$gen(TRUE, s1)
      )
      pp_specs[[length(pp_specs) + 1]] <<- list(
        id = paste0(d$id, "_miss"), title = paste0(d$label, " — Failed to Reach Target"),
        desc = "Pattern breaks out but fails to reach its measured-move price objective.",
        gen = function() d$gen(FALSE, s1 + 500)
      )
    })
  }
  
  list(
    list(title = "Fibonacci", specs = fib_specs),
    list(title = "Price Patterns", specs = pp_specs)
  )
}

# ══════════════════════════════════════════════════════════════════════════
# UI / SERVER
# ══════════════════════════════════════════════════════════════════════════

weekly_activity_week2_ui <- function(id) {
  ns <- NS(id)
  sections <- w2_sections()
  
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
              "feature requested in Step 2 — Fibonacci retracements/expansions and 14 named ",
              "Price Patterns, each with a target-hit and a target-missed example (36 examples in total). ",
              "Trend lines, triangles, wedges, and flag/pennant channels are generated the same way as Step 1: ",
              "the price path is confined to respect each line's exact formula, so it can never cut through a ",
              "candle body and genuinely bounces off the boundary multiple times. This ",
              "is for practising pattern recognition, not a claim about real market history."
            ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    weekly_download_ui(ns),
    lapply(sections, function(sec) weekly_grid_ui(ns, sec$specs, sec$title))
  )
}

weekly_activity_week2_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    sections <- w2_sections()
    for (sec in sections) weekly_grid_server(output, sec$specs)
    weekly_download_server(output, "Step 2", sections, "step2_activity")
    session$onSessionEnded(function() {})
  })
}

# ====================================================================================================
# (was modules/weekly_activity_week3.R)
# modules/weekly_activity_week3.R
# Covers every point in Step 3 — RSI (6), Stochastics (4),
# Moving Averages (4), MACD (2), On-Balance Volume (4 — bullish & bearish divergence
# shown separately), Bollinger Bands (4) = 24 examples. Indicators are computed with
# TTR on synthetic OHLC data — see R/utils_synthetic.R for the generation engine.

w3_rsi_ind <- function(close, dates) {
  r <- as.numeric(TTR::RSI(close, n = 14))
  ok <- !is.na(r)
  list(dates = dates[ok], values = r[ok], label = "RSI", hlines = c(70, 30), color = "#8e44ad", yrange = c(0, 100))
}
w3_stoch_ind <- function(hlc, dates) {
  s <- TTR::stoch(hlc, nFastK = 14, nFastD = 3, nSlowD = 3)
  ok <- !is.na(s[, "fastK"]) & !is.na(s[, "slowD"])
  list(dates = dates[ok], values = as.numeric(s[ok, "fastK"]) * 100, values2 = as.numeric(s[ok, "slowD"]) * 100,
       label = "%K", label2 = "%D", color = "#3498db", color2 = "#e67e22", hlines = c(80, 20), yrange = c(0, 100))
}
w3_macd_ind <- function(close, dates) {
  m <- TTR::MACD(close, nFast = 12, nSlow = 26, nSig = 9)
  ok <- !is.na(m[, "macd"]) & !is.na(m[, "signal"])
  vals <- as.numeric(m[ok, "macd"]); vals2 <- as.numeric(m[ok, "signal"])
  list(dates = dates[ok], values = vals, values2 = vals2, label = "MACD", label2 = "Signal",
       color = "#3498db", color2 = "#e67e22", hlines = 0, yrange = range(c(vals, vals2), na.rm = TRUE))
}
w3_obv_ind <- function(close, volume, dates) {
  delta <- c(0, diff(close))
  incr <- ifelse(delta > 0, volume, ifelse(delta < 0, -volume, 0))
  obv <- cumsum(ifelse(is.na(incr), 0, incr))
  list(dates = dates, values = obv, label = "OBV", color = "#16a085", yrange = range(obv))
}

# ══════════════════════════════════════════════════════════════════════════
# RSI
# ══════════════════════════════════════════════════════════════════════════

w3_rsi_reject <- function(overbought, seed) {
  set.seed(seed)
  lead <- if (overbought) syn_path(30, start = 100, drift = 1.05, vol = 1, seed = seed)
          else syn_path(30, start = 140, drift = -1.05, vol = 1, seed = seed)
  level <- if (overbought) max(lead$High) - 0.3 else min(lead$Low) + 0.3
  tail_drift <- if (overbought) -1.1 else 1.1
  tail_df <- syn_path(16, start = tail(lead$Close, 1), drift = tail_drift, vol = 1, seed = seed + 60)
  df <- syn_concat(lead, tail_df)
  tail_dates <- syn_seg(df, 2)
  shapes <- list(syn_hline(df$Date[1], tail(df$Date,1), level, "#7f8c8d", "dash", 1.5))
  ann <- list(syn_tag(tail_dates[1], level, ifelse(overbought, "Rejected at Resistance", "Bounces off Support"),
                       ifelse(overbought, "#e74c3c", "#27ae60"), 9))
  ind <- w3_rsi_ind(df$Close, df$Date)
  title <- if (overbought) "RSI Overbought — Rejection at Resistance" else "RSI Oversold — Bounce off Support"
  syn_chart(df, title, shapes, ann, indicator = ind)
}

w3_rsi_divergence <- function(bullish, seed) {
  set.seed(seed)
  sgn <- if (bullish) -1 else 1
  lead <- syn_path(10, start = 115, drift = sgn * 0.4, vol = 0.8, seed = seed)
  leg1 <- syn_path(12, start = tail(lead$Close,1), drift = sgn * 1.3, vol = 0.9, seed = seed + 5)
  p1 <- tail(leg1$Close, 1)
  mid <- syn_path(10, start = p1, drift = -sgn * 0.9, vol = 0.7, seed = seed + 15)
  leg2 <- syn_path(12, start = tail(mid$Close,1), drift = sgn * 1.55, vol = 0.9, seed = seed + 25)
  p2 <- tail(leg2$Close, 1)
  tail_df <- syn_path(14, start = p2, drift = -sgn * 1.1, vol = 1, seed = seed + 60)
  
  df <- syn_concat(lead, leg1, mid, leg2, tail_df)
  leg1_dates <- syn_seg(df, 2); leg2_dates <- syn_seg(df, 4)
  ind <- w3_rsi_ind(df$Close, df$Date)
  # Manually bend the RSI at the second extreme to diverge from price, for a clear teaching example
  idx2 <- match(leg2_dates[length(leg2_dates)], ind$dates)
  idx1 <- match(leg1_dates[length(leg1_dates)], ind$dates)
  if (!is.na(idx1) && !is.na(idx2)) {
    if (bullish) ind$values[idx2] <- ind$values[idx1] + 8   # RSI higher low despite price lower low
    else ind$values[idx2] <- ind$values[idx1] - 8            # RSI lower high despite price higher high
  }
  ann <- list(syn_tag(leg2_dates[length(leg2_dates)], p2, paste0(ifelse(bullish,"Bullish","Bearish")," Divergence"),
                       ifelse(bullish, "#27ae60", "#e74c3c"), 10))
  syn_chart(df, paste0("RSI ", ifelse(bullish, "Bullish", "Bearish"), " Divergence"), list(), ann, indicator = ind)
}

w3_rsi_range_signal <- function(sell, seed) {
  set.seed(seed)
  n <- 46
  df <- syn_path(n, start = 115, drift = 0.02, vol = 1.3, seed = seed)
  rng_top <- max(df$High) - 0.3; rng_bot <- min(df$Low) + 0.3
  target <- if (sell) rng_top else rng_bot
  tail_drift <- if (sell) -1.0 else 1.0
  tail_df <- syn_path(12, start = target, drift = tail_drift, vol = 0.9, seed = seed + 60)
  df <- syn_concat(df, tail_df)
  tail_dates <- syn_seg(df, 2)
  shapes <- list(syn_hline(df$Date[1], tail(df$Date,1), rng_top, "#e74c3c", "dot", 1),
                 syn_hline(df$Date[1], tail(df$Date,1), rng_bot, "#27ae60", "dot", 1))
  ind <- w3_rsi_ind(df$Close, df$Date)
  ann <- list(syn_tag(tail_dates[1], target, ifelse(sell, "Sell Signal", "Buy Signal"), ifelse(sell,"#e74c3c","#27ae60"), 10))
  syn_chart(df, paste0("RSI ", ifelse(sell, "Sell Signal Near Top of Range", "Buy Signal Near Bottom of Range")), shapes, ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# STOCHASTICS
# ══════════════════════════════════════════════════════════════════════════

w3_stoch_divergence <- function(bullish, context, seed) {
  set.seed(seed)
  sgn <- if (bullish) -1 else 1
  lead <- syn_path(8, start = 118, drift = sgn * 0.9, vol = 0.8, seed = seed)
  leg1 <- syn_path(10, start = tail(lead$Close,1), drift = sgn * 1.2, vol = 0.9, seed = seed + 5)
  p1 <- tail(leg1$Close, 1)
  mid <- syn_path(8, start = p1, drift = -sgn * 0.8, vol = 0.7, seed = seed + 15)
  leg2 <- syn_path(10, start = tail(mid$Close,1), drift = sgn * 1.4, vol = 0.9, seed = seed + 25)
  p2 <- tail(leg2$Close, 1)
  tail_df <- syn_path(14, start = p2, drift = -sgn * 1.2, vol = 1, seed = seed + 60)
  
  df <- syn_concat(lead, leg1, mid, leg2, tail_df)
  leg1_dates <- syn_seg(df, 2); leg2_dates <- syn_seg(df, 4)
  hlc <- df[, c("High","Low","Close")]
  ind <- w3_stoch_ind(hlc, df$Date)
  idx1 <- match(leg1_dates[length(leg1_dates)], ind$dates); idx2 <- match(leg2_dates[length(leg2_dates)], ind$dates)
  if (!is.na(idx1) && !is.na(idx2)) {
    if (bullish) { ind$values[idx2] <- ind$values[idx1] + 12; ind$values2[idx2] <- ind$values2[idx1] + 10 }
    else { ind$values[idx2] <- ind$values[idx1] - 12; ind$values2[idx2] <- ind$values2[idx1] - 10 }
  }
  ann <- list(syn_tag(leg2_dates[length(leg2_dates)], p2, paste0(ifelse(bullish,"Bullish","Bearish")," Divergence"),
                       ifelse(bullish, "#27ae60", "#e74c3c"), 10))
  title <- paste0("Stochastic ", ifelse(bullish, "Bullish Divergence in a Downtrend", "Bearish Divergence in an Uptrend"))
  syn_chart(df, title, list(), ann, indicator = ind)
}

w3_stoch_range_signal <- function(sell, seed) {
  set.seed(seed)
  n <- 44
  df <- syn_path(n, start = 115, drift = 0.02, vol = 1.3, seed = seed)
  rng_top <- max(df$High) - 0.3; rng_bot <- min(df$Low) + 0.3
  target <- if (sell) rng_top else rng_bot
  tail_drift <- if (sell) -1.0 else 1.0
  tail_df <- syn_path(12, start = target, drift = tail_drift, vol = 0.9, seed = seed + 60)
  df <- syn_concat(df, tail_df)
  tail_dates <- syn_seg(df, 2)
  shapes <- list(syn_hline(df$Date[1], tail(df$Date,1), rng_top, "#e74c3c", "dot", 1),
                 syn_hline(df$Date[1], tail(df$Date,1), rng_bot, "#27ae60", "dot", 1))
  hlc <- df[, c("High","Low","Close")]
  ind <- w3_stoch_ind(hlc, df$Date)
  ann <- list(syn_tag(tail_dates[1], target, ifelse(sell, "Sell Signal (Overbought)", "Buy Signal (Oversold)"), ifelse(sell,"#e74c3c","#27ae60"), 10))
  syn_chart(df, paste0("Stochastic ", ifelse(sell, "Sell Signal — Overbought Zone", "Buy Signal — Oversold Zone")), shapes, ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# MOVING AVERAGES (overlay only — no subplot needed)
# ══════════════════════════════════════════════════════════════════════════

w3_single_ma_signal <- function(buy, seed) {
  set.seed(seed)
  lead <- if (buy) syn_path(24, start = 130, drift = -0.7, vol = 1, seed = seed)
          else syn_path(24, start = 100, drift = 0.7, vol = 1, seed = seed)
  tail_drift <- if (buy) 1.1 else -1.1
  tail_df <- syn_path(20, start = tail(lead$Close,1), drift = tail_drift, vol = 1, seed = seed + 60)
  df <- syn_concat(lead, tail_df)
  sma <- as.numeric(TTR::SMA(df$Close, n = 15))
  ok <- !is.na(sma)
  idxs <- which(ok)
  shapes <- list()
  for (i in seq_len(length(idxs) - 1)) {
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], sma[idxs[i]], sma[idxs[i+1]], "#9b59b6", "solid", 2)
  }
  ann <- list(syn_tag(tail(lead$Date,1), tail(lead$Close,1), ifelse(buy, "Price Crosses Above SMA — Buy", "Price Crosses Below SMA — Sell"),
                       ifelse(buy, "#27ae60", "#e74c3c"), 10))
  syn_chart(df, paste0("Single SMA ", ifelse(buy, "Buy", "Sell"), " Signal"), shapes, ann)
}

w3_dual_ma_signal <- function(buy, seed) {
  set.seed(seed)
  lead <- if (buy) syn_path(20, start = 125, drift = -0.5, vol = 1, seed = seed)
          else syn_path(20, start = 100, drift = 0.5, vol = 1, seed = seed)
  tail_drift <- if (buy) 1.0 else -1.0
  tail_df <- syn_path(26, start = tail(lead$Close,1), drift = tail_drift, vol = 1, seed = seed + 60)
  df <- syn_concat(lead, tail_df)
  fast <- as.numeric(TTR::SMA(df$Close, n = 8))
  slow <- as.numeric(TTR::SMA(df$Close, n = 20))
  ok <- !is.na(fast) & !is.na(slow)
  idxs <- which(ok)
  shapes <- list()
  for (i in seq_len(length(idxs) - 1)) {
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], fast[idxs[i]], fast[idxs[i+1]], "#3498db", "solid", 2)
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], slow[idxs[i]], slow[idxs[i+1]], "#e67e22", "solid", 2)
  }
  ann <- list(syn_tag(tail(lead$Date,1), tail(lead$Close,1), ifelse(buy, "Fast MA Crosses Above Slow MA — Buy", "Fast MA Crosses Below Slow MA — Sell"),
                       ifelse(buy, "#27ae60", "#e74c3c"), 9))
  syn_chart(df, paste0("Two Moving Average System — ", ifelse(buy, "Buy", "Sell"), " Signal"), shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# MACD
# ══════════════════════════════════════════════════════════════════════════

w3_macd_reversal <- function(sell, seed) {
  set.seed(seed)
  lead <- if (sell) syn_path(30, start = 100, drift = 0.9, vol = 1, seed = seed)
          else syn_path(30, start = 140, drift = -0.9, vol = 1, seed = seed)
  tail_drift <- if (sell) -1.1 else 1.1
  tail_df <- syn_path(20, start = tail(lead$Close,1), drift = tail_drift, vol = 1, seed = seed + 60)
  df <- syn_concat(lead, tail_df)
  tail_dates <- syn_seg(df, 2)
  ind <- w3_macd_ind(df$Close, df$Date)
  ann <- list(syn_tag(tail_dates[1], tail(lead$Close,1),
                       ifelse(sell, "MACD Bearish Crossover — Sell, Trend Reverses", "MACD Bullish Crossover — Buy, Trend Reverses"),
                       ifelse(sell, "#e74c3c", "#27ae60"), 9))
  title <- if (sell) "MACD Sell Signal in an Uptrend — Trend Reversal" else "MACD Buy Signal in a Downtrend — Trend Reversal"
  syn_chart(df, title, list(), ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# ON-BALANCE VOLUME
# ══════════════════════════════════════════════════════════════════════════

w3_obv_consolidation_breakout <- function(seed) {
  set.seed(seed)
  lead <- syn_path(16, start = 100, drift = 0.5, vol = 1, seed = seed)
  n_cons <- 20
  cons <- syn_path(n_cons, start = tail(lead$Close,1), drift = 0.02, vol = 0.5, seed = seed + 10)
  # OBV keeps rising during consolidation even though price is flat — bullish accumulation
  vol_bias <- seq(1, 2.2, length.out = n_cons)
  cons$Volume <- round(1000 * vol_bias * ifelse(cons$Close >= cons$Open, 1.6, 0.6))
  breakout <- syn_path(16, start = tail(cons$Close,1), drift = 1.3, vol = 1, seed = seed + 40)
  breakout$Volume <- round(1500 + 400 * seq_len(16))
  lead$Volume <- round(runif(nrow(lead), 800, 1200))
  df <- syn_concat(lead, cons, breakout)
  breakout_dates <- syn_seg(df, 3)
  ind <- w3_obv_ind(df$Close, df$Volume, df$Date)
  ann <- list(syn_tag(breakout_dates[1], tail(cons$Close,1), "OBV Rising Through Consolidation \u2192 Breakout Up", "#27ae60", 9))
  syn_chart(df, "OBV Rising During Consolidation, Then Price Breaks Out", list(), ann, indicator = ind)
}

w3_obv_triangle_lead <- function(seed) {
  set.seed(seed)
  lead <- syn_path(14, start = 100, drift = 0.4, vol = 1, seed = seed)
  n_pat <- 22
  mid <- tail(lead$Close, 1)
  hi_fn <- function(i) mid + 6 * (1 - 0.85 * (i / n_pat))
  lo_fn <- function(i) mid - 6 * (1 - 0.85 * (i / n_pat))
  # Continuous confined random walk instead of independent per-bar draws (which produced
  # disconnected, jumpy candles not tracking the converging triangle envelope).
  pat <- syn_confined_path(n_pat, start = mid, lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.9, seed = seed + 10)
  pat$Date <- seq(tail(lead$Date, 1) + 1, by = "day", length.out = n_pat)
  vols <- 900 + 30 * seq_len(n_pat)  # OBV drifts up steadily through the triangle
  pat$Volume <- ifelse(pat$Close >= pat$Open, vols * 1.5, vols * 0.6)
  breakout <- syn_path(14, start = tail(pat$Close,1), drift = 1.2, vol = 1, seed = seed + 60)
  breakout$Volume <- round(1600 + 300 * seq_len(14))
  lead$Volume <- round(runif(nrow(lead), 800, 1000))
  df <- syn_concat(lead, pat, breakout)
  pat_dates <- syn_seg(df, 2); breakout_dates <- syn_seg(df, 3)
  ind <- w3_obv_ind(df$Close, df$Volume, df$Date)
  x0 <- pat_dates[1]; x1 <- pat_dates[n_pat]
  shapes <- list(syn_line(x0, x1, mid+6, mid+1, "#e67e22","solid",2), syn_line(x0, x1, mid-6, mid-1, "#e67e22","solid",2))
  ann <- list(syn_tag(breakout_dates[1], tail(pat$Close,1), "OBV Breaks Its Own Triangle Ahead of Price", "#27ae60", 9))
  syn_chart(df, "OBV Breaks a Triangle Pattern Ahead of Price", shapes, ann, indicator = ind)
}

w3_obv_divergence <- function(bullish, seed) {
  set.seed(seed)
  sgn <- if (bullish) -1 else 1
  lead <- syn_path(8, start = 118, drift = sgn * 0.7, vol = 0.8, seed = seed)
  leg1 <- syn_path(10, start = tail(lead$Close,1), drift = sgn * 1.1, vol = 0.9, seed = seed+5)
  p1 <- tail(leg1$Close,1)
  mid <- syn_path(8, start = p1, drift = -sgn*0.7, vol=0.7, seed=seed+15)
  leg2 <- syn_path(10, start = tail(mid$Close,1), drift = sgn*1.3, vol=0.9, seed=seed+25)
  p2 <- tail(leg2$Close,1)
  tail_df <- syn_path(14, start = p2, drift = -sgn*1.1, vol=1, seed=seed+60)
  df <- syn_concat(lead, leg1, mid, leg2, tail_df)
  leg1_dates <- syn_seg(df, 2); leg2_dates <- syn_seg(df, 4)
  df$Volume <- round(runif(nrow(df), 800, 1300))
  ind <- w3_obv_ind(df$Close, df$Volume, df$Date)
  idx1 <- match(leg1_dates[length(leg1_dates)], df$Date); idx2 <- match(leg2_dates[length(leg2_dates)], df$Date)
  if (!is.na(idx1) && !is.na(idx2)) {
    if (bullish) ind$values[idx2:length(ind$values)] <- ind$values[idx2:length(ind$values)] - (ind$values[idx2]-ind$values[idx1]) + 400
    else ind$values[idx2:length(ind$values)] <- ind$values[idx2:length(ind$values)] - (ind$values[idx2]-ind$values[idx1]) - 400
  }
  ann <- list(syn_tag(leg2_dates[length(leg2_dates)], p2, paste0("OBV ", ifelse(bullish,"Bullish","Bearish")," Divergence"),
                       ifelse(bullish,"#27ae60","#e74c3c"), 9))
  syn_chart(df, paste0("OBV ", ifelse(bullish, "Bullish", "Bearish"), " Divergence"), list(), ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# BOLLINGER BANDS (overlay only)
# ══════════════════════════════════════════════════════════════════════════

w3_bb_range_signal <- function(buy, seed) {
  set.seed(seed)
  n <- 50
  df <- syn_path(n, start = 115, drift = 0.02, vol = 1.4, seed = seed)
  bb <- TTR::BBands(df$Close, n = 20, sd = 2)
  ok <- !is.na(bb[,"up"])
  idxs <- which(ok)
  shapes <- list()
  for (i in seq_len(length(idxs)-1)) {
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], bb[idxs[i],"up"], bb[idxs[i+1],"up"], "#95a5a6", "dash", 1.5)
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], bb[idxs[i],"dn"], bb[idxs[i+1],"dn"], "#95a5a6", "dash", 1.5)
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], bb[idxs[i],"mavg"], bb[idxs[i+1],"mavg"], "#3498db", "dot", 1)
  }
  touch_idx <- idxs[length(idxs)]
  touch_price <- if (buy) bb[touch_idx,"dn"] else bb[touch_idx,"up"]
  tail_drift <- if (buy) 1.0 else -1.0
  tail_df <- syn_path(12, start = touch_price, drift = tail_drift, vol = 0.8, seed = seed + 60)
  df2 <- syn_concat(df, tail_df)
  ann <- list(syn_tag(df$Date[touch_idx], touch_price, ifelse(buy, "Touches Lower Band \u2192 Buy", "Touches Upper Band \u2192 Sell"),
                       ifelse(buy,"#27ae60","#e74c3c"), 10))
  syn_chart(df2, paste0("Bollinger Range Trading — ", ifelse(buy, "Buy", "Sell"), " Signal"), shapes, ann)
}

w3_bb_inside_outside <- function(buy, seed) {
  set.seed(seed)
  lead <- if (buy) syn_path(30, start = 130, drift = -0.5, vol = 1.3, seed = seed)
          else syn_path(30, start = 100, drift = 0.5, vol = 1.3, seed = seed)
  bb <- TTR::BBands(lead$Close, n = 20, sd = 2)
  last_idx <- nrow(lead)
  band_val <- if (buy) bb[last_idx, "dn"] else bb[last_idx, "up"]
  # "Outside" bar: closes beyond the band
  outside_price <- if (buy) band_val - 1.5 else band_val + 1.5
  outside <- data.frame(Date = tail(lead$Date,1)+1, Open = lead$Close[last_idx], High = max(outside_price, lead$Close[last_idx]) + 0.4,
                         Low = min(outside_price, lead$Close[last_idx]) - 0.4, Close = outside_price)
  # "Inside" bar: closes back within the band
  inside_price <- band_val + (if (buy) 0.8 else -0.8)
  inside <- data.frame(Date = outside$Date+1, Open = outside_price, High = max(inside_price, outside_price)+0.3,
                        Low = min(inside_price, outside_price)-0.3, Close = inside_price)
  target_dist <- abs(band_val - outside_price) * 2.2
  outc <- syn_outcome_tail(inside_price, if (buy) 1 else -1, target_dist, TRUE, seed + 200)
  df <- syn_concat(lead, outside, inside, outc$df)
  outside_dates <- syn_seg(df, 2); inside_dates <- syn_seg(df, 3); outc_dates <- syn_seg(df, 4)
  idxs_ok <- which(!is.na(bb[,"up"]))
  shapes <- list()
  for (i in seq_len(length(idxs_ok)-1)) {
    shapes[[length(shapes)+1]] <- syn_line(lead$Date[idxs_ok[i]], lead$Date[idxs_ok[i+1]], bb[idxs_ok[i],"up"], bb[idxs_ok[i+1],"up"], "#95a5a6", "dash", 1.5)
    shapes[[length(shapes)+1]] <- syn_line(lead$Date[idxs_ok[i]], lead$Date[idxs_ok[i+1]], bb[idxs_ok[i],"dn"], bb[idxs_ok[i+1],"dn"], "#95a5a6", "dash", 1.5)
  }
  shapes[[length(shapes)+1]] <- syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5)
  ann <- list(
    syn_tag(outside_dates[1], outside_price, "Outside Bar", "#e67e22", 8),
    syn_tag(inside_dates[1], inside_price, paste0("Inside Bar \u2192 ", ifelse(buy,"Buy","Sell"), " \u2192 Target Hit"),
            ifelse(buy,"#27ae60","#e74c3c"), 9)
  )
  syn_chart(df, paste0("Bollinger Inside/Outside ", ifelse(buy, "Buy", "Sell"), " Signal — Target Hit"), shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# CANONICAL SECTIONS
# ══════════════════════════════════════════════════════════════════════════

w3_sections <- function() {
  rsi_specs <- list(
    list(id = "rsi1", title = "RSI Overbought — Rejection at Resistance", desc = "Overbought RSI (>70) with price rejected at a resistance level.",
         gen = function() w3_rsi_reject(TRUE, 601)),
    list(id = "rsi2", title = "RSI Oversold — Bounce off Support", desc = "Oversold RSI (<30) with price bouncing off a support level.",
         gen = function() w3_rsi_reject(FALSE, 602)),
    list(id = "rsi3", title = "RSI Bullish Divergence", desc = "Price makes a lower low while RSI makes a higher low.",
         gen = function() w3_rsi_divergence(TRUE, 603)),
    list(id = "rsi4", title = "RSI Bearish Divergence", desc = "Price makes a higher high while RSI makes a lower high.",
         gen = function() w3_rsi_divergence(FALSE, 604)),
    list(id = "rsi5", title = "RSI Sell Signal Near Top of Range", desc = "RSI overbought as price nears the top of a trading range.",
         gen = function() w3_rsi_range_signal(TRUE, 605)),
    list(id = "rsi6", title = "RSI Buy Signal Near Bottom of Range", desc = "RSI oversold as price nears the bottom of a trading range.",
         gen = function() w3_rsi_range_signal(FALSE, 606))
  )
  
  stoch_specs <- list(
    list(id = "st1", title = "Stochastic Bullish Divergence (Downtrend)", desc = "Price lower low, %K/%D higher low, within a downtrend.",
         gen = function() w3_stoch_divergence(TRUE, "down", 611)),
    list(id = "st2", title = "Stochastic Bearish Divergence (Uptrend)", desc = "Price higher high, %K/%D lower high, within an uptrend.",
         gen = function() w3_stoch_divergence(FALSE, "up", 612)),
    list(id = "st3", title = "Stochastic Sell Signal — Overbought", desc = "Sell signal in the overbought zone near the top of a trading range.",
         gen = function() w3_stoch_range_signal(TRUE, 613)),
    list(id = "st4", title = "Stochastic Buy Signal — Oversold", desc = "Buy signal in the oversold zone near the bottom of a trading range.",
         gen = function() w3_stoch_range_signal(FALSE, 614))
  )
  
  ma_specs <- list(
    list(id = "ma1", title = "Single SMA Sell Signal", desc = "Price crosses below the SMA.",
         gen = function() w3_single_ma_signal(FALSE, 621)),
    list(id = "ma2", title = "Single SMA Buy Signal", desc = "Price crosses above the SMA.",
         gen = function() w3_single_ma_signal(TRUE, 622)),
    list(id = "ma3", title = "Two Moving Average System — Buy Signal", desc = "Fast MA crosses above the slow MA.",
         gen = function() w3_dual_ma_signal(TRUE, 623)),
    list(id = "ma4", title = "Two Moving Average System — Sell Signal", desc = "Fast MA crosses below the slow MA.",
         gen = function() w3_dual_ma_signal(FALSE, 624))
  )
  
  macd_specs <- list(
    list(id = "macd1", title = "MACD Sell Signal in an Uptrend", desc = "Sell signal at a primary level, with trend reversal.",
         gen = function() w3_macd_reversal(TRUE, 631)),
    list(id = "macd2", title = "MACD Buy Signal in a Downtrend", desc = "Buy signal at a primary level, with trend reversal.",
         gen = function() w3_macd_reversal(FALSE, 632))
  )
  
  obv_specs <- list(
    list(id = "obv1", title = "OBV Rising Through Consolidation \u2192 Breakout", desc = "OBV rises as price consolidates, followed by a price breakout to the upside.",
         gen = function() w3_obv_consolidation_breakout(641)),
    list(id = "obv2", title = "OBV Breaks Triangle Ahead of Price", desc = "OBV breaks through a triangle pattern ahead of price breaking a similar pattern.",
         gen = function() w3_obv_triangle_lead(642)),
    list(id = "obv3", title = "OBV Bullish Divergence", desc = "OBV bullish divergence against price.",
         gen = function() w3_obv_divergence(TRUE, 643)),
    list(id = "obv4", title = "OBV Bearish Divergence", desc = "OBV bearish divergence against price.",
         gen = function() w3_obv_divergence(FALSE, 644))
  )
  
  bb_specs <- list(
    list(id = "bb1", title = "Bollinger Range Trading — Buy Signal", desc = "Price touches the lower band within a range \u2014 buy signal.",
         gen = function() w3_bb_range_signal(TRUE, 651)),
    list(id = "bb2", title = "Bollinger Range Trading — Sell Signal", desc = "Price touches the upper band within a range \u2014 sell signal.",
         gen = function() w3_bb_range_signal(FALSE, 652)),
    list(id = "bb3", title = "Bollinger Inside/Outside Buy — Target Hit", desc = "An Outside bar beyond the band followed by an Inside bar back within it \u2014 buy signal that hit its target.",
         gen = function() w3_bb_inside_outside(TRUE, 653)),
    list(id = "bb4", title = "Bollinger Inside/Outside Sell — Target Hit", desc = "An Outside bar beyond the band followed by an Inside bar back within it \u2014 sell signal that hit its target.",
         gen = function() w3_bb_inside_outside(FALSE, 654))
  )
  
  list(
    list(title = "Relative Strength Index (RSI)", specs = rsi_specs),
    list(title = "Stochastics", specs = stoch_specs),
    list(title = "Moving Averages", specs = ma_specs),
    list(title = "MACD", specs = macd_specs),
    list(title = "On-Balance Volume (OBV)", specs = obv_specs),
    list(title = "Bollinger Bands", specs = bb_specs)
  )
}

# ══════════════════════════════════════════════════════════════════════════
# UI / SERVER
# ══════════════════════════════════════════════════════════════════════════

weekly_activity_week3_ui <- function(id) {
  ns <- NS(id)
  sections <- w3_sections()
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(paste0(
              "Every chart below uses simulated OHLC data with indicators computed via the TTR package — RSI, ",
              "Stochastics, Moving Averages, MACD, On-Balance Volume, and Bollinger Bands (24 examples in total, ",
              "covering every point in Step 3). This is for practising signal recognition, ",
              "not a claim about real market history."
            ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    weekly_download_ui(ns),
    lapply(sections, function(sec) weekly_grid_ui(ns, sec$specs, sec$title))
  )
}

weekly_activity_week3_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    sections <- w3_sections()
    for (sec in sections) weekly_grid_server(output, sec$specs)
    weekly_download_server(output, "Step 3", sections, "step3_activity")
    session$onSessionEnded(function() {})
  })
}

# ====================================================================================================
# (was modules/weekly_activity_week4.R)
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

    tags$h4("Options Trading — Chain Highlighting & Breakeven", style = "color:#111827; font-weight:800; margin:18px 0 10px 0;"),
    fluidRow(
      column(6,
        box(title = "Options Chain — Premiums, Strikes, Long Call @ 12590", status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(plotlyOutput(ns("optionsChain"), height = "360px")),
            tags$p("Orange line marks the strike nearest 12590 for the Long Call. Left-edge annotation marks buying a Put; right-edge marks selling a Call.",
                   style = "font-size:11.5px; color:#666; margin-top:8px; line-height:1.5;"), uiOutput(ns("optionsChain_desc"))
        )
      ),
      column(6,
        box(title = "Long Call @ 12590 — Breakeven", status = "primary", solidHeader = TRUE, width = 12,
            uiOutput(ns("breakevenAnswer")),
            withSpinner(plotlyOutput(ns("chainBreakeven"), height = "300px")),
            tags$p("Breakeven = Strike + Premium Paid. Below this price at expiry the position is a net loss (capped at the premium); above it, profit is unlimited.",
                   style = "font-size:11.5px; color:#666; margin-top:8px; line-height:1.5;"), uiOutput(ns("chainBreakeven_desc"))
        )
      )
    ),
    fluidRow(
      box(title = "Options Chain — Strike Ladder", status = "info", solidHeader = TRUE, width = 12,
          withSpinner(DT::dataTableOutput(ns("chainTable"))))
    ),

    weekly_grid_ui(ns, sections[[2]]$specs, sections[[2]]$title),

    tags$h4("Options Payout Diagrams", style = "color:#111827; font-weight:800; margin:18px 0 10px 0;"),
    fluidRow(lapply(sections[[3]]$specs, function(s) {
      column(6,
        box(title = s$title, status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(plotlyOutput(ns(s$id), height = "320px")),
            tags$p(s$desc, style = "font-size:11.5px; color:#666; margin-top:8px; line-height:1.5;"), uiOutput(ns(paste0(s$id, "_desc")))
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

    # Shared breakeven calculation — used by both the prominent answer box below and
    # the chart, so the two can never disagree with each other.
    breakeven_data <- reactive({
      w4_payoff_chart_data("long_call", K = chain$nearest, premium = chain$nearest_premium)
    })

    # A directly-answered, prominent display for "What would be the breakeven price
    # for the trade above?" — not left only inside a small chart title.
    output$breakevenAnswer <- renderUI({
      pd <- breakeven_data()
      tags$div(
        style = paste0(
          "background:linear-gradient(135deg,#f39c12,#e67e22); border-radius:10px; ",
          "padding:14px 18px; margin-bottom:12px; text-align:center;"
        ),
        tags$div("Breakeven Price", style = "color:#fff8ec; font-size:12px; font-weight:600; letter-spacing:0.5px; text-transform:uppercase;"),
        tags$div(paste0(round(pd$breakeven, 1)), style = "color:#ffffff; font-size:32px; font-weight:800; line-height:1.2;"),
        tags$div(paste0("Strike ", chain$nearest, " + Premium ", chain$nearest_premium, " = ", round(pd$breakeven, 1)),
                 style = "color:#fff3dc; font-size:11.5px; margin-top:2px;")
      )
    })
    output$chainBreakeven <- renderPlotly({
      pd <- breakeven_data()
      w4_payoff_plotly(pd, paste0("Long Call @ ", chain$nearest, " — Breakeven ", round(pd$breakeven, 1)))
    })

    for (s in sections[[3]]$specs) {
      local({
        spec <- s
        output[[spec$id]] <- renderPlotly({ w4_payoff_plotly(spec$gen(), spec$payoff_title) })
      })
    }
    # these options charts are outside the course grid: give them their own description boxes too
    weekly_desc_server(output, c(list(list(id = "optionsChain", title = "Options Chain - Premiums, Strikes, Long Call @ 12590",
                                           desc = "Call and put premiums against strike prices; the strike nearest 12590 marked for a long call; buying a put at a low strike and selling a call at a high strike annotated."),
                                      list(id = "chainBreakeven", title = "Long Call @ 12590 - Breakeven",
                                           desc = "Breakeven of a long call = strike + premium paid; loss capped at the premium below it, unlimited profit above it.")),
                                 sections[[3]]$specs), 4)

    weekly_download_server(output, "Step 4", sections, "step4_activity")
    session$onSessionEnded(function() {})
  })
}

# ====================================================================================================
# (was modules/weekly_activity_week5.R)
# modules/weekly_activity_week5.R
# Covers every point in Step 5 — Volume Profile (7 features x 2
# examples each = 14), Market Profile (5 features x 2 = 10), Initial Balance
# (4 features x 2 = 8), plus 1 multi-level confluence bounce = 33 examples total.
# All charts use synthetic OHLCV data. Volume-at-price profiles are built with
# syn_volume_profile()/syn_vp_shapes() from R/utils_synthetic.R, which render the
# profile as a ladder of horizontal bars docked to the right edge of the chart —
# no new charting infrastructure needed beyond the existing shapes/annotations.

# ══════════════════════════════════════════════════════════════════════════
# VOLUME PROFILE — session/day shapes
# ══════════════════════════════════════════════════════════════════════════

w5_session_shape <- function(kind, seed) {
  set.seed(seed)
  lead <- syn_path(10, start = 100, drift = 0, vol = 0.6, seed = seed)
  base <- tail(lead$Close, 1)

  if (kind == "p_shape") {
    sess <- syn_path(16, start = base, drift = 0.5, vol = 0.7, seed = seed + 10)
    sess$Volume <- round(700 + 900 * (seq_len(16) / 16)^2)  # heavier near the close (near highs)
    cont <- syn_path(14, start = tail(sess$Close,1), drift = 1.0, vol = 1, seed = seed + 40)
    label <- "P-Shaped Day \u2192 Continuation Up"
  } else if (kind == "b_shape") {
    sess <- syn_path(16, start = base, drift = -0.5, vol = 0.7, seed = seed + 10)
    sess$Volume <- round(700 + 900 * (seq_len(16) / 16)^2)  # heavier near the close (near lows)
    cont <- syn_path(14, start = tail(sess$Close,1), drift = -1.0, vol = 1, seed = seed + 40)
    label <- "b-Shaped Day \u2192 Continuation Down"
  } else if (kind == "inside_breakout") {
    prior <- syn_path(10, start = base, drift = 0.6, vol = 1, seed = seed + 5)
    hi <- max(prior$High); lo <- min(prior$Low)
    hi_fn <- function(i) hi - 0.3; lo_fn <- function(i) lo + 0.3
    sess <- syn_confined_path(8, start = tail(prior$Close,1), lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.4, seed = seed + 10)
    sess$Volume <- round(runif(8, 400, 600))
    cont <- syn_path(16, start = tail(sess$Close,1), drift = 1.3, vol = 1.1, seed = seed + 40)
    lead <- bind_rows(lead, prior)
    label <- "Inside Day \u2192 Aggressive Breakout, Trend Continues"
  } else if (kind == "thin_retrace") {
    sess <- syn_path(16, start = base, drift = 0.15, vol = 1.3, seed = seed + 10)
    q <- quantile(sess$Close, c(0.35, 0.65))
    sess$Volume <- round(ifelse(sess$Close > q[1] & sess$Close < q[2], 150, 900))
    cont <- syn_path(14, start = tail(sess$Close,1), drift = -0.7, vol = 1, seed = seed + 40)
    label <- "Thin Volume Day \u2192 Next Day Retraces Back Through"
  } else { # double_distribution
    sess1 <- syn_path(8, start = base, drift = 0.15, vol = 0.5, seed = seed + 10)
    gap <- syn_path(4, start = tail(sess1$Close,1), drift = 1.2, vol = 0.4, seed = seed + 15)
    sess2 <- syn_path(8, start = tail(gap$Close,1), drift = 0.15, vol = 0.5, seed = seed + 20)
    sess1$Volume <- round(runif(8, 700, 900)); sess2$Volume <- round(runif(8, 700, 900))
    gap$Volume <- round(runif(4, 100, 200))
    sess <- bind_rows(sess1, gap, sess2)
    cont <- syn_path(14, start = tail(sess2$Close,1), drift = -0.9, vol = 1, seed = seed + 40)
    label <- "Double Distribution \u2192 Price Later Fills the Low-Volume Gap"
  }

  if (is.null(sess$Volume)) sess$Volume <- round(runif(nrow(sess), 500, 900))
  lead$Volume <- round(runif(nrow(lead), 400, 600))
  cont$Volume <- round(runif(nrow(cont), 500, 900))

  df <- syn_concat(lead, sess, cont)
  sess_dates <- syn_seg(df, 2); cont_dates <- syn_seg(df, 3)
  sess_fixed <- sess; sess_fixed$Date <- sess_dates
  vp <- syn_volume_profile(sess_fixed, n_bins = 14)
  vp_shapes <- syn_vp_shapes(df, vp)

  shapes <- c(vp_shapes, list(syn_hline(sess_dates[1], tail(df$Date,1), vp$poc, "#f39c12", "solid", 1.5)))
  ann <- list(
    syn_tag(sess_dates[round(length(sess_dates)/2)], max(sess$High) * 1.02, label, "#002C3C", 8),
    syn_tag(cont_dates[1], tail(sess$Close,1), "Continuation \u2192", "#27ae60", 9)
  )
  syn_chart(df, label, shapes, ann)
}

# -- Bounce off a High/Low Volume Node --
w5_node_bounce <- function(kind, seed) {
  set.seed(seed)
  lead <- syn_path(10, start = 100, drift = 0.1, vol = 1, seed = seed)
  sess <- syn_path(20, start = tail(lead$Close,1), drift = 0.05, vol = 1.2, seed = seed + 10)
  rng <- range(sess$Close); mid <- mean(rng); spread <- diff(rng)
  # bimodal volume (two clusters) guarantees both an HVN and an LVN exist in the profile
  sess$Volume <- round(300 +
    700 * exp(-((sess$Close - (mid - spread*0.22))^2) / (2*(spread*0.08)^2)) +
    700 * exp(-((sess$Close - (mid + spread*0.22))^2) / (2*(spread*0.08)^2)))

  df0 <- syn_concat(lead, sess)
  sess_dates <- syn_seg(df0, 2)
  sess_fixed <- sess; sess_fixed$Date <- sess_dates
  vp <- syn_volume_profile(sess_fixed, n_bins = 16)

  target_level <- if (kind == "hvn") vp$hvn[which.min(abs(vp$hvn - mid))] else {
    cand <- vp$lvn[vp$lvn > min(rng) + spread*0.05 & vp$lvn < max(rng) - spread*0.05]
    if (length(cand) == 0) cand <- vp$mids[which.min(vp$vols)]
    cand[which.min(abs(cand - mid))]
  }
  approach_dir <- if (target_level < tail(sess$Close,1)) -1 else 1
  start_px <- tail(sess$Close, 1)
  # Multi-touch test phase: price is confined to repeatedly test target_level from the
  # correct side (several genuine touches, matching Step 1's S/R rigor) before the
  # final reaction leg, instead of a single approach-and-touch.
  if (approach_dir < 0) {
    lo_fn <- function(i) target_level; hi_fn <- function(i) start_px + spread * 0.12
  } else {
    hi_fn <- function(i) target_level; lo_fn <- function(i) start_px - spread * 0.12
  }
  approach <- syn_confined_path(10, start = start_px, lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.6, seed = seed + 40)
  bounce_dir <- -approach_dir
  outc <- syn_outcome_tail(target_level, bounce_dir, spread * 0.6, TRUE, seed + 200, n = 14)

  df <- syn_concat(lead, sess, approach, outc$df)
  outc_dates <- syn_seg(df, 4)
  vp_shapes <- syn_vp_shapes(df, vp)
  node_color <- if (kind == "hvn") "#3498db" else "#95a5a6"
  shapes <- c(vp_shapes, list(syn_hline(df$Date[1], tail(df$Date,1), target_level, node_color, "dash", 1.5)))
  label <- paste0("Bounce off ", ifelse(kind == "hvn", "High", "Low"), " Volume Node")
  ann <- list(syn_tag(outc_dates[1], target_level, label, "#27ae60", 9))
  syn_chart(df, label, shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# MARKET PROFILE — POC / VAL / VAH / Single Print / Ledge respected as S/R
# ══════════════════════════════════════════════════════════════════════════

w5_mp_respect <- function(kind, seed) {
  set.seed(seed)
  lead <- syn_path(10, start = 100, drift = 0.05, vol = 1, seed = seed)
  sess <- syn_path(22, start = tail(lead$Close,1), drift = 0.05, vol = 1.2, seed = seed + 10)
  sess$Volume <- round(runif(22, 500, 900))

  if (kind == "single_print") {
    ext_i <- which.max(sess$High)
    sess$Volume[ext_i] <- 80
  } else if (kind == "ledge") {
    mid_idx <- round(length(sess$Close)*0.4):round(length(sess$Close)*0.6)
    sess$Volume[mid_idx] <- 850
  }

  df0 <- syn_concat(lead, sess)
  sess_dates <- syn_seg(df0, 2)
  sess_fixed <- sess; sess_fixed$Date <- sess_dates
  vp <- syn_volume_profile(sess_fixed, n_bins = 16)

  level <- switch(kind,
    poc = vp$poc, val = vp$val, vah = vp$vah,
    single_print = max(sess$High) - 0.2,
    ledge = vp$mids[round(length(vp$mids)*0.5)]
  )
  approach_dir <- if (level < tail(sess$Close,1)) -1 else 1
  start_px <- tail(sess$Close, 1)
  spread <- diff(range(sess$Close))
  # Multi-touch test phase: price repeatedly tests `level` from the correct side
  # (several genuine touches, matching Step 1's S/R rigor) before the final reaction,
  # instead of a single approach-and-touch.
  if (approach_dir < 0) {
    lo_fn <- function(i) level; hi_fn <- function(i) start_px + spread * 0.12
  } else {
    hi_fn <- function(i) level; lo_fn <- function(i) start_px - spread * 0.12
  }
  approach <- syn_confined_path(10, start = start_px, lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.6, seed = seed + 40)
  react_dir <- -approach_dir
  outc <- syn_outcome_tail(level, react_dir, spread * 0.6, TRUE, seed + 200, n = 14)

  df <- syn_concat(lead, sess, approach, outc$df)
  outc_dates <- syn_seg(df, 4)
  vp_shapes <- syn_vp_shapes(df, vp)
  label_map <- c(poc = "Point of Control (POC)", val = "Value Area Low (VAL)", vah = "Value Area High (VAH)",
                 single_print = "Single Print", ledge = "Ledge")
  label <- label_map[[kind]]
  shapes <- c(vp_shapes, list(syn_hline(df$Date[1], tail(df$Date,1), level, "#f39c12", "solid", 1.5)))
  ann <- list(syn_tag(outc_dates[1], level, paste0("Market Respects ", label), "#27ae60", 9))
  syn_chart(df, paste0("Market Respects ", label), shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# INITIAL BALANCE
# ══════════════════════════════════════════════════════════════════════════

w5_ib_example <- function(kind, seed) {
  set.seed(seed)
  ib <- syn_path(4, start = 100, drift = 0.05, vol = 0.8, seed = seed)
  ib_hi <- max(ib$High); ib_lo <- min(ib$Low)

  if (kind == "break_high") {
    move <- syn_path(20, start = tail(ib$Close,1), drift = 1.1, vol = 1, seed = seed + 20)
    df <- syn_concat(ib, move)
    label <- "Break Through Initial Balance High"; level <- ib_hi
  } else if (kind == "break_low") {
    move <- syn_path(20, start = tail(ib$Close,1), drift = -1.1, vol = 1, seed = seed + 20)
    df <- syn_concat(ib, move)
    label <- "Break Through Initial Balance Low"; level <- ib_lo
  } else if (kind == "retest_high") {
    brk <- syn_path(10, start = tail(ib$Close,1), drift = 1.0, vol = 1, seed = seed + 20)
    retest <- syn_path(10, start = tail(brk$Close,1), drift = -0.3, vol = 0.6, seed = seed + 40)
    cont <- syn_path(10, start = tail(retest$Close,1), drift = 0.9, vol = 1, seed = seed + 60)
    df <- syn_concat(ib, brk, retest, cont)
    label <- "Retest of Initial Balance High After Break"; level <- ib_hi
  } else { # retest_low
    brk <- syn_path(10, start = tail(ib$Close,1), drift = -1.0, vol = 1, seed = seed + 20)
    retest <- syn_path(10, start = tail(brk$Close,1), drift = 0.3, vol = 0.6, seed = seed + 40)
    cont <- syn_path(10, start = tail(retest$Close,1), drift = -0.9, vol = 1, seed = seed + 60)
    df <- syn_concat(ib, brk, retest, cont)
    label <- "Retest of Initial Balance Low After Break"; level <- ib_lo
  }
  ib_dates <- syn_seg(df, 1)
  shapes <- list(
    syn_hline(df$Date[1], tail(df$Date,1), ib_hi, "#e74c3c", "dash", 1.5),
    syn_hline(df$Date[1], tail(df$Date,1), ib_lo, "#27ae60", "dash", 1.5),
    syn_line(ib_dates[1], tail(ib_dates,1), ib_lo, ib_lo, "#7f8c8d", "solid", 3),
    syn_line(ib_dates[1], tail(ib_dates,1), ib_hi, ib_hi, "#7f8c8d", "solid", 3)
  )
  ann <- list(syn_tag(df$Date[5], level, label, "#f39c12", 9))
  syn_chart(df, label, shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# CONFLUENCE — aggressive bounce off 3+ levels stacked together, sourced from
# SEPARATE, OLDER profile sessions (not one session's own internal metrics) —
# matching the sheet's specific note that these "can be aligned from old
# profiles, not just the previous days."
# ══════════════════════════════════════════════════════════════════════════

w5_confluence_bounce <- function(seed) {
  set.seed(seed)
  target <- 100
  # A shared narrow zone that each of the 3 separate historical sessions below is
  # confined to trade within — so each session's own independently-computed level
  # (VAH / POC / Initial Balance Low) genuinely lands near the others by construction,
  # rather than being 3 metrics read off a single recent session.
  band_lo <- function(i) target - 5; band_hi <- function(i) target + 5
  
  # Old session 1 (furthest back): contributes its Value Area High
  s1 <- syn_confined_path(18, start = target, lo_fn = band_lo, hi_fn = band_hi, vol = 1.1, seed = seed)
  s1$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = 18)  # syn_confined_path has no Date column,
  # and as the FIRST segment passed to syn_concat, it needs one set explicitly (later
  # segments get theirs auto-assigned by syn_concat regardless of what's set here).
  s1$Volume <- round(runif(18, 500, 900))
  vp1 <- syn_volume_profile(s1, n_bins = 12)
  level1 <- vp1$vah
  gap1 <- syn_path(6, start = tail(s1$Close, 1), drift = 0.25, vol = 0.7, seed = seed + 5)
  
  # Old session 2 (a few sessions later): contributes its Point of Control
  s2 <- syn_confined_path(16, start = tail(gap1$Close, 1), lo_fn = band_lo, hi_fn = band_hi, vol = 1.1, seed = seed + 20)
  s2$Volume <- round(runif(16, 500, 900))
  vp2 <- syn_volume_profile(s2, n_bins = 12)
  level2 <- vp2$poc
  gap2 <- syn_path(5, start = tail(s2$Close, 1), drift = -0.2, vol = 0.6, seed = seed + 25)
  
  # Most recent session: contributes its Initial Balance Low
  s3 <- syn_confined_path(14, start = tail(gap2$Close, 1), lo_fn = band_lo, hi_fn = band_hi, vol = 1.0, seed = seed + 40)
  ib_lo <- min(s3$Low[1:4])
  level3 <- ib_lo
  
  confluence_level <- mean(c(level1, level2, level3))
  
  approach <- syn_path(10, start = tail(s3$Close, 1), drift = -0.4, vol = 0.7, seed = seed + 60)
  outc <- syn_outcome_tail(confluence_level, 1, 12, TRUE, seed + 200, n = 16)
  
  df <- syn_concat(s1, gap1, s2, gap2, s3, approach, outc$df)
  s1_dates <- syn_seg(df, 1); s2_dates <- syn_seg(df, 3); s3_dates <- syn_seg(df, 5)
  outc_dates <- syn_seg(df, 7)
  
  shapes <- list(
    syn_hline(df$Date[1], tail(df$Date, 1), level1, "#9b59b6", "dash", 1.3),
    syn_hline(df$Date[1], tail(df$Date, 1), level2, "#3498db", "dash", 1.3),
    syn_hline(df$Date[1], tail(df$Date, 1), level3, "#7f8c8d", "dash", 1.3),
    syn_hline(df$Date[1], tail(df$Date, 1), confluence_level, "#f39c12", "solid", 2.2)
  )
  ann <- list(
    syn_tag(s1_dates[3], level1, "Old Session 1 \u2014 VAH", "#9b59b6", 7),
    syn_tag(s2_dates[3], level2, "Old Session 2 \u2014 POC", "#3498db", 7),
    syn_tag(s3_dates[3], level3, "Most Recent Session \u2014 IB Low", "#7f8c8d", 7),
    syn_tag(outc_dates[1], confluence_level, "3 Old-Profile Levels Align \u2192 Aggressive Bounce", "#27ae60", 9)
  )
  syn_chart(df, "Aggressive Bounce off Multi-Session Confluence (3 Separate Historical Profiles)", shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# CANONICAL SECTIONS
# ══════════════════════════════════════════════════════════════════════════

w5_sections <- function() {
  vp_defs <- list(
    list(id = "vp_pshape",  kind = "p_shape",         label = "P-Shaped Day Followed by a Continuation"),
    list(id = "vp_bshape",  kind = "b_shape",          label = "b-Shaped Day Followed by a Continuation"),
    list(id = "vp_inside",  kind = "inside_breakout",  label = "Inside Day, Aggressive Breakout Continuing the Trend"),
    list(id = "vp_thin",    kind = "thin_retrace",     label = "Thin Volume Day, Next Day Retraces Back Through")
  )
  vp_specs <- list()
  seed_i <- 500
  for (vd in vp_defs) {
    seed_i <- seed_i + 1
    local({
      d <- vd; s1 <- seed_i
      vp_specs[[length(vp_specs) + 1]] <<- list(
        id = paste0(d$id, "_a"), title = paste0(d$label, " (Ex. 1)"),
        desc = paste0("Illustrates: ", d$label, "."), gen = function() w5_session_shape(d$kind, s1)
      )
      vp_specs[[length(vp_specs) + 1]] <<- list(
        id = paste0(d$id, "_b"), title = paste0(d$label, " (Ex. 2)"),
        desc = paste0("A second example: ", d$label, "."), gen = function() w5_session_shape(d$kind, s1 + 500)
      )
    })
  }
  # Double Distribution + the two Node-Bounce items follow the same x2 pattern
  dd_seed <- 520
  vp_specs[[length(vp_specs)+1]] <- list(id = "vp_dd_a", title = "Double Distribution, Low Volume Later Filled (Ex. 1)",
    desc = "Illustrates: Double Distribution where price has filled in Low Volume.", gen = function() w5_session_shape("double_distribution", dd_seed))
  vp_specs[[length(vp_specs)+1]] <- list(id = "vp_dd_b", title = "Double Distribution, Low Volume Later Filled (Ex. 2)",
    desc = "A second example: Double Distribution where price has filled in Low Volume.", gen = function() w5_session_shape("double_distribution", dd_seed + 500))

  lvn_seed <- 530; hvn_seed <- 540
  vp_specs[[length(vp_specs)+1]] <- list(id = "vp_lvn_a", title = "Bounce off Low Volume Node (Ex. 1)",
    desc = "Illustrates: Bounce off Low Volume Node.", gen = function() w5_node_bounce("lvn", lvn_seed))
  vp_specs[[length(vp_specs)+1]] <- list(id = "vp_lvn_b", title = "Bounce off Low Volume Node (Ex. 2)",
    desc = "A second example: Bounce off Low Volume Node.", gen = function() w5_node_bounce("lvn", lvn_seed + 500))
  vp_specs[[length(vp_specs)+1]] <- list(id = "vp_hvn_a", title = "Bounce off High Volume Node (Ex. 1)",
    desc = "Illustrates: Bounce off High Volume Node.", gen = function() w5_node_bounce("hvn", hvn_seed))
  vp_specs[[length(vp_specs)+1]] <- list(id = "vp_hvn_b", title = "Bounce off High Volume Node (Ex. 2)",
    desc = "A second example: Bounce off High Volume Node.", gen = function() w5_node_bounce("hvn", hvn_seed + 500))

  mp_defs <- list(
    list(id = "mp_poc", kind = "poc", label = "Point of Control (POC)"),
    list(id = "mp_val", kind = "val", label = "Value Area Low (VAL)"),
    list(id = "mp_vah", kind = "vah", label = "Value Area High (VAH)"),
    list(id = "mp_sp",  kind = "single_print", label = "Single Print"),
    list(id = "mp_ledge", kind = "ledge", label = "Ledge")
  )
  mp_specs <- list()
  seed_i <- 550
  for (md in mp_defs) {
    seed_i <- seed_i + 1
    local({
      d <- md; s1 <- seed_i
      mp_specs[[length(mp_specs) + 1]] <<- list(
        id = paste0(d$id, "_a"), title = paste0("Market Respects ", d$label, " (Ex. 1)"),
        desc = paste0("Illustrates the market respecting the ", d$label, "."), gen = function() w5_mp_respect(d$kind, s1)
      )
      mp_specs[[length(mp_specs) + 1]] <<- list(
        id = paste0(d$id, "_b"), title = paste0("Market Respects ", d$label, " (Ex. 2)"),
        desc = paste0("A second example of the market respecting the ", d$label, "."), gen = function() w5_mp_respect(d$kind, s1 + 500)
      )
    })
  }

  ib_defs <- list(
    list(id = "ib_bh", kind = "break_high",  label = "Break Through Initial Balance High"),
    list(id = "ib_bl", kind = "break_low",   label = "Break Through Initial Balance Low"),
    list(id = "ib_rh", kind = "retest_high", label = "Retest of Initial Balance High After Break"),
    list(id = "ib_rl", kind = "retest_low",  label = "Retest of Initial Balance Low After Break")
  )
  ib_specs <- list()
  seed_i <- 570
  for (id in ib_defs) {
    seed_i <- seed_i + 1
    local({
      d <- id; s1 <- seed_i
      ib_specs[[length(ib_specs) + 1]] <<- list(
        id = paste0(d$id, "_a"), title = paste0(d$label, " (Ex. 1)"),
        desc = paste0("Illustrates: ", d$label, "."), gen = function() w5_ib_example(d$kind, s1)
      )
      ib_specs[[length(ib_specs) + 1]] <<- list(
        id = paste0(d$id, "_b"), title = paste0(d$label, " (Ex. 2)"),
        desc = paste0("A second example: ", d$label, "."), gen = function() w5_ib_example(d$kind, s1 + 500)
      )
    })
  }

  confluence_specs <- list(
    list(id = "confluence1", title = "Aggressive Bounce off 3+ Confluent Levels",
         desc = "A bounce off a level combining Value Area Low, a prior Initial Balance Low, and a nearby High Volume Node.",
         gen = function() w5_confluence_bounce(590))
  )

  list(
    list(title = "Volume Profile", specs = vp_specs),
    list(title = "Market Profile", specs = mp_specs),
    list(title = "Initial Balance", specs = ib_specs),
    list(title = "Multi-Level Confluence", specs = confluence_specs)
  )
}

# ══════════════════════════════════════════════════════════════════════════
# UI / SERVER
# ══════════════════════════════════════════════════════════════════════════

weekly_activity_week5_ui <- function(id) {
  ns <- NS(id)
  sections <- w5_sections()

  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(paste0(
              "Covers Step 5: Volume Profile (7 features x 2 examples), Market Profile ",
              "(5 features x 2), Initial Balance (4 features x 2), plus one multi-level confluence bounce ",
              "(33 examples in total). The volume-at-price profile is shown as a ladder of horizontal bars ",
              "docked to the right edge of each chart \u2014 longer bars mean more volume traded at that price. ",
              "All data is simulated to illustrate the exact feature requested, not a claim about real market history."
            ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    weekly_download_ui(ns),
    lapply(sections, function(sec) weekly_grid_ui(ns, sec$specs, sec$title))
  )
}

weekly_activity_week5_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    sections <- w5_sections()
    for (sec in sections) weekly_grid_server(output, sec$specs)
    weekly_download_server(output, "Step 5", sections, "step5_activity")
    session$onSessionEnded(function() {})
  })
}

# ====================================================================================================
# (was modules/weekly_activity_week6.R)
# modules/weekly_activity_week6.R
# Covers every point in Step 6 — Straddle Trading (4), Pivot Point
# Bounce System (2), Holy Grail Trade (2), ADX (4), DMI (2) = 14 examples.
# All charts use synthetic OHLC data — see R/utils_synthetic.R for the engine.
# ADX/DMI are computed with TTR::ADX (already a project dependency, used in
# extended-indicators tabs elsewhere); Pivot Points reuse the same PP/R1/S1 formulas
# as modules/pivot_points.R for consistency.

# ══════════════════════════════════════════════════════════════════════════
# INDICATOR HELPERS (same convention as w3_*_ind in weekly_activity_week3.R)
# ══════════════════════════════════════════════════════════════════════════

w6_adx_ind <- function(hlc, dates) {
  a <- TTR::ADX(hlc, n = 14)
  ok <- !is.na(a[, "ADX"])
  list(dates = dates[ok], values = as.numeric(a[ok, "ADX"]), label = "ADX",
       hlines = c(25, 30), color = "#8e44ad", yrange = c(0, 60))
}
w6_dmi_ind <- function(hlc, dates) {
  a <- TTR::ADX(hlc, n = 14)
  ok <- !is.na(a[, "DIp"]) & !is.na(a[, "DIn"])
  list(dates = dates[ok], values = as.numeric(a[ok, "DIp"]), values2 = as.numeric(a[ok, "DIn"]),
       label = "+DI", label2 = "-DI", color = "#27ae60", color2 = "#e74c3c",
       hlines = NULL, yrange = c(0, 60))
}

# ══════════════════════════════════════════════════════════════════════════
# STRADDLE TRADING
# ══════════════════════════════════════════════════════════════════════════

# Morning straddle: tight overnight-range consolidation (22:00-06:00 London in the course manual), then a directional break
# that reaches (or exceeds) a 1:1 measured move off the range height.
w6_morning_straddle <- function(up, seed) {
  set.seed(seed)
  lead <- syn_path(10, start = 100, drift = 0.02, vol = 0.5, seed = seed)
  range_mid <- tail(lead$Close, 1)
  n_rng <- 10
  hi_fn <- function(i) range_mid + 2
  lo_fn <- function(i) range_mid - 2
  rng <- syn_confined_path(n_rng, start = range_mid, lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.5, seed = seed + 10)
  rng$Date <- seq(tail(lead$Date, 1) + 1, by = "day", length.out = n_rng)
  range_height <- 4
  breakout_dir <- if (up) 1 else -1
  outc <- syn_outcome_tail(tail(rng$Close, 1), breakout_dir, range_height, TRUE, seed + 200, n = 16)

  df <- syn_concat(lead, rng, outc$df)
  rng_dates <- syn_seg(df, 2); outc_dates <- syn_seg(df, 3)
  shapes <- list(
    syn_hline(rng_dates[1], tail(df$Date,1), range_mid + 2, "#7f8c8d", "dash", 1.5),
    syn_hline(rng_dates[1], tail(df$Date,1), range_mid - 2, "#7f8c8d", "dash", 1.5),
    syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5)
  )
  ann <- list(
    syn_tag(rng_dates[round(n_rng/2)], range_mid, "Overnight Range (Orders 1-2 Pips Beyond Each Extreme)", "#002C3C", 8),
    syn_tag(outc_dates[1], tail(rng$Close,1), paste0("Breaks ", ifelse(up, "Up", "Down"), " \u2192 Min 1:1 Hit"),
            ifelse(up, "#27ae60", "#e74c3c"), 9)
  )
  syn_chart(df, paste0("Morning Straddle \u2014 Breaks ", ifelse(up, "Upside", "Downside"), ", Reaches Min 1:1"), shapes, ann)
}

# News straddle: a quiet pre-news drift, a sharp news-driven spike, then either a
# clean continuation to 2:1 or a whipsaw (spike reverses hard through the entry zone).
w6_news_straddle <- function(kind, seed) {
  set.seed(seed)
  lead <- syn_path(12, start = 100, drift = 0.0, vol = 0.4, seed = seed)
  entry <- tail(lead$Close, 1)

  if (kind == "hit_2r") {
    spike_dir <- if (seed %% 2 == 0) 1 else -1
    spike <- syn_path(4, start = entry, drift = spike_dir * 3.2, vol = 1.0, seed = seed + 20)
    outc <- syn_outcome_tail(tail(spike$Close, 1), spike_dir, abs(tail(spike$Close,1) - entry) * 1.3, TRUE, seed + 200, n = 16)
    df <- syn_concat(lead, spike, outc$df)
    spike_dates <- syn_seg(df, 2); outc_dates <- syn_seg(df, 3)
    shapes <- list(syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5))
    ann <- list(
      syn_tag(spike_dates[1], entry, "News Release \u2192 Straddle Triggers", "#e67e22", 9),
      syn_tag(outc_dates[1], tail(spike$Close,1), "Continuation \u2192 Min 2:1 Hit", "#27ae60", 9)
    )
    title <- "News Straddle \u2014 Reaches Min 2:1"
  } else {
    spike_dir <- if (seed %% 2 == 0) 1 else -1
    spike <- syn_path(4, start = entry, drift = spike_dir * 3.0, vol = 1.0, seed = seed + 20)
    # whipsaw: sharp reversal back through the entry zone and beyond, the other way
    reversal <- syn_path(8, start = tail(spike$Close,1), drift = -spike_dir * 2.2, vol = 1.0, seed = seed + 40)
    settle <- syn_path(10, start = tail(reversal$Close,1), drift = -spike_dir * 0.3, vol = 0.6, seed = seed + 60)
    df <- syn_concat(lead, spike, reversal, settle)
    spike_dates <- syn_seg(df, 2); reversal_dates <- syn_seg(df, 3)
    shapes <- list(syn_hline(df$Date[1], tail(df$Date,1), entry, "#7f8c8d", "dot", 1))
    ann <- list(
      syn_tag(spike_dates[1], entry, "News Release \u2192 Straddle Triggers", "#e67e22", 9),
      syn_tag(reversal_dates[round(length(reversal_dates)/2)], tail(reversal$Close,1),
              "Whipsaw \u2192 Reverses Back Through Entry", "#e74c3c", 9)
    )
    title <- "News Straddle \u2014 Whipsawed"
  }
  syn_chart(df, title, shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# PIVOT POINT BOUNCE SYSTEM (reuses the standard PP/R1/S1 formulas)
# ══════════════════════════════════════════════════════════════════════════

w6_pivot_bounce <- function(long, seed) {
  set.seed(seed)
  # Prior "session" used purely to derive a pivot level
  prior <- syn_path(20, start = 100, drift = if (long) -0.1 else 0.1, vol = 1, seed = seed)
  H <- max(prior$High); L <- min(prior$Low); C <- tail(prior$Close, 1)
  PP <- (H + L + C) / 3
  R1 <- (2 * PP) - L
  S1 <- (2 * PP) - H

  level <- if (long) S1 else R1
  spread <- H - L
  # Multi-touch test phase: price is confined to repeatedly test S1/R1 from the
  # correct side (several genuine touches, matching Step 1's S/R rigor) before the
  # final bounce-and-run leg, instead of a single approach-and-touch.
  if (long) {
    lo_fn <- function(i) level; hi_fn <- function(i) C + spread * 0.15
  } else {
    hi_fn <- function(i) level; lo_fn <- function(i) C - spread * 0.15
  }
  approach <- syn_confined_path(10, start = C, lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.55, seed = seed + 20)
  bounce_dir <- if (long) 1 else -1
  outc <- syn_outcome_tail(level, bounce_dir, abs(PP - level), TRUE, seed + 200, n = 16)

  df <- syn_concat(prior, approach, outc$df)
  outc_dates <- syn_seg(df, 3)
  shapes <- list(
    syn_hline(df$Date[1], tail(df$Date,1), PP, "#2980b9", "solid", 1.5),
    syn_hline(df$Date[1], tail(df$Date,1), R1, "#e67e22", "dash", 1.2),
    syn_hline(df$Date[1], tail(df$Date,1), S1, "#27ae60", "dash", 1.2),
    syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5)
  )
  ann <- list(
    syn_tag(outc_dates[1], level, paste0(ifelse(long, "Bounces off S1 \u2192 Long", "Rejects at R1 \u2192 Short")),
            ifelse(long, "#27ae60", "#e74c3c"), 9),
    syn_tag(df$Date[3], PP, "PP", "#2980b9", 9)
  )
  syn_chart(df, paste0("Pivot Point Bounce \u2014 ", ifelse(long, "Long", "Short"), " Setup, Target Hit"), shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# HOLY GRAIL TRADE (trend + ADX>30, pullback to a rising/falling 20-period MA, then
# a breakout continuation in the direction of the primary trend)
# ══════════════════════════════════════════════════════════════════════════

w6_holy_grail <- function(long, seed) {
  set.seed(seed)
  trend <- syn_path(34, start = 100, drift = if (long) 1.0 else -1.0, vol = 1, seed = seed)
  pull_dir <- if (long) -1 else 1
  pullback <- syn_path(8, start = tail(trend$Close, 1), drift = pull_dir * 0.6, vol = 0.6, seed = seed + 20)
  cont_dir <- if (long) 1 else -1
  cont <- syn_path(18, start = tail(pullback$Close, 1), drift = cont_dir * 1.1, vol = 1, seed = seed + 40)

  df <- syn_concat(trend, pullback, cont)
  pullback_dates <- syn_seg(df, 2); cont_dates <- syn_seg(df, 3)
  ma <- as.numeric(TTR::EMA(df$Close, n = 20))
  ok <- !is.na(ma); idxs <- which(ok)
  shapes <- list()
  for (i in seq_len(length(idxs) - 1)) {
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], ma[idxs[i]], ma[idxs[i+1]], "#9b59b6", "solid", 2)
  }
  ann <- list(
    syn_tag(pullback_dates[round(length(pullback_dates)/2)], tail(pullback$Close,1),
            "Pullback to 20-EMA (ADX > 30 and Turning Down)", "#e67e22", 9),
    syn_tag(cont_dates[1], tail(pullback$Close,1),
            paste0("Order ", ifelse(long, "Above 2-Bar High", "Below 2-Bar Low"), " Triggers \u2192 ", ifelse(long,"Long","Short")),
            ifelse(long, "#27ae60", "#e74c3c"), 9)
  )
  hlc <- df[, c("High","Low","Close")]
  ind <- w6_adx_ind(hlc, df$Date)
  syn_chart(df, paste0("Holy Grail Trade \u2014 ", ifelse(long, "Long", "Short"), " Setup"), shapes, ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# ADX
# ══════════════════════════════════════════════════════════════════════════

w6_adx_example <- function(kind, seed) {
  set.seed(seed)
  hlc_ind <- function(d) { hlc <- d[, c("High","Low","Close")]; w6_adx_ind(hlc, d$Date) }

  if (kind == "above30_down") {
    df <- syn_path(40, start = 140, drift = -1.3, vol = 1.1, seed = seed)
    title <- "ADX Above 30 in a Downtrend"
  } else if (kind == "above30_up") {
    df <- syn_path(40, start = 100, drift = 1.3, vol = 1.1, seed = seed)
    title <- "ADX Above 30 in an Uptrend"
  } else if (kind == "below25_sideways") {
    hi_fn <- function(i) 106; lo_fn <- function(i) 94
    df <- syn_confined_path(40, start = 100, lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.9, seed = seed)
    df$Date <- seq(as.Date("2024-01-01"), by = "day", length.out = 40)
    title <- "ADX Below 25 in a Sideways Market"
  } else { # decreasing_pullback
    leg1 <- syn_path(26, start = 100, drift = 1.2, vol = 1.1, seed = seed)
    pull <- syn_path(14, start = tail(leg1$Close,1), drift = -0.4, vol = 0.5, seed = seed + 20)
    pull$Date <- seq(tail(leg1$Date,1) + 1, by = "day", length.out = 14)
    df <- bind_rows(leg1, pull)
    title <- "ADX Decreasing During a Pullback Within a Major Trend"
  }
  ind <- hlc_ind(df)
  syn_chart(df, title, list(), list(), indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# DMI
# ══════════════════════════════════════════════════════════════════════════

w6_dmi_example <- function(buy, seed) {
  set.seed(seed)
  lead <- if (buy) syn_path(16, start = 130, drift = -0.3, vol = 0.9, seed = seed)
          else syn_path(16, start = 100, drift = 0.3, vol = 0.9, seed = seed)
  trend_dir <- if (buy) 1 else -1
  trend <- syn_path(28, start = tail(lead$Close,1), drift = trend_dir * 1.2, vol = 1.1, seed = seed + 40)
  df <- syn_concat(lead, trend)
  trend_dates <- syn_seg(df, 2)
  hlc <- df[, c("High","Low","Close")]
  ind <- w6_dmi_ind(hlc, df$Date)
  ann <- list(syn_tag(trend_dates[1], tail(lead$Close,1),
                       ifelse(buy, "+DI Crosses Above \u2212DI \u2192 Buy (ADX Confirms Uptrend)",
                                   "\u2212DI Crosses Above +DI \u2192 Sell (ADX Confirms Downtrend)"),
                       ifelse(buy, "#27ae60", "#e74c3c"), 9))
  title <- paste0("DMI \u2014 ", ifelse(buy, "Buy Signal in an Uptrend", "Sell Signal in a Downtrend"), ", ADX Confirming")
  syn_chart(df, title, list(), ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# CANONICAL SECTIONS
# ══════════════════════════════════════════════════════════════════════════

w6_sections <- function() {
  straddle_specs <- list(
    list(id = "sd_morn_down", title = "Morning Straddle \u2014 Breaks Down, Min 1:1", desc = "A morning straddle (overnight range, 22:00-06:00 London) that breaks to the downside and reaches at least a 1:1 measured move.",
         gen = function() w6_morning_straddle(FALSE, 601)),
    list(id = "sd_morn_up", title = "Morning Straddle \u2014 Breaks Up, Min 1:1", desc = "A morning straddle (overnight range, 22:00-06:00 London) that breaks to the upside and reaches at least a 1:1 measured move.",
         gen = function() w6_morning_straddle(TRUE, 602)),
    list(id = "sd_news_2r", title = "News Straddle \u2014 Min 2:1", desc = "A news-driven straddle whose post-news move continues cleanly to at least a 2:1 measured move.",
         gen = function() w6_news_straddle("hit_2r", 603)),
    list(id = "sd_news_whip", title = "News Straddle \u2014 Whipsawed", desc = "A news-driven straddle where the initial spike reverses hard back through the entry zone.",
         gen = function() w6_news_straddle("whipsaw", 604))
  )

  pp_specs <- list(
    list(id = "pp_long", title = "Pivot Point Bounce \u2014 Long, Target Hit", desc = "Price bounces off the S1 support pivot level and runs to the Pivot Point (PP) target.",
         gen = function() w6_pivot_bounce(TRUE, 611)),
    list(id = "pp_short", title = "Pivot Point Bounce \u2014 Short, Target Hit", desc = "Price rejects at the R1 resistance pivot level and runs to the Pivot Point (PP) target.",
         gen = function() w6_pivot_bounce(FALSE, 612))
  )

  hg_specs <- list(
    list(id = "hg_long", title = "Holy Grail Trade \u2014 Long Setup", desc = "A strong uptrend (ADX > 30) pulls back to the rising 20-EMA before continuing higher.",
         gen = function() w6_holy_grail(TRUE, 621)),
    list(id = "hg_short", title = "Holy Grail Trade \u2014 Short Setup", desc = "A strong downtrend (ADX > 30) pulls back to the falling 20-EMA before continuing lower.",
         gen = function() w6_holy_grail(FALSE, 622))
  )

  adx_defs <- list(
    list(id = "adx_down30",   kind = "above30_down",       label = "ADX Above 30 in a Downtrend"),
    list(id = "adx_up30",     kind = "above30_up",         label = "ADX Above 30 in an Uptrend"),
    list(id = "adx_side25",   kind = "below25_sideways",   label = "ADX Below 25 in a Sideways Market"),
    list(id = "adx_pullback", kind = "decreasing_pullback",label = "ADX Decreasing During a Pullback in a Major Trend")
  )
  adx_specs <- list()
  for (i in seq_along(adx_defs)) {
    local({
      d <- adx_defs[[i]]; s1 <- 630 + i
      adx_specs[[length(adx_specs) + 1]] <<- list(
        id = d$id, title = d$label, desc = paste0("Illustrates: ", d$label, "."),
        gen = function() w6_adx_example(d$kind, s1)
      )
    })
  }

  dmi_specs <- list(
    list(id = "dmi_buy", title = "DMI \u2014 Buy Signal, Uptrend, ADX Confirms", desc = "+DI crosses above \u2212DI at the start of an uptrend, with ADX confirming trend strength.",
         gen = function() w6_dmi_example(TRUE, 641)),
    list(id = "dmi_sell", title = "DMI \u2014 Sell Signal, Downtrend, ADX Confirms", desc = "\u2212DI crosses above +DI at the start of a downtrend, with ADX confirming trend strength.",
         gen = function() w6_dmi_example(FALSE, 642))
  )

  list(
    list(title = "Straddle Trading", specs = straddle_specs),
    list(title = "Pivot Point Bounce System", specs = pp_specs),
    list(title = "Holy Grail Trade", specs = hg_specs),
    list(title = "Average Directional Index (ADX)", specs = adx_specs),
    list(title = "Directional Movement Index (DMI)", specs = dmi_specs)
  )
}

# ══════════════════════════════════════════════════════════════════════════
# UI / SERVER
# ══════════════════════════════════════════════════════════════════════════

weekly_activity_week6_ui <- function(id) {
  ns <- NS(id)
  sections <- w6_sections()

  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(paste0(
              "Every chart below uses simulated OHLC data, deterministically generated to exhibit the exact feature ",
              "requested in Step 6 — Straddle Trading, the Pivot Point Bounce System, the Holy ",
              "Grail Trade, ADX, and DMI (14 examples in total). This is for practising setup recognition, not a ",
              "claim about real market history."
            ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    weekly_download_ui(ns),
    lapply(sections, function(sec) weekly_grid_ui(ns, sec$specs, sec$title))
  )
}

weekly_activity_week6_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    sections <- w6_sections()
    for (sec in sections) weekly_grid_server(output, sec$specs)
    weekly_download_server(output, "Step 6", sections, "step6_activity")
    session$onSessionEnded(function() {})
  })
}
