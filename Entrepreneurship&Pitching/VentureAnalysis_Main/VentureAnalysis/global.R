# global.R - Venture Analysis by Atera Analytics
# Brad Feld & Jason Mendelson: Applied to DeepTech
# v1.0

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)

# ── UI Helper Functions ─────────────────────────────────────

chapter_hero <- function(num, icon_emoji, title, subtitle, badges = character()) {
  badge_tags <- lapply(badges, function(b) span(class = "hero-badge", b))
  div(class = "chapter-hero",
      div(class = "hero-chapter-num",
          if (nzchar(as.character(num))) paste("Chapter", num) else "Brad Feld & Jason Mendelson · Wiley"),
      tags$h1(class = "hero-title", paste(icon_emoji, title)),
      tags$p(class = "hero-subtitle", subtitle),
      div(class = "badge-row", tagList(badge_tags)))
}

stats_row <- function(...) {
  stats <- list(...)
  cols  <- lapply(stats, function(s) {
    column(3, div(class = "stat-card",
                  span(class = "stat-value", s[[1]]),
                  span(class = "stat-label", s[[2]])))
  })
  fluidRow(tagList(cols))
}

timeline_strip <- function(...) {
  items <- list(...)
  cells <- lapply(seq_along(items), function(i) {
    it <- items[[i]]
    tags$div(class = "tl-cell",
      tags$div(class = "tl-num",   i),
      tags$div(class = "tl-label", it[[1]]),
      tags$div(class = "tl-desc",  it[[2]]))
  })
  div(class = "timeline-strip", tagList(cells))
}

algo_table <- function(headers, rows) {
  tags$table(class = "algo-table",
    tags$thead(tags$tr(lapply(headers, tags$th))),
    tags$tbody(lapply(rows, function(r) tags$tr(lapply(r, tags$td)))))
}

pull_quote <- function(text, source = NULL) {
  div(class = "pull-quote",
      tags$p(class = "pq-text", HTML(paste0("\u201c", text, "\u201d"))),
      if (!is.null(source)) tags$p(class = "pq-source", HTML(paste0(": ", source))))
}

insight_box <- function(title, ...) {
  div(class = "insight-box",
      tags$h5(class = "ib-title", title),
      ...)
}

fw <- function(heading, body_html) {
  div(class = "framework-card",
      tags$h5(heading),
      tags$p(HTML(body_html)))
}

tip_box     <- function(...) div(class = "tip-box",        ...)
success_box <- function(...) div(class = "success-box",    ...)
warn_box    <- function(...) div(class = "warn-box",       ...)
info_box    <- function(...) div(class = "info-box-plain", ...)

metric_card  <- function(val, lbl) div(class = "stat-card", span(class = "stat-value", val), span(class = "stat-label", lbl))
sh           <- function(text) tags$p(style = "font-size:11px;font-weight:800;color:#00e5ff;text-transform:uppercase;letter-spacing:1.2px;border-bottom:2px solid #00bfff;padding-bottom:5px;margin:18px 0 10px;", text)
hr_blue      <- function() tags$hr(style = "border:none;border-top:1px solid rgba(0,191,255,0.25);margin:18px 0;")
toc_item     <- function(num, text) div(style = "display:flex;align-items:flex-start;padding:10px 14px;margin-bottom:6px;background:rgba(7,26,62,0.80);border-radius:8px;border-left:4px solid #00bfff;", div(style = "font-weight:800;color:#00bfff;margin-right:12px;min-width:22px;font-family:'JetBrains Mono',monospace;", num), div(style = "font-size:13px;color:#8fb0d8;", text))
pct_bar      <- function(label, pct, color = "#00e5ff") div(class = "pct-bar-wrap", div(class = "pct-bar-label", span(label), span(paste0(pct, "%"))), div(class = "pct-bar-track", div(class = "pct-bar-fill", style = paste0("width:", pct, "%;background:", color))))
chapter_card <- function(num, title, desc, tags_vec = NULL) div(class = "chapter-card", div(class = "ch-num", paste("Chapter", num)), div(class = "ch-title", title), div(class = "ch-desc", desc), if (!is.null(tags_vec)) div(class = "ch-tags", lapply(tags_vec, function(t) span(class = "topic-tag", t))))
quote_block  <- function(text, attrib = NULL) pull_quote(text, attrib)
mc_stat      <- function(val, lbl) div(class = "mc-stat", div(class = "mc-val", val), div(class = "mc-lbl", lbl))

# ── Plotly dark theme ───────────────────────────────────────
dt_theme <- function(p) {
  p %>% layout(
    paper_bgcolor = "rgba(4,13,33,0)",
    plot_bgcolor  = "rgba(4,13,33,0)",
    font          = list(color = "#8fb0d8", family = "Inter"),
    xaxis = list(gridcolor = "rgba(0,191,255,0.10)", zerolinecolor = "rgba(0,191,255,0.15)", color = "#7aa8e0"),
    yaxis = list(gridcolor = "rgba(0,191,255,0.10)", zerolinecolor = "rgba(0,191,255,0.15)", color = "#7aa8e0"),
    legend = list(bgcolor = "rgba(7,26,62,0.80)", bordercolor = "rgba(0,191,255,0.20)", borderwidth = 1, font = list(color = "#adc8ff"))
  )
}

DT_style <- function(dt) {
  dt %>%
    DT::formatStyle(columns = seq_len(ncol(dt$x$data)),
                    backgroundColor = "rgba(7,26,62,0.60)",
                    color = "#8fb0d8")
}

`%||%` <- function(x, y) if (is.null(x)) y else x
