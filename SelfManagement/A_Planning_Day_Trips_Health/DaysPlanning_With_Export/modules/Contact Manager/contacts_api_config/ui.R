# modules/Contact Manager/contacts_api_config/ui.R
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
