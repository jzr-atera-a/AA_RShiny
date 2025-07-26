# Load required libraries
library(shiny)
library(shinydashboard)
library(plotly)
library(ggplot2)
library(dplyr)
library(DT)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "The Laws of Human Nature - Robert Greene"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("home")),
      menuItem("Irrationality", tabName = "irrationality", icon = icon("brain")),
      menuItem("Narcissism", tabName = "narcissism", icon = icon("mirror")),
      menuItem("Role Playing", tabName = "role_playing", icon = icon("theater-masks")),
      menuItem("Compulsiveness", tabName = "compulsiveness", icon = icon("repeat")),
      menuItem("Social Conformity", tabName = "conformity", icon = icon("users")),
      menuItem("Gender Dynamics", tabName = "gender", icon = icon("venus-mars")),
      menuItem("Generational Patterns", tabName = "generations", icon = icon("clock")),
      menuItem("Envy", tabName = "envy", icon = icon("eye")),
      menuItem("Grandiosity", tabName = "grandiosity", icon = icon("crown")),
      menuItem("Aggression", tabName = "aggression", icon = icon("fist-raised")),
      menuItem("Self-Awareness", tabName = "self_awareness", icon = icon("lightbulb"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f8f9fa;
        }
        .box {
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .law-title {
          color: #2c3e50;
          font-weight: bold;
          margin-bottom: 15px;
        }
        .principle {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
      "))
    ),
    
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "The Laws of Human Nature - Overview", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  h3("Robert Greene's Comprehensive Guide to Understanding Human Behavior"),
                  p("This dashboard explores the 18 laws outlined in Robert Greene's masterwork on human psychology and behavior. 
              Each law reveals fundamental patterns that govern how people think, feel, and act."),
                  br(),
                  h4("Key Themes:"),
                  tags$ul(
                    tags$li("Understanding the irrational forces that drive human behavior"),
                    tags$li("Recognizing social dynamics and power structures"),
                    tags$li("Developing emotional intelligence and self-awareness"),
                    tags$li("Learning to read and influence others ethically"),
                    tags$li("Mastering your own psychological patterns")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Laws Distribution by Category",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("laws_overview")
                ),
                box(
                  title = "Psychological Impact Scale",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("impact_scale")
                )
              )
      ),
      
      # Irrationality Tab
      tabItem(tabName = "irrationality",
              fluidRow(
                box(
                  title = "Law #1: Master Your Emotional Self", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Irrationality")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("Emotions and irrational impulses often override logical thinking. By understanding this tendency, 
                  you can develop greater self-control and make better decisions.")
                  ),
                  h4("Key Insights:"),
                  tags$ul(
                    tags$li("The rational mind is often hijacked by emotional reactions"),
                    tags$li("Stress and fatigue amplify irrational responses"),
                    tags$li("First impressions are heavily influenced by emotions, not facts"),
                    tags$li("Self-awareness is the first step to emotional mastery")
                  ),
                  h4("Practical Applications:"),
                  tags$ul(
                    tags$li("Pause before making important decisions when emotions are high"),
                    tags$li("Recognize your emotional triggers and patterns"),
                    tags$li("Use cooling-off periods for major choices"),
                    tags$li("Practice mindfulness to increase emotional awareness")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Emotional vs Rational Decision Making",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("emotion_ratio_plot")
                ),
                box(
                  title = "Emotional Triggers",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 4,
                  h5("Common Triggers:"),
                  tags$ul(
                    tags$li("Personal criticism"),
                    tags$li("Threats to status"),
                    tags$li("Financial pressure"),
                    tags$li("Time constraints"),
                    tags$li("Social rejection")
                  )
                )
              )
      ),
      
      # Narcissism Tab
      tabItem(tabName = "narcissism",
              fluidRow(
                box(
                  title = "Law #2: Transform Self-Love into Empathy", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Narcissism")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("Everyone has narcissistic tendencies - the deep need to feel special and validated. 
                  Understanding this in yourself and others is crucial for healthy relationships.")
                  ),
                  h4("Types of Narcissism:"),
                  tags$ul(
                    tags$li(strong("Deep Narcissists:"), " Grandiose, attention-seeking, lack empathy"),
                    tags$li(strong("Functional Narcissists:"), " Healthy self-esteem, can empathize"),
                    tags$li(strong("Healthy Narcissism:"), " Self-confidence without exploitation")
                  ),
                  h4("Warning Signs:"),
                  tags$ul(
                    tags$li("Constant need for admiration and validation"),
                    tags$li("Inability to handle criticism"),
                    tags$li("Lack of genuine empathy for others"),
                    tags$li("Grandiose sense of self-importance")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Narcissism Spectrum",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("narcissism_spectrum")
                ),
                box(
                  title = "Empathy Development",
                  status = "success",
                  solidHeader = TRUE,
                  width = 4,
                  h5("Building Empathy:"),
                  tags$ol(
                    tags$li("Listen without judgment"),
                    tags$li("Ask open-ended questions"),
                    tags$li("Practice perspective-taking"),
                    tags$li("Observe body language"),
                    tags$li("Validate others' emotions")
                  )
                )
              )
      ),
      
      # Role Playing Tab
      tabItem(tabName = "role_playing",
              fluidRow(
                box(
                  title = "Law #3: See Through People's Masks", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Role Playing")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("People constantly wear masks and play roles to fit social expectations. 
                  Learning to see past these personas reveals their true character.")
                  ),
                  h4("Common Social Masks:"),
                  tags$ul(
                    tags$li(strong("The Pleaser:"), " Always agreeable, hides true opinions"),
                    tags$li(strong("The Rebel:"), " Contrarian for attention, not conviction"),
                    tags$li(strong("The Victim:"), " Blames others, avoids responsibility"),
                    tags$li(strong("The Superior:"), " Acts condescending to hide insecurity")
                  ),
                  h4("Reading True Character:"),
                  tags$ul(
                    tags$li("Observe behavior under stress or when unguarded"),
                    tags$li("Notice patterns across different situations"),
                    tags$li("Pay attention to non-verbal cues"),
                    tags$li("Look for consistency between words and actions")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Authenticity vs Performance",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("authenticity_plot")
                ),
                box(
                  title = "Mask Detection Techniques",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  h5("Key Indicators:"),
                  tags$ul(
                    tags$li("Inconsistent behavior patterns"),
                    tags$li("Over-the-top emotional displays"),
                    tags$li("Stories that don't add up"),
                    tags$li("Defensiveness when questioned"),
                    tags$li("Rapid personality changes")
                  )
                )
              )
      ),
      
      # Compulsiveness Tab
      tabItem(tabName = "compulsiveness",
              fluidRow(
                box(
                  title = "Law #4: Determine the Strength of People's Character", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Compulsiveness")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("People have deeply ingrained patterns of behavior that they compulsively repeat. 
                  Understanding these patterns helps predict future actions.")
                  ),
                  h4("Character Patterns:"),
                  tags$ul(
                    tags$li(strong("The Rigid:"), " Inflexible, follows rules obsessively"),
                    tags$li(strong("The Dramatic:"), " Creates chaos and emotional scenes"),
                    tags$li(strong("The Dependent:"), " Constantly seeks approval and guidance"),
                    tags$li(strong("The Controlling:"), " Must dominate every situation")
                  ),
                  h4("Identifying Compulsive Patterns:"),
                  tags$ul(
                    tags$li("Look for repeated behaviors across time"),
                    tags$li("Notice how they handle stress and pressure"),
                    tags$li("Observe their relationships with authority"),
                    tags$li("Pay attention to their childhood stories")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Character Strength Assessment",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("character_strength")
                ),
                box(
                  title = "Pattern Recognition",
                  status = "success",
                  solidHeader = TRUE,
                  width = 4,
                  h5("Strong Character Signs:"),
                  tags$ul(
                    tags$li("Consistency under pressure"),
                    tags$li("Takes responsibility"),
                    tags$li("Adapts to change well"),
                    tags$li("Shows genuine empathy"),
                    tags$li("Maintains long-term relationships")
                  )
                )
              )
      ),
      
      # Social Conformity Tab
      tabItem(tabName = "conformity",
              fluidRow(
                box(
                  title = "Law #5: Become an Elusive Object of Desire", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Covetousness")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("People are drawn to what others desire and what seems scarce or forbidden. 
                  Understanding this tendency helps you become more attractive and influential.")
                  ),
                  h4("Social Proof Mechanisms:"),
                  tags$ul(
                    tags$li("Bandwagon effect - following the crowd"),
                    tags$li("Authority bias - deferring to experts"),
                    tags$li("Scarcity principle - wanting what's rare"),
                    tags$li("Social validation - seeking group approval")
                  ),
                  h4("Creating Healthy Independence:"),
                  tags$ul(
                    tags$li("Develop your own opinions before consulting others"),
                    tags$li("Question popular trends and assumptions"),
                    tags$li("Cultivate unique skills and perspectives"),
                    tags$li("Maintain mystery and unpredictability")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Conformity Pressure by Context",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("conformity_pressure")
                ),
                box(
                  title = "Independence Strategies",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 4,
                  h5("Building Autonomy:"),
                  tags$ol(
                    tags$li("Practice saying 'no'"),
                    tags$li("Delay decisions"),
                    tags$li("Seek diverse perspectives"),
                    tags$li("Question assumptions"),
                    tags$li("Trust your instincts")
                  )
                )
              )
      ),
      
      # Gender Dynamics Tab
      tabItem(tabName = "gender",
              fluidRow(
                box(
                  title = "Law #13: Advance with a Sense of Purpose", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Gender Rigidity")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("Understanding gender dynamics and stereotypes helps navigate social and professional relationships more effectively, 
                  while recognizing individual uniqueness beyond gender roles.")
                  ),
                  h4("Common Gender Patterns (Generalizations):"),
                  tags$ul(
                    tags$li("Communication styles and conflict resolution approaches"),
                    tags$li("Leadership and collaboration preferences"),
                    tags$li("Risk-taking and decision-making tendencies"),
                    tags$li("Social bonding and relationship building methods")
                  ),
                  h4("Transcending Limitations:"),
                  tags$ul(
                    tags$li("Develop both analytical and intuitive thinking"),
                    tags$li("Practice both assertive and collaborative styles"),
                    tags$li("Balance risk-taking with careful planning"),
                    tags$li("Cultivate emotional intelligence alongside logical reasoning")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Communication Style Preferences",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("gender_communication")
                ),
                box(
                  title = "Balanced Approach",
                  status = "success",
                  solidHeader = TRUE,
                  width = 4,
                  h5("Integration Strategies:"),
                  tags$ul(
                    tags$li("Adapt communication style to audience"),
                    tags$li("Combine logical and emotional appeals"),
                    tags$li("Practice both competition and cooperation"),
                    tags$li("Develop multiple leadership styles")
                  )
                )
              )
      ),
      
      # Generational Patterns Tab
      tabItem(tabName = "generations",
              fluidRow(
                box(
                  title = "Law #14: Resist the Downward Pull of the Group", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Generational Myopia")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("Each generation develops distinct values, communication styles, and worldviews based on their formative experiences. 
                  Understanding these differences improves cross-generational relationships.")
                  ),
                  h4("Generational Characteristics:"),
                  tags$ul(
                    tags$li(strong("Baby Boomers:"), " Value hierarchy, loyalty, face-to-face communication"),
                    tags$li(strong("Generation X:"), " Independent, skeptical, work-life balance focused"),
                    tags$li(strong("Millennials:"), " Tech-savvy, purpose-driven, collaborative"),
                    tags$li(strong("Generation Z:"), " Digital natives, entrepreneurial, socially conscious")
                  ),
                  h4("Bridging Generational Gaps:"),
                  tags$ul(
                    tags$li("Adapt communication methods to generational preferences"),
                    tags$li("Respect different approaches to work and technology"),
                    tags$li("Find common values despite different expressions"),
                    tags$li("Learn from each generation's unique strengths")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Generational Values Comparison",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("generational_values")
                ),
                box(
                  title = "Communication Preferences",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 4,
                  h5("By Generation:"),
                  tags$ul(
                    tags$li(strong("Boomers:"), " Phone, in-person"),
                    tags$li(strong("Gen X:"), " Email, direct"),
                    tags$li(strong("Millennials:"), " Text, collaborative"),
                    tags$li(strong("Gen Z:"), " Visual, instant")
                  )
                )
              )
      ),
      
      # Envy Tab
      tabItem(tabName = "envy",
              fluidRow(
                box(
                  title = "Law #10: Beware the Fragile Ego", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Envy")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("Envy is a universal emotion that can poison relationships and motivate destructive behavior. 
                  Learning to recognize and manage envy protects you from its harmful effects.")
                  ),
                  h4("Signs of Envy:"),
                  tags$ul(
                    tags$li("Passive-aggressive behavior toward successful people"),
                    tags$li("Subtle undermining or sabotage"),
                    tags$li("Excessive criticism disguised as 'helpful feedback'"),
                    tags$li("Joy at others' failures or setbacks")
                  ),
                  h4("Protecting Yourself from Envy:"),
                  tags$ul(
                    tags$li("Don't flaunt your successes unnecessarily"),
                    tags$li("Share credit and acknowledge others' contributions"),
                    tags$li("Be modest about achievements in certain company"),
                    tags$li("Recognize envious behavior patterns in others")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Envy Triggers and Intensity",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("envy_triggers")
                ),
                box(
                  title = "Managing Envy",
                  status = "danger",
                  solidHeader = TRUE,
                  width = 4,
                  h5("Personal Strategies:"),
                  tags$ul(
                    tags$li("Focus on your own journey"),
                    tags$li("Practice gratitude daily"),
                    tags$li("Celebrate others' successes"),
                    tags$li("Set personal goals"),
                    tags$li("Limit social media comparison")
                  )
                )
              )
      ),
      
      # Grandiosity Tab
      tabItem(tabName = "grandiosity",
              fluidRow(
                box(
                  title = "Law #11: Know Your Limits", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Grandiosity")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("Success can lead to inflated self-perception and poor decision-making. 
                  Maintaining humility and realistic self-assessment prevents destructive overconfidence.")
                  ),
                  h4("Grandiosity Warning Signs:"),
                  tags$ul(
                    tags$li("Believing you're immune to normal rules and limitations"),
                    tags$li("Dismissing advice from others as unnecessary"),
                    tags$li("Taking excessive risks without proper planning"),
                    tags$li("Attributing all success to personal brilliance")
                  ),
                  h4("Maintaining Perspective:"),
                  tags$ul(
                    tags$li("Regularly seek feedback from trusted advisors"),
                    tags$li("Study your failures as much as your successes"),
                    tags$li("Stay connected to your roots and early supporters"),
                    tags$li("Practice gratitude and acknowledge luck's role")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Success vs Grandiosity Curve",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("grandiosity_curve")
                ),
                box(
                  title = "Humility Practices",
                  status = "success",
                  solidHeader = TRUE,
                  width = 4,
                  h5("Stay Grounded:"),
                  tags$ol(
                    tags$li("Regular self-reflection"),
                    tags$li("Seek diverse perspectives"),
                    tags$li("Study historical examples"),
                    tags$li("Maintain learning mindset"),
                    tags$li("Practice gratitude")
                  )
                )
              )
      ),
      
      # Aggression Tab
      tabItem(tabName = "aggression",
              fluidRow(
                box(
                  title = "Law #12: Reconnect to the Masculine or Feminine Within You", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Aggression")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("Aggression manifests in many forms and can be channeled constructively or destructively. 
                  Understanding aggressive patterns helps you respond appropriately and protect yourself.")
                  ),
                  h4("Types of Aggression:"),
                  tags$ul(
                    tags$li(strong("Chronic:"), " Constant hostility and confrontation"),
                    tags$li(strong("Passive:"), " Indirect resistance and subtle sabotage"),
                    tags$li(strong("Micro:"), " Small acts of dominance and control"),
                    tags$li(strong("Assertive:"), " Healthy boundary-setting and self-advocacy")
                  ),
                  h4("Constructive Responses:"),
                  tags$ul(
                    tags$li("Remain calm and don't escalate conflicts"),
                    tags$li("Set clear boundaries without being aggressive"),
                    tags$li("Channel competitive energy into productive activities"),
                    tags$li("Address issues directly but diplomatically")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Aggression Response Strategies",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("aggression_response")
                ),
                box(
                  title = "De-escalation Techniques",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 4,
                  h5("Effective Methods:"),
                  tags$ul(
                    tags$li("Lower your voice"),
                    tags$li("Use calm body language"),
                    tags$li("Acknowledge their feelings"),
                    tags$li("Find common ground"),
                    tags$li("Redirect to solutions")
                  )
                )
              )
      ),
      
      # Self-Awareness Tab
      tabItem(tabName = "self_awareness",
              fluidRow(
                box(
                  title = "Law #18: See the Therapeutic Value of the Resistance", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  div(class = "law-title", h3("The Law of Self-Awareness")),
                  div(class = "principle", 
                      h4("Core Principle:"),
                      p("Self-awareness is the foundation of emotional intelligence and personal growth. 
                  Understanding your patterns, triggers, and motivations allows for conscious change.")
                  ),
                  h4("Components of Self-Awareness:"),
                  tags$ul(
                    tags$li(strong("Emotional Awareness:"), " Recognizing your feelings and their impact"),
                    tags$li(strong("Behavioral Patterns:"), " Understanding your habitual responses"),
                    tags$li(strong("Trigger Recognition:"), " Identifying what sets off emotional reactions"),
                    tags$li(strong("Value Clarity:"), " Knowing what truly matters to you")
                  ),
                  h4("Developing Self-Awareness:"),
                  tags$ul(
                    tags$li("Practice daily mindfulness and reflection"),
                    tags$li("Keep a journal of thoughts and emotions"),
                    tags$li("Seek feedback from trusted friends and mentors"),
                    tags$li("Notice your impact on others"),
                    tags$li("Study your own behavior patterns objectively")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Self-Awareness Development Path",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("self_awareness_path")
                ),
                box(
                  title = "Awareness Practices",
                  status = "success",
                  solidHeader = TRUE,
                  width = 4,
                  h5("Daily Practices:"),
                  tags$ul(
                    tags$li("Morning intention setting"),
                    tags$li("Mindful breathing"),
                    tags$li("Evening reflection"),
                    tags$li("Emotional check-ins"),
                    tags$li("Gratitude practice")
                  )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output) {
  
  # Overview plots
  output$laws_overview <- renderPlotly({
    categories <- data.frame(
      Category = c("Self-Knowledge", "Social Dynamics", "Power & Influence", "Emotional Patterns"),
      Count = c(5, 6, 4, 3),
      Description = c("Understanding yourself", "Reading others", "Leadership skills", "Managing emotions")
    )
    
    p <- ggplot(categories, aes(x = Category, y = Count, fill = Category)) +
      geom_col() +
      scale_fill_viridis_d() +
      theme_minimal() +
      labs(title = "Laws by Category", y = "Number of Laws") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p, tooltip = c("x", "y", "text"))
  })
  
  output$impact_scale <- renderPlotly({
    impact_data <- data.frame(
      Law = c("Irrationality", "Narcissism", "Role Playing", "Envy", "Grandiosity"),
      Impact = c(9, 8, 7, 9, 8),
      Frequency = c(95, 85, 90, 80, 60)
    )
    
    p <- ggplot(impact_data, aes(x = Impact, y = Frequency, size = Impact, color = Law)) +
      geom_point(alpha = 0.7) +
      scale_color_viridis_d() +
      theme_minimal() +
      labs(title = "Psychological Impact vs Frequency",
           x = "Impact Level (1-10)", 
           y = "Frequency in Population (%)") +
      xlim(0, 10) + ylim(0, 100)
    
    ggplotly(p)
  })
  
  # Irrationality plot
  output$emotion_ratio_plot <- renderPlotly({
    scenarios <- data.frame(
      Situation = c("Financial Stress", "Relationship Conflict", "Work Pressure", 
                    "Health Concerns", "Social Rejection", "Normal Day"),
      Emotional = c(85, 80, 70, 75, 90, 30),
      Rational = c(15, 20, 30, 25, 10, 70)
    )
    
    scenarios_long <- data.frame(
      Situation = rep(scenarios$Situation, 2),
      Response_Type = rep(c("Emotional", "Rational"), each = nrow(scenarios)),
      Percentage = c(scenarios$Emotional, scenarios$Rational)
    )
    
    p <- ggplot(scenarios_long, aes(x = Situation, y = Percentage, fill = Response_Type)) +
      geom_bar(stat = "identity", position = "stack") +
      scale_fill_manual(values = c("Emotional" = "#e74c3c", "Rational" = "#3498db")) +
      theme_minimal() +
      labs(title = "Emotional vs Rational Decision Making by Situation",
           y = "Percentage of Response Type") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Narcissism spectrum
  output$narcissism_spectrum <- renderPlotly({
    spectrum_data <- data.frame(
      Level = c("Healthy", "Moderate", "High", "Pathological"),
      Percentage = c(60, 25, 12, 3),
      Characteristics = c("Self-confident, empathetic", "Occasionally self-centered", 
                          "Often attention-seeking", "Lacks empathy, grandiose")
    )
    
    # Create ordered factor for proper ordering
    spectrum_data$Level <- factor(spectrum_data$Level, 
                                  levels = c("Healthy", "Moderate", "High", "Pathological"))
    
    p <- ggplot(spectrum_data, aes(x = Level, y = Percentage, fill = Level)) +
      geom_col() +
      scale_fill_manual(values = c("Healthy" = "#2ecc71", 
                                   "Moderate" = "#f39c12", 
                                   "High" = "#e67e22", 
                                   "Pathological" = "#e74c3c")) +
      theme_minimal() +
      labs(title = "Distribution of Narcissism Levels in Population",
           x = "Narcissism Level", y = "Percentage of Population") +
      theme(legend.position = "none")  # Remove legend since x-axis already shows levels
    
    ggplotly(p, tooltip = c("x", "y"))
  })
  
  # Authenticity plot
  output$authenticity_plot <- renderPlotly({
    contexts <- data.frame(
      Context = c("With Family", "Close Friends", "Workplace", "Social Media", "First Dates", "Job Interviews"),
      Authenticity = c(85, 80, 60, 40, 45, 35),
      Performance = c(15, 20, 40, 60, 55, 65)
    )
    
    contexts_long <- data.frame(
      Context = rep(contexts$Context, 2),
      Behavior_Type = rep(c("Authenticity", "Performance"), each = nrow(contexts)),
      Percentage = c(contexts$Authenticity, contexts$Performance)
    )
    
    p <- ggplot(contexts_long, aes(x = Context, y = Percentage, fill = Behavior_Type)) +
      geom_bar(stat = "identity", position = "fill") +
      scale_fill_manual(values = c("Authenticity" = "#27ae60", "Performance" = "#f39c12")) +
      theme_minimal() +
      labs(title = "Authenticity vs Performance by Social Context",
           y = "Proportion of Behavior") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Character strength assessment
  output$character_strength <- renderPlotly({
    traits <- data.frame(
      Trait = c("Consistency", "Resilience", "Empathy", "Integrity", "Adaptability", "Self-Control"),
      Strong_Character = c(85, 80, 75, 90, 70, 75),
      Weak_Character = c(30, 25, 35, 20, 40, 30)
    )
    
    traits_long <- data.frame(
      Trait = rep(traits$Trait, 2),
      Character_Type = rep(c("Strong_Character", "Weak_Character"), each = nrow(traits)),
      Score = c(traits$Strong_Character, traits$Weak_Character)
    )
    
    p <- ggplot(traits_long, aes(x = Trait, y = Score, fill = Character_Type)) +
      geom_bar(stat = "identity", position = "dodge") +
      scale_fill_manual(values = c("Strong_Character" = "#2ecc71", "Weak_Character" = "#e74c3c")) +
      theme_minimal() +
      labs(title = "Character Strength Indicators",
           y = "Average Score (0-100)",
           fill = "Character Type") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Conformity pressure plot
  output$conformity_pressure <- renderPlotly({
    pressure_data <- data.frame(
      Context = c("Workplace", "Social Groups", "Family", "Online Communities", "Religious Groups", "Political Groups"),
      Pressure_Level = c(75, 85, 60, 90, 70, 95),
      Resistance_Ability = c(40, 30, 55, 20, 45, 15)
    )
    
    p <- ggplot(pressure_data, aes(x = Pressure_Level, y = Resistance_Ability)) +
      geom_point(aes(color = Context, size = Pressure_Level), alpha = 0.7) +
      geom_smooth(method = "lm", se = FALSE, color = "red", linetype = "dashed") +
      scale_color_viridis_d() +
      theme_minimal() +
      labs(title = "Conformity Pressure vs Resistance Ability",
           x = "Conformity Pressure Level (%)",
           y = "Average Resistance Ability (%)") +
      xlim(0, 100) + ylim(0, 100)
    
    ggplotly(p)
  })
  
  # Gender communication plot
  output$gender_communication <- renderPlotly({
    comm_styles <- data.frame(
      Style = c("Direct/Assertive", "Collaborative", "Emotional Expression", "Analytical", "Relationship-Focused", "Task-Focused"),
      Traditional_Male = c(80, 40, 30, 75, 35, 85),
      Traditional_Female = c(45, 85, 80, 60, 85, 50),
      Modern_Balanced = c(65, 70, 60, 70, 65, 70)
    )
    
    comm_long <- data.frame(
      Style = rep(comm_styles$Style, 3),
      Approach = rep(c("Traditional_Male", "Traditional_Female", "Modern_Balanced"), each = nrow(comm_styles)),
      Preference = c(comm_styles$Traditional_Male, comm_styles$Traditional_Female, comm_styles$Modern_Balanced)
    )
    
    p <- ggplot(comm_long, aes(x = Style, y = Preference, fill = Approach)) +
      geom_bar(stat = "identity", position = "dodge") +
      scale_fill_manual(values = c("Traditional_Male" = "#3498db", 
                                   "Traditional_Female" = "#e74c3c", 
                                   "Modern_Balanced" = "#9b59b6")) +
      theme_minimal() +
      labs(title = "Communication Style Preferences",
           y = "Preference Level (0-100)") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Generational values plot
  output$generational_values <- renderPlotly({
    values_data <- data.frame(
      Value = c("Hierarchy", "Innovation", "Work-Life Balance", "Technology", "Social Justice", "Financial Security"),
      Baby_Boomers = c(85, 50, 40, 30, 60, 90),
      Gen_X = c(60, 65, 85, 60, 70, 85),
      Millennials = c(35, 85, 90, 85, 95, 70),
      Gen_Z = c(25, 90, 85, 95, 98, 60)
    )
    
    values_long <- data.frame(
      Value = rep(values_data$Value, 4),
      Generation = rep(c("Baby_Boomers", "Gen_X", "Millennials", "Gen_Z"), each = nrow(values_data)),
      Importance = c(values_data$Baby_Boomers, values_data$Gen_X, values_data$Millennials, values_data$Gen_Z)
    )
    
    p <- ggplot(values_long, aes(x = Value, y = Importance, color = Generation, group = Generation)) +
      geom_line(size = 1.2) +
      geom_point(size = 3) +
      scale_color_viridis_d() +
      theme_minimal() +
      labs(title = "Generational Values Comparison",
           y = "Importance Level (0-100)") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Envy triggers plot
  output$envy_triggers <- renderPlotly({
    triggers <- data.frame(
      Trigger = c("Financial Success", "Career Advancement", "Relationships", "Recognition", "Physical Appearance", "Lifestyle"),
      Intensity = c(85, 80, 70, 75, 60, 65),
      Frequency = c(70, 85, 60, 80, 90, 75)
    )
    
    p <- ggplot(triggers, aes(x = Frequency, y = Intensity)) +
      geom_point(aes(color = Trigger, size = Intensity), alpha = 0.7) +
      geom_text(aes(label = Trigger), vjust = -1, size = 3) +
      scale_color_viridis_d() +
      theme_minimal() +
      labs(title = "Envy Triggers: Frequency vs Intensity",
           x = "Frequency in Population (%)",
           y = "Average Intensity Level (%)") +
      xlim(50, 100) + ylim(50, 100)
    
    ggplotly(p, tooltip = c("x", "y", "colour"))
  })
  
  # Grandiosity curve plot
  output$grandiosity_curve <- renderPlotly({
    success_levels <- seq(0, 100, by = 5)
    grandiosity_risk <- pmin(100, pmax(0, (success_levels - 30)^1.5 / 10))
    effectiveness <- pmax(0, 100 - (grandiosity_risk * 0.8))
    
    curve_data <- data.frame(
      Success_Level = success_levels,
      Grandiosity_Risk = grandiosity_risk,
      Effectiveness = effectiveness
    )
    
    curve_long <- data.frame(
      Success_Level = rep(curve_data$Success_Level, 2),
      Metric = rep(c("Grandiosity_Risk", "Effectiveness"), each = nrow(curve_data)),
      Level = c(curve_data$Grandiosity_Risk, curve_data$Effectiveness)
    )
    
    p <- ggplot(curve_long, aes(x = Success_Level, y = Level, color = Metric)) +
      geom_line(size = 1.2) +
      scale_color_manual(values = c("Grandiosity_Risk" = "#e74c3c", "Effectiveness" = "#2ecc71")) +
      theme_minimal() +
      labs(title = "Success, Grandiosity Risk, and Effectiveness",
           x = "Success Level (%)",
           y = "Level (%)") +
      geom_vline(xintercept = 70, linetype = "dashed", alpha = 0.5) +
      annotate("text", x = 72, y = 50, label = "Danger Zone", angle = 90)
    
    ggplotly(p)
  })
  
  # Aggression response strategies
  output$aggression_response <- renderPlotly({
    strategies <- data.frame(
      Strategy = c("Avoidance", "Confrontation", "De-escalation", "Assertiveness", "Seeking Help"),
      Effectiveness = c(20, 30, 85, 80, 75),
      Risk_Level = c(10, 90, 15, 25, 20)
    )
    
    p <- ggplot(strategies, aes(x = Risk_Level, y = Effectiveness)) +
      geom_point(aes(color = Strategy, size = Effectiveness), alpha = 0.7) +
      geom_text(aes(label = Strategy), vjust = -1, size = 3) +
      scale_color_viridis_d() +
      theme_minimal() +
      labs(title = "Aggression Response Strategies: Risk vs Effectiveness",
           x = "Risk Level (%)",
           y = "Effectiveness (%)") +
      xlim(0, 100) + ylim(0, 100)
    
    ggplotly(p, tooltip = c("x", "y", "colour"))
  })
  
  # Self-awareness development path
  output$self_awareness_path <- renderPlotly({
    stages <- data.frame(
      Stage = c("Unconscious", "Awakening", "Recognition", "Understanding", "Integration", "Mastery"),
      Level = c(10, 25, 45, 65, 80, 95),
      Effort_Required = c(0, 20, 40, 60, 75, 85),
      Time_Months = c(0, 3, 9, 18, 36, 60)
    )
    
    p <- ggplot(stages, aes(x = Time_Months, y = Level)) +
      geom_line(color = "#3498db", size = 1.5) +
      geom_point(aes(size = Effort_Required), color = "#e74c3c", alpha = 0.7) +
      geom_text(aes(label = Stage), vjust = -1, size = 3) +
      theme_minimal() +
      labs(title = "Self-Awareness Development Journey",
           x = "Time Investment (Months)",
           y = "Self-Awareness Level (%)",
           size = "Effort Required") +
      xlim(0, 65) + ylim(0, 100)
    
    ggplotly(p)
  })
}

# Run the application
shinyApp(ui = ui, server = server)