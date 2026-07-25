# modules/add_single/ui.R

add_single_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Add Single Schedule Row Entry",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        dateInput(ns("schedule_date"), "Date:", value = Sys.Date()),
        day_type_dropdown_ui(ns),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'Travel'", ns("day_type_select")),
          country_city_dropdown_ui(ns)
        ),
        textInput(ns("trip_details"), "Trip Details (optional):", placeholder = "e.g., Museum day"),
        
        hr(),
        
        selectInput(ns("row_type"), "Row Type:",
                    choices = c("Location", "Transport", "Summary")),
        textInput(ns("location_name"), "Location / Transport Name:",
                  placeholder = "e.g., Eiffel Tower"),
        textInput(ns("location_details"), "Details:",
                  placeholder = "e.g., Address and short description"),
        textInput(ns("opening_hours"), "Opening Hours (Location rows only):",
                  placeholder = "e.g., 9:00 AM - 6:00 PM, or N/A"),
        textInput(ns("recommended_time"), "Recommended / Expected Time:",
                  placeholder = "e.g., 9:00 AM - 11:00 AM (2h 00m)"),
        textAreaInput(ns("observations"), "Observations:", rows = 4,
                      placeholder = "What to expect, tips, or directions..."),
        
        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg",
                    icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}
