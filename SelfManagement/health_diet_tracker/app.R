library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(tidyr)
library(lubridate)

# Define UI
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = "Health & Wellness Tracker",
    titleWidth = 280
  ),
  
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      id = "tabs",
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Weight Loss", tabName = "weight", icon = icon("weight")),
      menuItem("Nutrition", tabName = "nutrition", icon = icon("apple-alt")),
      menuItem("Exercise", tabName = "exercise", icon = icon("dumbbell")),
      menuItem("Sleep", tabName = "sleep", icon = icon("bed")),
      menuItem("Motivation", tabName = "motivation", icon = icon("fire")),
      menuItem("Goals", tabName = "goals", icon = icon("bullseye")),
      menuItem("Progress", tabName = "progress", icon = icon("chart-line"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f6f9;
        }
        .box {
          border-top: 3px solid #3c8dbc;
          box-shadow: 0 1px 3px rgba(0,0,0,0.12);
        }
        .small-box {
          border-radius: 4px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .info-box {
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .btn-primary {
          background-color: #3c8dbc;
          border-color: #3c8dbc;
        }
        .btn-success {
          background-color: #00a65a;
          border-color: #00a65a;
        }
        .nav-tabs-custom {
          box-shadow: 0 1px 3px rgba(0,0,0,0.12);
        }
        h3 {
          color: #3c8dbc;
          font-weight: 600;
        }
        .control-label {
          font-weight: 600;
          color: #555;
        }
      "))
    ),
    
    tabItems(
      # Dashboard Tab
      tabItem(
        tabName = "dashboard",
        fluidRow(
          valueBoxOutput("currentWeight", width = 3),
          valueBoxOutput("weightChange", width = 3),
          valueBoxOutput("avgSleep", width = 3),
          valueBoxOutput("weeklyWorkouts", width = 3)
        ),
        fluidRow(
          box(
            title = "Weekly Overview",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("weeklyOverview", height = 300)
          ),
          box(
            title = "Calorie Balance",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("calorieBalance", height = 300)
          )
        ),
        fluidRow(
          box(
            title = "Quick Actions",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            column(3, actionButton("logWeight", "Log Weight", class = "btn-primary btn-block")),
            column(3, actionButton("logMeal", "Log Meal", class = "btn-success btn-block")),
            column(3, actionButton("logWorkout", "Log Workout", class = "btn-warning btn-block")),
            column(3, actionButton("logSleep", "Log Sleep", class = "btn-info btn-block"))
          )
        )
      ),
      
      # Weight Loss Tab
      tabItem(
        tabName = "weight",
        fluidRow(
          box(
            title = "Weight Entry",
            status = "primary",
            solidHeader = TRUE,
            width = 4,
            dateInput("weightDate", "Date:", value = Sys.Date()),
            numericInput("weightValue", "Weight (lbs):", value = 150, min = 50, max = 500),
            numericInput("bodyFat", "Body Fat % (optional):", value = NULL, min = 5, max = 50),
            actionButton("submitWeight", "Submit Weight", class = "btn-primary btn-block")
          ),
          box(
            title = "Weight Goals",
            status = "success",
            solidHeader = TRUE,
            width = 4,
            numericInput("targetWeight", "Target Weight (lbs):", value = 140, min = 50, max = 500),
            numericInput("weeklyGoal", "Weekly Loss Goal (lbs):", value = 1.5, min = 0.5, max = 3, step = 0.5),
            dateInput("targetDate", "Target Date:", value = Sys.Date() + 90),
            actionButton("saveWeightGoal", "Save Goal", class = "btn-success btn-block")
          ),
          box(
            title = "Progress Summary",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            infoBoxOutput("totalLost", width = 12),
            infoBoxOutput("remainingLoss", width = 12),
            infoBoxOutput("projectedDate", width = 12)
          )
        ),
        fluidRow(
          box(
            title = "Weight Trend",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("weightTrend", height = 400)
          ),
          box(
            title = "Recent Entries",
            status = "primary",
            solidHeader = TRUE,
            width = 4,
            DTOutput("recentWeights")
          )
        )
      ),
      
      # Nutrition Tab
      tabItem(
        tabName = "nutrition",
        fluidRow(
          box(
            title = "Meal Logger",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            dateInput("mealDate", "Date:", value = Sys.Date()),
            selectInput("mealType", "Meal Type:", 
                        choices = c("Breakfast", "Lunch", "Dinner", "Snack")),
            textInput("mealDescription", "Description:", placeholder = "e.g., Grilled chicken salad"),
            numericInput("calories", "Calories:", value = 400, min = 0, max = 3000),
            numericInput("protein", "Protein (g):", value = 30, min = 0, max = 200),
            numericInput("carbs", "Carbs (g):", value = 40, min = 0, max = 300),
            numericInput("fats", "Fats (g):", value = 15, min = 0, max = 150),
            actionButton("submitMeal", "Log Meal", class = "btn-success btn-block")
          ),
          box(
            title = "Daily Targets",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            numericInput("targetCalories", "Daily Calorie Target:", value = 1800, min = 1000, max = 4000),
            numericInput("targetProtein", "Protein Target (g):", value = 120, min = 50, max = 300),
            numericInput("targetCarbs", "Carbs Target (g):", value = 180, min = 50, max = 400),
            numericInput("targetFats", "Fats Target (g):", value = 60, min = 20, max = 200),
            actionButton("saveNutritionGoals", "Save Targets", class = "btn-success btn-block"),
            hr(),
            plotlyOutput("macrosPie", height = 250)
          )
        ),
        fluidRow(
          box(
            title = "Daily Nutrition Progress",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("nutritionProgress", height = 350)
          ),
          box(
            title = "Today's Meals",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            DTOutput("todayMeals")
          )
        )
      ),
      
      # Exercise Tab
      tabItem(
        tabName = "exercise",
        fluidRow(
          box(
            title = "Workout Logger",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            dateInput("workoutDate", "Date:", value = Sys.Date()),
            selectInput("workoutType", "Workout Type:",
                        choices = c("Strength Training", "Cardio", "HIIT", "Yoga", "Sports", "Other")),
            textInput("workoutName", "Workout Name:", placeholder = "e.g., Upper Body Day"),
            numericInput("workoutDuration", "Duration (minutes):", value = 45, min = 5, max = 300),
            numericInput("caloriesBurned", "Calories Burned:", value = 300, min = 0, max = 2000),
            sliderInput("intensity", "Intensity:", min = 1, max = 10, value = 7),
            textAreaInput("workoutNotes", "Notes:", placeholder = "Exercise details, sets, reps...", rows = 3),
            actionButton("submitWorkout", "Log Workout", class = "btn-primary btn-block")
          ),
          box(
            title = "Weekly Exercise Plan",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            selectInput("planDay", "Day:", 
                        choices = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")),
            selectInput("planWorkoutType", "Planned Workout:",
                        choices = c("Rest", "Strength Training", "Cardio", "HIIT", "Yoga", "Sports", "Other")),
            numericInput("planDuration", "Planned Duration (min):", value = 45, min = 0, max = 300),
            actionButton("savePlan", "Save to Plan", class = "btn-success btn-block"),
            hr(),
            DTOutput("weeklyPlan")
          )
        ),
        fluidRow(
          box(
            title = "Workout History",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("workoutHistory", height = 350)
          ),
          box(
            title = "Exercise Statistics",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            infoBoxOutput("totalWorkouts", width = 12),
            infoBoxOutput("totalMinutes", width = 12),
            infoBoxOutput("avgIntensity", width = 12)
          )
        )
      ),
      
      # Sleep Tab
      tabItem(
        tabName = "sleep",
        fluidRow(
          box(
            title = "Sleep Logger",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            dateInput("sleepDate", "Date:", value = Sys.Date() - 1),
            numericInput("sleepHours", "Hours Slept:", value = 7.5, min = 0, max = 24, step = 0.5),
            sliderInput("sleepQuality", "Sleep Quality:", min = 1, max = 10, value = 7),
            checkboxGroupInput("sleepFactors", "Factors Affecting Sleep:",
                               choices = c("Stress", "Caffeine", "Exercise", "Late Meal", "Screen Time", "Alcohol"),
                               inline = TRUE),
            textAreaInput("sleepNotes", "Notes:", placeholder = "Any observations...", rows = 2),
            actionButton("submitSleep", "Log Sleep", class = "btn-info btn-block")
          ),
          box(
            title = "Sleep Goals & Routine",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            numericInput("targetSleep", "Target Hours:", value = 8, min = 6, max = 12, step = 0.5),
            textInput("bedtime", "Target Bedtime:", placeholder = "e.g., 10:30 PM"),
            textInput("waketime", "Target Wake Time:", placeholder = "e.g., 6:30 AM"),
            actionButton("saveSleepGoals", "Save Goals", class = "btn-success btn-block"),
            hr(),
            h4("Sleep Hygiene Checklist"),
            checkboxInput("darkRoom", "Dark, cool room"),
            checkboxInput("noScreen", "No screens 1hr before bed"),
            checkboxInput("regularSchedule", "Consistent schedule"),
            checkboxInput("noCaffeine", "No caffeine after 2pm")
          )
        ),
        fluidRow(
          box(
            title = "Sleep Trends",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("sleepTrends", height = 350)
          ),
          box(
            title = "Sleep Summary",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            infoBoxOutput("avgSleepHours", width = 12),
            infoBoxOutput("avgSleepQuality", width = 12),
            infoBoxOutput("sleepGoalProgress", width = 12)
          )
        )
      ),
      
      # Motivation Tab
      tabItem(
        tabName = "motivation",
        fluidRow(
          box(
            title = "Daily Motivation Check-in",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            dateInput("motivationDate", "Date:", value = Sys.Date()),
            sliderInput("motivationLevel", "Motivation Level:", min = 1, max = 10, value = 7),
            sliderInput("energyLevel", "Energy Level:", min = 1, max = 10, value = 7),
            sliderInput("moodLevel", "Mood:", min = 1, max = 10, value = 7),
            textAreaInput("gratitude", "What are you grateful for today?", rows = 2),
            textAreaInput("dailyWin", "Today's Win:", rows = 2),
            actionButton("submitMotivation", "Submit Check-in", class = "btn-primary btn-block")
          ),
          box(
            title = "Motivational Resources",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            h4("Your Why"),
            textAreaInput("whyStatement", "Why are you on this journey?", 
                          placeholder = "Write your compelling reason for change...", rows = 4),
            actionButton("saveWhy", "Save My Why", class = "btn-success btn-block"),
            hr(),
            h4("Daily Affirmations"),
            verbatimTextOutput("dailyAffirmation"),
            actionButton("newAffirmation", "New Affirmation", class = "btn-info")
          )
        ),
        fluidRow(
          box(
            title = "Motivation Trends",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("motivationTrends", height = 350)
          ),
          box(
            title = "Streak Tracker",
            status = "warning",
            solidHeader = TRUE,
            width = 4,
            infoBoxOutput("currentStreak", width = 12),
            infoBoxOutput("longestStreak", width = 12),
            infoBoxOutput("avgMotivation", width = 12)
          )
        ),
        fluidRow(
          box(
            title = "Vision Board",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            textAreaInput("visionGoals", "Describe your ideal future self (6 months from now):", 
                          placeholder = "Be specific about how you look, feel, and what you can do...", rows = 4),
            actionButton("saveVision", "Save Vision", class = "btn-success")
          )
        )
      ),
      
      # Goals Tab
      tabItem(
        tabName = "goals",
        fluidRow(
          box(
            title = "Set New Goal",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            selectInput("goalCategory", "Category:",
                        choices = c("Weight Loss", "Fitness", "Nutrition", "Sleep", "General")),
            textInput("goalTitle", "Goal Title:", placeholder = "e.g., Lose 20 lbs"),
            textAreaInput("goalDescription", "Description:", rows = 3),
            dateInput("goalDeadline", "Target Date:", value = Sys.Date() + 90),
            selectInput("goalPriority", "Priority:", choices = c("High", "Medium", "Low")),
            actionButton("submitGoal", "Add Goal", class = "btn-primary btn-block")
          ),
          box(
            title = "SMART Goal Framework",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            h4("Make Your Goals SMART:"),
            tags$ul(
              tags$li(tags$b("S"), "pecific - Clear and well-defined"),
              tags$li(tags$b("M"), "easurable - Track progress with numbers"),
              tags$li(tags$b("A"), "chievable - Realistic and attainable"),
              tags$li(tags$b("R"), "elevant - Aligned with your values"),
              tags$li(tags$b("T"), "ime-bound - Has a deadline")
            ),
            hr(),
            h4("Example Goals:"),
            tags$ul(
              tags$li("Lose 15 lbs by March 31st"),
              tags$li("Exercise 4x per week for 8 weeks"),
              tags$li("Sleep 7+ hours for 30 consecutive days"),
              tags$li("Eat 5 servings of vegetables daily")
            )
          )
        ),
        fluidRow(
          box(
            title = "Active Goals",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            DTOutput("activeGoals")
          )
        ),
        fluidRow(
          box(
            title = "Milestone Tracker",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            selectInput("milestoneGoal", "Select Goal:", choices = c("Goal 1", "Goal 2")),
            textInput("milestoneName", "Milestone Name:", placeholder = "e.g., Lost 5 lbs"),
            dateInput("milestoneDate", "Date Achieved:", value = Sys.Date()),
            actionButton("addMilestone", "Add Milestone", class = "btn-warning btn-block"),
            hr(),
            DTOutput("milestones")
          ),
          box(
            title = "Goal Progress",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("goalProgress", height = 350)
          )
        )
      ),
      
      # Progress Tab
      tabItem(
        tabName = "progress",
        fluidRow(
          box(
            title = "Time Range",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            dateRangeInput("progressDateRange", "Select Date Range:",
                           start = Sys.Date() - 90, end = Sys.Date()),
            actionButton("updateProgress", "Update Charts", class = "btn-primary")
          )
        ),
        fluidRow(
          box(
            title = "Overall Progress Score",
            status = "success",
            solidHeader = TRUE,
            width = 4,
            plotlyOutput("progressGauge", height = 300)
          ),
          box(
            title = "Category Breakdown",
            status = "info",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("categoryProgress", height = 300)
          )
        ),
        fluidRow(
          box(
            title = "Body Measurements",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("measurementsTrend", height = 350)
          ),
          box(
            title = "Consistency Heatmap",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("consistencyHeatmap", height = 350)
          )
        ),
        fluidRow(
          box(
            title = "Progress Photos",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            fileInput("progressPhoto", "Upload Progress Photo", accept = c('image/png', 'image/jpeg')),
            dateInput("photoDate", "Photo Date:", value = Sys.Date()),
            textInput("photoNotes", "Notes:", placeholder = "Weight, measurements, etc."),
            actionButton("savePhoto", "Save Photo", class = "btn-success btn-block")
          ),
          box(
            title = "Achievement Summary",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            h4("Total Achievements:"),
            verbatimTextOutput("achievementSummary"),
            hr(),
            h4("Recent Milestones:"),
            verbatimTextOutput("recentMilestones")
          )
        )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Reactive values for data storage
  weightData <- reactiveVal(data.frame(
    date = Sys.Date() - c(30:0),
    weight = 160 - c(0:30) * 0.3 + rnorm(31, 0, 0.5),
    bodyFat = 25 - c(0:30) * 0.1 + rnorm(31, 0, 0.3)
  ))
  
  nutritionData <- reactiveVal(data.frame(
    date = rep(Sys.Date(), 3),
    mealType = c("Breakfast", "Lunch", "Dinner"),
    description = c("Oatmeal with berries", "Chicken salad", "Salmon with veggies"),
    calories = c(350, 450, 550),
    protein = c(12, 35, 40),
    carbs = c(55, 30, 25),
    fats = c(8, 18, 22)
  ))
  
  workoutData <- reactiveVal(data.frame(
    date = Sys.Date() - c(6:0),
    type = c("Strength Training", "Cardio", "Rest", "HIIT", "Strength Training", "Yoga", "Cardio"),
    duration = c(45, 30, 0, 25, 50, 40, 35),
    calories = c(300, 350, 0, 400, 320, 180, 380),
    intensity = c(7, 6, 0, 9, 8, 5, 7)
  ))
  
  sleepData <- reactiveVal(data.frame(
    date = Sys.Date() - c(6:0),
    hours = c(7, 6.5, 8, 7.5, 6, 7, 8.5),
    quality = c(7, 6, 9, 8, 5, 7, 9)
  ))
  
  motivationData <- reactiveVal(data.frame(
    date = Sys.Date() - c(6:0),
    motivation = c(8, 7, 9, 8, 6, 7, 9),
    energy = c(7, 6, 8, 9, 5, 7, 8),
    mood = c(8, 7, 9, 8, 6, 8, 9)
  ))
  
  # Dashboard outputs
  output$currentWeight <- renderValueBox({
    weight_df <- weightData()
    current <- tail(weight_df$weight, 1)
    valueBox(
      paste0(round(current, 1), " lbs"),
      "Current Weight",
      icon = icon("weight"),
      color = "blue"
    )
  })
  
  output$weightChange <- renderValueBox({
    weight_df <- weightData()
    change <- tail(weight_df$weight, 1) - head(weight_df$weight, 1)
    valueBox(
      paste0(ifelse(change < 0, "", "+"), round(change, 1), " lbs"),
      "Total Change",
      icon = icon("chart-line"),
      color = if(change < 0) "green" else "red"
    )
  })
  
  output$avgSleep <- renderValueBox({
    sleep_df <- sleepData()
    avg <- mean(tail(sleep_df$hours, 7), na.rm = TRUE)
    valueBox(
      paste0(round(avg, 1), " hrs"),
      "Avg Sleep (7 days)",
      icon = icon("bed"),
      color = if(avg >= 7) "green" else "yellow"
    )
  })
  
  output$weeklyWorkouts <- renderValueBox({
    workout_df <- workoutData()
    count <- sum(tail(workout_df$duration, 7) > 0)
    valueBox(
      count,
      "Workouts This Week",
      icon = icon("dumbbell"),
      color = if(count >= 3) "green" else "yellow"
    )
  })
  
  output$weeklyOverview <- renderPlotly({
    workout_df <- workoutData()
    recent <- tail(workout_df, 7)
    
    plot_ly(recent, x = ~date, y = ~duration, type = 'bar', name = 'Exercise (min)',
            marker = list(color = '#3c8dbc')) %>%
      layout(title = "", xaxis = list(title = ""), yaxis = list(title = "Minutes"),
             showlegend = FALSE)
  })
  
  output$calorieBalance <- renderPlotly({
    nutrition_df <- nutritionData()
    today_cals <- sum(nutrition_df$calories[nutrition_df$date == Sys.Date()])
    target <- 1800
    
    plot_ly(
      type = "indicator",
      mode = "gauge+number+delta",
      value = today_cals,
      delta = list(reference = target),
      gauge = list(
        axis = list(range = list(NULL, 2500)),
        bar = list(color = if(today_cals <= target) "green" else "orange"),
        steps = list(
          list(range = c(0, target), color = "lightgray")
        ),
        threshold = list(
          line = list(color = "red", width = 4),
          thickness = 0.75,
          value = target
        )
      )
    ) %>%
      layout(margin = list(l = 20, r = 20, t = 20, b = 20))
  })
  
  # Weight Loss Tab
  output$weightTrend <- renderPlotly({
    weight_df <- weightData()
    
    plot_ly(weight_df, x = ~date) %>%
      add_trace(y = ~weight, type = 'scatter', mode = 'lines+markers',
                name = 'Weight', line = list(color = '#3c8dbc', width = 3),
                marker = list(size = 8, color = '#3c8dbc')) %>%
      add_trace(y = ~predict(loess(weight ~ as.numeric(date), data = weight_df)),
                type = 'scatter', mode = 'lines', name = 'Trend',
                line = list(color = '#00a65a', width = 2, dash = 'dash')) %>%
      layout(title = "", xaxis = list(title = "Date"),
             yaxis = list(title = "Weight (lbs)"),
             hovermode = 'x unified')
  })
  
  output$recentWeights <- renderDT({
    weight_df <- weightData()
    recent <- tail(weight_df, 10)
    recent$date <- as.character(recent$date)
    recent$weight <- round(recent$weight, 1)
    recent$bodyFat <- round(recent$bodyFat, 1)
    datatable(recent[order(recent$date, decreasing = TRUE), ],
              options = list(pageLength = 5, dom = 't'),
              rownames = FALSE)
  })
  
  output$totalLost <- renderInfoBox({
    weight_df <- weightData()
    total <- head(weight_df$weight, 1) - tail(weight_df$weight, 1)
    infoBox(
      "Total Lost",
      paste0(round(total, 1), " lbs"),
      icon = icon("arrow-down"),
      color = "green"
    )
  })
  
  output$remainingLoss <- renderInfoBox({
    weight_df <- weightData()
    current <- tail(weight_df$weight, 1)
    remaining <- current - 140  # target weight
    infoBox(
      "To Goal",
      paste0(round(remaining, 1), " lbs"),
      icon = icon("bullseye"),
      color = "blue"
    )
  })
  
  output$projectedDate <- renderInfoBox({
    infoBox(
      "Projected Goal Date",
      format(Sys.Date() + 60, "%b %d"),
      icon = icon("calendar"),
      color = "yellow"
    )
  })
  
  # Nutrition Tab
  output$macrosPie <- renderPlotly({
    plot_ly(
      labels = c("Protein", "Carbs", "Fats"),
      values = c(120, 180, 60),
      type = 'pie',
      marker = list(colors = c('#3c8dbc', '#00a65a', '#f39c12'))
    ) %>%
      layout(title = "Daily Macro Targets",
             showlegend = TRUE,
             margin = list(l = 10, r = 10, t = 40, b = 10))
  })
  
  output$nutritionProgress <- renderPlotly({
    categories <- c("Calories", "Protein", "Carbs", "Fats")
    current <- c(1650, 115, 170, 58)
    target <- c(1800, 120, 180, 60)
    
    plot_ly(x = categories, y = current, type = 'bar', name = 'Current',
            marker = list(color = '#3c8dbc')) %>%
      add_trace(y = target, name = 'Target', marker = list(color = '#00a65a')) %>%
      layout(title = "", yaxis = list(title = "Amount"),
             barmode = 'group', xaxis = list(title = ""))
  })
  
  output$todayMeals <- renderDT({
    nutrition_df <- nutritionData()
    today <- nutrition_df[nutrition_df$date == Sys.Date(), ]
    datatable(today[, c("mealType", "description", "calories", "protein")],
              options = list(pageLength = 5, dom = 't'),
              rownames = FALSE, colnames = c("Meal", "Food", "Cal", "Protein"))
  })
  
  # Exercise Tab
  output$workoutHistory <- renderPlotly({
    workout_df <- workoutData()
    recent <- tail(workout_df, 14)
    
    plot_ly(recent, x = ~date, y = ~duration, type = 'bar',
            marker = list(color = ~intensity, colorscale = 'Blues',
                          colorbar = list(title = "Intensity"))) %>%
      layout(title = "", xaxis = list(title = ""),
             yaxis = list(title = "Duration (minutes)"))
  })
  
  output$weeklyPlan <- renderDT({
    plan_df <- data.frame(
      Day = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"),
      Workout = c("Strength", "Cardio", "HIIT", "Strength", "Yoga", "Cardio", "Rest"),
      Duration = c(45, 30, 25, 50, 40, 35, 0)
    )
    datatable(plan_df, options = list(pageLength = 7, dom = 't'), rownames = FALSE)
  })
  
  output$totalWorkouts <- renderInfoBox({
    workout_df <- workoutData()
    total <- sum(workout_df$duration > 0)
    infoBox(
      "Total Workouts",
      total,
      icon = icon("check-circle"),
      color = "green"
    )
  })
  
  output$totalMinutes <- renderInfoBox({
    workout_df <- workoutData()
    total <- sum(workout_df$duration, na.rm = TRUE)
    infoBox(
      "Total Minutes",
      total,
      icon = icon("clock"),
      color = "blue"
    )
  })
  
  output$avgIntensity <- renderInfoBox({
    workout_df <- workoutData()
    avg <- mean(workout_df$intensity[workout_df$duration > 0], na.rm = TRUE)
    infoBox(
      "Avg Intensity",
      paste0(round(avg, 1), "/10"),
      icon = icon("fire"),
      color = "orange"
    )
  })
  
  # Sleep Tab
  output$sleepTrends <- renderPlotly({
    sleep_df <- sleepData()
    recent <- tail(sleep_df, 14)
    
    plot_ly(recent, x = ~date) %>%
      add_trace(y = ~hours, type = 'scatter', mode = 'lines+markers',
                name = 'Hours', line = list(color = '#3c8dbc', width = 2),
                marker = list(size = 8)) %>%
      add_trace(y = ~quality, type = 'scatter', mode = 'lines+markers',
                name = 'Quality', yaxis = 'y2',
                line = list(color = '#00a65a', width = 2),
                marker = list(size = 8)) %>%
      layout(
        title = "",
        xaxis = list(title = ""),
        yaxis = list(title = "Hours Slept", side = 'left'),
        yaxis2 = list(title = "Quality (1-10)", overlaying = 'y', side = 'right'),
        legend = list(x = 0.1, y = 1)
      )
  })
  
  output$avgSleepHours <- renderInfoBox({
    sleep_df <- sleepData()
    avg <- mean(tail(sleep_df$hours, 7), na.rm = TRUE)
    infoBox(
      "Avg Sleep (7d)",
      paste0(round(avg, 1), " hrs"),
      icon = icon("moon"),
      color = if(avg >= 7) "blue" else "yellow"
    )
  })
  
  output$avgSleepQuality <- renderInfoBox({
    sleep_df <- sleepData()
    avg <- mean(tail(sleep_df$quality, 7), na.rm = TRUE)
    infoBox(
      "Avg Quality",
      paste0(round(avg, 1), "/10"),
      icon = icon("star"),
      color = if(avg >= 7) "green" else "orange"
    )
  })
  
  output$sleepGoalProgress <- renderInfoBox({
    sleep_df <- sleepData()
    days_met <- sum(tail(sleep_df$hours, 7) >= 7.5)
    infoBox(
      "Days Meeting Goal",
      paste0(days_met, "/7"),
      icon = icon("check"),
      color = if(days_met >= 5) "green" else "red"
    )
  })
  
  # Motivation Tab
  affirmations <- c(
    "I am capable of achieving my health goals.",
    "Every day I am getting stronger and healthier.",
    "I choose to fuel my body with nutritious food.",
    "I am committed to my wellness journey.",
    "My body is transforming every single day.",
    "I have the discipline to reach my goals.",
    "I am worthy of a healthy, vibrant life.",
    "Progress, not perfection, is my goal.",
    "I am building sustainable healthy habits.",
    "My dedication today creates my success tomorrow."
  )
  
  currentAffirmation <- reactiveVal(sample(affirmations, 1))
  
  output$dailyAffirmation <- renderText({
    currentAffirmation()
  })
  
  observeEvent(input$newAffirmation, {
    currentAffirmation(sample(affirmations, 1))
  })
  
  output$motivationTrends <- renderPlotly({
    motivation_df <- motivationData()
    recent <- tail(motivation_df, 14)
    
    plot_ly(recent, x = ~date) %>%
      add_trace(y = ~motivation, type = 'scatter', mode = 'lines+markers',
                name = 'Motivation', line = list(color = '#f39c12', width = 2)) %>%
      add_trace(y = ~energy, type = 'scatter', mode = 'lines+markers',
                name = 'Energy', line = list(color = '#3c8dbc', width = 2)) %>%
      add_trace(y = ~mood, type = 'scatter', mode = 'lines+markers',
                name = 'Mood', line = list(color = '#00a65a', width = 2)) %>%
      layout(title = "", xaxis = list(title = ""),
             yaxis = list(title = "Level (1-10)", range = c(0, 10)))
  })
  
  output$currentStreak <- renderInfoBox({
    infoBox(
      "Current Streak",
      "7 days",
      icon = icon("fire"),
      color = "orange"
    )
  })
  
  output$longestStreak <- renderInfoBox({
    infoBox(
      "Longest Streak",
      "21 days",
      icon = icon("trophy"),
      color = "yellow"
    )
  })
  
  output$avgMotivation <- renderInfoBox({
    motivation_df <- motivationData()
    avg <- mean(tail(motivation_df$motivation, 7), na.rm = TRUE)
    infoBox(
      "Avg Motivation",
      paste0(round(avg, 1), "/10"),
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  # Goals Tab
  goalsData <- reactiveVal(data.frame(
    category = c("Weight Loss", "Fitness", "Sleep"),
    title = c("Lose 20 lbs", "Run 5K", "Sleep 8hrs daily"),
    deadline = c(Sys.Date() + 60, Sys.Date() + 45, Sys.Date() + 30),
    priority = c("High", "Medium", "High"),
    progress = c(35, 60, 70),
    status = c("In Progress", "In Progress", "In Progress")
  ))
  
  output$activeGoals <- renderDT({
    goals <- goalsData()
    datatable(goals, options = list(pageLength = 10, dom = 'tp'),
              rownames = FALSE)
  })
  
  output$milestones <- renderDT({
    milestone_df <- data.frame(
      Goal = c("Lose 20 lbs", "Lose 20 lbs", "Run 5K"),
      Milestone = c("Lost 5 lbs", "Lost 10 lbs", "Ran 2K"),
      Date = c(Sys.Date() - 20, Sys.Date() - 10, Sys.Date() - 5)
    )
    datatable(milestone_df, options = list(pageLength = 5, dom = 't'),
              rownames = FALSE)
  })
  
  output$goalProgress <- renderPlotly({
    goals <- goalsData()
    
    plot_ly(goals, x = ~title, y = ~progress, type = 'bar',
            marker = list(color = '#00a65a')) %>%
      layout(title = "", xaxis = list(title = ""),
             yaxis = list(title = "Progress (%)", range = c(0, 100)))
  })
  
  # Progress Tab
  output$progressGauge <- renderPlotly({
    overall_score <- 78
    
    plot_ly(
      type = "indicator",
      mode = "gauge+number",
      value = overall_score,
      title = list(text = "Overall Progress"),
      gauge = list(
        axis = list(range = list(NULL, 100)),
        bar = list(color = "#00a65a"),
        steps = list(
          list(range = c(0, 50), color = "lightgray"),
          list(range = c(50, 75), color = "#f39c12"),
          list(range = c(75, 100), color = "#00a65a")
        ),
        threshold = list(
          line = list(color = "red", width = 4),
          thickness = 0.75,
          value = 90
        )
      )
    ) %>%
      layout(margin = list(l = 20, r = 20, t = 50, b = 20))
  })
  
  output$categoryProgress <- renderPlotly({
    categories <- c("Weight Loss", "Nutrition", "Exercise", "Sleep", "Consistency")
    scores <- c(85, 75, 90, 70, 80)
    
    plot_ly(
      r = scores,
      theta = categories,
      type = 'scatterpolar',
      fill = 'toself',
      fillcolor = 'rgba(60, 141, 188, 0.5)',
      line = list(color = '#3c8dbc', width = 2)
    ) %>%
      layout(
        polar = list(
          radialaxis = list(visible = TRUE, range = c(0, 100))
        ),
        showlegend = FALSE
      )
  })
  
  output$measurementsTrend <- renderPlotly({
    weight_df <- weightData()
    recent <- tail(weight_df, 30)
    
    plot_ly(recent, x = ~date) %>%
      add_trace(y = ~weight, type = 'scatter', mode = 'lines+markers',
                name = 'Weight', line = list(color = '#3c8dbc', width = 2)) %>%
      add_trace(y = ~bodyFat * 6, type = 'scatter', mode = 'lines+markers',
                name = 'Body Fat %', yaxis = 'y2',
                line = list(color = '#f39c12', width = 2)) %>%
      layout(
        title = "",
        xaxis = list(title = ""),
        yaxis = list(title = "Weight (lbs)"),
        yaxis2 = list(title = "Body Fat %", overlaying = 'y', side = 'right',
                      range = c(15, 30)),
        legend = list(x = 0.1, y = 1)
      )
  })
  
  output$consistencyHeatmap <- renderPlotly({
    dates <- seq(Sys.Date() - 29, Sys.Date(), by = "day")
    consistency <- sample(0:3, 30, replace = TRUE, prob = c(0.1, 0.2, 0.3, 0.4))
    
    weeks <- rep(1:5, each = 6)[1:30]
    days <- rep(0:6, 5)[1:30]
    
    plot_ly(x = days, y = weeks, z = consistency,
            type = "heatmap",
            colorscale = list(c(0, 'lightgray'), c(0.33, '#ffeda0'),
                              c(0.66, '#feb24c'), c(1, '#00a65a')),
            showscale = FALSE) %>%
      layout(
        title = "Activity Consistency (Last 30 Days)",
        xaxis = list(title = "", ticktext = c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"),
                     tickvals = 0:6),
        yaxis = list(title = "Week", autorange = "reversed")
      )
  })
  
  output$achievementSummary <- renderText({
    paste(
      "🏆 Goals Achieved: 3",
      "⭐ Milestones Reached: 8",
      "🔥 Current Streak: 7 days",
      "💪 Workouts Completed: 24",
      "📉 Total Weight Lost: 10.5 lbs",
      sep = "\n"
    )
  })
  
  output$recentMilestones <- renderText({
    paste(
      "✓ Lost 10 lbs (Oct 1)",
      "✓ 7-day workout streak (Sep 28)",
      "✓ Logged 30 days of meals (Sep 25)",
      "✓ Slept 8+ hours for 5 days (Sep 20)",
      sep = "\n"
    )
  })
  
  # Event handlers for form submissions
  observeEvent(input$submitWeight, {
    current_data <- weightData()
    new_entry <- data.frame(
      date = input$weightDate,
      weight = input$weightValue,
      bodyFat = ifelse(is.null(input$bodyFat) || is.na(input$bodyFat), NA, input$bodyFat)
    )
    weightData(rbind(current_data, new_entry))
    showNotification("Weight logged successfully!", type = "message")
  })
  
  observeEvent(input$submitMeal, {
    current_data <- nutritionData()
    new_entry <- data.frame(
      date = input$mealDate,
      mealType = input$mealType,
      description = input$mealDescription,
      calories = input$calories,
      protein = input$protein,
      carbs = input$carbs,
      fats = input$fats
    )
    nutritionData(rbind(current_data, new_entry))
    showNotification("Meal logged successfully!", type = "message")
  })
  
  observeEvent(input$submitWorkout, {
    current_data <- workoutData()
    new_entry <- data.frame(
      date = input$workoutDate,
      type = input$workoutType,
      duration = input$workoutDuration,
      calories = input$caloriesBurned,
      intensity = input$intensity
    )
    workoutData(rbind(current_data, new_entry))
    showNotification("Workout logged successfully!", type = "message")
  })
  
  observeEvent(input$submitSleep, {
    current_data <- sleepData()
    new_entry <- data.frame(
      date = input$sleepDate,
      hours = input$sleepHours,
      quality = input$sleepQuality
    )
    sleepData(rbind(current_data, new_entry))
    showNotification("Sleep logged successfully!", type = "message")
  })
  
  observeEvent(input$submitMotivation, {
    current_data <- motivationData()
    new_entry <- data.frame(
      date = input$motivationDate,
      motivation = input$motivationLevel,
      energy = input$energyLevel,
      mood = input$moodLevel
    )
    motivationData(rbind(current_data, new_entry))
    showNotification("Check-in saved successfully!", type = "message")
  })
  
  observeEvent(input$submitGoal, {
    showNotification("Goal added successfully!", type = "message")
  })
  
  observeEvent(input$saveWeightGoal, {
    showNotification("Weight goal saved!", type = "message")
  })
  
  observeEvent(input$saveNutritionGoals, {
    showNotification("Nutrition targets saved!", type = "message")
  })
  
  observeEvent(input$saveSleepGoals, {
    showNotification("Sleep goals saved!", type = "message")
  })
  
  observeEvent(input$saveWhy, {
    showNotification("Your 'Why' has been saved!", type = "message")
  })
  
  observeEvent(input$saveVision, {
    showNotification("Vision saved successfully!", type = "message")
  })
  
  observeEvent(input$savePlan, {
    showNotification("Workout plan updated!", type = "message")
  })
  
  observeEvent(input$addMilestone, {
    showNotification("Milestone added!", type = "message")
  })
  
  observeEvent(input$savePhoto, {
    showNotification("Progress photo saved!", type = "message")
  })
  
  # Quick action buttons from dashboard
  observeEvent(input$logWeight, {
    updateTabItems(session, "tabs", "weight")
  })
  
  observeEvent(input$logMeal, {
    updateTabItems(session, "tabs", "nutrition")
  })
  
  observeEvent(input$logWorkout, {
    updateTabItems(session, "tabs", "exercise")
  })
  
  observeEvent(input$logSleep, {
    updateTabItems(session, "tabs", "sleep")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
                          