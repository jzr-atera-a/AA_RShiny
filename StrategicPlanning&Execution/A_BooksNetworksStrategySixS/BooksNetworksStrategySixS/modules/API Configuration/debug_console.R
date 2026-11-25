# modules/API Configuration/debug_console.R
# ---- module --------------------------------------------------------------------------------------
# id:           debug_console
# name:         Debug Console
# icon:         terminal
# description:  Live, copy-friendly mirror of every cat()/print() the app writes - built for copying long console output from a phone browser
# packages:     shiny, shinydashboard
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

#
# Live mirror of everything this app writes via cat()/print() (see the
# capture setup at the top of global.R), rendered into a <textarea> that's
# actually usable to select-and-copy from a phone browser - the real R
# console is often painful to select-and-copy from on mobile (e.g. Posit
# Cloud). This is a mirror, not a redirect: output still appears in the
# real console exactly as before.
#
# Only stdout (cat()/print()) is captured, not R's message()/warning()/
# error stream - sinking that stream risks silently hiding real errors
# from the normal console, so it's deliberately left alone.

debug_console_ui <- function(id) {
  ns <- NS(id)
  textarea_id <- ns("debugLogTextarea")

  # Built at UI-definition time via NS(id) - must resolve to the exact
  # same namespaced string as the <textarea>'s id, which the server
  # renders via session$ns("debugLogTextarea"). Both derive from the same
  # base string under the same module id, so they always match as long
  # as this string isn't renamed in only one of the two places.
  copy_js <- sprintf(
    "var el=document.getElementById('%s'); el.focus(); el.select(); el.setSelectionRange(0,999999); if(navigator.clipboard){navigator.clipboard.writeText(el.value);} else {document.execCommand('copy');}",
    textarea_id
  )

  tagList(
    fluidRow(
      box(
        title = "Debug Console",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Live mirror of the R console - every cat()/print() line this app writes also lands here, ",
          "so it can be copied from a phone browser. Warnings/errors from R itself are not captured here; ",
          "check the real console for those."),

        fluidRow(
          column(3, checkboxInput(ns("paused"), "Pause (freeze for copying)", value = FALSE)),
          column(3, actionButton(ns("clearLog"), "Clear Log", icon = icon("trash"), class = "btn-warning", width = "100%")),
          column(3, actionButton(ns("refreshNow"), "Refresh Now", icon = icon("sync"), width = "100%")),
          column(3,
                 tags$button(type = "button", class = "btn btn-primary", style = "width:100%;", onclick = copy_js,
                             icon("copy"), " Copy All"))
        ),

        br(),
        uiOutput(ns("logMeta")),
        uiOutput(ns("logBox"))
      )
    )
  )
}

# ==== Server =======================================================================================

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
