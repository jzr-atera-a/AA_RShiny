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
