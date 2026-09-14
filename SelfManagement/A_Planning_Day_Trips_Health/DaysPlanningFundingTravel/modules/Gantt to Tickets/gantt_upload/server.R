# modules/Gantt to Tickets/gantt_upload/server.R

gantt_upload_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    output$download_template <- downloadHandler(
      filename = function() paste("gantt_template_", Sys.Date(), ".xlsx", sep = ""),
      content = function(file) {
        template_data <- data.frame(
          Task_Name = c("Project Setup", "Research Phase", "Development Sprint 1", "Testing", "Deployment"),
          Description = c("Initial project configuration and setup", "Market research and requirements gathering",
                          "Core feature development", "QA testing and bug fixes", "Production deployment"),
          Start_Date = c("2026-01-15", "2026-01-20", "2026-02-01", "2026-02-20", "2026-03-01"),
          End_Date = c("2026-01-19", "2026-01-31", "2026-02-19", "2026-02-28", "2026-03-05"),
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

    observeEvent(input$gantt_file, {
      req(input$gantt_file)
      tryCatch({
        loaded <- readxl::read_excel(input$gantt_file$datapath)
        names(loaded) <- gsub(" ", "_", names(loaded))
        api_manager$gantt_tasks_data <- as.data.frame(loaded, stringsAsFactors = FALSE)

        output$preview_table <- DT::renderDataTable({
          DT::datatable(api_manager$gantt_tasks_data, options = list(scrollX = TRUE, pageLength = 10))
        })

        api_manager$trigger_state_update_gantt()
        showNotification("File loaded successfully!", type = "message")

      }, error = function(e) {
        showNotification(paste("Error reading file:", e$message), type = "error")
      })
    })

    output$preview_table <- DT::renderDataTable({
      DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE)
    })

    session$onSessionEnded(function() {})
  })
}
