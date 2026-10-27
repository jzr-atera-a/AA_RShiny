# R/utils_academic.R
# Shared UI-builder helpers for the "Unit Assignments" tabs (modules/unit1_assignment.R,
# unit2_assignment.R, unit3_assignment.R) and Unit 3 Live Signals' guidance section.
#
# IMPORTANT: every critical readability property (background, text color) is set as an
# INLINE style on each element, not left to the .ua-* classes in www/css/global.css.
# Inline styles cannot lose a CSS cascade/specificity fight to anything else on the page
# (short of another !important rule targeting the same property, which nothing here
# does) — this is deliberate, because these tabs render directly on the dashboard's dark
# gradient page background (.content-wrapper) rather than inside a shinydashboard box(),
# and relying on an external stylesheet class alone previously left the white background
# behind this text failing to render for reasons that weren't reproducible/diagnosable
# without a live browser. Inline styles remove that failure mode entirely. The .ua-*
# classes are kept alongside for non-critical cosmetics (box-shadow, hover transitions)
# that global.css still provides.

# Intro banner: unit title, module code/weighting/word count, and the official learning outcome.
ua_intro <- function(unit_label, module_title, weighting, word_count, learning_outcome) {
  tags$div(class = "ua-intro",
    style = "background: linear-gradient(135deg, #002C3C 0%, #008A82 100%); border-radius: 12px; padding: 18px 22px; margin-bottom: 16px; color: #ffffff;",
    tags$h3(style = "margin: 0 0 6px 0; font-size: 19px; font-weight: 800; color: #ffffff;",
            unit_label, ": ", module_title),
    tags$div(class = "ua-meta", style = "font-size: 12px; color: #d7f3f0;",
             paste0("Level 5 Diploma in Applied Financial Trading  \u00b7  Diploma Weighting: ", weighting,
                    "  \u00b7  Word Count Guideline: ", word_count)),
    tags$div(class = "ua-lo", style = "font-size: 13px; color: #eafffb; margin-top: 8px; line-height: 1.6;",
             tags$strong("Learning Outcome: "), learning_outcome)
  )
}

# One task section: number, title, marks, and arbitrary rich body content (tagList/tags$div etc).
ua_task <- function(task_no, title, marks, ...) {
  tags$div(class = "ua-task",
    style = "background: #ffffff; border: 1px solid #e2e8f0; border-left: 5px solid #008A82; border-radius: 10px; padding: 16px 20px; margin-bottom: 18px; box-shadow: 0 1px 4px rgba(0,44,60,0.06);",
    tags$div(class = "ua-task-head",
      style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; padding-bottom: 8px; border-bottom: 1px solid #e2e8f0;",
      tags$div(class = "ua-task-title", style = "font-size: 16px; font-weight: 800; color: #002C3C;",
               paste0("Task ", task_no, " \u2014 ", title)),
      tags$div(class = "ua-task-marks",
               style = "font-size: 11px; font-weight: 700; color: #008A82; background: rgba(0,138,130,0.1); border-radius: 20px; padding: 3px 12px; white-space: nowrap;",
               paste0(marks, " marks"))
    ),
    tags$div(class = "ua-task-body", style = "font-size: 13.5px; line-height: 1.75; color: #2c3e50;", ...)
  )
}

# A styled monospace formula block, e.g. ua_formula("Pivot Point (PP)", "PP = (H + L + C) / 3")
ua_formula <- function(label, ...) {
  tags$div(class = "ua-formula",
    style = "background: #002C3C; color: #7fe0e6; border-radius: 8px; padding: 12px 16px; margin: 10px 0; font-family: 'SFMono-Regular', Consolas, monospace; font-size: 13px; line-height: 1.8; overflow-x: auto;",
    tags$span(class = "ua-formula-label",
              style = "display: block; color: #8fd6ac; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px; font-family: inherit;",
              label),
    ...
  )
}

# A simple HTML table from a data.frame (character-friendly, no DT dependency needed for
# static reference tables — keeps these tabs lightweight).
ua_table <- function(df) {
  tags$table(class = "ua-table",
    style = "width: 100%; border-collapse: collapse; margin: 10px 0 14px 0; font-size: 12.5px; background: #ffffff;",
    tags$thead(tags$tr(lapply(names(df), function(n)
      tags$th(style = "background: #002C3C; color: #ffffff; padding: 8px 10px; text-align: left; font-weight: 700;", n)))),
    tags$tbody(lapply(seq_len(nrow(df)), function(i) {
      row_bg <- if (i %% 2 == 0) "#f6f8fb" else "#ffffff"
      tags$tr(lapply(df[i, ], function(cell)
        tags$td(style = paste0("padding: 7px 10px; border-bottom: 1px solid #e2e8f0; vertical-align: top; color: #2c3e50; background: ", row_bg, ";"),
                HTML(as.character(cell)))))
    }))
  )
}

# An amber callout box for caveats / "note" asides.
ua_callout <- function(...) {
  tags$div(class = "ua-callout",
    style = "background: #fff8ec; border: 1px solid #f0c674; border-left: 4px solid #e67e22; border-radius: 8px; padding: 10px 14px; margin: 10px 0; font-size: 12.5px; color: #5a3500; line-height: 1.6;",
    ...)
}

# One Harvard-style reference as a clickable card (opens the real source in a new tab).
# Harvard format: Author(s) (Year) Title. Source/Publisher. Available at: URL (Accessed: ...).
ua_ref <- function(citation_html, url) {
  tags$a(class = "ua-ref-card", href = url, target = "_blank", rel = "noopener noreferrer",
    style = "display: block; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px 14px; margin-bottom: 8px; text-decoration: none; color: #2c3e50; font-size: 12px; line-height: 1.55;",
    HTML(citation_html),
    tags$div(class = "ua-ref-link", style = "color: #008A82; font-size: 11px; word-break: break-all; margin-top: 4px;", url)
  )
}

# Wraps a list of ua_ref() cards in the References section shell.
ua_references <- function(...) {
  tags$div(class = "ua-refs", style = "background: #f6f8fb; border-radius: 10px; padding: 16px 20px; margin-top: 6px;",
    tags$h4(style = "color: #002C3C; font-size: 15px; font-weight: 800; margin-bottom: 4px;", "References (Harvard Style)"),
    tags$div(class = "ua-refs-sub", style = "font-size: 11.5px; color: #64748b; margin-bottom: 12px;",
             "Click any reference to open the original source."),
    ...
  )
}
