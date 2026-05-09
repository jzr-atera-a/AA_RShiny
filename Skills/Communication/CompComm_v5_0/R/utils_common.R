# R/utils_common.R - helpers matching provided CSS classes

`%||%` <- function(x, y) if (is.null(x)) y else x

chapter_hero <- function(chapter_num, title, subtitle, badges = character(0)) {
  div(class = "chapter-hero",
      div(class = "hero-chapter-num", paste("Chapter", chapter_num)),
      div(class = "hero-title", title),
      div(class = "hero-subtitle", subtitle),
      div(class = "badge-row",
          lapply(badges, function(b) span(class = "hero-badge", b))))
}

stat_card <- function(value, label) {
  div(class = "stat-card",
      span(class = "stat-value", value),
      span(class = "stat-label", label))
}

framework_card <- function(title, body) {
  div(class = "framework-card",
      tags$h5(title),
      tags$p(HTML(body)))
}

insight_box <- function(title, body) {
  div(class = "insight-box",
      div(class = "ib-title", title),
      tags$p(HTML(body)))
}

pull_quote <- function(text, source = NULL) {
  div(class = "pull-quote",
      tags$p(class = "pq-text", HTML(text)),
      if (!is.null(source)) tags$p(class = "pq-source", paste0("\u2014 ", source)))
}

tip_box   <- function(...) div(class = "tip-box", ...)
success_box <- function(...) div(class = "success-box", ...)
warn_box  <- function(...) div(class = "warn-box", ...)
info_box  <- function(...) div(class = "info-box-plain", ...)

sh <- function(text) {
  tags$p(style="font-family:'Nunito',sans-serif;font-size:11px;font-weight:800;
    color:#1a3a4a;text-transform:uppercase;letter-spacing:1.2px;
    border-bottom:2px solid #E8A020;padding-bottom:5px;margin:18px 0 10px;", text)
}

shg <- function(text) {
  tags$p(style="font-family:'Nunito',sans-serif;font-size:11px;font-weight:800;
    color:#1e5a5a;text-transform:uppercase;letter-spacing:1.2px;
    border-bottom:2px solid #27ae60;padding-bottom:5px;margin:18px 0 10px;", text)
}

pct_bar <- function(label, pct) {
  div(class = "pct-bar-wrap",
      div(class = "pct-bar-label", span(label), span(paste0(pct, "%"))),
      div(class = "pct-bar-track",
          div(class = "pct-bar-fill", style = paste0("width:", pct, "%"))))
}

chapter_card <- function(num, title, desc, tags_vec = NULL) {
  div(class = "chapter-card",
      div(class = "ch-num", paste("Chapter", num)),
      div(class = "ch-title", title),
      div(class = "ch-desc", desc),
      if (!is.null(tags_vec))
        div(class = "ch-tags",
            lapply(tags_vec, function(t) span(class = "topic-tag", t))))
}

tl_cell <- function(num, label, desc) {
  div(class = "tl-cell",
      div(class = "tl-num", num),
      div(class = "tl-label", label),
      div(class = "tl-desc", desc))
}

algo_table <- function(headers, rows) {
  tags$table(class = "algo-table",
    tags$thead(tags$tr(lapply(headers, tags$th))),
    tags$tbody(lapply(rows, function(r) tags$tr(lapply(r, function(c) tags$td(HTML(c)))))))
}

example_pair <- function(bad_label="\u274c Before", bad_text,
                          good_label="\u2705 After",  good_text) {
  tagList(
    div(class="warn-box",  tags$strong(bad_label),  tags$br(), HTML(bad_text)),
    div(class="success-box", tags$strong(good_label), tags$br(), HTML(good_text)))
}

hr_gold <- function() tags$hr(style="border:none;border-top:1px solid #E8A020;opacity:.3;margin:18px 0;")
