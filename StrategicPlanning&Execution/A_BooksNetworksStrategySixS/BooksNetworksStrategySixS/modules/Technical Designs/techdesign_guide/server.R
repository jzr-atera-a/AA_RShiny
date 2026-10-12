# modules/Technical Designs/techdesign_guide/server.R

techdesign_guide_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    all_items <- do.call(rbind, lapply(TD_GROUPS, function(g) {
      ids <- names(TD_CATALOG[[g]])
      data.frame(group = rep(g, length(ids)), type = ids, label = vapply(ids, function(i) TD_CATALOG[[g]][[i]]$label, ""),
                 stringsAsFactors = FALSE)
    }))

    output$cards <- renderUI({
      f <- input$group_filter %||% ""
      items <- if (nzchar(f)) all_items[all_items$group == f, ] else all_items
      lapply(seq_len(nrow(items)), function(i) {
        it <- items[i, ]
        info <- TD_INFO[[it$type]]
        div(class = "td-card", style = "margin-bottom:14px;padding:14px;border:1px solid #dfe6e9;border-radius:8px;background:#fff;",
            div(style = "display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;",
                h4(style = "margin:0;", it$label), td_group_badge(it$group)),
            if (!is.null(info)) tagList(
              p(style = "margin-top:8px;", tags$strong("What it is: "), info$what),
              p(tags$strong("Best for: "), info$best),
              p(tags$strong("Watch out for: "), info$watch),
              p(style = "color:#7f8c8d;font-size:12px;", tags$strong("Related: "),
                paste(vapply(strsplit(info$related, ",\\s*")[[1]], function(r) {
                  hit <- all_items$label[all_items$type == r]; if (length(hit)) hit[1] else r }, ""), collapse = ", "))
            ),
            fluidRow(
              column(3, actionButton(session$ns(paste0("ex_", it$type)), "Show example", icon = icon("eye"), class = "btn-info btn-sm", style = "width:100%;")),
              column(3, actionButton(session$ns(paste0("gen_", it$type)), "Generate this", icon = icon("magic"), class = "btn-primary btn-sm", style = "width:100%;"))
            ))
      })
    })

    shown <- reactiveVal(NULL)
    lapply(seq_len(nrow(all_items)), function(i) {
      it <- all_items[i, ]
      observeEvent(input[[paste0("ex_", it$type)]], {
        shown(it$type)
        shinyjs::runjs(sprintf("setTimeout(function(){var e=document.getElementById('%s'); if(e) e.scrollIntoView({behavior:'smooth', block:'start'});}, 250);", session$ns("example_box")))
      }, ignoreInit = TRUE)
      observeEvent(input[[paste0("gen_", it$type)]], {
        td_goto_generate(api_manager, session, it$group, it$type)
      }, ignoreInit = TRUE)
    })

    output$example <- renderUI({
      t <- shown()
      if (is.null(t)) return(tags$div(class = "status-info", "Click 'Show example' on any design above."))
      d <- td_seed_parsed(t)
      if (is.null(d)) return(tags$div(class = "status-warning", "No bundled example found for this design (the seed/techdesign folder is missing)."))
      tagList(export_capture_wrapper(session$ns, render_techdesign(d), d$meta$title),
              td_example_refs_ui(t), td_build_notes_ui())
    })
  })
}
