# modules/Day Planner/generate_schedule/ui.R

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
                 schedule_daytype_dropdown_ui(ns)
          ),
          column(6,
                 schedule_country_city_dropdown_ui(ns),
                 p(class = "text-muted", style = "margin-top: -8px; font-size: 0.85em;",
                   icon("cloud-sun"), " Required for Travel days; optional otherwise - used to look up ",
                   "the real weather forecast for that day and plan around it."),
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
          column(3, actionButton(ns("generate"), "Plan Schedule", icon = icon("route"),
                                 class = "btn-primary btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("copy_to_bulk"), "Copy to Bulk Import", icon = icon("arrow-right"),
                                 class = "btn-info btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("parse_and_upload"), "Parse & Upload Direct", icon = icon("cloud-upload-alt"),
                                 class = "btn-success btn-lg", style = "width: 100%;")),
          column(3, downloadButton(ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;"))
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

        h5("Review & Edit (re-parse after any manual fix):"),
        textAreaInput(ns("schedule_text_edit"), NULL, height = "350px",
                      placeholder = "Generated schedule will appear here - editable before upload."),
        actionButton(ns("reparse"), "Re-Parse & Update Preview", icon = icon("sync"), class = "btn-default"),

        br(), br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}
