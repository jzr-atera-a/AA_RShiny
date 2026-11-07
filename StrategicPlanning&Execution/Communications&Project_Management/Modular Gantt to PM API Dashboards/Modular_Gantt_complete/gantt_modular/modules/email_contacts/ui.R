# modules/email_contacts/ui.R
email_contacts_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Filter Contacts",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        fluidRow(
          column(3,
                 selectInput(ns("filter_country"), "Filter by Country:",
                             choices = c("All" = ""), multiple = FALSE)
          ),
          column(3,
                 selectInput(ns("filter_city"), "Filter by City:",
                             choices = c("All" = ""), multiple = FALSE)
          ),
          column(3,
                 selectInput(ns("filter_org"), "Filter by Organization:",
                             choices = c("All" = ""), multiple = FALSE)
          ),
          column(3,
                 br(),
                 actionButton(ns("apply_filters"), "Apply Filters", 
                              class = "btn-primary btn-block",
                              icon = icon("filter"))
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "Select Recipients",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        DT::dataTableOutput(ns("filtered_contacts_table")),
        br(),
        fluidRow(
          column(6,
                 actionButton(ns("select_all_contacts"), "Select All", 
                              class = "btn-info")
          ),
          column(6,
                 actionButton(ns("deselect_all_contacts"), "Deselect All", 
                              class = "btn-warning")
          )
        ),
        br(),
        htmlOutput(ns("selected_contacts_count"))
      )
    ),
    fluidRow(
      box(
        title = "Compose Email",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        textInput(ns("contact_email_subject"), "Email Subject:", 
                  placeholder = "Subject line here",
                  width = "100%"),
        textAreaInput(ns("contact_email_body"), "Email Body:", 
                      placeholder = "Type your message here...",
                      rows = 10,
                      width = "100%"),
        hr(),
        fluidRow(
          column(6,
                 checkboxInput(ns("include_contact_name"), "Personalize with name (use {NAME} in body)", 
                               value = TRUE)
          ),
          column(6,
                 checkboxInput(ns("include_org_name"), "Include organization (use {ORG} in body)", 
                               value = FALSE)
          )
        ),
        hr(),
        actionButton(ns("send_contact_emails"), "Send Emails to Selected Contacts", 
                     class = "btn-success btn-lg btn-block",
                     icon = icon("paper-plane")),
        br(),
        verbatimTextOutput(ns("contact_email_results"))
      )
    )
  )
}
