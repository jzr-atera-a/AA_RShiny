ideas_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("stats")),
    fluidRow(
      column(5,
        box(title = tagList(icon("pen"), " Anotar una idea nueva"), status = "primary", solidHeader = TRUE, width = NULL,
            textInput(ns("titulo"), "Título corto de la idea:", width = "100%",
                      placeholder = "p. ej. El municipio mexicano después de la reforma de 1983"),
            textAreaInput(ns("descripcion"), "¿De qué se trata? (unas líneas)", rows = 3, width = "100%"),
            textAreaInput(ns("experiencia"), "¿Por qué me importa? ¿Qué he vivido o visto sobre esto?", rows = 3, width = "100%"),
            selectizeInput(ns("materias"), "Materias o enfoques relacionados:", choices = MATERIAS_CHOICES(), multiple = TRUE,
                           width = "100%", options = list(placeholder = "Elija una o varias (opcional)")),
            actionButton(ns("add"), "Guardar idea", class = "btn-success btn-big", icon = icon("plus"), style = "width: 100%;")),
        box(title = tagList(icon("robot"), " Que Claude me sugiera temas"), status = "success", solidHeader = TRUE, width = NULL,
            collapsible = TRUE,
            p("Cuéntele a Claude un poco de usted y le propondrá 5 temas a su medida."),
            textAreaInput(ns("sugExp"), "Mi experiencia de vida y de trabajo:", rows = 3, width = "100%",
                          placeholder = "p. ej. Trabajé 20 años en una secretaría de Estado; viví la reforma administrativa de los 80…"),
            textAreaInput(ns("sugInt"), "Lo que me interesa hoy:", rows = 2, width = "100%",
                          placeholder = "p. ej. la participación ciudadana, el gobierno local, las mujeres en la política…"),
            selectizeInput(ns("sugMat"), "Materias o enfoques que me gustan:", choices = MATERIAS_CHOICES(), multiple = TRUE, width = "100%"),
            actionButton(ns("suggest"), "Sugerirme temas", class = "btn-primary btn-big", icon = icon("magic"), style = "width: 100%;"),
            uiOutput(ns("suggestions")))
      ),
      column(7,
        box(title = tagList(icon("lightbulb"), " Mis ideas"), status = "primary", solidHeader = TRUE, width = NULL,
            radioButtons(ns("filter"), NULL, inline = TRUE,
                         choices = c("Todas" = "all", "Nuevas y en exploración" = "open", "Descartadas" = "descartada"),
                         selected = "all"),
            uiOutput(ns("ideasList"))),
        box(title = "Explorar mis ideas con Claude", status = "info", solidHeader = TRUE, width = NULL,
            selectInput(ns("fbIdea"), "Ver comentarios de:", choices = c("Todas mis ideas" = ""), width = "100%"),
            ask_box_ui(ns, "ask", "Pregunte sobre la idea elegida arriba. P. ej.: ¿Qué periodo me conviene estudiar?", rows = 2),
            br(),
            uiOutput(ns("feedback")))
      )
    )
  )
}
