# ---- module ----------------------------------------------
# id:           decisions
# name:         Decisions
# icon:         gavel
# description:  Written decisions: options, a Driver and an Approver, everyone weighs in by a deadline, then the outcome is recorded
# packages:     shiny
# -----------------------------------------------------------
# Built to the Grant Compass mod_decisions.R design (linked_grant is programme_id here). Rules from settings:
#   blind_input    others' views stay hidden until you add yours
#   decision_days  days to weigh in
#   silence_agrees no objection by the deadline = the recommendation stands
# Recording Go on a bid decision moves the programme to Plan and creates a project; No go moves it to Learn.

decisions_ui <- function(id) {
  ns <- NS(id)
  layout_columns(col_widths = c(4, 8),
    tagList(
      card("Open decisions", uiOutput(ns("pick_ui"))),
      uiOutput(ns("new_box"))),
    uiOutput(ns("detail")))
}

decisions_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    opts <- ctx$table("decision_options")
    inputs <- reactive(latest_by(ctx$table("decision_inputs")(), c("decision_id", "email")))
    visible <- reactive({
      d <- ctx$data$decisions(); vis <- ctx$programmes()$programme_id
      if (ctx$is_partner()) d <- d[d$programme_id %in% vis, , drop = FALSE] else d <- d[!nzchar(d$programme_id) | d$programme_id %in% vis, , drop = FALSE]
      d[d$status == "open", , drop = FALSE][order(d$deadline[d$status == "open"]), , drop = FALSE]
    })
    want <- reactiveVal(NULL)   # a decision just created, to select it
    output$pick_ui <- renderUI({
      d <- visible()
      if (!nrow(d)) return(p(class = "small muted", "No open decisions. Closed ones are in the Decision log."))
      cur <- want() %||% isolate(input$pick)
      radioButtons(ns("pick"), NULL, setNames(d$decision_id, paste0(d$title, " (by ", d$deadline, ")")),
                   selected = if (isTRUE(cur %in% d$decision_id)) cur else d$decision_id[1])
    })
    dec <- reactive({ d <- visible(); d[d$decision_id == (input$pick %||% ""), , drop = FALSE] })

    output$detail <- renderUI({
      d <- dec(); req(nrow(d) > 0); s <- ctx$settings(); me <- tolower(ctx$user())
      o <- opts(); o <- o[o$decision_id == d$decision_id, , drop = FALSE]
      ins <- inputs(); ins <- ins[ins$decision_id == d$decision_id, , drop = FALSE]
      mine <- ins[tolower(ins$email) == me, , drop = FALSE]
      past <- isTRUE(as.Date(d$deadline) < Sys.Date())
      show_others <- !is_true(s$blind_input) || nrow(mine) > 0 || past
      objections <- sum(ins$stance == "object")
      can_record <- me %in% tolower(c(d$approver, d$driver)) || ctx$is_admin()
      p_name <- { p <- ctx$programmes(); p$programme_name[p$programme_id == d$programme_id][1] }
      tree <- if (nzchar(d$tree_inputs)) tryCatch(jsonlite::fromJSON(d$tree_inputs), error = function(e) NULL)
      tagList(
        card(d$title,
          p(class = "small muted", if (!is.na(p_name %||% NA)) paste0("Bid: ", p_name, ". "), "Driver: ", d$driver, ". Approver: ", d$approver,
            ". Weigh in by ", tags$b(d$deadline), "."),
          div(class = "mail-preview", d$context),
          if (!is.null(tree)) p(class = "small", "Go/no-go tree: expected value of bidding ", tags$b(fmt_gbp(tree$ev_bid_gbp)), " against GBP 0 for not bidding."),
          lapply(seq_len(nrow(o)), function(i) {
            oi <- ins[ins$option_id == o$option_id[i], , drop = FALSE]
            div(class = paste("opt-card", if (identical(o$option_id[i], d$recommended_option)) "rec"),
                tags$b(o$label[i]), if (identical(o$option_id[i], d$recommended_option)) span(class = "pill pill-fit", "Recommended"),
                if (nzchar(o$detail[i])) div(class = "small muted", o$detail[i]),
                if (show_others) div(class = "small",
                  sprintf("%d support, %d concern, %d object", sum(oi$stance == "support"), sum(oi$stance == "concern"), sum(oi$stance == "object"))))
          }),
          if (past && objections == 0 && is_true(s$silence_agrees) && nzchar(d$recommended_option))
            note("ok", "The deadline has passed with no objection, so the recommendation stands. The approver can record it.")
          else if (past) note("warn", "The deadline has passed. ", if (objections) sprintf("%d objection(s): this needs a conversation (see Meet by exception).", objections))),
        card("Your view",
          if (nrow(mine)) p(class = "small muted", "You said: ", span(class = paste0("stance-", mine$stance), mine$stance), " to ",
                            o$label[o$option_id == mine$option_id][1], ". You can change it."),
          layout_columns(col_widths = c(5, 7),
            radioButtons(ns("my_opt"), "Option", setNames(o$option_id, o$label), selected = if (nrow(mine)) mine$option_id else d$recommended_option %|% o$option_id[1]),
            radioButtons(ns("my_stance"), "Your stance", c("Support" = "support", "Concern" = "concern", "Object" = "object"),
                         selected = if (nrow(mine)) mine$stance else "support", inline = TRUE)),
          textAreaInput(ns("my_comment"), "Why (short)", value = if (nrow(mine)) mine$comment else "", rows = 2, width = "100%"),
          actionButton(ns("weigh_in"), "Save my view", class = "btn-brand")),
        card("Everyone's views",
          if (!show_others) note("info", "Views are hidden until you add yours, so everyone thinks for themselves.")
          else if (!nrow(ins)) p(class = "small muted", "No views yet.")
          else tags$table(class = "qs-table", tags$tbody(lapply(seq_len(nrow(ins)), function(i) tags$tr(
            tags$td(ins$email[i]), tags$td(o$label[o$option_id == ins$option_id[i]][1]),
            tags$td(span(class = paste0("stance-", ins$stance[i]), ins$stance[i])), tags$td(ins$comment[i])))))),
        if (can_record) card("Record the outcome (Driver, Approver or admin)",
          layout_columns(col_widths = c(4, 8),
            selectInput(ns("out_opt"), "Decision", setNames(o$option_id, o$label), selected = d$recommended_option %|% o$option_id[1]),
            textInput(ns("out_why"), "Rationale", width = "100%")),
          textInput(ns("out_revisit"), "Revisit if", width = "100%", placeholder = "e.g. the funder changes the deadline"),
          actionButton(ns("record"), "Record decision", class = "btn-brand", icon = icon("gavel"))))
    })

    observeEvent(input$weigh_in, {
      d <- dec(); req(nrow(d) > 0, input$my_opt)
      store_append("decision_inputs", data.frame(decision_id = d$decision_id, email = tolower(ctx$user()), option_id = input$my_opt,
        stance = input$my_stance, comment = input$my_comment %||% "", updated_at = now_ts(), stringsAsFactors = FALSE), user = ctx$user())
      ctx$bump(); showNotification("Your view is saved.", type = "message")
    })
    observeEvent(input$record, {
      d <- dec(); req(nrow(d) > 0, input$out_opt)
      if (!(tolower(ctx$user()) %in% tolower(c(d$approver, d$driver)) || ctx$is_admin())) return()
      msg <- tryCatch(record_decision_outcome(d$decision_id, input$out_opt, input$out_why, input$out_revisit, ctx$user()),
                      error = function(e) paste("Error:", safe_error_text(e)))
      ctx$bump(); showNotification(msg, type = "message", duration = 8)
    })

    # ---- new decision ----
    output$new_box <- renderUI({
      req(!ctx$is_partner())
      team <- get_users(); team <- team[team$role %in% c("admin", "member"), , drop = FALSE]
      card("New decision",
        textInput(ns("n_title"), "Question to decide", width = "100%", placeholder = "e.g. Which partner leads WP2?"),
        textAreaInput(ns("n_context"), "Background", rows = 3, width = "100%"),
        textAreaInput(ns("n_opts"), "Options (one per line)", rows = 3, width = "100%"),
        textInput(ns("n_rec"), "Recommended option (copy one line, optional)", width = "100%"),
        selectInput(ns("n_pid"), "Bid (optional)", programme_choices(ctx$programmes(), none = "(none)"), width = "100%"),
        selectInput(ns("n_driver"), "Driver", team$email, selected = ctx$user()),
        selectInput(ns("n_approver"), "Approver", team$email, selected = ctx$user()),
        actionButton(ns("create"), "Open for views", class = "btn-brand"))
    })
    observeEvent(input$create, {
      req(!ctx$is_partner())
      o <- trimws(strsplit(input$n_opts %||% "", "\n")[[1]]); o <- unique(o[nzchar(o)])
      if (blank(input$n_title) || length(o) < 2) return(showNotification("Add the question and at least two options.", type = "warning"))
      pid <- input$n_pid %||% ""
      cons <- if (nzchar(pid)) ctx$data$consortium() else NULL
      contrib <- if (!is.null(cons)) paste(cons$email[cons$programme_id == pid & cons$status != "declined"], collapse = ", ") else ""
      did <- create_decision(input$n_title, input$n_context %||% "", o, ctx$user(), programme_id = pid, driver = input$n_driver,
                             approver = input$n_approver, contributors = contrib, recommended = trimws(input$n_rec %||% ""))
      want(did); ctx$bump()
      for (f in c("n_title", "n_context", "n_opts", "n_rec")) updateTextInput(session, f, value = "")
      showNotification("Decision opened. Everyone can now add their view.", type = "message")
    })
  })
}
