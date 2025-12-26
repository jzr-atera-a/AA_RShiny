# modules/data_viewer/ui.R
# Data Viewer Module UI

data_viewer_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Data Filters",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(4,
            selectInput(ns("category"),
                       "Category:",
                       choices = c("Select..." = "", "Type A", "Type B", "Type C"))
          ),
          column(4,
            selectInput(ns("subcategory"),
                       "Subcategory:",
                       choices = c("Select..." = ""))
          ),
          column(4,
            actionButton(ns("load"),
                        "Load Data",
                        class = "btn-primary",
                        icon = icon("download"),
                        style = "margin-top: 25px; width: 100%;")
          )
        ),
        
        htmlOutput(ns("filter_status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Data Table",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        
        DT::dataTableOutput(ns("data_table"))
      )
    ),
    
    fluidRow(
      box(
        title = "Data Summary",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        
        htmlOutput(ns("data_summary"))
      )
    )
  )
}
