# modules/Events Scheduling/titan_auth/server.R

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
