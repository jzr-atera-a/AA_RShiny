# modules/manage_contacts/ui.R
manage_contacts_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Add New Contact",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        fluidRow(
          column(4,
                 textInput(ns("contact_country"), "Country:", placeholder = "USA"),
                 textInput(ns("contact_city"), "City:", placeholder = "New York"),
                 textInput(ns("contact_org"), "Organization:", placeholder = "Acme Corp")
          ),
          column(4,
                 textInput(ns("contact_name"), "Full Name:", placeholder = "John Doe"),
                 textInput(ns("contact_email"), "Email:", placeholder = "john@example.com"),
                 textInput(ns("contact_phone"), "Phone Number:", placeholder = "+1-555-0123")
          ),
          column(4,
                 textInput(ns("contact_linkedin"), "LinkedIn Profile:", 
                           placeholder = "https://linkedin.com/in/johndoe"),
                 br(),
                 actionButton(ns("add_contact"), "Add Contact", 
                              class = "btn-success btn-lg btn-block",
                              icon = icon("plus")),
                 br(),
                 actionButton(ns("clear_contact_form"), "Clear Form", 
                              class = "btn-warning btn-block")
          )
        ),
        hr(),
        htmlOutput(ns("contact_add_status"))
      )
    ),
    fluidRow(
      box(
        title = "Contacts Database",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        fluidRow(
          column(3,
                 actionButton(ns("refresh_contacts"), "Refresh List", 
                              icon = icon("sync"),
                              class = "btn-info btn-block")
          ),
          column(3,
                 downloadButton(ns("download_contacts"), "Download Excel", 
                                class = "btn-success btn-block")
          ),
          column(3,
                 fileInput(ns("upload_contacts"), "Upload Contacts File",
                           accept = c(".xlsx", ".xls"))
          ),
          column(3,
                 actionButton(ns("clear_all_contacts"), "Clear All", 
                              class = "btn-danger btn-block",
                              icon = icon("trash"))
          )
        ),
        hr(),
        DT::dataTableOutput(ns("contacts_table")),
        br(),
        htmlOutput(ns("contacts_count"))
      )
    )
  )
}
