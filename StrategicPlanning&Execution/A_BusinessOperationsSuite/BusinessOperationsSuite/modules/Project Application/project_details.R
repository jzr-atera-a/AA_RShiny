# modules/Project Application/project_details.R
# Subtab: Project Details (3 AI-assisted sections + Excel export)

project_details_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Word Limits Configuration", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p("Set the word limit for each section."),
          column(4, numericInput(ns("word_limit_1"), "Summary Word Limit:", value = 400, min = 50, max = 2000, step = 50)),
          column(4, numericInput(ns("word_limit_2"), "Description Word Limit:", value = 400, min = 50, max = 2000, step = 50)),
          column(4, numericInput(ns("word_limit_3"), "Scope Word Limit:", value = 400, min = 50, max = 2000, step = 50)))
    ),
    fluidRow(
      box(title = "1. Project Summary", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Project Summary"),
          div(class = "question-help", "Describe your project briefly and clearly. Highlight innovation."),
          textAreaInput(ns("main_ideas_1"), "Main Ideas / Key Points:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_1"), "Generate with ChatGPT", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("project_summary"), "Generated Summary:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_1"))))
    ),
    fluidRow(
      box(title = "2. Public Description", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Public Description"),
          div(class = "question-help", "Detailed description suitable for public publication."),
          textAreaInput(ns("main_ideas_2"), "Main Ideas / Key Points:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_2"), "Generate with ChatGPT", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("public_description"), "Generated Description:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_2"))))
    ),
    fluidRow(
      box(title = "3. Scope", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Scope"),
          div(class = "question-help", "Describe how your project aligns with competition scope."),
          textAreaInput(ns("main_ideas_3"), "Main Ideas / Key Points:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_3"), "Generate with ChatGPT", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("scope"), "Generated Scope:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_3"))))
    ),
    fluidRow(
      box(title = "Save to Excel", status = "success", solidHeader = TRUE, width = 12,
          p("Save your project details to an Excel file on the server (see note in the app README about this on hosted deployments)."),
          fluidRow(
            column(6, textInput(ns("version_name"), "Version Name:", value = "ProjectV1")),
            column(6, textInput(ns("sheet_name"), "Sheet Name:", value = "Project_Details"))
          ),
          textInput(ns("file_path"), "Excel File Path:", value = "project_application.xlsx"),
          actionButton(ns("save_excel"), "Save to Excel", class = "save-btn", icon = icon("file-excel")),
          br(), br(),
          uiOutput(ns("save_status_ui")))
    )
  )
}

project_details_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    call_chatgpt <- function(prompt, word_limit) {
      if (!api_manager$openai_authenticated) {
        showNotification("Please configure OpenAI API first (API Settings > ChatGPT API Config)!", type = "error", duration = 5)
        return(NULL)
      }
      tryCatch(
        api_manager$call_openai(prompt, max_tokens = as.integer(word_limit) * 2)$text,
        error = function(e) { showNotification(paste("OpenAI error:", e$message), type = "error", duration = 8); NULL }
      )
    }

    make_generate_handler <- function(main_ideas_id, word_limit_id, target_id, label) {
      observeEvent(input[[paste0("generate_", main_ideas_id)]], {
        idea_text <- input[[paste0("main_ideas_", main_ideas_id)]]
        req(idea_text)
        if (nchar(trimws(idea_text)) < 10) { showNotification("Please enter more details", type = "warning", duration = 3); return() }

        limit <- input[[paste0("word_limit_", word_limit_id)]]
        prompt <- paste0("Write a ", label, " (", limit, " words) based on: ", idea_text)
        showNotification("Generating...", type = "message", duration = NULL, id = paste0("gen", main_ideas_id))
        result <- call_chatgpt(prompt, limit)
        removeNotification(id = paste0("gen", main_ideas_id))

        if (!is.null(result)) {
          updateTextAreaInput(session, target_id, value = result)
          showNotification("Generated successfully!", type = "message", duration = 3)
        }
      })
    }

    make_generate_handler(1, 1, "project_summary", "project summary")
    make_generate_handler(2, 2, "public_description", "public description")
    make_generate_handler(3, 3, "scope", "scope description")

    output$word_count_1 <- renderText(format_word_count(input$project_summary, input$word_limit_1))
    output$word_count_2 <- renderText(format_word_count(input$public_description, input$word_limit_2))
    output$word_count_3 <- renderText(format_word_count(input$scope, input$word_limit_3))

    observeEvent(input$save_excel, {
      req(input$version_name, input$sheet_name, input$file_path)

      tryCatch({
        data <- data.frame(
          Version = input$version_name,
          Section = c("Summary", "Description", "Scope"),
          Content = c(input$project_summary, input$public_description, input$scope),
          Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          stringsAsFactors = FALSE
        )

        file_path <- normalizePath(input$file_path, mustWork = FALSE)

        if (file.exists(file_path)) {
          wb <- openxlsx::loadWorkbook(file_path)
          if (input$sheet_name %in% names(wb)) openxlsx::removeWorksheet(wb, input$sheet_name)
          openxlsx::addWorksheet(wb, input$sheet_name)
          openxlsx::writeData(wb, input$sheet_name, data)
          openxlsx::saveWorkbook(wb, file_path, overwrite = TRUE)
        } else {
          wb <- openxlsx::createWorkbook()
          openxlsx::addWorksheet(wb, input$sheet_name)
          openxlsx::writeData(wb, input$sheet_name, data)
          openxlsx::saveWorkbook(wb, file_path)
        }

        output$save_status_ui <- renderUI(create_status_ui(TRUE, paste(" Saved to", file_path)))
        showNotification("Saved successfully!", type = "message", duration = 5)
      }, error = function(e) {
        output$save_status_ui <- renderUI(create_status_ui(FALSE, paste(" Error:", e$message)))
      })
    })

    output$save_status_ui <- renderUI({ tags$div() })
  })
}
