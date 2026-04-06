# R/utils_common.R

`%||%` <- function(x, y) if (is.null(x)) y else x

progress_colour <- function(pct) {
  if (pct >= 80) "#10b981"
  else if (pct >= 50) "#f59e0b"
  else "#ef4444"
}

timeline_entry <- function(badge, title, detail) {
  div(class = "timeline-item",
      div(class = "timeline-badge", badge),
      div(class = "timeline-content",
          tags$h6(title),
          tags$p(detail)))
}

framework_card <- function(title, ...) {
  div(class = "framework-card",
      tags$h5(title),
      ...)
}

chapter_card <- function(num, title, desc, tags_vec = character(0)) {
  div(class = "chapter-card",
      div(class = "chapter-num", num),
      div(class = "chapter-title", title),
      div(class = "chapter-desc", desc),
      if (length(tags_vec))
        div(class = "chapter-tags",
            lapply(tags_vec, function(t) span(class = "chapter-tag", t))))
}
