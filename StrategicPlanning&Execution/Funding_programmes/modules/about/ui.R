# modules/about/ui.R

about_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "About This Application",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        
        h3("Funding Programmes Suite v1.0"),
        p("An integrated platform combining AI-assisted discovery of grants, incubators, accelerators, ",
          "and competitions with cloud database storage and filterable visualization."),
        
        hr(),
        
        h4("Features:"),
        tags$ul(
          tags$li(tags$strong("AI Programme Discovery:"), " Claude searches its training knowledge for relevant funding programmes"),
          tags$li(tags$strong("BigQuery Integration:"), " Cloud database storage (atera-2.business_strategy.funding_programmes)"),
          tags$li(tags$strong("One Row per Programme:"), " Each grant/incubator/accelerator/competition is a single, complete record"),
          tags$li(tags$strong("Category & Location Cascades:"), " Add new categories/countries/regions on the fly"),
          tags$li(tags$strong("Filterable Visualizations:"), " Filter by Country, City/Region, and date ranges on Start Date / Deadline")
        ),
        
        hr(),
        
        h4("Data Schema (BigQuery):"),
        p("Table: atera-2.business_strategy.funding_programmes"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - category (STRING)\n  - country (STRING)\n  - city_region (STRING, default \"All\")\n  - programme_name (STRING)\n  - amount_of_money (STRING)\n  - conditions (STRING)\n  - key_sponsors (STRING)\n  - key_organiser_profiles (STRING)\n  - areas_of_application (STRING)\n  - start_date_for_applying (STRING, YYYY-MM-DD when known)\n  - deadline (STRING, YYYY-MM-DD when known)\n  - recommendations_for_applying (STRING)\n  - verified_urls (STRING, comma-separated)"),
        
        hr(),
        
        h4("Important Accuracy Note:"),
        div(class = "alert alert-warning",
            "Claude generates programme details from its training data, which can be outdated or ",
            "incomplete. Always verify amounts, dates, and URLs against the official programme website ",
            "before relying on them for a real application."),
        
        hr(),
        
        h4("Modular Architecture:"),
        p("This application uses a modern modular architecture where each feature is a self-contained module."),
        tags$ul(
          tags$li("Enable/disable modules by editing modules/_module_registry.yml"),
          tags$li("Each module has its own UI, server, manifest, and README"),
          tags$li("Reactive state sharing via api_manager$state_trigger()")
        ),
        
        hr(),
        
        p("Version 1.0.0 - Modular Architecture | One-Row-Per-Programme Schema", 
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}
