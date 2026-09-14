# modules/Six Sigma Analysis/sixsigma_about/ui.R

sixsigma_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Six Sigma Analysis", status = "primary", solidHeader = TRUE, width = 12,
          h4("What this suite does"),
          p("Generates Lean Six Sigma diagrams (Fishbone, Pareto, Control Chart, CTQ Tree, FMEA, SIPOC, Pugh ",
            "Matrix, Process Map, 5S, DOE Table, Balanced Scorecard, Five Whys) via the Claude API, stored as ",
            "structured rows in its own BigQuery table (six_sigma_diagrams, same project/dataset as the other ",
            "five suites), and rendered with a small set of professional, type-aware renderers."),

          h4("Two levels of classification"),
          tags$ul(
            tags$li(tags$strong("Category / Domain / Topic"), " - the same shared 3-level cascade as Mind Map, ",
                    "Knowledge Graph, and Strategic Analysis: Category = broad life domain, Domain = subject ",
                    "area, Topic = specific subject."),
            tags$li(tags$strong("Diagram Group / Diagram Type"), " - a second, independent cascade specific to ",
                    "this suite: Group is the DMAIC phase (Define/Measure/Analyse/Improve/Control) a tool ",
                    "belongs to, narrowing the Type dropdown to the handful of tools relevant to that phase.")
          ),

          h4("The 12 diagram types"),
          tags$table(class = "table table-striped",
            tags$thead(tags$tr(tags$th("Group"), tags$th("Type"), tags$th("Renderer"))),
            tags$tbody(
              tags$tr(tags$td("Define"), tags$td("SIPOC"), tags$td("HTML/CSS grid (5 fixed columns)")),
              tags$tr(tags$td("Define"), tags$td("CTQ Tree"), tags$td("SVG - 3-level hierarchy with drawn parent/child edges")),
              tags$tr(tags$td("Measure"), tags$td("Process Map"), tags$td("HTML/CSS flow (rectangles + diamonds for decisions)")),
              tags$tr(tags$td("Analyse"), tags$td("Fishbone / Ishikawa"), tags$td("SVG - spine + angled category bones")),
              tags$tr(tags$td("Analyse"), tags$td("Five Whys"), tags$td("HTML/CSS sequential flow")),
              tags$tr(tags$td("Analyse"), tags$td("Pareto Chart"), tags$td("Plotly - bars + computed cumulative % line")),
              tags$tr(tags$td("Analyse"), tags$td("FMEA"), tags$td("HTML table - computed RPN, sorted, color-banded")),
              tags$tr(tags$td("Improve"), tags$td("Pugh Matrix"), tags$td("HTML table - computed column totals")),
              tags$tr(tags$td("Improve"), tags$td("DOE Factorial Table"), tags$td("HTML table")),
              tags$tr(tags$td("Improve"), tags$td("5S"), tags$td("HTML/CSS stacked list (5 fixed stages)")),
              tags$tr(tags$td("Control"), tags$td("Control Chart"), tags$td("Plotly - computed center line and \u00b13\u03c3 limits")),
              tags$tr(tags$td("Control"), tags$td("Balanced Scorecard"), tags$td("HTML/CSS 2x2 quadrant (4 fixed perspectives)"))
            )
          ),

          h4("Never trust the AI with arithmetic"),
          p("This is the single most important design rule in this suite. Claude supplies only RAW values - ",
            "candidate causes, raw frequency counts, raw 1-10 ratings, raw measurements, raw +/-/S symbols - ",
            "and is explicitly instructed never to compute anything derived. Every calculation that actually ",
            "matters is done here, deterministically, in R:"),
          tags$ul(
            tags$li(tags$strong("Pareto:"), " sort order and cumulative % are computed from the raw frequency values"),
            tags$li(tags$strong("Control Chart:"), " the center line and \u00b13-sigma control limits are computed from the raw measurements (mean and standard deviation)"),
            tags$li(tags$strong("FMEA:"), " RPN = Severity \u00d7 Occurrence \u00d7 Detection is computed and rows are sorted by it - RPN is never stored, so it can never drift out of sync with edited ratings"),
            tags$li(tags$strong("Pugh Matrix:"), " each concept column's total is computed by summing +1/-1/0 per row")
          ),

          h4("Why Claude never sets pixel positions"),
          p("Exactly the same principle as Strategic Analysis: Claude supplies categorical layout slots (grid ",
            "row/column, sequence order, quadrant position, or for tree/fishbone shapes, a lightweight ",
            "component_ref/parent_ref pair recording which node belongs under which), and the renderer computes ",
            "real geometry - CSS Grid placement, SVG bone angles, SVG tree coordinates - deterministically."),

          h4("Debugging"),
          p("Every generation (Generate Diagram tab) and every render (Visualizations tab) prints detailed ",
            "diagnostic output to the R console, including an explicit warning if a control chart finds points ",
            "beyond its computed \u00b13\u03c3 limits, or if an FMEA/table diagram is missing expected grid coordinates.")
      )
    )
  )
}
