# modules/email_contacts/server.R
email_contacts_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    selected_rows <- reactiveVal(c())
    filtered_data <- reactiveVal(NULL)
    
    # Update filter dropdowns when contacts change
    observe({
      api_manager$state_trigger()
      req(api_manager$contacts_data)
      
      if (nrow(api_manager$contacts_data) > 0) {
        countries <- unique(api_manager$contacts_data$Country)
        countries <- countries[countries != ""]
        updateSelectInput(session, "filter_country", 
                          choices = c("All" = "", countries))
        
        cities <- unique(api_manager$contacts_data$City)
        cities <- cities[cities != ""]
        updateSelectInput(session, "filter_city", 
                          choices = c("All" = "", cities))
        
        orgs <- unique(api_manager$contacts_data$Organization)
        orgs <- orgs[orgs != ""]
        updateSelectInput(session, "filter_org", 
                          choices = c("All" = "", orgs))
      }
    })
    
    # Apply filters
    observeEvent(input$apply_filters, {
      req(api_manager$contacts_data)
      
      filtered <- api_manager$contacts_data
      
      if (input$filter_country != "") {
        filtered <- filtered %>% dplyr::filter(Country == input$filter_country)
      }
      
      if (input$filter_city != "") {
        filtered <- filtered %>% dplyr::filter(City == input$filter_city)
      }
      
      if (input$filter_org != "") {
        filtered <- filtered %>% dplyr::filter(Organization == input$filter_org)
      }
      
      filtered_data(filtered)
      
      showNotification(
        paste("Filtered to", nrow(filtered), "contacts"), 
        type = "message"
      )
    })
    
    # Display filtered contacts table
    output$filtered_contacts_table <- DT::renderDataTable({
      data_to_show <- if (!is.null(filtered_data())) {
        filtered_data()
      } else if (!is.null(api_manager$contacts_data)) {
        api_manager$contacts_data
      } else {
        data.frame()
      }
      
      DT::datatable(
        data_to_show,
        options = list(
          pageLength = 10,
          scrollX = TRUE
        ),
        selection = 'multiple',
        rownames = FALSE
      )
    })
    
    # Track selected rows
    observeEvent(input$filtered_contacts_table_rows_selected, {
      selected_rows(input$filtered_contacts_table_rows_selected)
    })
    
    # Select all
    observeEvent(input$select_all_contacts, {
      data_to_show <- if (!is.null(filtered_data())) {
        filtered_data()
      } else {
        api_manager$contacts_data
      }
      
      if (!is.null(data_to_show) && nrow(data_to_show) > 0) {
        proxy <- DT::dataTableProxy('filtered_contacts_table')
        DT::selectRows(proxy, 1:nrow(data_to_show))
      }
    })
    
    # Deselect all
    observeEvent(input$deselect_all_contacts, {
      proxy <- DT::dataTableProxy('filtered_contacts_table')
      DT::selectRows(proxy, NULL)
    })
    
    # Selected contacts count
    output$selected_contacts_count <- renderUI({
      count <- length(selected_rows())
      if (count == 0) {
        tags$div("No contacts selected. Click on rows to select recipients.")
      } else {
        tags$div(class = "status-info",
                 paste("Selected:", count, "contact(s)"))
      }
    })
    
    # Send emails to selected contacts
    observeEvent(input$send_contact_emails, {
      req(selected_rows(), input$contact_email_subject, input$contact_email_body)
      
      if (!api_manager$email_connected || length(api_manager$smtp_config) == 0) {
        showNotification("Please configure email settings first (Email Configuration tab)", 
                         type = "error")
        return()
      }
      
      data_to_use <- if (!is.null(filtered_data())) {
        filtered_data()
      } else {
        api_manager$contacts_data
      }
      
      selected_contacts <- data_to_use[selected_rows(), ]
      
      if (nrow(selected_contacts) == 0) {
        showNotification("No contacts selected", type = "warning")
        return()
      }
      
      results <- c()
      
      withProgress(message = 'Sending emails to contacts...', value = 0, {
        for (i in 1:nrow(selected_contacts)) {
          contact <- selected_contacts[i, ]
          
          tryCatch({
            email_body <- input$contact_email_body
            
            if (input$include_contact_name) {
              email_body <- gsub("\\{NAME\\}", contact$Full_Name, email_body)
            }
            
            if (input$include_org_name) {
              email_body <- gsub("\\{ORG\\}", contact$Organization, email_body)
            }
            
            api_manager$send_email(
              to = contact$Email,
              subject = input$contact_email_subject,
              body = email_body
            )
            
            results <- c(results, paste("✓", contact$Full_Name, "-", contact$Email))
            
          }, error = function(e) {
            results <<- c(results, paste("✗", contact$Full_Name, "-", e$message))
          })
          
          incProgress(1/nrow(selected_contacts))
        }
      })
      
      output$contact_email_results <- renderText({
        paste(results, collapse = "\n")
      })
      
      showNotification(
        paste("Sent", sum(grepl("✓", results)), "of", nrow(selected_contacts), "emails"), 
        type = "message",
        duration = 10
      )
    })
    
    # Default outputs
    output$contact_email_results <- renderText({ "" })
  })
}
