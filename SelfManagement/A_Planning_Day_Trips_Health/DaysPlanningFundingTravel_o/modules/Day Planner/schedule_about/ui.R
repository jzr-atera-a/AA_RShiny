# modules/Day Planner/schedule_about/ui.R

schedule_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Day Planner", status = "info", solidHeader = TRUE, width = 12,

        h3("Day Planner"),
        p("AI-powered day/trip schedule generation, part of the Business Operations Suite."),

        hr(),
        h4("Table: atera-2.business_strategy.day_scheduler"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - schedule_date (STRING)\n  - day_type (STRING)\n  - country (STRING)\n  - city (STRING)\n  - trip_details (STRING)\n  - row_type (STRING) - Location | Transport | Summary\n  - row_sequence (INTEGER)\n  - location_name (STRING)\n  - location_details (STRING)\n  - opening_hours (STRING)\n  - recommended_time (STRING)\n  - observations (STRING)"),

        hr(),
        h4("Weather-Aware Planning"),
        p("Before planning, Claude searches the web for the real weather forecast for the date and location ",
          "you provide, and factors it into the route (indoor/outdoor choices, timing around rain, what to ",
          "bring). No schema change was needed - the forecast is woven into the existing ", tags$code("observations"),
          " field: a one-line \"Weather Forecast: ...\" summary opens the Summary row's observations, and any ",
          "weather-sensitive Location/Transport row gets a practical tip in its own observations."),
        p(tags$em("Country/City are optional for non-Travel days too - fill them in if you want weather-aware ",
                  "planning for a Work/Conference/Research day; leave blank to skip weather research entirely.")),

        hr(),
        h4("Night-Before Prep Checklist"),
        p("Generate Prep Steps reads a date you've already planned above and asks Claude for a short, ",
          "motivational checklist of things to do beforehand to be ready for it - a different concept from ",
          "the itinerary itself, which plans what happens ", tags$em("during"), " the day."),
        h5("Table: atera-2.business_strategy.day_prep_steps"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - schedule_date (STRING) - links back to a day_scheduler date\n  - category (STRING) - e.g. Work, Fitness, Health, Travel, General\n  - location (STRING) - e.g. Office, Home, Gym\n  - additional_context (STRING)\n  - step_sequence (INTEGER)\n  - step_text (STRING)\n  - is_completed (BOOL)"),
        p(tags$strong("Note:"), " unlike every other table in Day Planner, ", tags$code("is_completed"),
          " is genuinely mutable - toggling a checkbox in Prep Checklist issues a real ",
          tags$code("UPDATE"), ", and saving a regenerated checklist for a date issues a real ",
          tags$code("DELETE"), " of that date's previous steps first. This is a deliberate exception to the ",
          "append-only pattern used everywhere else in this suite (the only other exception in the whole app ",
          "is Contact Manager's mutable contact records)."),

        hr(),
        h4("Monthly Commitments"),
        p("Log commitments - Category/Sector/Topic, day of commitment, deadline, description, stakeholders, ",
          "the value of delivering, and the consequences of not delivering - track their status over the ",
          "month, optionally push them as Trello cards, and pull any commitment's full context straight into ",
          "Generate Schedule's Additional Details field so Claude plans the day with real time allocated ",
          "toward delivering it."),
        h5("Table: atera-2.business_strategy.monthly_commitments"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - category (STRING) - e.g. Strategic, Operational, Financial, Regulatory, Partnership\n  - sector (STRING) - e.g. Technology, Healthcare, Finance, Retail\n  - topic (STRING) - free text, no defaults\n  - commitment_date (STRING) - the day the commitment was made\n  - deadline (STRING)\n  - status (STRING) - Not Started | In Progress | Delivered | Missed | At Risk\n  - description (STRING)\n  - stakeholders (STRING)\n  - value_of_delivery (STRING)\n  - consequences_of_failure (STRING)\n  - trello_card_id (STRING) - \"N/A\" until pushed to Trello\n  - trello_card_url (STRING) - \"N/A\" until pushed to Trello"),
        p(tags$strong("Note:"), " genuinely mutable, like ", tags$code("day_prep_steps"), " above - ",
          tags$code("status"), " and the Trello linkage fields are updated in place via a real ", tags$code("UPDATE"),
          " as a commitment progresses, rather than logged as a new row each time."),
        p(tags$strong("Trello connection:"), " Commitment Trello Config is a ", tags$em("separate"), " Trello ",
          "connection from the one Gantt to Tickets uses - point it at whichever board you track commitments ",
          "on, which may differ from your project-tasks board."),

        hr(),
        h4("Row Structure"),
        tags$ul(
          tags$li(tags$strong("Location"), " row - one per place visited"),
          tags$li(tags$strong("Transport"), " row - follows every location except the last"),
          tags$li(tags$strong("Summary"), " row - one per day, at the end")
        ),
        p(tags$em("recommended_time and observations are reused across all three row types - see Generate Schedule for details.")),

        hr(),
        p("Part of the Business Operations Suite: Day Planner + Events Scheduling + Funding Programmes",
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}
