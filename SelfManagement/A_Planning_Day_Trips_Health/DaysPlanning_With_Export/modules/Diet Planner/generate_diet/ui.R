# modules/Diet Planner/generate_diet/ui.R

generate_diet_ui <- function(id) {
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
                 dateInput(ns("log_date"), "Date:", value = Sys.Date()),
                 diet_type_dropdown_ui(ns),
                 numericInput(ns("target_calories"), "Daily Calorie Target (optional):",
                              value = NA, min = 800, max = 5000, step = 50)
          ),
          column(6,
                 textInput(ns("dietary_restrictions"), "Dietary Restrictions / Allergies (optional):",
                           placeholder = "e.g., Gluten-free, Nut allergy, Lactose intolerant"),
                 textAreaInput(ns("preferences"), "Additional Preferences:", height = "120px",
                               placeholder = paste(
                                 "e.g., High protein, avoid dairy,",
                                 "prefer quick meals under 20 minutes,",
                                 "like Mediterranean flavours",
                                 sep = "\n"))
          )
        ),

        hr(),

        fluidRow(
          column(3, actionButton(ns("generate"), "Plan Diet", icon = icon("utensils"),
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
        title = "Generated Diet Plan",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Planning meals... This may take 30-60 seconds.")),

        h5("Review & Edit (re-parse after any manual fix):"),
        textAreaInput(ns("diet_text_edit"), NULL, height = "350px",
                      placeholder = "Generated diet plan will appear here - editable before upload."),
        actionButton(ns("reparse"), "Re-Parse & Update Preview", icon = icon("sync"), class = "btn-default"),

        br(), br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}
