# modules/bq_config/ui.R
# BigQuery Configuration UI
# ==========================

bq_config_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Google Cloud BigQuery Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p("Configure your Google Cloud BigQuery connection settings below."),
        p("Default settings are pre-filled for quick setup."),
        br(),
        
        fluidRow(
          column(6,
                 textInput(ns("bq_project"), "Project ID:", 
                           value = "atera-2",
                           placeholder = "atera-2",
                           width = "100%")),
          column(6,
                 textInput(ns("bq_dataset"), "Dataset Name:", 
                           value = "business_strategy",
                           placeholder = "business_strategy",
                           width = "100%"))
        ),
        
        textInput(ns("bq_table"), "Table Name (Contacts):", 
                  value = "business_contacts",
                  placeholder = "business_contacts",
                  width = "100%"),
        
        textInput(ns("bq_comm_table"), "Table Name (Communications):", 
                  value = "contact_communications",
                  placeholder = "contact_communications",
                  width = "100%"),
        
        br(),
        h4("Authentication Method:"),
        radioButtons(ns("bq_auth_method"), NULL,
                     choices = c("Service Account JSON Key File" = "json_key",
                                 "Application Default Credentials" = "adc"),
                     selected = "json_key",
                     inline = TRUE),
        
        conditionalPanel(
          condition = sprintf("input['%s'] == 'json_key'", ns("bq_auth_method")),
          fileInput(ns("bq_key_file"), "Upload Service Account JSON Key:",
                    accept = ".json",
                    width = "100%")
        ),
        
        conditionalPanel(
          condition = sprintf("input['%s'] == 'adc'", ns("bq_auth_method")),
          p(tags$small("Using Application Default Credentials. Make sure you have run:"),
            tags$br(),
            tags$code("gcloud auth application-default login"))
        ),
        
        br(),
        actionButton(ns("save_bq"), "Save BigQuery Settings", class = "btn-success", icon = icon("save")),
        actionButton(ns("test_bq"), "Test Connection & Load Data", class = "btn-info", icon = icon("database")),
        br(), br(),
        htmlOutput(ns("bq_status")),
        
        br(),
        div(class = "schema-info",
            h5("Table Schema for Business Contacts:"),
            p("The following schema will be used for the business_contacts table:"),
            tags$ul(
              tags$li(tags$code("contact_id"), " - STRING (Primary Key, Auto-generated UUID)"),
              tags$li(tags$code("full_name"), " - STRING"),
              tags$li(tags$code("industry"), " - STRING"),
              tags$li(tags$code("company"), " - STRING"),
              tags$li(tags$code("job_title"), " - STRING"),
              tags$li(tags$code("location"), " - STRING"),
              tags$li(tags$code("country"), " - STRING"),
              tags$li(tags$code("email"), " - STRING"),
              tags$li(tags$code("phone"), " - STRING"),
              tags$li(tags$code("linkedin"), " - STRING"),
              tags$li(tags$code("areas_of_interest"), " - STRING"),
              tags$li(tags$code("university"), " - STRING"),
              tags$li(tags$code("academic_background"), " - STRING"),
              tags$li(tags$code("user_notes"), " - STRING"),
              tags$li(tags$code("last_interaction_date"), " - DATE"),
              tags$li(tags$code("created_at"), " - TIMESTAMP"),
              tags$li(tags$code("updated_at"), " - TIMESTAMP")
            ),
            br(),
            h5("Table Schema for Contact Communications:"),
            p("The following schema will be used for the contact_communications table:"),
            tags$ul(
              tags$li(tags$code("message_id"), " - STRING (Primary Key)"),
              tags$li(tags$code("contact_id"), " - STRING (Foreign Key)"),
              tags$li(tags$code("channel_type"), " - STRING"),
              tags$li(tags$code("communication_purpose"), " - STRING"),
              tags$li(tags$code("language"), " - STRING"),
              tags$li(tags$code("message_length"), " - STRING"),
              tags$li(tags$code("message_content"), " - STRING"),
              tags$li(tags$code("created_at"), " - TIMESTAMP")
            )
        )
      )
    )
  )
}
