# modules/generate_summary/ui.R

generate_summary_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Book Information",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(6,
                 textInput(ns("book_title"), "Book Title:", placeholder = "e.g., Super Founders"),
                 textInput(ns("book_author"), "Author Name:", placeholder = "e.g., Ali Tamaseb")
          ),
          column(6,
                 genre_topic_dropdown_ui(ns)
          )
        ),
        
        hr(),
        
        fluidRow(
          column(3,
                 actionButton(ns("generate"), "Generate Summary", icon = icon("magic"),
                              class = "btn-primary btn-lg", style = "width: 100%;")
          ),
          column(3,
                 actionButton(ns("copy_to_bulk"), "Copy to Bulk Import", icon = icon("arrow-right"),
                              class = "btn-info btn-lg", style = "width: 100%;")
          ),
          column(3,
                 actionButton(ns("parse_and_upload"), "Parse & Upload Direct", icon = icon("cloud-upload-alt"),
                              class = "btn-success btn-lg", style = "width: 100%;")
          ),
          column(3,
                 downloadButton(ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;")
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Generated Summary",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        
        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Generating summary... This may take a minute or two.")),
        
        verbatimTextOutput(ns("summary_text")),
        htmlOutput(ns("status"))
      )
    )
  )
}
