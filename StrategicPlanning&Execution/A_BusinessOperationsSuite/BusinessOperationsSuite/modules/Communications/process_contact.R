# modules/Communications/process_contact.R
# Subtab: Process Contact (under the "Communications" main tab)
# Upload/paste raw contact info -> Claude extracts structured fields -> BigQuery.

process_contact_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Upload or Paste Contact Information", status = "primary", solidHeader = TRUE, width = 12,
        p("Upload a file OR paste contact information in the text box below."),
        p("Claude will extract and structure the relevant information."),
        br(),
        div(class = "file-upload-box",
            fileInput(ns("contact_file"), "Choose File (Optional)",
                      accept = c(".pdf", ".docx", ".doc", ".pptx", ".ppt", ".txt", ".text"), width = "100%"),
            p(tags$small("Supported formats: PDF, DOCX, PPTX, TXT"))),
        br(),
        h4("OR paste contact information here:"),
        textAreaInput(ns("contact_text"), NULL,
                      placeholder = "Paste contact information here (e.g., email signature, LinkedIn profile, business card details, etc.)...",
                      height = "200px", width = "100%"),
        br(),
        actionButton(ns("process_file"), "Process with Claude", class = "btn-primary",
                     icon = icon("wand-magic-sparkles"), style = "width: 100%;"),
        br(), br(),
        uiOutput(ns("process_status_ui"))
      )
    ),
    fluidRow(
      box(title = "Extracted Contact Information", status = "info", solidHeader = TRUE, width = 12,
          DTOutput(ns("extracted_data_table")), br(), uiOutput(ns("extraction_message")))
    ),
    fluidRow(
      box(title = "Additional Information", status = "success", solidHeader = TRUE, width = 6,
          textAreaInput(ns("user_notes"), "Your Notes About This Contact:",
                        placeholder = "Add any personal notes, context, or follow-up items about this contact...",
                        height = "150px", width = "100%"),
          br(),
          dateInput(ns("last_interaction"), "Last Interaction Date:", value = Sys.Date(),
                    format = "yyyy-mm-dd", width = "100%")),
      box(title = "Send to BigQuery", status = "warning", solidHeader = TRUE, width = 6,
          p("Review the extracted data and your notes, then send to BigQuery."),
          p(tags$strong("Note: "), "Make sure BigQuery is configured in API Settings."),
          br(),
          actionButton(ns("preview_data"), "Preview Final Data", class = "btn-info", icon = icon("eye"),
                       style = "width: 100%; margin-bottom: 10px;"),
          actionButton(ns("send_to_bq"), "Send to BigQuery", class = "btn-success", icon = icon("cloud-upload-alt"),
                       style = "width: 100%;"),
          br(), br(),
          uiOutput(ns("send_bq_status_ui")))
    ),
    fluidRow(
      box(title = "Data Preview", status = "primary", solidHeader = TRUE, width = 12,
          collapsible = TRUE, collapsed = TRUE, DTOutput(ns("preview_table")))
    )
  )
}

process_contact_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    extracted_data <- reactiveVal(NULL)

    extract_text_from_file <- function(file_path, file_name) {
      tryCatch({
        if (grepl("\\.pdf$", file_name, ignore.case = TRUE)) {
          paste(pdftools::pdf_text(file_path), collapse = "\n")
        } else if (grepl("\\.(docx?|pptx?)$", file_name, ignore.case = TRUE)) {
          readtext::readtext(file_path)$text
        } else {
          paste(readLines(file_path, warn = FALSE), collapse = "\n")
        }
      }, error = function(e) paste("Error extracting text:", e$message))
    }

    extract_contact_info <- function(text) {
      prompt <- paste0(
        "Extract business contact information from the following text. ",
        "Return the data as a valid JSON object with these exact keys:\n",
        "- full_name, industry, company, job_title, location, country, email, phone, linkedin, ",
        "areas_of_interest, university, academic_background\n\n",
        "If a field is not found, use 'Not specified' as the value.\n",
        "Return ONLY valid JSON, no additional text, no markdown code fences.\n\n",
        "Text to analyze:\n", text
      )
      result <- api_manager$call_claude(prompt, max_tokens = 1000,
        system = "You are an expert at extracting structured contact information from documents. Always return valid JSON, nothing else.")

      json_text <- trimws(gsub("```json\\s*|```\\s*", "", result$text))
      jsonlite::fromJSON(json_text)
    }

    observeEvent(input$process_file, {
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure your Claude API key first (API Settings)!", type = "error", duration = 5)
        return()
      }

      has_file <- !is.null(input$contact_file)
      has_text <- nchar(trimws(input$contact_text)) > 0
      if (!has_file && !has_text) {
        showNotification("Please upload a file or paste contact information!", type = "error", duration = 5)
        return()
      }

      showNotification("Processing with Claude...", type = "message", duration = NULL, id = "processing")
      output$process_status_ui <- renderUI({
        div(class = "alert-info", icon("spinner", class = "fa-spin"), " Processing... This may take a moment.")
      })

      tryCatch({
        file_text <- if (has_file) {
          txt <- extract_text_from_file(input$contact_file$datapath, input$contact_file$name)
          if (startsWith(txt, "Error")) stop(txt)
          txt
        } else input$contact_text

        contact_info <- extract_contact_info(file_text)

        extracted_data(data.frame(
          Field = c("Full Name", "Industry", "Company", "Job Title", "Location", "Country",
                    "Email", "Phone", "LinkedIn", "Areas of Interest", "University", "Academic Background"),
          Value = c(
            contact_info$full_name %||% "Not specified", contact_info$industry %||% "Not specified",
            contact_info$company %||% "Not specified", contact_info$job_title %||% "Not specified",
            contact_info$location %||% "Not specified", contact_info$country %||% "Not specified",
            contact_info$email %||% "Not specified", contact_info$phone %||% "Not specified",
            contact_info$linkedin %||% "Not specified", contact_info$areas_of_interest %||% "Not specified",
            contact_info$university %||% "Not specified", contact_info$academic_background %||% "Not specified"
          ),
          stringsAsFactors = FALSE
        ))

        removeNotification(id = "processing")
        output$process_status_ui <- renderUI({
          div(class = "alert-success", icon("check-circle"), " Processed successfully! Review the extracted data below.")
        })
        showNotification("Contact information extracted successfully!", type = "message", duration = 5)

      }, error = function(e) {
        removeNotification(id = "processing")
        output$process_status_ui <- renderUI({
          div(class = "alert-danger", icon("exclamation-circle"), " Error processing: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })

    output$extracted_data_table <- renderDT({
      req(extracted_data())
      datatable(extracted_data(),
        options = list(dom = 't', paging = FALSE, ordering = FALSE,
                       columnDefs = list(list(width = '30%', targets = 0), list(width = '70%', targets = 1))),
        editable = list(target = 'cell', disable = list(columns = 0)), rownames = FALSE, class = 'cell-border stripe')
    })

    observeEvent(input$extracted_data_table_cell_edit, {
      info <- input$extracted_data_table_cell_edit
      df <- extracted_data()
      df[info$row, info$col + 1] <- info$value
      extracted_data(df)
    })

    build_record <- function() {
      d <- extracted_data()
      data.frame(
        contact_id = UUIDgenerate(),
        full_name = d$Value[1], industry = d$Value[2], company = d$Value[3], job_title = d$Value[4],
        location = d$Value[5], country = d$Value[6], email = d$Value[7], phone = d$Value[8],
        linkedin = d$Value[9], areas_of_interest = d$Value[10], university = d$Value[11],
        academic_background = d$Value[12], user_notes = input$user_notes,
        last_interaction_date = as.character(input$last_interaction),
        created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        updated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        stringsAsFactors = FALSE
      )
    }

    observeEvent(input$preview_data, {
      req(extracted_data())
      record <- build_record()
      output$preview_table <- renderDT({
        datatable(t(record), options = list(dom = 't', paging = FALSE, ordering = FALSE),
                  rownames = TRUE, colnames = "Value", class = 'cell-border stripe')
      })
      shinyjs::runjs("$('[data-widget=\"collapse\"]').click();")
    })

    observeEvent(input$send_to_bq, {
      req(extracted_data())
      if (!api_manager$bq_authenticated) {
        showNotification("Please configure BigQuery settings first (API Settings)!", type = "error", duration = 5)
        return()
      }

      showNotification("Sending data to BigQuery...", type = "message", duration = NULL, id = "sending_bq")

      tryCatch({
        record <- build_record()
        api_manager$bq_insert_contact(record)

        removeNotification(id = "sending_bq")
        output$send_bq_status_ui <- renderUI({
          div(class = "alert-success", icon("check-circle"), " Data sent to BigQuery successfully!",
              tags$br(), tags$small("Contact ID: ", record$contact_id))
        })
        showNotification("Data sent to BigQuery successfully! View in Explore Contacts tab.", type = "message", duration = 5)

        extracted_data(NULL)
        updateTextAreaInput(session, "user_notes", value = "")
        updateTextAreaInput(session, "contact_text", value = "")
        updateDateInput(session, "last_interaction", value = Sys.Date())

      }, error = function(e) {
        removeNotification(id = "sending_bq")
        output$send_bq_status_ui <- renderUI({
          div(class = "alert-danger", icon("exclamation-circle"), " Error sending to BigQuery: ", e$message)
        })
        showNotification(paste("BigQuery Error:", e$message), type = "error", duration = 10)
      })
    })

    output$process_status_ui <- renderUI({ tags$div() })
    output$send_bq_status_ui <- renderUI({ tags$div() })
  })
}
