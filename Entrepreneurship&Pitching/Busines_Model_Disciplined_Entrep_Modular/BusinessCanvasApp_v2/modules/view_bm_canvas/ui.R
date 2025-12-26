view_bm_canvas_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # JavaScript to detect dropdown click and trigger event
    tags$head(
      tags$script(HTML(sprintf("
        $(document).on('shown.bs.dropdown', '#%s', function() {
          Shiny.setInputValue('%s', Math.random());
        });
        $(document).on('click', '#%s', function() {
          Shiny.setInputValue('%s', Math.random());
        });
      ", ns("select_business_area"), ns("select_business_area_clicked"),
                               ns("select_business_area"), ns("select_business_area_clicked"))))
    ),
    
    fluidRow(
      column(12,
             div(class = "selection-controls-box",
                 h3("Select Business Model Canvas", style = "margin-top: 0; color: #002C3C;"),
                 fluidRow(
                   column(3,
                          selectInput(ns("select_business_area"), 
                                      "Business Area:", 
                                      choices = c("Select..." = ""),
                                      width = "100%")
                   ),
                   column(3,
                          selectInput(ns("select_project"), 
                                      "Project:", 
                                      choices = c("Select..." = ""),
                                      width = "100%")
                   ),
                   column(3,
                          selectInput(ns("select_business_focus"), 
                                      "Business Focus:", 
                                      choices = c("Select..." = ""),
                                      width = "100%")
                   ),
                   column(3,
                          br(),
                          actionButton(ns("loadCanvas"), 
                                       "Load Canvas", 
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
             h2("Business Model Canvas", style = "text-align: center; color: white; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
             div(class = "canvas-grid",
                 div(class = "canvas-section key-partners partners",
                     div(class = "section-title",
                         span(class = "section-icon", "🤝"),
                         "Key Partners"
                     ),
                     htmlOutput(ns("canvas_key_partners"))
                 ),
                 
                 div(class = "canvas-section key-activities activities",
                     div(class = "section-title",
                         span(class = "section-icon", "⚡"),
                         "Key Activities"
                     ),
                     htmlOutput(ns("canvas_key_activities"))
                 ),
                 
                 div(class = "canvas-section key-resources resources",
                     div(class = "section-title",
                         span(class = "section-icon", "🏗️"),
                         "Key Resources"
                     ),
                     htmlOutput(ns("canvas_key_resources"))
                 ),
                 
                 div(class = "canvas-section value-propositions value-prop",
                     div(class = "section-title",
                         span(class = "section-icon", "🎁"),
                         "Value Propositions"
                     ),
                     htmlOutput(ns("canvas_value_propositions"))
                 ),
                 
                 div(class = "canvas-section customer-relationships relationships",
                     div(class = "section-title",
                         span(class = "section-icon", "💝"),
                         "Customer Relationships"
                     ),
                     htmlOutput(ns("canvas_customer_relationships"))
                 ),
                 
                 div(class = "canvas-section channels channels-grid",
                     div(class = "section-title",
                         span(class = "section-icon", "📢"),
                         "Channels"
                     ),
                     htmlOutput(ns("canvas_channels"))
                 ),
                 
                 div(class = "canvas-section customer-segments segments",
                     div(class = "section-title",
                         span(class = "section-icon", "👥"),
                         "Customer Segments"
                     ),
                     htmlOutput(ns("canvas_customer_segments"))
                 ),
                 
                 div(class = "canvas-section cost-structure costs",
                     div(class = "section-title",
                         span(class = "section-icon", "💰"),
                         "Cost Structure"
                     ),
                     htmlOutput(ns("canvas_cost_structure"))
                 ),
                 
                 div(class = "canvas-section revenue-streams revenue",
                     div(class = "section-title",
                         span(class = "section-icon", "💵"),
                         "Revenue Streams"
                     ),
                     htmlOutput(ns("canvas_revenue_streams"))
                 )
             )
      )
    )
  )
}