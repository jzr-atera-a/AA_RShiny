# ---- module ----------------------------------------------
# id:           budget
# name:         Budget by partner
# icon:         sterling-sign
# description:  Costs per partner and category, the grant at the funding rate, checked against the maximum and the agreed shares
# packages:     shiny, DT
# -----------------------------------------------------------
# Saved to budget (latest row per project + partner + category wins; amount 0 removes a line).

budget_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, selectInput(ns("proj"), "Project", NULL, width = "100%")),
    uiOutput(ns("checks")),
    layout_columns(col_widths = c(8, 4),
      card("Costs", DTOutput(ns("table"))),
      card("Add or change a line",
        selectizeInput(ns("partner"), "Partner", NULL, options = list(create = TRUE)),
        selectInput(ns("cat"), "Category", BUDGET_CATEGORIES),
        numericInput(ns("amt"), "Cost (GBP)", 0, min = 0, step = 500),
        numericInput(ns("rate"), "Funded (%)", 70, min = 0, max = 100),
        textInput(ns("note"), "Note", width = "100%"),
        actionButton(ns("save"), "Save line", class = "btn-brand"),
        p(class = "small muted", "Saving the same partner and category again replaces that line. A cost of 0 removes it."))),
    card("By partner", DTOutput(ns("by_partner"))))
}

budget_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    proj <- reactive({ pr <- ctx$data$projects(); pr[pr$project_id == (input$proj %||% ""), , drop = FALSE] })
    prog <- reactive({ r <- proj(); req(nrow(r) > 0); p <- ctx$programmes(); p[p$programme_id == r$programme_id, , drop = FALSE] })
    cons <- reactive({ r <- proj(); req(nrow(r) > 0); c <- ctx$data$consortium(); c[c$programme_id == r$programme_id & c$status != "declined", , drop = FALSE] })
    observe({
      c <- cons()
      org <- unique(c("Us (lead)", ifelse(nzchar(c$organisation), c$organisation, c$email)))
      updateSelectizeInput(session, "partner", choices = org, selected = pick_sel(isolate(input$partner), org))
      p <- prog(); if (nrow(p) && nzchar(p$funding_rate_pct)) updateNumericInput(session, "rate", value = num(p$funding_rate_pct))
    })
    lines <- reactive({
      b <- latest_by(ctx$table("budget")(), c("project_id", "partner", "category"))
      b <- b[b$project_id == (input$proj %||% "") & num(b$amount_gbp) > 0, , drop = FALSE]
      b$grant <- num(b$amount_gbp) * num(b$funded_pct) / 100; b
    })
    output$table <- renderDT({
      b <- lines()
      datatable(data.frame(Partner = b$partner, Category = b$category, Cost = num(b$amount_gbp), `Funded %` = b$funded_pct,
                           Grant = round(b$grant), Note = b$note, check.names = FALSE),
                rownames = FALSE, selection = "single", options = list(dom = "tip", pageLength = 15)) |>
        formatCurrency(c("Cost", "Grant"), currency = "GBP ", digits = 0)
    })
    observeEvent(input$table_rows_selected, { b <- lines()[input$table_rows_selected, , drop = FALSE]; req(nrow(b) > 0)
      updateSelectizeInput(session, "partner", selected = b$partner); updateSelectInput(session, "cat", selected = b$category)
      updateNumericInput(session, "amt", value = num(b$amount_gbp)); updateNumericInput(session, "rate", value = num(b$funded_pct))
      updateTextInput(session, "note", value = b$note) })
    observeEvent(input$save, {
      req(proj(), !ctx$is_partner(), input$partner)
      store_append("budget", data.frame(project_id = input$proj, partner = input$partner, category = input$cat, amount_gbp = num(input$amt),
        funded_pct = num(input$rate), note = input$note %||% "", updated_at = now_ts(), updated_by = ctx$user(), stringsAsFactors = FALSE), user = ctx$user())
      ctx$bump(); showNotification("Saved.", type = "message")
    })
    by_partner <- reactive({
      b <- lines(); if (!nrow(b)) return(NULL)
      ps <- unique(b$partner); tot <- sum(num(b$amount_gbp))
      c <- cons(); key <- ifelse(nzchar(c$organisation), c$organisation, c$email)
      data.frame(Partner = ps, Cost = vapply(ps, function(p) sum(num(b$amount_gbp[b$partner == p])), 1),
                 Grant = vapply(ps, function(p) round(sum(b$grant[b$partner == p])), 1),
                 `Share of costs %` = vapply(ps, function(p) round(100 * sum(num(b$amount_gbp[b$partner == p])) / tot, 1), 1),
                 `Agreed share %` = vapply(ps, function(p) { v <- c$budget_share_pct[key == p]; if (length(v)) v[1] else "" }, ""),
                 check.names = FALSE, row.names = NULL)
    })
    output$by_partner <- renderDT({ d <- by_partner(); req(d)
      datatable(d, rownames = FALSE, options = list(dom = "t", paging = FALSE)) |> formatCurrency(c("Cost", "Grant"), currency = "GBP ", digits = 0) })
    output$checks <- renderUI({
      if (!length(project_picker_choices(ctx))) return(project_empty_note())
      b <- lines(); req(nrow(b) > 0); p <- prog(); d <- by_partner()
      tot <- sum(num(b$amount_gbp)); grant <- sum(b$grant); mx <- num(p$max_gbp)
      off <- d[nzchar(d$`Agreed share %`) & abs(num(d$`Agreed share %`) - d$`Share of costs %`) > 2, , drop = FALSE]
      tagList(
        div(class = "stat-row",
          div(class = "stat", div(class = "stat-n", fmt_num(tot)), div(class = "stat-l", "total cost (GBP)")),
          div(class = "stat", div(class = "stat-n", fmt_num(grant)), div(class = "stat-l", "grant asked (GBP)")),
          div(class = "stat", div(class = "stat-n", fmt_num(tot - grant)), div(class = "stat-l", "our contribution (GBP)")),
          div(class = "stat", div(class = "stat-n", if (mx > 0) fmt_num(mx) else "-"), div(class = "stat-l", "programme maximum (GBP)"))),
        if (mx > 0 && grant > mx) note("bad", sprintf("The grant asked (%s) is above the programme maximum (%s).", fmt_gbp(grant), fmt_gbp(mx)))
        else if (mx > 0) note("ok", "The grant asked is within the programme maximum."),
        if (nrow(off)) note("warn", "Cost shares differ from the shares agreed in the consortium for: ", paste(off$Partner, collapse = ", "), "."))
    })
  })
}
