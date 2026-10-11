# modules/Events Scheduling/events_to_calendar/server.R

events_to_calendar_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns
    rv <- reactiveValues(imported = NULL, import_label = NULL, import_text = NULL, events = NULL)

    log_msg <- function(...) api_manager$titan_log_add(paste0(...))

    sel_tz <- function() {
      z <- input$tz
      if (is.null(z) || !nzchar(z) || !z %in% OlsonNames()) TITAN_DEFAULT_TZ else z
    }

    creds <- reactive(api_manager$titan_credentials())
    connected <- reactive(isTRUE(api_manager$titan_state()$ok))
    cal_url <- reactive({
      req(connected(), input$calendar)
      input$calendar
    })

    # ---- header: connection status + calendar picker ----
    output$conn_status <- renderUI({
      st <- api_manager$titan_state()
      if (isTRUE(st$ok)) {
        div(class = "status-success", style = "margin: 0;", icon("check-circle"),
            " Signed in to Titan as ", tags$strong(st$email), ".")
      } else {
        div(class = "status-warning", style = "margin: 0;", icon("lock"),
            " Not signed in. Open ", tags$strong("API Configuration > Titan Authentication"), " and load authenticateT.R. ",
            "You can still build events and download an .ics file.")
      }
    })

    output$calendar_ui <- renderUI({
      st <- api_manager$titan_state()
      req(isTRUE(st$ok), st$calendars)
      selectInput(ns("calendar"), "Save events to", setNames(st$calendars$url, st$calendars$name))
    })

    need_connection <- function() {
      if (!isTRUE(connected()) || is.null(input$calendar)) {
        showNotification("Sign in to Titan first (API Configuration > Titan Authentication).", type = "error")
        return(FALSE)
      }
      TRUE
    }

    # ---- build an event from the form ----
    form_event <- function() {
      title <- trimws(input$title)
      if (!nzchar(title)) stop("Give the event a title.")
      if (is.null(input$date) || is.na(input$date)) stop("Pick a date.")
      rem <- as.integer(titan_or(input$reminders, integer()))
      if (!is.null(input$custom_rem) && !is.na(input$custom_rem) && input$custom_rem >= 0)
        rem <- c(rem, as.integer(input$custom_rem))
      rem <- sort(unique(rem))
      tz <- sel_tz()
      if (isTRUE(input$all_day)) {
        s_min <- NA_real_; e_min <- NA_real_
      } else {
        if (!grepl("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", trimws(input$start)))
          stop("Start time must be HH:MM, e.g. 17:45.")
        dur <- input$duration
        if (is.null(dur) || is.na(dur) || dur <= 0) stop("Duration must be more than 0 minutes.")
        hm <- as.integer(strsplit(trimws(input$start), ":", fixed = TRUE)[[1]])
        s_min <- hm[1] * 60 + hm[2]
        e_min <- s_min + dur
      }
      ev <- ics_event(titan_new_uid(), title, as.Date(input$date), s_min, e_min,
                      description = titan_or(input$description, ""), location = titan_or(input$location, ""),
                      alarms = if (length(rem)) sprintf("-PT%dM", rem) else NULL)
      titan_events_to_queue(list(ev), tz)[[1]]
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
      api_manager$titan_queue_add(list(ev))
      updateTextInput(session, "title", value = "")
      showNotification(paste("Added:", ev$title), type = "message")
    })

    # queued items rendered in the CURRENTLY selected zone
    rendered_queue <- reactive({
      tz <- sel_tz()
      lapply(api_manager$titan_queue(), titan_item_in_tz, tz = tz)
    })

    queue_df <- reactive({
      q <- rendered_queue()
      if (!length(q)) return(data.frame(Title = character(), When = character(), Zone = character(), Reminders = character()))
      data.frame(Title = vapply(q, function(e) as.character(e$title), ""),
                 When = vapply(q, function(e) as.character(e$when), ""),
                 Zone = vapply(q, function(e) if (is.null(e$tz)) sel_tz() else as.character(e$tz), ""),
                 Reminders = vapply(q, function(e) titan_fmt_rem(e$reminders), ""),
                 stringsAsFactors = FALSE)
    })
    output$queue_tbl <- DT::renderDT(DT::datatable(queue_df(), rownames = FALSE, selection = "multiple",
      options = list(dom = "t", pageLength = 100,
                     language = list(emptyTable = "No events yet - fill in the form and choose Add to list."))))

    observeEvent(input$remove, {
      s <- input$queue_tbl_rows_selected
      q <- api_manager$titan_queue()
      if (length(s) && length(q)) api_manager$titan_queue(q[-s])
    })

    output$download <- downloadHandler(
      filename = function() paste0("events-", format(Sys.Date()), ".ics"),
      content = function(file) {
        q <- rendered_queue()
        if (!length(q)) q <- list(form_event())
        writeBin(charToRaw(enc2utf8(titan_combine_ics(lapply(q, function(e) e$ics)))), file)
      },
      contentType = "text/calendar"
    )

    # ---- saving ----
    save_items <- function(items, overwrite = FALSE) {
      res <- rep(FALSE, length(items))
      withProgress(message = "Saving to Titan...", value = 0, {
        for (i in seq_along(items)) {
          it <- items[[i]]
          cr <- creds()
          r <- titan_put_event(cal_url(), cr$user, cr$pass, it$ics, it$uid, overwrite)
          log_msg(if (r$ok) "Saved" else "FAILED", ": ", it$title, " - ", r$message)
          res[i] <- isTRUE(r$ok)
          incProgress(1 / length(items))
        }
      })
      showNotification(sprintf("%d of %d event(s) saved to Titan.%s", sum(res), length(items),
                               if (!all(res)) " See the Log tab for details." else ""),
                       type = if (all(res)) "message" else "warning", duration = 8)
      res
    }

    observeEvent(input$save_one, {
      if (!need_connection()) return()
      ev <- try_form(); if (is.null(ev)) return()
      if (all(save_items(list(ev)))) updateTextInput(session, "title", value = "")
    })

    observeEvent(input$save_all, {
      if (!need_connection()) return()
      q <- api_manager$titan_queue()
      if (!length(q)) { showNotification("The list is empty.", type = "warning"); return() }
      ok <- save_items(rendered_queue(), overwrite = isTRUE(input$overwrite_queue))
      api_manager$titan_queue(q[!ok])        # failed items stay in the list
    })

    # ---- import ----
    import_tz <- function() {
      z <- input$import_tz
      if (is.null(z) || !nzchar(z) || !z %in% OlsonNames()) sel_tz() else z
    }

    load_import_text <- function(text, label) {
      res <- tryCatch(titan_split_ics(text, import_tz()), error = function(e) e)
      if (inherits(res, "error")) {
        rv$imported <- NULL
        rv$import_label <- NULL
        showNotification(conditionMessage(res), type = "error")
        return(FALSE)
      }
      rv$imported <- res
      rv$import_label <- label
      rv$import_text <- text
      TRUE
    }

    observeEvent(input$ics_file, {
      f <- input$ics_file
      text <- paste(readLines(f$datapath, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
      load_import_text(text, paste0("file ", f$name))
    })

    # keep the two zone selectors in step, and re-read the loaded .ics in the new zone
    observeEvent(input$tz, {
      api_manager$titan_tz <- sel_tz()
      if (!identical(input$import_tz, input$tz)) updateSelectInput(session, "import_tz", selected = input$tz)
    }, ignoreInit = TRUE)
    observeEvent(input$import_tz, {
      if (!identical(input$import_tz, input$tz)) updateSelectInput(session, "tz", selected = input$import_tz)
      if (!is.null(rv$import_text)) load_import_text(rv$import_text, rv$import_label)
    }, ignoreInit = TRUE)

    # .ics sent from a Visualisation tab ('.ics load to calendar')
    observeEvent(api_manager$titan_pending_ics(), {
      p <- api_manager$titan_pending_ics()
      if (is.null(p)) return()
      load_import_text(p$text, paste0("the ", p$label, " tab"))
    }, ignoreInit = TRUE)

    # ask for a particular horizontal sub-tab (set by the Visualisation tabs)
    observeEvent(api_manager$titan_goto_tab(), {
      g <- api_manager$titan_goto_tab()
      if (!is.null(g)) updateTabsetPanel(session, "etc_tabs", selected = g$tab)
    }, ignoreInit = TRUE)

    output$import_source <- renderUI({
      if (is.null(rv$imported)) return(NULL)
      div(class = "status-info", icon("file-import"), " Loaded from ", rv$import_label, ": ",
          length(rv$imported), " event(s). Times without a zone were read as ", import_tz(), ".")
    })

    output$import_tbl <- DT::renderDT({
      req(rv$imported)
      df <- data.frame(
        Title = vapply(rv$imported, function(x) gsub("\\\\([,;\\\\])", "\\1", x$summary), ""),
        Start = vapply(rv$imported, function(x) {
          t <- titan_parse_ics_time(paste0("DTSTART", x$start))
          if (is.na(t)) "" else format(t, "%a %d %b %Y %H:%M %Z", tz = import_tz())
        }, ""),
        Reminders = vapply(rv$imported, function(x) as.numeric(x$alarms), 0),
        stringsAsFactors = FALSE)
      DT::datatable(df, rownames = FALSE, options = list(dom = "t", pageLength = 100), selection = "none")
    })

    observeEvent(input$save_import, {
      if (!need_connection()) return()
      if (is.null(rv$imported)) { showNotification("Load an .ics file first.", type = "warning"); return() }
      items <- lapply(rv$imported, function(x) list(uid = x$uid, title = x$summary, ics = x$ics))
      save_items(items, overwrite = isTRUE(input$overwrite))
    })

    # ---- upcoming (only on Refresh) ----
    load_events <- function() {
      if (!need_connection()) return()
      from <- as.POSIXct(format(input$range[1]), tz = sel_tz())
      to <- as.POSIXct(format(input$range[2] + 1), tz = sel_tz())
      cr <- creds()
      res <- NULL
      withProgress(message = "Loading events...", value = 0.3, {
        res <- tryCatch(titan_list_events(cal_url(), cr$user, cr$pass, from, to), error = function(e) e)
      })
      if (inherits(res, "error")) {
        showNotification(conditionMessage(res), type = "error")
        log_msg("Listing events failed: ", conditionMessage(res))
      } else {
        sk <- attr(res, "skipped")
        if (!is.null(sk) && sk > 0) {
          log_msg(sk, " event(s) could not be read in time. Server answer began: ", attr(res, "sample"))
          showNotification(sprintf("%d event(s) were skipped (see the Log). Narrow the date range and Refresh again.", sk),
                           type = "warning", duration = 10)
        }
        log_msg("Loaded ", nrow(res), " event(s) from the calendar.")
        rv$events <- res
      }
    }
    observeEvent(input$refresh, load_events())

    output$events_tbl <- DT::renderDT({
      req(rv$events)
      e <- rv$events
      tz <- sel_tz()
      df <- data.frame(Start = format(e$start, "%a %d %b %Y %H:%M", tz = tz),
                       End = format(e$end, "%H:%M", tz = tz),
                       Title = e$title, Reminders = e$alarms, stringsAsFactors = FALSE)
      DT::datatable(df, rownames = FALSE, selection = "multiple",
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
                         actionButton(ns("confirm_delete"), "Delete", class = "btn-danger"))))
    })
    observeEvent(input$confirm_delete, {
      removeModal()
      s <- input$events_tbl_rows_selected
      if (!length(s) || is.null(rv$events)) return()
      e <- rv$events[s, , drop = FALSE]
      cr <- creds()
      for (i in seq_len(nrow(e))) {
        ok <- tryCatch(titan_delete_event(e$href[i], cr$user, cr$pass), error = function(x) FALSE)
        log_msg(if (ok) "Deleted: " else "Delete FAILED: ", e$title[i])
      }
      load_events()
    })

    observeEvent(input$show_raw, {
      s <- input$events_tbl_rows_selected
      if (!length(s)) { showNotification("Select one or more events first.", type = "warning"); return() }
      e <- rv$events[s, , drop = FALSE]
      cr <- creds()
      txt <- vapply(seq_len(nrow(e)), function(i) {
        raw <- tryCatch(titan_get_event_raw(e$href[i], cr$user, cr$pass),
                        error = function(x) paste("Couldn't read:", conditionMessage(x)))
        paste0("===== ", e$title[i], " =====\n", gsub("\r\n", "\n", raw))
      }, "")
      showModal(modalDialog(
        title = "Raw event data from Titan", size = "l", easyClose = TRUE,
        p(tags$small("Select all and copy. No password or personal settings are included.")),
        tags$textarea(paste(txt, collapse = "\n\n"), readonly = NA, class = "form-control",
                      style = "height: 60vh; font-size: 12px; font-family: monospace;"),
        footer = modalButton("Close")))
    })

    output$log <- renderText(paste(api_manager$titan_log(), collapse = "\n"))
  })
}
