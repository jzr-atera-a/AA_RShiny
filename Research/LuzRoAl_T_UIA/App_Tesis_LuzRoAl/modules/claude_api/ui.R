claude_api_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("stats")),
    fluidRow(
      column(7,
        box(title = tagList(icon("robot"), " Conectar la app con Claude"), status = "primary", solidHeader = TRUE, width = NULL,
            p("Claude es el asistente de inteligencia artificial que le dará comentarios y sugerencias mientras escribe su tesis.",
              "Para usarlo se necesita una ", tags$b("clave de Claude (API key)"), "."),
            passwordInput(ns("api_key"), "Clave de Claude (empieza con sk-ant-…):", width = "100%",
                          placeholder = "sk-ant-api03-…"),
            uiOutput(ns("keyInfo")),
            checkboxInput(ns("remember"), "Recordar la clave en esta computadora (así no hay que escribirla cada vez)", FALSE),
            fluidRow(
              column(6, actionButton(ns("test"), "Probar conexión", class = "btn-success btn-big", icon = icon("plug"), style = "width: 100%;")),
              column(6, actionButton(ns("save"), "Guardar ajustes", class = "btn-primary btn-big", icon = icon("save"), style = "width: 100%;"))
            ),
            br(),
            uiOutput(ns("status"))
        ),
        box(title = "Ajustes de Claude", status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE,
            selectInput(ns("model"), "Modelo:", choices = CLAUDE_MODELS, width = "100%"),
            conditionalPanel("input.model == '__other__'", ns = ns,
                             textInput(ns("model_other"), "Nombre exacto del modelo:", width = "100%", placeholder = "p. ej. claude-sonnet-5-5")),
            fluidRow(
              column(6, numericInput(ns("max_tokens"), "Extensión máxima de respuesta (tokens):", value = 4000, min = 500, max = 32000, step = 500, width = "100%")),
              column(6, numericInput(ns("timeout"), "Tiempo de espera (segundos):", value = 300, min = 30, max = 900, step = 30, width = "100%"))
            ),
            div(class = "wm-hint", "Unas 4,000 unidades alcanzan para 2 o 3 páginas de comentarios. Si una respuesta sale cortada, súbalo.")
        )
      ),
      column(5,
        box(title = "Probar a Claude", status = "success", solidHeader = TRUE, width = NULL,
            p("Haga una pregunta corta para ver cómo responde:"),
            ask_box_ui(ns, "ask", "Por ejemplo: ¿Qué diferencia hay entre una tesis y una tesina?"),
            br(),
            uiOutput(ns("feedback"))
        ),
        box(title = "Información", status = "info", solidHeader = TRUE, width = NULL, collapsible = TRUE,
            div(class = "info-box-tpl", style = "margin-top: 0;",
                h4(style = "margin-top: 0; color: #667eea;", "💡 Para que sepa"),
                tags$ul(
                  tags$li("La clave se obtiene en ", tags$b("console.anthropic.com"), " (sección API Keys). El uso tiene un costo por consumo."),
                  tags$li("Si marca “Recordar la clave”, se guarda solo en esta computadora, en la carpeta ", tags$code("data/"), " de la app."),
                  tags$li("También se puede poner en la variable de entorno ", tags$code("ANTHROPIC_API_KEY"), "."),
                  tags$li("Cada vez que le pide algo a Claude, la app le manda el tema y el bosquejo de su tesis para que sus comentarios sean más útiles.")
                ))
        )
      )
    )
  )
}
