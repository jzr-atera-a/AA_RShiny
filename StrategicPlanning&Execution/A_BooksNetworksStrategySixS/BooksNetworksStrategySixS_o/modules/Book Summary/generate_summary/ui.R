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
        
        checkboxInput(ns("include_math"),
                      "Include mathematical formulas & numeric/graph data",
                      value = FALSE),
        p(class = "text-muted", style = "margin-top: -10px; font-size: 0.9em;",
          "Leave unchecked for books where formulas and numeric metrics wouldn't make sense ",
          "(fiction, biography, philosophy, etc). When unchecked, those fields are saved blank."),
        
        hr(),

        h4(icon("list-ol"), " Book index / table of contents (optional)"),
        fileInput(ns("index_files"), "Upload images or PDFs of the book's index:",
                  multiple = TRUE, width = "100%",
                  accept = c("image/*", ".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".tif", ".tiff", ".heic", ".pdf", "application/pdf"),
                  buttonLabel = "Browse...", placeholder = "JPEG, PNG, GIF, WEBP, PDF, ... (several files allowed)"),
        checkboxInput(ns("sort_index_files"), "Order files by file name (untick to keep the order they were selected in)", value = TRUE),
        p(class = "text-muted", style = "margin-top: -10px; font-size: 0.9em;",
          "Optional. If you upload the index pages, all files are sent together to the Editing Tool in one request, in order, and the summary will have ",
          "exactly one entry per chapter in that index, with the same numbers, titles and order. ",
          "If you upload nothing, the Editing Tool still aims to cover all the actual chapters of the book."),
        uiOutput(ns("index_files_info")),

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
