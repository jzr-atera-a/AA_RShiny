# The capitulos tab uses the shared writing module (R/writing_module.R)
capitulos_server <- function(id, tm, parent_session) writing_module_server(id, tm, parent_session, kind = "caps")
