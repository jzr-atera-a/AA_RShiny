# modules/visualizations/ui.R

visualizations_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Rich Data Visualizations",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4("Select Book to Visualize"),
        p("Choose a book from your BigQuery database to see rich HTML visualizations."),
        
        fluidRow(
          column(4, selectInput(ns("select_book"), "Select Book:", choices = NULL)),
          column(4, selectInput(ns("filter_chapter"), "Filter by Chapter (Optional):",
                                choices = c("All Chapters" = "all"))),
          column(4, actionButton(ns("load_viz"), "Load Visualizations",
                                 class = "btn-success btn-lg", icon = icon("chart-bar"),
                                 style = "width: 100%;"))
        ),
        
        hr(),
        htmlOutput(ns("status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Book Overview",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        htmlOutput(ns("book_header")),
        fluidRow(
          column(3, valueBoxOutput(ns("total_chapters"), width = 12)),
          column(3, valueBoxOutput(ns("total_sections"), width = 12)),
          column(3, valueBoxOutput(ns("avg_numeric"), width = 12)),
          column(3, valueBoxOutput(ns("total_entries"), width = 12))
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Chapter-by-Chapter Breakdown",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        htmlOutput(ns("chapters_html"))
      )
    ),
    
    fluidRow(
      box(
        title = "Numeric Data Trends",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        plotlyOutput(ns("numeric_chart"), height = "500px")
      )
    )
  )
}
