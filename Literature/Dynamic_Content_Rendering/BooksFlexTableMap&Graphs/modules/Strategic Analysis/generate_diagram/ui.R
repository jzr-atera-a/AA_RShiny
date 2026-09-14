# modules/Strategic Analysis/generate_diagram/ui.R

generate_diagram_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Generate a Strategy Diagram",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        div(class = "alert alert-info",
            tags$strong("How this works:"), " Claude never places elements on the canvas directly - it only ",
            "fills in labels, bullets, and structural slots (which grid cell, which quadrant, which position ",
            "in a sequence). The renderer computes actual layout, so nothing overlaps."),

        p(style = "color: #7f8c8d; font-size: 12px;",
          tags$strong("Category"), " = broad life domain (e.g. Business, Personal Life, Health). ",
          tags$strong("Domain"), " = analysis/framework family (e.g. Situational Analysis, Decision-Making Process). ",
          tags$strong("Topic"), " = the specific subject. Pick these first, then the Diagram Type."),

        category_domain_topic_dropdown_ui(ns),
        fluidRow(
          column(6, diagram_type_dropdown_ui(ns)),
          column(6, textInput(ns("title_hint"), "Diagram Title (optional):",
                              placeholder = "Leave blank to let Claude choose one"))
        ),
        textAreaInput(ns("user_request"), "Describe what you want the diagram to cover: *", height = "120px",
                      placeholder = "e.g. Build a SWOT for whether we should acquire Competitor X"),

        hr(),

        fluidRow(
          column(3, actionButton(ns("generate"), "Generate Diagram", icon = icon("magic"),
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
        title = "Generated Component Rows",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Generating... This may take 20-60 seconds.")),

        h5("Review & Edit (re-parse after any manual fix):"),
        textAreaInput(ns("diagram_text_edit"), NULL, height = "350px",
                      placeholder = "Generated component rows will appear here - editable before upload."),
        actionButton(ns("reparse"), "Re-Parse & Update Preview", icon = icon("sync"), class = "btn-default"),

        br(), br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}
