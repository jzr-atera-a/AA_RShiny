# modules/Day Planner/schedule_commitments_browse/server.R

schedule_commitments_browse_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    browse_data <- reactiveVal(data.frame())

    load_commitments <- function() {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading...") })
      tryCatch({
        data <- api_manager$bq_get_commitments()
        browse_data(data)
        output$table <- DT::renderDataTable({
          DT::datatable(data, selection = "single", options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
        })
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Loaded %d commitment(s)", nrow(data)))
        })
      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
      })
    }

    observeEvent(input$refresh, { load_commitments() })
    observeEvent(api_manager$state_trigger_schedule(), { if (api_manager$bq_authenticated) load_commitments() }, ignoreInit = TRUE)

    output$download <- downloadHandler(
      filename = function() paste0("monthly_commitments_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) if (nrow(browse_data()) > 0) write.csv(browse_data(), file, row.names = FALSE)
    )

    observeEvent(input$btn_update_status, {
      sel <- input$table_rows_selected
      if (is.null(sel)) { showNotification("Please select a commitment first.", type = "warning"); return() }
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      tryCatch({
        row <- browse_data()[sel, ]
        api_manager$bq_update_commitment(row$id, list(status = input$new_status))
        output$update_status_msg <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Status updated!")
        })
        showNotification("✓ Status updated!", type = "message")
      }, error = function(e) {
        output$update_status_msg <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$btn_send_to_generate, {
      sel <- input$table_rows_selected
      if (is.null(sel)) { showNotification("Please select a commitment first.", type = "warning"); return() }

      row <- browse_data()[sel, ]
      context_text <- format_commitment_for_schedule_context(row)
      api_manager$set_pending_commitment_context(context_text)

      output$send_status <- renderUI({
        tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                 " Sent! Go to Generate Schedule - the commitment's context has been added to Additional Details.")
      })
      updateTabItems(session$rootScope(), "sidebar_menu", selected = "generate_schedule")
      showNotification("✓ Commitment sent to Generate Schedule!", type = "message")
    })

    output$status <- renderUI({ tags$div("Click Refresh Data to load commitments.") })
    output$update_status_msg <- renderUI({ tags$div() })
    output$send_status <- renderUI({ tags$div() })
    output$table <- DT::renderDataTable({ DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE) })

    session$onSessionEnded(function() {})
  })
}
