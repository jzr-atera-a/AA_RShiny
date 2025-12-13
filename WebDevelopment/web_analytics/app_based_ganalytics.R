# ============================================================================
# ATERA ANALYTICS DASHBOARD - GA4 INTEGRATED VERSION
# ============================================================================
# Property ID: 515710306
# Website: www.atera-analytics.co.uk
# Format for API: Just numeric ID (googleAnalyticsR adds "properties/" prefix)
# ============================================================================

# Load required packages
library(shiny)
library(shinydashboard)
library(googleAuthR)
library(googleAnalyticsR)
library(plotly)
library(DT)
library(dplyr)
library(tidyr)
library(lubridate)
library(scales)

# ============================================================================
# UI DEFINITION
# ============================================================================

ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "Atera Analytics Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Settings & Connection", tabName = "settings", icon = icon("cog")),
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Traffic Sources", tabName = "traffic", icon = icon("share-alt")),
      menuItem("Geographic Analysis", tabName = "geography", icon = icon("globe")),
      menuItem("Technology & Devices", tabName = "technology", icon = icon("mobile-alt")),
      menuItem("Page Performance", tabName = "pages", icon = icon("file-alt")),
      menuItem("User Behavior", tabName = "behavior", icon = icon("users")),
      menuItem("Events Tracking", tabName = "events", icon = icon("bolt"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Color Palette */
        :root {
          --deep-blue: #0a1128;
          --dark-blue: #1e3c72;
          --medium-blue: #2a5298;
          --bright-blue: #4a90e2;
          --light-blue: #7ec8e3;
          --purple-dark: #3d1f4f;
          --purple-medium: #5e2e6c;
          --purple-light: #764ba2;
        }
        
        .skin-blue .main-header .navbar {
          background: linear-gradient(90deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%) !important;
          border-bottom: 3px solid #7ec8e3;
        }
        
        .skin-blue .main-header .logo {
          background: linear-gradient(135deg, #0a1128 0%, #1e3c72 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
          border-right: 2px solid #4a90e2;
        }
        
        .skin-blue .main-sidebar {
          background: linear-gradient(180deg, #0a1128 0%, #1e3c72 50%, #2a5298 100%) !important;
          box-shadow: 4px 0 15px rgba(10, 17, 40, 0.5);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          font-weight: bold;
          border-left: 4px solid #7ec8e3;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a {
          color: #e0e7ff !important;
          transition: all 0.3s ease;
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          color: #ffffff !important;
          border-left: 4px solid #7ec8e3;
          transform: translateX(5px);
        }
        
        .content-wrapper {
          background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important;
        }
        
        .box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(74, 144, 226, 0.3) !important;
          transition: all 0.3s ease;
        }
        
        .box:hover {
          box-shadow: 0 12px 35px rgba(74, 144, 226, 0.5) !important;
          transform: translateY(-2px);
        }
        
        .box.box-primary .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #4a90e2 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-info .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-success .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-warning .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box-body {
          background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important;
          color: #e0e7ff !important;
          padding: 20px !important;
          border-radius: 0 0 10px 10px;
        }
        
        p { 
          color: #c7d2fe !important; 
          line-height: 1.7 !important; 
        }
        
        strong { 
          color: #7ec8e3 !important; 
          font-weight: 600;
        }
        
        h3, h4, h5, h6 {
          color: #ffffff !important;
        }
        
        .form-control {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 8px;
        }
        
        .btn {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border: none !important;
          border-radius: 8px;
          padding: 10px 20px;
          font-weight: bold;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .btn:hover {
          background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(118, 75, 162, 0.4);
        }
        
        .btn-success {
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
        }
        
        .btn-warning {
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
        }
        
        .btn-danger {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
        }
        
        .info-box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2;
          border-radius: 8px;
          box-shadow: 0 4px 15px rgba(74, 144, 226, 0.3);
        }
        
        .info-box-icon {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        }
        
        .info-box-text {
          color: #e0e7ff !important;
        }
        
        .info-box-number {
          color: #7ec8e3 !important;
          font-weight: bold;
        }
        
        table.dataTable {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        
        table.dataTable thead th {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border-bottom: 2px solid #4a90e2 !important;
        }
        
        table.dataTable tbody tr {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        
        table.dataTable tbody tr:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
        
        .alert-success {
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
          border-color: #7ec8e3 !important;
          color: #ffffff !important;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
        
        .alert-danger {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
          border-color: #e74c3c !important;
          color: #ffffff !important;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
        
        .alert-info {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-color: #7ec8e3 !important;
          color: #ffffff !important;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
        
        label {
          color: #e0e7ff !important;
          font-weight: 500;
        }
        
        .schema-info {
          background: rgba(102, 126, 234, 0.2);
          border-left: 4px solid #667eea;
          padding: 15px;
          margin: 10px 0;
          border-radius: 0 8px 8px 0;
        }
        
        .connection-status-box {
          background: rgba(42, 82, 152, 0.3);
          border: 2px solid #4a90e2;
          border-radius: 10px;
          padding: 20px;
          margin: 15px 0;
        }
        
        .status-indicator {
          display: inline-block;
          width: 12px;
          height: 12px;
          border-radius: 50%;
          margin-right: 8px;
        }
        
        .status-connected {
          background: #2ecc71;
          box-shadow: 0 0 10px #2ecc71;
        }
        
        .status-disconnected {
          background: #e74c3c;
          box-shadow: 0 0 10px #e74c3c;
        }
        
        .credentials-loaded {
          background: rgba(46, 204, 113, 0.2);
          border: 2px solid #2ecc71;
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
        }
      "))
    ),
    
    tabItems(
      # Settings Tab
      tabItem(tabName = "settings",
              fluidRow(
                box(
                  title = "Website Connection Configuration",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "schema-info",
                      h4("Atera Analytics - WordPress Google Analytics Integration"),
                      p(strong("Website URL:"), "www.atera-analytics.co.uk"),
                      p(strong("Account ID:"), "377162613"),
                      p(strong("Property ID:"), "515710306"),
                      p(strong("Measurement ID:"), "G-VB81B86GEM"),
                      p(strong("Google Tag ID:"), "GT-M6QPKL9V"),
                      p(strong("Note:"), "Property ID is used for API calls. Measurement ID is embedded in your website tracking code.")
                  ),
                  hr(),
                  textInput("website_url", "Website URL:", 
                            value = "https://www.atera-analytics.co.uk"),
                  textInput("ga_property_id", "Google Analytics Property ID (GA4):", 
                            value = "515710306"),
                  helpText("Enter just the numeric Property ID (used for API calls)"),
                  textInput("ga_measurement_id", "Measurement ID (optional, for reference):", 
                            value = "G-VB81B86GEM",
                            placeholder = "e.g., G-XXXXXXXXXX"),
                  helpText("This is the tracking ID embedded in your website. Used for verification only."),
                  hr(),
                  div(class = "connection-status-box",
                      h4("Connection Status"),
                      uiOutput("connection_status_indicator"),
                      textOutput("connection_status_text")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Google Analytics API Credentials",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  fileInput("credentials_json", 
                            label = "Upload Service Account JSON File",
                            accept = c(".json")),
                  hr(),
                  uiOutput("credentials_status"),
                  hr(),
                  actionButton("test_connection", "🔍 Test Connection", 
                               class = "btn-warning",
                               style = "margin-right: 10px;"),
                  actionButton("disconnect_ga", "🔌 Disconnect", 
                               class = "btn-danger"),
                  hr(),
                  uiOutput("auth_status_display"),
                  hr(),
                  selectInput("ga_view_id", "Select GA4 Property:", 
                              choices = c("Not connected" = ""),
                              selected = "")
                )
              ),
              fluidRow(
                box(
                  title = "Date Range Configuration",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  dateRangeInput("default_date_range",
                                 "Select Date Range for Data Pull:",
                                 start = Sys.Date() - 30,
                                 end = Sys.Date()),
                  helpText("This date range will be used when loading data from Google Analytics")
                )
              ),
              fluidRow(
                box(
                  title = "Connection & Activity Log",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  verbatimTextOutput("connection_log")
                )
              )
      ),
      
      # Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Data Loading Controls",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  p(strong("Load Real Google Analytics Data")),
                  p("Click the button below to pull live data from your Google Analytics property for the selected date range."),
                  hr(),
                  actionButton("load_real_data", "🔗 Load Google Analytics Data", 
                               class = "btn-success",
                               style = "font-size: 16px;"),
                  hr(),
                  uiOutput("data_load_status")
                )
              ),
              fluidRow(
                box(
                  title = "Website Verification",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  uiOutput("website_verification")
                )
              ),
              fluidRow(
                valueBoxOutput("total_users", width = 3),
                valueBoxOutput("total_sessions", width = 3),
                valueBoxOutput("total_pageviews", width = 3),
                valueBoxOutput("avg_engagement", width = 3)
              ),
              fluidRow(
                box(
                  title = "Daily Traffic Trend",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("traffic_trend_plot", height = "400px")
                )
              ),
              fluidRow(
                box(
                  title = "Key Metrics Summary",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("metrics_summary_chart", height = "350px")
                ),
                box(
                  title = "User Engagement Overview",
                  status = "success",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("engagement_overview", height = "350px")
                )
              )
      ),
      
      # Traffic Sources Tab
      tabItem(tabName = "traffic",
              fluidRow(
                valueBoxOutput("direct_traffic", width = 4),
                valueBoxOutput("unique_sources", width = 4),
                valueBoxOutput("top_channel", width = 4)
              ),
              fluidRow(
                box(
                  title = "Traffic by Channel",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("channel_distribution", height = "350px")
                ),
                box(
                  title = "Source / Medium Breakdown",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("source_medium_chart", height = "350px")
                )
              ),
              fluidRow(
                box(
                  title = "Detailed Traffic Source Data",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("traffic_source_table")
                )
              )
      ),
      
      # Geographic Analysis Tab
      tabItem(tabName = "geography",
              fluidRow(
                valueBoxOutput("total_countries", width = 4),
                valueBoxOutput("total_cities", width = 4),
                valueBoxOutput("top_country", width = 4)
              ),
              fluidRow(
                box(
                  title = "Geographic Distribution Map",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("geo_map", height = "450px")
                )
              ),
              fluidRow(
                box(
                  title = "Top Countries by Users",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("top_countries_chart", height = "350px")
                ),
                box(
                  title = "Top Cities by Sessions",
                  status = "success",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("top_cities_chart", height = "350px")
                )
              ),
              fluidRow(
                box(
                  title = "Geographic Details",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("geo_table")
                )
              )
      ),
      
      # Technology & Devices Tab
      tabItem(tabName = "technology",
              fluidRow(
                valueBoxOutput("desktop_users", width = 4),
                valueBoxOutput("mobile_users", width = 4),
                valueBoxOutput("top_browser", width = 4)
              ),
              fluidRow(
                box(
                  title = "Device Category Distribution",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("device_category_chart", height = "350px")
                ),
                box(
                  title = "Operating System Distribution",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("os_distribution_chart", height = "350px")
                )
              ),
              fluidRow(
                box(
                  title = "Browser Distribution",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("browser_distribution_chart", height = "300px")
                )
              ),
              fluidRow(
                box(
                  title = "Technology Details",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("technology_table")
                )
              )
      ),
      
      # Page Performance Tab
      tabItem(tabName = "pages",
              fluidRow(
                valueBoxOutput("total_pages", width = 4),
                valueBoxOutput("top_page_views", width = 4),
                valueBoxOutput("avg_bounce", width = 4)
              ),
              fluidRow(
                box(
                  title = "Top Pages by Views",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("top_pages_chart", height = "400px")
                )
              ),
              fluidRow(
                box(
                  title = "Landing Pages Performance",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("landing_pages_chart", height = "350px")
                ),
                box(
                  title = "Page Engagement Metrics",
                  status = "success",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("page_engagement_chart", height = "350px")
                )
              ),
              fluidRow(
                box(
                  title = "Detailed Page Performance",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("page_performance_table")
                )
              )
      ),
      
      # User Behavior Tab
      tabItem(tabName = "behavior",
              fluidRow(
                valueBoxOutput("new_users", width = 4),
                valueBoxOutput("returning_users", width = 4),
                valueBoxOutput("sessions_per_user", width = 4)
              ),
              fluidRow(
                box(
                  title = "New vs Returning Users",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("user_type_chart", height = "350px")
                ),
                box(
                  title = "Hourly Traffic Pattern",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("hourly_traffic_chart", height = "350px")
                )
              ),
              fluidRow(
                box(
                  title = "Day of Week Traffic Pattern",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("day_of_week_chart", height = "300px")
                )
              ),
              fluidRow(
                box(
                  title = "User Behavior Metrics",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("user_behavior_table")
                )
              )
      ),
      
      # Events Tracking Tab
      tabItem(tabName = "events",
              fluidRow(
                valueBoxOutput("total_events", width = 4),
                valueBoxOutput("unique_event_types", width = 4),
                valueBoxOutput("events_per_user", width = 4)
              ),
              fluidRow(
                box(
                  title = "Event Distribution",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("event_distribution_chart", height = "400px")
                )
              ),
              fluidRow(
                box(
                  title = "Events by Page",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("events_by_page_chart", height = "350px")
                )
              ),
              fluidRow(
                box(
                  title = "Event Details",
                  status = "success",
                  solidHeader = TRUE,
                  width = 6,
                  DTOutput("event_details_table")
                ),
                box(
                  title = "Event-Page Combinations",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  DTOutput("event_page_table")
                )
              )
      )
    )
  )
)

# ============================================================================
# SERVER LOGIC
# ============================================================================

server <- function(input, output, session) {
  
  # Reactive values
  ga_data <- reactiveValues(
    authenticated = FALSE,
    connected = FALSE,
    credentials_loaded = FALSE,
    property_id = NULL,
    data_loaded = FALSE,
    
    # Data storage
    overview_data = NULL,
    geo_data = NULL,
    device_data = NULL,
    source_medium_data = NULL,
    channel_data = NULL,
    page_data = NULL,
    landing_page_data = NULL,
    user_type_data = NULL,
    hourly_data = NULL,
    dow_data = NULL,
    event_data = NULL,
    event_page_data = NULL,
    page_hostname_data = NULL,  # For website verification
    
    connection_log = character(0),
    account_summaries = NULL
  )
  
  # Helper function to add log entries
  add_log <- function(message) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    log_entry <- paste0("[", timestamp, "] ", message)
    ga_data$connection_log <- c(ga_data$connection_log, log_entry)
    if (length(ga_data$connection_log) > 50) {
      ga_data$connection_log <- tail(ga_data$connection_log, 50)
    }
  }
  
  # ============================================================================
  # AUTHENTICATION SECTION
  # ============================================================================
  
  # Load Service Account Credentials
  observeEvent(input$credentials_json, {
    req(input$credentials_json)
    
    add_log("Loading service account credentials...")
    
    tryCatch({
      json_path <- input$credentials_json$datapath
      
      googleAnalyticsR::ga_auth(json_file = json_path)
      Sys.sleep(1)
      
      account_summaries <- tryCatch({
        googleAnalyticsR::ga_account_list(type = "ga4")
      }, error = function(e) {
        NULL
      })
      
      if (!is.null(account_summaries) && nrow(account_summaries) > 0) {
        ga_data$credentials_loaded <- TRUE
        ga_data$authenticated <- TRUE
        ga_data$connected <- TRUE
        ga_data$account_summaries <- account_summaries
        
        add_log("✓ Service account authenticated successfully")
        add_log(paste("✓ Found", nrow(account_summaries), "GA4 properties"))
        
        showNotification(
          "✓ Service account authenticated successfully!",
          type = "message",
          duration = 5
        )
        
        # Get property ID column name
        property_id_col <- names(account_summaries)[grep("property.*id", names(account_summaries), ignore.case = TRUE)][1]
        if (is.na(property_id_col)) property_id_col <- "propertyId"
        
        property_choices <- setNames(
          account_summaries[[property_id_col]],
          paste0(account_summaries[[1]], " - (", account_summaries[[property_id_col]], ")")
        )
        
        updateSelectInput(session, "ga_view_id", choices = property_choices)
        
        target_property <- "515710306"
        if (target_property %in% property_choices) {
          ga_data$property_id <- target_property
          updateSelectInput(session, "ga_view_id", selected = target_property)
          add_log(paste("✓ Auto-selected property:", target_property))
          updateTextInput(session, "ga_property_id", value = target_property)
        } else if (length(property_choices) > 0) {
          ga_data$property_id <- property_choices[1]
          updateSelectInput(session, "ga_view_id", selected = property_choices[1])
          add_log(paste("Selected first property:", ga_data$property_id))
          updateTextInput(session, "ga_property_id", value = property_choices[1])
        }
        
      } else {
        ga_data$credentials_loaded <- FALSE
        ga_data$authenticated <- FALSE
        add_log("✗ Authentication failed: Could not retrieve GA properties")
        showNotification(
          "Authentication failed. Check service account permissions.",
          type = "error",
          duration = 10
        )
      }
      
    }, error = function(e) {
      add_log(paste("✗ Failed to authenticate:", e$message))
      showNotification(
        paste("Failed to load credentials:", e$message),
        type = "error",
        duration = 10
      )
      ga_data$credentials_loaded <- FALSE
      ga_data$authenticated <- FALSE
    })
  })
  
  # Observer for property selection
  observeEvent(input$ga_view_id, {
    req(input$ga_view_id)
    if (input$ga_view_id != "" && input$ga_view_id != "Not connected") {
      ga_data$property_id <- input$ga_view_id
      updateTextInput(session, "ga_property_id", value = input$ga_view_id)
      add_log(paste("Property selected:", ga_data$property_id))
    }
  })
  
  # Test Connection
  observeEvent(input$test_connection, {
    if (!ga_data$authenticated) {
      showNotification(
        "Please authenticate first by uploading your service account JSON.",
        type = "warning",
        duration = 5
      )
      add_log("Connection test failed: Not authenticated")
      return()
    }
    
    if (is.null(ga_data$property_id) || ga_data$property_id == "") {
      showNotification(
        "Please select a Property from the dropdown.",
        type = "warning",
        duration = 5
      )
      add_log("Connection test failed: No property selected")
      return()
    }
    
    add_log("Testing connection to Google Analytics...")
    add_log(paste("Using Property ID:", ga_data$property_id))
    showNotification("Testing connection...", type = "message", duration = 3)
    
    tryCatch({
      test_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(Sys.Date() - 7, Sys.Date()),
        metrics = "activeUsers",
        dimensions = "date",
        limit = 5
      )
      
      if (!is.null(test_data) && nrow(test_data) > 0) {
        ga_data$connected <- TRUE
        add_log("✓ Connection test successful!")
        add_log(paste("Retrieved", nrow(test_data), "days of data"))
        showNotification(
          "✓ Connection test successful! You can now load data.",
          type = "message",
          duration = 5
        )
      } else {
        add_log("⚠ Connection successful but no data returned")
        showNotification(
          "Connected but no data available. Check your date range.",
          type = "warning",
          duration = 5
        )
      }
      
    }, error = function(e) {
      add_log(paste("✗ Connection test failed:", e$message))
      showNotification(
        paste("Connection test failed:", e$message),
        type = "error",
        duration = 10
      )
      ga_data$connected <- FALSE
    })
  })
  
  # Disconnect
  observeEvent(input$disconnect_ga, {
    ga_data$authenticated <- FALSE
    ga_data$connected <- FALSE
    ga_data$data_loaded <- FALSE
    ga_data$property_id <- NULL
    updateSelectInput(session, "ga_view_id", choices = c("Not connected" = ""))
    updateTextInput(session, "ga_property_id", value = "515710306")
    add_log("Disconnected from Google Analytics")
    showNotification("Disconnected successfully.", type = "message", duration = 3)
  })
  
  # Status outputs
  output$credentials_status <- renderUI({
    if (ga_data$credentials_loaded) {
      div(class = "credentials-loaded",
          icon("check-circle"), 
          strong(" Credentials Status: "), "Loaded successfully"
      )
    } else {
      div(class = "alert-info",
          icon("info-circle"), 
          strong(" Credentials Status: "), "Not loaded. Please upload your service account JSON file."
      )
    }
  })
  
  output$connection_status_indicator <- renderUI({
    if (ga_data$connected) {
      div(
        span(class = "status-indicator status-connected"),
        strong("Connected", style = "color: #2ecc71;")
      )
    } else {
      div(
        span(class = "status-indicator status-disconnected"),
        strong("Not Connected", style = "color: #e74c3c;")
      )
    }
  })
  
  output$connection_status_text <- renderText({
    if (ga_data$connected) {
      paste("Successfully connected to Property:", ga_data$property_id)
    } else if (ga_data$authenticated) {
      "Authenticated. Please test the connection."
    } else {
      "Please upload service account JSON file first."
    }
  })
  
  output$auth_status_display <- renderUI({
    if (ga_data$connected) {
      div(class = "alert-success",
          icon("check-circle"), 
          strong(" Status: "), "Authenticated and Connected",
          br(),
          "Property ID: ", ga_data$property_id,
          br(),
          "Ready to load data!"
      )
    } else if (ga_data$authenticated) {
      div(class = "alert-info",
          icon("info-circle"), 
          strong(" Status: "), "Authenticated - Please test connection"
      )
    } else {
      div(class = "alert-danger",
          icon("times-circle"), 
          strong(" Status: "), "Not configured - Upload service account JSON file"
      )
    }
  })
  
  output$connection_log <- renderText({
    if (length(ga_data$connection_log) == 0) {
      return("No activity yet. Upload service account JSON file to begin.")
    }
    paste(rev(ga_data$connection_log), collapse = "\n")
  })
  
  # ============================================================================
  # DATA LOADING SECTION
  # ============================================================================
  
  observeEvent(input$load_real_data, {
    if (!ga_data$connected) {
      showNotification(
        "Please authenticate and test connection first in the Settings tab.",
        type = "warning",
        duration = 5
      )
      add_log("Data load failed: Not connected")
      return()
    }
    
    if (is.null(ga_data$property_id) || ga_data$property_id == "") {
      showNotification(
        "Please select a Property from the dropdown in Settings.",
        type = "warning",
        duration = 5
      )
      add_log("Data load failed: No Property selected")
      return()
    }
    
    add_log("Loading Google Analytics data for all tabs...")
    add_log(paste("Using Property ID:", ga_data$property_id))
    showNotification("Loading data from Google Analytics...", 
                     type = "message", duration = 5)
    
    tryCatch({
      start_date <- input$default_date_range[1]
      end_date <- input$default_date_range[2]
      
      add_log(paste("Date range:", start_date, "to", end_date))
      
      # 1. OVERVIEW DATA
      add_log("Fetching overview data...")
      ga_data$overview_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("activeUsers", "newUsers", "sessions", "screenPageViews", 
                    "userEngagementDuration", "averageSessionDuration", 
                    "bounceRate", "sessionsPerUser", "screenPageViewsPerSession", "eventCount"),
        dimensions = c("date"),
        limit = -1
      )
      add_log(paste("✓ Overview data:", nrow(ga_data$overview_data), "days"))
      
      # 2. GEOGRAPHIC DATA
      add_log("Fetching geographic data...")
      ga_data$geo_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("activeUsers", "sessions", "screenPageViews"),
        dimensions = c("country", "city", "region"),
        limit = 100
      )
      add_log(paste("✓ Geographic data:", nrow(ga_data$geo_data), "locations"))
      
      # 3. DEVICE DATA
      add_log("Fetching device data...")
      ga_data$device_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("activeUsers", "sessions", "screenPageViews", "averageSessionDuration"),
        dimensions = c("deviceCategory", "operatingSystem", "browser"),
        limit = 100
      )
      add_log(paste("✓ Device data:", nrow(ga_data$device_data), "combinations"))
      
      # 4. SOURCE/MEDIUM DATA
      add_log("Fetching traffic source data...")
      ga_data$source_medium_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("activeUsers", "newUsers", "sessions", "screenPageViews"),
        dimensions = c("sessionSource", "sessionMedium", "sessionCampaignName"),
        limit = 100
      )
      add_log(paste("✓ Source/medium data:", nrow(ga_data$source_medium_data), "sources"))
      
      # 5. CHANNEL DATA
      add_log("Fetching channel data...")
      ga_data$channel_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("activeUsers", "sessions", "screenPageViews", "averageSessionDuration"),
        dimensions = c("sessionDefaultChannelGroup"),
        limit = -1
      )
      add_log(paste("✓ Channel data:", nrow(ga_data$channel_data), "channels"))
      
      # 6. PAGE DATA
      add_log("Fetching page data...")
      ga_data$page_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("screenPageViews", "activeUsers", "averageSessionDuration", "bounceRate"),
        dimensions = c("pagePath", "pageTitle"),
        limit = 50
      )
      add_log(paste("✓ Page data:", nrow(ga_data$page_data), "pages"))
      
      # 7. LANDING PAGES
      add_log("Fetching landing page data...")
      ga_data$landing_page_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("sessions", "activeUsers", "bounceRate"),
        dimensions = c("landingPage"),
        limit = 20
      )
      add_log(paste("✓ Landing pages:", nrow(ga_data$landing_page_data), "pages"))
      
      # 8. USER TYPE DATA
      add_log("Fetching user type data...")
      ga_data$user_type_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("activeUsers", "newUsers", "sessions", "screenPageViews"),
        dimensions = c("newVsReturning"),
        limit = -1
      )
      add_log(paste("✓ User type data:", nrow(ga_data$user_type_data), "categories"))
      
      # 9. HOURLY DATA
      add_log("Fetching hourly data...")
      ga_data$hourly_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("activeUsers", "sessions"),
        dimensions = c("hour"),
        limit = -1
      )
      add_log(paste("✓ Hourly data:", nrow(ga_data$hourly_data), "hours"))
      
      # 10. DAY OF WEEK DATA
      add_log("Fetching day of week data...")
      ga_data$dow_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("activeUsers", "sessions", "screenPageViews"),
        dimensions = c("dayOfWeek", "dayOfWeekName"),
        limit = -1
      )
      add_log(paste("✓ Day of week data:", nrow(ga_data$dow_data), "days"))
      
      # 11. EVENT DATA
      add_log("Fetching event data...")
      ga_data$event_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("eventCount", "eventCountPerUser"),
        dimensions = c("eventName"),
        limit = 100
      )
      add_log(paste("✓ Event data:", nrow(ga_data$event_data), "event types"))
      
      # 12. EVENT-PAGE DATA
      add_log("Fetching event-page data...")
      ga_data$event_page_data <- googleAnalyticsR::ga_data(
        propertyId = ga_data$property_id,
        date_range = c(start_date, end_date),
        metrics = c("eventCount"),
        dimensions = c("eventName", "pagePath"),
        limit = 100
      )
      add_log(paste("✓ Event-page data:", nrow(ga_data$event_page_data), "combinations"))
      
      # 13. WEBSITE VERIFICATION - Get hostname to verify correct site
      add_log("Verifying website hostname...")
      ga_data$page_hostname_data <- tryCatch({
        googleAnalyticsR::ga_data(
          propertyId = ga_data$property_id,
          date_range = c(start_date, end_date),
          metrics = c("screenPageViews", "activeUsers"),
          dimensions = c("hostName", "pagePath", "pageTitle"),
          limit = 50
        )
      }, error = function(e) {
        add_log("⚠ Could not retrieve hostname data")
        NULL
      })
      
      if (!is.null(ga_data$page_hostname_data)) {
        hostnames <- unique(ga_data$page_hostname_data$hostName)
        add_log(paste("✓ Hostnames found:", paste(hostnames, collapse = ", ")))
        
        if ("www.atera-analytics.co.uk" %in% hostnames || "atera-analytics.co.uk" %in% hostnames) {
          add_log("✓✓✓ VERIFIED: This IS www.atera-analytics.co.uk data!")
        } else {
          add_log("⚠⚠⚠ WARNING: www.atera-analytics.co.uk NOT found in hostnames!")
          add_log(paste("Found hostnames:", paste(hostnames, collapse = ", ")))
        }
      }
      
      ga_data$data_loaded <- TRUE
      
      add_log("")
      add_log("═══════════════════════════════════════════")
      add_log("  DATA LOAD COMPLETE")
      add_log("═══════════════════════════════════════════")
      add_log(paste("Total Users:", sum(ga_data$overview_data$activeUsers, na.rm = TRUE)))
      add_log(paste("Total Sessions:", sum(ga_data$overview_data$sessions, na.rm = TRUE)))
      add_log(paste("Total Pageviews:", sum(ga_data$overview_data$screenPageViews, na.rm = TRUE)))
      add_log("═══════════════════════════════════════════")
      
      showNotification(
        "✓ All data loaded successfully from Google Analytics!", 
        type = "message",
        duration = 5
      )
      
    }, error = function(e) {
      add_log(paste("✗ Failed to load data:", e$message))
      showNotification(
        paste("Failed to load data:", e$message),
        type = "error",
        duration = 10
      )
    })
  })
  
  # Data load status
  output$data_load_status <- renderUI({
    if (ga_data$data_loaded) {
      div(class = "alert-success",
          icon("check-circle"), 
          strong(" Data Loaded Successfully"),
          br(),
          "Date Range: ", format(input$default_date_range[1], "%Y-%m-%d"), 
          " to ", format(input$default_date_range[2], "%Y-%m-%d"),
          br(),
          "Property ID: ", ga_data$property_id
      )
    } else {
      div(class = "alert-info",
          icon("info-circle"), 
          strong(" No data loaded. "), "Click 'Load Google Analytics Data' to fetch data."
      )
    }
  })
  
  # Website verification output
  output$website_verification <- renderUI({
    if (!ga_data$data_loaded || is.null(ga_data$page_hostname_data)) {
      return(div(
        p("Website verification will appear here after loading data."),
        p("This will confirm you're analyzing the correct website.")
      ))
    }
    
    hostnames <- unique(ga_data$page_hostname_data$hostName)
    is_correct_site <- "www.atera-analytics.co.uk" %in% hostnames || 
      "atera-analytics.co.uk" %in% hostnames
    
    # Get sample pages
    sample_pages <- ga_data$page_hostname_data %>%
      arrange(desc(screenPageViews)) %>%
      head(5)
    
    if (is_correct_site) {
      div(
        div(class = "alert-success",
            icon("check-circle", style = "font-size: 20px;"),
            strong(" VERIFIED: www.atera-analytics.co.uk", style = "font-size: 16px;"),
            br(), br(),
            strong("Connection Details:"), br(),
            "Account ID: 377162613", br(),
            "Property ID: ", ga_data$property_id, br(),
            "Measurement ID: G-VB81B86GEM", br(),
            "Google Tag ID: GT-M6QPKL9V", br(),
            br(),
            strong("Hostname(s) found in data:"), br(),
            tags$ul(
              lapply(hostnames, function(h) tags$li(h))
            )
        ),
        hr(),
        h4("Sample Pages from This Property:"),
        tags$ol(
          lapply(1:nrow(sample_pages), function(i) {
            tags$li(
              strong("Path: "), sample_pages$pagePath[i], br(),
              "Title: ", sample_pages$pageTitle[i], br(),
              "Host: ", sample_pages$hostName[i], br(),
              "Views: ", sample_pages$screenPageViews[i], " | Users: ", sample_pages$activeUsers[i]
            )
          })
        ),
        hr(),
        div(class = "schema-info",
            h4("WordPress Site Kit Configuration Status:"),
            p(strong("✓"), " Analytics plugin: Connected"),
            p(strong("✓"), " Account: 377162613"),
            p(strong("✓"), " Property: 515710306"),
            p(strong("✓"), " Measurement ID: G-VB81B86GEM"),
            p(strong("✓"), " Google Tag ID: GT-M6QPKL9V"),
            p(strong("✓"), " Snippet: Inserted"),
            p(strong("✓"), " Enhanced Measurement: Enabled"),
            p(strong("✓"), " Plugin conversion tracking: Enabled"),
            p("All data shown above is from this configured property.")
        )
      )
    } else {
      div(
        div(class = "alert-danger",
            icon("exclamation-triangle", style = "font-size: 20px;"),
            strong(" WARNING: Website Mismatch!", style = "font-size: 16px;"),
            br(), br(),
            p("The data does NOT appear to be from www.atera-analytics.co.uk"),
            br(),
            strong("Expected Configuration:"), br(),
            "Account ID: 377162613", br(),
            "Property ID: 515710306", br(),
            "Measurement ID: G-VB81B86GEM", br(),
            "Google Tag ID: GT-M6QPKL9V", br(),
            br(),
            strong("Hostname(s) found in data:"), br(),
            tags$ul(
              lapply(hostnames, function(h) tags$li(h))
            ),
            br(),
            p(style = "color: #ffffff;", 
              "Please verify you have selected the correct Property ID in Settings.")
        ),
        hr(),
        h4("Sample Pages from This Property:"),
        tags$ol(
          lapply(1:min(5, nrow(sample_pages)), function(i) {
            tags$li(
              strong("Path: "), sample_pages$pagePath[i], br(),
              "Title: ", sample_pages$pageTitle[i], br(),
              "Host: ", sample_pages$hostName[i], br(),
              "Views: ", sample_pages$screenPageViews[i]
            )
          })
        )
      )
    }
  })
  
  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================
  
  check_data_loaded <- function() {
    if (!ga_data$data_loaded || is.null(ga_data$overview_data)) {
      return(FALSE)
    }
    return(TRUE)
  }
  
  create_empty_plot <- function(message = "No data loaded. Please load data from the Overview tab.") {
    plot_ly() %>%
      add_annotations(
        text = message,
        x = 0.5,
        y = 0.5,
        xref = "paper",
        yref = "paper",
        showarrow = FALSE,
        font = list(size = 16, color = "#7ec8e3")
      ) %>%
      layout(
        xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
        yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)"
      )
  }
  
  # ============================================================================
  # OVERVIEW TAB OUTPUTS
  # ============================================================================
  
  output$total_users <- renderValueBox({
    if (!check_data_loaded()) {
      return(valueBox(
        value = "-",
        subtitle = "Total Users",
        icon = icon("users"),
        color = "purple"
      ))
    }
    
    total <- sum(ga_data$overview_data$activeUsers, na.rm = TRUE)
    valueBox(
      value = formatC(total, format = "d", big.mark = ","),
      subtitle = "Total Users",
      icon = icon("users"),
      color = "purple"
    )
  })
  
  output$total_sessions <- renderValueBox({
    if (!check_data_loaded()) {
      return(valueBox(
        value = "-",
        subtitle = "Total Sessions",
        icon = icon("chart-line"),
        color = "blue"
      ))
    }
    
    total <- sum(ga_data$overview_data$sessions, na.rm = TRUE)
    valueBox(
      value = formatC(total, format = "d", big.mark = ","),
      subtitle = "Total Sessions",
      icon = icon("chart-line"),
      color = "blue"
    )
  })
  
  output$total_pageviews <- renderValueBox({
    if (!check_data_loaded()) {
      return(valueBox(
        value = "-",
        subtitle = "Total Pageviews",
        icon = icon("eye"),
        color = "green"
      ))
    }
    
    total <- sum(ga_data$overview_data$screenPageViews, na.rm = TRUE)
    valueBox(
      value = formatC(total, format = "d", big.mark = ","),
      subtitle = "Total Pageviews",
      icon = icon("eye"),
      color = "green"
    )
  })
  
  output$avg_engagement <- renderValueBox({
    if (!check_data_loaded()) {
      return(valueBox(
        value = "-",
        subtitle = "Avg Engagement Duration",
        icon = icon("clock"),
        color = "yellow"
      ))
    }
    
    avg <- mean(ga_data$overview_data$averageSessionDuration, na.rm = TRUE)
    valueBox(
      value = paste0(round(avg, 1), " sec"),
      subtitle = "Avg Session Duration",
      icon = icon("clock"),
      color = "yellow"
    )
  })
  
  output$traffic_trend_plot <- renderPlotly({
    if (!check_data_loaded()) {
      return(create_empty_plot())
    }
    
    data <- ga_data$overview_data
    data$date <- as.Date(data$date)
    
    plot_ly(data, x = ~date) %>%
      add_trace(y = ~activeUsers, name = "Users", type = "scatter", mode = "lines+markers",
                line = list(color = "#667eea", width = 3),
                marker = list(color = "#667eea", size = 8)) %>%
      add_trace(y = ~sessions, name = "Sessions", type = "scatter", mode = "lines+markers",
                line = list(color = "#4a90e2", width = 3),
                marker = list(color = "#4a90e2", size = 8)) %>%
      add_trace(y = ~screenPageViews, name = "Pageviews", type = "scatter", mode = "lines+markers",
                line = list(color = "#2ecc71", width = 3),
                marker = list(color = "#2ecc71", size = 8)) %>%
      layout(
        xaxis = list(title = "Date", color = "#e0e7ff", gridcolor = "#2a5298"),
        yaxis = list(title = "Count", color = "#e0e7ff", gridcolor = "#2a5298"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff"),
        legend = list(font = list(color = "#e0e7ff"))
      )
  })
  
  output$metrics_summary_chart <- renderPlotly({
    if (!check_data_loaded()) {
      return(create_empty_plot())
    }
    
    data <- ga_data$overview_data
    
    summary_data <- data.frame(
      Metric = c("Users", "Sessions", "Pageviews", "Events"),
      Value = c(
        sum(data$activeUsers, na.rm = TRUE),
        sum(data$sessions, na.rm = TRUE),
        sum(data$screenPageViews, na.rm = TRUE),
        sum(data$eventCount, na.rm = TRUE)
      )
    )
    
    plot_ly(summary_data, x = ~Metric, y = ~Value, type = "bar",
            marker = list(color = c("#667eea", "#4a90e2", "#2ecc71", "#f39c12"))) %>%
      layout(
        xaxis = list(title = "", color = "#e0e7ff"),
        yaxis = list(title = "Total Count", color = "#e0e7ff", gridcolor = "#2a5298"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$engagement_overview <- renderPlotly({
    if (!check_data_loaded()) {
      return(create_empty_plot())
    }
    
    data <- ga_data$overview_data
    
    engagement_data <- data.frame(
      Metric = c("Bounce Rate", "Sessions/User", "Pages/Session"),
      Value = c(
        mean(data$bounceRate, na.rm = TRUE) * 100,
        mean(data$sessionsPerUser, na.rm = TRUE),
        mean(data$screenPageViewsPerSession, na.rm = TRUE)
      )
    )
    
    plot_ly(engagement_data, x = ~Metric, y = ~Value, type = "bar",
            marker = list(color = c("#e74c3c", "#667eea", "#2ecc71"))) %>%
      layout(
        xaxis = list(title = "", color = "#e0e7ff"),
        yaxis = list(title = "Average", color = "#e0e7ff", gridcolor = "#2a5298"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  # ============================================================================
  # TRAFFIC SOURCES TAB
  # ============================================================================
  
  output$direct_traffic <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$channel_data)) {
      return(valueBox(value = "-", subtitle = "Direct Traffic", 
                      icon = icon("arrow-right"), color = "purple"))
    }
    
    direct <- ga_data$channel_data %>%
      filter(sessionDefaultChannelGroup == "Direct") %>%
      summarise(total = sum(sessions, na.rm = TRUE))
    
    valueBox(
      value = formatC(direct$total, format = "d", big.mark = ","),
      subtitle = "Direct Sessions",
      icon = icon("arrow-right"),
      color = "purple"
    )
  })
  
  output$unique_sources <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$source_medium_data)) {
      return(valueBox(value = "-", subtitle = "Unique Sources",
                      icon = icon("share-alt"), color = "blue"))
    }
    
    count <- nrow(ga_data$source_medium_data)
    valueBox(
      value = count,
      subtitle = "Unique Sources",
      icon = icon("share-alt"),
      color = "blue"
    )
  })
  
  output$top_channel <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$channel_data)) {
      return(valueBox(value = "-", subtitle = "Top Channel",
                      icon = icon("trophy"), color = "green"))
    }
    
    top <- ga_data$channel_data %>%
      arrange(desc(sessions)) %>%
      slice(1)
    
    valueBox(
      value = top$sessionDefaultChannelGroup,
      subtitle = "Top Channel",
      icon = icon("trophy"),
      color = "green"
    )
  })
  
  output$channel_distribution <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$channel_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$channel_data %>%
      arrange(desc(sessions))
    
    plot_ly(data, labels = ~sessionDefaultChannelGroup, values = ~sessions, type = "pie",
            marker = list(colors = c("#667eea", "#4a90e2", "#2ecc71", "#f39c12", "#e74c3c")),
            textinfo = "label+percent",
            textfont = list(color = "#ffffff")) %>%
      layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff"),
        showlegend = TRUE,
        legend = list(font = list(color = "#e0e7ff"))
      )
  })
  
  output$source_medium_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$source_medium_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$source_medium_data %>%
      arrange(desc(sessions)) %>%
      head(10)
    
    data$label <- paste0(data$sessionSource, " / ", data$sessionMedium)
    
    plot_ly(data, x = ~sessions, y = ~reorder(label, sessions), type = "bar",
            orientation = "h",
            marker = list(color = "#667eea")) %>%
      layout(
        xaxis = list(title = "Sessions", color = "#e0e7ff", gridcolor = "#2a5298"),
        yaxis = list(title = "", color = "#e0e7ff"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$traffic_source_table <- renderDT({
    if (!check_data_loaded() || is.null(ga_data$source_medium_data)) {
      return(datatable(
        data.frame(Message = "No data loaded."),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    data <- ga_data$source_medium_data %>%
      arrange(desc(sessions))
    
    datatable(data,
              options = list(pageLength = 10, scrollX = TRUE),
              class = "display nowrap")
  })
  
  # ============================================================================
  # GEOGRAPHIC ANALYSIS TAB
  # ============================================================================
  
  output$total_countries <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$geo_data)) {
      return(valueBox(value = "-", subtitle = "Countries",
                      icon = icon("globe"), color = "purple"))
    }
    
    count <- length(unique(ga_data$geo_data$country))
    valueBox(
      value = count,
      subtitle = "Countries",
      icon = icon("globe"),
      color = "purple"
    )
  })
  
  output$total_cities <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$geo_data)) {
      return(valueBox(value = "-", subtitle = "Cities",
                      icon = icon("map-marker-alt"), color = "blue"))
    }
    
    count <- length(unique(ga_data$geo_data$city))
    valueBox(
      value = count,
      subtitle = "Cities",
      icon = icon("map-marker-alt"),
      color = "blue"
    )
  })
  
  output$top_country <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$geo_data)) {
      return(valueBox(value = "-", subtitle = "Top Country",
                      icon = icon("flag"), color = "green"))
    }
    
    top <- ga_data$geo_data %>%
      group_by(country) %>%
      summarise(total = sum(activeUsers, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total)) %>%
      slice(1)
    
    valueBox(
      value = top$country,
      subtitle = "Top Country",
      icon = icon("flag"),
      color = "green"
    )
  })
  
  output$geo_map <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$geo_data)) {
      return(create_empty_plot())
    }
    
    geo_summary <- ga_data$geo_data %>%
      group_by(country) %>%
      summarise(users = sum(activeUsers, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(users))
    
    plot_geo(geo_summary) %>%
      add_trace(
        z = ~users,
        locations = ~country,
        locationmode = "country names",
        text = ~paste(country, "<br>Users:", users),
        colors = "Blues",
        reversescale = TRUE
      ) %>%
      layout(
        geo = list(
          showcountries = TRUE,
          countrycolor = "#4a90e2",
          bgcolor = "rgba(0,0,0,0)"
        ),
        paper_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$top_countries_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$geo_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$geo_data %>%
      group_by(country) %>%
      summarise(users = sum(activeUsers, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(users)) %>%
      head(10)
    
    plot_ly(data, x = ~users, y = ~reorder(country, users), type = "bar",
            orientation = "h",
            marker = list(color = "#667eea")) %>%
      layout(
        xaxis = list(title = "Users", color = "#e0e7ff", gridcolor = "#2a5298"),
        yaxis = list(title = "", color = "#e0e7ff"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$top_cities_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$geo_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$geo_data %>%
      group_by(city) %>%
      summarise(sessions = sum(sessions, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(sessions)) %>%
      head(10)
    
    plot_ly(data, x = ~sessions, y = ~reorder(city, sessions), type = "bar",
            orientation = "h",
            marker = list(color = "#4a90e2")) %>%
      layout(
        xaxis = list(title = "Sessions", color = "#e0e7ff", gridcolor = "#2a5298"),
        yaxis = list(title = "", color = "#e0e7ff"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$geo_table <- renderDT({
    if (!check_data_loaded() || is.null(ga_data$geo_data)) {
      return(datatable(
        data.frame(Message = "No data loaded."),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    datatable(ga_data$geo_data,
              options = list(pageLength = 10, scrollX = TRUE),
              class = "display nowrap")
  })
  
  # ============================================================================
  # TECHNOLOGY & DEVICES TAB
  # ============================================================================
  
  output$desktop_users <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$device_data)) {
      return(valueBox(value = "-", subtitle = "Desktop Users",
                      icon = icon("desktop"), color = "purple"))
    }
    
    desktop <- ga_data$device_data %>%
      filter(deviceCategory == "desktop") %>%
      summarise(total = sum(activeUsers, na.rm = TRUE))
    
    valueBox(
      value = formatC(desktop$total, format = "d", big.mark = ","),
      subtitle = "Desktop Users",
      icon = icon("desktop"),
      color = "purple"
    )
  })
  
  output$mobile_users <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$device_data)) {
      return(valueBox(value = "-", subtitle = "Mobile Users",
                      icon = icon("mobile-alt"), color = "blue"))
    }
    
    mobile <- ga_data$device_data %>%
      filter(deviceCategory == "mobile") %>%
      summarise(total = sum(activeUsers, na.rm = TRUE))
    
    valueBox(
      value = formatC(mobile$total, format = "d", big.mark = ","),
      subtitle = "Mobile Users",
      icon = icon("mobile-alt"),
      color = "blue"
    )
  })
  
  output$top_browser <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$device_data)) {
      return(valueBox(value = "-", subtitle = "Top Browser",
                      icon = icon("chrome"), color = "green"))
    }
    
    top <- ga_data$device_data %>%
      group_by(browser) %>%
      summarise(total = sum(activeUsers, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total)) %>%
      slice(1)
    
    valueBox(
      value = top$browser,
      subtitle = "Top Browser",
      icon = icon("chrome"),
      color = "green"
    )
  })
  
  output$device_category_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$device_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$device_data %>%
      group_by(deviceCategory) %>%
      summarise(users = sum(activeUsers, na.rm = TRUE), .groups = "drop")
    
    plot_ly(data, labels = ~deviceCategory, values = ~users, type = "pie",
            marker = list(colors = c("#667eea", "#4a90e2", "#2ecc71")),
            hole = 0.4) %>%
      layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$os_distribution_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$device_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$device_data %>%
      group_by(operatingSystem) %>%
      summarise(users = sum(activeUsers, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(users)) %>%
      head(10)
    
    plot_ly(data, x = ~users, y = ~reorder(operatingSystem, users), type = "bar",
            orientation = "h",
            marker = list(color = "#4a90e2")) %>%
      layout(
        xaxis = list(title = "Users", color = "#e0e7ff", gridcolor = "#2a5298"),
        yaxis = list(title = "", color = "#e0e7ff"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$browser_distribution_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$device_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$device_data %>%
      group_by(browser) %>%
      summarise(users = sum(activeUsers, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(users)) %>%
      head(10)
    
    plot_ly(data, x = ~reorder(browser, users), y = ~users, type = "bar",
            marker = list(color = "#667eea")) %>%
      layout(
        xaxis = list(title = "", color = "#e0e7ff"),
        yaxis = list(title = "Users", color = "#e0e7ff", gridcolor = "#2a5298"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$technology_table <- renderDT({
    if (!check_data_loaded() || is.null(ga_data$device_data)) {
      return(datatable(
        data.frame(Message = "No data loaded."),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    datatable(ga_data$device_data,
              options = list(pageLength = 10, scrollX = TRUE),
              class = "display nowrap")
  })
  
  # ============================================================================
  # PAGE PERFORMANCE TAB
  # ============================================================================
  
  output$total_pages <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$page_data)) {
      return(valueBox(value = "-", subtitle = "Total Pages",
                      icon = icon("file"), color = "purple"))
    }
    
    count <- nrow(ga_data$page_data)
    valueBox(
      value = count,
      subtitle = "Total Pages",
      icon = icon("file"),
      color = "purple"
    )
  })
  
  output$top_page_views <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$page_data)) {
      return(valueBox(value = "-", subtitle = "Top Page Views",
                      icon = icon("eye"), color = "blue"))
    }
    
    top <- max(ga_data$page_data$screenPageViews, na.rm = TRUE)
    valueBox(
      value = formatC(top, format = "d", big.mark = ","),
      subtitle = "Top Page Views",
      icon = icon("eye"),
      color = "blue"
    )
  })
  
  output$avg_bounce <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$page_data)) {
      return(valueBox(value = "-", subtitle = "Avg Bounce Rate",
                      icon = icon("chart-line"), color = "yellow"))
    }
    
    avg <- mean(ga_data$page_data$bounceRate, na.rm = TRUE) * 100
    valueBox(
      value = paste0(round(avg, 1), "%"),
      subtitle = "Avg Bounce Rate",
      icon = icon("chart-line"),
      color = "yellow"
    )
  })
  
  output$top_pages_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$page_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$page_data %>%
      arrange(desc(screenPageViews)) %>%
      head(10)
    
    # Shorten page paths for display
    data$shortPath <- substr(data$pagePath, 1, 50)
    
    plot_ly(data, x = ~screenPageViews, y = ~reorder(shortPath, screenPageViews), 
            type = "bar", orientation = "h",
            marker = list(color = "#667eea"),
            text = ~paste("Path:", pagePath, "<br>Views:", screenPageViews),
            hoverinfo = "text") %>%
      layout(
        xaxis = list(title = "Pageviews", color = "#e0e7ff", gridcolor = "#2a5298"),
        yaxis = list(title = "", color = "#e0e7ff"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$landing_pages_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$landing_page_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$landing_page_data %>%
      arrange(desc(sessions)) %>%
      head(10)
    
    data$shortPath <- substr(data$landingPage, 1, 40)
    
    plot_ly(data, x = ~sessions, y = ~reorder(shortPath, sessions), 
            type = "bar", orientation = "h",
            marker = list(color = "#4a90e2")) %>%
      layout(
        xaxis = list(title = "Sessions", color = "#e0e7ff", gridcolor = "#2a5298"),
        yaxis = list(title = "", color = "#e0e7ff"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$page_engagement_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$page_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$page_data %>%
      arrange(desc(screenPageViews)) %>%
      head(10)
    
    data$shortPath <- substr(data$pagePath, 1, 30)
    
    plot_ly(data, x = ~shortPath, y = ~bounceRate * 100, type = "bar",
            name = "Bounce Rate %",
            marker = list(color = "#e74c3c")) %>%
      layout(
        xaxis = list(title = "", color = "#e0e7ff"),
        yaxis = list(title = "Bounce Rate %", color = "#e0e7ff", gridcolor = "#2a5298"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$page_performance_table <- renderDT({
    if (!check_data_loaded() || is.null(ga_data$page_data)) {
      return(datatable(
        data.frame(Message = "No data loaded."),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    datatable(ga_data$page_data,
              options = list(pageLength = 10, scrollX = TRUE),
              class = "display nowrap")
  })
  
  # ============================================================================
  # USER BEHAVIOR TAB
  # ============================================================================
  
  output$new_users <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$user_type_data)) {
      return(valueBox(value = "-", subtitle = "New Users",
                      icon = icon("user-plus"), color = "purple"))
    }
    
    new_users <- ga_data$user_type_data %>%
      filter(newVsReturning == "new") %>%
      summarise(total = sum(newUsers, na.rm = TRUE))
    
    valueBox(
      value = formatC(new_users$total, format = "d", big.mark = ","),
      subtitle = "New Users",
      icon = icon("user-plus"),
      color = "purple"
    )
  })
  
  output$returning_users <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$user_type_data)) {
      return(valueBox(value = "-", subtitle = "Returning Users",
                      icon = icon("user-check"), color = "blue"))
    }
    
    returning <- ga_data$user_type_data %>%
      filter(newVsReturning == "returning") %>%
      summarise(total = sum(activeUsers, na.rm = TRUE))
    
    valueBox(
      value = formatC(returning$total, format = "d", big.mark = ","),
      subtitle = "Returning Users",
      icon = icon("user-check"),
      color = "blue"
    )
  })
  
  output$sessions_per_user <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$overview_data)) {
      return(valueBox(value = "-", subtitle = "Sessions per User",
                      icon = icon("chart-bar"), color = "green"))
    }
    
    avg <- mean(ga_data$overview_data$sessionsPerUser, na.rm = TRUE)
    valueBox(
      value = round(avg, 2),
      subtitle = "Sessions per User",
      icon = icon("chart-bar"),
      color = "green"
    )
  })
  
  output$user_type_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$user_type_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$user_type_data %>%
      filter(newVsReturning != "")
    
    plot_ly(data, labels = ~newVsReturning, values = ~activeUsers, type = "pie",
            marker = list(colors = c("#667eea", "#4a90e2")),
            hole = 0.4) %>%
      layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$hourly_traffic_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$hourly_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$hourly_data
    data$hour <- as.numeric(data$hour)
    data <- data %>% arrange(hour)
    
    plot_ly(data, x = ~hour, y = ~activeUsers, type = "scatter", mode = "lines+markers",
            fill = "tozeroy",
            line = list(color = "#667eea", width = 3),
            marker = list(color = "#667eea", size = 8),
            fillcolor = "rgba(102, 126, 234, 0.3)") %>%
      layout(
        xaxis = list(title = "Hour of Day", color = "#e0e7ff", gridcolor = "#2a5298"),
        yaxis = list(title = "Active Users", color = "#e0e7ff", gridcolor = "#2a5298"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$day_of_week_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$dow_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$dow_data %>%
      arrange(as.numeric(dayOfWeek))
    
    plot_ly(data, x = ~dayOfWeekName, y = ~activeUsers, type = "bar",
            marker = list(color = "#4a90e2")) %>%
      add_trace(y = ~sessions, name = "Sessions", marker = list(color = "#2ecc71")) %>%
      layout(
        xaxis = list(title = "", color = "#e0e7ff"),
        yaxis = list(title = "Count", color = "#e0e7ff", gridcolor = "#2a5298"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff"),
        barmode = "group"
      )
  })
  
  output$user_behavior_table <- renderDT({
    if (!check_data_loaded() || is.null(ga_data$user_type_data)) {
      return(datatable(
        data.frame(Message = "No data loaded."),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    datatable(ga_data$user_type_data,
              options = list(pageLength = 10),
              class = "display nowrap")
  })
  
  # ============================================================================
  # EVENTS TRACKING TAB
  # ============================================================================
  
  output$total_events <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$event_data)) {
      return(valueBox(value = "-", subtitle = "Total Events",
                      icon = icon("bolt"), color = "purple"))
    }
    
    total <- sum(ga_data$event_data$eventCount, na.rm = TRUE)
    valueBox(
      value = formatC(total, format = "d", big.mark = ","),
      subtitle = "Total Events",
      icon = icon("bolt"),
      color = "purple"
    )
  })
  
  output$unique_event_types <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$event_data)) {
      return(valueBox(value = "-", subtitle = "Event Types",
                      icon = icon("list"), color = "blue"))
    }
    
    count <- nrow(ga_data$event_data)
    valueBox(
      value = count,
      subtitle = "Event Types",
      icon = icon("list"),
      color = "blue"
    )
  })
  
  output$events_per_user <- renderValueBox({
    if (!check_data_loaded() || is.null(ga_data$event_data)) {
      return(valueBox(value = "-", subtitle = "Events per User",
                      icon = icon("user"), color = "green"))
    }
    
    avg <- mean(ga_data$event_data$eventCountPerUser, na.rm = TRUE)
    valueBox(
      value = round(avg, 2),
      subtitle = "Events per User",
      icon = icon("user"),
      color = "green"
    )
  })
  
  output$event_distribution_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$event_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$event_data %>%
      arrange(desc(eventCount))
    
    plot_ly(data, x = ~reorder(eventName, eventCount), y = ~eventCount, type = "bar",
            marker = list(color = "#667eea")) %>%
      layout(
        xaxis = list(title = "", color = "#e0e7ff"),
        yaxis = list(title = "Event Count", color = "#e0e7ff", gridcolor = "#2a5298"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$events_by_page_chart <- renderPlotly({
    if (!check_data_loaded() || is.null(ga_data$event_page_data)) {
      return(create_empty_plot())
    }
    
    data <- ga_data$event_page_data %>%
      group_by(pagePath) %>%
      summarise(total = sum(eventCount, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total)) %>%
      head(10)
    
    data$shortPath <- substr(data$pagePath, 1, 40)
    
    plot_ly(data, x = ~total, y = ~reorder(shortPath, total), type = "bar",
            orientation = "h",
            marker = list(color = "#4a90e2")) %>%
      layout(
        xaxis = list(title = "Total Events", color = "#e0e7ff", gridcolor = "#2a5298"),
        yaxis = list(title = "", color = "#e0e7ff"),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = "#e0e7ff")
      )
  })
  
  output$event_details_table <- renderDT({
    if (!check_data_loaded() || is.null(ga_data$event_data)) {
      return(datatable(
        data.frame(Message = "No data loaded."),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    datatable(ga_data$event_data,
              options = list(pageLength = 10),
              class = "display nowrap")
  })
  
  output$event_page_table <- renderDT({
    if (!check_data_loaded() || is.null(ga_data$event_page_data)) {
      return(datatable(
        data.frame(Message = "No data loaded."),
        options = list(dom = 't'),
        rownames = FALSE
      ))
    }
    
    datatable(ga_data$event_page_data,
              options = list(pageLength = 10, scrollX = TRUE),
              class = "display nowrap")
  })
}

# ============================================================================
# RUN THE APPLICATION
# ============================================================================

shinyApp(ui = ui, server = server, options = list(
  port = 1410,
  host = "127.0.0.1"
))