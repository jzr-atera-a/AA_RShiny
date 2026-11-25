# ---- page ------------------------------------------------------------
# id:          debug_console
# tab label:   Debug Console
# main group:  API Configuration   (sidebar; see modules/_module_registry.yml)
# description: live, copy-friendly mirror of the R console
# functions:   debug_console_ui(id), debug_console_server(id, ...)
# --------------------------------------------------------------------
debug_console_ui <- function(id) {
  ns <- NS(id)
  textarea_id <- ns("debugLogTextarea")
  copy_js <- sprintf(
    "var el=document.getElementById('%s'); el.focus(); el.select(); el.setSelectionRange(0,999999); if(navigator.clipboard){navigator.clipboard.writeText(el.value);} else {document.execCommand('copy');}",
    textarea_id)
  card("Debug Console",
    sub = "Live mirror of the R console: every request, row count and error this app prints. R's own warnings are not captured.",
    fluidRow(
      column(3, checkboxInput(ns("paused"), "Pause (freeze for copying)", value = FALSE)),
      column(3, actionButton(ns("clearLog"), "Clear log", icon = icon("trash"), width = "100%")),
      column(3, actionButton(ns("refreshNow"), "Refresh now", icon = icon("sync"), width = "100%")),
      column(3, tags$button(type = "button", class = "btn btn-primary", style = "width:100%;",
                            onclick = copy_js, icon("copy"), " Copy all"))
    ),
    uiOutput(ns("logMeta")),
    uiOutput(ns("logBox"))
  )
}

debug_console_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    displayed_text <- reactiveVal("")
    last_updated   <- reactiveVal(NULL)
    line_count     <- reactiveVal(0)

    poll <- reactivePoll(1500, session,
      checkFunc = function() length(get_debug_log_lines()),
      valueFunc = function() get_debug_log_lines())

    show_lines <- function(lines) {
      displayed_text(paste(lines, collapse = "\n"))
      line_count(length(lines))
      last_updated(format(Sys.time(), "%H:%M:%S"))
    }
    observe({
      lines <- poll()
      if (isTRUE(input$paused)) return()
      show_lines(lines)
    })
    observeEvent(input$refreshNow, show_lines(get_debug_log_lines()))
    observeEvent(input$clearLog, { clear_debug_log(); show_lines(character(0)) })

    output$logMeta <- renderUI({
      tags$p(class = "ga-card-sub", sprintf("%d line(s) captured · last updated %s%s",
        line_count(), last_updated() %||% "—", if (isTRUE(input$paused)) " · PAUSED" else ""))
    })
    output$logBox <- renderUI({
      tags$textarea(id = session$ns("debugLogTextarea"), readonly = "readonly",
                    class = "debug-box", displayed_text())
    })
  })
}
