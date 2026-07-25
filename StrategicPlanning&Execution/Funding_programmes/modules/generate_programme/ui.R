# modules/generate_programme/ui.R

generate_programme_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Find Funding Programmes",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        div(class = "alert alert-info",
            tags$strong("Accuracy note:"),
            " Claude generates results from its training data, which can be outdated or incomplete for ",
            "fast-changing programmes. Always verify amounts, dates, and URLs on the official site before ",
            "relying on them."),
        
        fluidRow(
          column(6,
                 category_dropdown_ui(ns),
                 country_cityregion_dropdown_ui(ns)
          ),
          column(6,
                 textAreaInput(ns("search_focus"), "Additional Focus (optional):", height = "140px",
                               placeholder = paste(
                                 "e.g., Early-stage climate tech startups,",
                                 "non-dilutive funding preferred,",
                                 "pre-seed to seed stage",
                                 sep = "\n")),
                 numericInput(ns("n_results"), "Number of Programmes to Find:",
                              value = 4, min = 1, max = 8, step = 1)
          )
        ),
        
        hr(),
        
        fluidRow(
          column(3,
                 actionButton(ns("generate"), "Find Programmes", icon = icon("search-dollar"),
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
        title = "Discovered Programmes",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        
        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Searching... This may take 30-90 seconds.")),
        
        verbatimTextOutput(ns("programme_text")),
        htmlOutput(ns("status"))
      )
    )
  )
}
