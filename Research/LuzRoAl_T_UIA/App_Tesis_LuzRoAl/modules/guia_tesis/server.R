guia_tesis_server <- function(id, tm, parent_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    setup_common(input, parent_session)

    observeEvent(TRUE, once = TRUE, {
      updateCheckboxInput(session, "guideRead", value = isTRUE(tm$project$guide_read))
    })
    observeEvent(input$guideRead, ignoreInit = TRUE, {
      if (!identical(isTRUE(input$guideRead), isTRUE(tm$project$guide_read))) {
        tm$project$guide_read <- isTRUE(input$guideRead)
        tm$save_project(write_texts = FALSE); tm$touch()
        if (isTRUE(input$guideRead)) showNotification("✔ ¡Muy bien! Siguiente paso: anotar sus ideas.", type = "message", duration = 5)
      }
    })
    # keep the checkbox in sync when another work folder is opened
    observeEvent(tm$proj_trigger(), {
      if (!identical(isTRUE(isolate(input$guideRead)), isTRUE(tm$project$guide_read)))
        updateCheckboxInput(session, "guideRead", value = isTRUE(tm$project$guide_read))
    }, ignoreInit = TRUE)

    output$greeting <- renderUI({
      tm$cfg_trigger()
      name <- tm$config$author_name %||% ""
      h <- as.integer(format(Sys.time(), "%H"))
      saludo <- if (h < 12) "Buenos días" else if (h < 19) "Buenas tardes" else "Buenas noches"
      div(class = "suggest-banner greeting",
          HTML(sprintf("%s%s. Esta app le acompaña para escribir su tesis de <b>%s</b>, paso a paso y a su ritmo.",
                       saludo, if (nzchar(name)) paste0(", <b>", htmltools::htmlEscape(name), "</b>") else "", CARRERA)))
    })

    output$stats <- renderUI({
      tm$proj_trigger(); tm$claude_trigger()
      p <- tm$progress()
      tema <- tm$chosen()
      total_words <- tm$parts_words(INTRO_PARTS) + tm$chapters_words() + tm$parts_words(CONCL_PARTS)
      div(class = "stat-row",
          stat_tile("Avance total", paste0(p$overall, " %"), p$next_step, "green", p$overall),
          stat_tile("Mi tema", if (is.null(tema)) "Sin elegir" else HTML("<span style='font-size:22px;'>Elegido</span>"),
                    if (is.null(tema)) sprintf("%d ideas anotadas", length(tm$ideas())) else tema$titulo, "purple"),
          stat_tile("Palabras escritas", fmt_int(total_words), sprintf("≈ %s páginas", fmt_int(round(total_words / 300))), "orange"),
          stat_tile("Comentarios de Claude", fmt_int(length(tm$project$feedback)), "Guardados en su carpeta", ""))
    })

    output$route <- renderUI({
      tm$proj_trigger(); tm$claude_trigger()
      st <- tm$progress()$steps
      first_pending <- TRUE
      tagList(lapply(seq_along(RUTA), function(i) {
        r <- RUTA[[i]]; v <- st[[r$key]]
        cls <- if (v >= 100) "done" else if (first_pending) { first_pending <<- FALSE; "next" } else if (v > 0) "doing" else "todo"
        div(class = paste("route-step", cls),
            div(class = "route-num", if (v >= 100) HTML("&#10004;") else i),
            div(class = "route-body",
                div(class = "route-title", r$titulo, if (v > 0 && v < 100) span(class = "route-pct", paste0(v, " %"))),
                div(class = "route-text", r$texto),
                if (v > 0 && v < 100) progress_bar(v)),
            js_btn(if (cls == "next") " Ir ahora" else " Ir", ns("routeEvt"), r$tab, "go",
                   if (cls == "next") "btn-success" else "btn-default", icon_name = "arrow-right"))
      }))
    })

    observeEvent(input$routeEvt, {
      tab <- input$routeEvt$id
      if (identical(tab, "guia_tesis")) updateTabsetPanel(session, "subtabs", selected = "carrera")
      else go_to_tab(parent_session, tab)
    })

    observeEvent(input$bridgeEvt, {
      i <- as.integer(input$bridgeEvt$id)
      tm$add_idea(IDEAS_PUENTE[i], descripcion = "", origen = "guía")
      showNotification("✔ Se agregó a “Mis ideas y temas”. Ahí puede completarla y pedirle opinión a Claude.", type = "message", duration = 6)
    })

    output$targets <- renderUI({
      tm$cfg_trigger()
      tags$ul(class = "guide-list",
              tags$li(sprintf("Introducción: unas %s palabras", fmt_int(tm$part_target(INTRO_PARTS)))),
              tags$li(sprintf("Cada capítulo: unas %s palabras", fmt_int(tm$config$chapter_target %||% 4000))),
              tags$li(sprintf("Conclusiones y bibliografía: unas %s palabras", fmt_int(tm$part_target(CONCL_PARTS)))),
              tags$li("Una página tiene unas 300 palabras."))
    })

    ask <- function(q) {
      run_claude(session, tm, function() tm$ask(prompt_free_question(q, "Guía: cómo escribir una buena tesis"),
                                                tab = "guia_tesis", key = "guia", action = "question", title = substr(q, 1, 80)))
    }
    observeEvent(input$ask_send, {
      q <- trimws(input$ask_text %||% "")
      if (!nzchar(q)) { showNotification("Escriba primero su pregunta.", type = "warning"); return() }
      if (!is.null(ask(q))) updateTextAreaInput(session, "ask_text", value = "")
    })
    observeEvent(input$quickEvt, ask(GUIA_PREGUNTAS[as.integer(input$quickEvt$id)]))

    feedback_panel_server(input, output, session, tm, tab = "guia_tesis", keys_fun = reactive(NULL),
                          empty_msg = "Haga una pregunta y la respuesta de Claude aparecerá aquí.")
  })
}
