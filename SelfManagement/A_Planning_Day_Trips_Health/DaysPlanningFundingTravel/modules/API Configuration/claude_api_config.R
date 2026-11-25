# modules/API Configuration/claude_api_config.R
# ---- module ----------------------------------------------
# id:           claude_api_config
# name:         Claude API Config
# icon:         robot
# description:  Claude API credentials management, shared by all suites
# packages:     shiny, shinydashboard, httr, curl, jsonlite
# -----------------------------------------------------------

# ---- UI ----
claude_api_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Claude API Credentials",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        uiOutput(ns("auto_note")),
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

# ---- Server ----
claude_api_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # where the current key came from (local key folder / environment / by hand)
    output$auto_note <- renderUI({
      invalidateLater(3000); st <- cred_status()
      if (!is.null(st$claude)) cred_banner(TRUE, st$claude, " You can still paste another key below.")
      else cred_banner(FALSE, cred_not_found_text("ap_claude_1_line.txt"))
    })
    # the typed key if there is one, otherwise the key that was loaded automatically
    key_in_use <- function() if (nzchar(trimws(input$api_key %||% ""))) trimws(input$api_key) else api_manager$claude_api_key

    observeEvent(input$test_connection, {
      req(key_in_use())

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Testing connection...")
      })

      tryCatch({
        api_manager$set_claude_credentials(
          api_key = key_in_use(), model = input$model,
          max_tokens = input$max_tokens, timeout = input$timeout
        )
        api_manager$test_claude_connection()
        if (nzchar(trimws(input$api_key %||% ""))) cred_set_status(claude = "Key typed in this tab (tested).")

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " ✓ Connection Successful!", tags$br(),
                   tags$small("Model: ", input$model), tags$br(),
                   tags$small("Timeout: ", input$timeout, " seconds"), tags$br(),
                   tags$small("Status: Ready for all three suites"))
        })

        showNotification("✓ Claude API connection successful!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Connection Failed: ", tags$br(), tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })

    observeEvent(input$save_credentials, {
      req(key_in_use())

      api_manager$set_claude_credentials(
        api_key = key_in_use(), model = input$model,
        max_tokens = input$max_tokens, timeout = input$timeout
      )
      if (nzchar(trimws(input$api_key %||% ""))) cred_set_status(claude = "Key typed in this tab (not tested yet).")

      showNotification("✓ Credentials saved successfully!", type = "message")

      output$status <- renderUI({
        tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                 " Credentials Saved", tags$br(),
                 tags$small("Model: ", input$model), tags$br(),
                 tags$small("Max Tokens: ", input$max_tokens), tags$br(),
                 tags$small("Timeout: ", input$timeout, " seconds"))
      })
    })

    observeEvent(input$run_diagnostics, {
      output$diagnostics_output <- renderText({ "Running diagnostics... check the R console for live detail." })

      lines <- tryCatch({
        api_manager$diagnose_network()
      }, error = function(e) {
        c(paste("Diagnostics failed to run:", e$message))
      })

      output$diagnostics_output <- renderText({ paste(lines, collapse = "\n") })
    })

    output$status <- renderUI({ tags$div() })
    output$diagnostics_output <- renderText({ "" })

    session$onSessionEnded(function() {})
  })
}
