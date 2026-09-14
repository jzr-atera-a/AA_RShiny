# modules/about/server.R

events_about_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    session$onSessionEnded(function() {})
  })
}
