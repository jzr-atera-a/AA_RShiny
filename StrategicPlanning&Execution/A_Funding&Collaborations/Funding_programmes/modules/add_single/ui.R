# modules/add_single/ui.R

add_single_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Add Single Programme Entry",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        category_dropdown_ui(ns),
        country_cityregion_dropdown_ui(ns),
        
        hr(),
        
        textInput(ns("programme_name"), "Programme Name: *", placeholder = "e.g., Horizon Europe SME Instrument"),
        textInput(ns("amount_of_money"), "Amount of Money:", placeholder = "e.g., Up to EUR 2.5 million"),
        textAreaInput(ns("conditions"), "Conditions:", rows = 3, placeholder = "Eligibility requirements..."),
        textInput(ns("key_sponsors"), "Key Sponsors:", placeholder = "e.g., European Commission"),
        textAreaInput(ns("key_organiser_profiles"), "Key Organiser Profiles:", rows = 2,
                     placeholder = "Names/roles of key people who run this programme"),
        textInput(ns("areas_of_application"), "Areas of Application:", placeholder = "e.g., Deep tech, climate, health"),
        
        fluidRow(
          column(6, textInput(ns("start_date_for_applying"), "Start Date for Applying:",
                              placeholder = "YYYY-MM-DD, or e.g. 'Rolling basis'")),
          column(6, textInput(ns("deadline"), "Deadline:",
                              placeholder = "YYYY-MM-DD, or e.g. 'Rolling basis'"))
        ),
        
        textAreaInput(ns("recommendations_for_applying"), "Recommendations for Applying:", rows = 3),
        textAreaInput(ns("verified_urls"), "Verified URLs (comma or newline separated):", rows = 2,
                     placeholder = "https://example.com, https://example.com/apply"),
        
        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg",
                    icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}
