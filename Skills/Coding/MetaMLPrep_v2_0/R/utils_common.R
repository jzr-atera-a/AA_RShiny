# R/utils_common.R
# Common Utility Functions - Meta ML Interview Prep

`%||%` <- function(x, y) if (is.null(x)) y else x

# Render a coloured badge pill
badge <- function(text, colour = "#1877F2") {
  tags$span(
    style = paste0(
      "display:inline-block;background:", colour,
      ";color:white;border-radius:12px;padding:3px 11px;",
      "font-size:12px;font-weight:600;margin:2px;"
    ),
    text
  )
}

# Render a framework box
framework_box <- function(title, content, icon_name = NULL) {
  div(class = "framework-card",
      h5(if (!is.null(icon_name)) tagList(icon(icon_name), " ", title) else title),
      p(content))
}

# Render a tip
tip_box <- function(text) {
  div(class = "tip-box", HTML(paste0("<strong>💡 Tip:</strong> ", text)))
}

# Render a warning
warn_box <- function(text) {
  div(class = "warn-box", HTML(paste0("<strong>⚠️ Watch out:</strong> ", text)))
}

# Render success box
success_box <- function(text) {
  div(class = "success-box", HTML(paste0("<strong>✅ Key point:</strong> ", text)))
}

# Progress pill colour
progress_colour <- function(pct) {
  if (pct >= 80) "#16a34a"
  else if (pct >= 50) "#d97706"
  else "#dc2626"
}

# Timeline entry helper
timeline_entry <- function(number, title, detail) {
  div(class = "timeline-item",
      div(class = "timeline-badge", number),
      div(class = "timeline-content",
          tags$h6(title),
          tags$p(detail)))
}
