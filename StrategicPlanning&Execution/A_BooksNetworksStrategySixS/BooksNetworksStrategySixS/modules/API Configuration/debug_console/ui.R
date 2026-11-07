# modules/API Configuration/debug_console/ui.R
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
