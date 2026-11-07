# modules/API Configuration/debug_console/ui.R
# Live mirror of the R console (every cat()/print() line) in a copy-friendly
# textarea - built for selecting/copying long log output from a phone
# browser, where that's normally painful. See global.R for the sink()
# capture setup this reads from (get_debug_log_lines()/clear_debug_log()).

debug_console_ui <- function(id) {
  ns <- NS(id)
  textarea_id <- ns("debugLogTextarea")
  copy_js <- sprintf(
    "var el=document.getElementById('%s'); el.focus(); el.select(); el.setSelectionRange(0,999999); if(navigator.clipboard){navigator.clipboard.writeText(el.value);} else {document.execCommand('copy');}",
    textarea_id
  )

  tagList(
    fluidRow(
      box(title = "Debug Console", status = "primary", solidHeader = TRUE, width = 12,

        p("Live mirror of the R console - every ", tags$code("cat()"), "/", tags$code("print()"),
          " line this app writes also lands here, so it can be copied from a phone browser. ",
          "Warnings/errors from R itself are not captured here - only stdout."),

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
        uiOutput(ns("logBox"))
      )
    )
  )
}
