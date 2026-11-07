# ---- Decision log: the why, not just the what - so nothing is forgotten or re-argued ------------

mod_log_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "page-head",
      div(class = "eyebrow mag-t", "Decision log"),
      h2("What we decided, and why"),
      p(class = "lead", "Every recorded decision with its reasoning and the trigger that would make us revisit it. Settled choices stay settled unless the context changes.")),
    uiOutput(ns("stats")),
    div(class = "dec-toolbar",
      textInput(ns("q"), NULL, placeholder = "Search the log", width = "100%"),
      selectInput(ns("cat"), NULL, c("All types" = "", CATEGORIES), width = "100%"),
      downloadButton(ns("dl"), "Download CSV", class = "btn-ghost")),
    uiOutput(ns("entries"))
  )
}

mod_log_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    decided <- reactive({
      req(ctx$user$authed)
      d <- dec_latest(ctx$data$decisions()); d <- d[d$status == "decided", , drop = FALSE]
      d[order(d$decided_at, decreasing = TRUE), , drop = FALSE]
    })

    output$stats <- renderUI({
      d <- decided(); s <- sync_latest(ctx$data$syncs())
      live <- unique(s$decision_id[s$status %in% c("scheduled", "held")])
      days <- suppressWarnings(as.numeric(difftime(as.POSIXct(d$decided_at, tz = "UTC"), as.POSIXct(d$created_at, tz = "UTC"), units = "days")))
      stat <- function(n, l, cls = "") div(class = paste("stat", cls), div(class = "n", n), div(class = "l", l))
      div(class = "stat-row three",
        stat(nrow(d), "decisions on record", "mag"),
        stat(if (length(days) && any(!is.na(days))) sprintf("%.1f", mean(days, na.rm = TRUE)) else "-", "average days to decide", "teal"),
        stat(sum(!(d$decision_id %in% live)), "decided without a live session"))
    })

    filtered <- reactive({
      d <- decided()
      if (nzchar(input$cat %||% "")) d <- d[d$category == input$cat, , drop = FALSE]
      q <- tolower(trimws(input$q %||% ""))
      if (nzchar(q)) d <- d[grepl(q, tolower(paste(d$title, d$context, d$outcome_rationale, d$revisit_if)), fixed = TRUE), , drop = FALSE]
      d
    })

    output$entries <- renderUI({
      d <- filtered()
      if (nrow(d) == 0) return(div(class = "empty", "Nothing logged yet. Decisions appear here the moment an Approver records one."))
      o <- ctx$data$dopts(); i <- in_latest(ctx$data$dinputs()); users <- ctx$data$users()
      div(class = "log-list", lapply(seq_len(nrow(d)), function(k) {
        r <- d[k, ]; oo <- o[o$decision_id == r$decision_id, , drop = FALSE]
        ii <- i[i$decision_id == r$decision_id, , drop = FALSE]
        won <- oo$label[match(r$outcome_option, oo$option_id)]
        tags$details(class = "log-entry",
          tags$summary(
            span(class = "lg-date", substr(r$decided_at, 1, 10)),
            span(class = "lg-main", span(class = "lg-q", r$title), span(class = "lg-a", HTML("&rarr; "), won)),
            chip(r$category, "grey"),
            if (as.integer(num(r$reopen_count, 0)) > 0) chip(paste0("reopened x", r$reopen_count), "amber")),
          div(class = "lg-body",
            div(class = "lg-col", div(class = "lg-h", "Why"), p(r$outcome_rationale),
                if (nzchar(r$revisit_if)) tagList(div(class = "lg-h", "Revisit if"), p(r$revisit_if))),
            div(class = "lg-col", div(class = "lg-h", "Context"), p(HTML(gsub("\n", "<br>", esc(r$context)))),
                div(class = "lg-h", "Options considered"),
                tags$ul(lapply(seq_len(nrow(oo)), function(j) tags$li(
                  if (identical(oo$option_id[j], r$outcome_option)) strong(oo$label[j]) else oo$label[j],
                  span(class = "muted small", paste0(" - ", sum(ii$option_id == oo$option_id[j]), " preferred")))))),
            div(class = "lg-foot small muted",
                paste0("Approver: ", display_name(r$decided_by, users), "  |  ", nrow(ii), if (nrow(ii) == 1) " view  |  " else " views  |  ",
                       sum(ii$stance == "object"), if (sum(ii$stance == "object") == 1) " objection  |  ID " else " objections  |  ID ", r$decision_id))))
      }))
    })

    output$dl <- downloadHandler(
      filename = function() paste0("decision-log-", format(Sys.Date()), ".csv"),
      content = function(file) {
        d <- decided(); o <- ctx$data$dopts()
        d$outcome <- o$label[match(d$outcome_option, o$option_id)]
        utils::write.csv(d[c("decision_id", "title", "category", "context", "outcome", "outcome_rationale", "revisit_if", "decided_by", "decided_at")], file, row.names = FALSE)
      })
  })
}
