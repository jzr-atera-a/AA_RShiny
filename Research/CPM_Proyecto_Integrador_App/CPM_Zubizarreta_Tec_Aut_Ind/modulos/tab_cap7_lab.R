# =============================================================================
# Capítulo 7 — Planeación, seguimiento y validación; Laboratorio; Análisis en R
# =============================================================================

ui_cap7 <- function() {
  tabItem(tabName = "cap7",
    fluidRow(
      caja("Capítulo 7: Planeación, seguimiento de trayectorias y validación — Panorama",
        concepto(parrafo("Núcleo de robótica de la tesis: el generador de comandos que convierte una trayectoria dibujada en órdenes de
                 motor y dirección a 5 Hz, las métricas de seguimiento, el estimador de pose basado en el control del visor (Kalman y
                 compuerta física), las pruebas realizadas, la campaña cuantitativa, las lecciones y las limitaciones. Para ejecutar estos
                 algoritmos, use el Laboratorio de seguimiento."))
      )
    ),
    fluidRow(
      caja("7.1–7.2 Coordenadas y generador de comandos Ackermann", ancho = 7, estado = "primary",
        parrafo("El plano de trabajo es xz del espacio WebXR, con y vertical; el origen es la posición del usuario al iniciar la sesión, el
                 norte es −z y el este +x. En el modo 2 el cliente proyecta la posición del control al piso y crea un punto de paso cada
                 20 cm, con el rumbo hacia el siguiente:"),
        ecuacion("$$\\psi_i = \\operatorname{atan2}(x_{i+1}-x_i,\\ z_{i+1}-z_i) \\qquad (7.1)$$"),
        ecuacion("$$\\kappa_i^{sat} = \\operatorname{sgn}(\\kappa_i)\\min(|\\kappa_i|,\\kappa_{max}),\\qquad \\kappa_{max} = \\frac{1}{\\rho_{min}} = 2.0\\,\\text{m}^{-1} \\qquad (7.2)$$"),
        ecuacion("$$\\delta_i = \\arctan(\\ell\\,\\kappa_i^{sat}),\\qquad \\theta_{s,i} = \\operatorname{clamp}(90^\\circ + k_s\\delta_i,\\ 40^\\circ,\\ 140^\\circ) \\qquad (7.3)$$"),
        ecuacion("$$v_{ext,int} = v\\left(1 \\pm \\lambda\\,\\frac{b\\,\\kappa^{sat}}{2}\\right),\\qquad \\lambda\\in\\{0.25,\\,0.5,\\,0.75\\} \\qquad (7.4)$$"),
        ecuacion("$$u = u_{min} + (u_{max}-u_{min})\\,\\frac{v - v_{min}}{v_{max}-v_{min}},\\qquad u_{min} = 40\\,\\%,\\ u_{max} = 100\\,\\% \\qquad (7.5)$$"),
        p(class = "nota", "Velocidad de crucero de referencia v̄ = 0.13 m/s dentro de 0.08–0.20 m/s; se reduce con la distancia restante y
          siempre se agrega una trama de paro. ks = 40/30 en los modos 1 a 3 y 50/30 en el modo 5.")
      ),
      caja("7.3 Control vigente en el visor (modos 2 y 5)", ancho = 5, estado = "warning",
        ecuacion("$$\\delta = \\operatorname{sat}_{\\pm30^\\circ}\\Big(\\operatorname{wrap}(\\psi^*-\\psi_v) - \\operatorname{sat}_{\\pm15^\\circ}\\arctan\\frac{k\\,e_\\ell}{v}\\Big) \\qquad (7.6)$$",
                 "ψ* = atan2(xᵢ − x, zᵢ − z); e<sub>ℓ</sub> error lateral con signo (positivo a la izquierda); k = 2, v = 0.5 m/s. Si |e<sub>ℓ</sub>| > 12 cm, dirección máxima hacia la trayectoria."),
        parrafo("Modo 5: 85 % en recta y, con f = |δ|/30°, 85 + 15f para la rueda exterior y 85 − 35f para la interior (100/50 % en el
                 giro máximo). El motor interior es el del lado del giro: M1 (izquierdo) en el giro a la izquierda."),
        h4("7.3.2 Tasas de procesamiento — Tabla 7.1"), tabla_dt(tabla_tasas, paginas = 9, botones = FALSE)
      )
    ),
    fluidRow(
      caja("7.3.1 Convención de dirección y la inversión observada — prueba de signo", ancho = 12, estado = "danger",
        fluidRow(
          column(5,
            parrafo("El rumbo al objetivo, atan2(Δx, Δz), vale cero hacia +z; la guiñada del cuaternión del control vale cero hacia −z.
                     Sus ceros difieren en π, de modo que el error calculado es e + π: el término de rumbo queda siempre saturado y con
                     signo contrario. Invertir el signo de la conversión al servo devolvía el sentido del giro, pero dejaba un control
                     todo-nada (S2 en 40 o 140°)."),
            concepto(tipo = "verde", titulo = "Solución en tres partes", tags$ol(
              tags$li("Una sola convención: δ > 0 = izquierda, θS2 = 90° + ks δ (140° a la izquierda), M1 = motor izquierdo."),
              tags$li("Rumbo del vehículo en el marco del objetivo: ψv = ψq + π + φm (φm: ángulo de montaje)."),
              tags$li("Prueba de signo con las ruedas en el aire: un punto 1 m adelante y 0.3 m a la izquierda debe dar δ > 0, S2 > 90° y
                       M1 más lento que M2.")))
          ),
          column(7,
            fluidRow(column(4, radioButtons("c7_conv", "Rumbo usado", c("ψv = ψq (sin corregir)" = "bug", "ψv = ψq + π + φm" = "ok"))),
                     column(4, sliderInput("c7_phim", "Montaje φm (°)", -45, 45, 0, 1)),
                     column(4, sliderInput("c7_lat", "Punto de prueba a la izquierda (m)", -0.6, 0.6, 0.3, 0.05))),
            uiOutput("c7_signo")
          )
        )
      )
    ),
    fluidRow(
      caja("7.4 Métricas de seguimiento", ancho = 6, estado = "info",
        ecuacion("$$e_\\psi = \\operatorname{wrap}_{(-\\pi,\\pi]}(\\psi_i - \\psi),\\qquad e_{ct}^{RMS} = \\sqrt{\\tfrac1K\\textstyle\\sum_k e_{ct,k}^2} \\qquad (7.7)$$"),
        h4("Tabla 7.2 — Criterios de evaluación"), tabla_simple(tabla_criterios)
      ),
      caja("7.5 Estimación de la pose (Algoritmo 6)", ancho = 6, estado = "success",
        ecuacion("$$\\tilde\\psi_k = \\psi_k - 2\\pi\\,\\operatorname{round}\\left(\\frac{\\psi_k - \\hat\\psi_{k-1}}{2\\pi}\\right) \\qquad (7.8)$$"),
        ecuacion("$$\\lVert z_k - \\hat p_{k-1}\\rVert > \\Delta p_{max} = v_{max}\\Delta t,\\qquad |\\tilde\\psi_k - \\hat\\psi_{k-1}| > \\Delta\\psi_{max} = \\omega_{max}\\Delta t \\qquad (7.9)$$"),
        fluidRow(column(4, numericInput("c7_vmax", "v (cm/s)", 14, 1, 50, 0.5)),
                 column(4, numericInput("c7_vuelta", "Vuelta en (s)", 7, 1, 30, 0.5)),
                 column(4, numericInput("c7_dt", "Δt (s)", 0.2, 0.01, 1, 0.01))),
        uiOutput("c7_gate_res"),
        p(class = "nota", "Tres filtros escalares (x, z, ψ). Se forzó el rastreo solo de controles: el rastreo de manos hacía saltar el gemelo.")
      )
    ),
    fluidRow(
      caja("7.6 Pruebas del sistema integrado — Tabla 7.3", ancho = 7, estado = "primary",
        tabla_dt(tabla_pruebas_sistema, paginas = 10) %>%
          DT::formatStyle("Resultado", color = DT::styleEqual(c("Falló, corregida"), c("#C0392B"), default = "#1B6B47"), fontWeight = "bold")),
      caja("7.7 Campaña cuantitativa — Tabla 7.4", ancho = 5, estado = "warning",
        tabla_simple(tabla_campana),
        concepto(p("Resultados medidos (Tabla 6.9): vuelta completa al M25 suavizado con 0 a 7 cm, dentro del criterio de 8 cm; en la
                 segunda corrida el máximo de 18.3 cm en una esquina cerrada se corrigió a 0.3 cm en 18 s. Ambos confirman las hipótesis:
                 la desviación promedio se mantiene bajo 8 cm en curvatura moderada, y el error crece con la curvatura.")))
    ),
    fluidRow(
      caja("7.8 Lecciones aprendidas — Tabla 7.5", ancho = 7, estado = "success", tabla_simple(tabla_lecciones),
        p(class = "nota", "Congelar versiones que funcionan; una sola fuente de verdad para dimensiones y rangos; medir antes de afinar; el
          gemelo digital es tan bueno como su calibración.")),
      caja("7.9 Limitaciones", ancho = 5, estado = "danger",
        tags$ol(class = "description-text",
          tags$li("La validación de extremo a extremo es mayormente cualitativa; faltan mediciones de latencia y consumo."),
          tags$li("Seguimiento geométrico sin retroalimentación de velocidad: los codificadores de 2008 no están integrados."),
          tags$li("La pose depende del rastreo del visor, sensible a oclusiones; la compuerta puede rechazar movimientos legítimos."),
          tags$li("El software aún usa ℓ = 0.34 m y b = 0.30 m en lugar de 0.333 y 0.29 m; ks sin medir."),
          tags$li("El nodo de sensores del PIC y la seguridad ampliada están diseñados pero no implementados.")))
    )
  )
}

# -----------------------------------------------------------------------------
ui_lab <- function() {
  tabItem(tabName = "lab",
    fluidRow(
      caja("Laboratorio de seguimiento: del dibujo a la trama ALL", estado = "warning",
        parrafo("Reproduce la cadena de los modos 2 y 5: (1) elegir o dibujar la trayectoria roja, (2) suavizarla con ARC o SPLINE,
                 (3) colocar puntos de paso cada 20 cm, (4) generar las tramas con el Algoritmo 5 y (5) simular el seguimiento con el
                 estimador de pose (compuerta y Kalman) y la ley de control elegida, a 5 Hz."),
        aviso_sim()
      )
    ),
    fluidRow(
      caja("1–3. Trayectoria", ancho = 4, estado = "primary",
        selectInput("lab_tipo", "Trayectoria roja", c("Anillo M25 (modo 5)" = "m25", "Dibujada con clics (modo 2)" = "dibujo",
                                                       "Recta de 2 m (C4)" = "recta", "Arco de 1 m de radio (C4)" = "arco",
                                                       "“S” (C4)" = "ese", "Ocho (C4)" = "ocho")),
        conditionalPanel("input.lab_tipo == 'm25'", sliderInput("lab_S", "Escala del mapa (%)", 100, 150, 110, 5)),
        conditionalPanel("input.lab_tipo == 'dibujo'",
          p(class = "nota", "Haga clic sobre la rejilla de 10 cm (2.1 × 2.1 m) para agregar puntos."),
          fluidRow(column(6, actionButton("lab_borrar_ult", "Borrar último", icon = icon("rotate-left"))),
                   column(6, actionButton("lab_limpiar", "Limpiar", icon = icon("trash"))))),
        radioButtons("lab_metodo", "Suavizado", c("SPLINE (smooth)" = "spline", "ARC (loop-safe)" = "arc"), inline = TRUE),
        sliderInput("lab_R", "Radio de giro R (cm)", 5, 75, 45, 1),
        sliderInput("lab_lambda", "Factor diferencial λ", 0.25, 0.75, 0.25, 0.25),
        uiOutput("lab_tray_res")
      ),
      caja("Plano del piso", ancho = 8, estado = "info", plotlyOutput("lab_plano", height = "520px"))
    ),
    fluidRow(
      caja("4. Generador de comandos (Algoritmo 5)", ancho = 12, estado = "success",
        fluidRow(column(7, plotlyOutput("lab_gen_plot", height = "300px")),
                 column(5, DTOutput("lab_gen_tabla"), downloadButton("lab_gen_csv", "Descargar tramas (CSV)")))
      )
    ),
    fluidRow(
      caja("5. Simulación del seguimiento", ancho = 4, estado = "danger",
        radioButtons("lab_ley", "Ley de control", c("Modo 5: rumbo + Stanley (ec. 7.6)" = "modo5",
                                                    "Persecución pura (ec. 2.22)" = "pp",
                                                    "Algoritmo 5: solo curvatura" = "alg5")),
        conditionalPanel("input.lab_ley == 'pp'", sliderInput("lab_dla", "d_la (m)", 0.15, 0.8, 0.35, 0.05)),
        sliderInput("lab_v85", "Velocidad real al 85 % (m/s)", 0.08, 0.25, 0.14, 0.01),
        sliderInput("lab_ksr", "ks real del varillaje (calibración C1)", 1.0, 2.2, 50 / 30, 0.05),
        sliderInput("lab_ruido", "Ruido de la pose σ (cm)", 0, 3, 0.4, 0.1),
        sliderInput("lab_perd", "Pérdidas de rastreo (salto de 42 cm)", 0, 3, 0, 1),
        checkboxInput("lab_gate", "Compuerta física (2.8 cm / 10.3°)", TRUE),
        fluidRow(column(6, numericInput("lab_sqp", "σq² pos.", 0.01, 0.0001, 1, 0.001)),
                 column(6, numericInput("lab_srp", "σr² pos.", 0.10, 0.0001, 5, 0.01))),
        sliderInput("lab_semilla", "Semilla aleatoria", 1, 50, 1, 1),
        actionButton("lab_sim", "Simular", class = "btn-warning", icon = icon("play"), width = "100%")
      ),
      caja("Resultado", ancho = 8, estado = "primary",
        uiOutput("lab_sim_res"),
        tabsetPanel(
          tabPanel("Trayectoria", plotlyOutput("lab_sim_plano", height = "430px")),
          tabPanel("Errores", plotlyOutput("lab_sim_err", height = "430px")),
          tabPanel("Estimador", plotlyOutput("lab_sim_est", height = "430px")),
          tabPanel("Mandos", plotlyOutput("lab_sim_mandos", height = "430px"))),
        downloadButton("lab_csv", "Descargar CSV de seguimiento (formato de la Tabla 6.10)"),
        actionButton("lab_a_analisis", "Enviar al módulo de análisis", icon = icon("chart-line"))
      )
    )
  )
}

# -----------------------------------------------------------------------------
ui_analisis <- function() {
  tabItem(tabName = "analisis",
    fluidRow(
      caja("Módulo de análisis de pruebas en R (sección 6.6.1)", estado = "warning",
        parrafo("La tesis propone un módulo de R Shiny que lea los CSV de seguimiento y produzca, por corrida, cuatro salidas: la trayectoria
                 planeada superpuesta a la ejecutada sobre la rejilla del piso; el histograma y el valor cuadrático medio del error
                 transversal; la gráfica del error contra la curvatura local, cuya inclinación revelaría un error sistemático de la
                 constante ks; y la clasificación según la Tabla 7.2."),
        fluidRow(
          column(4, fileInput("an_archivo", "CSV de seguimiento", accept = c(".csv", "text/csv"), buttonLabel = "Examinar…",
                              placeholder = "Ningún archivo")),
          column(4, radioButtons("an_fuente", "Fuente", c("Corrida enviada desde el Laboratorio" = "lab", "Archivo cargado" = "archivo",
                                                         "Ejemplo incluido (simulado)" = "ejemplo"), selected = "ejemplo")),
          column(4, p(class = "nota", "Columnas requeridas: t, i, xi, zi, x_hat, z_hat, ect, kappa. Opcionales: ep, epsi, delta, theta_s,
                      u1, u2, Vbat, T. Las distancias en metros."),
                    downloadButton("an_plantilla", "Descargar ejemplo")))
      )
    ),
    uiOutput("an_resumen"),
    fluidRow(
      caja("1. Planeada contra ejecutada", ancho = 6, estado = "primary", plotlyOutput("an_plano", height = "400px")),
      caja("2. Error transversal", ancho = 6, estado = "info", plotlyOutput("an_hist", height = "400px"))
    ),
    fluidRow(
      caja("3. Error contra curvatura local", ancho = 6, estado = "success", plotlyOutput("an_curv", height = "380px"), uiOutput("an_curv_res")),
      caja("4. Clasificación (Tabla 7.2) y batería", ancho = 6, estado = "danger", DTOutput("an_clas"), plotlyOutput("an_bat", height = "250px"))
    )
  )
}

# -----------------------------------------------------------------------------
server_cap7_lab <- function(input, output, session, geo, ejemplo_csv) {
  # ---- prueba de signo
  output$c7_signo <- renderUI({
    xw <- input$c7_lat; zw <- -1                       # vehículo en el origen mirando al norte (−z)
    psi_real <- pi                                     # rumbo verdadero en el marco del objetivo
    psi_q <- psi_real - pi - rad(input$c7_phim)        # guiñada que entrega el control
    psi_v <- if (input$c7_conv == "ok") psi_q + pi + rad(input$c7_phim) else psi_q
    psi_obj <- atan2(xw - 0, zw - 0)
    e <- wrap_pi(psi_obj - psi_v); delta <- clamp(e, rad(-30), rad(30)); th <- clamp(90 + 50 / 30 * deg(delta), 40, 140)
    f <- abs(deg(delta)) / 30; m1 <- if (delta > 0) 85 - 35 * f else 85 + 15 * f; m2 <- if (delta > 0) 85 + 15 * f else 85 - 35 * f
    esperado_izq <- xw > 0
    ok <- (delta > 0) == esperado_izq && abs(deg(e)) < 29
    resultado(celda(paste0(fmt(deg(e), 1), "°"), "Error de rumbo calculado", if (abs(deg(e)) >= 29) "mal" else "ok"),
              celda(paste0(fmt(deg(delta), 1), "°"), "δ (positivo = izquierda)"),
              celda(paste0(round(th), "°"), "S2"),
              celda(paste0("M1 ", round(m1), " % · M2 ", round(m2), " %"), "Diferencial"),
              celda(if (ok) "Prueba aprobada" else "Prueba fallida", "Sentido y proporcionalidad", if (ok) "ok" else "mal"))
  })
  output$c7_gate_res <- renderUI({
    dp <- input$c7_vmax / 100 * input$c7_dt; w <- 360 / input$c7_vuelta; dpsi <- w * input$c7_dt
    resultado(celda(paste(fmt(dp * 100, 2), "cm"), "Δp<sub>max</sub> por muestra"), celda(paste0(fmt(w, 1), "°/s"), "ω<sub>max</sub>"),
              celda(paste0(fmt(dpsi, 1), "°"), "Δψ<sub>max</sub> por muestra"))
  })

  # ---- laboratorio
  puntos <- reactiveVal(matrix(c(0, 0, 0, -0.6, 0.4, -0.9), ncol = 2, byrow = TRUE, dimnames = list(NULL, c("x", "z"))))
  observeEvent(event_data("plotly_click", source = "lienzo"), {
    e <- event_data("plotly_click", source = "lienzo")
    if (input$lab_tipo == "dibujo" && !is.null(e$x)) puntos(rbind(puntos(), c(x = e$x, z = -e$y)))
  })
  observeEvent(input$lab_borrar_ult, { p <- puntos(); if (nrow(p) > 0) puntos(p[-nrow(p), , drop = FALSE]) })
  observeEvent(input$lab_limpiar, puntos(matrix(numeric(0), ncol = 2, dimnames = list(NULL, c("x", "z")))))
  roja <- reactive({
    if (input$lab_tipo == "m25") anillo_m25(geo, input$lab_S / 100)
    else if (input$lab_tipo == "dibujo") { p <- puntos(); if (nrow(p) >= 2) remuestrear(p, 0.05) else p }
    else trayectoria_predefinida(input$lab_tipo)
  })
  verde <- reactive({
    r <- roja(); req(nrow(r) >= 2); R <- input$lab_R / 100
    if (input$lab_metodo == "spline") suavizar_spline(r, R) else suavizar_arc(r, R)
  })
  wps <- reactive({ req(nrow(verde()) >= 2); puntos_de_paso(verde()) })
  gen <- reactive({ W <- wps(); req(nrow(W) >= 3); generador_ackermann(W, input$lab_lambda) })
  output$lab_tray_res <- renderUI({
    W <- wps(); L <- max(longitudes(verde()))
    resultado(celda(paste(fmt(L, 2), "m"), "Longitud verde"), celda(nrow(W), "Puntos de paso"),
              celda(paste(fmt(L / 0.14, 0), "s"), "Duración a 14 cm/s", if (L / 0.14 > 120) "warn" else ""))
  })
  output$lab_plano <- renderPlotly({
    r <- roja(); p <- plot_ly(source = "lienzo")
    if (input$lab_tipo == "dibujo") {
      g <- expand.grid(x = seq(-1.05, 1.05, by = 0.05), y = seq(-1.05, 1.05, by = 0.05))
      p <- p %>% add_markers(data = g, x = ~x, y = ~y, marker = list(color = "rgba(29,78,137,0.06)", size = 9), hoverinfo = "x+y",
                             name = "Rejilla (clic para agregar)", showlegend = FALSE)
    }
    if (nrow(r) >= 1) p <- p %>% add_trace(x = r[, 1], y = -r[, 2], type = "scatter", mode = if (nrow(r) > 1) "lines" else "markers",
                                           line = list(color = COL$ideal, width = 2.5), marker = list(color = COL$ideal), name = "Trayectoria ideal (roja)")
    if (input$lab_tipo == "dibujo" && nrow(puntos()) > 0)
      p <- p %>% add_markers(x = puntos()[, 1], y = -puntos()[, 2], marker = list(color = COL$ideal, size = 8), name = "Puntos dibujados")
    if (nrow(r) >= 2) {
      v <- verde(); W <- wps()
      p <- p %>% add_paths(x = v[, 1], y = -v[, 2], line = list(color = COL$suave, width = 3.5), name = "Suavizada (verde)") %>%
        add_markers(x = W$x, y = -W$z, marker = list(color = "#fff", size = 6, line = list(color = COL$suave, width = 2)), name = "Puntos de paso") %>%
        add_markers(x = W$x[1], y = -W$z[1], marker = list(color = "#D63AF9", size = 14, symbol = "triangle-up"), name = "Inicio")
    }
    rng <- if (input$lab_tipo == "dibujo") c(-1.1, 1.1) else NULL
    p %>% tema(NULL, NULL) %>% plano_piso(rng, rng) %>% layout(dragmode = if (input$lab_tipo == "dibujo") FALSE else "zoom") %>%
      event_register("plotly_click")
  })
  output$lab_gen_plot <- renderPlotly({
    g <- gen(); req(g)
    plot_ly(g, x = ~s) %>% add_lines(y = ~delta, name = "δ (°)", line = list(color = COL$azul, width = 2.5)) %>%
      add_lines(y = ~theta - 90, name = "θs − 90 (°)", line = list(color = COL$ambar, dash = "dash")) %>%
      add_lines(y = ~kappa_sat * 10, name = "κsat × 10 (m⁻¹)", line = list(color = COL$verde)) %>%
      add_lines(y = ~u1 - u2, name = "M1 − M2 (%)", line = list(color = COL$violeta, dash = "dot")) %>%
      tema("Distancia recorrida s (m)", NULL)
  })
  output$lab_gen_tabla <- renderDT({
    g <- gen(); req(g)
    tabla_dt(data.frame(i = g$i, `κ (m⁻¹)` = round(g$kappa, 2), `δ (°)` = round(g$delta, 1), Trama = g$trama, check.names = FALSE),
             paginas = 7, botones = FALSE, buscar = FALSE)
  })
  output$lab_gen_csv <- downloadHandler("tramas_generador.csv", function(f) write.csv(gen(), f, row.names = FALSE))

  sim <- eventReactive(input$lab_sim, {
    W <- wps(); req(nrow(W) >= 3)
    cfg <- list(offset = 0.05, semilla = input$lab_semilla, perdidas = input$lab_perd, tmax = 120, dur_perdida = 2, salto = 0.42,
                ruido_pos = input$lab_ruido / 100, ruido_rumbo = 1, compuerta = input$lab_gate, dp_max = 0.028, dpsi_max = 10.3,
                t_confirma = 1, sq_pos = input$lab_sqp, sr_pos = input$lab_srp, sq_psi = 0.01, sr_psi = 0.5, r_acept = 0.15,
                ley = input$lab_ley, ks_ctrl = 50 / 30, ks_real = input$lab_ksr, lambda = input$lab_lambda, v85 = input$lab_v85,
                part_dif = 0.3, d_la = if (is.null(input$lab_dla)) 0.35 else input$lab_dla)
    withProgress(message = "Simulando a 72 Hz…", value = 0.5, {
      s <- simular_seguimiento(W, verde(), cfg)
    })
    s$W <- W; s$verde <- verde(); s
  })
  output$lab_sim_res <- renderUI({
    s <- sim(); l <- s$log; req(nrow(l) > 0)
    m <- mean(l$desv_real) * 100
    resultado(celda(s$fin, "Fin de la corrida", if (startsWith(s$fin, "Vuelta")) "ok" else "mal"),
              celda(paste0(s$i_final, "/", s$n_wp - 1), "Último punto de paso"),
              celda(paste(fmt(m, 1), "cm"), "Desviación promedio (real)", if (m < 8) "ok" else if (m <= 15) "warn" else "mal"),
              celda(paste(fmt(max(l$desv_real) * 100, 1), "cm"), "Desviación máxima"),
              celda(paste(fmt(sqrt(mean(l$ect^2)) * 100, 1), "cm"), "e<sub>ct</sub><sup>RMS</sup> (reportado)"),
              celda(nrow(l), "Tramas a 5 Hz"),
              celda(clasificar_desviacion(m), "Clasificación (Tabla 7.2)", if (m < 8) "ok" else if (m <= 15) "warn" else "mal"))
  })
  output$lab_sim_plano <- renderPlotly({
    s <- sim(); tr <- s$traza; tr <- tr[seq(1, nrow(tr), by = 3), ]
    plot_ly() %>% add_paths(x = s$verde[, 1], y = -s$verde[, 2], line = list(color = COL$suave, width = 4), name = "Trayectoria verde") %>%
      add_markers(x = tr$mx, y = -tr$mz, marker = list(color = "rgba(242,140,40,.35)", size = 3), name = "Pose medida (control)") %>%
      add_paths(x = tr$fx, y = -tr$fz, line = list(color = COL$azul, width = 2), name = "Pose estimada") %>%
      add_paths(x = tr$x, y = -tr$z, line = list(color = COL$registro, width = 2.5, dash = "dot"), name = "Pose real (simulada)") %>%
      tema(NULL, NULL) %>% plano_piso()
  })
  output$lab_sim_err <- renderPlotly({
    l <- sim()$log
    plot_ly(l, x = ~t) %>% add_lines(y = ~desv_real * 100, name = "Desviación real (cm)", line = list(color = COL$rojo, width = 2.5)) %>%
      add_lines(y = ~ect * 100, name = "e_ct reportado (cm)", line = list(color = COL$azul)) %>%
      add_lines(y = ~deg(epsi), name = "e_ψ (°)", line = list(color = COL$gris, dash = "dot")) %>%
      add_lines(x = range(l$t), y = c(8, 8), name = "8 cm", line = list(color = COL$ambar, dash = "dash")) %>% tema("Tiempo (s)", NULL)
  })
  output$lab_sim_est <- renderPlotly({
    tr <- sim()$traza
    plot_ly(tr, x = ~t) %>% add_markers(y = ~mx * 100, name = "x medida", marker = list(color = "rgba(93,109,126,.35)", size = 3)) %>%
      add_lines(y = ~fx * 100, name = "x estimada", line = list(color = COL$azul, width = 2)) %>%
      add_lines(y = ~x * 100, name = "x real", line = list(color = COL$rojo, dash = "dash")) %>%
      add_markers(data = tr[tr$rechazo == 1, ], y = ~mx * 100, name = "Rechazada por la compuerta", marker = list(color = COL$ambar, size = 6, symbol = "x")) %>%
      tema("Tiempo (s)", "x (cm)")
  })
  output$lab_sim_mandos <- renderPlotly({
    l <- sim()$log
    plot_ly(l, x = ~t) %>% add_lines(y = ~theta_s, name = "S2 (°)", line = list(color = COL$azul, width = 2.5, shape = "hv")) %>%
      add_lines(y = ~u1, name = "M1 izquierdo (%)", line = list(color = COL$ambar, shape = "hv")) %>%
      add_lines(y = ~u2, name = "M2 derecho (%)", line = list(color = COL$verde, shape = "hv")) %>% tema("Tiempo (s)", NULL)
  })
  csv_sim <- reactive({ l <- sim()$log; l[, c("t", "i", "xi", "zi", "x_hat", "z_hat", "psi_hat", "ep", "ect", "epsi", "kappa", "delta",
                                              "theta_s", "u1", "u2", "Vbat", "T")] })
  output$lab_csv <- downloadHandler(function() paste0("seguimiento_simulado_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
                                    function(f) write.csv(csv_sim(), f, row.names = FALSE))
  datos_lab <- reactiveVal(NULL)
  observeEvent(input$lab_a_analisis, {
    datos_lab(list(log = csv_sim(), verde = sim()$verde))
    updateRadioButtons(session, "an_fuente", selected = "lab")
    updateTabItems(session, "menu", "analisis")
  })

  # ---- análisis en R
  datos_an <- reactive({
    if (input$an_fuente == "lab") { validate(need(!is.null(datos_lab()), "Ejecute una simulación en el Laboratorio y pulse «Enviar al módulo de análisis».")); return(datos_lab()) }
    if (input$an_fuente == "archivo") {
      validate(need(!is.null(input$an_archivo), "Cargue un CSV de seguimiento."))
      d <- tryCatch(read.csv(input$an_archivo$datapath), error = function(e) NULL)
      validate(need(!is.null(d), "No se pudo leer el archivo."))
      faltan <- setdiff(c("t", "i", "xi", "zi", "x_hat", "z_hat", "ect", "kappa"), names(d))
      validate(need(length(faltan) == 0, paste("Faltan columnas:", paste(faltan, collapse = ", "))))
      return(list(log = d, verde = NULL))
    }
    list(log = ejemplo_csv, verde = NULL)
  })
  output$an_resumen <- renderUI({
    d <- datos_an()$log; e <- abs(d$ect) * 100; m <- mean(e)
    fluidRow(column(12, div(class = "kpis",
      kpi(nrow(d), "Muestras (tramas a 5 Hz)", "list"),
      kpi(paste(fmt(m, 1), "cm"), "Error transversal promedio |e_ct|", "ruler-horizontal", "c2"),
      kpi(paste(fmt(sqrt(mean((d$ect * 100)^2)), 1), "cm"), "e_ct RMS", "square-root-variable", "c3"),
      kpi(paste(fmt(max(e), 1), "cm"), "Máximo", "arrow-up", "c6"),
      kpi(clasificar_desviacion(m), "Clasificación (Tabla 7.2)", "clipboard-check", if (m < 8) "c4" else "c6"))))
  })
  output$an_plano <- renderPlotly({
    x <- datos_an(); d <- x$log
    p <- plot_ly()
    if (!is.null(x$verde)) p <- p %>% add_paths(x = x$verde[, 1], y = -x$verde[, 2], line = list(color = COL$suave, width = 4), name = "Planeada (verde)")
    else p <- p %>% add_paths(x = d$xi, y = -d$zi, line = list(color = COL$suave, width = 4), name = "Puntos objetivo")
    p %>% add_trace(x = d$x_hat, y = -d$z_hat, type = "scatter", mode = "lines+markers", line = list(color = COL$registro),
                    marker = list(color = abs(d$ect) * 100, colorscale = "YlOrRd", size = 6, showscale = TRUE, colorbar = list(title = "|e_ct| cm")),
                    name = "Ejecutada (pose estimada)") %>%
      tema(NULL, NULL) %>% plano_piso()
  })
  output$an_hist <- renderPlotly({
    d <- datos_an()$log; e <- d$ect * 100
    plot_ly(x = e, type = "histogram", nbinsx = 30, marker = list(color = COL$azul2, line = list(color = "#fff", width = 1)), name = "e_ct") %>%
      tema("Error transversal con signo (cm), positivo a la izquierda", "Frecuencia", leyenda = FALSE) %>%
      layout(shapes = list(list(type = "line", x0 = -8, x1 = -8, yref = "paper", y0 = 0, y1 = 1, line = list(color = COL$ambar, dash = "dash")),
                           list(type = "line", x0 = 8, x1 = 8, yref = "paper", y0 = 0, y1 = 1, line = list(color = COL$ambar, dash = "dash"))),
             annotations = list(list(x = 0.98, y = 0.97, xref = "paper", yref = "paper", xanchor = "right", showarrow = FALSE,
                                     text = paste0("RMS = ", fmt(sqrt(mean(e^2)), 2), " cm<br>media = ", fmt(mean(e), 2), " cm"))))
  })
  ajuste <- reactive({ d <- datos_an()$log; d <- d[is.finite(d$kappa) & is.finite(d$ect), ]; list(d = d, m = lm(I(ect * 100) ~ kappa, data = d)) })
  output$an_curv <- renderPlotly({
    a <- ajuste(); d <- a$d; k <- range(d$kappa)
    plot_ly() %>% add_markers(x = d$kappa, y = d$ect * 100, marker = list(color = COL$azul, size = 6, opacity = .6), name = "Muestras") %>%
      add_lines(x = k, y = predict(a$m, data.frame(kappa = k)), line = list(color = COL$rojo, width = 3), name = "Ajuste lineal") %>%
      tema("Curvatura local κ (m⁻¹), positiva a la izquierda", "e_ct (cm)")
  })
  output$an_curv_res <- renderUI({
    a <- ajuste(); s <- summary(a$m)$coefficients
    pend <- s[2, 1]; pval <- s[2, 4]
    tagList(resultado(celda(paste(fmt(pend, 2), "cm·m"), "Pendiente e_ct contra κ"), celda(format.pval(pval, digits = 2), "Valor p"),
                      celda(if (pval < 0.05) "Sesgo con la curvatura" else "Sin sesgo significativo", "Interpretación", if (pval < 0.05) "warn" else "ok")),
            p(class = "nota", "Una pendiente significativa indica que el vehículo se abre o se cierra sistemáticamente en las curvas: revisar
              ks (calibración C1) y la distancia entre ejes del software."))
  })
  output$an_clas <- renderDT({
    d <- datos_an()$log; e <- abs(d$ect) * 100
    seg <- cut(seq_len(nrow(d)), breaks = min(5, nrow(d)), labels = paste("Tramo", seq_len(min(5, nrow(d)))))
    t <- do.call(rbind, lapply(split(e, seg), function(v) data.frame(`Media (cm)` = round(mean(v), 2), `Máx. (cm)` = round(max(v), 2),
                                                                      `Clasificación` = clasificar_desviacion(mean(v)), check.names = FALSE)))
    t <- rbind(t, data.frame(`Media (cm)` = round(mean(e), 2), `Máx. (cm)` = round(max(e), 2), `Clasificación` = clasificar_desviacion(mean(e)), check.names = FALSE))
    t <- cbind(Segmento = c(levels(seg), "Corrida completa"), t, `Recomendación` = sapply(c(sapply(split(e, seg), mean), mean(e)), recomendacion_desviacion))
    tabla_simple(t)
  })
  output$an_bat <- renderPlotly({
    d <- datos_an()$log
    validate(need(all(c("Vbat") %in% names(d)), "El archivo no incluye Vbat."))
    plot_ly(d, x = ~t) %>% add_lines(y = ~abs(ect) * 100, name = "|e_ct| (cm)", line = list(color = COL$azul)) %>%
      add_lines(y = ~Vbat, name = "Vbat (V)", yaxis = "y2", line = list(color = COL$ambar)) %>%
      tema("Tiempo (s)", "|e_ct| (cm)") %>% layout(yaxis2 = list(overlaying = "y", side = "right", title = "Vbat (V)"), margin = list(r = 60))
  })
  output$an_plantilla <- downloadHandler("ejemplo_seguimiento_simulado.csv", function(f) write.csv(ejemplo_csv, f, row.names = FALSE))
}
