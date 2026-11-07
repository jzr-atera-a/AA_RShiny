# modules/about/ui.R

about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "About Events Scheduling DB",
        status = "info", solidHeader = TRUE, width = 12,

        h3("Events Scheduling DB v1.1"),
        p("An AI-powered city events database — scan, store, and visualise events worldwide using Claude AI and Google BigQuery."),

        hr(),

        h4("How It Works:"),
        tags$ol(
          tags$li(tags$strong("BigQuery Setup:"),
                  " Connect to your Google Cloud project (default: atera-2) and configure the events table."),
          tags$li(tags$strong("Claude API Config:"),
                  " Enter your Anthropic API key to enable AI scanning."),
          tags$li(tags$strong("Scan Events:"),
                  " Enter an optional city, date range, category filter, Top-N count, and any extra context. ",
                  "Claude generates a structured event list. City is optional — leave blank to get the top N most notable events globally or by country."),
          tags$li(tags$strong("Bulk Import:"),
                  " Paste event text (from Scan Events or manually written) to parse and upload."),
          tags$li(tags$strong("Add Single Event:"),
                  " Manually add individual events with the full form including the extra_info field."),
          tags$li(tags$strong("Browse Events:"),
                  " Search and filter your event database by city and category, then download as CSV."),
          tags$li(tags$strong("Visualizations:"),
                  " Explore events on an interactive Leaflet map, month-view calendar, or timeline/category charts.")
        ),

        hr(),

        h4("Category / Subcategory System"),
        p("Works exactly like the Genre / Topic system in the Books app:"),
        tags$ul(
          tags$li("Category is the top-level classification (e.g. Music, Tech, Art, Food, Sports)"),
          tags$li("Subcategory is the sub-level (e.g. Jazz, AI Conference, Street Food, Marathon)"),
          tags$li("Both dropdowns are populated live from your BigQuery data"),
          tags$li("Select \"+ Add New Category\" or \"+ Add New Subcategory\" to create new values on the fly"),
          tags$li("The cascade refreshes automatically after every upload via state_trigger()")
        ),

        hr(),

        h4("Top-N Smart Scan"),
        p("The scan form includes a ", tags$strong("Number of Events (Top N)"), " dropdown (5–30, default 10):"),
        tags$ul(
          tags$li("When ", tags$strong("city is specified"), " and the date range is narrow, Claude returns events in that city for that period"),
          tags$li("When ", tags$strong("city is blank"), ", Claude returns the top N most notable events globally or in the specified country"),
          tags$li("When the ", tags$strong("date range is broad"), " (>90 days), Claude prioritises the most significant events rather than listing everything")
        ),

        hr(),

        h4("BigQuery Table Schema — atera-2.business_strategy.city_events"),
        tags$pre(style = "background:#f8f9fa; padding:12px; border-radius:8px; font-size:0.83em;",
          "Column         Type       Notes\n",
          "─────────────────────────────────────────────────────────────────────\n",
          "id             INTEGER    Auto-incremented row ID (client-computed)\n",
          "created_at     TIMESTAMP  Insert timestamp\n",
          "event_name     STRING     Full name of the event\n",
          "organiser      STRING     Promoter / organiser name\n",
          "city           STRING     City — blank for global/country-level events\n",
          "country        STRING     Country\n",
          "category       STRING     Top-level: Music, Tech, Art, Food, Sports, ...\n",
          "subcategory    STRING     Sub-level: Jazz, AI Conference, Street Food, ...\n",
          "event_date     STRING     ISO date YYYY-MM-DD (stored as STRING)\n",
          "event_time     STRING     HH:MM or 'All Day'\n",
          "venue_name     STRING     Venue name\n",
          "address        STRING     Full street address\n",
          "latitude       STRING     Decimal degrees or N/A\n",
          "longitude      STRING     Decimal degrees or N/A\n",
          "description    STRING     80-150 word event description\n",
          "ticket_url     STRING     Ticket purchase URL or N/A\n",
          "price_range    STRING     e.g. Free, £10-£25, $20, N/A\n",
          "source_url     STRING     Source website or N/A\n",
          "scan_date      STRING     Date this record was scanned\n",
          "extra_info     STRING     Accessibility, age restrictions, dress code, etc."
        ),

        hr(),

        h4("Architecture:"),
        tags$ul(
          tags$li("Modular R Shiny + shinydashboard with R6 ModuleLoader and APIManager"),
          tags$li("Enable/disable modules via modules/_module_registry.yml"),
          tags$li("Cross-module broadcast via api_manager$state_trigger()"),
          tags$li("Cross-module text handoff via api_manager$pending_bulk_text()"),
          tags$li("Category → Subcategory cascade from live BigQuery data (mirrors Genre → Topic)")
        ),

        hr(),

        p("Events Scheduling DB v1.1 — Built on the Modular R Shiny + BigQuery + LLM Blueprint",
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}
