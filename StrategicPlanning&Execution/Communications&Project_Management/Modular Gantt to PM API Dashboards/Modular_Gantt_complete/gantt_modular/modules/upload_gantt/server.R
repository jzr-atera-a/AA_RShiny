# modules/upload_gantt/server.R
# Upload Gantt Chart Server Logic
# ================================

upload_gantt_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Download Excel Template
    output$download_template <- downloadHandler(
      filename = function() {
        paste("gantt_template_", Sys.Date(), ".xlsx", sep = "")
      },
      content = function(file) {
        # Create sample template
        template_data <- data.frame(
          Task_Name = c("Project Setup", "Research Phase", "Development Sprint 1", "Testing", "Deployment"),
          Description = c(
            "Initial project configuration and setup",
            "Market research and requirements gathering",
            "Core feature development",
            "QA testing and bug fixes",
            "Production deployment"
          ),
          Start_Date = c("2025-01-15", "2025-01-20", "2025-02-01", "2025-02-20", "2025-03-01"),
          End_Date = c("2025-01-19", "2025-01-31", "2025-02-19", "2025-02-28", "2025-03-05"),
          Duration_Days = c(5, 12, 19, 9, 5),
          Assignee = c("John Doe", "Jane Smith", "Dev Team", "QA Team", "DevOps"),
          Priority = c("High", "High", "Medium", "High", "High"),
          Status = c("To Do", "To Do", "To Do", "To Do", "To Do"),
          Labels = c("setup,planning", "research", "development,sprint", "testing,qa", "deployment,production"),
          stringsAsFactors = FALSE
        )
        writexl::write_xlsx(template_data, file)
      }
    )
    
    # Load and preview Gantt data
    observeEvent(input$gantt_file, {
      req(input$gantt_file)
      
      tryCatch({
        api_manager$gantt_data <- readxl::read_excel(input$gantt_file$datapath)
        
        # Standardize column names
        names(api_manager$gantt_data) <- gsub(" ", "_", names(api_manager$gantt_data))
        
        output$preview_table <- DT::renderDataTable({
          DT::datatable(api_manager$gantt_data, 
                        options = list(scrollX = TRUE, pageLength = 10))
        })
        
        # Trigger state update so other modules know data is loaded
        api_manager$trigger_state_update()
        
        showNotification("File loaded successfully!", type = "message")
        
      }, error = function(e) {
        showNotification(paste("Error reading file:", e$message), type = "error")
      })
    })
    
    # Default output
    output$preview_table <- DT::renderDataTable({
      DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE)
    })
  })
}
