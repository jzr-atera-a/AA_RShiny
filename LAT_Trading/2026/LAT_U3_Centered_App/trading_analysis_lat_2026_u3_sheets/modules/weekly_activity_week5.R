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
