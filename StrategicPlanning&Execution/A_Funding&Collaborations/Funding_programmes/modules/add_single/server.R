# modules/add_single/server.R

add_single_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    category_react <- setup_category_cascade(input, output, session, api_manager)
    country_cityregion_react <- setup_country_cityregion_cascade(input, output, session, api_manager)
    
    observeEvent(input$submit, {
      
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      
      cat_val <- category_react()
      cc <- country_cityregion_react()
      
      if (nchar(cat_val) == 0 || nchar(cc$country) == 0 || trimws(input$programme_name) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Category, Country, and Programme Name")
        })
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting...")
      })
      
      tryCatch({
        df <- data.frame(
          category = cat_val,
          country = cc$country,
          city_region = cc$city_region,
          programme_name = trimws(input$programme_name),
          amount_of_money = trimws(input$amount_of_money),
          conditions = trimws(input$conditions),
          key_sponsors = trimws(input$key_sponsors),
          key_organiser_profiles = trimws(input$key_organiser_profiles),
          areas_of_application = trimws(input$areas_of_application),
          start_date_for_applying = trimws(input$start_date_for_applying),
          deadline = trimws(input$deadline),
          recommendations_for_applying = trimws(input$recommendations_for_applying),
          verified_urls = trimws(input$verified_urls),
          stringsAsFactors = FALSE
        )
        
        api_manager$bq_insert(df)
        api_manager$trigger_state_update()
        
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " Entry submitted successfully!")
        })
        
        showNotification("✓ Entry submitted!", type = "message")
        
        # Clear content fields (keep category/country selection for fast repeated entry)
        updateTextInput(session, "programme_name", value = "")
        updateTextInput(session, "amount_of_money", value = "")
        updateTextAreaInput(session, "conditions", value = "")
        updateTextInput(session, "key_sponsors", value = "")
        updateTextAreaInput(session, "key_organiser_profiles", value = "")
        updateTextInput(session, "areas_of_application", value = "")
        updateTextInput(session, "start_date_for_applying", value = "")
        updateTextInput(session, "deadline", value = "")
        updateTextAreaInput(session, "recommendations_for_applying", value = "")
        updateTextAreaInput(session, "verified_urls", value = "")
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    output$status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
