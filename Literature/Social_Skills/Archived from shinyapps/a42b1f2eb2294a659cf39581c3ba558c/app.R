library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(visNetwork)

# Define UI
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = "Personal Development Mastery Dashboard",
    titleWidth = 350
  ),
  
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem("The 5 AM Club", tabName = "five_am", icon = icon("sun")),
      menuItem("Captivate", tabName = "captivate", icon = icon("users")),
      menuItem("Limitless", tabName = "limitless", icon = icon("brain")),
      menuItem("Games People Play", tabName = "games", icon = icon("chess")),
      menuItem("Awaken Your Alpha", tabName = "alpha", icon = icon("fire")),
      menuItem("Ten Types of Humans", tabName = "ten_types", icon = icon("people-group"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .main-header .navbar {
          background-color: #1a237e !important;
        }
        .main-header .logo {
          background-color: #1a237e !important;
        }
        .sidebar {
          background-color: #283593 !important;
        }
        .content-wrapper {
          background-color: #f8f9fa !important;
        }
        .box {
          border-top: 3px solid #1a237e !important;
        }
        .nav-tabs-custom > .nav-tabs > li.active {
          border-top-color: #1a237e !important;
        }
      "))
    ),
    
    tabItems(
      # The 5 AM Club Tab
      tabItem(
        tabName = "five_am",
        fluidRow(
          box(
            title = "The 5 AM Club Framework", status = "primary", solidHeader = TRUE,
            width = 12, height = 200,
            h3(icon("sun"), " The Victory Hour (5-6 AM)"),
            p("Transform your mornings to transform your life through the 20/20/20 Formula:"),
            column(4,
                   div(style = "background-color: #e3f2fd; padding: 15px; border-radius: 5px;",
                       h4(icon("dumbbell"), " Move (20 min)"),
                       p("Exercise to activate neuroplasticity and release BDNF")
                   )
            ),
            column(4,
                   div(style = "background-color: #f3e5f5; padding: 15px; border-radius: 5px;",
                       h4(icon("meditation"), " Reflect (20 min)"),
                       p("Meditation, journaling, or prayer for clarity")
                   )
            ),
            column(4,
                   div(style = "background-color: #e8f5e8; padding: 15px; border-radius: 5px;",
                       h4(icon("book"), " Grow (20 min)"),
                       p("Learning through reading or skill development")
                   )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "20/20/20 Formula Tracker", status = "primary", solidHeader = TRUE,
            width = 6,
            sliderInput("exercise_min", "Exercise Minutes:", min = 0, max = 60, value = 20, step = 5),
            sliderInput("reflect_min", "Reflection Minutes:", min = 0, max = 60, value = 20, step = 5),
            sliderInput("learn_min", "Learning Minutes:", min = 0, max = 60, value = 20, step = 5),
            plotlyOutput("formula_chart")
          ),
          
          box(
            title = "The 4 Focuses of History-Makers", status = "primary", solidHeader = TRUE,
            width = 6,
            h4(icon("target"), " The Four Interior Empires:"),
            tags$ol(
              tags$li(tags$strong("Mindset:"), " Optimize psychology and beliefs"),
              tags$li(tags$strong("Heartset:"), " Emotional mastery and resilience"),
              tags$li(tags$strong("Healthset:"), " Physical energy and vitality"),
              tags$li(tags$strong("Soulset:"), " Spiritual connection and purpose")
            ),
            br(),
            h4(icon("cycle"), " Twin Cycles of Elite Performance:"),
            tags$ul(
              tags$li(tags$strong("High Excellence Cycle:"), " 90 days of intense focus"),
              tags$li(tags$strong("Deep Recovery Cycle:"), " 7 days of renewal")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Morning Routine Builder", status = "primary", solidHeader = TRUE,
            width = 8,
            column(4,
                   h4(icon("moon"), " Pre-5 AM Preparation"),
                   checkboxInput("early_sleep", "Sleep by 10 PM", value = TRUE),
                   checkboxInput("no_devices", "No devices 1hr before bed", value = TRUE),
                   checkboxInput("room_prep", "Prepare workout clothes", value = TRUE),
                   checkboxInput("hydrate", "Glass of water upon waking", value = TRUE)
            ),
            column(4,
                   h4(icon("clock"), " 5-6 AM Victory Hour"),
                   checkboxInput("move_20", "20 min Movement", value = TRUE),
                   checkboxInput("reflect_20", "20 min Reflection", value = TRUE),
                   checkboxInput("grow_20", "20 min Growth", value = TRUE),
                   checkboxInput("cold_shower", "Cold shower finish", value = FALSE)
            ),
            column(4,
                   h4(icon("calendar-day"), " Post-6 AM Excellence"),
                   checkboxInput("healthy_breakfast", "Nutritious breakfast", value = TRUE),
                   checkboxInput("day_planning", "Plan the day", value = TRUE),
                   checkboxInput("gratitude", "Gratitude practice", value = TRUE),
                   checkboxInput("visualization", "Goal visualization", value = FALSE)
            )
          ),
          
          box(
            title = "Habit Installation Progress", status = "primary", solidHeader = TRUE,
            width = 4,
            numericInput("days_practiced", "Days Practiced:", value = 1, min = 1, max = 66),
            plotlyOutput("habit_progress")
          )
        )
      ),
      
      # Captivate Tab
      tabItem(
        tabName = "captivate",
        fluidRow(
          box(
            title = "The Captivate Method - People Skills Matrix", status = "primary", solidHeader = TRUE,
            width = 12,
            h3(icon("users"), " Master the Art of Human Interaction"),
            p("Vanessa Van Edwards' system to decode people and build powerful connections")
          )
        ),
        
        fluidRow(
          box(
            title = "Microexpression Decoder", status = "primary", solidHeader = TRUE,
            width = 6,
            h4("The 7 Universal Microexpressions:"),
            selectInput("microexpression", "Choose Expression:",
                        choices = c("Happiness", "Sadness", "Anger", "Fear", 
                                    "Surprise", "Disgust", "Contempt")),
            textOutput("expression_meaning"),
            br(),
            h4("Body Language Checklist:"),
            checkboxInput("eye_contact", "Maintain appropriate eye contact", value = FALSE),
            checkboxInput("open_posture", "Use open body posture", value = FALSE),
            checkboxInput("mirroring", "Mirror the other person subtly", value = FALSE),
            checkboxInput("vocal_variety", "Use vocal variety and tone", value = FALSE)
          ),
          
          box(
            title = "Personality Matrix Assessment", status = "primary", solidHeader = TRUE,
            width = 6,
            h4("Rate yourself on these dimensions (1-10):"),
            sliderInput("extraversion", "Extraversion:", min = 1, max = 10, value = 5),
            sliderInput("agreeableness", "Agreeableness:", min = 1, max = 10, value = 5),
            sliderInput("conscientiousness", "Conscientiousness:", min = 1, max = 10, value = 5),
            sliderInput("neuroticism", "Neuroticism:", min = 1, max = 10, value = 5),
            sliderInput("openness", "Openness:", min = 1, max = 10, value = 5),
            plotlyOutput("personality_radar")
          )
        ),
        
        fluidRow(
          box(
            title = "Conversation Toolkit", status = "primary", solidHeader = TRUE,
            width = 12,
            h4("Question Bank:"),
            selectInput("question_type", "Question Category:",
                        choices = c("Icebreakers", "Deep Connectors", "Fun & Light", 
                                    "Professional", "Creative")),
            textOutput("sample_question"),
            br(),
            h4("The 5 Stages of Social Interaction:"),
            tags$ol(
              tags$li(tags$strong("The First Impression:"), " Non-verbal cues and presence"),
              tags$li(tags$strong("The Triple Threat:"), " Conversation starters that work"),
              tags$li(tags$strong("The Spark:"), " Finding mutual interests and passions"),
              tags$li(tags$strong("The Highlight Reel:"), " Memorable storytelling"),
              tags$li(tags$strong("The Follow-Up:"), " Building lasting connections")
            )
          )
        )
      ),
      
      # Limitless Tab
      tabItem(
        tabName = "limitless",
        fluidRow(
          box(
            title = "Limitless Framework by Jim Kwik", status = "primary", solidHeader = TRUE,
            width = 12,
            h3(icon("brain"), " Upgrade Your Brain, Learn Anything Faster"),
            p("The Limitless Model: Mindset × Methods × Motivation = Limitless Results")
          )
        ),
        
        fluidRow(
          box(
            title = "The Limitless Model Calculator", status = "primary", solidHeader = TRUE,
            width = 6,
            h4("Rate each component (1-10):"),
            sliderInput("mindset_score", "Mindset (What you believe):", min = 1, max = 10, value = 7),
            sliderInput("motivation_score", "Motivation (Why you learn):", min = 1, max = 10, value = 7),
            sliderInput("methods_score", "Methods (How you learn):", min = 1, max = 10, value = 7),
            h4("Your Limitless Score:"),
            verbatimTextOutput("limitless_score"),
            plotlyOutput("limitless_triangle")
          ),
          
          box(
            title = "Speed Reading Tracker", status = "primary", solidHeader = TRUE,
            width = 6,
            h4("Reading Speed Assessment:"),
            numericInput("words_read", "Words Read:", value = 200, min = 50),
            numericInput("time_minutes", "Time (minutes):", value = 1, min = 0.5, step = 0.5),
            h4("Your Reading Speed:"),
            verbatimTextOutput("reading_speed"),
            br(),
            h4("Speed Reading Techniques:"),
            checkboxInput("eliminate_subvocal", "Eliminate subvocalization", value = FALSE),
            checkboxInput("use_pacer", "Use finger/pen as pacer", value = FALSE),
            checkboxInput("preview_text", "Preview text before reading", value = FALSE),
            checkboxInput("chunk_reading", "Read in chunks, not word-by-word", value = FALSE)
          )
        ),
        
        fluidRow(
          box(
            title = "FASTER Learning Method", status = "primary", solidHeader = TRUE,
            width = 12,
            h4(icon("lightbulb"), " The FASTER Framework:"),
            column(6,
                   tags$ul(
                     tags$li(tags$strong("F") ,"orget - Forget what you think you know"),
                     tags$li(tags$strong("A") ,"ct - Take action, don't just consume"),
                     tags$li(tags$strong("S") ,"tate - Manage your mental and emotional state")
                   )
            ),
            column(6,
                   tags$ul(
                     tags$li(tags$strong("T") ,"each - Learn with the intention to teach"),
                     tags$li(tags$strong("E") ,"nter - Actively engage with the material"),
                     tags$li(tags$strong("R") ,"eview - Schedule spaced repetition")
                   )
            )
          )
        )
      ),
      
      # Games People Play Tab
      tabItem(
        tabName = "games",
        fluidRow(
          box(
            title = "Transactional Analysis - Games People Play", status = "primary", solidHeader = TRUE,
            width = 12,
            h3(icon("chess"), " Understanding Human Psychology and Social Interactions"),
            p("Eric Berne's groundbreaking theory on ego states and psychological games")
          )
        ),
        
        fluidRow(
          box(
            title = "The Three Ego States", status = "primary", solidHeader = TRUE,
            width = 8,
            selectInput("ego_state", "Select Ego State to Explore:",
                        choices = c("Parent" = "parent", "Adult" = "adult", "Child" = "child")),
            conditionalPanel(
              condition = "input.ego_state == 'parent'",
              div(style = "background-color: #ffebee; padding: 15px; border-radius: 5px;",
                  h4(icon("user-tie"), " Parent Ego State"),
                  p(tags$strong("Critical Parent:"), " Judgmental, controlling, rule-enforcing"),
                  p(tags$strong("Nurturing Parent:"), " Caring, protective, supportive"),
                  tags$ul(
                    tags$li("Contains learned behaviors from authority figures"),
                    tags$li("Operates from 'shoulds' and 'should nots'"),
                    tags$li("Can be helpful (guidance) or harmful (criticism)")
                  )
              )
            ),
            conditionalPanel(
              condition = "input.ego_state == 'adult'",
              div(style = "background-color: #e8f5e8; padding: 15px; border-radius: 5px;",
                  h4(icon("balance-scale"), " Adult Ego State"),
                  p("Rational, logical, problem-solving mindset"),
                  tags$ul(
                    tags$li("Processes information objectively"),
                    tags$li("Makes decisions based on facts"),
                    tags$li("Mediates between Parent and Child"),
                    tags$li("Goal: Healthy, mature responses")
                  )
              )
            ),
            conditionalPanel(
              condition = "input.ego_state == 'child'",
              div(style = "background-color: #fff3e0; padding: 15px; border-radius: 5px;",
                  h4(icon("child"), " Child Ego State"),
                  p(tags$strong("Free Child:"), " Spontaneous, creative, fun-loving"),
                  p(tags$strong("Adapted Child:"), " Compliant or rebellious to authority"),
                  tags$ul(
                    tags$li("Contains emotions and impulses"),
                    tags$li("Source of creativity and spontaneity"),
                    tags$li("Can be authentic or adapted to please others")
                  )
              )
            )
          ),
          
          box(
            title = "Psychological Games Detector", status = "primary", solidHeader = TRUE,
            width = 4,
            h4("Common Psychological Games:"),
            selectInput("game_type", "Select Game:",
                        choices = c("Why Don't You... Yes But",
                                    "If It Weren't For You",
                                    "See What You Made Me Do",
                                    "Wooden Leg",
                                    "Kick Me",
                                    "Now I've Got You")),
            textOutput("game_description")
          )
        ),
        
        fluidRow(
          box(
            title = "Life Positions Assessment", status = "primary", solidHeader = TRUE,
            width = 12,
            h4("The Four Life Positions:"),
            radioButtons("life_position", "Your dominant position:",
                         choices = c("I'm OK, You're OK" = "ok_ok",
                                     "I'm OK, You're Not OK" = "ok_not",
                                     "I'm Not OK, You're OK" = "not_ok",
                                     "I'm Not OK, You're Not OK" = "not_not")),
            textOutput("position_description")
          )
        )
      ),
      
      # Awaken Your Alpha Tab
      tabItem(
        tabName = "alpha",
        fluidRow(
          box(
            title = "Awaken Your Alpha - Adam Lewis Walker", status = "primary", solidHeader = TRUE,
            width = 12,
            h3(icon("fire"), " Transform into Your Most Powerful Self"),
            p("Unlock your inner alpha through mindset, physiology, and purposeful action")
          )
        ),
        
        fluidRow(
          box(
            title = "Alpha Assessment Dashboard", status = "primary", solidHeader = TRUE,
            width = 6,
            h4("Rate Your Alpha Qualities:"),
            sliderInput("confidence", "Confidence:", min = 1, max = 10, value = 5),
            sliderInput("discipline", "Discipline:", min = 1, max = 10, value = 5),
            sliderInput("leadership", "Leadership:", min = 1, max = 10, value = 5),
            sliderInput("authenticity", "Authenticity:", min = 1, max = 10, value = 5),
            sliderInput("resilience", "Resilience:", min = 1, max = 10, value = 5),
            plotlyOutput("alpha_radar")
          ),
          
          box(
            title = "Alpha Habits Tracker", status = "primary", solidHeader = TRUE,
            width = 6,
            h4("Daily Alpha Habits:"),
            checkboxInput("early_rise", "Rise before 6 AM", value = FALSE),
            checkboxInput("meditation_done", "10+ min meditation", value = FALSE),
            checkboxInput("physical_training", "Physical training", value = FALSE),
            checkboxInput("learning_time", "Skill/knowledge development", value = FALSE),
            checkboxInput("uncomfortable_action", "Did something uncomfortable", value = FALSE),
            checkboxInput("leadership_moment", "Showed leadership", value = FALSE),
            br(),
            h4("Alpha Mindset Principles:"),
            tags$ul(
              tags$li("Outcome Independence"),
              tags$li("Abundance Mentality"),
              tags$li("Personal Responsibility"),
              tags$li("Growth Orientation")
            )
          )
        )
      ),
      
      # Ten Types of Humans Tab
      tabItem(
        tabName = "ten_types",
        fluidRow(
          box(
            title = "Ten Types of Humans - Dexter Dias", status = "primary", solidHeader = TRUE,
            width = 12,
            h3(icon("people-group"), " Understanding Human Nature Through Science"),
            p("Explore the fundamental drives and behaviors that make us human, based on evolutionary psychology")
          )
        ),
        
        fluidRow(
          box(
            title = "The Ten Universal Human Types", status = "primary", solidHeader = TRUE,
            width = 8,
            selectInput("human_type", "Explore Each Human Type:",
                        choices = c("The Perceiver" = "perceiver",
                                    "The Kinship Maker" = "kinship",
                                    "The Rescuer" = "rescuer", 
                                    "The Tamer" = "tamer",
                                    "The Beguiler" = "beguiler",
                                    "The Tribalist" = "tribalist",
                                    "The Nurturer" = "nurturer",
                                    "The Romancer" = "romancer",
                                    "The Aggressor" = "aggressor",
                                    "The Voyeur" = "voyeur")),
            
            conditionalPanel(
              condition = "input.human_type == 'perceiver'",
              div(style = "background-color: #e3f2fd; padding: 15px; border-radius: 5px;",
                  h4(icon("eye"), " The Perceiver"),
                  p(tags$strong("Core Drive:"), " Pattern recognition and meaning-making"),
                  p("Seeks to understand, categorize, and make sense of the world through observation and analysis.")
              )
            ),
            
            conditionalPanel(
              condition = "input.human_type == 'kinship'",
              div(style = "background-color: #f3e5f5; padding: 15px; border-radius: 5px;",
                  h4(icon("handshake"), " The Kinship Maker"),
                  p(tags$strong("Core Drive:"), " Building connections and relationships"),
                  p("Naturally creates bonds, networks, and communities. The social glue of human society.")
              )
            ),
            
            conditionalPanel(
              condition = "input.human_type == 'rescuer'",
              div(style = "background-color: #e8f5e8; padding: 15px; border-radius: 5px;",
                  h4(icon("heart"), " The Rescuer"),
                  p(tags$strong("Core Drive:"), " Helping and protecting others"),
                  p("Compelled to save, help, and protect those in need. The caregiving instinct in action.")
              )
            )
          ),
          
          box(
            title = "Your Human Type Profile", status = "primary", solidHeader = TRUE,
            width = 4,
            h4("Rate your alignment (1-10):"),
            sliderInput("perceiver_score", "Perceiver:", min = 1, max = 10, value = 5),
            sliderInput("kinship_score", "Kinship Maker:", min = 1, max = 10, value = 5),
            sliderInput("rescuer_score", "Rescuer:", min = 1, max = 10, value = 5),
            sliderInput("tamer_score", "Tamer:", min = 1, max = 10, value = 5),
            sliderInput("beguiler_score", "Beguiler:", min = 1, max = 10, value = 5),
            plotlyOutput("human_types_chart")
          )
        )
      )
    )
  )
)

# Define Server Logic
server <- function(input, output, session) {
  
  # The 5 AM Club outputs
  output$formula_chart <- renderPlotly({
    data <- data.frame(
      Activity = c("Exercise", "Reflection", "Learning"),
      Minutes = c(input$exercise_min, input$reflect_min, input$learn_min),
      Target = c(20, 20, 20)
    )
    
    p <- ggplot(data, aes(x = Activity)) +
      geom_col(aes(y = Minutes), fill = "#1a237e", alpha = 0.8) +
      geom_point(aes(y = Target), color = "#ff5722", size = 4) +
      geom_line(aes(y = Target, group = 1), color = "#ff5722", linetype = "dashed") +
      labs(title = "20/20/20 Formula Progress", 
           y = "Minutes", x = "") +
      theme_minimal() +
      theme(plot.background = element_rect(fill = "white"))
    
    ggplotly(p)
  })
  
  output$habit_progress <- renderPlotly({
    days <- input$days_practiced
    progress <- min(100, (days / 66) * 100)
    
    data <- data.frame(
      Category = c("Completed", "Remaining"),
      Value = c(progress, 100 - progress)
    )
    
    p <- ggplot(data, aes(x = "", y = Value, fill = Category)) +
      geom_bar(stat = "identity", width = 1) +
      coord_polar("y", start = 0) +
      scale_fill_manual(values = c("#1a237e", "#e0e0e0")) +
      labs(title = paste0("Habit Installation: ", round(progress, 1), "%")) +
      theme_void()
    
    ggplotly(p)
  })
  
  # Captivate outputs
  output$expression_meaning <- renderText({
    meanings <- list(
      "Happiness" = "Genuine joy - look for crow's feet around eyes",
      "Sadness" = "Downturned mouth corners, drooping eyelids",
      "Anger" = "Furrowed brow, tightened lips, flared nostrils",
      "Fear" = "Wide eyes, raised eyebrows, open mouth",
      "Surprise" = "Raised eyebrows, wide eyes, dropped jaw",
      "Disgust" = "Wrinkled nose, raised upper lip",
      "Contempt" = "One-sided mouth raise, asymmetrical expression"
    )
    meanings[[input$microexpression]]
  })
  
  output$personality_radar <- renderPlotly({
    personality_data <- data.frame(
      Trait = c("Extraversion", "Agreeableness", "Conscientiousness", "Neuroticism", "Openness"),
      Score = c(input$extraversion, input$agreeableness, input$conscientiousness, 
                input$neuroticism, input$openness)
    )
    
    plot_ly(
      r = personality_data$Score,
      theta = personality_data$Trait,
      type = "scatterpolar",
      fill = "toself",
      fillcolor = "rgba(26, 35, 126, 0.3)",
      line = list(color = "#1a237e")
    ) %>%
      layout(
        polar = list(
          radialaxis = list(visible = TRUE, range = c(0, 10))
        ),
        title = "Personality Profile"
      )
  })
  
  output$sample_question <- renderText({
    questions <- list(
      "Icebreakers" = "What's the most interesting thing that happened to you this week?",
      "Deep Connectors" = "What's something you're passionate about that most people don't know?",
      "Fun & Light" = "If you could have dinner with anyone, dead or alive, who would it be?",
      "Professional" = "What project are you most excited about right now?",
      "Creative" = "If you could master any skill instantly, what would it be?"
    )
    questions[[input$question_type]]
  })
  
  # Limitless outputs
  output$limitless_score <- renderText({
    score <- input$mindset_score * input$motivation_score * input$methods_score
    paste("Your Limitless Score:", score, "/ 1000")
  })
  
  output$limitless_triangle <- renderPlotly({
    data <- data.frame(
      Component = c("Mindset", "Motivation", "Methods"),
      Score = c(input$mindset_score, input$motivation_score, input$methods_score)
    )
    
    p <- ggplot(data, aes(x = Component, y = Score)) +
      geom_col(fill = "#1a237e", alpha = 0.8) +
      geom_hline(yintercept = 7, color = "#ff5722", linetype = "dashed") +
      labs(title = "Limitless Model Components", 
           y = "Score (1-10)", x = "") +
      theme_minimal() +
      ylim(0, 10)
    
    ggplotly(p)
  })
  
  output$reading_speed <- renderText({
    wpm <- round(input$words_read / input$time_minutes)
    if (wpm < 200) {
      level <- "Below Average"
    } else if (wpm < 300) {
      level <- "Average"
    } else if (wpm < 500) {
      level <- "Good"
    } else {
      level <- "Excellent"
    }
    paste(wpm, "words per minute -", level)
  })
  
  # Games People Play outputs
  output$game_description <- renderText({
    games <- list(
      "Why Don't You... Yes But" = "Asking for advice but rejecting all suggestions to prove others can't help.",
      "If It Weren't For You" = "Blaming others for your limitations while secretly being grateful for the excuse.",
      "See What You Made Me Do" = "Provoking others into anger to justify your own bad behavior.",
      "Wooden Leg" = "Using a real or imagined disability as an excuse for not taking responsibility.",
      "Kick Me" = "Behaving in ways that invite criticism or punishment from others.",
      "Now I've Got You" = "Setting up others to make mistakes so you can feel superior."
    )
    games[[input$game_type]]
  })
  
  output$position_description <- renderText({
    positions <- list(
      "ok_ok" = "Healthy position: Mutual respect and collaboration.",
      "ok_not" = "Arrogant position: Looking down on others.",
      "not_ok" = "Depressive position: Feeling inferior to others.",
      "not_not" = "Futile position: Hopelessness about self and others."
    )
    positions[[input$life_position]]
  })
  
  # Awaken Your Alpha outputs
  output$alpha_radar <- renderPlotly({
    alpha_data <- data.frame(
      Quality = c("Confidence", "Discipline", "Leadership", "Authenticity", "Resilience"),
      Score = c(input$confidence, input$discipline, input$leadership, 
                input$authenticity, input$resilience)
    )
    
    plot_ly(
      r = alpha_data$Score,
      theta = alpha_data$Quality,
      type = "scatterpolar",
      fill = "toself",
      fillcolor = "rgba(26, 35, 126, 0.3)",
      line = list(color = "#1a237e")
    ) %>%
      layout(
        polar = list(
          radialaxis = list(visible = TRUE, range = c(0, 10))
        ),
        title = "Alpha Qualities Assessment"
      )
  })
  
  # Ten Types of Humans outputs
  output$human_types_chart <- renderPlotly({
    types_data <- data.frame(
      Type = c("Perceiver", "Kinship", "Rescuer", "Tamer", "Beguiler"),
      Score = c(input$perceiver_score, input$kinship_score, input$rescuer_score,
                input$tamer_score, input$beguiler_score)
    )
    
    p <- ggplot(types_data, aes(x = reorder(Type, Score), y = Score)) +
      geom_col(fill = "#1a237e", alpha = 0.8) +
      coord_flip() +
      labs(title = "Your Human Types Profile", 
           x = "Human Type", y = "Alignment Score") +
      theme_minimal()
    
    ggplotly(p)
  })
}

shinyApp(ui = ui, server = server)