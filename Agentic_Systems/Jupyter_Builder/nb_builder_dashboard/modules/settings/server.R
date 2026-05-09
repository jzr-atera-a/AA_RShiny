# ============================================================================
# SETTINGS MODULE - SERVER
# ============================================================================

settings_server <- function(id, session_mgr, python_bridge, session) {
  moduleServer(id, function(input, output, session) {

    # ── Populate from saved config on load ─────────────────────────────────
    observe({
      cfg <- session_mgr$config
      updateTextInput(session, "apiKey",      value = cfg$anthropic_api_key %||% "")
      updateSelectInput(session, "model",     selected = cfg$claude_model %||% "claude-opus-4-5")
      updateTextInput(session, "pythonPath",  value = cfg$python_env_path %||% "")
      updateTextInput(session, "contextDir",  value = cfg$context_dir %||% "")
      updateTextInput(session, "runsDir",     value = cfg$runs_dir %||% "")
      updateNumericInput(session, "maxCost",  value = cfg$max_cost_usd %||% 2.00)
      updateNumericInput(session, "maxTokens",value = cfg$max_tokens %||% 200000)
      updateNumericInput(session, "maxRetries",value = cfg$max_retries_per_cell %||% 3)
      updateNumericInput(session, "maxConsecFails", value = cfg$max_consec_fails %||% 3)
      updateCheckboxInput(session, "reviewEveryCell", value = cfg$review_every_cell %||% FALSE)
    })

    # ── Context file list ──────────────────────────────────────────────────
    output$contextFileList <- renderUI({
      ctx <- trimws(input$contextDir)
      if (nchar(ctx) == 0 || !dir.exists(ctx)) {
        return(div(class = "info-box", icon("folder"), " Enter a valid context folder above."))
      }
      files <- session_mgr$list_context_files(ctx)
      if (length(files) == 0) {
        return(div(class = "info-box", "No files found in context folder."))
      }
      tags$div(
        tags$b("Context files found (", length(files), "):"),
        tags$ul(lapply(files, function(f) tags$li(tags$code(f))))
      )
    })

    # ── Test Claude API ────────────────────────────────────────────────────
    observeEvent(input$testApiBtn, {
      key <- trimws(input$apiKey)
      if (nchar(key) == 0) {
        output$apiStatus <- renderText("✗ API key is empty.")
        return()
      }
      output$apiStatus <- renderText("Testing...")
      result <- tryCatch({
        resp <- httr::GET(
          "https://api.anthropic.com/v1/models",
          httr::add_headers(
            `x-api-key`         = key,
            `anthropic-version` = "2023-06-01"
          ),
          httr::timeout(10)
        )
        if (httr::status_code(resp) == 200) {
          "✓ Claude API connection successful!"
        } else {
          paste("✗ HTTP", httr::status_code(resp), httr::content(resp, "text"))
        }
      }, error = function(e) paste("✗ Error:", e$message))
      output$apiStatus <- renderText(result)
      if (startsWith(result, "✓")) {
        showNotification("✓ Claude API connected!", type = "message")
      } else {
        showNotification(result, type = "error")
      }
    })

    # ── Validate Python ────────────────────────────────────────────────────
    observeEvent(input$testPythonBtn, {
      py <- trimws(input$pythonPath)
      py <- if (nchar(py) == 0) NULL else py
      output$pythonStatus <- renderText("Validating...")
      result <- python_bridge$validate(py)
      output$pythonStatus <- renderText(
        if (result$ok) paste("✓", result$msg) else paste("✗", result$msg)
      )
      if (result$ok) {
        showNotification(paste("✓", result$msg), type = "message")
        # Update bridge path
        if (!is.null(py)) python_bridge$python_path <- py
      } else {
        showNotification(result$msg, type = "error")
      }
    })

    # ── Save all settings ──────────────────────────────────────────────────
    observeEvent(input$saveBtn, {
      cfg <- list(
        anthropic_api_key    = trimws(input$apiKey),
        claude_model         = input$model,
        python_env_path      = trimws(input$pythonPath),
        context_dir          = trimws(input$contextDir),
        runs_dir             = trimws(input$runsDir),
        max_cost_usd         = input$maxCost,
        max_tokens           = input$maxTokens,
        max_retries_per_cell = input$maxRetries,
        max_consec_fails     = input$maxConsecFails,
        review_every_cell    = input$reviewEveryCell,
        last_run_dir         = session_mgr$get("last_run_dir", "")
      )
      session_mgr$save_config(cfg)

      # Update python bridge path
      py <- trimws(input$pythonPath)
      if (nchar(py) > 0) python_bridge$python_path <- py

      output$saveStatus <- renderText(
        paste("✓ Saved at", format(Sys.time(), "%H:%M:%S"))
      )
      showNotification("✓ Settings saved!", type = "message")
    })
  })
}
