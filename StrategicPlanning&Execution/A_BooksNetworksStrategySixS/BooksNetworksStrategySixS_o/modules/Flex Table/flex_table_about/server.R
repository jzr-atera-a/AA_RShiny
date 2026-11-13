# modules/about/server.R

flex_table_about_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    session$onSessionEnded(function() {})
  })
}
