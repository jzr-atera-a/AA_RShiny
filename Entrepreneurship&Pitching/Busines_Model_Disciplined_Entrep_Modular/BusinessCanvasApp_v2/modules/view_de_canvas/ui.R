view_de_canvas_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # JavaScript to detect dropdown click
    tags$head(
      tags$script(HTML(sprintf("
        $(document).on('click', '#%s', function() {
          Shiny.setInputValue('%s', Math.random());
        });
      ", ns("de_select_business_area"), ns("de_select_business_area_clicked"))))
    ),
    
    fluidRow(
      column(12,
             div(class = "selection-controls-box",
                 h3("Select Disciplined Entrepreneurship Canvas", style = "margin-top: 0; color: #002C3C;"),
                 fluidRow(
                   column(3,
                          selectInput(ns("de_select_business_area"), 
                                      "Business Area:", 
                                      choices = c("Select..." = ""),
                                      width = "100%")
                   ),
                   column(3,
                          selectInput(ns("de_select_project"), 
                                      "Project:", 
                                      choices = c("Select..." = ""),
                                      width = "100%")
                   ),
                   column(3,
                          selectInput(ns("de_select_business_focus"), 
                                      "Business Focus:", 
                                      choices = c("Select..." = ""),
                                      width = "100%")
                   ),
                   column(3,
                          br(),
                          actionButton(ns("loadDECanvas"), 
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
             h2("The Disciplined Entrepreneurship Canvas", style = "text-align: center; color: white; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
             div(class = "de-canvas-grid",
                 div(class = "de-box de-box1",
                     div(class = "de-box-number", "1"),
                     div(class = "de-box-title", "Raison d'Être"),
                     div(class = "de-box-subtitle", "Why do you in business?"),
                     htmlOutput(ns("de_box1_content"))
                 ),
                 
                 div(class = "de-box de-box2",
                     div(class = "de-box-number", "2"),
                     div(class = "de-box-title", "Initial Market"),
                     div(class = "de-box-subtitle", "Who is your customer?"),
                     htmlOutput(ns("de_box2_content"))
                 ),
                 
                 div(class = "de-box de-box3",
                     div(class = "de-box-number", "3"),
                     div(class = "de-box-title", "Value Creation"),
                     div(class = "de-box-subtitle", "What can you do for your customer?"),
                     htmlOutput(ns("de_box3_content"))
                 ),
                 
                 div(class = "de-box de-box4",
                     div(class = "de-box-number", "4"),
                     div(class = "de-box-title", "Competitive Advantage"),
                     div(class = "de-box-subtitle", "Why you?"),
                     htmlOutput(ns("de_box4_content"))
                 ),
                 
                 div(class = "de-box de-box5",
                     div(class = "de-box-number", "5"),
                     div(class = "de-box-title", "Customer Acquisition"),
                     div(class = "de-box-subtitle", "How does your customer acquire your product?"),
                     htmlOutput(ns("de_box5_content"))
                 ),
                 
                 div(class = "de-box de-box6",
                     div(class = "de-box-number", "6"),
                     div(class = "de-box-title", "Product Unit Economics"),
                     div(class = "de-box-subtitle", "Can you make money?"),
                     htmlOutput(ns("de_box6_content"))
                 ),
                 
                 div(class = "de-box de-box7",
                     div(class = "de-box-number", "7"),
                     div(class = "de-box-title", "Sales"),
                     div(class = "de-box-subtitle", "How do you sell your product?"),
                     htmlOutput(ns("de_box7_content"))
                 ),
                 
                 div(class = "de-box de-box8",
                     div(class = "de-box-number", "8"),
                     div(class = "de-box-title", "Overall Economics"),
                     div(class = "de-box-subtitle", "Does your product make money?"),
                     htmlOutput(ns("de_box8_content"))
                 ),
                 
                 div(class = "de-box de-box9",
                     div(class = "de-box-number", "9"),
                     div(class = "de-box-title", "Design & Build"),
                     div(class = "de-box-subtitle", "How do you produce the product?"),
                     htmlOutput(ns("de_box9_content"))
                 ),
                 
                 div(class = "de-box de-box10",
                     div(class = "de-box-number", "10"),
                     div(class = "de-box-title", "Scaling"),
                     div(class = "de-box-subtitle", "How do you scale?"),
                     htmlOutput(ns("de_box10_content"))
                 )
             )
      )
    )
  )
}