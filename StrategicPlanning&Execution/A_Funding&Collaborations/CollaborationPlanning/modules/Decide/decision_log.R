# ---- module ----------------------------------------------
# id:           decision_log
# name:         Decision log
# icon:         book
# description:  Every recorded decision with its outcome, rationale and when to revisit it
# packages:     shiny, DT
# -----------------------------------------------------------
# Built to the Grant Compass mod_declog.R design.

decision_log_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, DTOutput(ns("table")), downloadButton(ns("dl"), "Download the log (CSV)", class = "btn-ghost sm")),
    uiOutput(ns("detail")))
}

decision_log_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    log_df <- reactive({
      d <- ctx$data$decisions(); vis <- ctx$programmes()
      d <- d[d$status == "decided", , drop = FALSE]
      d <- if (ctx$is_partner()) d[d$programme_id %in% vis$programme_id, , drop = FALSE] else d[!nzchar(d$programme_id) | d$programme_id %in% vis$programme_id, , drop = FALSE]
      o <- ctx$table("decision_options")()
      d$Outcome <- o$label[match(d$outcome_option, o$option_id)]
      d$Bid <- vis$programme_name[match(d$programme_id, vis$programme_id)]
      d[order(d$decided_at, decreasing = TRUE), , drop = FALSE]
    })
    output$table <- renderDT({
      d <- log_df()
      out <- data.frame(Decided = substr(d$decided_at, 1, 10), Question = d$title, Outcome = d$Outcome, Bid = d$Bid %||% "",
                        Rationale = d$outcome_rationale, `Revisit if` = d$revisit_if, `Decided by` = d$decided_by, check.names = FALSE)
      datatable(out, rownames = FALSE, selection = "single", options = list(dom = "ftip", pageLength = 15, scrollX = TRUE))
    })
    output$detail <- renderUI({
      i <- input$table_rows_selected; req(length(i) > 0); d <- log_df()[i, , drop = FALSE]
      ins <- latest_by(ctx$table("decision_inputs")(), c("decision_id", "email")); ins <- ins[ins$decision_id == d$decision_id, , drop = FALSE]
      o <- ctx$table("decision_options")()
      card(d$title, div(class = "mail-preview", d$context),
        p(tags$b("Outcome: "), d$Outcome, ". ", d$outcome_rationale),
        if (nrow(ins)) tags$table(class = "qs-table", tags$tbody(lapply(seq_len(nrow(ins)), function(k) tags$tr(
          tags$td(ins$email[k]), tags$td(o$label[o$option_id == ins$option_id[k]][1]),
          tags$td(span(class = paste0("stance-", ins$stance[k]), ins$stance[k])), tags$td(ins$comment[k]))))))
    })
    output$dl <- downloadHandler(filename = function() paste0("decision_log_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) utils::write.csv(log_df()[, c("decided_at", "title", "Outcome", "Bid", "outcome_rationale", "revisit_if", "decided_by", "context")], file, row.names = FALSE))
  })
}
