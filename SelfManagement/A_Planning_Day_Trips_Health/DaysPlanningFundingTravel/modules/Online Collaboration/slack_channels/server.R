# modules/Online Collaboration/slack_channels/server.R
# Nothing loads automatically: every Slack call runs from an explicit button.

slack_channels_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    channels   <- reactiveVal(slack_empty_channels())
    chan_msg   <- reactiveVal(NULL)       # list(ok, text)
    msgs_raw   <- reactiveVal(list())     # raw messages, newest first
    msgs_trunc <- reactiveVal(FALSE)
    msgs_chan  <- reactiveVal(NULL)       # channel id the loaded messages belong to
    msgs_msg   <- reactiveVal(NULL)
    thread_raw <- reactiveVal(list())
    thread_key <- reactiveVal(NULL)       # list(channel, ts)
    thread_msg <- reactiveVal(NULL)
    post_msg   <- reactiveVal(NULL)

    connected <- function() isTRUE(api_manager$slack_state()$ok)
    token <- function() api_manager$slack_token

    # Runs one Slack action, logging method / result / time. fn returns a slack_call-like list.
    timed <- function(method, fn) {
      t0 <- Sys.time()
      res <- fn()
      secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
      api_manager$slack_log_add(method, if (isTRUE(res$ok)) "ok" else paste0("failed: ", slack_or(res$code, "error")), secs)
      res
    }

    output$conn_note <- renderUI({
      if (!connected()) {
        div(class = "status-warning", icon("exclamation-triangle"), " Not connected to Slack. Open ",
            tags$strong("Online Collaboration > Slack Connection"), " first.")
      }
    })

    # ---- helpers ----------------------------------------------------------
    users_map <- function() api_manager$slack_users
    chan_map <- reactive({
      ch <- channels()
      if (nrow(ch) == 0) return(character())
      setNames(ch$name, ch$id)
    })

    filtered_channels <- reactive({
      ch <- channels()
      f <- trimws(input$chan_filter %||% "")
      if (nzchar(f)) ch <- ch[grepl(f, ch$name, ignore.case = TRUE, fixed = TRUE), , drop = FALSE]
      if (isTRUE(input$only_member)) ch <- ch[ch$is_member, , drop = FALSE]
      ch
    })

    selected_channel <- reactive({
      ch <- filtered_channels()
      i <- input$channels_tbl_rows_selected
      if (length(i) != 1 || i > nrow(ch)) return(NULL)
      ch[i, , drop = FALSE]
    })

    tz <- reactive(bos_tz_value(input$time_zone))

    # ---- channels ---------------------------------------------------------
    observeEvent(input$load_channels, {
      if (!connected()) { chan_msg(list(ok = FALSE, text = "Connect to Slack first (Slack Connection tab).")); return() }
      res <- withProgress(message = "Loading channels...", value = 0.4, {
        timed("conversations.list", function() slack_channels(token()))
      })
      if (!isTRUE(res$ok)) { chan_msg(list(ok = FALSE, text = res$error)); return() }
      channels(res$df)
      # people's names (optional: needs users:read)
      if (is.null(api_manager$slack_users)) {
        ur <- withProgress(message = "Loading people's names...", value = 0.7, {
          timed("users.list", function() slack_users(token()))
        })
        if (isTRUE(ur$ok)) api_manager$slack_users <- ur$users
        else showNotification(paste("Names not loaded - author IDs will be shown. ", ur$error), type = "warning", duration = 8)
      }
      chan_msg(list(ok = TRUE, text = sprintf("%d channel(s) loaded; the app is a member of %d.%s",
                                              nrow(res$df), sum(res$df$is_member),
                                              if (isTRUE(res$truncated)) " (stopped early: very large workspace)" else "")))
    })

    output$channels_status <- renderUI({
      m <- chan_msg(); if (is.null(m)) return(NULL)
      div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin: 8px 0;",
          icon(if (isTRUE(m$ok)) "check-circle" else "exclamation-triangle"), " ", m$text)
    })

    output$channels_tbl <- DT::renderDT({
      ch <- filtered_channels()
      df <- data.frame(
        Channel = if (nrow(ch)) paste0("#", ch$name) else character(),
        Type = ifelse(ch$is_private, "private", "public"),
        `App is member` = ifelse(ch$is_member, "yes", ifelse(ch$is_private, "no - invite it in Slack", "no")),
        Members = ch$num_members,
        Topic = ifelse(nzchar(ch$topic), ch$topic, ch$purpose),
        check.names = FALSE, stringsAsFactors = FALSE)
      DT::datatable(df, rownames = FALSE, selection = "single",
                    options = list(pageLength = 10, scrollX = TRUE, dom = "ftip"))
    })

    observeEvent(input$join_channel, {
      ch <- selected_channel()
      if (!connected()) return()
      if (is.null(ch)) { showNotification("Select a channel first.", type = "warning"); return() }
      if (ch$is_member) { showNotification("The app is already in this channel.", type = "message"); return() }
      if (ch$is_private) {
        showNotification("This is a private channel: invite the app in Slack with /invite @AppName.", type = "warning", duration = 8)
        return()
      }
      res <- timed("conversations.join", function() slack_join(token(), ch$id))
      if (!isTRUE(res$ok)) { showNotification(res$error, type = "error", duration = 10); return() }
      all <- channels(); all$is_member[all$id == ch$id] <- TRUE; channels(all)
      showNotification(paste0("Joined #", ch$name, "."), type = "message")
    })

    # ---- messages ---------------------------------------------------------
    output$selected_channel <- renderUI({
      ch <- selected_channel()
      if (is.null(ch)) return(div(class = "status-info", icon("info-circle"), " Select a channel in the table above."))
      div(class = "status-info", icon("hashtag"), " Selected: ", tags$strong(ch$name),
          if (!ch$is_member) tagList(" - ", tags$em("the app is not a member of this channel yet")))
    })

    period_oldest <- function() {
      z <- tz()
      today0 <- as.POSIXct(paste(format(Sys.time(), "%Y-%m-%d", tz = z), "00:00:00"), tz = z)
      switch(input$period,
        today  = today0,
        "7"    = today0 - 6 * 86400,
        "30"   = today0 - 29 * 86400,
        custom = as.POSIXct(paste(format(input$range[1], "%Y-%m-%d"), "00:00:00"), tz = z),
        today0 - 6 * 86400)
    }
    period_latest <- function() {
      if (!identical(input$period, "custom")) return(NULL)
      as.POSIXct(paste(format(input$range[2], "%Y-%m-%d"), "23:59:59"), tz = tz()) + 0.999
    }

    fetch_messages <- function(more = FALSE) {
      if (!connected()) { msgs_msg(list(ok = FALSE, text = "Connect to Slack first (Slack Connection tab).")); return() }
      ch <- selected_channel()
      if (is.null(ch)) { msgs_msg(list(ok = FALSE, text = "Select a channel first.")); return() }
      latest <- period_latest()
      if (more) {
        cur <- msgs_raw()
        if (length(cur) == 0 || !identical(msgs_chan(), ch$id)) {
          msgs_msg(list(ok = FALSE, text = "Load messages first, then use Load older messages.")); return()
        }
        oldest_ts <- min(as.numeric(vapply(cur, function(m) as.character(m$ts), "")))
        latest <- oldest_ts                                    # strictly older than what we have
      }
      oldest <- if (more) NULL else period_oldest()
      res <- withProgress(message = "Reading messages...", value = 0.5, {
        timed("conversations.history", function() {
          slack_history(token(), ch$id, oldest = oldest, latest = latest, max_messages = 1000)
        })
      })
      if (!isTRUE(res$ok)) { msgs_msg(list(ok = FALSE, text = res$error)); return() }
      new <- res$messages
      if (more) {
        have <- vapply(msgs_raw(), function(m) as.character(m$ts), "")
        new <- Filter(function(m) !(as.character(m$ts) %in% have), new)
        msgs_raw(c(msgs_raw(), new))
      } else {
        msgs_raw(new); thread_raw(list()); thread_key(NULL); thread_msg(NULL)
      }
      msgs_chan(ch$id); msgs_trunc(isTRUE(res$truncated))
      msgs_msg(list(ok = TRUE, text = sprintf("%d new message(s) read for #%s (%d shown).%s",
                                              length(new), ch$name, length(msgs_raw()),
                                              if (isTRUE(res$truncated)) " Stopped at the 1,000-message / 25-second limit: use Load older messages for more." else "")))
    }
    observeEvent(input$load_messages, fetch_messages(FALSE))
    observeEvent(input$load_older, fetch_messages(TRUE))

    output$messages_status <- renderUI({
      m <- msgs_msg(); if (is.null(m)) return(NULL)
      div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin: 8px 0;",
          icon(if (isTRUE(m$ok)) "check-circle" else "exclamation-triangle"), " ", m$text)
    })

    msgs_df <- reactive({
      slack_messages_df(msgs_raw(), users_map(), chan_map(), tz())
    })

    output$messages_tbl <- DT::renderDT({
      d <- msgs_df()
      df <- data.frame(Time = d$time, Author = d$author, Message = d$text_html,
                       Replies = d$replies, Reactions = d$reactions,
                       check.names = FALSE, stringsAsFactors = FALSE)
      DT::datatable(df, rownames = FALSE, selection = "single", escape = c("Time", "Author", "Replies", "Reactions"),
                    options = list(pageLength = 15, scrollX = TRUE, dom = "ftip", order = list()))
    })

    output$download_csv <- downloadHandler(
      filename = function() {
        ch <- selected_channel()
        paste0("slack_", if (is.null(ch)) "channel" else ch$name, "_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        d <- msgs_df()
        out <- data.frame(Time = d$time, Zone = rep(tz(), nrow(d)), Author = d$author, Message = d$text,
                          Replies = d$replies, Reactions = d$reactions, stringsAsFactors = FALSE)
        utils::write.csv(out, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )

    # ---- thread -----------------------------------------------------------
    observeEvent(input$messages_tbl_rows_selected, {
      i <- input$messages_tbl_rows_selected
      d <- msgs_df()
      if (length(i) != 1 || i > nrow(d)) return()
      ch_id <- msgs_chan()
      if (d$replies[i] <= 0) {
        thread_raw(list()); thread_key(list(channel = ch_id, ts = d$ts[i]))
        thread_msg(list(ok = TRUE, text = "This message has no replies. A reply posted below with 'Reply in the selected thread' starts a thread on it."))
        return()
      }
      res <- withProgress(message = "Reading thread...", value = 0.5, {
        timed("conversations.replies", function() slack_replies(token(), ch_id, d$ts[i]))
      })
      if (!isTRUE(res$ok)) { thread_msg(list(ok = FALSE, text = res$error)); return() }
      thread_raw(res$messages); thread_key(list(channel = ch_id, ts = d$ts[i]))
      thread_msg(list(ok = TRUE, text = sprintf("Thread with %d message(s) (the first is the original).", length(res$messages))))
    })

    output$thread_status <- renderUI({
      m <- thread_msg(); if (is.null(m)) return(NULL)
      div(class = if (isTRUE(m$ok)) "status-info" else "status-error", style = "margin: 8px 0;",
          icon(if (isTRUE(m$ok)) "info-circle" else "exclamation-triangle"), " ", m$text)
    })

    output$thread_tbl <- DT::renderDT({
      d <- slack_messages_df(thread_raw(), users_map(), chan_map(), tz())
      df <- data.frame(Time = d$time, Author = d$author, Message = d$text_html, check.names = FALSE, stringsAsFactors = FALSE)
      DT::datatable(df, rownames = FALSE, selection = "none", escape = c("Time", "Author"),
                    options = list(pageLength = 20, scrollX = TRUE, dom = "tip", ordering = FALSE))
    })

    # ---- post -------------------------------------------------------------
    observeEvent(input$send_post, {
      if (!connected()) { post_msg(list(ok = FALSE, text = "Connect to Slack first (Slack Connection tab).")); return() }
      ch <- selected_channel()
      if (is.null(ch)) { post_msg(list(ok = FALSE, text = "Select a channel first.")); return() }
      txt <- trimws(input$post_text %||% "")
      if (!nzchar(txt)) { post_msg(list(ok = FALSE, text = "Write the message first.")); return() }
      ts <- NULL
      if (isTRUE(input$post_in_thread)) {
        k <- thread_key()
        if (is.null(k) || !identical(k$channel, ch$id)) {
          post_msg(list(ok = FALSE, text = "Select a message in the table above to reply in its thread, or untick the box.")); return()
        }
        ts <- k$ts
      }
      res <- timed("chat.postMessage", function() slack_post(token(), ch$id, txt, ts))
      if (!isTRUE(res$ok)) { post_msg(list(ok = FALSE, text = res$error)); return() }
      post_msg(list(ok = TRUE, text = sprintf("Posted to #%s%s.", ch$name, if (!is.null(ts)) " (in thread)" else "")))
      updateTextAreaInput(session, "post_text", value = "")
      if (identical(msgs_chan(), ch$id)) fetch_messages(FALSE)     # refresh what is shown
    })

    output$post_status <- renderUI({
      m <- post_msg(); if (is.null(m)) return(NULL)
      div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin-top: 8px;",
          icon(if (isTRUE(m$ok)) "check-circle" else "exclamation-triangle"), " ", m$text)
    })
  })
}
