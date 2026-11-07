# =============================================================================
# Inicio y Capítulo 1 — Introducción
# =============================================================================

ui_inicio <- function() {
  tabItem(tabName = "inicio",
    div(class = "portada",
      div(class = "inst", tags$img(src = "img/logo_cpm.png", alt = "CPM"),
          span("Colegio y Proyectos en Microelectrónica, S.C. · Técnico en Automatización Industrial")),
      h1("Integración progresiva de elementos de microelectrónica y robótica en un sistema de navegación autónoma con Realidad Aumentada"),
      div(class = "sub", "Proyecto integrador basado en el curso de la carrera de Técnico en Automatización Industrial"),
      div(class = "autor", "José Francisco Zubizarreta Rodríguez · Ciudad de México, 2026")
    ),
    div(class = "kpis",
      kpi("5", "Contribuciones de la tesis", "lightbulb"),
      kpi("13", "Módulos de la carrera integrados en el vehículo", "graduation-cap", "c2"),
      kpi("4", "Etapas: PIC → sensores y actuadores → Arduino → Jetson", "microchip", "c3"),
      kpi("5 Hz", "Ciclo del generador de comandos Ackermann", "stopwatch", "c4"),
      kpi("28/28", "Puntos de paso en la vuelta autónoma al M25 (0 a 7 cm)", "route", "c5"),
      kpi("1286", "Tramas aplicadas sin un solo error del Arduino", "check-double", "c6")
    ),
    fluidRow(
      caja("Resumen", ancho = 8,
        parrafo("Esta tesis presenta el desarrollo de un vehículo robótico de cuatro ruedas con dirección Ackermann, tracción por dos
                 motores de corriente directa y un brazo manipulador, que se opera y se observa desde unos lentes Meta Quest 3S mediante
                 una aplicación web de Realidad Aumentada. Sobre el piso real se proyecta un mapa del anillo periférico M25 de Londres de
                 4.2 m × 2.1 m y un gemelo digital del vehículo a escala 1:1, construido a partir de una malla de 10 318 triángulos. La
                 estructura mecánica proviene de un rediseño realizado por el autor en 2008 (dirección Ackermann de aluminio con un
                 servomotor Hitec HS-805BB, dos motorreductores Toshiba 12-14 y carcasa de fibra de vidrio), cuyas medidas físicas
                 (ℓ = 0.333 m, b = 0.29 m) se integran al gemelo digital; los soportes de la cámara frontal, de las pinzas y de la carcasa
                 se rediseñaron con geometría triangulada y se imprimieron en PLA con una Bambu Lab A1."),
        parrafo("El trabajo se estructura según los trece módulos de la carrera y responde a la pregunta de cómo integrar, de forma
                 progresiva y segura, microcontroladores y una computadora de borde para controlar el vehículo desde la Realidad
                 Aumentada y medir la diferencia entre la trayectoria planeada y la ejecutada. La integración extremo a extremo (visor,
                 Jetson, Arduino, puente H MD22 y servomotor) quedó validada: el robot ejecuta trayectorias dibujadas en Realidad
                 Aumentada y completó una vuelta autónoma al anillo M25 suavizado con desviación típica de 0 a 7 cm."),
        concepto(titulo = "Palabras clave",
          lapply(c("automatización industrial", "microcontroladores PIC", "Arduino", "NVIDIA Jetson", "dirección Ackermann",
                   "gemelo digital", "Realidad Aumentada", "WebXR", "filtro de Kalman", "impresión 3D",
                   "seguimiento de trayectorias"), etiqueta))
      ),
      caja("El vehículo", ancho = 4, estado = "info",
        figura("img/vehiculo_tres_cuartos.jpg", "<b>Figura 3.4(b).</b> Aspecto actual del vehículo robótico, con la carcasa de fibra de
               vidrio, el panel superior triangular, las franjas de advertencia y la cámara frontal sobre su soporte impreso."),
        figura("img/ra_gemelo_superpuesto.jpg", "<b>Figura 6.4(b).</b> El gemelo digital superpuesto al vehículo real y al mapa del M25,
               visto desde el visor.")
      )
    ),
    fluidRow(
      caja("Las cinco contribuciones", estado = "success",
        fluidRow(
          column(4, div(class = "contrib", div(class = "ico", icon("stairs")), h4("1. Ruta de integración en cuatro etapas"),
                        parrafo("Sistema PIC, sensores y actuadores, Arduino Nano y Mega, NVIDIA Jetson. Documenta los nueve
                                 experimentos de la placa BK300 y explica con cálculos por qué el PIC16F877A a 4 MHz no puede
                                 comunicarse a 115 200 baudios (error de 8.5 %) ni generar por hardware los 50 Hz de un servo
                                 (mínimo de 244 Hz)."))),
          column(4, div(class = "contrib", div(class = "ico", icon("layer-group")), h4("2. Arquitectura jerárquica de tiempo real"),
                        parrafo("Tres capas de paro independientes: interrupción del PIC, lógica de la Jetson y vigilancia de
                                 comandos del Arduino, diseñada con límite de 500 ms."))),
          column(4, div(class = "contrib", div(class = "ico", icon("vr-cardboard")), h4("3. Gemelo digital en RA"),
                        parrafo("Ocho modos de operación, panel de control proyectado y dos algoritmos de suavizado de
                                 trayectorias (ARC y SPLINE) que respetan el radio de giro.")))
        ),
        fluidRow(
          column(2),
          column(4, div(class = "contrib", div(class = "ico", icon("route")), h4("4. Generador Ackermann a 5 Hz"),
                        parrafo("Basado en la curvatura de Menger, con radio mínimo de giro de 0.50 m (δmax = 34.2°) y métricas
                                 de error de posición, transversal y de rumbo."))),
          column(4, div(class = "contrib", div(class = "ico", icon("crosshairs")), h4("5. Estimador de pose de bajo costo"),
                        parrafo("Usa el control del visor montado en el robot, filtrado de Kalman y una compuerta física que
                                 rechaza saltos mayores a 2.8 cm o 10.3° por muestra.")))
        )
      )
    ),
    fluidRow(
      caja("Cómo usar esta aplicación", estado = "warning", ancho = 12,
        fluidRow(
          column(6,
            tags$ul(class = "description-text",
              tags$li(strong("Capítulos 1 a 8:"), " el contenido de la tesis, con sus tablas, figuras y ecuaciones. Cada capítulo
                      incluye calculadoras interactivas construidas con las mismas ecuaciones del documento."),
              tags$li(strong("Plan de estudios CPM:"), " los trece módulos de la carrera y dónde aparece cada uno en el vehículo."),
              tags$li(strong("Laboratorio de seguimiento:"), " dibuje una trayectoria o use el anillo M25, suavícela con ARC o SPLINE,
                      genere las tramas ALL y simule el seguimiento con el estimador de pose."))),
          column(6,
            tags$ul(class = "description-text",
              tags$li(strong("Análisis de pruebas en R:"), " el módulo propuesto en la sección 6.6.1: lee el CSV de seguimiento y
                      produce la trayectoria planeada contra la ejecutada, el histograma del error transversal, el error contra la
                      curvatura y la clasificación de la Tabla 7.2."),
              tags$li(strong("Apéndices técnicos:"), " los modelos 3D de los soportes y los 36 listados de programas (PIC, Arduino,
                      Jetson y aplicación WebXR), con búsqueda y descarga, y los seis algoritmos de la tesis."),
              tags$li(strong("Bibliografía y anexos:"), " referencias en estilo Harvard, abreviaturas, nomenclatura, derivaciones y
                      archivos del proyecto."),
              tags$li(strong("Aviso:"), " las simulaciones están marcadas como tales; los resultados medidos que se citan provienen
                      de la tesis.")))
        )
      )
    )
  )
}

ui_cap1 <- function() {
  tabItem(tabName = "cap1",
    fluidRow(
      caja("Capítulo 1: Introducción — Panorama",
        concepto(parrafo("Este capítulo presenta la motivación del proyecto, formula el problema y la pregunta de investigación, enumera
                 las contribuciones, delimita el alcance y describe la organización del documento. El hilo conductor es la carrera de
                 Técnico en Automatización Industrial del plan de estudios CPM: el vehículo robótico se concibe como el proyecto
                 integrador en el que convergen sus trece módulos."))
      )
    ),
    fluidRow(
      caja("1.1 Motivación", ancho = 7,
        parrafo("La automatización industrial descansa sobre una cadena que va del componente eléctrico al sistema completo: una fuente
                 de energía alimenta actuadores, estos son gobernados por electrónica de potencia, la electrónica de potencia obedece a
                 un microcontrolador y el microcontrolador recibe órdenes de un nivel superior que planea y supervisa. Enseñar esa cadena
                 con ejemplos aislados (un LED, un motor, un sensor) deja al estudiante sin una visión de conjunto; enseñarla con un
                 sistema industrial real es costoso y riesgoso. Un vehículo robótico de escala reducida ocupa un punto intermedio: es lo
                 bastante complejo para exigir todos los niveles de la cadena y lo bastante pequeño para probarse en un laboratorio."),
        parrafo("Dos tendencias tecnológicas hacen especialmente oportuno este proyecto. La primera es el concepto de gemelo digital: una
                 representación virtual sincronizada con un objeto físico que permite anticipar y analizar su comportamiento (Grieves y
                 Vickers, 2017). La segunda es la disponibilidad de visores de Realidad Aumentada autónomos y de una interfaz estándar,
                 WebXR, que permite superponer contenido 3D sobre el mundo real desde un navegador web (W3C, 2026). Con ambos elementos,
                 el gemelo digital deja de ser una imagen en una pantalla y se convierte en un objeto que comparte el piso con el
                 vehículo real: se puede dibujar una trayectoria con la mano, ver al vehículo seguirla y medir la diferencia."),
        parrafo("Desde el punto de vista formativo, el proyecto obliga a recorrer la evolución tecnológica que enseña la carrera: de los
                 fundamentos eléctricos (Módulo I) a los microprocesadores de 8 y 16 bits (Módulos VI y XI), de los microcontroladores
                 (Módulo XII) a la robótica aplicada (Módulo XIII).")
      ),
      caja("Figura 1.1 — El gemelo digital", ancho = 5, estado = "info",
        figura("img/fig1_1_modelo3d.png", "<b>Figura 1.1.</b> Modelo 3D del vehículo robótico usado como gemelo digital, renderizado a
               partir de la malla STL del proyecto (10 318 triángulos, escala 200 unidades = 0.60 m). (a) Vista isométrica: carrocería,
               ruedas y brazo manipulador al frente. (b) Vista superior."),
        concepto(tipo = "gris", p(class = "nota", "Plataforma de cuatro ruedas con dirección tipo automóvil (Ackermann), tracción por
                 dos motores de corriente directa, un brazo manipulador articulado y una cámara frontal. El modelo se usa sin
                 modificaciones como gemelo digital en la Realidad Aumentada."))
      )
    ),
    fluidRow(
      caja("Figura 1.2 — Ruta de integración electrónica en cuatro etapas", estado = "primary",
        div(class = "base-ruta", "Fundamentos: electricidad (I), electrónica (II) y electrónica digital (III–V)"),
        div(class = "ruta",
          div(class = "etapa", div(class = "n", "ETAPA 1"), div(class = "t", "Sistema PIC"), div(class = "d", "PIC16F877A, BK300"),
              div(class = "m", "Módulos VI, VII, VIII, IX, XII")),
          div(class = "etapa", div(class = "n", "ETAPA 2"), div(class = "t", "Sensores y actuadores"), div(class = "d", "ADC, DS18B20, MD22, servos"),
              div(class = "m", "Módulos VIII, X, XIII")),
          div(class = "etapa", div(class = "n", "ETAPA 3"), div(class = "t", "Arduino Nano y Mega 2560"), div(class = "d", "Intérprete de comandos"),
              div(class = "m", "Módulo XII")),
          div(class = "etapa", div(class = "n", "ETAPA 4"), div(class = "t", "NVIDIA Jetson"), div(class = "d", "Integración, servidores, RA"),
              div(class = "m", "Módulos IX, XI, XIII"))
        ),
        p(class = "nota", "Cada etapa conserva lo aprendido en la anterior: el protocolo de comandos, por ejemplo, no cambia del Arduino
          Nano al Mega ni al nodo PIC.")
      )
    ),
    fluidRow(
      caja("1.2 Descripción del problema", ancho = 6, estado = "info",
        parrafo("Integrar un vehículo robótico controlado desde la Realidad Aumentada plantea tres dificultades que se refuerzan entre sí."),
        concepto(titulo = "Heterogeneidad de tiempos",
          p("Generar el pulso de un servomotor exige precisión de microsegundos; leer un sensor, de milisegundos; recalcular una
            trayectoria, de decenas de milisegundos; dibujar un cuadro de RA, alrededor de 14 ms. Ningún procesador por sí solo
            atiende bien todas esas escalas.")),
        concepto(titulo = "Riesgo de la integración prematura", tipo = "ambar",
          p("Durante semanas el puente H respondía en el bus I²C, pero los motores no se movían, porque se habían mezclado una
            dirección de 7 bits con una de 8 bits y un mapa de registros de otro controlador. Detectar errores así requiere probar
            cada componente por separado antes de integrarlo.")),
        concepto(titulo = "Falta de una medida objetiva del desempeño", tipo = "rojo",
          p("Sin retroalimentación de posición, la única evaluación posible de una trayectoria es visual. Para comparar lo planeado
            contra lo ejecutado se necesita una estimación de la pose suficientemente precisa, robusta a pérdidas de rastreo y barata."))
      ),
      caja("Pregunta de investigación", ancho = 6, estado = "warning",
        div(class = "pregunta", "¿Cómo integrar de forma progresiva y segura microcontroladores PIC, Arduino y una computadora de borde
            NVIDIA Jetson para controlar un vehículo robótico con dirección Ackermann desde un entorno de Realidad Aumentada, de modo
            que su gemelo digital permita planear trayectorias y medir objetivamente la diferencia entre lo planeado y lo ejecutado?"),
        br(),
        concepto(titulo = "Escalas de tiempo del sistema", plotlyOutput("c1_escalas", height = "250px"))
      )
    ),
    fluidRow(
      caja("1.3 Contribuciones", ancho = 7, estado = "success",
        tags$ol(class = "description-text",
          tags$li(strong("Ruta de integración electrónica progresiva."), " Frente a la práctica común de conectar directamente una
                  computadora de alto nivel con los actuadores, se propone y documenta una ruta en cuatro etapas que valida cada
                  nivel antes del siguiente (capítulos 4 y 5)."),
          tags$li(strong("Arquitectura jerárquica de tiempo real con seguridad redundante."), " Tres niveles de tiempo
                  (microcontroladores, computadora de borde y visor) y tres capas de paro independientes (capítulos 3 y 5)."),
          tags$li(strong("Gemelo digital en Realidad Aumentada a escala 1:1."), " El mapa y el modelo se anclan al piso detectado por
                  el visor y se operan con ocho modos desde un panel proyectado en el entorno (capítulo 6)."),
          tags$li(strong("Generación y seguimiento de trayectorias Ackermann con métricas."), " Generador de comandos a 5 Hz que respeta
                  el radio mínimo de giro, con tres métricas y criterios de aceptación; se compara con persecución pura (Coulter, 1992)
                  y Stanley (Snider, 2009) (capítulo 7)."),
          tags$li(strong("Estimación de pose de bajo costo."), " El control del propio visor, montado sobre el vehículo, como sensor de
                  posición y orientación, con filtro de Kalman escalar (Kalman, 1960; Welch y Bishop, 1995), desenvolvimiento de
                  ángulo y una compuerta derivada de los límites físicos del vehículo (capítulo 7)."))
      ),
      caja("1.4 Alcance", ancho = 5, estado = "danger",
        parrafo("El vehículo parte de una plataforma existente. En su diseño original de 2008 no llevaba microcontroladores a bordo: una
                 tarjeta de adquisición NI 6211, conectada a una portátil, generaba los pulsos del MD22 y del servomotor; la imagen se
                 procesaba en LabVIEW en una segunda computadora. En este proyecto se conservaron la estructura mecánica, la dirección,
                 los motorreductores, el servomotor y la carcasa, y se sustituyeron la electrónica, el control, los sensores y los
                 soportes."),
        concepto(tipo = "verde", titulo = "Cubre", p("Diseño, integración y validación funcional en interiores, sobre piso plano y dentro
                 del volumen rastreado por el visor (≈ 0.5 a 2.0 m del usuario).")),
        concepto(tipo = "rojo", titulo = "No cubre", p("Retroalimentación por encoders en lazo cerrado de velocidad, detección de
                 obstáculos a bordo, operación en exteriores con GPS ni coordinación de varios vehículos."))
      )
    ),
    fluidRow(
      caja("1.5 Estructura de la tesis", estado = "primary",
        tabla_simple(data.frame(Capítulo = c("2. Marco teórico", "3. Arquitectura del sistema y diseño mecánico",
                                             "4. Etapas 1 y 2: sistema PIC, sensores y actuadores", "5. Etapas 3 y 4: Arduino y NVIDIA Jetson",
                                             "6. Software, gemelo digital y entorno de RA",
                                             "7. Planeación, seguimiento de trayectorias y validación experimental",
                                             "8. Conclusiones y trabajo futuro"),
                                Contenido = c("Circuitos y máquinas eléctricas, electrónica de potencia y digital, comunicación serie, ADC, cinemática Ackermann, filtrado de Kalman y trabajos previos",
                                              "Jerarquía de tiempo real, hardware, energía, estructura mecánica de 2008, soportes impresos y modelo 3D",
                                              "Experimentación con el PIC16F877A y caracterización de sensores y actuadores (MD22, servos)",
                                              "Firmware de actuadores, protocolo de comandos, integración con la computadora de borde y seguridad",
                                              "Servidores, sesión WebXR, proyección del mapa, ocho modos, pruebas con el vehículo real, ARC y SPLINE, Kalman",
                                              "Generador de comandos, estimador de pose, pruebas realizadas y campaña cuantitativa",
                                              "Respuesta a la pregunta, contribuciones con su evidencia, limitaciones y trabajo futuro"),
                                check.names = FALSE, stringsAsFactors = FALSE))
      )
    )
  )
}

server_cap1 <- function(input, output, session) {
  output$c1_escalas <- renderPlotly({
    d <- data.frame(tarea = c("Pulso de servo (1–2 ms, precisión µs)", "Lectura de un sensor", "Cuadro de RA (72 Hz)",
                              "Recalcular trayectoria", "Ciclo del generador (5 Hz)"),
                    seg = c(1.5e-3, 5e-3, 13.9e-3, 30e-3, 0.2),
                    equipo = c("Arduino / PIC", "PIC", "Meta Quest 3S", "Jetson", "Jetson / visor"))
    d$tarea <- factor(d$tarea, levels = d$tarea)
    plot_ly(d, y = ~tarea, x = ~seg * 1000, type = "bar", orientation = "h", color = ~equipo,
            colors = c(COL$azul, COL$cian, COL$ambar, COL$verde, COL$violeta),
            text = ~paste0(equipo, ": ", signif(seg * 1000, 3), " ms"), hoverinfo = "text") %>%
      tema("Escala de tiempo (ms, logarítmica)", NULL) %>%
      layout(xaxis = list(type = "log"), margin = list(l = 230), legend = list(y = -0.35))
  })
}
