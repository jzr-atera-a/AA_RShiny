# modules/bulk_import_events/ui.R

bulk_import_events_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Bulk Import Events to BigQuery",
        status = "primary", solidHeader = TRUE, width = 12,

        h4("Paste or Receive Events Text"),
        p("Paste a structured events block (from Scan Events or manually written) to parse and upload."),

        div(class = "alert alert-info",
            tags$strong("Expected Format:"),
            tags$ul(
              tags$li("Header: [city]: ... (blank = global), [country]: ..., [scan_date]: ..."),
              tags$li("[event_name], [organiser], [category], [subcategory]"),
              tags$li("[event_date] (YYYY-MM-DD), [event_time], [venue_name], [address]"),
              tags$li("[latitude], [longitude], [description]"),
              tags$li("[ticket_url], [price_range], [source_url]"),
              tags$li("[extra_info] — additional notes, accessibility, requirements (or N/A)")
            )
        ),

        textAreaInput(ns("events_text"), "Paste Events Text Here:", height = "500px",
                      placeholder = paste0(
                        "[city]: London\n[country]: United Kingdom\n[scan_date]: 2026-07-01\n\n",
                        "[event_name]: ...\n[organiser]: ...\n[category]: Music\n",
                        "[subcategory]: Jazz\n[event_date]: 2026-07-15\n[event_time]: 19:30\n",
                        "[venue_name]: ...\n[address]: ...\n[latitude]: 51.5\n[longitude]: -0.1\n",
                        "[description]: ...\n[ticket_url]: N/A\n[price_range]: Free\n",
                        "[source_url]: N/A\n[extra_info]: N/A"
                      )),

        fluidRow(
          column(4, actionButton(ns("parse"),  "Parse Events",      class = "btn-info btn-lg",
                                 icon = icon("cogs"),               style = "width: 100%;")),
          column(4, actionButton(ns("upload"), "Upload to BigQuery", class = "btn-success btn-lg",
                                 icon = icon("cloud-upload-alt"),   style = "width: 100%;")),
          column(4, actionButton(ns("clear"),  "Clear All",          class = "btn-danger",
                                 icon = icon("trash"),              style = "width: 100%;"))
        ),

        br(),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Parsed Data Preview", status = "info", solidHeader = TRUE, width = 12,
        htmlOutput(ns("parse_info")),
        br(),
        div(class = "preview-section", DT::dataTableOutput(ns("preview_table")))
      )
    )
  )
}
