# modules/add_single_event/ui.R

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
                 category_dropdown_ui(ns)
          ),
          column(6,
                 dateInput(ns("event_date"), "Event Date: *", value = Sys.Date(), format = "yyyy-mm-dd"),
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
