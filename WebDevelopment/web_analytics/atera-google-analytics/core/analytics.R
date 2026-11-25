# core/analytics.R - period maths, comparisons, anomaly detection, forecast, insights

# ---- Date ranges -----------------------------------------------------------
resolve_range <- function(preset, custom = NULL, today = Sys.Date()) {
  end <- today - 1                               # yesterday = last complete day
  first_of_month <- as.Date(format(today, "%Y-%m-01"))
  rng <- switch(preset %||% "28",
    "7"  = c(end - 6, end),
    "28" = c(end - 27, end),
    "90" = c(end - 89, end),
    "mtd" = c(min(first_of_month, end), end),
    "lastmonth" = { last_end <- first_of_month - 1
                    c(as.Date(format(last_end, "%Y-%m-01")), last_end) },
    "ytd" = c(min(as.Date(format(today, "%Y-01-01")), end), end),
    "custom" = if (length(custom) == 2 && !anyNA(custom)) as.Date(custom) else c(end - 27, end),
    c(end - 27, end))
  if (rng[2] < rng[1]) rng <- rev(rng)
  rng
}

compare_range <- function(start, end, mode) {
  n <- as.integer(end - start) + 1
  switch(mode %||% "previous",
    previous = c(start - n, start - 1),
    year     = c(start - 364, end - 364),        # 52 weeks back: weekdays line up
    c(as.Date(NA), as.Date(NA)))
}

# ---- Small data helpers ----------------------------------------------------
totals_list <- function(df, mets) {
  out <- stats::setNames(as.list(rep(0, length(mets))), mets)
  if (!is.null(df) && nrow(df) > 0) {
    for (m in mets) if (!is.null(df[[m]]) && !is.na(df[[m]][1])) out[[m]] <- df[[m]][1]
  }
  out
}

pct_change <- function(cur, prev) {
  if (is.null(prev) || is.null(cur) || !is.finite(prev) || !is.finite(cur) || prev == 0) return(NA_real_)
  (cur - prev) / prev
}

complete_days <- function(df, start, end, value_cols) {
  out <- data.frame(date = seq(as.Date(start), as.Date(end), by = "day"))
  for (v in value_cols) {
    out[[v]] <- 0
    if (!is.null(df) && nrow(df) > 0 && !is.null(df[[v]])) {
      k <- match(out$date, df$date)
      out[[v]][!is.na(k)] <- df[[v]][k[!is.na(k)]]
    }
  }
  out
}

# Adds <metric>_chg columns (fractional change vs the comparison period).
with_prev <- function(cur, prev, by, mets) {
  if (is.null(cur)) return(NULL)
  for (m in mets) cur[[paste0(m, "_chg")]] <- rep(NA_real_, nrow(cur))
  if (is.null(prev) || nrow(prev) == 0 || nrow(cur) == 0) return(cur)
  kc <- do.call(paste, c(unname(as.list(cur[by])), sep = "\r"))
  kp <- do.call(paste, c(unname(as.list(prev[by])), sep = "\r"))
  idx <- match(kc, kp)
  for (m in mets) {
    pv <- prev[[m]][idx]
    cur[[paste0(m, "_chg")]] <- ifelse(is.na(pv) | pv == 0, NA_real_, (cur[[m]] - pv) / pv)
  }
  cur
}

# Keep the n biggest groups; fold the rest into "Other".
top_groups <- function(df, dim, metric, n = 5) {
  tot <- tapply(df[[metric]], df[[dim]], sum)
  tot <- sort(tot, decreasing = TRUE)
  names(tot)[seq_len(min(n, length(tot)))]
}

ma7 <- function(y) {
  if (length(y) < 7) return(rep(NA_real_, length(y)))
  as.numeric(stats::filter(y, rep(1 / 7, 7), sides = 1))
}

# ---- Anomaly detection -----------------------------------------------------
# Each day is compared with the median of the same weekday over the previous
# 8 weeks; flagged when it sits more than z_cut robust deviations away.
detect_anomalies <- function(dates, y, z_cut = 3.5, min_history = 14) {
  n <- length(y)
  res <- data.frame(date = dates, actual = y, expected = NA_real_, z = NA_real_, flag = FALSE)
  if (n < min_history + 1) return(res)
  wd <- as.POSIXlt(dates)$wday
  for (i in (min_history + 1):n) {
    hist_idx <- max(1, i - 56):(i - 1)
    same <- hist_idx[wd[hist_idx] == wd[i]]
    ref  <- if (length(same) >= 3) y[same] else y[hist_idx]
    med  <- stats::median(ref)
    scale <- max(stats::mad(ref), 0.1 * max(med, 1), 1)
    z <- (y[i] - med) / scale
    res$expected[i] <- med
    res$z[i] <- z
    res$flag[i] <- abs(z) >= z_cut
  }
  res
}

# ---- Forecast --------------------------------------------------------------
# Damped linear trend on weekday-adjusted values, re-seasonalised by weekday.
# Band = 80% range from how far the model missed in the recent past.
forecast_daily <- function(dates, y, h = 30) {
  n <- length(y)
  last <- if (n > 0) max(dates) else Sys.Date() - 1
  future <- seq(last + 1, by = "day", length.out = h)
  flat <- function(v) data.frame(date = future, forecast = rep(v, h), lower = rep(v, h), upper = rep(v, h))
  if (n == 0) return(flat(0))
  if (n < 14 || sum(y) <= 0) return(flat(mean(y)))

  wd <- as.POSIXlt(dates)$wday
  overall <- mean(y)
  fac <- rep(1, 7)
  for (d in 0:6) {
    v <- y[wd == d]
    if (length(v) >= 2) fac[d + 1] <- mean(v) / overall
  }
  fac[!is.finite(fac) | fac <= 0] <- 0.05
  adj <- y / fac[wd + 1]

  k   <- min(n, 84)
  fit_df <- data.frame(a = adj[(n - k + 1):n], t = (n - k + 1):n)
  fit <- stats::lm(a ~ t, data = fit_df)
  co  <- unname(stats::coef(fit))
  slope <- if (is.na(co[2])) 0 else co[2]
  level <- co[1] + slope * n
  sdv   <- stats::sd(stats::residuals(fit))
  if (!is.finite(sdv)) sdv <- 0

  steps <- seq_len(h)
  base  <- pmax(0, level + slope * cumsum(0.97 ^ steps))
  fwd   <- as.POSIXlt(future)$wday
  fc    <- base * fac[fwd + 1]
  band  <- 1.2816 * sdv * fac[fwd + 1] * sqrt(1 + steps / k)
  data.frame(date = future, forecast = fc, lower = pmax(0, fc - band), upper = fc + band)
}

# ---- Plain-English insights ------------------------------------------------
# Returns a list of list(kind = "good" | "bad" | "info", text = "...").
build_insights <- function(tot_cur, tot_prev, daily, channels = NULL, pages = NULL,
                           devices = NULL, compare_label = "the previous period") {
  out <- list()
  add <- function(kind, text) out[[length(out) + 1]] <<- list(kind = kind, text = text)
  has_prev <- !is.null(tot_prev)

  if (has_prev) {
    for (m in c("totalUsers", "keyEvents")) {
      ch <- pct_change(tot_cur[[m]], tot_prev[[m]])
      if (is.finite(ch) && abs(ch) >= 0.05) {
        add(if (ch > 0) "good" else "bad",
            sprintf("%s %s %s vs %s (%s, was %s).", metric_label(m),
                    if (ch > 0) "up" else "down", fmt_pct(abs(ch)), compare_label,
                    fmt_metric(tot_cur[[m]], m), fmt_metric(tot_prev[[m]], m)))
      }
    }
    d_er <- tot_cur$engagementRate - tot_prev$engagementRate
    if (is.finite(d_er) && abs(d_er) >= 0.03) {
      add(if (d_er > 0) "good" else "bad",
          sprintf("Engagement rate moved %s%.1f points to %s.", if (d_er > 0) "+" else "",
                  100 * d_er, fmt_pct(tot_cur$engagementRate)))
    }
  }

  if (!is.null(channels) && nrow(channels) > 0) {
    top <- channels[which.max(channels$sessions), ]
    add("info", sprintf("%s is the biggest channel: %s of sessions.",
                        top$sessionDefaultChannelGroup,
                        fmt_pct(top$sessions / max(1, sum(channels$sessions)))))
    if (!is.null(channels$sessions_chg)) {
      big <- channels[channels$sessions >= 0.05 * sum(channels$sessions) & !is.na(channels$sessions_chg), ]
      if (nrow(big) > 0) {
        up <- big[which.max(big$sessions_chg), ]; dn <- big[which.min(big$sessions_chg), ]
        if (up$sessions_chg >= 0.10) add("good", sprintf("%s sessions grew %s.",
                                         up$sessionDefaultChannelGroup, fmt_pct(up$sessions_chg)))
        if (dn$sessions_chg <= -0.10) add("bad", sprintf("%s sessions fell %s.",
                                          dn$sessionDefaultChannelGroup, fmt_pct(abs(dn$sessions_chg))))
      }
    }
    if (!is.null(channels$engagementRate) && nrow(channels) > 1) {
      ok <- channels[channels$sessions >= 0.05 * sum(channels$sessions), ]
      if (nrow(ok) > 1) {
        best <- ok[which.max(ok$engagementRate), ]
        add("info", sprintf("%s visitors are the most engaged (%s engagement rate).",
                            best$sessionDefaultChannelGroup, fmt_pct(best$engagementRate)))
      }
    }
  }

  if (!is.null(daily) && nrow(daily) >= 15) {
    an <- detect_anomalies(daily$date, daily$sessions)
    fl <- an[an$flag, ]
    if (nrow(fl) > 0) {
      worst <- fl[which.max(abs(fl$z)), ]
      add(if (worst$z > 0) "good" else "bad",
          sprintf("Unusual day: %s had %s sessions (about %s expected).",
                  format(worst$date, "%a %d %b"), fmt_int(worst$actual), fmt_int(worst$expected)))
    }
    wd <- tapply(daily$sessions, format(daily$date, "%A"), mean)
    add("info", sprintf("%s is the busiest weekday (%s sessions on average).",
                        names(wd)[which.max(wd)], fmt_int(max(wd))))
  }

  if (!is.null(pages) && nrow(pages) > 0) {
    add("info", sprintf("Most viewed page: %s (%s views).", pages$pagePath[1],
                        fmt_int(pages$screenPageViews[1])))
  }
  if (!is.null(devices) && nrow(devices) > 0) {
    mob <- sum(devices$sessions[devices$deviceCategory == "mobile"]) / max(1, sum(devices$sessions))
    add("info", sprintf("%s of sessions are on mobile.", fmt_pct(mob)))
  }
  if (length(out) == 0) add("info", "Not enough data in this period to say anything useful yet.")
  out
}

insights_ui <- function(items) {
  icon_for <- c(good = "arrow-up", bad = "arrow-down", info = "info-circle")
  shiny::tags$ul(class = "insights", lapply(items, function(it) {
    shiny::tags$li(class = it$kind, shiny::icon(icon_for[[it$kind]]), shiny::span(it$text))
  }))
}

# ---- Downloadable summary --------------------------------------------------
build_report_html <- function(title, period_label, kpis, insights, tables) {
  esc <- function(x) {
    x <- gsub("&", "&amp;", as.character(x), fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE)
    gsub(">", "&gt;", x, fixed = TRUE)
  }
  tbl_html <- function(df) {
    if (is.null(df) || nrow(df) == 0) return("<p>No data.</p>")
    head_html <- paste0("<tr>", paste0("<th>", esc(names(df)), "</th>", collapse = ""), "</tr>")
    body <- vapply(seq_len(nrow(df)), function(i) {
      paste0("<tr>", paste0("<td>", esc(unlist(lapply(df[i, , drop = FALSE], as.character))),
                            "</td>", collapse = ""), "</tr>")
    }, character(1))
    paste0("<table>", head_html, paste(body, collapse = ""), "</table>")
  }
  kpi_html <- paste0(vapply(kpis, function(k) {
    sprintf("<div class='k'><div class='l'>%s</div><div class='v'>%s</div><div class='d'>%s</div></div>",
            esc(k$label), esc(k$value), esc(k$delta))
  }, character(1)), collapse = "")
  ins_html <- paste0("<ul>", paste0("<li>", esc(vapply(insights, function(i) i$text, character(1))),
                                    "</li>", collapse = ""), "</ul>")
  tabs <- paste0(vapply(names(tables), function(n) {
    paste0("<h2>", esc(n), "</h2>", tbl_html(tables[[n]]))
  }, character(1)), collapse = "")
  paste0(
    "<!doctype html><html><head><meta charset='utf-8'><title>", esc(title), "</title><style>",
    "body{font-family:Segoe UI,Helvetica,Arial,sans-serif;color:#1b2540;max-width:900px;margin:32px auto;padding:0 16px}",
    "h1{margin-bottom:0}h2{margin-top:28px;font-size:18px}.p{color:#5b6785;margin-bottom:20px}",
    ".ks{display:flex;flex-wrap:wrap;gap:12px}.k{border:1px solid #d7deee;border-radius:8px;padding:12px 16px;min-width:150px}",
    ".l{font-size:12px;color:#5b6785}.v{font-size:24px;font-weight:600}.d{font-size:12px;color:#5b6785}",
    "table{border-collapse:collapse;width:100%;font-size:13px}th,td{text-align:left;padding:6px 8px;border-bottom:1px solid #e3e8f4}",
    "th{color:#5b6785;font-weight:600}</style></head><body>",
    "<h1>", esc(title), "</h1><div class='p'>", esc(period_label), "</div>",
    "<div class='ks'>", kpi_html, "</div><h2>What changed</h2>", ins_html, tabs,
    "<p class='p'>Generated ", format(Sys.time(), "%d %b %Y %H:%M"), "</p></body></html>")
}
