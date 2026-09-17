# modules/Project Application/openai_config.R
# Subtab: OpenAI API Config (under the "Project Application" main tab)
# Kept separate from API Settings because this key is only used by this
# suite (ChatGPT-based generation buttons + the Diagram Generator).

openai_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "OpenAI API Configuration", status = "primary", solidHeader = TRUE, width = 12,
        p("Enter your OpenAI API key below. This key powers the ChatGPT-based generation buttons ",
          "in Project Details, Business Case, Team & Impact, and the Diagram Generator."),
        p("Get key from: ", tags$a(href = "https://platform.openai.com/api-keys", target = "_blank",
                                    style = "color: #7ec8e3;", "platform.openai.com/api-keys")),
        br(),
        passwordInput(ns("api_key"), "OpenAI API Key:", placeholder = "sk-...", width = "100%"),
        textInput(ns("openai_model"), "Model:", value = "gpt-4", width = "50%"),
        actionButton(ns("save_api"), "Save API Key", class = "btn-success", icon = icon("save")),
        actionButton(ns("test_api"), "Test API Connection", class = "btn-info", icon = icon("plug")),
        br(), br(),
        uiOutput(ns("api_status_ui")),
        br(),
        h4("Instructions:"),
        tags$ol(
          tags$li("Paste your OpenAI API key in the field above"),
          tags$li("Click 'Save API Key' to store it for this session"),
          tags$li("Click 'Test API Connection' to verify it works"),
          tags$li("Navigate to the other Project Application tabs to start generating content"),
          tags$li("(Claude is configured separately, under API Settings, and powers 'Claude Diagrams')")
        )
      )
    )
  )
}

openai_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    output$api_status_ui <- renderUI({ tags$div() })

    observeEvent(input$save_api, {
      if (nchar(trimws(input$api_key)) == 0) {
        output$api_status_ui <- renderUI(create_status_ui(FALSE, " Please enter a valid API key."))
        showNotification("Please enter a valid API key", type = "error", duration = 3)
        return()
      }
      api_manager$save_openai_config(input$api_key)
      api_manager$openai_model <- trimws(input$openai_model)

      output$api_status_ui <- renderUI(create_status_ui(TRUE, " API Key saved successfully!"))
      showNotification("OpenAI API Key saved successfully!", type = "message", duration = 3)
    })

    observeEvent(input$test_api, {
      if (!api_manager$openai_authenticated) {
        showNotification("Please save your API key first!", type = "error", duration = 3)
        return()
      }
      showNotification("Testing API connection...", type = "message", duration = NULL, id = "test_api")

      tryCatch({
        result <- api_manager$test_openai()
        removeNotification(id = "test_api")
        output$api_status_ui <- renderUI(create_status_ui(TRUE, paste0(" API connection successful! Response: ", result$text)))
        showNotification("API connection successful!", type = "message", duration = 5)
      }, error = function(e) {
        removeNotification(id = "test_api")
        output$api_status_ui <- renderUI(create_status_ui(FALSE, paste(" Connection failed:", e$message)))
        showNotification(paste("Error:", e$message), type = "error", duration = 5)
      })
    })
  })
}
