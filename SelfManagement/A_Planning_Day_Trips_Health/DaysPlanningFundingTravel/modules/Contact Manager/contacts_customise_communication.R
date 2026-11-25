# modules/Contact Manager/contacts_customise_communication.R
# ---- module ----------------------------------------------
# id:           contacts_customise_communication
# name:         Customise Communication
# icon:         comments
# description:  Generate personalized outreach messages with an LLM
# packages:     shiny, shinydashboard
# -----------------------------------------------------------

# ---- UI ----
contacts_customise_communication_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Communication Settings", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, selectInput(ns("comm_channel"), "Channel Type:",
                                 choices = c("LinkedIn", "Email", "WhatsApp", "General Message"), selected = "LinkedIn")),
            column(3, selectInput(ns("comm_purpose"), "Communication Purpose:",
                                 choices = c("Introduction", "Follow Up", "Partnership Enquiry",
                                           "Met at recent event", "Having something in common", "Other"), selected = "Introduction")),
            column(3, selectInput(ns("comm_language"), "Language:",
                                 choices = c("English UK", "English US", "Spanish LatinAmerica"), selected = "English UK")),
            column(3, selectInput(ns("comm_length"), "Message Length:", choices = c("50", "100", "180", "240", "500"), selected = "100"))
          )
      )
    ),
    fluidRow(
      box(title = "Selected Contact Profile", status = "info", solidHeader = TRUE, width = 12,
          htmlOutput(ns("contact_profile")))
    ),
    fluidRow(
      box(title = "Recent Communication History", status = "success", solidHeader = TRUE, width = 12,
          actionButton(ns("load_recent_messages"), "Load Last 3 Messages", class = "btn-info", icon = icon("history"), style = "margin-bottom: 15px;"),
          br(),
          htmlOutput(ns("recent_messages"))
      )
    ),
    fluidRow(
      box(title = "Message Customisation Guidelines", status = "primary", solidHeader = TRUE, width = 12,
          p("Provide specific guidelines and key points to include in the new message:"),
          textAreaInput(ns("message_guidelines"), NULL,
                        placeholder = "E.g., 'Mention our mutual interest in renewable energy'...", height = "150px", width = "100%"),
          br(),
          actionButton(ns("generate_message"), "Generate Message with LLM", class = "btn-success", icon = icon("magic"), style = "width: 100%;"),
          br(), br(),
          htmlOutput(ns("generate_status"))
      )
    ),
    fluidRow(
      box(title = "Generated Message", status = "success", solidHeader = TRUE, width = 12,
          htmlOutput(ns("generated_message")),
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
          br(),
          htmlOutput(ns("save_message_status"))
      )
    )
  )
}

# ---- Server ----
contacts_customise_communication_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    generated_text <- reactiveVal(NULL)

    output$contact_profile <- renderUI({
      api_manager$state_trigger_contacts()
      c <- api_manager$contacts_selected_contact
      if (is.null(c)) return(tags$p("No contact selected. Go to Explore Contacts and click 'Customise Communication'."))
      tagList(
        tags$h4(c$full_name %||% "Unknown"),
        tags$p(tags$strong("Company: "), c$company %||% "N/A", " | ", tags$strong("Title: "), c$job_title %||% "N/A"),
        tags$p(tags$strong("Location: "), c$location %||% "N/A", ", ", c$country %||% ""),
        tags$p(tags$strong("Industry: "), c$industry %||% "N/A"),
        tags$p(tags$strong("Areas of Interest: "), c$areas_of_interest %||% "N/A"),
        tags$p(tags$strong("Email: "), c$email %||% "N/A", " | ", tags$strong("LinkedIn: "), c$linkedin %||% "N/A")
      )
    })

    observeEvent(input$load_recent_messages, {
      c <- api_manager$contacts_selected_contact
      if (is.null(c)) { showNotification("No contact selected.", type = "warning"); return() }
      tryCatch({
        msgs <- api_manager$bq_get_recent_communications(c$contact_id, limit = 3)
        output$recent_messages <- renderUI({
          if (nrow(msgs) == 0) return(tags$p("No previous communications found."))
          tagList(lapply(seq_len(nrow(msgs)), function(i) {
            tags$div(class = "reference-box", style = "margin-bottom: 10px;",
                     tags$strong(msgs$channel_type[i], " - ", msgs$created_at[i]),
                     tags$p(msgs$message_content[i]))
          }))
        })
      }, error = function(e) showNotification(paste("Error:", e$message), type = "error"))
    })

    observeEvent(input$generate_message, {
      c <- api_manager$contacts_selected_contact
      if (is.null(c)) { showNotification("No contact selected.", type = "warning"); return() }
      if (!api_manager$contacts_api_authenticated) { showNotification("Please configure OpenAI API first!", type = "error"); return() }

      output$generate_status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Generating...") })

      tryCatch({
        prompt <- paste0(
          "Write a ", input$comm_channel, " message to ", c$full_name %||% "this contact",
          " (", c$job_title %||% "", " at ", c$company %||% "", "). ",
          "Purpose: ", input$comm_purpose, ". Language: ", input$comm_language, ". ",
          "Target length: approximately ", input$comm_length, " words. ",
          "Guidelines: ", if (nchar(trimws(input$message_guidelines %||% "")) > 0) input$message_guidelines else "None provided.",
          " Write only the message itself, no preamble."
        )

        message_text <- api_manager$call_openai(prompt, max_tokens = 800)
        generated_text(trimws(message_text))

        output$generated_message <- renderUI({ tags$div(class = "reference-box", tags$p(trimws(message_text))) })
        output$generate_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Message generated!")
        })
        showNotification("✓ Message generated!", type = "message")

      }, error = function(e) {
        output$generate_status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$save_message, {
      req(generated_text())
      c <- api_manager$contacts_selected_contact
      if (is.null(c)) { showNotification("No contact selected.", type = "warning"); return() }
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      tryCatch({
        record <- data.frame(
          message_id = uuid::UUIDgenerate(), contact_id = c$contact_id, channel_type = input$comm_channel,
          communication_purpose = input$comm_purpose, language = input$comm_language,
          message_length = input$comm_length, message_content = generated_text(), stringsAsFactors = FALSE
        )
        api_manager$bq_insert_communication(record)

        output$save_message_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Message saved!")
        })
        showNotification("✓ Message saved to BigQuery!", type = "message")

      }, error = function(e) {
        output$save_message_status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$send_to_email_tab, {
      req(generated_text())
      api_manager$contacts_generated_message <- generated_text()
      api_manager$trigger_state_update_contacts()
      nav_goto(session, "contacts_send_email")
      showNotification("✓ Message sent to Send Email tab!", type = "message")
    })

    output$recent_messages <- renderUI({ tags$div() })
    output$generate_status <- renderUI({ tags$div() })
    output$generated_message <- renderUI({ tags$div() })
    output$save_message_status <- renderUI({ tags$div() })

    session$onSessionEnded(function() {})
  })
}
