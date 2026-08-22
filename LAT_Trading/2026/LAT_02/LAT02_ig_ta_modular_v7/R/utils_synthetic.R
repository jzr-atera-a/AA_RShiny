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
syn_chart <- function(df, title, shapes = list(), annotations = list(), yrange = NULL) {
  p <- plot_ly(df, x = ~Date, type = "candlestick", open = ~Open, high = ~High, low = ~Low, close = ~Close,
               increasing = list(line = list(color = "#27ae60")),
               decreasing = list(line = list(color = "#e74c3c")))
  p %>% layout(
    title = list(text = title, font = list(size = 13)),
    xaxis = list(title = "", rangeslider = list(visible = FALSE)),
    yaxis = list(title = "Price (simulated)", range = yrange),
    shapes = shapes, annotations = annotations,
    plot_bgcolor = "white", paper_bgcolor = "white",
    margin = list(t = 40)
  )
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
        title = s$title, status = "primary", solidHeader = TRUE, width = 12,
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
    if (!is.null(section_title)) tags$h4(section_title, style = "color:#002C3C; margin:18px 0 10px 0;"),
    rows
  )
}

weekly_grid_server <- function(output, specs) {
  for (s in specs) {
    local({
      spec <- s
      output[[spec$id]] <- renderPlotly({ spec$gen() })
    })
  }
}
