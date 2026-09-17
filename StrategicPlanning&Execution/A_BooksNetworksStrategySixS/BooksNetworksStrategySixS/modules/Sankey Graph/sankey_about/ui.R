# modules/Sankey Graph/sankey_about/ui.R

sankey_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Sankey Graph", status = "primary", solidHeader = TRUE, width = 12,
          h4("What this suite does"),
          p("Generates professional Sankey flow diagrams via the Claude API - the kind used for energy flows, ",
            "budget breakdowns, customer funnels, or any quantity that redistributes across a sequence of ",
            "stages - stored as structured rows in its own BigQuery table (sankey_graphs, same project/dataset ",
            "as the other six suites), and rendered with D3's d3-sankey layout plugin."),

          h4("Data model: nodes and links, not a tree or a general graph"),
          p("Unlike Mind Map (a tree) or Knowledge Graph (an unconstrained graph), a Sankey is a "),
          tags$ul(
            tags$li(tags$strong("Node"), " (", tags$code("row_kind = \"node\""), "): a labeled box at a specific ",
                    tags$code("column_index"), " (its left-to-right stage) and ", tags$code("sequence_order"),
                    " (its vertical position within that column)."),
            tags$li(tags$strong("Link"), " (", tags$code("row_kind = \"link\""), "): a weighted flow from ",
                    tags$code("source_ref"), " to ", tags$code("target_ref"), ", carrying a raw ",
                    tags$code("value_numeric"), " magnitude. A link's target column must always be strictly ",
                    "later than its source column - but it may ", tags$strong("skip ahead"), " past intermediate ",
                    "columns entirely, exactly like a real energy source bypassing a conversion stage or a ",
                    "budget line going straight to \"Unallocated.\"")
          ),

          h4("Classification"),
          p("Category / Domain (labeled \"Sector\" on the Generate and Visualize tabs) / Topic use the exact ",
            "same shared 3-level cascade as Mind Map, Knowledge Graph, Strategic Analysis, and Six Sigma - ",
            "Category = broad life domain, Domain = subject area, Topic = specific subject. A Sankey is further ",
            "identified by its Title, since (unlike the other suites) there is only one Sankey \"type\" - the ",
            "structural variety comes from the columns/rows sliders and the flow described in the request, not ",
            "from a named framework catalog."),

          h4("The two sliders"),
          tags$ul(
            tags$li(tags$strong("Number of Columns (2-12, default 6):"), " the left-to-right depth of the diagram. Fixed - Claude must use exactly this many stages."),
            tags$li(tags$strong("Number of Initial Rows (2-20, default 8):"), " exactly how many nodes must exist in column 1 - the starting streams everything flows from. Later columns are free to have a different node count as flows merge or split.")
          ),

          h4("Never trust the AI with the layout math"),
          p("The single most important design rule in this suite, same as everywhere else in this app: Claude ",
            "supplies only which nodes exist, which column each sits in, and the raw flow value of each link. ",
            "It never calculates node height or link curve width - the d3-sankey JavaScript library computes ",
            "both of those directly from the raw ", tags$code("value_numeric"), " figures at render time, using ",
            "an explicit ", tags$code("nodeAlign()"), " override so every node renders in the exact column ",
            "Claude assigned it, rather than d3-sankey's own automatic (and, for this app's purposes, wrong) ",
            "column-from-topology inference."),

          h4("Debugging"),
          p("Every generation (Generate Sankey tab) and every render (Visualizations tab) prints detailed ",
            "diagnostic output to the R console, including a warning if any link references a component_ref ",
            "that doesn't match a real node, or if column 1's actual node count doesn't match the slider value ",
            "that was requested.")
      )
    )
  )
}
