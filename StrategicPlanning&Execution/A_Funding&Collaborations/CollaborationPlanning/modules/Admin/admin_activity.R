# ---- module ----------------------------------------------
# id:           admin_activity
# name:         Activity
# icon:         terminal
# description:  Change log (every write) and the app's debug log, with module loader warnings
# packages:     shiny, DT
# -----------------------------------------------------------

admin_activity_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card("Change log", p(class = "small muted", "Every change anyone makes, newest first."),
         DTOutput(ns("changes")), downloadButton(ns("dl"), "Download CSV", class = "btn-ghost sm")),
    card("Debug log", p(class = "small muted", "What the app has been doing since it started (last 400 lines)."),
         actionButton(ns("refresh"), "Refresh", class = "btn-ghost sm"),
         verbatimTextOutput(ns("debug"))))
}

admin_activity_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    changes <- reactive({ c <- ctx$data$changelog(); c[order(c$timestamp, decreasing = TRUE), , drop = FALSE] })
    output$changes <- renderDT({
      req(ctx$admin_ok())
      datatable(utils::head(changes(), 1000), rownames = FALSE, options = list(pageLength = 15, dom = "ftip"))
    })
    output$dl <- downloadHandler(filename = function() paste0("changelog_", Sys.Date(), ".csv"),
                                 content = function(f) utils::write.csv(changes(), f, row.names = FALSE))
    output$debug <- renderText({
      req(ctx$admin_ok()); input$refresh; ctx$tick()
      w <- if (length(loader$warnings)) paste("Loader warnings:", paste(loader$warnings, collapse = "\n"), "", sep = "\n") else ""
      paste0(w, paste(rev(.debug$lines), collapse = "\n"))
    })
  })
}
