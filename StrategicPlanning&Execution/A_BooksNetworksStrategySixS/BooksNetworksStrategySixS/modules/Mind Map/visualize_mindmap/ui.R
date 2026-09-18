# modules/visualize_mindmap/ui.R

visualize_mindmap_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Select Mind Map to View",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        fluidRow(
          column(3, selectInput(ns("viz_category"), "Category: *", choices = NULL)),
          column(3, selectInput(ns("viz_domain"), "Domain: *", choices = NULL)),
          column(3, selectInput(ns("viz_topic"), "Topic: *", choices = NULL)),
          column(3, selectInput(ns("viz_map_id"), "Map Version: *", choices = NULL))
        ),

        fluidRow(
          column(6,
                 checkboxInput(ns("show_cross_links"), "Show cross-links (dashed orange edges)", value = TRUE)
          ),
          column(6,
                 actionButton(ns("load_map"), "Load Map", class = "btn-success btn-lg",
                             icon = icon("project-diagram"), style = "width: 100%;")
          )
        ),

        hr(),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Mind Map",
        status = "success",
        solidHeader = TRUE,
        width = 8,
        collapsible = TRUE,

        p(style = "color: #7f8c8d; font-size: 12px;",
          "Click a CIRCLE to collapse/expand that branch. Click a LABEL to see its full content on the ",
          "right. Scroll/pinch to zoom, drag the background to pan. Solid colored lines = primary ",
          "hierarchy (color = branch). Dashed orange lines = cross-links."),

        export_controls_ui(ns, ns("export_target"), "mind_map"),
        uiOutput(ns("network"))
      ),
      box(
        title = "Selected Node",
        status = "info",
        solidHeader = TRUE,
        width = 4,
        collapsible = TRUE,

        htmlOutput(ns("node_detail"))
      )
    )
  )
}
