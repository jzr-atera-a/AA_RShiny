# modules/Six Sigma Analysis/sixsigma_about/ui.R

sixsigma_about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "About Six Sigma Analysis", status = "primary", solidHeader = TRUE, width = 12,
          h4("What this suite does"),
          p("Generates Lean Six Sigma diagrams covering every tool named in the Green Belt Body of Knowledge - ",
            "Fishbone, Pareto, Control Chart, CTQ Tree, FMEA, SIPOC, Pugh Matrix, DMAIC/DMADV flows, House of ",
            "Quality, Gage R&R, Process Capability, Spaghetti Diagrams, and more - via the Claude API, stored ",
            "as structured rows in its own BigQuery table (six_sigma_diagrams, same project/dataset as the ",
            "other five suites), and rendered with a small set of professional, type-aware renderers."),

          h4("Two levels of classification"),
          tags$ul(
            tags$li(tags$strong("Category / Domain / Topic"), " - the same shared 3-level cascade as Mind Map, ",
                    "Knowledge Graph, and Strategic Analysis: Category = broad life domain, Domain = subject ",
                    "area, Topic = specific subject."),
            tags$li(tags$strong("Diagram Group / Diagram Type"), " - a second, independent cascade specific to ",
                    "this suite: Group is one of 7 lenses (Framework Overview, Define, Measure, Analyse, ",
                    "Improve, Control, Data Analysis) a tool belongs to, narrowing the Type dropdown to the ",
                    "handful of tools relevant to that phase.")
          ),

          h4("The 33 diagram types"),
          p("Full list and \"when to use it\" guidance lives on the Tool Guide tab. Several tools ",
            "deliberately reuse the same underlying renderer (e.g. DMAIC, DMADV, Chaku-Chaku, and the Five ",
            "Lean Principles all share the same sequential-flow renderer as Process Map) since their visual ",
            "shape is identical even though their content differs - this keeps the codebase small without ",
            "limiting which named tools are available."),
          tags$table(class = "table table-striped",
            tags$thead(tags$tr(tags$th("Group"), tags$th("Tools"), tags$th("Renderer family"))),
            tags$tbody(
              tags$tr(tags$td("Framework Overview"), tags$td("DMAIC, DMADV, Roles Hierarchy"), tags$td("HTML/CSS flow / stacked list")),
              tags$tr(tags$td("Define"), tags$td("SIPOC, CTQ Tree, Stakeholder Analysis, Voice of Customer, Cost of Quality"), tags$td("HTML grid / SVG tree / quadrant")),
              tags$tr(tags$td("Measure"), tags$td("Process Map, Gage R&R, House of Quality, Check Sheet, Histogram, Scatter Plot"), tags$td("HTML flow/table, Plotly bar/scatter")),
              tags$tr(tags$td("Analyse"), tags$td("Fishbone, Five Whys, Pareto, FMEA, Current Reality Tree, Spaghetti Diagram"), tags$td("SVG spine/tree/path, Plotly, HTML table")),
              tags$tr(tags$td("Improve"), tags$td("Pugh Matrix, DOE Table, 5S, Seven Wastes, Five Lean Principles, Poka-Yoke, SMED, Chaku-Chaku"), tags$td("HTML table/grid/flow/stacked list")),
              tags$tr(tags$td("Control"), tags$td("Control Chart, Balanced Scorecard, Andon Board"), tags$td("Plotly, HTML quadrant/grid")),
              tags$tr(tags$td("Data Analysis"), tags$td("Normal Distribution, Process Capability"), tags$td("Plotly - both fully server-computed"))
            )
          ),

          h4("Never trust the AI with arithmetic"),
          p("This is the single most important design rule in this suite. Claude supplies only RAW values - ",
            "candidate causes, raw frequency counts, raw 1-10 ratings, raw measurements, raw +/-/S symbols, ",
            "raw (x,y) points, raw mean/sigma/spec-limit numbers - and is explicitly instructed never to ",
            "compute anything derived. Every calculation that actually matters is done here, deterministically, in R:"),
          tags$ul(
            tags$li(tags$strong("Pareto:"), " sort order and cumulative % are computed from the raw frequency values"),
            tags$li(tags$strong("Control Chart:"), " the center line and \u00b13-sigma control limits are computed from the raw measurements (mean and standard deviation)"),
            tags$li(tags$strong("FMEA:"), " RPN = Severity \u00d7 Occurrence \u00d7 Detection is computed and rows are sorted by it - RPN is never stored, so it can never drift out of sync with edited ratings"),
            tags$li(tags$strong("Pugh Matrix:"), " each concept column's total is computed by summing +1/-1/0 per row"),
            tags$li(tags$strong("Scatter Plot:"), " the trend line and correlation coefficient are computed via lm()/cor() from the raw points"),
            tags$li(tags$strong("Normal Distribution:"), " the entire bell curve is computed via dnorm() from just a mean and standard deviation"),
            tags$li(tags$strong("Process Capability:"), " Cp, Cpk, and an approximate sigma level are all computed from raw mean/sigma/USL/LSL"),
            tags$li(tags$strong("Spaghetti Diagram:"), " total distance travelled is summed from the individual leg distances")
          ),

          h4("Why Claude never sets pixel positions"),
          p("Exactly the same principle as Strategic Analysis: Claude supplies categorical layout slots (grid ",
            "row/column, sequence order, quadrant position, or for tree/fishbone/path shapes, a lightweight ",
            "component_ref/parent_ref pair or visit sequence recording structure), and the renderer computes ",
            "real geometry - CSS Grid placement, SVG bone angles, SVG tree coordinates, SVG path layout - ",
            "deterministically."),

          h4("Debugging"),
          p("Every generation (Generate Diagram tab) and every render (Visualizations tab) prints detailed ",
            "diagnostic output to the R console, including an explicit warning if a control chart finds points ",
            "beyond its computed \u00b13\u03c3 limits, the computed Cp/Cpk/correlation/total-distance for the ",
            "relevant tools, or if a table-shaped diagram is missing expected grid coordinates.")
      )
    )
  )
}
