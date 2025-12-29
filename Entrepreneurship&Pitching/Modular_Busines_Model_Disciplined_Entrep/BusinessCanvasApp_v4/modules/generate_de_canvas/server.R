# Generate DE Canvas Module - Server

generate_de_canvas_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    parsed_de_canvas <- reactiveVal(NULL)
    
    # Generate DE Canvas
    observeEvent(input$generate_de_canvas, {
      if (!api_manager$claude_connected) {
        output$de_generate_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please connect to Claude API first (see Claude API Connection tab)")
        })
        return()
      }
      
      if (is.null(input$de_business_area) || trimws(input$de_business_area) == "" ||
          is.null(input$de_project) || trimws(input$de_project) == "" ||
          is.null(input$de_business_focus) || trimws(input$de_business_focus) == "" ||
          is.null(input$de_business_description) || trimws(input$de_business_description) == "") {
        output$de_generate_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in all fields")
        })
        return()
      }
      
      output$de_generate_status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Generating Disciplined Entrepreneurship Canvas with Claude... Please wait.")
      })
      
      tryCatch({
        prompt <- paste0(
          "You are a business strategy expert specializing in the Disciplined Entrepreneurship framework.\n\n",
          "Business Area: ", input$de_business_area, "\n",
          "Project: ", input$de_project, "\n",
          "Business Focus: ", input$de_business_focus, "\n",
          "Business Description: ", input$de_business_description, "\n\n",
          "Based on the information above, generate a comprehensive Disciplined Entrepreneurship Canvas with all 10 sections. ",
          "Format your response EXACTLY as follows:\n\n",
          "[Raison d'Être]\nMission: (describe mission)\nPassion: (describe passion)\nValues: (describe core values)\n\n",
          "[Initial Market]\nBeachhead: (describe beachhead market)\nEnd User Profile: (describe end user)\n\n",
          "[Value Creation]\nUse Case: (describe use case)\nProduct Description: (describe product)\n\n",
          "[Competitive Advantage]\nMoats: (describe competitive moats)\nCore: (describe core competencies)\n\n",
          "[Customer Acquisition]\nDMU: (describe decision-making unit)\nProcess to Acquire Customer: (describe process)\n\n",
          "[Product Unit Economics]\nBusiness Model: (describe business model)\nEstimated Pricing: (describe pricing strategy)\n\n",
          "[Sales]\nPreferred Sales Channel: (describe sales channel)\nSales Funnel: (describe sales funnel)\n\n",
          "[Overall Economics]\nEstimated R&D Expenses: (describe R&D costs)\nEstimated G&A Expenses: (describe G&A costs)\n\n",
          "[Design & Build]\nIdentify Key Assumptions: (list assumptions)\nTest Key Assumptions: (describe testing approach)\n\n",
          "[Scaling]\nProduct Plan for Beachhead: (describe initial plan)\nNext Market: (describe expansion strategy)\n\n",
          "Make the content specific, actionable, and tailored to the business description provided."
        )
        
        generated_content <- api_manager$call_claude(prompt)
        
        updateTextAreaInput(session, "de_claude_output", value = generated_content)
        updateTextAreaInput(session, "de_bulk_text", value = generated_content)
        
        output$de_generate_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " DE Canvas generated successfully!",
                   br(),
                   tags$small("Review the content above and click 'Parse Canvas Data' when ready"))
        })
        
        showNotification("✓ DE Canvas generated successfully!", type = "message")
        
      }, error = function(e) {
        output$de_generate_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Generation failed: ",
                   br(),
                   tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Parse DE Canvas
    observeEvent(input$parseDECanvas, {
      
      if (is.null(input$de_bulk_text) || trimws(input$de_bulk_text) == "") {
        output$deBulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please paste canvas content to parse")
        })
        return()
      }
      
      if (is.null(input$de_business_area) || trimws(input$de_business_area) == "" ||
          is.null(input$de_project) || trimws(input$de_project) == "" ||
          is.null(input$de_business_focus) || trimws(input$de_business_focus) == "") {
        output$deBulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please provide Business Area, Project, and Business Focus")
        })
        return()
      }
      
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"), 
                 " Parsing canvas data...")
      })
      
      tryCatch({
        text <- input$de_bulk_text
        
        raison_detre <- stringr::str_match(text, "(?i)\\[Raison d'Être\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        initial_market <- stringr::str_match(text, "(?i)\\[Initial Market\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        value_creation <- stringr::str_match(text, "(?i)\\[Value Creation\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        competitive_advantage <- stringr::str_match(text, "(?i)\\[Competitive Advantage\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        customer_acquisition <- stringr::str_match(text, "(?i)\\[Customer Acquisition\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        product_unit_economics <- stringr::str_match(text, "(?i)\\[Product Unit Economics\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        sales <- stringr::str_match(text, "(?i)\\[Sales\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        overall_economics <- stringr::str_match(text, "(?i)\\[Overall Economics\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        design_build <- stringr::str_match(text, "(?i)\\[Design & Build\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        scaling <- stringr::str_match(text, "(?i)\\[Scaling\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        
        missing_sections <- c()
        if (is.na(raison_detre)) missing_sections <- c(missing_sections, "Raison d'Être")
        if (is.na(initial_market)) missing_sections <- c(missing_sections, "Initial Market")
        if (is.na(value_creation)) missing_sections <- c(missing_sections, "Value Creation")
        if (is.na(competitive_advantage)) missing_sections <- c(missing_sections, "Competitive Advantage")
        if (is.na(customer_acquisition)) missing_sections <- c(missing_sections, "Customer Acquisition")
        if (is.na(product_unit_economics)) missing_sections <- c(missing_sections, "Product Unit Economics")
        if (is.na(sales)) missing_sections <- c(missing_sections, "Sales")
        if (is.na(overall_economics)) missing_sections <- c(missing_sections, "Overall Economics")
        if (is.na(design_build)) missing_sections <- c(missing_sections, "Design & Build")
        if (is.na(scaling)) missing_sections <- c(missing_sections, "Scaling")
        
        if (length(missing_sections) > 0) {
          stop(paste("Missing sections:", paste(missing_sections, collapse = ", ")))
        }
        
        parsed_de_canvas(list(
          business_area = substr(trimws(input$de_business_area), 1, 32),
          project = substr(trimws(input$de_project), 1, 32),
          business_focus = substr(trimws(input$de_business_focus), 1, 32),
          raison_detre = trimws(raison_detre),
          initial_market = trimws(initial_market),
          value_creation = trimws(value_creation),
          competitive_advantage = trimws(competitive_advantage),
          customer_acquisition = trimws(customer_acquisition),
          product_unit_economics = trimws(product_unit_economics),
          sales = trimws(sales),
          overall_economics = trimws(overall_economics),
          design_build = trimws(design_build),
          scaling = trimws(scaling)
        ))
        
        output$deBulkStatus <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Successfully parsed DE Canvas!",
                   br(),
                   tags$small("All 10 sections parsed"))
        })
        
        output$deParseInfo <- renderUI({
          tags$p(
            tags$strong("Parsed DE Canvas Summary:"),
            br(),
            paste("Business Area:", parsed_de_canvas()$business_area),
            br(),
            paste("Project:", parsed_de_canvas()$project),
            br(),
            paste("Business Focus:", parsed_de_canvas()$business_focus)
          )
        })
        
        output$deParsedPreview <- renderText({
          paste0(
            "Business Area: ", parsed_de_canvas()$business_area, "\n",
            "Project: ", parsed_de_canvas()$project, "\n",
            "Business Focus: ", parsed_de_canvas()$business_focus, "\n\n",
            "Raison d'Être: ", substr(parsed_de_canvas()$raison_detre, 1, 150), "...\n\n",
            "Initial Market: ", substr(parsed_de_canvas()$initial_market, 1, 150), "...\n\n",
            "Value Creation: ", substr(parsed_de_canvas()$value_creation, 1, 150), "...\n\n",
            "Competitive Advantage: ", substr(parsed_de_canvas()$competitive_advantage, 1, 150), "...\n\n",
            "Customer Acquisition: ", substr(parsed_de_canvas()$customer_acquisition, 1, 150), "...\n\n",
            "[All 10 sections successfully parsed - full content will be saved to BigQuery]"
          )
        })
        
        showNotification("✓ DE Canvas parsed successfully!", type = "message")
        
      }, error = function(e) {
        output$deBulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Parsing failed: ", e$message)
        })
        parsed_de_canvas(NULL)
      })
    })
    
    # Submit DE Canvas - FIXED VERSION USING bq_table_upload
    observeEvent(input$submitDECanvas, {
      
      if (!api_manager$bq_authenticated) {
        output$deBulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please authenticate BigQuery first")
        })
        return()
      }
      
      if (is.null(parsed_de_canvas())) {
        output$deBulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please parse the canvas first")
        })
        return()
      }
      
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"), 
                 " Submitting to BigQuery...")
      })
      
      tryCatch({
        canvas_id <- paste0(
          gsub("[^A-Za-z0-9]", "_", parsed_de_canvas()$business_area), "_",
          gsub("[^A-Za-z0-9]", "_", parsed_de_canvas()$project), "_",
          gsub("[^A-Za-z0-9]", "_", parsed_de_canvas()$business_focus), "_",
          format(Sys.time(), "%Y%m%d%H%M%S")
        )
        
        # Create table if not exists
        create_de_table_query <- sprintf("
        CREATE TABLE IF NOT EXISTS `%s.%s.disciplined_entrepreneurship_canvas` (
          canvas_id STRING NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
          business_area STRING,
          project STRING,
          business_focus STRING,
          raison_detre STRING,
          initial_market STRING,
          value_creation STRING,
          competitive_advantage STRING,
          customer_acquisition STRING,
          product_unit_economics STRING,
          sales STRING,
          overall_economics STRING,
          design_build STRING,
          scaling STRING
        )", api_manager$bq_project_id, api_manager$bq_dataset_id)
        
        tryCatch({
          bigrquery::bq_project_query(api_manager$bq_project_id, create_de_table_query)
        }, error = function(e) {})
        
        # Prepare data frame (CORRECT METHOD)
        canvas_data <- data.frame(
          canvas_id = canvas_id,
          created_at = Sys.time(),
          updated_at = Sys.time(),
          business_area = parsed_de_canvas()$business_area,
          project = parsed_de_canvas()$project,
          business_focus = parsed_de_canvas()$business_focus,
          raison_detre = parsed_de_canvas()$raison_detre,
          initial_market = parsed_de_canvas()$initial_market,
          value_creation = parsed_de_canvas()$value_creation,
          competitive_advantage = parsed_de_canvas()$competitive_advantage,
          customer_acquisition = parsed_de_canvas()$customer_acquisition,
          product_unit_economics = parsed_de_canvas()$product_unit_economics,
          sales = parsed_de_canvas()$sales,
          overall_economics = parsed_de_canvas()$overall_economics,
          design_build = parsed_de_canvas()$design_build,
          scaling = parsed_de_canvas()$scaling,
          stringsAsFactors = FALSE
        )
        
        # Upload using bq_table_upload (CORRECT METHOD - NO SQL INJECTION)
        table_ref <- bigrquery::bq_table(api_manager$bq_project_id, api_manager$bq_dataset_id, "disciplined_entrepreneurship_canvas")
        bigrquery::bq_table_upload(table_ref, canvas_data, fields = NULL, write_disposition = "WRITE_APPEND")
        
        output$deBulkStatus <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Successfully submitted DE Canvas to BigQuery!",
                   br(),
                   tags$small("Canvas ID: ", canvas_id))
        })
        
        showNotification("✓ DE Canvas submitted successfully!", type = "message")
        
      }, error = function(e) {
        output$deBulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Clear
    observeEvent(input$clearDECanvas, {
      updateTextInput(session, "de_business_area", value = "")
      updateTextInput(session, "de_project", value = "")
      updateTextInput(session, "de_business_focus", value = "")
      updateTextAreaInput(session, "de_business_description", value = "")
      updateTextAreaInput(session, "de_claude_output", value = "")
      updateTextAreaInput(session, "de_bulk_text", value = "")
      parsed_de_canvas(NULL)
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-info-circle"),
                 " All fields cleared.")
      })
      output$deParseInfo <- renderUI(NULL)
      output$deParsedPreview <- renderText("")
      output$de_generate_status <- renderUI(NULL)
    })
    
  })
}
