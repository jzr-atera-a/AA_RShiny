# =============================================================================
# Capítulo 8, Plan de estudios CPM, Bibliografía y Anexos
# =============================================================================

ui_cap8 <- function() {
  tabItem(tabName = "cap8",
    fluidRow(
      caja("Capítulo 8: Conclusiones y trabajo futuro — Panorama",
        concepto(parrafo("Este capítulo responde la pregunta de investigación, relaciona cada contribución con la evidencia que la sostiene,
                 muestra cómo el proyecto integra los trece módulos de la carrera, reconoce las limitaciones y propone el trabajo futuro
                 en tres horizontes."))
      )
    ),
    fluidRow(
      caja("8.1 Respuesta a la pregunta de investigación", estado = "warning",
        fluidRow(
          column(3, concepto(titulo = "Progresiva", p("Cada etapa produce un conocimiento que la siguiente necesita y una limitación medible
                 que la motiva: 8.51 % de error a 115 200 baudios y 244 Hz de PWM mínimo justificaron el Arduino; un microcontrolador
                 no puede servir una página segura, lo que justificó la Jetson. El resultado es una jerarquía: el PIC como nodo de
                 sensores, el Arduino como controlador de actuadores y la Jetson como integrador."))),
          column(3, concepto(tipo = "verde", titulo = "Demostrada en el vehículo real", p("Vuelta autónoma al anillo M25 suavizado con
                 SPLINE (28 de 28 puntos de paso, radio de 45 cm, escala 110 %), con desviación típica de 0 a 7 cm, y 1286 tramas sin un
                 solo error del Arduino, con el lazo de posición cerrado a 5 Hz."))),
          column(3, concepto(tipo = "ambar", titulo = "Segura", p("Paro repartido en capas independientes: interrupción del PIC con relevador
                 opcional, filtro de la Jetson y vigilante de comandos del Arduino (diseñado, ausente en el firmware vigente), con una
                 función de habilitación implementable en firmware y en hardware."))),
          column(3, concepto(tipo = "gris", titulo = "Medible", p("El gemelo digital permite dibujar una trayectoria sobre el piso real,
                 ejecutarla con un generador Ackermann a 5 Hz y medir la pose con el control del visor. La tesis entrega el instrumento de
                 medición y el diseño de la campaña; la parte abierta es completar los valores cuantitativos.")))
        )
      )
    ),
    fluidRow(
      caja("8.2 Contribuciones y evidencia — Tabla 8.1", ancho = 7, estado = "success", tabla_simple(tabla_contribuciones)),
      caja("Estado de las pruebas registradas", ancho = 5, estado = "info", plotlyOutput("c8_pruebas", height = "300px"))
    ),
    fluidRow(
      caja("8.3 El proyecto como integración de los módulos de electrónica", ancho = 12, estado = "primary",
        fluidRow(
          column(6,
            concepto(titulo = "Del módulo I al II: la energía condiciona la electrónica", p("El presupuesto de corriente mostró que la carga
                     dominante es la Jetson; un regulador lineal disiparía (12 − 5) × 2 = 14 W, de ahí el buck de 5 A. El pico de arranque,
                     no la corriente nominal, dimensiona el fusible, el MOSFET del MD22 y el TVS.")),
            concepto(titulo = "De los módulos III a V: la lógica que protege a la potencia", p("La función de habilitación es el único lugar
                     donde convergen las señales de los tres niveles; exige adaptar familias de 3.3 V, 5 V y ±10 V y guardar calibraciones
                     en EEPROM.")),
            concepto(titulo = "De los módulos VI a IX: el microcontrolador como sistema completo", p("El conflicto del preescalador
                     compartido entre Timer0 y watchdog no se resuelve sabiendo solo programar ni solo configurar periféricos: hace falta el
                     diagrama de tiempo (trama de 42 ms frente a 18 ms del watchdog) y la arquitectura que explica por qué el recurso es único."))
          ),
          column(6,
            concepto(titulo = "El módulo X: la frontera con el mundo físico", p("14.7 mV de batería por cuenta y un voltaje promedio D·Vbat en
                     cada motor; la razón de los anchos de pulso de 2008 reproduce la geometría Ackermann con 0.034 de diferencia
                     cuadrática media.")),
            concepto(titulo = "Módulos XI y XII: el reparto del cómputo", p("La arquitectura de tres niveles responde qué tarea corresponde a
                     un microcontrolador y cuál a un procesador con sistema operativo, a partir de números calculados, no de preferencias.")),
            concepto(titulo = "El módulo XIII: la retroalimentación como síntesis", p("Los cuatro lazos resumen la carrera: servo (II),
                     supervisión (III, X, XII), trayectoria (XI, VIII, IX) y velocidad propuesta (V, VIII, X)."))
          )
        ),
        div(class = "pregunta", "Ningún módulo queda sin aplicación: el vehículo es el lugar donde los trece módulos dejan de ser materias y
            se convierten en un sistema que se mueve, se mide y se detiene con seguridad.")
      )
    ),
    fluidRow(
      caja("8.4 Limitaciones", ancho = 5, estado = "danger",
        tags$ul(class = "description-text",
          tags$li("Faltan mediciones cuantitativas de latencia y consumo, y la campaña completa de 36 corridas."),
          tags$li("Lazo abierto en velocidad: los codificadores de 2008 no están integrados."),
          tags$li("Dependencia del rastreo del visor."),
          tags$li("Constante del servo sin medir y parámetros geométricos del software sin actualizar."),
          tags$li("Nodo de sensores del PIC sin implementación física."),
          tags$li("El servidor HTTPS expone la llave privada del certificado."),
          tags$li("Los archivos vigentes solo existen en el historial de sesiones; deben pasar a un repositorio."),
          tags$li("No hay pruebas automatizadas del intérprete de comandos ni de los cálculos de curvatura y error."))),
      caja("8.5 Trabajo futuro", ancho = 7, estado = "success",
        tabBox(width = 12,
          tabPanel("Inmediato", tags$ul(lapply(trabajo_futuro[[1]], tags$li))),
          tabPanel("Corto plazo", tags$ul(lapply(trabajo_futuro[[2]], tags$li))),
          tabPanel("Mediano plazo", tags$ul(lapply(trabajo_futuro[[3]], tags$li))),
          tabPanel("Largo plazo", tags$ul(lapply(trabajo_futuro[[4]], tags$li)),
                   p(class = "nota", "Vehículos autónomos, gemelos digitales y logística en el Reino Unido y México: el gemelo digital deja de
                     ser solo la representación del robot y se convierte en la de un sistema de transporte (Grieves y Vickers, 2017).")))
      )
    ),
    fluidRow(
      caja("8.6 Comentario final", estado = "primary",
        parrafo("Más allá del vehículo, el valor de este trabajo está en mostrar que los trece módulos de una carrera técnica no son temas
                 aislados: un divisor de voltaje, un mapa de Karnaugh, una ecuación de velocidad serie y un filtro de Kalman terminan en el
                 mismo sistema y se necesitan mutuamente. Documentar esa ruta con honestidad, incluidos los errores y los datos que faltan,
                 es lo que permite a la siguiente generación de estudiantes recorrerla más rápido. Y el mismo vehículo que comenzó en 2008
                 como un ejercicio de inteligencia artificial en un laboratorio universitario queda hoy como un banco de pruebas para
                 gemelos digitales de transporte y logística, con la perspectiva de aplicarse tanto en el Reino Unido como en México."))
    )
  )
}

ui_plan <- function() {
  tabItem(tabName = "plan",
    fluidRow(
      caja("Plan de estudios CPM: Técnico en Automatización Industrial", estado = "warning",
        parrafo("La carrera dura 18 meses y se compone de trece módulos con 68 semanas lectivas. La Tabla 2.7 relaciona cada módulo con el
                 lugar donde aparece en el robot y con el capítulo que lo desarrolla; es la columna vertebral del documento."),
        fluidRow(column(6, plotlyOutput("plan_semanas", height = "380px")),
                 column(6, selectInput("plan_mod", "Módulo", setNames(modulos_cpm$num, paste0(modulos_cpm$romano, ". ", modulos_cpm$nombre)), width = "100%"),
                        uiOutput("plan_detalle")))
      )
    ),
    fluidRow(
      caja("Tabla 2.7 y Tabla 8.2 — Correspondencia y evidencia", estado = "primary",
        tabla_dt(data.frame(`Módulo` = paste0(modulos_cpm$romano, ". ", modulos_cpm$nombre), Semanas = modulos_cpm$semanas,
                            `Dónde aparece en el robot` = modulos_cpm$donde, `Cap.` = modulos_cpm$capitulos,
                            `Componentes y cálculos` = modulos_cpm$evidencia, `Dónde se documenta` = modulos_cpm$documenta,
                            check.names = FALSE), paginas = 13))
    )
  )
}

ui_biblio <- function() {
  tabItem(tabName = "biblio",
    fluidRow(
      caja("Bibliografía", estado = "primary",
        parrafo("La tesis cita 16 fuentes externas en estilo Harvard (hojas de datos, informes técnicos, libros, artículos y especificaciones)
                 y tres documentos internos del proyecto. Use los filtros para explorarlas; la tabla se puede exportar."),
        fluidRow(column(4, selectInput("bib_tipo", "Tipo", c("Todos", sort(unique(bibliografia$Tipo))))),
                 column(4, selectInput("bib_tema", "Tema", c("Todos", sort(unique(bibliografia$Tema))))),
                 column(4, textInput("bib_txt", "Buscar", placeholder = "autor, título o tema…"))),
        DTOutput("bib_tabla"))
    ),
    fluidRow(
      caja("Fuentes por tipo", ancho = 6, estado = "info", plotlyOutput("bib_tipo_plot", height = "300px")),
      caja("Fuentes por tema", ancho = 6, estado = "success", plotlyOutput("bib_tema_plot", height = "300px"))
    ),
    fluidRow(
      caja("Referencias clave por línea de trabajo", estado = "warning",
        fluidRow(
          column(3, concepto(titulo = "Seguimiento de trayectorias", tags$ul(tags$li(strong("Coulter (1992):"), " persecución pura en Carnegie Mellon."),
                 tags$li(strong("Snider (2009):"), " comparación de persecución pura, Stanley y controladores basados en modelo."),
                 tags$li(strong("Rajamani (2012):"), " modelo cinemático de bicicleta.")))),
          column(3, concepto(titulo = "Estimación", tags$ul(tags$li(strong("Kalman (1960):"), " el filtro original."),
                 tags$li(strong("Welch y Bishop (1995):"), " presentación didáctica del filtro.")))),
          column(3, concepto(titulo = "Gemelo digital y RA", tags$ul(tags$li(strong("Grieves y Vickers (2017):"), " definición del gemelo digital."),
                 tags$li(strong("W3C (2026):"), " WebXR Device API."), tags$li(strong("three.js (s.f.):"), " escena 3D sobre WebGL.")))),
          column(3, concepto(titulo = "Hardware", tags$ul(tags$li(strong("Microchip (2003):"), " PIC16F87XA."),
                 tags$li(strong("Devantech (s.f.):"), " MD22."), tags$li(strong("NXP (2021):"), " bus I²C."),
                 tags$li(strong("Arduino, NVIDIA, Analog Devices, Bambu Lab:"), " documentación técnica."))))
        ))
    )
  )
}

ui_anexos <- function() {
  tabItem(tabName = "anexos",
    fluidRow(
      caja("Abreviaturas", ancho = 5, estado = "primary", tabla_dt(tabla_abreviaturas, paginas = 20, botones = FALSE)),
      caja("Nomenclatura", ancho = 7, estado = "info",
        p(class = "nota", "Vectores en negritas minúsculas; matrices y constantes en mayúsculas; ángulos en radianes salvo que se indique °.
          Se reservan R para resistencia, ρ para radio de giro y σr² para el ruido de medición; La para inductancia y ℓ para distancia entre ejes."),
        tabla_dt(tabla_nomenclatura, paginas = 12))
    ),
    fluidRow(
      caja("Apéndice B — Derivaciones de apoyo", ancho = 12, estado = "success",
        fluidRow(
          column(4, h4("B.1 Curvatura y ángulo de dirección"),
                 parrafo("En el modelo de bicicleta, el centro instantáneo C está sobre la prolongación del eje trasero a una distancia ρ.
                          En el triángulo rectángulo RFC el ángulo en C es igual a δ:"),
                 ecuacion("$$\\tan\\delta = \\frac{\\ell}{\\rho} = \\ell\\kappa \\;\\Rightarrow\\; \\delta = \\arctan(\\ell\\kappa) \\qquad (B.1)$$"),
                 p(class = "nota", "En las ruedas reales, δ_int,ext = arctan(ℓ/(ρ ∓ b/2)).")),
          column(4, h4("B.2 Fórmula de Menger"),
                 parrafo("Por la ley de los senos 2ρ = a/sin Â y el área es 𝒜 = ½ b′c sin Â, de donde:"),
                 ecuacion("$$\\rho = \\frac{a\\,b'\\,c}{4\\mathcal A},\\qquad \\kappa = \\frac1\\rho = \\frac{4\\mathcal A}{|AB|\\,|BC|\\,|CA|} \\qquad (B.2)$$"),
                 p(class = "nota", "Si los puntos son colineales, 𝒜 = 0 y κ = 0.")),
          column(4, h4("B.3 Ganancia del filtro de Kalman escalar"),
                 parrafo("Para xk = xk−1 + wk y zk = xk + vk, la varianza del error es"),
                 ecuacion("$$P_k = (1-K)^2P_k^- + K^2\\sigma_r^2 \\qquad (B.3)$$"),
                 parrafo("Derivando e igualando a cero: Kk = Pk⁻/(Pk⁻ + σr²) y Pk = (1 − Kk)Pk⁻."))
        ))
    ),
    fluidRow(
      caja("Apéndice G — Archivos del proyecto CPM Completion", ancho = 8, estado = "warning", tabla_dt(tabla_archivos, paginas = 14),
           p(class = "nota", "Los apéndices A y C a F (modelos 3D y los 36 listados de programas del PIC, el Arduino, la Jetson y la aplicación
             WebXR) están en la pestaña Apéndices técnicos.")),
      caja("Material audiovisual (Tabla G.2)", ancho = 4, estado = "danger",
        tags$ul(class = "description-text",
          tags$li(strong("M1:"), " vehículo ejecutando una trayectoria dibujada en RA (prueba T-03)."),
          tags$li(strong("M2:"), " vista desde el visor del mapa y el gemelo a escala 1:1."),
          tags$li(strong("M3:"), " paro de emergencia de extremo a extremo (prueba P4-06)."),
          tags$li(strong("M4:"), " corridas finales del modo 5 con bitácoras del servidor.")),
        p(class = "nota", "Ubicación: archivo del autor."))
    )
  )
}

server_cap8_extra <- function(input, output, session) {
  output$c8_pruebas <- renderPlotly({
    todas <- c(tabla_pruebas_12$Estado, tabla_pruebas_34$Estado, tabla_pruebas_sistema$Resultado)
    cat_ <- ifelse(grepl("^Aprobada|Fluido", todas), "Aprobada", ifelse(grepl("Falló", todas), "Falló y se corrigió",
                   ifelse(grepl("Implementada", todas), "Implementada", "Definida / otra")))
    t <- table(factor(cat_, levels = c("Aprobada", "Falló y se corrigió", "Implementada", "Definida / otra")))
    plot_ly(labels = names(t), values = as.vector(t), type = "pie", hole = 0.55, sort = FALSE,
            marker = list(colors = c(COL$verde, COL$rojo, COL$ambar, COL$gris)), textinfo = "value") %>%
      tema(leyenda = TRUE) %>% layout(annotations = list(list(text = paste0(sum(t), "<br>pruebas"), showarrow = FALSE, font = list(size = 16))))
  })
  output$plan_semanas <- renderPlotly({
    d <- modulos_cpm; d$etq <- factor(paste0(d$romano, ". ", d$nombre), levels = rev(paste0(d$romano, ". ", d$nombre)))
    sel <- as.integer(input$plan_mod)
    plot_ly(d, y = ~etq, x = ~semanas, type = "bar", orientation = "h",
            marker = list(color = ifelse(d$num == sel, COL$ambar, COL$azul2)), text = ~paste(semanas, "semanas"), hoverinfo = "text") %>%
      tema("Semanas lectivas (total 68)", NULL, leyenda = FALSE) %>% layout(margin = list(l = 260))
  })
  output$plan_detalle <- renderUI({
    m <- modulos_cpm[modulos_cpm$num == as.integer(input$plan_mod), ]
    div(class = "panel-modulo",
        h3(paste0("Módulo ", m$romano, ". ", m$nombre)), etiqueta(paste(m$semanas, "semanas")), etiqueta(paste("Capítulos", m$capitulos)),
        etiqueta(m$bloque, "warn"),
        h4("Dónde aparece en el robot"), p(m$donde),
        h4("Cómo se materializa (sección 5.7)"), parrafo(m$parrafo),
        h4("Evidencia (Tabla 8.2)"), p(m$evidencia, br(), span(class = "small-muted", m$documenta)))
  })
  bib <- reactive({
    d <- bibliografia
    if (input$bib_tipo != "Todos") d <- d[d$Tipo == input$bib_tipo, ]
    if (input$bib_tema != "Todos") d <- d[d$Tema == input$bib_tema, ]
    if (nzchar(input$bib_txt)) { q <- input$bib_txt
      d <- d[grepl(q, d$Clave, ignore.case = TRUE) | grepl(q, d$`Título`, ignore.case = TRUE) | grepl(q, d$Tema, ignore.case = TRUE), ] }
    d
  })
  output$bib_tabla <- renderDT({
    d <- bib(); d$Enlace <- ifelse(nzchar(d$Enlace), sprintf("<a href='%s' target='_blank' rel='noopener'>Abrir</a>", d$Enlace), "Documento interno")
    d$`Año` <- ifelse(is.na(d$`Año`), "s.f.", d$`Año`)
    DT::datatable(d, rownames = FALSE, escape = setdiff(seq_along(d) - 1, which(names(d) == "Enlace") - 1), extensions = "Buttons",
                  class = "cell-border stripe hover compact",
                  options = list(pageLength = 10, dom = "Bfrtip", buttons = list("copy", "csv", "excel"), language = idioma_dt, scrollX = TRUE))
  })
  output$bib_tipo_plot <- renderPlotly({
    t <- sort(table(bibliografia$Tipo), decreasing = TRUE)
    plot_ly(x = as.vector(t), y = factor(names(t), levels = rev(names(t))), type = "bar", orientation = "h", marker = list(color = COL$azul2)) %>%
      tema("Número de fuentes", NULL, leyenda = FALSE) %>% layout(margin = list(l = 160))
  })
  output$bib_tema_plot <- renderPlotly({
    t <- sort(table(bibliografia$Tema), decreasing = TRUE)
    plot_ly(labels = names(t), values = as.vector(t), type = "pie", hole = 0.45,
            marker = list(colors = c(COL$azul, COL$cian, COL$ambar, COL$verde, COL$violeta, COL$rojo, COL$gris, COL$naranja, "#8E9AAF", "#2A6FB5", "#A3C4BC"))) %>%
      tema()
  })
}
