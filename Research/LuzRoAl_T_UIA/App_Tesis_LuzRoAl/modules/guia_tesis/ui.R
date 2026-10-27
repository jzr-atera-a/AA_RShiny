guia_tesis_ui <- function(id) {
  ns <- NS(id)
  li <- function(x) tags$ul(class = "guide-list", lapply(x, function(i) tags$li(HTML(i))))

  div(
    class = "explorer-tabs",
    tabsetPanel(
      id = ns("subtabs"), type = "tabs", selected = "avance",

      # ------------------------------------------------------------ 1. Progress
      tabPanel(
        title = "1. Mi avance", value = "avance", icon = icon("route"),
        uiOutput(ns("greeting")),
        uiOutput(ns("stats")),
        fluidRow(
          column(8, box(title = "El camino de su tesis, paso a paso", status = "primary", solidHeader = TRUE, width = NULL,
                        uiOutput(ns("route")))),
          column(4, box(title = "Cómo usar esta app", status = "info", solidHeader = TRUE, width = NULL,
                        div(class = "info-box-tpl", style = "margin-top: 0;",
                            tags$ol(class = "guide-list",
                                    tags$li("Siga las pestañas del menú de arriba hacia abajo."),
                                    tags$li("Todo lo que escribe se guarda solito."),
                                    tags$li(HTML("En cada pestaña puede pedirle ayuda a <b>Claude</b>: revisa, sugiere y contesta preguntas.")),
                                    tags$li("Los comentarios de Claude quedan guardados para leerlos después."),
                                    tags$li(HTML("Si se pierde, vuelva a <b>Mi avance</b>: le dice cuál es el siguiente paso.")))),
                        checkboxInput(ns("guideRead"), HTML("<b>Ya leí la guía</b> (las pestañas 2 a 4)"), FALSE)))
        )
      ),

      # ------------------------------------------------------------ 2. The degree then and now
      tabPanel(
        title = "2. La carrera: ayer y hoy", value = "carrera", icon = icon("university"),
        fluidRow(
          column(5,
            box(title = "Plan de estudios 1979–1980 (el que usted cursó)", status = "primary", solidHeader = TRUE, width = NULL,
                p(PLAN_1979$resumen),
                lapply(PLAN_1979$ejes, function(e) div(class = "dimension-display", tags$b(e$titulo), br(), e$texto)),
                div(class = "wm-hint", "Fuente: Biblioteca Francisco Xavier Clavigero, “Historia de las Carreras de la IBERO (1943–2021)”.")),
            box(title = "Lo que distingue a la carrera en la IBERO", status = "primary", solidHeader = TRUE, width = NULL,
                li(RASGOS_IBERO),
                tags$b("Hoy, quien egresa puede:"), li(PERFIL_EGRESO))
          ),
          column(7,
            box(title = "Plan de estudios actual (2026)", status = "primary", solidHeader = TRUE, width = NULL,
                p("Áreas de formación: ", tags$b(paste(AREAS_ACTUALES, collapse = " · "))),
                div(class = "plan-grid",
                    lapply(names(PLAN_ACTUAL), function(s) div(class = "plan-sem",
                      div(class = "plan-sem-title", s),
                      tags$ul(lapply(PLAN_ACTUAL[[s]], tags$li))))),
                div(class = "wm-hint", "Fuente: IBERO, Licenciatura en Ciencias Políticas y Administración Pública. Consulte en su coordinación la oferta del periodo.")),
            box(title = "Puentes entre su plan y el actual: ideas para empezar", status = "success", solidHeader = TRUE, width = NULL,
                p("Su generación vivió el México que hoy se estudia como historia. Estas ideas unen lo que usted aprendió con los enfoques actuales:"),
                lapply(seq_along(IDEAS_PUENTE), function(i) div(class = "bridge-row",
                  span(IDEAS_PUENTE[i]),
                  js_btn(" Agregar a mis ideas", ns("bridgeEvt"), i, "add", "btn-success btn-sm", icon_name = "plus"))))
          )
        )
      ),

      # ------------------------------------------------------------ 3. A good thesis
      tabPanel(
        title = "3. Una buena tesis", value = "buena", icon = icon("star"),
        fluidRow(
          column(6,
            box(title = "Qué hace buena a una tesis de Ciencias Políticas", status = "primary", solidHeader = TRUE, width = NULL,
                li(GUIA_BUENA_TESIS$criterios)),
            box(title = "Errores frecuentes (y cómo evitarlos)", status = "danger", solidHeader = TRUE, width = NULL,
                li(GUIA_BUENA_TESIS$errores))
          ),
          column(6,
            box(title = "Tipos de tesis que funcionan bien en esta carrera", status = "primary", solidHeader = TRUE, width = NULL,
                lapply(GUIA_BUENA_TESIS$tipos, function(t) div(class = "dimension-display", tags$b(t[[1]]), br(), t[[2]]))),
            box(title = "Un ejemplo de casa", status = "success", solidHeader = TRUE, width = NULL,
                p("La tesis de cinta negra ", tags$i("Análisis sobre el taekwondo, la guerra y la productividad en los negocios"),
                  " (Manuel Zubizarreta Segura, 2026) usa recursos que también sirven para su tesis:"),
                li(GUIA_BUENA_TESIS$ejemplo_casa))
          )
        )
      ),

      # ------------------------------------------------------------ 4. Structure, method and sources
      tabPanel(
        title = "4. Estructura, método y fuentes", value = "estructura", icon = icon("list-ol"),
        fluidRow(
          column(6,
            box(title = "Partes de la tesis (en orden)", status = "primary", solidHeader = TRUE, width = NULL,
                tags$ol(class = "guide-list", lapply(GUIA_BUENA_TESIS$estructura, tags$li)),
                div(class = "reference-box",
                    h4(style = "margin-top:0; color:#4f46e5;", "📏 Extensión orientativa"),
                    p("Una tesis de licenciatura suele tener entre 80 y 150 páginas. La app usa estas metas (se pueden cambiar en Administrador):"),
                    uiOutput(ns("targets")))),
            box(title = "Cómo citar (APA 7.ª edición)", status = "primary", solidHeader = TRUE, width = NULL,
                div(class = "prompt-box", tags$b("En el texto: "), "(Cosío Villegas, 1972, p. 21)  ·  Según Cosío Villegas (1972)…"),
                div(class = "prompt-box", tags$b("Libro: "), "Cosío Villegas, D. (1972). ", tags$i("El sistema político mexicano"), ". Joaquín Mortiz."),
                div(class = "prompt-box", tags$b("Documento oficial: "), "Secretaría de Gobernación. (1983, 3 de febrero). Decreto de reforma al artículo 115 constitucional. ", tags$i("Diario Oficial de la Federación"), "."),
                div(class = "prompt-box", tags$b("Entrevista propia: "), "se cita en el texto (nombre, comunicación personal, fecha) y se describe en la metodología y los anexos."),
                div(class = "wm-hint", "Confirme con su asesor/a el formato que pide la IBERO."))
          ),
          column(6,
            box(title = "El método en 5 decisiones", status = "primary", solidHeader = TRUE, width = NULL,
                tags$ol(class = "guide-list",
                        tags$li(HTML("<b>¿Qué tipo de estudio?</b> Caso, comparación, histórico, evaluación o ensayo teórico.")),
                        tags$li(HTML("<b>¿Dónde y cuándo?</b> Delimite lugar y periodo (p. ej. administración pública federal, 1982–2000).")),
                        tags$li(HTML("<b>¿Con qué conceptos?</b> Su marco teórico: Estado, poder, instituciones, gobernanza, políticas públicas…")),
                        tags$li(HTML("<b>¿Con qué fuentes?</b> Documentos, datos, bibliografía, entrevistas y su propio testimonio.")),
                        tags$li(HTML("<b>¿Cómo las analiza?</b> Análisis documental, histórico, de contenido, estadístico o comparado.")))),
            box(title = "Dónde buscar fuentes", status = "primary", solidHeader = TRUE, width = NULL,
                li(GUIA_BUENA_TESIS$fuentes))
          )
        )
      ),

      # ------------------------------------------------------------ 5. Claude and integrity
      tabPanel(
        title = "5. Pregúntele a Claude", value = "claude", icon = icon("robot"),
        fluidRow(
          column(5,
            box(title = "Claude como tutor (uso honesto de la IA)", status = "warning", solidHeader = TRUE, width = NULL,
                li(GUIA_BUENA_TESIS$ia)),
            box(title = "Pregunte lo que quiera sobre cómo hacer su tesis", status = "success", solidHeader = TRUE, width = NULL,
                ask_box_ui(ns, "ask", "Por ejemplo: ¿Cómo delimito un tema sobre el sistema político mexicano?", rows = 4),
                div(class = "quick-questions",
                    p(tags$b("O elija una pregunta frecuente:")),
                    lapply(seq_along(GUIA_PREGUNTAS), function(i)
                      js_btn(GUIA_PREGUNTAS[i], ns("quickEvt"), i, "ask", "btn-default quick-q"))))
          ),
          column(7, box(title = "Respuestas de Claude", status = "info", solidHeader = TRUE, width = NULL, uiOutput(ns("feedback"))))
        )
      )
    )
  )
}

GUIA_PREGUNTAS <- c(
  "¿Qué diferencia hay entre tema, problema y pregunta de investigación?",
  "¿Cómo puedo usar mi experiencia de vida como fuente sin que pierda rigor?",
  "¿Qué teorías de los años 70 siguen siendo útiles hoy en ciencia política?",
  "¿Cómo organizo mi tiempo para terminar la tesis en un año?",
  "¿Qué espera un sinodal en el examen profesional?"
)
