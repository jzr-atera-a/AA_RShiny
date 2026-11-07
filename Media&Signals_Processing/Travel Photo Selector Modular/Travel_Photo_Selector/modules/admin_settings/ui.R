admin_settings_ui <- function(id) {
  ns <- NS(id)
  # Everything is rendered by the server only after the correct admin code is entered
  uiOutput(ns("panel"))
}
