# ---- module ----------------------------------------------
# id:           team_ranking
# name:         Team ranking
# icon:         ranking-star
# description:  Programmes ranked by average fit score, with stances, eligibility and closing dates
# packages:     shiny, DT
# -----------------------------------------------------------
# Ported from the ranking view of Grant Compass R/mod_prioritise.R.

team_ranking_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, checkboxInput(ns("all"), "Include programmes nobody has scored yet", FALSE), DTOutput(ns("rank"))),
    uiOutput(ns("actions")))
}

team_ranking_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    ranked <- reactive({
      p <- ctx$programmes(); p <- p[p$stage %in% c("Discover", "Qualify", "Team up", "Decide"), , drop = FALSE]
      st <- ctx$status(); f <- st$fit
      m <- match(p$programme_id, f$programme_id)
      d <- data.frame(programme_id = p$programme_id, Programme = p$programme_name, Funder = p$funder,
                      Fit = f$fit[m], Scorers = f$scorers[m] %||% 0, Lead = f$lead[m], Partner = f$partner[m],
                      Watch = f$watch[m], Pass = f$pass[m],
                      Eligibility = vapply(p$programme_id, elig_status_of, "", es = st$elig),
                      Closes = p$closes_date %|% "", Stage = p$stage, stringsAsFactors = FALSE)
      d$Closes <- ifelse(nzchar(p$closes_date), p$closes_date, ifelse(is_true_vec(p$rolling), "rolling", p$deadline_text))
      if (!isTRUE(input$all)) d <- d[!is.na(d$Fit), , drop = FALSE]
      d[order(-ifelse(is.na(d$Fit), -1, d$Fit)), , drop = FALSE]
    })
    output$rank <- renderDT({
      d <- ranked()
      datatable(d[, -1], rownames = FALSE, selection = "single", options = list(dom = "ftip", pageLength = 15, scrollX = TRUE)) |>
        formatStyle("Eligibility", color = styleEqual(c("ineligible", "eligible"), c("#d6336c", "#2f9e6e")), fontWeight = "bold")
    })
    sel <- reactive({ i <- input$rank_rows_selected; if (length(i)) ranked()[i, , drop = FALSE] else NULL })
    output$actions <- renderUI({
      r <- sel()
      if (is.null(r)) return(p(class = "small muted", "Select a programme to move it on or start the bid decision."))
      wants <- num(r$Lead) + num(r$Partner) > 0
      card(r$Programme,
        p(elig_badge(r$Eligibility), fit_badge(r$Fit), " ", r$Stage),
        if (!wants) note("info", "Nobody has chosen Lead or Partner yet, so it cannot move to Team up."),
        div(class = "btn-row",
          if (wants) actionButton(ns("to_teamup"), "Move to Team up", class = "btn-ghost", icon = icon("people-group")),
          actionButton(ns("decide"), "Decide whether to bid", class = "btn-brand", icon = icon("scale-balanced"))))
    })
    observeEvent(input$to_teamup, {
      r <- sel(); req(r)
      res <- move_programme_stage(r$programme_id, "Team up", ctx$user()); ctx$bump()
      showNotification(res$msg, type = if (res$ok) "message" else "error", duration = 8)
    })
    observeEvent(input$decide, {
      r <- sel(); req(r)
      res <- tryCatch({ create_bid_decision(r$programme_id, ctx$user()); NULL }, error = function(e) safe_error_text(e))
      ctx$bump()
      if (!is.null(res)) return(showNotification(res, type = "error", duration = 10))
      showNotification("Bid decision opened in 4 Decide.", type = "message"); ctx$nav("decide", "decisions")
    })
  })
}
