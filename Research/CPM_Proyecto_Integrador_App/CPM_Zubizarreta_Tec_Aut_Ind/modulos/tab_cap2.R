# =============================================================================
# Capítulo 2 — Marco teórico
# =============================================================================

ui_cap2 <- function() {
  tabItem(tabName = "cap2",
    fluidRow(
      caja("Capítulo 2: Marco teórico — Panorama",
        concepto(parrafo("Este capítulo reúne solo las ideas, ecuaciones y criterios de diseño que hacen falta para entender, revisar y
                 reparar la electrónica y el software del vehículo, ilustradas con sus componentes reales. El orden sigue el de la
                 carrera: electricidad y electrónica (módulos I y II), electrónica digital (III a V), comunicación serie y conversión
                 analógico-digital (VIII y X), y al final la cinemática, el seguimiento de trayectorias, la estimación y el gemelo
                 digital que sostienen la parte de robótica (módulo XIII). Los valores que aún no se han medido se usan como valores de
                 ejemplo señalados como tales."))
      )
    ),
    fluidRow(
      tabBox(width = 12, id = "c2_tabs",
        # ---------------------------------------------------------------- 2.1
        tabPanel("2.1 Electricidad",
          fluidRow(
            column(6,
              h4("2.1.1 Magnitudes, ley de Ohm y potencia"),
              parrafo("Las cuatro magnitudes básicas del módulo I aparecen en todas las piezas del robot: 12 V de la batería, 5 V en la
                       lógica del Arduino, del PIC y del MD22, 3.3 V en los pines de la Jetson; corrientes de varios amperes en los
                       motores y de miliamperes en las señales; y la potencia que se disipa como calor en reguladores y conductores."),
              ecuacion("$$V = IR,\\qquad P = VI = I^2R = \\frac{V^2}{R} \\qquad (2.1)$$"),
              concepto(titulo = "Calculadora: resistencia de un LED indicador",
                fluidRow(column(4, numericInput("c2_led_vs", "Fuente (V)", 5, 1, 24, 0.1)),
                         column(4, numericInput("c2_led_vf", "Vf del LED (V)", 2.0, 0.5, 4, 0.1)),
                         column(4, numericInput("c2_led_i", "Corriente (mA)", 10, 1, 30, 1))),
                uiOutput("c2_led_res"),
                p(class = "nota", "El PIC16F877A entrega hasta 25 mA por pin (Microchip Technology, 2003)."))
            ),
            column(6,
              h4("Consumo y autonomía"),
              ecuacion("$$t \\approx \\frac{0.5\\,C_{bat}}{I} \\qquad (2.2)$$",
                       "No conviene descargar una batería de plomo-ácido por debajo del 50 %."),
              fluidRow(column(4, numericInput("c2_aut_i", "Corriente total (A)", 3.0, 0.1, 20, 0.1)),
                       column(4, numericInput("c2_aut_c", "Capacidad (Ah)", 7, 1, 100, 0.5)),
                       column(4, sliderInput("c2_aut_dod", "Descarga útil (%)", 20, 80, 50, 5))),
              uiOutput("c2_aut_res"),
              h4("Tabla 2.1 — Estado de carga a circuito abierto"),
              tabla_simple(tabla_soc),
              h4("Fusible y calibre de cable"),
              fluidRow(column(4, numericInput("c2_cab_i", "Corriente (A)", 5, 0.1, 30, 0.5)),
                       column(4, numericInput("c2_cab_l", "Ida y vuelta (m)", 1, 0.1, 10, 0.1)),
                       column(4, selectInput("c2_cab_awg", "Calibre", c("18 AWG (21 mΩ/m)" = 0.021, "20 AWG (33 mΩ/m)" = 0.033,
                                                                     "22 AWG (53 mΩ/m)" = 0.053, "24 AWG (84 mΩ/m)" = 0.084)))),
              uiOutput("c2_cab_res")
            )
          ),
          hr(),
          fluidRow(
            column(6,
              h4("2.1.2 Divisor de voltaje para medir la batería"),
              ecuacion("$$V_{AN} = V_{bat}\\frac{R_2}{R_1+R_2} = \\frac{V_{bat}}{3},\\qquad I_{div}=\\frac{V_{bat}}{R_1+R_2}\\le\\frac{14.4\\,\\text{V}}{30\\,\\text{k}\\Omega} = 0.48\\,\\text{mA} \\qquad (2.3)$$"),
              ecuacion("$$V_{bat} = N_{ADC}\\,\\frac{V_{ref}}{1023}\\,\\frac{R_1+R_2}{R_2} = 3\\,N_{ADC}\\,\\frac{5}{1023} \\qquad (2.13)$$",
                       "Resolución de 4.89 mV en el pin, equivalente a ≈ 14.7 mV de batería."),
              sliderInput("c2_vbat", "Voltaje de la batería (V)", 10, 14.4, 12.6, 0.05, width = "100%"),
              uiOutput("c2_div_res")
            ),
            column(6, plotlyOutput("c2_div_plot", height = "330px"),
                   p(class = "nota", "Equivalente a la Figura 4.1(b): voltaje de batería estimado en función de las cuentas del ADC
                     con los umbrales de estado de carga."))
          ),
          hr(),
          fluidRow(
            column(6,
              h4("2.1.3 El motor de corriente directa"),
              ecuacion("$$V = IR_a + L_a\\frac{dI}{dt} + k_e\\,\\omega \\quad (2.4),\\qquad \\tau = k_t I \\quad (2.5),\\qquad I_{arr} = \\frac{V}{R_a} \\quad (2.6)$$"),
              parrafo("En régimen permanente y sin carga, ω ≈ V/kₑ: la velocidad depende del voltaje promedio, que es lo que el puente
                       H regula con PWM. Al arrancar, ω = 0 y la corriente queda limitada solo por la resistencia del devanado."),
              h4("2.1.4 Reactancia inductiva y frecuencia de PWM"),
              ecuacion("$$X_L = 2\\pi f L_a \\qquad (2.7)$$")
            ),
            column(6,
              concepto(titulo = "Calculadora: arranque y reactancia (valores de ejemplo)",
                fluidRow(column(3, numericInput("c2_m_v", "V (V)", 12, 1, 24, 0.5)),
                         column(3, numericInput("c2_m_ra", "Ra (Ω)", 2, 0.1, 50, 0.1)),
                         column(3, numericInput("c2_m_la", "La (mH)", 1, 0.01, 50, 0.1)),
                         column(3, numericInput("c2_m_f", "PWM (kHz)", 1, 0.1, 50, 0.1))),
                uiOutput("c2_m_res"),
                p(class = "nota", "Reglas de operación del firmware: usar la aceleración gradual del controlador y nunca invertir el
                  giro de golpe a velocidad máxima. El MD22 entrega hasta 5 A por canal (Devantech, s.f.)."))
            )
          )
        ),
        # ---------------------------------------------------------------- 2.2
        tabPanel("2.2 Potencia",
          fluidRow(
            column(6,
              h4("2.2.1 El puente H"),
              parrafo("Cuatro interruptores (MOSFET en el MD22) dispuestos alrededor del motor. Encender un par diagonal aplica la
                       batería en un sentido; el otro par, en el sentido contrario. Active los transistores para ver el resultado:"),
              fluidRow(column(3, checkboxInput("c2_q1", "Q1", TRUE)), column(3, checkboxInput("c2_q2", "Q2", FALSE)),
                       column(3, checkboxInput("c2_q3", "Q3", FALSE)), column(3, checkboxInput("c2_q4", "Q4", TRUE))),
              div(class = "svg-wrap", uiOutput("c2_hbridge")),
              p(class = "nota", "Al cambiar de sentido, el controlador apaga un par, espera un tiempo muerto de algunos cientos de
                nanosegundos y solo entonces enciende el otro. Los diodos de rueda libre dan camino a la corriente inductiva.")
            ),
            column(6,
              h4("Tabla 2.2 — Estados de un puente H"), tabla_simple(tabla_puente_h),
              h4("2.2.2 Regulación de voltaje"),
              fluidRow(column(3, numericInput("c2_r_vin", "Vin (V)", 12, 5, 24, 0.5)),
                       column(3, numericInput("c2_r_vout", "Vout (V)", 5, 1, 12, 0.1)),
                       column(3, numericInput("c2_r_i", "Iout (A)", 0.5, 0.05, 5, 0.05)),
                       column(3, numericInput("c2_r_eta", "η buck (%)", 90, 70, 98, 1))),
              uiOutput("c2_reg_res"),
              tabla_simple(tabla_reguladores)
            )
          ),
          hr(),
          fluidRow(
            column(6,
              h4("2.2.3 El convertidor reductor"),
              ecuacion("$$V_{out} = D\\,V_{in},\\qquad \\Delta I_L = \\frac{(V_{in}-V_{out})\\,D}{L\\,f_s},\\qquad \\Delta V_{out} \\approx \\frac{\\Delta I_L}{8 f_s C} \\qquad (2.8)$$"),
              fluidRow(column(4, numericInput("c2_b_vin", "Vin (V)", 12, 5, 30, 0.5)),
                       column(4, numericInput("c2_b_vout", "Vout (V)", 6, 1, 24, 0.1)),
                       column(4, numericInput("c2_b_fs", "fs (kHz)", 150, 10, 2000, 10))),
              fluidRow(column(6, numericInput("c2_b_l", "L (µH)", 33, 1, 1000, 1)),
                       column(6, numericInput("c2_b_c", "C (µF)", 220, 1, 5000, 10))),
              uiOutput("c2_buck_res")
            ),
            column(6,
              figura("img/fig3_2_diagrama.png", "<b>Figura 3.2 (detalle).</b> En el vehículo, un buck 12→6 V de 3 A alimenta los
                     servos y un buck 12→5 V de 5 A alimenta la Jetson.", ancho = "100%", alto = "420px"),
              h4("2.2.4 Oscilador de cristal"),
              ecuacion("$$T_{cy} = \\frac{4}{f_{osc}} = 1\\,\\mu\\text{s} \\qquad (2.9)$$",
                       "Con 4 MHz, un millón de instrucciones por segundo. El cristal de 32.768 kHz (= 2¹⁵) produce 1 Hz con quince divisiones entre dos.")
            )
          )
        ),
        # ---------------------------------------------------------------- 2.3
        tabPanel("2.3 Digital",
          fluidRow(
            column(6,
              h4("2.3.1 Lógica de habilitación segura"),
              parrafo("Antes de que los motores puedan moverse se deben cumplir tres condiciones: P = 1 cuando el paro de emergencia
                       está presionado, W = 1 cuando llegó un comando en los últimos 500 ms y B = 1 cuando la batería está por
                       arriba del mínimo."),
              ecuacion("$$EN = \\overline{P}\\cdot W\\cdot B \\qquad (2.10)$$"),
              fluidRow(column(4, checkboxInput("c2_en_p", "P: paro presionado", FALSE)),
                       column(4, checkboxInput("c2_en_w", "W: vigilante bien", TRUE)),
                       column(4, checkboxInput("c2_en_b", "B: batería ≥ mínimo", TRUE))),
              uiOutput("c2_en_res"),
              p(class = "nota", "El mapa de Karnaugh tiene un solo 1: una compuerta AND de tres entradas con P negada (en hardware, un
                74HC11 y un inversor). Las compuertas Q1 = EN·DIR y Q3 = EN·DIR̄ garantizan por construcción que no haya shoot-through.")
            ),
            column(6,
              h4("Tabla 2.4 — Mapa de Karnaugh de EN"), uiOutput("c2_kmap"),
              h4("2.3.2 Tabla 2.5 — Niveles lógicos"), tabla_simple(tabla_niveles),
              p(class = "nota", "Reglas: el Arduino habla con la Jetson por USB; el PIC sale por RS232 (MAX232) y llega a la Jetson
                mediante un adaptador USB-RS232, nunca a los pines UART del cabezal; el bus I²C entre Arduino y MD22 trabaja a 5 V.")
            )
          ),
          hr(),
          h4("2.3.3 Circuitos secuenciales y memorias — Tabla 2.6"),
          parrafo("Un latch 74HC573 copia el bus PORTD mientras LE está en alto y congela el último valor cuando baja. El contador de
                   16 bits del Timer1 puede contar pulsos de un encoder sin intervención del programa, y la EEPROM conserva
                   calibraciones al apagar el equipo (centro real del servo, constante ks, zona muerta y factor del divisor)."),
          tabla_simple(tabla_memorias)
        ),
        # ---------------------------------------------------------------- 2.4
        tabPanel("2.4 Comunicación serie",
          fluidRow(
            column(6,
              h4("2.4.1 Comunicación asíncrona (UART y RS232)"),
              parrafo("En una UART cada carácter se transmite como un bit de inicio, ocho de datos y uno de paro (8N1). Como no hay
                       reloj compartido, emisor y receptor deben coincidir en la velocidad. En el PIC16F877A con BRGH = 1:"),
              ecuacion("$$B = \\frac{f_{osc}}{16\\,(SPBRG+1)},\\qquad \\varepsilon_B = \\frac{B - B_{deseada}}{B_{deseada}}\\times 100\\,\\% \\qquad (2.11)$$",
                       "Un receptor tolera en la práctica un error acumulado del orden de 2 %; un error ε<sub>B</sub> desplaza el muestreo del bit de paro en 9.5 ε<sub>B</sub> periodos de bit."),
              fluidRow(column(6, selectInput("c2_u_f", "Cristal del PIC", c("4 MHz (BK300)" = 4e6, "8 MHz" = 8e6,
                                                                          "10 MHz" = 10e6, "16 MHz" = 16e6, "20 MHz" = 20e6))),
                       column(6, radioButtons("c2_u_brgh", "BRGH", c("1 (alta velocidad)" = 1, "0" = 0), inline = TRUE))),
              DTOutput("c2_u_tabla"),
              ecuacion("$$CS = c_1 \\oplus c_2 \\oplus \\cdots \\oplus c_n \\qquad (2.12)$$",
                       "Suma de verificación XOR del protocolo del nodo de sensores; detecta cualquier error de un solo bit.")
            ),
            column(6, plotlyOutput("c2_u_plot", height = "330px"),
                   p(class = "nota", "Equivalente a la Figura 4.1(a): magnitud del error de velocidad del PIC frente a un ATmega a
                     16 MHz con U2X = 1. La línea punteada marca la tolerancia típica de 2 %."),
                   h4("2.4.2 Bus I²C y resistencias de pull-up"),
                   parrafo("START → (dirección₇ ∥ W) → ACK → registro → ACK → dato → ACK → STOP. A 100 kHz cada bit dura 10 µs y una
                            escritura de tres bytes al MD22 ocupa unos 0.3 ms. El MD22 documenta su dirección en 8 bits (0xB0) y la
                            librería Wire espera 7 bits (0x58): ambas designan al mismo dispositivo."),
                   ecuacion("$$R_{p,min} = \\frac{V_{DD}-V_{OL,max}}{I_{OL}},\\qquad R_{p,max} = \\frac{t_r}{0.8473\\,C_b} \\qquad (2.17)$$"),
                   fluidRow(column(4, numericInput("c2_i2c_vdd", "VDD (V)", 5, 3, 5.5, 0.1)),
                            column(4, numericInput("c2_i2c_cb", "Cb (pF)", 200, 10, 400, 10)),
                            column(4, selectInput("c2_i2c_modo", "Modo", c("Estándar 100 kHz (tr ≤ 1000 ns)" = 1000,
                                                                         "Rápido 400 kHz (tr ≤ 300 ns)" = 300)))),
                   uiOutput("c2_i2c_res"))
          )
        ),
        # ---------------------------------------------------------------- 2.5/2.6
        tabPanel("2.5–2.6 ADC, PWM y sensores",
          fluidRow(
            column(6,
              h4("2.5 Modulación por ancho de pulso"),
              ecuacion("$$\\bar V = D\\,V_{bat},\\qquad D = t_{on}/T \\qquad (2.14)$$",
                       "En un motor importa el promedio; en un servomotor importa la duración absoluta del pulso, entre 1 y 2 ms cada 20 ms (50 Hz)."),
              sliderInput("c2_pwm_d", "Ciclo de trabajo D (%)", 0, 100, 60, 1, width = "100%"),
              plotlyOutput("c2_pwm_plot", height = "230px")
            ),
            column(6,
              h4("2.6.1 Codificadores ópticos incrementales"),
              ecuacion("$$v_{frec} = \\frac{N\\,\\Delta s}{T_w},\\quad \\delta v_{frec} = \\frac{\\Delta s}{T_w};\\qquad v_{per} = \\frac{\\Delta s}{T_p} \\qquad (2.15)$$"),
              fluidRow(column(3, numericInput("c2_enc_r", "r (mm)", 52.5, 10, 200, 0.5)),
                       column(3, numericInput("c2_enc_n", "Ranuras", 400, 10, 4096, 10)),
                       column(3, numericInput("c2_enc_kg", "kg", 0.625, 0.05, 10, 0.005)),
                       column(3, numericInput("c2_enc_tw", "Tw (ms)", 200, 10, 1000, 10))),
              uiOutput("c2_enc_res"),
              h4("2.6.2 Filtro RC"),
              ecuacion("$$f_c = \\frac{1}{2\\pi RC} \\qquad (2.16)$$",
                       "En el divisor de la batería, R₁∥R₂ = 6.67 kΩ con 100 nF da f<sub>c</sub> ≈ 239 Hz."),
              fluidRow(column(6, numericInput("c2_rc_r", "R (kΩ)", 6.67, 0.01, 1000, 0.01)),
                       column(6, numericInput("c2_rc_c", "C (nF)", 100, 0.1, 100000, 1))),
              uiOutput("c2_rc_res")
            )
          )
        ),
        # ---------------------------------------------------------------- 2.7
        tabPanel("2.7 Cinemática Ackermann",
          fluidRow(
            column(5,
              parrafo("La dirección Ackermann orienta las dos ruedas delanteras de modo que sus ejes se crucen en un mismo centro
                       instantáneo de rotación sobre la prolongación del eje trasero. Para planear trayectorias basta el modelo de
                       bicicleta cinemático (Rajamani, 2012), con el punto de referencia en el centro del eje trasero:"),
              ecuacion("$$\\dot x = v\\sin\\psi,\\qquad \\dot z = v\\cos\\psi,\\qquad \\dot\\psi = \\frac{v}{\\ell}\\tan\\delta \\qquad (2.18)$$"),
              ecuacion("$$\\delta = \\arctan(\\ell\\,\\kappa),\\qquad \\kappa = \\frac{1}{\\rho} \\qquad (2.19)$$"),
              ecuacion("$$v_{int} = v\\left(1-\\frac{b}{2\\rho}\\right),\\qquad v_{ext} = v\\left(1+\\frac{b}{2\\rho}\\right) \\qquad (2.20)$$",
                       "Diferencial electrónico: en el radio mínimo la diferencia teórica es de ±30 %; en el software se escala por λ."),
              ecuacion("$$\\kappa(A,B,C) = \\frac{4\\,\\mathcal{A}(A,B,C)}{|AB|\\,|BC|\\,|CA|},\\qquad \\mathcal{A} = \\tfrac12\\,(B-A)\\times(C-A) \\qquad (2.21)$$",
                       "Curvatura discreta de Menger: la del círculo que pasa por tres puntos consecutivos; el signo del producto cruz indica izquierda o derecha."),
              fluidRow(column(6, sliderInput("c2_ack_l", "Distancia entre ejes ℓ (m)", 0.25, 0.45, 0.34, 0.001)),
                       column(6, sliderInput("c2_ack_b", "Vía b (m)", 0.20, 0.40, 0.30, 0.005))),
              sliderInput("c2_ack_rho", "Radio mínimo ρmin (m)", 0.3, 1.0, 0.5, 0.01),
              uiOutput("c2_ack_res")
            ),
            column(7, plotlyOutput("c2_ack_delta", height = "280px"), plotlyOutput("c2_ack_dif", height = "280px"),
                   p(class = "nota", "Equivalente a la Figura 7.1: (a) ángulo de dirección contra radio de giro; (b) razones de
                     velocidad de las ruedas exterior e interior para los factores λ disponibles."))
          )
        ),
        # ---------------------------------------------------------------- 2.8
        tabPanel("2.8 Seguimiento",
          fluidRow(
            column(6,
              parrafo("Los métodos geométricos de seguimiento calculan el ángulo de dirección a partir de la posición del vehículo
                       respecto a la trayectoria, sin un modelo dinámico detallado, lo que los hace adecuados para vehículos lentos."),
              ecuacion("$$\\kappa_{pp} = \\frac{2\\sin\\alpha}{d_{la}},\\qquad \\delta_{pp} = \\arctan\\left(\\frac{2\\ell\\sin\\alpha}{d_{la}}\\right) \\qquad (2.22)$$",
                       "Persecución pura (Coulter, 1992): α es el ángulo entre el rumbo y la línea al punto objetivo a la distancia de anticipación d<sub>la</sub>."),
              ecuacion("$$\\delta_{St} = e_\\psi + \\arctan\\left(\\frac{k_{St}\\,e_{ct}}{v}\\right) \\qquad (2.23)$$",
                       "Método de Stanley (Snider, 2009): combina el error de rumbo y el error transversal medidos desde el eje delantero."),
              ecuacion("$$e_{ct} = \\frac{|(p-a)\\times(b-a)|}{\\lVert b-a\\rVert} \\qquad (2.24)$$",
                       "Error transversal respecto al segmento entre los puntos de paso a y b. El error de rumbo e<sub>ψ</sub> se normaliza a (−π, π]."),
              parrafo("Snider (2009) muestra que la persecución pura es robusta a velocidades bajas pero corta las curvas cuando d_la es
                       grande, y que Stanley sigue mejor la trayectoria a costa de mayor sensibilidad al ruido de la pose. El
                       generador de esta tesis usa la curvatura de la propia trayectoria como alimentación directa.")
            ),
            column(6,
              concepto(titulo = "Interactivo: persecución pura frente a d_la",
                sliderInput("c2_pp_dla", "Distancia de anticipación d_la (m)", 0.1, 1.2, 0.4, 0.05),
                sliderInput("c2_pp_alfa", "Ángulo al objetivo α (°)", -60, 60, 20, 1),
                uiOutput("c2_pp_res"), plotlyOutput("c2_pp_plot", height = "260px"))
            )
          )
        ),
        # ---------------------------------------------------------------- 2.9
        tabPanel("2.9 Filtro de Kalman",
          fluidRow(
            column(5,
              parrafo("Las mediciones de pose llegan con ruido. El filtro de Kalman calcula, de forma recursiva, el estimado de mínima
                       varianza de un estado lineal con ruido gaussiano (Kalman, 1960). En su forma escalar con modelo de estado
                       constante (Welch y Bishop, 1995):"),
              ecuacion("$$\\hat x_k^- = \\hat x_{k-1},\\qquad P_k^- = P_{k-1} + \\sigma_q^2 \\qquad (2.25)$$"),
              ecuacion("$$K_k = \\frac{P_k^-}{P_k^- + \\sigma_r^2},\\qquad \\hat x_k = \\hat x_k^- + K_k(z_k - \\hat x_k^-),\\qquad P_k = (1-K_k)P_k^- \\qquad (2.26)$$"),
              ecuacion("$$\\psi = \\operatorname{atan2}\\big(2(q_wq_y + q_xq_z),\\,1 - 2(q_x^2+q_y^2)\\big) \\qquad (2.27)$$",
                       "El rumbo se obtiene de la guiñada del cuaternión del control, y se desenvuelve antes de filtrar."),
              fluidRow(column(6, numericInput("c2_k_sq", "σq² (proceso)", 0.01, 0.0001, 1, 0.001)),
                       column(6, numericInput("c2_k_sr", "σr² (medición)", 0.10, 0.0001, 10, 0.01))),
              uiOutput("c2_k_res"),
              p(class = "nota", "El cociente σq²/σr² fija el compromiso entre suavidad y retardo.")
            ),
            column(7, plotlyOutput("c2_k_plot", height = "360px"),
                   aviso_sim("Señal sintética: un escalón y una rampa con ruido gaussiano, filtrados a 72 actualizaciones por segundo."))
          )
        ),
        # ---------------------------------------------------------------- 2.10–2.12
        tabPanel("2.10–2.12 Gemelo digital y trabajos",
          fluidRow(
            column(6,
              h4("2.10 Gemelo digital y Realidad Aumentada"),
              parrafo("Grieves y Vickers (2017) definen el gemelo digital como un conjunto de construcciones de información virtual que
                       describen completamente un producto físico y que se mantienen vinculadas con su contraparte real durante su ciclo
                       de vida. Distinguen el prototipo digital, la instancia digital y el entorno en el que ambos se comparan. En esta
                       tesis el gemelo cumple esas tres funciones: el modelo 3D precede al vehículo, su pose se vincula a la del vehículo
                       real mediante el control del visor, y la comparación entre trayectoria planeada y ejecutada se hace en el mismo
                       espacio."),
              parrafo("La WebXR Device API permite a una página solicitar una sesión immersive-ar, obtener en cada cuadro la pose del
                       visor y de los controles en un espacio de referencia común y dibujar sobre la imagen de las cámaras (W3C, 2026);
                       three.js ofrece la escena y el ciclo de dibujo sobre WebGL. La sesión inmersiva solo se concede a páginas servidas
                       en un contexto seguro (HTTPS) y tras una acción del usuario.")
            ),
            column(6,
              h4("2.12 Trabajos relacionados"),
              tags$ul(class = "description-text",
                tags$li(strong("Seguimiento geométrico:"), " Coulter (1992) documentó la persecución pura en Carnegie Mellon; Snider (2009)
                        comparó persecución pura, Stanley y controladores basados en modelo; Rajamani (2012) sistematiza el modelo de
                        bicicleta, válido holgadamente a las velocidades de 0.08 a 0.20 m/s del vehículo."),
                tags$li(strong("Estimación:"), " Kalman (1960) y Welch y Bishop (1995) son la base de la mayoría de los estimadores de pose
                        en robótica móvil."),
                tags$li(strong("Gemelo digital y RA en la web:"), " Grieves y Vickers (2017); WebXR estandarizada por el W3C (2026).")),
              concepto(titulo = "La brecha que atiende la tesis", tipo = "ambar",
                p("No está en ninguno de esos métodos por separado, sino en su integración didáctica de bajo costo: un mismo vehículo
                  que se construye siguiendo la secuencia de una carrera técnica, desde un PIC a 4 MHz hasta una computadora de borde,
                  y que usa un visor comercial a la vez como interfaz de operación, como gemelo digital y como sistema de medición de pose."))
            )
          )
        )
      )
    )
  )
}

server_cap2 <- function(input, output, session) {
  # ---- LED
  output$c2_led_res <- renderUI({
    vs <- input$c2_led_vs; vf <- input$c2_led_vf; i <- input$c2_led_i / 1000
    req(vs, vf, i, vs > vf, i > 0)
    R <- (vs - vf) / i; Rc <- valor_comercial(R); ir <- (vs - vf) / Rc; P <- ir^2 * Rc
    resultado(celda(fmt_ohm(R), "R calculada"), celda(fmt_ohm(Rc), "Valor comercial E12"),
              celda(paste(fmt(ir * 1000, 1), "mA"), "Corriente real", if (ir * 1000 > 25) "mal" else "ok"),
              celda(paste(fmt(P * 1000, 0), "mW"), "Disipación", if (P > 0.25) "mal" else "ok"))
  })
  output$c2_aut_res <- renderUI({
    req(input$c2_aut_i > 0)
    t <- input$c2_aut_dod / 100 * input$c2_aut_c / input$c2_aut_i
    resultado(celda(paste(fmt(input$c2_aut_dod / 100 * input$c2_aut_c, 1), "Ah"), "Capacidad útil"),
              celda(paste(fmt(t, 2), "h"), "Autonomía estimada"),
              celda(paste(fmt(12 * input$c2_aut_i, 0), "W"), "Potencia a 12 V"))
  })
  output$c2_cab_res <- renderUI({
    r <- as.numeric(input$c2_cab_awg); dv <- input$c2_cab_i * r * input$c2_cab_l; p <- input$c2_cab_i^2 * r * input$c2_cab_l
    resultado(celda(paste(fmt(dv, 3), "V"), "Caída en el cable", if (dv > 0.2) "warn" else "ok"),
              celda(paste(fmt(p, 2), "W"), "Disipación"),
              celda("5–10 A", "Fusible de acción retardada recomendado"))
  })
  # ---- Divisor / ADC
  output$c2_div_res <- renderUI({
    v <- input$c2_vbat; van <- divisor_van(v); n <- adc_cuentas(van); vb <- adc_a_vbat(n)
    clase <- if (v >= 12.4) "ok" else if (v >= 11.9) "warn" else "mal"
    resultado(celda(paste(fmt(van, 3), "V"), "V<sub>AN</sub> en el pin RA5/AN4"), celda(n, "N<sub>ADC</sub> (cuentas)"),
              celda(paste(vbat_mv_entero(n), "mV"), "Vbat en aritmética entera, ec. (4.4)"),
              celda(paste(fmt(v / 30e3 * 1000, 3), "mA"), "Corriente del divisor"),
              celda(estado_carga(v), "Estado de carga (Tabla 2.1)", clase),
              celda(if (v < 11.8) "BLOQUEADO" else "Permitido", "Movimiento (umbral de 11.8 V)", if (v < 11.8) "mal" else "ok"))
  })
  output$c2_div_plot <- renderPlotly({
    n <- 0:1023; v <- adc_a_vbat(n); nn <- adc_cuentas(divisor_van(input$c2_vbat))
    plot_ly() %>%
      add_lines(x = n, y = v, name = "Vbat estimado", line = list(color = COL$azul, width = 2.5)) %>%
      add_markers(x = nn, y = adc_a_vbat(nn), name = "Lectura actual", marker = list(color = COL$ambar, size = 12)) %>%
      add_segments(x = 0, xend = 1023, y = 12.7, yend = 12.7, name = "12.7 V: 100 %", line = list(color = COL$verde, dash = "dot")) %>%
      add_segments(x = 0, xend = 1023, y = 12.2, yend = 12.2, name = "12.2 V: 50 %", line = list(color = COL$ambar, dash = "dot")) %>%
      add_segments(x = 0, xend = 1023, y = 11.8, yend = 11.8, name = "11.8 V: bloqueo", line = list(color = COL$rojo, dash = "dot")) %>%
      tema("Cuentas del ADC (10 bits)", "Vbat estimado (V)")
  })
  output$c2_m_res <- renderUI({
    req(input$c2_m_ra > 0)
    iarr <- input$c2_m_v / input$c2_m_ra; xl <- 2 * pi * input$c2_m_f * 1e3 * input$c2_m_la * 1e-3
    tau_e <- input$c2_m_la * 1e-3 / input$c2_m_ra
    resultado(celda(paste(fmt(iarr, 2), "A"), "Corriente de arranque", if (iarr > 5) "mal" else "ok"),
              celda(paste(fmt(xl, 2), "Ω"), "X<sub>L</sub> a la frecuencia del PWM"),
              celda(paste(fmt(tau_e * 1e3, 3), "ms"), "Constante eléctrica L<sub>a</sub>/R<sub>a</sub>"),
              celda(if (iarr > 5) "Excede 5 A del MD22" else "Dentro del límite del MD22", "Diagnóstico", if (iarr > 5) "mal" else "ok"))
  })
  # ---- Puente H
  output$c2_hbridge <- renderUI({
    q <- c(input$c2_q1, input$c2_q2, input$c2_q3, input$c2_q4)
    estado <- if ((q[1] && q[2]) || (q[3] && q[4])) "corto" else if (q[1] && q[4] && !q[2] && !q[3]) "adelante"
              else if (q[2] && q[3] && !q[1] && !q[4]) "reversa" else if (q[2] && q[4] && !q[1] && !q[3]) "freno"
              else if (!any(q)) "libre" else "indef"
    txt <- switch(estado, corto = "PROHIBIDO: corto directo de la batería (shoot-through)", adelante = "Gira hacia adelante (Q1 y Q4)",
                  reversa = "Gira en reversa (Q3 y Q2)", freno = "Freno: motor en corto por la parte baja", libre = "Libre: se detiene por fricción",
                  indef = "Combinación sin camino completo para la corriente")
    colq <- function(on) if (on) "#2E9D6A" else "#C9D3DF"
    flujo <- switch(estado, adelante = "<path d='M70,40 L70,95 L230,95 L230,150' stroke='#E8A317' stroke-width='4' fill='none' marker-end='url(#fl)'/>",
                    reversa = "<path d='M230,40 L230,95 L70,95 L70,150' stroke='#E8A317' stroke-width='4' fill='none' stroke-dasharray='8 5' marker-end='url(#fl)'/>",
                    corto = "<path d='M70,40 L70,150' stroke='#C0392B' stroke-width='6' fill='none'/>", "")
    fondo <- if (estado == "corto") "#FDECEA" else "#F7F9FC"
    HTML(sprintf("
<svg viewBox='0 0 300 210' width='100%%' style='max-width:380px' role='img' aria-label='Puente H'>
 <defs><marker id='fl' markerWidth='8' markerHeight='8' refX='5' refY='3' orient='auto'><path d='M0,0 L6,3 L0,6 z' fill='#E8A317'/></marker></defs>
 <rect x='5' y='5' width='290' height='200' rx='12' fill='%s' stroke='#DCE3EC'/>
 <text x='150' y='24' text-anchor='middle' font-size='12' fill='#1F2D3D'>+Vbat (12 V)</text>
 <line x1='40' y1='32' x2='260' y2='32' stroke='#1F2D3D' stroke-width='2'/>
 <line x1='40' y1='170' x2='260' y2='170' stroke='#1F2D3D' stroke-width='2'/>
 <text x='150' y='192' text-anchor='middle' font-size='12' fill='#1F2D3D'>GND</text>
 <rect x='52' y='42' width='36' height='34' rx='6' fill='%s'/><text x='70' y='64' text-anchor='middle' font-size='13' fill='#fff' font-weight='700'>Q1</text>
 <rect x='52' y='118' width='36' height='34' rx='6' fill='%s'/><text x='70' y='140' text-anchor='middle' font-size='13' fill='#fff' font-weight='700'>Q2</text>
 <rect x='212' y='42' width='36' height='34' rx='6' fill='%s'/><text x='230' y='64' text-anchor='middle' font-size='13' fill='#fff' font-weight='700'>Q3</text>
 <rect x='212' y='118' width='36' height='34' rx='6' fill='%s'/><text x='230' y='140' text-anchor='middle' font-size='13' fill='#fff' font-weight='700'>Q4</text>
 <line x1='70' y1='32' x2='70' y2='42' stroke='#1F2D3D'/><line x1='70' y1='76' x2='70' y2='118' stroke='#1F2D3D'/><line x1='70' y1='152' x2='70' y2='170' stroke='#1F2D3D'/>
 <line x1='230' y1='32' x2='230' y2='42' stroke='#1F2D3D'/><line x1='230' y1='76' x2='230' y2='118' stroke='#1F2D3D'/><line x1='230' y1='152' x2='230' y2='170' stroke='#1F2D3D'/>
 <line x1='70' y1='97' x2='128' y2='97' stroke='#1F2D3D'/><line x1='172' y1='97' x2='230' y2='97' stroke='#1F2D3D'/>
 <circle cx='150' cy='97' r='22' fill='#fff' stroke='#1D4E89' stroke-width='2.5'/><text x='150' y='103' text-anchor='middle' font-size='17' fill='#1D4E89' font-weight='700'>M</text>
 %s
</svg>", fondo, colq(q[1]), colq(q[2]), colq(q[3]), colq(q[4]), flujo)) |>
      tagList(div(style = "margin-top:6px", etiqueta(txt, if (estado == "corto") "mal" else if (estado %in% c("adelante", "reversa")) "ok" else "warn")))
  })
  output$c2_reg_res <- renderUI({
    vin <- input$c2_r_vin; vout <- input$c2_r_vout; i <- input$c2_r_i; eta <- input$c2_r_eta / 100
    req(vin > vout)
    p_lin <- (vin - vout) * i; eff_lin <- vout / vin; pout <- vout * i; p_buck <- pout / eta - pout
    resultado(celda(paste0(fmt(eff_lin * 100, 0), " %"), "Eficiencia lineal (Vout/Vin)"),
              celda(paste(fmt(p_lin, 2), "W"), "Calor en el regulador lineal", if (p_lin > 1) "mal" else "ok"),
              celda(paste(fmt(p_buck, 2), "W"), "Pérdidas del buck", "ok"),
              celda(paste(fmt(pout / eta / vin, 3), "A"), "Corriente de entrada del buck"))
  })
  output$c2_buck_res <- renderUI({
    req(input$c2_b_vin > input$c2_b_vout)
    b <- buck(input$c2_b_vin, input$c2_b_vout, input$c2_b_fs * 1e3, input$c2_b_l * 1e-6, input$c2_b_c * 1e-6)
    resultado(celda(fmt(b$D, 3), "Ciclo de trabajo D"), celda(paste(fmt(b$dIL, 3), "A"), "Rizo de corriente ΔI<sub>L</sub>"),
              celda(paste(fmt(b$dV * 1000, 2), "mV"), "Rizo de voltaje ΔV<sub>out</sub>"))
  })
  # ---- Lógica EN
  output$c2_en_res <- renderUI({
    en <- !input$c2_en_p && input$c2_en_w && input$c2_en_b
    resultado(celda(if (en) "EN = 1" else "EN = 0", if (en) "Motores habilitados" else "Motores bloqueados", if (en) "ok" else "mal"))
  })
  output$c2_kmap <- renderUI({
    P <- as.integer(input$c2_en_p); W <- as.integer(input$c2_en_w); B <- as.integer(input$c2_en_b)
    cols <- list(c(0, 0), c(0, 1), c(1, 1), c(1, 0))
    fila <- function(p) {
      tags$tr(tags$th(paste0("P = ", p)), lapply(cols, function(wb) {
        v <- as.integer(p == 0 && wb[1] == 1 && wb[2] == 1)
        act <- p == P && wb[1] == W && wb[2] == B
        tags$td(v, style = paste0("text-align:center;font-weight:700;padding:6px 14px;",
                                  if (act) "background:#E8A317;color:#fff;" else if (v == 1) "background:#DDF3E8;" else ""))
      }))
    }
    tags$table(class = "table table-bordered", style = "max-width:420px",
      tags$thead(tags$tr(tags$th(""), lapply(c("WB = 00", "WB = 01", "WB = 11", "WB = 10"), tags$th))),
      tags$tbody(fila(0), fila(1)))
  })
  # ---- UART
  tabla_uart <- reactive({
    f <- as.numeric(input$c2_u_f); brgh <- as.integer(input$c2_u_brgh)
    rates <- c(9600, 19200, 38400, 57600, 115200)
    do.call(rbind, lapply(rates, function(B) {
      r <- baud_pic(B, f, brgh); a <- baud_avr(B, 16e6)
      data.frame(`Velocidad deseada` = format(B, big.mark = " "), SPBRG = r$spbrg, `Velocidad real` = format(round(r$real), big.mark = " "),
                 `Error PIC (%)` = round(r$err, 2), `Desplazamiento del bit de paro (bits)` = round(9.5 * abs(r$err) / 100, 2),
                 `Error ATmega 16 MHz (%)` = round(a$err, 2), `¿Viable?` = ifelse(abs(r$err) <= 2, "Sí", "No"),
                 check.names = FALSE, stringsAsFactors = FALSE)
    }))
  })
  output$c2_u_tabla <- renderDT({
    tabla_simple(tabla_uart()) %>% DT::formatStyle("¿Viable?", color = DT::styleEqual(c("Sí", "No"), c("#1B6B47", "#C0392B")),
                                                    fontWeight = "bold")
  })
  output$c2_u_plot <- renderPlotly({
    d <- tabla_uart()
    x <- c("9.6k", "19.2k", "38.4k", "57.6k", "115.2k")
    plot_ly(x = factor(x, levels = x)) %>%
      add_bars(y = abs(d$`Error PIC (%)`), name = paste0("PIC16F877A, ", as.numeric(input$c2_u_f) / 1e6, " MHz"), marker = list(color = COL$azul)) %>%
      add_bars(y = abs(d$`Error ATmega 16 MHz (%)`), name = "ATmega, 16 MHz, U2X = 1", marker = list(color = COL$ambar)) %>%
      add_lines(x = factor(x, levels = x), y = rep(2, 5), name = "≈ 2 % tolerancia típica", line = list(color = COL$rojo, dash = "dot")) %>%
      tema("Velocidad nominal (baudios)", "|Error| (%)") %>% layout(barmode = "group")
  })
  output$c2_i2c_res <- renderUI({
    r <- pullup_i2c(vdd = input$c2_i2c_vdd, tr = as.numeric(input$c2_i2c_modo) * 1e-9, cb = input$c2_i2c_cb * 1e-12)
    ok47 <- 4700 >= r$rmin && 4700 <= r$rmax
    resultado(celda(fmt_ohm(r$rmin), "R<sub>p</sub> mínima"), celda(fmt_ohm(r$rmax), "R<sub>p</sub> máxima", if (r$rmax < r$rmin) "mal" else ""),
              celda(if (ok47) "Cumple" else "No cumple", "4.7 kΩ del diseño de circuito 2", if (ok47) "ok" else "mal"))
  })
  # ---- PWM
  output$c2_pwm_plot <- renderPlotly({
    D <- input$c2_pwm_d / 100; t <- seq(0, 3, by = 0.001); s <- ifelse((t %% 1) < D, 12, 0)
    plot_ly() %>% add_lines(x = t, y = s, name = "Señal PWM", line = list(color = COL$azul, shape = "hv")) %>%
      add_lines(x = c(0, 3), y = c(12 * D, 12 * D), name = paste0("V̄ = ", fmt(12 * D, 2), " V"), line = list(color = COL$ambar, width = 3, dash = "dash")) %>%
      tema("Tiempo (periodos)", "Voltaje (V)") %>% layout(yaxis = list(range = c(-1, 13.5)))
  })
  output$c2_enc_res <- renderUI({
    ds <- encoder_ds(input$c2_enc_r / 1000, input$c2_enc_n, input$c2_enc_kg); tw <- input$c2_enc_tw / 1000
    fenc <- input$c2_enc_n * 22 / 60
    resultado(celda(paste(fmt(ds * 1000, 2), "mm"), "Δs por pulso"), celda(paste(fmt(ds / tw * 1000, 1), "mm/s"), "Resolución δv (frecuencia)"),
              celda(paste(fmt(fenc, 0), "Hz"), "Pulsos a 22 rpm del motor"),
              celda(paste(fmt(0.19 / ds * tw, 0)), "Pulsos por ventana a 0.19 m/s"))
  })
  output$c2_rc_res <- renderUI({
    fc <- 1 / (2 * pi * input$c2_rc_r * 1e3 * input$c2_rc_c * 1e-9)
    resultado(celda(paste(fmt(fc, 1), "Hz"), "Frecuencia de corte f<sub>c</sub>"),
              celda(paste(fmt(1 / (2 * pi * fc) * 1000, 2), "ms"), "Constante de tiempo RC"))
  })
  # ---- Ackermann
  output$c2_ack_res <- renderUI({
    l <- input$c2_ack_l; rho <- input$c2_ack_rho; b <- input$c2_ack_b
    resultado(celda(paste0(fmt(deg(atan(l / rho)), 1), "°"), "δ<sub>max</sub> = arctan(ℓ/ρ<sub>min</sub>)"),
              celda(paste(fmt(1 / rho, 2), "m⁻¹"), "κ<sub>max</sub>"),
              celda(paste0("±", fmt(b / (2 * rho) * 100, 1), " %"), "Diferencial completo en ρ<sub>min</sub>"),
              celda(paste0("±", fmt(0.25 * b / (2 * rho) * 100, 1), " %"), "Con λ = 0.25"))
  })
  output$c2_ack_delta <- renderPlotly({
    rho <- seq(0.3, 3, by = 0.01); l <- input$c2_ack_l; rm <- input$c2_ack_rho
    plot_ly() %>% add_lines(x = rho, y = deg(atan(l / rho)), name = paste0("ℓ = ", l, " m"), line = list(color = COL$azul, width = 2.5)) %>%
      add_lines(x = rho, y = deg(atan(0.333 / rho)), name = "ℓ físico = 0.333 m", line = list(color = COL$gris, dash = "dot")) %>%
      add_segments(x = rm, xend = rm, y = 0, yend = 50, name = paste0("ρmin = ", rm, " m (δ = ", fmt(deg(atan(l / rm)), 1), "°)"),
                   line = list(color = COL$rojo, dash = "dash")) %>%
      tema("Radio de giro ρ (m)", "Ángulo de dirección δ (°)") %>% layout(title = list(text = "(a) δ contra ρ", x = 0.02, font = list(size = 14)))
  })
  output$c2_ack_dif <- renderPlotly({
    rho <- seq(input$c2_ack_rho, 3, by = 0.01); b <- input$c2_ack_b
    p <- plot_ly(); cols <- c(COL$marino, COL$azul2, COL$cian, COL$ambar); lams <- c(1, 0.75, 0.5, 0.25)
    for (k in seq_along(lams)) {
      d <- diferencial(rho, b, lams[k])
      p <- p %>% add_lines(x = rho, y = d$ext, name = paste0("λ = ", lams[k]), line = list(color = cols[k]), legendgroup = k) %>%
        add_lines(x = rho, y = d$int, showlegend = FALSE, line = list(color = cols[k], dash = "dash"), legendgroup = k)
    }
    p %>% tema("Radio de giro ρ (m)", "v_ext/v (continua) y v_int/v (discontinua)") %>%
      layout(title = list(text = "(b) Diferencial electrónico", x = 0.02, font = list(size = 14)))
  })
  # ---- Persecución pura
  output$c2_pp_res <- renderUI({
    a <- rad(input$c2_pp_alfa); d <- input$c2_pp_dla; k <- 2 * sin(a) / d; del <- atan(2 * 0.34 * sin(a) / d)
    resultado(celda(paste(fmt(k, 2), "m⁻¹"), "κ<sub>pp</sub>"), celda(paste(fmt(if (abs(k) > 1e-6) 1 / abs(k) else Inf, 2), "m"), "Radio del arco"),
              celda(paste0(fmt(deg(del), 1), "°"), "δ<sub>pp</sub>", if (abs(deg(del)) > 34.2) "mal" else "ok"))
  })
  output$c2_pp_plot <- renderPlotly({
    a <- rad(input$c2_pp_alfa); d <- input$c2_pp_dla; k <- 2 * sin(a) / d
    tx <- d * sin(a); tz <- d * cos(a)                                  # objetivo en el marco del vehículo (z adelante, x izquierda)
    arco <- if (abs(k) < 1e-6) cbind(0, seq(0, d, length.out = 50)) else {
      R <- 1 / k; th <- seq(0, 2 * a, length.out = 60); cbind(R * (1 - cos(th)), R * sin(th)) }
    plot_ly() %>% add_paths(x = -arco[, 1], y = arco[, 2], name = "Arco de persecución pura", line = list(color = COL$verde, width = 3)) %>%
      add_markers(x = -tx, y = tz, name = "Punto objetivo", marker = list(color = COL$rojo, size = 11)) %>%
      add_markers(x = 0, y = 0, name = "Vehículo", marker = list(color = COL$azul, size = 12, symbol = "triangle-up")) %>%
      tema("Lateral (m), derecha positiva", "Adelante (m)") %>% layout(xaxis = list(scaleanchor = "y"))
  })
  # ---- Kalman
  output$c2_k_res <- renderUI({
    k <- kalman_estacionario(input$c2_k_sq, input$c2_k_sr)
    resultado(celda(fmt(k$K, 3), "Ganancia K<sub>∞</sub>"), celda(fmt(k$Nt, 1), "N<sub>τ</sub> (muestras)"),
              celda(paste(fmt(k$t * 1000, 0), "ms"), "t<sub>τ</sub> a 72 Hz"))
  })
  output$c2_k_plot <- renderPlotly({
    set.seed(7); n <- 360; t <- (0:(n - 1)) / 72
    verdad <- ifelse(t < 1, 0, ifelse(t < 3, 0.10, 0.10 + 0.05 * (t - 3)))
    z <- verdad + rnorm(n, 0, 0.012)
    f <- kalman1(z[1]); est <- numeric(n)
    for (i in 1:n) { f <- kalman_paso(f, z[i], input$c2_k_sq, input$c2_k_sr); est[i] <- f$x }
    plot_ly(x = t) %>% add_markers(y = z * 100, name = "Medición", marker = list(color = "rgba(93,109,126,.45)", size = 4)) %>%
      add_lines(y = verdad * 100, name = "Valor real", line = list(color = COL$rojo, dash = "dash")) %>%
      add_lines(y = est * 100, name = "Estimado de Kalman", line = list(color = COL$azul, width = 3)) %>%
      tema("Tiempo (s)", "Posición (cm)")
  })
}
