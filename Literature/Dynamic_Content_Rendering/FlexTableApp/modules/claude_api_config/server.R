# modules/claude_api_config/server.R
# Claude API Configuration Server Logic

claude_api_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_connection, {
      req(input$api_key)

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Testing connection...")
      })

      tryCatch({
        api_manager$set_claude_credentials(
          api_key = input$api_key,
          model = input$model,
          max_tokens = input$max_tokens,
          timeout = input$timeout
        )

        api_manager$test_claude_connection()

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Connection Successful!",
                   tags$br(),
                   tags$small("Model: ", input$model),
                   tags$br(),
                   tags$small("Timeout: ", input$timeout, " seconds"),
                   tags$br(),
                   tags$small("Status: Ready to generate tables"))
        })

        showNotification("✓ Claude API connection successful!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Connection Failed: ",
                   tags$br(),
                   tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })

    observeEvent(input$save_credentials, {
      req(input$api_key)

      api_manager$set_claude_credentials(
        api_key = input$api_key,
        model = input$model,
        max_tokens = input$max_tokens,
        timeout = input$timeout
      )

      showNotification("✓ Credentials saved successfully!", type = "message")

      output$status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Credentials Saved",
                 tags$br(),
                 tags$small("Model: ", input$model),
                 tags$br(),
                 tags$small("Max Tokens: ", input$max_tokens),
                 tags$br(),
                 tags$small("Timeout: ", input$timeout, " seconds"))
      })
    })

    output$status <- renderUI({ tags$div() })

    session$onSessionEnded(function() {})
  })
}
