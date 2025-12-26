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
          "You are a business strategy expert specializing in Disciplined Entrepreneurship.\n\n",
          "Business Area: ", input$roadmap_business_area, "\n",
          "Project: ", input$roadmap_project, "\n",
          "Business Focus: ", input$roadmap_business_focus, "\n",
          "Business Description: ", input$roadmap_business_description, "\n\n",
          "Generate a comprehensive Disciplined Entrepreneurship Roadmap with ALL 24 steps.\n\n",
          "CRITICAL: You MUST include ALL 24 steps. Do NOT skip any steps.\n\n",
          "Format EXACTLY as follows (use these EXACT headers):\n\n",
          "[Step 1: Market Segmentation]\n",
          "(Detailed content for market segmentation)\n\n",
          "[Step 2: Select a Beachhead Market]\n",
          "(Detailed content for selecting beachhead market)\n\n",
          "[Step 3: Build an End User Profile]\n",
          "(Detailed content for end user profile)\n\n",
          "[Step 4: Calculate TAM Size for Beachhead Market]\n",
          "(Detailed content for TAM calculation)\n\n",
          "[Step 5: Profile the Persona for the Beachhead Market]\n",
          "(Detailed content for persona profiling)\n\n",
          "[Step 6: Full Life Cycle Use Case]\n",
          "(Detailed content for life cycle use case)\n\n",
          "[Step 7: High-Level Product Specification]\n",
          "(Detailed content for product specification)\n\n",
          "[Step 8: Quantify the Value Proposition]\n",
          "(Detailed content for value proposition)\n\n",
          "[Step 9: Identify Your Next 10 Customers]\n",
          "(Detailed content for next 10 customers)\n\n",
          "[Step 10: Define Your Core]\n",
          "(Detailed content for defining core)\n\n",
          "[Step 11: Chart Your Competitive Position]\n",
          "(Detailed content for competitive position)\n\n",
          "[Step 12: Determine the Customer's Decision-Making Unit]\n",
          "(Detailed content for DMU)\n\n",
          "[Step 13: Map Process to Acquire Paying Customer]\n",
          "(Detailed content for acquisition process)\n\n",
          "[Step 14: Calculate TAM Size for Follow-on Markets]\n",
          "(Detailed content for follow-on TAM)\n\n",
          "[Step 15: Design a Business Model]\n",
          "(Detailed content for business model)\n\n",
          "[Step 16: Set Your Pricing Framework]\n",
          "(Detailed content for pricing framework)\n\n",
          "[Step 17: Calculate Lifetime Value of an Acquired Customer]\n",
          "(Detailed content for LTV calculation)\n\n",
          "[Step 18: Map Sales Process to Acquire a Customer]\n",
          "(Detailed content for sales process)\n\n",
          "[Step 19: Calculate the Cost of Customer Acquisition]\n",
          "(Detailed content for CAC calculation)\n\n",
          "[Step 20: Identify Key Assumptions]\n",
          "(Detailed content for key assumptions)\n\n",
          "[Step 21: Test Key Assumptions]\n",
          "(Detailed content for testing assumptions)\n\n",
          "[Step 22: Define the Minimum Viable Business Product (MVBP)]\n",
          "(Detailed content for MVBP)\n\n",
          "[Step 23: Show That \"The Dogs Will Eat the Dog Food\"]\n",
          "(Detailed content for market validation)\n\n",
          "[Step 24: Develop a Product Plan]\n",
          "(Detailed content for product plan)\n\n",
          "IMPORTANT: Make sure you provide ALL 24 steps with specific, actionable content for this business."
        )
        
        generated <- api_manager$call_claude(prompt)
        updateTextAreaInput(session, "roadmap_claude_output", value = generated)
        updateTextAreaInput(session, "roadmap_bulk_text", value = generated)
        
        output$roadmap_generate_status <- renderUI({
          tags$div(class = "status-success", "✓ Roadmap generated! Review and click 'Parse Roadmap Data'")
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
        
        # Parse all 24 steps with EXACT patterns matching the prompt
        steps <- list()
        
        # Step patterns - match EXACTLY what we tell Claude to generate
        step_patterns <- list(
          "(?i)\\[Step 1:?\\s*Market Segmentation\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 2:?\\s*Select a Beachhead Market\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 3:?\\s*Build an End User Profile\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 4:?\\s*Calculate TAM Size for Beachhead Market\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 5:?\\s*Profile the Persona.*?Beachhead Market\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 6:?\\s*Full Life Cycle Use Case\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 7:?\\s*High-Level Product Specification\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 8:?\\s*Quantify the Value Proposition\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 9:?\\s*Identify Your Next 10 Customers\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 10:?\\s*Define Your Core\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 11:?\\s*Chart Your Competitive Position\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 12:?\\s*Determine.*?Customer'?s Decision-Making Unit\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 13:?\\s*Map Process to Acquire.*?Customer\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 14:?\\s*Calculate TAM Size for Follow-on Markets\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 15:?\\s*Design a Business Model\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 16:?\\s*Set Your Pricing Framework\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 17:?\\s*Calculate.*?Lifetime Value.*?Customer\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 18:?\\s*Map Sales Process.*?Customer\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 19:?\\s*Calculate.*?Cost of Customer Acquisition\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 20:?\\s*Identify Key Assumptions\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 21:?\\s*Test Key Assumptions\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 22:?\\s*Define.*?Minimum Viable Business Product.*?MVBP.*?\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 23:?\\s*Show That.*?Dogs Will Eat.*?Dog Food.*?\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)",
          "(?i)\\[Step 24:?\\s*Develop a Product Plan\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)"
        )
        
        for (i in 1:24) {
          match <- stringr::str_match(text, step_patterns[[i]])[,2]
          steps[[sprintf("step_%02d", i)]] <- if (!is.na(match)) trimws(match) else NA
        }
        
        missing <- which(is.na(unlist(steps)))
        if (length(missing) > 0) {
          stop(paste("Missing steps:", paste(missing, collapse = ", "), 
                     "\n\nPlease ensure ALL 24 steps are included with proper [Step X: Title] headers."))
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
          tags$div(class = "status-success", 
                   tags$i(class = "fa fa-check-circle"), 
                   " Successfully parsed all 24 steps!",
                   br(),
                   tags$small("Business Area: ", parsed_roadmap()$business_area),
                   br(),
                   tags$small("Project: ", parsed_roadmap()$project),
                   br(),
                   tags$small("Business Focus: ", parsed_roadmap()$business_focus))
        })
        
        output$roadmapParseInfo <- renderUI({
          tags$p(tags$strong("✓ All 24 steps parsed successfully!"),
                 br(), "Ready to submit to BigQuery.")
        })
        
        showNotification("✓ All 24 steps parsed!", type = "message")
        
      }, error = function(e) {
        output$roadmapBulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Parse failed: ", br(), tags$small(e$message))
        })
        parsed_roadmap(NULL)
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Submit to BigQuery
    observeEvent(input$submitRoadmap, {
      if (!api_manager$bq_authenticated) {
        output$roadmapBulkStatus <- renderUI({
          tags$div(class = "status-error", "Authenticate BigQuery first")
        })
        return()
      }
      
      if (is.null(parsed_roadmap())) {
        output$roadmapBulkStatus <- renderUI({
          tags$div(class = "status-error", "Parse roadmap first")
        })
        return()
      }
      
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting...")
      })
      
      tryCatch({
        table_id <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        
        # Create table if doesn't exist
        create_query <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            roadmap_id STRING NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            business_area STRING,
            project STRING,
            business_focus STRING,
            step_01_market_segmentation STRING,
            step_02_select_beachhead_market STRING,
            step_03_build_end_user_profile STRING,
            step_04_calculate_tam_beachhead STRING,
            step_05_profile_persona STRING,
            step_06_full_life_cycle_use_case STRING,
            step_07_high_level_product_spec STRING,
            step_08_quantify_value_proposition STRING,
            step_09_identify_next_10_customers STRING,
            step_10_define_your_core STRING,
            step_11_chart_competitive_position STRING,
            step_12_determine_dmu STRING,
            step_13_map_process_acquire_customer STRING,
            step_14_calculate_tam_followon STRING,
            step_15_design_business_model STRING,
            step_16_set_pricing_framework STRING,
            step_17_calculate_ltv STRING,
            step_18_map_sales_process STRING,
            step_19_calculate_cac STRING,
            step_20_identify_key_assumptions STRING,
            step_21_test_key_assumptions STRING,
            step_22_define_mvbp STRING,
            step_23_dogs_eat_dog_food STRING,
            step_24_develop_product_plan STRING
          )", table_id)
        
        bigrquery::bq_project_query(api_manager$bq_project_id, create_query)
        
        # Prepare data frame
        roadmap_data <- data.frame(
          roadmap_id = paste0(
            gsub("[^A-Za-z0-9]", "_", parsed_roadmap()$business_area), "_",
            gsub("[^A-Za-z0-9]", "_", parsed_roadmap()$project), "_",
            gsub("[^A-Za-z0-9]", "_", parsed_roadmap()$business_focus), "_",
            format(Sys.time(), "%Y%m%d%H%M%S")
          ),
          created_at = Sys.time(),
          updated_at = Sys.time(),
          business_area = parsed_roadmap()$business_area,
          project = parsed_roadmap()$project,
          business_focus = parsed_roadmap()$business_focus,
          step_01_market_segmentation = parsed_roadmap()$step_01,
          step_02_select_beachhead_market = parsed_roadmap()$step_02,
          step_03_build_end_user_profile = parsed_roadmap()$step_03,
          step_04_calculate_tam_beachhead = parsed_roadmap()$step_04,
          step_05_profile_persona = parsed_roadmap()$step_05,
          step_06_full_life_cycle_use_case = parsed_roadmap()$step_06,
          step_07_high_level_product_spec = parsed_roadmap()$step_07,
          step_08_quantify_value_proposition = parsed_roadmap()$step_08,
          step_09_identify_next_10_customers = parsed_roadmap()$step_09,
          step_10_define_your_core = parsed_roadmap()$step_10,
          step_11_chart_competitive_position = parsed_roadmap()$step_11,
          step_12_determine_dmu = parsed_roadmap()$step_12,
          step_13_map_process_acquire_customer = parsed_roadmap()$step_13,
          step_14_calculate_tam_followon = parsed_roadmap()$step_14,
          step_15_design_business_model = parsed_roadmap()$step_15,
          step_16_set_pricing_framework = parsed_roadmap()$step_16,
          step_17_calculate_ltv = parsed_roadmap()$step_17,
          step_18_map_sales_process = parsed_roadmap()$step_18,
          step_19_calculate_cac = parsed_roadmap()$step_19,
          step_20_identify_key_assumptions = parsed_roadmap()$step_20,
          step_21_test_key_assumptions = parsed_roadmap()$step_21,
          step_22_define_mvbp = parsed_roadmap()$step_22,
          step_23_dogs_eat_dog_food = parsed_roadmap()$step_23,
          step_24_develop_product_plan = parsed_roadmap()$step_24,
          stringsAsFactors = FALSE
        )
        
        # Upload to BigQuery
        table_ref <- bigrquery::bq_table(api_manager$bq_project_id, api_manager$bq_dataset_id, "disciplined_entrepreneurship_roadmap")
        bigrquery::bq_table_upload(table_ref, roadmap_data, fields = NULL, write_disposition = "WRITE_APPEND")
        
        output$roadmapBulkStatus <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Successfully submitted roadmap to BigQuery!",
                   br(),
                   tags$small("Roadmap ID: ", roadmap_data$roadmap_id))
        })
        
        showNotification("✓ Roadmap submitted successfully!", type = "message")
        
      }, error = function(e) {
        output$roadmapBulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Submission failed: ", br(), tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Clear form
    observeEvent(input$clearRoadmap, {
      updateTextInput(session, "roadmap_business_area", value = "")
      updateTextInput(session, "roadmap_project", value = "")
      updateTextInput(session, "roadmap_business_focus", value = "")
      updateTextAreaInput(session, "roadmap_business_description", value = "")
      updateTextAreaInput(session, "roadmap_claude_output", value = "")
      updateTextAreaInput(session, "roadmap_bulk_text", value = "")
      parsed_roadmap(NULL)
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-info", "All fields cleared")
      })
      output$roadmapParseInfo <- renderUI(NULL)
      output$roadmap_generate_status <- renderUI(NULL)
    })
    
  })
}
