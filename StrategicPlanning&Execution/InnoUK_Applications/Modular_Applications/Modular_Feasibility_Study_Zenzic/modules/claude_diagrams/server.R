claude_diagrams_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    context_data <- reactiveVal(NULL)
    diagram_code <- reactiveVal(NULL)
    analysis_text <- reactiveVal("")
    
    # Save context to CSV
    observeEvent(input$save_context, {
      tryCatch({
        context_df <- data.frame(
          Section = character(),
          Content = character(),
          stringsAsFactors = FALSE
        )
        
        # Collect from all modules if available
        if (exists("module_returns", envir = .GlobalEnv)) {
          if (!is.null(module_returns$project_details)) {
            ctx <- module_returns$project_details$get_context()
            if (nchar(ctx) > 0) {
              context_df <- rbind(context_df, data.frame(
                Section = "Project Context",
                Content = ctx,
                stringsAsFactors = FALSE
              ))
            }
          }
        }
        
        context_data(context_df)
        
        if (nrow(context_df) > 0) {
          showNotification(paste("Context saved:", nrow(context_df), "sections"), 
                          type = "message", duration = 3)
        } else {
          showNotification("No content to save. Complete some sections first.", 
                          type = "warning", duration = 3)
        }
      }, error = function(e) {
        showNotification(paste("Error saving context:", e$message), type = "error")
      })
    })
    
    # Download context CSV
    output$download_context <- downloadHandler(
      filename = function() {
        paste0("context_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
      },
      content = function(file) {
        req(context_data())
        write.csv(context_data(), file, row.names = FALSE)
      }
    )
    
    # Upload context CSV
    observeEvent(input$upload_context, {
      req(input$upload_context)
      
      tryCatch({
        ctx_df <- read.csv(input$upload_context$datapath, stringsAsFactors = FALSE)
        context_data(ctx_df)
        
        output$context_info <- renderText({
          paste0("Loaded: ", nrow(ctx_df), " sections\n",
                "Sections: ", paste(ctx_df$Section, collapse = ", "))
        })
        
        showNotification("Context loaded successfully!", type = "message", duration = 3)
      }, error = function(e) {
        showNotification(paste("Error loading context:", e$message), type = "error")
      })
    })
    
    # File upload handler
    observeEvent(input$ref_file, {
      req(input$ref_file)
      
      output$file_info <- renderText({
        file_ext <- tools::file_ext(input$ref_file$name)
        support <- if (file_ext %in% c("jpg", "jpeg", "png", "gif", "webp", "pdf")) {
          "Native Support ✓"
        } else {
          "Text Extraction"
        }
        
        paste0(
          "File: ", input$ref_file$name, "\n",
          "Size: ", round(input$ref_file$size / 1024, 2), " KB\n",
          "Type: ", toupper(file_ext), "\n",
          "Claude Support: ", support
        )
      })
      
      showNotification("File loaded for Claude!", type = "message", duration = 3)
    })
    
    # Generate diagram with Claude
    observeEvent(input$generate, {
      req(input$instructions)
      
      if (nchar(trimws(input$instructions)) < 20) {
        showNotification("Please provide more detailed instructions", type = "warning", duration = 3)
        return()
      }
      
      showNotification("Generating diagram with Claude... This may take 30-90 seconds.", 
                       duration = NULL, id = "gen_claude")
      
      # Build content array for Claude
      content_parts <- list()
      
      # Add context if requested
      if (input$use_context && !is.null(context_data())) {
        ctx_text <- paste0("\n\n=== APPLICATION CONTEXT ===\n\n")
        for (i in 1:nrow(context_data())) {
          ctx_text <- paste0(ctx_text, "[", context_data()$Section[i], "]\n",
                            context_data()$Content[i], "\n\n")
        }
        content_parts[[length(content_parts) + 1]] <- list(
          type = "text",
          text = ctx_text
        )
      }
      
      # Build main instruction
      main_instruction <- paste0(
        "You are a professional diagram expert with expertise in creating sophisticated diagrams.\n\n",
        "TASK: Generate a ", input$type, " diagram based on:\n",
        input$instructions, "\n\n"
      )
      
      # Add format-specific instructions
      if (input$format == "svg") {
        main_instruction <- paste0(main_instruction,
          "OUTPUT: Complete, valid SVG code with proper viewBox and dimensions. ",
          "Return ONLY the SVG code, no explanations.")
      } else if (input$format == "html") {
        main_instruction <- paste0(main_instruction,
          "OUTPUT: Complete HTML document with <!DOCTYPE html> and inline CSS. ",
          "Return ONLY the HTML code.")
      } else if (input$format == "mermaid") {
        main_instruction <- paste0(main_instruction,
          "OUTPUT: Valid Mermaid diagram syntax. Return ONLY the Mermaid code.")
      } else if (input$format == "d3js") {
        main_instruction <- paste0(main_instruction,
          "OUTPUT: Complete HTML with D3.js visualization from CDN. ",
          "Include tooltips and interactions.")
      }
      
      content_parts[[length(content_parts) + 1]] <- list(
        type = "text",
        text = main_instruction
      )
      
      # Call Claude API
      result <- tryCatch({
        messages <- list(list(role = "user", content = content_parts))
        api_manager$call_claude(messages, max_tokens = 4096)
      }, error = function(e) {
        removeNotification(id = "gen_claude")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "gen_claude")
      
      if (!is.null(result)) {
        # Clean up code
        result <- gsub("```svg\\s*", "", result)
        result <- gsub("```html\\s*", "", result)
        result <- gsub("```mermaid\\s*", "", result)
        result <- gsub("```javascript\\s*", "", result)
        result <- gsub("```\\s*$", "", result)
        result <- trimws(result)
        
        diagram_code(result)
        analysis_text("Diagram generated successfully by Claude.")
        
        # Display diagram
        output$preview <- renderUI({
          if (input$format %in% c("svg")) {
            tags$div(style = "border: 2px solid #4a90e2; padding: 20px; background: white;",
                    HTML(result))
          } else if (input$format %in% c("html", "d3js")) {
            tags$iframe(srcdoc = result, width = "100%", height = "700px",
                       style = "border: 2px solid #4a90e2;")
          } else if (input$format == "mermaid") {
            tags$div(
              tags$script(src = "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"),
              tags$script("mermaid.initialize({startOnLoad:true, theme: \'default\'});"),
              tags$div(class = "mermaid", style = "background: white; padding: 20px;", result)
            )
          } else {
            tags$div(style = "border: 2px solid #4a90e2; padding: 20px; background: white;",
                    HTML(result))
          }
        })
        
        output$code_display <- renderText({
          substr(result, 1, 1500)
        })
        
        output$analysis <- renderText({
          analysis_text()
        })
        
        output$status <- renderUI({
          div(class = "save-status-success", icon("check-circle"), 
              " Diagram generated successfully by Claude!")
        })
        
        showNotification("Diagram generated by Claude!", type = "message", duration = 5)
      }
    })
    
    # Download handlers
    output$download_main <- downloadHandler(
      filename = function() {
        ext <- switch(input$format, "svg" = ".svg", "html" = ".html", 
                     "mermaid" = ".mmd", "d3js" = ".html", 
                     "png" = ".png", "pdf" = ".pdf", ".txt")
        paste0("claude_diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ext)
      },
      content = function(file) {
        req(diagram_code())
        writeLines(diagram_code(), file)
      }
    )
    
    output$download_svg <- downloadHandler(
      filename = function() {
        paste0("claude_diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".svg")
      },
      content = function(file) {
        req(diagram_code())
        writeLines(diagram_code(), file)
      }
    )
    
    output$download_png <- downloadHandler(
      filename = function() {
        paste0("claude_diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".png")
      },
      content = function(file) {
        req(diagram_code())
        tryCatch({
          library(rsvg)
          temp_svg <- tempfile(fileext = ".svg")
          writeLines(diagram_code(), temp_svg)
          rsvg_png(temp_svg, file, width = 1200, height = 800)
        }, error = function(e) {
          showNotification(paste("PNG conversion error:", e$message), type = "error")
        })
      }
    )
  })
}