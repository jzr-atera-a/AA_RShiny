# modules/Sankey Graph/generate_sankey/ui.R

generate_sankey_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Generate a Sankey Flow Diagram",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        div(class = "alert alert-info",
            tags$strong("How this works:"), " Claude decides which nodes exist, which column each sits in, ",
            "and each link's flow value - it never places anything on the canvas directly, and links may skip ",
            "ahead past intermediate columns. The actual layout (node heights, link curve widths) is computed ",
            "by the d3-sankey library from those raw values at render time, not by Claude or by this app."),

        category_domain_topic_dropdown_ui(ns),

        fluidRow(
          column(6,
                 sliderInput(ns("num_columns"), "Number of Columns (left-to-right stages):",
                            min = 2, max = 12, value = 6, step = 1, width = "100%")
          ),
          column(6,
                 sliderInput(ns("num_initial_rows"), "Number of Initial Rows (starting streams in column 1):",
                            min = 2, max = 20, value = 8, step = 1, width = "100%")
          )
        ),
        p(style = "color: #7f8c8d; font-size: 12px; margin-top: -10px;",
          "Later columns can have a different number of nodes than this, as flows merge or split on their ",
          "way across the diagram."),

        textInput(ns("title_hint"), "Sankey Title (optional):",
                 placeholder = "Leave blank to let Claude choose one"),
        textAreaInput(ns("user_request"), "Describe the flow this Sankey should show: *", height = "120px",
                      placeholder = "e.g. Show electricity flow in the UK from generation sources (gas, wind, nuclear) through the grid to end users, including transmission losses"),

        hr(),

        fluidRow(
          column(3, actionButton(ns("generate"), "Generate Sankey", icon = icon("magic"),
                                 class = "btn-primary btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("copy_to_bulk"), "Copy to Bulk Import", icon = icon("arrow-right"),
                                 class = "btn-info btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("parse_and_upload"), "Parse & Upload Direct", icon = icon("cloud-upload-alt"),
                                 class = "btn-success btn-lg", style = "width: 100%;")),
          column(3, downloadButton(ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;"))
        )
      )
    ),

    fluidRow(
      box(
        title = "Generated Node/Link Rows",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Generating... This may take 20-60 seconds.")),

        h5("Review & Edit (re-parse after any manual fix):"),
        textAreaInput(ns("sankey_text_edit"), NULL, height = "350px",
                      placeholder = "Generated node/link rows will appear here - editable before upload."),
        actionButton(ns("reparse"), "Re-Parse & Update Preview", icon = icon("sync"), class = "btn-default"),

        br(), br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}
