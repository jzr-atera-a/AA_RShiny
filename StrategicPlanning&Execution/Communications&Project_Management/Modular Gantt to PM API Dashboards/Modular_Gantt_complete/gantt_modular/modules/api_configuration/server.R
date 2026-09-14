# modules/api_configuration/server.R
# API Configuration Server Logic
# ==============================

api_configuration_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Test Trello Connection
    observeEvent(input$test_trello, {
      tryCatch({
        api_manager$set_trello_credentials(
          key = input$trello_key,
          token = input$trello_token,
          board_id = input$trello_board_id
        )
        
        result <- api_manager$test_trello_connection()
        
        output$trello_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   paste(" ✓ Connected as:", result$name))
        })
        
        showNotification("✓ Trello connected!", type = "message")
        
      }, error = function(e) {
        output$trello_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " ✗ ",
                   e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Test Jira Connection
    observeEvent(input$test_jira, {
      tryCatch({
        api_manager$set_jira_credentials(
          url = input$jira_url,
          email = input$jira_email,
          token = input$jira_token,
          project_key = input$jira_project_key
        )
        
        result <- api_manager$test_jira_connection()
        
        output$jira_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   paste(" ✓ Connected as:", result$name))
        })
        
        showNotification("✓ Jira connected!", type = "message")
        
      }, error = function(e) {
        output$jira_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " ✗ ",
                   e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Default outputs
    output$trello_status <- renderUI({ tags$div() })
    output$jira_status <- renderUI({ tags$div() })
  })
}
