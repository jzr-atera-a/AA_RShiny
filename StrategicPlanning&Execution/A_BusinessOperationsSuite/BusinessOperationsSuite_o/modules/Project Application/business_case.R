# modules/Project Application/business_case.R
# Subtab: Business Case (5 AI-assisted sections + Excel export)

business_case_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Word Limits Configuration - Business Case", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p("Set word limits for each section."),
          column(2, numericInput(ns("word_limit_bc1"), "Problem:", value = 500, min = 50, max = 2000)),
          column(2, numericInput(ns("word_limit_bc2"), "CAM Service:", value = 500, min = 50, max = 2000)),
          column(2, numericInput(ns("word_limit_bc3"), "Readiness:", value = 500, min = 50, max = 2000)),
          column(2, numericInput(ns("word_limit_bc4"), "Feasibility:", value = 500, min = 50, max = 2000)),
          column(2, numericInput(ns("word_limit_bc5"), "Commercialisation:", value = 400, min = 50, max = 2000)))
    ),
    fluidRow(
      box(title = "9. Problem, Opportunity and Market Potential", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Problem & Market"),
          div(class = "question-help", "What is the size and timing of the opportunity?"),
          textAreaInput(ns("main_ideas_bc1"), "Main Ideas:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_bc1"), "Generate with ChatGPT (with context)", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("problem_opportunity"), "Generated Response:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_bc1"))))
    ),
    fluidRow(
      box(title = "10. Proposed CAM Service", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "CAM Service & Value Proposition"),
          div(class = "question-help", "Why is this the right service in the right location?"),
          textAreaInput(ns("main_ideas_bc2"), "Main Ideas:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_bc2"), "Generate with ChatGPT (with context)", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("cam_service"), "Generated Response:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_bc2"))))
    ),
    fluidRow(
      box(title = "11. Readiness, Stakeholders and Regulatory", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Readiness & Regulatory Compliance"),
          div(class = "question-help", "How ready is your current business case?"),
          textAreaInput(ns("main_ideas_bc3"), "Main Ideas:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_bc3"), "Generate with ChatGPT (with context)", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("readiness"), "Generated Response:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_bc3"))))
    ),
    fluidRow(
      box(title = "12. Feasibility Study Plan", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Feasibility Study Plan"),
          div(class = "question-help", "What will your study deliver?"),
          textAreaInput(ns("main_ideas_bc4"), "Main Ideas:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_bc4"), "Generate with ChatGPT (with context)", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("feasibility"), "Generated Response:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_bc4"))))
    ),
    fluidRow(
      box(title = "13. Commercialisation Roadmap", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Commercialisation & KPIs"),
          div(class = "question-help", "What happens after the feasibility study?"),
          textAreaInput(ns("main_ideas_bc5"), "Main Ideas:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_bc5"), "Generate with ChatGPT (with context)", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("commercialisation"), "Generated Response:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_bc5"))))
    ),
    fluidRow(
      box(title = "Save Business Case", status = "success", solidHeader = TRUE, width = 12,
          p("Save business case to Excel file on the server."),
          textInput(ns("file_path_bc"), "Excel File Path:", value = "project_application.xlsx"),
          actionButton(ns("save_business_case"), "Save to Excel", class = "save-btn", icon = icon("file-excel")),
          br(), br(),
          uiOutput(ns("save_bc_status_ui")))
    )
  )
}

business_case_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    call_chatgpt_with_context <- function(prompt, word_limit) {
      if (!api_manager$openai_authenticated) {
        showNotification("Please configure OpenAI API first (Project Application > OpenAI API Config)!", type = "error", duration = 5)
        return(NULL)
      }
      tryCatch(
        api_manager$call_openai(prompt, max_tokens = as.integer(word_limit) * 2)$text,
        error = function(e) { showNotification(paste("OpenAI error:", e$message), type = "error", duration = 8); NULL }
      )
    }

    make_generate_handler <- function(suffix, target_id, label) {
      observeEvent(input[[paste0("generate_bc", suffix)]], {
        idea_text <- input[[paste0("main_ideas_bc", suffix)]]
        req(idea_text)
        if (nchar(trimws(idea_text)) < 10) { showNotification("Please enter more details", type = "warning", duration = 3); return() }

        limit <- input[[paste0("word_limit_bc", suffix)]]
        prompt <- paste0("Write ", label, " (", limit, " words): ", idea_text)
        showNotification("Generating...", type = "message", duration = NULL, id = paste0("gen_bc", suffix))
        result <- call_chatgpt_with_context(prompt, limit)
        removeNotification(id = paste0("gen_bc", suffix))
        if (!is.null(result)) updateTextAreaInput(session, target_id, value = result)
      })
    }

    make_generate_handler(1, "problem_opportunity", "problem & market analysis")
    make_generate_handler(2, "cam_service", "CAM service description")
    make_generate_handler(3, "readiness", "readiness assessment")
    make_generate_handler(4, "feasibility", "feasibility study plan")
    make_generate_handler(5, "commercialisation", "commercialisation roadmap")

    output$word_count_bc1 <- renderText(format_word_count(input$problem_opportunity, input$word_limit_bc1))
    output$word_count_bc2 <- renderText(format_word_count(input$cam_service, input$word_limit_bc2))
    output$word_count_bc3 <- renderText(format_word_count(input$readiness, input$word_limit_bc3))
    output$word_count_bc4 <- renderText(format_word_count(input$feasibility, input$word_limit_bc4))
    output$word_count_bc5 <- renderText(format_word_count(input$commercialisation, input$word_limit_bc5))

    observeEvent(input$save_business_case, {
      req(input$file_path_bc)
      tryCatch({
        data <- data.frame(
          Section = c("Problem", "CAM Service", "Readiness", "Feasibility", "Commercialisation"),
          Content = c(input$problem_opportunity, input$cam_service, input$readiness, input$feasibility, input$commercialisation),
          Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          stringsAsFactors = FALSE
        )
        file_path <- normalizePath(input$file_path_bc, mustWork = FALSE)

        if (file.exists(file_path)) {
          wb <- openxlsx::loadWorkbook(file_path)
          if ("Business_Case" %in% names(wb)) openxlsx::removeWorksheet(wb, "Business_Case")
          openxlsx::addWorksheet(wb, "Business_Case")
          openxlsx::writeData(wb, "Business_Case", data)
          openxlsx::saveWorkbook(wb, file_path, overwrite = TRUE)
        } else {
          wb <- openxlsx::createWorkbook()
          openxlsx::addWorksheet(wb, "Business_Case")
          openxlsx::writeData(wb, "Business_Case", data)
          openxlsx::saveWorkbook(wb, file_path)
        }

        output$save_bc_status_ui <- renderUI(create_status_ui(TRUE, " Saved successfully!"))
        showNotification("Business Case saved!", type = "message", duration = 5)
      }, error = function(e) {
        output$save_bc_status_ui <- renderUI(create_status_ui(FALSE, paste(" Error:", e$message)))
      })
    })

    output$save_bc_status_ui <- renderUI({ tags$div() })
  })
}
