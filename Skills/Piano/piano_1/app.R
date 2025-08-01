# Piano Learning Dashboard App
# Professional R Shiny application for piano education

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)

# Define UI
ui <- dashboardPage(
  skin = "black",
  
  # Header
  dashboardHeader(
    title = "Piano Learning Academy",
    titleWidth = 250
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 250,
    tags$head(
      tags$style(HTML("
        .skin-black .main-sidebar {
          background-color: #2c3e50;
        }
        .skin-black .sidebar-menu > li.active > a,
        .skin-black .sidebar-menu > li:hover > a {
          background-color: #34495e;
          border-left-color: #3498db;
        }
        .content-wrapper {
          background-color: #34495e;
        }
        .box {
          background-color: #2c3e50;
          border: 1px solid #34495e;
        }
        .box-header {
          color: #ecf0f1;
        }
        .box-body {
          color: #bdc3c7;
        }
        .nav-tabs-custom > .nav-tabs > li.active {
          border-top-color: #3498db;
        }
        .piano-key {
          display: inline-block;
          width: 40px;
          height: 120px;
          margin: 2px;
          border: 1px solid #333;
          text-align: center;
          line-height: 120px;
          font-weight: bold;
          cursor: pointer;
        }
        .white-key {
          background-color: #ecf0f1;
          color: #2c3e50;
        }
        .black-key {
          background-color: #2c3e50;
          color: #ecf0f1;
          width: 25px;
          height: 80px;
          margin-left: -15px;
          margin-right: -15px;
          z-index: 2;
          position: relative;
        }
        .staff-line {
          border-bottom: 2px solid #34495e;
          height: 20px;
          width: 100%;
          position: relative;
        }
        .note {
          width: 20px;
          height: 20px;
          background-color: #2c3e50;
          border-radius: 50%;
          position: absolute;
          border: 2px solid #ecf0f1;
        }
      "))
    ),
    
    sidebarMenu(
      menuItem("Basics & Theory", tabName = "basics", icon = icon("music")),
      menuItem("Musical Notation", tabName = "notation", icon = icon("file-music")),
      menuItem("Scales & Chords", tabName = "scales", icon = icon("chart-line")),
      menuItem("Practice Exercises", tabName = "practice", icon = icon("dumbbell")),
      menuItem("Progress Tracking", tabName = "progress", icon = icon("chart-bar")),
      menuItem("Best Practices", tabName = "tips", icon = icon("lightbulb"))
    )
  ),
  
  # Body
  dashboardBody(
    tabItems(
      # Tab 1: Basics & Theory
      tabItem(tabName = "basics",
              fluidRow(
                box(
                  title = "Piano Keyboard Layout", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  height = "200px",
                  div(
                    style = "text-align: center; padding: 20px;",
                    div(class = "piano-key white-key", "C"),
                    div(class = "piano-key black-key", "C#"),
                    div(class = "piano-key white-key", "D"),
                    div(class = "piano-key black-key", "D#"),
                    div(class = "piano-key white-key", "E"),
                    div(class = "piano-key white-key", "F"),
                    div(class = "piano-key black-key", "F#"),
                    div(class = "piano-key white-key", "G"),
                    div(class = "piano-key black-key", "G#"),
                    div(class = "piano-key white-key", "A"),
                    div(class = "piano-key black-key", "A#"),
                    div(class = "piano-key white-key", "B")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Basic Music Theory", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  h4("Note Names"),
                  p("The musical alphabet consists of 7 letters: A, B, C, D, E, F, G"),
                  h4("Sharps and Flats"),
                  p("# (sharp) raises a note by a semitone"),
                  p("♭ (flat) lowers a note by a semitone"),
                  h4("Octaves"),
                  p("Notes repeat every 12 semitones (8 white keys)")
                ),
                box(
                  title = "Hand Position", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  h4("Proper Posture"),
                  tags$ul(
                    tags$li("Sit tall with feet flat on floor"),
                    tags$li("Arms relaxed at your sides"),
                    tags$li("Wrists level with hands"),
                    tags$li("Curved fingers, like holding a small ball")
                  ),
                  h4("Finger Numbers"),
                  p("Thumb = 1, Index = 2, Middle = 3, Ring = 4, Pinky = 5")
                )
              )
      ),
      
      # Tab 2: Musical Notation
      tabItem(tabName = "notation",
              fluidRow(
                box(
                  title = "Staff and Clefs", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  h4("Treble Clef (Right Hand)"),
                  div(
                    style = "margin: 20px 0; background: #ecf0f1; padding: 20px; border-radius: 5px;",
                    div(style = "border-bottom: 2px solid #2c3e50; height: 15px; margin: 8px 0; position: relative;",
                        div(style = "position: absolute; right: 10px; top: -8px; background: #2c3e50; color: white; border-radius: 50%; width: 16px; height: 16px; text-align: center; font-size: 10px; line-height: 16px;", "F")),
                    div(style = "border-bottom: 2px solid #2c3e50; height: 15px; margin: 8px 0; position: relative;",
                        div(style = "position: absolute; right: 10px; top: -8px; background: #2c3e50; color: white; border-radius: 50%; width: 16px; height: 16px; text-align: center; font-size: 10px; line-height: 16px;", "D")),
                    div(style = "border-bottom: 2px solid #2c3e50; height: 15px; margin: 8px 0; position: relative;",
                        div(style = "position: absolute; right: 10px; top: -8px; background: #2c3e50; color: white; border-radius: 50%; width: 16px; height: 16px; text-align: center; font-size: 10px; line-height: 16px;", "B")),
                    div(style = "border-bottom: 2px solid #2c3e50; height: 15px; margin: 8px 0; position: relative;",
                        div(style = "position: absolute; right: 10px; top: -8px; background: #2c3e50; color: white; border-radius: 50%; width: 16px; height: 16px; text-align: center; font-size: 10px; line-height: 16px;", "G")),
                    div(style = "border-bottom: 2px solid #2c3e50; height: 15px; margin: 8px 0; position: relative;",
                        div(style = "position: absolute; right: 10px; top: -8px; background: #2c3e50; color: white; border-radius: 50%; width: 16px; height: 16px; text-align: center; font-size: 10px; line-height: 16px;", "E"))
                  ),
                  p("Lines (bottom to top): E, G, B, D, F - 'Every Good Boy Does Fine'"),
                  p("Spaces (bottom to top): F, A, C, E - 'FACE'")
                )
              ),
              fluidRow(
                box(
                  title = "Note Values", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  DT::dataTableOutput("noteValuesTable")
                ),
                box(
                  title = "Time Signatures", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  h4("Common Time Signatures"),
                  tags$ul(
                    tags$li("4/4: 4 quarter note beats per measure"),
                    tags$li("3/4: 3 quarter note beats per measure (waltz)"),
                    tags$li("2/4: 2 quarter note beats per measure"),
                    tags$li("6/8: 6 eighth note beats per measure")
                  )
                )
              )
      ),
      
      # Tab 3: Scales & Chords
      tabItem(tabName = "scales",
              fluidRow(
                box(
                  title = "Major Scales Pattern", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  plotlyOutput("scalesPlot", height = "300px")
                )
              ),
              fluidRow(
                box(
                  title = "Scale Degrees", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  DT::dataTableOutput("scaleDegreesTable")
                ),
                box(
                  title = "Basic Chords", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  h4("Triads in C Major"),
                  tags$ul(
                    tags$li("C Major: C - E - G"),
                    tags$li("D minor: D - F - A"),
                    tags$li("E minor: E - G - B"),
                    tags$li("F Major: F - A - C"),
                    tags$li("G Major: G - B - D"),
                    tags$li("A minor: A - C - E"),
                    tags$li("B diminished: B - D - F")
                  )
                )
              )
      ),
      
      # Tab 4: Practice Exercises
      tabItem(tabName = "practice",
              fluidRow(
                box(
                  title = "Daily Practice Routine", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  h4("Beginner (30 minutes)"),
                  tags$ol(
                    tags$li("Warm-up scales (5 min)"),
                    tags$li("Finger exercises (5 min)"),
                    tags$li("New piece practice (15 min)"),
                    tags$li("Review previous pieces (5 min)")
                  ),
                  h4("Intermediate (45 minutes)"),
                  tags$ol(
                    tags$li("Technical exercises (10 min)"),
                    tags$li("Scales and arpeggios (10 min)"),
                    tags$li("New repertoire (20 min)"),
                    tags$li("Performance pieces (5 min)")
                  )
                ),
                box(
                  title = "Metronome Practice", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  h4("Tempo Guidelines (BPM)"),
                  tags$ul(
                    tags$li("Beginner scales: 60-80"),
                    tags$li("Intermediate scales: 100-120"),
                    tags$li("Advanced scales: 140-160"),
                    tags$li("Sight-reading: 60-80"),
                    tags$li("New pieces: Start at 50% tempo")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Exercise Tracker", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  DT::dataTableOutput("exerciseTable")
                )
              )
      ),
      
      # Tab 5: Progress Tracking
      tabItem(tabName = "progress",
              fluidRow(
                box(
                  title = "Practice Time Tracking", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 8,
                  plotlyOutput("practiceTimeChart")
                ),
                box(
                  title = "Weekly Goals", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  h4("Current Week Goals"),
                  tags$ul(
                    tags$li("Practice 5 days minimum"),
                    tags$li("Master C Major scale"),
                    tags$li("Learn new piece: Minuet in G"),
                    tags$li("Improve sight-reading")
                  ),
                  h4("Achievement Level"),
                  div(style = "background: #27ae60; height: 20px; width: 75%; border-radius: 10px; margin: 10px 0;"),
                  p("75% Complete")
                )
              ),
              fluidRow(
                box(
                  title = "Skill Development", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  plotlyOutput("skillChart")
                )
              )
      ),
      
      # Tab 6: Best Practices
      tabItem(tabName = "tips",
              fluidRow(
                box(
                  title = "Practice Tips", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  h4("Effective Practice Strategies"),
                  tags$ul(
                    tags$li("Practice slowly and accurately first"),
                    tags$li("Use a metronome regularly"),
                    tags$li("Practice hands separately before together"),
                    tags$li("Break difficult passages into small sections"),
                    tags$li("Practice mental rehearsal away from piano"),
                    tags$li("Record yourself to identify areas for improvement")
                  )
                ),
                box(
                  title = "Common Mistakes to Avoid", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  h4("Pitfalls to Watch Out For"),
                  tags$ul(
                    tags$li("Practicing mistakes repeatedly"),
                    tags$li("Ignoring proper fingering"),
                    tags$li("Rushing through difficult sections"),
                    tags$li("Neglecting scales and technical work"),
                    tags$li("Poor posture and hand position"),
                    tags$li("Practicing only easy pieces")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Learning Progression", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  plotlyOutput("learningCurve")
                )
              )
      )
    )
  )
)

# Define Server Function
server <- function(input, output, session) {
  
  # Note Values Table
  output$noteValuesTable <- DT::renderDataTable({
    data.frame(
      "Note Type" = c("Whole Note", "Half Note", "Quarter Note", "Eighth Note", "Sixteenth Note"),
      "Symbol" = c("○", "♩", "♪", "♫", "♬"),
      "Beats (4/4 time)" = c("4", "2", "1", "0.5", "0.25"),
      stringsAsFactors = FALSE
    )
  }, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  
  # Scale Degrees Table
  output$scaleDegreesTable <- DT::renderDataTable({
    data.frame(
      "Degree" = c("1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"),
      "Name" = c("Tonic", "Supertonic", "Mediant", "Subdominant", 
                 "Dominant", "Submediant", "Leading Tone", "Octave"),
      "C Major" = c("C", "D", "E", "F", "G", "A", "B", "C"),
      stringsAsFactors = FALSE
    )
  }, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  
  # Exercise Table
  output$exerciseTable <- DT::renderDataTable({
    data.frame(
      "Exercise" = c("C Major Scale", "Hanon #1", "Chromatic Scale", "Alberti Bass", "Octaves"),
      "Difficulty" = c("Beginner", "Intermediate", "Intermediate", "Advanced", "Advanced"),
      "Focus Area" = c("Finger Independence", "Technique", "Chromatic Movement", "Left Hand", "Strength"),
      "Recommended BPM" = c("60-100", "80-120", "60-90", "70-100", "60-80"),
      stringsAsFactors = FALSE
    )
  }, options = list(pageLength = 10), rownames = FALSE)
  
  # Scales Plot
  output$scalesPlot <- renderPlotly({
    notes <- c("C", "D", "E", "F", "G", "A", "B", "C")
    intervals <- c(0, 2, 4, 5, 7, 9, 11, 12)
    
    p <- ggplot(data.frame(notes, intervals), aes(x = factor(notes, levels = notes), y = intervals)) +
      geom_col(fill = "#3498db", alpha = 0.8) +
      geom_text(aes(label = paste0(notes, "\n(", intervals, ")")), 
                vjust = -0.5, color = "#ecf0f1", size = 3) +
      labs(title = "C Major Scale - Semitone Intervals",
           x = "Notes", y = "Semitones from C") +
      theme_dark() +
      theme(
        plot.background = element_rect(fill = "#2c3e50"),
        panel.background = element_rect(fill = "#34495e"),
        text = element_text(color = "#ecf0f1"),
        axis.text = element_text(color = "#bdc3c7")
      )
    
    ggplotly(p) %>% 
      layout(plot_bgcolor = "#34495e", paper_bgcolor = "#2c3e50")
  })
  
  # Practice Time Chart
  output$practiceTimeChart <- renderPlotly({
    days <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    minutes <- c(45, 30, 60, 0, 40, 90, 35)
    
    p <- ggplot(data.frame(days = factor(days, levels = days), minutes), 
                aes(x = days, y = minutes)) +
      geom_col(fill = "#27ae60", alpha = 0.8) +
      geom_text(aes(label = paste0(minutes, " min")), 
                vjust = -0.5, color = "#ecf0f1", size = 3) +
      labs(title = "Weekly Practice Time",
           x = "Day", y = "Minutes Practiced") +
      theme_dark() +
      theme(
        plot.background = element_rect(fill = "#2c3e50"),
        panel.background = element_rect(fill = "#34495e"),
        text = element_text(color = "#ecf0f1"),
        axis.text = element_text(color = "#bdc3c7")
      )
    
    ggplotly(p) %>% 
      layout(plot_bgcolor = "#34495e", paper_bgcolor = "#2c3e50")
  })
  
  # Skill Development Chart
  output$skillChart <- renderPlotly({
    skills <- c("Technique", "Sight Reading", "Rhythm", "Expression", "Memory")
    current <- c(7, 5, 8, 6, 7)
    target <- c(9, 8, 9, 8, 9)
    
    df <- data.frame(
      skills = factor(rep(skills, 2), levels = skills),
      values = c(current, target),
      type = factor(rep(c("Current", "Target"), each = 5))
    )
    
    p <- ggplot(df, aes(x = skills, y = values, fill = type)) +
      geom_col(position = "dodge", alpha = 0.8) +
      scale_fill_manual(values = c("Current" = "#3498db", "Target" = "#e74c3c")) +
      labs(title = "Skill Development Progress",
           x = "Skills", y = "Level (1-10)") +
      ylim(0, 10) +
      theme_dark() +
      theme(
        plot.background = element_rect(fill = "#2c3e50"),
        panel.background = element_rect(fill = "#34495e"),
        text = element_text(color = "#ecf0f1"),
        axis.text = element_text(color = "#bdc3c7"),
        legend.background = element_rect(fill = "#2c3e50")
      )
    
    ggplotly(p) %>% 
      layout(plot_bgcolor = "#34495e", paper_bgcolor = "#2c3e50")
  })
  
  # Learning Curve
  output$learningCurve <- renderPlotly({
    months <- 1:12
    beginner <- c(1, 2, 3, 4, 5, 6, 6.5, 7, 7.2, 7.4, 7.5, 7.6)
    intermediate <- c(0, 0, 1, 2, 3, 4, 5, 6, 7, 7.5, 8, 8.2)
    advanced <- c(0, 0, 0, 0, 1, 1.5, 2, 3, 4, 5, 6, 6.5)
    
    df <- data.frame(
      months = rep(months, 3),
      skill_level = c(beginner, intermediate, advanced),
      category = rep(c("Beginner Skills", "Intermediate Skills", "Advanced Skills"), each = 12)
    )
    
    p <- ggplot(df, aes(x = months, y = skill_level, color = category)) +
      geom_line(size = 1.2) +
      geom_point(size = 2) +
      scale_color_manual(values = c("#27ae60", "#f39c12", "#e74c3c")) +
      labs(title = "Typical Piano Learning Progression",
           x = "Months of Practice", y = "Skill Level (1-10)",
           color = "Skill Category") +
      theme_dark() +
      theme(
        plot.background = element_rect(fill = "#2c3e50"),
        panel.background = element_rect(fill = "#34495e"),
        text = element_text(color = "#ecf0f1"),
        axis.text = element_text(color = "#bdc3c7"),
        legend.background = element_rect(fill = "#2c3e50")
      )
    
    ggplotly(p) %>% 
      layout(plot_bgcolor = "#34495e", paper_bgcolor = "#2c3e50")
  })
}

# Run the Shiny Application  
shinyApp(ui = ui, server = server)