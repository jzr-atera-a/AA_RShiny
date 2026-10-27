# =============================================================================
# Capítulo 6 — Software, gemelo digital y entorno de Realidad Aumentada
# =============================================================================

ui_cap6 <- function() {
  tabItem(tabName = "cap6",
    fluidRow(
      caja("Capítulo 6: Software, gemelo digital y RA — Panorama",
        concepto(parrafo("Este capítulo presenta el software que da las órdenes a la cadena electrónica y que convierte el visor en interfaz
                 de operación, gemelo digital y sistema de medición: los dos procesos del servidor en la Jetson (incluido un hallazgo de
                 seguridad), el arranque de la sesión WebXR, la proyección del mapa sobre el piso, la aplicación de ocho modos, las pruebas
                 con el vehículo real, los algoritmos de suavizado ARC y SPLINE y el ajuste del filtro de Kalman."))
      )
    ),
    fluidRow(
      caja("6.1 Servidores en la Jetson — Tablas 6.1 a 6.3", ancho = 7, estado = "info",
        tabla_simple(tabla_procesos),
        parrafo("HTTPS se usa incluso en una red local porque el navegador solo concede sesiones immersive-ar a páginas servidas en un
                 contexto seguro. El servidor de archivos (Python 3.9 a 3.13) tiene un manejador propio de tipos MIME, cabeceras de
                 aislamiento de origen, bitácora filtrada, selección automática de IP y contexto TLS."),
        tabla_simple(tabla_servicios), br(), tabla_dt(tabla_mensajes, paginas = 8, botones = FALSE)
      ),
      caja("Hallazgo de seguridad", ancho = 5, estado = "danger",
        concepto(tipo = "rojo", parrafo("El servidor publica todo el directorio donde vive el script y su tabla de tipos declara .pem como
                 texto: cualquier dispositivo de la red puede descargar la llave privada del certificado. La llave del proyecto debe
                 considerarse comprometida y regenerarse.")),
        tags$ol(class = "description-text",
          tags$li("Servir solo una carpeta publico/ con lista blanca de extensiones (404 para todo lo demás)."),
          tags$li("Guardar cert.pem y key.pem en una carpeta privada con chmod 600."),
          tags$li("No incluir la llave en ningún repositorio ni proyecto compartido.")),
        tags$pre("openssl req -x509 -newkey rsa:2048 -keyout certs/key.pem \\\n  -out certs/cert.pem -days 365 -nodes"),
        p(class = "nota", "El servidor combinado para tableta (Listado E.7) repite el problema y requiere la misma corrección."),
        h4("Algoritmo 3 — Despachador del servidor de control"),
        tags$ol(class = "nota",
          tags$li("Comando directo (ALL:, MOTORS…) → filtro de seguridad → Arduino."),
          tags$li("MODE2_PATH → leer puntos de paso y λ; activar seguimiento con i ← 0."),
          tags$li("MODE2_STOP → desactivar seguimiento; trama de paro."),
          tags$li("SAVE_MODE1_ANALYSIS → guardar el análisis."),
          tags$li("Pose con seguimiento activo → calcular ep, ect, eψ y registrar.")),
        p(class = "nota", "Al terminar una trayectoria el servidor siempre agrega ALL:M1:0:M2:0:S1:90:S2:90.")
      )
    ),
    fluidRow(
      caja("6.3.1 El visor Meta Quest 3S — Tabla 6.4", ancho = 5, estado = "primary",
        figura("img/meta_quest_3s.jpg", "<b>Figura 6.2.</b> Meta Quest 3S con sus dos controles Touch Plus. Imagen del fabricante.", ancho = "75%"),
        tabla_simple(tabla_quest),
        parrafo("Cumple tres papeles: interfaz (dibuja mapa, gemelo y paneles sobre el passthrough), sensor de pose (el control izquierdo
                 montado en el vehículo es rastreado por las cámaras infrarrojas) y controlador (filtra la pose en cada cuadro y calcula
                 los lazos de los modos 2 y 5 cada 200 ms).")
      ),
      caja("6.3.2–6.3.3 Sesión WebXR y presupuesto por cuadro", ancho = 7, estado = "warning",
        parrafo("Arranque: verificar immersive-ar; crear la escena y preconstruir el vehículo; solicitar la sesión con local-floor (respaldo:
                 local); detectar el piso; crear plano colisionador, rejilla de 6 m y mapa. Presupuesto de referencia: ≥ 72 cuadros/s,
                 < 50 000 polígonos y < 100 llamadas de dibujo."),
        ecuacion("$$T_{cuadro} = \\frac{1}{f_{XR}} = \\frac{1}{72\\,\\text{Hz}} \\approx 13.9\\,\\text{ms} \\qquad (6.1)$$"),
        sliderInput("c6_fxr", "Frecuencia del visor (Hz)", 72, 120, 72, 1),
        uiOutput("c6_fxr_res"),
        h4("6.3.5 Aplicación de ocho modos — Tabla 6.5"), tabla_dt(tabla_modos, paginas = 8, botones = FALSE),
        h4("Tabla 6.6 — Mapa de controles"), tabla_simple(tabla_controles)
      )
    ),
    fluidRow(
      caja("6.3.4 Proyección del mapa M25 sobre el piso (GeoJSON del proyecto)", ancho = 12, estado = "success",
        fluidRow(
          column(4,
            ecuacion("$$x = \\frac{\\lambda-\\lambda_0}{0.0037}\\,(4.2\\,\\text{m}),\\qquad -z = \\frac{\\varphi-\\varphi_0}{0.0037}\\,(2.1\\,\\text{m}) \\qquad (6.2)$$",
                     "Con (λ₀, φ₀) = (0.000045, 0.000125); este hacia +x y norte hacia −z."),
            ecuacion("$$z_{3D} = \\left(\\frac{c_y}{2048}-0.5\\right)2.1\\,S + (S-1)\\cdot 1.05 \\qquad (6.3)$$",
                     "La escala S (100 a 150 %) crece solo hacia los lados y hacia el usuario."),
            sliderInput("c6_S", "Escala del mapa S (%)", 100, 150, 110, 5),
            radioButtons("c6_metodo", "Suavizado", c("SPLINE (smooth)" = "spline", "ARC (loop-safe)" = "arc", "Ninguno" = "no"), inline = TRUE),
            sliderInput("c6_R", "Radio de giro R (cm)", 5, 75, 45, 1),
            uiOutput("c6_map_res"),
            p(class = "nota", "Convención de colores del panel: rojo, anillo del GeoJSON; verde, trayectoria suavizada; puntos de paso cada
              20 cm. El criterio de diseño es R ≥ ρmin en las unidades del piso.")
          ),
          column(8, plotlyOutput("c6_mapa", height = "520px"))
        )
      )
    ),
    fluidRow(
      caja("6.4 Pruebas con el vehículo real en Realidad Aumentada", ancho = 12, estado = "primary",
        div(class = "galeria",
          figura("img/ra_vehiculo_real.jpg", "<b>Figura 6.4(a).</b> Vehículo real en el área de navegación (passthrough); el arco blanco es el límite del volumen de trabajo."),
          figura("img/ra_gemelo_superpuesto.jpg", "<b>Figura 6.4(b).</b> Gemelo digital 1:1 sobre el vehículo real y el mapa del M25."),
          figura("img/ra_panel_modo5.jpg", "<b>Figura 6.5(a).</b> Panel del modo 5 con selector ARC/SPLINE y escala del mapa (110 %)."),
          figura("img/ra_panel_modos.jpg", "<b>Figura 6.5(b).</b> Panel de modos y radio de giro de 17 cm."),
          figura("img/ra_trayectoria_rejilla.jpg", "<b>Figura 6.6.</b> Rojo: trayectoria dibujada; verde: optimizada según el radio de giro; naranja: registro del control montado."),
          figura("img/ra_m25_gemelo.jpg", "<b>Figura 6.7.</b> Anillo M25 en RA con el gemelo digital y el mapa de calor de tráfico simulado.")
        )
      )
    ),
    fluidRow(
      caja("6.4.3 Dos algoritmos de planeación de alto nivel", ancho = 6, estado = "info",
        parrafo("Una trayectoria dibujada a mano o tomada del GeoJSON tiene esquinas más cerradas que el radio mínimo de giro. Ambos
                 algoritmos buscan que la trayectoria verde aproxime a la roja respetando el radio, sin pasar obligatoriamente por cada
                 punto y sin formar lazos."),
        concepto(titulo = "ARC (loop-safe)",
          ecuacion("$$\\lVert p_j - p_{j-1}\\rVert \\ge 2R \\qquad (6.4)$$"),
          p("Simplifica conservando puntos separados al menos 2R (2.5R en la versión final) y redondea cada esquina con distancia de
            tangencia T = R tan(θ/2), limitada al 45 % del segmento más corto, mediante un arco de Bézier cuadrático.")),
        concepto(titulo = "SPLINE (smooth)",
          ecuacion("$$c(u) = \\tfrac12\\big[2p_1 + (p_2-p_0)u + (2p_0-5p_1+4p_2-p_3)u^2 + (3p_1-p_0-3p_2+p_3)u^3\\big] \\qquad (6.5)$$"),
          ecuacion("$$\\hat\\kappa_i = \\frac{|d_1\\times d_2|}{(s_1+s_2)/2},\\qquad \\text{se conserva } c_i \\text{ si } 1/\\hat\\kappa_i \\ge 0.8R \\qquad (6.6)$$"),
          p("Catmull-Rom con 20 muestras por segmento; en la versión final la entrada se adelgaza a 2R y el radio efectivo en esquinas
            cerradas es ≈ 0.8R. El radio práctico mínimo a escala 110 % resultó de unos 40 cm."))
      ),
      caja("6.4.4 Iteraciones de ajuste del filtro de Kalman — Tabla 6.7", ancho = 6, estado = "warning",
        ecuacion("$$P_\\infty^- = \\frac{\\sigma_q^2+\\sqrt{\\sigma_q^4+4\\sigma_q^2\\sigma_r^2}}{2},\\quad K_\\infty = \\frac{P_\\infty^-}{P_\\infty^-+\\sigma_r^2},\\quad N_\\tau = \\frac{-1}{\\ln(1-K_\\infty)} \\qquad (6.7)$$"),
        DTOutput("c6_kalman_tabla"),
        concepto(tipo = "verde", p("La solución estable separó ambas funciones: filtros de Kalman moderados para el ruido y una compuerta
                 física para los saltos, que son errores de rastreo y no ruido gaussiano."))
      )
    ),
    fluidRow(
      caja("6.4.5–6.4.6 Resultados registrados (abril de 2026)", ancho = 12, estado = "success",
        fluidRow(column(6, h4("Tabla 6.8 — Corrida del modo 5 con pérdida de rastreo"), tabla_simple(tabla_corrida_m5)),
                 column(6, h4("Tabla 6.9 — Corridas finales del modo 5"), tabla_simple(tabla_corridas_finales),
                        concepto(p("En la corrida 2, en la esquina del punto 23 la desviación creció hasta 18.3 cm; el término lateral de
                          Stanley la redujo a 0.3 cm en 18 s. Giros cerrados: ALL:M1:100:M2:50:S1:90:S2:40 a la derecha y
                          ALL:M1:50:M2:100:S1:90:S2:140 a la izquierda (M1 = motor izquierdo). Las 1286 tramas se aplicaron sin un solo
                          ERR:RANGE.")))),
        plotlyOutput("c6_corridas", height = "260px")
      )
    ),
    fluidRow(
      caja("6.5 Formatos de datos — Tabla 6.10", ancho = 7, estado = "primary", tabla_simple(tabla_formatos),
        p(class = "nota", "El CSV de seguimiento propuesto reúne referencia, pose estimada, errores, mandos, batería y temperatura; permite
          preguntar, por ejemplo, si el error transversal crece cuando baja el voltaje. La pestaña Análisis de pruebas en R lo implementa.")),
      caja("6.6–6.7 Simulación, R y plan de estudios", ancho = 5, estado = "info",
        parrafo("Una API Flask ejecutada con NVIDIA Isaac Sim lanza simulaciones de un vehículo de 1500 kg con PID sobre rutas reales (por
                 ejemplo York–Oxford: 286.4 km, 287 puntos, a 60 Hz). Una aplicación R Shiny modular filtra escenarios por tráfico, tipo
                 de vía, infraestructura y clima, y una API en R Plumber sirve el visor (el error encontrado fue la falta de
                 #* @serializer html)."),
        parrafo("El software aplica los módulos IX (servicios, permisos, procesos), XI (procesador de 64 bits multinúcleo), VIII (protocolos
                 de tramas de texto en UART, USB y WebSocket) y XIII (la RA como interfaz humano-máquina del robot)."))
    )
  )
}

server_cap6 <- function(input, output, session, geo) {
  output$c6_fxr_res <- renderUI({
    T <- 1000 / input$c6_fxr
    resultado(celda(paste(fmt(T, 1), "ms"), "Presupuesto por cuadro"), celda(fmt(input$c6_fxr / 5, 1), "Cuadros por ciclo de 5 Hz"))
  })
  mapa <- reactive({
    S <- input$c6_S / 100; capas <- geo_a_capas(geo, S); ring <- anillo_m25(geo, S); R <- input$c6_R / 100
    verde <- switch(input$c6_metodo, spline = suavizar_spline(ring, R), arc = suavizar_arc(ring, R), no = remuestrear(ring, 0.05))
    list(capas = capas, ring = ring, verde = verde, W = puntos_de_paso(verde), S = S)
  })
  output$c6_map_res <- renderUI({
    m <- mapa(); k <- curvatura_discreta(remuestrear(m$verde, 0.05)); rmin <- 1 / max(k[k > 0])
    resultado(celda(paste(fmt(4.2 * m$S, 2), "×", fmt(2.1 * m$S, 2), "m"), "Tamaño del mapa"),
              celda(paste(fmt(max(longitudes(m$verde)), 2), "m"), "Longitud verde"),
              celda(nrow(m$W), "Puntos de paso a 20 cm"),
              celda(paste(fmt(rmin * 100, 0), "cm"), "Radio local mínimo", if (rmin < 0.5) "warn" else "ok"))
  })
  output$c6_mapa <- renderPlotly({
    m <- mapa(); c <- m$capas; L <- c$lineas
    p <- plot_ly()
    if (!is.null(c$zona)) p <- p %>% add_polygons(x = c$zona$x, y = -c$zona$z, fillcolor = "rgba(160,170,185,.25)",
                                                  line = list(color = "rgba(120,130,145,.6)"), name = "Central London", hoverinfo = "name")
    rio <- L[L$tipo == "river", ]
    p <- p %>% add_paths(x = rio$x, y = -rio$z, line = list(color = "#4A90E2", width = 3), name = "Río Támesis")
    rad_ <- L[L$tipo == "highway" & L$id != "m25_orbital", ]
    for (id in unique(rad_$id)) { s <- rad_[rad_$id == id, ]
      p <- p %>% add_paths(x = s$x, y = -s$z, line = list(color = "#5D6D7E", width = 2), name = "Autopistas radiales",
                           legendgroup = "rad", showlegend = id == unique(rad_$id)[1], text = s$nombre[1], hoverinfo = "text") }
    ring <- m$ring; pos <- seq(0, 1, length.out = nrow(ring))
    p <- p %>% add_markers(x = ring[, 1], y = -ring[, 2], marker = list(color = pos, colorscale = list(c(0, "#2E9D6A"), c(0.5, "#E8A317"), c(1, "#C0392B")),
                                                                       size = 9, opacity = .45), name = "Mapa de calor simulado", hoverinfo = "skip") %>%
      add_paths(x = ring[, 1], y = -ring[, 2], line = list(color = COL$ideal, width = 2.5), name = "M25 del GeoJSON (rojo)")
    if (input$c6_metodo != "no") p <- p %>% add_paths(x = m$verde[, 1], y = -m$verde[, 2], line = list(color = COL$suave, width = 3.5), name = "Trayectoria suavizada (verde)")
    p <- p %>% add_markers(x = m$W$x, y = -m$W$z, marker = list(color = "#fff", size = 6, line = list(color = COL$suave, width = 2)), name = "Puntos de paso (20 cm)") %>%
      add_text(x = c$puntos$x, y = -c$puntos$z, text = c$puntos$nombre, textfont = list(size = 10, color = "#34495E"), name = "Lugares", visible = "legendonly") %>%
      add_markers(x = m$W$x[1], y = -m$W$z[1], marker = list(color = "#D63AF9", size = 14, symbol = "triangle-up"), name = "Cono de inicio")
    p %>% tema(NULL, NULL) %>% plano_piso()
  })
  output$c6_kalman_tabla <- renderDT({
    d <- tabla_kalman_iter
    k <- mapply(function(a, b) if (is.na(a)) NA else kalman_estacionario(a, b)$K, d$sq, d$sr)
    tt <- mapply(function(a, b) if (is.na(a)) NA else kalman_estacionario(a, b)$t, d$sq, d$sr)
    out <- data.frame(`It.` = d$`It.`, Filtro = d$Filtro, `(σq², σr²)` = ifelse(is.na(d$sq), "2.8 cm y 10.3° por muestra", paste0("(", d$sq, ", ", d$sr, ")")),
                      `K∞; tτ` = ifelse(is.na(k), "–", paste0(fmt(k, 3), "; ", ifelse(tt < 1, paste(round(tt * 1000), "ms"), paste(fmt(tt, 2), "s")))),
                      `Observación` = d$`Observación`, check.names = FALSE)
    tabla_simple(out)
  })
  output$c6_corridas <- renderPlotly({
    d <- data.frame(c = c("Corrida previa (Tabla 6.8)", "Corrida 1", "Corrida 2"), tipica = c(5, 7, 5), max = c(30.6, 7, 18.3))
    plot_ly(d, x = ~c) %>% add_bars(y = ~tipica, name = "Desviación típica máx. (cm)", marker = list(color = COL$verde)) %>%
      add_bars(y = ~max, name = "Desviación máxima registrada (cm)", marker = list(color = COL$rojo)) %>%
      add_lines(x = d$c, y = rep(8, 3), name = "Criterio de 8 cm (Tabla 7.2)", line = list(color = COL$ambar, dash = "dash")) %>%
      tema(NULL, "cm") %>% layout(barmode = "group")
  })
}
