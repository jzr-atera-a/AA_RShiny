# modules/API Configuration/claude_api_config/ui.R

claude_api_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Claude API Credentials",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("Configure Claude API — shared by every suite"),
        p("One connection powers Day Planner's schedule generation, Events Scheduling's event search, ",
          "and Funding Programmes' programme discovery."),

        fluidRow(
          column(6,
                 textInput(ns("api_key"), "API Key:", value = "", placeholder = "sk-ant-api03-..."),

                 selectInput(ns("model"), "Model:",
                             choices = c(
                               "Claude Sonnet 4.6 (Recommended)" = "claude-sonnet-4-6",
                               "Claude Opus 4.8 (Most Capable)" = "claude-opus-4-8",
                               "Claude Haiku 4.5 (Fastest)" = "claude-haiku-4-5-20251001"
                             ),
                             selected = "claude-sonnet-4-6"),

                 numericInput(ns("max_tokens"), "Max Tokens:", value = 8000, min = 1000, max = 32000, step = 1000),
                 numericInput(ns("timeout"), "Request Timeout (seconds):", value = 180, min = 60, max = 900, step = 30),

                 div(class = "alert alert-info", style = "margin-top: 10px;",
                     tags$strong("Streaming enabled:"), " requests use Server-Sent Events so a corporate proxy ",
                     "sees continuous bytes rather than a long silence, which is the most common cause of a ",
                     "connection being dropped as \"idle\" partway through a longer generation.")
          ),
          column(6,
                 h5("Actions:"),
                 actionButton(ns("test_connection"), "Test Connection", icon = icon("plug"),
                              class = "btn-info", style = "width: 100%; margin-bottom: 10px;"),

                 actionButton(ns("save_credentials"), "Save Credentials", icon = icon("save"),
                              class = "btn-success", style = "width: 100%; margin-bottom: 10px;"),

                 actionButton(ns("run_diagnostics"), "Run Network Diagnostics", icon = icon("stethoscope"),
                              class = "btn-warning", style = "width: 100%;"),

                 hr(),
                 h5("Connection Status:"),
                 htmlOutput(ns("status")),

                 h5("Diagnostics Output:", style = "margin-top: 15px;"),
                 verbatimTextOutput(ns("diagnostics_output"))
          )
        )
      )
    )
  )
}
