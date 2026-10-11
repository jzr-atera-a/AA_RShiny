# modules/econ_api_config.R
#
# "API Configuration" — BigQuery + Claude credentials for the Economic
# Calendars feature. Adapted from business_operations_suite's
# bigquery_auth/claude_api_config modules, condensed into this app's
# one-file-per-module convention. Nothing here is required for the rest of
# the app to function — only the new Economic Calendars subtabs depend on it.

# ---- BigQuery tab ---------------------------------------------------------
econ_bigquery_auth_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$h3("BigQuery \u2014 Economic Calendar Data"),
    ua_callout(paste0(
      "Connects to the shared GCP project (\u201catera-2\u201d), dataset \u201cbusiness_strategy\u201d \u2014 the official ",
      "dataset for this app, shared with the Business Operations suite \u2014 table \u201ceconomic_calendar_summary\u201d, ",
      "a name of this app's own within that dataset (deliberately not \u201ceconomic_calendar\u201d, to avoid colliding ",
      "with a same-named table created elsewhere with different columns). Uses a service-account JSON key. The ",
      "table is created automatically on first connect if it doesn't already exist \u2014 nothing already stored is ",
      "ever altered or dropped."
    )),
    fluidRow(
      box(title = "Connection Settings", status = "primary", solidHeader = TRUE, width = 5,
          textInput(ns("project_id"), "GCP Project ID:", value = "atera-2"),
          textInput(ns("dataset_id"), "BigQuery Dataset:", value = "business_strategy"),
          tags$hr(),
          fileInput(ns("json_file"), "Service Account JSON (file):", accept = ".json"),
          tags$p("\u2014 or \u2014", style = "text-align:center; color:#999; font-size:12px;"),
          textAreaInput(ns("json_text"), "Paste JSON contents:", rows = 5, placeholder = "{ \"type\": \"service_account\", ... }"),
          actionButton(ns("authenticate"), "Connect & Prepare Table", icon = icon("plug"), class = "btn-primary", width = "100%"),
          uiOutput(ns("auth_status"))
      ),
      box(title = "Test Query", status = "info", solidHeader = TRUE, width = 7,
          actionButton(ns("test_query"), "Run Test Query (SELECT * LIMIT 5)", icon = icon("play")),
          uiOutput(ns("test_status")),
          DT::dataTableOutput(ns("test_table"))
      )
    )
  )
}

econ_bigquery_auth_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$authenticate, {
      if (trimws(input$project_id) == "" || trimws(input$dataset_id) == "") {
        output$auth_status <- renderUI(tags$div(style="color:#c0392b; margin-top:8px;", "Please fill in Project ID and Dataset ID"))
        return()
      }
      tryCatch({
        api_manager$set_bigquery_credentials(trimws(input$project_id), trimws(input$dataset_id))

        if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
          api_manager$authenticate_bigquery(json_path = input$json_file$datapath)
        } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
          api_manager$authenticate_bigquery(json_text = input$json_text)
        } else {
          stop("Please provide credentials via file upload or pasted text")
        }

        output$auth_status <- renderUI(tags$div(style="color:#27ae60; margin-top:8px;",
          icon("check-circle"), " Connected. Table ready: ", tags$code(api_manager$bq_full_table_economic_calendar)))
        showNotification("\u2713 BigQuery connected \u2014 economic_calendar_summary table ready", type = "message")
      }, error = function(e) {
        output$auth_status <- renderUI(tags$div(style="color:#c0392b; margin-top:8px;",
          icon("times-circle"), " Failed: ", e$message))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$test_query, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate first!", type = "error")
        return()
      }
      tryCatch({
        d <- api_manager$bq_query(sprintf("SELECT * FROM `%s` LIMIT 5", api_manager$bq_full_table_economic_calendar))
        output$test_status <- renderUI(tags$div(style="color:#27ae60;", sprintf("Retrieved %d row(s)", nrow(d))))
        output$test_table <- DT::renderDataTable(DT::datatable(d, options = list(scrollX = TRUE, pageLength = 5), rownames = FALSE))
      }, error = function(e) {
        output$test_status <- renderUI(tags$div(style="color:#c0392b;", "Query failed: ", e$message))
      })
    })

    output$auth_status <- renderUI(tags$div())
    output$test_status <- renderUI(tags$div())
    output$test_table  <- DT::renderDataTable(DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE))
  })
}

# ---- Claude API tab ---------------------------------------------------------
econ_claude_config_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$h3("Claude API \u2014 Calendar Summary Generation"),
    ua_callout("Uses a streaming connection (SSE), which keeps small chunks of data flowing continuously and avoids the ~60s idle-connection timeout some corporate networks/VPNs impose on plain long-running requests."),
    fluidRow(
      box(title = "Credentials", status = "primary", solidHeader = TRUE, width = 5,
          passwordInput(ns("api_key"), "Anthropic API Key:", placeholder = "sk-ant-..."),
          selectInput(ns("model"), "Model:", choices = c("claude-sonnet-4-6", "claude-opus-5", "claude-haiku-4-5-20251001"), selected = "claude-sonnet-4-6"),
          numericInput(ns("max_tokens"), "Max Tokens:", value = 8000, min = 1000, max = 64000, step = 500),
          numericInput(ns("timeout"), "Timeout (seconds):", value = 120, min = 30, max = 300),
          actionButton(ns("test_connection"), "Test Connection", icon = icon("plug")),
          actionButton(ns("save_credentials"), "Save Credentials", icon = icon("save"), class = "btn-primary"),
          uiOutput(ns("status"))
      ),
      box(title = "Notes", status = "info", solidHeader = TRUE, width = 7,
          tags$p("The Daily/Weekly Trend Summary tab calls Claude with the web_search tool enabled, so it looks up real, currently-scheduled or already-released events from reputable sources rather than generating dates/figures from training data alone."),
          tags$p("Your API key is kept in-session only (server memory), never written to disk or logged.")
      )
    )
  )
}

econ_claude_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_connection, {
      req(input$api_key)
      tryCatch({
        api_manager$set_claude_credentials(input$api_key, input$model, input$max_tokens, input$timeout)
        api_manager$test_claude_connection()
        output$status <- renderUI(tags$div(style="color:#27ae60; margin-top:8px;", icon("check-circle"), " Connection successful \u2014 model: ", input$model))
        showNotification("\u2713 Claude API connection successful", type = "message")
      }, error = function(e) {
        output$status <- renderUI(tags$div(style="color:#c0392b; margin-top:8px;", icon("times-circle"), " Failed: ", e$message))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$save_credentials, {
      req(input$api_key)
      api_manager$set_claude_credentials(input$api_key, input$model, input$max_tokens, input$timeout)
      output$status <- renderUI(tags$div(style="color:#27ae60; margin-top:8px;", "Credentials saved for this session"))
      showNotification("\u2713 Credentials saved", type = "message")
    })

    output$status <- renderUI(tags$div())
  })
}
