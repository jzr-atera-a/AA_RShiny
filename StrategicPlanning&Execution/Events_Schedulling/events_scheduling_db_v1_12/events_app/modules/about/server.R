# modules/about/server.R

about_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    session$onSessionEnded(function() {})
  })
}
