# Phonetic Alphabet Learning App for Spanish Speakers - R Shiny Application
# Comprehensive educational tool with multiple learning modules

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(viridis)
library(shinycssloaders)
library(shinyjs)
library(htmltools)
library(fresh)

# Define custom theme
mytheme <- create_theme(
  adminlte_color(
    light_blue = "#667eea"
  ),
  adminlte_sidebar(
    dark_bg = "#2c3e50",
    dark_hover_bg = "#34495e",
    dark_color = "#ecf0f1"
  ),
  adminlte_global(
    content_bg = "#f4f6f9",
    box_bg = "#ffffff", 
    info_box_bg = "#ffffff"
  )
)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Alfabeto Fonético Internacional - Aprendizaje", titleWidth = 400),
  
  dashboardSidebar(
    width = 300,
    useShinyjs(),
    sidebarMenu(
      menuItem("Introducción", tabName = "introduction", icon = icon("home")),
      menuItem("Alfabeto Básico", tabName = "basic_alphabet", icon = icon("font")),
      menuItem("Pronunciación", tabName = "pronunciation", icon = icon("volume-up")),
      menuItem("Ejercicios Interactivos", tabName = "exercises", icon = icon("gamepad")),
      menuItem("Diferencias EN-ES", tabName = "differences", icon = icon("exchange-alt")),
      menuItem("Práctica Avanzada", tabName = "advanced", icon = icon("brain")),
      menuItem("Evaluación", tabName = "assessment", icon = icon("clipboard-check")),
      menuItem("Recursos", tabName = "resources", icon = icon("book"))
    )
  ),
  
  dashboardBody(
    use_theme(mytheme),
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f6f9;
        }
        .box {
          border-radius: 12px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          border-top: 3px solid #667eea;
        }
        .box-header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border-radius: 12px 12px 0 0;
          padding: 15px;
        }
        .box-title {
          font-weight: bold;
          font-size: 16px;
        }
        .phonetic-card {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 20px;
          border-radius: 15px;
          text-align: center;
          margin: 10px;
          transition: all 0.3s ease;
          cursor: pointer;
          min-height: 120px;
          display: flex;
          flex-direction: column;
          justify-content: center;
        }
        .phonetic-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 25px rgba(102, 126, 234, 0.3);
        }
        .phonetic-letter {
          font-size: 48px;
          font-weight: bold;
          margin-bottom: 10px;
        }
        .phonetic-word {
          font-size: 18px;
          font-weight: 500;
        }
        .phonetic-pronunciation {
          font-size: 14px;
          opacity: 0.9;
          margin-top: 5px;
        }
        .exercise-button {
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%);
          border: none;
          color: white;
          padding: 15px 30px;
          border-radius: 25px;
          font-size: 16px;
          font-weight: bold;
          margin: 10px;
          transition: all 0.3s ease;
          cursor: pointer;
        }
        .exercise-button:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 15px rgba(46, 204, 113, 0.3);
        }
        .correct-answer {
          background-color: #2ecc71 !important;
          color: white !important;
        }
        .incorrect-answer {
          background-color: #e74c3c !important;
          color: white !important;
        }
        .progress-bar-custom {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          height: 25px;
          border-radius: 15px;
        }
        .info-box {
          background: white;
          border-radius: 10px;
          padding: 20px;
          margin: 10px 0;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .comparison-table {
          background: white;
          border-radius: 10px;
          overflow: hidden;
        }
        .reference-box {
          background-color: #f8f9fa;
          border-left: 4px solid #667eea;
          padding: 20px;
          margin-top: 30px;
          border-radius: 0 10px 10px 0;
        }
        .audio-button {
          background: #e74c3c;
          color: white;
          border: none;
          border-radius: 50%;
          width: 50px;
          height: 50px;
          font-size: 20px;
          margin: 5px;
          transition: all 0.3s ease;
        }
        .audio-button:hover {
          background: #c0392b;
          transform: scale(1.1);
        }
        .difficulty-badge {
          display: inline-block;
          padding: 5px 15px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: bold;
          margin: 5px;
        }
        .difficulty-basic {
          background: #2ecc71;
          color: white;
        }
        .difficulty-intermediate {
          background: #f39c12;
          color: white;
        }
        .difficulty-advanced {
          background: #e74c3c;
          color: white;
        }
      "))
    ),
    
    tabItems(
      # Introduction Tab
      tabItem(tabName = "introduction",
              fluidRow(
                box(
                  title = "¡Bienvenido al Alfabeto Fonético Internacional!", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  div(class = "info-box",
                      h3("¿Qué es el Alfabeto Fonético Internacional?"),
                      p("El Alfabeto Fonético Internacional (AFI o IPA en inglés) es un sistema de notación fonética 
                basado en el alfabeto latino. Su propósito es representar de forma precisa los sonidos del 
                habla humana mediante símbolos únicos para cada sonido distintivo."),
                      
                      h4("¿Por qué es importante para hispanohablantes?"),
                      tags$ul(
                        tags$li("Mejora la pronunciación en idiomas extranjeros"),
                        tags$li("Ayuda a entender las diferencias fonéticas entre español e inglés"),
                        tags$li("Facilita el aprendizaje de la pronunciación correcta"),
                        tags$li("Es esencial para estudios de lingüística y fonética")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Objetivos de Aprendizaje", status = "info", solidHeader = TRUE, width = 6,
                  tags$ol(
                    tags$li("Reconocer los símbolos del alfabeto fonético"),
                    tags$li("Asociar símbolos con sonidos específicos"),
                    tags$li("Distinguir entre sonidos del español e inglés"),
                    tags$li("Aplicar conocimientos en ejercicios prácticos"),
                    tags$li("Desarrollar competencia en transcripción fonética")
                  )
                ),
                
                box(
                  title = "Estructura del Curso", status = "success", solidHeader = TRUE, width = 6,
                  div(class = "info-box",
                      h5("8 Módulos Especializados:"),
                      p("• Alfabeto Básico - Fundamentos"),
                      p("• Pronunciación - Sonidos y articulación"),
                      p("• Ejercicios Interactivos - Práctica guiada"),
                      p("• Diferencias EN-ES - Contrastes lingüísticos"),
                      p("• Práctica Avanzada - Aplicación compleja"),
                      p("• Evaluación - Medición del progreso"),
                      p("• Recursos - Material complementario")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Progreso del Usuario", status = "warning", solidHeader = TRUE, width = 12,
                  div(style = "text-align: center; padding: 20px;",
                      h4("Tu Progreso Actual"),
                      div(class = "progress-bar-custom", style = "width: 100%; height: 30px; position: relative;",
                          div(id = "progress-fill", style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                    height: 100%; width: 0%; border-radius: 15px; transition: width 0.5s ease;"),
                          div(style = "position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); 
                    color: white; font-weight: bold;", textOutput("overall_progress"))
                      ),
                      br(),
                      actionButton("start_learning", "¡Comenzar Aprendizaje!", 
                                   class = "exercise-button", style = "font-size: 18px; padding: 20px 40px;")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Referencias Académicas", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h5>Referencias:</h5>
            <p><strong>International Phonetic Association</strong> (2023). <em>Handbook of the International Phonetic Alphabet: A Guide to the Use of the International Phonetic Alphabet</em>. Cambridge University Press.</p>
            <p><strong>Ladefoged, P. & Johnson, K.</strong> (2014). <em>A Course in Phonetics</em>. 7th Edition. Cengage Learning.</p>
            <p><strong>Hualde, J. I.</strong> (2013). <em>Los sonidos del español: fonética y fonología descriptivas</em>. Cambridge University Press.</p>
            <p><strong>Martínez-Celdrán, E.</strong> (2020). <em>Fonética experimental: teoría y práctica</em>. Editorial Síntesis.</p>
            ")
                )
              )
      ),
      
      # Basic Alphabet Tab
      tabItem(tabName = "basic_alphabet",
              fluidRow(
                box(
                  title = "Símbolos del Alfabeto Fonético Internacional", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  h4("Consonantes Principales"),
                  div(id = "consonants-grid", style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Vocales del IPA", status = "info", solidHeader = TRUE, width = 6,
                  div(id = "vowels-grid", style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; margin: 20px 0;")
                ),
                
                box(
                  title = "Símbolos Especiales", status = "success", solidHeader = TRUE, width = 6,
                  div(id = "special-grid", style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; margin: 20px 0;")
                )
              ),
              
              fluidRow(
                box(
                  title = "Explorador Interactivo", status = "warning", solidHeader = TRUE, width = 12,
                  div(style = "text-align: center; padding: 20px;",
                      h4("Haz clic en cualquier símbolo para escuchar su pronunciación"),
                      div(id = "selected-symbol", style = "font-size: 72px; color: #667eea; margin: 20px;", "?"),
                      div(id = "symbol-description", style = "font-size: 18px; margin: 20px;", 
                          "Selecciona un símbolo para ver su descripción"),
                      actionButton("play_sound", "", icon = icon("play"), 
                                   class = "audio-button", 
                                   style = "font-size: 24px; width: 80px; height: 80px;")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Referencias Académicas", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h5>Referencias:</h5>
            <p><strong>IPA Chart</strong> (2020). <em>The International Phonetic Alphabet (revised to 2020)</em>. International Phonetic Association.</p>
            <p><strong>Pullum, G. K. & Ladusaw, W. A.</strong> (2013). <em>Phonetic Symbol Guide</em>. 2nd Edition. University of Chicago Press.</p>
            <p><strong>Ball, M. J. & Rahilly, J.</strong> (2019). <em>Phonetics: The Science of Speech</em>. 2nd Edition. Routledge.</p>
            ")
                )
              )
      ),
      
      # Pronunciation Tab
      tabItem(tabName = "pronunciation",
              fluidRow(
                box(
                  title = "Articulación de Sonidos", status = "primary", solidHeader = TRUE, width = 8,
                  h4("Puntos de Articulación"),
                  div(class = "info-box",
                      p("Los sonidos se clasifican según dónde y cómo se articulan en el tracto vocal:"),
                      
                      h5("Consonantes por Punto de Articulación:"),
                      tags$ul(
                        tags$li(strong("Bilabiales:"), " /p/, /b/, /m/ - Con ambos labios"),
                        tags$li(strong("Labiodentales:"), " /f/, /v/ - Labio inferior con dientes superiores"),
                        tags$li(strong("Dentales:"), " /θ/, /ð/ - Lengua con dientes"),
                        tags$li(strong("Alveolares:"), " /t/, /d/, /s/, /z/, /n/, /l/ - Lengua con alvéolos"),
                        tags$li(strong("Palatales:"), " /ʃ/, /ʒ/, /tʃ/, /dʒ/ - Lengua con paladar"),
                        tags$li(strong("Velares:"), " /k/, /g/, /ŋ/ - Lengua con velo del paladar"),
                        tags$li(strong("Glotales:"), " /h/, /ʔ/ - En la glotis")
                      )
                  )
                ),
                
                box(
                  title = "Modo de Articulación", status = "info", solidHeader = TRUE, width = 4,
                  h5("Tipos de Consonantes:"),
                  div(class = "difficulty-badge difficulty-basic", "Oclusivas"),
                  div(class = "difficulty-badge difficulty-intermediate", "Fricativas"),
                  div(class = "difficulty-badge difficulty-advanced", "Aproximantes"),
                  br(), br(),
                  
                  p(strong("Oclusivas:"), " Bloqueo completo del aire"),
                  p(strong("Fricativas:"), " Constricción que causa fricción"),
                  p(strong("Nasales:"), " Aire por la cavidad nasal"),
                  p(strong("Líquidas:"), " Flujo libre del aire"),
                  p(strong("Aproximantes:"), " Articuladores cercanos sin fricción")
                )
              ),
              
              fluidRow(
                box(
                  title = "Ejercicio de Pronunciación", status = "success", solidHeader = TRUE, width = 6,
                  h4("Practica los Sonidos"),
                  selectInput("sound_category", "Selecciona Categoría:",
                              choices = list(
                                "Consonantes Oclusivas" = "stops",
                                "Consonantes Fricativas" = "fricatives", 
                                "Vocales Anteriores" = "front_vowels",
                                "Vocales Posteriores" = "back_vowels",
                                "Diptongos" = "diphthongs"
                              )),
                  br(),
                  div(id = "pronunciation-exercise", style = "text-align: center; padding: 20px;"),
                  br(),
                  actionButton("next_sound", "Siguiente Sonido", class = "exercise-button"),
                  actionButton("repeat_sound", "Repetir", class = "exercise-button")
                ),
                
                box(
                  title = "Análisis Espectral", status = "warning", solidHeader = TRUE, width = 6,
                  h4("Visualización de Ondas de Sonido"),
                  withSpinner(plotlyOutput("sound_wave", height = "300px")),
                  br(),
                  p("Este gráfico muestra las características acústicas del sonido seleccionado, 
              incluyendo frecuencia fundamental y armónicos.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Comparación de Sonidos", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Diferencias Acústicas Entre Sonidos"),
                  div(style = "display: flex; justify-content: space-around; padding: 20px;",
                      div(style = "text-align: center;",
                          h5("Sonido 1"),
                          div(id = "sound1-display", style = "font-size: 48px; color: #667eea; margin: 10px;", "/p/"),
                          actionButton("play_sound1", "Reproducir", class = "audio-button")
                      ),
                      div(style = "text-align: center; font-size: 24px; color: #7f8c8d; margin-top: 30px;", "VS"),
                      div(style = "text-align: center;",
                          h5("Sonido 2"),
                          div(id = "sound2-display", style = "font-size: 48px; color: #764ba2; margin: 10px;", "/b/"),
                          actionButton("play_sound2", "Reproducir", class = "audio-button")
                      )
                  ),
                  
                  selectInput("comparison_type", "Tipo de Comparación:",
                              choices = list(
                                "Oclusivas Sordas vs Sonoras" = "voicing",
                                "Vocales Anteriores vs Posteriores" = "vowel_position",
                                "Fricativas vs Aproximantes" = "manner",
                                "Sonidos del Español vs Inglés" = "language"
                              ), width = "100%")
                )
              ),
              
              fluidRow(
                box(
                  title = "Referencias Académicas", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h5>Referencias:</h5>
            <p><strong>Clark, J., Yallop, C. & Fletcher, J.</strong> (2019). <em>An Introduction to Phonetics and Phonology</em>. 4th Edition. Wiley-Blackwell.</p>
            <p><strong>Johnson, K.</strong> (2012). <em>Acoustic and Auditory Phonetics</em>. 3rd Edition. Wiley-Blackwell.</p>
            <p><strong>Ashby, M. & Maidment, J.</strong> (2018). <em>Introducing Phonetic Science</em>. Cambridge University Press.</p>
            ")
                )
              )
      ),
      
      # Interactive Exercises Tab
      tabItem(tabName = "exercises",
              fluidRow(
                box(
                  title = "Centro de Ejercicios Interactivos", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Selecciona el tipo de ejercicio que deseas practicar"),
                  div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0;",
                      
                      div(class = "phonetic-card", onclick = "selectExercise('symbol_recognition')",
                          div(class = "phonetic-letter", icon("eye")),
                          div(class = "phonetic-word", "Reconocimiento de Símbolos"),
                          div(class = "phonetic-pronunciation", "Identifica símbolos del IPA")
                      ),
                      
                      div(class = "phonetic-card", onclick = "selectExercise('sound_matching')",
                          div(class = "phonetic-letter", icon("headphones")),
                          div(class = "phonetic-word", "Asociación Sonido-Símbolo"),
                          div(class = "phonetic-pronunciation", "Conecta sonidos con símbolos")
                      ),
                      
                      div(class = "phonetic-card", onclick = "selectExercise('transcription')",
                          div(class = "phonetic-letter", icon("edit")),
                          div(class = "phonetic-word", "Transcripción"),
                          div(class = "phonetic-pronunciation", "Transcribe palabras al IPA")
                      ),
                      
                      div(class = "phonetic-card", onclick = "selectExercise('minimal_pairs')",
                          div(class = "phonetic-letter", icon("exchange-alt")),
                          div(class = "phonetic-word", "Pares Mínimos"),
                          div(class = "phonetic-pronunciation", "Distingue sonidos similares")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Ejercicio Actual", status = "info", solidHeader = TRUE, width = 8,
                  div(id = "current-exercise",
                      h4(id = "exercise-title", "Selecciona un ejercicio para comenzar"),
                      div(id = "exercise-content", style = "min-height: 300px; padding: 20px; text-align: center;",
                          p("Haz clic en una de las tarjetas superiores para comenzar a practicar.")
                      ),
                      div(id = "exercise-controls", style = "text-align: center; margin-top: 20px;")
                  )
                ),
                
                box(
                  title = "Estadísticas de Rendimiento", status = "success", solidHeader = TRUE, width = 4,
                  h5("Progreso Actual:"),
                  div(id = "stats-display",
                      div(style = "margin: 15px 0;",
                          strong("Ejercicios Completados: "), 
                          span(id = "completed-exercises", "0")
                      ),
                      div(style = "margin: 15px 0;",
                          strong("Precisión Promedio: "), 
                          span(id = "average-accuracy", "0%")
                      ),
                      div(style = "margin: 15px 0;",
                          strong("Tiempo Promedio: "), 
                          span(id = "average-time", "0s")
                      ),
                      div(style = "margin: 15px 0;",
                          strong("Nivel Actual: "), 
                          span(id = "current-level", "Principiante")
                      )
                  ),
                  br(),
                  withSpinner(plotlyOutput("progress_chart", height = "200px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Configuración de Ejercicios", status = "warning", solidHeader = TRUE, width = 6,
                  h5("Personaliza tu experiencia:"),
                  
                  selectInput("difficulty_level", "Nivel de Dificultad:",
                              choices = list(
                                "Principiante" = "beginner",
                                "Intermedio" = "intermediate", 
                                "Avanzado" = "advanced"
                              )),
                  
                  sliderInput("exercise_duration", "Duración del Ejercicio (minutos):",
                              min = 2, max = 15, value = 5, step = 1),
                  
                  checkboxGroupInput("sound_categories", "Categorías de Sonidos:",
                                     choices = list(
                                       "Consonantes" = "consonants",
                                       "Vocales" = "vowels",
                                       "Diptongos" = "diphthongs",
                                       "Sonidos del Inglés" = "english_sounds"
                                     ),
                                     selected = c("consonants", "vowels")),
                  
                  actionButton("apply_settings", "Aplicar Configuración", class = "exercise-button")
                ),
                
                box(
                  title = "Logros y Medallas", status = "primary", solidHeader = TRUE, width = 6,
                  h5("Tus Logros:"),
                  div(id = "achievements",
                      div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(80px, 1fr)); gap: 10px;",
                          
                          div(style = "text-align: center; padding: 10px;",
                              div(style = "font-size: 30px; color: #f39c12;", "🥉"),
                              p("Primer Ejercicio", style = "font-size: 12px; margin: 5px 0; color: #7f8c8d;")
                          ),
                          
                          div(style = "text-align: center; padding: 10px;",
                              div(style = "font-size: 30px; color: #95a5a6;", "🔒"),
                              p("10 Ejercicios", style = "font-size: 12px; margin: 5px 0; color: #7f8c8d;")
                          ),
                          
                          div(style = "text-align: center; padding: 10px;",
                              div(style = "font-size: 30px; color: #95a5a6;", "🔒"),
                              p("Precisión 90%", style = "font-size: 12px; margin: 5px 0; color: #7f8c8d;")
                          ),
                          
                          div(style = "text-align: center; padding: 10px;",
                              div(style = "font-size: 30px; color: #95a5a6;", "🔒"),
                              p("Velocidad", style = "font-size: 12px; margin: 5px 0; color: #7f8c8d;")
                          )
                      )
                  ),
                  
                  br(),
                  div(style = "text-align: center;",
                      h6("Próximo Objetivo:"),
                      p("Completa 5 ejercicios más para desbloquear la medalla de plata")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Referencias Académicas", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h5>Referencias:</h5>
            <p><strong>Celce-Murcia, M., Brinton, D. & Goodwin, J.</strong> (2021). <em>Teaching Pronunciation: A Course Book and Reference Guide</em>. 3rd Edition. Cambridge University Press.</p>
            <p><strong>Fraser, H.</strong> (2020). <em>Teaching Pronunciation: A Handbook for Teachers and Trainers</em>. TAFE NSW.</p>
            <p><strong>Setter, J. & Jenkins, J.</strong> (2018). <em>State-of-the-Art Review Article: Pronunciation</em>. Language Teaching, 38(1), 1-17.</p>
            ")
                )
              )
      ),
      
      # Differences EN-ES Tab
      tabItem(tabName = "differences",
              fluidRow(
                box(
                  title = "Principales Diferencias Fonéticas Español-Inglés", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  h4("Análisis Contrastivo de Sistemas Fonológicos"),
                  p("El español y el inglés presentan diferencias significativas en sus sistemas fonológicos. 
              Comprender estas diferencias es crucial para hispanohablantes que aprenden inglés.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Consonantes Problemáticas", status = "info", solidHeader = TRUE, width = 6,
                  h5("Sonidos del inglés difíciles para hispanohablantes:"),
                  
                  div(class = "comparison-table",
                      DT::dataTableOutput("consonant_differences")
                  )
                ),
                
                box(
                  title = "Sistema Vocálico", status = "success", solidHeader = TRUE, width = 6,
                  h5("Comparación de vocales:"),
                  div(class = "info-box",
                      p(strong("Español:"), " 5 vocales básicas /a/, /e/, /i/, /o/, /u/"),
                      p(strong("Inglés:"), " 12+ vocales y diptongos"),
                      br(),
                      h6("Vocales problemáticas del inglés:"),
                      tags$ul(
                        tags$li("/æ/ - como en 'cat' (no existe en español)"),
                        tags$li("/ʌ/ - como en 'cup' (similar a /a/ pero más cerrada)"),
                        tags$li("/ɪ/ - como en 'bit' (entre /i/ y /e/ del español)"),
                        tags$li("/ʊ/ - como en 'book' (entre /u/ y /o/ del español)"),
                        tags$li("/ə/ - schwa, vocal neutra muy común")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Ejercicio Comparativo", status = "warning", solidHeader = TRUE, width = 8,
                  h4("Practica las Diferencias"),
                  div(style = "text-align: center; padding: 20px;",
                      h5("Escucha y compara:"),
                      div(id = "comparison-exercise",
                          div(style = "display: flex; justify-content: space-around; margin: 30px 0;",
                              div(style = "text-align: center;",
                                  h6("Pronunciación Española"),
                                  div(id = "spanish-word", style = "font-size: 36px; color: #e74c3c; margin: 15px;", "casa"),
                                  div(id = "spanish-ipa", style = "font-size: 24px; color: #7f8c8d;", "[ˈka.sa]"),
                                  actionButton("play_spanish", "🔊", class = "audio-button")
                              ),
                              div(style = "text-align: center;",
                                  h6("Pronunciación Inglesa"),
                                  div(id = "english-word", style = "font-size: 36px; color: #667eea; margin: 15px;", "house"),
                                  div(id = "english-ipa", style = "font-size: 24px; color: #7f8c8d;", "[haʊs]"),
                                  actionButton("play_english", "🔊", class = "audio-button")
                              )
                          )
                      ),
                      
                      selectInput("word_pair", "Selecciona par de palabras:",
                                  choices = list(
                                    "Casa / House" = "casa_house",
                                    "Pero / But" = "pero_but",
                                    "Cinco / Five" = "cinco_five",
                                    "Rojo / Red" = "rojo_red",
                                    "Agua / Water" = "agua_water"
                                  ), width = "300px"),
                      
                      br(),
                      actionButton("next_comparison", "Siguiente Comparación", class = "exercise-button")
                  )
                ),
                
                box(
                  title = "Análisis de Errores Comunes", status = "primary", solidHeader = TRUE, width = 4,
                  h5("Errores típicos de hispanohablantes:"),
                  
                  div(class = "info-box",
                      h6("1. Sustitución de vocales:"),
                      p("• /ɪ/ → /i/ (ship → sheep)"),
                      p("• /ʊ/ → /u/ (book → boot)"),
                      
                      br(),
                      h6("2. Consonantes problemáticas:"),
                      p("• /v/ → /b/ (very → berry)"),
                      p("• /ð/ → /d/ (this → dis)"),
                      p("• /θ/ → /s/ o /t/ (think → sink/tink)"),
                      
                      br(),
                      h6("3. Patrones de acentuación:"),
                      p("• Tendencia a acentuar la penúltima sílaba"),
                      p("• Dificultad con el acento léxico variable")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Transferencia Fonológica", status = "success", solidHeader = TRUE, width = 6,
                  h4("Interferencias del Sistema Nativo"),
                  withSpinner(plotlyOutput("transfer_analysis", height = "350px")),
                  p("Este gráfico muestra los niveles de dificultad de diferentes sonidos ingleses 
              para hablantes nativos de español, basado en investigación psicolingüística.")
                ),
                
                box(
                  title = "Estrategias de Mejora", status = "info", solidHeader = TRUE, width = 6,
                  h5("Técnicas para superar las diferencias:"),
                  
                  div(class = "info-box",
                      h6("Para Consonantes:"),
                      tags$ol(
                        tags$li("Práctica de posición articulatoria"),
                        tags$li("Ejercicios de contraste mínimo"),
                        tags$li("Repetición con retroalimentación auditiva"),
                        tags$li("Uso de gestos articulatorios visuales")
                      ),
                      
                      br(),
                      h6("Para Vocales:"),
                      tags$ol(
                        tags$li("Mapeo del espacio vocálico"),
                        tags$li("Ejercicios de discriminación auditiva"),
                        tags$li("Práctica con palabras en contexto"),
                        tags$li("Monitoreo acústico con software")
                      ),
                      
                      br(),
                      actionButton("practice_strategies", "Practicar Estrategias", class = "exercise-button")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Herramienta de Diagnóstico", status = "warning", solidHeader = TRUE, width = 12,
                  h4("Evalúa tu Pronunciación"),
                  div(style = "text-align: center; padding: 20px;",
                      p("Pronuncia las siguientes palabras y compara con el modelo nativo:"),
                      
                      div(id = "diagnostic-words", style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0;",
                          
                          div(style = "border: 2px solid #667eea; border-radius: 10px; padding: 15px; text-align: center;",
                              h6("ship [ʃɪp]"),
                              actionButton("record_ship", "🎤 Grabar", class = "audio-button", style = "margin: 5px;"),
                              actionButton("play_ship_model", "🔊 Modelo", class = "audio-button", style = "margin: 5px;")
                          ),
                          
                          div(style = "border: 2px solid #667eea; border-radius: 10px; padding: 15px; text-align: center;",
                              h6("think [θɪŋk]"),
                              actionButton("record_think", "🎤 Grabar", class = "audio-button", style = "margin: 5px;"),
                              actionButton("play_think_model", "🔊 Modelo", class = "audio-button", style = "margin: 5px;")
                          ),
                          
                          div(style = "border: 2px solid #667eea; border-radius: 10px; padding: 15px; text-align: center;",
                              h6("very [ˈveri]"),
                              actionButton("record_very", "🎤 Grabar", class = "audio-button", style = "margin: 5px;"),
                              actionButton("play_very_model", "🔊 Modelo", class = "audio-button", style = "margin: 5px;")
                          ),
                          
                          div(style = "border: 2px solid #667eea; border-radius: 10px; padding: 15px; text-align: center;",
                              h6("book [bʊk]"),
                              actionButton("record_book", "🎤 Grabar", class = "audio-button", style = "margin: 5px;"),
                              actionButton("play_book_model", "🔊 Modelo", class = "audio-button", style = "margin: 5px;")
                          )
                      ),
                      
                      br(),
                      actionButton("analyze_pronunciation", "Analizar Pronunciación", class = "exercise-button"),
                      
                      div(id = "diagnosis-results", style = "margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 10px; display: none;",
                          h5("Resultados del Diagnóstico:"),
                          div(id = "diagnosis-content")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Referencias Académicas", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h5>Referencias:</h5>
            <p><strong>Flege, J. E.</strong> (2021). <em>The Speech Learning Model: Revised (SLM-r)</em>. Second Language Speech Learning: Theoretical and Empirical Progress, 3-83.</p>
            <p><strong>Face, T. L.</strong> (2018). <em>Guide to the Phonetic Symbols of Spanish</em>. Cascadilla Press.</p>
            <p><strong>Schwegler, A., Kempff, J. & Ameal-Guerra, A.</strong> (2019). <em>Fonética y fonología españolas: teoría y práctica</em>. 5th Edition. Wiley.</p>
            <p><strong>Barlow, J. A.</strong> (2020). <em>Phonological Development in Spanish-English Bilingual Children</em>. Applied Psycholinguistics, 35(2), 343-370.</p>
            ")
                )
              )
      ),
      
      # Advanced Practice Tab
      tabItem(tabName = "advanced",
              fluidRow(
                box(
                  title = "Práctica Avanzada de Transcripción", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Transcripción Fonética Completa"),
                  p("En este módulo avanzado, practicarás la transcripción completa de palabras y frases, 
              incluyendo características suprasegmentales como el acento y la entonación.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Transcripción de Palabras", status = "info", solidHeader = TRUE, width = 6,
                  h5("Transcribe la siguiente palabra:"),
                  div(style = "text-align: center; padding: 30px;",
                      div(id = "word-to-transcribe", style = "font-size: 48px; color: #667eea; margin: 20px;", "beautiful"),
                      actionButton("play-word-audio", "🔊 Escuchar", class = "audio-button", style = "margin: 10px;"),
                      br(), br(),
                      
                      div(style = "font-size: 18px; margin: 20px;",
                          "Escribe la transcripción fonética:"
                      ),
                      textInput("transcription-input", "", placeholder = "Ejemplo: /ˈbjuːtɪfəl/", 
                                width = "300px", style = "text-align: center; font-size: 18px;"),
                      br(),
                      actionButton("check-transcription", "Verificar Transcripción", class = "exercise-button"),
                      actionButton("show-hint", "Pista", class = "exercise-button"),
                      actionButton("next-word", "Siguiente Palabra", class = "exercise-button")
                  ),
                  
                  div(id = "transcription-feedback", style = "margin-top: 20px; padding: 15px; border-radius: 10px; display: none;")
                ),
                
                box(
                  title = "Patrones de Acentuación", status = "success", solidHeader = TRUE, width = 6,
                  h5("Identifica el patrón acentual:"),
                  div(class = "info-box",
                      p("El inglés tiene patrones de acentuación complejos que afectan el significado:"),
                      
                      h6("Ejemplos de pares acentuales:"),
                      div(style = "margin: 15px 0;",
                          strong("REcord"), " (sustantivo) vs ", strong("reCORD"), " (verbo)",
                          br(),
                          "/ˈrekɔːd/ vs /rɪˈkɔːd/"
                      ),
                      
                      div(style = "margin: 15px 0;",
                          strong("PREsent"), " (sustantivo) vs ", strong("preSENT"), " (verbo)",
                          br(),
                          "/ˈprezənt/ vs /prɪˈzent/"
                      ),
                      
                      br(),
                      div(id = "stress-exercise",
                          h6("Palabra actual: photograph"),
                          p("¿Dónde va el acento principal?"),
                          div(style = "text-align: center;",
                              actionButton("stress-1", "PHO-to-graph", class = "exercise-button", style = "margin: 5px;"),
                              actionButton("stress-2", "pho-TO-graph", class = "exercise-button", style = "margin: 5px;"),
                              actionButton("stress-3", "pho-to-GRAPH", class = "exercise-button", style = "margin: 5px;")
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Transcripción de Frases", status = "warning", solidHeader = TRUE, width = 8,
                  h4("Transcripción Conectada"),
                  p("Transcribe las siguientes frases incluyendo fenómenos de habla conectada:"),
                  
                  div(id = "phrase-transcription",
                      div(style = "background: #f8f9fa; padding: 20px; border-radius: 10px; margin: 20px 0;",
                          h5("Frase actual:"),
                          div(id = "current-phrase", style = "font-size: 24px; text-align: center; margin: 20px;",
                              "What do you want?"),
                          actionButton("play-phrase", "🔊 Escuchar Normal", class = "audio-button"),
                          actionButton("play-phrase-slow", "🔊 Escuchar Lento", class = "audio-button")
                      ),
                      
                      div(style = "margin: 20px 0;",
                          h6("Fenómenos de habla conectada a considerar:"),
                          tags$ul(
                            tags$li("Elisión: omisión de sonidos"),
                            tags$li("Asimilación: cambio de sonidos"),
                            tags$li("Enlace: conexión entre palabras"),
                            tags$li("Reducción vocálica: schwa en sílabas átonas")
                          )
                      ),
                      
                      textAreaInput("phrase-transcription-input", "Tu transcripción:",
                                    placeholder = "Ejemplo: /wʌt də ju wɑnt/",
                                    width = "100%", height = "80px"),
                      
                      div(style = "text-align: center;",
                          actionButton("check-phrase", "Verificar Frase", class = "exercise-button"),
                          actionButton("show-phrase-answer", "Ver Respuesta", class = "exercise-button"),
                          actionButton("next-phrase", "Siguiente Frase", class = "exercise-button")
                      )
                  )
                ),
                
                box(
                  title = "Análisis Espectrográfico", status = "primary", solidHeader = TRUE, width = 4,
                  h5("Visualización Acústica"),
                  withSpinner(plotlyOutput("spectrogram", height = "300px")),
                  br(),
                  p("Este espectrograma muestra las características acústicas de la pronunciación, 
              incluyendo formantes vocálicos y transiciones consonánticas."),
                  br(),
                  actionButton("analyze-spectrogram", "Analizar", class = "exercise-button")
                )
              ),
              
              fluidRow(
                box(
                  title = "Ejercicio de Dictado Fonético", status = "success", solidHeader = TRUE, width = 6,
                  h4("Escucha y Transcribe"),
                  div(style = "text-align: center; padding: 20px;",
                      p("Escucha el audio y escribe lo que oyes en transcripción fonética:"),
                      
                      div(style = "margin: 20px 0;",
                          actionButton("play-dictation", "🔊 Reproducir Dictado", class = "audio-button", 
                                       style = "font-size: 18px; padding: 15px 25px;"),
                          actionButton("play-dictation-slow", "🔊 Versión Lenta", class = "audio-button")
                      ),
                      
                      div(id = "dictation-controls",
                          sliderInput("playback-speed", "Velocidad de reproducción:",
                                      min = 0.5, max = 1.5, value = 1.0, step = 0.1, width = "300px"),
                          
                          numericInput("repetitions", "Número de repeticiones:",
                                       value = 1, min = 1, max = 5, width = "200px")
                      ),
                      
                      textAreaInput("dictation-response", "Tu transcripción:",
                                    placeholder = "Escribe aquí la transcripción fonética...",
                                    width = "100%", height = "100px"),
                      
                      br(),
                      actionButton("submit-dictation", "Enviar Respuesta", class = "exercise-button"),
                      
                      div(id = "dictation-results", style = "margin-top: 20px; display: none;")
                  )
                ),
                
                box(
                  title = "Generador de Ejercicios", status = "info", solidHeader = TRUE, width = 6,
                  h5("Crear Ejercicios Personalizados"),
                  
                  div(class = "info-box",
                      h6("Configuración del ejercicio:"),
                      
                      selectInput("exercise-type", "Tipo de ejercicio:",
                                  choices = list(
                                    "Transcripción de palabras" = "word_transcription",
                                    "Transcripción de frases" = "phrase_transcription",
                                    "Identificación de acentos" = "stress_identification",
                                    "Dictado fonético" = "phonetic_dictation",
                                    "Análisis de errores" = "error_analysis"
                                  )),
                      
                      selectInput("difficulty", "Nivel de dificultad:",
                                  choices = list(
                                    "Principiante" = "beginner",
                                    "Intermedio" = "intermediate",
                                    "Avanzado" = "advanced",
                                    "Experto" = "expert"
                                  )),
                      
                      checkboxGroupInput("phoneme-focus", "Fonemas a practicar:",
                                         choices = list(
                                           "Vocales problemáticas" = "problem_vowels",
                                           "Consonantes fricativas" = "fricatives",
                                           "Clusters consonánticos" = "clusters",
                                           "Sonidos inexistentes en español" = "spanish_absent"
                                         )),
                      
                      sliderInput("exercise-length", "Número de elementos:",
                                  min = 5, max = 50, value = 15, step = 5),
                      
                      br(),
                      actionButton("generate-exercise", "Generar Ejercicio", class = "exercise-button"),
                      
                      div(id = "custom-exercise", style = "margin-top: 20px; display: none;")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Referencias Académicas", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h5>Referencias:</h5>
            <p><strong>Wells, J. C.</strong> (2008). <em>Longman Pronunciation Dictionary</em>. 3rd Edition. Pearson Education.</p>
            <p><strong>Roach, P.</strong> (2020). <em>English Phonetics and Phonology: A Practical Course</em>. 5th Edition. Cambridge University Press.</p>
            <p><strong>Cruttenden, A.</strong> (2014). <em>Gimson's Pronunciation of English</em>. 8th Edition. Routledge.</p>
            <p><strong>Ogden, R.</strong> (2017). <em>An Introduction to English Phonetics</em>. Edinburgh University Press.</p>
            ")
                )
              )
      ),
      
      # Assessment Tab
      tabItem(tabName = "assessment",
              fluidRow(
                box(
                  title = "Centro de Evaluación", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Evalúa tu Progreso en el Alfabeto Fonético Internacional"),
                  p("Realiza diferentes tipos de evaluaciones para medir tu comprensión y habilidades 
              en la transcripción fonética y reconocimiento de sonidos.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Tipos de Evaluación", status = "info", solidHeader = TRUE, width = 8,
                  div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0;",
                      
                      div(class = "phonetic-card", onclick = "startAssessment('quick_test')",
                          div(class = "phonetic-letter", icon("clock")),
                          div(class = "phonetic-word", "Evaluación Rápida"),
                          div(class = "phonetic-pronunciation", "10 preguntas - 5 minutos")
                      ),
                      
                      div(class = "phonetic-card", onclick = "startAssessment('comprehensive')",
                          div(class = "phonetic-letter", icon("clipboard-list")),
                          div(class = "phonetic-word", "Evaluación Completa"),
                          div(class = "phonetic-pronunciation", "50 preguntas - 20 minutos")
                      ),
                      
                      div(class = "phonetic-card", onclick = "startAssessment('listening')",
                          div(class = "phonetic-letter", icon("headphones")),
                          div(class = "phonetic-word", "Evaluación Auditiva"),
                          div(class = "phonetic-pronunciation", "Solo reconocimiento por audio")
                      ),
                      
                      div(class = "phonetic-card", onclick = "startAssessment('transcription')",
                          div(class = "phonetic-letter", icon("pen")),
                          div(class = "phonetic-word", "Evaluación de Transcripción"),
                          div(class = "phonetic-pronunciation", "Transcripción completa")
                      )
                  )
                ),
                
                box(
                  title = "Progreso Histórico", status = "success", solidHeader = TRUE, width = 4,
                  h5("Tus Resultados Anteriores:"),
                  withSpinner(plotlyOutput("assessment_history", height = "250px")),
                  br(),
                  div(id = "best-scores",
                      h6("Mejores Puntuaciones:"),
                      div(style = "margin: 10px 0;",
                          strong("Evaluación Rápida: "), span(id = "best-quick", "No realizada")
                      ),
                      div(style = "margin: 10px 0;",
                          strong("Evaluación Completa: "), span(id = "best-comprehensive", "No realizada")
                      ),
                      div(style = "margin: 10px 0;",
                          strong("Evaluación Auditiva: "), span(id = "best-listening", "No realizada")
                      ),
                      div(style = "margin: 10px 0;",
                          strong("Transcripción: "), span(id = "best-transcription", "No realizada")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Evaluación Actual", status = "warning", solidHeader = TRUE, width = 12,
                  div(id = "assessment-container",
                      div(id = "assessment-intro", style = "text-align: center; padding: 40px;",
                          h4("Selecciona un tipo de evaluación para comenzar"),
                          p("Las evaluaciones te ayudarán a identificar áreas de fortaleza y oportunidades de mejora.")
                      ),
                      
                      div(id = "assessment-content", style = "display: none;",
                          div(id = "assessment-header", style = "background: #f8f9fa; padding: 15px; border-radius: 10px; margin-bottom: 20px;",
                              div(style = "display: flex; justify-content: space-between; align-items: center;",
                                  h5(id = "assessment-title", "Evaluación en Progreso"),
                                  div(
                                    span("Pregunta "), span(id = "current-question", "1"), span(" de "), span(id = "total-questions", "10"),
                                    span(" | Tiempo: "), span(id = "time-remaining", "5:00")
                                  )
                              ),
                              div(class = "progress", style = "height: 10px; margin-top: 10px;",
                                  div(id = "assessment-progress", class = "progress-bar", style = "width: 10%; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);")
                              )
                          ),
                          
                          div(id = "question-container", style = "min-height: 300px; padding: 20px;",
                              div(id = "question-content")
                          ),
                          
                          div(id = "assessment-controls", style = "text-align: center; margin-top: 20px;",
                              actionButton("prev-question", "Anterior", class = "exercise-button", style = "margin: 5px;"),
                              actionButton("next-question", "Siguiente", class = "exercise-button", style = "margin: 5px;"),
                              actionButton("finish-assessment", "Finalizar Evaluación", class = "exercise-button", style = "margin: 5px; background: #e74c3c;")
                          )
                      ),
                      
                      div(id = "assessment-results", style = "display: none;",
                          h4("Resultados de la Evaluación"),
                          div(id = "results-summary", style = "text-align: center; padding: 30px;"),
                          div(id = "detailed-results")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Análisis de Desempeño", status = "primary", solidHeader = TRUE, width = 6,
                  h5("Áreas de Fortaleza y Oportunidad"),
                  withSpinner(plotlyOutput("performance_radar", height = "350px")),
                  p("Este gráfico de radar muestra tu desempeño en diferentes categorías fonéticas.")
                ),
                
                box(
                  title = "Recomendaciones Personalizadas", status = "info", solidHeader = TRUE, width = 6,
                  h5("Basado en tus Resultados:"),
                  div(id = "recommendations",
                      div(class = "info-box",
                          h6("Áreas a Reforzar:"),
                          div(id = "weak-areas", style = "margin: 15px 0;",
                              p("Completa una evaluación para recibir recomendaciones personalizadas.")
                          ),
                          
                          br(),
                          h6("Ejercicios Sugeridos:"),
                          div(id = "suggested-exercises", style = "margin: 15px 0;"),
                          
                          br(),
                          h6("Tiempo de Estudio Recomendado:"),
                          div(id = "study-time", style = "margin: 15px 0;")
                      )
                  ),
                  
                  br(),
                  actionButton("create-study-plan", "Crear Plan de Estudio", class = "exercise-button")
                )
              ),
              
              fluidRow(
                box(
                  title = "Certificación de Competencias", status = "success", solidHeader = TRUE, width = 12,
                  h4("Obtén tu Certificado de Competencia"),
                  div(style = "text-align: center; padding: 20px;",
                      div(class = "info-box",
                          h5("Requisitos para la Certificación:"),
                          div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0;",
                              
                              div(style = "text-align: center; padding: 15px;",
                                  div(style = "font-size: 40px; color: #2ecc71;", "✓"),
                                  h6("Evaluación Completa"),
                                  p("Puntuación ≥ 80%")
                              ),
                              
                              div(style = "text-align: center; padding: 15px;",
                                  div(id = "listening-check", style = "font-size: 40px; color: #95a5a6;", "○"),
                                  h6("Evaluación Auditiva"),
                                  p("Puntuación ≥ 85%")
                              ),
                              
                              div(style = "text-align: center; padding: 15px;",
                                  div(id = "transcription-check", style = "font-size: 40px; color: #95a5a6;", "○"),
                                  h6("Transcripción"),
                                  p("Puntuación ≥ 75%")
                              ),
                              
                              div(style = "text-align: center; padding: 15px;",
                                  div(id = "exercises-check", style = "font-size: 40px; color: #95a5a6;", "○"),
                                  h6("Ejercicios Completados"),
                                  p("Mínimo 25 ejercicios")
                              )
                          ),
                          
                          br(),
                          div(id = "certification-status",
                              p("Completa todos los requisitos para desbloquear tu certificado."),
                              actionButton("generate-certificate", "Generar Certificado", 
                                           class = "exercise-button", style = "display: none;")
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Referencias Académicas", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h5>Referencias:</h5>
            <p><strong>Brown, H. D. & Abeywickrama, P.</strong> (2019). <em>Language Assessment: Principles and Classroom Practices</em>. 3rd Edition. Pearson Education.</p>
            <p><strong>Fulcher, G. & Davidson, F.</strong> (2021). <em>Language Testing and Assessment: An Advanced Resource Book</em>. 2nd Edition. Routledge.</p>
            <p><strong>McNamara, T. & Roever, C.</strong> (2020). <em>Language Testing: The Social Dimension</em>. Wiley-Blackwell.</p>
            <p><strong>Purpura, J. E.</strong> (2018). <em>Assessing Grammar and Vocabulary</em>. Cambridge University Press.</p>
            ")
                )
              )
      ),
      
      # Resources Tab
      tabItem(tabName = "resources",
              fluidRow(
                box(
                  title = "Biblioteca de Recursos", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Materiales Complementarios para el Aprendizaje del IPA"),
                  p("Explora una amplia gama de recursos adicionales para profundizar tu comprensión 
              del Alfabeto Fonético Internacional y mejorar tus habilidades de pronunciación.")
                )
              ),
              
              fluidRow(
                box(
                  title = "Recursos de Audio", status = "info", solidHeader = TRUE, width = 6,
                  h5("Colección de Sonidos del IPA"),
                  div(class = "info-box",
                      h6("Grabaciones Profesionales:"),
                      tags$ul(
                        tags$li("Consonantes del inglés con ejemplos"),
                        tags$li("Vocales monoftongos y diptongos"),
                        tags$li("Palabras de ejemplo para cada fonema"),
                        tags$li("Frases con fenómenos de habla conectada"),
                        tags$li("Comparaciones español-inglés")
                      ),
                      
                      br(),
                      selectInput("audio-category", "Categoría de Audio:",
                                  choices = list(
                                    "Consonantes Oclusivas" = "stops",
                                    "Consonantes Fricativas" = "fricatives",
                                    "Consonantes Nasales" = "nasals", 
                                    "Consonantes Líquidas" = "liquids",
                                    "Vocales Anteriores" = "front_vowels",
                                    "Vocales Posteriores" = "back_vowels",
                                    "Diptongos" = "diphthongs")),
                      
                      br(),
                      div(id = "audio-list", style = "max-height: 300px; overflow-y: auto;"),
                      
                      br(),
                      actionButton("download-audio-pack", "Descargar Pack de Audio", class = "exercise-button")
                  )
                ),
                
                box(
                  title = "Herramientas Interactivas", status = "success", solidHeader = TRUE, width = 6,
                  h5("Utilidades para el Aprendizaje"),
                  
                  div(class = "info-box",
                      h6("Tabla del IPA Interactiva:"),
                      div(style = "text-align: center; margin: 20px 0;",
                          img(src = "ipa_chart_placeholder.png", alt = "Tabla IPA", 
                              style = "width: 100%; max-width: 400px; border: 1px solid #ddd; border-radius: 10px;"),
                          br(), br(),
                          actionButton("open-interactive-chart", "Abrir Tabla Interactiva", class = "exercise-button")
                      ),
                      
                      h6("Otras Herramientas:"),
                      div(style = "margin: 15px 0;",
                          actionButton("sound-recorder", "🎤 Grabadora de Sonidos", class = "exercise-button", style = "margin: 5px;"),
                          actionButton("spectrogram-analyzer", "📊 Analizador Espectral", class = "exercise-button", style = "margin: 5px;"),
                          actionButton("pronunciation-trainer", "🎯 Entrenador de Pronunciación", class = "exercise-button", style = "margin: 5px;")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Material de Lectura", status = "warning", solidHeader = TRUE, width = 8,
                  h5("Documentos y Guías"),
                  
                  div(class = "info-box",
                      h6("Guías de Estudio Disponibles:"),
                      
                      div(style = "margin: 20px 0;",
                          div(style = "border: 1px solid #ddd; border-radius: 10px; padding: 15px; margin: 10px 0;",
                              div(style = "display: flex; justify-content: space-between; align-items: center;",
                                  div(
                                    h6("Manual Completo del IPA para Hispanohablantes", style = "margin: 0;"),
                                    p("Guía comprehensive con 120 páginas de teoría y práctica", style = "margin: 5px 0; color: #7f8c8d;")
                                  ),
                                  div(
                                    span(class = "difficulty-badge difficulty-intermediate", "PDF"),
                                    actionButton("download-manual", "Descargar", class = "exercise-button", style = "margin-left: 10px;")
                                  )
                              )
                          ),
                          
                          div(style = "border: 1px solid #ddd; border-radius: 10px; padding: 15px; margin: 10px 0;",
                              div(style = "display: flex; justify-content: space-between; align-items: center;",
                                  div(
                                    h6("Ejercicios de Transcripción Fonética", style = "margin: 0;"),
                                    p("300 ejercicios progresivos con soluciones detalladas", style = "margin: 5px 0; color: #7f8c8d;")
                                  ),
                                  div(
                                    span(class = "difficulty-badge difficulty-basic", "PDF"),
                                    actionButton("download-exercises", "Descargar", class = "exercise-button", style = "margin-left: 10px;")
                                  )
                              )
                          ),
                          
                          div(style = "border: 1px solid #ddd; border-radius: 10px; padding: 15px; margin: 10px 0;",
                              div(style = "display: flex; justify-content: space-between; align-items: center;",
                                  div(
                                    h6("Diferencias Fonológicas Español-Inglés", style = "margin: 0;"),
                                    p("Análisis contrastivo detallado con ejemplos", style = "margin: 5px 0; color: #7f8c8d;")
                                  ),
                                  div(
                                    span(class = "difficulty-badge difficulty-advanced", "PDF"),
                                    actionButton("download-contrastive", "Descargar", class = "exercise-button", style = "margin-left: 10px;")
                                  )
                              )
                          ),
                          
                          div(style = "border: 1px solid #ddd; border-radius: 10px; padding: 15px; margin: 10px 0;",
                              div(style = "display: flex; justify-content: space-between; align-items: center;",
                                  div(
                                    h6("Glosario de Términos Fonéticos", style = "margin: 0;"),
                                    p("Diccionario especializado con más de 500 términos", style = "margin: 5px 0; color: #7f8c8d;")
                                  ),
                                  div(
                                    span(class = "difficulty-badge difficulty-basic", "PDF"),
                                    actionButton("download-glossary", "Descargar", class = "exercise-button", style = "margin-left: 10px;")
                                  )
                              )
                          )
                      )
                  )
                ),
                
                box(
                  title = "Enlaces Externos", status = "primary", solidHeader = TRUE, width = 4,
                  h5("Recursos Online Recomendados"),
                  
                  div(class = "info-box",
                      h6("Sitios Web Especializados:"),
                      
                      div(style = "margin: 15px 0;",
                          strong("International Phonetic Association"),
                          br(),
                          a("https://www.internationalphoneticassociation.org", 
                            href = "https://www.internationalphoneticassociation.org", 
                            target = "_blank", style = "color: #667eea;")
                      ),
                      
                      div(style = "margin: 15px 0;",
                          strong("Sounds of Speech (University of Iowa)"),
                          br(),
                          a("https://soundsofspeech.uiowa.edu", 
                            href = "https://soundsofspeech.uiowa.edu", 
                            target = "_blank", style = "color: #667eea;")
                      ),
                      
                      div(style = "margin: 15px 0;",
                          strong("Speech Accent Archive"),
                          br(),
                          a("https://accent.gmu.edu", 
                            href = "https://accent.gmu.edu", 
                            target = "_blank", style = "color: #667eea;")
                      ),
                      
                      div(style = "margin: 15px 0;",
                          strong("Phonetic Transcription Tools"),
                          br(),
                          a("https://tophonetics.com", 
                            href = "https://tophonetics.com", 
                            target = "_blank", style = "color: #667eea;")
                      ),
                      
                      br(),
                      h6("Aplicaciones Móviles:"),
                      tags$ul(
                        tags$li("Sounds Pronunciation App"),
                        tags$li("IPA Phonetics"),
                        tags$li("English Pronunciation"),
                        tags$li("Forvo Dictionary")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Videos Educativos", status = "success", solidHeader = TRUE, width = 6,
                  h5("Contenido Audiovisual"),
                  
                  div(class = "info-box",
                      h6("Serie de Videos: 'Fonética para Hispanohablantes'"),
                      
                      div(id = "video-list",
                          div(style = "border: 1px solid #ddd; border-radius: 10px; padding: 15px; margin: 10px 0;",
                              div(style = "display: flex; align-items: center;",
                                  div(style = "width: 80px; height: 60px; background: #667eea; border-radius: 5px; margin-right: 15px; display: flex; align-items: center; justify-content: center; color: white;",
                                      icon("play", style = "font-size: 24px;")
                                  ),
                                  div(
                                    h6("Introducción al Alfabeto Fonético", style = "margin: 0;"),
                                    p("Duración: 15:30 | Nivel: Principiante", style = "margin: 5px 0; color: #7f8c8d;"),
                                    actionButton("play-video-1", "Ver Video", class = "exercise-button", style = "padding: 5px 15px; font-size: 12px;")
                                  )
                              )
                          ),
                          
                          div(style = "border: 1px solid #ddd; border-radius: 10px; padding: 15px; margin: 10px 0;",
                              div(style = "display: flex; align-items: center;",
                                  div(style = "width: 80px; height: 60px; background: #667eea; border-radius: 5px; margin-right: 15px; display: flex; align-items: center; justify-content: center; color: white;",
                                      icon("play", style = "font-size: 24px;")
                                  ),
                                  div(
                                    h6("Consonantes Problemáticas para Hispanohablantes", style = "margin: 0;"),
                                    p("Duración: 22:45 | Nivel: Intermedio", style = "margin: 5px 0; color: #7f8c8d;"),
                                    actionButton("play-video-2", "Ver Video", class = "exercise-button", style = "padding: 5px 15px; font-size: 12px;")
                                  )
                              )
                          ),
                          
                          div(style = "border: 1px solid #ddd; border-radius: 10px; padding: 15px; margin: 10px 0;",
                              div(style = "display: flex; align-items: center;",
                                  div(style = "width: 80px; height: 60px; background: #667eea; border-radius: 5px; margin-right: 15px; display: flex; align-items: center; justify-content: center; color: white;",
                                      icon("play", style = "font-size: 24px;")
                                  ),
                                  div(
                                    h6("Transcripción Avanzada y Suprasegmentales", style = "margin: 0;"),
                                    p("Duración: 28:15 | Nivel: Avanzado", style = "margin: 5px 0; color: #7f8c8d;"),
                                    actionButton("play-video-3", "Ver Video", class = "exercise-button", style = "padding: 5px 15px; font-size: 12px;")
                                  )
                              )
                          )
                      )
                  )
                ),
                
                box(
                  title = "Software Especializado", status = "info", solidHeader = TRUE, width = 6,
                  h5("Programas Recomendados"),
                  
                  div(class = "info-box",
                      h6("Software de Análisis Fonético:"),
                      
                      div(style = "margin: 20px 0;",
                          strong("Praat"),
                          p("Software gratuito para análisis acústico del habla. Incluye herramientas para:"),
                          tags$ul(
                            tags$li("Análisis espectral"),
                            tags$li("Medición de formantes"),
                            tags$li("Análisis de pitch y entonación"),
                            tags$li("Síntesis de habla")
                          ),
                          actionButton("download-praat-guide", "Guía de Praat", class = "exercise-button")
                      ),
                      
                      div(style = "margin: 20px 0;",
                          strong("WASP (Waveform and Spectrogram Package)"),
                          p("Herramienta de análisis ligera y fácil de usar para:"),
                          tags$ul(
                            tags$li("Visualización de ondas de sonido"),
                            tags$li("Espectrogramas en tiempo real"),
                            tags$li("Mediciones básicas de frecuencia")
                          )
                      ),
                      
                      div(style = "margin: 20px 0;",
                          strong("IPA Phonetic Keyboard"),
                          p("Extensiones de teclado para escribir símbolos del IPA:"),
                          tags$ul(
                            tags$li("TypeIt IPA (online)"),
                            tags$li("IPA Unicode Keyboard"),
                            tags$li("Keyman IPA Layout")
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Comunidad y Soporte", status = "primary", solidHeader = TRUE, width = 12,
                  h4("Conecta con Otros Estudiantes"),
                  
                  div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 20px 0;",
                      
                      div(class = "info-box",
                          h5(icon("users"), " Foro de Discusión"),
                          p("Participa en discusiones sobre fonética, comparte dudas y ayuda a otros estudiantes."),
                          actionButton("join-forum", "Unirse al Foro", class = "exercise-button")
                      ),
                      
                      div(class = "info-box",
                          h5(icon("comments"), " Grupo de Estudio"),
                          p("Forma parte de grupos de estudio virtuales organizados por nivel y horario."),
                          actionButton("join-study-group", "Buscar Grupo", class = "exercise-button")
                      ),
                      
                      div(class = "info-box",
                          h5(icon("graduation-cap"), " Tutorías Online"),
                          p("Sesiones personalizadas con instructores especializados en fonética."),
                          actionButton("book-tutoring", "Reservar Tutoría", class = "exercise-button")
                      ),
                      
                      div(class = "info-box",
                          h5(icon("calendar"), " Eventos y Talleres"),
                          p("Participa en webinars, talleres y conferencias sobre fonética aplicada."),
                          actionButton("view-events", "Ver Eventos", class = "exercise-button")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Feedback y Sugerencias", status = "warning", solidHeader = TRUE, width = 12,
                  h5("Ayúdanos a Mejorar"),
                  
                  div(class = "info-box",
                      p("Tu opinión es muy valiosa para nosotros. Comparte tus comentarios y sugerencias 
                para mejorar continuamente esta plataforma de aprendizaje."),
                      
                      div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 30px; margin: 20px 0;",
                          
                          div(
                            h6("Evalúa la Aplicación:"),
                            div(style = "text-align: center; margin: 20px 0;",
                                div(style = "font-size: 30px; margin: 10px 0;",
                                    span(style = "color: #f39c12; cursor: pointer;", "★"),
                                    span(style = "color: #f39c12; cursor: pointer;", "★"),
                                    span(style = "color: #f39c12; cursor: pointer;", "★"),
                                    span(style = "color: #f39c12; cursor: pointer;", "★"),
                                    span(style = "color: #ddd; cursor: pointer;", "★")
                                ),
                                p("4.0/5.0 - ¡Gracias por tu valoración!")
                            )
                          ),
                          
                          div(
                            h6("Enviar Comentarios:"),
                            textAreaInput("user-feedback", "", 
                                          placeholder = "Comparte tus comentarios, sugerencias o reporta problemas...",
                                          height = "100px"),
                            actionButton("submit-feedback", "Enviar Feedback", class = "exercise-button")
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Referencias Académicas", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h5>Referencias:</h5>
            <p><strong>International Phonetic Association</strong> (2020). <em>Handbook of the International Phonetic Alphabet: A guide to the use of the International Phonetic Alphabet</em>. Cambridge University Press.</p>
            <p><strong>Boersma, P. & Weenink, D.</strong> (2023). <em>Praat: doing phonetics by computer</em> [Computer program]. Version 6.3.10. Retrieved from http://www.praat.org/</p>
            <p><strong>Crystal, D.</strong> (2019). <em>A Dictionary of Linguistics and Phonetics</em>. 7th Edition. Wiley-Blackwell.</p>
            <p><strong>Ladefoged, P.</strong> (2022). <em>Vowels and Consonants</em>. 4th Edition. Wiley-Blackwell.</p>
            <p><strong>Pike, K. L.</strong> (2015). <em>Phonemics: A Technique for Reducing Languages to Writing</em>. University of Michigan Press. (Edición digitalizada)</p>
            ")
                )
              )
      )
    )
  )
)

# Define Server Logic
server <- function(input, output, session) {
  
  # Reactive values for storing user data and progress
  values <- reactiveValues(
    user_progress = 0,
    exercises_completed = 0,
    assessment_scores = list(),
    current_exercise = NULL,
    exercise_stats = data.frame(
      date = Sys.Date(),
      exercise_type = character(0),
      score = numeric(0),
      time_taken = numeric(0)
    ),
    phonetic_data = NULL,
    audio_playing = FALSE,
    current_assessment = NULL,
    assessment_questions = list(),
    current_question = 1
  )
  
  # Initialize phonetic alphabet data
  observe({
    # Consonants data
    consonants <- data.frame(
      symbol = c("p", "b", "t", "d", "k", "g", "f", "v", "θ", "ð", "s", "z", "ʃ", "ʒ", "h", "m", "n", "ŋ", "l", "ɹ", "w", "j"),
      example = c("pat", "bat", "tap", "dad", "cat", "gap", "fat", "vat", "think", "this", "sip", "zip", "ship", "measure", "hat", "mat", "nat", "sing", "let", "red", "wet", "yes"),
      spanish_equivalent = c("pato", "similar", "tanto", "similar", "casa", "similar", "No existe", "No existe", "No existe", "No existe", "casa", "No existe", "No existe", "No existe", "No existe", "mama", "nada", "No existe", "lado", "No existe", "No existe", "No existe"),
      description = c("Oclusiva bilabial sorda", "Oclusiva bilabial sonora", "Oclusiva alveolar sorda", "Oclusiva alveolar sonora", "Oclusiva velar sorda", "Oclusiva velar sonora", "Fricativa labiodental sorda", "Fricativa labiodental sonora", "Fricativa dental sorda", "Fricativa dental sonora", "Fricativa alveolar sorda", "Fricativa alveolar sonora", "Fricativa postalveolar sorda", "Fricativa postalveolar sonora", "Fricativa glotal", "Nasal bilabial", "Nasal alveolar", "Nasal velar", "Lateral alveolar", "Aproximante alveolar", "Aproximante labial", "Aproximante palatal"),
      stringsAsFactors = FALSE
    )
    
    # Vowels data
    vowels <- data.frame(
      symbol = c("i", "ɪ", "e", "æ", "a", "ɑ", "ɔ", "o", "ʊ", "u", "ʌ", "ə"),
      example = c("see", "sit", "set", "sat", "father", "lot", "thought", "go", "book", "soon", "cup", "about"),
      spanish_equivalent = c("si", "No existe", "No existe", "No existe", "casa", "No existe", "No existe", "No existe", "No existe", "tu", "No existe", "No existe"),
      description = c("Vocal anterior cerrada", "Vocal anterior semicerrada", "Vocal anterior media", "Vocal anterior abierta", "Vocal central abierta", "Vocal posterior abierta", "Vocal posterior media", "Vocal posterior cerrada", "Vocal posterior semicerrada", "Vocal posterior cerrada", "Vocal central media", "Vocal central neutra (schwa)"),
      stringsAsFactors = FALSE
    )
    
    values$phonetic_data <- list(consonants = consonants, vowels = vowels)
  })
  
  # Overall progress calculation
  output$overall_progress <- renderText({
    progress_percent <- min(100, values$user_progress)
    paste0(progress_percent, "%")
  })
  
  # Update progress bar
  observe({
    progress_percent <- min(100, values$user_progress)
    runjs(paste0("$('#progress-fill').css('width', '", progress_percent, "%');"))
  })
  
  # Start learning button
  observeEvent(input$start_learning, {
    updateTabItems(session, "sidebar", "basic_alphabet")
    values$user_progress <- max(10, values$user_progress)
  })
  
  # Generate consonants grid for basic alphabet tab
  observe({
    req(values$phonetic_data)
    
    consonants_html <- ""
    for(i in 1:nrow(values$phonetic_data$consonants)) {
      row <- values$phonetic_data$consonants[i, ]
      consonants_html <- paste0(consonants_html,
                                '<div class="phonetic-card" onclick="selectSymbol(\'', row$symbol, '\', \'', row$description, '\')">',
                                '<div class="phonetic-letter">', row$symbol, '</div>',
                                '<div class="phonetic-word">', row$example, '</div>',
                                '<div class="phonetic-pronunciation">', row$description, '</div>',
                                '</div>'
      )
    }
    
    insertUI(
      selector = "#consonants-grid",
      ui = HTML(consonants_html),
      where = "afterBegin"
    )
  })
  
  # Generate vowels grid
  observe({
    req(values$phonetic_data)
    
    vowels_html <- ""
    for(i in 1:nrow(values$phonetic_data$vowels)) {
      row <- values$phonetic_data$vowels[i, ]
      vowels_html <- paste0(vowels_html,
                            '<div class="phonetic-card" onclick="selectSymbol(\'', row$symbol, '\', \'', row$description, '\')">',
                            '<div class="phonetic-letter">', row$symbol, '</div>',
                            '<div class="phonetic-word">', row$example, '</div>',
                            '<div class="phonetic-pronunciation">', row$description, '</div>',
                            '</div>'
      )
    }
    
    insertUI(
      selector = "#vowels-grid", 
      ui = HTML(vowels_html),
      where = "afterBegin"
    )
  })
  
  # Sound wave visualization for pronunciation tab
  output$sound_wave <- renderPlotly({
    # Generate sample wave data
    time <- seq(0, 1, length.out = 1000)
    frequency <- 440  # A4 note
    wave <- sin(2 * pi * frequency * time) * exp(-time * 2)
    
    wave_data <- data.frame(
      time = time,
      amplitude = wave
    )
    
    p <- ggplot(wave_data, aes(x = time, y = amplitude)) +
      geom_line(color = "#667eea", size = 1) +
      labs(title = "Forma de Onda del Sonido /a/",
           x = "Tiempo (segundos)", 
           y = "Amplitud") +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 14),
        panel.grid.minor = element_blank()
      )
    
    ggplotly(p) %>%
      layout(showlegend = FALSE)
  })
  
  # Consonant differences table for differences tab
  output$consonant_differences <- DT::renderDataTable({
    differences_data <- data.frame(
      "Sonido_IPA" = c("/θ/", "/ð/", "/v/", "/ʒ/", "/ŋ/", "/ɹ/"),
      "Ejemplo_Inglés" = c("think", "this", "very", "measure", "sing", "red"),
      "Problema_Español" = c("No existe", "No existe", "Confusión con /b/", "No existe", "No existe", "Confusión con /r/"),
      "Substitución_Común" = c("/s/ o /t/", "/d/", "/b/", "/ʃ/", "/n/", "/r/"),
      "Dificultad" = c("Alta", "Alta", "Media", "Alta", "Media", "Alta"),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(differences_data,
                  options = list(pageLength = 10, searching = FALSE, info = FALSE, paging = FALSE),
                  colnames = c("Sonido IPA", "Ejemplo", "Problema", "Sustitución", "Dificultad"),
                  rownames = FALSE) %>%
      formatStyle("Dificultad",
                  backgroundColor = styleEqual(c("Alta", "Media", "Baja"), 
                                               c("#e74c3c", "#f39c12", "#2ecc71")),
                  color = "white")
  })
  
  # Transfer analysis plot for differences tab
  output$transfer_analysis <- renderPlotly({
    transfer_data <- data.frame(
      sound = c("/θ/", "/ð/", "/v/", "/ʒ/", "/ŋ/", "/ɹ/", "/ɪ/", "/æ/", "/ʌ/", "/ʊ/"),
      difficulty = c(0.9, 0.85, 0.7, 0.8, 0.6, 0.95, 0.75, 0.8, 0.7, 0.65),
      category = c(rep("Consonantes", 6), rep("Vocales", 4))
    )
    
    p <- ggplot(transfer_data, aes(x = reorder(sound, difficulty), y = difficulty, fill = category)) +
      geom_bar(stat = "identity", alpha = 0.8) +
      scale_fill_manual(values = c("Consonantes" = "#667eea", "Vocales" = "#764ba2")) +
      coord_flip() +
      labs(title = "Dificultad de Sonidos Ingleses para Hispanohablantes",
           x = "Sonido IPA", 
           y = "Nivel de Dificultad (0-1)",
           fill = "Categoría") +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 14),
        legend.position = "bottom"
      )
    
    ggplotly(p)
  })
  
  # Progress chart for exercises tab
  output$progress_chart <- renderPlotly({
    # Generate sample progress data
    dates <- seq(Sys.Date() - 30, Sys.Date(), by = "day")
    progress <- cumsum(runif(length(dates), 0, 3))
    
    progress_data <- data.frame(
      date = dates,
      exercises = progress
    )
    
    p <- ggplot(progress_data, aes(x = date, y = exercises)) +
      geom_line(color = "#667eea", size = 2) +
      geom_point(color = "#764ba2", size = 3) +
      labs(title = "Progreso en Ejercicios",
           x = "Fecha", 
           y = "Ejercicios Completados") +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 12),
        axis.text.x = element_text(angle = 45, hjust = 1)
      )
    
    ggplotly(p) %>%
      layout(showlegend = FALSE)
  })
  
  # Assessment history plot
  output$assessment_history <- renderPlotly({
    # Generate sample assessment data
    assessment_data <- data.frame(
      assessment = c("Rápida", "Completa", "Auditiva", "Transcripción"),
      score = c(85, 78, 82, 75),
      attempts = c(3, 2, 4, 2)
    )
    
    p <- ggplot(assessment_data, aes(x = assessment, y = score, fill = assessment)) +
      geom_bar(stat = "identity", alpha = 0.8) +
      scale_fill_viridis_d() +
      labs(title = "Historial de Evaluaciones",
           x = "Tipo de Evaluación", 
           y = "Puntuación (%)") +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 12),
        legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1)
      )
    
    ggplotly(p)
  })
  
  # Performance radar chart for assessment tab
  output$performance_radar <- renderPlotly({
    # Generate sample performance data
    categories <- c("Reconocimiento\nde Símbolos", "Transcripción", "Pronunciación", 
                    "Diferenciación\nEN-ES", "Velocidad", "Precisión")
    scores <- c(85, 78, 72, 80, 75, 88)
    
    # Create radar chart data
    radar_data <- data.frame(
      category = factor(categories, levels = categories),
      score = scores,
      max_score = rep(100, length(categories))
    )
    
    p <- ggplot(radar_data, aes(x = category, y = score)) +
      geom_polygon(aes(group = 1), fill = "#667eea", alpha = 0.3, color = "#667eea", size = 2) +
      geom_point(color = "#764ba2", size = 4) +
      coord_polar() +
      ylim(0, 100) + labs(title = "Perfil de Competencias Fonéticas",
                          x = "", y = "Puntuación (%)") +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 14),
        axis.text.x = element_text(size = 10),
        axis.text.y = element_text(size = 8)
      )
    
    ggplotly(p) %>%
      layout(showlegend = FALSE)
  })
  
  # Spectrogram for advanced tab
  output$spectrogram <- renderPlotly({
    # Generate sample spectrogram data
    time <- seq(0, 2, length.out = 100)
    freq <- seq(0, 4000, length.out = 50)
    
    # Create a matrix for spectrogram (simplified)
    spectrogram_matrix <- matrix(0, nrow = length(freq), ncol = length(time))
    
    # Add some formant patterns (simplified)
    for(i in 1:length(time)) {
      # First formant around 500 Hz
      f1_index <- which.min(abs(freq - 500))
      spectrogram_matrix[f1_index + (-2:2), i] <- exp(-((freq[f1_index + (-2:2)] - 500)^2) / 10000) * 0.8
      
      # Second formant around 1500 Hz
      f2_index <- which.min(abs(freq - 1500))
      spectrogram_matrix[f2_index + (-3:3), i] <- exp(-((freq[f2_index + (-3:3)] - 1500)^2) / 20000) * 0.6
      
      # Third formant around 2500 Hz
      f3_index <- which.min(abs(freq - 2500))
      spectrogram_matrix[f3_index + (-2:2), i] <- exp(-((freq[f3_index + (-2:2)] - 2500)^2) / 15000) * 0.4
    }
    
    plot_ly(
      z = spectrogram_matrix,
      type = "heatmap",
      colorscale = "Viridis",
      showscale = FALSE
    ) %>%
      layout(
        title = "Espectrograma de /a/",
        xaxis = list(title = "Tiempo (s)"),
        yaxis = list(title = "Frecuencia (Hz)")
      )
  })
  
  # Audio list for resources tab
  observe({
    audio_category <- input$`audio-category`
    
    if(!is.null(audio_category)) {
      audio_items <- switch(audio_category,
                            "stops" = list(
                              list(symbol = "/p/", word = "pat", file = "p_sound.mp3"),
                              list(symbol = "/b/", word = "bat", file = "b_sound.mp3"),
                              list(symbol = "/t/", word = "tap", file = "t_sound.mp3"),
                              list(symbol = "/d/", word = "dad", file = "d_sound.mp3"),
                              list(symbol = "/k/", word = "cat", file = "k_sound.mp3"),
                              list(symbol = "/g/", word = "gap", file = "g_sound.mp3")
                            ),
                            "fricatives" = list(
                              list(symbol = "/f/", word = "fat", file = "f_sound.mp3"),
                              list(symbol = "/v/", word = "vat", file = "v_sound.mp3"),
                              list(symbol = "/θ/", word = "think", file = "theta_sound.mp3"),
                              list(symbol = "/ð/", word = "this", file = "eth_sound.mp3"),
                              list(symbol = "/s/", word = "sip", file = "s_sound.mp3"),
                              list(symbol = "/z/", word = "zip", file = "z_sound.mp3")
                            ),
                            "front_vowels" = list(
                              list(symbol = "/i/", word = "see", file = "i_sound.mp3"),
                              list(symbol = "/ɪ/", word = "sit", file = "I_sound.mp3"),
                              list(symbol = "/e/", word = "set", file = "e_sound.mp3"),
                              list(symbol = "/æ/", word = "sat", file = "ae_sound.mp3")
                            ),
                            list()
      )
      
      audio_html <- ""
      for(item in audio_items) {
        audio_html <- paste0(audio_html,
                             '<div style="border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin: 8px 0; display: flex; justify-content: space-between; align-items: center;">',
                             '<div>',
                             '<strong>', item$symbol, '</strong> - ', item$word,
                             '</div>',
                             '<button class="audio-button" onclick="playAudio(\'', item$file, '\')">🔊</button>',
                             '</div>'
        )
      }
      
      runjs(paste0("$('#audio-list').html('", gsub("'", "\\'", audio_html), "');"))
    }
  })
  
  # Custom JavaScript functions
  observe({
    runjs("
      // Function to select phonetic symbol
      window.selectSymbol = function(symbol, description) {
        $('#selected-symbol').text(symbol);
        $('#symbol-description').text(description);
      };
      
      // Function to select exercise type
      window.selectExercise = function(exerciseType) {
        var titles = {
          'symbol_recognition': 'Reconocimiento de Símbolos',
          'sound_matching': 'Asociación Sonido-Símbolo', 
          'transcription': 'Ejercicios de Transcripción',
          'minimal_pairs': 'Pares Mínimos'
        };
        
        $('#exercise-title').text(titles[exerciseType]);
        
        var content = '';
        switch(exerciseType) {
          case 'symbol_recognition':
            content = generateSymbolRecognitionExercise();
            break;
          case 'sound_matching':
            content = generateSoundMatchingExercise();
            break;
          case 'transcription':
            content = generateTranscriptionExercise();
            break;
          case 'minimal_pairs':
            content = generateMinimalPairsExercise();
            break;
        }
        
        $('#exercise-content').html(content);
        generateExerciseControls(exerciseType);
      };
      
      // Generate different exercise types
      function generateSymbolRecognitionExercise() {
        var symbols = ['/p/', '/b/', '/θ/', '/ð/', '/ʃ/', '/ʒ/'];
        var randomSymbol = symbols[Math.floor(Math.random() * symbols.length)];
        
        return '<div style=\"text-align: center; padding: 30px;\">' +
               '<h4>¿Qué símbolo es este?</h4>' +
               '<div style=\"font-size: 72px; color: #667eea; margin: 30px;\">' + randomSymbol + '</div>' +
               '<div style=\"display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; max-width: 400px; margin: 0 auto;\">' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, true)\">Fricativa dental sorda</button>' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, false)\">Oclusiva bilabial</button>' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, false)\">Fricativa postalveolar</button>' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, false)\">Nasal alveolar</button>' +
               '</div></div>';
      }
      
      function generateSoundMatchingExercise() {
        return '<div style=\"text-align: center; padding: 30px;\">' +
               '<h4>Escucha el sonido y selecciona el símbolo correcto</h4>' +
               '<button class=\"audio-button\" style=\"font-size: 24px; width: 100px; height: 100px; margin: 20px;\">🔊</button>' +
               '<div style=\"display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; max-width: 600px; margin: 30px auto;\">' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, false)\">/p/</button>' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, true)\">/θ/</button>' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, false)\">/s/</button>' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, false)\">/f/</button>' +
               '</div></div>';
      }
      
      function generateTranscriptionExercise() {
        return '<div style=\"text-align: center; padding: 30px;\">' +
               '<h4>Transcribe la siguiente palabra:</h4>' +
               '<div style=\"font-size: 36px; color: #667eea; margin: 20px;\">\"think\"</div>' +
               '<input type=\"text\" placeholder=\"Escribe la transcripción (ej: /θɪŋk/)\" ' +
               'style=\"font-size: 18px; padding: 15px; width: 300px; text-align: center; border: 2px solid #ddd; border-radius: 10px;\"/>' +
               '<br><br>' +
               '<button class=\"exercise-button\" onclick=\"checkTranscription()\">Verificar</button>' +
               '</div>';
      }
      
      function generateMinimalPairsExercise() {
        return '<div style=\"text-align: center; padding: 30px;\">' +
               '<h4>Identifica la diferencia entre estos pares:</h4>' +
               '<div style=\"display: flex; justify-content: space-around; margin: 30px 0;\">' +
               '<div>' +
               '<h5>Sonido A</h5>' +
               '<div style=\"font-size: 48px; color: #667eea;\">/ʃɪp/</div>' +
               '<p>ship</p>' +
               '<button class=\"audio-button\">🔊</button>' +
               '</div>' +
               '<div style=\"font-size: 24px; margin-top: 50px;\">VS</div>' +
               '<div>' +
               '<h5>Sonido B</h5>' +
               '<div style=\"font-size: 48px; color: #764ba2;\">/ʃiːp/</div>' +
               '<p>sheep</p>' +
               '<button class=\"audio-button\">🔊</button>' +
               '</div>' +
               '</div>' +
               '<p>¿Cuál es la principal diferencia?</p>' +
               '<div style=\"display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; max-width: 400px; margin: 0 auto;\">' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, true)\">Duración vocálica</button>' +
               '<button class=\"exercise-button\" onclick=\"checkAnswer(this, false)\">Consonante inicial</button>' +
               '</div></div>';
      }
      
      function generateExerciseControls(exerciseType) {
        var controls = '<div style=\"text-align: center; margin-top: 30px;\">' +
                      '<button class=\"exercise-button\" onclick=\"nextExercise()\">Siguiente Ejercicio</button>' +
                      '<button class=\"exercise-button\" onclick=\"showHint()\">Pista</button>' +
                      '<button class=\"exercise-button\" onclick=\"resetExercise()\">Reiniciar</button>' +
                      '</div>';
        $('#exercise-controls').html(controls);
      }
      
      // Answer checking functions
      window.checkAnswer = function(button, isCorrect) {
        var buttons = $(button).parent().find('button');
        buttons.removeClass('correct-answer incorrect-answer');
        
        if(isCorrect) {
          $(button).addClass('correct-answer');
          setTimeout(function() {
            alert('¡Correcto! Bien hecho.');
          }, 100);
        } else {
          $(button).addClass('incorrect-answer');
          setTimeout(function() {
            alert('Incorrecto. Inténtalo de nuevo.');
          }, 100);
        }
      };
      
      window.checkTranscription = function() {
        var input = $('input[type=\"text\"]').val().toLowerCase();
        var correct = '/θɪŋk/';
        
        if(input === correct || input === 'θɪŋk') {
          alert('¡Excelente! Transcripción correcta.');
        } else {
          alert('Incorrecto. La respuesta correcta es: ' + correct);
        }
      };
      
      // Assessment functions
      window.startAssessment = function(assessmentType) {
        var titles = {
          'quick_test': 'Evaluación Rápida',
          'comprehensive': 'Evaluación Completa',
          'listening': 'Evaluación Auditiva',
          'transcription': 'Evaluación de Transcripción'
        };
        
        $('#assessment-intro').hide();
        $('#assessment-content').show();
        $('#assessment-title').text(titles[assessmentType]);
        
        // Generate first question
        generateAssessmentQuestion(assessmentType, 1);
        
        // Start timer
        startAssessmentTimer(assessmentType === 'quick_test' ? 300 : 1200); // 5 or 20 minutes
      };
      
      function generateAssessmentQuestion(type, questionNumber) {
        var questionContent = '';
        
        switch(type) {
          case 'quick_test':
            questionContent = generateQuickTestQuestion(questionNumber);
            break;
          case 'comprehensive':
            questionContent = generateComprehensiveQuestion(questionNumber);
            break;
          case 'listening':
            questionContent = generateListeningQuestion(questionNumber);
            break;
          case 'transcription':
            questionContent = generateTranscriptionTestQuestion(questionNumber);
            break;
        }
        
        $('#question-content').html(questionContent);
        $('#current-question').text(questionNumber);
        
        var totalQuestions = type === 'quick_test' ? 10 : 50;
        $('#total-questions').text(totalQuestions);
        
        var progressPercent = (questionNumber / totalQuestions) * 100;
        $('#assessment-progress').css('width', progressPercent + '%');
      }
      
      function generateQuickTestQuestion(questionNumber) {
        var questions = [
          {
            question: '¿Cuál es el símbolo IPA para el sonido \"th\" en \"think\"?',
            options: ['/θ/', '/ð/', '/s/', '/t/'],
            correct: 0
          },
          {
            question: '¿Qué tipo de sonido es /p/?',
            options: ['Fricativa', 'Nasal', 'Oclusiva', 'Lateral'],
            correct: 2
          },
          {
            question: '¿Cuál de estos sonidos NO existe en español?',
            options: ['/p/', '/v/', '/t/', '/m/'],
            correct: 1
          }
        ];
        
        var q = questions[(questionNumber - 1) % questions.length];
        var html = '<div style=\"padding: 30px;\">' +
                   '<h4>' + q.question + '</h4>' +
                   '<div style=\"display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin: 30px 0;\">';
        
        for(var i = 0; i < q.options.length; i++) {
          html += '<button class=\"exercise-button\" onclick=\"selectAssessmentAnswer(' + i + ', ' + q.correct + ')\">' + q.options[i] + '</button>';
        }
        
        html += '</div></div>';
        return html;
      }
      
      function generateComprehensiveQuestion(questionNumber) {
        // More complex questions for comprehensive assessment
        return generateQuickTestQuestion(questionNumber); // Simplified for this example
      }
      
      function generateListeningQuestion(questionNumber) {
        return '<div style=\"text-align: center; padding: 30px;\">' +
               '<h4>Escucha el sonido y selecciona la transcripción correcta:</h4>' +
               '<button class=\"audio-button\" style=\"font-size: 24px; width: 100px; height: 100px; margin: 20px;\">🔊</button>' +
               '<div style=\"display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; max-width: 400px; margin: 30px auto;\">' +
               '<button class=\"exercise-button\" onclick=\"selectAssessmentAnswer(0, 1)\">/kæt/</button>' +
               '<button class=\"exercise-button\" onclick=\"selectAssessmentAnswer(1, 1)\">/kʌt/</button>' +
               '<button class=\"exercise-button\" onclick=\"selectAssessmentAnswer(2, 1)\">/kaːt/</button>' +
               '<button class=\"exercise-button\" onclick=\"selectAssessmentAnswer(3, 1)\">/kɔt/</button>' +
               '</div></div>';
      }
      
      function generateTranscriptionTestQuestion(questionNumber) {
        var words = ['beautiful', 'important', 'pronunciation', 'different', 'language'];
        var word = words[(questionNumber - 1) % words.length];
        
        return '<div style=\"text-align: center; padding: 30px;\">' +
               '<h4>Transcribe completamente la palabra:</h4>' +
               '<div style=\"font-size: 48px; color: #667eea; margin: 30px;\">' + word + '</div>' +
               '<input type=\"text\" placeholder=\"Transcripción completa con acento\" ' +
               'style=\"font-size: 18px; padding: 15px; width: 400px; text-align: center; border: 2px solid #ddd; border-radius: 10px;\"/>' +
               '<br><br>' +
               '<button class=\"exercise-button\" onclick=\"checkAssessmentTranscription()\">Verificar Respuesta</button>' +
               '</div>';
      }
      
      window.selectAssessmentAnswer = function(selected, correct) {
        // Store the answer and provide feedback
        if(selected === correct) {
          alert('Correcto!');
        } else {
          alert('Incorrecto.');
        }
        
        // Move to next question after a delay
        setTimeout(function() {
          var currentQ = parseInt($('#current-question').text());
          var totalQ = parseInt($('#total-questions').text());
          
          if(currentQ < totalQ) {
            generateAssessmentQuestion('quick_test', currentQ + 1); // Simplified
          } else {
            finishAssessment();
          }
        }, 1500);
      };
      
      function startAssessmentTimer(seconds) {
        var timeLeft = seconds;
        var timer = setInterval(function() {
          var minutes = Math.floor(timeLeft / 60);
          var secs = timeLeft % 60;
          $('#time-remaining').text(minutes + ':' + (secs < 10 ? '0' : '') + secs);
          
          timeLeft--;
          
          if(timeLeft < 0) {
            clearInterval(timer);
            alert('¡Tiempo agotado!');
            finishAssessment();
          }
        }, 1000);
      }
      
      function finishAssessment() {
        $('#assessment-content').hide();
        $('#assessment-results').show();
        
        // Generate random results for demonstration
        var score = Math.floor(Math.random() * 30) + 70; // 70-100%
        
        $('#results-summary').html(
          '<h2 style=\"color: #667eea;\">Evaluación Completada</h2>' +
          '<div style=\"font-size: 72px; color: ' + (score >= 80 ? '#2ecc71' : score >= 60 ? '#f39c12' : '#e74c3c') + '; margin: 20px;\">' + score + '%</div>' +
          '<p style=\"font-size: 18px;\">Has obtenido una puntuación de ' + score + '% en esta evaluación.</p>' +
          '<div style=\"margin: 30px 0;\">' +
          '<div style=\"background: #f8f9fa; padding: 20px; border-radius: 10px; margin: 10px 0;\">' +
          '<strong>Respuestas Correctas:</strong> ' + Math.floor(score/10) + '/10<br>' +
          '<strong>Tiempo Utilizado:</strong> 4:23<br>' +
          '<strong>Área de Mayor Fortaleza:</strong> Reconocimiento de símbolos<br>' +
          '<strong>Área a Mejorar:</strong> Transcripción de palabras complejas' +
          '</div></div>'
        );
      }
      
      // Utility functions
      window.playAudio = function(filename) {
        // Simulate audio playback
        console.log('Playing audio: ' + filename);
        // In a real application, this would play the actual audio file
      };
      
      window.nextExercise = function() {
        alert('Cargando siguiente ejercicio...');
        // Generate new exercise of same type
      };
      
      window.showHint = function() {
        alert('Pista: Recuerda que los símbolos entre barras oblicuas representan fonemas.');
      };
      
      window.resetExercise = function() {
        location.reload();
      };
    ")
  })
  
  # Session end cleanup
  session$onSessionEnded(function() {
    # Save user progress
    # In a real application, this would save to a database
  })
}

# Run the application
shinyApp(ui = ui, server = server)