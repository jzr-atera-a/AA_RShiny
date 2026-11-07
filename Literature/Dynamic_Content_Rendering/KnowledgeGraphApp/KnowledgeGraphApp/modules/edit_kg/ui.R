# modules/edit_kg/ui.R

edit_kg_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Select Knowledge Graph to Edit",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Pick the exact graph to edit. If a Topic has more than one generated graph, choose which ",
          "version - the most recent is selected by default."),

        fluidRow(
          column(3, selectInput(ns("edit_category"), "Category: *", choices = NULL)),
          column(3, selectInput(ns("edit_domain"), "Domain: *", choices = NULL)),
          column(3, selectInput(ns("edit_topic"), "Topic: *", choices = NULL)),
          column(3, selectInput(ns("edit_graph_id"), "Graph Version: *", choices = NULL))
        ),

        actionButton(ns("load_graph"), "Load Current Graph", class = "btn-info btn-lg",
                    icon = icon("download"), style = "width: 100%;"),

        hr(),
        htmlOutput(ns("load_status")),
        htmlOutput(ns("current_graph_outline"))
      )
    ),

    fluidRow(
      box(
        title = "Request an Edit",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        p("Describe what should change. Claude will return ONLY the delta (new/changed/removed entities ",
          "or relationships) - the app automatically cascades any entity DELETE to every relationship ",
          "that touches it, so you don't need to list those individually."),

        textAreaInput(ns("edit_request"), "Edit Request: *", rows = 4, width = "100%",
                      placeholder = "e.g., Add 2 more entities for related discoveries under E3. Delete E7 and all its relationships. Reword E2's description to be more concise. Add a relationship between E4 and E9."),

        fluidRow(
          column(4,
                 numericInput(ns("expected_changes"), "Expected Number of Changed/New Items (approx.):",
                              value = 5, min = 1, max = 40, step = 1)
          ),
          column(4,
                 radioButtons(ns("include_latex"), "Include LaTeX in new/changed content?",
                              choices = c("No (plain text only)" = "no", "Yes" = "yes"), selected = "no")
          ),
          column(4,
                 sliderInput(ns("words_per_item"), "Max Words per Description:",
                            min = 20, max = 200, value = 30, step = 10)
          )
        ),

        actionButton(ns("request_edit"), "Request Edit from Claude", class = "btn-primary btn-lg",
                    icon = icon("magic"), style = "width: 100%;"),

        hr(),
        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Requesting edit from Claude...")),
        htmlOutput(ns("edit_status")),
        verbatimTextOutput(ns("raw_delta_text"))
      )
    ),

    fluidRow(
      box(
        title = "Preview Changes",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        htmlOutput(ns("delta_preview")),
        br(),
        actionButton(ns("apply_changes"), "Apply Changes to BigQuery", class = "btn-success btn-lg",
                    icon = icon("cloud-upload-alt"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("apply_status"))
      )
    )
  )
}
