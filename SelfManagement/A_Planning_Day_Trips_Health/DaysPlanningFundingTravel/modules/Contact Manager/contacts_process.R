# modules/Contact Manager/contacts_process.R
# ---- module ----------------------------------------------
# id:           contacts_process
# name:         Process Contact
# icon:         file-import
# description:  Extract contact information from documents with an LLM
# packages:     shiny, shinydashboard, DT, jsonlite, uuid, pdftools, readtext
# -----------------------------------------------------------

# ---- UI ----
contacts_process_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Add Contact from Document or Text", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(6, fileInput(ns("contact_file"), "Upload File (PDF, DOCX, PPTX, TXT):",
                                accept = c(".pdf", ".docx", ".pptx", ".txt"))),
            column(6, textAreaInput(ns("contact_text"), "Or Paste Text:", rows = 6, placeholder = "Paste a bio, email signature, LinkedIn profile text..."))
          ),
          actionButton(ns("process_file"), "Process with LLM", class = "btn-primary btn-lg", icon = icon("magic")),
          br(), br(),
          htmlOutput(ns("process_status"))
      )
    ),
    fluidRow(
      box(title = "Extracted Information (editable)", status = "info", solidHeader = TRUE, width = 12,
          DT::dataTableOutput(ns("extracted_data_table")),
          br(),
          fluidRow(
            column(6, dateInput(ns("last_interaction"), "Last Interaction Date:", value = Sys.Date())),
            column(6, textAreaInput(ns("user_notes"), "Your Notes:", rows = 2))
          ),
          actionButton(ns("preview_data"), "Preview Record", class = "btn-info"),
          br(), br(),
          DT::dataTableOutput(ns("preview_table"))
      )
    ),
    fluidRow(
      box(title = "Save Contact", status = "success", solidHeader = TRUE, width = 12,
          actionButton(ns("send_to_bq"), "Send to BigQuery", class = "btn-success btn-lg", icon = icon("save")),
          br(), br(),
          htmlOutput(ns("send_bq_status"))
      )
    )
  )
}

# ---- Server ----
contacts_process_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    extracted_data <- reactiveVal(NULL)

    extract_text <- function(file_path, file_name) {
      if (grepl("\\.pdf$", file_name, ignore.case = TRUE)) {
        paste(pdftools::pdf_text(file_path), collapse = "\n")
      } else if (grepl("\\.(docx?|pptx)$", file_name, ignore.case = TRUE)) {
        readtext::readtext(file_path)$text
      } else {
        paste(readLines(file_path, warn = FALSE), collapse = "\n")
      }
    }

    observeEvent(input$process_file, {
      if (!api_manager$contacts_api_authenticated) {
        showNotification("Please configure OpenAI API first!", type = "error"); return()
      }
      has_file <- !is.null(input$contact_file)
      has_text <- nchar(trimws(input$contact_text %||% "")) > 0
      if (!has_file && !has_text) { showNotification("Please upload a file or paste text!", type = "error"); return() }

      output$process_status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Processing with LLM...") })

      tryCatch({
        text <- if (has_file) extract_text(input$contact_file$datapath, input$contact_file$name) else input$contact_text

        prompt <- paste0(
          "Extract contact info as JSON with keys: full_name, industry, company, ",
          "job_title, location, country, email, phone, linkedin, areas_of_interest, ",
          "university, academic_background. Use 'Not specified' for missing fields.\n\n",
          "Text:\n", text
        )

        json_text <- api_manager$call_openai(prompt, max_tokens = 1000)
        json_text <- gsub("```json\\s*", "", json_text)
        json_text <- gsub("```\\s*", "", json_text)
        json_text <- trimws(json_text)

        info <- jsonlite::fromJSON(json_text)

        data <- data.frame(
          Field = c("Full Name", "Industry", "Company", "Job Title", "Location", "Country",
                    "Email", "Phone", "LinkedIn", "Areas of Interest", "University", "Academic Background"),
          Value = c(info$full_name, info$industry, info$company, info$job_title,
                   info$location, info$country, info$email, info$phone,
                   info$linkedin, info$areas_of_interest, info$university, info$academic_background),
          stringsAsFactors = FALSE
        )

        extracted_data(data)

        output$process_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Processed successfully!")
        })
        showNotification("Contact extracted successfully!", type = "message")

      }, error = function(e) {
        output$process_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$extracted_data_table <- DT::renderDataTable({
      req(extracted_data())
      DT::datatable(extracted_data(), options = list(dom = 't', paging = FALSE, ordering = FALSE),
                    editable = list(target = 'cell', disable = list(columns = 0)), rownames = FALSE)
    })

    observeEvent(input$extracted_data_table_cell_edit, {
      info <- input$extracted_data_table_cell_edit
      data <- extracted_data()
      data[info$row, info$col + 1] <- info$value
      extracted_data(data)
    })

    build_record <- function() {
      data <- extracted_data()
      data.frame(
        contact_id = uuid::UUIDgenerate(),
        full_name = data$Value[1], industry = data$Value[2], company = data$Value[3], job_title = data$Value[4],
        location = data$Value[5], country = data$Value[6], email = data$Value[7], phone = data$Value[8],
        linkedin = data$Value[9], areas_of_interest = data$Value[10], university = data$Value[11],
        academic_background = data$Value[12], user_notes = input$user_notes %||% "",
        last_interaction_date = as.character(input$last_interaction), stringsAsFactors = FALSE
      )
    }

    observeEvent(input$preview_data, {
      req(extracted_data())
      record <- build_record()
      output$preview_table <- DT::renderDataTable({
        DT::datatable(t(record), options = list(dom = 't', paging = FALSE, ordering = FALSE), rownames = TRUE, colnames = "Value")
      })
    })

    observeEvent(input$send_to_bq, {
      req(extracted_data())
      if (!api_manager$bq_authenticated) { showNotification("Please configure BigQuery first!", type = "error"); return() }

      output$send_bq_status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Sending to BigQuery...") })

      tryCatch({
        record <- build_record()
        api_manager$bq_insert_contact(record)

        output$send_bq_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Data sent successfully!")
        })
        showNotification("Data sent to BigQuery!", type = "message")

        extracted_data(NULL)
        updateTextAreaInput(session, "user_notes", value = "")
        updateTextAreaInput(session, "contact_text", value = "")

      }, error = function(e) {
        output$send_bq_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$process_status <- renderUI({ tags$div() })
    output$send_bq_status <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({ DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE) })

    session$onSessionEnded(function() {})
  })
}
