ideas_server <- function(id, tm, parent_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    setup_common(input, parent_session)
    editing <- reactiveVal(NULL)

    ESTADOS <- c("Nueva" = "nueva", "Explorando" = "explorando", "Mi tema" = "elegida", "Descartada" = "descartada")

    # ------------------------------------------------------------ add
    observeEvent(input$add, {
      t <- trimws(input$titulo %||% "")
      if (!nzchar(t)) { showNotification("Escriba al menos un título para la idea.", type = "warning"); return() }
      tm$add_idea(t, trimws(input$descripcion), trimws(input$experiencia), input$materias %||% character())
      for (f in c("titulo")) updateTextInput(session, f, value = "")
      for (f in c("descripcion", "experiencia")) updateTextAreaInput(session, f, value = "")
      updateSelectizeInput(session, "materias", selected = character())
      showNotification("✔ Idea guardada", type = "message")
    })

    # ------------------------------------------------------------ list
    output$ideasList <- renderUI({
      tm$proj_trigger()
      ideas <- tm$ideas()
      f <- input$filter %||% "all"
      if (f == "open") ideas <- Filter(function(x) (x$estado %||% "nueva") %in% c("nueva", "explorando", "elegida"), ideas)
      if (f == "descartada") ideas <- Filter(function(x) identical(x$estado, "descartada"), ideas)
      if (!length(ideas)) return(div(class = "empty-state",
        if (length(tm$ideas())) "No hay ideas con este filtro." else
          HTML("Todavía no hay ideas. Anote la primera a la izquierda,<br>o tome una de las ideas de la guía (pestaña <b>La carrera: ayer y hoy</b>).")))
      chosen <- tm$project$chosen_idea %||% ""
      nfb <- function(idd) length(tm$feedback_for(keys = idd, tab = "ideas"))
      tagList(lapply(rev(ideas), function(x) {
        est <- x$estado %||% "nueva"
        is_chosen <- identical(x$id, chosen)
        div(class = paste("idea-card", est, if (is_chosen) "chosen"),
            div(class = "idea-head",
                span(class = "idea-title", if (is_chosen) "⭐ ", x$titulo),
                span(class = paste("idea-badge", est), names(ESTADOS)[ESTADOS == est])),
            if (nzchar(x$descripcion %||% "")) div(class = "idea-desc", x$descripcion),
            if (nzchar(x$experiencia %||% "")) div(class = "idea-exp", tags$b("Mi experiencia: "), x$experiencia),
            if (length(x$materias)) div(class = "idea-tags", lapply(unlist(x$materias), function(m) span(class = "special-tag", m))),
            div(class = "idea-actions",
                js_btn(" Opinión de Claude", ns("ideaEvt"), x$id, "claude", "btn-success", icon_name = "robot"),
                if (!is_chosen) js_btn(" Elegir como mi tema", ns("ideaEvt"), x$id, "choose", "btn-primary", icon_name = "star"),
                js_btn(" Editar", ns("ideaEvt"), x$id, "edit", "btn-default", icon_name = "edit"),
                js_btn("", ns("ideaEvt"), x$id, "delete", "btn-default", title = "Borrar", icon_name = "trash"),
                if (nfb(x$id)) span(class = "wm-hint", sprintf("  %d comentario(s) de Claude", nfb(x$id)))))
      }))
    })

    # keep the "ver comentarios de" list in sync
    observe({
      tm$proj_trigger()
      ideas <- tm$ideas()
      ch <- c("Todas mis ideas" = "", setNames(vapply(ideas, `[[`, "", "id"), vapply(ideas, `[[`, "", "titulo")))
      sel <- isolate(input$fbIdea) %||% ""
      if (!sel %in% ch) sel <- ""
      updateSelectInput(session, "fbIdea", choices = ch, selected = sel)
    })

    ask_idea <- function(idea) {
      run_claude(session, tm, function() tm$ask(prompt_idea_feedback(idea), tab = "ideas", key = idea$id,
                                                action = "idea", title = idea$titulo))
    }

    observeEvent(input$ideaEvt, {
      e <- input$ideaEvt
      idea <- tm$get_idea(e$id); if (is.null(idea)) return()
      if (e$action == "claude") {
        if (!is.null(ask_idea(idea))) {
          updateSelectInput(session, "fbIdea", selected = idea$id)
          if (identical(idea$estado, "nueva")) tm$update_idea(idea$id, estado = "explorando")
        }
      } else if (e$action == "choose") {
        tm$choose_idea(idea$id)
        showModal(modalDialog(title = "⭐ ¡Ya tiene tema!",
          div(class = "big-message", p(tags$b(idea$titulo)),
              p("El siguiente paso es armar el bosquejo de la tesis. Claude le puede proponer uno a partir de este tema.")),
          footer = tagList(modalButton("Más tarde"),
                           actionButton(ns("goOutline"), "Ir al Bosquejo", class = "btn-success", icon = icon("sitemap"))),
          easyClose = TRUE))
      } else if (e$action == "edit") {
        editing(idea$id)
        showModal(modalDialog(title = "Editar idea", size = "l", easyClose = TRUE,
          textInput(ns("eTitulo"), "Título:", value = idea$titulo, width = "100%"),
          textAreaInput(ns("eDesc"), "¿De qué se trata?", value = idea$descripcion %||% "", rows = 4, width = "100%"),
          textAreaInput(ns("eExp"), "¿Por qué me importa? Mi experiencia:", value = idea$experiencia %||% "", rows = 4, width = "100%"),
          selectizeInput(ns("eMat"), "Materias o enfoques:", choices = MATERIAS_CHOICES(), selected = unlist(idea$materias),
                         multiple = TRUE, width = "100%"),
          radioButtons(ns("eEstado"), "Estado:", choices = ESTADOS[ESTADOS != "elegida"],
                       selected = if (identical(idea$estado, "elegida")) "explorando" else idea$estado %||% "nueva", inline = TRUE),
          if (identical(idea$estado, "elegida")) div(class = "wm-hint", "Esta idea es su tema. Para cambiar de tema, elija otra idea."),
          footer = tagList(modalButton("Cancelar"), actionButton(ns("eSave"), "Guardar cambios", class = "btn-success"))))
      } else if (e$action == "delete") {
        editing(idea$id)
        showModal(modalDialog(title = "¿Borrar esta idea?", p(tags$b(idea$titulo)),
          p("Si solo quiere dejarla de lado, mejor márquela como “Descartada” en Editar."),
          footer = tagList(modalButton("Cancelar"), actionButton(ns("delOk"), "Sí, borrar", class = "btn-danger")), easyClose = TRUE))
      }
    })
    observeEvent(input$goOutline, { removeModal(); go_to_tab(parent_session, "bosquejo") })

    observeEvent(input$eSave, {
      id <- editing(); idea <- tm$get_idea(id); if (is.null(idea)) return()
      t <- trimws(input$eTitulo %||% "")
      if (!nzchar(t)) { showNotification("El título no puede quedar vacío.", type = "warning"); return() }
      est <- if (identical(idea$estado, "elegida")) "elegida" else input$eEstado
      tm$update_idea(id, titulo = t, descripcion = trimws(input$eDesc), experiencia = trimws(input$eExp),
                     materias = as.list(input$eMat %||% character()), estado = est)
      removeModal(); showNotification("✔ Idea actualizada", type = "message")
    })
    observeEvent(input$delOk, { removeModal(); tm$delete_idea(editing()) })

    # ------------------------------------------------------------ topic suggestions
    observeEvent(input$suggest, {
      if (!nzchar(trimws(paste(input$sugExp, input$sugInt)))) {
        showNotification("Cuéntele a Claude algo de su experiencia o de lo que le interesa.", type = "warning"); return()
      }
      fb <- run_claude(session, tm, function() tm$ask(prompt_suggest_topics(trimws(input$sugExp), trimws(input$sugInt), input$sugMat %||% character()),
                                                      tab = "ideas", key = "sugerencias", action = "topics", title = "Temas sugeridos",
                                                      store = FALSE), message = "Claude está pensando temas para usted…")
      if (is.null(fb)) return()
      txt <- fb$messages[[2]]$content
      js <- extract_json(txt)
      if (is.null(js) || !length(js)) {
        tm$add_feedback(fb)   # keep the plain answer at least
        showNotification("Claude respondió, pero no en el formato esperado. Puede leer su respuesta en los comentarios.", type = "warning", duration = 8)
        return()
      }
      if (!is.null(js$titulo)) js <- list(js)
      tm$project$suggestions <- lapply(js, function(s) list(titulo = s$titulo %||% "", descripcion = s$descripcion %||% "",
                                                            por_que = s$por_que %||% "", experiencia = trimws(input$sugExp)))
      tm$save_project(write_texts = FALSE); tm$touch()
    })

    output$suggestions <- renderUI({
      tm$proj_trigger()
      sg <- tm$project$suggestions %||% list()
      if (!length(sg)) return(NULL)
      tagList(
        h4(style = "color:#4f46e5; margin-top: 18px;", "Temas que le sugiere Claude"),
        lapply(seq_along(sg), function(i) {
          s <- sg[[i]]
          div(class = "suggest-card",
              div(class = "idea-title", s$titulo), div(s$descripcion),
              if (nzchar(s$por_que %||% "")) div(class = "wm-hint", style = "margin: 4px 0;", tags$b("Por qué le queda bien: "), s$por_que),
              js_btn(" Agregar a mis ideas", ns("sugEvt"), i, "add", "btn-success btn-sm", icon_name = "plus"),
              js_btn(" Quitar", ns("sugEvt"), i, "drop", "btn-default btn-sm", icon_name = "times"))
        }))
    })

    observeEvent(input$sugEvt, {
      i <- as.integer(input$sugEvt$id)
      sg <- tm$project$suggestions %||% list()
      if (i > length(sg)) return()
      if (input$sugEvt$action == "add") {
        s <- sg[[i]]
        tm$add_idea(s$titulo, paste(s$descripcion, s$por_que), s$experiencia %||% "", origen = "claude")
        showNotification("✔ Se agregó a sus ideas", type = "message")
      }
      sg[[i]] <- NULL
      tm$project$suggestions <- sg
      tm$save_project(write_texts = FALSE); tm$touch()
    })

    # ------------------------------------------------------------ free question about an idea
    observeEvent(input$ask_send, {
      q <- trimws(input$ask_text %||% "")
      if (!nzchar(q)) { showNotification("Escriba primero su pregunta.", type = "warning"); return() }
      idea <- if (nzchar(input$fbIdea %||% "")) tm$get_idea(input$fbIdea) else NULL
      prompt <- if (is.null(idea)) prompt_free_question(q, "Mis ideas y temas") else
        paste0("Sobre mi idea “", idea$titulo, "” (", idea$descripcion %||% "", "):\n\n", q)
      res <- run_claude(session, tm, function() tm$ask(prompt, tab = "ideas", key = if (is.null(idea)) "ideas" else idea$id,
                                                       action = "question", title = if (is.null(idea)) substr(q, 1, 70) else idea$titulo))
      if (!is.null(res)) updateTextAreaInput(session, "ask_text", value = "")
    })

    feedback_panel_server(input, output, session, tm, tab = "ideas",
                          keys_fun = reactive(if (nzchar(input$fbIdea %||% "")) input$fbIdea else NULL),
                          empty_msg = "Presione “Opinión de Claude” en una idea, o haga una pregunta.")

    # ------------------------------------------------------------ stats
    output$stats <- renderUI({
      tm$proj_trigger()
      ideas <- tm$ideas()
      tema <- tm$chosen()
      n_open <- sum(vapply(ideas, function(x) !identical(x$estado, "descartada"), logical(1)))
      div(class = "stat-row",
          stat_tile("Ideas anotadas", fmt_int(length(ideas)), sprintf("%d activas · se recomiendan al menos 3", n_open), "purple",
                    min(100, 100 * length(ideas) / 3)),
          stat_tile("Mi tema", if (is.null(tema)) "Sin elegir" else HTML("<span style='font-size:22px;'>⭐ Elegido</span>"),
                    if (is.null(tema)) "Elija una idea con “Elegir como mi tema”" else tema$titulo, if (is.null(tema)) "orange" else "green"),
          stat_tile("Comentarios de Claude", fmt_int(length(tm$feedback_for(tab = "ideas"))), "Sobre sus ideas", ""))
    })
  })
}
