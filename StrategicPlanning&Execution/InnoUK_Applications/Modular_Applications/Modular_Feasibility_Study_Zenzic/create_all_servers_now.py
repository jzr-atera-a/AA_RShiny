#!/usr/bin/env python3
"""Generate ALL server files with COMPLETE implementations"""
import os

BASE = "/mnt/user-data/outputs/Complete_Full_App/modules"

# ============================================
# BUSINESS_CASE SERVER - COMPLETE
# ============================================
business_case_server = '''business_case_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Helper to get context from project_details
    get_project_context <- reactive({
      if (exists("module_returns", envir = .GlobalEnv) && 
          !is.null(module_returns$project_details)) {
        module_returns$project_details$get_context()
      } else {
        ""
      }
    })
    
    # Generator 1: Problem & Market
    observeEvent(input$genbc1, {
      req(input$ideasbc1)
      
      context <- get_project_context()
      prompt <- paste0(
        context,
        "\\n\\nBased on ALL the above context, answer this question:\\n",
        "What mobility challenge or gap are you addressing, and what is the size and timing of the opportunity?\\n\\n",
        "Main Ideas:\\n", input$ideasbc1, "\\n\\n",
        "Write approximately ", input$limitbc1, " words."
      )
      
      showNotification("Generating with context...", duration = NULL, id = "genbc1")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limitbc1, "Problem & Market")
      }, error = function(e) {
        removeNotification(id = "genbc1")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "genbc1")
      if (!is.null(result)) {
        updateTextAreaInput(session, "problem", value = result)
        showNotification("Generated!", type = "message", duration = 3)
      }
    })
    
    # Generator 2: CAM Service
    observeEvent(input$genbc2, {
      req(input$ideasbc2)
      
      context <- get_project_context()
      prompt <- paste0(
        context,
        "\\n\\nBased on ALL the above context, answer this question:\\n",
        "What CAM service or solution are you proposing, and why is this the right service in the right location?\\n\\n",
        "Main Ideas:\\n", input$ideasbc2, "\\n\\n",
        "Write approximately ", input$limitbc2, " words."
      )
      
      showNotification("Generating with context...", duration = NULL, id = "genbc2")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limitbc2, "CAM Service")
      }, error = function(e) {
        removeNotification(id = "genbc2")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "genbc2")
      if (!is.null(result)) {
        updateTextAreaInput(session, "cam", value = result)
        showNotification("Generated!", type = "message", duration = 3)
      }
    })
    
    # Generator 3: Readiness
    observeEvent(input$genbc3, {
      req(input$ideasbc3)
      
      context <- get_project_context()
      prompt <- paste0(
        context,
        "\\n\\nBased on ALL the above context, answer this question:\\n",
        "How ready is your current business case? Identify areas of complete knowledge and gaps.\\n\\n",
        "Main Ideas:\\n", input$ideasbc3, "\\n\\n",
        "Write approximately ", input$limitbc3, " words."
      )
      
      showNotification("Generating with context...", duration = NULL, id = "genbc3")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limitbc3, "Readiness")
      }, error = function(e) {
        removeNotification(id = "genbc3")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "genbc3")
      if (!is.null(result)) {
        updateTextAreaInput(session, "readiness", value = result)
        showNotification("Generated!", type = "message", duration = 3)
      }
    })
    
    # Generator 4: Feasibility
    observeEvent(input$genbc4, {
      req(input$ideasbc4)
      
      context <- get_project_context()
      prompt <- paste0(
        context,
        "\\n\\nBased on ALL the above context, answer this question:\\n",
        "What will your feasibility study deliver, and how will you know if it is successful?\\n\\n",
        "Main Ideas:\\n", input$ideasbc4, "\\n\\n",
        "Write approximately ", input$limitbc4, " words."
      )
      
      showNotification("Generating with context...", duration = NULL, id = "genbc4")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limitbc4, "Feasibility")
      }, error = function(e) {
        removeNotification(id = "genbc4")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "genbc4")
      if (!is.null(result)) {
        updateTextAreaInput(session, "feasibility", value = result)
        showNotification("Generated!", type = "message", duration = 3)
      }
    })
    
    # Generator 5: Commercialisation
    observeEvent(input$genbc5, {
      req(input$ideasbc5)
      
      context <- get_project_context()
      prompt <- paste0(
        context,
        "\\n\\nBased on ALL the above context, answer this question:\\n",
        "What happens after the feasibility study, and how will you measure progress?\\n\\n",
        "Main Ideas:\\n", input$ideasbc5, "\\n\\n",
        "Write approximately ", input$limitbc5, " words."
      )
      
      showNotification("Generating with context...", duration = NULL, id = "genbc5")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limitbc5, "Commercialisation")
      }, error = function(e) {
        removeNotification(id = "genbc5")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "genbc5")
      if (!is.null(result)) {
        updateTextAreaInput(session, "commercialisation", value = result)
        showNotification("Generated!", type = "message", duration = 3)
      }
    })
    
    # Word counters
    output$countbc1 <- renderText({
      words <- strsplit(trimws(input$problem), "\\\\s+")[[1]]
      paste("Words:", length(words), "/", input$limitbc1, "| Remaining:", input$limitbc1 - length(words))
    })
    
    output$countbc2 <- renderText({
      words <- strsplit(trimws(input$cam), "\\\\s+")[[1]]
      paste("Words:", length(words), "/", input$limitbc2, "| Remaining:", input$limitbc2 - length(words))
    })
    
    output$countbc3 <- renderText({
      words <- strsplit(trimws(input$readiness), "\\\\s+")[[1]]
      paste("Words:", length(words), "/", input$limitbc3, "| Remaining:", input$limitbc3 - length(words))
    })
    
    output$countbc4 <- renderText({
      words <- strsplit(trimws(input$feasibility), "\\\\s+")[[1]]
      paste("Words:", length(words), "/", input$limitbc4, "| Remaining:", input$limitbc4 - length(words))
    })
    
    output$countbc5 <- renderText({
      words <- strsplit(trimws(input$commercialisation), "\\\\s+")[[1]]
      paste("Words:", length(words), "/", input$limitbc5, "| Remaining:", input$limitbc5 - length(words))
    })
    
    # Save to Excel
    observeEvent(input$save, {
      file_path <- if (exists("module_returns", envir = .GlobalEnv) && 
                      !is.null(module_returns$project_details)) {
        module_returns$project_details$get_file_path()
      } else {
        "project_application.xlsx"
      }
      
      version <- if (exists("module_returns", envir = .GlobalEnv) && 
                    !is.null(module_returns$project_details)) {
        module_returns$project_details$get_version()
      } else {
        "V1"
      }
      
      sheet <- if (exists("module_returns", envir = .GlobalEnv) && 
                  !is.null(module_returns$project_details)) {
        module_returns$project_details$get_sheet()
      } else {
        "Project"
      }
      
      tryCatch({
        library(openxlsx)
        
        data_bc <- data.frame(
          Version = rep(version, 5),
          Section = c("Problem & Market", "CAM Service", "Readiness", "Feasibility", "Commercialisation"),
          Question = c(
            "Problem, opportunity and market potential",
            "Proposed CAM service and location",
            "Readiness, stakeholders and compliance",
            "Feasibility study plan",
            "Commercialisation roadmap and KPIs"
          ),
          MainIdeas = c(input$ideasbc1, input$ideasbc2, input$ideasbc3, input$ideasbc4, input$ideasbc5),
          GeneratedContent = c(input$problem, input$cam, input$readiness, input$feasibility, input$commercialisation),
          WordLimit = c(input$limitbc1, input$limitbc2, input$limitbc3, input$limitbc4, input$limitbc5),
          WordCount = c(
            length(strsplit(trimws(input$problem), "\\\\s+")[[1]]),
            length(strsplit(trimws(input$cam), "\\\\s+")[[1]]),
            length(strsplit(trimws(input$readiness), "\\\\s+")[[1]]),
            length(strsplit(trimws(input$feasibility), "\\\\s+")[[1]]),
            length(strsplit(trimws(input$commercialisation), "\\\\s+")[[1]])
          ),
          Timestamp = rep(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), 5),
          stringsAsFactors = FALSE
        )
        
        if (file.exists(file_path)) {
          wb <- loadWorkbook(file_path)
          if (sheet %in% names(wb)) {
            existing_data <- readWorkbook(wb, sheet)
            combined_data <- rbind(existing_data, data_bc)
            removeWorksheet(wb, sheet)
            addWorksheet(wb, sheet)
            writeData(wb, sheet, combined_data)
          } else {
            addWorksheet(wb, sheet)
            writeData(wb, sheet, data_bc)
          }
          saveWorkbook(wb, file_path, overwrite = TRUE)
        } else {
          showNotification("File does not exist. Save Project Details first!", type = "error", duration = 5)
          return()
        }
        
        output$save_status <- renderUI({
          div(class = "save-status-success",
              icon("check-circle"), " Business case saved to ", file_path)
        })
        showNotification("Business case saved!", type = "message", duration = 5)
        
      }, error = function(e) {
        output$save_status <- renderUI({
          div(class = "save-status-error", icon("exclamation-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
  })
}'''

with open(f"{BASE}/business_case/server.R", 'w') as f:
    f.write(business_case_server)

print("✓ business_case/server.R created (COMPLETE)")

