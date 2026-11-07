# modules/edit_mindmap/ui.R

edit_mindmap_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Select Mind Map to Edit",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Pick the exact map to edit. If a Topic has more than one generated map, choose which ",
          "version - the most recent is selected by default."),

        fluidRow(
          column(3, selectInput(ns("edit_category"), "Category: *", choices = NULL)),
          column(3, selectInput(ns("edit_domain"), "Domain: *", choices = NULL)),
          column(3, selectInput(ns("edit_topic"), "Topic: *", choices = NULL)),
          column(3, selectInput(ns("edit_map_id"), "Map Version: *", choices = NULL))
        ),

        actionButton(ns("load_tree"), "Load Current Tree", class = "btn-info btn-lg",
                    icon = icon("download"), style = "width: 100%;"),

        hr(),
        htmlOutput(ns("load_status")),
        htmlOutput(ns("current_tree_outline"))
      )
    ),

    fluidRow(
      box(
        title = "Request an Edit",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        p("Describe what should change. Claude will return ONLY the delta (new/changed/removed ",
          "nodes) - the app automatically cascades any DELETE to that node's descendants, so you ",
          "don't need to list them individually."),

        textAreaInput(ns("edit_request"), "Edit Request: *", rows = 4, width = "100%",
                      placeholder = "e.g., Add 2 more sub-points under N3 about its regulatory role. Delete N7 and everything under it. Reword N2 to be more concise."),

        fluidRow(
          column(4,
                 numericInput(ns("expected_changes"), "Expected Number of Changed/New Nodes (approx.):",
                              value = 5, min = 1, max = 40, step = 1)
          ),
          column(4,
                 radioButtons(ns("include_latex"), "Include LaTeX in new/changed content?",
                              choices = c("No (plain text only)" = "no", "Yes" = "yes"), selected = "no")
          ),
          column(4,
                 sliderInput(ns("words_per_node"), "Max Words per Node:",
                            min = 20, max = 200, value = 40, step = 20)
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
