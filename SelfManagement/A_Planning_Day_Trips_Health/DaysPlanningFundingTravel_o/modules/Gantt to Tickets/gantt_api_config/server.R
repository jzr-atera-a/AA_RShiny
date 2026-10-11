# modules/Gantt to Tickets/gantt_api_config/server.R

gantt_api_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_trello, {
      req(input$trello_key, input$trello_token)
      tryCatch({
        api_manager$set_trello_credentials(input$trello_key, input$trello_token, input$trello_board_id)
        api_manager$test_trello_connection()
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

    observeEvent(input$test_jira, {
      req(input$jira_url, input$jira_email, input$jira_token)
      tryCatch({
        api_manager$set_jira_credentials(input$jira_url, input$jira_email, input$jira_token, input$jira_project_key)
        api_manager$test_jira_connection()
        output$jira_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Jira connected successfully!")
        })
        showNotification("✓ Jira connected!", type = "message")
      }, error = function(e) {
        output$jira_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Connection failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$trello_status <- renderUI({ tags$div() })
    output$jira_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
