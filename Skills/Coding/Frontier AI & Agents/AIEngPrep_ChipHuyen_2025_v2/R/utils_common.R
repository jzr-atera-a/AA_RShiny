# R/utils_common.R

`%||%` <- function(x, y) if (is.null(x)) y else x

badge <- function(text, colour = "#1877F2") {
  tags$span(
    style = paste0("display:inline-block;background:", colour,
                   ";color:white;border-radius:12px;padding:3px 11px;",
                   "font-size:12px;font-weight:600;margin:2px;"),
    text
  )
}

framework_box <- function(title, content, icon_name = NULL) {
  div(class = "framework-card",
      h5(if (!is.null(icon_name)) tagList(icon(icon_name), " ", title) else title),
      p(content))
}

tip_box <- function(text) {
  div(class = "tip-box", HTML(paste0("<strong>💡 Tip:</strong> ", text)))
}

warn_box <- function(text) {
  div(class = "warn-box", HTML(paste0("<strong>⚠️ Watch out:</strong> ", text)))
}

success_box <- function(text) {
  div(class = "success-box", HTML(paste0("<strong>✅ Key point:</strong> ", text)))
}

jobfit_box <- function(text, tags_vec = character(0)) {
  div(class = "jobfit-box",
      HTML(paste0("<strong>🎯 A1 job-fit:</strong> ", text)),
      if (length(tags_vec) > 0)
        div(style = "margin-top:8px;",
            lapply(tags_vec, function(t) span(class = "jf-tag", t)))
  )
}

progress_colour <- function(pct) {
  if (pct >= 80) "#16a34a"
  else if (pct >= 50) "#d97706"
  else "#dc2626"
}

timeline_entry <- function(number, title, detail) {
  div(class = "timeline-item",
      div(class = "timeline-badge", number),
      div(class = "timeline-content",
          tags$h6(title),
          tags$p(detail)))
}

chapter_card <- function(num, title, desc, tags_vec = character(0)) {
  div(class = "chapter-card",
      div(class = "chapter-num", num),
      div(class = "chapter-title", title),
      div(class = "chapter-desc", desc),
      if (length(tags_vec) > 0)
        div(class = "chapter-tags",
            lapply(tags_vec, function(t) span(class = "chapter-tag", t)))
  )
}
