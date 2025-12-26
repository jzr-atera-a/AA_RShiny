# Generate DE Roadmap Module - Server
# Handles 24-step roadmap generation and parsing

generate_de_roadmap_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    parsed_roadmap <- reactiveVal(NULL)
    
    # Generate Roadmap
    observeEvent(input$generate_roadmap, {
      if (!api_manager$claude_connected) {
        output$roadmap_generate_status <- renderUI({
          tags$div(class = "status-error", "Connect to Claude API first")
        })
        return()
      }
      
      if (trimws(input$roadmap_business_area) == "" || trimws(input$roadmap_project) == "" || 
          trimws(input$roadmap_business_focus) == "" || trimws(input$roadmap_business_description) == "") {
        output$roadmap_generate_status <- renderUI({
          tags$div(class = "status-error", "Fill in all fields")
        })
        return()
      }
      
      output$roadmap_generate_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Generating...")
      })
      
      tryCatch({
        prompt <- paste0(
          "Generate a Disciplined Entrepreneurship Roadmap with ALL 24 steps.\n",
          "Business: ", input$roadmap_business_area, " - ", input$roadmap_project, "\n",
          "Focus: ", input$roadmap_business_focus, "\n",
          "Description: ", input$roadmap_business_description, "\n\n",
          "Format EXACTLY:\n",
          "[Step 1: Market Segmentation]\n(content)\n\n",
          "[Step 2: Select a Beachhead Market]\n(content)\n\n",
          "... continue for all 24 steps with proper titles"
        )
        
        generated <- api_manager$call_claude(prompt)
        updateTextAreaInput(session, "roadmap_claude_output", value = generated)
        updateTextAreaInput(session, "roadmap_bulk_text", value = generated)
        
        output$roadmap_generate_status <- renderUI({
          tags$div(class = "status-success", "✓ Roadmap generated!")
        })
        showNotification("✓ Roadmap generated!", type = "message")
        
      }, error = function(e) {
        output$roadmap_generate_status <- renderUI({
          tags$div(class = "status-error", "Error: ", e$message)
        })
      })
    })
    
    # Parse Roadmap
    observeEvent(input$parseRoadmap, {
      if (trimws(input$roadmap_bulk_text) == "") {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", "Paste content first"))
        return()
      }
      
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing...")
      })
      
      tryCatch({
        text <- input$roadmap_bulk_text
        
        # Parse all 24 steps
        steps <- list()
        step_titles <- c(
          "Market Segmentation", "Select a Beachhead Market", "Build an End User Profile",
          "Calculate TAM Size for Beachhead Market", "Profile the Persona for the Beachhead Market",
          "Full Life Cycle Use Case", "High-Level Product Specification", "Quantify the Value Proposition",
          "Identify Your Next 10 Customers", "Define Your Core", "Chart Your Competitive Position",
          "Determine the Customer's Decision-Making Unit", "Map Process to Acquire Paying Customer",
          "Calculate TAM Size for Follow-on Markets", "Design a Business Model", "Set Your Pricing Framework",
          "Calculate Lifetime Value of an Acquired Customer", "Map Sales Process to Acquire a Customer",
          "Calculate the Cost of Customer Acquisition", "Identify Key Assumptions", "Test Key Assumptions",
          "Define the Minimum Viable Business Product.*?MVBP", "Show That.*?The Dogs Will Eat the Dog Food",
          "Develop a Product Plan"
        )
        
        for (i in 1:24) {
          pattern <- sprintf("(?i)\\[Step %d:?\\s*%s.*?\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)", i, step_titles[i])
          match <- stringr::str_match(text, pattern)[,2]
          steps[[sprintf("step_%02d", i)]] <- if (!is.na(match)) trimws(match) else NA
        }
        
        missing <- which(is.na(unlist(steps)))
        if (length(missing) > 0) {
          stop(paste("Missing steps:", paste(missing, collapse = ", ")))
        }
        
        parsed_roadmap(c(
          list(
            business_area = substr(trimws(input$roadmap_business_area), 1, 32),
            project = substr(trimws(input$roadmap_project), 1, 32),
            business_focus = substr(trimws(input$roadmap_business_focus), 1, 32)
          ),
          steps
        ))
        
        output$roadmapBulkStatus <- renderUI({
          tags$div(class = "status-success", "✓ All 24 steps parsed!")
        })
        
        output$roadmapParseInfo <- renderUI({
          tags$p(tags$strong("Parsed:"), " All 24 steps")
        })
        
        output$roadmapParsedPreview <- renderText({
          paste0("Business: ", parsed_roadmap()$business_area, "\n",
                 "Project: ", parsed_roadmap()$project, "\n",
                 "Focus: ", parsed_roadmap()$business_focus, "\n",
                 "Steps 1-24: Parsed successfully")
        })
        
        showNotification("✓ Roadmap parsed!", type = "message")
        
      }, error = function(e) {
        output$roadmapBulkStatus <- renderUI({
          tags$div(class = "status-error", "Parse failed: ", e$message)
        })
        parsed_roadmap(NULL)
      })
    })
    
    # Submit Roadmap
    observeEvent(input$submitRoadmap, {
      if (!api_manager$bq_authenticated) {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", "Authenticate BigQuery first"))
        return()
      }
      
      if (is.null(parsed_roadmap())) {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", "Parse first"))
        return()
      }
      
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting...")
      })
      
      tryCatch({
        roadmap_id <- paste0(
          gsub("[^A-Za-z0-9]", "_", parsed_roadmap()$business_area), "_",
          gsub("[^A-Za-z0-9]", "_", parsed_roadmap()$project), "_",
          gsub("[^A-Za-z0-9]", "_", parsed_roadmap()$business_focus), "_",
          format(Sys.time(), "%Y%m%d%H%M%S")
        )
        
        table_id <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        
        # Create table
        create_query <- sprintf("
        CREATE TABLE IF NOT EXISTS `%s` (
          roadmap_id STRING NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
          business_area STRING,
          project STRING,
          business_focus STRING,
          %s
        )", table_id, paste(sprintf("step_%02d_text STRING", 1:24), collapse = ",\n"))
        
        tryCatch(bigrquery::bq_project_query(api_manager$bq_project_id, create_query), error = function(e) {})
        
        # Insert
        step_values <- paste(sapply(1:24, function(i) {
          sprintf("'%s'", gsub("'", "\\\\'", parsed_roadmap()[[sprintf("step_%02d", i)]]))
        }), collapse = ", ")
        
        insert_query <- sprintf("
        INSERT INTO `%s` 
        (roadmap_id, created_at, updated_at, business_area, project, business_focus, %s) 
        VALUES ('%s', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), '%s', '%s', '%s', %s)",
                                table_id,
                                paste(sprintf("step_%02d_text", 1:24), collapse = ", "),
                                roadmap_id,
                                gsub("'", "\\\\'", parsed_roadmap()$business_area),
                                gsub("'", "\\\\'", parsed_roadmap()$project),
                                gsub("'", "\\\\'", parsed_roadmap()$business_focus),
                                step_values
        )
        
        bigrquery::bq_project_query(api_manager$bq_project_id, insert_query)
        
        output$roadmapBulkStatus <- renderUI({
          tags$div(class = "status-success", "✓ Submitted to BigQuery!")
        })
        showNotification("✓ Roadmap submitted!", type = "message")
        
      }, error = function(e) {
        output$roadmapBulkStatus <- renderUI({
          tags$div(class = "status-error", "Error: ", e$message)
        })
      })
    })
    
    # Clear
    observeEvent(input$clearRoadmap, {
      updateTextInput(session, "roadmap_business_area", value = "")
      updateTextInput(session, "roadmap_project", value = "")
      updateTextInput(session, "roadmap_business_focus", value = "")
      updateTextAreaInput(session, "roadmap_business_description", value = "")
      updateTextAreaInput(session, "roadmap_claude_output", value = "")
      updateTextAreaInput(session, "roadmap_bulk_text", value = "")
      parsed_roadmap(NULL)
      output$roadmapBulkStatus <- renderUI(tags$div(class = "status-info", "Cleared"))
      output$roadmapParseInfo <- renderUI(NULL)
      output$roadmapParsedPreview <- renderText("")
      output$roadmap_generate_status <- renderUI(NULL)
    })
    
  })
}
