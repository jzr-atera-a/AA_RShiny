# Load required libraries
library(shiny)
library(DT)
library(shinydashboard)

# Function to get comprehensive OS information
get_os_info <- function() {
  
  # Basic system information
  os_info <- list(
    "Operating System" = Sys.info()["sysname"],
    "OS Release" = Sys.info()["release"],
    "OS Version" = Sys.info()["version"],
    "Machine Type" = Sys.info()["machine"],
    "Node Name" = Sys.info()["nodename"],
    "User" = Sys.info()["user"],
    "R Version" = R.version.string,
    "Platform" = R.version$platform,
    "Architecture" = R.version$arch
  )
  
  # Additional system details
  tryCatch({
    os_info[["Locale"]] <- Sys.getlocale()
    os_info[["Time Zone"]] <- Sys.timezone()
    os_info[["Current Time"]] <- Sys.time()
    os_info[["Working Directory"]] <- getwd()
    os_info[["Home Directory"]] <- Sys.getenv("HOME")
    os_info[["Temporary Directory"]] <- tempdir()
  }, error = function(e) {
    # Handle any errors gracefully
  })
  
  # Memory information (if available)
  tryCatch({
    if (.Platform$OS.type == "unix") {
      # Try to get memory info on Unix-like systems
      mem_info <- system("free -h 2>/dev/null || vm_stat 2>/dev/null || echo 'Memory info not available'", intern = TRUE)
      if (length(mem_info) > 1) {
        os_info[["Memory Info"]] <- paste(mem_info, collapse = "\n")
      }
    } else if (.Platform$OS.type == "windows") {
      # Try to get memory info on Windows
      mem_info <- system('wmic computersystem get TotalPhysicalMemory /value 2>nul', intern = TRUE)
      if (length(mem_info) > 0) {
        os_info[["Memory Info"]] <- paste(mem_info, collapse = "\n")
      }
    }
  }, error = function(e) {
    os_info[["Memory Info"]] <- "Memory information not available"
  })
  
  # CPU information
  tryCatch({
    if (.Platform$OS.type == "unix") {
      cpu_info <- system("nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 'CPU count not available'", intern = TRUE)
      os_info[["CPU Cores"]] <- cpu_info[1]
    } else if (.Platform$OS.type == "windows") {
      os_info[["CPU Cores"]] <- Sys.getenv("NUMBER_OF_PROCESSORS")
    }
  }, error = function(e) {
    os_info[["CPU Cores"]] <- "CPU information not available"
  })
  
  # Environment variables (selected important ones)
  important_env_vars <- c("PATH", "SHELL", "TERM", "LANG", "LC_ALL", "PROCESSOR_ARCHITECTURE", "COMPUTERNAME", "USERNAME")
  for (var in important_env_vars) {
    env_val <- Sys.getenv(var)
    if (env_val != "") {
      os_info[[paste0("ENV: ", var)]] <- env_val
    }
  }
  
  return(os_info)
}

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Operating System Information"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("System Overview", tabName = "overview", icon = icon("desktop")),
      menuItem("Detailed Info", tabName = "details", icon = icon("list")),
      menuItem("Environment Variables", tabName = "env", icon = icon("cogs"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # System Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "System Summary", status = "primary", solidHeader = TRUE, width = 12,
                  verbatimTextOutput("system_summary")
                )
              ),
              fluidRow(
                box(
                  title = "Platform Details", status = "info", solidHeader = TRUE, width = 6,
                  verbatimTextOutput("platform_info")
                ),
                box(
                  title = "User & Directories", status = "success", solidHeader = TRUE, width = 6,
                  verbatimTextOutput("user_info")
                )
              )
      ),
      
      # Detailed Info Tab
      tabItem(tabName = "details",
              fluidRow(
                box(
                  title = "Complete System Information", status = "primary", solidHeader = TRUE, width = 12,
                  DT::dataTableOutput("detailed_table")
                )
              )
      ),
      
      # Environment Variables Tab
      tabItem(tabName = "env",
              fluidRow(
                box(
                  title = "Environment Variables", status = "warning", solidHeader = TRUE, width = 12,
                  DT::dataTableOutput("env_table")
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Get OS information once when the app starts
  os_data <- reactive({
    get_os_info()
  })
  
  # System Summary
  output$system_summary <- renderText({
    data <- os_data()
    paste0(
      "Operating System: ", data[["Operating System"]], "\n",
      "Version: ", data[["OS Version"]], "\n",
      "Architecture: ", data[["Architecture"]], "\n",
      "R Version: ", data[["R Version"]], "\n",
      "Current Time: ", data[["Current Time"]]
    )
  })
  
  # Platform Information
  output$platform_info <- renderText({
    data <- os_data()
    paste0(
      "Platform: ", data[["Platform"]], "\n",
      "Machine: ", data[["Machine Type"]], "\n",
      "Node Name: ", data[["Node Name"]], "\n",
      "CPU Cores: ", data[["CPU Cores"]]
    )
  })
  
  # User Information
  output$user_info <- renderText({
    data <- os_data()
    paste0(
      "User: ", data[["User"]], "\n",
      "Home Directory: ", data[["Home Directory"]], "\n",
      "Working Directory: ", data[["Working Directory"]], "\n",
      "Temp Directory: ", data[["Temporary Directory"]], "\n",
      "Time Zone: ", data[["Time Zone"]]
    )
  })
  
  # Detailed Table
  output$detailed_table <- DT::renderDataTable({
    data <- os_data()
    
    # Convert to data frame for better display
    df <- data.frame(
      Property = names(data),
      Value = unlist(data),
      stringsAsFactors = FALSE
    )
    
    # Filter out environment variables for this table
    df <- df[!grepl("^ENV:", df$Property), ]
    
    DT::datatable(df, 
                  options = list(pageLength = 15, scrollX = TRUE),
                  rownames = FALSE)
  })
  
  # Environment Variables Table
  output$env_table <- DT::renderDataTable({
    data <- os_data()
    
    # Extract only environment variables
    env_data <- data[grepl("^ENV:", names(data))]
    
    if (length(env_data) > 0) {
      df <- data.frame(
        Variable = gsub("^ENV: ", "", names(env_data)),
        Value = unlist(env_data),
        stringsAsFactors = FALSE
      )
    } else {
      df <- data.frame(
        Variable = "No environment variables captured",
        Value = "",
        stringsAsFactors = FALSE
      )
    }
    
    DT::datatable(df, 
                  options = list(pageLength = 15, scrollX = TRUE),
                  rownames = FALSE)
  })
}

# Run the app
shinyApp(ui = ui, server = server)