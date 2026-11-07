# modules/add_single/server.R

add_single_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    day_type_react <- setup_day_type_cascade(input, output, session, api_manager)
    country_city_react <- setup_country_city_cascade(input, output, session, api_manager)
    
    observeEvent(input$submit, {
      
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      
      dt <- day_type_react()
      
      if (nchar(dt) == 0 || trimws(input$location_name) == "" ||
          trimws(input$location_details) == "" || trimws(input$recommended_time) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Type of Day, Name, Details, and Recommended Time")
        })
        return()
      }
      
      is_travel <- identical(dt, "Travel")
      country <- "N/A"
      city <- "N/A"
      
      if (is_travel) {
        cc <- country_city_react()
        if (nchar(cc$country) == 0 || nchar(cc$city) == 0) {
          output$status <- renderUI({
            tags$div(class = "status-error",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     " Please select or enter both Country and City for a Travel day")
          })
          return()
        }
        country <- cc$country
        city <- cc$city
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Submitting...")
      })
      
      tryCatch({
        schedule_date_chr <- as.character(input$schedule_date)
        
        # Auto-increment row_sequence within this date
        next_seq <- tryCatch({
          safe_date <- safe_sql_escape(schedule_date_chr)
          q <- sprintf("SELECT COALESCE(MAX(row_sequence), 0) as max_seq FROM `%s` WHERE schedule_date = '%s'",
                       api_manager$bq_full_table_id, safe_date)
          r <- api_manager$bq_query(q)
          as.integer(r$max_seq[1]) + 1
        }, error = function(e) 1)
        
        df <- data.frame(
          schedule_date = schedule_date_chr,
          day_type = dt,
          country = country,
          city = city,
          trip_details = ifelse(trimws(input$trip_details) == "", "N/A", trimws(input$trip_details)),
          row_type = input$row_type,
          row_sequence = next_seq,
          location_name = trimws(input$location_name),
          location_details = trimws(input$location_details),
          opening_hours = ifelse(trimws(input$opening_hours) == "", "N/A", trimws(input$opening_hours)),
          recommended_time = trimws(input$recommended_time),
          observations = trimws(input$observations),
          stringsAsFactors = FALSE
        )
        
        api_manager$bq_insert(df)
        
        # ⭐ TRIGGER DATA REFRESH - notify other modules
        api_manager$trigger_state_update()
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Entry submitted successfully!")
        })
        
        showNotification("✓ Entry submitted!", type = "message")
        
        # Clear inputs (keep date/day type/location for fast repeated entry)
        updateTextInput(session, "location_name", value = "")
        updateTextInput(session, "location_details", value = "")
        updateTextInput(session, "opening_hours", value = "")
        updateTextInput(session, "recommended_time", value = "")
        updateTextAreaInput(session, "observations", value = "")
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    output$status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
