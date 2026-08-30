# R/utils_common.R — AI Agents in Action Study Suite

`%||%` <- function(x, y) if (is.null(x)) y else x

# ── Badges ──────────────────────────────────────────────────────────
badge <- function(text, colour = "#7C3AED") {
  tags$span(
    style = paste0("display:inline-block;background:", colour,
                   ";color:white;border-radius:12px;padding:3px 11px;",
                   "font-size:12px;font-weight:600;margin:2px;"),
    text
  )
}

chapter_badge <- function(num) {
  tags$span(
    style = "display:inline-block;background:linear-gradient(135deg,#7C3AED,#A855F7);
             color:white;border-radius:8px;padding:2px 10px;font-size:11px;
             font-weight:700;margin:2px;font-family:'JetBrains Mono',monospace;",
    paste0("Ch.", num)
  )
}

status_badge <- function(text, status = "ok") {
  col <- switch(status,
    ok      = "#16a34a",
    warn    = "#d97706",
    danger  = "#dc2626",
    info    = "#2563eb",
    "#7C3AED"
  )
  tags$span(
    style = paste0("display:inline-block;background:", col,
                   ";color:white;border-radius:6px;padding:2px 10px;",
                   "font-size:11px;font-weight:700;margin:2px;"),
    text
  )
}

# ── Content boxes ────────────────────────────────────────────────────
tip_box <- function(text) {
  div(class = "tip-box", HTML(paste0("<strong>💡 Insight:</strong> ", text)))
}

warn_box <- function(text) {
  div(class = "warn-box", HTML(paste0("<strong>⚠️ Watch out:</strong> ", text)))
}

success_box <- function(text) {
  div(class = "success-box", HTML(paste0("<strong>✅ Key point:</strong> ", text)))
}

code_box <- function(text) {
  div(class = "code-box", HTML(text))
}

# ── Timeline ──────────────────────────────────────────────────────────
timeline_entry <- function(label, title, detail) {
  div(class = "timeline-item",
      div(class = "timeline-badge", label),
      div(class = "timeline-content",
          tags$h6(title),
          tags$p(detail)))
}

# ── Framework card ────────────────────────────────────────────────────
framework_card <- function(title, content, icon_name = NULL) {
  div(class = "framework-card",
      tags$h5(if (!is.null(icon_name)) tagList(icon(icon_name), " ", title) else title),
      tags$p(content))
}

# ── Chapter card ──────────────────────────────────────────────────────
chapter_card <- function(num, title, desc, tags_vec = character(0), status = NULL) {
  status_indicator <- if (!is.null(status)) {
    col <- switch(status, done = "#16a34a", partial = "#d97706", todo = "#94a3b8", "#94a3b8")
    div(style = paste0("position:absolute;top:10px;right:12px;width:10px;height:10px;
                        border-radius:50%;background:", col, ";"))
  }
  div(class = "chapter-card", style = "position:relative;",
      status_indicator,
      div(class = "chapter-num", num),
      div(class = "chapter-title", title),
      div(class = "chapter-desc", desc),
      if (length(tags_vec) > 0)
        div(class = "chapter-tags",
            lapply(tags_vec, function(t) span(class = "chapter-tag", t)))
  )
}

# ── API compatibility pill ─────────────────────────────────────────────
api_pill <- function(name, status, date = NULL) {
  col <- switch(status,
    alive    = "#16a34a",
    retiring = "#d97706",
    dead     = "#dc2626",
    "#94a3b8"
  )
  lbl <- switch(status, alive = "✓ Active", retiring = "⚠ Retiring", dead = "✗ Shutdown", "?")
  div(style = paste0("display:flex;align-items:center;gap:10px;padding:8px 14px;",
                     "background:#f8f9fa;border-left:4px solid ", col, ";",
                     "border-radius:0 8px 8px 0;margin:5px 0;"),
      tags$b(name, style = paste0("color:", col, ";min-width:180px;font-size:13px;")),
      tags$span(lbl, style = paste0("color:", col, ";font-size:11px;font-weight:700;")),
      if (!is.null(date)) tags$small(date, style = "color:#64748b;font-family:'JetBrains Mono',monospace;")
  )
}

# ── Progress colour helper ─────────────────────────────────────────────
progress_colour <- function(pct) {
  if (pct >= 80) "#16a34a"
  else if (pct >= 50) "#d97706"
  else "#dc2626"
}

# ── Comparison row ──────────────────────────────────────────────────────
compare_row <- function(dimension, old_val, new_val) {
  tags$tr(
    tags$td(tags$b(dimension)),
    tags$td(old_val, style = "color:#dc2626;"),
    tags$td(new_val, style = "color:#16a34a;font-weight:600;")
  )
}
