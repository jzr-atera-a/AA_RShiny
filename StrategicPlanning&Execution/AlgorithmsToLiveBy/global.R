# global.R — Algorithms to Live By
# Brian Christian & Tom Griffiths
# UI helpers only — no Python execution

library(shiny)
library(shinydashboard)

# ── Chapter hero banner ───────────────────────────────────────
chapter_hero <- function(num, icon_emoji, title, subtitle, badges = character()) {
  badge_tags <- lapply(badges, function(b) span(class = "hero-badge", b))
  div(class = "chapter-hero",
      div(class = "hero-chapter-num", paste("Chapter", num)),
      tags$h1(class = "hero-title", paste(icon_emoji, title)),
      tags$p(class = "hero-subtitle", subtitle),
      div(class = "badge-row", tagList(badge_tags)))
}

# ── 4-column stat cards ───────────────────────────────────────
stats_row <- function(...) {
  stats <- list(...)
  cols  <- lapply(stats, function(s) {
    column(3, div(class = "stat-card",
                  span(class = "stat-value", s[[1]]),
                  span(class = "stat-label", s[[2]])))
  })
  fluidRow(tagList(cols))
}

# ── Visual timeline / process strip ──────────────────────────
timeline_strip <- function(...) {
  items <- list(...)
  cells <- lapply(seq_along(items), function(i) {
    it <- items[[i]]
    tags$div(class = "tl-cell",
      tags$div(class = "tl-num", i),
      tags$div(class = "tl-label", it[[1]]),
      tags$div(class = "tl-desc", it[[2]])
    )
  })
  div(class = "timeline-strip", tagList(cells))
}

# ── Comparison table helper ───────────────────────────────────
algo_table <- function(headers, rows) {
  tags$table(class = "algo-table",
    tags$thead(tags$tr(lapply(headers, tags$th))),
    tags$tbody(lapply(rows, function(r) tags$tr(lapply(r, tags$td))))
  )
}

# ── Quote block ───────────────────────────────────────────────
pull_quote <- function(text, source = NULL) {
  div(class = "pull-quote",
      tags$p(class = "pq-text", HTML(paste0("\u201c", text, "\u201d"))),
      if (!is.null(source)) tags$p(class = "pq-source", HTML(paste0("\u2014 ", source))))
}

# ── Insight box ───────────────────────────────────────────────
insight_box <- function(title, ...) {
  div(class = "insight-box",
      tags$h5(class = "ib-title", title),
      ...)
}
