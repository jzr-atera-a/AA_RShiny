# modules/Technical Designs/techdesign_recommender/server.R

techdesign_recommender_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    recs <- reactiveVal(list())

    observeEvent(input$go, {
      if (!api_manager$claude_authenticated) { showNotification("Please configure and save Editing Tool API credentials first!", type = "error", duration = 10); return() }
      if (nchar(trimws(input$problem %||% "")) < 10) { showNotification("Please describe the problem (at least a sentence).", type = "warning"); return() }
      output$status <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Asking the Editing Tool..."))
      tryCatch({
        prompt <- generate_td_recommend_prompt(input$problem, n = input$n %||% 3, constraints = input$constraints %||% "")
        resp <- api_manager$call_claude(prompt = prompt, max_tokens = 3000, progress_callback = function(msg) NULL)
        r <- parse_td_recommendations(resp)
        recs(r)
        if (length(r) == 0) {
          output$status <- renderUI(tags$div(class = "status-warning", "The Editing Tool's answer did not contain any recognised designs. Try rephrasing the problem."))
        } else {
          output$status <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" %d recommendation(s).", length(r))))
        }
      }, error = function(e) {
        output$status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Failed: ", e$message))
      })
    })

    output$results <- renderUI({
      r <- recs()
      if (length(r) == 0) return(tags$div(class = "status-info", "No recommendations yet."))
      lapply(seq_along(r), function(i) {
        x <- r[[i]]
        col <- switch(tolower(x$fit), high = "#27AE60", medium = "#E67E22", "#95A5A6")
        div(style = "margin-bottom:14px;padding:14px;border:1px solid #dfe6e9;border-radius:8px;background:#fff;",
            div(style = "display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;",
                h4(style = "margin:0;", sprintf("%d. %s", i, x$label)),
                tags$span(td_group_badge(x$group), " ",
                          tags$span(style = sprintf("background:%s;color:#fff;border-radius:10px;padding:2px 9px;font-size:11px;", col), paste(x$fit, "fit")))),
            p(style = "margin-top:8px;", tags$strong("Why: "), x$reasoning),
            p(tags$strong("Watch out: "), x$drawbacks),
            tags$button(type = "button", class = "btn btn-primary btn-sm",
                        onclick = sprintf("Shiny.setInputValue('%s', %d, {priority: 'event'})", session$ns("pick"), i),
                        tags$i(class = "fa fa-magic"), " Generate this design"))
      })
    })

    observeEvent(input$pick, {
      r <- recs(); i <- input$pick
      if (is.null(i) || i < 1 || i > length(r)) return()
      x <- r[[i]]
      ctx <- if (isTRUE(input$pass_context)) (if (nzchar(x$tailored_context)) x$tailored_context else trimws(input$problem)) else ""
      td_goto_generate(api_manager, session, x$group, x$design_type, ctx)
    })

    output$status <- renderUI(tags$div())
  })
}
