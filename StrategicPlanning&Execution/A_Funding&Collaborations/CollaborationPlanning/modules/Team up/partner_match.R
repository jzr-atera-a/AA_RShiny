# ---- module ----------------------------------------------
# id:           partner_match
# name:         Partner match
# icon:         handshake
# description:  Rank saved people by how well their interests and past projects fit a programme
# packages:     shiny, DT
# -----------------------------------------------------------
# Simple word overlap first (themes + conditions + summary against interests + past projects + role),
# with an optional Claude explanation for the top matches.

partner_match_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL,
      layout_columns(col_widths = c(8, 4),
        selectInput(ns("pid"), "Programme", NULL, width = "100%"),
        selectInput(ns("type"), "Who", c("Partners and contacts" = "pc", "Everyone" = "all")))),
    card("Best matches",
      p(class = "small muted", "Score = share of the programme's key words found in the person's interests, projects and role. ",
        "People already in this bid's consortium are marked."),
      DTOutput(ns("table")),
      div(class = "btn-row",
          actionButton(ns("add"), "Add selected to consortium", class = "btn-brand", icon = icon("user-plus")),
          actionButton(ns("explain"), "Explain the top 5 with Claude", class = "btn-ghost", icon = icon("robot")))),
    uiOutput(ns("why")))
}

partner_match_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observe({ ch <- programme_choices(ctx$programmes(), c("Qualify", "Team up", "Decide", "Plan", "Write"))
              updateSelectInput(session, "pid", choices = ch, selected = pick_sel(isolate(input$pid), ch)) })
    prog <- reactive({ p <- ctx$programmes(); p[p$programme_id == (input$pid %||% ""), , drop = FALSE] })
    scored <- reactive({
      r <- prog(); req(nrow(r) > 0)
      ppl <- ctx$data$people()
      if (identical(input$type, "pc")) ppl <- ppl[ppl$type %in% c("partner", "contact"), , drop = FALSE]
      if (!nrow(ppl)) return(NULL)
      pw <- key_words(c(r$themes, r$conditions, r$summary, r$programme_name))
      cons <- ctx$data$consortium(); inb <- cons$email[cons$programme_id == r$programme_id & cons$status != "declined"]
      hits <- lapply(seq_len(nrow(ppl)), function(i) intersect(pw, key_words(c(ppl$interests[i], ppl$past_projects[i], ppl$role_title[i], ppl$notes[i]))))
      ppl$score <- vapply(hits, function(h) if (length(pw)) round(100 * length(h) / length(pw)) else 0, 1)
      ppl$matched <- vapply(hits, function(h) paste(utils::head(h, 12), collapse = ", "), "")
      ppl$in_bid <- ifelse(ppl$email %in% inb & nzchar(ppl$email), "yes", "")
      ppl[order(-ppl$score), , drop = FALSE]
    })
    output$table <- renderDT({
      d <- scored(); req(d)
      out <- d[, c("name", "organisation", "type", "score", "matched", "in_bid")]
      names(out) <- c("Name", "Organisation", "Type", "Score", "Matching words", "In the bid")
      datatable(out, rownames = FALSE, selection = "multiple", options = list(dom = "tip", pageLength = 10, scrollX = TRUE))
    })
    observeEvent(input$add, {
      d <- scored(); i <- input$table_rows_selected
      if (!length(i)) return(showNotification("Select one or more people first.", type = "warning"))
      d <- d[i, , drop = FALSE]; d <- d[nzchar(d$email) & d$in_bid != "yes", , drop = FALSE]
      if (!nrow(d)) return(showNotification("Those people are already in the bid, or have no email.", type = "warning"))
      store_append("consortium", data.frame(programme_id = input$pid, email = d$email, role = "partner", status = "asked",
        budget_share_pct = "", documents_owed = "Letter of support", updated_at = now_ts(), documents_received = "",
        name = d$name, organisation = d$organisation, updated_by = ctx$user(), stringsAsFactors = FALSE), user = ctx$user())
      p <- prog(); if (p$stage %in% c("Discover", "Qualify")) move_programme_stage(input$pid, "Team up", ctx$user())
      ctx$bump(); showNotification(sprintf("Added %d to the consortium as asked.", nrow(d)), type = "message")
    })
    observeEvent(input$explain, {
      d <- scored(); req(d); r <- prog(); d <- utils::head(d[d$score > 0, , drop = FALSE], 5)
      if (!nrow(d)) return(output$why <- renderUI(note("info", "No matches to explain yet.")))
      if (!claude_ready()) return(output$why <- renderUI(note("bad", "No Claude API key is set.")))
      prompt <- paste0("Programme: ", r$programme_name, " (", r$funder, "). Themes: ", r$themes, ". Conditions: ", r$conditions,
        ".\n\nFor each person below, write one or two plain sentences on what they could bring to a bid, and one risk or gap. ",
        "Use only what is written here.\n\n",
        paste(sprintf("- %s, %s at %s. Interests: %s. Past projects: %s.", d$name, d$role_title, d$organisation, d$interests, d$past_projects), collapse = "\n"))
      res <- withProgress(message = "Asking Claude...", tryCatch(claude_call(prompt, max_tokens = 1500)$text, error = function(e) paste("Error:", safe_error_text(e))))
      output$why <- renderUI(card("Why these people", div(class = "mail-preview", res)))
    })
  })
}
