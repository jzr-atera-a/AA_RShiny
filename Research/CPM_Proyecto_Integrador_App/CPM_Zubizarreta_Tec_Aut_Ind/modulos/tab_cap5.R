# =============================================================================
# Capítulo 5 — Etapas 3 y 4: Arduino y NVIDIA Jetson
# =============================================================================

ui_cap5 <- function() {
  tabItem(tabName = "cap5",
    fluidRow(
      caja("Capítulo 5: Etapas 3 y 4 — Panorama",
        concepto(parrafo("En la Etapa 3 los actuadores pasaron a un Arduino Nano, primero, y a un Arduino Mega 2560, después, con un
                 programa de prueba mínimo por actuador y un firmware que interpreta comandos de texto. En la Etapa 4 una NVIDIA Jetson
                 Nano concentró el procesamiento, los servidores y el registro, y se comunicó con el Arduino (actuadores) y con el PIC
                 (sensores). El capítulo termina con la lógica de seguridad de tres capas, el ciclo de control y las pruebas."))
      )
    ),
    fluidRow(
      caja("5.1 Por qué cambiar al Arduino — Tabla 5.1", ancho = 6, estado = "info",
        parrafo("El problema era la velocidad de iteración: cada cambio en el PIC implicaba compilar, grabar y volver a probar, y el
                 cristal de 4 MHz limitaba el puerto serie y el PWM. El Arduino Nano ofrece un ciclo de prueba de segundos, un reloj de
                 16 MHz con el que 115 200 baudios se generan con +2.1 % de error (frente al +8.5 % del PIC), bibliotecas probadas
                 (Wire, Servo, Serial) y un monitor serie integrado."),
        tabla_simple(tabla_nano_pic),
        p(class = "nota", "Regla adoptada: cada actuador tiene su propio programa de prueba mínimo, y solo cuando todos pasan se juntan
          en el firmware completo.")
      ),
      caja("5.2 Programas de la Etapa 3 — Tablas 5.2 y 5.3", ancho = 6, estado = "primary",
        tabla_simple(tabla_programas_e3), br(), tabla_simple(tabla_rutinas),
        p(class = "nota", "N3 enseña una práctica valiosa: leer un registro de solo lectura (la versión del MD22) es la mejor prueba de que
          la dirección y el bus están bien antes de mandar velocidades. Secuencia con las ruedas en el aire: PING, M1:20, M1:-20, M1:0,
          M2:20 y STOP.")
      )
    ),
    fluidRow(
      caja("5.2.1–5.2.2 Intérprete de comandos y vigilante de comunicación — simulador del firmware", ancho = 12, estado = "warning",
        fluidRow(
          column(5,
            ecuacion("$$u' = \\begin{cases} 0 & \\text{si } u = 0,\\\\ \\operatorname{sgn}(u)\\,\\min\\big(\\max(|u|, 40),\\,100\\big) & \\text{en otro caso} \\end{cases} \\qquad (5.1)$$",
                     "Validación de cada velocidad en el programa de referencia N5; el firmware vigente (Listado D.7) no satura: rechaza la trama completa con ERR:RANGE."),
            radioButtons("c5_fw", "Firmware", c("Vigente D.7 (rechaza fuera de rango)" = "D7", "Referencia N5 (satura y vigila)" = "N5")),
            textInput("c5_cmd", "Comando (115 200 baudios, 8N1, terminado en \\n)", "ALL:M1:60:M2:60:S1:90:S2:90", width = "100%"),
            fluidRow(column(4, actionButton("c5_enviar", "Enviar", class = "btn-primary", icon = icon("paper-plane"))),
                     column(8, selectInput("c5_ejemplo", NULL, c("Ejemplos…" = "", "ALL:M1:60:M2:60:S1:90:S2:90", "ALL:M1:100:M2:50:S1:90:S2:40",
                                                                  "ALL:M1:50:M2:100:S1:90:S2:140", "ALL:M1:30:M2:60:S1:90:S2:150",
                                                                  "MOTORS:60", "MOTOR1:50", "SERVO2:120", "PING", "STATUS",
                                                                  "STOP_ALL_MOTORS", "M1:0,M2:0,S2:90")))),
            uiOutput("c5_estado"),
            h4("Tabla 5.4 — Protocolo de comandos"), tabla_simple(tabla_comandos)
          ),
          column(7,
            div(class = "consola", uiOutput("c5_consola")),
            br(),
            concepto(titulo = "Vigilante de comunicación (Algoritmo 1): Tw = 500 ms",
              parrafo("El valor de Tw equivale a 2.5 periodos del generador de 5 Hz: la pérdida de una sola trama no detiene el vehículo,
                       pero la de tres consecutivas sí. Elija qué tramas se pierden en una secuencia de 5 s:"),
              fluidRow(column(6, sliderInput("c5_wd_ini", "Primera trama perdida", 1, 24, 8, 1)),
                       column(6, sliderInput("c5_wd_n", "Tramas consecutivas perdidas", 0, 8, 3, 1))),
              plotlyOutput("c5_wd_plot", height = "220px"),
              uiOutput("c5_wd_res"))
          )
        )
      )
    ),
    fluidRow(
      caja("5.2.3 Conexiones del Arduino Mega 2560 — Tabla 5.5", ancho = 6, estado = "success",
        tabla_simple(tabla_conexiones_mega),
        p(class = "nota", "Del Nano al Mega el código se reutilizó casi sin cambios; solo el I²C pasó a los pines 20 (SDA) y 21 (SCL) y el
          puerto en Linux pasó de /dev/ttyUSB0 (CH340) a /dev/ttyACM0.")),
      caja("5.3 Etapa 4: la computadora de borde", ancho = 6, estado = "primary",
        parrafo("El vehículo necesita servir una página segura al visor, mantener una conexión WebSocket, calcular curvaturas y errores
                 con punto flotante a 5 Hz, registrar archivos y atender dos microcontroladores a la vez. La Jetson Nano tiene una CPU ARM
                 Cortex-A57 de cuatro núcleos a 1.43 GHz, GPU Maxwell de 128 núcleos y 4 GB de memoria; su cabezal de 40 pines trabaja a
                 3.3 V y no tolera 5 V. Se alimenta por barril a 5 V y 4 A con el puente J48 colocado."),
        parrafo("Configuración: SSH (ssh joe@192.168.100.10), Samba y tmux; el usuario se agrega al grupo dialout; reglas udev dan nombres
                 permanentes: /dev/cpm_actuadores para el Arduino y /dev/cpm_sensores para el adaptador USB-RS232 de la BK300."),
        concepto(titulo = "Del módulo XI a la Jetson", p("Z80 de 8 bits → 8086 con segmentación → 80286 con modo protegido → 80386/486 con
                 memoria virtual, pipeline y caché → Pentium superescalar → ARM de 64 bits con cuatro núcleos y sistema operativo. La GPU
                 cumple a otra escala el papel del coprocesador 8087.")))
    ),
    fluidRow(
      caja("5.3.2 Protocolo del nodo de sensores", ancho = 6, estado = "info",
        ecuacion("$$\\texttt{\\$<TIPO>,<campo>=<valor>,}\\ldots\\texttt{*<CS>\\textbackslash r\\textbackslash n}$$",
                 "CS es el XOR de todos los caracteres entre $ y *, en dos dígitos hexadecimales. Si la Jetson calcula un valor distinto, descarta la trama."),
        fluidRow(column(4, numericInput("c5_s_v", "VBAT (mV)", 12600, 0, 20000, 10)),
                 column(4, numericInput("c5_s_t", "TEMP (décimas °C)", 285, -550, 1250, 1)),
                 column(4, numericInput("c5_s_p", "POT1 (cuentas)", 512, 0, 1023, 1))),
        uiOutput("c5_trama"),
        textInput("c5_verif", "Verificar una trama recibida", "$SEN,VBAT=12600,TEMP=285,POT1=512*02", width = "100%"),
        uiOutput("c5_verif_res"),
        h4("Tabla 5.6 — Tramas y comandos"), tabla_simple(tabla_tramas_pic),
        p(class = "nota", "El preescalador del PIC es único y compartido entre Timer0 y watchdog: si quedara en el Timer0, el watchdog
          (≈ 18 ms) se dispararía mientras se envía una trama de 42 ms. Por eso se asigna al watchdog (1:128, ≈ 2.3 s) y la base de 1 ms
          se genera con el Timer2.")
      ),
      caja("5.3.3 Puente de software y lógica de seguridad (Algoritmo 2)", ancho = 6, estado = "danger",
        ecuacion("$$EN = \\overline{P}\\cdot W_A\\cdot W_P\\cdot B\\cdot T\\cdot D \\qquad (5.2)$$",
                 "Habilitación ampliada con los vigilantes de ambos microcontroladores, la temperatura y la distancia libre."),
        fluidRow(column(6, checkboxInput("c5_paro", "Paro de emergencia presionado (P)", FALSE)),
                 column(6, sliderInput("c5_tcmd", "Tiempo desde el último comando al Arduino (ms)", 0, 1500, 200, 50))),
        fluidRow(column(6, sliderInput("c5_tsen", "Tiempo desde la última trama $SEN (s)", 0, 3, 0.2, 0.1)),
                 column(6, sliderInput("c5_vb", "Vbat (V)", 10.5, 13.5, 12.4, 0.05))),
        fluidRow(column(6, sliderInput("c5_temp", "Temperatura del MD22 (°C)", 20, 90, 35, 1)),
                 column(6, sliderInput("c5_dist", "Distancia libre HC-SR04 (cm, propuesto)", 5, 200, 120, 5))),
        uiOutput("c5_seg_res"),
        h4("Tabla 5.7 — Lógica de seguridad"), tabla_dt(tabla_seguridad, paginas = 7, botones = FALSE),
        concepto(tipo = "ambar", p("Tres capas de paro independientes: el PIC (interrupción y relevador), la Jetson (software) y el Arduino
                 (falta de comandos). La tercera capa todavía no existe en el firmware vigente; si se cae la Jetson o el cable USB, la
                 protección depende del PIC y del relevador."))
      )
    ),
    fluidRow(
      caja("5.3.4 Ciclo de control y presupuesto de latencia — Figura 5.1", ancho = 7, estado = "primary",
        plotlyOutput("c5_ciclo", height = "330px"),
        p(class = "nota", "Duraciones estimadas de diseño. El cálculo de la Jetson tarda menos de 5 ms; una trama ALL de ≈ 30 caracteres
          tarda 30 × 10/115 200 ≈ 2.6 ms; la trama $SEN ocupa ≈ 42 ms a 9600 baudios. El ciclo deja más de 100 ms libres: el sistema
          podría operar a 10 Hz.")
      ),
      caja("Latencia de extremo a extremo", ancho = 5, estado = "info",
        sliderInput("c5_l_xr", "Cuadro WebXR (ms)", 0, 20, 14, 1),
        sliderInput("c5_l_wifi", "Wi-Fi (ms)", 0, 160, 15, 1),
        sliderInput("c5_l_srv", "Servidor (ms)", 0, 10, 3, 0.5),
        sliderInput("c5_l_ser", "Serie USB (ms)", 0, 10, 3, 0.5),
        sliderInput("c5_l_ard", "Arduino con I²C (ms)", 0, 15, 6, 0.5),
        uiOutput("c5_lat_res"),
        p(class = "nota", "En las corridas de abril se registraron latencias de ping del visor de 14 a 156 ms, atribuidas al ahorro de
          energía del visor (Tabla 6.8).")
      )
    ),
    fluidRow(
      caja("5.4 Componentes electrónicos adicionales en evaluación", ancho = 12, estado = "success",
        fluidRow(
          column(6, h4("5.4.1 LiDAR — Tabla 5.8"), tabla_simple(tabla_lidar),
                 p(class = "nota", "Una vuelta de un LiDAR 2D ocupa varios kilobytes, del orden de los 8 KB de SRAM del Mega: los de barrido
                   se asignan a la Jetson y el telémetro de un punto al Arduino."),
                 h4("5.4.3 Canales de mando — Tabla 5.9"), tabla_simple(tabla_canales)),
          column(6, h4("5.4.2 Transmisión de video al visor"),
                 ecuacion("$$R_{video} \\approx \\frac{w\\,h\\,f\\,b_{px}}{c} \\qquad (5.3)$$"),
                 fluidRow(column(4, selectInput("c5_v_res", "Resolución", c("640 × 480" = "640x480", "1280 × 720" = "1280x720", "1920 × 1080" = "1920x1080"))),
                          column(4, numericInput("c5_v_f", "Cuadros/s", 30, 1, 120, 1)),
                          column(4, numericInput("c5_v_c", "Compresión c", 100, 1, 1000, 5))),
                 uiOutput("c5_video_res"),
                 p(class = "nota", "Con YUV 4:2:0 (12 bits por píxel). La latencia estimada de WebRTC/RTSP es de 50 a 200 ms."),
                 h4("5.4.4 Arranque autónomo"),
                 parrafo("La Jetson ejecuta un programa de Python al encender, como servicio del sistema, y manda al Arduino órdenes de alto
                          nivel: MOVE, HEAD, ARM, STOP y STATUS, que deben pasar por el mismo filtro de seguridad."))
        )
      )
    ),
    fluidRow(
      caja("5.5 Diseños de conexión de circuito", ancho = 12, estado = "primary",
        parrafo("La electrónica del vehículo se reúne en cinco diseños de conexión de circuito con el estilo de un circuito impreso (placa
                 verde, pistas de potencia anaranjadas, pistas de señal doradas y plano de tierra discontinuo). Son diagramas de conexión:
                 indican qué terminal se une con cuál, con qué componente intermedio y con qué valor."),
        tabBox(width = 12,
          tabPanel("1 · Nodo de sensores PIC",
            fluidRow(column(7, parrafo("El PIC16F877A (U1) recibe 5 V con capacitores de desacoplo de 100 nF junto a los pines 11–12 y 31–32,
                     el cristal de 4 MHz con dos capacitores de 22 pF entre OSC1 y OSC2, y 10 kΩ en MCLR. Entradas: divisor 20 kΩ/10 kΩ con
                     100 nF hacia RA5/AN4; DS18B20 con pull-up de 4.7 kΩ; codificador por un 74HC14 hacia RC0/T1CKI; paro NC hacia RB0/INT;
                     receptor IR VS1838B hacia RB4. Salidas: dos 2N2222 para el relevador K1 (con 1N4007) y el zumbador; el MAX232 convierte
                     TX/RX a RS232 hacia un DB9."),
                     concepto(tipo = "gris", titulo = "Criterios de distribución", p("Parte analógica separada de la digital; desacoplo pegado
                     a los pines; cristal con pistas cortas; plano de tierra que rodea las zonas para que las corrientes de retorno no crucen
                     bajo el ADC; conector ICSP para reprogramar sin retirar el PIC."))),
              column(5, concepto(titulo = "Resistencia de base del relevador (ec. 5.4)",
                ecuacion("$$I_B = 3\\,\\frac{I_C}{h_{FE,min}},\\qquad R_B = \\frac{V_{OH}-V_{BE}}{I_B}$$"),
                fluidRow(column(6, numericInput("c5_rb_ic", "Bobina (mA)", 70, 5, 500, 5)),
                         column(6, numericInput("c5_rb_h", "hFE mínima", 100, 10, 500, 10))),
                uiOutput("c5_rb_res"))))),
          tabPanel("2 · Actuadores Arduino",
            parrafo("Bus I²C de los pines 20 y 21 al MD22 con pull-ups de 4.7 kΩ; servos S2 (pin 9), S1 (pin 8) y cámara propuesta (pin 11)
                     alimentados por el bus de 6 V del convertidor U1 —nunca por el regulador del Mega— con un electrolítico de 470 µF;
                     codificadores por un 74HC14 hacia INT0 e INT1 (pines 2 y 3); Serial1 libre para el PIC o el TF-Luna; USB-B a la Jetson."),
            concepto(tipo = "ambar", p("La decisión más importante: un servo de alto par como el HS-805BB demanda picos de varios amperes; si esa
                     corriente pasara por el regulador del Mega, el voltaje de la lógica caería lo suficiente para reiniciar el
                     microcontrolador a mitad de una maniobra."))),
          tabPanel("3 · Distribución de potencia",
            parrafo("La batería entra por J1, pasa por el fusible de acción retardada F1 (7.5 A) y el interruptor SW1 al bus de 12 V conmutado,
                     protegido por un TVS de 15 V. El bus alimenta el MD22 a través del contacto NA del relevador K1 (gobernado por el nodo
                     PIC) con 1000 µF/25 V, el buck de 6 V y 3 A para los servos y el buck de 5 V y 5 A para la Jetson y la lógica. La toma
                     del divisor se hace antes del fusible para medir la batería aun con el interruptor abierto."),
            concepto(titulo = "Orden de las protecciones", p("Fusible inmediatamente después del borne positivo (protege todo el cableado);
                     TVS contra los transitorios que los motores devuelven al bus; capacitor de 1000 µF junto al MD22; contacto de K1
                     dimensionado para la corriente de arranque de ambos motores."))),
          tabPanel("4 · Concentrador Jetson",
            parrafo("Cuatro puertos USB con nombres fijos: Arduino Mega (/dev/cpm_actuadores, 115 200 Bd), adaptador USB-RS232 al nodo PIC
                     (/dev/cpm_sensores, 9600 Bd), cámara frontal y adaptador Wi-Fi (puertos 8443 y 8444). Ethernet para SSH y Samba. Si se
                     conectara el PIC directo a la UART del cabezal (pines 8 y 10), haría falta un adaptador de niveles con BSS138."),
            concepto(titulo = "Por qué todo por USB", p("Eléctrica: cada dispositivo trae su convertidor y sus niveles quedan aislados de los
                     3.3 V de la Jetson. Software: udev asigna nombres fijos por número de serie. Costo: ≈ 1 ms de latencia por transferencia,
                     despreciable frente a 200 ms."))),
          tabPanel("5 · Controlador integral PIC + MD22",
            parrafo("Antes del Arduino, el PIC16F877A fue la primera unidad capaz de comunicarse por el puerto serie, leer los sensores y
                     mandar el MD22 por I²C. Su firmware habla exactamente el mismo protocolo que el Arduino Mega, de modo que la Jetson y el
                     visor no distinguen cuál de los dos está conectado."),
            fluidRow(column(6, h4("Tabla 5.10 — Asignación de recursos"), tabla_simple(tabla_recursos_pic)),
                     column(6, h4("Tabla 5.11 — Alineación con el sistema"), tabla_simple(tabla_alineacion))),
            concepto(tipo = "gris", p("Convivencia de los servos con el 1-Wire: deshabilitar interrupciones durante una ranura de hasta 70 µs
                     alargaría un pulso de servo ≈ 12°; por eso las transacciones 1-Wire se ejecutan solo en la fase de reposo de los servos
                     (≥ 16 ms) y si faltan más de 4 ms para el siguiente pulso.")))
        )
      )
    ),
    fluidRow(
      caja("5.6 Sistema de retroalimentación — cuatro lazos", ancho = 7, estado = "info",
        tabla_simple(data.frame(Lazo = c("1. Seguimiento geométrico", "2. Posición del servo", "3. Velocidad por rueda", "4. Supervisión"),
                                Tasa = c("5 Hz (actual)", "Interno, analógico", "Propuesto, T = 50 ms", "Continuo"),
                                `Sensor` = c("Control del visor + compuerta + 3 filtros de Kalman", "Potenciómetro del servo",
                                             "Codificadores de 400 ranuras", "Nodo PIC: Vbat, T, paro; vigilantes"),
                                `Qué corrige` = c("Qué punto se persigue (la dirección sale de la curvatura)", "Ángulo del eje en ≈ 0.23 s",
                                                  "Velocidad de cada rueda con PID (5.5)", "Habilita o bloquea los demás lazos (5.2)"),
                                check.names = FALSE)),
        ecuacion("$$u_k = K_p e_k + K_i T\\sum_{j=0}^{k} e_j + K_d\\,\\frac{e_k - e_{k-1}}{T},\\qquad e_k = v_k^{ref} - v_k \\qquad (5.5)$$",
                 "Lazo 3 propuesto, con saturación al intervalo de (5.1) y anti-acumulación del término integral.")
      ),
      caja("Lazo 3 propuesto: PID de velocidad", ancho = 5, estado = "warning",
        fluidRow(column(4, numericInput("c5_kp", "Kp", 300, 0, 2000, 10)),
                 column(4, numericInput("c5_ki", "Ki", 900, 0, 5000, 10)),
                 column(4, numericInput("c5_kd", "Kd", 0, 0, 100, 1))),
        sliderInput("c5_carga", "Perturbación a t = 3 s (rampa o fricción)", 0, 0.08, 0.03, 0.005),
        plotlyOutput("c5_pid_plot", height = "260px"),
        aviso_sim("Motor genérico de primer orden (τ = 0.25 s): muestra la estructura del lazo, no los parámetros del Toshiba 12-14.")
      )
    ),
    fluidRow(
      caja("5.8 Lista de verificación previa a energizar — Tabla 5.12", ancho = 6, estado = "danger",
        div(class = "checklist", checkboxGroupInput("c5_check", NULL, width = "100%",
            choiceNames = paste0(lista_verificacion$`#`, ". [", lista_verificacion$Fase, "] ", lista_verificacion$`Verificación`),
            choiceValues = lista_verificacion$`#`)),
        uiOutput("c5_check_res")),
      caja("5.9 Pruebas de las Etapas 3 y 4 — Tabla 5.13", ancho = 6, estado = "success",
        tabla_dt(tabla_pruebas_34, paginas = 8),
        p(class = "nota", "Hito principal, P4-03: el vehículo ejecutó trayectorias dibujadas en el visor a través de la cadena completa
          visor → Jetson → Arduino → MD22 y servo, validada de forma cualitativa en enero de 2026."))
    )
  )
}

server_cap5 <- function(input, output, session) {
  hist <- reactiveVal(list(list(tipo = "info", txt = "Firmware de actuadores listo — 115200 8N1")))
  est <- reactiveVal(list(M1 = 0L, M2 = 0L, S1 = 90L, S2 = 90L))
  observeEvent(input$c5_ejemplo, { if (nzchar(input$c5_ejemplo)) updateTextInput(session, "c5_cmd", value = input$c5_ejemplo) })
  observeEvent(input$c5_enviar, {
    r <- interpretar_comando(input$c5_cmd, input$c5_fw, est())
    est(r$estado)
    h <- c(hist(), list(list(tipo = "tx", txt = paste0("> ", toupper(trimws(input$c5_cmd)))),
                     list(tipo = if (r$valido) "ok" else "err", txt = r$resp)))
    if (length(h) > 60) h <- tail(h, 60)
    hist(h)
  })
  observeEvent(input$c5_fw, { hist(c(hist(), list(list(tipo = "info", txt = paste0("— Firmware cambiado a ", input$c5_fw, " —"))))) },
               ignoreInit = TRUE)
  output$c5_consola <- renderUI({
    tagList(lapply(rev(hist()), function(l) div(class = l$tipo, l$txt)))
  })
  output$c5_estado <- renderUI({
    e <- est(); dl <- (e$S2 - 90) / (50 / 30)
    resultado(celda(paste0(e$M1, " %"), "M1 (izquierdo)"), celda(paste0(e$M2, " %"), "M2 (derecho)"),
              celda(paste0(e$S1, "°"), "S1 pinzas"), celda(paste0(e$S2, "°"), paste0("S2 dirección (δ ≈ ", fmt(dl, 1), "°)")),
              celda(md22_registro(e$M1), "Registro 1 del MD22"), celda(md22_registro(e$M2), "Registro 2 del MD22"))
  })
  wd <- reactive({
    t <- seq(0, 5, by = 0.2); n <- length(t); recibida <- rep(TRUE, n)
    if (input$c5_wd_n > 0) recibida[pmin(n, input$c5_wd_ini + 0:(input$c5_wd_n - 1))] <- FALSE
    tc <- 0; parado <- FALSE; t_paro <- NA
    tt <- seq(0, 5, by = 0.01); estado <- logical(length(tt))
    for (k in seq_along(tt)) {
      j <- which(abs(t - tt[k]) < 1e-9)
      if (length(j) && recibida[j]) { tc <- tt[k]; parado <- FALSE }
      if (!parado && tt[k] - tc > 0.5) { parado <- TRUE; if (is.na(t_paro)) t_paro <- tt[k] }
      estado[k] <- !parado
    }
    list(t = t, recibida = recibida, tt = tt, estado = estado, t_paro = t_paro)
  })
  output$c5_wd_plot <- renderPlotly({
    w <- wd()
    plot_ly() %>% add_markers(x = w$t, y = 1.25, marker = list(color = ifelse(w$recibida, COL$verde, COL$rojo), size = 10, symbol = "square"),
                              name = "Tramas (verde: recibida; rojo: perdida)", hoverinfo = "x") %>%
      add_lines(x = w$tt, y = as.numeric(w$estado), line = list(color = COL$azul, shape = "hv", width = 2.5), name = "Motores habilitados") %>%
      tema("Tiempo (s)", NULL) %>% layout(yaxis = list(tickvals = c(0, 1, 1.25), ticktext = c("Paro", "Mueve", "Trama"), range = c(-0.2, 1.45)))
  })
  output$c5_wd_res <- renderUI({
    w <- wd()
    if (input$c5_fw == "D7") return(resultado(celda("Sin vigilante", "Firmware vigente: el MD22 conservaría la última velocidad", "mal")))
    if (is.na(w$t_paro)) resultado(celda("Sin paro", "La pérdida no excede Tw = 500 ms", "ok"))
    else resultado(celda(paste(fmt(w$t_paro, 2), "s"), "Instante del paro (pararTodo(): motores en 128, dirección a 90°)", "warn"),
                   celda("WARN timeout", "Aviso enviado"))
  })
  output$c5_trama <- renderUI({
    cuerpo <- sprintf("SEN,VBAT=%d,TEMP=%d,POT1=%d", as.integer(input$c5_s_v), as.integer(input$c5_s_t), as.integer(input$c5_s_p))
    cs <- xor_checksum(cuerpo); tr <- paste0("$", cuerpo, "*", cs)
    nch <- nchar(tr) + 2
    resultado(celda(paste0("<span class='mono' style='font-size:14px'>", tr, "\\r\\n</span>"), "Trama completa"),
              celda(cs, "Suma XOR"), celda(paste(fmt(nch * 10 / 9600 * 1000, 1), "ms"), "Tiempo a 9600 baudios"))
  })
  output$c5_verif_res <- renderUI({
    s <- trimws(input$c5_verif)
    m <- regmatches(s, regexec("^\\$(.*)\\*([0-9A-Fa-f]{2})$", s))[[1]]
    if (length(m) != 3) return(resultado(celda("Formato inválido", "Se espera $cuerpo*CS", "mal")))
    calc <- xor_checksum(m[2]); ok <- toupper(m[3]) == calc
    resultado(celda(calc, "XOR calculado"), celda(toupper(m[3]), "XOR recibido"),
              celda(if (ok) "Aceptada" else "Descartada", "Decisión de la Jetson", if (ok) "ok" else "mal"))
  })
  output$c5_seg_res <- renderUI({
    m <- filtro_seguridad(input$c5_paro, input$c5_tsen, input$c5_vb, input$c5_temp, input$c5_dist / 100)
    terms <- c(`P̄` = !input$c5_paro, `W_A` = input$c5_tcmd <= 500, `W_P` = input$c5_tsen <= 1, B = input$c5_vb >= 11.8,
               T = input$c5_temp <= 60, D = input$c5_dist >= 30)
    en <- all(terms)
    tagList(
      div(lapply(names(terms), function(n) etiqueta(paste0(n, " = ", as.integer(terms[[n]])), if (terms[[n]]) "ok" else "mal"))),
      resultado(celda(if (en) "EN = 1" else "EN = 0", "Función de habilitación (5.2)", if (en) "ok" else "mal"),
                celda(if (nzchar(m)) paste0("BLOQUEADO:", m) else "Reenviar al Arduino", "Jetson (Algoritmo 2)", if (nzchar(m)) "mal" else "ok"),
                celda(if (input$c5_tcmd > 500) "Paro por vigilante" else "—", "Arduino (vigilante N5)", if (input$c5_tcmd > 500) "warn" else "")),
      if (nzchar(m)) p(class = "nota", "Se envía ALL:M1:0:M2:0:S1:90:S2:90 y se responde al visor con BLOQUEADO:", m, ".")
    )
  })
  output$c5_ciclo <- renderPlotly({
    d <- ciclo_control; d$tarea <- factor(d$tarea, levels = rev(d$tarea))
    cols <- c(COL$ambar, COL$azul, COL$cian, COL$verde, COL$violeta, COL$rojo, COL$azul2)
    p <- plot_ly()
    for (k in seq_len(nrow(d))) {
      for (rep in 0:1) {
        p <- p %>% add_segments(x = d$inicio[k] + 200 * rep, xend = d$inicio[k] + d$duracion[k] + 200 * rep, y = d$tarea[k], yend = d$tarea[k],
                                line = list(color = cols[k], width = 16), showlegend = FALSE, hoverinfo = "text",
                                text = paste0(d$tarea[k], ": ", d$duracion[k], " ms"))
      }
    }
    p %>% add_segments(x = 200, xend = 200, y = 0.5, yend = 7.5, line = list(color = COL$gris, dash = "dash"), showlegend = FALSE) %>%
      tema("Tiempo (ms)", NULL, leyenda = FALSE) %>% layout(margin = list(l = 170), xaxis = list(range = c(0, 260)),
             annotations = list(list(x = 100, y = 7.4, text = "ciclo de 200 ms (5 Hz)", showarrow = FALSE, yref = "y")))
  })
  output$c5_lat_res <- renderUI({
    L <- input$c5_l_xr + input$c5_l_wifi + input$c5_l_srv + input$c5_l_ser + input$c5_l_ard
    resultado(celda(paste(fmt(L, 1), "ms"), "Latencia de extremo a extremo", if (L < 100) "ok" else "mal"),
              celda(if (L < 100) "Cumple" else "No cumple", "Criterio R-06 (< 100 ms)", if (L < 100) "ok" else "mal"),
              celda(paste0(fmt(L / 200 * 100, 0), " %"), "Fracción del ciclo de 200 ms"))
  })
  output$c5_video_res <- renderUI({
    wh <- as.numeric(strsplit(input$c5_v_res, "x")[[1]]); R <- wh[1] * wh[2] * input$c5_v_f * 12 / input$c5_v_c
    resultado(celda(paste(fmt(R / 1e6, 2), "Mbit/s"), "Ancho de banda R<sub>video</sub>"),
              celda(paste(fmt(R / 8 / 1e3, 0), "KB/s"), "Equivalente en bytes"))
  })
  output$c5_rb_res <- renderUI({
    r <- rb_relevador(input$c5_rb_ic / 1000, input$c5_rb_h)
    resultado(celda(paste(fmt(r$ib * 1000, 2), "mA"), "I<sub>B</sub>", if (r$ib > 0.025) "mal" else "ok"),
              celda(fmt_ohm(r$rb), "R<sub>B</sub> calculada"), celda(fmt_ohm(valor_comercial(r$rb) / ifelse(valor_comercial(r$rb) > r$rb * 1.15, 1, 1)), "Comercial (E12)"))
  })
  output$c5_pid_plot <- renderPlotly({
    s <- sim_pid(input$c5_kp, input$c5_ki, input$c5_kd, carga = input$c5_carga)
    plot_ly(s, x = ~t) %>% add_lines(y = ~v * 100, name = "Velocidad (cm/s)", line = list(color = COL$azul, width = 2.5)) %>%
      add_lines(y = ~vref * 100, name = "Referencia", line = list(color = COL$rojo, dash = "dash")) %>%
      add_lines(y = ~u / 5, name = "Mando u/5 (%)", line = list(color = COL$ambar, width = 1.5), yaxis = "y") %>%
      tema("Tiempo (s)", "cm/s")
  })
  output$c5_check_res <- renderUI({
    n <- length(input$c5_check); pct <- n / 10 * 100
    tagList(div(class = "progress", div(class = paste("progress-bar", if (n == 10) "progress-bar-success" else "progress-bar-warning"),
                                        style = paste0("width:", pct, "%"))),
            p(if (n == 10) strong("Lista completa: se pueden iniciar las pruebas en piso al 40–60 %.")
              else paste0(n, " de 10 verificaciones completadas.")))
  })
}
