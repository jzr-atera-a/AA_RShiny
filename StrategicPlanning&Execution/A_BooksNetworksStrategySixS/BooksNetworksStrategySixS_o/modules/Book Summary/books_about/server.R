# modules/about/server.R

books_about_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    # Static content, no server logic needed
    session$onSessionEnded(function() {})
  })
}
