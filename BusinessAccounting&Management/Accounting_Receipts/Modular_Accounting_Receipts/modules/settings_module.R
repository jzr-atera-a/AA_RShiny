# Settings Module

settingsUI <- function(id) {
  ns <- NS(id)
  
  fluidRow(
    box(
      title = "API Configuration",
      status = "warning",
      solidHeader = TRUE,
      width = 12,
      passwordInput(
        ns("api_key"),
        "OpenAI API Key:",
        placeholder = "Enter your API key (starts with sk-proj-... or sk-...)"
      ),
      p(strong("Get your API key from:"), " https://platform.openai.com/api-keys"),
      hr(),
      textInput(
        ns("receipts_folder"),
        "Receipts Storage Folder:",
        value = "receipts"
      ),
      textInput(
        ns("excel_filename"),
        "Excel Output Filename:",
        value = "receipt_data.xlsx"
      ),
      hr(),
      actionButton(ns("save_settings"), "Save Settings", class = "btn-success", icon = icon("save")),
      actionButton(ns("test_api"), "Test API Connection", class = "btn-info", icon = icon("flask")),
      hr(),
      verbatimTextOutput(ns("settings_status")),
      hr(),
      uiOutput(ns("test_result"))
    )
  )
}

settingsServer <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    
    # Save settings
    observeEvent(input$save_settings, {
      # Trim whitespace from API key
      shared_rv$api_key <- trimws(input$api_key)
      shared_rv$receipts_folder <- input$receipts_folder
      shared_rv$excel_filename <- input$excel_filename
      
      # Validate API key format for OpenAI
      api_key_valid <- nchar(shared_rv$api_key) > 0 && grepl("^sk-", shared_rv$api_key)
      
      # Create folder if it doesn't exist
      if (!dir.exists(shared_rv$receipts_folder)) {
        dir.create(shared_rv$receipts_folder, recursive = TRUE)
      }
      
      # Display status
      output$settings_status <- renderText({
        paste0("Settings saved successfully!\n",
               "API Key: ", ifelse(nchar(shared_rv$api_key) > 0, 
                                   ifelse(api_key_valid, "Set ✓", "Set (Warning: should start with 'sk-')"), 
                                   "Not Set ✗"), "\n",
               "Receipts Folder: ", shared_rv$receipts_folder, "\n",
               "Excel Filename: ", shared_rv$excel_filename, "\n",
               "Last Updated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
      })
      
      # Show notification
      if (!api_key_valid && nchar(shared_rv$api_key) > 0) {
        showNotification("Warning: API key should start with 'sk-'", type = "warning", duration = 5)
      } else if (api_key_valid) {
        showNotification("Settings saved successfully! You can now test the API connection or process receipts.", 
                         type = "message", duration = 3)
      }
    })
    
    # Test API Connection
    observeEvent(input$test_api, {
      if (is.null(shared_rv$api_key) || nchar(shared_rv$api_key) == 0) {
        output$test_result <- renderUI({
          tags$div(
            class = "alert alert-danger",
            tags$strong("Error: "),
            "Please enter and save your API key first."
          )
        })
        return()
      }
      
      # Show testing message
      output$test_result <- renderUI({
        tags$div(
          class = "alert alert-info",
          tags$strong("Testing... "),
          "Connecting to OpenAI API..."
        )
      })
      
      # Test API
      result <- test_api_connection(shared_rv$api_key)
      
      if (result$success) {
        output$test_result <- renderUI({
          tags$div(
            class = "alert alert-success",
            HTML(result$message)
          )
        })
        showNotification("API test successful!", type = "message", duration = 3)
      } else {
        output$test_result <- renderUI({
          tags$div(
            class = "alert alert-danger",
            HTML(result$message)
          )
        })
      }
    })
    
  })
}
