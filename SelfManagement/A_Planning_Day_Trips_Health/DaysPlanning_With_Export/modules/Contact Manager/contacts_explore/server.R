# modules/Contact Manager/contacts_explore/server.R

contacts_explore_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    all_contacts <- reactiveVal(data.frame())
    edited_contacts <- reactiveVal(data.frame())

    load_contacts <- function() {
      if (!api_manager$bq_authenticated) return(invisible(NULL))
      data <- tryCatch(api_manager$bq_get_contacts(), error = function(e) data.frame())
      all_contacts(data)
      edited_contacts(data)
      if (nrow(data) > 0) {
        updateSelectInput(session, "filter_industry", choices = c("All" = "", sort(unique(data$industry[nchar(trimws(data$industry)) > 0]))))
        updateSelectInput(session, "filter_country", choices = c("All" = "", sort(unique(data$country[nchar(trimws(data$country)) > 0]))))
        updateSelectInput(session, "filter_location", choices = c("All" = "", sort(unique(data$location[nchar(trimws(data$location)) > 0]))))
        updateSelectInput(session, "filter_university", choices = c("All" = "", sort(unique(data$university[nchar(trimws(data$university)) > 0]))))
        updateSelectInput(session, "filter_company", choices = c("All" = "", sort(unique(data$company[nchar(trimws(data$company)) > 0]))))
      }
      output$table_status <- renderUI({
        tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Loaded %d contact(s)", nrow(data)))
      })
    }

    observeEvent(input$refresh_data, { load_contacts() })
    observeEvent(api_manager$state_trigger_contacts(), { if (api_manager$bq_authenticated) load_contacts() }, ignoreInit = TRUE)

    filtered <- reactive({
      d <- edited_contacts()
      if (nrow(d) == 0) return(d)
      if (nchar(input$filter_industry %||% "") > 0) d <- d[d$industry == input$filter_industry, ]
      if (nchar(input$filter_country %||% "") > 0) d <- d[d$country == input$filter_country, ]
      if (nchar(input$filter_location %||% "") > 0) d <- d[d$location == input$filter_location, ]
      if (nchar(input$filter_university %||% "") > 0) d <- d[d$university == input$filter_university, ]
      if (nchar(input$filter_company %||% "") > 0) d <- d[d$company == input$filter_company, ]
      d
    })

    observeEvent(input$clear_filters, {
      updateSelectInput(session, "filter_industry", selected = "")
      updateSelectInput(session, "filter_country", selected = "")
      updateSelectInput(session, "filter_location", selected = "")
      updateSelectInput(session, "filter_university", selected = "")
      updateSelectInput(session, "filter_company", selected = "")
    })

    output$contacts_table <- DT::renderDataTable({
      input$apply_filters; input$clear_filters
      DT::datatable(filtered(), selection = "single", editable = TRUE,
                    options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$contacts_table_cell_edit, {
      info <- input$contacts_table_cell_edit
      d <- filtered()
      d[info$row, info$col + 1] <- info$value
      # Write the edit back into the full (unfiltered) working copy, keyed by contact_id
      full <- edited_contacts()
      full[full$contact_id == d$contact_id[info$row], ] <- d[info$row, ]
      edited_contacts(full)
    })

    observeEvent(input$customise_comm, {
      sel <- input$contacts_table_rows_selected
      if (is.null(sel)) { showNotification("Please select a contact first.", type = "warning"); return() }
      contact <- filtered()[sel, ]
      api_manager$set_contacts_selected_contact(as.list(contact))
      updateTabItems(session$rootScope(), "sidebar_menu", selected = "contacts_customise_communication")
    })

    observeEvent(input$update_record, {
      sel <- input$contacts_table_rows_selected
      if (is.null(sel)) { showNotification("Please select a contact first.", type = "warning"); return() }
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      tryCatch({
        contact <- filtered()[sel, ]
        updatable_cols <- setdiff(names(contact), c("contact_id", "created_at", "updated_at"))
        updates <- as.list(contact[updatable_cols])
        api_manager$bq_update_contact(contact$contact_id, updates)

        output$update_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Contact updated successfully!")
        })
        showNotification("✓ Contact updated!", type = "message")

      }, error = function(e) {
        output$update_status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$delete_record, {
      sel <- input$contacts_table_rows_selected
      if (is.null(sel)) { showNotification("Please select a contact first.", type = "warning"); return() }
      contact <- filtered()[sel, ]

      showModal(modalDialog(
        title = "Confirm Delete",
        sprintf("Are you sure you want to delete '%s'? This cannot be undone.", contact$full_name),
        footer = tagList(modalButton("Cancel"),
                         actionButton(session$ns("confirm_delete"), "Delete", class = "btn-danger"))
      ))
      session$userData$pending_delete_id <- contact$contact_id
    })

    observeEvent(input$confirm_delete, {
      removeModal()
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      tryCatch({
        api_manager$bq_delete_contact(session$userData$pending_delete_id)
        output$update_status <- renderUI({
          tags$div(class = "status-warning", tags$i(class = "fa fa-trash"), " Contact deleted.")
        })
        showNotification("Contact deleted", type = "warning")
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$table_status <- renderUI({ tags$div("Click Refresh Data to load contacts.") })
    output$update_status <- renderUI({ tags$div() })

    session$onSessionEnded(function() {})
  })
}
