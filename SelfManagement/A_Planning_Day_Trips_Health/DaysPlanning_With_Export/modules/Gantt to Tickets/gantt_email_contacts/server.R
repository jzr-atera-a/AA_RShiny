# modules/Gantt to Tickets/gantt_email_contacts/server.R

gantt_email_contacts_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    all_contacts <- reactiveVal(data.frame())
    selected_rows <- reactiveVal(integer())

    load_contacts <- function() {
      if (!api_manager$bq_authenticated) return(invisible(NULL))
      data <- tryCatch(api_manager$bq_get_gantt_contacts(), error = function(e) data.frame())
      all_contacts(data)
      if (nrow(data) > 0) {
        updateSelectInput(session, "filter_country", choices = c("All" = "", sort(unique(data$country[nchar(trimws(data$country)) > 0]))))
        updateSelectInput(session, "filter_city", choices = c("All" = "", sort(unique(data$city[nchar(trimws(data$city)) > 0]))))
        updateSelectInput(session, "filter_org", choices = c("All" = "", sort(unique(data$organization[nchar(trimws(data$organization)) > 0]))))
      }
    }

    observe({ api_manager$state_trigger_gantt(); load_contacts() })

    filtered <- reactive({
      d <- all_contacts()
      if (nrow(d) == 0) return(d)
      if (nchar(input$filter_country %||% "") > 0) d <- d[d$country == input$filter_country, ]
      if (nchar(input$filter_city %||% "") > 0) d <- d[d$city == input$filter_city, ]
      if (nchar(input$filter_org %||% "") > 0) d <- d[d$organization == input$filter_org, ]
      d
    })

    observeEvent(input$apply_filters, {
      output$filtered_contacts_table <- DT::renderDataTable({
        DT::datatable(filtered(), selection = "multiple", options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
      })
    })

    output$filtered_contacts_table <- DT::renderDataTable({
      DT::datatable(filtered(), selection = "multiple", options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
    })

    observeEvent(input$select_all_contacts, {
      proxy <- DT::dataTableProxy("filtered_contacts_table")
      DT::selectRows(proxy, seq_len(nrow(filtered())))
    })
    observeEvent(input$deselect_all_contacts, {
      proxy <- DT::dataTableProxy("filtered_contacts_table")
      DT::selectRows(proxy, NULL)
    })

    output$selected_contacts_count <- renderUI({
      n <- length(input$filtered_contacts_table_rows_selected %||% integer())
      tags$div(class = "status-info", sprintf("%d contact(s) selected", n))
    })

    observeEvent(input$send_contact_emails, {
      if (!api_manager$gantt_smtp_authenticated) { showNotification("Please configure and test SMTP in Email Config first!", type = "error"); return() }

      sel <- input$filtered_contacts_table_rows_selected
      if (is.null(sel) || length(sel) == 0) { showNotification("No contacts selected.", type = "warning"); return() }

      recipients <- filtered()[sel, ]
      results <- c()

      withProgress(message = 'Sending emails...', value = 0, {
        for (i in seq_len(nrow(recipients))) {
          contact <- recipients[i, ]
          body <- input$contact_email_body
          if (isTRUE(input$include_contact_name)) body <- gsub("\\{NAME\\}", contact$full_name, body)

          result <- tryCatch({
            api_manager$send_email_via_curl(
              host = api_manager$gantt_smtp_host, port = api_manager$gantt_smtp_port,
              user = api_manager$gantt_smtp_user, password = api_manager$gantt_smtp_password,
              from = api_manager$gantt_smtp_user, to = contact$email, subject = input$contact_email_subject, body = body
            )
            "✓"
          }, error = function(e) paste("✗ Error:", e$message))

          results <- c(results, paste(result, contact$full_name, "(", contact$email, ")"))
          incProgress(1 / nrow(recipients))
        }
      })

      output$contact_email_results <- renderText({ paste(results, collapse = "\n") })
      showNotification(sprintf("Sent %d of %d emails", sum(grepl("^✓", results)), length(results)), type = "message")
    })

    output$contact_email_results <- renderText({ "" })
    session$onSessionEnded(function() {})
  })
}
