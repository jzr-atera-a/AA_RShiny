# modules/Gantt to Tickets/manage_contacts.R
# Subtab: Manage Contacts
# NOTE: this is a separate, simpler contact list (Country/City/Organization/
# Full_Name/LinkedIn/Email/Phone/Date_Added, local-Excel-backed) from the
# Communications suite's BigQuery-backed business_contacts - different schema,
# different storage, kept intentionally separate as api_manager$gantt_contacts_data.

manage_contacts_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Add New Contact", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4,
                   textInput(ns("contact_country"), "Country:", placeholder = "USA"),
                   textInput(ns("contact_city"), "City:", placeholder = "New York"),
                   textInput(ns("contact_org"), "Organization:", placeholder = "Acme Corp")),
            column(4,
                   textInput(ns("contact_name"), "Full Name:", placeholder = "John Doe"),
                   textInput(ns("contact_email"), "Email:", placeholder = "john@example.com"),
                   textInput(ns("contact_phone"), "Phone Number:", placeholder = "+1-555-0123")),
            column(4,
                   textInput(ns("contact_linkedin"), "LinkedIn Profile:", placeholder = "https://linkedin.com/in/johndoe"),
                   br(),
                   actionButton(ns("add_contact"), "Add Contact", class = "btn-success btn-lg btn-block", icon = icon("plus")),
                   br(),
                   actionButton(ns("clear_contact_form"), "Clear Form", class = "btn-warning btn-block"))
          ),
          hr(), htmlOutput(ns("contact_add_status")))
    ),
    fluidRow(
      box(title = "Contacts Database", status = "info", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, actionButton(ns("refresh_contacts"), "Refresh List", icon = icon("sync"), class = "btn-info btn-block")),
            column(3, downloadButton(ns("download_contacts"), "Download Excel", class = "btn-success btn-block")),
            column(3, fileInput(ns("upload_contacts"), "Upload Contacts File", accept = c(".xlsx", ".xls"))),
            column(3, actionButton(ns("clear_all_contacts"), "Clear All", class = "btn-danger btn-block", icon = icon("trash")))
          ),
          hr(),
          DT::dataTableOutput(ns("contacts_table")), br(),
          htmlOutput(ns("contacts_count")))
    )
  )
}

manage_contacts_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$add_contact, {
      req(input$contact_name, input$contact_email)
      if (!grepl("@", input$contact_email)) { showNotification("Please enter a valid email address", type = "error"); return() }

      new_contact <- data.frame(
        Country = input$contact_country, City = input$contact_city, Organization = input$contact_org,
        Full_Name = input$contact_name, LinkedIn = input$contact_linkedin, Email = input$contact_email,
        Phone = input$contact_phone, Date_Added = as.character(Sys.Date()), stringsAsFactors = FALSE
      )

      api_manager$gantt_contacts_data <- if (is.null(api_manager$gantt_contacts_data) || nrow(api_manager$gantt_contacts_data) == 0) {
        new_contact
      } else rbind(api_manager$gantt_contacts_data, new_contact)

      tryCatch({
        api_manager$save_gantt_contacts()
        output$contact_add_status <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                         paste(" ✓ Contact added successfully:", input$contact_name)))
        showNotification("Contact added and saved!", type = "message")

        updateTextInput(session, "contact_country", value = "")
        updateTextInput(session, "contact_city", value = "")
        updateTextInput(session, "contact_org", value = "")
        updateTextInput(session, "contact_name", value = "")
        updateTextInput(session, "contact_linkedin", value = "")
        updateTextInput(session, "contact_email", value = "")
        updateTextInput(session, "contact_phone", value = "")

        api_manager$trigger_state_update_gantt()
      }, error = function(e) {
        output$contact_add_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                                                         " ✗ Error saving contact: ", e$message))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$clear_contact_form, {
      updateTextInput(session, "contact_country", value = "")
      updateTextInput(session, "contact_city", value = "")
      updateTextInput(session, "contact_org", value = "")
      updateTextInput(session, "contact_name", value = "")
      updateTextInput(session, "contact_linkedin", value = "")
      updateTextInput(session, "contact_email", value = "")
      updateTextInput(session, "contact_phone", value = "")
    })

    output$contacts_table <- DT::renderDataTable({
      req(api_manager$gantt_contacts_data)
      DT::datatable(api_manager$gantt_contacts_data,
                    options = list(pageLength = 10, scrollX = TRUE, order = list(list(7, 'desc'))), rownames = FALSE)
    })

    output$contacts_count <- renderUI({
      if (is.null(api_manager$gantt_contacts_data) || nrow(api_manager$gantt_contacts_data) == 0) {
        tags$div("No contacts in database")
      } else {
        tags$div(class = "status-info", paste("Total contacts:", nrow(api_manager$gantt_contacts_data)))
      }
    })

    observeEvent(input$refresh_contacts, {
      if (file.exists(api_manager$gantt_contacts_file)) {
        tryCatch({
          api_manager$gantt_contacts_data <- readxl::read_excel(api_manager$gantt_contacts_file)
          api_manager$trigger_state_update_gantt()
          showNotification("Contacts refreshed!", type = "message")
        }, error = function(e) {
          showNotification(paste("Error refreshing:", e$message), type = "error")
        })
      }
    })

    output$download_contacts <- downloadHandler(
      filename = function() paste0("contacts_export_", Sys.Date(), ".xlsx"),
      content = function(file) writexl::write_xlsx(api_manager$gantt_contacts_data, file)
    )

    observeEvent(input$upload_contacts, {
      req(input$upload_contacts)
      tryCatch({
        uploaded_data <- readxl::read_excel(input$upload_contacts$datapath)

        required_cols <- c("Country", "City", "Organization", "Full_Name", "Email")
        if (!all(required_cols %in% names(uploaded_data))) {
          showNotification("Invalid file format. Missing required columns.", type = "error")
          return()
        }

        api_manager$gantt_contacts_data <- if (is.null(api_manager$gantt_contacts_data) || nrow(api_manager$gantt_contacts_data) == 0) {
          uploaded_data
        } else rbind(api_manager$gantt_contacts_data, uploaded_data)

        api_manager$gantt_contacts_data <- api_manager$gantt_contacts_data %>% dplyr::distinct(Email, .keep_all = TRUE)

        api_manager$save_gantt_contacts()
        api_manager$trigger_state_update_gantt()

        showNotification(paste("Uploaded", nrow(uploaded_data), "contacts (duplicates removed)"), type = "message")
      }, error = function(e) {
        showNotification(paste("Upload error:", e$message), type = "error")
      })
    })

    observeEvent(input$clear_all_contacts, {
      showModal(modalDialog(
        title = "Confirm Delete", "Are you sure you want to delete ALL contacts? This cannot be undone.",
        footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirm_clear_contacts"), "Delete All", class = "btn-danger"))
      ))
    })

    observeEvent(input$confirm_clear_contacts, {
      api_manager$gantt_contacts_data <- api_manager$empty_gantt_contacts_df()
      if (file.exists(api_manager$gantt_contacts_file)) file.remove(api_manager$gantt_contacts_file)
      api_manager$trigger_state_update_gantt()
      removeModal()
      showNotification("All contacts deleted", type = "warning")
    })

    output$contact_add_status <- renderUI({ tags$div() })
  })
}
