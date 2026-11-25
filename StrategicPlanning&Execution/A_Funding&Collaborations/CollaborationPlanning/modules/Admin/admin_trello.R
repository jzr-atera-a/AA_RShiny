# ---- module ----------------------------------------------
# id:           admin_trello
# name:         Trello
# icon:         trello
# description:  Trello key, token and the board that delivery tasks go to
# packages:     shiny, httr
# -----------------------------------------------------------

admin_trello_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Phase 5 sends each project's tasks to Trello as cards, as the Gantt to Tickets tabs in Business Operations Suite do. ",
         "Get a key and token at trello.com/power-ups/admin. For permanent use set ", tags$code("TRELLO_KEY"), " and ",
         tags$code("TRELLO_TOKEN"), " in shinyapps.io > Settings > Variables."),
    card("Connection",
      uiOutput(ns("status")),
      layout_columns(col_widths = c(6, 6),
        passwordInput(ns("key"), "Key (optional, this running app only)"),
        passwordInput(ns("token"), "Token (optional, this running app only)")),
      div(class = "btn-row",
          actionButton(ns("save_keys"), "Save keys", class = "btn-ghost"),
          actionButton(ns("load"), "Load my boards", class = "btn-brand")),
      uiOutput(ns("boards_ui"))))
}

admin_trello_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    boards <- reactiveVal(NULL)
    output$status <- renderUI({
      req(ctx$admin_ok()); input$save_keys; s <- ctx$settings()
      p("Key: ", tags$code(key_hint(trello_key())), "  Token: ", tags$code(key_hint(trello_token())),
        tags$br(), "Board for delivery tasks: ", tags$b(if (nzchar(s$trello_board_id)) s$trello_board_id else "not chosen"))
    })
    observeEvent(input$save_keys, {
      req(ctx$admin_ok())
      if (nzchar(trimws(input$key %||% ""))) session_key_set("trello_key", trimws(input$key))
      if (nzchar(trimws(input$token %||% ""))) session_key_set("trello_token", trimws(input$token))
      updateTextInput(session, "key", value = ""); updateTextInput(session, "token", value = "")
      log_change(ctx$user(), "setting", "trello keys", "set for this running app")
      showNotification("Trello keys kept for this running app.", type = "message")
    })
    observeEvent(input$load, {
      req(ctx$admin_ok())
      b <- tryCatch(trello_boards(), error = function(e) { showNotification(safe_error_text(e), type = "error"); NULL })
      boards(b)
    })
    output$boards_ui <- renderUI({
      b <- boards(); req(b)
      if (!nrow(b)) return(note("warn", "No open boards found for this account."))
      tagList(
        selectInput(ns("board"), "Board for delivery tasks", setNames(b$id, b$name), selected = ctx$settings()$trello_board_id),
        actionButton(ns("save_board"), "Use this board", class = "btn-brand"))
    })
    observeEvent(input$save_board, {
      req(ctx$admin_ok(), input$board)
      set_setting("trello_board_id", input$board, ctx$user())
      ctx$bump(); showNotification("Board saved.", type = "message")
    })
  })
}
