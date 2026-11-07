# modules/Contact Manager/contacts_api_config/server.R

contacts_api_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_connection, {
      req(input$api_key)
      tryCatch({
        api_manager$set_contacts_openai_credentials(input$api_key, input$gpt_model)
        api_manager$test_contacts_openai_connection()
        output$api_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " ✓ Connected! Model: ", input$gpt_model)
        })
        showNotification("✓ OpenAI connected!", type = "message")
      }, error = function(e) {
        output$api_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Connection failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$api_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
