# modules/trello_jira_config.R
# Trello & Jira credentials - adapted from Atlassian_API.zip (gantt_api_config),
# wired to this app's shared `api_manager` object alongside BigQuery and Claude.

trello_jira_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    tags$h3("Trello & Jira \u2014 Atlassian API Configuration"),
    ua_callout("Shares the same api_manager object as the BigQuery and Claude API tabs. Once connected here, Trello/Jira access is available to any tab in this app that needs it (e.g. a future link between calendar events and a Trello board)."),

    fluidRow(
      box(title = "Trello API Credentials", status = "primary", solidHeader = TRUE, width = 6,
          textInput(ns("trello_key"), "API Key:", ""),
          textInput(ns("trello_token"), "API Token:", ""),
          textInput(ns("trello_board_id"), "Board ID (optional):", ""),
          actionButton(ns("test_trello"), "Test Connection", class = "btn-success"),
          br(), br(),
          htmlOutput(ns("trello_status"))
      ),
      box(title = "Jira API Credentials", status = "info", solidHeader = TRUE, width = 6,
          textInput(ns("jira_url"), "Jira URL:", placeholder = "https://your-domain.atlassian.net"),
          textInput(ns("jira_email"), "Email:", ""),
          passwordInput(ns("jira_token"), "API Token:", ""),
          textInput(ns("jira_project_key"), "Project Key:", placeholder = "PROJ"),
          actionButton(ns("test_jira"), "Test Connection", class = "btn-success"),
          br(), br(),
          htmlOutput(ns("jira_status"))
      )
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
               </ul>")
      )
    )
  )
}

trello_jira_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_trello, {
      req(input$trello_key, input$trello_token)
      tryCatch({
        api_manager$set_trello_credentials(input$trello_key, input$trello_token, input$trello_board_id)
        api_manager$test_trello_connection()
        output$trello_status <- renderUI({
          tags$div(style = "color:#27ae60;", icon("check-circle"), " Trello connected successfully!")
        })
        showNotification("\u2713 Trello connected!", type = "message")
      }, error = function(e) {
        output$trello_status <- renderUI({
          tags$div(style = "color:#c0392b;", icon("times-circle"), " Connection failed: ", e$message)
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
          tags$div(style = "color:#27ae60;", icon("check-circle"), " Jira connected successfully!")
        })
        showNotification("\u2713 Jira connected!", type = "message")
      }, error = function(e) {
        output$jira_status <- renderUI({
          tags$div(style = "color:#c0392b;", icon("times-circle"), " Connection failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$trello_status <- renderUI({ tags$div() })
    output$jira_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
