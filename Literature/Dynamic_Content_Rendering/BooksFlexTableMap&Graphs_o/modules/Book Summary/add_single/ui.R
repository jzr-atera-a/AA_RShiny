# modules/add_single/ui.R

add_single_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Add Single Book Summary Entry",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        textInput(ns("book_name"), "Book Name:", placeholder = "Enter book title"),
        textInput(ns("author"), "Author:", placeholder = "Enter author name"),
        genre_topic_dropdown_ui(ns),
        textInput(ns("chapter"), "Chapter:", placeholder = "e.g., Chapter 01: Introduction"),
        textInput(ns("section"), "Section:", placeholder = "e.g., All Sections"),
        textAreaInput(ns("main_details"), "Main Details:", rows = 8, 
                      placeholder = "Enter summary content..."),
        textInput(ns("numeric_data"), "Numeric Data (comma-separated):", 
                  placeholder = "e.g., 10,25,30,45,60,75"),
        
        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg",
                    icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}
