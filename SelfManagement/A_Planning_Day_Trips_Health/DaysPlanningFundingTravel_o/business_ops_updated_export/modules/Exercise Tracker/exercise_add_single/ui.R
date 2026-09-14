# modules/Exercise Tracker/exercise_add_single/ui.R

exercise_add_single_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Log a Single Exercise / Activity Entry",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        dateInput(ns("workout_date"), "Date:", value = Sys.Date()),
        session_type_dropdown_ui(ns),
        textInput(ns("session_notes"), "Session Notes (optional):", placeholder = "e.g., Felt strong today"),

        hr(),

        selectInput(ns("row_type"), "Row Type:", choices = c("Exercise", "Summary")),
        h5("Classification"),
        exercise_category_dropdown_ui(ns),
        textInput(ns("exercise_details"), "Details:", placeholder = "e.g., 4 sets x 8 reps, 90s rest"),

        fluidRow(
          column(6, textInput(ns("metric_primary"), "Primary Metric:", placeholder = "e.g., 4 sets x 8 reps, or 5.2 km")),
          column(6, textInput(ns("metric_secondary"), "Secondary Metric:", placeholder = "e.g., 70 kg, or Avg pace 5:30/km, or N/A"))
        ),
        textInput(ns("calories_burned"), "Calories Burned:", placeholder = "e.g., 180 kcal, or N/A"),
        textAreaInput(ns("observations"), "Observations:", rows = 4, placeholder = "Form cues, RPE, how it felt, recommendations..."),

        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg", icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}
