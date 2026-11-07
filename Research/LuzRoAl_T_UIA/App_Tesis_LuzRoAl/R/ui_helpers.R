# ============================================================================
# UI HELPERS shared by the modules
#   - run_claude(): calls Claude with a progress message and friendly errors
#   - feedback cards + panel server (list, follow-up questions, delete, use correction)
#   - js_btn(): button that sends {id, action} to Shiny (see www/js/app.js)
# ============================================================================

# Button that fires input[[input_id]] = list(id, action) through app.js
js_btn <- function(label, input_id, id, action, class = "btn-default", title = NULL, icon_name = NULL) {
  tags$button(type = "button", class = paste("btn js-evt", class), title = title,
              `data-input` = input_id, `data-id` = id, `data-action` = action,
              if (!is.null(icon_name)) icon(icon_name), label)
}

go_to_tab <- function(parent_session, tab) {
  shinydashboard::updateTabItems(parent_session, "sidebar_menu", selected = tab)
}

# Modal shown when Claude is not ready
claude_not_ready_modal <- function(ns, msg) {
  showModal(modalDialog(
    title = "Falta conectar a Claude",
    div(class = "big-message", p(msg),
        p("Vaya a la pestaña ", tags$b("Conexión con Claude"), ", escriba la clave y presione ", tags$b("Probar conexión"), ".")),
    footer = tagList(modalButton("Cerrar"),
                     actionButton(ns("goto_claude"), "Ir a Conexión con Claude", class = "btn-primary")),
    easyClose = TRUE
  ))
}

# Runs fn() (which calls Claude) with a progress bar. Returns its value, or NULL on error.
run_claude <- function(session, tm, fn, message = "Claude está leyendo y pensando…") {
  ns <- session$ns
  if (!tm$claude$has_key() || !tm$claude$connected) {
    claude_not_ready_modal(ns, if (!tm$claude$has_key()) "Todavía no hay una clave de Claude guardada." else "Claude todavía no está conectado.")
    return(NULL)
  }
  withProgress(message = message, detail = "Esto puede tardar entre 10 segundos y un par de minutos.", value = 0.3, {
    tryCatch({
      out <- fn()
      setProgress(1)
      out
    }, error = function(e) {
      tm$log("Claude error: ", conditionMessage(e))
      showModal(modalDialog(
        title = "No se pudo obtener la respuesta de Claude",
        div(class = "big-message", p(conditionMessage(e))),
        footer = modalButton("Entendido"), easyClose = TRUE
      ))
      NULL
    })
  })
}

ACTION_LABELS <- c(review = "Revisión", start = "Cómo empezar / seguir", correct = "Corrección de estilo",
                   question = "Pregunta", sources = "Fuentes sugeridas", idea = "Opinión sobre la idea",
                   topics = "Temas sugeridos", outline_review = "Revisión del bosquejo",
                   outline_propose = "Bosquejo propuesto", coherence = "Coherencia introducción–conclusiones")

# One stored Claude answer (with its follow-up conversation)
feedback_card <- function(fb, input_id, show_part = FALSE) {
  msgs <- fb$messages
  answers <- which(vapply(msgs, function(m) identical(m$role, "assistant"), logical(1)))
  last <- msgs[[answers[length(answers)]]]$content
  is_correct <- identical(fb$action, "correct")
  shown <- if (is_correct) {
    corr <- extract_tag(last, "texto_corregido")
    rest <- sub("(?s)<texto_corregido>.*?</texto_corregido>", "", last, perl = TRUE)
    tagList(if (!is.null(corr)) div(class = "corrected-text", corr), md_html(rest))
  } else md_html(last)

  # earlier turns of the conversation (follow-up questions)
  history <- NULL
  if (length(msgs) > 2) {
    turns <- msgs[3:(length(msgs) - 1)]
    history <- tags$details(class = "fb-history",
      tags$summary(sprintf("Ver la conversación completa (%d mensajes)", length(msgs))),
      div(md_html(msgs[[2]]$content)),
      lapply(turns, function(m) div(class = if (m$role == "user") "fb-q" else "fb-a",
                                    if (m$role == "user") tagList(tags$b("Usted preguntó: "), m$content) else md_html(m$content))))
    q <- msgs[[length(msgs) - 1]]$content
    shown <- tagList(div(class = "fb-q", tags$b("Usted preguntó: "), q), shown)
  }

  div(class = paste("fb-card", paste0("fb-", fb$action)),
      div(class = "fb-head",
          span(class = "fb-tag", ACTION_LABELS[[fb$action]] %||% fb$action),
          span(class = "fb-title", fb$title),
          span(class = "fb-time", fmt_fecha(fb$time))),
      div(class = "fb-body", shown),
      history,
      div(class = "fb-actions",
          if (is_correct) js_btn(" Usar esta versión corregida", input_id, fb$id, "use", "btn-success", icon_name = "check"),
          js_btn(" Seguir conversando", input_id, fb$id, "followup", "btn-primary", icon_name = "comments"),
          js_btn(" Borrar", input_id, fb$id, "delete", "btn-default fb-del", icon_name = "trash")))
}

# Server side of a feedback list. keys_fun(): reactive returning the feedback keys to show (NULL = all of the tab).
# on_use(fb, corrected_text): called when the user accepts a corrected text.
feedback_panel_server <- function(input, output, session, tm, tab, keys_fun, output_id = "feedback",
                                  on_use = NULL, empty_msg = "Aquí aparecerán los comentarios de Claude.") {
  ns <- session$ns
  evt <- paste0(output_id, "_evt")
  current_fb <- reactiveVal(NULL)

  output[[output_id]] <- renderUI({
    tm$fb_trigger(); tm$proj_trigger()
    fbs <- tm$feedback_for(keys = keys_fun(), tab = tab)
    if (!length(fbs)) return(div(class = "empty-state small", empty_msg))
    tagList(lapply(fbs, feedback_card, input_id = ns(evt)))
  })

  observeEvent(input[[evt]], {
    e <- input[[evt]]
    i <- tm$feedback_index(e$id)
    if (is.na(i)) return()
    fb <- tm$project$feedback[[i]]
    if (identical(e$action, "delete")) {
      current_fb(fb$id)
      showModal(modalDialog(title = "¿Borrar este comentario?",
                            p("Se quita de la lista. (La copia en la carpeta “retroalimentacion” se conserva.)"),
                            footer = tagList(modalButton("Cancelar"),
                                             actionButton(ns(paste0(output_id, "_del_ok")), "Sí, borrar", class = "btn-danger")),
                            easyClose = TRUE))
    } else if (identical(e$action, "followup")) {
      current_fb(fb$id)
      showModal(modalDialog(
        title = "Seguir conversando con Claude", size = "l", easyClose = TRUE,
        p(class = "wm-hint", "Claude recuerda esta conversación. Escriba su pregunta o comentario:"),
        textAreaInput(ns(paste0(output_id, "_fu_text")), NULL, rows = 5, width = "100%",
                      placeholder = "Por ejemplo: ¿Me puede dar un ejemplo de cómo delimitar mejor el periodo?"),
        footer = tagList(modalButton("Cancelar"),
                         actionButton(ns(paste0(output_id, "_fu_send")), "Enviar a Claude", class = "btn-success btn-big", icon = icon("paper-plane")))
      ))
    } else if (identical(e$action, "use") && !is.null(on_use)) {
      last <- fb$messages[[length(fb$messages)]]$content
      corr <- extract_tag(last, "texto_corregido")
      if (is.null(corr)) { showNotification("No se encontró el texto corregido en la respuesta.", type = "error"); return() }
      current_fb(fb$id)
      showModal(modalDialog(title = "¿Usar la versión corregida?",
        div(class = "big-message",
            p("Su texto actual se reemplazará por la versión corregida de Claude."),
            p("Antes se guarda una copia de su texto actual en ", tags$b("Versiones"), ", así que puede regresar a él.")),
        footer = tagList(modalButton("Cancelar"),
                         actionButton(ns(paste0(output_id, "_use_ok")), "Sí, usar la versión corregida", class = "btn-success")),
        easyClose = TRUE))
    }
  })

  observeEvent(input[[paste0(output_id, "_del_ok")]], {
    removeModal(); tm$delete_feedback(current_fb())
  })

  observeEvent(input[[paste0(output_id, "_fu_send")]], {
    q <- trimws(input[[paste0(output_id, "_fu_text")]] %||% "")
    if (!nzchar(q)) { showNotification("Escriba primero su pregunta.", type = "warning"); return() }
    removeModal()
    run_claude(session, tm, function() tm$follow_up(current_fb(), q))
  })

  observeEvent(input[[paste0(output_id, "_use_ok")]], {
    removeModal()
    i <- tm$feedback_index(current_fb()); if (is.na(i)) return()
    fb <- tm$project$feedback[[i]]
    corr <- extract_tag(fb$messages[[length(fb$messages)]]$content, "texto_corregido")
    on_use(fb, corr)
  })

  invisible(NULL)
}

# Observers every module needs once (the "go to Claude tab" button of the modal above)
setup_common <- function(input, parent_session) {
  observeEvent(input$goto_claude, { removeModal(); go_to_tab(parent_session, "claude_api") })
}

# "Ask Claude anything" box
ask_box_ui <- function(ns, id = "ask", placeholder = "Escriba aquí su pregunta para Claude…", rows = 3) {
  div(class = "ask-box",
      textAreaInput(ns(paste0(id, "_text")), "Pregúntele a Claude:", rows = rows, width = "100%", placeholder = placeholder),
      actionButton(ns(paste0(id, "_send")), "Preguntar", class = "btn-primary btn-big", icon = icon("paper-plane"),
                   style = "width: 100%;"))
}
