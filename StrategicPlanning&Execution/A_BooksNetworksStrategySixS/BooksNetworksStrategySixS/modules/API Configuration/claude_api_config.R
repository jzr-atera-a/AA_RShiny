# modules/API Configuration/claude_api_config.R
# ---- module --------------------------------------------------------------------------------------
# id:           claude_api_config
# name:         Editing Tool API Configuration
# label:        Editing Tool API Config
# icon:         robot
# description:  Configure Anthropic Editing Tool API credentials
# packages:     shiny, shinydashboard, httr, jsonlite, curl
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

# Claude API Configuration UI

claude_api_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Editing Tool API Credentials",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        app_cred_box_ui(ns, "Claude key file ap_claude_1_line.txt"),
        h4("Configure Editing Tool API for Table Generation"),
        p("Enter your Anthropic API credentials to enable AI-powered comparison table generation."),

        fluidRow(
          column(6,
                 textInput(ns("api_key"),
                           "API Key:",
                           value = "",
                           placeholder = "sk-ant-api03-..."),

                 selectInput(ns("model"),
                             "Model:",
                             choices = c(
                               "Editing Tool Sonnet 4.6 (Recommended)" = "claude-sonnet-4-6",
                               "Editing Tool Opus 4.8 (Most Capable)" = "claude-opus-4-8",
                               "Editing Tool Haiku 4.5 (Fastest)" = "claude-haiku-4-5-20251001"
                             ),
                             selected = "claude-sonnet-4-6"),

                 numericInput(ns("max_tokens"),
                              "Max Tokens:",
                              value = 16000,
                              min = 1000,
                              max = 32000,
                              step = 1000),

                 numericInput(ns("timeout"),
                              "Request Timeout (seconds):",
                              value = 300,
                              min = 60,
                              max = 600,
                              step = 30),

                 div(class = "alert alert-info",
                     style = "margin-top: 10px;",
                     tags$strong("Timeout Info:"), br(),
                     "Wide tables (many columns) or many rows may need more time.", br(),
                     "Default: 300 seconds (5 minutes)", br(),
                     "Increase if you get timeout errors.")
          ),
          column(6,
                 h5("Actions:"),
                 actionButton(ns("test_connection"),
                              "Test Connection",
                              icon = icon("plug"),
                              class = "btn-info",
                              style = "width: 100%; margin-bottom: 10px;"),

                 actionButton(ns("save_credentials"),
                              "Save Credentials",
                              icon = icon("save"),
                              class = "btn-success",
                              style = "width: 100%;"),

                 br(), br(),
                 actionButton(ns("diagnose"),
                              "Run Network Diagnostics",
                              icon = icon("stethoscope"),
                              class = "btn-warning",
                              style = "width: 100%;"),
                 p(style = "color: #7f8c8d; font-size: 12px; margin-top: 5px;",
                   "Checks curl/SSL setup and reachability to api.anthropic.com without ",
                   "sending a real generation request. Full detail is printed to the R console."),

                 hr(),
                 h5("Connection Status:"),
                 htmlOutput(ns("status")),

                 hr(),
                 h5("Diagnostics Output:"),
                 htmlOutput(ns("diagnostics_output"))
          )
        )
      )
    )
  )
}

# ==== Server =======================================================================================

# Claude API Configuration Server Logic

claude_api_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    cred_tick <- reactiveVal(0)
    output$auto_key <- renderUI(app_cred_banner("claude", cred_tick))
    observeEvent(input$cred_load, {
      d <- trimws(input$cred_dir %||% ""); if (!nzchar(d)) { showNotification("Type the folder first.", type = "warning"); return() }
      app_cred_autoload(api_manager, dir = d, which = "claude", force = TRUE); cred_tick(cred_tick() + 1)
    })

    observeEvent(input$test_connection, {
      typed <- nzchar(trimws(input$api_key %||% ""))
      if (!typed && !(isTRUE(api_manager$claude_authenticated) && !is.null(api_manager$claude_api_key))) {
        showNotification("Paste a key first, or load one from the key folder.", type = "warning"); return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Testing connection...")
      })

      tryCatch({
        # empty box = test the key already loaded (for example from the key folder)
        api_manager$set_claude_credentials(
          api_key = if (typed) input$api_key else api_manager$claude_api_key,
          model = input$model,
          max_tokens = input$max_tokens,
          timeout = input$timeout
        )

        api_manager$test_claude_connection()

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Connection Successful!",
                   tags$br(),
                   tags$small("Model: ", input$model),
                   tags$br(),
                   tags$small("Timeout: ", input$timeout, " seconds"),
                   tags$br(),
                   tags$small("Status: Ready to generate tables"))
        })

        showNotification("✓ Editing Tool API connection successful!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Connection Failed: ",
                   tags$br(),
                   tags$small(app_err_text(e)))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error", duration = 10)
      })
    })

    observeEvent(input$save_credentials, {
      req(input$api_key)

      api_manager$set_claude_credentials(
        api_key = input$api_key,
        model = input$model,
        max_tokens = input$max_tokens,
        timeout = input$timeout
      )

      showNotification("✓ Credentials saved successfully!", type = "message")

      output$status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Credentials Saved",
                 tags$br(),
                 tags$small("Model: ", input$model),
                 tags$br(),
                 tags$small("Max Tokens: ", input$max_tokens),
                 tags$br(),
                 tags$small("Timeout: ", input$timeout, " seconds"))
      })
    })

    observeEvent(input$diagnose, {
      output$diagnostics_output <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Running diagnostics... check the R console for live detail.")
      })

      lines <- tryCatch({
        api_manager$diagnose_network()
      }, error = function(e) {
        c(paste("Diagnostics failed to run:", app_err_text(e)))
      })

      output$diagnostics_output <- renderUI({
        tags$div(class = "status-info",
                 tags$pre(style = "white-space: pre-wrap; font-size: 12px;",
                          paste(lines, collapse = "\n")))
      })
    })

    output$status <- renderUI({ tags$div() })
    output$diagnostics_output <- renderUI({ tags$div() })

  })
}
