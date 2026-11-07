# R/utils_common.R
# Common Utility Functions - MTS Frontier AI Interview Prep
# (Carried over from MetaMLPrep v3.0 utils, plus two additions at the bottom)

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
  div(class = "tip-box", HTML(paste0("<strong>\U0001F4A1 Tip:</strong> ", text)))
}

# Render a warning
warn_box <- function(text) {
  div(class = "warn-box", HTML(paste0("<strong>\u26A0\uFE0F Watch out:</strong> ", text)))
}

# Render success box
success_box <- function(text) {
  div(class = "success-box", HTML(paste0("<strong>\u2705 Key point:</strong> ", text)))
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

# ── Added for MTS Frontier AI Prep ─────────────────────────────────────────

# A practice-prompt card, tagged (e.g. "Prompt 1", "Exercise-style").
# Clicking it sets `<module>-open_prompt` to prompt_id, which the module's
# server observes to show a detailed-answer modal. Click another card, or
# click outside the modal (easyClose), to dismiss/replace it.
scenario_card <- function(ns, prompt_id, tag, text) {
  div(class = "scenario-card", style = "cursor:pointer;",
      onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority:'event'})",
                         ns("open_prompt"), prompt_id),
      span(class = "scenario-tag", tag),
      div(text),
      div(style = "margin-top:8px;font-size:11px;font-weight:700;color:#0A66C2;letter-spacing:.04em;",
          "CLICK FOR A WORKED ANSWER \u2192")
  )
}

# Builds the detailed-answer modal using the 5-step Frame/Evidence/Mechanism/
# Tradeoffs/Decision structure used throughout this app.
answer_modal <- function(title_text, frame, evidence, mechanism, tradeoffs, decision) {
  modalDialog(
    title = title_text,
    size = "l",
    easyClose = TRUE,
    fade = TRUE,
    footer = modalButton("Close"),
    div(class = "framework-card", tags$h5("1. Frame"), tags$p(frame)),
    div(class = "framework-card", tags$h5("2. Evidence"), tags$p(evidence)),
    div(class = "framework-card", tags$h5("3. Mechanism"), tags$p(mechanism)),
    div(class = "framework-card", tags$h5("4. Tradeoffs"), tags$p(tradeoffs)),
    div(class = "success-box", tags$h5("5. Decision"), tags$p(decision))
  )
}

# A monospace "spec" / example block (annotation schema, eval spec, etc.)
spec_block <- function(text) {
  div(class = "spec-block", text)
}
