# modules/scan_events/ui.R

scan_events_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "City Event Scanner", status = "primary", solidHeader = TRUE, width = 12,

        h4("Scan Events Using Claude AI"),
        p("Enter a location and date range — Claude will generate a structured list of events. ",
          "City is optional: leave blank to get the top N most notable events globally or by country."),

        # ── Row 1: Location + Dates + Top-N ─────────────────
        fluidRow(
          column(4,
                 textInput(ns("city"),    "City (optional):",
                           placeholder = "e.g., London — leave blank for country/global scan"),
                 textInput(ns("country"), "Country (optional):",
                           placeholder = "e.g., United Kingdom")
          ),
          column(4,
                 dateInput(ns("date_from"), "From Date:",
                           value = Sys.Date(), format = "yyyy-mm-dd"),
                 dateInput(ns("date_to"),   "To Date:",
                           value = Sys.Date() + 30, format = "yyyy-mm-dd")
          ),
          column(4,
                 selectInput(ns("top_n"), "Number of Events (Top N):",
                             choices  = setNames(seq(5, 30, by = 5),
                                                 paste(seq(5, 30, by = 5), "events")),
                             selected = 10),
                 div(class = "alert alert-info", style = "margin-top: 6px; font-size: 0.85em;",
                     icon("info-circle"), " ",
                     "When city is blank or date range is broad, Claude returns the ",
                     tags$strong("top N most relevant"), " events.")
          )
        ),

        hr(),

        # ── Row 2: Category cascade + Extra info ─────────────
        fluidRow(
          column(6,
                 h5("Category Filter"),
                 p(class = "text-muted", style = "margin-top:-8px; font-size:0.88em;",
                   "Select existing values from your database, or type a new one."),
                 category_dropdown_ui(ns)
          ),
          column(6,
                 h5("Additional Context (optional)"),
                 p(class = "text-muted", style = "margin-top:-8px; font-size:0.88em;",
                   "Sent verbatim to Claude — e.g. \"outdoor only\", \"free events\", \"family-friendly\"."),
                 textAreaInput(ns("extra_info"), label = NULL, rows = 3,
                               placeholder = "e.g., Focus on free outdoor events suitable for families.")
          )
        ),

        hr(),

        # ── Row 3: Optional fields radio ─────────────────────
        fluidRow(
          column(12,
                 h5("Optional Fields to Include"),
                 p(class = "text-muted", style = "font-size:0.88em;",
                   "Controls which optional fields Claude is asked to populate. ",
                   "Fewer fields = faster response. ",
                   tags$strong("Core only"), " is recommended for reliable results."),
                 radioButtons(
                   ns("optional_fields"),
                   label = NULL,
                   choices = list(
                     "Core only — event_name, organiser, category, subcategory, event_date, event_time, venue_name, address, description, price_range, source_url" = "core",
                     "Core + Location — also include latitude & longitude"                                         = "core_geo",
                     "Core + Tickets — also include ticket_url & extra_info"                                       = "core_tickets",
                     "Full — all fields including latitude, longitude, ticket_url & extra_info"                    = "full"
                   ),
                   selected = "core",
                   inline = FALSE
                 )
          )
        ),

        hr(),

        # ── Action buttons ────────────────────────────────────
        fluidRow(
          column(3,
                 actionButton(ns("scan"), "Scan Events", icon = icon("search"),
                              class = "btn-primary btn-lg", style = "width: 100%;")
          ),
          column(3,
                 actionButton(ns("copy_to_bulk"), "Copy to Bulk Import", icon = icon("arrow-right"),
                              class = "btn-info btn-lg", style = "width: 100%;")
          ),
          column(3,
                 actionButton(ns("parse_and_upload"), "Parse & Upload Direct",
                              icon = icon("cloud-upload-alt"),
                              class = "btn-success btn-lg", style = "width: 100%;")
          ),
          column(3,
                 downloadButton(ns("download"), "Download Text",
                                class = "btn-warning", style = "width: 100%;")
          )
        )
      )
    ),

    # ── Output panel ─────────────────────────────────────────
    fluidRow(
      box(
        title = "Generated Events", status = "success", solidHeader = TRUE, width = 12,

        div(id = ns("loading_spinner"),
            style = "display: none; text-align: center; padding: 30px;",
            tags$i(class = "fa fa-spinner fa-spin fa-3x"),
            h4("Scanning for events... check the R console for live progress.")),

        verbatimTextOutput(ns("scan_text")),
        htmlOutput(ns("status"))
      )
    )
  )
}
