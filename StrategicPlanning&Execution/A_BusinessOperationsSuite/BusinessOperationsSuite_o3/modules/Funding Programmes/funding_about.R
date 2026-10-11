# modules/Funding Programmes/funding_about.R
# Subtab: About (static schema documentation)

funding_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Funding Programmes", status = "info", solidHeader = TRUE, width = 12,
          h3("Funding Programmes"),
          p("AI-assisted discovery of grants, incubators, accelerators, and competitions, part of the Business Operations Suite."),
          hr(),
          h4("Table: <project>.<dataset>.funding_programmes (see API Settings > BigQuery Config for the active names)"),
          tags$pre(paste(
            "Fields:",
            "  - id (INTEGER)",
            "  - created_at (TIMESTAMP)",
            "  - category (STRING)",
            "  - country (STRING)",
            "  - city_region (STRING, default \"All\")",
            "  - programme_name (STRING)",
            "  - amount_of_money (STRING)",
            "  - conditions (STRING)",
            "  - key_sponsors (STRING)",
            "  - key_organiser_profiles (STRING)",
            "  - areas_of_application (STRING)",
            "  - start_date_for_applying (STRING, YYYY-MM-DD when known)",
            "  - deadline (STRING, YYYY-MM-DD when known)",
            "  - recommendations_for_applying (STRING)",
            "  - verified_urls (STRING, comma-separated)",
            sep = "\n"
          )),
          hr(),
          h4("Important Accuracy Note"),
          div(class = "alert alert-warning",
              "Claude generates programme details from its training data, which can be outdated or ",
              "incomplete. Always verify amounts, dates, and URLs against the official programme website ",
              "before relying on them for a real application."),
          hr(),
          p("Part of the Business Operations Suite: API Settings + Communications + Funding Programmes",
            style = "text-align: center; color: #999; font-size: 12px;"))
    )
  )
}

funding_about_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    # Static informational tab - no server logic needed
  })
}
