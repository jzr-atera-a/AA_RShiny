# core/helpers.R - small shared helpers, formatting, theme colours, UI pieces

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# ---- Theme tokens (chart colours validated for colour-blind separation) ----
PAL     <- c("#00968c", "#e0712c", "#3b6fd8", "#c4407a",
             "#7a9a01", "#8a5cd6", "#b8860b", "#d64545")   # validated on white (colour-blind safe)
INK     <- "#22313f"
INK2    <- "#4a5a68"
MUTED   <- "#6b7a86"
GRID    <- "#e6ecec"
SURFACE <- "#ffffff"
LAND    <- "#eef3f3"
GOOD    <- "#1e7e4a"
BAD     <- "#b3261e"
SEQ_SCALE <- list(list(0, "#e3f3f1"), list(0.5, "#3fb0a6"), list(1, "#00524d"))

# ---- Metric dictionary: label + format + which direction is "good" ---------
METRICS <- list(
  totalUsers             = list(label = "Users",                fmt = "int", good = "up"),
  activeUsers            = list(label = "Active users",         fmt = "int", good = "up"),
  newUsers               = list(label = "New users",            fmt = "int", good = "up"),
  sessions               = list(label = "Sessions",             fmt = "int", good = "up"),
  engagedSessions        = list(label = "Engaged sessions",     fmt = "int", good = "up"),
  screenPageViews        = list(label = "Page views",           fmt = "int", good = "up"),
  eventCount             = list(label = "Events",               fmt = "int", good = "up"),
  keyEvents              = list(label = "Key events",           fmt = "int", good = "up"),
  engagementRate         = list(label = "Engagement rate",      fmt = "pct", good = "up"),
  bounceRate             = list(label = "Bounce rate",          fmt = "pct", good = "down"),
  averageSessionDuration = list(label = "Avg. session length",  fmt = "dur", good = "up"),
  userEngagementDuration = list(label = "Engagement time (s)",  fmt = "int", good = "up")
)

metric_label <- function(m) {
  vapply(m, function(x) (METRICS[[x]] %||% list(label = x))$label, character(1), USE.NAMES = FALSE)
}

# ---- Formatting ------------------------------------------------------------
fmt_int <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x)) return("-")
  formatC(round(x), format = "d", big.mark = ",")
}
fmt_pct <- function(x, digits = 1) {
  if (is.null(x) || length(x) == 0 || is.na(x)) return("-")
  paste0(formatC(100 * x, format = "f", digits = digits), "%")
}
fmt_dur <- function(sec) {
  if (is.null(sec) || length(sec) == 0 || is.na(sec)) return("-")
  sec <- round(sec)
  if (sec < 60) return(paste0(sec, "s"))
  paste0(sec %/% 60, "m ", formatC(sec %% 60, width = 2, flag = "0"), "s")
}
fmt_metric <- function(x, metric) {
  f <- (METRICS[[metric]] %||% list(fmt = "int"))$fmt
  switch(f, pct = fmt_pct(x), dur = fmt_dur(x), fmt_int(x))
}
fmt_int_vec <- function(x) vapply(x, fmt_int, character(1), USE.NAMES = FALSE)
fmt_pct_vec <- function(x) vapply(x, fmt_pct, character(1), USE.NAMES = FALSE)
trunc_lab <- function(s, n = 38) {
  s <- as.character(s)
  ifelse(nchar(s) > n, paste0(substr(s, 1, n - 1), "…"), s)
}

# Deterministic pseudo-noise in [0, 1) - used by the demo data so that the
# same date always produces the same numbers (period comparisons stay stable).
hnoise <- function(x) {
  v <- sin(x * 12.9898 + 78.233) * 43758.5453
  v - floor(v)
}
str_hash <- function(s) {
  vapply(as.character(s), function(z) {
    k <- utf8ToInt(z)
    if (length(k) == 0 || anyNA(k)) return(0)
    sum(k * seq_along(k)) %% 9973
  }, numeric(1), USE.NAMES = FALSE)
}

# ---- UI building blocks ----------------------------------------------------
card <- function(title = NULL, ..., sub = NULL, right = NULL) {
  shiny::div(class = "ga-card",
    if (!is.null(title) || !is.null(right))
      shiny::div(class = "ga-card-head",
        shiny::div(
          shiny::div(class = "ga-card-title", title),
          if (!is.null(sub)) shiny::div(class = "ga-card-sub", sub)
        ),
        if (!is.null(right)) shiny::div(class = "ga-card-tools", right)
      ),
    shiny::div(class = "ga-card-body", ...)
  )
}

kpi_tile <- function(label, value, delta = NULL, good_dir = "up", sub = NULL) {
  chip <- NULL
  if (!is.null(delta) && length(delta) == 1 && is.finite(delta)) {
    up   <- delta >= 0
    good <- (up && good_dir == "up") || (!up && good_dir == "down")
    cls  <- if (abs(delta) < 0.005) "flat" else if (good) "good" else "bad"
    chip <- shiny::span(class = paste("delta", cls),
                        if (up) "▲ " else "▼ ",
                        paste0(formatC(abs(delta) * 100, format = "f", digits = 1), "%"))
  }
  shiny::div(class = "kpi",
    shiny::div(class = "kpi-label", label),
    shiny::div(class = "kpi-value", value),
    shiny::div(class = "kpi-foot", chip, if (!is.null(sub)) shiny::span(class = "kpi-sub", sub))
  )
}

kpi_row <- function(...) shiny::div(class = "kpi-row", ...)

note_box <- function(..., kind = "info") shiny::div(class = paste("ga-note", kind), ...)

# ---- Plot helpers ----------------------------------------------------------
ga_layout <- function(p, xtitle = "", ytitle = "", legend = FALSE, hovermode = "x unified") {
  p <- plotly::layout(p,
    paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
    font = list(color = INK2, size = 12),
    margin = list(l = 8, r = 8, t = 8, b = 8),
    xaxis = list(title = xtitle, gridcolor = GRID, linecolor = GRID, zeroline = FALSE,
                 automargin = TRUE, tickfont = list(color = MUTED)),
    yaxis = list(title = ytitle, gridcolor = GRID, zeroline = FALSE, automargin = TRUE,
                 rangemode = "tozero", tickfont = list(color = MUTED)),
    showlegend = legend,
    legend = list(orientation = "h", x = 0, y = 1.14, font = list(color = INK2)),
    hoverlabel = list(bgcolor = "#ffffff", bordercolor = "#00968c", font = list(color = INK)),
    hovermode = hovermode
  )
  plotly::config(p, displayModeBar = FALSE)
}

bar_h <- function(labels, values, color = PAL[1], hover_fmt = ",.0f", xtitle = "") {
  labels <- trunc_lab(labels)
  p <- plotly::plot_ly(
    x = values, y = labels, type = "bar", orientation = "h",
    marker = list(color = color),
    hovertemplate = paste0("%{y}: %{x:", hover_fmt, "}<extra></extra>")
  )
  p <- ga_layout(p, xtitle = xtitle, hovermode = "closest")
  plotly::layout(p,
    yaxis = list(categoryorder = "array", categoryarray = rev(labels),
                 rangemode = "normal", gridcolor = "rgba(0,0,0,0)"),
    bargap = 0.35)
}

# One line per series; `series` is a named list of numeric vectors.
line_chart <- function(x, series, ytitle = "", yformat = NULL, dash = NULL) {
  p <- plotly::plot_ly()
  nm <- names(series)
  for (i in seq_along(series)) {
    p <- plotly::add_trace(p, x = x, y = series[[i]], name = nm[i],
      type = "scatter", mode = "lines",
      line = list(color = PAL[(i - 1) %% length(PAL) + 1], width = 2,
                  dash = if (is.null(dash)) "solid" else dash[i]))
  }
  p <- ga_layout(p, ytitle = ytitle, legend = length(series) > 1)
  if (!is.null(yformat)) {
    p <- plotly::layout(p, yaxis = list(tickformat = yformat, hoverformat = yformat))
  }
  p
}

# ---- Table helper ----------------------------------------------------------
ga_table <- function(df, labels = NULL, int = NULL, pct = NULL, dec = NULL, chg = NULL,
                     page = 10, search = TRUE) {
  cn   <- names(df)
  disp <- vapply(cn, function(n) if (!is.null(labels) && n %in% names(labels)) labels[[n]] else n,
                 character(1), USE.NAMES = FALSE)
  dt <- DT::datatable(df, rownames = FALSE, colnames = disp, class = "compact hover",
    options = list(pageLength = page, dom = if (search) "ftp" else "tp",
                   scrollX = TRUE, order = list()))
  int <- intersect(int, cn); pct <- intersect(pct, cn)
  dec <- intersect(dec, cn); chg <- intersect(chg, cn)
  if (length(int)) dt <- DT::formatRound(dt, int, 0)
  if (length(dec)) dt <- DT::formatRound(dt, dec, 2)
  if (length(pct)) dt <- DT::formatPercentage(dt, pct, 1)
  if (length(chg)) {
    dt <- DT::formatPercentage(dt, chg, 1)
    dt <- DT::formatStyle(dt, chg, color = DT::styleInterval(0, c(BAD, GOOD)))
  }
  dt
}

csv_handler <- function(data_fn, name) {
  shiny::downloadHandler(
    filename = function() paste0("atera_", name, "_", format(Sys.Date(), "%Y%m%d"), ".csv"),
    content  = function(file) {
      d <- data_fn()
      if (is.null(d)) d <- data.frame()
      utils::write.csv(d, file, row.names = FALSE)
    }
  )
}

dl_link <- function(id, label = "CSV") {
  shiny::downloadLink(id, label = shiny::tagList(shiny::icon("download"), label), class = "dl-link")
}
