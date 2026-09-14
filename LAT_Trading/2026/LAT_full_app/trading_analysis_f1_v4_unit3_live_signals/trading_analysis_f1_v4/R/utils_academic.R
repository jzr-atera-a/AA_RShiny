# R/utils_academic.R
# Shared UI-builder helpers for the "Unit Assignments" tabs (modules/unit1_assignment.R,
# unit2_assignment.R, unit3_assignment.R). Kept separate from R/utils_synthetic.R (which is
# the candlestick/chart-spec engine) since these are plain HTML-builders with no chart logic.

# Intro banner: unit title, module code/weighting/word count, and the official learning outcome.
ua_intro <- function(unit_label, module_title, weighting, word_count, learning_outcome) {
  tags$div(class = "ua-intro",
    tags$h3(unit_label, ": ", module_title),
    tags$div(class = "ua-meta",
             paste0("Level 5 Diploma in Applied Financial Trading  \u00b7  Diploma Weighting: ", weighting,
                    "  \u00b7  Word Count Guideline: ", word_count)),
    tags$div(class = "ua-lo", tags$strong("Learning Outcome: "), learning_outcome)
  )
}

# One task section: number, title, marks, and arbitrary rich body content (tagList/tags$div etc).
ua_task <- function(task_no, title, marks, ...) {
  tags$div(class = "ua-task",
    tags$div(class = "ua-task-head",
      tags$div(class = "ua-task-title", paste0("Task ", task_no, " \u2014 ", title)),
      tags$div(class = "ua-task-marks", paste0(marks, " marks"))
    ),
    tags$div(class = "ua-task-body", ...)
  )
}

# A styled monospace formula block, e.g. ua_formula("Pivot Point (PP)", "PP = (H + L + C) / 3")
ua_formula <- function(label, ...) {
  tags$div(class = "ua-formula",
    tags$span(class = "ua-formula-label", label),
    ...
  )
}

# A simple HTML table from a data.frame (character-friendly, no DT dependency needed for
# static reference tables — keeps these tabs lightweight).
ua_table <- function(df) {
  tags$table(class = "ua-table",
    tags$thead(tags$tr(lapply(names(df), function(n) tags$th(n)))),
    tags$tbody(lapply(seq_len(nrow(df)), function(i) {
      tags$tr(lapply(df[i, ], function(cell) tags$td(HTML(as.character(cell)))))
    }))
  )
}

# An amber callout box for caveats / "note" asides.
ua_callout <- function(...) tags$div(class = "ua-callout", ...)

# One Harvard-style reference as a clickable card (opens the real source in a new tab).
# Harvard format: Author(s) (Year) Title. Source/Publisher. Available at: URL (Accessed: ...).
ua_ref <- function(citation_html, url) {
  tags$a(class = "ua-ref-card", href = url, target = "_blank", rel = "noopener noreferrer",
    HTML(citation_html),
    tags$div(class = "ua-ref-link", url)
  )
}

# Wraps a list of ua_ref() cards in the References section shell.
ua_references <- function(...) {
  tags$div(class = "ua-refs",
    tags$h4("References (Harvard Style)"),
    tags$div(class = "ua-refs-sub", "Click any reference to open the original source."),
    ...
  )
}
