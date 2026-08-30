# R/utils_synthetic.R
# Synthetic OHLC pattern-generation engine for the Weekly Activity tabs.
#
# The activity sheets ask for ~90 distinct, precisely-defined chart examples (a
# CONFIRMED vs FAILED Shooting Star, a Double Top that hits vs misses its measured-move
# target, an RSI bullish divergence, etc.). Hunting for a real historical instance of
# every exact combination isn't practical, so every chart here is built from a
# deterministically-seeded synthetic OHLC series shaped to exhibit the named feature.
# This is clearly simulated data for illustration, not a live market claim.
#
# Design: a small set of reusable PRIMITIVES (trend legs, candle shape injection,
# geometric pattern builders) plus a generic "spec list -> grid of boxes" renderer,
# so ~90 examples are built from a manageable number of parameterized functions
# rather than ~90 fully bespoke ones.

# ══════════════════════════════════════════════════════════════════════════
# PRIMITIVES
# ══════════════════════════════════════════════════════════════════════════

# A random-walk-with-drift base OHLC path.
syn_path <- function(n, start = 100, drift = 0, vol = 1, seed = 1) {
  set.seed(seed)
  close <- numeric(n)
  close[1] <- start
  for (i in 2:n) close[i] <- max(close[i - 1] + drift + rnorm(1, 0, vol), 0.5)
  open <- c(start, close[-n]) + rnorm(n, 0, vol * 0.15)
  high <- pmax(open, close) + abs(rnorm(n, vol * 0.5, vol * 0.25))
  low  <- pmin(open, close) - abs(rnorm(n, vol * 0.5, vol * 0.25))
  data.frame(
    Date = seq(as.Date("2024-01-01"), by = "day", length.out = n),
    Open = open, High = high, Low = low, Close = close
  )
}

# Overwrites a single bar's OHLC to match a named candlestick shape. base = reference
# price level for that bar; vol scales body/wick sizes; up = TRUE colours it bullish.
syn_confined_path <- function(n, start, lo_fn, hi_fn, vol = 1, seed = 1) {
  set.seed(seed)
  close <- numeric(n)
  close[1] <- min(max(start, lo_fn(1)), hi_fn(1))
  for (i in 2:n) {
    step <- rnorm(1, 0, vol)
    cand <- close[i - 1] + step
    lo <- lo_fn(i); hi <- hi_fn(i)
    if (cand > hi) cand <- hi - abs(cand - hi) * 0.4
    if (cand < lo) cand <- lo + abs(lo - cand) * 0.4
    close[i] <- min(max(cand, lo), hi)
  }
  open <- c(start, close[-n]) + rnorm(n, 0, vol * 0.12)
  high <- pmax(open, close) + abs(rnorm(n, vol * 0.35, vol * 0.15))
  low  <- pmin(open, close) - abs(rnorm(n, vol * 0.35, vol * 0.15))
  data.frame(Open = open, High = high, Low = low, Close = close)
}

syn_candle <- function(base, vol, type, up = TRUE) {
  b <- vol * 1.1  # typical body size
  switch(type,
    doji_long_legged = list(o = base, c = base + 0.05 * vol, h = base + 2.2 * vol, l = base - 2.2 * vol),
    doji_dragonfly    = list(o = base, c = base + 0.03 * vol, h = base + 0.15 * vol, l = base - 2.6 * vol),
    hammer            = list(o = base, c = base + b, h = base + b + 0.15 * vol, l = base - 2.4 * vol),
    inverted_hammer   = list(o = base, c = base + b, h = base + 2.5 * vol, l = base - 0.15 * vol),
    shooting_star     = list(o = base + b, c = base, h = base + b + 2.4 * vol, l = base - 0.15 * vol),
    hanging_man       = list(o = base + b, c = base, h = base + b + 0.15 * vol, l = base - 2.4 * vol),
    marubozu_bull     = list(o = base, c = base + 3 * vol, h = base + 3 * vol + 0.05 * vol, l = base - 0.05 * vol),
    marubozu_bear     = list(o = base + 3 * vol, c = base, h = base + 3 * vol + 0.05 * vol, l = base - 0.05 * vol),
    spinning_top      = list(o = base, c = base + 0.3 * vol, h = base + 1.5 * vol, l = base - 1.5 * vol),
    list(o = base, c = base + b, h = base + b + 0.3 * vol, l = base - 0.3 * vol)
  )
}

# plot_ly candlestick + optional shapes/annotations, common layout.
# Builds a reusable CHART SPEC (not a plotly object) — every pattern generator ends by
# calling this. The same spec drives both the interactive plotly view (spec_to_plotly)
# and the static base-R render used for PDF export (base_candlestick_plot), so nothing
# has to be built twice. `indicator`, if supplied, is a secondary series (RSI/Stochastic/
# MACD/OBV) rendered as a sub-panel below price on-screen, and as a compressed inset at
# the bottom of the same panel in the static PDF render:
#   indicator = list(dates=, values=, label=, hlines=c(70,30), color="#3498db",
#                     values2=NULL, label2=NULL, color2=NULL, yrange=c(0,100))
syn_chart <- function(df, title, shapes = list(), annotations = list(), yrange = NULL, indicator = NULL) {
  list(df = df, title = title, shapes = shapes, annotations = annotations, yrange = yrange, indicator = indicator)
}

# Interactive plotly candlestick chart from a spec (used for on-screen rendering).
# Uses a stacked subplot (price on top, indicator below) when spec$indicator is present.
spec_to_plotly <- function(spec) {
  p1 <- plot_ly(spec$df, x = ~Date, type = "candlestick", open = ~Open, high = ~High, low = ~Low, close = ~Close,
                increasing = list(line = list(color = "#27ae60")),
                decreasing = list(line = list(color = "#e74c3c")), showlegend = FALSE) %>%
    layout(xaxis = list(title = "", rangeslider = list(visible = FALSE)),
           yaxis = list(title = "Price (simulated)", range = spec$yrange),
           shapes = spec$shapes, annotations = spec$annotations)
  
  if (is.null(spec$indicator)) {
    return(p1 %>% layout(title = list(text = spec$title, font = list(size = 13)),
                          plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 40)))
  }
  
  ind <- spec$indicator
  p2 <- plot_ly(x = ind$dates, y = ind$values, type = "scatter", mode = "lines", name = ind$label,
                line = list(color = ind$color %||% "#3498db", width = 2), showlegend = FALSE)
  if (!is.null(ind$values2)) {
    p2 <- p2 %>% add_trace(x = ind$dates, y = ind$values2, type = "scatter", mode = "lines",
                            name = ind$label2, line = list(color = ind$color2 %||% "#e67e22", width = 1.5))
  }
  ind_shapes <- list()
  if (!is.null(ind$hlines)) {
    for (hl in ind$hlines) {
      ind_shapes[[length(ind_shapes) + 1]] <- list(
        type = "line", x0 = min(ind$dates), x1 = max(ind$dates), y0 = hl, y1 = hl, xref = "x2", yref = "y2",
        line = list(color = "#bdc3c7", width = 1, dash = "dash")
      )
    }
  }
  p2 <- p2 %>% layout(yaxis = list(title = ind$label, range = ind$yrange), xaxis = list(title = ""))
  
  subplot(p1, p2, nrows = 2, heights = c(0.65, 0.35), shareX = TRUE, titleY = TRUE) %>%
    layout(title = list(text = spec$title, font = list(size = 13)),
           shapes = c(spec$shapes, ind_shapes), annotations = spec$annotations,
           plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 40), showlegend = FALSE)
}

# Static base-R candlestick render from a spec (used for PDF export — deliberately
# dependency-free: no webshot2/Chromium, no kaleido/Python, just base graphics, so it
# works on any plain R server without extra system dependencies).
base_candlestick_plot <- function(spec, caption = NULL) {
  df <- spec$df
  n <- nrow(df)
  x <- seq_len(n)
  price_yr <- if (!is.null(spec$yrange)) spec$yrange else range(c(df$Low, df$High), na.rm = TRUE)
  price_pad <- diff(price_yr) * 0.08
  price_yr <- c(price_yr[1] - price_pad, price_yr[2] + price_pad)
  
  has_ind <- !is.null(spec$indicator)
  # Reserve the bottom 26% of the panel for the indicator inset when present.
  if (has_ind) {
    band_h <- diff(price_yr) * 0.35
    yr <- c(price_yr[1] - band_h, price_yr[2])
  } else {
    yr <- price_yr
  }
  
  date_to_idx <- function(d) { idx <- match(d, df$Date); ifelse(is.na(idx), NA, idx) }
  lty_map <- function(dash) {
    if (is.null(dash)) return(1)
    if (dash == "dash") return(2) else if (dash == "dot") return(3) else return(1)
  }
  
  # Wrap long titles onto multiple lines rather than letting them overflow the panel —
  # a single fixed-width line (previous behaviour) clipped/overran for longer pattern
  # names (e.g. "Broken Countertrend Line — Uptrend Continues").
  wrapped_title <- paste(strwrap(spec$title, width = 30), collapse = "\n")
  n_title_lines <- length(strsplit(wrapped_title, "\n")[[1]])
  par(mar = c(1.2, 1.2, 1.3 + 1.05 * n_title_lines, 0.6))
  plot(x, df$Close, type = "n", xlim = c(0.5, n + 0.5), ylim = yr,
       xaxt = "n", yaxt = "n", xlab = "", ylab = "",
       main = wrapped_title, cex.main = 0.62, font.main = 2, col.main = "#002C3C")
  box(col = "#cccccc")
  
  up <- df$Close >= df$Open
  col_up <- "#27ae60"; col_down <- "#e74c3c"
  bar_col <- ifelse(up, col_up, col_down)
  segments(x, df$Low, x, df$High, col = bar_col, lwd = 1)
  body_lo <- pmin(df$Open, df$Close); body_hi <- pmax(df$Open, df$Close)
  w <- max(0.28, min(0.42, 18 / n))
  rect(x - w, body_lo, x + w, body_hi, col = bar_col, border = bar_col)
  
  for (sh in spec$shapes) {
    x0i <- date_to_idx(sh$x0); x1i <- date_to_idx(sh$x1)
    if (is.na(x0i)) x0i <- 1
    if (is.na(x1i)) x1i <- n
    segments(x0i, sh$y0, x1i, sh$y1, col = sh$line$color,
             lwd = max(1, (sh$line$width %||% 1.5) * 0.8), lty = lty_map(sh$line$dash))
  }
  
  for (an in spec$annotations) {
    xi <- date_to_idx(an$x)
    if (is.na(xi)) xi <- round(n * 0.15)
    lbl <- gsub("<b>|</b>", "", an$text)
    txt_col <- if (!is.null(an$font) && !is.null(an$font$color)) an$font$color else "#002C3C"
    text(xi, an$y, labels = lbl, col = txt_col, cex = 0.42, pos = 3, offset = 0.2, font = 2)
  }
  
  if (has_ind) {
    ind <- spec$indicator
    band_lo <- yr[1]; band_hi <- price_yr[1]
    rescale <- function(v) {
      rng <- ind$yrange %||% range(v, na.rm = TRUE)
      band_lo + (v - rng[1]) / diff(rng) * (band_hi - band_lo)
    }
    abline(h = band_hi, col = "#dddddd", lwd = 0.6)
    ind_x <- date_to_idx(ind$dates)
    ind_y <- rescale(ind$values)
    lines(ind_x, ind_y, col = ind$color %||% "#3498db", lwd = 1.2)
    if (!is.null(ind$values2)) lines(ind_x, rescale(ind$values2), col = ind$color2 %||% "#e67e22", lwd = 1)
    if (!is.null(ind$hlines)) {
      for (hl in ind$hlines) abline(h = rescale(hl), col = "#bbbbbb", lty = 2, lwd = 0.6)
    }
    text(1, band_lo + (band_hi - band_lo) * 0.5, labels = ind$label, col = "#666666", cex = 0.35, pos = 4, font = 3)
  }
  
  if (!is.null(caption)) {
    mtext(caption, side = 1, line = 0.3, cex = 0.36, col = "#666666")
  }
}

# Cover page: step title, optional subtitle line + link, generation date.
draw_pdf_cover_page <- function(week_title,
                                 student_name = "",
                                 course_line  = "Trading Analysis F1",
                                 course_url   = "") {
  graphics::par(mfrow = c(1, 1), mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0))
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(0, 1))
  graphics::text(0.5, 0.60, week_title, cex = 2.3, font = 2, col = "#002C3C")
  if (nzchar(student_name)) graphics::text(0.5, 0.49, student_name, cex = 1.5, font = 2, col = "#002C3C")
  if (nzchar(course_line)) graphics::text(0.5, 0.43, course_line, cex = 1.05, col = "#333333")
  # PDF hyperlink where the device supports it (R >= 4.2's pdf() text(..., link=)); always
  # shows the plain URL text as a fallback even if the link annotation itself isn't supported.
  if (nzchar(course_url)) {
    tryCatch(
      graphics::text(0.5, 0.37, course_url, cex = 0.95, col = "#1a73e8", link = course_url),
      error = function(e) graphics::text(0.5, 0.37, course_url, cex = 0.95, col = "#1a73e8")
    )
  }
  graphics::text(0.5, 0.28, paste("Generated:", format(Sys.Date(), "%d %B %Y")), cex = 0.85, col = "#666666")
}

# Exports a full set of sections (each a named list of specs) to a multi-page, portrait
# A4 PDF. A cover page carries the step/branding details. 4 charts per page (2x2),
# each with its title baked into the panel and its activity-sheet description as a
# one-line caption underneath. A section header prints at the top of every page that
# section spans, and a running branding footer prints at the bottom of every
# content page. No external rendering dependencies.
export_weekly_pdf <- function(file, week_title, sections,
                               student_name = "",
                               course_line  = "Trading Analysis F1",
                               course_url   = "") {
  grDevices::pdf(file, width = 8.27, height = 11.69, onefile = TRUE)
  on.exit(grDevices::dev.off(), add = TRUE)
  
  draw_pdf_cover_page(week_title, student_name, course_line, course_url)
  
  per_page <- 4
  footer_text <- if (nzchar(student_name)) paste0(student_name, "  \u2014  ", course_line) else course_line
  
  for (section in sections) {
    specs <- section$specs
    n <- length(specs)
    if (n == 0) next
    n_pages <- ceiling(n / per_page)
    
    for (pg in seq_len(n_pages)) {
      i0 <- (pg - 1) * per_page + 1
      i1 <- min(pg * per_page, n)
      page_specs <- specs[i0:i1]
      
      graphics::par(mfrow = c(2, 2), oma = c(1.1, 0, 3.2, 0))
      for (s in page_specs) {
        cs <- s$gen()
        render_fn <- s$render_fn %||% base_candlestick_plot
        render_fn(cs, caption = s$desc)
      }
      if (length(page_specs) < per_page) {
        for (k in seq_len(per_page - length(page_specs))) { graphics::plot.new() }
      }
      graphics::mtext(paste0(week_title, "  \u2014  ", section$title,
                              if (n_pages > 1) paste0("  (page ", pg, " of ", n_pages, ")") else ""),
                       outer = TRUE, cex = 1.0, font = 2, col = "#002C3C", line = 1)
      graphics::mtext(footer_text, outer = TRUE, cex = 0.55, col = "#888888", side = 1, line = 0)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# ══════════════════════════════════════════════════════════════════════════
# VOLUME PROFILE PRIMITIVES (Step 5) — built entirely from existing shapes/
# annotations machinery, so no new rendering path is needed. The profile is
# rendered as a ladder of horizontal bars right-docked inside the chart's own
# date range (bar length ∝ volume at that price), which both spec_to_plotly
# and base_candlestick_plot already know how to draw via `shapes`.
# ══════════════════════════════════════════════════════════════════════════

# Bins a df's High/Low/Volume into a volume-at-price profile. Each bar's volume
# is spread evenly across every bin its High-Low range touches (a standard
# volume-profile approximation when only OHLCV, not tick data, is available).
syn_volume_profile <- function(df, n_bins = 20, value_area_pct = 0.70) {
  rng <- range(c(df$Low, df$High), na.rm = TRUE)
  breaks <- seq(rng[1], rng[2], length.out = n_bins + 1)
  mids <- (breaks[-1] + breaks[-(n_bins + 1)]) / 2
  vols <- numeric(n_bins)
  for (i in seq_len(nrow(df))) {
    lo <- df$Low[i]; hi <- df$High[i]; v <- if (!is.null(df$Volume)) df$Volume[i] else 1
    if (is.na(v) || v <= 0) v <- 1
    idx <- which(breaks[-1] >= lo & breaks[-(n_bins + 1)] <= hi)
    if (length(idx) == 0) idx <- which.min(abs(mids - df$Close[i]))
    vols[idx] <- vols[idx] + v / length(idx)
  }
  poc_i <- which.max(vols)
  total <- sum(vols)
  lo_i <- poc_i; hi_i <- poc_i; covered <- vols[poc_i]
  while (covered < value_area_pct * total && (lo_i > 1 || hi_i < n_bins)) {
    down <- if (lo_i > 1) vols[lo_i - 1] else -1
    up   <- if (hi_i < n_bins) vols[hi_i + 1] else -1
    if (up >= down) { hi_i <- hi_i + 1; covered <- covered + up } else { lo_i <- lo_i - 1; covered <- covered + down }
  }
  hvn_thresh <- stats::quantile(vols[vols > 0], 0.8, names = FALSE)
  lvn_thresh <- stats::quantile(vols[vols > 0], 0.2, names = FALSE)
  list(mids = mids, vols = vols, poc = mids[poc_i], vah = mids[hi_i], val = mids[lo_i],
       hvn = mids[vols >= hvn_thresh], lvn = mids[vols > 0 & vols <= lvn_thresh])
}

# Converts a volume profile into a ladder of horizontal-bar shapes, docked to
# the right edge of df's date range (bars grow leftward from that edge).
syn_vp_shapes <- function(df, vp, max_width_frac = 0.16, color = "rgba(52,152,219,0.4)", width = 5) {
  n <- nrow(df)
  x_right <- df$Date[n]
  span_days <- as.numeric(df$Date[n] - df$Date[1])
  if (span_days <= 0) span_days <- n
  maxv <- max(vp$vols); if (maxv <= 0) maxv <- 1
  raw <- lapply(seq_along(vp$mids), function(i) {
    if (vp$vols[i] <= 0) return(NULL)
    w <- (vp$vols[i] / maxv) * max_width_frac * span_days
    syn_line(x_right - w, x_right, vp$mids[i], vp$mids[i], color, "solid", width)
  })
  Filter(Negate(is.null), raw)
}

syn_line <- function(x0, x1, y0, y1, color = "#f39c12", dash = "solid", width = 2) {
  list(type = "line", x0 = x0, x1 = x1, y0 = y0, y1 = y1,
       line = list(color = color, width = width, dash = dash))
}

syn_hline <- function(x0, x1, y, color = "#7f8c8d", dash = "dash", width = 1.5) {
  syn_line(x0, x1, y, y, color, dash, width)
}

syn_label <- function(x, y, text, color = "#002C3C", size = 11, ay = -20) {
  list(x = x, y = y, text = text, showarrow = TRUE, arrowhead = 2, arrowcolor = color,
       ax = 0, ay = ay, font = list(color = color, size = size),
       bgcolor = "rgba(255,255,255,0.85)", bordercolor = color, borderwidth = 1, borderpad = 3)
}

# Concatenates OHLC segments end-to-end, re-sequencing dates so each segment continues
# immediately after the previous one (segment 2+ don't need their own Date column set).
#
# CRITICAL: this re-sequencing means the Date column of every segment except the first
# is REWRITTEN here. Any shapes/annotations built by a caller using a segment's own
# pre-concat $Date value (e.g. `pat$Date[1]` for the 2nd+ segment passed in) will not
# match any date in the returned df — this was the root cause of orange boundary/target
# lines rendering across the full chart width (or off-screen) instead of over the
# correct zone. Use `syn_seg(df, i)` below to get the CORRECT, post-concat Date vector
# for the i-th segment passed to this call, and build all shapes/annotations from that.
syn_concat <- function(...) {
  segs <- list(...)
  if (length(segs) > 1) {
    for (i in 2:length(segs)) {
      segs[[i]]$Date <- seq(max(segs[[i - 1]]$Date) + 1, by = "day", length.out = nrow(segs[[i]]))
    }
  }
  out <- dplyr::bind_rows(segs)
  attr(out, "seg_dates") <- lapply(segs, function(s) s$Date)
  out
}

# Correct, post-concatenation Date vector for the i-th segment passed to syn_concat().
# Always use this (not the segment variable's own $Date) when placing shapes/annotations
# that reference a specific segment's position in a syn_concat()-built series.
syn_seg <- function(df, i) attr(df, "seg_dates")[[i]]

# Shared "breakout + hit/miss target" tail used across chart-pattern generators:
# drifts price from the breakout point toward (hit=TRUE) or short of (hit=FALSE) a
# measured-move target the given distance away in the given direction (+1 up, -1 down).
syn_outcome_tail <- function(breakout_price, direction, target_distance, hit, seed, n = 16) {
  target_price <- breakout_price + direction * target_distance
  frac <- if (hit) 1.15 else 0.45
  drift <- direction * (target_distance / n) * frac
  vol <- max(0.15, target_distance / n * 0.35)
  tail_df <- syn_path(n, start = breakout_price, drift = drift, vol = vol, seed = seed)
  list(df = tail_df, target_price = target_price)
}

syn_tag <- function(x, y, text, color, size = 12) {
  list(x = x, y = y, text = paste0("<b>", text, "</b>"), showarrow = FALSE, yanchor = "bottom",
       font = list(color = color, size = size), bgcolor = "rgba(255,255,255,0.9)",
       bordercolor = color, borderwidth = 1, borderpad = 3)
}

# ══════════════════════════════════════════════════════════════════════════
# GENERIC "SPEC LIST -> 2-PER-ROW GRID" RENDERER (shared by all 3 weeks)
# ══════════════════════════════════════════════════════════════════════════

# specs: list of list(id=, title=, desc=, gen=function())
weekly_grid_ui <- function(ns, specs, section_title = NULL) {
  boxes <- lapply(specs, function(s) {
    column(6,
      box(
        title = tags$span(s$title, style = paste0(
          "white-space:normal; overflow:visible; text-overflow:clip; ",
          "word-wrap:break-word; overflow-wrap:break-word; line-height:1.3; ",
          "display:inline-block; width:100%;"
        )),
        status = "primary", solidHeader = TRUE, width = 12,
        withSpinner(plotlyOutput(ns(s$id), height = "360px")),
        tags$p(s$desc, style = "font-size:11.5px; color:#666; margin-top:8px; line-height:1.5;")
      )
    )
  })
  # pair into rows of 2
  rows <- list()
  for (i in seq(1, length(boxes), by = 2)) {
    pair <- if (i + 1 <= length(boxes)) list(boxes[[i]], boxes[[i + 1]]) else list(boxes[[i]])
    rows[[length(rows) + 1]] <- do.call(fluidRow, pair)
  }
  tagList(
    if (!is.null(section_title)) tags$h4(section_title, style = paste0(
      "color:#ffffff; font-weight:700; margin:18px 0 10px 0; ",
      "text-shadow: 0 1px 3px rgba(0,0,0,0.35);"
    )),
    rows
  )
}

# Reusable "Download PDF" button + status line, placed once at the top of each week's tab.
weekly_download_ui <- function(ns) {
  fluidRow(
    box(
      width = 12, solidHeader = FALSE, status = "primary",
      div(style = "display:flex; align-items:center; gap:16px; flex-wrap:wrap;",
          downloadButton(ns("downloadPdf"), "Download All Visualisations (PDF)", class = "btn-primary"),
          tags$span("Exports every chart on this tab to a multi-page, print-ready A4 PDF (4 charts per page).",
                    style = "font-size:12px; color:#666;")
      )
    )
  )
}

weekly_grid_server <- function(output, specs) {
  for (s in specs) {
    local({
      spec <- s
      output[[spec$id]] <- renderPlotly({ spec_to_plotly(spec$gen()) })
    })
  }
}

# Wires up the shared "Download PDF" button against a week's full section list
# (list of list(title=, specs=list(list(id=,gen=,desc=), ...))).
weekly_download_server <- function(output, week_title, sections, filename_prefix) {
  output$downloadPdf <- downloadHandler(
    filename = function() paste0(filename_prefix, "_", format(Sys.Date(), "%Y%m%d"), ".pdf"),
    content = function(file) {
      export_weekly_pdf(file, week_title, sections)
    },
    contentType = "application/pdf"
  )
}
