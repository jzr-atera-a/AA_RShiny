# modules/Exercise Tracker/generate_workout/ui.R

generate_workout_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Session Information",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        fluidRow(
          column(6,
                 dateInput(ns("workout_date"), "Date:", value = Sys.Date()),
                 session_type_dropdown_ui(ns),
                 selectInput(ns("fitness_level"), "Fitness Level:",
                             choices = c("Beginner", "Intermediate", "Advanced"), selected = "Intermediate"),
                 numericInput(ns("duration_minutes"), "Target Duration (minutes, optional):",
                              value = NA, min = 10, max = 240, step = 5)
          ),
          column(6,
                 textAreaInput(ns("session_notes"), "Additional Notes / Goals:", height = "170px",
                               placeholder = paste(
                                 "e.g., Focus on upper body,",
                                 "recovering from a minor knee issue,",
                                 "training for a 10k race",
                                 sep = "\n"))
          )
        ),

        hr(),

        fluidRow(
          column(3, actionButton(ns("generate"), "Plan Workout", icon = icon("dumbbell"),
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
        title = "Generated Workout Plan",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Planning workout... This may take 30-60 seconds.")),

        h5("Review & Edit (re-parse after any manual fix):"),
        textAreaInput(ns("workout_text_edit"), NULL, height = "350px",
                      placeholder = "Generated workout plan will appear here - editable before upload."),
        actionButton(ns("reparse"), "Re-Parse & Update Preview", icon = icon("sync"), class = "btn-default"),

        br(), br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}
