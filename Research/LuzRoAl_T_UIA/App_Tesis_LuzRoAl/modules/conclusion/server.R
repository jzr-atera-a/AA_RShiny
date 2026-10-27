# The conclusion tab uses the shared writing module (R/writing_module.R)
conclusion_server <- function(id, tm, parent_session) writing_module_server(id, tm, parent_session, kind = "concl")
