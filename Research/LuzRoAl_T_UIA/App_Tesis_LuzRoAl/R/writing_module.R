# ============================================================================
# WRITING MODULE FACTORY
# Shared by the Introducción, Capítulos and Conclusiones tabs:
#   part selector (big pills) → editor with autosave + versions → Claude help + feedback
# kind = "intro" | "caps" | "concl"
# ============================================================================

WRITING_KINDS <- list(
  intro = list(tab = "introduccion", title = "Introducción", icon = "door-open",
               lead = "La introducción presenta el problema, la pregunta, los objetivos y el camino que seguirá la tesis. Escríbala por partes; muchas personas la terminan al final, cuando ya saben bien lo que encontraron."),
  caps = list(tab = "capitulos", title = "Capítulos", icon = "layer-group",
              lead = "Los capítulos son el cuerpo de la tesis. Salen del bosquejo: si quiere agregar, quitar o cambiar el nombre de un capítulo, hágalo en “Bosquejo de la tesis”."),
  concl = list(tab = "conclusion", title = "Conclusiones", icon = "flag-checkered",
               lead = "Las conclusiones responden la pregunta de la introducción, resumen los hallazgos y dicen qué aporta su tesis. Al final está la bibliografía.")
)

writing_module_ui <- function(id, kind) {
  ns <- NS(id)
  k <- WRITING_KINDS[[kind]]
  tagList(
    uiOutput(ns("stats")),
    fluidRow(column(12,
      box(width = NULL, status = "primary", solidHeader = TRUE,
          title = tagList(icon(k$icon), paste0(" ", k$title, ": elija la parte que quiere escribir")),
          p(class = "lead-text", k$lead),
          uiOutput(ns("partSelector"))))),
    fluidRow(
      column(7,
        box(width = NULL, status = "primary", solidHeader = TRUE, title = uiOutput(ns("partTitle"), inline = TRUE),
            uiOutput(ns("partGuide")),
            textAreaInput(ns("text"), NULL, rows = 18, width = "100%", resize = "vertical",
                          placeholder = "Escriba aquí. Todo se guarda solito mientras escribe."),
            uiOutput(ns("editorFooter")),
            div(class = "editor-buttons",
                actionButton(ns("saveNow"), "Guardar ahora", class = "btn-primary", icon = icon("save")),
                actionButton(ns("saveVersion"), "Guardar una versión", class = "btn-default", icon = icon("bookmark")),
                actionButton(ns("showVersions"), "Ver versiones anteriores", class = "btn-default", icon = icon("history"))))),
      column(5,
        box(width = NULL, status = "success", solidHeader = TRUE, title = tagList(icon("robot"), " Ayuda de Claude"),
            div(class = "claude-actions",
                actionButton(ns("aReview"), "Revisar mi texto", class = "btn-success btn-big", icon = icon("search")),
                actionButton(ns("aStart"), "Ayúdeme a empezar o a seguir", class = "btn-primary btn-big", icon = icon("lightbulb")),
                actionButton(ns("aCorrect"), "Corregir ortografía y estilo", class = "btn-default btn-big", icon = icon("spell-check")),
                if (kind == "caps") actionButton(ns("aSources"), "Sugerir fuentes", class = "btn-default btn-big", icon = icon("book")),
                if (kind == "concl") actionButton(ns("aCoherence"), "¿Responden a mi introducción?", class = "btn-default btn-big", icon = icon("balance-scale"))),
            ask_box_ui(ns, "ask", "Por ejemplo: ¿Cómo cito una entrevista que yo hice?", rows = 2),
            checkboxInput(ns("allFb"), "Mostrar los comentarios de todas las partes de esta pestaña", FALSE)),
        box(width = NULL, status = "info", solidHeader = TRUE, title = "Comentarios de Claude",
            uiOutput(ns("feedback"))))
    )
  )
}

writing_module_server <- function(id, tm, parent_session, kind) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    k <- WRITING_KINDS[[kind]]
    setup_common(input, parent_session)

    # ------------------------------------------------------------ parts
    parts <- reactive({
      tm$proj_trigger()
      if (kind == "intro") return(INTRO_PARTS)
      if (kind == "concl") return(CONCL_PARTS)
      caps <- tm$chapters()
      lapply(seq_along(caps), function(i) list(
        key = tm$chapter_key(caps[[i]]$id),
        titulo = sprintf("Capítulo %d. %s", i, if (nzchar(caps[[i]]$titulo %||% "")) caps[[i]]$titulo else "(sin título)"),
        short = sprintf("Cap. %d", i),
        guia = paste0(if (nzchar(caps[[i]]$descripcion %||% "")) paste0("<b>De su bosquejo:</b> ", htmltools::htmlEscape(caps[[i]]$descripcion), "<br>") else "",
                      CHAPTER_GUIDE),
        meta = as.numeric(tm$config$chapter_target %||% 4000)))
    })

    # Status of each part (only changes when a part goes from empty to written, etc.)
    part_status <- reactiveVal(NULL)
    observe({
      ps <- parts()
      st <- vapply(ps, function(p) paste(p$key, p$titulo, tm$words(p$key) > 0, tm$words(p$key) >= (p$meta %||% 1)), character(1))
      if (!identical(st, isolate(part_status()))) part_status(st)
    })

    selected_key <- reactiveVal(NULL)

    output$partSelector <- renderUI({
      part_status()
      ps <- isolate(parts())
      if (!length(ps)) {
        return(div(class = "empty-state",
                   p("Todavía no hay capítulos en su bosquejo."),
                   actionButton(ns("goOutline"), "Ir a Bosquejo de la tesis", class = "btn-primary btn-big", icon = icon("sitemap"))))
      }
      keys <- vapply(ps, function(p) p$key, character(1))
      sel <- isolate(selected_key())
      if (is.null(sel) || !(sel %in% keys)) sel <- keys[1]
      labels <- lapply(ps, function(p) {
        w <- tm$words(p$key)
        mark <- if (w >= (p$meta %||% 1)) "✔ " else if (w > 0) "✎ " else ""
        HTML(paste0(mark, htmltools::htmlEscape(if (kind == "caps") p$titulo else p$titulo),
                    "<span class='pill-words'>", fmt_int(w), " pal.</span>"))
      })
      div(class = "part-pills",
          radioButtons(ns("part"), NULL, choiceNames = labels, choiceValues = keys, selected = sel, inline = TRUE))
    })
    observeEvent(input$goOutline, go_to_tab(parent_session, "bosquejo"))

    current_part <- reactive({
      ps <- parts(); req(length(ps) > 0)
      key <- input$part %||% ps[[1]]$key
      p <- Filter(function(x) identical(x$key, key), ps)
      if (!length(p)) ps[[1]] else p[[1]]
    })

    # ------------------------------------------------------------ editor (autosave)
    loaded_key <- reactiveVal(NULL)
    frozen <- reactiveVal(FALSE)
    last_saved <- reactiveVal(NULL)

    save_current <- function(text = isolate(input$text)) {
      key <- isolate(loaded_key())
      if (is.null(key) || isolate(frozen()) || is.null(text)) return(invisible(FALSE))
      changed <- tm$set_text(key, text)
      if (isTRUE(changed)) last_saved(Sys.time())
      invisible(changed)
    }

    observeEvent(current_part()$key, {
      new_key <- current_part()$key
      if (identical(new_key, loaded_key())) return()
      save_current()                         # flush the part we are leaving
      selected_key(new_key)
      txt <- tm$get_text(new_key)
      loaded_key(new_key)
      if (!identical(isolate(input$text) %||% "", txt)) {
        frozen(TRUE)
        updateTextAreaInput(session, "text", value = txt)
      }
    }, ignoreNULL = TRUE)

    # Another work folder was opened: show its text
    observeEvent(tm$load_trigger(), {
      key <- loaded_key(); if (is.null(key)) return()
      txt <- tm$get_text(key)
      if (!identical(isolate(input$text) %||% "", txt)) { frozen(TRUE); updateTextAreaInput(session, "text", value = txt) }
    }, ignoreInit = TRUE)

    text_d <- debounce(reactive(input$text), reactive(1000 * as.numeric(tm$config$autosave_secs %||% 2)))

    observeEvent(input$text, {
      if (frozen() && identical(input$text, tm$get_text(loaded_key()))) frozen(FALSE)
    })
    observeEvent(text_d(), { if (!frozen()) save_current(text_d()) })
    observeEvent(input$saveNow, {
      frozen(FALSE); save_current(input$text)
      showNotification("✔ Guardado", type = "message", duration = 3)
    })
    session$onSessionEnded(function() isolate(save_current()))

    output$partTitle <- renderUI({ p <- current_part(); span(p$titulo) })
    output$partGuide <- renderUI({
      p <- current_part()
      div(class = "info-box-tpl part-guide", HTML(paste0("<b style='color:#667eea;'>📝 Qué escribir aquí:</b> ", p$guia)))
    })

    output$editorFooter <- renderUI({
      p <- current_part()
      w <- word_count(input$text)
      meta <- p$meta %||% 0
      saved <- last_saved()
      upd <- tm$get_updated(p$key)
      div(class = "editor-footer",
          div(class = "ef-words", tags$b(fmt_int(w)), " palabras",
              if (meta > 0) span(class = "ef-meta", sprintf(" · meta orientativa: %s", fmt_int(meta)))),
          if (meta > 0) progress_bar(100 * w / meta),
          div(class = "ef-saved",
              if (!is.null(saved)) span(class = "status-ok", icon("check"), " Guardado a las ", format(saved, "%H:%M:%S"))
              else if (nzchar(upd)) span(class = "status-ok", icon("check"), " Guardado: ", fmt_fecha(upd))
              else span(style = "color:#8a93a6;", "Se guarda solito mientras escribe")))
    })

    # ------------------------------------------------------------ versions
    observeEvent(input$saveVersion, {
      save_current(input$text)
      f <- tm$snapshot(current_part()$key, "versión guardada por el usuario")
      if (is.null(f)) showNotification("No hay texto para guardar todavía.", type = "warning")
      else showNotification("✔ Versión guardada. La puede ver en “Ver versiones anteriores”.", type = "message", duration = 5)
    })

    output$versionsList <- renderUI({
      tm$proj_trigger(); input$saveVersion
      vs <- tm$versions(current_part()$key)
      if (!length(vs)) return(p("Todavía no hay versiones guardadas de esta parte."))
      tagList(lapply(vs, function(f) {
        stamp <- sub(".*_(\\d{8}_\\d{6})\\.md$", "\\1", basename(f))
        when <- fmt_fecha(as.POSIXct(stamp, format = "%Y%m%d_%H%M%S"))
        txt <- read_utf8(f); txt <- sub("^<!--.*?-->\\n?", "", txt)
        div(class = "version-row",
            div(tags$b(when), span(class = "wm-hint", sprintf("  ·  %s palabras", fmt_int(word_count(txt))))),
            div(class = "version-preview", substr(txt, 1, 280), if (nchar(txt) > 280) "…"),
            js_btn(" Regresar a esta versión", ns("verEvt"), basename(f), "restore", "btn-primary", icon_name = "undo"))
      }))
    })
    observeEvent(input$showVersions, {
      showModal(modalDialog(title = paste("Versiones anteriores —", current_part()$titulo), size = "l", easyClose = TRUE,
                            div(class = "versions-box", uiOutput(ns("versionsList"))),
                            footer = modalButton("Cerrar")))
    })
    observeEvent(input$verEvt, {
      f <- file.path(tm$work_dir(), "versiones", input$verEvt$id)
      if (!file.exists(f)) return()
      key <- current_part()$key
      save_current(input$text)
      tm$snapshot(key, "antes de regresar a una versión anterior")
      txt <- sub("^<!--.*?-->\\n?", "", read_utf8(f))
      tm$set_text(key, txt)
      frozen(TRUE)
      updateTextAreaInput(session, "text", value = txt)
      removeModal()
      showNotification("✔ Se recuperó la versión. Su texto anterior quedó guardado como versión.", type = "message", duration = 6)
    })

    # ------------------------------------------------------------ Claude
    extra_context <- function() {
      p <- current_part()
      if (kind == "caps") paste0("Este es el capítulo: ", p$titulo, "\n\n")
      else ""
    }
    ask_part <- function(prompt, action, title, max_tokens = NULL) {
      p <- current_part()
      save_current(input$text)
      run_claude(session, tm, function() tm$ask(prompt, tab = k$tab, key = p$key, action = action,
                                                title = paste(title, "—", p$titulo), max_tokens = max_tokens))
    }
    need_text <- function() {
      if (!nzchar(trimws(input$text %||% ""))) {
        showNotification("Primero escriba algo en esta parte (aunque sea un borrador).", type = "warning", duration = 6)
        return(FALSE)
      }
      TRUE
    }

    observeEvent(input$aReview, {
      if (!need_text()) return()
      p <- current_part()
      ask_part(prompt_section_review(p$titulo, gsub("<[^>]+>", "", p$guia), input$text, extra_context()), "review", "Revisión")
    })
    observeEvent(input$aStart, {
      p <- current_part()
      ask_part(prompt_section_start(p$titulo, gsub("<[^>]+>", "", p$guia), input$text %||% "", extra_context()), "start", "Cómo seguir")
    })
    observeEvent(input$aCorrect, {
      if (!need_text()) return()
      n <- word_count(input$text)
      ask_part(prompt_section_correct(input$text), "correct", "Corrección",
               max_tokens = max(as.integer(tm$claude$max_tokens), min(16000L, as.integer(n * 3 + 800))))
    })
    observeEvent(input$aSources, {
      p <- current_part()
      ask_part(prompt_sources(p$titulo, input$text %||% "", extra_context()), "sources", "Fuentes")
    })
    observeEvent(input$aCoherence, {
      intro <- paste(vapply(INTRO_PARTS, function(x) paste0("## ", x$titulo, "\n", tm$get_text(x$key)), character(1)), collapse = "\n\n")
      concl <- paste(vapply(Filter(function(x) x$key != "concl_biblio", CONCL_PARTS), function(x)
        paste0("## ", x$titulo, "\n", tm$get_text(x$key)), character(1)), collapse = "\n\n")
      if (word_count(intro) < 30 || word_count(concl) < 30) {
        showNotification("Para comparar, necesita tener escrito algo de la introducción y de las conclusiones.", type = "warning", duration = 7)
        return()
      }
      ask_part(prompt_conclusion_coherence(intro, concl), "coherence", "Coherencia")
    })
    observeEvent(input$ask_send, {
      q <- trimws(input$ask_text %||% "")
      if (!nzchar(q)) { showNotification("Escriba primero su pregunta.", type = "warning"); return() }
      p <- current_part()
      res <- ask_part(paste0(prompt_free_question(q, paste(k$title, "—", p$titulo)),
                             if (nzchar(trimws(input$text %||% ""))) paste0("\n\n=== LO QUE LLEVO ESCRITO EN ESTA PARTE ===\n", clip_text(input$text, 8000)) else ""),
                      "question", "Pregunta")
      if (!is.null(res)) updateTextAreaInput(session, "ask_text", value = "")
    })

    feedback_panel_server(input, output, session, tm, tab = k$tab,
      keys_fun = reactive(if (isTRUE(input$allFb)) NULL else current_part()$key),
      on_use = function(fb, corrected) {
        key <- fb$key
        tm$snapshot(key, "antes de usar la corrección de Claude")
        tm$set_text(key, corrected)
        if (identical(key, loaded_key())) { frozen(TRUE); updateTextAreaInput(session, "text", value = corrected) }
        showNotification("✔ Se usó la versión corregida. Su texto anterior quedó en “Versiones”.", type = "message", duration = 6)
      },
      empty_msg = "Cuando le pida ayuda a Claude, sus comentarios aparecerán aquí y quedarán guardados.")

    # ------------------------------------------------------------ stats row
    output$stats <- renderUI({
      tm$proj_trigger()
      ps <- parts()
      w <- sum(vapply(ps, function(p) tm$words(p$key), numeric(1)))
      meta <- sum(vapply(ps, function(p) as.numeric(p$meta %||% 0), numeric(1)))
      done <- sum(vapply(ps, function(p) tm$words(p$key) > 0, logical(1)))
      nfb <- length(tm$feedback_for(tab = k$tab))
      div(class = "stat-row",
          stat_tile(paste("Palabras en", k$title), fmt_int(w), if (meta > 0) sprintf("Meta orientativa: %s", fmt_int(meta)),
                    "green", if (meta > 0) 100 * w / meta),
          stat_tile("Partes con texto", HTML(sprintf("%d <small>de %d</small>", done, length(ps))), NULL, "purple",
                    if (length(ps)) 100 * done / length(ps)),
          stat_tile("Comentarios de Claude", nfb, "Quedan guardados en su carpeta de trabajo", "orange"))
    })
  })
}
