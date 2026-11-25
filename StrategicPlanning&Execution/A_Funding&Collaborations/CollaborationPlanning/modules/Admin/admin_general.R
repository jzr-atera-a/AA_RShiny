# ---- module ----------------------------------------------
# id:           admin_general
# name:         General settings
# icon:         gear
# description:  Company profile, scoring weights and decision rules used by later phases
# packages:     shiny
# -----------------------------------------------------------

admin_general_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card("Company profile",
      p(class = "small muted", "Used by the eligibility check (phase 2): size, location, sector, stage, past grants."),
      textAreaInput(ns("profile"), NULL, rows = 5, width = "100%",
                    placeholder = "e.g. UK micro company in Cambridge, AI for energy and mobility, 2 Innovate UK grants won...")),
    card("Fit score weights",
      p(class = "small muted", "From Grant Compass: each person scores alignment, interest and capability from 1 to 5, ",
        "and these weights turn them into a 0 to 100 fit score."),
      layout_columns(col_widths = c(4, 4, 4),
        numericInput(ns("w_alignment"), "Alignment", 1.5, min = 0, max = 5, step = 0.5),
        numericInput(ns("w_interest"), "Interest", 1, min = 0, max = 5, step = 0.5),
        numericInput(ns("w_capability"), "Capability", 1.5, min = 0, max = 5, step = 0.5))),
    card("Decision rules",
      layout_columns(col_widths = c(4, 4, 4),
        numericInput(ns("decision_days"), "Days to weigh in", 3, min = 1, max = 30),
        checkboxInput(ns("blind_input"), "Hide others' views until you add yours", TRUE),
        checkboxInput(ns("silence_agrees"), "No objection by the deadline = recommendation stands", TRUE))),
    card("Programme checks",
      numericInput(ns("verify_days"), "Show \"check at source\" after this many days", 30, min = 1, max = 365)),
    actionButton(ns("save"), "Save settings", class = "btn-brand"))
}

admin_general_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    keys <- c("w_alignment", "w_interest", "w_capability", "decision_days", "verify_days")
    observe({
      s <- ctx$settings()
      updateTextAreaInput(session, "profile", value = s$company_profile)
      for (k in keys) updateNumericInput(session, k, value = suppressWarnings(as.numeric(s[[k]])))
      updateCheckboxInput(session, "blind_input", value = is_true(s$blind_input))
      updateCheckboxInput(session, "silence_agrees", value = is_true(s$silence_agrees))
    })
    observeEvent(input$save, {
      req(ctx$admin_ok())
      s <- ctx$settings()
      new <- c(list(company_profile = input$profile %||% ""),
               setNames(lapply(keys, function(k) as.character(input[[k]])), keys),
               list(blind_input = tolower(as.character(isTRUE(input$blind_input))),
                    silence_agrees = tolower(as.character(isTRUE(input$silence_agrees)))))
      changed <- 0
      for (k in names(new)) if (!identical(as.character(s[[k]]), new[[k]])) { set_setting(k, new[[k]], ctx$user()); changed <- changed + 1 }
      ctx$bump()
      showNotification(sprintf("Saved (%d change%s).", changed, if (changed == 1) "" else "s"), type = "message")
    })
  })
}
