# modules/API Settings/claude_config.R
# Subtab: Claude API Config (under the "API Settings" main tab)

claude_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Claude (Anthropic) API Configuration",
        status = "primary", solidHeader = TRUE, width = 12,

        p("Enter your Anthropic API key below. This key is stored in-memory for the duration of your session ",
          "and is used by every AI feature in this app (contact extraction, message generation, communication ",
          "summaries, and Funding Programmes discovery)."),
        p("You can obtain an API key from: ",
          tags$a(href = "https://console.anthropic.com/settings/keys", target = "_blank",
                 style = "color: #7ec8e3;", "console.anthropic.com/settings/keys")),
        br(),

        passwordInput(ns("api_key"), "Anthropic API Key:", placeholder = "sk-ant-...", width = "100%"),
        textInput(ns("claude_model"), "Claude Model:", value = "claude-sonnet-4-5", width = "50%"),
        p(tags$small("See docs.anthropic.com/en/docs/about-claude/models for current model names.")),

        br(),
        actionButton(ns("save_api"), "Save API Key", class = "btn-success", icon = icon("save")),
        actionButton(ns("test_api"), "Test API Connection", class = "btn-info", icon = icon("plug")),
        br(), br(),
        uiOutput(ns("api_status_ui")),

        br(),
        h4("Instructions:"),
        tags$ol(
          tags$li("Paste your Anthropic API key in the field above"),
          tags$li("Confirm or change the model name"),
          tags$li("Click 'Save API Key' to store it for this session"),
          tags$li("Optionally click 'Test API Connection' to verify it works"),
          tags$li("Navigate to 'BigQuery Config' (still under API Settings) to configure the database connection")
        )
      )
    )
  )
}

claude_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    output$api_status_ui <- renderUI({ tags$div() })

    observeEvent(input$save_api, {
      if (nchar(trimws(input$api_key)) == 0) {
        output$api_status_ui <- renderUI({
          div(class = "api-status-error", icon("exclamation-circle"), " Please enter a valid API key.")
        })
        showNotification("Please enter a valid API key", type = "error", duration = 3)
        return()
      }

      api_manager$save_claude_config(input$api_key, input$claude_model)

      output$api_status_ui <- renderUI({
        div(class = "api-status-success", icon("check-circle"), " API Key saved successfully! Model: ", api_manager$claude_model)
      })
      showNotification("Claude API Key saved successfully!", type = "message", duration = 3)
    })

    observeEvent(input$test_api, {
      if (!api_manager$claude_authenticated) {
        showNotification("Please save your API key first!", type = "error", duration = 3)
        return()
      }

      showNotification("Testing Claude API connection...", type = "message", duration = NULL, id = "test_claude")

      tryCatch({
        result <- api_manager$test_claude()
        removeNotification(id = "test_claude")

        output$api_status_ui <- renderUI({
          div(class = "api-status-success", icon("check-circle"),
              " API connection successful! Model: ", api_manager$claude_model,
              tags$br(), tags$small("Response: ", result$text))
        })
        showNotification("Claude API connection successful!", type = "message", duration = 5)
      }, error = function(e) {
        removeNotification(id = "test_claude")
        output$api_status_ui <- renderUI({
          div(class = "api-status-error", icon("exclamation-circle"), " Connection error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
  })
}
