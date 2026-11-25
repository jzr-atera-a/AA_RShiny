# modules/Strategic Analysis/diagram_about.R
# ---- module --------------------------------------------------------------------------------------
# id:           diagram_about
# name:         About Strategic Analysis
# label:        About
# icon:         info-circle
# description:  Schema documentation for strategy_diagrams and the delimiter convention
# packages:     shiny, shinydashboard
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

diagram_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Strategic Analysis", status = "primary", solidHeader = TRUE, width = 12,
          h4("What this suite does"),
          p("Generates strategy diagrams (SWOT, PESTEL, Five Forces, quadrant charts, timelines, etc.) via the ",
            "Editing Tool API, stored as structured rows in one BigQuery table (in the same project/dataset as ",
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
              tags$tr(tags$td("diagram_name / diagram_type / diagram_group"), tags$td("Human label + one of the 32 named framework ids (e.g. \"swot\", \"bcg_matrix\", \"decision_questions_wheel\") + which of the 8 strategic-lens groups it belongs to")),
              tags$tr(tags$td("category / topic / title"), tags$td("Indexing/search fields, denormalized per row")),
              tags$tr(tags$td("is_template / source_diagram_id"), tags$td("TRUE = reusable reference framework; generated instances point back to the template they were based on")),
              tags$tr(tags$td("component_type / layout_role"), tags$td("What kind of element this row is, and how the renderer should treat it")),
              tags$tr(tags$td("grid_row / grid_col / quadrant_position / sequence_order"), tags$td("CATEGORICAL layout slots the Editing Tool fills in - never raw coordinates")),
              tags$tr(tags$td("pos_x / pos_y / width / height"), tags$td("Optional MANUAL OVERRIDE layer for a human hand-editing a saved diagram - never populated by the Editing Tool on first generation")),
              tags$tr(tags$td("label_text / sub_text"), tags$td("Primary and secondary text content")),
              tags$tr(tags$td("items_packed"), tags$td("Multiple bullets/items in ONE row, joined by the delimiter below")),
              tags$tr(tags$td("value_numeric / value_axis / series_name / unit_label"), tags$td("Chart-family fields (line/bar/funnel/dual-axis)")),
              tags$tr(tags$td("color_hint / icon_name"), tags$td("Semantic style hints, not literal hex/pixel values")),
              tags$tr(tags$td("node_id / parent_id / branch_label"), tags$td("Decision trees only: the tree structure - each node names its parent and the label of the branch leading into it")),
              tags$tr(tags$td("probability / cash_flow"), tags$td("Decision trees only: the chance of a branch after a chance node, and the money paid (-) or received (+) when a branch is taken; end-node payoffs use value_numeric")),
              tags$tr(tags$td("Hard Decision Questions Wheel"), tags$td("component_type = wheel_slice (one per question: sequence_order 1-20, quadrant_position = its angle, label_text = the fixed question, sub_text = the answer, items_packed = next steps, color_hint = clear / partial / open); region_quadrant rows hold each angle's summary; one text_label row holds the verdict")),
              tags$tr(tags$td("expected_value"), tags$td("Decision trees only: the expected value at each node when saved (a snapshot - the app always recalculates on load); color_hint = 'best' marks the recommended plan"))
            )
          ),

          h4("The delimiter convention"),
          p("Multi-item content within one component (e.g. a SWOT cell's bullets) is packed into ", tags$code("items_packed"),
            " using the literal token ", tags$code(DIAG_ITEM_SEP), " - the same DELIMITER CONTRACT pattern as Flex ",
            "Table's ", tags$code("COL_SEP"), "/", tags$code("KV_SEP"), " and Mind Map's ", tags$code("CROSS_LINK_SEP"),
            " elsewhere in this app. Every diagram-type prompt block explicitly instructs the Editing Tool to never use this ",
            "sequence inside real content, so splitting on it is always safe."),

          h4("Why the Editing Tool never sets pixel positions"),
          p("LLMs are unreliable at spatial arithmetic - that's the actual source of overlapping/disorganized ",
            "diagrams, not the choice of renderer. So the Editing Tool only ever supplies categorical layout slots ",
            "(which grid cell, which quadrant, which position in a sequence), and the renderer computes real ",
            "geometry deterministically:"),
          tags$ul(
            tags$li(tags$strong("grid, quadrant, table, stacked_list, linear_flow"), " -> HTML/CSS Grid & Flexbox (the browser layout engine guarantees no overlap)"),
            tags$li(tags$strong("radial, network"), " -> server-computed SVG (R computes evenly-spaced angles/node positions with trigonometry)"),
            tags$li(tags$strong("line_chart, bar_chart, funnel, dual_axis_timeseries"), " -> plotly (real numeric axes, native auto-scaling, same library as Book Summary's Visualizations tab)"),
            tags$li(tags$strong("business_model_canvas, value_chain, rules_table"), " -> purpose-built HTML layouts for the 9-block canvases, Porter's value chain and the rules table"),
            tags$li(tags$strong("decision_tree"), " -> the decision tree solver and drawing (expected values, recommended plan, risk)"),
            tags$li(tags$strong("question_wheel"), " -> the Hard Decision Questions Wheel: server-computed SVG of 20 fixed question slices in 4 angles, with click-to-open pop-up boxes (www/js/question_wheel.js)")
          ),

          h4("BigQuery & Editing Tool API setup"),
          p("This suite shares the single BigQuery connection and single Editing Tool API connection configured in ",
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

# ==== Server =======================================================================================

diagram_about_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    # Static documentation module - no server logic needed.
  })
}
