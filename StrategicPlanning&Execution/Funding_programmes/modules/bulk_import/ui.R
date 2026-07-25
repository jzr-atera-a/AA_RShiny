# modules/bulk_import/ui.R

bulk_import_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Bulk Import Funding Programmes to BigQuery",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4("Paste or Generate Programme Data"),
        p("Paste one or more programme entries to parse and upload to BigQuery."),
        
        div(class = "alert alert-info",
            tags$strong("Expected Format (one block per programme, blank line between):"),
            tags$ul(
              tags$li("[programme_name], [category], [country], [city_region]"),
              tags$li("[amount_of_money], [conditions], [key_sponsors]"),
              tags$li("[key_organiser_profiles], [areas_of_application]"),
              tags$li("[start_date_for_applying], [deadline]"),
              tags$li("[recommendations_for_applying], [verified_urls]")
            )
        ),
        
        textAreaInput(ns("programme_text"), "Paste Programme Data Here:", height = "500px",
                      placeholder = "[programme_name]: Horizon Europe SME Instrument\n[category]: Grant\n[country]: European Union\n[city_region]: All\n..."),
        
        fluidRow(
          column(4, actionButton(ns("parse"), "Parse Programmes", class = "btn-info btn-lg",
                                 icon = icon("cogs"), width = "100%")),
          column(4, actionButton(ns("upload"), "Upload to BigQuery", class = "btn-success btn-lg",
                                 icon = icon("cloud-upload-alt"), width = "100%")),
          column(4, actionButton(ns("clear"), "Clear All", class = "btn-danger",
                                 icon = icon("trash"), width = "100%"))
        ),
        
        br(),
        htmlOutput(ns("status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Parsed Data Preview",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        htmlOutput(ns("parse_info")),
        br(),
        div(class = "preview-section", DT::dataTableOutput(ns("preview_table")))
      )
    )
  )
}
