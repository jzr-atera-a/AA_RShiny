# ---- module ----------------------------------------------
# id:           go_no_go
# name:         Go/no-go tree
# icon:         sitemap
# description:  Expected value of bidding against not bidding, from a fixed decision tree
# packages:     shiny
# -----------------------------------------------------------
# Ported from BooksNetworks StrategySixS R/utils_decision_tree.R (expected value rolled back):
#   Bid (cost of writing, negative) -> chance node: Win (probability, value) / Lose (0);  Don't bid (0).

go_no_go_ui <- function(id) {
  ns <- NS(id)
  tagList(
    layout_columns(col_widths = c(5, 7),
      card("Inputs",
        selectInput(ns("pid"), "Programme", NULL, width = "100%"),
        numericInput(ns("cost"), "Cost of writing the bid (GBP: staff time, advisers)", 5000, min = 0, step = 500),
        sliderInput(ns("prob"), "Chance of winning (%)", 0, 100, 20, step = 1),
        numericInput(ns("value"), "Value to us if we win (GBP)", 0, min = 0, step = 1000),
        uiOutput(ns("value_help")),
        textAreaInput(ns("note"), "How we estimated these", rows = 2, width = "100%"),
        actionButton(ns("save"), "Save with the programme", class = "btn-brand")),
      card("Tree", uiOutput(ns("tree")))))
}

go_no_go_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    gn <- reactive(latest_by(ctx$table("gonogo")(), "programme_id"))
    observe({
      ch <- programme_choices(ctx$programmes(), c("Qualify", "Team up", "Decide"))
      updateSelectInput(session, "pid", choices = ch, selected = pick_sel(isolate(input$pid), ch))
    })
    prog <- reactive({ p <- ctx$programmes(); p[p$programme_id == (input$pid %||% ""), , drop = FALSE] })
    observeEvent(input$pid, {
      g <- gn(); g <- g[g$programme_id == input$pid, , drop = FALSE]; r <- prog()
      if (nrow(g)) {
        updateNumericInput(session, "cost", value = num(g$bid_cost_gbp)); updateSliderInput(session, "prob", value = num(g$win_prob_pct))
        updateNumericInput(session, "value", value = num(g$win_value_gbp)); updateTextAreaInput(session, "note", value = g$note)
      } else if (nrow(r)) updateNumericInput(session, "value", value = num(r$max_gbp))
    })
    output$value_help <- renderUI({
      r <- prog(); req(nrow(r) > 0)
      p(class = "small muted", "Pre-filled from the programme's maximum (", fmt_gbp(r$max_gbp), ")",
        if (nzchar(r$funding_rate_pct)) paste0(". It funds ", r$funding_rate_pct, "% of costs, so lower this if our own share or the work itself costs us more than it brings."),
        ".")
    })
    ev <- reactive(-num(input$cost) + num(input$prob) / 100 * num(input$value))
    output$tree <- renderUI({
      e <- ev(); best <- if (e > 0) "bid" else "no"
      be <- if (num(input$value) > 0) round(100 * num(input$cost) / num(input$value), 1) else NA
      div(class = "tree",
        div(class = "node", tags$b("Bid or not?")),
        tags$ul(
          tags$li(div(class = paste("node", if (best == "bid") "best"), "Bid: cost ", fmt_gbp(-num(input$cost)), ", expected value ", tags$b(fmt_gbp(e))),
            tags$ul(tags$li(div(class = "node chance", sprintf("Win (%s%%): %s", input$prob, fmt_gbp(num(input$value))))),
                    tags$li(div(class = "node chance", sprintf("Lose (%s%%): GBP 0", 100 - num(input$prob)))))),
          tags$li(div(class = paste("node", if (best == "no") "best"), "Don't bid: expected value GBP 0"))),
        note(if (e > 0) "ok" else "warn", if (e > 0) "Bidding has the higher expected value." else "Not bidding has the higher expected value.",
             if (!is.na(be)) paste0(" Bidding pays off when the chance of winning is above ", be, "%.")))
    })
    observeEvent(input$save, {
      req(input$pid)
      store_append("gonogo", data.frame(programme_id = input$pid, bid_cost_gbp = num(input$cost), win_prob_pct = num(input$prob),
        win_value_gbp = num(input$value), ev_bid_gbp = round(ev()), note = input$note %||% "", updated_by = ctx$user(),
        updated_at = now_ts(), stringsAsFactors = FALSE), user = ctx$user())
      ctx$bump(); showNotification("Saved. It will be added to the bid decision.", type = "message")
    })
  })
}
