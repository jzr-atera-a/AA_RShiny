# modules/manage_contacts/server.R
manage_contacts_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Add new contact
    observeEvent(input$add_contact, {
      req(input$contact_name, input$contact_email)
      
      if (!grepl("@", input$contact_email)) {
        showNotification("Please enter a valid email address", type = "error")
        return()
      }
      
      new_contact <- data.frame(
        Country = input$contact_country,
        City = input$contact_city,
        Organization = input$contact_org,
        Full_Name = input$contact_name,
        LinkedIn = input$contact_linkedin,
        Email = input$contact_email,
        Phone = input$contact_phone,
        Date_Added = as.character(Sys.Date()),
        stringsAsFactors = FALSE
      )
      
      if (is.null(api_manager$contacts_data) || nrow(api_manager$contacts_data) == 0) {
        api_manager$contacts_data <- new_contact
      } else {
        api_manager$contacts_data <- rbind(api_manager$contacts_data, new_contact)
      }
      
      tryCatch({
        writexl::write_xlsx(api_manager$contacts_data, api_manager$contacts_file)
        output$contact_add_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   paste(" ✓ Contact added successfully:", input$contact_name))
        })
        showNotification("Contact added and saved!", type = "message")
        
        # Clear form
        updateTextInput(session, "contact_country", value = "")
        updateTextInput(session, "contact_city", value = "")
        updateTextInput(session, "contact_org", value = "")
        updateTextInput(session, "contact_name", value = "")
        updateTextInput(session, "contact_linkedin", value = "")
        updateTextInput(session, "contact_email", value = "")
        updateTextInput(session, "contact_phone", value = "")
        
        api_manager$trigger_state_update()
        
      }, error = function(e) {
        output$contact_add_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " ✗ Error saving contact: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Clear contact form
    observeEvent(input$clear_contact_form, {
      updateTextInput(session, "contact_country", value = "")
      updateTextInput(session, "contact_city", value = "")
      updateTextInput(session, "contact_org", value = "")
      updateTextInput(session, "contact_name", value = "")
      updateTextInput(session, "contact_linkedin", value = "")
      updateTextInput(session, "contact_email", value = "")
      updateTextInput(session, "contact_phone", value = "")
    })
    
    # Display contacts table
    output$contacts_table <- DT::renderDataTable({
      req(api_manager$contacts_data)
      DT::datatable(
        api_manager$contacts_data,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          order = list(list(7, 'desc'))
        ),
        rownames = FALSE
      )
    })
    
    # Contacts count
    output$contacts_count <- renderUI({
      if (is.null(api_manager$contacts_data) || nrow(api_manager$contacts_data) == 0) {
        tags$div("No contacts in database")
      } else {
        tags$div(class = "status-info",
                 paste("Total contacts:", nrow(api_manager$contacts_data)))
      }
    })
    
    # Refresh contacts
    observeEvent(input$refresh_contacts, {
      if (file.exists(api_manager$contacts_file)) {
        tryCatch({
          api_manager$contacts_data <- readxl::read_excel(api_manager$contacts_file)
          api_manager$trigger_state_update()
          showNotification("Contacts refreshed!", type = "message")
        }, error = function(e) {
          showNotification(paste("Error refreshing:", e$message), type = "error")
        })
      }
    })
    
    # Download contacts
    output$download_contacts <- downloadHandler(
      filename = function() {
        paste0("contacts_export_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        writexl::write_xlsx(api_manager$contacts_data, file)
      }
    )
    
    # Upload contacts
    observeEvent(input$upload_contacts, {
      req(input$upload_contacts)
      
      tryCatch({
        uploaded_data <- readxl::read_excel(input$upload_contacts$datapath)
        
        required_cols <- c("Country", "City", "Organization", "Full_Name", "Email")
        if (!all(required_cols %in% names(uploaded_data))) {
          showNotification("Invalid file format. Missing required columns.", type = "error")
          return()
        }
        
        if (is.null(api_manager$contacts_data) || nrow(api_manager$contacts_data) == 0) {
          api_manager$contacts_data <- uploaded_data
        } else {
          api_manager$contacts_data <- rbind(api_manager$contacts_data, uploaded_data)
        }
        
        api_manager$contacts_data <- api_manager$contacts_data %>%
          dplyr::distinct(Email, .keep_all = TRUE)
        
        writexl::write_xlsx(api_manager$contacts_data, api_manager$contacts_file)
        api_manager$trigger_state_update()
        
        showNotification(
          paste("Uploaded", nrow(uploaded_data), "contacts (duplicates removed)"), 
          type = "message"
        )
        
      }, error = function(e) {
        showNotification(paste("Upload error:", e$message), type = "error")
      })
    })
    
    # Clear all contacts
    observeEvent(input$clear_all_contacts, {
      showModal(modalDialog(
        title = "Confirm Delete",
        "Are you sure you want to delete ALL contacts? This cannot be undone.",
        footer = tagList(
          modalButton("Cancel"),
          actionButton(session$ns("confirm_clear_contacts"), "Delete All", class = "btn-danger")
        )
      ))
    })
    
    observeEvent(input$confirm_clear_contacts, {
      api_manager$contacts_data <- data.frame(
        Country = character(),
        City = character(),
        Organization = character(),
        Full_Name = character(),
        LinkedIn = character(),
        Email = character(),
        Phone = character(),
        Date_Added = character(),
        stringsAsFactors = FALSE
      )
      
      if (file.exists(api_manager$contacts_file)) {
        file.remove(api_manager$contacts_file)
      }
      
      api_manager$trigger_state_update()
      removeModal()
      showNotification("All contacts deleted", type = "warning")
    })
    
    # Default outputs
    output$contact_add_status <- renderUI({ tags$div() })
  })
}
