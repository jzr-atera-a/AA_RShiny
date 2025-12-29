#!/usr/bin/env python3
"""
Complete Module Generator
Generates ALL modules with FULL functionality from the 4000-line app.R
"""
import os

BASE = "/mnt/user-data/outputs/Complete_Full_App/modules"

# I'll create each module with complete server logic
# Starting with PROJECT_DETAILS - complete server

project_details_server = '''project_details_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive value to store file path globally within module
    file_path_reactive <- reactiveVal("project_application.xlsx")
    
    # Update file path when changed
    observeEvent(input$filepath, {
      file_path_reactive(input$filepath)
    })
    
    # Generator 1: Project Summary
    observeEvent(input$gen1, {
      req(input$ideas1)
      
      if (nchar(trimws(input$ideas1)) < 10) {
        showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                         type = "warning", 
                         duration = 3)
        return()
      }
      
      prompt <- paste0(
        "Based on the following main ideas and key points, write a compelling project summary that:\\n",
        "1. Describes the project briefly and clearly\\n",
        "2. Highlights what makes it innovative and unique\\n",
        "3. Is suitable for expert reviewers to assess the application\\n",
        "4. Is approximately ", input$limit1, " words long (strict limit)\\n",
        "5. Is professional, clear, and persuasive\\n\\n",
        "Main Ideas and Key Points:\\n", input$ideas1, "\\n\\n",
        "Write ONLY the project summary text, without any additional commentary or labels. ",
        "Make it exactly around ", input$limit1, " words."
      )
      
      showNotification("Generating project summary with ChatGPT...", 
                       type = "message", 
                       duration = NULL, 
                       id = "gen1")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limit1, "Project Summary")
      }, error = function(e) {
        removeNotification(id = "gen1")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "gen1")
      
      if (!is.null(result)) {
        updateTextAreaInput(session, "summary", value = result)
        showNotification("Project summary generated successfully!", 
                         type = "message", 
                         duration = 3)
      }
    })
    
    # Generator 2: Public Description
    observeEvent(input$gen2, {
      req(input$ideas2)
      
      if (nchar(trimws(input$ideas2)) < 10) {
        showNotification("Please enter more detailed main ideas", 
                         type = "warning", 
                         duration = 3)
        return()
      }
      
      prompt <- paste0(
        "Based on the following main ideas and key points, write a detailed public project description that:\\n",
        "1. Describes the project comprehensively and in detail\\n",
        "2. Is suitable for public publication (no commercially sensitive information)\\n",
        "3. Is clear, professional, and engaging for a general audience\\n",
        "4. Is approximately ", input$limit2, " words long (strict limit)\\n",
        "5. Explains the project's objectives, approach, and expected outcomes\\n\\n",
        "Main Ideas and Key Points:\\n", input$ideas2, "\\n\\n",
        "Write ONLY the public description text. ",
        "Make it exactly around ", input$limit2, " words."
      )
      
      showNotification("Generating public description...", 
                       type = "message", 
                       duration = NULL, 
                       id = "gen2")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limit2, "Public Description")
      }, error = function(e) {
        removeNotification(id = "gen2")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "gen2")
      
      if (!is.null(result)) {
        updateTextAreaInput(session, "description", value = result)
        showNotification("Public description generated successfully!", 
                         type = "message", 
                         duration = 3)
      }
    })
    
    # Generator 3: Scope
    observeEvent(input$gen3, {
      req(input$ideas3)
      
      if (nchar(trimws(input$ideas3)) < 10) {
        showNotification("Please enter more detailed main ideas", 
                         type = "warning", 
                         duration = 3)
        return()
      }
      
      prompt <- paste0(
        "Based on the following main ideas and key points, write a project scope description that:\\n",
        "1. Clearly explains how the project fits the competition scope\\n",
        "2. Demonstrates alignment with competition requirements and eligibility\\n",
        "3. Is approximately ", input$limit3, " words long (strict limit)\\n",
        "4. Is convincing and shows clear understanding of the competition criteria\\n",
        "5. Addresses any specific scope requirements mentioned\\n\\n",
        "Main Ideas and Key Points:\\n", input$ideas3, "\\n\\n",
        "Write ONLY the scope description text. ",
        "Make it exactly around ", input$limit3, " words."
      )
      
      showNotification("Generating scope description...", 
                       type = "message", 
                       duration = NULL, 
                       id = "gen3")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limit3, "Scope")
      }, error = function(e) {
        removeNotification(id = "gen3")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "gen3")
      
      if (!is.null(result)) {
        updateTextAreaInput(session, "scope", value = result)
        showNotification("Scope description generated successfully!", 
                         type = "message", 
                         duration = 3)
      }
    })
    
    # Word counters
    output$count1 <- renderText({
      if (nchar(trimws(input$summary)) == 0) {
        paste("Words: 0 /", input$limit1, "| Words remaining:", input$limit1)
      } else {
        words <- strsplit(trimws(input$summary), "\\\\s+")[[1]]
        word_count <- length(words)
        remaining <- input$limit1 - word_count
        paste("Words:", word_count, "/", input$limit1, "| Words remaining:", remaining)
      }
    })
    
    output$count2 <- renderText({
      if (nchar(trimws(input$description)) == 0) {
        paste("Words: 0 /", input$limit2, "| Words remaining:", input$limit2)
      } else {
        words <- strsplit(trimws(input$description), "\\\\s+")[[1]]
        word_count <- length(words)
        remaining <- input$limit2 - word_count
        paste("Words:", word_count, "/", input$limit2, "| Words remaining:", remaining)
      }
    })
    
    output$count3 <- renderText({
      if (nchar(trimws(input$scope)) == 0) {
        paste("Words: 0 /", input$limit3, "| Words remaining:", input$limit3)
      } else {
        words <- strsplit(trimws(input$scope), "\\\\s+")[[1]]
        word_count <- length(words)
        remaining <- input$limit3 - word_count
        paste("Words:", word_count, "/", input$limit3, "| Words remaining:", remaining)
      }
    })
    
    # Save to Excel
    observeEvent(input$save, {
      req(input$version, input$sheet, input$filepath)
      
      if (nchar(trimws(input$version)) == 0 || 
          nchar(trimws(input$sheet)) == 0 || 
          nchar(trimws(input$filepath)) == 0) {
        output$save_status <- renderUI({
          div(class = "save-status-error",
              icon("exclamation-circle"), 
              " Please fill in all fields: Version Name, Sheet Name, and File Path.")
        })
        showNotification("Please fill in all required fields", 
                         type = "error", 
                         duration = 3)
        return()
      }
      
      tryCatch({
        library(openxlsx)
        
        word_count_1 <- if (nchar(trimws(input$summary)) == 0) 0 else 
          length(strsplit(trimws(input$summary), "\\\\s+")[[1]])
        word_count_2 <- if (nchar(trimws(input$description)) == 0) 0 else 
          length(strsplit(trimws(input$description), "\\\\s+")[[1]])
        word_count_3 <- if (nchar(trimws(input$scope)) == 0) 0 else 
          length(strsplit(trimws(input$scope), "\\\\s+")[[1]])
        
        data <- data.frame(
          Version = rep(input$version, 3),
          Section = c("Project Summary", "Public Description", "Scope"),
          Question = c(
            "What should I include in the project summary?",
            "What should I include in the project public description?",
            "What should I include in the project scope?"
          ),
          MainIdeas = c(
            ifelse(is.null(input$ideas1) || input$ideas1 == "", "", input$ideas1), 
            ifelse(is.null(input$ideas2) || input$ideas2 == "", "", input$ideas2), 
            ifelse(is.null(input$ideas3) || input$ideas3 == "", "", input$ideas3)
          ),
          GeneratedContent = c(
            ifelse(is.null(input$summary) || input$summary == "", "", input$summary), 
            ifelse(is.null(input$description) || input$description == "", "", input$description), 
            ifelse(is.null(input$scope) || input$scope == "", "", input$scope)
          ),
          WordLimit = c(input$limit1, input$limit2, input$limit3),
          WordCount = c(word_count_1, word_count_2, word_count_3),
          WordsRemaining = c(
            input$limit1 - word_count_1,
            input$limit2 - word_count_2,
            input$limit3 - word_count_3
          ),
          Timestamp = rep(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), 3),
          stringsAsFactors = FALSE
        )
        
        file_path <- normalizePath(input$filepath, mustWork = FALSE)
        file_path_reactive(file_path)
        
        if (file.exists(file_path)) {
          wb <- loadWorkbook(file_path)
          
          if (input$sheet %in% names(wb)) {
            removeWorksheet(wb, input$sheet)
          }
          
          addWorksheet(wb, input$sheet)
          writeData(wb, input$sheet, data, startRow = 1, startCol = 1)
          setColWidths(wb, input$sheet, cols = 1:ncol(data), widths = "auto")
          
          saveWorkbook(wb, file_path, overwrite = TRUE)
          
        } else {
          wb <- createWorkbook()
          addWorksheet(wb, input$sheet)
          writeData(wb, input$sheet, data, startRow = 1, startCol = 1)
          setColWidths(wb, input$sheet, cols = 1:ncol(data), widths = "auto")
          
          saveWorkbook(wb, file_path)
        }
        
        output$save_status <- renderUI({
          div(class = "save-status-success",
              icon("check-circle"), 
              " Data saved successfully to: ", tags$br(),
              tags$strong(file_path), tags$br(),
              "Sheet: ", tags$strong(input$sheet))
        })
        
        showNotification(paste("Data saved to sheet:", input$sheet), 
                         type = "message", 
                         duration = 5)
        
      }, error = function(e) {
        output$save_status <- renderUI({
          div(class = "save-status-error",
              icon("exclamation-circle"), 
              " Error saving file: ", tags$br(),
              tags$small(e$message))
        })
        showNotification(paste("Error saving Excel file:", e$message), 
                         type = "error", 
                         duration = 10)
      })
    })
    
    # Return file path for other modules to use
    return(list(
      get_file_path = reactive({ file_path_reactive() }),
      get_version = reactive({ input$version }),
      get_sheet = reactive({ input$sheet }),
      get_context = reactive({
        paste0(
          if (!is.null(input$summary) && nchar(trimws(input$summary)) > 0) 
            paste0("[PROJECT SUMMARY]\\n", input$summary, "\\n\\n") else "",
          if (!is.null(input$description) && nchar(trimws(input$description)) > 0) 
            paste0("[PUBLIC DESCRIPTION]\\n", input$description, "\\n\\n") else "",
          if (!is.null(input$scope) && nchar(trimws(input$scope)) > 0) 
            paste0("[SCOPE]\\n", input$scope, "\\n\\n") else ""
        )
      })
    ))
  })
}'''

with open(f"{BASE}/project_details/server.R", 'w') as f:
    f.write(project_details_server)

print("✓ project_details/server.R created (COMPLETE)")

# Now create the remaining modules...
# I'll continue with business_case, team_impact, diagram_generator, claude_diagrams

