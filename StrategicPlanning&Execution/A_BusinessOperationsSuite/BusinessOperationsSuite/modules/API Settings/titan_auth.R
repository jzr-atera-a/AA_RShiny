# modules/API Configuration/titan_auth.R
# ---- module ----------------------------------------------
# id:           titan_auth
# name:         Titan Authentication
# icon:         user-lock
# description:  Sign in to the Titan calendar from an authenticateT.R file
# packages:     shiny, shinydashboard, httr2, xml2, uuid
# -----------------------------------------------------------

# ---- UI ----
titan_auth_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Titan Calendar Authentication", status = "primary", solidHeader = TRUE, width = 12,
          p("Sign in to your Titan calendar by loading a small text file named ",
            tags$code("authenticateT.R"), ". The file is read as plain text (it is never run) and ",
            "must contain two separate lines, the prefix first and then the value:"),
          tags$pre(style = "background: #f8f9fa; border-left: 4px solid #008A82; padding: 10px;",
                   "e:your.name@yourdomain.com\np:your-mailbox-password"),
          p(tags$small("Use the full email address and the mailbox password (the one used for webmail and the ",
                       "Titan app, not the GoDaddy account password). The password is kept in this app's ",
                       "server memory only: it is not written to disk, not shown, and not logged. The uploaded ",
                       "copy is deleted as soon as it has been read.")),
          fileInput(ns("auth_file"), "Load authenticateT.R", accept = c(".R", ".r", ".txt", "text/plain"),
                    buttonLabel = "Browse...", placeholder = "No file selected"),
          htmlOutput(ns("file_status"))
      )
    ),
    fluidRow(
      box(title = "Calendar Server", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          fluidRow(
            column(6, selectInput(ns("server"), "Calendar server", TITAN_SERVERS)),
            column(6, conditionalPanel(sprintf("input['%s'] == 'custom'", ns("server")),
                      textInput(ns("custom_server"), "Server URL", placeholder = "https://caldav.example.com")))
          ),
          p(tags$small("Leave on Auto-detect: it tries dav.myprofessionalmail.com (GoDaddy / 123 Reg Professional ",
                       "Email), then dav.titan.email and dav-eu.titan.email, and stops at the first that returns calendars.")),
          fluidRow(
            column(4, actionButton(ns("authenticate"), "Authenticate with Titan",
                                   icon = icon("sign-in-alt"), class = "btn-primary", style = "width: 100%;")),
            column(4, actionButton(ns("sign_out"), "Sign out",
                                   icon = icon("sign-out-alt"), class = "btn-danger", style = "width: 100%;"))
          ),
          htmlOutput(ns("auth_status"))
      )
    ),
    fluidRow(
      box(title = "Email Sending (SMTP)", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p("The same Titan mailbox also sends email (",
            tags$strong("Events Scheduling > Send Invites (Titan)"), "). It uses the email address and password from the file above, ",
            "so there is nothing else to enter. Only change the server if the default does not work."),
          fluidRow(
            column(5, selectInput(ns("smtp_server"), "Outgoing mail (SMTP) server", TITAN_SMTP_SERVERS)),
            column(4, conditionalPanel(sprintf("input['%s'] == 'custom'", ns("smtp_server")),
                      textInput(ns("smtp_custom_host"), "SMTP host", placeholder = "smtp.example.com"))),
            column(3, selectInput(ns("smtp_port"), "Port", c("465 (SSL)" = "465", "587 (STARTTLS)" = "587")))
          ),
          htmlOutput(ns("smtp_effective")),
          actionButton(ns("smtp_test"), "Test email login", icon = icon("vial"), class = "btn-info"),
          p(class = "text-muted", style = "font-size: 0.85em; margin-top: 8px;",
            "The test logs in to the mail server only; no message is sent."),
          htmlOutput(ns("smtp_status"))
      )
    ),
    fluidRow(
      box(title = "Connected Calendars", status = "success", solidHeader = TRUE, width = 12,
          htmlOutput(ns("calendars_info")),
          DT::DTOutput(ns("calendars_tbl")),
          hr(),
          p(tags$small("Time zone: choose it on Events to Calendar > New events > Events to save. It applies to ",
                       "events you type in, to events sent from the Visualisation tabs, and (in the Import tab) to ",
                       "imported times that carry no zone.")),
          tags$details(
            tags$summary("Calendar URL manually (if no calendar is found automatically)"),
            textInput(ns("manual_url"), NULL,
                      placeholder = "https://dav.titan.email/principals/you@domain/calendar/ID/"),
            actionButton(ns("use_manual"), "Use this URL", class = "btn-info")
          )
      )
    )
  )
}

# ---- Server ----
titan_auth_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed <- reactiveVal(NULL)       # list(ok, email, pass, msg) from the loaded file
    auth_msg <- reactiveVal(NULL)     # list(ok, msg) shown under the Authenticate button

    # ---- read authenticateT.R as plain text (never source()d) ----
    observeEvent(input$auth_file, {
      f <- input$auth_file
      lines <- tryCatch(readLines(f$datapath, warn = FALSE, encoding = "UTF-8"),
                        error = function(e) NULL)
      unlink(f$datapath)
      if (is.null(lines)) {
        parsed(list(ok = FALSE, msg = "The file could not be read."))
        return()
      }
      res <- titan_parse_auth_file(lines)
      parsed(res)
      auth_msg(NULL)
      api_manager$titan_log_add(if (isTRUE(res$ok))
        paste0("authenticateT.R loaded for ", res$email) else paste0("authenticateT.R problem: ", res$msg))
    })

    output$file_status <- renderUI({
      p <- parsed()
      if (is.null(p)) {
        return(div(class = "status-info", icon("info-circle"), " No file loaded yet."))
      }
      if (!isTRUE(p$ok)) {
        return(div(class = "status-error", icon("exclamation-triangle"), " ", p$msg))
      }
      div(class = "status-success", icon("check-circle"), " File read. Email: ",
          tags$strong(p$email), ". Password: found (hidden). Now choose a server and press ",
          tags$strong("Authenticate with Titan"), ".")
    })

    # ---- authenticate ----
    observeEvent(input$authenticate, {
      p <- parsed()
      if (is.null(p) || !isTRUE(p$ok)) {
        auth_msg(list(ok = FALSE, msg = "Load a valid authenticateT.R file first."))
        return()
      }
      if (is.null(p$pass)) {
        auth_msg(list(ok = FALSE, msg = "The password was cleared after the last sign-in. Load authenticateT.R again."))
        return()
      }
      srv <- input$server
      if (identical(srv, "custom")) srv <- trimws(titan_or(input$custom_server, ""))
      if (!nzchar(srv)) {
        auth_msg(list(ok = FALSE, msg = "Enter the server URL."))
        return()
      }
      servers <- if (identical(srv, "auto")) TITAN_SERVER_URLS else srv
      res <- NULL
      errors <- character()
      withProgress(message = "Connecting to calendar server...", value = 0, {
        for (s in servers) {
          setProgress(detail = s)
          r <- tryCatch(titan_discover_calendars(s, p$email, p$pass), error = function(e) e)
          tr <- r$trace
          api_manager$titan_log_add(paste0("Connection test for ", s, ":\n",
            if (is.null(tr) || !nrow(tr)) "  (no requests made)" else
              paste(sprintf("  %-15s %-12s %s %s", tr$step, tr$status, tr$url, tr$note), collapse = "\n")))
          if (!inherits(r, "error")) { res <- r; res$server <- s; break }
          errors <- c(errors, paste0(sub("^https://", "", s), ": ", conditionMessage(r)))
          incProgress(1 / length(servers))
        }
      })
      if (is.null(res)) {
        api_manager$titan_sign_out()
        auth_msg(list(ok = FALSE, msg = paste(errors, collapse = "\n\n")))
        api_manager$titan_log_add("Authentication failed.")
      } else {
        api_manager$titan_set_session(p$email, p$pass, res$server, res$calendars)
        parsed(list(ok = TRUE, email = p$email, pass = NULL, msg = ""))   # drop the copy of the password
        auth_msg(list(ok = TRUE, msg = sprintf("Authenticated as %s on %s. %d calendar(s) found.",
                                              p$email, sub("^https://", "", res$server), nrow(res$calendars))))
        api_manager$titan_log_add(paste0("Authenticated as ", p$email, " on ", res$server,
                                         "; calendars: ", paste(res$calendars$name, collapse = ", ")))
      }
    })

    observeEvent(input$use_manual, {
      u <- trimws(titan_or(input$manual_url, ""))
      p <- parsed()
      if (!grepl("^https?://", u)) {
        auth_msg(list(ok = FALSE, msg = "The calendar URL must start with https://"))
        return()
      }
      if (is.null(p) || !isTRUE(p$ok) || is.null(p$pass)) {
        st <- api_manager$titan_state()
        if (!isTRUE(st$ok)) {
          auth_msg(list(ok = FALSE, msg = "Load authenticateT.R and authenticate (or load the file again) before using a manual URL."))
          return()
        }
        email <- st$email; pass <- api_manager$titan_pass; server <- st$server
      } else {
        email <- p$email; pass <- p$pass; server <- "manual"
      }
      api_manager$titan_set_session(email, pass, server,
        data.frame(name = "Manual calendar URL", url = titan_ensure_slash(u), stringsAsFactors = FALSE))
      auth_msg(list(ok = TRUE, msg = "Using the calendar URL you entered."))
      api_manager$titan_log_add("Using a manually entered calendar URL.")
    })

    # ---- email (SMTP) settings: shared with Events Scheduling > Send Invites (Titan) ----
    smtp_msg <- reactiveVal(NULL)
    smtp_settings <- reactive({
      st <- api_manager$titan_state()
      sel <- input$smtp_server %||% "auto"
      host <- if (identical(sel, "auto")) titan_smtp_default_host(st$server)
              else if (identical(sel, "custom")) trimws(input$smtp_custom_host %||% "")
              else sel
      list(host = host, port = as.integer(input$smtp_port %||% 465))
    })
    observe({
      s <- smtp_settings()
      old <- isolate(api_manager$titan_smtp())
      if (!identical(old$host, s$host) || !identical(old$port, s$port)) {
        api_manager$titan_smtp(s)
        api_manager$titan_smtp_ok(FALSE)          # a changed server has not been tested yet
      }
    })
    output$smtp_effective <- renderUI({
      s <- smtp_settings()
      p(class = "text-muted", style = "font-size: 0.9em;", icon("envelope"), " Will send through ",
        tags$strong(if (nzchar(s$host)) paste0(s$host, ":", s$port) else "(enter a host)"),
        if (isTRUE(api_manager$titan_state()$ok)) paste0(" as ", api_manager$titan_state()$email))
    })
    observeEvent(input$smtp_test, {
      st <- api_manager$titan_state()
      s <- smtp_settings()
      if (!isTRUE(st$ok)) { smtp_msg(list(ok = FALSE, msg = "Authenticate with Titan first (load authenticateT.R).")); return() }
      if (!nzchar(s$host)) { smtp_msg(list(ok = FALSE, msg = "Enter the SMTP host.")); return() }
      r <- withProgress(message = "Testing email login...", value = 0.5,
                        titan_smtp_test(st$email, api_manager$titan_pass, s$host, s$port))
      api_manager$titan_smtp_ok(isTRUE(r$ok))
      smtp_msg(r)
      api_manager$titan_log_add(paste0("SMTP login test (", s$host, ":", s$port, "): ", if (isTRUE(r$ok)) "ok" else "failed"))
    })
    output$smtp_status <- renderUI({
      m <- smtp_msg(); if (is.null(m)) return(NULL)
      div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin-top: 8px;",
          icon(if (isTRUE(m$ok)) "check-circle" else "times-circle"), " ", m$msg)
    })

    observeEvent(input$sign_out, {
      api_manager$titan_sign_out()
      parsed(NULL)
      auth_msg(list(ok = TRUE, msg = "Signed out. The password has been cleared from memory."))
      api_manager$titan_log_add("Signed out.")
    })

    output$auth_status <- renderUI({
      m <- auth_msg()
      st <- api_manager$titan_state()
      if (is.null(m)) {
        if (isTRUE(st$ok)) m <- list(ok = TRUE, msg = paste("Authenticated as", st$email))
        else return(NULL)
      }
      div(class = if (isTRUE(m$ok)) "status-success" else "status-error",
          style = "white-space: pre-wrap;", icon(if (isTRUE(m$ok)) "check-circle" else "times-circle"), " ", m$msg)
    })

    output$calendars_info <- renderUI({
      st <- api_manager$titan_state()
      if (!isTRUE(st$ok)) {
        return(div(class = "status-warning", icon("lock"),
                   " Not authenticated. The calendar-load buttons on the Visualisation tabs stay hidden until you sign in."))
      }
      NULL
    })

    output$calendars_tbl <- DT::renderDT({
      st <- api_manager$titan_state()
      req(isTRUE(st$ok), !is.null(st$calendars))
      df <- data.frame(Calendar = st$calendars$name, URL = st$calendars$url, stringsAsFactors = FALSE)
      DT::datatable(df, rownames = FALSE, selection = "none", options = list(dom = "t", pageLength = 20))
    })
  })
}
