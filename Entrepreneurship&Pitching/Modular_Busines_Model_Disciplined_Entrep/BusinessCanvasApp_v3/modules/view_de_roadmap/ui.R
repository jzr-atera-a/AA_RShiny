view_de_roadmap_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(12,
             div(class = "selection-controls-box",
                 h3("Select Disciplined Entrepreneurship Roadmap"),
                 fluidRow(
                   column(3, selectInput(ns("roadmap_select_business_area"), "Business Area:", choices = NULL)),
                   column(3, selectInput(ns("roadmap_select_project"), "Project:", choices = NULL)),
                   column(3, selectInput(ns("roadmap_select_business_focus"), "Business Focus:", choices = NULL)),
                   column(3, br(), actionButton(ns("loadRoadmap"), "Load Data", class = "btn btn-success btn-lg", width = "100%"))
                 )
             )
      )
    ),
    fluidRow(
      column(12,
             h2("Disciplined Entrepreneurship Roadmap (24 Steps)", style = "text-align: center; color: white;"),
             htmlOutput(ns("roadmap_display"))
      )
    )
  )
}
