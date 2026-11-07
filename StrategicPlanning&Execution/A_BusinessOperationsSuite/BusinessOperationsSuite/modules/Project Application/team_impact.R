# modules/Project Application/team_impact.R
# Subtab: Team & Impact (4 AI-assisted sections + Excel export)

team_impact_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Word Limits - Team & Impact", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          column(3, numericInput(ns("word_limit_ti1"), "Team:", value = 400, min = 50, max = 2000)),
          column(3, numericInput(ns("word_limit_ti2"), "Finance:", value = 400, min = 50, max = 2000)),
          column(3, numericInput(ns("word_limit_ti3"), "Impact:", value = 500, min = 50, max = 2000)),
          column(3, numericInput(ns("word_limit_ti4"), "Costs:", value = 400, min = 50, max = 2000)))
    ),
    fluidRow(
      box(title = "14. Team and Capability", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Team and Capability"),
          div(class = "question-help", "Who is in your team and how will you fill gaps?"),
          textAreaInput(ns("main_ideas_ti1"), "Main Ideas:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_ti1"), "Generate with Full Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("team_capability"), "Generated Response:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_ti1"))))
    ),
    fluidRow(
      box(title = "15. Finance and Risk Management", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Finance and Risk Management"),
          div(class = "question-help", "How will you manage finances and risks?"),
          textAreaInput(ns("main_ideas_ti2"), "Main Ideas:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_ti2"), "Generate with Full Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("finance_risk"), "Generated Response:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_ti2"))))
    ),
    fluidRow(
      box(title = "16. Impact on UK Economy and Society", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Impact on UK Economy"),
          div(class = "question-help", "What impact will your proposal have?"),
          textAreaInput(ns("main_ideas_ti3"), "Main Ideas:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_ti3"), "Generate with Full Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("impact"), "Generated Response:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_ti3"))))
    ),
    fluidRow(
      box(title = "17. Costs and Value for Money", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "question-label", "Costs and Value for Money"),
          div(class = "question-help", "How do your costs represent value?"),
          textAreaInput(ns("main_ideas_ti4"), "Main Ideas:", placeholder = "Enter key points...", height = "120px", width = "100%"),
          actionButton(ns("generate_ti4"), "Generate with Full Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
          textAreaInput(ns("costs_value"), "Generated Response:", placeholder = "AI-generated content will appear here...", height = "250px", width = "100%"),
          div(class = "word-counter", textOutput(ns("word_count_ti4"))))
    ),
    fluidRow(
      box(title = "Save Team & Impact", status = "success", solidHeader = TRUE, width = 12,
          p("Save team & impact data to Excel file."),
          textInput(ns("file_path_ti"), "Excel File Path:", value = "project_application.xlsx"),
          actionButton(ns("save_team_impact"), "Save to Excel", class = "save-btn", icon = icon("file-excel")),
          br(), br(),
          uiOutput(ns("save_ti_status_ui")))
    )
  )
}

team_impact_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    call_chatgpt_with_context <- function(prompt, word_limit) {
      if (!api_manager$openai_authenticated) {
        showNotification("Please configure OpenAI API first (API Settings > ChatGPT API Config)!", type = "error", duration = 5)
        return(NULL)
      }
      tryCatch(
        api_manager$call_openai(prompt, max_tokens = as.integer(word_limit) * 2)$text,
        error = function(e) { showNotification(paste("OpenAI error:", e$message), type = "error", duration = 8); NULL }
      )
    }

    make_generate_handler <- function(suffix, target_id, label) {
      observeEvent(input[[paste0("generate_ti", suffix)]], {
        idea_text <- input[[paste0("main_ideas_ti", suffix)]]
        req(idea_text)
        if (nchar(trimws(idea_text)) < 10) { showNotification("Please enter more details", type = "warning", duration = 3); return() }

        limit <- input[[paste0("word_limit_ti", suffix)]]
        prompt <- paste0("Write ", label, " (", limit, " words): ", idea_text)
        showNotification("Generating...", type = "message", duration = NULL, id = paste0("gen_ti", suffix))
        result <- call_chatgpt_with_context(prompt, limit)
        removeNotification(id = paste0("gen_ti", suffix))
        if (!is.null(result)) updateTextAreaInput(session, target_id, value = result)
      })
    }

    make_generate_handler(1, "team_capability", "team & capability assessment")
    make_generate_handler(2, "finance_risk", "finance & risk analysis")
    make_generate_handler(3, "impact", "impact assessment")
    make_generate_handler(4, "costs_value", "costs & value analysis")

    output$word_count_ti1 <- renderText(format_word_count(input$team_capability, input$word_limit_ti1))
    output$word_count_ti2 <- renderText(format_word_count(input$finance_risk, input$word_limit_ti2))
    output$word_count_ti3 <- renderText(format_word_count(input$impact, input$word_limit_ti3))
    output$word_count_ti4 <- renderText(format_word_count(input$costs_value, input$word_limit_ti4))

    observeEvent(input$save_team_impact, {
      req(input$file_path_ti)
      tryCatch({
        data <- data.frame(
          Section = c("Team", "Finance", "Impact", "Costs"),
          Content = c(input$team_capability, input$finance_risk, input$impact, input$costs_value),
          Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          stringsAsFactors = FALSE
        )
        file_path <- normalizePath(input$file_path_ti, mustWork = FALSE)

        if (file.exists(file_path)) {
          wb <- openxlsx::loadWorkbook(file_path)
          if ("Team_Impact" %in% names(wb)) openxlsx::removeWorksheet(wb, "Team_Impact")
          openxlsx::addWorksheet(wb, "Team_Impact")
          openxlsx::writeData(wb, "Team_Impact", data)
          openxlsx::saveWorkbook(wb, file_path, overwrite = TRUE)
        } else {
          wb <- openxlsx::createWorkbook()
          openxlsx::addWorksheet(wb, "Team_Impact")
          openxlsx::writeData(wb, "Team_Impact", data)
          openxlsx::saveWorkbook(wb, file_path)
        }

        output$save_ti_status_ui <- renderUI(create_status_ui(TRUE, " Saved successfully!"))
        showNotification("Team & Impact saved!", type = "message", duration = 5)
      }, error = function(e) {
        output$save_ti_status_ui <- renderUI(create_status_ui(FALSE, paste(" Error:", e$message)))
      })
    })

    output$save_ti_status_ui <- renderUI({ tags$div() })
  })
}
