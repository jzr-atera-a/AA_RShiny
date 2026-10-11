# modules/Communications/customise_communication.R
# Subtab: Customise Communication (under the "Communications" main tab)

customise_communication_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Communication Settings", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, selectInput(ns("comm_channel"), "Channel Type:",
                                   choices = c("LinkedIn", "Email", "WhatsApp", "General Message"), selected = "LinkedIn", width = "100%")),
            column(3, selectInput(ns("comm_purpose"), "Communication Purpose:",
                                   choices = c("Introduction", "Follow Up", "Partnership Enquiry", "Met at recent event",
                                               "Having something in common", "Other"), selected = "Introduction", width = "100%")),
            column(3, selectInput(ns("comm_language"), "Language:",
                                   choices = c("English UK", "English US", "Spanish LatinAmerica"), selected = "English UK", width = "100%")),
            column(3, selectInput(ns("comm_length"), "Message Length:",
                                   choices = c("50 words" = "50", "100 words" = "100", "180 words" = "180",
                                               "240 words" = "240", "500 words" = "500"), selected = "100", width = "100%"))
          )
      )
    ),
    fluidRow(
      box(title = "Selected Contact Profile", status = "info", solidHeader = TRUE, width = 12,
          div(class = "profile-summary-box", uiOutput(ns("contact_profile_summary"))))
    ),
    fluidRow(
      box(title = "Recent Communication History", status = "success", solidHeader = TRUE, width = 12,
          actionButton(ns("load_recent_messages"), "Load Last 3 Messages", class = "btn-info", icon = icon("history"), style = "margin-bottom: 15px;"),
          br(), div(class = "message-box", uiOutput(ns("recent_messages_display"))))
    ),
    fluidRow(
      box(title = "Communication Summary (Claude Analysis)", status = "warning", solidHeader = TRUE, width = 12,
          div(class = "message-box", uiOutput(ns("communication_summary_ui"))))
    ),
    fluidRow(
      box(title = "Message Customisation Guidelines", status = "primary", solidHeader = TRUE, width = 12,
          p("Provide specific guidelines and key points to include in the new message:"),
          textAreaInput(ns("message_guidelines"), NULL,
                        placeholder = "E.g., 'Mention our mutual interest in renewable energy', 'Reference the conference in Barcelona', etc.",
                        height = "150px", width = "100%"),
          br(),
          actionButton(ns("generate_message"), "Generate Message with Claude", class = "btn-success", icon = icon("magic"), style = "width: 100%;"),
          br(), br(), uiOutput(ns("generate_status_ui")))
    ),
    fluidRow(
      box(title = "Generated Message", status = "success", solidHeader = TRUE, width = 12,
          div(class = "message-box", uiOutput(ns("generated_message_display"))),
          br(),
          fluidRow(
            column(6, actionButton(ns("save_message"), "Save Message to BigQuery", class = "btn-primary", icon = icon("save"), style = "width: 100%;")),
            column(6, actionButton(ns("copy_message"), "Copy to Clipboard", class = "btn-info", icon = icon("copy"), style = "width: 100%;"))
          ),
          br(),
          conditionalPanel(
            condition = sprintf("input['%s'] == 'Email'", ns("comm_channel")),
            actionButton(ns("send_to_email_tab"), "Send Email", class = "btn-success", icon = icon("envelope"), style = "width: 100%; margin-top: 10px;")
          ),
          br(), uiOutput(ns("save_message_status_ui")))
    )
  )
}

customise_communication_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    output$contact_profile_summary <- renderUI({
      contact <- api_manager$selected_contact()
      if (is.null(contact)) {
        return(div(class = "empty-state",
          div(class = "empty-state-icon", icon("user-slash")),
          p("No contact selected."),
          p("Please go to 'Explore Contacts' and select a contact, then click 'Customise Communication'.")))
      }
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
        p(tags$strong("Notes: "), contact$user_notes),
        p(tags$strong("Last Interaction: "), contact$last_interaction_date)
      )
    })

    summarize_communication <- function() {
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure your Claude API key first!", type = "error", duration = 3)
        return()
      }
      messages <- api_manager$recent_messages()
      if (is.null(messages) || nrow(messages) == 0) {
        output$communication_summary_ui <- renderUI({ p("No messages to summarize.") })
        return()
      }

      showNotification("Summarizing communication history with Claude...", type = "message", duration = NULL, id = "summarizing")

      messages_text <- paste(apply(messages, 1, function(row) {
        paste0("Date: ", row["created_at"], "\nChannel: ", row["channel_type"],
               "\nPurpose: ", row["communication_purpose"], "\nMessage: ", row["message_content"], "\n")
      }), collapse = "\n---\n")

      prompt <- paste0(
        "Please provide a concise summary of the communication history below. ",
        "Highlight the main topics discussed, the relationship progression, and any key points or follow-ups mentioned.\n\n",
        "Communication History:\n", messages_text
      )

      tryCatch({
        result <- api_manager$call_claude(prompt, max_tokens = 500,
          system = "You are a helpful assistant that summarizes communication history concisely.")
        api_manager$communication_summary(result$text)
        removeNotification(id = "summarizing")
        output$communication_summary_ui <- renderUI({
          div(p(icon("lightbulb"), tags$strong(" Communication Summary:"), style = "color: #7ec8e3; margin-bottom: 10px;"),
              p(result$text))
        })
      }, error = function(e) {
        removeNotification(id = "summarizing")
        output$communication_summary_ui <- renderUI({ p("Error: ", e$message, style = "color: #e74c3c;") })
      })
    }

    observeEvent(input$load_recent_messages, {
      contact <- api_manager$selected_contact()
      if (is.null(contact)) { showNotification("No contact selected!", type = "warning", duration = 3); return() }

      showNotification("Loading recent messages from BigQuery...", type = "message", duration = NULL, id = "load_msgs")

      tryCatch({
        messages_data <- api_manager$bq_get_recent_messages(contact$contact_id, n = 3)
        api_manager$recent_messages(if (nrow(messages_data) > 0) messages_data else NULL)
        removeNotification(id = "load_msgs")

        output$recent_messages_display <- renderUI({
          messages <- api_manager$recent_messages()
          if (is.null(messages) || nrow(messages) == 0) {
            return(div(class = "empty-state", div(class = "empty-state-icon", icon("comments")),
              p(icon("info-circle"), " No previous messages found for this contact.", style = "color: #7ec8e3;"),
              p("This is the first time you're communicating with ", contact$full_name, ".")))
          }
          do.call(tagList, lapply(seq_len(nrow(messages)), function(i) {
            div(style = "border-bottom: 1px solid #4a90e2; padding: 10px 0; margin: 10px 0;",
                p(tags$strong(icon("calendar"), " ", messages$created_at[i]), style = "color: #7ec8e3; margin-bottom: 5px;"),
                p(tags$strong("Channel: "), messages$channel_type[i], " | ", tags$strong("Purpose: "), messages$communication_purpose[i],
                  " | ", tags$strong("Language: "), messages$language[i]),
                p(messages$message_content[i], style = "font-style: italic;"))
          }))
        })

        if (!is.null(api_manager$recent_messages())) summarize_communication()
        else output$communication_summary_ui <- renderUI({
          div(class = "empty-state", p(icon("info-circle"), " No communication history to summarize.", style = "color: #7ec8e3;"))
        })

      }, error = function(e) {
        removeNotification(id = "load_msgs")
        showNotification(paste("Error loading messages:", e$message), type = "error", duration = 10)
      })
    })

    observeEvent(input$generate_message, {
      if (!api_manager$claude_authenticated) { showNotification("Please configure your Claude API key first!", type = "error", duration = 3); return() }
      contact <- api_manager$selected_contact()
      if (is.null(contact)) { showNotification("No contact selected!", type = "warning", duration = 3); return() }
      if (nchar(trimws(input$message_guidelines)) == 0) { showNotification("Please provide message customisation guidelines!", type = "warning", duration = 3); return() }

      showNotification("Generating message with Claude...", type = "message", duration = NULL, id = "generating")
      output$generate_status_ui <- renderUI({ div(class = "alert-info", icon("spinner", class = "fa-spin"), " Generating message...") })

      channel <- input$comm_channel; purpose <- input$comm_purpose; language <- input$comm_language; length <- input$comm_length

      history_context <- if (!is.null(api_manager$communication_summary())) {
        paste0("\n\nCommunication History Summary:\n", api_manager$communication_summary())
      } else ""

      prompt <- paste0(
        "Generate a professional ", channel, " message for the following contact.\n\n",
        "CONTACT INFORMATION:\nName: ", contact$full_name, "\nCompany: ", contact$company, "\nJob Title: ", contact$job_title,
        "\nIndustry: ", contact$industry, "\nAreas of Interest: ", contact$areas_of_interest, "\nUniversity: ", contact$university,
        "\nAcademic Background: ", contact$academic_background, "\nNotes: ", contact$user_notes,
        history_context, "\n\nMESSAGE REQUIREMENTS:\nChannel: ", channel, "\nPurpose: ", purpose, "\nLanguage: ", language,
        "\nTarget Length: approximately ", length, " words\n\nCUSTOMISATION GUIDELINES:\n", input$message_guidelines, "\n\n",
        "Please generate an appropriate message that:\n- Is written in ", language, "\n- Matches the tone and format appropriate for ", channel,
        "\n- Addresses the ", purpose, " purpose\n- Is approximately ", length, " words\n- Incorporates the customisation guidelines provided\n",
        "- Is personalized to the contact's background and interests\n\nReturn ONLY the message text, no additional commentary."
      )

      tryCatch({
        result <- api_manager$call_claude(prompt, max_tokens = as.integer(as.numeric(length) * 2),
          system = paste0("You are an expert at writing professional business communications. You understand the nuances of ",
                           "different channels (LinkedIn, Email, WhatsApp, etc.) and can adapt your writing style accordingly. ",
                           "You write in a warm, professional, and authentic voice that builds genuine connections."))

        api_manager$generated_message(result$text)
        removeNotification(id = "generating")

        output$generated_message_display <- renderUI({
          div(p(icon("envelope"), tags$strong(" Generated Message:"), style = "color: #7ec8e3; margin-bottom: 10px;"),
              tags$hr(style = "border-color: #4a90e2;"),
              p(result$text, style = "white-space: pre-wrap; line-height: 1.8;"),
              tags$hr(style = "border-color: #4a90e2;"),
              p(tags$small(icon("info-circle"), " Channel: ", channel, " | Purpose: ", purpose,
                           " | Language: ", language, " | Length: ~", length, " words"), style = "color: #a0aec0;"))
        })
        output$generate_status_ui <- renderUI({ div(class = "alert-success", icon("check-circle"), " Message generated successfully!") })
        showNotification("Message generated successfully!", type = "message", duration = 5)

      }, error = function(e) {
        removeNotification(id = "generating")
        output$generate_status_ui <- renderUI({ div(class = "alert-danger", icon("exclamation-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })

    observeEvent(input$save_message, {
      if (is.null(api_manager$generated_message())) { showNotification("Please generate a message first!", type = "warning", duration = 3); return() }
      if (!api_manager$bq_authenticated) { showNotification("Please configure BigQuery settings first!", type = "error", duration = 5); return() }

      showNotification("Saving message to BigQuery...", type = "message", duration = NULL, id = "saving_msg")

      tryCatch({
        contact <- api_manager$selected_contact()
        comm_record <- data.frame(
          message_id = UUIDgenerate(), contact_id = contact$contact_id, channel_type = input$comm_channel,
          communication_purpose = input$comm_purpose, language = input$comm_language, message_length = input$comm_length,
          message_content = api_manager$generated_message(), created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          stringsAsFactors = FALSE
        )
        api_manager$bq_insert_communication(comm_record)
        api_manager$recent_messages(NULL)

        removeNotification(id = "saving_msg")
        output$save_message_status_ui <- renderUI({
          div(class = "alert-success", icon("check-circle"), " Message saved to BigQuery successfully!",
              tags$br(), tags$small("Message ID: ", comm_record$message_id))
        })
        showNotification("Message saved successfully! Click 'Load Last 3 Messages' to see it.", type = "message", duration = 5)

      }, error = function(e) {
        removeNotification(id = "saving_msg")
        output$save_message_status_ui <- renderUI({ div(class = "alert-danger", icon("exclamation-circle"), " Error saving to BigQuery: ", e$message) })
        showNotification(paste("BigQuery Error:", e$message), type = "error", duration = 10)
      })
    })

    observeEvent(input$copy_message, {
      if (is.null(api_manager$generated_message())) { showNotification("Please generate a message first!", type = "warning", duration = 3); return() }
      shinyjs::runjs(paste0("navigator.clipboard.writeText(`", gsub("`", "\\`", api_manager$generated_message()),
                            "`).then(() => { Shiny.setInputValue('clipboard_success', Math.random()); });"))
      showNotification("Message copied to clipboard!", type = "message", duration = 3)
    })

    observeEvent(input$send_to_email_tab, {
      if (is.null(api_manager$generated_message())) { showNotification("Please generate a message first!", type = "warning", duration = 3); return() }
      if (is.null(api_manager$selected_contact_email())) { showNotification("No email address available for this contact!", type = "error", duration = 5); return() }

      # send_email module reads to/body/subject directly off api_manager
      api_manager$pending_email_subject(paste("Re:", input$comm_purpose))
      updateTabItems(session$rootScope(), "sidebar_menu", "send_email")
      showNotification("Email tab loaded with generated message!", type = "message", duration = 3)
    })

    output$recent_messages_display <- renderUI({ tags$div() })
    output$communication_summary_ui <- renderUI({ tags$div() })
    output$generated_message_display <- renderUI({ tags$div() })
    output$generate_status_ui <- renderUI({ tags$div() })
    output$save_message_status_ui <- renderUI({ tags$div() })
  })
}
