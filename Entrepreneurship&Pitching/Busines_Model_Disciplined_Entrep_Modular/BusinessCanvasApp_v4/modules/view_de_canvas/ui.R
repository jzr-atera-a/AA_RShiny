view_de_canvas_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(12,
             div(class = "selection-controls-box",
                 h3("Select Disciplined Entrepreneurship Canvas"),
                 fluidRow(
                   column(3, selectInput(ns("de_select_business_area"), "Business Area:", choices = NULL)),
                   column(3, selectInput(ns("de_select_project"), "Project:", choices = NULL)),
                   column(3, selectInput(ns("de_select_business_focus"), "Business Focus:", choices = NULL)),
                   column(3, br(), actionButton(ns("loadDECanvas"), "Load Data", class = "btn btn-success btn-lg", icon = icon("download"), width = "100%"))
                 )
             )
      )
    ),
    fluidRow(
      column(12,
             h2("Disciplined Entrepreneurship Canvas", style = "text-align: center; color: white;"),
             div(class = "de-canvas-grid",
                 div(class = "de-box de-box1",
                     div(class = "de-box-number", "1"),
                     div(class = "de-box-title", "Raison d'Être"),
                     htmlOutput(ns("de_box1_content"))
                 ),
                 div(class = "de-box de-box2",
                     div(class = "de-box-number", "2"),
                     div(class = "de-box-title", "Initial Market"),
                     htmlOutput(ns("de_box2_content"))
                 ),
                 div(class = "de-box de-box3",
                     div(class = "de-box-number", "3"),
                     div(class = "de-box-title", "Value Creation"),
                     htmlOutput(ns("de_box3_content"))
                 ),
                 div(class = "de-box de-box4",
                     div(class = "de-box-number", "4"),
                     div(class = "de-box-title", "Competitive Advantage"),
                     htmlOutput(ns("de_box4_content"))
                 ),
                 div(class = "de-box de-box5",
                     div(class = "de-box-number", "5"),
                     div(class = "de-box-title", "Customer Acquisition"),
                     htmlOutput(ns("de_box5_content"))
                 ),
                 div(class = "de-box de-box6",
                     div(class = "de-box-number", "6"),
                     div(class = "de-box-title", "Product Unit Economics"),
                     htmlOutput(ns("de_box6_content"))
                 ),
                 div(class = "de-box de-box7",
                     div(class = "de-box-number", "7"),
                     div(class = "de-box-title", "Sales"),
                     htmlOutput(ns("de_box7_content"))
                 ),
                 div(class = "de-box de-box8",
                     div(class = "de-box-number", "8"),
                     div(class = "de-box-title", "Overall Economics"),
                     htmlOutput(ns("de_box8_content"))
                 ),
                 div(class = "de-box de-box9",
                     div(class = "de-box-number", "9"),
                     div(class = "de-box-title", "Design & Build"),
                     htmlOutput(ns("de_box9_content"))
                 ),
                 div(class = "de-box de-box10",
                     div(class = "de-box-number", "10"),
                     div(class = "de-box-title", "Scaling"),
                     htmlOutput(ns("de_box10_content"))
                 )
             )
      )
    )
  )
}
