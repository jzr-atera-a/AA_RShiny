# Generate Business Model Canvas Module - Server

generate_bm_canvas_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Local reactive values for this module
    parsed_canvas <- reactiveVal(NULL)
    
    # Generate Business Model Canvas with Claude
    observeEvent(input$generate_bm_canvas, {
      if (!api_manager$claude_connected) {
        output$generate_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please connect to Claude API first (see Claude API Connection tab)")
        })
        return()
      }
      
      if (is.null(input$business_area) || trimws(input$business_area) == "" ||
          is.null(input$project) || trimws(input$project) == "" ||
          is.null(input$business_focus) || trimws(input$business_focus) == "" ||
          is.null(input$business_description) || trimws(input$business_description) == "") {
        output$generate_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in all fields (Business Area, Project, Business Focus, and Description)")
        })
        return()
      }
      
      output$generate_status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Generating Business Model Canvas with Claude... Please wait.")
      })
      
      tryCatch({
        prompt <- paste0(
          "You are a business strategy expert specializing in the Business Model Canvas framework by Alexander Osterwalder.\n\n",
          "Business Area: ", input$business_area, "\n",
          "Project: ", input$project, "\n",
          "Business Focus: ", input$business_focus, "\n",
          "Business Description: ", input$business_description, "\n\n",
          "Based on the information above, generate a comprehensive Business Model Canvas with all 9 building blocks. ",
          "Format your response EXACTLY as follows, with each section starting with its title in square brackets:\n\n",
          "[Key Partners]\n(Provide detailed content about key partners, suppliers, strategic alliances)\n\n",
          "[Key Activities]\n(Provide detailed content about key activities needed to deliver value proposition)\n\n",
          "[Key Resources]\n(Provide detailed content about key resources required)\n\n",
          "[Value Propositions]\n(Provide detailed content about value propositions and what makes this business unique)\n\n",
          "[Customer Relationships]\n(Provide detailed content about how to build and maintain customer relationships)\n\n",
          "[Channels]\n(Provide detailed content about channels to reach customers)\n\n",
          "[Customer Segments]\n(Provide detailed content about target customer segments)\n\n",
          "[Cost Structure]\n(Provide detailed content about major costs)\n\n",
          "[Revenue Streams]\n(Provide detailed content about revenue sources)\n\n",
          "Make the content specific, actionable, and tailored to the business description provided. ",
          "Include relevant details, examples, and strategic considerations for each section."
        )
        
        generated_content <- api_manager$call_claude(prompt)
        
        updateTextAreaInput(session, "claude_output", value = generated_content)
        updateTextAreaInput(session, "bulk_text", value = generated_content)
        
        output$generate_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Business Model Canvas generated successfully!",
                   br(),
                   tags$small("Review the content above and click 'Parse Canvas Data' when ready"))
        })
        
        showNotification("✓ Canvas generated successfully!", type = "message")
        
      }, error = function(e) {
        output$generate_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Generation failed: ",
                   br(),
                   tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Parse canvas data
    observeEvent(input$parseCanvas, {
      
      if (is.null(input$bulk_text) || trimws(input$bulk_text) == "") {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please paste canvas content to parse")
        })
        return()
      }
      
      if (is.null(input$business_area) || trimws(input$business_area) == "") {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please provide Business Area")
        })
        return()
      }
      
      if (is.null(input$project) || trimws(input$project) == "") {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please provide Project name")
        })
        return()
      }
      
      if (is.null(input$business_focus) || trimws(input$business_focus) == "") {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please provide Business Focus")
        })
        return()
      }
      
      output$bulkStatus <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"), 
                 " Parsing canvas data...")
      })
      
      tryCatch({
        text <- input$bulk_text
        
        key_partners <- stringr::str_match(text, "(?i)\\[Key Partners\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        key_activities <- stringr::str_match(text, "(?i)\\[Key Activities\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        key_resources <- stringr::str_match(text, "(?i)\\[Key Resources\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        value_propositions <- stringr::str_match(text, "(?i)\\[Value Propositions\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        customer_relationships <- stringr::str_match(text, "(?i)\\[Customer Relationships\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        channels <- stringr::str_match(text, "(?i)\\[Channels\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        customer_segments <- stringr::str_match(text, "(?i)\\[Customer Segments\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        cost_structure <- stringr::str_match(text, "(?i)\\[Cost Structure\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        revenue_streams <- stringr::str_match(text, "(?i)\\[Revenue Streams\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
        
        missing_sections <- c()
        if (is.na(key_partners)) missing_sections <- c(missing_sections, "Key Partners")
        if (is.na(key_activities)) missing_sections <- c(missing_sections, "Key Activities")
        if (is.na(key_resources)) missing_sections <- c(missing_sections, "Key Resources")
        if (is.na(value_propositions)) missing_sections <- c(missing_sections, "Value Propositions")
        if (is.na(customer_relationships)) missing_sections <- c(missing_sections, "Customer Relationships")
        if (is.na(channels)) missing_sections <- c(missing_sections, "Channels")
        if (is.na(customer_segments)) missing_sections <- c(missing_sections, "Customer Segments")
        if (is.na(cost_structure)) missing_sections <- c(missing_sections, "Cost Structure")
        if (is.na(revenue_streams)) missing_sections <- c(missing_sections, "Revenue Streams")
        
        if (length(missing_sections) > 0) {
          stop(paste("Missing sections:", paste(missing_sections, collapse = ", "), 
                     "\n\nPlease ensure all 9 sections are included with proper [Section Name] headers."))
        }
        
        parsed_canvas(list(
          business_area = substr(trimws(input$business_area), 1, 32),
          project = substr(trimws(input$project), 1, 32),
          business_focus = substr(trimws(input$business_focus), 1, 32),
          key_partners = trimws(key_partners),
          key_activities = trimws(key_activities),
          key_resources = trimws(key_resources),
          value_propositions = trimws(value_propositions),
          customer_relationships = trimws(customer_relationships),
          channels = trimws(channels),
          customer_segments = trimws(customer_segments),
          cost_structure = trimws(cost_structure),
          revenue_streams = trimws(revenue_streams)
        ))
        
        output$bulkStatus <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Successfully parsed Business Model Canvas!",
                   br(),
                   tags$small("Business Area: ", parsed_canvas()$business_area),
                   br(),
                   tags$small("Project: ", parsed_canvas()$project),
                   br(),
                   tags$small("Business Focus: ", parsed_canvas()$business_focus))
        })
        
        output$parseInfo <- renderUI({
          tags$p(
            tags$strong("Parsed Canvas Summary:"),
            br(),
            paste("Business Area:", parsed_canvas()$business_area),
            br(),
            paste("Project:", parsed_canvas()$project),
            br(),
            paste("Business Focus:", parsed_canvas()$business_focus),
            br(),
            "All 9 building blocks successfully parsed"
          )
        })
        
        output$parsedPreview <- renderText({
          paste0(
            "Business Area: ", parsed_canvas()$business_area, "\n",
            "Project: ", parsed_canvas()$project, "\n",
            "Business Focus: ", parsed_canvas()$business_focus, "\n\n",
            "Key Partners: ", substr(parsed_canvas()$key_partners, 1, 100), "...\n\n",
            "Key Activities: ", substr(parsed_canvas()$key_activities, 1, 100), "...\n\n",
            "Key Resources: ", substr(parsed_canvas()$key_resources, 1, 100), "...\n\n",
            "Value Propositions: ", substr(parsed_canvas()$value_propositions, 1, 100), "...\n\n",
            "Customer Relationships: ", substr(parsed_canvas()$customer_relationships, 1, 100), "...\n\n",
            "Channels: ", substr(parsed_canvas()$channels, 1, 100), "...\n\n",
            "Customer Segments: ", substr(parsed_canvas()$customer_segments, 1, 100), "...\n\n",
            "Cost Structure: ", substr(parsed_canvas()$cost_structure, 1, 100), "...\n\n",
            "Revenue Streams: ", substr(parsed_canvas()$revenue_streams, 1, 100), "..."
          )
        })
        
        showNotification("✓ Canvas parsed successfully!", type = "message")
        
      }, error = function(e) {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Parsing failed: ",
                   br(),
                   tags$small(e$message))
        })
        parsed_canvas(NULL)
        output$parseInfo <- renderUI(NULL)
        output$parsedPreview <- renderText("")
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Submit canvas to BigQuery
    observeEvent(input$submitCanvas, {
      
      if (!api_manager$bq_authenticated) {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please authenticate first in the BigQuery Authentication tab")
        })
        return()
      }
      
      if (is.null(parsed_canvas())) {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please parse the canvas first by clicking 'Parse Canvas Data'")
        })
        return()
      }
      
      output$bulkStatus <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"), 
                 " Submitting to BigQuery... Please wait.")
      })
      
      tryCatch({
        canvas_id <- paste0(
          gsub("[^A-Za-z0-9]", "_", parsed_canvas()$business_area), "_",
          gsub("[^A-Za-z0-9]", "_", parsed_canvas()$project), "_",
          gsub("[^A-Za-z0-9]", "_", parsed_canvas()$business_focus), "_",
          format(Sys.time(), "%Y%m%d%H%M%S")
        )
        
        canvas_data <- data.frame(
          canvas_id = canvas_id,
          created_at = Sys.time(),
          updated_at = Sys.time(),
          business_area = parsed_canvas()$business_area,
          project = parsed_canvas()$project,
          business_focus = parsed_canvas()$business_focus,
          key_partners = parsed_canvas()$key_partners,
          key_activities = parsed_canvas()$key_activities,
          key_resources = parsed_canvas()$key_resources,
          value_propositions = parsed_canvas()$value_propositions,
          customer_relationships = parsed_canvas()$customer_relationships,
          channels = parsed_canvas()$channels,
          customer_segments = parsed_canvas()$customer_segments,
          cost_structure = parsed_canvas()$cost_structure,
          revenue_streams = parsed_canvas()$revenue_streams,
          stringsAsFactors = FALSE
        )
        
        table_ref <- bigrquery::bq_table(api_manager$bq_project_id, api_manager$bq_dataset_id, api_manager$bq_table_id)
        bigrquery::bq_table_upload(table_ref, canvas_data, fields = NULL, write_disposition = "WRITE_APPEND")
        
        output$bulkStatus <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Successfully submitted Business Model Canvas to BigQuery!",
                   br(),
                   tags$small("Canvas ID: ", canvas_id))
        })
        
        showNotification("✓ Canvas submitted successfully!", type = "message")
        
      }, error = function(e) {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error submitting to BigQuery: ",
                   br(),
                   tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Clear all fields
    observeEvent(input$clearCanvas, {
      updateTextInput(session, "business_area", value = "")
      updateTextInput(session, "project", value = "")
      updateTextInput(session, "business_focus", value = "")
      updateTextAreaInput(session, "business_description", value = "")
      updateTextAreaInput(session, "claude_output", value = "")
      updateTextAreaInput(session, "bulk_text", value = "")
      parsed_canvas(NULL)
      output$bulkStatus <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-info-circle"),
                 " All fields cleared. Ready for new input.")
      })
      output$parseInfo <- renderUI(NULL)
      output$parsedPreview <- renderText("")
      output$generate_status <- renderUI(NULL)
    })
    
  })
}
