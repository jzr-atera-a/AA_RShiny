# ---- module ----------------------------------------------
# id:           team_scoring
# name:         Team scoring
# icon:         star-half-stroke
# description:  Each person scores alignment, interest and capability, and picks a stance
# packages:     shiny, DT
# -----------------------------------------------------------
# Ported from Grant Compass R/mod_prioritise.R. Fit score = calc_score() in R/collab.R.

team_scoring_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Score each programme from 1 (low) to 5 (high). Your fit score is worked out with the weights in Admin > General settings. ",
         "Saving again replaces your previous score."),
    layout_columns(col_widths = c(6, 6),
      card("Your score",
        selectInput(ns("pid"), "Programme", NULL, width = "100%"),
        uiOutput(ns("prog_info")),
        sliderInput(ns("a"), "Alignment with our strategy", 1, 5, 3, step = 1, width = "100%"),
        sliderInput(ns("i"), "Our interest", 1, 5, 3, step = 1, width = "100%"),
        sliderInput(ns("c"), "Our capability to deliver", 1, 5, 3, step = 1, width = "100%"),
        radioButtons(ns("stance"), "Your stance", c("Lead" = "lead", "Partner" = "partner", "Watch" = "watch", "Pass" = "pass"), inline = TRUE),
        textAreaInput(ns("note"), "Note", rows = 2, width = "100%"),
        div(class = "btn-row", actionButton(ns("save"), "Save score", class = "btn-brand"), uiOutput(ns("preview")))),
      card("Your scores so far", DTOutput(ns("mine")))))
}

team_scoring_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observe({
      ch <- programme_choices(ctx$programmes(), c("Discover", "Qualify", "Team up", "Decide"))
      updateSelectInput(session, "pid", choices = ch, selected = pick_sel(isolate(input$pid), ch))
    })
    mine <- reactive({
      p <- latest_by(ctx$data$priorities(), c("email", "programme_id"))
      p[tolower(p$email) == tolower(ctx$user()), , drop = FALSE]
    })
    # show my last score for the chosen programme
    observeEvent(input$pid, {
      m <- mine(); m <- m[m$programme_id == input$pid, , drop = FALSE]
      if (nrow(m)) {
        updateSliderInput(session, "a", value = num(m$alignment)); updateSliderInput(session, "i", value = num(m$interest))
        updateSliderInput(session, "c", value = num(m$capability)); updateRadioButtons(session, "stance", selected = m$stance)
        updateTextAreaInput(session, "note", value = m$note)
      }
    })
    output$prog_info <- renderUI({
      p <- ctx$programmes(); r <- p[p$programme_id == (input$pid %||% ""), , drop = FALSE]; req(nrow(r) > 0)
      p(class = "small muted", r$summary %|% r$themes, " ", elig_badge(elig_status_of(r$programme_id, ctx$status()$elig)))
    })
    output$preview <- renderUI(span(class = "big-n", calc_score(input$a, input$i, input$c, ctx$settings()), span(class = "small muted", " / 100 fit")))
    observeEvent(input$save, {
      req(input$pid)
      if (ctx$is_partner()) return(showNotification("Partners do not score programmes.", type = "warning"))
      store_append("priorities", data.frame(email = tolower(ctx$user()), programme_id = input$pid, alignment = input$a,
        interest = input$i, capability = input$c, stance = input$stance, note = input$note %||% "", updated_at = now_ts(),
        stringsAsFactors = FALSE), user = ctx$user())
      p <- ctx$programmes(); if (identical(p$stage[p$programme_id == input$pid][1], "Discover")) move_programme_stage(input$pid, "Qualify", ctx$user())
      ctx$bump(); showNotification("Score saved.", type = "message")
    })
    output$mine <- renderDT({
      m <- mine(); p <- ctx$programmes()
      m <- m[m$programme_id %in% p$programme_id, , drop = FALSE]
      d <- data.frame(Programme = p$programme_name[match(m$programme_id, p$programme_id)],
                      Fit = calc_score(m$alignment, m$interest, m$capability, ctx$settings()), Stance = m$stance, Saved = m$updated_at)
      datatable(d, rownames = FALSE, options = list(dom = "tip", pageLength = 8))
    })
  })
}
