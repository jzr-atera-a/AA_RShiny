

# Web Traffic Analytics Dashboard
# R Shiny App with Google Analytics Integration

# Load required libraries
library(shiny)
library(shinydashboard)
library(googleAnalyticsR)
library(ggplot2)
library(plotly)
library(dplyr)
library(lubridate)
library(DT)

# ============================================================================
# SETUP INSTRUCTIONS
# ============================================================================
# 1. Install required packages:
#    install.packages(c("shiny", "shinydashboard", "googleAnalyticsR", 
#                       "ggplot2", "plotly", "dplyr", "lubridate", "DT"))
#
# 2. Set up Google Analytics API:
#    - Go to https://console.cloud.google.com/
#    - Create a new project
#    - Enable Google Analytics Data API
#    - Create OAuth 2.0 credentials (Desktop app)
#    - Download the JSON file and save as "ga_auth.json" in the app directory
#
# 3. Authenticate (run once):
#    ga_auth(json_file = "ga_auth.json")
#
# 4. Get your GA4 Property ID:
#    - Go to Google Analytics > Admin > Property Settings
#    - Copy your Property ID (format: 123456789)
# ============================================================================

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(
    title = "Web Traffic Analytics",
    titleWidth = 280
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Traffic Sources", tabName = "sources", icon = icon("chart-line")),
      menuItem("Page Analytics", tabName = "pages", icon = icon("file-alt")),
      menuItem("User Behavior", tabName = "behavior", icon = icon("users")),
      menuItem("Settings", tabName = "settings", icon = icon("cog"))
    ),
    
    # Date range selector
    dateRangeInput("dateRange",
                   "Date Range:",
                   start = Sys.Date() - 30,
                   end = Sys.Date(),
                   max = Sys.Date()),
    
    # Refresh button
    actionButton("refresh", "Refresh Data", 
                 icon = icon("sync"),
                 class = "btn-primary",
                 style = "width: 90%; margin: 10px 5%;")
  ),
  
  # Body
  dashboardBody(
    # Custom CSS
    tags$head(
      tags$style(HTML("
        .small-box { border-radius: 5px; }
        .content-wrapper { background-color: #f4f6f9; }
        .box { border-radius: 5px; box-shadow: 0 1px 3px rgba(0,0,0,0.12); }
      "))
    ),
    
    tabItems(
      # Dashboard Tab
      tabItem(tabName = "dashboard",
              fluidRow(
                valueBoxOutput("totalUsers", width = 3),
                valueBoxOutput("totalSessions", width = 3),
                valueBoxOutput("avgSessionDuration", width = 3),
                valueBoxOutput("bounceRate", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Daily Traffic Trend",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  plotlyOutput("trafficTrend", height = 350)
                ),
                box(
                  title = "Traffic by Device",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  plotlyOutput("deviceChart", height = 350)
                )
              ),
              
              fluidRow(
                box(
                  title = "Top Countries",
                  status = "success",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("countriesChart", height = 300)
                ),
                box(
                  title = "Recent Activity",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  DTOutput("recentActivity")
                )
              )
      ),
      
      # Traffic Sources Tab
      tabItem(tabName = "sources",
              fluidRow(
                box(
                  title = "Traffic by Source",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("sourceChart", height = 400)
                ),
                box(
                  title = "Traffic by Medium",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("mediumChart", height = 400)
                )
              ),
              
              fluidRow(
                box(
                  title = "Source/Medium Details",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("sourceTable")
                )
              )
      ),
      
      # Page Analytics Tab
      tabItem(tabName = "pages",
              fluidRow(
                box(
                  title = "Top Pages by Views",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("topPagesTable")
                )
              ),
              
              fluidRow(
                box(
                  title = "Page Performance",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("pagePerformance", height = 400)
                )
              )
      ),
      
      # User Behavior Tab
      tabItem(tabName = "behavior",
              fluidRow(
                box(
                  title = "Sessions by Hour of Day",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("hourlyChart", height = 350)
                ),
                box(
                  title = "Sessions by Day of Week",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("weekdayChart", height = 350)
                )
              ),
              
              fluidRow(
                box(
                  title = "User Engagement Metrics",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("engagementTable")
                )
              )
      ),
      
      # Settings Tab
      tabItem(tabName = "settings",
              fluidRow(
                box(
                  title = "Google Analytics Configuration",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  textInput("propertyId", "GA4 Property ID:", 
                            placeholder = "Enter your GA4 Property ID"),
                  actionButton("saveSettings", "Save Settings", 
                               class = "btn-success"),
                  hr(),
                  h4("Connection Status:"),
                  verbatimTextOutput("connectionStatus")
                ),
                box(
                  title = "Setup Instructions",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  h4("How to Get Started:"),
                  tags$ol(
                    tags$li("Install Google Analytics on your WordPress site"),
                    tags$li("Set up Google Cloud Console API credentials"),
                    tags$li("Authenticate using ga_auth()"),
                    tags$li("Enter your GA4 Property ID in the field"),
                    tags$li("Click 'Save Settings' and refresh data")
                  ),
                  hr(),
                  actionButton("authenticate", "Authenticate with Google", 
                               class = "btn-primary")
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values to store data
  rv <- reactiveValues(
    ga_data = NULL,
    property_id = NULL,
    authenticated = FALSE
  )
  
  # Load saved property ID on startup
  observe({
    if (file.exists("ga_property_id.rds")) {
      rv$property_id <- readRDS("ga_property_id.rds")
      updateTextInput(session, "propertyId", value = rv$property_id)
    }
  })
  
  # Save property ID
  observeEvent(input$saveSettings, {
    rv$property_id <- input$propertyId
    saveRDS(rv$property_id, "ga_property_id.rds")
    showNotification("Settings saved successfully!", type = "message")
  })
  
  # Authentication button
  observeEvent(input$authenticate, {
    tryCatch({
      ga_auth()
      rv$authenticated <- TRUE
      showNotification("Authentication successful!", type = "message")
    }, error = function(e) {
      showNotification(paste("Authentication failed:", e$message), 
                      type = "error")
    })
  })
  
  # Fetch data function
  fetch_ga_data <- function() {
    req(rv$property_id)
    
    tryCatch({
      # Fetch main metrics
      data <- ga_data(
        propertyId = rv$property_id,
        date_range = c(input$dateRange[1], input$dateRange[2]),
        metrics = c("sessions", "totalUsers", "screenPageViews", 
                   "averageSessionDuration", "bounceRate"),
        dimensions = c("date", "deviceCategory", "country", 
                      "sessionSource", "sessionMedium", "pageTitle"),
        limit = -1
      )
      
      rv$ga_data <- data
      showNotification("Data refreshed successfully!", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error fetching data:", e$message), 
                      type = "error")
      # Return sample data for demonstration
      rv$ga_data <- generate_sample_data(input$dateRange[1], input$dateRange[2])
    })
  }
  
  # Generate sample data for demonstration
  generate_sample_data <- function(start_date, end_date) {
    dates <- seq(start_date, end_date, by = "day")
    
    data.frame(
      date = rep(dates, each = 10),
      sessions = sample(50:500, length(dates) * 10, replace = TRUE),
      totalUsers = sample(40:450, length(dates) * 10, replace = TRUE),
      screenPageViews = sample(100:1000, length(dates) * 10, replace = TRUE),
      averageSessionDuration = sample(60:300, length(dates) * 10, replace = TRUE),
      bounceRate = runif(length(dates) * 10, 0.3, 0.7),
      deviceCategory = sample(c("desktop", "mobile", "tablet"), 
                            length(dates) * 10, replace = TRUE,
                            prob = c(0.5, 0.4, 0.1)),
      country = sample(c("United States", "United Kingdom", "Canada", 
                        "Germany", "France", "Spain", "Italy", "Other"),
                      length(dates) * 10, replace = TRUE),
      sessionSource = sample(c("google", "direct", "facebook", "twitter", 
                              "linkedin", "other"),
                            length(dates) * 10, replace = TRUE),
      sessionMedium = sample(c("organic", "direct", "referral", "social", "cpc"),
                            length(dates) * 10, replace = TRUE),
      pageTitle = sample(c("Home", "About", "Services", "Blog", "Contact",
                          "Products", "Portfolio", "Pricing"),
                        length(dates) * 10, replace = TRUE)
    )
  }
  
  # Refresh data on button click or date change
  observeEvent(input$refresh, {
    fetch_ga_data()
  })
  
  observeEvent(input$dateRange, {
    fetch_ga_data()
  }, ignoreNULL = TRUE, ignoreInit = TRUE)
  
  # Initialize with sample data
  observe({
    if (is.null(rv$ga_data)) {
      rv$ga_data <- generate_sample_data(input$dateRange[1], input$dateRange[2])
    }
  })
  
  # Value Boxes
  output$totalUsers <- renderValueBox({
    req(rv$ga_data)
    total <- sum(rv$ga_data$totalUsers, na.rm = TRUE)
    valueBox(
      format(total, big.mark = ","),
      "Total Users",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$totalSessions <- renderValueBox({
    req(rv$ga_data)
    total <- sum(rv$ga_data$sessions, na.rm = TRUE)
    valueBox(
      format(total, big.mark = ","),
      "Total Sessions",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  output$avgSessionDuration <- renderValueBox({
    req(rv$ga_data)
    avg <- mean(rv$ga_data$averageSessionDuration, na.rm = TRUE)
    minutes <- floor(avg / 60)
    seconds <- round(avg %% 60)
    valueBox(
      paste0(minutes, "m ", seconds, "s"),
      "Avg. Session Duration",
      icon = icon("clock"),
      color = "purple"
    )
  })
  
  output$bounceRate <- renderValueBox({
    req(rv$ga_data)
    avg_bounce <- mean(rv$ga_data$bounceRate, na.rm = TRUE) * 100
    valueBox(
      paste0(round(avg_bounce, 1), "%"),
      "Bounce Rate",
      icon = icon("sign-out-alt"),
      color = "yellow"
    )
  })
  
  # Traffic Trend Chart
  output$trafficTrend <- renderPlotly({
    req(rv$ga_data)
    
    daily_data <- rv$ga_data %>%
      group_by(date) %>%
      summarise(
        users = sum(totalUsers, na.rm = TRUE),
        sessions = sum(sessions, na.rm = TRUE),
        pageviews = sum(screenPageViews, na.rm = TRUE)
      )
    
    plot_ly(daily_data, x = ~date) %>%
      add_trace(y = ~users, name = "Users", type = "scatter", 
                mode = "lines+markers", line = list(color = "#3c8dbc")) %>%
      add_trace(y = ~sessions, name = "Sessions", type = "scatter",
                mode = "lines+markers", line = list(color = "#00a65a")) %>%
      add_trace(y = ~pageviews, name = "Page Views", type = "scatter",
                mode = "lines+markers", line = list(color = "#f39c12")) %>%
      layout(
        xaxis = list(title = "Date"),
        yaxis = list(title = "Count"),
        hovermode = "x unified",
        legend = list(x = 0.1, y = 1)
      )
  })
  
  # Device Chart
  output$deviceChart <- renderPlotly({
    req(rv$ga_data)
    
    device_data <- rv$ga_data %>%
      group_by(deviceCategory) %>%
      summarise(sessions = sum(sessions, na.rm = TRUE)) %>%
      arrange(desc(sessions))
    
    plot_ly(device_data, labels = ~deviceCategory, values = ~sessions,
            type = "pie",
            marker = list(colors = c("#3c8dbc", "#00a65a", "#f39c12"))) %>%
      layout(showlegend = TRUE)
  })
  
  # Countries Chart
  output$countriesChart <- renderPlotly({
    req(rv$ga_data)
    
    country_data <- rv$ga_data %>%
      group_by(country) %>%
      summarise(users = sum(totalUsers, na.rm = TRUE)) %>%
      arrange(desc(users)) %>%
      head(10)
    
    plot_ly(country_data, x = ~users, y = ~reorder(country, users),
            type = "bar", orientation = "h",
            marker = list(color = "#3c8dbc")) %>%
      layout(
        xaxis = list(title = "Users"),
        yaxis = list(title = ""),
        margin = list(l = 100)
      )
  })
  
  # Recent Activity Table
  output$recentActivity <- renderDT({
    req(rv$ga_data)
    
    recent <- rv$ga_data %>%
      arrange(desc(date)) %>%
      select(date, pageTitle, sessions, totalUsers) %>%
      head(10)
    
    datatable(recent, 
              options = list(pageLength = 5, dom = 't'),
              rownames = FALSE,
              colnames = c("Date", "Page", "Sessions", "Users"))
  })
  
  # Source Chart
  output$sourceChart <- renderPlotly({
    req(rv$ga_data)
    
    source_data <- rv$ga_data %>%
      group_by(sessionSource) %>%
      summarise(sessions = sum(sessions, na.rm = TRUE)) %>%
      arrange(desc(sessions))
    
    plot_ly(source_data, labels = ~sessionSource, values = ~sessions,
            type = "pie") %>%
      layout(title = "")
  })
  
  # Medium Chart
  output$mediumChart <- renderPlotly({
    req(rv$ga_data)
    
    medium_data <- rv$ga_data %>%
      group_by(sessionMedium) %>%
      summarise(sessions = sum(sessions, na.rm = TRUE)) %>%
      arrange(desc(sessions))
    
    plot_ly(medium_data, x = ~sessions, y = ~reorder(sessionMedium, sessions),
            type = "bar", orientation = "h",
            marker = list(color = "#00a65a")) %>%
      layout(
        xaxis = list(title = "Sessions"),
        yaxis = list(title = "")
      )
  })
  
  # Source Table
  output$sourceTable <- renderDT({
    req(rv$ga_data)
    
    source_table <- rv$ga_data %>%
      group_by(sessionSource, sessionMedium) %>%
      summarise(
        sessions = sum(sessions, na.rm = TRUE),
        users = sum(totalUsers, na.rm = TRUE),
        pageviews = sum(screenPageViews, na.rm = TRUE),
        avg_duration = mean(averageSessionDuration, na.rm = TRUE),
        bounce_rate = mean(bounceRate, na.rm = TRUE) * 100,
        .groups = "drop"
      ) %>%
      arrange(desc(sessions))
    
    datatable(source_table,
              options = list(pageLength = 10),
              rownames = FALSE,
              colnames = c("Source", "Medium", "Sessions", "Users", 
                          "Page Views", "Avg Duration (s)", "Bounce Rate (%)")) %>%
      formatRound(columns = c("avg_duration", "bounce_rate"), digits = 2)
  })
  
  # Top Pages Table
  output$topPagesTable <- renderDT({
    req(rv$ga_data)
    
    page_data <- rv$ga_data %>%
      group_by(pageTitle) %>%
      summarise(
        pageviews = sum(screenPageViews, na.rm = TRUE),
        users = sum(totalUsers, na.rm = TRUE),
        avg_duration = mean(averageSessionDuration, na.rm = TRUE),
        bounce_rate = mean(bounceRate, na.rm = TRUE) * 100,
        .groups = "drop"
      ) %>%
      arrange(desc(pageviews)) %>%
      head(20)
    
    datatable(page_data,
              options = list(pageLength = 10),
              rownames = FALSE,
              colnames = c("Page Title", "Page Views", "Users", 
                          "Avg Duration (s)", "Bounce Rate (%)")) %>%
      formatRound(columns = c("avg_duration", "bounce_rate"), digits = 2)
  })
  
  # Page Performance Chart
  output$pagePerformance <- renderPlotly({
    req(rv$ga_data)
    
    page_perf <- rv$ga_data %>%
      group_by(pageTitle) %>%
      summarise(
        pageviews = sum(screenPageViews, na.rm = TRUE),
        avg_duration = mean(averageSessionDuration, na.rm = TRUE)
      ) %>%
      arrange(desc(pageviews)) %>%
      head(10)
    
    plot_ly(page_perf, x = ~pageviews, y = ~reorder(pageTitle, pageviews),
            type = "bar", orientation = "h",
            marker = list(color = "#3c8dbc")) %>%
      layout(
        xaxis = list(title = "Page Views"),
        yaxis = list(title = ""),
        margin = list(l = 150)
      )
  })
  
  # Hourly Chart (simulated)
  output$hourlyChart <- renderPlotly({
    req(rv$ga_data)
    
    # This would require hour dimension from GA
    # Simulating for demonstration
    hourly_data <- data.frame(
      hour = 0:23,
      sessions = sample(100:1000, 24)
    )
    
    plot_ly(hourly_data, x = ~hour, y = ~sessions,
            type = "bar",
            marker = list(color = "#3c8dbc")) %>%
      layout(
        xaxis = list(title = "Hour of Day"),
        yaxis = list(title = "Sessions")
      )
  })
  
  # Weekday Chart (simulated)
  output$weekdayChart <- renderPlotly({
    req(rv$ga_data)
    
    weekday_data <- rv$ga_data %>%
      mutate(weekday = wday(date, label = TRUE)) %>%
      group_by(weekday) %>%
      summarise(sessions = sum(sessions, na.rm = TRUE))
    
    plot_ly(weekday_data, x = ~weekday, y = ~sessions,
            type = "bar",
            marker = list(color = "#00a65a")) %>%
      layout(
        xaxis = list(title = "Day of Week"),
        yaxis = list(title = "Sessions")
      )
  })
  
  # Engagement Table
  output$engagementTable <- renderDT({
    req(rv$ga_data)
    
    engagement <- rv$ga_data %>%
      group_by(date) %>%
      summarise(
        sessions = sum(sessions, na.rm = TRUE),
        users = sum(totalUsers, na.rm = TRUE),
        pageviews = sum(screenPageViews, na.rm = TRUE),
        pages_per_session = pageviews / sessions,
        avg_duration = mean(averageSessionDuration, na.rm = TRUE),
        bounce_rate = mean(bounceRate, na.rm = TRUE) * 100,
        .groups = "drop"
      ) %>%
      arrange(desc(date)) %>%
      head(15)
    
    datatable(engagement,
              options = list(pageLength = 10),
              rownames = FALSE,
              colnames = c("Date", "Sessions", "Users", "Page Views",
                          "Pages/Session", "Avg Duration (s)", "Bounce Rate (%)")) %>%
      formatRound(columns = c("pages_per_session", "avg_duration", "bounce_rate"), 
                  digits = 2)
  })
  
  # Connection Status
  output$connectionStatus <- renderText({
    if (rv$authenticated) {
      "✓ Connected to Google Analytics"
    } else if (!is.null(rv$property_id) && rv$property_id != "") {
      "⚠ Property ID set, but not authenticated"
    } else {
      "✗ Not configured"
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)
