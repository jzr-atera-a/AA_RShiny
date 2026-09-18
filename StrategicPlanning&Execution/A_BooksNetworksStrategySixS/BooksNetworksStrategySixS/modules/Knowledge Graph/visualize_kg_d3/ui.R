# modules/visualize_kg_d3/ui.R

visualize_kg_d3_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Select Knowledge Graph to View",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        fluidRow(
          column(3, selectInput(ns("viz_category"), "Category: *", choices = NULL)),
          column(3, selectInput(ns("viz_domain"), "Domain: *", choices = NULL)),
          column(3, selectInput(ns("viz_topic"), "Topic: *", choices = NULL)),
          column(3, selectInput(ns("viz_graph_id"), "Graph Version: *", choices = NULL))
        ),

        fluidRow(
          column(6,
                 checkboxInput(ns("show_predicate_labels"), "Show relationship (predicate) labels on edges", value = TRUE)
          ),
          column(6,
                 actionButton(ns("load_graph"), "Load Graph", class = "btn-success btn-lg",
                             icon = icon("circle-nodes"), style = "width: 100%;")
          )
        ),

        hr(),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Knowledge Graph (D3 force-directed)",
        status = "success",
        solidHeader = TRUE,
        width = 8,
        collapsible = TRUE,

        p(style = "color: #7f8c8d; font-size: 12px;",
          "Click a node to see its full description on the right. Drag a node to reposition it, drag the ",
          "background to pan, scroll/pinch to zoom. Node color = entity type, node size = number of ",
          "connections."),

        export_controls_ui(ns, ns("export_target"), "knowledge_graph_d3"),
        uiOutput(ns("network"))
      ),
      box(
        title = "Selected Entity",
        status = "info",
        solidHeader = TRUE,
        width = 4,
        collapsible = TRUE,

        htmlOutput(ns("node_detail"))
      )
    )
  )
}
