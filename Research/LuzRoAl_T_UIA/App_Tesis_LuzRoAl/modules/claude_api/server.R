claude_api_server <- function(id, tm, parent_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    cl <- tm$claude
    setup_common(input, parent_session)
    status_msg <- reactiveVal(NULL)

    # Fill the controls with the saved settings
    observeEvent(TRUE, once = TRUE, {
      cfg <- tm$config
      model <- cfg$claude_model %||% "claude-sonnet-5-5"
      if (model %in% CLAUDE_MODELS) updateSelectInput(session, "model", selected = model)
      else { updateSelectInput(session, "model", selected = "__other__"); updateTextInput(session, "model_other", value = model) }
      updateNumericInput(session, "max_tokens", value = cfg$claude_max_tokens %||% 4000)
      updateNumericInput(session, "timeout", value = cfg$claude_timeout %||% 300)
      updateCheckboxInput(session, "remember", value = isTRUE(cfg$remember_key))
    })

    chosen_model <- function() {
      if (identical(input$model, "__other__")) trimws(input$model_other %||% "") else input$model
    }

    apply_inputs <- function() {
      key <- trimws(input$api_key %||% "")
      cl$set_credentials(api_key = if (nzchar(key)) key else NULL, model = chosen_model(),
                         max_tokens = input$max_tokens, timeout = input$timeout)
      tm$set_config(claude_model = cl$model, claude_max_tokens = cl$max_tokens, claude_timeout = cl$timeout)
      tm$remember_key(isTRUE(input$remember))
    }

    do_test <- function(quiet = FALSE) {
      withProgress(message = "Probando la conexión con Claude…", value = 0.5, {
        ok <- tryCatch({ cl$test(); TRUE }, error = function(e) { status_msg(list(ok = FALSE, msg = conditionMessage(e))); FALSE })
      })
      if (ok) {
        status_msg(list(ok = TRUE, msg = paste("Conectado con el modelo", cl$model)))
        tm$log("Claude connected: ", cl$model)
        if (!quiet) showNotification("✔ ¡Claude está conectado!", type = "message", duration = 5)
      } else if (!quiet) showNotification("No se pudo conectar. Vea el mensaje en rojo.", type = "error", duration = 8)
      tm$save_usage()
      bump(tm$claude_trigger)
      tm$touch()
      ok
    }

    observeEvent(input$test, {
      apply_inputs()
      if (!cl$has_key()) { status_msg(list(ok = FALSE, msg = "Escriba primero la clave de Claude.")); return() }
      do_test()
    })

    observeEvent(input$save, {
      apply_inputs()
      showNotification("✔ Ajustes guardados", type = "message")
      if (cl$has_key() && !cl$connected) do_test(quiet = TRUE)
    })

    # If a key was remembered, connect quietly when the app opens
    observeEvent(TRUE, once = TRUE, {
      if (cl$has_key() && !cl$connected) do_test(quiet = TRUE)
    })

    output$keyInfo <- renderUI({
      tm$claude_trigger()
      if (cl$has_key()) div(class = "wm-hint", "Clave guardada en esta sesión: ", tags$code(cl$masked_key()),
                            " — deje el campo vacío para seguir usándola.")
    })

    output$status <- renderUI({
      tm$claude_trigger()
      s <- status_msg()
      if (cl$connected) {
        div(class = "places-ok", icon("check-circle"), tags$b(" Claude está conectado y listo."),
            br(), sprintf("Modelo: %s", cl$model),
            if (!is.null(cl$last_test)) span(sprintf(" · probado: %s", fmt_fecha(cl$last_test))))
      } else if (!is.null(s) && !isTRUE(s$ok)) {
        div(class = "places-pending error-box", icon("times-circle"), tags$b(" No se pudo conectar"), br(), s$msg)
      } else {
        div(class = "places-pending", icon("info-circle"), " Claude todavía no está conectado. Escriba la clave y presione ",
            tags$b("Probar conexión"), ".")
      }
    })

    output$stats <- renderUI({
      tm$claude_trigger()
      div(class = "stat-row",
          stat_tile("Estado", if (cl$connected) "Conectado" else "Sin conectar",
                    if (cl$connected) cl$model else "Falta probar la conexión", if (cl$connected) "green" else "red"),
          stat_tile("Consultas a Claude", fmt_int(cl$calls), "Desde que se instaló la app", "purple"),
          stat_tile("Texto procesado", HTML(sprintf("%s <small>tokens</small>", fmt_int(cl$tokens_in + cl$tokens_out))),
                    sprintf("Enviados %s · recibidos %s", fmt_int(cl$tokens_in), fmt_int(cl$tokens_out)), "orange"))
    })

    observeEvent(input$ask_send, {
      q <- trimws(input$ask_text %||% "")
      if (!nzchar(q)) { showNotification("Escriba primero su pregunta.", type = "warning"); return() }
      res <- run_claude(session, tm, function() tm$ask(prompt_free_question(q), tab = "claude_api", key = "prueba",
                                                       action = "question", title = substr(q, 1, 70)))
      if (!is.null(res)) updateTextAreaInput(session, "ask_text", value = "")
    })

    feedback_panel_server(input, output, session, tm, tab = "claude_api", keys_fun = reactive(NULL),
                          empty_msg = "La respuesta aparecerá aquí.")
  })
}
