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
        h4("Row Structure"),
        tags$ul(
          tags$li(tags$strong("Location"), " row - one per place visited"),
          tags$li(tags$strong("Transport"), " row - follows every location except the last"),
          tags$li(tags$strong("Summary"), " row - one per day, at the end")
        ),
        p(tags$em("recommended_time and observations are reused across all three row types - see Generate Schedule for details.")),

        hr(),
        h4("📅 Calendar Export (All Modules)"),
        div(style = "background: #f0f7ff; border-left: 4px solid #2196F3; padding: 20px; border-radius: 4px; margin: 15px 0;",
          h5(style = "color: #1976D2; margin-top: 0;", "How to Import Calendar Files"),
          
          h5(style = "color: #1565C0;", "For Outlook (Windows/Web/Mobile):"),
          tags$ol(
            tags$li("Download the .ics file"),
            tags$li(tags$strong("Windows Outlook:"), " File → Open & Export → Import a file → Select the .ics file → Choose calendar → Import"),
            tags$li(tags$strong("Outlook Web:"), " Settings → Import calendar → Select the .ics file → Import"),
            tags$li(tags$strong("Outlook Mobile:"), " Double-tap the .ics file → Select calendar → Import")
          ),
          
          h5(style = "color: #1565C0;", "For Android Calendar:"),
          tags$ol(
            tags$li("Download the .ics file to your device"),
            tags$li("Open file manager and find the file"),
            tags$li("Tap the .ics file → Select Calendar app"),
            tags$li("Choose which calendar to import to"),
            tags$li("Tap Import/Add"),
            tags$li(tags$strong("Alternative:"), " Open Google Calendar app → + button → Import events → Select file → Import")
          ),
          
          div(style = "margin-top: 15px; padding: 10px; background: #fff3cd; border-left: 3px solid #ffc107; border-radius: 3px;",
            tags$strong("💡 Tip:"), " Events will appear on their scheduled dates in your calendar. Set reminders within your calendar app as needed."
          )
        ),

        hr(),
        p("Part of the Business Operations Suite: Day Planner + Events Scheduling + Funding Programmes",
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}
