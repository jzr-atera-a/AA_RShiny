# =============================================================================
# Capítulo 4 — Etapas 1 y 2: sistema PIC, sensores y actuadores
# =============================================================================

ui_cap4 <- function() {
  tabItem(tabName = "cap4",
    fluidRow(
      caja("Capítulo 4: Etapas 1 y 2 — Panorama",
        concepto(parrafo("La Etapa 1 consistió en experimentar con el microcontrolador PIC16F877A sobre la placa de entrenamiento BK300,
                 siguiendo el “sistema PIC” del plan de estudios para los módulos VI a IX y XII. La Etapa 2 usó lo aprendido para
                 comunicar el microcontrolador con sensores y actuadores reales: los motores de tracción con el puente H MD22 y los
                 servomotores. El capítulo responde una pregunta concreta: ¿qué puede hacer el PIC a 4 MHz dentro del vehículo y qué no?
                 La respuesta justifica la arquitectura: el PIC es adecuado como nodo de sensores, pero no como controlador de actuadores."))
      )
    ),
    fluidRow(
      caja("4.1–4.3 Por qué empezar con un PIC", ancho = 6, estado = "info",
        tags$ol(class = "description-text",
          tags$li("No hay bibliotecas que escondan el hardware: para encender un LED, generar PWM o mandar un byte hay que escribir en los
                   registros, lo que obliga a entender qué es un puerto, un temporizador o una interrupción."),
          tags$li("El PIC es heredero directo de los microprocesadores de 8 bits del módulo VI: datos de 8 bits, registros, banderas y
                   saltos condicionales que se reconocen del ensamblador del Z80."),
          tags$li("Lo aprendido se transfiere: después se entiende qué hacen por dentro Serial.begin(), analogWrite() o Wire.write().")),
        parrafo("La BK300 se alimenta con 5 V; los programas se escribieron para MPLAB IDE 8.91 con HI-TECH PICC 9.83 y se grabaron con un
                 clon de PICkit 3 por ICSP; la versión moderna equivalente es MPLAB X con XC8."),
        h4("Tabla 4.1 — Periféricos de la placa BK300"), tabla_dt(tabla_bk300, paginas = 11, botones = FALSE)
      ),
      caja("Tabla 4.2 — Z80 frente a PIC16F877A", ancho = 6, estado = "primary",
        tabla_simple(tabla_z80_pic),
        parrafo("En ensamblador, las ideas del módulo VII se conservan: LD A,0FFh del Z80 equivale a MOVLW 0xFF; SET 0,A a BSF PORTB,0;
                 y DJNZ a la pareja DECFSZ/GOTO. Un error clásico es olvidar el cambio de banco: TRISB está en el banco 1 y PORTB en el 0."),
        ecuacion("$$n = \\frac{1\\,\\text{ms}}{4\\,T_{cy}} \\approx 250\\ \\text{vueltas} \\qquad (4.1)$$",
                 "Rutina de retardo de 1 ms con un lazo interno de cuatro ciclos (NOP, DECFSZ y GOTO); se programa con 249 vueltas para compensar la carga del contador y el regreso.")
      )
    ),
    fluidRow(
      caja("4.4 Experimentos de la Etapa 1 — Tabla 4.3", estado = "success", tabla_dt(tabla_experimentos, paginas = 9))
    ),
    fluidRow(
      caja("4.4.1 Timer0: base de tiempo de 5 Hz", ancho = 4, estado = "info",
        ecuacion("$$T_{TMR0} = (256 - TMR0_0)\\,\\frac{4N_{pre}}{f_{osc}} \\qquad (4.2)$$"),
        numericInput("c4_t0_pre", "Valor de precarga TMR0₀", 6, 0, 255, 1),
        selectInput("c4_t0_n", "Preescalador Npre", c(1, 2, 4, 8, 16, 32, 64, 128, 256), selected = 4),
        numericInput("c4_t0_cnt", "Interrupciones contadas", 200, 1, 10000, 1),
        uiOutput("c4_t0_res"),
        p(class = "nota", "Con Npre = 4 y TMR0₀ = 6: 250 × 4 µs = 1.000 ms; 200 interrupciones dan 5 Hz. La interrupción solo avisa y
          el programa principal hace el trabajo.")
      ),
      caja("4.4.3 PWM por hardware y su límite inferior", ancho = 4, estado = "warning",
        ecuacion("$$T_{PWM} = (PR2+1)\\,\\frac{4N_{pre2}}{f_{osc}},\\qquad f_{min} = \\frac{f_{osc}}{4\\cdot 16\\cdot 256} \\approx 244\\,\\text{Hz} \\qquad (4.3)$$"),
        numericInput("c4_pr2", "PR2", 249, 0, 255, 1),
        selectInput("c4_pwm_n", "Preescalador Npre2", c(1, 4, 16), selected = 4),
        selectInput("c4_pwm_f", "Cristal", c("4 MHz" = 4e6, "8 MHz" = 8e6, "20 MHz" = 20e6)),
        uiOutput("c4_pwm_res")
      ),
      caja("4.4.5 EEPROM y watchdog", ancho = 4, estado = "danger",
        parrafo("La escritura en la EEPROM exige la secuencia de desbloqueo 0x55, 0xAA en EECON2 con las interrupciones deshabilitadas:
                 una protección de hardware que impide que un programa descontrolado borre la memoria."),
        tabla_simple(data.frame(`Dirección` = c("0x00", "0x01", "0x02", "0x03"),
                                Contenido = c("Firma 0xA5 (calibración válida)", "Centro del servo", "Constante ks × 10", "Zona muerta de los motores"),
                                check.names = FALSE)),
        ecuacion("$$T_{WDT} \\approx 18\\,\\text{ms}\\times 128 \\approx 2.3\\,\\text{s}$$",
                 "Con el preescalador 1:128 asignado al WDT. Un nodo que se bloquea en silencio es peligroso: la Jetson seguiría usando el último valor.")
      )
    ),
    fluidRow(
      caja("4.4.4 Comunicación RS232 y el límite de velocidad", ancho = 12, estado = "primary",
        fluidRow(
          column(5,
            parrafo("Con f_osc = 4 MHz y BRGH = 1, a 9600 y 19 200 baudios el error es de 0.16 %. Para 115 200 baudios el valor ideal sería
                     SPBRG = 1.17; los enteros vecinos dan errores de +8.5 % y −27.7 %. En un carácter de diez bits, εB = 0.085 desplaza
                     el muestreo del bit de paro 0.81 bits, mayor que el medio bit disponible: el enlace del PIC se fija en 9600 baudios."),
            tabla_simple(data.frame(`Velocidad deseada` = c("9600", "19 200", "57 600", "115 200"), SPBRG = c(25, 12, 3, 1),
                                    `Velocidad real` = c("9615", "19 231", "62 500", "125 000"),
                                    `Error εB` = c("+0.16 %", "+0.16 %", "+8.51 %", "+8.51 %"), check.names = FALSE)),
            p(class = "nota", "Tabla 4.4. La calculadora completa está en Marco teórico → 2.4.")
          ),
          column(7,
            h4("Figura 4.2 interactiva — Transmisión de un carácter en 8N1"),
            fluidRow(column(4, textInput("c4_char", "Carácter", "A")),
                     column(4, selectInput("c4_baud", "Velocidad", c(9600, 19200, 115200), 9600)),
                     column(4, uiOutput("c4_char_info"))),
            plotlyOutput("c4_uart_plot", height = "230px"),
            p(class = "nota", "Bit menos significativo primero: inicio (0), ocho datos, paro (1). A 9600 baudios cada bit dura ≈ 104 µs y
              un carácter completo 1.04 ms.")
          )
        )
      )
    ),
    fluidRow(
      caja("Tabla 4.5 — Limitaciones del PIC16F877A a 4 MHz", ancho = 6, estado = "danger",
        tabla_simple(tabla_limitaciones_pic),
        p(class = "nota", "Ninguna impide usar el PIC como nodo de sensores a 5 Hz, el papel que se le asigna en la Etapa 4.")),
      caja("4.5 Etapa 2: método de cinco pasos", ancho = 6, estado = "success",
        tags$ol(class = "description-text",
          tags$li(strong("Leer"), " la hoja de datos y anotar voltajes, corrientes, protocolo y tiempos."),
          tags$li(strong("Probar"), " el dispositivo solo con un programa mínimo."),
          tags$li(strong("Medir"), " con multímetro y, cuando se pudo, con osciloscopio."),
          tags$li(strong("Comunicar"), " el valor leído o la orden por el puerto serie, en ambos sentidos."),
          tags$li(strong("Documentar"), " el resultado y lo que salió mal.")),
        div(class = "pregunta", "Un dispositivo que no funciona solo no va a funcionar integrado."))
    ),
    fluidRow(
      caja("4.6 Sensores — Tabla 4.6", ancho = 7, estado = "info",
        tabla_dt(tabla_sensores, paginas = 7),
        h4("4.6.1 Sensores analógicos con el ADC"),
        parrafo("El ADC convierte por aproximaciones sucesivas, con un multiplexor interno de ocho canales (bits CHS2:CHS0 de ADCON0),
                 resultado justificado a la derecha, referencia VDD y reloj fosc/8 (2 µs por bit). AN0–AN2 leen los potenciómetros y AN4
                 el divisor de la batería, en aritmética entera:"),
        ecuacion("$$V_{bat}\\,[\\text{mV}] = \\left\\lfloor\\frac{15\\,000\\,N_{ADC}}{1023}\\right\\rfloor \\qquad (4.4)$$",
                 "Evita el punto flotante; la lectura se envía a 5 Hz con el formato $SEN,POT1=…,VBAT=…"),
        h4("4.6.3 Receptor infrarrojo y otros sensores"),
        parrafo("El receptor 1838B entrega la envolvente de una portadora de 38 kHz. El protocolo NEC: encabezado de 9 ms en bajo y 4.5 ms
                 en alto, 32 bits (dirección, dirección invertida, comando y comando invertido), con 0 = 562 + 562 µs y 1 = 562 + 1687 µs.
                 Se propone como segundo paro de emergencia inalámbrico. Propuestos también: HC-SR04 (d [cm] = t_e [µs]/58) y ACS712
                 (185 mV/A alrededor de 2.5 V).")
      ),
      caja("4.6.2 Temperatura con el DS18B20", ancho = 5, estado = "warning",
        parrafo("Mide entre −55 y +125 °C con resolución de hasta 0.0625 °C (12 bits) y pull-up de 4.7 kΩ (Analog Devices, s.f.).
                 Secuencia: reinicio, 0xCC (omitir ROM), 0x44 (convertir), espera de 750 ms, reinicio, 0xCC, 0xBE (leer) y dos bytes."),
        tabla_simple(tabla_onewire),
        concepto(titulo = "Decodificador de la lectura",
          fluidRow(column(6, textInput("c4_ds_lsb", "Byte bajo (hex)", "91")),
                   column(6, textInput("c4_ds_msb", "Byte alto (hex)", "01"))),
          uiOutput("c4_ds_res"),
          p(class = "nota", "Temperatura = entero con signo de 16 bits × 0.0625 °C. En el vehículo el sensor va sobre el disipador del
            MD22; si supera el umbral, la Jetson reduce la velocidad o bloquea el movimiento.")),
        h4("Comprobador del protocolo NEC"),
        fluidRow(column(6, numericInput("c4_nec_dir", "Dirección (0–255)", 0, 0, 255, 1)),
                 column(6, numericInput("c4_nec_cmd", "Comando (0–255)", 69, 0, 255, 1))),
        uiOutput("c4_nec_res")
      )
    ),
    fluidRow(
      caja("4.7.1 Motores de tracción y puente H MD22", ancho = 12, estado = "primary",
        fluidRow(
          column(5,
            parrafo("Los dos motorreductores Toshiba 12-14 se conservan de 2008: 22 rpm y 18 kg·cm en la flecha de salida, de 6 a 24 V,
                     0.09 A sin carga y 0.18 A con carga a 24 V."),
            ecuacion("$$P_m = VI = 24\\,\\text{V}\\times 0.18\\,\\text{A} \\approx 4.3\\,\\text{W por motor} \\qquad (4.5)$$"),
            parrafo("El MD22 contiene dos puentes H de hasta 5 A por canal y acepta órdenes por I²C, por voltaje analógico o por pulsos
                     de radiocontrol (Devantech, s.f.). Su lógica se alimenta con 5 V del microcontrolador; la batería llega a B+ y B−
                     por el fusible, nunca a la entrada Vin del Arduino."),
            fluidRow(column(6, tabla_simple(tabla_md22)), column(6, tabla_simple(tabla_md22_modos)))
          ),
          column(7,
            concepto(titulo = "Conversión del mando al registro del MD22 (modo 0)",
              ecuacion("$$r(u) = 128 + \\frac{127\\,u}{100} \\qquad (4.6)$$"),
              sliderInput("c4_md22_u", "Mando u (%)", -100, 100, 60, 1, width = "100%"),
              uiOutput("c4_md22_res"),
              plotlyOutput("c4_md22_plot", height = "220px")),
            concepto(tipo = "rojo", titulo = "El error más costoso de la Etapa 2",
              p("Durante semanas el MD22 respondía en el bus pero los motores no se movían. La causa fue doble: la confusión entre la
                dirección de 8 bits (0xB0) y la de 7 bits (0x58), y un programa de prueba con el mapa de registros de otro controlador de
                la misma marca (modo en 0x0F, aceleración en 0x0E, velocidades en 0x00 y 0x01). La lección: verificar la hoja de datos
                del modelo exacto y no de uno parecido."))
          )
        )
      )
    ),
    fluidRow(
      caja("El modo de pulsos de radiocontrol: la experiencia de 2008", ancho = 7, estado = "info",
        ecuacion("$$t_p = D\\,(20\\,\\text{ms}),\\qquad u_{RC} = \\frac{t_p - 1.5\\,\\text{ms}}{0.5\\,\\text{ms}}\\times 100\\,\\% \\qquad (4.7)$$"),
        parrafo("La NI 6211 generaba para cada motor un pulso cada 20 ms: 1.5 ms paro, 2 ms avance máximo y 1 ms reversa máxima. En el
                 extremo de 33°, la rueda interior recibía 1.708 ms (41.7 %) y la exterior 1.880 ms (76.0 %); su razón es 0.549, contra
                 0.559 que predice la geometría con ℓ = 0.333 m y b = 0.29 m. En todo el recorrido la diferencia cuadrática media fue de
                 0.034, lo que confirma con datos reales el diferencial electrónico."),
        plotlyOutput("c4_rc_plot", height = "300px"),
        p(class = "nota", "La curva es la razón teórica (ρ − b/2)/(ρ + b/2) con ρ = ℓ/tan δ; los puntos son los dos valores medidos que
          reporta la tesis (0° y 33°). La serie completa de 2008 está en la Figura 4.3 del documento.")
      ),
      caja("4.7.2 Interfaz de los codificadores ópticos", ancho = 5, estado = "success",
        ecuacion("$$R_{LED} = \\frac{5 - 1.2}{0.020} = 190\\,\\Omega \\rightarrow 220\\,\\Omega \\qquad (4.8)$$"),
        ecuacion("$$f_{enc} = N_{enc}\\,\\frac{\\omega_m}{60} = 400\\times\\frac{22}{60} \\approx 147\\,\\text{Hz} \\qquad (4.9)$$"),
        parrafo("El fototransistor trabaja en emisor común con 10 kΩ de colector; un inversor Schmitt 74HC14 limpia los flancos y entrega
                 la señal a T1CKI (PIC) o a INT del Arduino. Con la ventana de 200 ms el método de frecuencia daría ≈ 29 pulsos por
                 ventana y una resolución de ≈ 6.6 mm/s; a velocidades bajas conviene el método de periodo con la captura del CCP.")
      )
    ),
    fluidRow(
      caja("4.7.3 Servomotores", ancho = 12, estado = "warning",
        fluidRow(
          column(5,
            parrafo("Un servomotor es un pequeño sistema de control en lazo cerrado: compara la posición que pide el pulso con la que
                     mide un potenciómetro acoplado al eje y mueve un motor, a través de engranes, hasta que coinciden."),
            ecuacion("$$t_p\\,[\\mu\\text{s}] = 1000 + \\frac{1000\\,\\theta}{180^\\circ},\\qquad \\theta\\in[0^\\circ, 180^\\circ] \\qquad (4.10)$$"),
            sliderInput("c4_srv", "Ángulo de mando θs del servo S2 (°)", 40, 140, 90, 1, width = "100%"),
            selectInput("c4_srv_ks", "Constante ks", c("40/30 (modos 1 a 3)" = 40 / 30, "50/30 (modo 5)" = 50 / 30)),
            uiOutput("c4_srv_res")
          ),
          column(7, plotlyOutput("c4_srv_plot", height = "250px"),
            concepto(titulo = "Presupuesto de corriente de los servos (ec. 4.11)",
              ecuacion("$$I_{servos} \\ge \\sum_{j=1}^{n} I_{carga,j} + I_{S2} \\qquad (4.11)$$"),
              fluidRow(column(4, numericInput("c4_ns", "Servos estándar", 2, 0, 10, 1)),
                       column(4, numericInput("c4_is", "I con carga c/u (A)", 0.7, 0.1, 3, 0.05)),
                       column(4, numericInput("c4_is2", "Pico del HS-805BB (A)", 1.0, 0.1, 5, 0.1))),
              uiOutput("c4_isrv_res")),
            ecuacion("$$TMR1_0 = 65\\,536 - t,\\qquad t\\in\\{t_{p,1},\\ t_{p,2},\\ 20\\,000 - t_{p,1} - t_{p,2}\\}\\ \\mu\\text{s} \\qquad (4.12)$$",
                     "Servos con el PIC: PWM por software con el Timer1 de 16 bits en una máquina de tres estados.")
          )
        )
      )
    ),
    fluidRow(
      caja("4.7.4–4.7.5 Sistema motriz, motor a pasos e indicadores", ancho = 6, estado = "primary",
        parrafo("La batería alimenta al MD22 por el fusible y el interruptor; el MD22 maneja los dos motorreductores; el convertidor de 6 V
                 alimenta los servos; y el Arduino envía las órdenes por I²C y por pulsos de PWM. Todas las tierras convergen en el punto
                 de tierra en estrella."),
        parrafo("La placa maneja un motor a pasos unipolar (como el 28BYJ-48) con el ULN2003. Con una reductora de ≈ 64:1, una vuelta del
                 eje de salida requiere unos 4096 medios pasos."),
        sliderInput("c4_paso", "Paso de la secuencia de medio paso", 1, 8, 1, 1, animate = animationOptions(400, loop = TRUE)),
        uiOutput("c4_paso_res")
      ),
      caja("4.8 Pruebas de las Etapas 1 y 2 — Tabla 4.9", ancho = 6, estado = "success",
        tabla_dt(tabla_pruebas_12, paginas = 9) %>%
          DT::formatStyle("Estado", color = DT::styleEqual("Fuente identificada", "#7A5600", default = "#1B6B47"), fontWeight = "bold"))
    )
  )
}

server_cap4 <- function(input, output, session) {
  output$c4_t0_res <- renderUI({
    T <- timer0_periodo(input$c4_t0_pre, as.numeric(input$c4_t0_n)); Tt <- T * input$c4_t0_cnt
    resultado(celda(paste(fmt(T * 1000, 3), "ms"), "Periodo de interrupción"), celda(paste(fmt(Tt * 1000, 1), "ms"), "Periodo total"),
              celda(paste(fmt(1 / Tt, 3), "Hz"), "Frecuencia resultante", if (abs(1 / Tt - 5) < 0.05) "ok" else ""))
  })
  output$c4_pwm_res <- renderUI({
    f <- as.numeric(input$c4_pwm_f); T <- pwm_periodo(input$c4_pr2, as.numeric(input$c4_pwm_n), f); fmin <- f / (4 * 16 * 256)
    servo_ok <- fmin <= 50
    resultado(celda(paste(fmt(1 / T, 1), "Hz"), "Frecuencia del PWM"), celda(4 * (input$c4_pr2 + 1), "Pasos de resolución"),
              celda(paste(fmt(fmin, 0), "Hz"), "Mínimo con este cristal"),
              celda(if (servo_ok) "Posible" else "Imposible", "Servo a 50 Hz por hardware", if (servo_ok) "ok" else "mal"))
  })
  output$c4_char_info <- renderUI({
    t <- trama_8n1(input$c4_char, as.numeric(input$c4_baud))
    div(style = "margin-top:25px", etiqueta(sprintf("0x%02X", t$code)), etiqueta(paste(fmt(10 / as.numeric(input$c4_baud) * 1000, 3), "ms")))
  })
  output$c4_uart_plot <- renderPlotly({
    t <- trama_8n1(input$c4_char, as.numeric(input$c4_baud)); tb <- t$tbit * 1e6
    y <- c(1, 1, as.vector(rbind(t$bits, t$bits)))
    x <- c(-tb, 0, as.vector(rbind((0:9) * tb, (1:10) * tb)))
    plot_ly() %>% add_lines(x = x, y = y, line = list(color = COL$azul, width = 3), name = "TX", hoverinfo = "skip") %>%
      add_text(x = (0:9 + 0.5) * tb, y = 1.35, text = t$etiquetas, textfont = list(size = 11, color = COL$marino), showlegend = FALSE) %>%
      add_text(x = (0:9 + 0.5) * tb, y = 0.5, text = t$bits, textfont = list(size = 13, color = COL$ambar), showlegend = FALSE) %>%
      tema("Tiempo (µs)", "Nivel lógico", leyenda = FALSE) %>% layout(yaxis = list(range = c(-0.2, 1.6), tickvals = c(0, 1)))
  })
  output$c4_ds_res <- renderUI({
    l <- strtoi(input$c4_ds_lsb, 16L); h <- strtoi(input$c4_ds_msb, 16L)
    validate(need(!is.na(l) && !is.na(h) && l <= 255 && h <= 255, "Introduzca dos bytes hexadecimales (00–FF)."))
    v <- h * 256 + l; if (v >= 32768) v <- v - 65536
    tc <- v * 0.0625
    resultado(celda(v, "Entero con signo"), celda(paste(fmt(tc, 4), "°C"), "Temperatura", if (tc > 60) "mal" else "ok"),
              celda(if (tc > 60) "Bloqueo / reducción" else "Normal", "Reacción de la Jetson (> 60 °C)", if (tc > 60) "mal" else "ok"))
  })
  output$c4_nec_res <- renderUI({
    d <- input$c4_nec_dir %% 256; c <- input$c4_nec_cmd %% 256
    bytes <- c(d, 255 - d, c, 255 - c)
    bits <- unlist(lapply(bytes, function(b) as.integer(intToBits(b))[1:8]))
    dur <- 9 + 4.5 + sum(ifelse(bits == 1, 0.562 + 1.687, 0.562 + 0.562)) + 0.562
    resultado(celda(paste(sprintf("%02X", bytes), collapse = " "), "Bytes transmitidos"),
              celda(sum(bits), "Unos en los 32 bits"), celda(paste(fmt(dur, 2), "ms"), "Duración de la trama"))
  })
  output$c4_md22_res <- renderUI({
    u <- input$c4_md22_u; r <- md22_registro(u)
    firm <- if (u == 0 || (u >= 40 && u <= 100)) "Aceptado por el firmware vigente" else if (u < 0) "ERR:RANGE (el firmware vigente no usa reversa)" else "ERR:RANGE (no vence la fricción de arranque)"
    resultado(celda(r, "Registro (decimal)"), celda(sprintf("0x%02X", r), "Registro (hex)"),
              celda(firm, "Firmware D.7: 0 o 40–100 %", if (startsWith(firm, "Acept")) "ok" else "mal"))
  })
  output$c4_md22_plot <- renderPlotly({
    u <- -100:100
    plot_ly() %>% add_lines(x = u, y = md22_registro(u), name = "r(u)", line = list(color = COL$azul, width = 2.5)) %>%
      add_markers(x = input$c4_md22_u, y = md22_registro(input$c4_md22_u), name = "Mando actual", marker = list(color = COL$ambar, size = 12)) %>%
      add_segments(x = 40, xend = 40, y = 0, yend = 255, name = "40 % mínimo", line = list(color = COL$rojo, dash = "dot")) %>%
      tema("Mando u (%)", "Registro del MD22")
  })
  output$c4_rc_plot <- renderPlotly({
    l <- 0.333; b <- 0.29; dg <- seq(1, 33, by = 0.5); rho <- l / tan(rad(dg)); r <- (rho - b / 2) / (rho + b / 2)
    plot_ly() %>% add_lines(x = c(-rev(dg), dg), y = c(rev(r), r), name = "Teórico (ρ − b/2)/(ρ + b/2)", line = list(color = COL$azul, width = 2.5)) %>%
      add_markers(x = c(-33, 33), y = c(0.549, 0.549), name = "Medido en 2008 (extremos de 33°)", marker = list(color = COL$ambar, size = 12, symbol = "diamond")) %>%
      add_markers(x = 0, y = 1.864 / 1.880, name = "0°: 1.864 / 1.880 ms (compensación entre motores)", marker = list(color = COL$verde, size = 11)) %>%
      tema("Ángulo de giro (°)", "v_int / v_ext")
  })
  output$c4_srv_res <- renderUI({
    th <- input$c4_srv; ks <- as.numeric(input$c4_srv_ks); dl <- (th - 90) / ks
    lado <- if (th > 90) "izquierda" else if (th < 90) "derecha" else "recto"
    resultado(celda(paste(fmt(servo_tp(th), 0), "µs"), "Ancho de pulso t<sub>p</sub>"),
              celda(paste0(fmt(dl, 1), "°"), "Ángulo de las ruedas δ = (θs − 90°)/ks"),
              celda(lado, "Sentido del giro (140° = izquierda máx.)"),
              celda(paste(fmt(abs(th - 90) / 60 * 0.14, 3), "s"), "Tiempo para llegar desde 90°"))
  })
  output$c4_srv_plot <- renderPlotly({
    tp <- servo_tp(input$c4_srv) / 1000; t <- seq(0, 60, by = 0.01); s <- ifelse((t %% 20) < tp, 1, 0)
    plot_ly() %>% add_lines(x = t, y = s, line = list(color = COL$azul, width = 2.5, shape = "hv"), name = "Señal de mando") %>%
      tema("Tiempo (ms)", "Pulso", leyenda = FALSE) %>%
      layout(yaxis = list(range = c(-0.1, 1.3), tickvals = c(0, 1)),
             annotations = list(list(x = 10, y = 1.2, text = paste0("t_p = ", fmt(tp, 3), " ms cada 20 ms (50 Hz)"), showarrow = FALSE)))
  })
  output$c4_isrv_res <- renderUI({
    I <- input$c4_ns * input$c4_is + input$c4_is2
    resultado(celda(paste(fmt(I, 2), "A"), "Corriente requerida"),
              celda(if (I <= 3) "Suficiente" else "Insuficiente", "Convertidor de 3 A", if (I <= 3) "ok" else "mal"))
  })
  output$c4_paso_res <- renderUI({
    pat <- c(0x01, 0x03, 0x02, 0x06, 0x04, 0x0C, 0x08, 0x09)[input$c4_paso]
    bits <- as.integer(intToBits(pat))[1:4]
    div(resultado(celda(sprintf("0x%02X", pat), "Patrón"), celda(paste(rev(bits), collapse = ""), "Bobinas D C B A")),
        div(style = "display:flex;gap:10px;margin-top:6px",
            lapply(1:4, function(k) div(style = paste0("width:60px;height:60px;border-radius:10px;display:flex;align-items:center;",
                                                      "justify-content:center;font-weight:700;color:#fff;background:",
                                                      if (bits[k] == 1) COL$ambar else "#C9D3DF"), LETTERS[k]))))
  })
}
