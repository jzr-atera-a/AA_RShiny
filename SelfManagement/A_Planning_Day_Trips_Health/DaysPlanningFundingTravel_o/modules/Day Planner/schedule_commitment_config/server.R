# modules/Day Planner/schedule_commitment_config/server.R

schedule_commitment_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_trello, {
      req(input$trello_key, input$trello_token)
      tryCatch({
        api_manager$set_commitment_trello_credentials(input$trello_key, input$trello_token, input$trello_board_id)
        api_manager$test_commitment_trello_connection()
        output$trello_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Trello connected successfully!")
        })
        showNotification("✓ Trello connected!", type = "message")
      }, error = function(e) {
        output$trello_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Connection failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$trello_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
