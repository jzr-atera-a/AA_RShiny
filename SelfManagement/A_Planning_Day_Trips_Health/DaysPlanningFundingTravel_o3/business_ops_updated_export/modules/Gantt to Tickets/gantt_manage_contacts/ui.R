# modules/Gantt to Tickets/gantt_manage_contacts/ui.R

gantt_manage_contacts_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Add New Contact", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4, textInput(ns("contact_country"), "Country:")),
            column(4, textInput(ns("contact_city"), "City:")),
            column(4, textInput(ns("contact_org"), "Organization:"))
          ),
          fluidRow(
            column(4, textInput(ns("contact_name"), "Full Name: *")),
            column(4, textInput(ns("contact_linkedin"), "LinkedIn:")),
            column(4, textInput(ns("contact_email"), "Email: *"))
          ),
          fluidRow(column(4, textInput(ns("contact_phone"), "Phone:"))),
          fluidRow(
            column(6, actionButton(ns("add_contact"), "Add Contact", class = "btn-success", icon = icon("plus"), style = "width: 100%;")),
            column(6, actionButton(ns("clear_contact_form"), "Clear Form", class = "btn-default", style = "width: 100%;"))
          ),
          br(), htmlOutput(ns("contact_add_status"))
      )
    ),
    fluidRow(
      box(title = "Upload / Download Contacts", status = "info", solidHeader = TRUE, width = 12,
          fluidRow(
            column(6, fileInput(ns("upload_contacts"), "Upload Contacts (Excel):", accept = c(".xlsx", ".xls"))),
            column(6, br(), downloadButton(ns("download_contacts"), "Download Contacts", class = "btn-info"))
          )
      )
    ),
    fluidRow(
      box(title = "Contact Database", status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(6, actionButton(ns("refresh_contacts"), "Refresh", class = "btn-primary", icon = icon("sync"))),
            column(6, htmlOutput(ns("contacts_count")))
          ),
          br(),
          DT::dataTableOutput(ns("contacts_table"))
      )
    )
  )
}
