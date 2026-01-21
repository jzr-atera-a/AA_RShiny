# modules/customise_communication/server.R
customise_communication_server <- function(id, contact_manager, parent_session) {
  moduleServer(id, function(input, output, session) {
    
    # Display selected contact
    output$contact_profile <- renderUI({
      if (is.null(contact_manager$selected_contact)) {
        return(div(class = "empty-state",
                   div(class = "empty-state-icon", icon("user-slash")),
                   p("No contact selected."),
                   p("Please go to 'Explore Contacts' and select a contact.")))
      }
      
      contact <- contact_manager$selected_contact
      
      tagList(
        h4(icon("user"), " ", contact$full_name),
        tags$hr(style = "border-color: #4a90e2;"),
        fluidRow(
          column(6,
                 p(tags$strong("Company: "), contact$company),
                 p(tags$strong("Job Title: "), contact$job_title),
                 p(tags$strong("Industry: "), contact$industry),
                 p(tags$strong("Location: "), contact$location, ", ", contact$country)),
          column(6,
                 p(tags$strong("Email: "), contact$email),
                 p(tags$strong("Phone: "), contact$phone),
                 p(tags$strong("LinkedIn: "), contact$linkedin),
                 p(tags$strong("University: "), contact$university))
        ),
        tags$hr(style = "border-color: #4a90e2;"),
        p(tags$strong("Areas of Interest: "), contact$areas_of_interest),
        p(tags$strong("Academic Background: "), contact$academic_background),
        p(tags$strong("Notes: "), contact$user_notes)
      )
    })
    
    # Load recent messages
    observeEvent(input$load_recent_messages, {
      if (is.null(contact_manager$selected_contact)) {
        showNotification("No contact selected!", type = "warning", duration = 3)
        return()
      }
      
      showNotification("Loading recent messages...", type = "message", duration = NULL, id = "load_msgs")
      
      tryCatch({
        # Query BigQuery for recent messages
        con <- DBI::dbConnect(
          bigrquery::bigquery(),
          project = contact_manager$bq_project,
          dataset = contact_manager$bq_dataset,
          billing = contact_manager$bq_project
        )
        
        query <- sprintf("
          SELECT * FROM `%s.%s.%s`
          WHERE contact_id = '%s'
          ORDER BY created_at DESC LIMIT 3
        ", contact_manager$bq_project, contact_manager$bq_dataset, 
           contact_manager$bq_comm_table, contact_manager$selected_contact$contact_id)
        
        messages_data <- DBI::dbGetQuery(con, query)
        DBI::dbDisconnect(con)
        
        if (nrow(messages_data) > 0) {
          contact_manager$recent_messages <- messages_data
        } else {
          contact_manager$recent_messages <- NULL
        }
        
        removeNotification(id = "load_msgs")
        
        output$recent_messages <- renderUI({
          if (is.null(contact_manager$recent_messages) || nrow(contact_manager$recent_messages) == 0) {
            return(div(class = "empty-state",
                       div(class = "empty-state-icon", icon("comments")),
                       p(icon("info-circle"), " No previous messages found.")))
          }
          
          messages <- contact_manager$recent_messages
          
          message_list <- lapply(1:nrow(messages), function(i) {
            div(
              style = "border-bottom: 1px solid #4a90e2; padding: 10px 0; margin: 10px 0;",
              p(tags$strong(icon("calendar"), " ", messages$created_at[i]), style = "color: #7ec8e3;"),
              p(tags$strong("Channel: "), messages$channel_type[i], " | ",
                tags$strong("Purpose: "), messages$communication_purpose[i]),
              p(messages$message_content[i], style = "font-style: italic;")
            )
          })
          
          do.call(tagList, message_list)
        })
        
        # Summarize if messages exist
        if (!is.null(contact_manager$recent_messages) && nrow(contact_manager$recent_messages) > 0) {
          summarize_communication()
        }
        
      }, error = function(e) {
        removeNotification(id = "load_msgs")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
    
    # Summarize communication
    summarize_communication <- function() {
      if (!contact_manager$api_authenticated) {
        output$communication_summary <- renderUI({ p("Configure API first to summarize.") })
        return()
      }
      
      showNotification("Summarizing communication...", type = "message", duration = NULL, id = "summarizing")
      
      messages_text <- paste(
        apply(contact_manager$recent_messages, 1, function(row) {
          paste0("Date: ", row["created_at"], "\nChannel: ", row["channel_type"],
                 "\nPurpose: ", row["communication_purpose"], "\nMessage: ", 
                 row["message_content"], "\n")
        }),
        collapse = "\n---\n"
      )
      
      prompt <- paste0(
        "Provide a concise summary of the communication history below. ",
        "Highlight main topics, relationship progression, and key points.\n\n",
        "Communication History:\n", messages_text
      )
      
      tryCatch({
        summary <- contact_manager$call_llm(prompt, max_tokens = 500)
        
        contact_manager$communication_summary <- summary
        
        output$communication_summary <- renderUI({
          div(
            p(icon("lightbulb"), tags$strong(" Communication Summary:"), 
              style = "color: #7ec8e3; margin-bottom: 10px;"),
            p(summary)
          )
        })
        
        removeNotification(id = "summarizing")
        
      }, error = function(e) {
        removeNotification(id = "summarizing")
        output$communication_summary <- renderUI({
          p("Error generating summary: ", e$message, style = "color: #e74c3c;")
        })
      })
    }
    
    # Generate message
    observeEvent(input$generate_message, {
      if (!contact_manager$api_authenticated) {
        showNotification("Configure API first!", type = "error", duration = 3)
        return()
      }
      
      if (is.null(contact_manager$selected_contact)) {
        showNotification("No contact selected!", type = "warning", duration = 3)
        return()
      }
      
      if (nchar(trimws(input$message_guidelines)) == 0) {
        showNotification("Provide message guidelines!", type = "warning", duration = 3)
        return()
      }
      
      showNotification("Generating message...", type = "message", duration = NULL, id = "generating")
      
      contact <- contact_manager$selected_contact
      
      history_context <- ""
      if (!is.null(contact_manager$communication_summary)) {
        history_context <- paste0("\n\nCommunication History Summary:\n", 
                                  contact_manager$communication_summary)
      }
      
      prompt <- paste0(
        "Generate a professional ", input$comm_channel, " message for this contact.\n\n",
        "CONTACT INFORMATION:\n",
        "Name: ", contact$full_name, "\n",
        "Company: ", contact$company, "\n",
        "Job Title: ", contact$job_title, "\n",
        "Industry: ", contact$industry, "\n",
        "Areas of Interest: ", contact$areas_of_interest, "\n",
        history_context, "\n\n",
        "MESSAGE REQUIREMENTS:\n",
        "Channel: ", input$comm_channel, "\n",
        "Purpose: ", input$comm_purpose, "\n",
        "Language: ", input$comm_language, "\n",
        "Target Length: approximately ", input$comm_length, " words\n\n",
        "CUSTOMISATION GUIDELINES:\n",
        input$message_guidelines, "\n\n",
        "Return ONLY the message text, no additional commentary."
      )
      
      tryCatch({
        message_text <- contact_manager$call_llm(prompt, max_tokens = as.integer(input$comm_length) * 2)
        
        contact_manager$generated_message <- message_text
        
        output$generated_message <- renderUI({
          div(
            p(icon("envelope"), tags$strong(" Generated Message:"), 
              style = "color: #7ec8e3; margin-bottom: 10px;"),
            tags$hr(style = "border-color: #4a90e2;"),
            p(message_text, style = "white-space: pre-wrap; line-height: 1.8;"),
            tags$hr(style = "border-color: #4a90e2;"),
            p(tags$small(icon("info-circle"), " Channel: ", input$comm_channel, 
                         " | Purpose: ", input$comm_purpose,
                         " | Language: ", input$comm_language),
              style = "color: #a0aec0;")
          )
        })
        
        removeNotification(id = "generating")
        
        output$generate_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " Message generated successfully!")
        })
        
        showNotification("Message generated!", type = "message", duration = 3)
        
      }, error = function(e) {
        removeNotification(id = "generating")
        output$generate_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
    
    # Save message to BigQuery
    observeEvent(input$save_message, {
      if (is.null(contact_manager$generated_message)) {
        showNotification("Generate a message first!", type = "warning", duration = 3)
        return()
      }
      
      showNotification("Saving message...", type = "message", duration = NULL, id = "saving_msg")
      
      tryCatch({
        comm_record <- data.frame(
          message_id = uuid::UUIDgenerate(),
          contact_id = contact_manager$selected_contact$contact_id,
          channel_type = input$comm_channel,
          communication_purpose = input$comm_purpose,
          language = input$comm_language,
          message_length = input$comm_length,
          message_content = contact_manager$generated_message,
          created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          stringsAsFactors = FALSE
        )
        
        contact_manager$insert_communication(comm_record)
        
        removeNotification(id = "saving_msg")
        
        output$save_message_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " Message saved to BigQuery successfully!")
        })
        
        showNotification("Message saved!", type = "message", duration = 3)
        
      }, error = function(e) {
        removeNotification(id = "saving_msg")
        output$save_message_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
    
    # Copy to clipboard
    observeEvent(input$copy_message, {
      if (is.null(contact_manager$generated_message)) {
        showNotification("Generate a message first!", type = "warning", duration = 3)
        return()
      }
      
      showNotification("Message copied to clipboard!", type = "message", duration = 3)
    })
    
    # Send to email tab
    observeEvent(input$send_to_email_tab, {
      if (is.null(contact_manager$generated_message)) {
        showNotification("Generate a message first!", type = "warning", duration = 3)
        return()
      }
      
      if (is.null(contact_manager$selected_contact_email)) {
        showNotification("No email address available!", type = "error", duration = 5)
        return()
      }
      
      updateTabItems(session = parent_session, "sidebar_menu", "send_email")
      showNotification("Email tab loaded!", type = "message", duration = 3)
    })
    
    # Default outputs
    output$recent_messages <- renderUI({ tags$div() })
    output$communication_summary <- renderUI({ tags$div() })
    output$generated_message <- renderUI({ tags$div() })
    output$generate_status <- renderUI({ tags$div() })
    output$save_message_status <- renderUI({ tags$div() })
  })
}
