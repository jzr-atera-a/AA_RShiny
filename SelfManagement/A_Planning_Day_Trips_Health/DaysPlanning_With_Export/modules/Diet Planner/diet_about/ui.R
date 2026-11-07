# modules/Diet Planner/diet_about/ui.R

diet_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Diet Planner", status = "info", solidHeader = TRUE, width = 12,

        h3("Diet Planner"),
        p("AI-generated and manually-logged daily meal plans, part of the Business Operations Suite."),

        hr(),
        h4("Table: atera-2.business_strategy.diet_log"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - log_date (STRING)\n  - diet_type (STRING)\n  - dietary_restrictions (STRING)\n  - row_type (STRING) - Meal | Summary\n  - row_sequence (INTEGER)\n  - meal_name (STRING)\n  - meal_details (STRING)\n  - meal_time (STRING)\n  - calories_macros (STRING)\n  - observations (STRING)"),

        hr(),
        h4("Row Structure"),
        tags$ul(
          tags$li(tags$strong("Meal"), " row - one per meal (Breakfast/Lunch/Dinner/Snack): name, ingredients, time, calories/macros, and tips"),
          tags$li(tags$strong("Summary"), " row - one per day, at the end: a one-line day title, total calories/macros, and key nutritional insights")
        ),
        p(tags$em("calories_macros and observations are reused across both row types - per-meal values vs. day totals; per-meal tips vs. day-level insights.")),

        hr(),
        h4("Every Day Can Be Logged"),
        tags$ul(
          tags$li(tags$strong("Generate Diet:"), " Claude designs a full day of meals matching your diet type, restrictions, and calorie target"),
          tags$li(tags$strong("Bulk Import:"), " paste a complete day's meals (from Generate Diet or written manually) and upload in one go"),
          tags$li(tags$strong("Add Single Entry:"), " log one meal at a time as you eat, building up the day incrementally"),
          tags$li(tags$strong("Browse Data:"), " see every logged day across time"),
          tags$li(tags$strong("Visualizations:"), " meal timeline plus a stacked macro breakdown chart per meal")
        ),

        hr(),
        p("Part of the Business Operations Suite: Day Planner + Diet Planner + Exercise Tracker + Events Scheduling + Funding Programmes",
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}
