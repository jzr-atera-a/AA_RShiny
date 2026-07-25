# modules/bulk_import/ui.R

bulk_import_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Bulk Import Day Schedule to BigQuery",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4("Paste or Generate Day Schedule"),
        p("Paste a complete day schedule to parse and upload to BigQuery."),
        
        div(class = "alert alert-info",
            tags$strong("Expected Format:"),
            tags$ul(
              tags$li("Day metadata: [Date], [Day Type], [Country], [City], [Trip Details]"),
              tags$li("[row_type]: Location | Transport | Summary"),
              tags$li("[location_name], [location_details]"),
              tags$li("[opening_hours], [recommended_time]"),
              tags$li("[observations]")
            )
        ),
        
        textAreaInput(ns("schedule_text"), "Paste Day Schedule Here:", height = "500px",
                      placeholder = "[2026-07-10]\n[Travel]\n[France]\n[Paris]\n[Museum day]\n\n[row_type]: Location\n..."),
        
        fluidRow(
          column(4, actionButton(ns("parse"), "Parse Schedule", class = "btn-info btn-lg",
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
