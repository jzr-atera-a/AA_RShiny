# ---- module ----------------------------------------------
# id:           admin_claude
# name:         Claude API
# icon:         robot
# description:  Claude API key (server memory or environment), model, and a connection test
# packages:     shiny, httr
# -----------------------------------------------------------

admin_claude_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Claude powers live programme search, eligibility checks and drafting in later phases. ",
         "For a permanent key, set ", tags$code("ANTHROPIC_API_KEY"), " in shinyapps.io > Settings > Variables. ",
         "A key pasted here is kept in the server's memory only until the app restarts, and is never saved to the Sheet or BigQuery."),
    card("Connection",
      uiOutput(ns("key_status")),
      passwordInput(ns("key"), "Paste an API key for this running app (optional)", width = "100%"),
      layout_columns(col_widths = c(6, 6),
        selectInput(ns("model"), "Model", CLAUDE_MODELS),
        checkboxInput(ns("web"), "Use live web search when finding programmes", TRUE)),
      div(class = "btn-row",
          actionButton(ns("save"), "Save", class = "btn-brand"),
          actionButton(ns("test"), "Test connection", class = "btn-ghost")),
      uiOutput(ns("result"))))
}

admin_claude_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observe({
      s <- ctx$settings()
      updateSelectInput(session, "model", selected = s$claude_model)
      updateCheckboxInput(session, "web", value = is_true(s$claude_web_search))
    })
    output$key_status <- renderUI({
      req(ctx$admin_ok()); input$save
      src <- if (nzchar(session_key_get("anthropic"))) "pasted in this app" else if (nzchar(cfg$anthropic_key)) "environment variable" else ""
      p("Key: ", tags$code(key_hint(claude_key())), if (nzchar(src)) span(class = "muted", paste0(" (", src, ")")))
    })
    observeEvent(input$save, {
      req(ctx$admin_ok())
      if (nzchar(trimws(input$key %||% ""))) session_key_set("anthropic", trimws(input$key))
      set_setting("claude_model", input$model, ctx$user())
      set_setting("claude_web_search", tolower(as.character(isTRUE(input$web))), ctx$user())
      updateTextInput(session, "key", value = "")
      ctx$bump(); showNotification("Claude settings saved.", type = "message")
    })
    observeEvent(input$test, {
      req(ctx$admin_ok())
      res <- tryCatch(note("ok", "Connected. ", input$model, " replied: ", claude_ping(input$model)),
                      error = function(e) note("bad", "Test failed: ", safe_error_text(e)))
      output$result <- renderUI(res)
    })
  })
}
