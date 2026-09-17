# modules/Funding Programmes/funding_add_single.R
# Subtab: Add Single Entry

funding_add_single_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Add Single Programme Entry", status = "primary", solidHeader = TRUE, width = 12,
          funding_category_dropdown_ui(ns),
          funding_country_cityregion_dropdown_ui(ns),
          hr(),
          textInput(ns("programme_name"), "Programme Name: *", placeholder = "e.g., Horizon Europe SME Instrument"),
          textInput(ns("amount_of_money"), "Amount of Money:", placeholder = "e.g., Up to EUR 2.5 million"),
          textAreaInput(ns("conditions"), "Conditions:", rows = 3, placeholder = "Eligibility requirements..."),
          textInput(ns("key_sponsors"), "Key Sponsors:", placeholder = "e.g., European Commission"),
          textAreaInput(ns("key_organiser_profiles"), "Key Organiser Profiles:", rows = 2,
                       placeholder = "Names/roles of key people who run this programme"),
          textInput(ns("areas_of_application"), "Areas of Application:", placeholder = "e.g., Deep tech, climate, health"),
          fluidRow(
            column(6, textInput(ns("start_date_for_applying"), "Start Date for Applying:", placeholder = "YYYY-MM-DD, or e.g. 'Rolling basis'")),
            column(6, textInput(ns("deadline"), "Deadline:", placeholder = "YYYY-MM-DD, or e.g. 'Rolling basis'"))
          ),
          textAreaInput(ns("recommendations_for_applying"), "Recommendations for Applying:", rows = 3),
          textAreaInput(ns("verified_urls"), "Verified URLs (comma or newline separated):", rows = 2,
                       placeholder = "https://example.com, https://example.com/apply"),
          br(),
          actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg", icon = icon("save"), style = "width: 100%;"),
          br(), br(), htmlOutput(ns("status")))
    )
  )
}

funding_add_single_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    category_react <- setup_funding_category_cascade(input, output, session, api_manager)
    country_cityregion_react <- setup_funding_country_cityregion_cascade(input, output, session, api_manager)

    observeEvent(input$submit, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      cat_val <- category_react()
      cc <- country_cityregion_react()

      if (nchar(cat_val) == 0 || nchar(cc$country) == 0 || trimws(input$programme_name) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please fill in Category, Country, and Programme Name")
        })
        return()
      }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting...") })

      tryCatch({
        df <- data.frame(
          category = cat_val, country = cc$country, city_region = cc$city_region,
          programme_name = trimws(input$programme_name), amount_of_money = trimws(input$amount_of_money),
          conditions = trimws(input$conditions), key_sponsors = trimws(input$key_sponsors),
          key_organiser_profiles = trimws(input$key_organiser_profiles),
          areas_of_application = trimws(input$areas_of_application),
          start_date_for_applying = trimws(input$start_date_for_applying), deadline = trimws(input$deadline),
          recommendations_for_applying = trimws(input$recommendations_for_applying),
          verified_urls = trimws(input$verified_urls), stringsAsFactors = FALSE
        )

        api_manager$bq_insert_funding(df)
        api_manager$trigger_state_update_funding()

        output$status <- renderUI({ tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Entry submitted successfully!") })
        showNotification("✓ Entry submitted!", type = "message")

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
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
  })
}
