# modules/Gantt to Tickets/email_contacts.R
# Subtab: Email Contacts

email_contacts_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Filter Contacts", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, selectInput(ns("filter_country"), "Filter by Country:", choices = c("All" = ""), multiple = FALSE)),
            column(3, selectInput(ns("filter_city"), "Filter by City:", choices = c("All" = ""), multiple = FALSE)),
            column(3, selectInput(ns("filter_org"), "Filter by Organization:", choices = c("All" = ""), multiple = FALSE)),
            column(3, br(), actionButton(ns("apply_filters"), "Apply Filters", class = "btn-primary btn-block", icon = icon("filter")))
          ))
    ),
    fluidRow(
      box(title = "Select Recipients", status = "info", solidHeader = TRUE, width = 12,
          DT::dataTableOutput(ns("filtered_contacts_table")), br(),
          fluidRow(
            column(6, actionButton(ns("select_all_contacts"), "Select All", class = "btn-info")),
            column(6, actionButton(ns("deselect_all_contacts"), "Deselect All", class = "btn-warning"))
          ),
          br(), htmlOutput(ns("selected_contacts_count")))
    ),
    fluidRow(
      box(title = "Compose Email", status = "success", solidHeader = TRUE, width = 12,
          textInput(ns("contact_email_subject"), "Email Subject:", placeholder = "Subject line here", width = "100%"),
          textAreaInput(ns("contact_email_body"), "Email Body:", placeholder = "Type your message here...", rows = 10, width = "100%"),
          hr(),
          fluidRow(
            column(6, checkboxInput(ns("include_contact_name"), "Personalize with name (use {NAME} in body)", value = TRUE)),
            column(6, checkboxInput(ns("include_org_name"), "Include organization (use {ORG} in body)", value = FALSE))
          ),
          hr(),
          actionButton(ns("send_contact_emails"), "Send Emails to Selected Contacts", class = "btn-success btn-lg btn-block", icon = icon("paper-plane")),
          br(), verbatimTextOutput(ns("contact_email_results")))
    )
  )
}

email_contacts_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    selected_rows <- reactiveVal(c())
    filtered_data <- reactiveVal(NULL)

    observe({
      api_manager$state_trigger_gantt()
      req(api_manager$gantt_contacts_data)

      if (nrow(api_manager$gantt_contacts_data) > 0) {
        countries <- unique(api_manager$gantt_contacts_data$Country); countries <- countries[countries != ""]
        updateSelectInput(session, "filter_country", choices = c("All" = "", countries))

        cities <- unique(api_manager$gantt_contacts_data$City); cities <- cities[cities != ""]
        updateSelectInput(session, "filter_city", choices = c("All" = "", cities))

        orgs <- unique(api_manager$gantt_contacts_data$Organization); orgs <- orgs[orgs != ""]
        updateSelectInput(session, "filter_org", choices = c("All" = "", orgs))
      }
    })

    observeEvent(input$apply_filters, {
      req(api_manager$gantt_contacts_data)
      filtered <- api_manager$gantt_contacts_data

      if (input$filter_country != "") filtered <- filtered %>% dplyr::filter(Country == input$filter_country)
      if (input$filter_city != "") filtered <- filtered %>% dplyr::filter(City == input$filter_city)
      if (input$filter_org != "") filtered <- filtered %>% dplyr::filter(Organization == input$filter_org)

      filtered_data(filtered)
      showNotification(paste("Filtered to", nrow(filtered), "contacts"), type = "message")
    })

    output$filtered_contacts_table <- DT::renderDataTable({
      data_to_show <- if (!is.null(filtered_data())) filtered_data()
                       else if (!is.null(api_manager$gantt_contacts_data)) api_manager$gantt_contacts_data
                       else data.frame()

      DT::datatable(data_to_show, options = list(pageLength = 10, scrollX = TRUE), selection = 'multiple', rownames = FALSE)
    })

    observeEvent(input$filtered_contacts_table_rows_selected, {
      selected_rows(input$filtered_contacts_table_rows_selected)
    })

    observeEvent(input$select_all_contacts, {
      data_to_show <- if (!is.null(filtered_data())) filtered_data() else api_manager$gantt_contacts_data
      if (!is.null(data_to_show) && nrow(data_to_show) > 0) {
        proxy <- DT::dataTableProxy('filtered_contacts_table')
        DT::selectRows(proxy, 1:nrow(data_to_show))
      }
    })

    observeEvent(input$deselect_all_contacts, {
      proxy <- DT::dataTableProxy('filtered_contacts_table')
      DT::selectRows(proxy, NULL)
    })

    output$selected_contacts_count <- renderUI({
      count <- length(selected_rows())
      if (count == 0) tags$div("No contacts selected. Click on rows to select recipients.")
      else tags$div(class = "status-info", paste("Selected:", count, "contact(s)"))
    })

    observeEvent(input$send_contact_emails, {
      req(selected_rows(), input$contact_email_subject, input$contact_email_body)

      if (!api_manager$gantt_email_connected || length(api_manager$gantt_smtp_config) == 0) {
        showNotification("Please configure email settings first (Email Configuration tab)", type = "error")
        return()
      }

      data_to_use <- if (!is.null(filtered_data())) filtered_data() else api_manager$gantt_contacts_data
      selected_contacts <- data_to_use[selected_rows(), ]

      if (nrow(selected_contacts) == 0) { showNotification("No contacts selected", type = "warning"); return() }

      results <- c()

      withProgress(message = 'Sending emails to contacts...', value = 0, {
        for (i in 1:nrow(selected_contacts)) {
          contact <- selected_contacts[i, ]

          tryCatch({
            email_body <- input$contact_email_body
            if (input$include_contact_name) email_body <- gsub("\\{NAME\\}", contact$Full_Name, email_body)
            if (input$include_org_name) email_body <- gsub("\\{ORG\\}", contact$Organization, email_body)

            api_manager$send_gantt_email(to = contact$Email, subject = input$contact_email_subject, body = email_body)
            results <- c(results, paste("✓", contact$Full_Name, "-", contact$Email))
          }, error = function(e) {
            results <<- c(results, paste("✗", contact$Full_Name, "-", e$message))
          })

          incProgress(1 / nrow(selected_contacts))
        }
      })

      output$contact_email_results <- renderText(paste(results, collapse = "\n"))
      showNotification(paste("Sent", sum(grepl("✓", results)), "of", nrow(selected_contacts), "emails"), type = "message", duration = 10)
    })

    output$contact_email_results <- renderText({ "" })
  })
}
