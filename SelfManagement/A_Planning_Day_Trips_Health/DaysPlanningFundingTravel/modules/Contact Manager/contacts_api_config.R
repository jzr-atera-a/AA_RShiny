# modules/Contact Manager/contacts_api_config.R
# ---- module ----------------------------------------------
# id:           contacts_api_config
# name:         OpenAI Config
# icon:         key
# description:  OpenAI API credentials, local to this suite
# packages:     shiny, shinydashboard, httr, jsonlite
# -----------------------------------------------------------

# ---- UI ----
# OpenAI credentials - local to this suite only, per instruction. Kept as
# OpenAI (not the app's shared Claude connection) since this suite was
# purpose-built around it.

contacts_api_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "OpenAI API Configuration", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "alert alert-info",
              tags$strong("Note:"), " This suite uses OpenAI (not the shared Claude connection used by the ",
              "rest of the app) for contact extraction and message generation, matching how it was ",
              "originally built."),
          passwordInput(ns("api_key"), "OpenAI API Key:", placeholder = "sk-..."),
          selectInput(ns("gpt_model"), "Model:",
                      choices = c("GPT-4o" = "gpt-4o", "GPT-4 Turbo" = "gpt-4-turbo",
                                 "GPT-4" = "gpt-4", "GPT-3.5 Turbo" = "gpt-3.5-turbo"),
                      selected = "gpt-4o"),
          actionButton(ns("test_connection"), "Test Connection", class = "btn-success"),
          br(), br(),
          htmlOutput(ns("api_status"))
      )
    )
  )
}

# ---- Server ----
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
