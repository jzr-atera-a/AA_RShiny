# modules/Technical Designs/techdesign_bulk_import/ui.R

techdesign_bulk_import_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Bulk Import Designs", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "alert alert-info",
              "Paste one or many designs in the Technical Designs text format. Separate several designs with a line of ", tags$code("====="),
              " (or simply start the next design with its own header lines). Add a ", tags$code("design_id:"), " header line to give a design a stable id: ",
              "designs whose id already exists are skipped unless you tick 'add as new version'."),
          fluidRow(
            column(4, actionButton(ns("load_seeds"), "Load Starter Library (12 designs)", icon = icon("book"), class = "btn-info", style = "width:100%;")),
            column(4, fileInput(ns("file"), NULL, accept = c(".txt", ".md"), buttonLabel = "Upload .txt file", placeholder = "or choose a text file")),
            column(4, actionButton(ns("clear"), "Clear", icon = icon("eraser"), class = "btn-default", style = "width:100%;"))
          ),
          textAreaInput(ns("text"), NULL, rows = 14, width = "100%", placeholder = "Paste design text here..."),
          fluidRow(
            column(3, actionButton(ns("parse"), "Parse & Validate", icon = icon("search"), class = "btn-primary btn-lg", style = "width:100%;")),
            column(3, actionButton(ns("upload"), "Upload to BigQuery", icon = icon("cloud-upload-alt"), class = "btn-success btn-lg", style = "width:100%;")),
            column(6, checkboxInput(ns("as_version"), "If a design_id already exists, add as a new version instead of skipping", value = FALSE))
          ),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(box(title = "Validation Results", status = "info", solidHeader = TRUE, width = 12, DT::dataTableOutput(ns("preview"))))
  )
}
