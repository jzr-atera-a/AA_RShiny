# modules/process_contact/server.R
process_contact_server <- function(id, contact_manager, parent_session) {
  moduleServer(id, function(input, output, session) {
    
    extracted_data <- reactiveVal(NULL)
    
    # Extract text from file
    extract_text <- function(file_path, file_type) {
      if (grepl("\\.pdf$", file_type, ignore.case = TRUE)) {
        paste(pdftools::pdf_text(file_path), collapse = "\n")
      } else if (grepl("\\.(docx?)$", file_type, ignore.case = TRUE)) {
        readtext::readtext(file_path)$text
      } else {
        paste(readLines(file_path, warn = FALSE), collapse = "\n")
      }
    }
    
    # Process with LLM
    observeEvent(input$process_file, {
      if (!contact_manager$api_authenticated) {
        showNotification("Please configure API first!", type = "error", duration = 3)
        return()
      }
      
      has_file <- !is.null(input$contact_file)
      has_text <- nchar(trimws(input$contact_text)) > 0
      
      if (!has_file && !has_text) {
        showNotification("Please upload a file or paste text!", type = "error", duration = 3)
        return()
      }
      
      showNotification("Processing with LLM...", type = "message", duration = NULL, id = "processing")
      
      tryCatch({
        # Get text
        text <- if (has_file) {
          extract_text(input$contact_file$datapath, input$contact_file$name)
        } else {
          input$contact_text
        }
        
        # Call LLM
        prompt <- paste0(
          "Extract contact info as JSON with keys: full_name, industry, company, ",
          "job_title, location, country, email, phone, linkedin, areas_of_interest, ",
          "university, academic_background. Use 'Not specified' for missing fields.\n\n",
          "Text:\n", text
        )
        
        json_text <- contact_manager$call_llm(prompt, max_tokens = 1000)
        json_text <- gsub("```json\\s*", "", json_text)
        json_text <- gsub("```\\s*", "", json_text)
        json_text <- trimws(json_text)
        
        info <- jsonlite::fromJSON(json_text)
        
        # Convert to data frame
        data <- data.frame(
          Field = c("Full Name", "Industry", "Company", "Job Title", "Location", "Country",
                    "Email", "Phone", "LinkedIn", "Areas of Interest", "University", "Academic Background"),
          Value = c(info$full_name, info$industry, info$company, info$job_title,
                   info$location, info$country, info$email, info$phone,
                   info$linkedin, info$areas_of_interest, info$university, info$academic_background),
          stringsAsFactors = FALSE
        )
        
        extracted_data(data)
        
        removeNotification(id = "processing")
        output$process_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " Processed successfully!")
        })
        showNotification("Contact extracted successfully!", type = "message", duration = 3)
        
      }, error = function(e) {
        removeNotification(id = "processing")
        output$process_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
    
    # Render extracted data
    output$extracted_data_table <- DT::renderDataTable({
      req(extracted_data())
      DT::datatable(extracted_data(), options = list(dom = 't', paging = FALSE, ordering = FALSE),
                    editable = list(target = 'cell', disable = list(columns = 0)),
                    rownames = FALSE)
    })
    
    # Handle cell edits
    observeEvent(input$extracted_data_table_cell_edit, {
      info <- input$extracted_data_table_cell_edit
      data <- extracted_data()
      data[info$row, info$col + 1] <- info$value
      extracted_data(data)
    })
    
    # Preview data
    observeEvent(input$preview_data, {
      req(extracted_data())
      data <- extracted_data()
      
      preview_df <- data.frame(
        contact_id = uuid::UUIDgenerate(),
        full_name = data$Value[1],
        industry = data$Value[2],
        company = data$Value[3],
        job_title = data$Value[4],
        location = data$Value[5],
        country = data$Value[6],
        email = data$Value[7],
        phone = data$Value[8],
        linkedin = data$Value[9],
        areas_of_interest = data$Value[10],
        university = data$Value[11],
        academic_background = data$Value[12],
        user_notes = input$user_notes,
        last_interaction_date = as.character(input$last_interaction),
        created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        updated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        stringsAsFactors = FALSE
      )
      
      output$preview_table <- DT::renderDataTable({
        DT::datatable(t(preview_df), options = list(dom = 't', paging = FALSE, ordering = FALSE),
                      rownames = TRUE, colnames = "Value")
      })
    })
    
    # Send to BigQuery
    observeEvent(input$send_to_bq, {
      req(extracted_data())
      
      if (!contact_manager$bq_authenticated) {
        showNotification("Please configure BigQuery first!", type = "error", duration = 3)
        return()
      }
      
      showNotification("Sending to BigQuery...", type = "message", duration = NULL, id = "sending_bq")
      
      tryCatch({
        data <- extracted_data()
        
        record <- data.frame(
          contact_id = uuid::UUIDgenerate(),
          full_name = data$Value[1],
          industry = data$Value[2],
          company = data$Value[3],
          job_title = data$Value[4],
          location = data$Value[5],
          country = data$Value[6],
          email = data$Value[7],
          phone = data$Value[8],
          linkedin = data$Value[9],
          areas_of_interest = data$Value[10],
          university = data$Value[11],
          academic_background = data$Value[12],
          user_notes = input$user_notes,
          last_interaction_date = as.character(input$last_interaction),
          created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          updated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          stringsAsFactors = FALSE
        )
        
        contact_manager$insert_contact(record)
        
        removeNotification(id = "sending_bq")
        
        output$send_bq_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " Data sent successfully!")
        })
        
        showNotification("Data sent to BigQuery!", type = "message", duration = 3)
        
        # Clear form
        extracted_data(NULL)
        updateTextAreaInput(session, "user_notes", value = "")
        updateTextAreaInput(session, "contact_text", value = "")
        
      }, error = function(e) {
        removeNotification(id = "sending_bq")
        output$send_bq_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
    
    # Default outputs
    output$process_status <- renderUI({ tags$div() })
    output$send_bq_status <- renderUI({ tags$div() })
    output$extraction_message <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({
      DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE)
    })
  })
}
