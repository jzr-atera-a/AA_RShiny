library(shiny)
library(shinydashboard)
library(httr)
library(jsonlite)
library(lubridate)
library(dplyr)
library(plotly)
library(DT)

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "Daily Planning Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Plan Your Day", tabName = "planner", icon = icon("calendar-check")),
      menuItem("Weather Forecast", tabName = "weather", icon = icon("cloud-sun")),
      menuItem("Sleep Analysis", tabName = "sleep", icon = icon("bed"))
    ),
    
    hr(),
    
    # Location inputs
    textInput("city", "City:", value = "London"),
    selectInput("country", "Country Code:", 
                choices = c("US", "GB", "CA", "AU", "DE", "FR", "ES", "IT", "JP", "CN", "IN", "BR"),
                selected = "GB"),
    
    hr(),
    
    # Sleep schedule inputs
    textInput("bedtime", "Bedtime (HH:MM):", value = "22:00", 
              placeholder = "e.g., 22:00"),
    textInput("waketime", "Wake Time (HH:MM):", value = "05:00",
              placeholder = "e.g., 05:00"),
    
    hr(),
    
    actionButton("generate_plan", "Generate Daily Plan", 
                 class = "btn-primary btn-block", icon = icon("magic"))
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .box { border-radius: 8px; }
        .small-box { border-radius: 8px; }
        .content-wrapper { background-color: #f4f6f9; }
        .time-block { 
          padding: 10px; 
          margin: 5px 0; 
          background: white; 
          border-left: 4px solid #3c8dbc;
          border-radius: 4px;
        }
        .goal-item {
          padding: 8px;
          margin: 5px 0;
          background: #f8f9fa;
          border-radius: 4px;
        }
      "))
    ),
    
    tabItems(
      # Planning Tab
      tabItem(tabName = "planner",
              fluidRow(
                valueBoxOutput("sleep_hours", width = 3),
                valueBoxOutput("productive_hours", width = 3),
                valueBoxOutput("sunrise_box", width = 3),
                valueBoxOutput("sunset_box", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Today's Weather Summary",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  uiOutput("today_weather")
                ),
                
                box(
                  title = "Tomorrow's Weather Summary",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  uiOutput("tomorrow_weather")
                )
              ),
              
              fluidRow(
                box(
                  title = "Your Optimized Daily Schedule",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  uiOutput("daily_schedule")
                )
              ),
              
              fluidRow(
                box(
                  title = "Daily Goals & Priorities",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  uiOutput("daily_goals")
                ),
                
                box(
                  title = "Evening Routine for Better Sleep",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  uiOutput("evening_routine")
                )
              )
      ),
      
      # Weather Tab
      tabItem(tabName = "weather",
              fluidRow(
                box(
                  title = "7-Day Weather Forecast",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("weather_plot", height = "400px")
                )
              ),
              
              fluidRow(
                box(
                  title = "Detailed Forecast Table",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("weather_table")
                )
              )
      ),
      
      # Sleep Analysis Tab
      tabItem(tabName = "sleep",
              fluidRow(
                box(
                  title = "Sleep Schedule Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("sleep_chart")
                ),
                
                box(
                  title = "Sleep Quality Insights",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  uiOutput("sleep_insights")
                )
              ),
              
              fluidRow(
                box(
                  title = "The 5 AM Club Principles",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  uiOutput("five_am_club")
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values
  weather_data <- reactiveVal(NULL)
  
  # Helper function to validate and parse time input
  parse_time <- function(time_str) {
    # Remove spaces and validate format
    time_str <- gsub(" ", "", time_str)
    
    # Check if it matches HH:MM format
    if(!grepl("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", time_str)) {
      return(NULL)
    }
    
    return(time_str)
  }
  
  # Validate time inputs
  observe({
    req(input$bedtime)
    if(is.null(parse_time(input$bedtime))) {
      showNotification("Bedtime must be in HH:MM format (e.g., 22:00)", type = "warning")
    }
  })
  
  observe({
    req(input$waketime)
    if(is.null(parse_time(input$waketime))) {
      showNotification("Wake time must be in HH:MM format (e.g., 05:00)", type = "warning")
    }
  })
  
  # Fetch weather data
  observeEvent(input$generate_plan, {
    req(input$city, input$country)
    
    tryCatch({
      # Using Open-Meteo API (free, no API key required)
      # First get coordinates for the city
      geo_url <- sprintf("https://geocoding-api.open-meteo.com/v1/search?name=%s&count=1&language=en&format=json",
                         URLencode(input$city))
      
      geo_response <- GET(geo_url)
      geo_data <- fromJSON(content(geo_response, "text", encoding = "UTF-8"))
      
      if(!is.null(geo_data$results) && nrow(geo_data$results) > 0) {
        lat <- geo_data$results$latitude[1]
        lon <- geo_data$results$longitude[1]
        
        # Get weather forecast
        weather_url <- sprintf(
          "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode,sunrise,sunset&timezone=auto&forecast_days=7",
          lat, lon
        )
        
        weather_response <- GET(weather_url)
        weather <- fromJSON(content(weather_response, "text", encoding = "UTF-8"))
        
        weather_df <- data.frame(
          date = as.Date(weather$daily$time),
          temp_max = weather$daily$temperature_2m_max,
          temp_min = weather$daily$temperature_2m_min,
          precipitation = weather$daily$precipitation_sum,
          weathercode = weather$daily$weathercode,
          sunrise = weather$daily$sunrise,
          sunset = weather$daily$sunset
        )
        
        weather_data(weather_df)
      } else {
        showNotification("City not found. Please try another city.", type = "error")
      }
      
    }, error = function(e) {
      showNotification(paste("Error fetching weather:", e$message), type = "error")
    })
  })
  
  # Helper function to interpret weather codes
  get_weather_description <- function(code) {
    descriptions <- c(
      "0" = "Clear sky",
      "1" = "Mainly clear",
      "2" = "Partly cloudy",
      "3" = "Overcast",
      "45" = "Foggy",
      "48" = "Foggy",
      "51" = "Light drizzle",
      "53" = "Moderate drizzle",
      "55" = "Dense drizzle",
      "61" = "Slight rain",
      "63" = "Moderate rain",
      "65" = "Heavy rain",
      "71" = "Slight snow",
      "73" = "Moderate snow",
      "75" = "Heavy snow",
      "80" = "Rain showers",
      "81" = "Rain showers",
      "82" = "Heavy rain showers",
      "95" = "Thunderstorm",
      "96" = "Thunderstorm with hail",
      "99" = "Thunderstorm with hail"
    )
    
    desc <- descriptions[as.character(code)]
    if(is.na(desc)) return("Unknown")
    return(desc)
  }
  
  # Calculate sleep hours
  sleep_hours_calc <- reactive({
    req(input$bedtime, input$waketime)
    
    # Validate time formats
    bedtime_str <- parse_time(input$bedtime)
    waketime_str <- parse_time(input$waketime)
    
    if(is.null(bedtime_str) || is.null(waketime_str)) {
      return(8)  # Default to 8 hours if invalid format
    }
    
    bedtime <- as.POSIXct(paste(Sys.Date(), bedtime_str), format = "%Y-%m-%d %H:%M")
    waketime <- as.POSIXct(paste(Sys.Date() + 1, waketime_str), format = "%Y-%m-%d %H:%M")
    
    hours <- as.numeric(difftime(waketime, bedtime, units = "hours"))
    if(hours < 0) hours <- hours + 24
    
    return(hours)
  })
  
  # Value boxes
  output$sleep_hours <- renderValueBox({
    hours <- sleep_hours_calc()
    color <- if(hours >= 7 && hours <= 9) "green" else if(hours >= 6) "yellow" else "red"
    
    valueBox(
      sprintf("%.1f hrs", hours),
      "Sleep Duration",
      icon = icon("bed"),
      color = color
    )
  })
  
  output$productive_hours <- renderValueBox({
    hours <- sleep_hours_calc()
    productive <- 24 - hours - 3  # Minus sleep and personal time
    
    valueBox(
      sprintf("%.0f hrs", productive),
      "Productive Hours",
      icon = icon("clock"),
      color = "blue"
    )
  })
  
  output$sunrise_box <- renderValueBox({
    wd <- weather_data()
    if(is.null(wd)) {
      sunrise_time <- "N/A"
    } else {
      sunrise <- as.POSIXct(wd$sunrise[1])
      sunrise_time <- format(sunrise, "%H:%M")
    }
    
    valueBox(
      sunrise_time,
      "Sunrise Today",
      icon = icon("sun"),
      color = "orange"
    )
  })
  
  output$sunset_box <- renderValueBox({
    wd <- weather_data()
    if(is.null(wd)) {
      sunset_time <- "N/A"
    } else {
      sunset <- as.POSIXct(wd$sunset[1])
      sunset_time <- format(sunset, "%H:%M")
    }
    
    valueBox(
      sunset_time,
      "Sunset Today",
      icon = icon("moon"),
      color = "purple"
    )
  })
  
  # Today's weather
  output$today_weather <- renderUI({
    wd <- weather_data()
    if(is.null(wd)) {
      return(p("Click 'Generate Daily Plan' to load weather data."))
    }
    
    today <- wd[1, ]
    
    tagList(
      h4(icon("calendar"), format(today$date, "%A, %B %d")),
      hr(),
      div(
        style = "font-size: 16px;",
        p(icon("temperature-high"), strong(" High:"), sprintf(" %.1f°C", today$temp_max)),
        p(icon("temperature-low"), strong(" Low:"), sprintf(" %.1f°C", today$temp_min)),
        p(icon("cloud"), strong(" Conditions:"), get_weather_description(today$weathercode)),
        p(icon("tint"), strong(" Precipitation:"), sprintf(" %.1f mm", today$precipitation))
      )
    )
  })
  
  # Tomorrow's weather
  output$tomorrow_weather <- renderUI({
    wd <- weather_data()
    if(is.null(wd) || nrow(wd) < 2) {
      return(p("Weather data not available."))
    }
    
    tomorrow <- wd[2, ]
    
    tagList(
      h4(icon("calendar-plus"), format(tomorrow$date, "%A, %B %d")),
      hr(),
      div(
        style = "font-size: 16px;",
        p(icon("temperature-high"), strong(" High:"), sprintf(" %.1f°C", tomorrow$temp_max)),
        p(icon("temperature-low"), strong(" Low:"), sprintf(" %.1f°C", tomorrow$temp_min)),
        p(icon("cloud"), strong(" Conditions:"), get_weather_description(tomorrow$weathercode)),
        p(icon("tint"), strong(" Precipitation:"), sprintf(" %.1f mm", tomorrow$precipitation))
      )
    )
  })
  
  # Daily schedule
  output$daily_schedule <- renderUI({
    req(input$waketime, input$bedtime)
    
    waketime_str <- parse_time(input$waketime)
    bedtime_str <- parse_time(input$bedtime)
    
    if(is.null(waketime_str) || is.null(bedtime_str)) {
      return(div(class = "alert alert-warning",
                 icon("exclamation-triangle"), 
                 " Please enter valid times in HH:MM format (e.g., 22:00 for bedtime, 05:00 for wake time)"))
    }
    
    wake_time <- as.POSIXct(paste(Sys.Date(), waketime_str), format = "%Y-%m-%d %H:%M")
    
    schedule <- list(
      list(time = format(wake_time, "%H:%M"), 
           activity = "Wake Up & Victory Hour", 
           desc = "20 min exercise, 20 min learning, 20 min planning"),
      list(time = format(wake_time + 3600, "%H:%M"), 
           activity = "Healthy Breakfast", 
           desc = "Fuel your body with nutritious food"),
      list(time = format(wake_time + 7200, "%H:%M"), 
           activity = "Deep Work Session 1", 
           desc = "Focus on your most important task"),
      list(time = format(wake_time + 16200, "%H:%M"), 
           activity = "Mid-Morning Break", 
           desc = "Stretch, hydrate, short walk"),
      list(time = format(wake_time + 18000, "%H:%M"), 
           activity = "Deep Work Session 2", 
           desc = "Continue focused work"),
      list(time = format(wake_time + 25200, "%H:%M"), 
           activity = "Lunch Break", 
           desc = "Healthy meal and rest"),
      list(time = format(wake_time + 28800, "%H:%M"), 
           activity = "Afternoon Tasks", 
           desc = "Meetings, emails, collaborative work"),
      list(time = format(wake_time + 39600, "%H:%M"), 
           activity = "Exercise & Refresh", 
           desc = "Physical activity or outdoor time"),
      list(time = format(wake_time + 45000, "%H:%M"), 
           activity = "Dinner & Family Time", 
           desc = "Connect with loved ones"),
      list(time = format(wake_time + 50400, "%H:%M"), 
           activity = "Evening Wind Down", 
           desc = "Light reading, reflection, journaling"),
      list(time = bedtime_str, 
           activity = "Bedtime", 
           desc = "Aim for 7-9 hours of quality sleep")
    )
    
    schedule_html <- lapply(schedule, function(s) {
      div(class = "time-block",
          h4(style = "margin-top: 0;", icon("clock"), s$time, " - ", s$activity),
          p(style = "margin-bottom: 0;", s$desc)
      )
    })
    
    tagList(schedule_html)
  })
  
  # Daily goals
  output$daily_goals <- renderUI({
    goals <- c(
      "Complete your #1 priority task during morning deep work",
      "Exercise for at least 30 minutes",
      "Drink 8 glasses of water throughout the day",
      "Take regular breaks every 90 minutes",
      "Practice gratitude - list 3 things you're thankful for",
      "Limit screen time 1 hour before bed",
      "Prepare tomorrow's outfit and essentials tonight",
      "Review and celebrate today's wins"
    )
    
    goal_html <- lapply(goals, function(g) {
      div(class = "goal-item",
          icon("check-circle"), " ", g
      )
    })
    
    tagList(goal_html)
  })
  
  # Evening routine
  output$evening_routine <- renderUI({
    routine <- c(
      "2 hours before bed: Dim lights and reduce blue light exposure",
      "1.5 hours before bed: Light stretching or yoga",
      "1 hour before bed: No screens - read or listen to calm music",
      "45 min before bed: Prepare for tomorrow (clothes, bag, to-do list)",
      "30 min before bed: Personal hygiene routine",
      "15 min before bed: Meditation or breathing exercises",
      "Bedtime: Keep room cool (60-67°F), dark, and quiet"
    )
    
    routine_html <- lapply(routine, function(r) {
      div(class = "goal-item",
          icon("moon"), " ", r
      )
    })
    
    tagList(routine_html)
  })
  
  # Weather plot
  output$weather_plot <- renderPlotly({
    wd <- weather_data()
    if(is.null(wd)) {
      return(plotly_empty())
    }
    
    plot_ly(wd) %>%
      add_trace(x = ~date, y = ~temp_max, type = 'scatter', mode = 'lines+markers',
                name = 'Max Temp', line = list(color = 'rgb(255, 100, 100)'),
                marker = list(size = 8)) %>%
      add_trace(x = ~date, y = ~temp_min, type = 'scatter', mode = 'lines+markers',
                name = 'Min Temp', line = list(color = 'rgb(100, 150, 255)'),
                marker = list(size = 8)) %>%
      layout(title = sprintf("7-Day Temperature Forecast - %s, %s", input$city, input$country),
             xaxis = list(title = "Date"),
             yaxis = list(title = "Temperature (°C)"),
             hovermode = "x unified",
             plot_bgcolor = 'rgb(240, 240, 240)',
             paper_bgcolor = 'rgb(250, 250, 250)')
  })
  
  # Weather table
  output$weather_table <- renderDT({
    wd <- weather_data()
    if(is.null(wd)) {
      return(data.frame())
    }
    
    wd_display <- wd %>%
      mutate(
        Date = format(date, "%a, %b %d"),
        `High (°C)` = sprintf("%.1f", temp_max),
        `Low (°C)` = sprintf("%.1f", temp_min),
        Conditions = sapply(weathercode, get_weather_description),
        `Rain (mm)` = sprintf("%.1f", precipitation),
        Sunrise = format(as.POSIXct(sunrise), "%H:%M"),
        Sunset = format(as.POSIXct(sunset), "%H:%M")
      ) %>%
      select(Date, `High (°C)`, `Low (°C)`, Conditions, `Rain (mm)`, Sunrise, Sunset)
    
    datatable(wd_display, 
              options = list(pageLength = 7, dom = 't'),
              rownames = FALSE)
  })
  
  # Sleep chart
  output$sleep_chart <- renderPlotly({
    hours <- sleep_hours_calc()
    
    optimal_min <- 7
    optimal_max <- 9
    
    colors <- c(
      if(hours < optimal_min) 'rgb(255, 100, 100)' else if(hours > optimal_max) 'rgb(255, 200, 100)' else 'rgb(100, 200, 100)'
    )
    
    plot_ly() %>%
      add_trace(
        type = "indicator",
        mode = "gauge+number+delta",
        value = hours,
        title = list(text = "Sleep Hours", font = list(size = 24)),
        delta = list(reference = 8, increasing = list(color = "green")),
        gauge = list(
          axis = list(range = list(0, 12), tickwidth = 1, tickcolor = "darkblue"),
          bar = list(color = colors),
          bgcolor = "white",
          borderwidth = 2,
          bordercolor = "gray",
          steps = list(
            list(range = c(0, 6), color = "rgba(255, 100, 100, 0.3)"),
            list(range = c(6, 7), color = "rgba(255, 200, 100, 0.3)"),
            list(range = c(7, 9), color = "rgba(100, 200, 100, 0.3)"),
            list(range = c(9, 12), color = "rgba(255, 200, 100, 0.3)")
          ),
          threshold = list(
            line = list(color = "red", width = 4),
            thickness = 0.75,
            value = 8
          )
        )
      ) %>%
      layout(
        margin = list(l = 20, r = 20, t = 60, b = 20),
        paper_bgcolor = "white",
        font = list(color = "darkblue", family = "Arial")
      )
  })
  
  # Sleep insights
  output$sleep_insights <- renderUI({
    hours <- sleep_hours_calc()
    
    assessment <- if(hours >= 7 && hours <= 9) {
      list(
        color = "success",
        icon = "check-circle",
        title = "Excellent Sleep Duration!",
        message = "You're getting optimal sleep for recovery and performance."
      )
    } else if(hours >= 6 && hours < 7) {
      list(
        color = "warning",
        icon = "exclamation-triangle",
        title = "Slightly Below Optimal",
        message = "Consider going to bed 30-60 minutes earlier for better recovery."
      )
    } else if(hours > 9) {
      list(
        color = "info",
        icon = "info-circle",
        title = "Extended Sleep Duration",
        message = "While sleep is important, very long sleep may indicate other health factors."
      )
    } else {
      list(
        color = "danger",
        icon = "times-circle",
        title = "Insufficient Sleep",
        message = "You're not getting enough sleep. Prioritize an earlier bedtime."
      )
    }
    
    tagList(
      div(class = paste0("alert alert-", assessment$color),
          h4(icon(assessment$icon), " ", assessment$title),
          p(assessment$message)
      ),
      hr(),
      h4("Sleep Benefits:"),
      tags$ul(
        tags$li("Enhanced cognitive function and creativity"),
        tags$li("Improved immune system function"),
        tags$li("Better emotional regulation"),
        tags$li("Increased physical performance"),
        tags$li("Better memory consolidation")
      ),
      hr(),
      h4("Sleep Quality Tips:"),
      tags$ul(
        tags$li("Keep consistent sleep and wake times"),
        tags$li("Create a dark, cool sleeping environment"),
        tags$li("Avoid caffeine 6+ hours before bed"),
        tags$li("Exercise regularly, but not close to bedtime"),
        tags$li("Manage stress through meditation or journaling")
      )
    )
  })
  
  # 5 AM Club principles
  output$five_am_club <- renderUI({
    tagList(
      p("The 5 AM Club, popularized by Robin Sharma, advocates for waking up at 5 AM to own your morning and elevate your life. While you can customize your schedule, the core principles remain valuable:"),
      
      h4(icon("trophy"), " The Victory Hour (First Hour After Waking)"),
      p("Divide your first hour into three 20-minute segments:"),
      div(class = "goal-item",
          strong("20/20/20 Formula:"),
          tags$ul(
            tags$li(strong("Move (0-20 min):"), " Intense exercise to activate your metabolism and release BDNF"),
            tags$li(strong("Reflect (20-40 min):"), " Meditation, journaling, or planning to reduce cortisol and gain clarity"),
            tags$li(strong("Grow (40-60 min):"), " Reading, learning, or skill development while your mind is fresh")
          )
      ),
      
      hr(),
      
      h4(icon("brain"), " The Four Focuses of History Makers"),
      div(class = "goal-item",
          tags$ol(
            tags$li(strong("Capitalization IQ:"), " Focus your gifts on opportunities with exponential results"),
            tags$li(strong("Freedom from Distraction:"), " Protect your attention from digital interruptions"),
            tags$li(strong("Personal Mastery Practice:"), " Daily improvement across mind, body, emotion, and soul"),
            tags$li(strong("Day Stacking:"), " Each great day compounds into an exceptional life")
          )
      ),
      
      hr(),
      
      h4(icon("clock"), " The Twin Cycles of Elite Performance"),
      div(class = "goal-item",
          tags$ul(
            tags$li(strong("High Excellence Cycle (90 min):"), " Deep focus on your most valuable work"),
            tags$li(strong("Deep Recovery Cycle (15-20 min):"), " Rest, refuel, and recharge between sessions")
          )
      ),
      
      hr(),
      
      p(em("Remember: The actual time matters less than the consistency of your routine and the quality of your morning ritual. Customize this to fit your life while maintaining the principle of starting your day with intention and excellence."))
    )
  })
  
}

# Run the app
shinyApp(ui = ui, server = server)