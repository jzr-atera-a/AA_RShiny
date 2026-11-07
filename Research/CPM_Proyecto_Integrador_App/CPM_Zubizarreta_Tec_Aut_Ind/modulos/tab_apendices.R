# =============================================================================
# Apéndices A, C, D, E y F — Modelos 3D, programas y algoritmos
# =============================================================================

tabla_mallas <- df(
  Archivo = c("A_marco_trapezoidal.stl", "B_soporte_torii.stl", "C_mensula_servo_Z.stl", "E_mensula_trapezoidal.stl",
              "F_soporte_trapezoidal_frontal.stl"),
  `Triángulos` = c(1260, 2442, 1232, 1252, 2392),
  `Volumen (cm³)` = c("34.95", "88.98", "10.97", "5.14", "–"),
  `Masa PLA (g)` = c("43.3", "110.3", "13.6", "6.4", "–"),
  Cerrada = c("Sí", "Sí", "Sí", "Sí", "No")
)
tabla_torii <- df(
  `Polígono` = c("Base izquierda / derecha", "Pata izquierda / derecha", "Barra media", "Columnas", "Barra superior",
                 "Ventana (se resta)", "Costillas (se suman, z de −8.5 a −5.5)", "Barrenos (se restan)"),
  `Vértices` = c("(−68, 0)(−54, 0)(−54, 25)(−68, 25) / (54, 0)(68, 0)(68, 25)(54, 25)",
                 "(−68, 25)(−54, 25)(−45, 69)(−59, 69) / (54, 25)(68, 25)(59, 69)(45, 69)",
                 "(−59, 69)(59, 69)(59, 81)(−59, 81)",
                 "(−59, 81)(−45, 81)(−45, 101)(−59, 101) y (45, 81)(59, 81)(59, 101)(45, 101)",
                 "(−90, 101)(90, 101)(90, 115)(−90, 115)", "(−45, 81)(45, 81)(45, 101)(−45, 101)",
                 "(−45, 69)(0, 69)(−54, 54) y (45, 69)(0, 69)(54, 54)",
                 "5 mm en (±61, 17.5) ∥ Z; 4 mm en (0, 75) ∥ Z; 4 mm en y = 10, z = −7 ∥ X; 7 mm en x = ±69, z = −7 ∥ Y")
)
tabla_piezaF <- df(
  Rasgo = c("Caja envolvente", "Cuerpo trapezoidal", "Cavidad principal", "Repisa frontal", "Poste", "Barrenos superiores",
            "Barrenos de la base", "Malla"),
  Medida = c("X de −45 a 45; Y de −38.1 a 12.7; Z de 0 a 76.2",
             "Base ±38.1 en X, tapa ±45; fondo Y de −12.7 a 12.7; altura 50.8; placas inferior (0–3) y superior (47.8–50.8)",
             "Pasante en Y; octagonal, ancho máximo ≈ 77 a z = 25.4, de z = 3 a z ≈ 37, con base plana de x = −10.1 a 10.1 y cuatro tirantes diagonales",
             "X de −15.4 a 15.4; Y de −38.1 a −12.7; espesor 3 (de z = 47.8 a 50.8), con cartela a 45°",
             "7 × 8 (X de −3.5 a 3.5; Y de −29.4 a −21.4), punta redondeada de radio 4 hasta z = 76.2; barreno transversal ∥ X de ≈ 5",
             "Dos de 6 en (±35, 0), pasantes en la placa superior", "Dos de 10 en (±25.4, 0), separados 50.8, pasantes en la placa inferior",
             "2392 triángulos, 835 vértices tras unir duplicados; 346 triángulos con aristas libres: reparar antes de laminar")
)
tabla_funciones_F <- df(
  Bloque = c("Infraestructura", "Modo 7: flotilla", "Escena y mapas", "Gemelo digital", "Gráficas y paneles", "Modo 1: manual",
             "Modo 2: trayectoria", "Convención de dirección", "Modo 5: M25", "Modos 4 y 5 (ancla)", "Modo 3: M25 simulado",
             "Modo 6: cargadores"),
  Funciones = c("debugLog, downloadTextFile, connectWS, init, detectFloor, animate",
                "loadMode7Map, createMode7MapTexture, placeMode7Map, createMode7Markers, getColorForTruck, cleanupMode7, createMode7InfoPanel",
                "latLonToARCoords, buildScene, buildMap, buildLondonMap, createLondonMapTexture, placeLondonMap",
                "buildProceduralRobot, loadTruckModel, buildTruck, show/hideMode0Robot, show/hideMode0Truck, getCurrentVehicle, switchToVehicle",
                "build3DChart, updateChart3D, updateRobotChart, updateM25Chart, buildControlPanel, buildVehiclePanel, drawVehiclePanel, buildDifferentialPanel, drawDifferentialPanel, drawControlPanel, check…Interaction, executeMode",
                "buildMode1LeftPanel, createMode1Grid, updateMode1Path, sendMode1AnalysisToServer, startManualControl, stopManualControl, sendManualControlCommand, sendStopCommand, processJoystickInput, processGripperButtons",
                "addPoint, updateTrajectoryLine, approve, deleteLast, downsamplePath, sendTrajectory, smoothPathWithTurningRadius, generatePathCommands, startMode2Following, mode2ControlLoop, regeneratePathCommandsWithHeading, stopMode2Following, paneles, rejilla y análisis",
                "envolverPi, rumboVehiculo, anguloAServo, errorLateral",
                "buildMode5LeftPanel, checkMode5LeftPanelClick, rebuildMode5LeftPanel, startMode5Following, stopMode5Following, mode5ControlLoop",
                "startRobotTracking, stopRobotTracking, startAnchorTracking, placeAnchorAtReticle",
                "buildMode3LeftPanel, startMode3Simulation, latLonTo3D, getM25PointAtDistance, analyzeMode3Paths",
                "startChargerMode, updateChargers, createChargerMarker, showChargerInfoPanel, build3DChargerGraph, build2DChargerPanel y gráficas de batería, historial y costo"),
  `Líneas` = c("64–143, 473–614, 5619–6168", "286–472", "540–881", "882–1197", "1198–2045", "2046–2509", "2510–4153", "3065–3084",
               "4154–4421", "4423–4570", "4571–4916", "4917–5618")
)
tabla_protocolo_F <- df(
  Mensaje = c("TRACK:…", "MODE2_PATH:{json}", "MODE2_TRACK:…", "MODE5_PATH, MODE5_TRACK", "MODE2_STOP, MODE5_STOP",
              "ALL:M1:0:M2:0:S1:90:S2:90", "JSON (MODE_SELECTED, SAVE_MODE1_ANALYSIS, ROBOT_POSITION, ANCHOR_POSITION, differential_mode, cargadores)"),
  `Origen y uso` = c("Modo 1, cada 200 ms: pose y comandos del joystick", "Modo 2: puntos de paso [x, z, ψ] y factor λ",
                     "Modo 2, cada 200 ms: pose, errores y comandos", "Modo 5: igual que el modo 2",
                     "Fin, paro de emergencia o cambio de modo", "Al conectar y al detener el modo 1", "Notificaciones de los demás modos"),
  `Acción del servidor` = c("Arma y reenvía ALL", "Registra la trayectoria", "Arma y reenvía ALL", "Igual que el modo 2",
                            "Paro al Arduino", "Reenvía", "Se ignoran; el análisis se guarda en el visor")
)

intro_apendices <- list(
  C = "Programas de las Etapas 1, 2 y 4 para el PIC16F877A de la placa BK300, escritos para el compilador XC8. Los programas de los experimentos son de referencia: reproducen lo que enseña cada práctica del fabricante y deben compilarse y validarse en la tarjeta. Los pines marcados como [POR CONFIRMAR] deben tomarse del diagrama esquemático de la BK300. La sección C.1 reproduce el firmware integral del diseño de conexión de circuito 5 (Listado C.15), que habla el mismo protocolo que el Arduino Mega.",
  D = "Programas de la Etapa 3: los seis programas mínimos N1 a N6 para el Arduino Nano y, en la sección D.1, el firmware vigente de actuadores del Arduino Mega 2560 con rangos ampliados (40–140° y 0 o 40–100 %), reconstruido a partir de las versiones de abril de 2026. Su revisión mostró que no incluye el vigilante de comunicación de 500 ms, que se mantiene como recomendación (programa N5).",
  E = "Software de la Jetson: reglas udev, puente de software con capa de seguridad, procedimiento de arranque, servidor HTTPS de referencia que corrige el hallazgo de seguridad, unidad de servicio systemd, servidor de control WSS vigente (sección E.1, con los manejadores del modo 5 reconstruidos) y el servidor combinado con vehículo simulado para tableta.",
  F = "Fragmentos de la aplicación WebXR del visor en la versión de las corridas finales de abril de 2026 (trajectory_6modes_tracker0.html: 6170 líneas y 117 funciones). El lazo del modo 5 se reconstruyó a partir del reporte de las corridas ([RECONSTRUIDO]) y se marcaron las correcciones de congruencia ([CORRECCION]). Los números de línea son los del archivo original."
)

algoritmos <- list(
  "Algoritmo 1 — Lazo principal del firmware de actuadores con vigilante de comunicación" =
"Entrada: tramas de texto por el puerto serie; tiempo actual t en ms
Salida: registros del MD22 y pulsos de los servos; respuestas OK/ERR
 1  tc ← t; detenido ← falso; pararTodo()
 2  mientras verdadero hacer
 3      si hay una línea completa c entonces
 4          si c empieza con ALL: y contiene cuatro enteros (m1, m2, a1, a2) entonces
 5              escribir r(m1') y r(m2') en los registros 1 y 2 del MD22      // ecs. (4.6), (5.1)
 6              S1 ← clamp(a1, 0, 180); S2 ← clamp(a2, 40, 140); ok ← verdadero
 7          si no, si c = STOP_ALL_MOTORS o c = PING entonces
 8              ejecutar la orden; ok ← verdadero
 9          en otro caso
10              ok ← falso
11          responder OK o ERR
12          si ok entonces tc ← t; detenido ← falso
13      si no detenido y t − tc > Tw entonces
14          pararTodo()                                  // motores en 128, dirección a 90°
15          detenido ← verdadero; avisar WARN timeout",
  "Algoritmo 2 — Filtro de seguridad de la Jetson para cada comando de movimiento" =
"Entrada: comando c del visor; estado {Vbat, T, paro, tsen} actualizado por el hilo de sensores
Salida: trama reenviada al Arduino o trama de paro y aviso de bloqueo
 1  si paro entonces m ← \"paro de emergencia\"
 3  si no, si t − tsen > 1 s entonces m ← \"sin datos del nodo de sensores\"
 5  si no, si Vbat < 11.8 V entonces m ← \"batería baja\"
 7  si no, si T > 60 °C entonces m ← \"temperatura alta\"
 9  en otro caso m ← ∅
11  si c es de movimiento y m ≠ ∅ entonces
12      enviar ALL:M1:0:M2:0:S1:90:S2:90; responder al visor BLOQUEADO:m
13  en otro caso
14      reenviar c al Arduino
    // Además, al recibir $EST,PARO=1 el hilo de sensores envía el paro sin esperar al siguiente comando.",
  "Algoritmo 3 — Despachador de mensajes del servidor de control" =
"Entrada: mensajes WSS del visor
Salida: tramas al Arduino, análisis en consola y archivos CSV/TXT
 1  para cada mensaje m recibido hacer
 2      si m es un comando directo (ALL:, MOTORS, …) entonces
 3          reenviar al Arduino tras el filtro de seguridad (Alg. 2)
 4      si no, si m empieza con MODE2_PATH: entonces
 5          leer puntos de paso y factor λ; activar seguimiento con índice i ← 0
 6      si no, si m = MODE2_STOP entonces
 7          desactivar seguimiento; enviar trama de paro
 8      si no, si m es SAVE_MODE1_ANALYSIS entonces
 9          guardar el análisis en un archivo de texto
10      si no, si m es una pose y el seguimiento está activo entonces
11          calcular ep, ect, eψ respecto a pi y registrar (cap. 7)",
  "Algoritmo 4 — Suavizado de la trayectoria de referencia (modos 2 y 5)" =
"Entrada: trayectoria roja {pi}; radio R del panel; método ∈ {ARC, SPLINE}
Salida: trayectoria verde y puntos de paso cada 20 cm
 1  si método = ARC entonces
 2      conservar solo los puntos que cumplen ‖pj − pj−1‖ ≥ 2R            // ec. (6.4)
 3      unir los puntos conservados con segmentos rectos y arcos de radio R
 4  en otro caso
 5      interpolar con Catmull-Rom (6.5), 20 muestras por segmento
 6      descartar las muestras con radio local < 0.8R según (6.6); diezmar 2:1
 7  proyectar todos los puntos a la altura del piso detectado
 8  colocar puntos de paso cada 20 cm sobre la trayectoria verde; mostrarla en verde
 9  esperar el botón A para iniciar el seguimiento",
  "Algoritmo 5 — Generador de comandos Ackermann a 5 Hz" =
"Entrada: puntos de paso {pi}, i = 0…N−1; factor λ; pose medida p (opcional); Δt = 0.2 s
Salida: tramas ALL:M1:u1:M2:u2:S1:90:S2:θs y registro CSV
 1  i ← 1
 2  mientras i < N − 1 y el seguimiento está activo hacer
 3      si se recibió p y ‖p − pi‖ < racept entonces i ← i + 1
 4      κ ← sat2.0( κ(pi−1, pi, pi+1) )                          // ecs. (2.21), (7.2)
 5      δ ← arctan(ℓκ); θs ← clamp(90° + ks δ, 40°, 140°)
 6      v ← perfil de velocidad según la distancia restante, en [0.08, 0.20] m/s
 7      (vizq, vder) ← diferencial (7.4) según el signo de κ
 8      (u1, u2) ← conversión (7.5); enviar trama; registrar en CSV
 9      si no hay pose entonces i ← i + 1
10      esperar hasta completar Δt
11  enviar ALL:M1:0:M2:0:S1:90:S2:90",
  "Algoritmo 6 — Estimador de pose con compuerta física y filtros de Kalman escalares" =
"Entrada: pose del control (zk, qk) a 5 Hz; estimado previo (p̂k−1, ψ̂k−1)
Salida: pose filtrada (p̂k, ψ̂k) publicada al cliente y al servidor
 1  si la fuente es una mano y no un control entonces descartar la muestra
 2  ψk ← guiñada de qk                                              // ec. (2.27)
 3  ψ̃k ← desenvolver ψk                                             // ec. (7.8)
 4  si se cumple alguna condición de (7.9) entonces
 5      (p̂k, ψ̂k) ← (p̂k−1, ψ̂k−1)                       // mantener; esperar confirmación
 6  en otro caso
 7      actualizar los filtros de x, z y ψ con zk y ψ̃k              // ecs. (2.25), (2.26)"
)

ui_apendices <- function() {
  tabItem(tabName = "apendices",
    fluidRow(
      caja("Apéndices A, C, D, E y F — Modelos 3D, programas y algoritmos",
        concepto(parrafo("Esta sección reúne los apéndices técnicos de la tesis: los modelos 3D de los soportes impresos (A), los programas
                 del sistema PIC (C), del Arduino (D), de la Jetson (E) y de la aplicación de Realidad Aumentada (F), y los seis algoritmos
                 del documento. Los programas se identifican con dos etiquetas: histórico, cuando existió y se probó en el proyecto, y de
                 referencia, cuando se escribió para la tesis a partir de los históricos y aún debe compilarse y validarse en la tarjeta.")))
    ),
    fluidRow(
      tabBox(width = 12, id = "ap_tabs",
        tabPanel("A · Modelos 3D",
          parrafo("Las piezas A, B, C y E se reconstruyeron a partir de las tablas de coordenadas del registro de diseño con el programa
                   piezas3d.py (shapely, trimesh y manifold3d). Todas las cotas están en milímetros. El volumen de la pieza A coincide
                   exactamente con el registro (34.95 cm³) y el de la E también (5 143 mm³); el de la B difiere en 0.7 % por la
                   discretización de los barrenos. La pieza F no es una reconstrucción: su STL es el archivo de diseño del autor."),
          fluidRow(column(6, h4("Tabla A.1 — Mallas STL reconstruidas"), tabla_simple(tabla_mallas)),
                   column(6, h4("Tabla A.2 — Perfil 2D del soporte torii (XY)"), tabla_simple(tabla_torii))),
          fluidRow(
            column(6,
              h4("A.1 Pieza A: marco trapezoidal"),
              figura("img/figA1_piezaA.png", "<b>Figura A.1.</b> Pieza A reconstruida: vistas isométrica, superior y frontal."),
              p(class = "nota", "Perfil XY extruido 12 mm en Z. Contorno exterior (−50, 0), (50, 0), (22, 76), (−22, 76); abertura interior
                (−38, 12), (38, 12), (10, 64), (−10, 64); dos barrenos de 4 mm en (±36, 6) ∥ Z y uno de 7 mm en x = 0, z = 6 ∥ Y."),
              h4("A.3 Pieza C: ménsula en Z para servo"),
              figura("img/figA3_piezaC.png", "<b>Figura A.3.</b> Pieza C reconstruida: vistas isométrica, superior y frontal."),
              p(class = "nota", "Perfil YZ extruido 22.5 mm a cada lado en X (45 mm). Placa base Y −35…0, Z 0…3; pared Y −3…0, Z 3…31; ala
                de Y = −3 a Y = 15 inclinada 3° hacia abajo; costilla de 3 mm; barrenos de 4 mm en el ala y de 5 mm en la base."),
              h4("A.4 Pieza D: barra de carga reticulada"),
              p(class = "nota", "Barra de 180 × 30 × 25.4 mm sobre dos bridas de 100 × 15 mm; nueve celdas tetraédricas con barras de 4 mm;
                138.17 cm³ (171.3 g). No se reconstruyó porque su segunda iteración quedó marcada para revisión.")
            ),
            column(6,
              h4("A.2 Pieza B: soporte tipo torii"),
              figura("img/figA2_piezaB.png", "<b>Figura A.2.</b> Pieza B reconstruida: vistas isométrica, superior y frontal."),
              h4("A.5 Pieza E: ménsula con tubo y bosses"),
              figura("img/figA4_piezaE.png", "<b>Figura A.4.</b> Pieza E reconstruida: vistas isométrica, superior y frontal."),
              p(class = "nota", "Cuña XZ (0, 0), (25.4, 0), (25.4, 3), (0, 5) extruida en Y de −22 a 22; tubo de 6 mm con barreno de 3 mm;
                dos bosses de 12 mm con barreno de 5 mm; ranura de 4 mm. Incorpora tres revisiones: profundidad de 1.5” (38.1 mm), rebajes
                a 12 mm del frente separados ±35 mm y barra alineada con el frente de la cuña.")
            )
          ),
          h4("A.6 Pieza F: soporte trapezoidal frontal para cámara y brazo auxiliar"),
          fluidRow(column(5, figura("img/figA5_piezaF.png", "<b>Figura A.5.</b> Pieza F, archivo de diseño: vistas isométrica, superior y frontal.")),
                   column(7, figura("img/figA6_piezaF_cotas.png", "<b>Figura A.6.</b> Pieza F: vistas frontal, lateral y superior generadas del STL, con cotas en milímetros."))),
          h4("Tabla A.3 — Rasgos de la pieza F (mm; origen al centro de la base, −Y hacia el frente)"), tabla_simple(tabla_piezaF)
        ),
        tabPanel("C–F · Programas",
          fluidRow(
            column(4,
              selectInput("ap_apendice", "Apéndice", c("C · Sistema PIC" = "C", "D · Arduino" = "D", "E · Jetson" = "E",
                                                      "F · Aplicación de RA (Meta Quest 3S)" = "F")),
              uiOutput("ap_intro"),
              selectInput("ap_listado", "Listado", choices = NULL, width = "100%"),
              textInput("ap_buscar", "Buscar en todos los listados", placeholder = "p. ej. MD22, Kalman, 0x58, WDT…"),
              uiOutput("ap_busqueda"),
              uiOutput("ap_info"),
              downloadButton("ap_descargar", "Descargar este listado")
            ),
            column(8, uiOutput("ap_codigo"))
          )
        ),
        tabPanel("F · Estructura de la aplicación",
          parrafo("La página carga three.js 0.170.0 y sus complementos ARButton y GLTFLoader desde jsDelivr, pide una sesión immersive-ar con
                   las capacidades obligatorias hit-test y local-floor y las opcionales dom-overlay y anchors, y dibuja la escena en el ciclo
                   animate (72 a 90 Hz). En cada cuadro se lee la pose del control izquierdo y se filtra con Kalman; los comandos al vehículo
                   salen a 5 Hz. La versión anterior enviaba cada mensaje de depuración al servidor, lo que generaba unas 100 peticiones HTTP
                   al iniciar y retrasaba unos 10 s el botón de RA; en la versión vigente se eliminó."),
          h4("Tabla F.1 — Mapa de funciones de trajectory_6modes_tracker0.html"), tabla_simple(tabla_funciones_F),
          h4("Tabla F.2 — Mensajes entre la aplicación y el servidor vigente"), tabla_simple(tabla_protocolo_F),
          p(class = "nota", "Con las correcciones, el visor envía un solo mensaje por ciclo de 5 Hz y el servidor arma la trama ALL; en el
            archivo del 18 de abril el modo 2 enviaba la trama ALL y además MODE2_TRACK (el Arduino recibía cada comando dos veces), y el
            paro de emergencia del modo 5 enviaba M1:0,M2:0,S2:90, un formato que ni el servidor ni el Arduino reconocen.")
        ),
        tabPanel("Algoritmos 1–6",
          parrafo("Los seis algoritmos de la tesis, en el pseudocódigo del documento. Cada uno está implementado en esta aplicación:
                   1 y 2 en el simulador del firmware y la lógica de seguridad (capítulo 5), 4 en el suavizado ARC/SPLINE, 5 en el
                   generador de comandos y 6 en el estimador del Laboratorio de seguimiento."),
          lapply(names(algoritmos), function(n) concepto(titulo = n, tipo = "gris", tags$pre(class = "pseudo", algoritmos[[n]])))
        )
      )
    )
  )
}

server_apendices <- function(input, output, session, listados) {
  observeEvent(input$ap_apendice, {
    l <- listados[listados$apendice == input$ap_apendice, ]
    updateSelectInput(session, "ap_listado", choices = setNames(l$id, paste0("Listado ", l$id, ": ", l$titulo)))
  })
  output$ap_intro <- renderUI(p(class = "nota", intro_apendices[[input$ap_apendice]]))
  actual <- reactive({ req(input$ap_listado); listados[listados$id == input$ap_listado, ][1, ] })
  output$ap_info <- renderUI({
    l <- actual(); ref <- grepl("referencia|\\(ref", l$titulo, ignore.case = TRUE)
    resultado(celda(l$lineas, "Líneas"), celda(toupper(l$lenguaje), "Lenguaje"),
              celda(if (l$apendice == "F") paste0(l$inicio, "–", l$inicio + l$lineas - 1) else "1", "Línea inicial en el archivo"))
  })
  output$ap_codigo <- renderUI({
    l <- actual(); lin <- strsplit(l$codigo, "\n", fixed = TRUE)[[1]]
    n <- seq(l$inicio, length.out = length(lin))
    num <- paste(formatC(n, width = nchar(max(n))), collapse = "\n")
    tagList(h4(paste0("Listado ", l$id, ": ", l$titulo)),
            div(class = "codigo-wrap",
                tags$pre(class = "codigo-num", num),
                tags$pre(class = "codigo", tags$code(class = paste0("language-", l$lenguaje), paste(lin, collapse = "\n")))),
            tags$script(HTML("if (window.hljs) { document.querySelectorAll('pre.codigo code').forEach(function(b){ hljs.highlightElement(b); }); }")))
  })
  output$ap_busqueda <- renderUI({
    q <- trimws(input$ap_buscar); req(nchar(q) >= 2)
    hits <- vapply(listados$codigo, function(x) sum(grepl(q, strsplit(x, "\n", fixed = TRUE)[[1]], fixed = TRUE, ignore.case = FALSE) |
                                                  grepl(tolower(q), tolower(strsplit(x, "\n", fixed = TRUE)[[1]]), fixed = TRUE)), 0)
    d <- listados[hits > 0, ]; h <- hits[hits > 0]
    if (!nrow(d)) return(p(class = "nota", "Sin coincidencias."))
    tagList(p(class = "nota", paste0(sum(h), " líneas en ", nrow(d), " listados:")),
            div(lapply(seq_len(nrow(d)), function(k) actionLink(paste0("ap_ir_", gsub("\\.", "_", d$id[k])),
                                                                 etiqueta(paste0(d$id[k], " (", h[k], ")"))))))
  })
  lapply(listados$id, function(id) {
    observeEvent(input[[paste0("ap_ir_", gsub("\\.", "_", id))]], {
      ap <- substr(id, 1, 1)
      updateSelectInput(session, "ap_apendice", selected = ap)
      l <- listados[listados$apendice == ap, ]
      updateSelectInput(session, "ap_listado", choices = setNames(l$id, paste0("Listado ", l$id, ": ", l$titulo)), selected = id)
    }, ignoreInit = TRUE)
  })
  output$ap_descargar <- downloadHandler(
    filename = function() {
      l <- actual(); ext <- c(c = "c", cpp = "ino", python = "py", javascript = "js", bash = "sh", ini = "service", x86asm = "asm")[l$lenguaje]
      paste0("Listado_", gsub("\\.", "_", l$id), ".", ext)
    },
    content = function(f) writeLines(actual()$codigo, f, useBytes = TRUE))
}
