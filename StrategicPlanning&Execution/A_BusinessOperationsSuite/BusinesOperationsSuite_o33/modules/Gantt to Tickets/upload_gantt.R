# modules/Gantt to Tickets/upload_gantt.R
# Subtab: Upload Gantt Chart

upload_gantt_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Upload Excel File", status = "primary", solidHeader = TRUE, width = 12,
          fileInput(ns("gantt_file"), "Choose Excel File (.xlsx or .xls)", accept = c(".xlsx", ".xls")),
          hr(),
          h4("Expected Excel Format:"),
          p("Your Excel file should contain the following columns:"),
          tags$ul(
            tags$li(tags$strong("Task_Name"), " - Name of the task (required)"),
            tags$li(tags$strong("Description"), " - Detailed description of the task (optional)"),
            tags$li(tags$strong("Start_Date"), " - Start date (format: YYYY-MM-DD or MM/DD/YYYY)"),
            tags$li(tags$strong("End_Date"), " - End date (format: YYYY-MM-DD or MM/DD/YYYY)"),
            tags$li(tags$strong("Duration_Days"), " - Duration in days (optional if dates provided)"),
            tags$li(tags$strong("Assignee"), " - Person assigned to task (optional)"),
            tags$li(tags$strong("Priority"), " - High/Medium/Low (optional)"),
            tags$li(tags$strong("Status"), " - To Do/In Progress/Done (optional)"),
            tags$li(tags$strong("Labels"), " - Comma-separated tags (optional)")
          ),
          downloadButton(ns("download_template"), "Download Excel Template"))
    ),
    fluidRow(
      box(title = "Preview Uploaded Data", status = "info", solidHeader = TRUE, width = 12,
          DT::dataTableOutput(ns("preview_table")))
    )
  )
}

upload_gantt_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    output$download_template <- downloadHandler(
      filename = function() paste("gantt_template_", Sys.Date(), ".xlsx", sep = ""),
      content = function(file) {
        template_data <- data.frame(
          Task_Name = c("Project Setup", "Research Phase", "Development Sprint 1", "Testing", "Deployment"),
          Description = c("Initial project configuration and setup", "Market research and requirements gathering",
                          "Core feature development", "QA testing and bug fixes", "Production deployment"),
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

    observeEvent(input$gantt_file, {
      req(input$gantt_file)
      tryCatch({
        api_manager$gantt_data <- readxl::read_excel(input$gantt_file$datapath)
        names(api_manager$gantt_data) <- gsub(" ", "_", names(api_manager$gantt_data))

        output$preview_table <- DT::renderDataTable({
          DT::datatable(api_manager$gantt_data, options = list(scrollX = TRUE, pageLength = 10))
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
  })
}
