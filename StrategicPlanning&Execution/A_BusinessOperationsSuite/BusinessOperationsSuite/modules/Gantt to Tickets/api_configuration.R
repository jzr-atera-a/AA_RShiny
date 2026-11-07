# modules/Gantt to Tickets/api_configuration.R
# Subtab: API Configuration (Trello + Jira credentials)

api_configuration_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Trello API Credentials", status = "primary", solidHeader = TRUE, width = 6,
          textInput(ns("trello_key"), "API Key:", ""),
          textInput(ns("trello_token"), "API Token:", ""),
          textInput(ns("trello_board_id"), "Board ID (optional):", ""),
          actionButton(ns("test_trello"), "Test Connection", class = "btn-success"),
          br(), br(), htmlOutput(ns("trello_status"))),
      box(title = "Jira API Credentials", status = "info", solidHeader = TRUE, width = 6,
          textInput(ns("jira_url"), "Jira URL:", placeholder = "https://your-domain.atlassian.net"),
          textInput(ns("jira_email"), "Email:", ""),
          passwordInput(ns("jira_token"), "API Token:", ""),
          textInput(ns("jira_project_key"), "Project Key:", placeholder = "PROJ"),
          actionButton(ns("test_jira"), "Test Connection", class = "btn-success"),
          br(), br(), htmlOutput(ns("jira_status")))
    ),
    fluidRow(
      box(title = "Instructions", status = "warning", width = 12,
          HTML("<h4>How to get your API credentials:</h4>
               <p><strong>Trello:</strong></p>
               <ul>
                 <li>API Key: Visit <a href='https://trello.com/app-key' target='_blank'>https://trello.com/app-key</a></li>
                 <li>Token: Click on 'Token' link on the same page and authorize</li>
                 <li>Board ID: Open your board, it's in the URL: trello.com/b/<strong>BOARD_ID</strong>/board-name</li>
               </ul>
               <p><strong>Jira:</strong></p>
               <ul>
                 <li>URL: Your Jira instance URL (e.g., https://yourcompany.atlassian.net)</li>
                 <li>Email: Your Jira account email</li>
                 <li>API Token: Go to <a href='https://id.atlassian.com/manage-profile/security/api-tokens' target='_blank'>Atlassian Account Settings</a> > Security > Create API token</li>
                 <li>Project Key: The short code for your project (visible in project settings)</li>
               </ul>"))
    )
  )
}

api_configuration_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_trello, {
      tryCatch({
        api_manager$set_trello_credentials(key = input$trello_key, token = input$trello_token, board_id = input$trello_board_id)
        result <- api_manager$test_trello_connection()
        output$trello_status <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                    paste(" ✓ Connected as:", result$name)))
        showNotification("✓ Trello connected!", type = "message")
      }, error = function(e) {
        output$trello_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " ✗ ", e$message))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$test_jira, {
      tryCatch({
        api_manager$set_jira_credentials(url = input$jira_url, email = input$jira_email,
                                          token = input$jira_token, project_key = input$jira_project_key)
        result <- api_manager$test_jira_connection()
        output$jira_status <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                  paste(" ✓ Connected as:", result$name)))
        showNotification("✓ Jira connected!", type = "message")
      }, error = function(e) {
        output$jira_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " ✗ ", e$message))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$trello_status <- renderUI({ tags$div() })
    output$jira_status <- renderUI({ tags$div() })
  })
}
