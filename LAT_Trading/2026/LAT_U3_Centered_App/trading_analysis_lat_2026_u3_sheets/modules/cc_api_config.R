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
