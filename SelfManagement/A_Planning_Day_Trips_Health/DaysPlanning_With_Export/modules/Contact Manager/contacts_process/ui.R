# modules/Contact Manager/contacts_process/ui.R

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
