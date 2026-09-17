# modules/Project Application/diagram_generator.R
# Subtab: Diagram Generator (ChatGPT-based)

diagram_generator_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Upload Reference File", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p("Upload a reference file to keep alongside your instructions (optional)."),
          fileInput(ns("diagram_ref_file"), "Select File:", accept = c(".jpg", ".jpeg", ".png", ".svg", ".pdf", ".docx", ".csv"),
                    placeholder = "Choose file..."),
          verbatimTextOutput(ns("diagram_file_info")))
    ),
    fluidRow(
      box(title = "Diagram Instructions", status = "primary", solidHeader = TRUE, width = 12,
          p("Describe the diagram you want ChatGPT to generate."),
          textAreaInput(ns("diagram_instructions"), "Instructions:",
                        placeholder = "Example: Create a flowchart showing the 5 phases of our project...",
                        height = "200px", width = "100%"),
          br(),
          selectInput(ns("diagram_type_select"), "Type of Diagram:",
                      choices = c("Flowchart" = "flowchart", "Timeline" = "timeline", "Organizational Chart" = "org_chart",
                                  "Mind Map" = "mindmap", "Network Diagram" = "network", "Bar Chart" = "bar"),
                      selected = "flowchart"))
    ),
    fluidRow(
      box(title = "Output Format", status = "warning", solidHeader = TRUE, width = 12,
          selectInput(ns("diagram_output_format"), "Output Format:",
                      choices = c("SVG (Vector)" = "svg", "HTML (Interactive)" = "html", "Mermaid" = "mermaid"), selected = "svg"),
          br(),
          actionButton(ns("generate_diagram_btn"), "Generate with ChatGPT", class = "generate-btn",
                       icon = icon("wand-magic-sparkles"), style = "font-size: 16px; padding: 12px 30px;"))
    ),
    fluidRow(
      box(title = "Generated Diagram", status = "success", solidHeader = TRUE, width = 12,
          uiOutput(ns("diagram_preview_display")),
          hr(),
          h4("Download Options:"),
          fluidRow(
            column(4, downloadButton(ns("download_diagram_main"), "Download", class = "btn-success")),
            column(4, downloadButton(ns("download_diagram_svg"), "Download SVG", class = "btn-info")),
            column(4, downloadButton(ns("download_diagram_html"), "Download HTML", class = "btn-info"))
          ),
          br(),
          uiOutput(ns("diagram_status_ui")))
    )
  )
}

diagram_generator_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    values <- reactiveValues(diagram_code = NULL, diagram_type = NULL)

    observeEvent(input$diagram_ref_file, {
      req(input$diagram_ref_file)
      output$diagram_file_info <- renderText(preview_uploaded_file(input$diagram_ref_file$datapath, input$diagram_ref_file$name))
    })

    observeEvent(input$generate_diagram_btn, {
      req(input$diagram_instructions)
      if (nchar(trimws(input$diagram_instructions)) < 20) {
        showNotification("Please provide more detailed instructions", type = "warning", duration = 3)
        return()
      }
      if (!api_manager$openai_authenticated) {
        showNotification("Please configure OpenAI API first (Project Application > OpenAI API Config)!", type = "error", duration = 5)
        return()
      }

      showNotification("Generating diagram...", type = "message", duration = NULL, id = "gen_diagram")

      prompt <- paste0("Generate a ", input$diagram_type_select, " diagram as ", input$diagram_output_format,
                        " code based on: ", input$diagram_instructions, ". Return ONLY the code, no explanations.")

      result <- tryCatch(api_manager$call_openai(prompt, max_tokens = 1000)$text, error = function(e) {
        showNotification(paste("OpenAI error:", e$message), type = "error", duration = 8); NULL
      })
      removeNotification(id = "gen_diagram")

      if (!is.null(result)) {
        values$diagram_code <- result
        values$diagram_type <- input$diagram_output_format

        output$diagram_preview_display <- renderUI({
          if (input$diagram_output_format == "svg") {
            tags$div(style = "border: 2px solid #4a90e2; padding: 20px; background: white; border-radius: 8px;", HTML(result))
          } else if (input$diagram_output_format == "html") {
            tags$iframe(srcdoc = result, width = "100%", height = "600px", style = "border: 2px solid #4a90e2; border-radius: 8px;")
          } else {
            tags$div(tags$script(src = "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"),
                      tags$div(class = "mermaid", result))
          }
        })

        output$diagram_status_ui <- renderUI(create_status_ui(TRUE, " Diagram generated successfully!"))
        showNotification("Diagram generated!", type = "message", duration = 5)
      } else {
        output$diagram_status_ui <- renderUI(create_status_ui(FALSE, " Failed to generate diagram"))
      }
    })

    output$download_diagram_main <- downloadHandler(
      filename = function() paste0("diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".", values$diagram_type),
      content = function(file) if (!is.null(values$diagram_code)) writeLines(values$diagram_code, file)
    )
    output$download_diagram_svg <- downloadHandler(
      filename = function() paste0("diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".svg"),
      content = function(file) if (!is.null(values$diagram_code)) writeLines(values$diagram_code, file)
    )
    output$download_diagram_html <- downloadHandler(
      filename = function() paste0("diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".html"),
      content = function(file) if (!is.null(values$diagram_code)) writeLines(values$diagram_code, file)
    )

    output$diagram_file_info <- renderText("")
    output$diagram_status_ui <- renderUI({ tags$div() })
  })
}
