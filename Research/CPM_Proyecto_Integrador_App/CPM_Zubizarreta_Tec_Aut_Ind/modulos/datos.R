# =============================================================================
# datos.R — Tablas tomadas de la tesis
# "Integración progresiva de elementos de microelectrónica y robótica en un
#  sistema de navegación autónoma con Realidad Aumentada"
# José Francisco Zubizarreta Rodríguez — CPM, Ciudad de México, 2026
# Cada objeto indica la tabla o sección de origen.
# =============================================================================

df <- function(...) data.frame(..., stringsAsFactors = FALSE, check.names = FALSE)

# ---- Tabla 2.1: estado de carga de una batería de plomo-ácido de 12 V --------
tabla_soc <- df(
  `Voltaje en reposo` = c("≥ 12.7 V", "12.4 V", "12.2 V", "≤ 11.9 V"),
  `Carga aproximada`  = c("100 %", "≈ 75 %", "≈ 50 %", "< 25 %"),
  `Acción`            = c("Lista para pruebas", "Operación normal",
                          "Terminar la sesión y cargar",
                          "No usar: se acorta la vida de la batería")
)

# ---- Tabla 2.2: estados de un puente H -----------------------------------
tabla_puente_h <- df(
  Q1 = c("1", "0", "0", "0", "1"), Q2 = c("0", "1", "1", "0", "1"),
  Q3 = c("0", "1", "0", "0", "–"), Q4 = c("1", "0", "1", "0", "–"),
  Resultado = c("Gira hacia adelante", "Gira en reversa",
                "Freno: el motor queda en corto por la parte baja",
                "Libre: se detiene por fricción",
                "Prohibido: corto directo (shoot-through)")
)

# ---- Tabla 2.3: reguladores ----------------------------------------------
tabla_reguladores <- df(
  Tipo = c("Lineal", "Conmutado (buck)"),
  Ejemplo = c("LM7805", "LM2596 o equivalente"),
  Eficiencia = c("5/12 ≈ 42 %", "85–92 %"),
  `Calor disipado` = c("3.5 W, requiere disipador", "≈ 0.3–0.4 W")
)

# ---- Tabla 2.5: niveles lógicos -----------------------------------------
tabla_niveles <- df(
  Equipo = c("PIC16F877A, entrada TTL", "PIC16F877A, entrada Schmitt",
             "ATmega328P / ATmega2560", "Jetson Nano (cabezal de 40 pines)",
             "RS232 (salida del MAX232)"),
  `Alimentación` = c("5 V", "5 V", "5 V", "3.3 V", "±5 a ±15 V"),
  `Alto mínimo` = c("2.0 V", "4.0 V", "3.0 V", "≈ 2.0 V", "–"),
  `Bajo máximo` = c("0.8 V", "1.0 V", "1.5 V", "≈ 0.8 V", "–"),
  `¿Tolera 5 V?` = c("Sí", "Sí", "Sí", "No", "Solo en puerto RS232")
)

# ---- Tabla 2.6: memorias --------------------------------------------------
tabla_memorias <- df(
  Memoria = c("Flash (programa)", "RAM", "EEPROM interna", "EEPROM externa"),
  PIC16F877A = c("8 K palabras de 14 bits", "368 bytes", "256 bytes", "AT24C02 (256 B, I²C)"),
  ATmega328P = c("32 KB", "2 KB", "1 KB", "–"),
  ATmega2560 = c("256 KB", "8 KB", "4 KB", "–"),
  Uso = c("Firmware", "Variables y búferes", "Calibraciones", "Registro de eventos")
)

# ---- Tabla 2.7 + sección 5.7 + Tabla 8.2: los trece módulos --------------
modulos_cpm <- df(
  num = 1:13,
  romano = c("I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"),
  nombre = c("Fundamentos de la Electricidad", "Fundamentos de Electrónica",
             "Electrónica Digital I", "Electrónica Digital II", "Electrónica Digital III",
             "Microcomputadoras y Microprocesadores", "Ensamblador para el Z80",
             "Interfaces y Controladores", "Diseño de Microcomputadoras",
             "Interfaz Analógica (de Potencia)", "Microprocesadores de 16 bits",
             "Microcontroladores y Procesadores", "Robótica (Automatización)"),
  semanas = c(4, 4, 2, 4, 4, 4, 4, 10, 4, 4, 8, 8, 8),
  bloque = c("Fundamentos", "Fundamentos", "Electrónica digital", "Electrónica digital",
             "Electrónica digital", "Microcomputadoras", "Microcomputadoras",
             "Microcomputadoras", "Microcomputadoras", "Potencia y procesadores",
             "Potencia y procesadores", "Potencia y procesadores", "Robótica"),
  donde = c("Batería, consumo, fusible, calibre de cable, divisor, motor CD",
            "Puente H con MOSFET, diodos, reguladores, cristal, optoacopladores",
            "Lógica de habilitación segura EN = P̄·W·B",
            "Multiplexado del display y del ADC; niveles 3.3/5 V",
            "Latch 74HC573, contadores para encoder, EEPROM",
            "Arquitectura Harvard del PIC frente a Von Neumann del Z80",
            "Rutinas de retardo y manejo de bits; lectura del desensamblado",
            "UART/RS232, I²C, interrupciones, Timer0/1/2",
            "Diagramas de tiempo de I²C y servo; Linux en la Jetson",
            "ADC de 10 bits, PWM como D/A, control de motores",
            "CPU ARM de 64 bits y GPU de la Jetson como evolución",
            "PIC16F877A, ATmega328P y ATmega2560",
            "Vehículo completo: dirección, tracción, sensores, trayectorias"),
  capitulos = c("2, 3", "2, 4", "2, 5", "2, 3", "2, 4", "4", "4", "4, 5", "4, 5",
                "4", "5", "4, 5", "3, 6, 7"),
  evidencia = c("Divisor 20k/10k, fusible 7.5 A, potencia de 4.3 W por motor, presupuesto de 1.5 A",
                "MOSFET del MD22, 2N2222, 1N4007, ULN2003, convertidores buck, TVS, cristal",
                "Habilitación EN y su mapa de Karnaugh, XOR de tramas",
                "Multiplexor del ADC, 74HC14, MAX232, adaptador BSS138",
                "Latch 74HC573, temporizadores, contadores de codificador, EEPROM",
                "PIC16F877A frente al Z80",
                "Retardo de 1 ms, manejo de bits",
                "UART/RS232, USB, I²C, interrupciones, Timer0/1/2",
                "Diagramas de tiempo, watchdog, Linux en la Jetson",
                "ADC de 10 bits, PWM, HC-SR04, sistema motriz",
                "ARM Cortex-A57 de 64 bits, memoria virtual, GPU",
                "PIC16F877A, ATmega328P, ATmega2560",
                "Ackermann, diferencial, sensores, cuatro lazos de retroalimentación"),
  documenta = c("Ecs. (2.3), (4.5), (3.1); Fig. 5.4", "Ecs. (2.8), (5.4); Figs. 2.1, 5.2",
                "Ecs. (2.10), (5.2), (2.12)", "Tabla 2.5; Figs. 5.2, 5.5",
                "Tabla 2.6; ec. (3.5)", "Tabla 4.2", "Ec. (4.1); Listado C.2",
                "Ecs. (2.11), (4.2), (4.12); Fig. 2.3", "Figs. 4.2, 5.1, 6.1",
                "Ecs. (2.13), (2.14), (4.7); Fig. 4.3", "Sección 5.3", "Tablas 5.1, 4.5",
                "Figs. 5.7, 4.6; cap. 7"),
  parrafo = c(
    "Las magnitudes de este módulo gobiernan todo el diseño de conexión de circuito de potencia. La ley de Ohm dimensiona la resistencia de 1 kΩ del LED de encendido y la de 220 Ω del emisor infrarrojo del codificador; el divisor de 20 y 10 kΩ reduce los 12 V de la batería al rango del ADC; la potencia P = VI estima los 4.3 W de cada motorreductor Toshiba y el presupuesto de 1.5 A del sistema. El modelo del motor de corriente directa explica por qué la corriente de arranque dimensiona el fusible de 7.5 A, y la reactancia inductiva por qué el devanado suaviza la corriente del PWM del MD22.",
    "Los semiconductores del módulo están en cada diseño de conexión de circuito: los MOSFET de los dos puentes H del MD22, con sus diodos de rueda libre; los transistores 2N2222 que manejan el relevador y el zumbador del nodo PIC; el diodo 1N4007 de rueda libre de la bobina de K1; el arreglo Darlington ULN2003 del motor a pasos; el fototransistor del codificador; los convertidores reductores de 6 y 5 V; el diodo TVS que protege el bus de 12 V; el cristal de 4 MHz del PIC; y el optoacoplador propuesto para el cable del paro. Los SCR y TRIAC no se usan porque el vehículo es de corriente directa.",
    "El álgebra booleana define la función de habilitación EN = P̄·W·B y su ampliación con seis variables, que es el lazo de supervisión; su mapa de Karnaugh demuestra que es mínima. La misma lógica, con Q1 = EN·DIR y Q3 = EN·DIR̄, garantiza que un puente H no pueda cortocircuitar la batería. La suma de verificación XOR de las tramas del nodo PIC es otra operación booleana, aplicada byte a byte.",
    "Los bloques combinacionales MSI aparecen en el multiplexor analógico de ocho canales del ADC del PIC (bits CHS2:CHS0), en el multiplexado del display de siete segmentos, en el barrido del teclado matricial de la BK300 y en el disparador Schmitt 74HC14 que acondiciona los codificadores. La compatibilidad entre familias lógicas es central: el PIC y el Arduino trabajan a 5 V, la Jetson a 3.3 V sin tolerancia a 5 V y el enlace RS232 a ±10 V, lo que obliga al MAX232 y al adaptador BSS138.",
    "Los circuitos secuenciales están en el latch 74HC573 que retiene el patrón de los LEDs de la BK300, en los contadores Timer0, Timer1 y Timer2 del PIC y del ATmega2560, y en el conteo de pulsos de los codificadores en T1CKI. La Flash guarda el firmware, la RAM las variables, la EEPROM interna del PIC el centro del servo, la constante ks, la zona muerta y el factor del divisor, y la EEPROM externa AT24C02 queda disponible para un registro de eventos.",
    "Lo que en una microcomputadora de 8 bits requería CPU, ROM, RAM, PIO, SIO y CTC en tarjetas separadas, el PIC lo integra en un solo encapsulado de 40 pines. La arquitectura Harvard explica por qué casi todas sus instrucciones duran Tcy = 1 µs, y la organización en bancos de memoria explica errores típicos al programarlo.",
    "Las rutinas de retardo y de manejo de bits del PIC aplican las mismas ideas del ensamblador del Z80: cargar, operar, probar una bandera y saltar. El cálculo de 249 vueltas de un lazo de cuatro ciclos para obtener 1 ms es el tipo de análisis de tiempo por instrucción que enseña este módulo.",
    "Es el módulo con más presencia en el vehículo, como corresponde a sus diez semanas. Las interfaces serie son tres: UART/RS232 entre el PIC y la Jetson, USB entre el Arduino y la Jetson, e I²C entre el Arduino y el MD22. Las interrupciones atienden el paro en RB0/INT, los codificadores en INT0 e INT1 del Mega y el receptor infrarrojo en RB4. Los temporizadores generan la base de 5 Hz, el PWM y los pulsos de los servos por software.",
    "El análisis dinámico se aplica en los diagramas de tiempo del carácter RS232, de la escritura I²C, del pulso del servo y del ciclo completo de control. El análisis estático aparece en los presupuestos de corriente y de pines. Los periféricos y el sistema operativo se integran en la Jetson (Linux con servicios, permisos de grupo y reglas udev), y la confiabilidad se diseña con el watchdog del PIC y el vigilante de comunicación del Arduino.",
    "La conversión A/D está en el ADC de 10 bits que lee la batería con resolución de 14.7 mV y, propuesto, la corriente del ACS712; la conversión D/A de potencia es el PWM, cuyo voltaje promedio V̄ = D·Vbat fija la velocidad de los motores a través del MD22. El ultrasonido del temario corresponde al HC-SR04 propuesto, y el control de potencia a todo el sistema motriz.",
    "La evolución del módulo, del 8086 con segmentación al Pentium superescalar, desemboca en el procesador ARM Cortex-A57 de 64 bits y cuatro núcleos de la Jetson, con memoria virtual paginada, modo protegido, cachés y pipeline. La GPU de 128 núcleos es el siguiente paso de esa historia y queda disponible para visión con la cámara frontal.",
    "El vehículo usa tres microcontroladores del temario: el PIC16F877A como nodo de sensores, el ATmega328P del Arduino Nano para las pruebas rápidas y el ATmega2560 del Arduino Mega como controlador de actuadores. La explicación de por qué el PIC a 4 MHz no puede generar 115 200 baudios ni 50 Hz de PWM por hardware es el núcleo de este módulo.",
    "El módulo integrador es el vehículo completo: sensores (control del visor como sensor de pose, codificadores, DS18B20, divisor, receptor IR, LiDAR en evaluación), sistemas motrices (motorreductores Toshiba con engranes 40:25, servo HS-805BB con mecanismo Ackermann, pinzas) y diseño mecánico (chasis de aluminio, carcasa de fibra de vidrio y soportes impresos en 3D). La planeación de trayectorias, el diferencial electrónico y los cuatro lazos de retroalimentación son la aplicación de la automatización a un robot móvil.")
)

# ---- Tabla 3.1: requisitos -----------------------------------------------
tabla_requisitos <- df(
  `Id.` = paste0("R", 1:8),
  Requisito = c(
    "Operar el vehículo desde el visor en modo manual, con dirección y velocidad independientes",
    "Dibujar una trayectoria sobre el piso y ejecutarla de forma autónoma respetando ρmin = 0.50 m",
    "Mostrar el gemelo digital a escala 1:1 sobre un mapa proyectado en el piso",
    "Medir la pose del vehículo y calcular errores de posición, transversal y de rumbo",
    "Detener los motores ante paro de emergencia, pérdida de comandos o batería baja, sin depender de una sola capa",
    "Leer voltaje de batería y temperatura con un nodo de sensores independiente",
    "Registrar comandos y errores en archivos para su análisis posterior",
    "Usar componentes de bajo costo y herramientas abiertas, y documentar cada etapa con fines didácticos"),
  `Verificación` = c("Cap. 7", "Cap. 7", "Cap. 6", "Cap. 7", "Cap. 5", "Cap. 4, 5", "Cap. 6",
                     "Todo el documento")
)

# ---- Tabla 3.2: niveles de tiempo ----------------------------------------
tabla_niveles_tiempo <- df(
  Nivel = c("Tiempo real duro (microsegundos)", "Tiempo real suave (decenas de ms)",
            "Interacción (cuadros de 14 ms)"),
  Equipo = c("Arduino y PIC", "Jetson Nano", "Meta Quest 3S"),
  `Por qué ahí` = c(
    "Generar pulsos de servo de 1–2 ms, transacciones I²C, lectura del ADC y reacción a un paro de emergencia sin depender de un sistema operativo",
    "Calcular curvaturas, seguir trayectorias a 5 Hz, filtrar datos, atender dos microcontroladores y registrar archivos",
    "Dibujar el mundo virtual a ≥ 72 cuadros por segundo, leer los controles y rastrear la pose del vehículo")
)

# ---- Tabla 3.3: componentes de hardware ----------------------------------
tabla_hardware <- df(
  Componente = c("Meta Quest 3S", "NVIDIA Jetson Nano", "Arduino Nano", "Arduino Mega 2560",
                 "PIC16F877A en BK300", "Devantech MD22", "Motorreductores CD (2)",
                 "Servomotor S2", "Servomotor S1", "Cámara frontal", "Soportes impresos",
                 "Batería de plomo-ácido", "Marcador triangular"),
  `Función` = c("Interfaz de RA; su control izquierdo, montado en el robot, mide la pose",
                "Procesamiento central, servidores y registro",
                "Pruebas rápidas de actuadores (Etapa 3)",
                "Control de actuadores (versión vigente)",
                "Experimentación (Etapa 1) y nodo de sensores (Etapa 4)",
                "Etapa de potencia de los motores", "Tracción independiente",
                "Dirección Ackermann", "Canal auxiliar (pinzas frontales o cámara)",
                "Imagen desde el vehículo", "Cámara, pinzas y carcasa", "Energía de tracción",
                "Referencia visual de orientación"),
  `Datos clave` = c(
    "Modo passthrough a color; navegador con WebXR",
    "ARM Cortex-A57 de 4 núcleos a 1.43 GHz, GPU Maxwell de 128 núcleos, 4 GB LPDDR4, Ubuntu (JetPack); IP 192.168.100.10",
    "ATmega328P a 16 MHz, 32 KB Flash, 2 KB SRAM, 1 KB EEPROM",
    "ATmega2560 a 16 MHz, 256 KB Flash, 8 KB SRAM, 4 KB EEPROM, 4 UART; I²C en pines 20 y 21",
    "8 K palabras de Flash, 368 B de RAM, 256 B de EEPROM, cristal de 4 MHz",
    "2 canales de hasta 5 A, alimentación de motores hasta 24 V, control por I²C, dirección de 7 bits 0x58",
    "Toshiba 12-14: 18 kg·cm, 22 rpm a 24 V, 6–24 V, 0.18 A con carga (2008); hoy a 12 V",
    "Hitec HS-805BB, 24.7 kg·cm a 6 V, 0.14 s/60°; PWM de 50 Hz; 40° (derecha máx.), 90° (recto), 140° (izquierda máx.)",
    "PWM de 50 Hz, 40–140°; mueve las pinzas frontales (pin 8)",
    "Montada en el soporte impreso frontal; USB a la Jetson",
    "PLA, Bambu Lab A1 (sección 3.8)",
    "12 V, fusible retardado de 5–10 A",
    "10 × 20 cm, ápice al frente, a 25 cm del piso")
)

# ---- Tabla 3.4: etapas y cronología --------------------------------------
tabla_etapas <- df(
  Etapa = c("1. Sistema PIC", "2. Sensores y actuadores", "3. Arduino Nano y Mega",
            "4. NVIDIA Jetson", "Gemelo digital y RA", "Simulación y R"),
  Contenido = c("Placa BK300, PIC16F877A, MPLAB con HI-TECH PICC o XC8, PICkit 3; nueve experimentos registrados",
                "ADC, temperatura, IR; motores con MD22; servos; motor a pasos, relevador, zumbador",
                "Programas por actuador, intérprete de comandos, firmware consolidado",
                "Servidores, puente serie, trayectorias, registro; nodo PIC",
                "Modelo 3D, mapa, de seis a ocho modos, rastreo",
                "Isaac Sim, Flask, R Shiny, Plumber"),
  `Módulos` = c("VI–IX, XII", "VIII, X, XIII", "XII", "IX, XI, XIII", "XIII", "Apoyo"),
  Registro = c("Marzo 2026", "Enero y abril 2026", "Enero y abril 2026", "Enero a abril 2026",
               "Febrero a julio 2026", "Febrero 2026")
)
# Intervalos para el diagrama de Gantt (meses de 2026; los periodos con dos
# meses no contiguos se dibujan como dos barras)
gantt_etapas <- df(
  etapa = c("1. Sistema PIC", "2. Sensores y actuadores", "2. Sensores y actuadores",
            "3. Arduino Nano y Mega", "3. Arduino Nano y Mega", "4. NVIDIA Jetson",
            "Gemelo digital y RA", "Simulación y R"),
  inicio = as.Date(c("2026-03-01", "2026-01-01", "2026-04-01", "2026-01-01", "2026-04-01",
                     "2026-01-01", "2026-02-01", "2026-02-01")),
  fin = as.Date(c("2026-03-31", "2026-01-31", "2026-04-30", "2026-01-31", "2026-04-30",
                  "2026-04-30", "2026-07-31", "2026-02-28"))
)

# ---- Tabla 3.5: transiciones ---------------------------------------------
tabla_transiciones <- df(
  `Transición` = c("PIC → sensores y actuadores", "Sensores y actuadores → Arduino",
                   "Nano → Mega", "Arduino → Jetson"),
  `Qué la motivó` = c("Ya se dominaban puertos, temporizadores e interrupciones; faltaba mover cosas reales",
                      "Compilar y grabar el PIC era lento; el cristal de 4 MHz limitaba la velocidad serie y no permitía PWM de hardware a 50 Hz",
                      "Más pines, más memoria y cuatro puertos serie",
                      "Un microcontrolador no puede servir una página segura, calcular trayectorias y registrar datos a la vez"),
  `Qué se llevó a la siguiente etapa` = c("Configurar registros a mano hace evidente qué hace después cada librería",
                                          "Los mismos conceptos (I²C, PWM, UART) con librerías probadas y ciclo de prueba de segundos",
                                          "El protocolo de comandos se mantuvo igual",
                                          "Los microcontroladores conservan el tiempo real; la Jetson, el cálculo y la red")
)

# ---- Tabla 3.6: presupuesto de corriente ---------------------------------
tabla_presupuesto <- df(
  Consumidor = c("Motores (2)", "Servos (2)", "Jetson Nano", "Arduino, lógica del MD22 y BK300",
                 "Total desde la batería"),
  `Corriente típica` = c("0.36 A (medido en 2008)", "0.3 A a 6 V", "1.5–2 A a 5 V", "0.3 A a 5 V", "≈ 1.5 A"),
  Pico = c("Corriente de arranque medida y verificada", "2 A", "4 A", "0.5 A", "–")
)

# ---- Tabla 3.7 / 3.8 / 3.9: mecánica -------------------------------------
tabla_actuadores_2008 <- df(
  `Característica` = c("Par", "Alimentación", "Velocidad", "Corriente", "Cantidad"),
  `Servo HS-805BB (dirección)` = c("24.7 kg·cm (242 N·cm)", "6 V", "0.14 s por 60°", "–", "1"),
  `Motorreductor Toshiba 12-14 (tracción)` = c("18 kg·cm (176.4 N·cm) por motor", "6 a 24 V",
                                               "22 rpm máxima", "0.09 A sin carga; 0.18 A con carga",
                                               "2, uno por rueda trasera")
)
tabla_2008_vs_actual <- df(
  Subsistema = c("Chasis y dirección", "Servo de dirección", "Tracción", "Etapa de potencia", "Energía",
                 "Control", "Medición de pose", "Cámara del vehículo", "Sensores", "Soportes", "Carcasa"),
  `2008` = c("Mecanismo Ackermann de aluminio, ±33°", "Hitec HS-805BB",
             "2 motorreductores Toshiba 12-14, engranes 40:25",
             "Devantech MD22, mando por pulsos de 1–2 ms desde NI 6211",
             "4 baterías de 6 V en serie (24 V, 0.4 A máx.)", "LabVIEW en dos portátiles, red ad hoc",
             "Cámara web o videocámara cenital a 3.5 m", "–", "Codificadores ópticos de 400 ranuras",
             "Piezas de aluminio maquinadas", "Fibra de vidrio"),
  Actual = c("Se conserva", "Se conserva (canal S2)", "Se conserva",
             "Se conserva; mando por I²C desde el Arduino", "Batería de plomo-ácido de 12 V con fusible",
             "Arduino Mega, Jetson Nano y Meta Quest 3S", "Control del visor montado en el vehículo",
             "Cámara frontal en el soporte impreso F", "Nodo PIC (batería, DS18B20, IR); LiDAR en evaluación",
             "Soportes de PLA impresos en Bambu Lab A1", "Se conserva; franjas reflejantes y defensa frontal")
)
tabla_parametros <- df(
  `Parámetro` = c("Distancia entre ejes, ℓ", "Vía (centros de llanta), b", "Radio de rueda, r",
                  "Longitud de carcasa", "Masa", "Ángulo máximo de dirección", "Radio mínimo de giro, ρmin",
                  "Velocidad máxima", "Recorrido del servo S2"),
  `Físico (2008)` = c("0.333 m", "0.29 m", "0.0525 m", "–", "7 kg (2008)", "±33° (diseño ±35°)",
                      "≈ 0.51 m", "0.19 m/s a 24 V", "–"),
  `En el software` = c("0.34 m", "0.30 m", "–", "0.60 m", "–", "34.2°", "0.50 m", "0.20 m/s",
                       "40°–140°, centro 90°"),
  Uso = c("Ángulo Ackermann", "Diferencial electrónico", "Conversión rpm → m/s", "Escala del modelo STL",
          "Cálculo de par", "Saturación", "Saturación de curvatura", "Límite del generador",
          "Firmware (abril 2026)")
)

# ---- Tablas 3.10 a 3.13: impresión 3D ------------------------------------
tabla_bambu <- df(
  `Característica` = c("Tecnología", "Volumen de construcción", "Boquilla", "Temperaturas",
                       "Velocidad y aceleración", "Materiales recomendados", "Multimaterial",
                       "Calibración", "Conectividad", "Interfaz y programa"),
  Valor = c("Extrusión de filamento fundido de 1.75 mm, cinemática de cama móvil en Y",
            "256 × 256 × 256 mm", "0.4 mm de serie, con cambio rápido del conjunto de la boquilla",
            "Extrusor hasta 300 °C; cama caliente hasta 100 °C", "Hasta 500 mm/s y 10 000 mm/s²",
            "PLA, PETG, TPU y PVA; no recomendada para ABS, ASA ni materiales con fibra",
            "AMS Lite: cuatro carretes con cambio automático de filamento",
            "Nivelación automática de la cama y calibración automática del flujo",
            "Wi-Fi, nube de Bambu Lab, modo LAN (MQTT sobre TLS, puerto 8883) y tarjeta microSD",
            "Pantalla táctil; laminador Bambu Studio, que genera archivos .gcode.3mf")
)
tabla_piezas <- df(
  Pieza = c("A. Marco trapezoidal", "B. Soporte torii", "C. Ménsula en Z", "D. Barra de carga reticulada",
            "E. Ménsula con tubo y bosses", "F. Soporte trapezoidal frontal"),
  `Envolvente (mm)` = c("100 × 76 × 12", "180 × 115 × 14", "45 × 50 × 34", "180 × 100 × 25.4",
                        "33 × 44 × 8", "90 × 50.8 × 76.2"),
  Masa = c("≈ 43 g", "≈ 110 g", "≈ 14 g", "≈ 171 g", "≈ 6 g", "Pesada tras imprimir"),
  `Función de diseño` = c(
    "Ménsula triangulada con dos barrenos de 4 mm en la base y un alojamiento axial de 7 mm",
    "Arco transversal principal para 3 kg, con ventana de 90 × 20 mm, dos costillas y siete barrenos",
    "Sujeta la parte trasera de un servo; ala inclinada 3°",
    "Viga de celdas tetraédricas para 3 kg fijada a madera",
    "Cuña con barra, tubo de 6/3 mm y dos bosses con barreno de 5 mm",
    "Caja trapezoidal con cavidad pasante de atrás hacia adelante, repisa frontal con cartela y poste con barreno"),
  `Uso en el vehículo` = c("Mástil de la cámara frontal", "Soporte de carcasa", "Servo de las pinzas",
                           "Soporte de carcasa", "Pinzas o cámara",
                           "Frente del vehículo: cámara, brazo auxiliar y paso de las pinzas")
)
tabla_verif_piezas <- df(
  `Verificación` = c("Caja envolvente del soporte torii", "Pila vertical del torii",
                     "Mallas reconstruidas (A, B, C, E)", "Malla de la pieza F (archivo de diseño)",
                     "Holguras de barrenos", "Paredes laterales del trapecio", "Prueba de campo del torii"),
  Resultado = c("X −90…90, Y 0…115, Z −14…0 mm: coincide con 180 × 115 × 14",
                "25 + 44 + 12 + 20 + 14 = 115 mm", "Cerradas; imprimibles sin reparación",
                "Caja envolvente X ±45, Y −38.1…12.7, Z 0…76.2 mm; abierta (346 triángulos con aristas libres): reparar en el laminador",
                "4.5 mm a cada lado del de 5 mm en las bases; 3.5 mm alrededor del de 7 mm en la barra superior",
                "No son uniformes (7.1 a 15.4 mm en perpendicular); regenerar como desplazamiento real si se requieren 12 mm",
                "Entregado para prueba en febrero de 2026 y verificado en el vehículo")
)
tabla_modelo_proc <- df(
  Pieza = c("Chasis base", "Carrocería central", "Tapas frontal y trasera", "Panel superior",
            "Ruedas (4)", "Brazo", "Cámara"),
  `Geometría` = c("Caja", "Caja", "Medio cilindro", "Extrusión triangular",
                  "Cilindro con 16 bloques de dibujo", "Base, 3 servos, 2 eslabones, muñeca, pinza",
                  "Caja con lente emisivo"),
  `Medidas principales` = c("0.40 × 0.02 × 0.30 m a 0.12 m del piso", "0.40 × 0.12 × 0.30 m",
                            "Radio 0.15 m, alto 0.12 m", "Largo ≈ 0.33 m, base 0.24 m",
                            "Radio 0.08 m, ancho 0.06 m", "Montado en x = 0.25 m", "2.5 × 2.5 × 1.5 cm")
)

# ---- Capítulo 4 -----------------------------------------------------------
tabla_bk300 <- df(
  Grupo = c("Núcleo", "Salidas visuales", "Entradas", "Actuadores", "Comunicación", "Sensores", "Memoria",
            "PORTA / PORTE", "PORTB", "PORTC", "PORTD"),
  `Periféricos` = c("PIC16F877A (40 pines), cristal de 4 MHz, cristal de 32.768 kHz para el reloj DS1302",
                    "8 LEDs a través de un latch 74HC573, display de 7 segmentos de 4 dígitos, conectores para LCD 16×2 y 128×64",
                    "Botones, teclado matricial 4×4, teclado PS/2",
                    "Zumbador, relevador, interfaz para motor CD y para motor a pasos (ULN2003)",
                    "RS232 (MAX232), RS485 (MAX485)", "DS18B20, receptor infrarrojo 1838B, potenciómetros VR1–VR3",
                    "EEPROM AT24C02 (I²C)", "Entradas analógicas; señales de control, relevador y motor a pasos",
                    "Teclado, LEDs de PWM, interrupción externa RB0/INT, ICSP (RB6/RB7)",
                    "UART (RC6 TX, RC7 RX), I²C (RC3 SCL, RC4 SDA), PWM (RC1 CCP2, RC2 CCP1)",
                    "Bus de datos paralelo de 8 bits hacia los latches")
)
tabla_z80_pic <- df(
  `Característica` = c("Tipo", "Memoria", "Instrucciones", "Registros", "Programa", "E/S", "Pila"),
  `Z80 (módulo VI)` = c("Microprocesador", "Von Neumann: programa y datos comparten bus",
                        "CISC, más de 150, de 1 a 4 bytes", "A, F, B–L, IX, IY, SP",
                        "ROM/EPROM externa, hasta 64 KB", "Chips externos (PIO, SIO, CTC)", "En RAM, tamaño libre"),
  `PIC16F877A (módulo XII)` = c("Microcontrolador", "Harvard: buses separados", "RISC, 35, de 14 bits",
                                "Acumulador W y 368 registros de archivo", "8 K palabras de Flash interna",
                                "33 pines, ADC de 8 canales, 2 CCP, USART, MSSP, 3 temporizadores",
                                "De hardware, 8 niveles")
)
tabla_experimentos <- df(
  `#` = c(1:8, 11),
  Experimento = c("LED", "KEY", "TIMER0", "INT", "RS232", "EEPROM", "Watchdog", "PWM", "DS18B20"),
  `Qué enseña` = c("Salidas, manejo de bits, latch", "Entradas, pull-ups, antirrebote",
                   "Temporización por interrupción", "Interrupción externa", "Comunicación serie con la PC",
                   "Memoria no volátil", "Reinicio si el programa se bloquea", "Modulación por ancho de pulso",
                   "Sensor digital 1-Wire"),
  `Periférico` = c("PORTD + latch", "PORTB", "Timer0", "RB0/INT", "USART", "EEPROM", "WDT", "CCP1/Timer2",
                   "Pin + tiempo"),
  `Mód.` = c("V, VIII", "III, VIII", "VIII", "VIII", "VIII", "V", "IX", "X", "VIII, XIII"),
  `Aplicación en el robot` = c("LEDs de estado", "Botones de modo y paro", "Base de 5 Hz del nodo",
                               "Paro de emergencia", "Enlace con la Jetson", "Calibraciones",
                               "Confiabilidad del nodo", "Control de potencia", "Temperatura del MD22")
)
tabla_limitaciones_pic <- df(
  `Limitación` = c("Sin 115 200 baudios", "Sin PWM de hardware a 50 Hz", "Ciclo de desarrollo lento",
                   "Pila de 8 niveles", "368 bytes de RAM"),
  Causa = c("Cristal de 4 MHz, ec. (2.11)", "Timer2 de 8 bits, preescalador máx. 1:16, ec. (4.3)",
            "Compilar, grabar y probar", "Arquitectura PIC16", "Microcontrolador pequeño"),
  Consecuencia = c("Enlace con el PIC a 9600 baudios", "Servos por software con Timer1", "Actuadores en Arduino",
                   "Evitar llamadas anidadas profundas", "Búferes cortos y tramas compactas")
)
tabla_sensores <- df(
  Dispositivo = c("Potenciómetros VR1–VR3", "Divisor de batería", "DS18B20", "Receptor IR 1838B",
                  "Botones y paro", "Codificadores ópticos", "Control del visor", "Cámara frontal",
                  "Motorreductores (2)", "Servo HS-805BB", "Servos de pinzas o cámara", "Motor a pasos",
                  "Relevador y zumbador", "HC-SR04, ACS712, LiDAR"),
  Tipo = c("Sensor analógico", "Sensor analógico", "Temperatura", "Digital", "Digital", "Velocidad",
           "Pose", "Imagen", "Actuador de potencia", "Posición", "Posición", "Posición", "Todo o nada",
           "Distancia, corriente"),
  `Señal` = c("0–5 V", "0–4.8 V", "1-Wire", "Pulsos de 38 kHz demodulados", "Contacto",
              "Pulsos, 400 por vuelta", "Datos WebXR", "Video digital", "PWM por puente H",
              "Pulso de 1–2 ms", "Pulso de 1–2 ms", "Secuencia de fases", "Bobina o tono",
              "Eco, analógica, serie"),
  Interfaz = c("ADC", "ADC", "Pin con temporización", "Interrupción y Timer1", "Entrada con pull-up",
               "Contador Timer1", "Wi-Fi", "USB a la Jetson", "I²C al MD22", "PWM", "PWM", "ULN2003",
               "Transistor o PWM", "Captura, ADC, UART/USB"),
  Estado = c("Práctica", "Diseñado", "Práctica", "Práctica", "Práctica", "Instalados en 2008", "En uso",
             "Instalada", "En uso", "En uso", "En uso", "Práctica", "Práctica", "Propuestos")
)
tabla_onewire <- df(
  `Operación` = c("Reinicio", "Escribir un 1", "Escribir un 0", "Leer un bit", "Conversión a 12 bits"),
  `El maestro (PIC)` = c("Baja la línea, la suelta y espera el pulso de presencia",
                         "Baja la línea y la suelta pronto", "Baja la línea y la mantiene",
                         "Baja 1–2 µs, suelta y lee", "Espera tras el comando 0x44"),
  `Duración` = c("480 µs en bajo", "1–15 µs en bajo, ranura de 60 µs", "60 µs en bajo",
                 "Muestrear antes de 15 µs", "750 ms")
)
tabla_md22 <- df(
  `Reg.` = c(0, 1, 2, 3, 7),
  Nombre = c("Modo", "Velocidad 1", "Velocidad 2", "Aceleración", "Versión"),
  Uso = c("Interpretación de 1 y 2", "Motor izquierdo", "Motor derecho o giro", "Rapidez de cambio",
          "Diagnóstico (lectura)")
)
tabla_md22_modos <- df(
  Modo = 0:3,
  `Registros 1 y 2` = c("Cada motor, 0–255", "Cada motor, −128 a 127", "Común + giro, 0–255",
                        "Común + giro, con signo"),
  Paro = c(128, 0, 128, 0)
)
tabla_pruebas_12 <- df(
  `Id.` = c("P1-01", "P1-02", "P1-04", "P1-06", "P1-07", "P1-08", "P1-09", "P1-10", "P2-01", "P2-02",
            "P2-05", "P2-06", "P2-07", "P2-08", "P2-09", "P2-10", "P2-12"),
  Prueba = c("Alimentar la BK300", "Grabación por ICSP", "Timer0 (base de 200 ms)", "RS232", "EEPROM",
             "Watchdog", "PWM", "DS18B20", "Potenciómetro por ADC", "Voltaje de batería", "MD22, presencia",
             "MD22, motores", "Batería y fusible", "Servo S2", "Servo desde el visor", "Motor a pasos",
             "Control del visor como sensor"),
  `Criterio de aceptación` = c("Encendido sin calentamiento", "Grabación y verificación correctas",
                               "±1 % con osciloscopio", "Eco a 9600 8N1 durante 10 min sin errores",
                               "El valor sobrevive al apagado", "Reinicio en ≈ 2.3 s sin CLRWDT()",
                               "1 kHz y ciclo de 0–100 % medidos", "±0.5 °C contra termómetro",
                               "0–1023 continuo, sin saltos", "Diferencia < 1 % tras calibrar", "Responde en 0x58",
                               "Giro lento en ambos sentidos y paro", "Motores al 60 % por 5 min sin reinicios",
                               "Barrido 40–90–140° sin atoramiento", "El servo sigue al control",
                               "Una vuelta con ≈ 4096 medios pasos", "Error < 2 cm y < 3° en puntos marcados"),
  Estado = c("Fuente identificada", rep("Aprobada", 10), "Aprobada con el mapa corregido (abril 2026)",
             "Aprobada (abril 2026)", "Aprobada (rango 40–140°)", "Aprobada (enero 2026)", "Aprobada", "Aprobada")
)

# ---- Capítulo 5 -----------------------------------------------------------
tabla_nano_pic <- df(
  Concepto = c("Reloj de instrucción", "Instrucciones", "Registros de trabajo", "Pila",
               "UART a 115 200 baudios", "Servo a 50 Hz", "I²C", "Convertidor USB"),
  PIC16F877A = c("1 MHz (4 MHz ÷ 4)", "35", "Un acumulador W", "8 niveles de hardware", "No posible",
                 "Por software (Timer1)", "RC3/RC4 (MSSP)", "Adaptador externo RS232"),
  `ATmega328P (Nano)` = c("16 MHz", "≈ 130", "32 de propósito general", "En RAM", "Sí",
                          "Biblioteca Servo (Timer1)", "A4 (SDA), A5 (SCL)", "Integrado (CH340 en clones)")
)
tabla_programas_e3 <- df(
  `Id.` = paste0("N", 1:6),
  Programa = c("Tarjeta y puerto serie", "Servo por comandos", "MD22 con mapa correcto", "Lectura de sensores",
               "Intérprete con vigilante", "Autodiagnóstico"),
  `Qué verifica o enseña` = c("Cable, controlador USB y monitor serie a 115 200",
                              "S:<ángulo> con saturación 40–140° mediante constrain()",
                              "PING lee el registro de versión antes de mandar velocidades; M1:x, M2:x, STOP",
                              "Promedio de 8 lecturas del divisor y distancia ultrasónica con el mismo formato $SEN del PIC",
                              "Trama ALL, validación de rangos y paro tras 500 ms sin comandos",
                              "Presencia del MD22 y movimiento corto del servo al encender"),
  Listado = c("D.1 (ref.)", "D.2 (hist.)", "D.3 (hist.)", "D.4 (ref.)", "D.5 (ref.)", "D.6 (ref.)")
)
tabla_rutinas <- df(
  Rutina = c("md22() / md22Leer()", "pct()", "validarMotor()", "constrain() en servos", "interpretarALL()",
             "pararTodo()", "Vigilante de comunicación", "autodiagnostico()"),
  `Qué hace` = c("Escribe o lee un registro por I²C", "Convierte −100…100 % a 0…255, ec. (4.6)",
                 "Zona muerta y límites, ec. (5.1)", "Evita forzar topes mecánicos", "Analiza la trama de texto",
                 "Estado seguro", "Paro tras 500 ms sin comandos", "Verifica actuadores al encender"),
  `Concepto de la carrera` = c("VIII: interfaz serie síncrona", "IV: aritmética binaria",
                               "XIII: protección del sistema motriz", "XIII", "VII: manejo de cadenas",
                               "III: lógica de habilitación", "IX: confiabilidad (análogo al WDT)",
                               "IX: análisis estático y dinámico")
)
tabla_comandos <- df(
  Comando = c("ALL:M1:a:M2:b:S1:c:S2:d", "MOTORS:v", "MOTOR1:v, MOTOR2:v", "SERVO2:θ", "STOP_ALL_MOTORS",
              "PING, STATUS"),
  Ejemplo = c("ALL:M1:60:M2:60:S1:90:S2:90", "MOTORS:60", "MOTOR1:50", "SERVO2:90", "–", "–"),
  Efecto = c("Motores y servos en una trama (el más usado)", "Ambos motores", "Un motor", "Dirección",
             "Paro inmediato", "Diagnóstico")
)
tabla_conexiones_mega <- df(
  `Señal` = c("SDA, SCL", "Servo S2 (dirección)", "Servo S1 (pinzas frontales)", "USB (Serial)",
              "Lógica del MD22", "Servo de la cámara (propuesto)", "Serial1–3"),
  `Pin del Mega` = c("20, 21", "9", "8", "Conector USB-B", "5 V y GND", "11", "18/19, 16/17, 14/15"),
  `Destino y nivel` = c("MD22, bus I²C a 5 V, 100 kHz", "HS-805BB, pulso de 1–2 ms a 50 Hz",
                        "Servo de las pinzas, pulso de 1–2 ms", "Jetson, /dev/cpm_actuadores, 115 200 baudios",
                        "Alimentación de la lógica del MD22",
                        "Orientación de la cámara frontal, fuente de 6 V con tierra común",
                        "Libres: enlace directo al PIC o LiDAR por UART"),
  Fuente = c("Firmware", "Firmware", "Firmware vigente", "Firmware", "Cableado", "Propuesto", "Disponible")
)
tabla_tramas_pic <- df(
  Trama = c("$BOOT", "$SEN", "$EST", "$IR", "RELE:0/1", "BUZ:<ms>", "CAL:VBAT=<mV>"),
  Frecuencia = c("Al arrancar", "5 Hz", "Al cambiar", "Al recibir", "Comando", "Comando", "Comando"),
  Contenido = c("Versión de firmware y bandera WDT=1 si el reinicio lo causó el watchdog",
                "VBAT en mV, TEMP en décimas de °C, POT1 en cuentas", "PARO=1 (presionado) o PARO=0 (liberado)",
                "Código de comando del control infrarrojo", "Corta o habilita la potencia de los motores",
                "Suena el zumbador", "Calibra el factor del divisor y lo guarda en EEPROM")
)
tabla_seguridad <- df(
  Evento = c("Paro presionado", "Wi-Fi o visor desconectados", "Servidor de la Jetson detenido", "PIC bloqueado",
             "Batería < 11.8 V", "MD22 > 60 °C", "Obstáculo < 30 cm (propuesto)"),
  `Lo detecta` = c("PIC (interrupción RB0)", "Arduino (vigilante recomendado; ausente en el firmware vigente)",
                   "Arduino (ídem)", "Watchdog del PIC; Jetson sin datos", "PIC → Jetson", "DS18B20 → Jetson",
                   "HC-SR04 → Jetson"),
  `Reacción` = c("$EST,PARO=1; la Jetson manda el paro; opcionalmente el relevador corta la potencia",
                 "Paro por vigilante", "Paro por vigilante", "Reinicio del PIC; bloqueo de movimiento",
                 "Bloqueo y aviso en el visor", "Bloqueo o reducción de velocidad", "Paro"),
  `Tiempo estimado` = c("< 50 ms (< 1 ms con relevador)", "≤ Tw", "≤ Tw", "≤ 1 s", "200 ms", "≈ 1 s", "200 ms")
)
tabla_lidar <- df(
  Modelo = c("LDROBOT D500", "RPLIDAR C1", "youyeetoo FHL-LD19", "MakerFocus TF-Luna"),
  Tipo = c("Barrido 2D", "Barrido 2D", "Barrido 2D", "Telémetro de un punto"),
  `Con la Jetson Nano` = c("Compatible (USB o serie, soporte ROS)", "Compatible", "Compatible", "Capacidad limitada"),
  `Con el Arduino Mega` = c("Limitado", "No recomendado: volumen de datos y memoria",
                            "No recomendado: volumen de datos y memoria",
                            "Recomendado: UART o I²C, poca carga de proceso")
)
tabla_canales <- df(
  Canal = c("WebSocket (adoptado)", "ROS con rosbridge", "API REST", "UDP"),
  Ventaja = c("Bidireccional, desde el navegador, baja sobrecarga", "Integra el ecosistema ROS (LiDAR, mapas)",
              "Simple, sin estado", "Mínima latencia"),
  `Limitación` = c("Requiere contexto seguro y manejo de reconexión", "Agrega una capa de software y dependencias",
                   "Una conexión por orden; mayor latencia", "Sin garantía de entrega ni orden; requiere cliente nativo")
)
tabla_recursos_pic <- df(
  `Función` = c("Enlace con la Jetson", "Puente H MD22", "Servo S2 (dirección) y S1 (pinzas)", "Base de tiempo",
                "Codificador", "Batería", "Temperatura", "Paro de emergencia", "Relevador K1, zumbador", "Indicadores"),
  `Pines y recurso` = c("RC6/TX, RC7/RX; USART", "RC3/SCL, RC4/SDA; MSSP", "RC1, RC2; Timer1", "Timer2",
                        "RA4/T0CKI; Timer0", "RA5/AN4; ADC", "RB5; 1-Wire", "RB0/INT", "RE1, RE2", "RD0, RD1"),
  Detalle = c("9600 baudios 8N1 por MAX232 y adaptador USB-RS232; recepción por interrupción en una cola de 48 bytes",
              "I²C maestro a 100 kHz (SSPADD = 9), dirección 0xB0; modo 0 y aceleración gradual",
              "Pulsos de 1–2 ms cada 20 ms por software, en tres fases",
              "1 ms (PR2 = 249, preescalador 1:4); vigilante de 500 ms y reporte a 5 Hz",
              "Contador de pulsos con extensión a 16 bits por desbordamiento",
              "Divisor 20k/10k, factor calibrable en EEPROM", "DS18B20 leído solo en la fase de reposo de los servos",
              "Flanco de subida (botón NC); abre K1 dentro de la interrupción",
              "Transistores 2N2222; K1 arranca abierto hasta recibir RELE:1",
              "LED de vida (parpadeo a 2.5 Hz) y LED de paro")
)
tabla_alineacion <- df(
  Aspecto = c("Comandos de la Jetson", "Respuestas", "Validación de rangos", "Vigilante de comunicación",
              "Puente H", "Servos", "Enlace", "Sensores y seguridad", "Tramas de estado"),
  `Arduino Mega (vigente)` = c("ALL diferencial y heredado, SERVO1/2, MOTORS, MOTOR1/2, STOP_ALL_MOTORS, PING, STATUS",
                               "OK:M1:a:M2:b:S1:c:S2:d, ERR:RANGE:..., PONG",
                               "Motores 0 o 40–100 %, S1 40–140°, S2 40–140°; trama fuera de rango rechazada completa",
                               "No implementado en el firmware vigente (recomendado)",
                               "MD22 por I²C con Wire (0x58)", "Biblioteca Servo (Timer1 del ATmega)",
                               "USB a 115 200 baudios", "No incluidos (los aporta el nodo PIC)", "–"),
  `PIC16F877A (circuito 5)` = c("ALL diferencial, STOP_ALL_MOTORS, PING, STATUS, más RELE, BUZ, CAL:VBAT, CAL:S2C",
                                "Las mismas, más BLOQUEADO y WARN timeout", "Idéntica, con las mismas constantes",
                                "500 ms (2.5 periodos del ciclo de 5 Hz)", "MD22 por I²C con el MSSP (0xB0)",
                                "Timer1 del PIC por software", "RS232 a 9600 baudios",
                                "Batería, temperatura, codificador, paro y relevador en la misma unidad",
                                "$BOOT, $SEN (5 Hz), $EST con XOR")
)
lista_verificacion <- df(
  `#` = 1:10,
  Fase = c("Sin energía", "Sin energía", "Sin energía", "Sin energía", "Lógica", "Lógica", "Lógica",
           "Potencia", "Potencia", "Piso"),
  `Verificación` = c("Fusible presente y del valor correcto; interruptor general abierto",
                     "Polaridad de batería, MD22 y convertidores revisada con multímetro; sin continuidad entre B+ y tierra",
                     "Voltaje de batería en reposo ≥ 12.4 V (Tabla 2.1)",
                     "Tierras unidas en el punto de estrella; conectores de servos con la polaridad correcta",
                     "Jetson encendida; /dev/cpm_actuadores y /dev/cpm_sensores presentes",
                     "Respuesta OK a PING y lectura del registro de versión del MD22",
                     "Salida del convertidor de servos entre 5.8 y 6.2 V antes de conectar los servos",
                     "Ruedas en el aire; ALL:M1:40:M2:40:S1:90:S2:90 y paro; dirección 40–90–140°",
                     "Vigilante: detener el servidor y confirmar el paro en ≤ 0.5 s",
                     "Área despejada, operador con acceso al interruptor; primeras pruebas al 40–60 %")
)
tabla_pruebas_34 <- df(
  `Id.` = c(paste0("P3-0", 1:7), paste0("P4-0", 1:9)),
  Prueba = c("N1: tarjeta y monitor serie", "N2: servo por comandos", "N3: PING al MD22",
             "N3: motores por comandos", "N5: trama ALL válida", "N5: valores fuera de rango", "N5: vigilante",
             "SSH y Samba", "Detección del Arduino desde Python", "Visor → Jetson → Arduino → vehículo",
             "Nombres fijos udev", "Tramas del PIC", "Paro de extremo a extremo", "Bloqueo por batería",
             "Pérdida del nodo PIC", "Consumo total"),
  Criterio = c("Eco correcto a 115 200", "Respeta 40–140°", "Devuelve versión", "Giro lento en ambos sentidos",
               "OK y actuadores en posición", "Saturados a 140° y 100 %", "Paro en ≤ 0.5 s al detener el servidor",
               "Acceso a terminal y carpeta", "Puerto encontrado", "Ejecuta una trayectoria dibujada",
               "Enlaces presentes tras 3 reinicios", "1000 tramas $SEN sin error de checksum",
               "Motores detenidos en < 100 ms (video a 240 fps)", "Con fuente a 11.5 V: bloqueo y aviso",
               "Bloqueo en ≤ 1 s", "Corriente con motores al 60 %"),
  Estado = c("Aprobada", "Aprobada", "Aprobada tras corregir dirección", "Aprobada con mapa corregido",
             "Aprobada en el Mega", "Implementada; resultado por registrar", "Diseñada (programa de referencia N5)",
             "Aprobada (abril 2026)", "Aprobada", "Aprobada cualitativamente", "Aprobada", "Aprobada", "Aprobada",
             "Aprobada", "Aprobada", "Aprobada")
)
# Figura 5.1: diagrama de tiempo del ciclo de control (estimaciones de diseño)
ciclo_control <- df(
  tarea = c("Visor (comando o pose)", "Jetson (cálculo)", "Serie a Arduino", "Arduino (I²C + servos)",
            "PIC (ADC + DS18B20)", "Serie del PIC ($SEN)", "Jetson (validación)"),
  inicio = c(0, 14, 19, 22, 0, 10, 52),
  duracion = c(14, 5, 2.6, 1, 10, 42, 3)
)

# ---- Capítulo 6 -----------------------------------------------------------
tabla_procesos <- df(
  Proceso = c("https_server.py", "trajectory_websocket_server*.py", "combined_server_simulated.py"),
  Puerto = c("8443", "8444", "8443 y 8444"),
  Responsabilidad = c("Entregar HTML, JavaScript, GeoJSON y modelos al navegador del visor",
                      "Recibir comandos y poses por WSS, generar comandos a 5 Hz, reenviar al Arduino, registrar y analizar (versión vigente: Listado E.6)",
                      "Ambos servicios en un solo proceso, con vehículo simulado, para una tableta Android con Termux (Listado E.7)")
)
tabla_mensajes <- df(
  Mensaje = c("Comando directo", "Pose y joystick", "Seguimiento", "Diferencial", "Trayectoria", "Paro", "Pose", "Análisis"),
  Formato = c("ALL:M1:<0|40-100>:M2:<0|40-100>:S1:<40-140>:S2:<40-140>",
              "TRACK:t:x:y:z:ψc:ψv:ψf:M1:a:M2:b:S1:c:S2:d, cada 200 ms",
              "MODE2_TRACK:t:x:0:z:ψ:ψ*:d:e:WP:i/N:M1:a:M2:b:S2:c, cada 200 ms",
              "{\"differential_mode\":0.25}", "MODE2_PATH:{\"waypoints\":[[x,z,ψ],…],\"differential\":0.25}",
              "MODE2_STOP, MODE5_STOP", "JSON con posición filtrada y rumbo", "{\"command\":\"SAVE_MODE1_ANALYSIS\",…}"),
  Origen = c("Paro y pruebas", "Modo 1", "Modos 2 y 5 (MODE5_TRACK)", "Panel del diferencial",
             "Modos 2 y 5 (MODE5_PATH)", "Modos 2 y 5", "Modo 4", "Modo 1")
)
tabla_servicios <- df(
  `Servicio o enlace` = c("HTTPS (TLS)", "WebSocket seguro", "SSH", "Samba (SMB)", "Serie USB", "Serie RS232", "I²C"),
  Extremo = c("Jetson 192.168.100.10", "Jetson", "Jetson", "Jetson", "Arduino Mega", "Nodo PIC", "MD22"),
  `Puerto o dispositivo` = c("TCP 8443", "TCP 8444", "TCP 22", "TCP 445", "/dev/cpm_actuadores",
                             "/dev/cpm_sensores", "Dirección 0x58"),
  Uso = c("Páginas, JavaScript, mapa y modelos para el visor", "Comandos, trayectorias, poses y análisis",
          "Terminal remota (usuario joe)", "Carpeta compartida con la PC de desarrollo",
          "Tramas ALL a 115 200 baudios", "Tramas $SEN, $EST, $BOOT, $IR a 9600 baudios",
          "Registros de modo, velocidad y aceleración")
)
tabla_quest <- df(
  `Característica` = c("Procesador", "Memoria", "Pantalla", "Óptica", "Cámaras", "Controles", "Conectividad", "Masa"),
  Valor = c("Qualcomm Snapdragon XR2 Gen 2 (4 nm): CPU de 2 núcleos Cortex-A715 y 4 Cortex-A510 a 2.05 GHz; GPU Adreno 740",
            "8 GB LPDDR4X; almacenamiento de 128 o 256 GB", "LCD de un solo panel, 1832 × 1920 píxeles por ojo, 90 a 120 Hz",
            "Lentes de Fresnel; campo de visión horizontal de 96°; distancia interpupilar de 58, 63 o 68 mm",
            "Dos cámaras RGB de 4 MP para el passthrough a color y cuatro cámaras infrarrojas de 400 × 400 en dos grupos triangulares para el rastreo; sin sensor de profundidad",
            "Dos Touch Plus con LED infrarrojos y sensores inerciales, rastreados por el visor; también rastreo de manos",
            "Wi-Fi 6E y Bluetooth 5.2", "514 g")
)
tabla_modos <- df(
  Modo = 0:7,
  `Nombre en el panel` = c("R Vehicle Map View", "Manual (joystick)", "User Trajectory (dibujar)", "M25 Highway",
                           "Ctrl Track (Kalman izquierdo)", "M25 Smooth Tracking", "EV Chargers", "Truck Positions"),
  `Descripción` = c(
    "Gemelo digital del vehículo sobre el mapa del M25 de Londres (modo inicial)",
    "Joystick a motores y dirección; trazo del control izquierdo sobre una rejilla de 21 × 21 celdas de 10 cm; marcadores cada 20 cm; envío para análisis",
    "Se dibuja la ruta roja en el piso, se elige ARC o SPLINE y el radio (5–75 cm), se aprueba, se suaviza en verde con puntos de paso cada 20 cm y el botón A inicia el seguimiento autónomo; límite de 2 minutos por recorrido",
    "Recorrido del anillo del GeoJSON escalado al piso, en tres variantes: real (el vehículo conduce), virtual (manejo manual del gemelo) y simulación (demostración automática)",
    "Pose filtrada del control montado en el vehículo; medición cruda y filtrada; no envía comandos",
    "Suavizado del anillo M25 con radio de giro elegido (ARC o SPLINE) y seguimiento autónomo de la trayectoria suavizada",
    "Estado simulado de cargadores de vehículos eléctricos sobre el mapa; solo visualización",
    "Posiciones de una flotilla de camiones sobre el mapa; solo visualización")
)
tabla_controles <- df(
  Entrada = c("Gatillo derecho", "Botón A", "Botón B", "Joystick derecho, eje X / eje Y", "Presionar el joystick derecho",
              "Control izquierdo (pose)", "Gatillo izquierdo", "Agarre izquierdo", "Botón X"),
  `Función` = c("Interacción con los paneles por rayo", "Iniciar el seguimiento (modos 2 y 5); abrir las pinzas a 40° (modo 1)",
                "Cerrar las pinzas a 140° (modo 1)", "Dirección / avance sin reversa (modo 1)",
                "Paro de emergencia (modos 2 y 5); borrar el último punto (modo 2)",
                "Posición y rumbo del vehículo, filtrados con Kalman en cada cuadro", "Dibujar la trayectoria (modo 2)",
                "Borrar el trazo (modo 1)", "Reiniciar la vista (modo 6)")
)
tabla_kalman_iter <- df(
  `It.` = c("1", "1", "2", "3", "3", "4"),
  Filtro = c("Posición", "Rumbo", "Rumbo", "Posición", "Rumbo", "Compuerta"),
  sq = c(0.01, 0.01, 0.001, 0.01, 0.01, NA),
  sr = c(0.25, 0.50, 2.0, 0.10, 0.50, NA),
  `Observación` = c("Suavizado moderado; base de partida",
                    "Persistían saltos de rumbo (por ejemplo, 348° → 55° → 91°)",
                    "Eliminó los saltos, pero el gemelo tardaba decenas de cuadros en girar; con límites de velocidad demasiado estrictos casi no reflejaba los movimientos reales",
                    "Respuesta más rápida a los movimientos reales", "Menor retardo; se retiraron los límites estrictos",
                    "Se reintrodujo un rechazo de saltos basado en los límites físicos del vehículo (2.8 cm y 10.3° por muestra), junto con el desenvolvimiento del ángulo")
)
tabla_corrida_m5 <- df(
  Aspecto = c("Puntos de paso", "Desviación hasta el punto 11", "Pérdida de rastreo del visor", "Maniobra de recuperación",
              "Diferencial aplicado", "Comunicación", "Red Wi-Fi"),
  Resultado = c("26 sobre la trayectoria suavizada", "Entre 0.3 y 5 cm",
                "Salto de 42 cm en la posición medida; la desviación pasó de 2.0 a 31.0 cm y el vehículo no se recuperó",
                "Se activó al superar el umbral; la dirección S2 pasó de 50 a 79° y la corrida se detuvo con 30.6 cm de desviación",
                "Razón de mandos 50/80 = 0.625, distinta del factor 0.25 elegido en el panel: defecto detectado y corregido",
                "900 comandos enviados sin errores; canal WebSocket estable y sin bloqueos de la pantalla",
                "Latencias de ping del visor de 14 a 156 ms en la misma red, atribuidas al ahorro de energía del visor")
)
tabla_corridas_finales <- df(
  `Parámetro` = c("Escala del mapa, método, radio", "Puntos de paso", "Tramas enviadas", "Errores del Arduino",
                  "Duración", "Desviación", "Fin"),
  `Corrida 1` = c("110 %, SPLINE, 45 cm", "28/28 a 20 cm: vuelta completa", "820 (800 de movimiento y 20 de paro)",
                  "0", "≈ 2 minutos", "0 a 7 cm típica", "Vuelta autónoma completa"),
  `Corrida 2` = c("110 %, SPLINE, 45 cm", "Del 3 al 23 de 28; paro manual", "456 (tramas 830 a 1286 de la sesión)",
                  "0", "Servidor activo 2396 s (≈ 40 min continuos)",
                  "0 a 5 cm hasta el punto 22; 18.3 cm en la esquina del punto 23", "Ctrl+C")
)
tabla_formatos <- df(
  `Archivo o mensaje` = c("mode1_analysis_<ts>.txt", "Pose del modo 4", "CSV de comandos por trayectoria",
                          "CSV de seguimiento", "Bitácora del nodo PIC"),
  Campos = c("grid_x, grid_z, world_x, world_z, heading_deg, motor_linear, motor_angular, timestamp; metadatos grid_size, map_size, total_points, markers",
             "Posición filtrada (x, z) y rumbo ψ en radianes", "Una fila por comando enviado",
             "t, i, xᵢ, zᵢ, x̂, ẑ, ψ̂, ep, ect, eψ, κ, δ, θs, u1, u2, Vbat, T",
             "Tramas $SEN, $EST, $BOOT con marca de tiempo de la Jetson"),
  Estado = c("Documentado", "Documentado", "Documentado (columnas por fijar)", "Propuesto", "Propuesto")
)

# ---- Capítulo 7 -----------------------------------------------------------
tabla_tasas <- df(
  Componente = c("Meta Quest 3S", "Lazo de control", "Jetson Nano", "Enlace USB serie", "Arduino Mega 2560",
                 "Bus I²C al MD22", "Servos (biblioteca Servo)", "PIC16F877A", "Simulador (tableta)"),
  `Reloj o tasa` = c("Snapdragon XR2 Gen 2; cuadros a 72–90 Hz", "5 Hz (200 ms)",
                     "4 núcleos Cortex-A57 a 1.43 GHz; GPU de 128 núcleos", "115 200 Bd",
                     "ATmega2560 a 16 MHz (62.5 ns por ciclo)", "100 kHz", "Pulsos de 50 Hz, resolución 0.5 µs",
                     "4 MHz (1 µs por instrucción)", "50 Hz"),
  `Qué procesa a esa tasa` = c("Pose del control, filtro de Kalman, desenvolvimiento del rumbo, cálculo de la desviación y dibujo estereoscópico, en cada cuadro de 11 a 14 ms",
                               "Rumbo, término lateral, servo, diferencial y envío de MODEx_TRACK",
                               "Reenvío de un mensaje en 0.1 a 1 ms; servidor HTTPS, bitácora; video propuesto",
                               "Una trama ALL de unos 30 caracteres en ≈ 2.6 ms",
                               "loop() decenas de miles de veces por segundo; validación y aplicación de una trama en ≈ 4 ms",
                               "Un registro en ≈ 0.3 ms; dos motores por trama", "Posición de S1 y S2",
                               "ADC, 1-Wire, interrupción del paro en microsegundos; reporte a 5 Hz",
                               "Integración del modelo de bicicleta")
)
tabla_criterios <- df(
  `Desviación promedio` = c("< 8 cm", "8–15 cm", "> 15 cm"),
  `Clasificación` = c("Baja, aceptable", "Moderada", "Alta"),
  `Recomendación` = c("Ajuste fino opcional", "Afinar la velocidad, la respuesta del servo y la compensación anticipativa",
                      "Revisar calibración de motores, geometría Ackermann, ganancias y deslizamiento")
)
tabla_pruebas_sistema <- df(
  `Id.` = c("R-01", "R-03", "R-04", "R-06", "A-01", "A-03", "A-04", "A-06", "A-07", "T-01", "T-02", "T-03", "T-04",
            "T-05", "T-06", "T-07", "T-08", "T-09", "T-10"),
  Prueba = c("Servo desde el navegador del visor", "Contexto seguro HTTPS", "Servidor en Python 3.9 y 3.13",
             "Latencia de extremo a extremo", "Detección de piso (local-floor)", "Escala 1:1 del gemelo",
             "Orientación del modelo", "Rendimiento con STL embebido", "Panel de diferencial", "Dibujo de trayectoria",
             "Comandos a 5 Hz", "Ejecución en el vehículo (lazo abierto)", "Rumbo del control", "Saltos de posición y giro",
             "Control perdido", "Comandos en modo 1", "Seguimiento con métricas", "Suavizado ARC y SPLINE (modo 5)",
             "Seguimiento autónomo del M25 suavizado"),
  Resultado = c("Aprobada (ene)", "Aprobada", "Aprobada (feb)", "Aprobada", "Aprobada", "Aprobada", "Aprobada", "Fluido",
                "Aprobada (abr)", "Aprobada", "Aprobada", "Aprobada cualitativamente (ene)", "Falló, corregida",
                "Falló, corregida", "Falló, corregida", "Falló, corregida", "Implementada (abr)",
                "Implementada tras iteraciones", "Aprobada en el tramo con rastreo"),
  `Observación` = c("Primer enlace extremo a extremo", "Botón de RA habilitado", "Tipos MIME propios", "Criterio < 100 ms",
                    "Rejilla y mapa sobre el piso real", "Largo de 60 cm; ver inconsistencia de ℓ y b",
                    "Rotaciones horneadas en la geometría", "El problema fue el tamaño del archivo, no el dibujo",
                    "Tres factores con efecto en el modo 1", "Marcadores cada 20 cm", "CSV por trayectoria",
                    "Dibujo, comandos, recepción y ejecución", "Guiñada del cuaternión", "Saltos > 20 cm; compuerta (7.9)",
                    "Solo controles", "Regresión; se regresó a la versión base", "Valores medidos no registrados",
                    "Sin lazos; radio del panel (sección 6.4.3)",
                    "0.3–5 cm hasta el punto 11; falla por pérdida de rastreo (Tabla 6.8)")
)
tabla_campana <- df(
  `#` = paste0("C", 1:6),
  Experimento = c("Calibración de dirección", "Calibración de velocidad", "Radio mínimo real", "Seguimiento",
                  "Precisión del rastreo", "Latencia"),
  Procedimiento = c("Medir el ángulo real de las ruedas con S2 en 40, 65, 90, 115 y 140°",
                    "Recorrer 2 m en recta a 40, 60, 80 y 100 %, con batería llena y a media carga",
                    "Círculo con S2 en cada extremo; medir el diámetro",
                    "Recta de 2 m, arco de 1 m de radio, “S” y ocho; λ ∈ {0.25, 0.5, 0.75}; 3 repeticiones (36 corridas)",
                    "Vehículo inmóvil sobre puntos conocidos de la rejilla",
                    "Marca de tiempo en el visor contra llegada al Arduino"),
  `Resultado esperado` = c("ks por mínimos cuadrados", "Curva v(u)", "ρmin medido", "ēp, max ep, eRMS_ct",
                           "Sesgo y desviación estándar", "Latencia media y percentil 95")
)
tabla_lecciones <- df(
  Problema = c("MD22 responde pero no mueve", "guess_type falla", "Rumbo casi constante", "Saltos del gemelo",
               "Gemelo salta a la mano", "Regresiones en la app", "Sesiones saturadas", "Llave privada expuesta"),
  `Causa raíz` = c("Dirección de 7/8 bits y registros de otro modelo", "Cambio de firma entre versiones de Python",
                   "Ángulo calculado desde la posición", "Ruido y pérdidas de rastreo", "Cambio automático a rastreo de manos",
                   "Cambios no solicitados", "Página de 712 KB con STL embebido", "Servidor publica todo su directorio"),
  `Lección` = c("Hoja de datos del modelo exacto", "Aislar dependencias de la biblioteca estándar",
                "Usar la orientación (cuaternión)", "Kalman, desenvolvimiento y compuerta", "Filtrar fuentes de entrada",
                "Versión base congelada", "Modelos 3D como archivos externos", "Carpeta pública con lista blanca")
)

# ---- Capítulo 8 -----------------------------------------------------------
tabla_contribuciones <- df(
  `Contribución` = c("Ruta de integración en cuatro etapas alineada con los 13 módulos",
                     "Arquitectura jerárquica con tres capas de paro", "Gemelo digital en RA con ocho modos",
                     "Generador Ackermann a 5 Hz con métricas", "Estimador de pose de bajo costo"),
  `Capítulos` = c("2–5", "3, 5", "3, 6", "7", "7"),
  Evidencia = c("Tabla 2.7; experimentos de la BK300; límites calculados del PIC (Tablas 4.4 y 4.5); pruebas P2-05 a P2-09 y P3-01 a P3-05 aprobadas",
                "Figura 3.1; Algoritmos 1 y 2; Tabla 5.7; pruebas de seguridad P4-06 a P4-08",
                "Pruebas A-01 a A-07 aprobadas; Figs. 6.4 a 6.7; Tabla 6.8",
                "Algoritmo 5; pruebas T-01 a T-03 aprobadas; T-08 implementada",
                "Algoritmo 6; fallos T-04 a T-06 corregidos")
)
trabajo_futuro <- list(
  "Inmediato (1–2 semanas)" = c(
    "Corregir la exposición de la llave y regenerar los certificados, también en el servidor combinado para tableta",
    "Agregar al firmware del Arduino el vigilante de comunicación de 500 ms",
    "Recuperar y versionar los archivos finales de las corridas de abril y compararlos con las reconstrucciones",
    "Aplicar la convención única de dirección con ψv = ψq + π y ejecutar la prueba de signo",
    "Crear un archivo único de configuración con dimensiones, rangos y constantes",
    "Ejecutar las calibraciones C1 a C3 y el experimento C4"),
  "Corto plazo (1–2 meses)" = c(
    "Implementar el nodo de sensores del PIC con divisor y DS18B20, el paro en RB0 y el relevador de corte",
    "Suavizar y remuestrear las trayectorias con saturación de curvatura",
    "Implementar persecución pura y Stanley sobre la pose rastreada y compararlos con el generador actual",
    "Desarrollar el módulo de análisis en R",
    "Odometría de las ruedas con mensajes ODOM:izq:der para cubrir las pérdidas de rastreo",
    "Velocidad del modo 2 modulada por la curvatura (70 − 200 κ) y repetición automática de la vuelta en el modo 5",
    "Telemetría de batería e inclinación por las entradas analógicas del Arduino"),
  "Mediano plazo" = c(
    "Reincorporar los codificadores ópticos de 400 ranuras con control PID de velocidad",
    "Sensor ultrasónico con paro automático (OBSTACLE:dist)",
    "Migrar por fases funciones al PIC conservando el protocolo",
    "Sustituir el M25 simulado por una ruta del campus levantada con GPS; RTK-GPS para exteriores",
    "Coordinar varios vehículos con un identificador en los comandos",
    "Ejecutar a escala las rutas que se simulan en Isaac Sim"),
  "Largo plazo" = c(
    "Monitoreo y control de vehículos autónomos reales en el Reino Unido y México",
    "Sustituir los datos simulados de los modos 6 y 7 por fuentes reales de tráfico, recarga y telemetría de flotillas",
    "Mapas de corredores logísticos mexicanos (accesos y periféricos de la Ciudad de México)",
    "Usar el vehículo a escala como banco de pruebas de estrategias de ruteo, recarga y conducción autónoma")
)

# ---- Abreviaturas y nomenclatura ------------------------------------------
tabla_abreviaturas <- df(
  Sigla = c("AMS", "ADC", "AR, RA", "CCP", "CD", "CPM", "CSV", "EEPROM", "GPU", "HTTPS", "I²C", "ICSP", "MSSP",
            "PWM", "RS232", "STL", "UART/USART", "WDT", "WebXR", "WSS"),
  Significado = c("Sistema automático de materiales de la impresora 3D (AMS Lite)",
                  "Convertidor analógico-digital (analog-to-digital converter)", "Realidad Aumentada (augmented reality)",
                  "Módulo de captura, comparación y PWM del PIC", "Corriente directa",
                  "Colegio y Proyectos en Microelectrónica, S.C., institución que imparte la carrera de Técnico en Automatización Industrial",
                  "Valores separados por comas (formato de bitácora)", "Memoria no volátil borrable eléctricamente",
                  "Unidad de procesamiento gráfico", "Protocolo de transferencia de hipertexto seguro",
                  "Bus serie síncrono de dos hilos", "Programación en el circuito (in-circuit serial programming)",
                  "Módulo serie síncrono maestro del PIC (I²C/SPI)", "Modulación por ancho de pulso",
                  "Norma de comunicación serie con niveles de ±5 a ±15 V", "Formato de malla triangular para modelos 3D",
                  "Transmisor-receptor serie (a)síncrono universal", "Temporizador perro guardián (watchdog timer)",
                  "Interfaz web para Realidad Virtual y Aumentada", "WebSocket sobre TLS")
)
tabla_nomenclatura <- df(
  Grupo = c(rep("Electricidad y electrónica", 13), rep("Cinemática y trayectorias", 15), rep("Estimación", 7)),
  `Símbolo` = c("V, I, R, P", "Vbat", "Ra, La", "ke, kt", "ω", "τ", "XL", "D", "fosc, Tcy", "NADC", "B, εB",
                "R1, R2, Vref", "Cbat",
                "ℓ", "b", "ρ, ρmin", "κ", "δ", "θs", "ks", "ψ", "v, vint, vext", "λ", "pᵢ", "ep, ect, eψ", "Δt",
                "dla, α", "kSt",
                "x̂k, Pk", "zk", "Kk", "σq², σr²", "Δpmax, Δψmax", "q = (qx, qy, qz, qw)", "racept"),
  Significado = c("Voltaje, corriente, resistencia y potencia", "Voltaje de la batería",
                  "Resistencia e inductancia del devanado del motor", "Constantes de fuerza contraelectromotriz y de par",
                  "Velocidad angular del motor", "Par mecánico", "Reactancia inductiva", "Ciclo de trabajo del PWM",
                  "Frecuencia del oscilador y periodo de instrucción", "Lectura del convertidor de 10 bits",
                  "Velocidad serie y error relativo", "Resistencias del divisor y referencia del ADC", "Capacidad de la batería",
                  "Distancia entre ejes (0.34 m en el software)", "Vía o ancho entre ruedas (0.30 m en el software)",
                  "Radio de giro y radio mínimo (0.50 m)", "Curvatura de la trayectoria, κ = 1/ρ",
                  "Ángulo de dirección de las ruedas delanteras", "Ángulo de mando del servomotor de dirección",
                  "Ganancia servo–ruedas, θs = 90° + ks δ", "Rumbo del vehículo en el plano del piso",
                  "Velocidad del vehículo y de las ruedas interior y exterior", "Factor del modo diferencial (0.25, 0.5 o 0.75)",
                  "Punto de paso (waypoint) i en el plano xz", "Errores de posición, transversal y de rumbo",
                  "Periodo del generador de comandos (0.2 s)", "Distancia de anticipación y ángulo al punto objetivo (persecución pura)",
                  "Ganancia del método de Stanley",
                  "Estimado y varianza del filtro de Kalman escalar", "Medición escalar en el instante k", "Ganancia de Kalman",
                  "Varianzas del proceso y de la medición", "Saltos máximos admitidos por muestra",
                  "Cuaternión de orientación del control", "Radio de aceptación de un punto de paso"),
  Unidad = c("V, A, Ω, W", "V", "Ω, H", "V·s/rad, N·m/A", "rad/s", "N·m", "Ω", "–", "Hz, s", "cuentas", "baudios, %",
             "Ω, V", "Ah", "m", "m", "m", "m⁻¹", "rad", "°", "–", "rad", "m/s", "–", "m", "m, m, rad", "s", "m, rad",
             "m/s", "–", "–", "–", "–", "m, rad", "–", "m")
)

# ---- Apéndice G: archivos y medios ----------------------------------------
tabla_archivos <- df(
  Archivo = c("robot_ar_map.html", "robot-viewer-v10.html", "https_server.py", "sample_campus_map.geojson",
              "cert.pem / key.pem", "Documento_Tecnico_CPM_v2.md", "stl/*.stl (5 archivos)", "piezas3d.py",
              "trajectory_6modes_tracker0.html", "trajectory_websocket_server_m2.py",
              "arduino_actuator_controller_expanded_ranges.ino", "AR_Robot_M25_Project_Report.md",
              "combined_server_simulated.py", "jetson_api_server_full.py"),
  `Tamaño` = c("≈ 712 KB", "≈ 15 KB", "≈ 5 KB", "≈ 12 KB", "–", "–", "60–122 KB", "–", "315 KB", "19.7 KB", "–",
               "14.8 KB", "17.2 KB", "15.8 KB"),
  `Descripción` = c("Visor de RA con STL embebido y mapa GeoJSON", "Visor procedimental y exportador GLB",
                    "Servidor HTTPS (ver hallazgo de seguridad)", "Mapa normalizado del M25",
                    "Certificado autofirmado y llave privada: considerar comprometida y regenerar",
                    "Documento técnico del que se deriva esta tesis",
                    "Soportes impresos: A, B, C y E reconstruidos y F de diseño", "Reconstrucción paramétrica de los soportes",
                    "Aplicación WebXR de ocho modos (modo 5 reconstruido)", "Servidor de control vigente (MODE5 reconstruido)",
                    "Firmware vigente reconstruido (Listado D.7)", "Reporte de las corridas finales (sección 6.4.6)",
                    "Servidor HTTPS + WSS con vehículo simulado (Listado E.7)",
                    "Servidor Flask de enero para la aplicación de R Shiny")
)

# ---- Bibliografía ----------------------------------------------------------
bibliografia <- df(
  Clave = c("Analog Devices (s.f.)", "Arduino (s.f. a)", "Arduino (s.f. b)", "Bambu Lab (s.f.)", "Coulter (1992)",
            "Devantech (s.f.)", "Grieves y Vickers (2017)", "Kalman (1960)", "Microchip Technology (2003)", "NVIDIA (s.f.)",
            "NXP Semiconductors (2021)", "Rajamani (2012)", "Snider (2009)", "three.js (s.f.)", "Welch y Bishop (1995)",
            "W3C (2026)", "Zubizarreta Rodríguez y Ayala Solares (2008)", "Proyecto CPM Completion (2026a)",
            "Proyecto CPM Completion (2026b)"),
  `Año` = c(NA, NA, NA, NA, 1992, NA, 2017, 1960, 2003, NA, 2021, 2012, 2009, NA, 1995, 2026, 2008, 2026, 2026),
  `Título` = c("DS18B20: Programmable Resolution 1-Wire Digital Thermometer", "Mega 2560 Rev3. Documentación de hardware",
               "Nano. Documentación de hardware", "Bambu Lab A1: Specifications",
               "Implementation of the Pure Pursuit Path Tracking Algorithm (CMU-RI-TR-92-01)",
               "MD22 – Dual 24 Volt 5 Amp H Bridge Motor Drive: Technical Documentation",
               "Digital Twin: mitigating unpredictable, undesirable emergent behavior in complex systems",
               "A new approach to linear filtering and prediction problems",
               "PIC16F87XA Data Sheet: 28/40/44-Pin Enhanced Flash Microcontrollers (DS39582B)",
               "Get Started With Jetson Nano Developer Kit", "UM10204: I²C-bus specification and user manual, Rev. 7.0",
               "Vehicle Dynamics and Control, 2.ª ed.",
               "Automatic Steering Methods for Autonomous Automobile Path Tracking (CMU-RI-TR-09-08)",
               "Three.js – JavaScript 3D Library", "An Introduction to the Kalman Filter (TR 95-041)",
               "WebXR Device API. Candidate Recommendation Draft",
               "Control de vehículo robótico por Inteligencia Artificial",
               "Robotic Vehicle Support Structure: 3D Prints Design Summary, v3",
               "Chat Summaries: Additional Electronic Components to Consider"),
  Tipo = c("Hoja de datos", "Documentación técnica", "Documentación técnica", "Hoja de datos", "Informe técnico",
           "Documentación técnica", "Capítulo de libro", "Artículo de revista", "Hoja de datos", "Documentación técnica",
           "Especificación", "Libro", "Informe técnico", "Documentación técnica", "Informe técnico", "Especificación",
           "Documento interno", "Documento interno", "Documento interno"),
  Tema = c("Sensores", "Microcontroladores", "Microcontroladores", "Fabricación aditiva", "Seguimiento de trayectorias",
           "Electrónica de potencia", "Gemelo digital", "Estimación", "Microcontroladores", "Cómputo de borde",
           "Comunicación serie", "Seguimiento de trayectorias", "Seguimiento de trayectorias", "Realidad Aumentada",
           "Estimación", "Realidad Aumentada", "Antecedente del vehículo", "Fabricación aditiva", "Componentes electrónicos"),
  `Dónde se usa` = c("Cap. 4 (DS18B20)", "Caps. 2, 3, 5", "Caps. 2, 3, 5", "Cap. 3 (sección 3.8)", "Caps. 2, 7",
                     "Caps. 2, 3, 4", "Caps. 1, 2, 8", "Caps. 1, 2, 7", "Caps. 2, 3, 4, 5", "Caps. 2, 3, 5",
                     "Caps. 2, 5", "Caps. 2, 7", "Caps. 1, 2, 7, 8", "Caps. 2, 6", "Caps. 1, 2, 7", "Caps. 1, 2, 6, 7",
                     "Caps. 1, 3, 4", "Cap. 3", "Cap. 5"),
  Enlace = c("https://www.analog.com/en/products/ds18b20.html", "https://docs.arduino.cc/hardware/mega-2560",
             "https://docs.arduino.cc/hardware/nano",
             "https://cdn.shopify.com/s/files/1/0635/8247/0318/files/A1_Spec_EN_1.pdf",
             "https://publications.ri.cmu.edu/implementation-of-the-pure-pursuit-path-tracking-algorithm",
             "https://www.robot-electronics.co.uk/htm/md22tech.htm", "https://doi.org/10.1007/978-3-319-38756-7_4",
             "https://doi.org/10.1115/1.3662552", "https://ww1.microchip.com/downloads/en/devicedoc/39582b.pdf",
             "https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit",
             "https://www.nxp.com/docs/en/user-guide/UM10204.pdf", "https://doi.org/10.1007/978-1-4614-1433-9",
             "https://publications.ri.cmu.edu/automatic-steering-methods-for-autonomous-automobile-path-tracking",
             "https://threejs.org/", "https://www.cs.unc.edu/~welch/kalman/kalmanIntro.html", "https://www.w3.org/TR/webxr/",
             "", "", "")
)
