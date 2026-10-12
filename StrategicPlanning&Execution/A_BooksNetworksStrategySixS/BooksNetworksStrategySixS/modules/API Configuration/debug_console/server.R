# modules/API Configuration/debug_console/server.R
#
# api_manager is accepted (unused) purely for signature consistency with
# every other module's server function in this app, all of which are
# wired by module_loader.R as server(id, api_manager) - this module has
# no need for it, since it reads the global get_debug_log_lines()/
# clear_debug_log() functions defined once in global.R, not anything
# suite-specific.

debug_console_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    displayed_text <- reactiveVal("")
    last_updated   <- reactiveVal(NULL)
    line_count     <- reactiveVal(0)

    # Polls the shared buffer periodically; skips updating the displayed
    # value while paused, so the user can select/copy without the text
    # shifting mid-selection.
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
      tags$textarea(
        id = session$ns("debugLogTextarea"), readonly = "readonly",
        style = "width:100%; height:520px; font-family:monospace; font-size:11.5px; line-height:1.5; background:#0b1e26; color:#c9f7f1; border:1px solid #002C3C; border-radius:8px; padding:12px; white-space:pre; overflow:auto;",
        displayed_text()
      )
    })
  })
}
