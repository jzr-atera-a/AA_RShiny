# modules/bulk_import/ui.R

bulk_import_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Bulk Import Book Summary to BigQuery",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4("Paste or Generate Book Summary"),
        p("Paste a complete book summary to parse and upload to BigQuery."),
        
        div(class = "alert alert-info",
            tags$strong("Format with NEW Fields:"),
            tags$ul(
              tags$li("Book metadata: [Title], [Author], [Genre], [Topic]"),
              tags$li("[chapter], [section], [main_details]"),
              tags$li("NEW: [formula], [formula_explanation]"),
              tags$li("NEW: [reference_url], [reference_description]"),
              tags$li("[numeric_data], [numeric_data_description]")
            )
        ),
        
        textAreaInput(ns("summary_text"), "Paste Book Summary Here:", height = "500px",
                      placeholder = "[Book Title]\n[Author]\n[Genre]\n[Topic]\n\n[chapter]: Chapter 01: Title\n..."),
        
        fluidRow(
          column(4, actionButton(ns("parse"), "Parse Summary", class = "btn-info btn-lg",
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
