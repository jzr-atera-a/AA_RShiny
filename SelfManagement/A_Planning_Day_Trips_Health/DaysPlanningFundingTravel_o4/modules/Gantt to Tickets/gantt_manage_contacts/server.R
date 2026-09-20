# modules/Gantt to Tickets/gantt_manage_contacts/server.R

gantt_manage_contacts_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$add_contact, {
      req(input$contact_name, input$contact_email)
      if (!grepl("@", input$contact_email)) { showNotification("Please enter a valid email address", type = "error"); return() }
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      tryCatch({
        new_contact <- data.frame(
          country = input$contact_country, city = input$contact_city, organization = input$contact_org,
          full_name = input$contact_name, linkedin = input$contact_linkedin, email = input$contact_email,
          phone = input$contact_phone, date_added = as.character(Sys.Date()), stringsAsFactors = FALSE
        )
        api_manager$bq_insert_gantt_contact(new_contact)

        output$contact_add_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   paste(" ✓ Contact added successfully:", input$contact_name))
        })
        showNotification("Contact added!", type = "message")

        updateTextInput(session, "contact_country", value = "")
        updateTextInput(session, "contact_city", value = "")
        updateTextInput(session, "contact_org", value = "")
        updateTextInput(session, "contact_name", value = "")
        updateTextInput(session, "contact_linkedin", value = "")
        updateTextInput(session, "contact_email", value = "")
        updateTextInput(session, "contact_phone", value = "")

        api_manager$trigger_state_update_gantt()

      }, error = function(e) {
        output$contact_add_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " ✗ Error saving contact: ", e$message)
        })
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

    load_contacts <- function() {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      tryCatch({
        data <- api_manager$bq_get_gantt_contacts()
        output$contacts_table <- DT::renderDataTable({
          DT::datatable(data, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        output$contacts_count <- renderUI({
          tags$div(class = "status-info", paste("Total contacts:", nrow(data)))
        })
      }, error = function(e) { showNotification(paste("Error loading contacts:", e$message), type = "error") })
    }

    observeEvent(input$refresh_contacts, { load_contacts() })
    observeEvent(api_manager$state_trigger_gantt(), { if (api_manager$bq_authenticated) load_contacts() }, ignoreInit = TRUE)

    output$download_contacts <- downloadHandler(
      filename = function() paste0("contacts_export_", Sys.Date(), ".xlsx"),
      content = function(file) {
        data <- if (api_manager$bq_authenticated) api_manager$bq_get_gantt_contacts() else data.frame()
        writexl::write_xlsx(data, file)
      }
    )

    observeEvent(input$upload_contacts, {
      req(input$upload_contacts)
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      tryCatch({
        uploaded_data <- as.data.frame(readxl::read_excel(input$upload_contacts$datapath), stringsAsFactors = FALSE)
        names(uploaded_data) <- tolower(names(uploaded_data))

        required_cols <- c("country", "city", "organization", "full_name", "email")
        if (!all(required_cols %in% names(uploaded_data))) {
          showNotification("Invalid file format. Missing required columns.", type = "error"); return()
        }
        if (!"linkedin" %in% names(uploaded_data)) uploaded_data$linkedin <- ""
        if (!"phone" %in% names(uploaded_data)) uploaded_data$phone <- ""
        uploaded_data$date_added <- as.character(Sys.Date())

        uploaded_data <- uploaded_data %>% dplyr::distinct(email, .keep_all = TRUE)
        api_manager$bq_insert_gantt_contact(uploaded_data)

        showNotification(paste("Uploaded", nrow(uploaded_data), "contacts"), type = "message")
        api_manager$trigger_state_update_gantt()

      }, error = function(e) { showNotification(paste("Upload error:", e$message), type = "error") })
    })

    output$contact_add_status <- renderUI({ tags$div() })
    output$contacts_table <- DT::renderDataTable({ DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE) })
    output$contacts_count <- renderUI({ tags$div("No contacts loaded yet - click Refresh") })

    session$onSessionEnded(function() {})
  })
}
