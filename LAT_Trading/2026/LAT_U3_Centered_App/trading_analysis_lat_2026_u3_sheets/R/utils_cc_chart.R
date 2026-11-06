# R/utils_cc_chart.R
# Chart of the "T Records C.C" tab (Market & Patterns): candles, EMAs and every pattern drawn ON the price
#   * the candles the pattern covers are shaded (start to end) in its bias colour;
#   * its shape (lines from the detector), markers on its first and last candle, and a label with name + status;
#   * the level that cancels it and its target, as named lines at the right-hand edge;
#   * indicator patterns (crosses, RSI, MACD...) get a marker on the candle where they happened, and the matching
#     indicator is shown in the lower panel (RSI, MACD, ADX/DI or Stochastic) with its threshold lines.
# Several patterns can be drawn at once; labels are staggered so they do not sit on top of each other.

cc_bias_col <- function(bias) switch(bias %||% "trend", bullish = "#16a34a", bearish = "#dc2626", "#7c3aed")
cc_alpha <- function(hex, a) { v <- grDevices::col2rgb(hex); sprintf("rgba(%d,%d,%d,%.2f)", v[1], v[2], v[3], a) }
cc_ind_for <- function(key) {   # the lower panel that shows the indicator behind a pattern
  if (grepl("^rsi|rsi_div", key)) "RSI" else if (grepl("macd", key)) "MACD" else if (grepl("^stoch", key)) "Stochastic" else if (grepl("adx|di_x|holy", key)) "ADX" else NA_character_ }

# cancel / target lines: every pattern when 3 or fewer are drawn; with more, only pattern 1 (else the right edge is unreadable)
cc_chart <- function(scan, picks = list(), title = NULL, panel = "auto", show_ma = TRUE, show_levels = TRUE) {
  ctx <- scan$ctx; s <- max(1L, scan$show_from); ix <- s:ctx$n; b <- ctx$b[ix, ]; d <- ctx$ind
  rng <- range(c(b$low, b$high)); pad <- diff(rng) * 0.08; rng0 <- rng; xr <- c(s - 1, ctx$n + max(8, round(0.12 * length(ix))))
  hover <- sprintf("%s UK<br>O %s  H %s<br>L %s  C %s", format(b$time, "%d/%m %H:%M", tz = "Europe/London"), signif(b$open, 7), signif(b$high, 7), signif(b$low, 7), signif(b$close, 7))
  p <- plotly::plot_ly(x = ix, type = "candlestick", open = b$open, high = b$high, low = b$low, close = b$close, text = hover, hoverinfo = "text", name = "Price",
                       increasing = list(line = list(color = "#16a34a")), decreasing = list(line = list(color = "#dc2626")), showlegend = FALSE)
  if (show_ma) for (m in list(c("ema20", "#2563eb", "EMA20"), c("ema50", "#f59e0b", "EMA50"), c("ema200", "#7c3aed", "EMA200"))) { v <- d[[m[1]]][ix]
    if (any(is.finite(v))) p <- plotly::add_lines(p, x = ix, y = v, name = m[3], line = list(color = m[2], width = 1.1), inherit = FALSE, hoverinfo = "skip") }
  shapes <- list(); ann <- list(); edge <- ctx$n + 1
  clip <- function(z) { z$x0c <- max(z$x0, s); z$y0c <- if (z$x1 == z$x0) z$y0 else z$y0 + (z$y1 - z$y0) * (z$x0c - z$x0) / (z$x1 - z$x0); z }
  for (k in seq_along(picks)) { o <- picks[[k]]; r <- cc_cat_row(o$key); col <- cc_bias_col(r$bias); i0 <- max(o$i0, s); i1 <- min(o$i1, ctx$n); num <- o$num %||% k
    if (i1 < s) next
    # 1. shaded span: from where the pattern's recent part starts to its last candle (a level touched long ago is
    #    drawn as a line from its first touch, but only its recent part is shaded), at most the last 60 candles
    sh0 <- max(i0, o$shade0 %||% i0, i1 - 60L, s); lo <- min(ctx$l[sh0:i1]); hi <- max(ctx$h[sh0:i1])
    shapes[[length(shapes) + 1]] <- list(type = "rect", xref = "x", yref = "y", x0 = sh0 - 0.5, x1 = i1 + 0.5, y0 = lo - 0.15 * ctx$a[i1], y1 = hi + 0.15 * ctx$a[i1],
                                         fillcolor = cc_alpha(col, 0.10), line = list(color = cc_alpha(col, 0.45), width = 1, dash = "dot"), layer = "below")
    # 2. its shape
    if (!is.null(o$lines) && nrow(o$lines)) for (j in seq_len(nrow(o$lines))) { z <- clip(o$lines[j, ]); if (z$x1 < s) next
      shapes[[length(shapes) + 1]] <- list(type = "line", xref = "x", yref = "y", x0 = z$x0c, x1 = z$x1, y0 = z$y0c, y1 = z$y1, line = list(color = col, dash = z$dash, width = 2.4)) }
    # 3. circles on its key candles (swing points, touches), and an arrow marker on its last candle
    up <- !identical(r$bias, "bearish"); mk_y <- function(i) if (up) ctx$l[i] - 0.35 * ctx$a[i] else ctx$h[i] + 0.35 * ctx$a[i]
    km <- unique(o$marks %||% integer(0)); km <- km[km >= s & km <= ctx$n]
    if (length(km)) { near_hi <- vapply(km, function(i) { ys <- if (!is.null(o$lines) && nrow(o$lines)) c(o$lines$y0, o$lines$y1, o$level) else o$level
        ys <- ys[is.finite(ys)]; if (!length(ys)) ctx$h[i] >= ctx$c[i] else abs(ctx$h[i] - ys[which.min(abs(ctx$h[i] - ys))]) <= abs(ctx$l[i] - ys[which.min(abs(ctx$l[i] - ys))]) }, TRUE)
      p <- plotly::add_markers(p, x = km, y = ifelse(near_hi, ctx$h[km], ctx$l[km]), inherit = FALSE, showlegend = FALSE, hoverinfo = "text", text = sprintf("%d. %s: key candle", num, r$label),
                               marker = list(symbol = "circle-open", size = 12, color = col, line = list(width = 2.4))) }
    mx <- i1; p <- plotly::add_markers(p, x = mx, y = vapply(mx, mk_y, 0), inherit = FALSE, showlegend = FALSE, hoverinfo = "text",
      text = sprintf("%s (%s)<br>%s", r$label, o$status, o$note), marker = list(symbol = if (up) "triangle-up" else if (identical(r$bias, "bearish")) "triangle-down" else "diamond", size = 11, color = col, line = list(color = "#ffffff", width = 1)))
    # 4. label
    # labels sit in two tidy columns (bearish above the price, bullish / neutral below), each with an arrow to its last candle
    side_k <- sum(vapply(picks[seq_len(k)], function(z) identical(cc_cat_row(z$key)$bias, "bearish") == !up, TRUE))
    step <- diff(rng0) / 11; ly <- if (up) rng0[1] + (side_k - 1) * step else rng0[2] - (side_k - 1) * step
    lx <- s + round(0.55 * (ctx$n - s)) - ((side_k - 1) %% 2) * round(0.22 * (ctx$n - s))
    ann[[length(ann) + 1]] <- list(x = i1, y = if (up) ctx$l[i1] else ctx$h[i1], xref = "x", yref = "y", axref = "x", ayref = "y", ax = lx, ay = ly,
      text = sprintf("<b>%d. %s</b> (%s)", num, r$label, o$status), showarrow = TRUE, arrowhead = 2, arrowsize = 0.8, arrowwidth = 1, arrowcolor = cc_alpha(col, 0.6),
      font = list(size = 11, color = col), bgcolor = "rgba(255,255,255,0.85)", bordercolor = col, borderwidth = 1)
    # 5. cancel / target lines, named at the right edge
    if (show_levels && (length(picks) <= 3 || k == 1)) for (lv in list(list(v = o$invalid, nm = "Cancels", c = "#b91c1c"), list(v = o$target, nm = "Target", c = "#15803d"))) { v <- as.numeric(lv$v %||% NA)
      if (!is.finite(v)) next
      shapes[[length(shapes) + 1]] <- list(type = "line", xref = "x", yref = "y", x0 = i0, x1 = xr[2], y0 = v, y1 = v, line = list(color = lv$c, dash = "dash", width = 1.4))
      ann[[length(ann) + 1]] <- list(x = xr[2], y = v, xref = "x", yref = "y", xanchor = "right", yanchor = "bottom", showarrow = FALSE,
        text = sprintf("%d %s %s%s", num, lv$nm, signif(v, 6), if (isTRUE(o$atr_default) && lv$nm == "Cancels") " (ATR)" else ""), font = list(size = 10, color = lv$c)) }
    rng <- range(c(rng, if (is.finite(o$invalid %||% NA)) o$invalid, if (is.finite(o$target %||% NA)) o$target))
  }
  # x axis: UK times on the candle index (no gaps for nights / weekends)
  tk <- unique(round(seq(s, ctx$n, length.out = min(9, length(ix)))))
  xa <- list(rangeslider = list(visible = FALSE), tickvals = tk, ticktext = format(ctx$b$time[tk], "%d/%m %H:%M", tz = "Europe/London"), range = xr, title = "")
  p <- plotly::layout(p, shapes = shapes, annotations = ann, xaxis = xa, yaxis = list(title = "Price", range = c(rng[1] - pad, rng[2] + pad)),
                      legend = list(orientation = "h", y = -0.06, x = 0, yanchor = "top"), margin = list(r = 20, t = 40, b = 40))
  # lower panel: the indicator behind the patterns (auto) or the one chosen
  if (identical(panel, "auto")) { w <- unique(stats::na.omit(vapply(picks, function(o) cc_ind_for(o$key), ""))); panel <- if (length(w)) w[1] else "RSI" }
  if (identical(panel, "none")) return(plotly::layout(p, title = list(text = title %||% "", font = list(size = 13), x = 0.01)))
  q <- plotly::plot_ly(); hl <- numeric(0)
  if (panel == "RSI") { q <- plotly::add_lines(q, x = ix, y = d$rsi[ix], name = "RSI(14)", line = list(color = "#7c3aed", width = 1.3)); hl <- c(30, 50, 70) }
  else if (panel == "MACD") { q <- plotly::add_bars(q, x = ix, y = d$macd_hist[ix], name = "Histogram", marker = list(color = ifelse(d$macd_hist[ix] >= 0, "#86efac", "#fca5a5")))
    q <- plotly::add_lines(q, x = ix, y = d$macd[ix], name = "MACD", line = list(color = "#2563eb", width = 1.3)); q <- plotly::add_lines(q, x = ix, y = d$macd_signal[ix], name = "Signal", line = list(color = "#f59e0b", width = 1.1)); hl <- 0 }
  else if (panel == "ADX") { q <- plotly::add_lines(q, x = ix, y = d$adx[ix], name = "ADX", line = list(color = "#111827", width = 1.5))
    q <- plotly::add_lines(q, x = ix, y = d$di_p[ix], name = "DI+", line = list(color = "#16a34a", width = 1)); q <- plotly::add_lines(q, x = ix, y = d$di_n[ix], name = "DI-", line = list(color = "#dc2626", width = 1)); hl <- c(ctx$adx_range, ctx$adx_trend) }
  else if (panel == "Stochastic") { q <- plotly::add_lines(q, x = ix, y = d$stoch_k[ix], name = "%K", line = list(color = "#2563eb", width = 1.3)); q <- plotly::add_lines(q, x = ix, y = d$stoch_d[ix], name = "%D", line = list(color = "#f59e0b", width = 1.1)); hl <- c(20, 80) }
  # markers in the lower panel on the candle of each indicator pattern
  for (k in seq_along(picks)) { o <- picks[[k]]; if (!identical(cc_ind_for(o$key), panel) || o$i1 < s) next
    yv <- switch(panel, RSI = d$rsi, MACD = d$macd, ADX = d$adx, Stochastic = d$stoch_k)[o$i1]
    if (is.finite(yv)) q <- plotly::add_markers(q, x = o$i1, y = yv, inherit = FALSE, showlegend = FALSE, marker = list(size = 10, color = cc_bias_col(cc_cat_row(o$key)$bias)), hoverinfo = "text", text = cc_cat_row(o$key)$label) }
  q <- plotly::layout(q, shapes = lapply(hl, function(v) list(type = "line", xref = "x", yref = "y", x0 = xr[1], x1 = xr[2], y0 = v, y1 = v, line = list(color = "#94a3b8", dash = "dot", width = 1))),
                      yaxis = list(title = panel), xaxis = xa)
  out <- plotly::subplot(p, q, nrows = 2, shareX = TRUE, heights = c(0.74, 0.26), titleY = TRUE, margin = 0.03)
  plotly::layout(out, title = list(text = title %||% "", font = list(size = 13), x = 0.01), xaxis = xa)
}

# ---- what is saved for a scan: enough to redraw it exactly and to analyse it later --------------------------------
cc_scan_payload <- function(scan, meta, settings, daily = NULL) {
  ctx <- scan$ctx; keep <- max(1L, scan$show_from - 260L):ctx$n   # shown candles + their indicator warm-up
  occ <- lapply(scan$current, function(o) { o$lines <- if (is.null(o$lines)) NULL else o$lines; o })
  list(version = 1L, meta = meta, settings = settings, regime = scan$regime, adx = scan$adx, tally = scan$tally[c("bull", "bear", "n_bull", "n_bear", "text")],
       show_from_time = format(ctx$b$time[scan$show_from], "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
       bars_all = list(t = format(ctx$b$time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), o = ctx$o, h = ctx$h, l = ctx$l, c = ctx$c),
       indicators_shown = cbind(time = format(ctx$b$time[keep], "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), as.data.frame(lapply(ctx$ind[keep, ], function(v) signif(v, 8)))),
       daily = if (is.null(daily) || !nrow(daily)) NULL else list(t = format(daily$time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), o = daily$open, h = daily$high, l = daily$low, c = daily$close),
       patterns = occ, stats = scan$stats)
}
# rebuild a scan from what was saved: the same candles + settings give the same patterns (the engine is deterministic)
cc_scan_restore <- function(bars_json, current_json = NULL) {
  j <- jsonlite::fromJSON(bars_json, simplifyVector = TRUE)
  if (is.null(j$bars_all)) stop("This scan was saved before full scans were kept: only its pattern list is available.")
  b <- data.frame(time = as.POSIXct(j$bars_all$t, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), open = j$bars_all$o, high = j$bars_all$h, low = j$bars_all$l, close = j$bars_all$c)
  st <- j$settings %||% list(); sf <- match(as.POSIXct(j$show_from_time, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), b$time); if (is.na(sf)) sf <- max(1L, nrow(b) - 192L)
  dl <- if (is.null(j$daily)) NULL else data.frame(time = as.POSIXct(j$daily$t, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), open = j$daily$o, high = j$daily$h, low = j$daily$l, close = j$daily$c)
  sc <- cc_scan(b, j$meta$mins %||% 15, st, daily = dl, show_from = sf)
  list(scan = sc, meta = j$meta, saved = j)
}
