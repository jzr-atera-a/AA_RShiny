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

# Morning straddle: tight opening-range consolidation, then a directional break
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
    syn_tag(rng_dates[round(n_rng/2)], range_mid, "Morning Range (Straddle Placed at Range Extremes)", "#002C3C", 8),
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
  # approach the level, bounce, and run to target (PP as the first target)
  approach <- syn_path(10, start = C, drift = if (long) -0.5 else 0.5, vol = 0.7, seed = seed + 20)
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
            "Pullback to Rising 20-EMA (ADX > 30)", "#e67e22", 9),
    syn_tag(cont_dates[1], tail(pullback$Close,1),
            paste0("Breaks ", ifelse(long, "Above", "Below"), " Pullback High/Low \u2192 ", ifelse(long,"Long","Short")),
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
    list(id = "sd_morn_down", title = "Morning Straddle \u2014 Breaks Down, Min 1:1", desc = "A morning-range straddle that breaks to the downside and reaches at least a 1:1 measured move.",
         gen = function() w6_morning_straddle(FALSE, 601)),
    list(id = "sd_morn_up", title = "Morning Straddle \u2014 Breaks Up, Min 1:1", desc = "A morning-range straddle that breaks to the upside and reaches at least a 1:1 measured move.",
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
