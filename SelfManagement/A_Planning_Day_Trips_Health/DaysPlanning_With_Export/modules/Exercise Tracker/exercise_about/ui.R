# modules/Exercise Tracker/exercise_about/ui.R

exercise_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Exercise Tracker", status = "info", solidHeader = TRUE, width = 12,

        h3("Exercise Tracker"),
        p("AI-generated and manually-logged workout sessions - gym (cardio, weights) plus other sports and ",
          "activities (swimming, running, yoga, hiking) - part of the Business Operations Suite."),

        hr(),
        h4("Table: atera-2.business_strategy.exercise_log"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - workout_date (STRING)\n  - session_type (STRING) - Gym | Cardio | Swimming | Running | Yoga | Hiking | Mixed | custom\n  - session_notes (STRING)\n  - row_type (STRING) - Exercise | Summary\n  - row_sequence (INTEGER)\n  - exercise_category (STRING) - Cardio | Weights | Swimming | Running | Yoga | Hiking | Sports | Other\n  - exercise_name (STRING)\n  - exercise_details (STRING)\n  - metric_primary (STRING)\n  - metric_secondary (STRING)\n  - calories_burned (STRING)\n  - observations (STRING)"),

        hr(),
        h4("Row Structure"),
        tags$ul(
          tags$li(tags$strong("Exercise"), " row - one per exercise set or activity segment"),
          tags$li(tags$strong("Summary"), " row - one per session, at the end: a one-line session title, total duration/volume, total calories, and key insights")
        ),
        p(tags$em("metric_primary/metric_secondary/calories_burned/observations are reused across row types and exercise categories - ",
                  "e.g. metric_primary is \"sets x reps\" for Weights but \"distance\" or \"duration\" for Cardio/Swimming/Running/Yoga/Hiking.")),

        hr(),
        h4("Pre-Seeded Exercise Library"),
        p("The Exercise / Activity Name dropdown comes pre-populated with real, common entries per category so ",
          "you can log immediately without typing everything from scratch:"),
        tags$ul(
          tags$li(tags$strong("Cardio:"), " Treadmill Run, Stationary Bike, Rowing Machine, Elliptical, Stair Climber, Jump Rope"),
          tags$li(tags$strong("Weights:"), " Bench Press, Squat, Deadlift, Overhead Press, Barbell Row, Bicep Curl, Tricep Extension, Lat Pulldown, Leg Press, Leg Curl, Shoulder Press, Pull-Up, Push-Up, Plank"),
          tags$li(tags$strong("Swimming:"), " Freestyle, Backstroke, Breaststroke, Butterfly, Individual Medley"),
          tags$li(tags$strong("Running:"), " Outdoor Run, Treadmill Run, Trail Run, Interval Sprints"),
          tags$li(tags$strong("Yoga:"), " Vinyasa Flow, Hatha Yoga, Power Yoga, Yin Yoga, Restorative Yoga"),
          tags$li(tags$strong("Hiking:"), " Trail Hike, Mountain Hike, Nature Walk"),
          tags$li(tags$strong("Sports:"), " Basketball, Tennis, Soccer, Cycling, Rock Climbing, Boxing")
        ),
        p("Selecting \"+ Add New Category\" or \"+ Add New Exercise\" lets you extend this list permanently - ",
          "every new value you log becomes available in the dropdown for next time, exactly like every other ",
          "cascade in this suite."),

        hr(),
        p("Part of the Business Operations Suite: Day Planner + Diet Planner + Exercise Tracker + Events Scheduling + Funding Programmes",
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}
