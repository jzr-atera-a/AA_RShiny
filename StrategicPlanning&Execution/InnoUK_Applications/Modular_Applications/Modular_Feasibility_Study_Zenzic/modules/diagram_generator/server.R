diagram_generator_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    diagram_code <- reactiveVal(NULL)
    
    # File upload handler
    observeEvent(input$ref_file, {
      req(input$ref_file)
      
      output$file_info <- renderText({
        paste0(
          "File: ", input$ref_file$name, "\n",
          "Size: ", round(input$ref_file$size / 1024, 2), " KB\n",
          "Type: ", tools::file_ext(input$ref_file$name)
        )
      })
      
      showNotification("File loaded!", type = "message", duration = 3)
    })
    
    # Generate diagram
    observeEvent(input$generate, {
      req(input$instructions)
      
      if (nchar(trimws(input$instructions)) < 20) {
        showNotification("Please provide more detailed instructions", type = "warning", duration = 3)
        return()
      }
      
      showNotification("Generating diagram... This may take 30-60 seconds.", 
                       duration = NULL, id = "gen_diagram")
      
      # Build prompt
      prompt <- "You are a professional diagram expert. "
      
      # Add context if requested
      if (input$include_context && exists("module_returns", envir = .GlobalEnv)) {
        if (!is.null(module_returns$project_details)) {
          prompt <- paste0(prompt, "\n\nAPPLICATION CONTEXT:\n", 
                          module_returns$project_details$get_context())
        }
      }
      
      # Add diagram instructions
      prompt <- paste0(prompt, "\n\nTASK: Generate a ", input$type, " diagram based on:\n", 
                      input$instructions)
      
      # Add format-specific instructions
      if (input$format == "svg") {
        prompt <- paste0(prompt, "\n\nRETURN: Complete, valid SVG code. Start with <svg> and end with </svg>. ",
                        "Include proper viewBox and dimensions. Return ONLY the SVG code, no explanations.")
      } else if (input$format == "html") {
        prompt <- paste0(prompt, "\n\nRETURN: Complete HTML document with inline CSS. ",
                        "Include <!DOCTYPE html>. Return ONLY the HTML code.")
      } else if (input$format == "mermaid") {
        prompt <- paste0(prompt, "\n\nRETURN: Mermaid diagram code. ",
                        "Return ONLY the Mermaid code, no markdown formatting.")
      }
      
      # Call API
      result <- tryCatch({
        api_manager$call_openai(prompt, 2000, "Diagram")
      }, error = function(e) {
        removeNotification(id = "gen_diagram")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        NULL
      })
      
      removeNotification(id = "gen_diagram")
      
      if (!is.null(result)) {
        # Clean up code
        result <- gsub("```svg\\s*", "", result)
        result <- gsub("```html\\s*", "", result)
        result <- gsub("```mermaid\\s*", "", result)
        result <- gsub("```\\s*$", "", result)
        result <- trimws(result)
        
        diagram_code(result)
        
        # Display diagram
        output$preview <- renderUI({
          if (input$format == "svg") {
            tags$div(style = "border: 2px solid #4a90e2; padding: 20px; background: white;",
                    HTML(result))
          } else if (input$format == "html") {
            tags$iframe(srcdoc = result, width = "100%", height = "600px",
                       style = "border: 2px solid #4a90e2;")
          } else if (input$format == "mermaid") {
            tags$div(
              tags$script(src = "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"),
              tags$script("mermaid.initialize({startOnLoad:true});"),
              tags$div(class = "mermaid", style = "background: white; padding: 20px;", result)
            )
          } else {
            tags$div(style = "border: 2px solid #4a90e2; padding: 20px; background: white;",
                    HTML(result))
          }
        })
        
        output$code_display <- renderText({
          substr(result, 1, 1000)
        })
        
        output$status <- renderUI({
          div(class = "save-status-success", icon("check-circle"), " Diagram generated!")
        })
        
        showNotification("Diagram generated successfully!", type = "message", duration = 5)
      }
    })
    
    # Download handlers
    output$download_main <- downloadHandler(
      filename = function() {
        ext <- switch(input$format, "svg" = ".svg", "html" = ".html", 
                     "mermaid" = ".mmd", "png" = ".png", "pdf" = ".pdf", ".txt")
        paste0("diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ext)
      },
      content = function(file) {
        req(diagram_code())
        writeLines(diagram_code(), file)
      }
    )
    
    output$download_svg <- downloadHandler(
      filename = function() {
        paste0("diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".svg")
      },
      content = function(file) {
        req(diagram_code())
        writeLines(diagram_code(), file)
      }
    )
    
    output$download_png <- downloadHandler(
      filename = function() {
        paste0("diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".png")
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