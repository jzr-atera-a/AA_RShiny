# Titan Events - create calendar events in R Shiny and save them straight
# into a Titan Mail calendar over CalDAV (no Titan app or website needed).
#
# Run:   shiny::runApp("titan-events")
# Needs: install.packages(c("shiny", "bslib", "DT", "httr2", "xml2", "uuid"))
#
# Optional: set TITAN_EMAIL / TITAN_PASSWORD (e.g. in ~/.Renviron) to prefill
# the sign-in. Credentials are only kept in memory for the session.

library(shiny)
library(bslib)
library(DT)
source("caldav.R", local = TRUE)

SERVERS <- c(
  "Auto-detect (try all below)"                                 = "auto",
  "GoDaddy Professional Email (Titan) - dav.myprofessionalmail.com" = "https://dav.myprofessionalmail.com",
  "Titan (global) - dav.titan.email"                            = "https://dav.titan.email",
  "Titan (EU) - dav-eu.titan.email"                             = "https://dav-eu.titan.email",
  "Other CalDAV server..."                                      = "custom"
)
SERVER_URLS <- unname(SERVERS[!SERVERS %in% c("auto", "custom")])

REMINDERS <- c("At start" = 0, "5 min" = 5, "10 min" = 10, "15 min" = 15,
               "30 min" = 30, "1 hour" = 60, "2 hours" = 120, "1 day" = 1440)

fmt_rem <- function(m) {
  if (!length(m)) return("none")
  paste(vapply(sort(m), function(x) {
    if (x == 0) "at start" else if (x %% 1440 == 0) paste0(x / 1440, "d")
    else if (x %% 60 == 0) paste0(x / 60, "h") else paste0(x, "m")
  }, ""), collapse = ", ")
}

next_slot <- function(tz) {
  t <- as.POSIXlt(Sys.time() + 3600, tz = tz)
  sprintf("%02d:00", t$hour)
}

ui <- page_sidebar(
  title = "Titan Events",
  theme = bs_theme(version = 5, primary = "#2f5d8a"),
  sidebar = sidebar(
    width = 330,
    h5("Titan account"),
    selectInput("server", "Calendar server", SERVERS),
    conditionalPanel("input.server == 'custom'",
      textInput("custom_server", "Server URL", placeholder = "https://caldav.example.com")),
    textInput("email", "Email address", Sys.getenv("TITAN_EMAIL")),
    passwordInput("password", "Mailbox password (same as webmail / Titan app)", Sys.getenv("TITAN_PASSWORD")),
    actionButton("connect", "Connect", class = "btn-primary w-100"),
    uiOutput("conn_status"),
    uiOutput("calendar_ui"),
    tags$details(
      tags$summary("Calendar URL manually"),
      textInput("manual_url", NULL,
                placeholder = "https://dav.titan.email/principals/you@domain/calendar/ID/"),
      actionButton("use_manual", "Use this URL", class = "btn-sm btn-outline-secondary")
    )
  ),
  navset_card_tab(
    id = "tabs",
    nav_panel("New events",
      layout_columns(
        col_widths = c(5, 7),
        card(
          card_header("Event details"),
          textInput("title", "Title", ""),
          layout_columns(
            dateInput("date", "Date", Sys.Date(), weekstart = 1),
            textInput("start", "Start (HH:MM)", next_slot("Europe/London"))
          ),
          layout_columns(
            numericInput("duration", "Duration (minutes)", 60, min = 5, step = 5),
            checkboxInput("all_day", "All-day event", FALSE)
          ),
          selectInput("tz", "Time zone", OlsonNames(), "Europe/London"),
          textInput("location", "Location", ""),
          textAreaInput("description", "Notes", "", rows = 2),
          checkboxGroupInput("reminders", "Notify me before the event",
                             REMINDERS, selected = 10, inline = TRUE),
          numericInput("custom_rem", "Extra reminder (minutes before, optional)",
                       NA, min = 0, step = 5),
          layout_columns(
            actionButton("add", "Add to list", class = "btn-outline-primary"),
            actionButton("save_one", "Save to Titan now", class = "btn-primary")
          )
        ),
        card(
          card_header("Events to save"),
          DTOutput("queue_tbl"),
          layout_columns(
            actionButton("remove", "Remove selected", class = "btn-sm btn-outline-danger"),
            downloadButton("download", "Download .ics", class = "btn-sm btn-outline-secondary"),
            actionButton("save_all", "Save all to Titan", class = "btn-sm btn-primary")
          )
        )
      )
    ),
    nav_panel("Import .ics file",
      card(
        p("Upload an existing .ics file. Each event in it is saved to the selected",
          "Titan calendar, reminders (VALARM) included."),
        fileInput("ics_file", NULL, accept = c(".ics", "text/calendar")),
        DTOutput("import_tbl"),
        checkboxInput("overwrite", "Replace events that already exist (same UID)", FALSE),
        actionButton("save_import", "Save these events to Titan", class = "btn-primary")
      )
    ),
    nav_panel("Upcoming events",
      card(
        layout_columns(
          dateRangeInput("range", "Show events between", Sys.Date(), Sys.Date() + 30,
                         weekstart = 1),
          div(class = "pt-4", actionButton("refresh", "Refresh", class = "btn-outline-primary"))
        ),
        DTOutput("events_tbl"),
        div(class = "d-flex gap-2",
          actionButton("show_raw", "Show raw event data", class = "btn-sm btn-outline-secondary"),
          actionButton("delete", "Delete selected from Titan", class = "btn-sm btn-outline-danger"))
      )
    ),
    nav_panel("Log", verbatimTextOutput("log"))
  )
)

server <- function(input, output, session) {
  rv <- reactiveValues(calendars = NULL, connected = FALSE, status = NULL,
                       queue = list(), imported = NULL, events = NULL, log = character())

  log_msg <- function(...) {
    rv$log <- c(sprintf("[%s] %s", format(Sys.time(), "%H:%M:%S"), paste0(...)), rv$log)
  }

  server_url <- reactive({
    if (input$server == "custom") input$custom_server else input$server
  })
  creds <- reactive(list(user = trimws(input$email), pass = input$password))
  cal_url <- reactive({
    req(rv$connected, input$calendar)
    input$calendar
  })

  # ---- connect ------------------------------------------------------------
  observeEvent(input$connect, {
    validate_creds <- nzchar(creds()$user) && nzchar(creds()$pass)
    if (!validate_creds) {
      rv$status <- list(ok = FALSE, msg = "Enter your email and password.")
      return()
    }
    servers <- if (server_url() == "auto") SERVER_URLS else server_url()
    res <- NULL
    errors <- character()
    withProgress(message = "Connecting to calendar server...", value = 0, {
      for (srv in servers) {
        setProgress(detail = srv)
        r <- tryCatch(discover_calendars(srv, creds()$user, creds()$pass), error = function(e) e)
        tr <- if (inherits(r, "error")) r$trace else r$trace
        log_msg("Connection test for ", srv, ":\n",
                if (is.null(tr) || !nrow(tr)) "  (no requests made)" else
                  paste(sprintf("  %-15s %-12s %s %s", tr$step, tr$status, tr$url, tr$note),
                        collapse = "\n"))
        if (!inherits(r, "error")) { res <- r; res$server <- srv; break }
        errors <- c(errors, paste0(sub("^https://", "", srv), ": ", conditionMessage(r)))
        incProgress(1 / length(servers))
      }
    })
    if (is.null(res)) {
      rv$connected <- FALSE
      rv$status <- list(ok = FALSE, msg = HTML(paste(htmltools::htmlEscape(errors), collapse = "<br><br>")))
      log_msg("Connect failed.")
    } else {
      rv$calendars <- res$calendars
      rv$connected <- TRUE
      rv$status <- list(ok = TRUE, msg = sprintf("Connected to %s - %d calendar(s) found.",
                                                 sub("^https://", "", res$server), nrow(res$calendars)))
      log_msg("Connected as ", creds()$user, " on ", res$server, "; calendars: ",
              paste(res$calendars$name, collapse = ", "))
    }
  })

  observeEvent(input$use_manual, {
    u <- trimws(input$manual_url)
    if (!grepl("^https?://", u)) {
      rv$status <- list(ok = FALSE, msg = "The calendar URL must start with https://")
      return()
    }
    rv$calendars <- data.frame(name = "Manual calendar URL", url = ensure_slash(u))
    rv$connected <- TRUE
    rv$status <- list(ok = TRUE, msg = "Using the calendar URL you entered.")
  })

  output$conn_status <- renderUI({
    s <- rv$status
    if (is.null(s)) return(NULL)
    div(class = paste("small mt-2", if (s$ok) "text-success" else "text-danger"), s$msg)
  })

  output$calendar_ui <- renderUI({
    req(rv$calendars)
    selectInput("calendar", "Save events to",
                setNames(rv$calendars$url, rv$calendars$name))
  })

  # ---- build events from the form ----------------------------------------
  form_event <- function() {
    title <- trimws(input$title)
    if (!nzchar(title)) stop("Give the event a title.")
    if (is.null(input$date) || is.na(input$date)) stop("Pick a date.")
    rem <- as.integer(input$reminders %||% integer())
    if (!is.na(input$custom_rem) && input$custom_rem >= 0) rem <- c(rem, as.integer(input$custom_rem))
    rem <- sort(unique(rem))
    if (isTRUE(input$all_day)) {
      start <- as.POSIXct(format(input$date), tz = input$tz)
      end <- as.POSIXct(format(input$date + 1), tz = input$tz)
      when <- paste(format(input$date, "%a %d %b %Y"), "(all day)")
    } else {
      if (!grepl("^([01]?\\d|2[0-3]):[0-5]\\d$", trimws(input$start)))
        stop("Start time must be HH:MM, e.g. 17:45.")
      start <- as.POSIXct(paste(format(input$date), trimws(input$start)),
                          format = "%Y-%m-%d %H:%M", tz = input$tz)
      if (is.na(start)) stop("That time doesn't exist in ", input$tz, " (clock change).")
      dur <- input$duration
      if (is.na(dur) || dur <= 0) stop("Duration must be more than 0 minutes.")
      end <- start + dur * 60
      when <- format(start, "%a %d %b %Y %H:%M %Z")
    }
    uid <- new_uid()
    list(uid = uid, title = title, when = when, start = start, reminders = rem,
         ics = build_event_ics(title, start, end, isTRUE(input$all_day),
                               input$location, input$description, rem, uid))
  }

  try_form <- function() {
    ev <- tryCatch(form_event(), error = function(e) e)
    if (inherits(ev, "error")) {
      showNotification(conditionMessage(ev), type = "error")
      return(NULL)
    }
    ev
  }

  observeEvent(input$add, {
    ev <- try_form(); if (is.null(ev)) return()
    rv$queue <- c(rv$queue, list(ev))
    updateTextInput(session, "title", value = "")
    showNotification(paste("Added:", ev$title), type = "message")
  })

  queue_df <- reactive({
    q <- rv$queue
    if (!length(q)) return(data.frame(Title = character(), When = character(), Reminders = character()))
    data.frame(Title = vapply(q, `[[`, "", "title"),
               When = vapply(q, `[[`, "", "when"),
               Reminders = vapply(q, function(e) fmt_rem(e$reminders), ""))
  })
  output$queue_tbl <- renderDT(datatable(queue_df(), rownames = FALSE,
    options = list(dom = "t", pageLength = 100, language = list(emptyTable = "No events yet - fill in the form and choose Add to list.")),
    selection = "multiple"))

  observeEvent(input$remove, {
    s <- input$queue_tbl_rows_selected
    if (length(s)) rv$queue <- rv$queue[-s]
  })

  output$download <- downloadHandler(
    filename = function() paste0("events-", format(Sys.Date()), ".ics"),
    content = function(file) {
      q <- rv$queue
      if (!length(q)) { ev <- form_event(); q <- list(ev) }
      writeBin(charToRaw(combine_ics(lapply(q, `[[`, "ics"))), file)
    }
  )

  # ---- saving -------------------------------------------------------------
  need_connection <- function() {
    if (!isTRUE(rv$connected) || is.null(input$calendar)) {
      showNotification("Connect to your Titan account first (left panel).", type = "error")
      return(FALSE)
    }
    TRUE
  }

  save_items <- function(items, overwrite = FALSE) {
    ok <- 0
    withProgress(message = "Saving to Titan...", value = 0, {
      for (i in seq_along(items)) {
        it <- items[[i]]
        r <- put_event(cal_url(), creds()$user, creds()$pass, it$ics, it$uid, overwrite)
        log_msg(if (r$ok) "Saved" else "FAILED", ": ", it$title, " - ", r$message)
        if (r$ok) ok <- ok + 1
        incProgress(1 / length(items))
      }
    })
    n <- length(items)
    showNotification(sprintf("%d of %d event(s) saved to Titan.%s", ok, n,
                             if (ok < n) " See the Log tab for details." else ""),
                     type = if (ok == n) "message" else "warning", duration = 8)
    ok
  }

  observeEvent(input$save_one, {
    if (!need_connection()) return()
    ev <- try_form(); if (is.null(ev)) return()
    if (save_items(list(ev)) == 1) updateTextInput(session, "title", value = "")
  })

  observeEvent(input$save_all, {
    if (!need_connection()) return()
    if (!length(rv$queue)) { showNotification("The list is empty.", type = "warning"); return() }
    q <- rv$queue
    results <- vapply(seq_along(q), function(i) {
      r <- put_event(cal_url(), creds()$user, creds()$pass, q[[i]]$ics, q[[i]]$uid)
      log_msg(if (r$ok) "Saved" else "FAILED", ": ", q[[i]]$title, " - ", r$message)
      r$ok
    }, logical(1))
    rv$queue <- q[!results]
    showNotification(sprintf("%d of %d event(s) saved to Titan.%s", sum(results), length(q),
                             if (!all(results)) " Unsaved events stay in the list; see the Log tab." else ""),
                     type = if (all(results)) "message" else "warning", duration = 8)
  })

  # ---- import ---------------------------------------------------------------
  observeEvent(input$ics_file, {
    text <- paste(readLines(input$ics_file$datapath, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    res <- tryCatch(split_ics(text), error = function(e) e)
    if (inherits(res, "error")) {
      rv$imported <- NULL
      showNotification(conditionMessage(res), type = "error")
    } else {
      rv$imported <- res
    }
  })

  output$import_tbl <- renderDT({
    req(rv$imported)
    df <- data.frame(Title = vapply(rv$imported, `[[`, "", "summary"),
                     Start = vapply(rv$imported, function(x)
                       format(parse_ics_time(paste0("DTSTART", x$start)), "%a %d %b %Y %H:%M %Z", tz = "Europe/London"), ""),
                     Reminders = vapply(rv$imported, `[[`, 0, "alarms"))
    datatable(df, rownames = FALSE, options = list(dom = "t"), selection = "none")
  })

  observeEvent(input$save_import, {
    if (!need_connection()) return()
    req(rv$imported)
    items <- lapply(rv$imported, function(x) list(uid = x$uid, title = x$summary, ics = x$ics))
    save_items(items, overwrite = isTRUE(input$overwrite))
  })

  # ---- upcoming -------------------------------------------------------------
  load_events <- function() {
    if (!need_connection()) return()
    from <- as.POSIXct(format(input$range[1]), tz = "Europe/London")
    to <- as.POSIXct(format(input$range[2] + 1), tz = "Europe/London")
    res <- tryCatch(list_events(cal_url(), creds()$user, creds()$pass, from, to),
                    error = function(e) e)
    if (inherits(res, "error")) {
      showNotification(conditionMessage(res), type = "error")
      log_msg("Listing events failed: ", conditionMessage(res))
    } else rv$events <- res
  }
  observeEvent(input$refresh, load_events())
  observeEvent(input$tabs, if (input$tabs == "Upcoming events" && isTRUE(rv$connected)) load_events())

  output$events_tbl <- renderDT({
    req(rv$events)
    e <- rv$events
    tz <- input$tz %||% "Europe/London"
    df <- data.frame(Start = format(e$start, "%a %d %b %Y %H:%M", tz = tz),
                     End = format(e$end, "%H:%M", tz = tz),
                     Title = e$title, Reminders = e$alarms)
    datatable(df, rownames = FALSE, selection = "multiple",
              options = list(pageLength = 25, dom = "tp",
                             language = list(emptyTable = "No events in this period.")))
  })

  observeEvent(input$delete, {
    s <- input$events_tbl_rows_selected
    if (!length(s)) { showNotification("Select events to delete first.", type = "warning"); return() }
    showModal(modalDialog(
      title = "Delete events?",
      sprintf("Permanently delete %d event(s) from your Titan calendar?", length(s)),
      footer = tagList(modalButton("Cancel"),
                       actionButton("confirm_delete", "Delete", class = "btn-danger"))))
  })
  observeEvent(input$confirm_delete, {
    removeModal()
    e <- rv$events[input$events_tbl_rows_selected, ]
    for (i in seq_len(nrow(e))) {
      ok <- tryCatch(delete_event(e$href[i], creds()$user, creds()$pass), error = function(x) FALSE)
      log_msg(if (ok) "Deleted: " else "Delete FAILED: ", e$title[i])
    }
    load_events()
  })

  # Raw calendar data as stored on the server (to compare how Titan stores reminders)
  observeEvent(input$show_raw, {
    s <- input$events_tbl_rows_selected
    if (!length(s)) { showNotification("Select one or more events first.", type = "warning"); return() }
    e <- rv$events[s, ]
    txt <- vapply(seq_len(nrow(e)), function(i) {
      raw <- tryCatch(get_event_raw(e$href[i], creds()$user, creds()$pass),
                      error = function(x) paste("Couldn't read:", conditionMessage(x)))
      paste0("===== ", e$title[i], " =====\n", gsub("\r\n", "\n", raw))
    }, "")
    showModal(modalDialog(
      title = "Raw event data from Titan", size = "l", easyClose = TRUE,
      p(class = "small text-muted", "Select all and copy. No password or personal settings are included."),
      tags$textarea(paste(txt, collapse = "\n\n"), readonly = NA, class = "form-control font-monospace",
                    style = "height: 60vh; font-size: 12px;"),
      footer = modalButton("Close")))
  })

  output$log <- renderText(paste(rv$log, collapse = "\n"))
}

shinyApp(ui, server)
