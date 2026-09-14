# R/utils_common.R
# Common Utility Functions - Compelling Communication @ Atera Analytics

`%||%` <- function(x, y) if (is.null(x)) y else x

# ── Badge pill ────────────────────────────────────────
badge <- function(text, colour = "#6b3fc8") {
  tags$span(
    style = paste0(
      "display:inline-block;background:", colour,
      ";color:white;border-radius:12px;padding:3px 11px;",
      "font-size:12px;font-weight:600;margin:2px;"
    ),
    text
  )
}

# ── Hero badge (used in chapter heroes) ──────────────
hero_badge <- function(icon_name, label) {
  span(class = "hero-badge", icon(icon_name), paste0(" ", label))
}

# ── Concept card (purple — theory) ───────────────────
concept_card <- function(title, body) {
  div(class = "concept-card",
      tags$h4(title),
      tags$p(HTML(body)))
}

# ── Application card (green — Atera use) ─────────────
app_card <- function(title, body) {
  div(class = "app-card",
      tags$h4(title),
      tags$p(HTML(body)))
}

# ── Table of contents item ────────────────────────────
toc_item <- function(num, text) {
  div(class = "toc-item",
      div(class = "toc-num", num),
      div(class = "toc-text", text))
}

# ── Before / After example pair ──────────────────────
example_pair <- function(bad_label  = "\u274c Before",
                          bad_text,
                          good_label = "\u2705 After",
                          good_text) {
  tagList(
    div(class = "example-bad",
        div(class = "example-label", bad_label),
        bad_text),
    div(class = "example-good",
        div(class = "example-label", good_label),
        good_text)
  )
}

# ── Quote block ───────────────────────────────────────
quote_block <- function(text, attrib = NULL) {
  div(class = "quote-block",
      HTML(text),
      if (!is.null(attrib)) div(class = "quote-attrib", paste0("- ", attrib)))
}

# ── Callout boxes ─────────────────────────────────────
tip_box <- function(...) {
  div(class = "tip-box",
      tags$strong("\U0001f4a1 Tip: "), ...)
}

success_box <- function(...) {
  div(class = "success-box",
      tags$strong("\u2705 Key point: "), ...)
}

warn_box <- function(...) {
  div(class = "warn-box",
      tags$strong("\u26a0\ufe0f Watch out: "), ...)
}

# ── Section headings ──────────────────────────────────
sh  <- function(text) div(class = "section-heading",       text)
shg <- function(text) div(class = "section-heading-green", text)

# ── Progress bar item ─────────────────────────────────
progress_bar_item <- function(label, pct) {
  div(class = "progress-wrap",
      div(class = "progress-label",
          span(label), span(paste0(pct, "%"))),
      div(class = "progress",
          div(class = "progress-bar", role = "progressbar",
              style = paste0("width:", pct, "%"),
              `aria-valuenow` = pct,
              `aria-valuemin` = 0,
              `aria-valuemax` = 100)))
}

# ── Metric card ───────────────────────────────────────
metric_card <- function(value, label) {
  div(class = "metric-card",
      span(class = "metric-value", value),
      span(class = "metric-label", label))
}

# ── Framework card (matches ZIP framework-card class) ─
framework_box <- function(title, content, icon_name = NULL) {
  div(class = "framework-card",
      tags$h5(if (!is.null(icon_name)) tagList(icon(icon_name), " ", title) else title),
      tags$p(HTML(content)))
}

# ── Timeline entry (matches ZIP timeline pattern) ─────
timeline_entry <- function(number, title, detail) {
  div(class = "timeline-item",
      div(class = "timeline-badge", number),
      div(class = "timeline-content",
          tags$h6(title),
          tags$p(detail)))
}
