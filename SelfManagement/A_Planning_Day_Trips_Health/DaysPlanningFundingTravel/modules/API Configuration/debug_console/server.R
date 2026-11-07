# modules/API Configuration/debug_console/server.R
# Note: takes api_manager like every other module's _server() function for
# a consistent call signature (see global.R's create_server()), but doesn't
# use it - this module reads the global get_debug_log_lines()/
# clear_debug_log() functions directly instead, since the log buffer isn't
# suite-specific.

debug_console_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    displayed_text <- reactiveVal("")
    last_updated   <- reactiveVal(NULL)
    line_count     <- reactiveVal(0)

    # Polls the shared buffer periodically; skips updating the displayed
    # value while paused, so the user can select/copy without text shifting.
    poll <- reactivePoll(
      1500, session,
      checkFunc = function() length(get_debug_log_lines()),
      valueFunc = function() get_debug_log_lines()
    )

    observe({
      lines <- poll()
      if (isTRUE(input$paused)) return()
      displayed_text(paste(lines, collapse = "\n"))
      line_count(length(lines))
      last_updated(format(Sys.time(), "%H:%M:%S"))
    })

    observeEvent(input$refreshNow, {
      lines <- get_debug_log_lines()
      displayed_text(paste(lines, collapse = "\n"))
      line_count(length(lines))
      last_updated(format(Sys.time(), "%H:%M:%S"))
    })

    observeEvent(input$clearLog, {
      clear_debug_log()
      displayed_text("")
      line_count(0)
      last_updated(format(Sys.time(), "%H:%M:%S"))
    })

    output$logMeta <- renderUI({
      tags$p(sprintf("%d line(s) captured \u00b7 last updated %s%s",
                      line_count(), last_updated() %||% "\u2014",
                      if (isTRUE(input$paused)) " \u00b7 PAUSED" else ""))
    })

    output$logBox <- renderUI({
      ns <- session$ns
      tags$textarea(
        id = ns("debugLogTextarea"), readonly = "readonly",
        style = "width:100%; height:520px; font-family:monospace; font-size:11.5px; line-height:1.5; background:#0b1e26; color:#c9f7f1; border:1px solid #002C3C; border-radius:8px; padding:12px; white-space:pre; overflow:auto;",
        displayed_text()
      )
    })

    session$onSessionEnded(function() {})
  })
}
