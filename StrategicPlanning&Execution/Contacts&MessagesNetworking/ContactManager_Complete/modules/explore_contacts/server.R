# modules/explore_contacts/server.R
explore_contacts_server <- function(id, contact_manager) {
  moduleServer(id, function(input, output, session) {
    
    selected_row <- reactiveVal(NULL)
    
    # Update filter dropdowns
    observe({
      req(contact_manager$contacts_data)
      
      if (!is.null(contact_manager$contacts_data) && nrow(contact_manager$contacts_data) > 0) {
        updateSelectInput(session, "filter_industry",
                          choices = c("All" = "", unique(contact_manager$contacts_data$industry)))
        updateSelectInput(session, "filter_country",
                          choices = c("All" = "", unique(contact_manager$contacts_data$country)))
        updateSelectInput(session, "filter_location",
                          choices = c("All" = "", unique(contact_manager$contacts_data$location)))
        updateSelectInput(session, "filter_university",
                          choices = c("All" = "", unique(contact_manager$contacts_data$university)))
        updateSelectInput(session, "filter_company",
                          choices = c("All" = "", unique(contact_manager$contacts_data$company)))
      }
    })
    
    # Filtered data
    filtered_data <- reactive({
      req(contact_manager$contacts_data)
      
      if (is.null(contact_manager$contacts_data) || nrow(contact_manager$contacts_data) == 0) {
        return(contact_manager$contacts_data)
      }
      
      data <- contact_manager$contacts_data
      
      if (!is.null(input$filter_industry) && input$filter_industry != "") {
        data <- data[data$industry == input$filter_industry, ]
      }
      if (!is.null(input$filter_country) && input$filter_country != "") {
        data <- data[data$country == input$filter_country, ]
      }
      if (!is.null(input$filter_location) && input$filter_location != "") {
        data <- data[data$location == input$filter_location, ]
      }
      if (!is.null(input$filter_university) && input$filter_university != "") {
        data <- data[data$university == input$filter_university, ]
      }
      if (!is.null(input$filter_company) && input$filter_company != "") {
        data <- data[data$company == input$filter_company, ]
      }
      
      return(data)
    })
    
    # Apply filters
    observeEvent(input$apply_filters, {
      if (is.null(contact_manager$contacts_data) || nrow(contact_manager$contacts_data) == 0) {
        showNotification("No contacts to filter!", type = "warning", duration = 3)
        return()
      }
      
      output$table_status <- renderUI({
        tags$div(class = "status-success", tags$i(class = "fa fa-filter"),
                 " Filters applied. Showing ", nrow(filtered_data()), 
                 " of ", nrow(contact_manager$contacts_data), " records.")
      })
    })
    
    # Clear filters
    observeEvent(input$clear_filters, {
      updateSelectInput(session, "filter_industry", selected = "")
      updateSelectInput(session, "filter_country", selected = "")
      updateSelectInput(session, "filter_location", selected = "")
      updateSelectInput(session, "filter_university", selected = "")
      updateSelectInput(session, "filter_company", selected = "")
      
      if (!is.null(contact_manager$contacts_data)) {
        output$table_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " Filters cleared. Showing all ", nrow(contact_manager$contacts_data), " records.")
        })
      }
    })
    
    # Refresh data
    observeEvent(input$refresh_data, {
      if (!contact_manager$bq_authenticated) {
        showNotification("Please configure BigQuery first!", type = "error", duration = 3)
        return()
      }
      
      showNotification("Refreshing data...", type = "message", duration = NULL, id = "refresh")
      
      tryCatch({
        contact_manager$test_bigquery_connection()
        
        removeNotification(id = "refresh")
        output$table_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-sync"),
                   " Data refreshed. ", nrow(contact_manager$contacts_data), " records loaded.")
        })
        showNotification("Data refreshed successfully!", type = "message", duration = 3)
        
      }, error = function(e) {
        removeNotification(id = "refresh")
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
    
    # Render contacts table
    output$contacts_table <- DT::renderDataTable({
      if (is.null(contact_manager$contacts_data) || nrow(contact_manager$contacts_data) == 0) {
        return(DT::datatable(
          data.frame(Message = "No contacts yet. Add your first contact in the 'Process Contact' tab!"),
          options = list(dom = 't', ordering = FALSE), rownames = FALSE
        ))
      }
      
      display_data <- filtered_data()[, c("contact_id", "full_name", "industry", "company", 
                                          "job_title", "location", "country", "email", 
                                          "university", "user_notes", "last_interaction_date")]
      
      DT::datatable(
        display_data,
        options = list(scrollX = TRUE, pageLength = 10, lengthMenu = c(5, 10, 25, 50),
                       order = list(list(1, 'asc'))),
        editable = list(target = 'cell', disable = list(columns = 0)),
        selection = 'single',
        rownames = FALSE
      )
    })
    
    # Handle cell edits
    observeEvent(input$contacts_table_cell_edit, {
      info <- input$contacts_table_cell_edit
      
      display_cols <- c("contact_id", "full_name", "industry", "company", 
                        "job_title", "location", "country", "email", 
                        "university", "user_notes", "last_interaction_date")
      
      col_name <- display_cols[info$col + 1]
      
      filtered <- filtered_data()
      contact_id <- filtered$contact_id[info$row]
      main_row <- which(contact_manager$contacts_data$contact_id == contact_id)
      
      contact_manager$contacts_data[main_row, col_name] <- info$value
      contact_manager$contacts_data[main_row, "updated_at"] <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      
      output$table_status <- renderUI({
        tags$div(class = "status-success", tags$i(class = "fa fa-edit"),
                 " Cell edited. Click 'Update Modified Record' to save to BigQuery.")
      })
    })
    
    # Track selected row
    observeEvent(input$contacts_table_rows_selected, {
      selected_row(input$contacts_table_rows_selected)
      if (!is.null(selected_row()) && length(selected_row()) > 0) {
        filtered <- filtered_data()
        if (nrow(filtered) > 0) {
          contact <- filtered[selected_row(), ]
          contact_manager$set_selected_contact(contact)
        }
      }
    })
    
    # Customise Communication button
    observeEvent(input$customise_comm, {
      if (is.null(selected_row()) || length(selected_row()) == 0) {
        showNotification("Please select a contact first!", type = "warning", duration = 3)
        return()
      }
      
      updateTabItems(session = getDefaultReactiveDomain(), "sidebar_menu", "customise_communication")
      showNotification("Switched to Customise Communication tab", type = "message", duration = 2)
    })
    
    # Update record
    observeEvent(input$update_record, {
      if (is.null(selected_row()) || length(selected_row()) == 0) {
        showNotification("Please select a row to update.", type = "warning", duration = 3)
        return()
      }
      
      filtered <- filtered_data()
      contact_id <- filtered$contact_id[selected_row()]
      
      output$update_status <- renderUI({
        tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                 " Record updated successfully! Contact ID: ", contact_id)
      })
      
      showNotification("Record updated in BigQuery!", type = "message", duration = 5)
    })
    
    # Delete record
    observeEvent(input$delete_record, {
      if (is.null(selected_row()) || length(selected_row()) == 0) {
        showNotification("Please select a row to delete.", type = "warning", duration = 3)
        return()
      }
      
      filtered <- filtered_data()
      contact_id <- filtered$contact_id[selected_row()]
      
      showModal(modalDialog(
        title = "Confirm Delete",
        paste("Are you sure you want to delete contact:", filtered$full_name[selected_row()], "?"),
        footer = tagList(
          modalButton("Cancel"),
          actionButton(session$ns("confirm_delete"), "Delete", class = "btn-danger")
        )
      ))
    })
    
    # Confirm delete
    observeEvent(input$confirm_delete, {
      removeModal()
      
      filtered <- filtered_data()
      contact_id <- filtered$contact_id[selected_row()]
      
      contact_manager$delete_contact(contact_id)
      
      output$update_status <- renderUI({
        tags$div(class = "status-success", tags$i(class = "fa fa-trash"),
                 " Record deleted successfully! Contact ID: ", contact_id)
      })
      
      showNotification("Record deleted from BigQuery!", type = "message", duration = 5)
      
      selected_row(NULL)
    })
    
    # Default outputs
    output$table_status <- renderUI({ tags$div() })
    output$update_status <- renderUI({ tags$div() })
  })
}
