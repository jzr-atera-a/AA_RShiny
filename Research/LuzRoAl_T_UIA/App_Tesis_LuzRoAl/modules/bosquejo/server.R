OUTLINE_FIELDS <- list(
  list(key = "titulo", label = "Título tentativo", rows = 0, ph = "Puede ser provisional; se afina al final."),
  list(key = "pregunta", label = "Pregunta de investigación", rows = 2, ph = "¿Qué quiere responder? En una o dos frases."),
  list(key = "hipotesis", label = "Hipótesis o tesis central", rows = 2, ph = "Su respuesta tentativa a la pregunta."),
  list(key = "objetivo_general", label = "Objetivo general", rows = 2, ph = "Empieza con un verbo: analizar, explicar, comparar, evaluar…"),
  list(key = "objetivos_especificos", label = "Objetivos específicos (uno por renglón)", rows = 4, ph = "Describir…\nIdentificar…\nEvaluar…"),
  list(key = "justificacion", label = "Justificación: ¿por qué importa?", rows = 3, ph = "Para la ciencia política, para México, para usted."),
  list(key = "marco_teorico", label = "Marco teórico: conceptos y autores", rows = 3, ph = "p. ej. Estado, poder, instituciones, nueva gerencia pública…"),
  list(key = "metodologia", label = "Metodología y fuentes", rows = 3, ph = "Tipo de estudio y fuentes: documentos, datos, entrevistas, su testimonio."),
  list(key = "alcances", label = "Alcances: lugar, periodo y actores", rows = 2, ph = "p. ej. Administración pública federal, 1982–2000.")
)

bosquejo_server <- function(id, tm, parent_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    setup_common(input, parent_session)

    form_ver <- reactiveVal(0)    # re-draw the fields (project loaded, proposal applied)
    ch_ver <- reactiveVal(0)      # re-draw the chapters list
    frozen <- reactiveVal(TRUE)   # ignore input values until the drawn form reports back
    last_saved <- reactiveVal(NULL)
    pending_del <- reactiveVal(NULL)

    # A different work folder was opened → redraw
    observeEvent(tm$load_trigger(), { form_ver(form_ver() + 1); ch_ver(ch_ver() + 1); frozen(TRUE) }, ignoreInit = TRUE)

    output$form <- renderUI({
      form_ver()
      o <- isolate(tm$outline())
      frozen(TRUE)
      tagList(lapply(OUTLINE_FIELDS, function(f) {
        val <- o[[f$key]] %||% ""
        if (f$rows == 0) textInput(ns(paste0("f_", f$key)), f$label, value = val, width = "100%", placeholder = f$ph)
        else textAreaInput(ns(paste0("f_", f$key)), f$label, value = val, rows = f$rows, width = "100%", placeholder = f$ph, resize = "vertical")
      }))
    })

    output$chapters <- renderUI({
      ch_ver(); form_ver()
      caps <- isolate(tm$chapters())
      frozen(TRUE)
      if (!length(caps)) return(div(class = "empty-state small", "Todavía no hay capítulos. Agréguelos con el botón de abajo, o pida a Claude que le proponga un bosquejo."))
      tagList(lapply(seq_along(caps), function(i) {
        c <- caps[[i]]
        w <- tm$words(tm$chapter_key(c$id))
        div(class = "chapter-row",
            div(class = "chapter-num", i),
            div(class = "chapter-fields",
                textInput(ns(paste0("ct_", c$id)), NULL, value = c$titulo %||% "", width = "100%", placeholder = "Título del capítulo"),
                textAreaInput(ns(paste0("cd_", c$id)), NULL, value = c$descripcion %||% "", rows = 2, width = "100%",
                              placeholder = "¿Qué se trata en este capítulo? (1 o 2 frases)", resize = "vertical"),
                if (w > 0) div(class = "wm-hint", sprintf("Ya tiene %s palabras escritas en la pestaña Capítulos.", fmt_int(w)))),
            div(class = "chapter-btns",
                js_btn("", ns("chEvt"), c$id, "up", "btn-default", title = "Subir", icon_name = "arrow-up"),
                js_btn("", ns("chEvt"), c$id, "down", "btn-default", title = "Bajar", icon_name = "arrow-down"),
                js_btn("", ns("chEvt"), c$id, "delete", "btn-default", title = "Quitar", icon_name = "trash")))
      }))
    })

    # ------------------------------------------------------------ collect + autosave
    collect <- reactive({
      ch_ver(); form_ver()
      fields <- lapply(OUTLINE_FIELDS, function(f) input[[paste0("f_", f$key)]])
      names(fields) <- vapply(OUTLINE_FIELDS, `[[`, "", "key")
      caps <- isolate(tm$chapters())
      ch <- lapply(caps, function(c) list(id = c$id, titulo = input[[paste0("ct_", c$id)]], descripcion = input[[paste0("cd_", c$id)]]))
      list(fields = fields, chapters = ch)
    })

    stored <- function() {
      o <- tm$outline()
      f <- lapply(OUTLINE_FIELDS, function(x) o[[x$key]] %||% "")
      names(f) <- vapply(OUTLINE_FIELDS, `[[`, "", "key")
      list(fields = f, chapters = lapply(tm$chapters(), function(c) list(id = c$id, titulo = c$titulo %||% "", descripcion = c$descripcion %||% "")))
    }
    complete <- function(x) !any(vapply(x$fields, is.null, logical(1))) &&
      !any(vapply(x$chapters, function(c) is.null(c$titulo) || is.null(c$descripcion), logical(1)))

    save_inputs <- function(x = isolate(collect())) {
      if (isolate(frozen()) || !complete(x)) return(invisible(FALSE))
      st <- stored()
      if (identical(x, st)) return(invisible(FALSE))
      tm$set_outline(x$fields, x$chapters)
      last_saved(Sys.time())
      invisible(TRUE)
    }

    collect_d <- debounce(collect, 1500)
    observeEvent(collect(), {
      x <- collect()
      if (frozen() && complete(x) && identical(x, stored())) frozen(FALSE)
    })
    observeEvent(collect_d(), save_inputs(collect_d()))
    session$onSessionEnded(function() isolate(save_inputs()))

    output$saveState <- renderUI({
      s <- last_saved()
      upd <- tm$project$updated
      div(class = "ef-saved", style = "margin-top: 6px;",
          if (!is.null(s)) span(class = "status-ok", icon("check"), " Bosquejo guardado a las ", format(s, "%H:%M:%S"))
          else span(style = "color:#8a93a6;", "Se guarda solito mientras escribe."))
    })

    # ------------------------------------------------------------ chapter operations
    redraw_chapters <- function() { frozen(TRUE); ch_ver(ch_ver() + 1) }

    observeEvent(input$addCh, {
      save_inputs()
      caps <- tm$chapters()
      caps[[length(caps) + 1]] <- list(id = new_id("c"), titulo = "", descripcion = "")
      tm$set_outline(list(), caps)
      redraw_chapters()
    })

    observeEvent(input$chEvt, {
      save_inputs()
      caps <- tm$chapters()
      ids <- vapply(caps, `[[`, "", "id")
      i <- match(input$chEvt$id, ids); if (is.na(i)) return()
      a <- input$chEvt$action
      if (a == "up" && i > 1) { caps[c(i - 1, i)] <- caps[c(i, i - 1)] }
      else if (a == "down" && i < length(caps)) { caps[c(i, i + 1)] <- caps[c(i + 1, i)] }
      else if (a == "delete") {
        w <- tm$words(tm$chapter_key(ids[i]))
        if (w > 0) {
          pending_del(ids[i])
          showModal(modalDialog(title = "¿Quitar este capítulo?",
            div(class = "big-message",
                p(sprintf("Este capítulo ya tiene %s palabras escritas.", fmt_int(w))),
                p("Se guardará una copia de su texto en la carpeta “versiones” antes de quitarlo.")),
            footer = tagList(modalButton("Cancelar"), actionButton(ns("delChOk"), "Sí, quitar", class = "btn-danger")), easyClose = TRUE))
          return()
        }
        caps[[i]] <- NULL
      } else return()
      tm$set_outline(list(), caps)
      redraw_chapters()
    })

    observeEvent(input$delChOk, {
      removeModal()
      id <- pending_del()
      tm$snapshot(tm$chapter_key(id), "capítulo quitado del bosquejo")
      caps <- Filter(function(c) !identical(c$id, id), tm$chapters())
      tm$set_outline(list(), caps)
      redraw_chapters()
    })

    # ------------------------------------------------------------ banner + stats
    output$temaBanner <- renderUI({
      tm$proj_trigger()
      t <- tm$chosen()
      if (is.null(t)) {
        div(class = "places-pending", icon("star"), " Todavía no ha elegido su tema. Puede llenar el bosquejo de todos modos, o ",
            actionLink(ns("goIdeas"), "ir a Mis ideas y temas"), " para elegirlo primero.")
      } else div(class = "suggest-banner", HTML(sprintf("⭐ <b>Mi tema:</b> %s", htmltools::htmlEscape(t$titulo))))
    })
    observeEvent(input$goIdeas, go_to_tab(parent_session, "ideas"))

    output$stats <- renderUI({
      tm$proj_trigger()
      pct <- tm$outline_pct()
      n <- length(tm$chapters())
      div(class = "stat-row",
          stat_tile("Bosquejo completo", paste0(pct, " %"), "Campos llenos y al menos 3 capítulos", if (pct >= 100) "green" else "purple", pct),
          stat_tile("Capítulos", n, if (n < 3) "Se recomiendan de 3 a 5" else "¡Bien!", if (n >= 3) "green" else "orange"),
          stat_tile("Comentarios de Claude", fmt_int(length(tm$feedback_for(tab = "bosquejo"))), "Sobre su bosquejo", ""))
    })

    # ------------------------------------------------------------ Claude
    observeEvent(input$propose, {
      save_inputs()
      t <- tm$chosen()
      if (is.null(t)) {
        showModal(modalDialog(title = "Primero elija su tema",
          div(class = "big-message", p("Para proponerle un bosquejo, Claude necesita saber su tema. Elíjalo en “Mis ideas y temas” con el botón “Elegir como mi tema”.")),
          footer = tagList(modalButton("Cerrar"), actionButton(ns("goIdeas2"), "Ir a Mis ideas", class = "btn-primary")), easyClose = TRUE))
        return()
      }
      fb <- run_claude(session, tm, function() tm$ask(prompt_outline_propose(t), tab = "bosquejo", key = "propuesta",
                                                      action = "outline_propose", title = "Bosquejo propuesto", store = FALSE),
                       message = "Claude está armando un bosquejo para su tema…")
      if (is.null(fb)) return()
      js <- extract_json(fb$messages[[2]]$content)
      if (is.null(js) || is.null(js$titulo)) {
        tm$add_feedback(fb)
        showNotification("Claude respondió, pero no en el formato esperado. Puede leer su respuesta abajo.", type = "warning", duration = 8)
        return()
      }
      tm$project$outline_proposal <- js
      tm$save_project(write_texts = FALSE); tm$touch()
    })
    observeEvent(input$goIdeas2, { removeModal(); go_to_tab(parent_session, "ideas") })

    output$proposal <- renderUI({
      tm$proj_trigger()
      js <- tm$project$outline_proposal
      if (is.null(js)) return(NULL)
      oe <- js$objetivos_especificos
      oe <- if (is.list(oe) || length(oe) > 1) paste0("<li>", vapply(oe, as.character, ""), "</li>", collapse = "") else as.character(oe %||% "")
      caps <- js$capitulos %||% list()
      row <- function(l, v) div(class = "prop-row", tags$b(l, ": "), HTML(v))
      esc <- function(x) htmltools::htmlEscape(paste(unlist(x %||% ""), collapse = " "))
      box(title = tagList(icon("magic"), " Propuesta de Claude"), status = "warning", solidHeader = TRUE, width = NULL,
          div(class = "proposal",
              row("Título", esc(js$titulo)), row("Pregunta", esc(js$pregunta)), row("Hipótesis", esc(js$hipotesis)),
              row("Objetivo general", esc(js$objetivo_general)), row("Objetivos específicos", paste0("<ul>", oe, "</ul>")),
              row("Justificación", esc(js$justificacion)), row("Marco teórico", esc(js$marco_teorico)),
              row("Metodología", esc(js$metodologia)), row("Alcances", esc(js$alcances)),
              tags$b("Capítulos:"),
              tags$ol(lapply(caps, function(c) tags$li(tags$b(c$titulo %||% ""), " — ", c$descripcion %||% "")))),
          div(class = "fb-actions",
              actionButton(ns("useProp"), "Usar esta propuesta", class = "btn-success", icon = icon("check")),
              actionButton(ns("dropProp"), "Descartarla", class = "btn-default", icon = icon("times"))),
          div(class = "wm-hint", "Puede usarla como punto de partida y luego cambiar todo lo que quiera."))
    })

    observeEvent(input$dropProp, { tm$project$outline_proposal <- NULL; tm$save_project(write_texts = FALSE); tm$touch() })

    observeEvent(input$useProp, {
      if (tm$outline_pct() > 0) {
        showModal(modalDialog(title = "¿Reemplazar su bosquejo?",
          div(class = "big-message", p("Su bosquejo actual se reemplazará por la propuesta de Claude."),
              p("Antes se guarda una copia en la carpeta “versiones”. Los textos que ya escribió en Capítulos no se borran.")),
          footer = tagList(modalButton("Cancelar"), actionButton(ns("useOk"), "Sí, usar la propuesta", class = "btn-success")), easyClose = TRUE))
      } else apply_proposal()
    })
    observeEvent(input$useOk, { removeModal(); apply_proposal() })

    apply_proposal <- function() {
      js <- tm$project$outline_proposal; if (is.null(js)) return()
      save_inputs()
      if (tm$outline_pct() > 0) {
        f <- file.path(tm$work_dir(), "versiones", sprintf("bosquejo_%s.md", format(Sys.time(), "%Y%m%d_%H%M%S")))
        write_utf8(tm$outline_text(), f)
      }
      txt <- function(x) paste(unlist(x %||% ""), collapse = "\n")
      fields <- list(titulo = txt(js$titulo), pregunta = txt(js$pregunta), hipotesis = txt(js$hipotesis),
                     objetivo_general = txt(js$objetivo_general), objetivos_especificos = txt(js$objetivos_especificos),
                     justificacion = txt(js$justificacion), marco_teorico = txt(js$marco_teorico),
                     metodologia = txt(js$metodologia), alcances = txt(js$alcances))
      old <- tm$chapters()
      caps <- lapply(seq_along(js$capitulos %||% list()), function(i) {
        c <- js$capitulos[[i]]
        # keep the id (and the text already written) of the chapter in the same position
        id <- if (i <= length(old)) old[[i]]$id else new_id("c")
        list(id = id, titulo = txt(c$titulo), descripcion = txt(c$descripcion))
      })
      for (j in seq_along(old)) if (j > length(caps)) tm$snapshot(tm$chapter_key(old[[j]]$id), "capítulo reemplazado por la propuesta")
      tm$project$outline_proposal <- NULL
      tm$set_outline(fields, caps)
      frozen(TRUE); form_ver(form_ver() + 1)
      showNotification("✔ Se usó la propuesta. Ahora puede ajustarla a su gusto.", type = "message", duration = 6)
    }

    observeEvent(input$review, {
      save_inputs()
      if (tm$outline_pct() < 20) { showNotification("Llene primero algunos campos del bosquejo.", type = "warning"); return() }
      run_claude(session, tm, function() tm$ask(prompt_outline_review(tm$outline_text()), tab = "bosquejo", key = "bosquejo",
                                                action = "outline_review", title = "Revisión del bosquejo"))
    })

    observeEvent(input$ask_send, {
      q <- trimws(input$ask_text %||% "")
      if (!nzchar(q)) { showNotification("Escriba primero su pregunta.", type = "warning"); return() }
      save_inputs()
      res <- run_claude(session, tm, function() tm$ask(prompt_free_question(q, "Bosquejo de la tesis"), tab = "bosquejo",
                                                       key = "bosquejo", action = "question", title = substr(q, 1, 70)))
      if (!is.null(res)) updateTextAreaInput(session, "ask_text", value = "")
    })

    feedback_panel_server(input, output, session, tm, tab = "bosquejo", keys_fun = reactive(NULL),
                          empty_msg = "Pida a Claude que revise su bosquejo y sus comentarios aparecerán aquí.")
  })
}
