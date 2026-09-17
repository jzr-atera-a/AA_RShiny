# modules/Project Application/claude_diagrams.R
# Subtab: Claude Diagrams - uses the SAME Claude API config as API Settings
# (api_manager$claude_authenticated / api_manager$call_claude()), so nothing
# to configure here beyond API Settings > Claude API Config.

claude_diagrams_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Context Management", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p("Save and load application context for Claude analysis."),
          fluidRow(
            column(6,
                   actionButton(ns("save_context_csv"), "Save Context to CSV", class = "btn-warning", icon = icon("download"),
                                style = "width: 100%; margin-bottom: 10px;"),
                   downloadButton(ns("download_context_csv"), "Download Context CSV", class = "btn-info", style = "width: 100%;")),
            column(6,
                   fileInput(ns("upload_context_csv"), "Load Context CSV:", accept = c(".csv"), placeholder = "Choose CSV file..."),
                   verbatimTextOutput(ns("context_csv_info")))
          ))
    ),
    fluidRow(
      box(title = "Upload Reference File", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p("Upload a file to keep alongside your instructions (supports images, PDFs, documents)."),
          fileInput(ns("claude_diagram_ref_file"), "Select File:", accept = c(".jpg", ".jpeg", ".png", ".gif", ".pdf", ".docx", ".csv", ".txt"),
                    placeholder = "Choose file..."),
          verbatimTextOutput(ns("claude_diagram_file_info")))
    ),
    fluidRow(
      box(title = "Diagram Instructions for Claude", status = "primary", solidHeader = TRUE, width = 12,
          p("Describe the diagram you want Claude to generate."),
          textAreaInput(ns("claude_diagram_instructions"), "Instructions:",
                        placeholder = "Example: Create a comprehensive flowchart analyzing the project lifecycle...",
                        height = "200px", width = "100%"),
          br(),
          selectInput(ns("claude_diagram_type_select"), "Type of Diagram:",
                      choices = c("Flowchart" = "flowchart", "Timeline" = "timeline", "Organizational Chart" = "org_chart",
                                  "Mind Map" = "mindmap", "Architecture" = "architecture", "Data Visualization" = "data_viz"),
                      selected = "flowchart"),
          checkboxInput(ns("claude_use_loaded_context"), "Include loaded context from CSV", value = TRUE))
    ),
    fluidRow(
      box(title = "Output Format for Claude", status = "warning", solidHeader = TRUE, width = 12,
          selectInput(ns("claude_diagram_output_format"), "Output Format:",
                      choices = c("SVG" = "svg", "HTML" = "html", "Mermaid" = "mermaid"), selected = "svg"),
          br(),
          actionButton(ns("generate_claude_diagram_btn"), "Generate with Claude", class = "generate-btn",
                       icon = icon("wand-magic-sparkles"), style = "font-size: 16px; padding: 12px 30px;"))
    ),
    fluidRow(
      box(title = "Claude Generated Diagram", status = "success", solidHeader = TRUE, width = 12,
          uiOutput(ns("claude_diagram_preview_display")),
          hr(),
          h4("Download Options:"),
          fluidRow(
            column(4, downloadButton(ns("download_claude_diagram_main"), "Download", class = "btn-success")),
            column(4, downloadButton(ns("download_claude_diagram_svg"), "Download SVG", class = "btn-info")),
            column(4, downloadButton(ns("download_claude_diagram_html"), "Download HTML", class = "btn-info"))
          ),
          br(),
          h4("Claude Analysis:"),
          verbatimTextOutput(ns("claude_diagram_analysis")),
          br(),
          uiOutput(ns("claude_diagram_status_ui")))
    )
  )
}

claude_diagrams_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    values <- reactiveValues(context_data = NULL, diagram_code = NULL, diagram_type = NULL, analysis = NULL)

    observeEvent(input$claude_diagram_ref_file, {
      req(input$claude_diagram_ref_file)
      output$claude_diagram_file_info <- renderText(
        preview_uploaded_file(input$claude_diagram_ref_file$datapath, input$claude_diagram_ref_file$name)
      )
    })

    observeEvent(input$save_context_csv, {
      values$context_data <- data.frame(Section = "Overview", Content = "Application context saved", stringsAsFactors = FALSE)
      showNotification("Context prepared for download", type = "message", duration = 3)
    })

    output$download_context_csv <- downloadHandler(
      filename = function() paste0("context_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
      content = function(file) if (!is.null(values$context_data)) write.csv(values$context_data, file, row.names = FALSE)
    )

    observeEvent(input$upload_context_csv, {
      req(input$upload_context_csv)
      tryCatch({
        values$context_data <- read.csv(input$upload_context_csv$datapath, stringsAsFactors = FALSE)
        output$context_csv_info <- renderText(paste0("Loaded: ", nrow(values$context_data), " sections\nReady for diagram generation"))
        showNotification("Context loaded successfully!", type = "message", duration = 3)
      }, error = function(e) {
        showNotification(paste("Error loading context:", e$message), type = "error", duration = 5)
      })
    })

    observeEvent(input$generate_claude_diagram_btn, {
      req(input$claude_diagram_instructions)
      if (nchar(trimws(input$claude_diagram_instructions)) < 20) {
        showNotification("Please provide more detailed instructions", type = "warning", duration = 3)
        return()
      }
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure Claude API first (API Settings > Claude API Config)!", type = "error", duration = 5)
        return()
      }

      showNotification("Generating diagram with Claude...", type = "message", duration = NULL, id = "gen_claude")

      context_text <- ""
      if (isTRUE(input$claude_use_loaded_context) && !is.null(values$context_data)) {
        context_text <- paste0("Context:\n", paste(values$context_data$Section, values$context_data$Content, sep = ": ", collapse = "\n"))
      }

      prompt <- paste0(context_text, "\n\n",
                        "Generate a ", input$claude_diagram_type_select, " diagram as ", input$claude_diagram_output_format,
                        " code based on: ", input$claude_diagram_instructions, ". Return ONLY the code, no explanations.")

      result <- tryCatch(api_manager$call_claude(prompt, max_tokens = 1200)$text, error = function(e) {
        showNotification(paste("Claude error:", e$message), type = "error", duration = 8); NULL
      })
      removeNotification(id = "gen_claude")

      if (!is.null(result)) {
        values$diagram_code <- result
        values$diagram_type <- input$claude_diagram_output_format
        values$analysis <- "Diagram generated successfully by Claude"

        output$claude_diagram_preview_display <- renderUI({
          if (input$claude_diagram_output_format == "svg") {
            tags$div(style = "border: 2px solid #4a90e2; padding: 20px; background: white; border-radius: 8px;", HTML(result))
          } else if (input$claude_diagram_output_format == "html") {
            tags$iframe(srcdoc = result, width = "100%", height = "600px", style = "border: 2px solid #4a90e2; border-radius: 8px;")
          } else {
            tags$div(tags$script(src = "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"),
                      tags$div(class = "mermaid", result))
          }
        })

        output$claude_diagram_analysis <- renderText(values$analysis)
        output$claude_diagram_status_ui <- renderUI(create_status_ui(TRUE, " Diagram generated successfully by Claude!"))
        showNotification("Claude diagram generated!", type = "message", duration = 5)
      } else {
        output$claude_diagram_status_ui <- renderUI(create_status_ui(FALSE, " Failed to generate diagram"))
      }
    })

    output$download_claude_diagram_main <- downloadHandler(
      filename = function() paste0("claude_diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".", values$diagram_type),
      content = function(file) if (!is.null(values$diagram_code)) writeLines(values$diagram_code, file)
    )
    output$download_claude_diagram_svg <- downloadHandler(
      filename = function() paste0("claude_diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".svg"),
      content = function(file) if (!is.null(values$diagram_code)) writeLines(values$diagram_code, file)
    )
    output$download_claude_diagram_html <- downloadHandler(
      filename = function() paste0("claude_diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".html"),
      content = function(file) if (!is.null(values$diagram_code)) writeLines(values$diagram_code, file)
    )

    output$claude_diagram_file_info <- renderText("")
    output$context_csv_info <- renderText("")
    output$claude_diagram_analysis <- renderText("")
    output$claude_diagram_status_ui <- renderUI({ tags$div() })
  })
}
