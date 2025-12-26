view_de_roadmap_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # JavaScript to detect dropdown click
    tags$head(
      tags$script(HTML(sprintf("
        $(document).on('click', '#%s', function() {
          Shiny.setInputValue('%s', Math.random());
        });
      ", ns("roadmap_select_business_area"), ns("roadmap_select_business_area_clicked"))))
    ),
    
    fluidRow(
      column(12,
             div(class = "selection-controls-box",
                 h3("Select Disciplined Entrepreneurship Roadmap", style = "margin-top: 0; color: #002C3C;"),
                 fluidRow(
                   column(3,
                          selectInput(ns("roadmap_select_business_area"), 
                                      "Business Area:", 
                                      choices = c("Select..." = ""),
                                      width = "100%")
                   ),
                   column(3,
                          selectInput(ns("roadmap_select_project"), 
                                      "Project:", 
                                      choices = c("Select..." = ""),
                                      width = "100%")
                   ),
                   column(3,
                          selectInput(ns("roadmap_select_business_focus"), 
                                      "Business Focus:", 
                                      choices = c("Select..." = ""),
                                      width = "100%")
                   ),
                   column(3,
                          br(),
                          actionButton(ns("loadRoadmap"), 
                                       "Load Data", 
                                       class = "btn btn-success btn-lg",
                                       icon = icon("download"),
                                       width = "100%")
                   )
                 )
             )
      )
    ),
    
    fluidRow(
      column(12,
             h2("Disciplined Entrepreneurship Roadmap", style = "text-align: center; color: white; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
             htmlOutput(ns("roadmap_display"))
      )
    )
  )
}