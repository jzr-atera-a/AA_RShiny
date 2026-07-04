# modules/add_single_event/server.R

add_single_event_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    cat_sub <- setup_category_cascade(input, output, session, api_manager)

    observeEvent(input$submit, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      # Required: event_name and description only (city is optional)
      if (trimws(input$event_name) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Event Name is required")
        })
        return()
      }
      if (trimws(input$description) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Description is required")
        })
        return()
      }

      cs <- cat_sub()
      if (nchar(cs$category) == 0 || nchar(cs$subcategory) == 0) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please select or enter both Category and Subcategory")
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"), " Submitting...")
      })

      tryCatch({
        df <- data.frame(
          event_name  = trimws(input$event_name),
          organiser   = if (trimws(input$organiser)   == "") "N/A" else trimws(input$organiser),
          city        = trimws(input$city),       # intentionally blank for global events
          country     = trimws(input$country),
          category    = cs$category,
          subcategory = cs$subcategory,
          event_date  = as.character(input$event_date),
          event_time  = if (trimws(input$event_time)  == "") "TBD" else trimws(input$event_time),
          venue_name  = trimws(input$venue_name),
          address     = trimws(input$address),
          latitude    = if (trimws(input$latitude)    == "") "N/A" else trimws(input$latitude),
          longitude   = if (trimws(input$longitude)   == "") "N/A" else trimws(input$longitude),
          description = trimws(input$description),
          ticket_url  = if (trimws(input$ticket_url)  == "") "N/A" else trimws(input$ticket_url),
          price_range = if (trimws(input$price_range) == "") "N/A" else trimws(input$price_range),
          source_url  = if (trimws(input$source_url)  == "") "N/A" else trimws(input$source_url),
          scan_date   = as.character(Sys.Date()),
          extra_info  = trimws(input$extra_info),
          stringsAsFactors = FALSE
        )

        api_manager$bq_insert(df)
        api_manager$trigger_state_update()

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"), " Event submitted successfully!")
        })
        showNotification("✓ Event submitted!", type = "message")

        # Clear form
        for (f in c("event_name", "organiser", "city", "country",
                    "event_time", "venue_name", "latitude", "longitude",
                    "ticket_url", "price_range", "source_url")) {
          updateTextInput(session, f, value = "")
        }
        updateTextAreaInput(session, "address",     value = "")
        updateTextAreaInput(session, "description", value = "")
        updateTextAreaInput(session, "extra_info",  value = "")
        updateDateInput(session,     "event_date",  value = Sys.Date())

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
