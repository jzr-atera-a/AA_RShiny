# ---- module ----------------------------------------------
# id:           home_board
# name:         Pipeline board
# icon:         table-columns
# description:  Every programme as a card in the column of its stage (fit score, eligibility, blocked flags), plus a setup checklist for admins
# packages:     shiny, bslib
# -----------------------------------------------------------

home_board_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("setup")),
    uiOutput(ns("counts")),
    uiOutput(ns("board")))
}

home_board_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    progs <- reactive(ctx$programmes())
    # projects with a blocker in this week's or last week's update
    blocked <- reactive({
      w <- latest_by(ctx$table("weekly")(), c("email", "project_id", "week"))
      w <- w[nzchar(trimws(w$blockers)) & suppressWarnings(as.Date(w$week)) >= Sys.Date() - 13, , drop = FALSE]
      pr <- ctx$data$projects()
      unique(pr$programme_id[pr$project_id %in% w$project_id])
    })
    observeEvent(input$decide, {
      res <- tryCatch({ create_bid_decision(input$decide, ctx$user()); NULL }, error = function(e) safe_error_text(e))
      ctx$bump()
      if (!is.null(res)) return(showNotification(res, type = "error", duration = 10))
      showNotification("Bid decision opened in 4 Decide.", type = "message"); ctx$nav("decide", "decisions")
    })

    output$setup <- renderUI({
      req(ctx$is_admin())
      st <- store_status(); s <- ctx$settings()
      users <- nrow(get_users())
      steps <- list(
        list(ok = isTRUE(st$sheet_ok), txt = "Google Sheet connected (approved users and team tables)"),
        list(ok = isTRUE(st$bq_ok), txt = "BigQuery connected (full history)"),
        list(ok = nzchar(cfg$anthropic_key) || nzchar(session_key_get("anthropic")), txt = "Claude API key set"),
        list(ok = nzchar(trello_key()) && nzchar(trello_token()), txt = "Trello key and token set"),
        list(ok = smtp_ready(s), txt = "Email (SMTP) set up for outreach and reminders"),
        list(ok = nzchar(trimws(s$company_profile)), txt = "Company profile written (used by the eligibility check)"),
        list(ok = users > 1, txt = sprintf("Team added to the approved list (%d so far)", users)),
        list(ok = nrow(progs()) > 0, txt = "Programmes imported or added"))
      done <- sum(vapply(steps, `[[`, TRUE, "ok"))
      if (done == length(steps)) return(NULL)
      card(sprintf("Setup: %d of %d done", done, length(steps)),
           tags$ul(class = "checklist", lapply(steps, function(s)
             tags$li(class = if (s$ok) "done" else "", icon(if (s$ok) "circle-check" else "circle"), " ", s$txt))),
           p(class = "small muted", "Open Admin to finish setup. Only admins see this box."),
           class = "setup-card")
    })

    output$counts <- renderUI({
      p <- progs()
      n <- table(factor(p$stage, levels = STAGES))
      div(class = "stat-row",
          div(class = "stat", div(class = "stat-n", nrow(p)), div(class = "stat-l", "programmes")),
          div(class = "stat", div(class = "stat-n", sum(n[c("Qualify", "Team up", "Decide")])), div(class = "stat-l", "being assessed")),
          div(class = "stat", div(class = "stat-n", sum(n[c("Plan", "Write")])), div(class = "stat-l", "bids in progress")),
          div(class = "stat", div(class = "stat-n", n[["Deliver"]]), div(class = "stat-l", "projects running")))
    })

    output$board <- renderUI({
      p <- progs(); st <- ctx$status(); bl <- blocked(); partner <- ctx$is_partner()
      if (!nrow(p) && partner) return(card("No bids yet", p("You will see a bid here once the lead adds you to its consortium.")))
      if (!nrow(p)) return(card("No programmes yet",
        p("Programmes appear here as cards, one column per stage. ",
          "An admin can import the existing Funding Programmes and Grant Compass data in Admin > Data import, ",
          "or add a CSV in 1 Discover > Programmes.")))
      div(class = "board",
          lapply(STAGES, function(s) {
            rows <- p[p$stage == s, , drop = FALSE]
            rows <- rows[order(rows$closes_date == "", rows$closes_date), , drop = FALSE]
            div(class = "board-col",
                div(class = "board-h", span(s), span(class = "board-n", nrow(rows))),
                lapply(seq_len(min(nrow(rows), 12)), function(i) {
                  r <- rows[i, ]
                  el <- elig_status_of(r$programme_id, st$elig); fit <- st$fit$fit[st$fit$programme_id == r$programme_id]
                  div(class = paste("prog-card", if (el == "ineligible") "inelig"),
                      div(class = "pc-t", r$programme_name),
                      div(class = "pc-m", paste(c(r$funder, r$country)[nzchar(c(r$funder, r$country))], collapse = " - ")),
                      div(class = "pc-f",
                          if (nzchar(r$closes_date)) span(icon("calendar"), " ", r$closes_date)
                          else if (nzchar(r$deadline_text)) span(icon("calendar"), " ", substr(r$deadline_text, 1, 30)),
                          if (is_true(r$is_example)) example_badge()),
                      div(class = "pc-b", fit_badge(fit[1]), if (el == "ineligible") elig_badge(el),
                          if (r$programme_id %in% bl) span(class = "pill pill-flag", icon("flag"), " Blocked")),
                      if (!partner && s %in% c("Qualify", "Team up") && el != "ineligible")
                        div(class = "pc-act", tags$a(onclick = js_click(ns("decide"), r$programme_id), "Decide whether to bid")))
                }),
                if (nrow(rows) > 12) div(class = "small muted", sprintf("+ %d more", nrow(rows) - 12)))
          }))
    })
  })
}
