# modules/Online Collaboration/slack_connection/server.R

slack_connection_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    env_token <- function() trimws(Sys.getenv("SLACK_BOT_TOKEN", ""))
    msg <- reactiveVal(NULL)          # list(ok, text) shown under the buttons

    output$env_note <- renderUI({
      if (nzchar(env_token())) {
        p(class = "text-muted", style = "font-size: 0.85em;", icon("info-circle"),
          " The SLACK_BOT_TOKEN environment variable is set: leave the box empty to use it.")
      }
    })

    observeEvent(input$test_connection, {
      tok <- trimws(input$token %||% "")
      if (!nzchar(tok)) tok <- env_token()
      if (!nzchar(tok)) {
        msg(list(ok = FALSE, text = "Paste the Bot User OAuth Token (xoxb-...) first."))
        return()
      }
      if (!grepl("^xox[bp]-", tok)) {
        msg(list(ok = FALSE, text = "That does not look like a Slack token: a bot token starts with xoxb-."))
        return()
      }
      t0 <- Sys.time()
      res <- withProgress(message = "Connecting to Slack...", value = 0.5, slack_test(tok))
      secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
      api_manager$slack_log_add("auth.test", if (isTRUE(res$ok)) "ok" else paste0("failed: ", res$code), secs)
      if (!isTRUE(res$ok)) {
        msg(list(ok = FALSE, text = res$error))
        return()
      }
      api_manager$slack_set_session(tok, res$info)
      updateTextInput(session, "token", value = "")       # do not keep the token in the browser
      msg(list(ok = TRUE, text = "connected"))
      showNotification("Connected to Slack.", type = "message")
    })

    observeEvent(input$disconnect, {
      api_manager$slack_sign_out()
      api_manager$slack_log_add("disconnect", "token cleared from memory")
      msg(list(ok = FALSE, text = "Disconnected. The token was cleared from memory."))
    })

    output$status <- renderUI({
      st <- api_manager$slack_state()
      m <- msg()
      if (isTRUE(st$ok)) {
        return(div(class = "status-success", style = "margin-top: 10px;", icon("check-circle"),
                   " Connected to ", tags$strong(st$team), " as ", tags$strong(st$bot_user), ".",
                   if (nzchar(st$url %||% "")) tagList(" ", tags$small(st$url)),
                   tags$br(), tags$small("Open the Slack Channels tab to browse channels and messages.")))
      }
      if (!is.null(m)) {
        return(div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin-top: 10px;",
                   icon(if (isTRUE(m$ok)) "check-circle" else "exclamation-triangle"), " ", m$text))
      }
      div(class = "status-info", style = "margin-top: 10px;", icon("info-circle"), " Not connected.")
    })

    output$scopes_tbl <- DT::renderDT({
      st <- api_manager$slack_state()
      have <- if (isTRUE(st$ok)) st$scopes else character()
      all_sc <- c(SLACK_NEEDED_SCOPES, SLACK_OPTIONAL_SCOPES)
      df <- data.frame(
        Scope = names(all_sc),
        Needed = ifelse(names(all_sc) %in% names(SLACK_NEEDED_SCOPES), "required", "optional"),
        Purpose = unname(all_sc),
        Status = if (!isTRUE(st$ok)) "not connected"
                 else ifelse(names(all_sc) %in% have, "granted",
                             ifelse(names(all_sc) %in% names(SLACK_NEEDED_SCOPES), "MISSING", "not granted")),
        stringsAsFactors = FALSE)
      dt <- DT::datatable(df, rownames = FALSE, selection = "none",
                          options = list(dom = "t", pageLength = 20, ordering = FALSE))
      DT::formatStyle(dt, "Status", color = DT::styleEqual(c("granted", "MISSING"), c("#1e7e34", "#c0392b")),
                      fontWeight = DT::styleEqual("MISSING", "bold"))
    })

    output$log <- renderText({
      l <- api_manager$slack_log()
      if (length(l) == 0) "(nothing yet)" else paste(l, collapse = "\n")
    })
  })
}
