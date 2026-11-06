# modules/Exercise Tracker/muscle_log/ui.R

muscle_log_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Log a workout (loads, reps and reps-in-reserve)", status = "primary", solidHeader = TRUE, width = 12,
          uiOutput(ns("bq_note")),
          fluidRow(
            column(3, dateInput(ns("date"), "Workout date", value = Sys.Date())),
            column(6, selectInput(ns("programme"), "Planned workout (saved in Muscle Programme)", choices = character(0), width = "100%")),
            column(3, br(), actionButton(ns("load"), "Load workout", icon = icon("download"), class = "btn-primary", style = "width:100%"))
          ),
          p(tags$small("Targets and suggested loads are pre-filled. Type the weight you used, the reps you got and how many reps you had left (RIR) for each set. ",
                       "Rows with no reps are ignored. Next time, the programme suggests your next load from what you log here (double progression).")),
          DT::dataTableOutput(ns("tbl")),
          hr(),
          fluidRow(
            column(4, textInput(ns("free_name"), "Add an extra exercise", "", placeholder = "e.g. Cable curl")),
            column(4, selectInput(ns("free_muscles"), "Main muscle(s)", choices = stats::setNames(MUSCLE_CAT$id, MUSCLE_CAT$name), multiple = TRUE)),
            column(2, numericInput(ns("free_sets"), "Sets", value = 3, min = 1, max = 8)),
            column(2, br(), actionButton(ns("free_add"), "Add", icon = icon("plus"), style = "width:100%"))
          ),
          fluidRow(column(6, actionButton(ns("save"), "Save sets to BigQuery", icon = icon("cloud-upload-alt"), class = "btn-success btn-lg", style = "width:100%"))),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Next time (progression)", status = "info", solidHeader = TRUE, width = 6, DT::dataTableOutput(ns("next_tbl"))),
      box(title = "This week so far (sets vs target)", status = "success", solidHeader = TRUE, width = 6, uiOutput(ns("week_map")))
    )
  )
}
