# modules/debug_console.R
#
# "Debug Console" — API Configuration group. Displays a live copy of
# everything written to stdout (every cat()/print() call app-wide, which
# covers all the [BigQuery]/[Claude]/[Trend Summary]/[Export]/etc. logging
# already built into this app), backed by the capture set up in global.R
# (get_debug_log_lines() / clear_debug_log()).
#
# Built specifically so this text is easy to select and copy from a phone
# browser — a plain <textarea readonly> (tap, Select All, Copy) rather than
# a <pre>/<div>, which is far harder to select cleanly on mobile — plus a
# one-tap "Copy All" button using the browser clipboard API directly, no
# server round-trip needed for the copy itself.

debug_console_ui <- function(id) {
  ns <- NS(id)
  textarea_id <- ns("debugLogTextarea")
  copy_js <- sprintf(
    "var el=document.getElementById('%s'); el.focus(); el.select(); el.setSelectionRange(0,999999); if(navigator.clipboard){navigator.clipboard.writeText(el.value);} else {document.execCommand('copy');}",
    textarea_id
  )

  tagList(
    tags$h3("Debug Console"),
    ua_callout(paste0(
      "Live mirror of the R console \u2014 every cat()/print() line this app writes (all the [BigQuery], [Claude], ",
      "[Trend Summary], [Export], etc. logging already built in) also lands here, so it can be copied from a phone ",
      "browser instead of only being visible in Posit's own console. Warnings/errors from R itself (not this app's ",
      "own cat() logging) are not captured here \u2014 check the real console for those."
    )),

    fluidRow(
      column(3, checkboxInput(ns("paused"), "Pause (freeze for copying)", value = FALSE)),
      column(3, actionButton(ns("clearLog"), "Clear Log", icon = icon("trash"), class = "btn-warning", width = "100%")),
      column(3, actionButton(ns("refreshNow"), "Refresh Now", icon = icon("rotate"), width = "100%")),
      column(3,
        tags$button(type = "button", class = "btn btn-primary", style = "width:100%;", onclick = copy_js,
                     icon("copy"), " Copy All")
      )
    ),

    uiOutput(ns("logMeta")),
    withSpinner(uiOutput(ns("logBox")))
  )
}

debug_console_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    displayed_text <- reactiveVal("")
    last_updated   <- reactiveVal(NULL)
    line_count     <- reactiveVal(0)

    # Polls the shared log buffer every 1.5s; only actually re-renders the
    # (potentially large) textarea when the line count changes, and skips
    # updating the displayed value entirely while paused, so the user can
    # select/copy text without it shifting under their finger.
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
      showNotification("\u2713 Debug log cleared", type = "message")
    })

    output$logMeta <- renderUI({
      tags$p(
        style = "font-size:12px; color:#64748b; margin: 4px 0 8px 0;",
        sprintf("%d line(s) captured \u00b7 last updated %s%s",
                line_count(), last_updated() %||% "\u2014",
                if (isTRUE(input$paused)) " \u00b7 PAUSED (new lines are still being captured, just not shown until resumed)" else "")
      )
    })

    output$logBox <- renderUI({
      ns <- session$ns
      tags$textarea(
        id = ns("debugLogTextarea"), readonly = "readonly",
        style = "width:100%; height:520px; font-family:'SFMono-Regular',Consolas,monospace; font-size:11.5px; line-height:1.5; background:#0b1e26; color:#c9f7f1; border:1px solid #002C3C; border-radius:8px; padding:12px; white-space:pre; overflow:auto;",
        displayed_text()
      )
    })
  })
}
