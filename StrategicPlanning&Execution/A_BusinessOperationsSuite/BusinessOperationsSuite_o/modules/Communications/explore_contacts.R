# modules/Communications/explore_contacts.R
# Subtab: Explore Contacts (under the "Communications" main tab)

explore_contacts_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Filter Contacts", status = "info", solidHeader = TRUE, width = 12,
          fluidRow(
            column(2, selectInput(ns("filter_industry"), "Industry:", choices = c("All" = ""), width = "100%")),
            column(2, selectInput(ns("filter_country"), "Country:", choices = c("All" = ""), width = "100%")),
            column(2, selectInput(ns("filter_location"), "Location:", choices = c("All" = ""), width = "100%")),
            column(2, selectInput(ns("filter_university"), "University:", choices = c("All" = ""), width = "100%")),
            column(2, selectInput(ns("filter_company"), "Company:", choices = c("All" = ""), width = "100%")),
            column(2, br(), actionButton(ns("refresh_data"), "Refresh Data", class = "btn-info", icon = icon("sync"), style = "width: 100%;"))
          ),
          br(),
          actionButton(ns("apply_filters"), "Apply Filters", class = "btn-primary", icon = icon("filter")),
          actionButton(ns("clear_filters"), "Clear Filters", class = "btn-warning", icon = icon("times"))
      )
    ),
    fluidRow(
      box(title = "Contacts Table", status = "primary", solidHeader = TRUE, width = 12,
          p("Click on a row to select it. Double-click a cell to edit inline."),
          DTOutput(ns("contacts_table")), br(), uiOutput(ns("table_status_ui")))
    ),
    fluidRow(
      box(title = "Actions for Selected Contact", status = "success", solidHeader = TRUE, width = 12,
          p("Select a contact and choose an action below."),
          fluidRow(
            column(4, actionButton(ns("customise_comm"), "Customise Communication", class = "btn-primary", icon = icon("comments"), style = "width: 100%;")),
            column(4, actionButton(ns("update_record"), "Update Modified Record", class = "btn-success", icon = icon("save"), style = "width: 100%;")),
            column(4, actionButton(ns("delete_record"), "Delete Selected Record", class = "btn-danger", icon = icon("trash"), style = "width: 100%;"))
          ),
          br(), uiOutput(ns("update_status_ui")))
    )
  )
}

explore_contacts_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    display_cols <- c("contact_id", "full_name", "industry", "company", "job_title", "location",
                       "country", "email", "university", "user_notes", "last_interaction_date")

    selected_row <- reactiveVal(NULL)

    contacts_data <- reactive({
      api_manager$state_trigger_contacts()
      api_manager$contacts_cache %||% api_manager$empty_contacts_df()
    })

    observe({
      data <- contacts_data()
      if (is.null(data) || nrow(data) == 0) return()
      updateSelectInput(session, "filter_industry", choices = c("All" = "", unique(data$industry)))
      updateSelectInput(session, "filter_country", choices = c("All" = "", unique(data$country)))
      updateSelectInput(session, "filter_location", choices = c("All" = "", unique(data$location)))
      updateSelectInput(session, "filter_university", choices = c("All" = "", unique(data$university)))
      updateSelectInput(session, "filter_company", choices = c("All" = "", unique(data$company)))
    })

    filtered_data <- reactive({
      data <- contacts_data()
      if (nrow(data) == 0) return(data)
      if (nzchar(input$filter_industry %||% "")) data <- data[data$industry == input$filter_industry, ]
      if (nzchar(input$filter_country %||% "")) data <- data[data$country == input$filter_country, ]
      if (nzchar(input$filter_location %||% "")) data <- data[data$location == input$filter_location, ]
      if (nzchar(input$filter_university %||% "")) data <- data[data$university == input$filter_university, ]
      if (nzchar(input$filter_company %||% "")) data <- data[data$company == input$filter_company, ]
      data
    })

    observeEvent(input$apply_filters, {
      output$table_status_ui <- renderUI({
        div(class = "api-status-success", icon("filter"), " Filters applied. Showing ",
            nrow(filtered_data()), " of ", nrow(contacts_data()), " records.")
      })
    })

    observeEvent(input$clear_filters, {
      updateSelectInput(session, "filter_industry", selected = "")
      updateSelectInput(session, "filter_country", selected = "")
      updateSelectInput(session, "filter_location", selected = "")
      updateSelectInput(session, "filter_university", selected = "")
      updateSelectInput(session, "filter_company", selected = "")
      output$table_status_ui <- renderUI({
        div(class = "api-status-success", icon("check-circle"), " Filters cleared. Showing all ", nrow(contacts_data()), " records.")
      })
    })

    observeEvent(input$refresh_data, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please configure BigQuery settings first (API Settings)!", type = "error", duration = 3)
        return()
      }
      showNotification("Refreshing data from BigQuery...", type = "message", duration = NULL, id = "refresh")
      tryCatch({
        data <- api_manager$bq_load_contacts()
        api_manager$trigger_state_update_contacts()
        removeNotification(id = "refresh")
        output$table_status_ui <- renderUI({
          div(class = "api-status-success", icon("sync"), " Data refreshed. ", nrow(data), " records loaded.")
        })
        showNotification("Data refreshed successfully!", type = "message", duration = 3)
      }, error = function(e) {
        removeNotification(id = "refresh")
        showNotification(paste("Error refreshing:", e$message), type = "error", duration = 10)
      })
    })

    output$contacts_table <- renderDT({
      data <- contacts_data()
      if (nrow(data) == 0) {
        return(datatable(
          data.frame(Message = "No contacts yet. Add your first contact in the 'Process Contact' tab!"),
          options = list(dom = 't', ordering = FALSE), rownames = FALSE, class = 'cell-border stripe'
        ))
      }
      display_data <- filtered_data()[, display_cols]
      datatable(display_data,
        options = list(scrollX = TRUE, pageLength = 10, lengthMenu = c(5, 10, 25, 50), order = list(list(1, 'asc'))),
        editable = list(target = 'cell', disable = list(columns = 0)),
        selection = 'single', rownames = FALSE, class = 'cell-border stripe')
    })

    observeEvent(input$contacts_table_cell_edit, {
      info <- input$contacts_table_cell_edit
      col_name <- display_cols[info$col + 1]
      filtered <- filtered_data()
      contact_id <- filtered$contact_id[info$row]

      updates <- setNames(list(as.character(info$value)), col_name)
      api_manager$bq_update_contact(contact_id, updates)

      output$table_status_ui <- renderUI({
        div(class = "api-status-success", icon("edit"), " Cell edited and synced to BigQuery.")
      })
    })

    observeEvent(input$contacts_table_rows_selected, {
      selected_row(input$contacts_table_rows_selected)
      if (!is.null(selected_row()) && length(selected_row()) > 0) {
        filtered <- filtered_data()
        if (nrow(filtered) > 0) {
          contact <- filtered[selected_row(), ]
          api_manager$selected_contact(contact)
          if (!is.null(contact$email) && contact$email != "" && contact$email != "Not specified") {
            api_manager$selected_contact_email(contact$email)
          } else {
            api_manager$selected_contact_email(NULL)
          }
        }
      }
    })

    observeEvent(input$customise_comm, {
      if (is.null(selected_row()) || length(selected_row()) == 0) {
        showNotification("Please select a contact first!", type = "warning", duration = 3)
        return()
      }
      updateTabItems(session$rootScope(), "sidebar_menu", "customise_communication")
      showNotification("Switched to Customise Communication tab", type = "message", duration = 2)
    })

    observeEvent(input$update_record, {
      if (is.null(selected_row()) || length(selected_row()) == 0) {
        showNotification("Please select a row to update.", type = "warning", duration = 3)
        return()
      }
      filtered <- filtered_data()
      contact_id <- filtered$contact_id[selected_row()]
      output$update_status_ui <- renderUI({
        div(class = "alert-success", icon("check-circle"), " Record already synced (edits save on cell change).",
            tags$br(), tags$small("Contact ID: ", contact_id))
      })
      showNotification("Record is up to date in BigQuery!", type = "message", duration = 5)
    })

    observeEvent(input$delete_record, {
      if (is.null(selected_row()) || length(selected_row()) == 0) {
        showNotification("Please select a row to delete.", type = "warning", duration = 3)
        return()
      }
      filtered <- filtered_data()
      showModal(modalDialog(
        title = "Confirm Delete",
        paste("Are you sure you want to delete contact:", filtered$full_name[selected_row()], "?"),
        footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirm_delete"), "Delete", class = "btn-danger"))
      ))
    })

    observeEvent(input$confirm_delete, {
      removeModal()
      filtered <- filtered_data()
      contact_id <- filtered$contact_id[selected_row()]

      showNotification("Deleting record from BigQuery...", type = "message", duration = NULL, id = "deleting")
      api_manager$bq_delete_contact(contact_id)
      removeNotification(id = "deleting")

      output$update_status_ui <- renderUI({
        div(class = "alert-success", icon("trash"), " Record deleted successfully!", tags$br(), tags$small("Contact ID: ", contact_id))
      })
      showNotification("Record deleted from BigQuery!", type = "message", duration = 5)

      selected_row(NULL)
      api_manager$selected_contact(NULL)
      api_manager$selected_contact_email(NULL)
    })

    output$table_status_ui <- renderUI({ tags$div() })
    output$update_status_ui <- renderUI({ tags$div() })
  })
}
