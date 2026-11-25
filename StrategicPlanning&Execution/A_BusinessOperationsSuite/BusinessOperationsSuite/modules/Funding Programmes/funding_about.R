# modules/Funding Programmes/funding_about.R
# Updated from DaysPlanningFundingTravel (modules/Funding Programmes/funding_about/ui.R + server.R);
# time zones and the calendar engine brought over from it as well.

funding_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Funding Programmes", status = "info", solidHeader = TRUE, width = 12,

        h3("Funding Programmes"),
        p("AI-assisted discovery of grants, incubators, accelerators, and competitions, part of the Business Operations Suite."),

        hr(),
        h4("Table: <project>.<dataset>.funding_programmes (see API Settings > BigQuery Config for the active names)"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - category (STRING)\n  - country (STRING)\n  - city_region (STRING, default \"All\")\n  - programme_name (STRING)\n  - amount_of_money (STRING)\n  - conditions (STRING)\n  - key_sponsors (STRING)\n  - key_organiser_profiles (STRING)\n  - areas_of_application (STRING)\n  - start_date_for_applying (STRING, YYYY-MM-DD when known)\n  - deadline (STRING, YYYY-MM-DD when known)\n  - recommendations_for_applying (STRING)\n  - verified_urls (STRING, comma-separated)\n  - time_zone (STRING, e.g. Europe/London; added automatically to older tables)"),

        hr(),
        h4("Time zones and calendars"),
        tags$ul(
          tags$li("Find Programmes, Add Single Entry and Bulk Import have a time-zone dropdown (it starts on this computer's zone). ",
                  "Claude is told to write every date and time in it, and it is saved with each programme."),
          tags$li("Generated text starts with a [time_zone] line, so the zone survives editing and Copy to Bulk Import."),
          tags$li("Visualizations and Browse Data export deadlines (and application-open dates) as an .ics calendar file ",
                  "for Outlook, Google, Apple and Android calendars, in each programme's own zone, with reminders 7 days and ",
                  "1 day before (and 1 hour before deadlines that have a time). Programmes saved before time zones existed ",
                  "are read as America/Mexico_City, the rule shared with DaysPlanningFundingTravel.")),

        hr(),
        h4("Important Accuracy Note"),
        div(class = "alert alert-warning",
            "Claude generates programme details from its training data, which can be outdated or ",
            "incomplete. Always verify amounts, dates, and URLs against the official programme website ",
            "before relying on them for a real application."),

        hr(),
        p("Part of the Business Operations Suite",
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}

funding_about_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    # Static informational tab - no server logic needed
  })
}
