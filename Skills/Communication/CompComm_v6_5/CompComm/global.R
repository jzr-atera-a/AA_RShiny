# global.R — Compelling Communication: Simon Hall
# Minimal helpers — matching AlgorithmsToLiveBy pattern

library(shiny)
library(shinydashboard)

chapter_hero <- function(num, icon_emoji, title, subtitle, badges = character()) {
  badge_tags <- lapply(badges, function(b) span(class = "hero-badge", b))
  div(class = "chapter-hero",
      div(class = "hero-chapter-num", if (nzchar(as.character(num))) paste("Chapter", num) else "Cambridge University Press \u00b7 Simon Hall"),
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
      if (!is.null(source)) tags$p(class = "pq-source", HTML(paste0("\u2014 ", source))))
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

# Legacy aliases so old module function names still work
concept_card   <- function(title, body) fw(title, body)
app_card       <- function(title, body) fw(title, body)
sh             <- function(text) tags$p(style="font-size:11px;font-weight:800;color:#1a3a4a;text-transform:uppercase;letter-spacing:1.2px;border-bottom:2px solid #E8A020;padding-bottom:5px;margin:18px 0 10px;", text)
shg            <- function(text) tags$p(style="font-size:11px;font-weight:800;color:#1e5a5a;text-transform:uppercase;letter-spacing:1.2px;border-bottom:2px solid #27ae60;padding-bottom:5px;margin:18px 0 10px;", text)
metric_card    <- function(val, lbl) div(class="stat-card", span(class="stat-value", val), span(class="stat-label", lbl))
toc_item       <- function(num, text) div(style="display:flex;align-items:flex-start;padding:10px 14px;margin-bottom:6px;background:#f8fafc;border-radius:8px;border-left:4px solid #E8A020;", div(style="font-weight:800;color:#E8A020;margin-right:12px;min-width:20px;", num), div(style="font-size:13px;color:#2c3e50;", text))
example_pair   <- function(bad_label="\u274c Before", bad_text, good_label="\u2705 After", good_text) tagList(div(class="warn-box", tags$strong(bad_label), tags$br(), HTML(bad_text)), div(class="success-box", tags$strong(good_label), tags$br(), HTML(good_text)))
quote_block    <- function(text, attrib=NULL) pull_quote(text, attrib)
pct_bar        <- function(label, pct) div(class="pct-bar-wrap", div(class="pct-bar-label", span(label), span(paste0(pct,"%"))), div(class="pct-bar-track", div(class="pct-bar-fill", style=paste0("width:",pct,"%"))))
chapter_card   <- function(num, title, desc, tags_vec=NULL) div(class="chapter-card", div(class="ch-num", paste("Chapter",num)), div(class="ch-title", title), div(class="ch-desc", desc), if(!is.null(tags_vec)) div(class="ch-tags", lapply(tags_vec, function(t) span(class="topic-tag", t))))
hr_gold        <- function() tags$hr(style="border:none;border-top:1px solid #E8A020;opacity:.3;margin:18px 0;")
