# modules/Strategic Analysis/diagram_about/ui.R

diagram_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Strategic Analysis", status = "primary", solidHeader = TRUE, width = 12,
          h4("What this suite does"),
          p("Generates strategy diagrams (SWOT, PESTEL, Five Forces, quadrant charts, timelines, etc.) via the ",
            "Claude API, stored as structured rows in one BigQuery table (in the same project/dataset as ",
            "Book Summary, Flex Table, Mind Map, and Knowledge Graph), and rendered with a small set of ",
            "generic, type-aware renderers - never a hand-written renderer per framework."),

          h4("Table: strategy_diagrams"),
          p("One row = one visual component (a grid cell, a quadrant, an axis, a chart series). Denormalized: ",
            "diagram_name/diagram_type/diagram_group/category/topic/title are repeated on every row belonging to the same ",
            "diagram_id, so a full diagram is one WHERE diagram_id = ... query, no joins."),
          tags$table(class = "table table-striped",
            tags$thead(tags$tr(tags$th("Column"), tags$th("Purpose"))),
            tags$tbody(
              tags$tr(tags$td("diagram_id"), tags$td("Slug + timestamp id shared by every component row of one diagram")),
              tags$tr(tags$td("diagram_name / diagram_type / diagram_group"), tags$td("Human label + one of the ~27 named framework ids (e.g. \"swot\", \"bcg_matrix\") + which of the 7 strategic-lens groups it belongs to")),
              tags$tr(tags$td("category / topic / title"), tags$td("Indexing/search fields, denormalized per row")),
              tags$tr(tags$td("is_template / source_diagram_id"), tags$td("TRUE = reusable reference framework; generated instances point back to the template they were based on")),
              tags$tr(tags$td("component_type / layout_role"), tags$td("What kind of element this row is, and how the renderer should treat it")),
              tags$tr(tags$td("grid_row / grid_col / quadrant_position / sequence_order"), tags$td("CATEGORICAL layout slots Claude fills in - never raw coordinates")),
              tags$tr(tags$td("pos_x / pos_y / width / height"), tags$td("Optional MANUAL OVERRIDE layer for a human hand-editing a saved diagram - never populated by Claude on first generation")),
              tags$tr(tags$td("label_text / sub_text"), tags$td("Primary and secondary text content")),
              tags$tr(tags$td("items_packed"), tags$td("Multiple bullets/items in ONE row, joined by the delimiter below")),
              tags$tr(tags$td("value_numeric / value_axis / series_name / unit_label"), tags$td("Chart-family fields (line/bar/funnel/dual-axis)")),
              tags$tr(tags$td("color_hint / icon_name"), tags$td("Semantic style hints, not literal hex/pixel values"))
            )
          ),

          h4("The delimiter convention"),
          p("Multi-item content within one component (e.g. a SWOT cell's bullets) is packed into ", tags$code("items_packed"),
            " using the literal token ", tags$code(DIAG_ITEM_SEP), " - the same DELIMITER CONTRACT pattern as Flex ",
            "Table's ", tags$code("COL_SEP"), "/", tags$code("KV_SEP"), " and Mind Map's ", tags$code("CROSS_LINK_SEP"),
            " elsewhere in this app. Every diagram-type prompt block explicitly instructs Claude to never use this ",
            "sequence inside real content, so splitting on it is always safe."),

          h4("Why Claude never sets pixel positions"),
          p("LLMs are unreliable at spatial arithmetic - that's the actual source of overlapping/disorganized ",
            "diagrams, not the choice of renderer. So Claude only ever supplies categorical layout slots ",
            "(which grid cell, which quadrant, which position in a sequence), and the renderer computes real ",
            "geometry deterministically:"),
          tags$ul(
            tags$li(tags$strong("grid, quadrant, table, stacked_list, linear_flow"), " -> HTML/CSS Grid & Flexbox (the browser layout engine guarantees no overlap)"),
            tags$li(tags$strong("radial, network"), " -> server-computed SVG (R computes evenly-spaced angles/node positions with trigonometry)"),
            tags$li(tags$strong("line_chart, bar_chart, funnel, dual_axis_timeseries"), " -> plotly (real numeric axes, native auto-scaling, same library as Book Summary's Visualizations tab)")
          ),

          h4("BigQuery & Claude API setup"),
          p("This suite shares the single BigQuery connection and single Claude API connection configured in ",
            "API Configuration - no separate credentials needed. Connecting to BigQuery there automatically ",
            "creates the ", tags$code("strategy_diagrams"), " table (CREATE TABLE IF NOT EXISTS, alongside the ",
            "other four suites' tables) in the same project/dataset."),

          h4("Debugging"),
          p("Every generation (Generate Diagram tab) and every render (Visualizations tab) prints detailed ",
            "diagnostic output to the R console: prompt parameters and timing on generation; row counts, ",
            "component-type breakdown, and render timing on visualization.")
      )
    )
  )
}
