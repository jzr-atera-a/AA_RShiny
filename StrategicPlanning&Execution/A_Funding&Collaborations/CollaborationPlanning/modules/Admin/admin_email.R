# ---- module ----------------------------------------------
# id:           admin_email
# name:         Email
# icon:         at
# description:  SMTP settings for outreach and reminders, a login test and a test email
# packages:     shiny, curl
# -----------------------------------------------------------
# Ported from BOS modules/Communications/smtp_config.R and DaysPlanning contacts_smtp_config.R.
# The password is never stored in the Sheet or BigQuery: set SMTP_PASSWORD on shinyapps.io, or paste it here
# (server memory only, until the app restarts).

admin_email_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Outreach and Reminders send email through your mailbox. Titan: smtp.titan.email, port 465. ",
         "GoDaddy: smtpout.secureserver.net, port 465. Gmail and Microsoft 365 need an app password. ",
         "For a permanent password set ", tags$code("SMTP_PASSWORD"), " in shinyapps.io > Settings > Variables."),
    card("Mailbox",
      uiOutput(ns("status")),
      layout_columns(col_widths = c(5, 2, 5),
        textInput(ns("host"), "SMTP server", width = "100%"),
        textInput(ns("port"), "Port", "465"),
        textInput(ns("user"), "Mailbox address (sends as)", width = "100%")),
      layout_columns(col_widths = c(6, 6),
        passwordInput(ns("pass"), "Password (optional, this running app only)", width = "100%"),
        textInput(ns("cc"), "Always copy (optional, separated by commas)", width = "100%")),
      numericInput(ns("rdays"), "Reminders look this many days ahead", 7, min = 1, max = 30, width = "260px"),
      div(class = "btn-row",
          actionButton(ns("save"), "Save", class = "btn-brand"),
          actionButton(ns("test"), "Test login", class = "btn-ghost"),
          actionButton(ns("send_test"), "Send me a test email", class = "btn-ghost")),
      uiOutput(ns("result"))))
}

admin_email_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observe({
      s <- ctx$settings()
      updateTextInput(session, "host", value = s$smtp_host); updateTextInput(session, "port", value = s$smtp_port)
      updateTextInput(session, "user", value = s$smtp_user); updateTextInput(session, "cc", value = s$smtp_always_cc)
      updateNumericInput(session, "rdays", value = num(s$reminder_days))
    })
    output$status <- renderUI({
      req(ctx$admin_ok()); input$save
      src <- if (nzchar(session_key_get("smtp_password"))) "pasted in this app" else if (nzchar(cfg$smtp_password)) "SMTP_PASSWORD" else ""
      p("Password: ", if (nzchar(src)) tags$b(paste("set (", src, ")")) else tags$b("not set"), " ",
        status_pill(smtp_ready(ctx$settings()), "Ready to send", "Not ready"))
    })
    observeEvent(input$save, {
      req(ctx$admin_ok())
      if (nzchar(input$pass %||% "")) session_key_set("smtp_password", input$pass)
      new <- list(smtp_host = trimws(input$host), smtp_port = trimws(input$port), smtp_user = tolower(trimws(input$user)),
                  smtp_always_cc = trimws(input$cc), reminder_days = as.character(input$rdays))
      s <- ctx$settings()
      for (k in names(new)) if (!identical(as.character(s[[k]]), new[[k]])) set_setting(k, new[[k]], ctx$user())
      updateTextInput(session, "pass", value = "")
      ctx$bump(); showNotification("Email settings saved.", type = "message")
    })
    observeEvent(input$test, {
      req(ctx$admin_ok())
      r <- withProgress(message = "Logging in...", smtp_test(smtp_config(ctx$settings())))
      output$result <- renderUI(note(if (r$ok) "ok" else "bad", r$msg))
    })
    observeEvent(input$send_test, {
      req(ctx$admin_ok())
      r <- tryCatch({ send_mail(ctx$user(), paste(APP_NAME, "test email"),
                                paste0("This is a test from ", APP_NAME, ". Email is working.\n\nSent at ", now_ts()), conf = smtp_config(ctx$settings()))
                      note("ok", "Sent to ", ctx$user(), ".") }, error = function(e) note("bad", safe_error_text(e)))
      output$result <- renderUI(r)
    })
  })
}
