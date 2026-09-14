# modules/Strategic Analysis/diagram_add_single/ui.R

diagram_add_single_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Add a Single Diagram Component",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Add one component to a NEW diagram, or an EXISTING diagram_id (paste it below to append to it)."),

        fluidRow(
          column(4, textInput(ns("diagram_id_existing"), "Existing Diagram ID (optional - leave blank to start a new diagram):")),
          column(4, diagram_type_dropdown_ui(ns)),
          column(4, textInput(ns("title"), "Diagram Title: *"))
        ),
        diagram_category_topic_dropdown_ui(ns),

        hr(),
        h4("Component Fields"),
        fluidRow(
          column(4, selectInput(ns("component_type"), "Component Type:",
                                choices = c("shape_rectangle", "shape_circle", "shape_ellipse", "axis", "axis_label",
                                            "text_label", "title", "bullet_list_item", "region_quadrant",
                                            "data_point", "table_cell"))),
          column(4, selectInput(ns("layout_role"), "Layout Role:",
                                choices = c("grid_cell", "quadrant_region", "axis", "list_item", "node", "title", "annotation"))),
          column(4, selectInput(ns("quadrant_position"), "Quadrant Position (if applicable):",
                                choices = c("N/A", "top_left", "top_right", "bottom_left", "bottom_right")))
        ),
        fluidRow(
          column(4, numericInput(ns("grid_row"), "Grid Row:", value = 1, min = 1)),
          column(4, numericInput(ns("grid_col"), "Grid Col:", value = 1, min = 1)),
          column(4, numericInput(ns("sequence_order"), "Sequence Order:", value = 1, min = 0))
        ),
        textInput(ns("label_text"), "Label Text: *"),
        textInput(ns("sub_text"), "Sub Text (optional):"),
        textAreaInput(ns("items_raw"), "Items (one per line - will be packed with the delimiter automatically):",
                      height = "100px"),
        fluidRow(
          column(6, textInput(ns("color_hint"), "Color Hint (optional):", placeholder = "e.g. accent_blue")),
          column(6, textInput(ns("icon_name"), "Icon Name (optional):"))
        ),

        actionButton(ns("add_component"), "Add Component to BigQuery", icon = icon("plus"),
                    class = "btn-success btn-lg", style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}
