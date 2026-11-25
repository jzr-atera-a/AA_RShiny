# modules/Events Scheduling/add_single_event.R
# ---- module ----------------------------------------------
# id:           add_single_event
# name:         Add Single Event
# icon:         plus-circle
# description:  Manually add a single event entry
# packages:     shiny, shinydashboard
# -----------------------------------------------------------

# ---- UI ----
add_single_event_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Add Single Event Entry",
        status = "primary", solidHeader = TRUE, width = 12,

        fluidRow(
          column(6,
                 textInput(ns("event_name"), "Event Name: *", placeholder = "e.g., London Jazz Festival"),
                 textInput(ns("organiser"),  "Organiser:",    placeholder = "e.g., Ronnie Scott's"),
                 textInput(ns("city"),       "City:",         placeholder = "e.g., London  (optional for global events)"),
                 textInput(ns("country"),    "Country:",      placeholder = "e.g., United Kingdom"),
                 # Category/subcategory mirrors Genre/Topic from books app
                 h5("Classification"),
                 events_category_dropdown_ui(ns)
          ),
          column(6,
                 dateInput(ns("event_date"), "Event Date: *", value = Sys.Date(), format = "yyyy-mm-dd"),
        bos_tz_dropdown_ui(ns, help = "Saved with the entry, so calendar exports use the right zone."),
                 textInput(ns("event_time"), "Event Time:",   placeholder = "e.g., 19:30 or All Day"),
                 textInput(ns("venue_name"), "Venue Name:",   placeholder = "e.g., Barbican Centre"),
                 textAreaInput(ns("address"), "Address:", rows = 2,
                               placeholder = "e.g., Silk Street, London EC2Y 8DS"),
                 fluidRow(
                   column(6, textInput(ns("latitude"),  "Latitude:",  placeholder = "e.g., 51.5132")),
                   column(6, textInput(ns("longitude"), "Longitude:", placeholder = "e.g., -0.0931"))
                 )
          )
        ),

        textAreaInput(ns("description"), "Description: *", rows = 4,
                      placeholder = "Event description (80-150 words recommended)"),

        fluidRow(
          column(4, textInput(ns("ticket_url"),  "Ticket URL:",  placeholder = "https://...")),
          column(4, textInput(ns("price_range"), "Price Range:", placeholder = "e.g., Free, £10-£25, N/A")),
          column(4, textInput(ns("source_url"),  "Source URL:",  placeholder = "https://..."))
        ),

        textAreaInput(ns("extra_info"), "Additional Information:", rows = 2,
                      placeholder = "Any extra notes — accessibility, age restrictions, dress code, special requirements... (optional)"),

        br(),
        actionButton(ns("submit"), "Submit Event", class = "btn-success btn-lg",
                     icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}

# ---- Server ----
add_single_event_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    cat_sub <- setup_events_category_cascade(input, output, session, api_manager)

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

        df$time_zone <- bos_tz_value(input$time_zone)
        api_manager$bq_insert_events(df)
        api_manager$trigger_state_update_events()

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
