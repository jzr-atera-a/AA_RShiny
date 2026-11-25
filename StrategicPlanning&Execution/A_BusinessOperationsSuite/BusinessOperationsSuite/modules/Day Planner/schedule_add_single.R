# modules/Day Planner/schedule_add_single.R
# ---- module ----------------------------------------------
# id:           schedule_add_single
# name:         Add Single Entry
# icon:         plus-circle
# description:  Add an individual schedule row entry
# packages:     shiny, shinydashboard
# -----------------------------------------------------------

# ---- UI ----
schedule_add_single_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Add Single Schedule Row Entry",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        dateInput(ns("schedule_date"), "Date:", value = Sys.Date()),
        bos_tz_dropdown_ui(ns, help = "Saved with the entry, so calendar exports use the right zone."),
        schedule_daytype_dropdown_ui(ns),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'Travel'", ns("day_type_select")),
          schedule_country_city_dropdown_ui(ns)
        ),
        textInput(ns("trip_details"), "Trip Details (optional):", placeholder = "e.g., Museum day"),

        hr(),

        selectInput(ns("row_type"), "Row Type:", choices = c("Location", "Transport", "Summary")),
        textInput(ns("location_name"), "Location / Transport Name:", placeholder = "e.g., Eiffel Tower"),
        textInput(ns("location_details"), "Details:", placeholder = "e.g., Address and short description"),
        textInput(ns("opening_hours"), "Opening Hours (Location rows only):", placeholder = "e.g., 9:00 AM - 6:00 PM, or N/A"),
        textInput(ns("recommended_time"), "Recommended / Expected Time:", placeholder = "e.g., 9:00 AM - 11:00 AM (2h 00m)"),
        textAreaInput(ns("observations"), "Observations:", rows = 4, placeholder = "What to expect, tips, or directions..."),

        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg", icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}

# ---- Server ----
schedule_add_single_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    day_type_react <- setup_schedule_daytype_cascade(input, output, session, api_manager)
    country_city_react <- setup_schedule_country_city_cascade(input, output, session, api_manager)

    observeEvent(input$submit, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      dt <- day_type_react()
      if (nchar(dt) == 0 || trimws(input$location_name) == "" || trimws(input$location_details) == "" || trimws(input$recommended_time) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Type of Day, Name, Details, and Recommended Time")
        })
        return()
      }

      is_travel <- identical(dt, "Travel")
      country <- "N/A"; city <- "N/A"
      if (is_travel) {
        cc <- country_city_react()
        if (nchar(cc$country) == 0 || nchar(cc$city) == 0) {
          output$status <- renderUI({
            tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                     " Please select or enter both Country and City for a Travel day")
          })
          return()
        }
        country <- cc$country; city <- cc$city
      }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting...") })

      tryCatch({
        schedule_date_chr <- as.character(input$schedule_date)

        next_seq <- tryCatch({
          safe_date <- safe_sql_escape(schedule_date_chr)
          q <- sprintf("SELECT COALESCE(MAX(row_sequence), 0) as max_seq FROM `%s` WHERE schedule_date = '%s'",
                       api_manager$bq_full_table_schedule, safe_date)
          r <- api_manager$bq_query(q)
          as.integer(r$max_seq[1]) + 1
        }, error = function(e) 1)

        df <- data.frame(
          schedule_date = schedule_date_chr, day_type = dt, country = country, city = city,
          trip_details = ifelse(trimws(input$trip_details) == "", "N/A", trimws(input$trip_details)),
          row_type = input$row_type, row_sequence = next_seq,
          location_name = trimws(input$location_name), location_details = trimws(input$location_details),
          opening_hours = ifelse(trimws(input$opening_hours) == "", "N/A", trimws(input$opening_hours)),
          recommended_time = trimws(input$recommended_time), observations = trimws(input$observations),
          stringsAsFactors = FALSE
        )

        df$time_zone <- bos_tz_value(input$time_zone)
        api_manager$bq_insert_schedule(df)
        api_manager$trigger_state_update_schedule()

        output$status <- renderUI({ tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Entry submitted successfully!") })
        showNotification("✓ Entry submitted!", type = "message")

        updateTextInput(session, "location_name", value = "")
        updateTextInput(session, "location_details", value = "")
        updateTextInput(session, "opening_hours", value = "")
        updateTextInput(session, "recommended_time", value = "")
        updateTextAreaInput(session, "observations", value = "")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
