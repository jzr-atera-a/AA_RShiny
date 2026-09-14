# modules/Six Sigma Analysis/generate_sixsigma/ui.R

generate_sixsigma_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Generate a Six Sigma Diagram",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        div(class = "alert alert-info",
            tags$strong("How this works:"), " Claude never places elements on the canvas or does the maths - it ",
            "only fills in labels, causes, and raw values. Cumulative percentages, control limits, RPN scores, ",
            "and Pugh totals are always calculated by the app itself, never trusted to the AI."),

        p(style = "color: #7f8c8d; font-size: 12px;",
          tags$strong("Category"), " = broad life domain. ", tags$strong("Domain"), " = subject area. ",
          tags$strong("Topic"), " = the specific subject. ", tags$strong("Diagram Group"), " = which DMAIC ",
          "phase this tool belongs to. ", tags$strong("Diagram Type"), " = the specific Six Sigma tool."),

        category_domain_topic_dropdown_ui(ns),

        fluidRow(
          column(6, sixsigma_group_dropdown_ui(ns)),
          column(6, sixsigma_type_dropdown_ui(ns))
        ),
        textInput(ns("title_hint"), "Diagram Title (optional):",
                 placeholder = "Leave blank to let Claude choose one"),
        textAreaInput(ns("user_request"), "Describe the process/problem this diagram should cover: *", height = "120px",
                      placeholder = "e.g. Investigate why our cereal boxes have inconsistent fill weight"),

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
