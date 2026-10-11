# modules/Receipt Processor/receipt_settings.R
# Subtab: Settings

receipt_settings_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    box(title = "API Configuration", status = "warning", solidHeader = TRUE, width = 12,
        passwordInput(ns("api_key"), "OpenAI API Key:", placeholder = "Enter your API key (starts with sk-proj-... or sk-...)"),
        p(strong("Get your API key from:"), " https://platform.openai.com/api-keys"),
        hr(),
        textInput(ns("receipts_folder"), "Receipts Storage Folder:", value = "receipts"),
        textInput(ns("excel_filename"), "Excel Output Filename:", value = "receipt_data.xlsx"),
        hr(),
        actionButton(ns("save_settings"), "Save Settings", class = "btn-success", icon = icon("save")),
        actionButton(ns("test_api"), "Test API Connection", class = "btn-info", icon = icon("flask")),
        hr(),
        verbatimTextOutput(ns("settings_status")),
        hr(),
        uiOutput(ns("test_result")))
  )
}

receipt_settings_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$save_settings, {
      api_manager$receipt_api_key <- trimws(input$api_key)
      api_manager$receipt_folder <- input$receipts_folder
      api_manager$receipt_excel_filename <- input$excel_filename

      api_key_valid <- nchar(api_manager$receipt_api_key) > 0 && grepl("^sk-", api_manager$receipt_api_key)

      if (!dir.exists(api_manager$receipt_folder)) dir.create(api_manager$receipt_folder, recursive = TRUE)
      if (!file.exists(api_manager$receipt_excel_filename)) api_manager$init_receipt_storage()

      output$settings_status <- renderText({
        paste0("Settings saved successfully!\n",
               "API Key: ", ifelse(nchar(api_manager$receipt_api_key) > 0,
                                   ifelse(api_key_valid, "Set ✓", "Set (Warning: should start with 'sk-')"),
                                   "Not Set ✗"), "\n",
               "Receipts Folder: ", api_manager$receipt_folder, "\n",
               "Excel Filename: ", api_manager$receipt_excel_filename, "\n",
               "Last Updated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
      })

      if (!api_key_valid && nchar(api_manager$receipt_api_key) > 0) {
        showNotification("Warning: API key should start with 'sk-'", type = "warning", duration = 5)
      } else if (api_key_valid) {
        showNotification("Settings saved successfully! You can now test the API connection or process receipts.",
                         type = "message", duration = 3)
      }
    })

    observeEvent(input$test_api, {
      if (nchar(api_manager$receipt_api_key) == 0) {
        output$test_result <- renderUI(tags$div(class = "alert alert-danger", tags$strong("Error: "), "Please enter and save your API key first."))
        return()
      }

      output$test_result <- renderUI(tags$div(class = "alert alert-info", tags$strong("Testing... "), "Connecting to OpenAI API..."))

      result <- api_manager$test_receipt_api_connection()

      if (result$success) {
        output$test_result <- renderUI(tags$div(class = "alert alert-success", HTML(result$message)))
        showNotification("API test successful!", type = "message", duration = 3)
      } else {
        output$test_result <- renderUI(tags$div(class = "alert alert-danger", HTML(result$message)))
      }
    })

    output$settings_status <- renderText("")
    output$test_result <- renderUI({ tags$div() })
  })
}
