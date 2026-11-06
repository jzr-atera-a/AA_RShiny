# modules/API Configuration/claude_api_config/server.R

claude_api_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # where the current key came from (local key folder / environment / by hand)
    output$auto_note <- renderUI({
      invalidateLater(3000); st <- cred_status()
      if (!is.null(st$claude)) cred_banner(TRUE, st$claude, " You can still paste another key below.")
      else cred_banner(FALSE, cred_not_found_text("ap_claude_1_line.txt"))
    })
    # the typed key if there is one, otherwise the key that was loaded automatically
    key_in_use <- function() if (nzchar(trimws(input$api_key %||% ""))) trimws(input$api_key) else api_manager$claude_api_key

    observeEvent(input$test_connection, {
      req(key_in_use())

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Testing connection...")
      })

      tryCatch({
        api_manager$set_claude_credentials(
          api_key = key_in_use(), model = input$model,
          max_tokens = input$max_tokens, timeout = input$timeout
        )
        api_manager$test_claude_connection()
        if (nzchar(trimws(input$api_key %||% ""))) cred_set_status(claude = "Key typed in this tab (tested).")

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " ✓ Connection Successful!", tags$br(),
                   tags$small("Model: ", input$model), tags$br(),
                   tags$small("Timeout: ", input$timeout, " seconds"), tags$br(),
                   tags$small("Status: Ready for all three suites"))
        })

        showNotification("✓ Claude API connection successful!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Connection Failed: ", tags$br(), tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })

    observeEvent(input$save_credentials, {
      req(key_in_use())

      api_manager$set_claude_credentials(
        api_key = key_in_use(), model = input$model,
        max_tokens = input$max_tokens, timeout = input$timeout
      )
      if (nzchar(trimws(input$api_key %||% ""))) cred_set_status(claude = "Key typed in this tab (not tested yet).")

      showNotification("✓ Credentials saved successfully!", type = "message")

      output$status <- renderUI({
        tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                 " Credentials Saved", tags$br(),
                 tags$small("Model: ", input$model), tags$br(),
                 tags$small("Max Tokens: ", input$max_tokens), tags$br(),
                 tags$small("Timeout: ", input$timeout, " seconds"))
      })
    })

    observeEvent(input$run_diagnostics, {
      output$diagnostics_output <- renderText({ "Running diagnostics... check the R console for live detail." })

      lines <- tryCatch({
        api_manager$diagnose_network()
      }, error = function(e) {
        c(paste("Diagnostics failed to run:", e$message))
      })

      output$diagnostics_output <- renderText({ paste(lines, collapse = "\n") })
    })

    output$status <- renderUI({ tags$div() })
    output$diagnostics_output <- renderText({ "" })

    session$onSessionEnded(function() {})
  })
}
