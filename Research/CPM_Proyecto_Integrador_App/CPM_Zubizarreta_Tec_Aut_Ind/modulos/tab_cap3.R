# =============================================================================
# Capítulo 3 — Arquitectura del sistema y diseño mecánico
# =============================================================================

ui_cap3 <- function() {
  tabItem(tabName = "cap3",
    fluidRow(
      caja("Capítulo 3: Arquitectura del sistema y diseño mecánico — Panorama",
        concepto(parrafo("Este capítulo presenta la arquitectura del sistema completo antes de entrar al detalle de cada etapa
                 electrónica: los requisitos, la jerarquía de tiempo real en cuatro capas, los componentes de hardware, la ruta de
                 aprendizaje y la distribución de energía. Las últimas secciones tratan el diseño mecánico del vehículo, heredado del
                 rediseño de 2008, los soportes impresos en 3D y su representación tridimensional, que es la base del gemelo digital."))
      )
    ),
    fluidRow(
      caja("3.1 Requisitos del sistema — Tabla 3.1", ancho = 7, estado = "info", tabla_simple(tabla_requisitos)),
      caja("3.2 Reparto por nivel de tiempo — Tabla 3.2", ancho = 5, estado = "warning",
        tabla_simple(tabla_niveles_tiempo),
        concepto(titulo = "¿Por qué dos microcontroladores?", tags$ol(
          tags$li(strong("Separación de funciones:"), " el Arduino solo mueve y el PIC solo mide."),
          tags$li(strong("Seguridad redundante:"), " el paro entra al PIC por interrupción y puede cortar la potencia con un relevador
                  aunque el Arduino o la Jetson se bloqueen."),
          tags$li(strong("Aprovechar lo aprendido:"), " los periféricos de la BK300 ya se probaron en la Etapa 1."),
          tags$li(strong("Camino de migración:"), " si las funciones se concentran en una sola tarjeta, el protocolo ya está definido.")))
      )
    ),
    fluidRow(
      caja("3.4 Diagrama integral de componentes e interconexiones — Figura 3.2", ancho = 7,
        figura("img/fig3_2_diagrama.png", "<b>Figura 3.2.</b> Diagrama integral del sistema: software del visor y de la Jetson, modo
               simulado en tableta, Arduino Mega (con el Nano como predecesor), puente H MD22, nodo PIC (con el controlador integral
               del circuito 5 como predecesor), sensores, actuadores y potencia, con el tipo de cada enlace.")
      ),
      caja("Lectura del diagrama, de arriba hacia abajo", ancho = 5, estado = "info",
        tags$ul(class = "description-text",
          tags$li(strong("Meta Quest 3S."), " La aplicación WebXR de ocho modos dibuja el mapa y el gemelo digital, recibe las órdenes
                  del control derecho y usa el control izquierdo, montado en el vehículo, como sensor de pose; en cada cuadro (72 a
                  90 Hz) lee esa pose, la filtra con Kalman y, cada 200 ms, calcula la dirección y las velocidades."),
          tags$li(strong("Red local."), " HTTPS en el puerto 8443 y canal de control WSS en el 8444, por el que viajan las tramas
                  TRACK, MODE2_TRACK y MODE5_TRACK a 5 Hz."),
          tags$li(strong("Jetson Nano."), " El servidor de control recibe un mensaje de seguimiento cada 200 ms, arma la trama ALL y la
                  escribe por el puerto con nombre fijo; procesa cada mensaje en menos de 1 ms."),
          tags$li(strong("Arduino Mega 2560."), " Interpreta las tramas a 115 200 baudios, mueve los servos S1 y S2 con PWM y escribe las
                  velocidades al MD22 por I²C."),
          tags$li(strong("PIC16F877A."), " Mide batería, temperatura y codificador, atiende el paro y el relevador K1, y reporta por
                  RS232 a 9600 baudios."),
          tags$li(strong("Capa física."), " El MD22 entrega la potencia de la batería, a través del fusible y del relevador, a los
                  motorreductores M1 y M2; los servos se alimentan del convertidor de 6 V y la Jetson de su fuente de 5 V.")),
        h4("Tabla 3.3 — Componentes de hardware"), tabla_dt(tabla_hardware, paginas = 5)
      )
    ),
    fluidRow(
      caja("3.5 Ruta de aprendizaje y cronología — Tablas 3.4 y 3.5", ancho = 12, estado = "success",
        parrafo("El orden de los capítulos sigue la ruta de aprendizaje de la carrera (PIC, sensores y actuadores, Arduino, Jetson). Las
                 fechas del historial de sesiones no siempre coinciden con ese orden, porque varias líneas avanzaron en paralelo: las
                 primeras pruebas con Arduino Nano y el MD22 están registradas en enero de 2026 y el análisis detallado de las prácticas
                 de la placa BK300 en marzo."),
        fluidRow(column(6, plotlyOutput("c3_gantt", height = "300px")), column(6, tabla_simple(tabla_etapas))),
        h4("Motivación y aprendizaje de cada transición"), tabla_simple(tabla_transiciones)
      )
    ),
    fluidRow(
      caja("3.6 Distribución de energía y presupuesto de corriente", ancho = 12, estado = "warning",
        fluidRow(
          column(5,
            parrafo("Una sola batería de 12 V alimenta la tracción directamente y, a través de dos convertidores conmutados, los servos
                     y la Jetson. El Arduino recibe su alimentación lógica por el USB de la Jetson, y la placa BK300 desde el
                     convertidor de 5 V. Todas las tierras se unen en un solo punto cerca del negativo de la batería (tierra en
                     estrella), de modo que la corriente de los motores no circula por los cables de señal."),
            ecuacion("$$I_{bat} \\approx I_{mot} + \\frac{P_{servos}+P_{Jetson}+P_{lógica}}{0.9\\,V_{bat}} \\approx 0.36 + \\frac{1.8+8.8+1.5}{0.9\\times 12} \\approx 1.5\\,\\text{A} \\qquad (3.1)$$"),
            tabla_simple(tabla_presupuesto)
          ),
          column(7,
            concepto(titulo = "Calculadora del presupuesto (ec. 3.1)",
              fluidRow(column(3, numericInput("c3_imot", "Motores (A)", 0.36, 0, 10, 0.01)),
                       column(3, numericInput("c3_pserv", "Servos (W)", 1.8, 0, 50, 0.1)),
                       column(3, numericInput("c3_pjet", "Jetson (W)", 8.8, 0, 30, 0.1)),
                       column(3, numericInput("c3_plog", "Lógica (W)", 1.5, 0, 10, 0.1))),
              fluidRow(column(4, numericInput("c3_eta", "Eficiencia buck (%)", 90, 60, 99, 1)),
                       column(4, numericInput("c3_cap", "Batería (Ah)", 7, 1, 100, 0.5)),
                       column(4, sliderInput("c3_dod", "Descarga útil (%)", 20, 80, 50, 5))),
              uiOutput("c3_pres_res"), plotlyOutput("c3_pres_plot", height = "230px"),
              p(class = "nota", "Con los motorreductores de bajo consumo, la carga dominante no es la tracción sino la Jetson: casi tres
                cuartas partes de la corriente de la batería alimentan el cómputo."))
          )
        )
      )
    ),
    fluidRow(
      caja("3.7 Diseño mecánico del vehículo", ancho = 12, estado = "primary",
        parrafo("El vehículo es una plataforma de cuatro ruedas con dirección Ackermann (las ruedas delanteras giran mediante un solo
                 servomotor y un mecanismo trapezoidal) y tracción trasera con dos motorreductores de corriente directa gobernados de
                 forma independiente, lo que permite aplicar el diferencial electrónico. Su estructura proviene del rediseño mecánico
                 de 2008 en el Tecnológico de Monterrey, Campus Ciudad de México (Zubizarreta Rodríguez y Ayala Solares, 2008)."),
        div(class = "galeria",
          figura("img/vehiculo_frontal.jpg", "<b>Figura 3.4(a).</b> Vista frontal del vehículo actual."),
          figura("img/medidas_chasis.png", "<b>Figura 3.5.</b> Distancia entre ejes L = 33.3 cm y entre centros de llantas Lt = 29 cm. Fuente: tesis de 2008."),
          figura("img/ackermann_cero.jpg", "<b>Figura 3.6(a).</b> Mecanismo Ackermann de aluminio y latón, ángulo de giro cero. Fuente: 2008."),
          figura("img/ackermann_giro.jpg", "<b>Figura 3.6(b).</b> En un giro, la rueda interior gira más que la exterior. Fuente: 2008."),
          figura("img/servo_hs805bb.jpg", "<b>Figura 3.6(c).</b> Servomotor de alto par Hitec HS-805BB. Fuente: 2008."),
          figura("img/motorreductor.jpg", "<b>Figura 3.7(a).</b> Motorreductor Toshiba 12-14. Fuente: 2008."),
          figura("img/diferencial_electronico.jpg", "<b>Figura 3.7(b).</b> Dos motorreductores independientes: diferencial electrónico. Fuente: 2008."),
          figura("img/codificador_400.jpg", "<b>Figura 3.7(c).</b> Codificador óptico de 400 ranuras. Fuente: 2008."),
          figura("img/carcasa_boceto.jpg", "<b>Figura 3.8(a).</b> Boceto de diseño de la carcasa (alumno Pedro Romero). Fuente: 2008."),
          figura("img/carcasa_fibra.jpg", "<b>Figura 3.8(b).</b> Carcasa de fibra de vidrio terminada; primer lugar en Hiper-Entrega. Fuente: 2008.")
        )
      )
    ),
    fluidRow(
      caja("3.7.2 Tracción y cálculo del motor (2008)", ancho = 6, estado = "info",
        ecuacion("$$\\omega_T = \\frac{40}{25}\\,\\omega_m = \\frac85\\,\\omega_m,\\qquad \\tau_T = \\frac58\\,\\tau_m \\qquad (3.2)$$"),
        ecuacion("$$F_R = \\mu\\frac m2 g,\\qquad \\tau_T = F_R\\,r,\\qquad \\tau_m = \\frac85\\tau_T \\qquad (3.3)$$"),
        ecuacion("$$v_{max} = r\\,\\frac85\\,\\omega_m \\qquad (3.4)$$"),
        fluidRow(column(4, numericInput("c3_masa", "Masa (kg)", 8, 1, 30, 0.5)),
                 column(4, numericInput("c3_mu", "μ (cemento)", 1.0, 0.1, 1.5, 0.05)),
                 column(4, numericInput("c3_rueda", "r (cm)", 5.25, 1, 20, 0.05))),
        fluidRow(column(6, numericInput("c3_rpm", "rpm del motor", 22, 1, 200, 0.5)),
                 column(6, numericInput("c3_volt", "Voltaje del motor (V)", 24, 6, 24, 1))),
        uiOutput("c3_mot_res"),
        p(class = "nota", "Resultados de 2008: 7 kg, ≈ 19 cm/s a 24 V con 0.18 A por motor; desviación promedio de 4 cm en 2 m de
          línea recta; diámetro de giro más cerrado de 1.2 m. Esta es la línea base histórica de la campaña cuantitativa.")
      ),
      caja("Tablas 3.7 a 3.9 — Actuadores, cambios y parámetros físicos", ancho = 6, estado = "success",
        tabla_simple(tabla_actuadores_2008), br(),
        tabla_dt(tabla_2008_vs_actual, paginas = 6), br(),
        tabla_simple(tabla_parametros),
        p(class = "nota", "Con las medidas de 2008 se resuelve la inconsistencia entre las dos versiones del gemelo digital: los valores
          físicos son ℓ = 0.333 m y b = 0.29 m; el generador de comandos todavía usa 0.34 y 0.30 m (la diferencia en ℓ cambia δ en
          menos de 0.5°). Con el límite de 33°, ρmin = 0.333/tan 33° ≈ 0.51 m.")
      )
    ),
    fluidRow(
      caja("3.8 Fabricación aditiva de soportes con la Bambu Lab A1", ancho = 12, estado = "warning",
        fluidRow(
          column(4, figura("img/bambu_a1.jpg", "<b>Figura 3.9.</b> Bambu Lab A1 con la unidad AMS Lite de cuatro carretes. Imagen del fabricante."),
                 tabla_simple(tabla_bambu)),
          column(8,
            parrafo("Las piezas de sujeción se rediseñaron y fabricaron en PLA: el soporte de la cámara frontal, el de las pinzas
                     frontales y los de la carcasa. Cada pieza siguió un ciclo: boceto a mano → aclarar cotas (preguntas y respuestas)
                     → CAD paramétrico en Python (shapely + trimesh) → barrenos booleanos (manifold3d) → STL y revisión de la caja
                     envolvente → Bambu Studio e impresión en la A1."),
            figura("img/fig3_11_soportes.png", "<b>Figura 3.11.</b> Soportes reconstruidos a partir de sus tablas de coordenadas. Las
                   mallas son cerradas y sus volúmenes coinciden con el registro de diseño: 34.95 cm³ para la pieza A y 5.14 cm³ para la E.",
                   ancho = "88%"),
            h4("Tabla 3.11 — Soportes impresos"), tabla_dt(tabla_piezas, paginas = 6)
          )
        ),
        fluidRow(
          column(6,
            h4("Pieza F: soporte trapezoidal frontal"),
            figura("img/fig3_12_piezaF.png", "<b>Figura 3.12.</b> Pieza F generada del STL. La flecha naranja marca el recorrido del
                   mecanismo de las pinzas por la cavidad principal; arriba, la repisa en voladizo con su poste para la cámara o el
                   brazo auxiliar."),
            parrafo("Caja de perfil trapezoidal de 90 mm de ancho arriba y 76.2 mm abajo, 25.4 mm de fondo y 50.8 mm de alto, con
                     paredes de 3 mm; sus cotas son múltiplos de 12.7 mm (media pulgada). El archivo tiene 2392 triángulos, de los
                     cuales 346 tienen aristas sin pareja: se repara en Bambu Studio antes de laminar.")
          ),
          column(6,
            h4("3.8.5 Geometría triangulada del soporte torii"),
            parrafo("Un triángulo no se deforma por cortante bajo la vibración del vehículo, mientras que un marco rectangular sí."),
            ecuacion("$$\\alpha_{pata} = \\arctan\\frac{h}{\\Delta x},\\qquad L_{pata} = \\sqrt{\\Delta x^2 + h^2},\\qquad t_{real} = t\\cos(90^\\circ - \\alpha_{pata}) \\qquad (3.6)$$"),
            fluidRow(column(4, numericInput("c3_h", "Altura h (mm)", 44, 5, 200, 1)),
                     column(4, numericInput("c3_dx", "Desplazamiento Δx (mm)", 9, 0, 100, 0.5)),
                     column(4, numericInput("c3_t", "Espesor t (mm)", 14, 1, 50, 0.5))),
            uiOutput("c3_torii_res"),
            ecuacion("$$\\mathcal{A}_{costilla} = \\tfrac12\\,|(x_2-x_1)(y_3-y_1)-(x_3-x_1)(y_2-y_1)| = 337.5\\,\\text{mm}^2 \\qquad (3.7)$$",
                     "Costillas con vértices en (±45, 69), (0, 69) y (±54, 54)."),
            h4("Tabla 3.12 — Verificaciones"), tabla_simple(tabla_verif_piezas)
          )
        )
      )
    ),
    fluidRow(
      caja("3.9 Modelo tridimensional del vehículo", ancho = 12, estado = "info",
        fluidRow(
          column(6,
            parrafo("La primera representación es una malla STL binaria generada con numpy-stl 3.2.0 el 24 de febrero de 2026, con
                     10 318 triángulos (≈ 516 KB) y una escala de 200 unidades STL por 600 mm reales. En la aplicación de RA el archivo
                     va embebido en base64; la orientación se hornea con dos rotaciones, Rx(−π/2) y Ry(−π/2), para que el frente apunte
                     a −z (el norte del mapa), y la malla se traslada para que las ruedas queden en y = 0."),
            parrafo("Como el STL embebido hacía que la página pesara cerca de 712 KB, se construyó un modelo procedimental con
                     primitivas de three.js, más ligero y editable, que se exporta en formato GLB.")
          ),
          column(6, h4("Tabla 3.13 — Piezas del modelo procedimental"), tabla_simple(tabla_modelo_proc))
        )
      )
    )
  )
}

server_cap3 <- function(input, output, session) {
  output$c3_gantt <- renderPlotly({
    d <- gantt_etapas; niveles <- rev(unique(tabla_etapas$Etapa))
    d$etapa <- factor(d$etapa, levels = niveles)
    cols <- setNames(c(COL$azul, COL$cian, COL$ambar, COL$verde, COL$violeta, COL$gris), unique(tabla_etapas$Etapa))
    p <- plot_ly()
    for (i in seq_len(nrow(d))) {
      p <- p %>% add_segments(x = d$inicio[i], xend = d$fin[i], y = d$etapa[i], yend = d$etapa[i],
                              line = list(color = cols[as.character(d$etapa[i])], width = 18), showlegend = FALSE,
                              hoverinfo = "text", text = paste0(d$etapa[i], ": ", format(d$inicio[i], "%b"), "–", format(d$fin[i], "%b %Y")))
    }
    p %>% tema(NULL, NULL, leyenda = FALSE) %>% layout(margin = list(l = 180), xaxis = list(tickformat = "%b %Y"),
                                                       title = list(text = "Registro en el historial del proyecto (2026)", font = list(size = 14), x = 0.02))
  })
  pres <- reactive({
    eta <- input$c3_eta / 100
    comp <- c(Motores = input$c3_imot, Servos = input$c3_pserv / (eta * 12), Jetson = input$c3_pjet / (eta * 12),
              `Lógica` = input$c3_plog / (eta * 12))
    list(comp = comp, total = sum(comp))
  })
  output$c3_pres_res <- renderUI({
    p <- pres(); aut <- input$c3_dod / 100 * input$c3_cap / p$total
    resultado(celda(paste(fmt(p$total, 2), "A"), "Corriente desde la batería"),
              celda(paste0(fmt(p$comp["Jetson"] / p$total * 100, 0), " %"), "Fracción de la Jetson"),
              celda(paste(fmt(aut, 2), "h"), "Autonomía estimada (ec. 2.2)"))
  })
  output$c3_pres_plot <- renderPlotly({
    p <- pres()
    plot_ly(x = names(p$comp), y = p$comp, type = "bar", marker = list(color = c(COL$azul, COL$cian, COL$ambar, COL$verde)),
            text = paste(fmt(p$comp, 2), "A"), textposition = "outside", hoverinfo = "x+text") %>%
      tema(NULL, "Corriente equivalente en la batería (A)", leyenda = FALSE)
  })
  output$c3_mot_res <- renderUI({
    r <- input$c3_rueda / 100; FR <- input$c3_mu * input$c3_masa / 2 * 9.81; tT <- FR * r * 100; tm <- 8 / 5 * tT
    wm <- input$c3_rpm * 2 * pi / 60 * input$c3_volt / 24
    vmax <- r * 8 / 5 * wm
    disp <- 2 * 176.4
    resultado(celda(paste(fmt(FR, 2), "N"), "Fuerza de tracción F<sub>R</sub>"),
              celda(paste(fmt(tT, 0), "N·cm"), "Par en la rueda τ<sub>T</sub>"),
              celda(paste(fmt(tm, 0), "N·cm"), "Par requerido en los motores τ<sub>m</sub>", if (tm > disp) "mal" else "ok"),
              celda(paste(fmt(disp, 1), "N·cm"), "Par disponible (2 × 176.4)"),
              celda(paste(fmt(vmax * 100, 1), "cm/s"), "v<sub>max</sub> (proporcional al voltaje)"))
  })
  output$c3_torii_res <- renderUI({
    a <- atan2(input$c3_h, input$c3_dx); L <- sqrt(input$c3_h^2 + input$c3_dx^2); tr <- input$c3_t * cos(pi / 2 - a)
    resultado(celda(paste0(fmt(deg(a), 1), "°"), "α<sub>pata</sub>"), celda(paste(fmt(L, 1), "mm"), "L<sub>pata</sub>"),
              celda(paste(fmt(tr, 1), "mm"), "t<sub>real</sub>"))
  })
}
