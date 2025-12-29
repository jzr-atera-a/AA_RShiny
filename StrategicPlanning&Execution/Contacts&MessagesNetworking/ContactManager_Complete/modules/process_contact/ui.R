# modules/process_contact/ui.R
process_contact_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Upload or Paste Contact Information", status = "primary", solidHeader = TRUE, width = 12,
        p("Upload a file OR paste contact information in the text box below."),
        div(class = "file-upload-box",
          fileInput(ns("contact_file"), "Choose File (Optional)",
                    accept = c(".pdf", ".docx", ".txt"), width = "100%")),
        br(),
        textAreaInput(ns("contact_text"), "OR paste contact information here:",
                      placeholder = "Paste contact information...", height = "200px", width = "100%"),
        br(),
        actionButton(ns("process_file"), "Process with LLM", class = "btn-primary", 
                     icon = icon("wand-magic-sparkles"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("process_status"))
      )
    ),
    fluidRow(
      box(title = "Extracted Contact Information", status = "info", solidHeader = TRUE, width = 12,
        DT::dataTableOutput(ns("extracted_data_table")),
        br(), htmlOutput(ns("extraction_message"))
      )
    ),
    fluidRow(
      box(title = "Additional Information", status = "success", solidHeader = TRUE, width = 6,
        textAreaInput(ns("user_notes"), "Your Notes About This Contact:",
                      placeholder = "Add personal notes...", height = "150px", width = "100%"),
        br(),
        dateInput(ns("last_interaction"), "Last Interaction Date:", value = Sys.Date(), width = "100%")
      ),
      box(title = "Send to BigQuery", status = "warning", solidHeader = TRUE, width = 6,
        p("Review the extracted data and your notes, then send to BigQuery."),
        actionButton(ns("preview_data"), "Preview Final Data", class = "btn-info", icon = icon("eye"), style = "width: 100%; margin-bottom: 10px;"),
        actionButton(ns("send_to_bq"), "Send to BigQuery", class = "btn-success", icon = icon("cloud-upload-alt"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("send_bq_status"))
      )
    ),
    fluidRow(
      box(title = "Data Preview", status = "primary", solidHeader = TRUE, width = 12,
          collapsible = TRUE, collapsed = TRUE,
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}
