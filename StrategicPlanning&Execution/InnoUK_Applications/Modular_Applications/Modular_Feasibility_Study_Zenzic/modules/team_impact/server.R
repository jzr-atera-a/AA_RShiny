team_impact_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    get_full_context <- reactive({
      context <- ""
      if (exists("module_returns", envir = .GlobalEnv)) {
        if (!is.null(module_returns$project_details)) {
          context <- paste0(context, module_returns$project_details$get_context())
        }
      }
      return(context)
    })
    
    # Generator 1: Team
    observeEvent(input$genti1, {
      req(input$ideasti1)
      
      context <- get_full_context()
      prompt <- paste0(
        context,
        "\n\nBased on ALL context, answer:\n",
        "Who is in your team and how will you fill gaps?\n\n",
        "Main Ideas:\n", input$ideasti1, "\n\n",
        "Write approximately ", input$limitti1, " words."
      )
      
      showNotification("Generating...", duration = NULL, id = "genti1")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limitti1, "Team")
      }, error = function(e) {
        removeNotification(id = "genti1")
        showNotification(paste("Error:", e$message), type = "error")
        NULL
      })
      
      removeNotification(id = "genti1")
      if (!is.null(result)) {
        updateTextAreaInput(session, "team", value = result)
        showNotification("Generated!", type = "message", duration = 3)
      }
    })
    
    # Generator 2: Finance
    observeEvent(input$genti2, {
      req(input$ideasti2)
      
      context <- get_full_context()
      prompt <- paste0(
        context,
        "\n\nBased on ALL context, answer:\n",
        "How will you manage finances and risks?\n\n",
        "Main Ideas:\n", input$ideasti2, "\n\n",
        "Write approximately ", input$limitti2, " words."
      )
      
      showNotification("Generating...", duration = NULL, id = "genti2")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limitti2, "Finance")
      }, error = function(e) {
        removeNotification(id = "genti2")
        showNotification(paste("Error:", e$message), type = "error")
        NULL
      })
      
      removeNotification(id = "genti2")
      if (!is.null(result)) {
        updateTextAreaInput(session, "finance", value = result)
        showNotification("Generated!", type = "message", duration = 3)
      }
    })
    
    # Generator 3: Impact
    observeEvent(input$genti3, {
      req(input$ideasti3)
      
      context <- get_full_context()
      prompt <- paste0(
        context,
        "\n\nBased on ALL context, answer:\n",
        "What impact will your proposal have on UK economy and society?\n\n",
        "Main Ideas:\n", input$ideasti3, "\n\n",
        "Write approximately ", input$limitti3, " words."
      )
      
      showNotification("Generating...", duration = NULL, id = "genti3")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limitti3, "Impact")
      }, error = function(e) {
        removeNotification(id = "genti3")
        showNotification(paste("Error:", e$message), type = "error")
        NULL
      })
      
      removeNotification(id = "genti3")
      if (!is.null(result)) {
        updateTextAreaInput(session, "impact", value = result)
        showNotification("Generated!", type = "message", duration = 3)
      }
    })
    
    # Generator 4: Costs
    observeEvent(input$genti4, {
      req(input$ideasti4)
      
      context <- get_full_context()
      prompt <- paste0(
        context,
        "\n\nBased on ALL context, answer:\n",
        "How do your costs represent value for money?\n\n",
        "Main Ideas:\n", input$ideasti4, "\n\n",
        "Write approximately ", input$limitti4, " words."
      )
      
      showNotification("Generating...", duration = NULL, id = "genti4")
      
      result <- tryCatch({
        api_manager$call_openai(prompt, input$limitti4, "Costs")
      }, error = function(e) {
        removeNotification(id = "genti4")
        showNotification(paste("Error:", e$message), type = "error")
        NULL
      })
      
      removeNotification(id = "genti4")
      if (!is.null(result)) {
        updateTextAreaInput(session, "costs", value = result)
        showNotification("Generated!", type = "message", duration = 3)
      }
    })
    
    # Word counters
    output$countti1 <- renderText({
      words <- strsplit(trimws(input$team), "\\s+")[[1]]
      paste("Words:", length(words), "/", input$limitti1)
    })
    
    output$countti2 <- renderText({
      words <- strsplit(trimws(input$finance), "\\s+")[[1]]
      paste("Words:", length(words), "/", input$limitti2)
    })
    
    output$countti3 <- renderText({
      words <- strsplit(trimws(input$impact), "\\s+")[[1]]
      paste("Words:", length(words), "/", input$limitti3)
    })
    
    output$countti4 <- renderText({
      words <- strsplit(trimws(input$costs), "\\s+")[[1]]
      paste("Words:", length(words), "/", input$limitti4)
    })
    
    # Save
    observeEvent(input$save, {
      file_path <- if (exists("module_returns", envir = .GlobalEnv) && 
                      !is.null(module_returns$project_details)) {
        module_returns$project_details$get_file_path()
      } else "project_application.xlsx"
      
      version <- if (exists("module_returns", envir = .GlobalEnv) && 
                    !is.null(module_returns$project_details)) {
        module_returns$project_details$get_version()
      } else "V1"
      
      sheet <- if (exists("module_returns", envir = .GlobalEnv) && 
                  !is.null(module_returns$project_details)) {
        module_returns$project_details$get_sheet()
      } else "Project"
      
      tryCatch({
        library(openxlsx)
        
        data_ti <- data.frame(
          Version = rep(version, 4),
          Section = c("Team & Capability", "Finance & Risk", "Impact", "Costs & Value"),
          Question = c("Team and capability", "Finance and risk", "Impact on UK", "Costs and value"),
          MainIdeas = c(input$ideasti1, input$ideasti2, input$ideasti3, input$ideasti4),
          GeneratedContent = c(input$team, input$finance, input$impact, input$costs),
          WordLimit = c(input$limitti1, input$limitti2, input$limitti3, input$limitti4),
          WordCount = c(
            length(strsplit(trimws(input$team), "\\s+")[[1]]),
            length(strsplit(trimws(input$finance), "\\s+")[[1]]),
            length(strsplit(trimws(input$impact), "\\s+")[[1]]),
            length(strsplit(trimws(input$costs), "\\s+")[[1]])
          ),
          Timestamp = rep(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), 4),
          stringsAsFactors = FALSE
        )
        
        if (file.exists(file_path)) {
          wb <- loadWorkbook(file_path)
          if (sheet %in% names(wb)) {
            existing_data <- readWorkbook(wb, sheet)
            combined_data <- rbind(existing_data, data_ti)
            removeWorksheet(wb, sheet)
            addWorksheet(wb, sheet)
            writeData(wb, sheet, combined_data)
          } else {
            addWorksheet(wb, sheet)
            writeData(wb, sheet, data_ti)
          }
          saveWorkbook(wb, file_path, overwrite = TRUE)
        }
        
        output$save_status <- renderUI({
          div(class = "save-status-success", icon("check-circle"), " Team & Impact saved!")
        })
        showNotification("Team & Impact saved!", type = "message", duration = 5)
        
      }, error = function(e) {
        output$save_status <- renderUI({
          div(class = "save-status-error", icon("exclamation-circle"), " Error: ", e$message)
        })
      })
    })
  })
}