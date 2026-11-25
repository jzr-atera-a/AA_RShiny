# ====================================================================================================
# (was modules/econ_api_config.R)
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
          uiOutput(ns("auto_key")),
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
    output$auto_key <- renderUI({
      st <- if (exists("u3_cred_status", mode = "function")) u3_cred_status() else list(); txt <- st$bq; d <- if (is.null(st$dir)) "" else st$dir
      if (!is.null(txt)) tags$div(style = "background:#ecfdf5; border:1px solid #a7f3d0; color:#065f46; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;", icon("key"), " ", txt, " You can still load another key below.")
      else tags$div(style = "background:#fffbeb; border:1px solid #fde68a; color:#92400e; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;",
        if (nzchar(d)) paste0("No service-account .json key found in ", d, ": load the key file or paste it below.") else "This is not Windows, so no local key folder is searched: load the key file or paste it below.")
    })

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
          uiOutput(ns("auto_key")),
          passwordInput(ns("api_key"), "Anthropic API Key:", placeholder = "sk-ant-..."),
          selectInput(ns("model"), "Model:", choices = c(
            "claude-sonnet-5-5 (default: best at reading IG screenshots)" = "claude-sonnet-5-5",
            "claude-haiku-5-5 (cheaper and faster; less reliable on busy screenshots)" = "claude-haiku-5-5",
            "claude-sonnet-4-6 (previous default)" = "claude-sonnet-4-6",
            "claude-opus-5-5 (most capable, most expensive)" = "claude-opus-5-5",
            "claude-opus-5" = "claude-opus-5", "claude-haiku-4-5-20251001" = "claude-haiku-4-5-20251001"),
            selected = if (nzchar(Sys.getenv("CLAUDE_MODEL"))) Sys.getenv("CLAUDE_MODEL") else "claude-sonnet-5-5"),
          numericInput(ns("max_tokens"), "Max Tokens:", value = 8000, min = 1000, max = 64000, step = 500),
          numericInput(ns("timeout"), "Timeout (seconds, up to 3000):", value = 3000, min = 30, max = 3000),
          actionButton(ns("test_connection"), "Test Connection", icon = icon("plug")),
          actionButton(ns("save_credentials"), "Save Credentials", icon = icon("save"), class = "btn-primary"),
          uiOutput(ns("status"))
      ),
      box(title = "Notes", status = "info", solidHeader = TRUE, width = 7,
          tags$p("Claude reads your IG screenshots (Order Evidence, Morning Sheet levels and economic calendar) and, when you choose web search, looks up market levels, headlines and the calendar with their sources. Screenshot reading uses temperature 0 and only copies what is visible."),
          tags$p("Set ANTHROPIC_API_KEY (and CLAUDE_MODEL) in .Renviron to connect automatically at start-up; otherwise paste the key here. Test Connection checks the key and the model."),
          tags$p("Your API key is kept in-session only (server memory), never written to disk or logged.")
      )
    )
  )
}

econ_claude_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    output$auto_key <- renderUI({
      st <- if (exists("u3_cred_status", mode = "function")) u3_cred_status() else list(); txt <- st$claude; d <- if (is.null(st$dir)) "" else st$dir
      if (!is.null(txt)) tags$div(style = "background:#ecfdf5; border:1px solid #a7f3d0; color:#065f46; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;", icon("key"), " ", txt, " You can still load another key below.")
      else tags$div(style = "background:#fffbeb; border:1px solid #fde68a; color:#92400e; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;",
        if (nzchar(d)) paste0("No ap_claude_1_line.txt found in ", d, ": paste the key below and press Test Connection.") else "This is not Windows, so no local key folder is searched: paste the key below and press Test Connection.")
    })

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

# ====================================================================================================
# (was modules/cc_api_config.R)
# modules/cc_api_config.R
# API Configuration > Capital.com: load the credentials file (like the BigQuery key), connect, see the status, pick the
# account, and save the (non-secret) settings. The key, login and API password stay in memory only.
#
# Credentials file (JSON), for example capital_com_demo.json:
#   {"api_key": "...", "identifier": "you@example.com", "api_password": "...", "environment": "demo"}
# On Windows it is also picked up automatically from C:/111_SecA/_q_api (or the folder in LAT_CRED_DIR).

cc_api_config_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$h3("Capital.com API (demo account)"),
    tags$div(style = "background:#eef6f5; border:1px solid #b2e0db; border-radius:8px; padding:10px 12px; margin-bottom:12px; font-size:12.5px; color:#134e4a; line-height:1.6;",
      "Used by ", tags$b("Trade Journal > Trading Desk (tabs 3 to 6)"), ". Make the key on Capital.com: turn on two-factor sign-in, then ", tags$b("Settings > API integrations > Generate new key"),
      " (you set a custom password for the key there). Put the key, your login email and that password in a JSON file and load it below. ",
      "Orders are only ever sent to the ", tags$b("DEMO"), " environment from this app; a live key can read prices and history but cannot trade here. ",
      "Keys are never written to BigQuery, files or the log: only the masked key is shown."),
    fluidRow(
      box(title = "Credentials", status = "primary", solidHeader = TRUE, width = 5,
        uiOutput(ns("auto_key")),
        fileInput(ns("cred_file"), "Capital.com credentials (.json):", accept = ".json"),
        tags$p("\u2014 or \u2014", style = "text-align:center; color:#999; font-size:12px;"),
        textAreaInput(ns("cred_text"), "Paste the JSON:", rows = 4, placeholder = '{"api_key": "...", "identifier": "you@example.com", "api_password": "...", "environment": "demo"}'),
        tags$pre(style = "font-size:11px; background:#f8fafc; padding:6px 8px; border-radius:6px; white-space:pre-wrap;",
                 '{"api_key": "<from API integrations>",\n "identifier": "<your login email>",\n "api_password": "<the key\'s custom password>",\n "environment": "demo"}'),
        actionButton(ns("connect"), "Load & connect", icon = icon("plug"), class = "btn-primary", width = "100%"),
        tags$div(style = "margin-top:6px;", actionButton(ns("test"), "Test connection", icon = icon("stethoscope")), actionButton(ns("disconnect"), "Disconnect", icon = icon("power-off"))),
        uiOutput(ns("conn_msg"))),
      box(title = "Connection status", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("status")),
        tags$hr(),
        tags$div(style = "font-weight:700; color:#002C3C; margin-bottom:4px;", "Accounts on this login"),
        DT::DTOutput(ns("accounts")),
        fluidRow(column(8, selectInput(ns("account"), "Account used by the app:", choices = c("(connect first)" = ""))),
                 column(4, tags$div(style = "margin-top:25px;", actionButton(ns("use_account"), "Use this account", icon = icon("check"))))),
        tags$hr(),
        tags$div(style = "font-weight:700; color:#002C3C; margin-bottom:4px;", "Settings kept for next time (no secrets)"),
        fluidRow(column(6, textInput(ns("def_epic"), "Default market (epic):", "")), column(6, textInput(ns("def_search"), "Default market search:", "Brent"))),
        actionButton(ns("save"), "Save settings", icon = icon("save"), class = "btn-success"),
        uiOutput(ns("save_msg")),
        tags$hr(),
        tags$details(tags$summary(style = "cursor:pointer; font-weight:700;", "Recent Capital.com calls (log)"), verbatimTextOutput(ns("log")))))
  )
}

cc_api_config_server <- function(id, client, store = NULL) {
  moduleServer(id, function(input, output, session) {
    tick <- reactiveVal(0); msg <- reactiveVal(NULL)
    refresh <- function() tick(isolate(tick()) + 1)
    output$auto_key <- renderUI({ tick()
      st <- if (exists("u3_cred_status", mode = "function")) u3_cred_status() else list(); txt <- st$cc; d <- if (is.null(st$dir)) "" else st$dir
      if (!is.null(txt)) tags$div(style = "background:#ecfdf5; border:1px solid #a7f3d0; color:#065f46; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;", icon("key"), " ", txt, " You can still load another file below.")
      else tags$div(style = "background:#fffbeb; border:1px solid #fde68a; color:#92400e; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;",
        if (nzchar(d)) paste0("No Capital.com credentials file found in ", d, ": load it below.") else "This is not Windows, so no local key folder is searched: load the credentials file below.")
    })
    do_connect <- function(creds) {
      client$set_credentials(creds)
      ok <- tryCatch({ client$login(); TRUE }, error = function(e) { msg(list(ok = FALSE, text = conditionMessage(e))); FALSE })
      if (ok) { msg(list(ok = TRUE, text = sprintf("Connected to Capital.com %s as %s.", toupper(creds$environment), creds$identifier)))
        st <- if (exists("u3_cred_status", mode = "function")) u3_cred_status() else list()
        st$cc <- sprintf("Connected (%s, key %s).", toupper(creds$environment), cc_mask(creds$api_key)); assign(".u3_cred_status", st, envir = .GlobalEnv) }
      refresh(); ok
    }
    observeEvent(input$connect, {
      creds <- tryCatch({
        if (!is.null(input$cred_file$datapath)) cc_read_credentials(input$cred_file$datapath)
        else if (nzchar(trimws(input$cred_text %||% ""))) cc_read_credentials(text = input$cred_text)
        else stop("Choose the credentials file or paste its JSON.")
      }, error = function(e) { msg(list(ok = FALSE, text = conditionMessage(e))); NULL })
      if (is.null(creds)) return()
      updateTextAreaInput(session, "cred_text", value = "")   # do not keep the secret on screen
      withProgress(message = "Connecting to Capital.com...", value = 0.5, do_connect(creds))
    })
    observeEvent(input$test, {
      if (!client$has_credentials()) { msg(list(ok = FALSE, text = "Load the credentials first.")); return() }
      r <- tryCatch({ client$ping(); TRUE }, error = function(e) { msg(list(ok = FALSE, text = conditionMessage(e))); FALSE })
      if (r) msg(list(ok = TRUE, text = sprintf("Capital.com answered at %s UK.", format(Sys.time(), "%H:%M:%S", tz = "Europe/London")))); refresh()
    })
    observeEvent(input$disconnect, { client$disconnect(); msg(list(ok = TRUE, text = "Disconnected. The credentials stay loaded in this session until you load another file.")); refresh() })
    output$conn_msg <- renderUI({ m <- msg(); if (is.null(m)) return(NULL)
      tags$div(style = sprintf("margin-top:8px; color:%s;", if (m$ok) "#27ae60" else "#c0392b"), icon(if (m$ok) "check-circle" else "times-circle"), " ", m$text) })
    acc <- reactive({ tick(); if (!client$connected()) return(data.frame()); tryCatch(cc_accounts_df(client$accounts()), error = function(e) data.frame()) })
    observe({ a <- acc(); if (!nrow(a)) return()
      ch <- setNames(a$account_id, sprintf("%s (%s, %s %s)", a$name, a$account_id, a$currency, format(round(a$balance, 2), big.mark = ",")))
      updateSelectInput(session, "account", choices = ch, selected = client$account_id() %||% a$account_id[1]) })
    output$accounts <- DT::renderDT({ a <- acc(); if (!nrow(a)) return(DT::datatable(data.frame(Note = "Connect to list the accounts."), rownames = FALSE, options = list(dom = "t")))
      DT::datatable(a[, c("name", "account_id", "type", "currency", "balance", "available", "profit_loss", "preferred")], rownames = FALSE, options = list(dom = "t", scrollX = TRUE)) })
    observeEvent(input$use_account, { id <- input$account; if (!nzchar(id %||% "")) return()
      ok <- tryCatch({ client$switch_account(id); TRUE }, error = function(e) { msg(list(ok = FALSE, text = conditionMessage(e))); FALSE })
      if (ok) msg(list(ok = TRUE, text = paste("Using account", id))); refresh() })
    output$status <- renderUI({ tick(); invalidateLater(5000); s <- client$status()
      row <- function(k, v) tags$tr(tags$td(style = "padding:3px 10px 3px 0; color:#64748b;", k), tags$td(style = "padding:3px 0; font-weight:600;", v))
      col <- if (s$connected) "#16a34a" else if (s$has_credentials) "#f59e0b" else "#ef4444"
      tagList(
        tags$div(style = sprintf("font-weight:800; color:%s; margin-bottom:6px;", col), icon("circle"), " ",
                 if (s$connected) "Connected" else if (s$has_credentials) "Credentials loaded, not connected" else "Not set up"),
        tags$table(row("Environment", if (is.na(s$environment)) "-" else toupper(s$environment)), row("API key", if (nzchar(s$masked_key)) s$masked_key else "-"),
                   row("Login", if (is.na(s$identifier)) "-" else s$identifier), row("Account", if (is.na(s$account_id)) "-" else s$account_id),
                   row("Account currency", if (is.na(s$currency)) "-" else s$currency), row("Requests this session", s$calls),
                   row("Last request", if (s$calls) format(s$last_call, "%d/%m %H:%M:%S", tz = "Europe/London") else "-"),
                   row("Orders allowed", if (!s$has_credentials) "-" else if (isTRUE(client$is_demo())) "Yes (demo)" else "No (not the demo environment)")),
        if (!is.null(s$last_error)) tags$div(style = "color:#b91c1c; margin-top:6px; font-size:12px;", "Last error: ", s$last_error)) })
    output$log <- renderText({ tick(); invalidateLater(5000); paste(rev(client$log()), collapse = "\n") })
    # non-secret settings: BigQuery cc_settings when connected, else this session only
    observe({ if (is.null(store)) return(); s <- tryCatch(store$current("settings"), error = function(e) NULL); if (is.null(s) || !nrow(s)) return()
      v <- function(k) { x <- s$setting_value[s$setting_key == k]; if (length(x)) x[1] else NA }
      if (!is.na(v("cc_default_epic"))) updateTextInput(session, "def_epic", value = v("cc_default_epic"))
      if (!is.na(v("cc_default_search"))) updateTextInput(session, "def_search", value = v("cc_default_search")) })
    observeEvent(input$save, {
      df <- data.frame(setting_key = c("cc_environment", "cc_account_id", "cc_default_epic", "cc_default_search"),
                       setting_value = c(client$environment(), client$account_id() %||% NA, input$def_epic, input$def_search), stringsAsFactors = FALSE)
      where <- if (is.null(store)) "this session" else store$write("settings", df)
      output$save_msg <- renderUI(tags$div(style = "color:#27ae60; margin-top:6px;", icon("check"), sprintf(" Saved (%s). Keys are never saved.", where)))
    })
  })
}

# ====================================================================================================
# (was modules/trello_jira_config.R)
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
