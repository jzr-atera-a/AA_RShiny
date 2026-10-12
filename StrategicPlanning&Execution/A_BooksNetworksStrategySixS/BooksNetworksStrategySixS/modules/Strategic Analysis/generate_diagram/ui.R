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
            tags$strong("How this works:"), " The Editing Tool never places elements on the canvas directly - it only ",
            "fills in labels, bullets, and structural slots (which grid cell, which quadrant, which position ",
            "in a sequence). The renderer computes actual layout, so nothing overlaps."),

        p(style = "color: #7f8c8d; font-size: 12px;",
          tags$strong("Category"), " = broad life domain (e.g. Business, Personal Life, Health). ",
          tags$strong("Domain"), " = subject area (e.g. Manufacturing Quality, Tech Startups). ",
          tags$strong("Topic"), " = the specific subject. ",
          tags$strong("Diagram Group"), " = the strategic lens (e.g. Competitive Positioning). ",
          tags$strong("Framework"), " = the specific named diagram (e.g. BCG Matrix). Not sure which ",
          "Framework fits? Check the Tool Guide tab first."),

        category_domain_topic_dropdown_ui(ns),
        fluidRow(
          column(6, diagram_group_dropdown_ui(ns)),
          column(6, diagram_type_dropdown_ui(ns))
        ),
        # Rules Table options - only shown when that framework is selected
        conditionalPanel(
          condition = sprintf("input['%s'] == 'rules_table'", ns("diagram_type_select")),
          div(class = "well",
              tags$strong("Rules Table options"),
              fluidRow(
                column(4, numericInput(ns("rules_count"), "Number of rules:", value = 6, min = 2, max = 15, step = 1)),
                column(4, textInput(ns("rules_outcome"), "Critical outcome wanted:",
                                    placeholder = "e.g., Both people want a second date")),
                column(4, textInput(ns("rules_reference"), "Book or online resource to follow (optional):",
                                    placeholder = "e.g., Never Split the Difference"))
              ))
        ),
        textInput(ns("title_hint"), "Diagram Title (optional):",
                 placeholder = "Leave blank to let the Editing Tool choose one"),
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
