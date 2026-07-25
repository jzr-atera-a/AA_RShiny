# modules/generate_schedule/ui.R

generate_schedule_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Day Information",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(6,
                 dateInput(ns("schedule_date"), "Date:", value = Sys.Date()),
                 day_type_dropdown_ui(ns)
          ),
          column(6,
                 conditionalPanel(
                   condition = sprintf("input['%s'] == 'Travel'", ns("day_type_select")),
                   country_city_dropdown_ui(ns)
                 ),
                 textAreaInput(ns("trip_details"), "Additional Details:", height = "140px",
                               placeholder = paste(
                                 "e.g., Start point: Hotel near Bir-Hakeim.",
                                 "End point: back at the hotel by 8pm.",
                                 "Must visit: Eiffel Tower, Louvre.",
                                 "Prefer walking over taxis.",
                                 sep = "\n"))
          )
        ),
        
        hr(),
        
        fluidRow(
          column(3,
                 actionButton(ns("generate"), "Plan Schedule", icon = icon("route"),
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
        title = "Generated Schedule",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        
        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Planning schedule... This may take 30-90 seconds.")),
        
        verbatimTextOutput(ns("schedule_text")),
        htmlOutput(ns("status"))
      )
    )
  )
}
