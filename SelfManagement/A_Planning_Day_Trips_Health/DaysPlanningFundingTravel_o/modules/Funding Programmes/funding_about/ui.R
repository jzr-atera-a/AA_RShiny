# modules/Funding Programmes/funding_about/ui.R

funding_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Funding Programmes", status = "info", solidHeader = TRUE, width = 12,

        h3("Funding Programmes"),
        p("AI-assisted discovery of grants, incubators, accelerators, and competitions, part of the Business Operations Suite."),

        hr(),
        h4("Table: atera-2.business_strategy.funding_programmes"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - category (STRING)\n  - country (STRING)\n  - city_region (STRING, default \"All\")\n  - programme_name (STRING)\n  - amount_of_money (STRING)\n  - conditions (STRING)\n  - key_sponsors (STRING)\n  - key_organiser_profiles (STRING)\n  - areas_of_application (STRING)\n  - start_date_for_applying (STRING, YYYY-MM-DD when known)\n  - deadline (STRING, YYYY-MM-DD when known)\n  - recommendations_for_applying (STRING)\n  - verified_urls (STRING, comma-separated)"),

        hr(),
        h4("Important Accuracy Note"),
        div(class = "alert alert-warning",
            "Claude generates programme details from its training data, which can be outdated or ",
            "incomplete. Always verify amounts, dates, and URLs against the official programme website ",
            "before relying on them for a real application."),

        hr(),
        p("Part of the Business Operations Suite: Day Planner + Events Scheduling + Funding Programmes",
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}
