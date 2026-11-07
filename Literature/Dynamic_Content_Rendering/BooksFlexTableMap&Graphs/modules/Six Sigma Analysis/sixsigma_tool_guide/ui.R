# modules/Six Sigma Analysis/sixsigma_tool_guide/ui.R

# Small local helper - not exported, just keeps the 12 cards below
# consistent without repeating the same box/layout markup 12 times.
.sixsigma_tool_card <- function(name, when_to_use, best_for, sample_request) {
  box(
    title = name, status = "primary", solidHeader = TRUE, width = 6,
    p(tags$strong("Use it when: "), when_to_use),
    p(tags$strong("Best for: "), best_for),
    div(class = "example-box",
        h4("Try asking for it like this:"),
        p(tags$em(sample_request))
    )
  )
}

.sixsigma_phase_header <- function(phase_label, phase_description) {
  fluidRow(
    box(width = 12, status = "warning", solidHeader = FALSE,
        style = "background-color: #FFFACD; border-left: 5px solid #FF8C00;",
        h4(phase_label, style = "margin-top: 0;"),
        p(phase_description, style = "margin-bottom: 0;")
    )
  )
}

sixsigma_tool_guide_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Which Six Sigma diagram should I ask for?", status = "primary", solidHeader = TRUE, width = 12,
          p("Each entry below is one value of the ", tags$strong("Diagram Type"), " dropdown on the Generate ",
            "Diagram tab, organized by which DMAIC phase (", tags$strong("Diagram Group"), ") it belongs to. ",
            "Pick the Group first (which phase of the project you're in), then the specific Type. As with ",
            "Strategic Analysis, Claude fills in the content - but for several of these tools (Pareto, Control ",
            "Chart, FMEA, Pugh Matrix) the app itself calculates every derived number (cumulative %, control ",
            "limits, RPN, totals), never Claude, so the maths is always correct.")
      )
    ),

    .sixsigma_phase_header("DEFINE", "Scoping the project and translating customer needs into measurable requirements."),
    fluidRow(
      .sixsigma_tool_card(
        "SIPOC",
        "you need a high-level view of a process's boundaries before mapping it in detail.",
        "scoping a project and identifying key stakeholders at the very start.",
        "\"Build a SIPOC for our invoice processing workflow\""
      ),
      .sixsigma_tool_card(
        "CTQ Tree",
        "you need to translate a vague customer need into specific, measurable requirements.",
        "turning Voice of the Customer feedback into concrete project success metrics.",
        "\"Build a CTQ tree for 'reliable delivery' for our logistics customers\""
      )
    ),

    .sixsigma_phase_header("MEASURE", "Documenting how the process actually works today, before any analysis."),
    fluidRow(
      .sixsigma_tool_card(
        "Process Map",
        "you need to document the actual step-by-step flow of a process, including decision points.",
        "building a shared, accurate baseline understanding before root-cause analysis.",
        "\"Map our current mortgage approval process including decision points\""
      ),
      box(title = "Coming from Measure into Analyse", status = "info", solidHeader = TRUE, width = 6,
          p("Once you have an accurate process map and a baseline measurement, the next question is usually ",
            "\"why\" - that's what the Analyse-phase tools below are for.")
      )
    ),

    .sixsigma_phase_header("ANALYSE", "Finding and prioritizing the root cause(s) of the problem."),
    fluidRow(
      .sixsigma_tool_card(
        "Fishbone / Ishikawa Diagram",
        "you need to brainstorm and categorize potential root causes across standard categories.",
        "structured cause exploration across Methods, Machines, Materials, Manpower, Measurement, and Environment.",
        "\"Build a fishbone diagram investigating why our deliveries keep arriving late\""
      ),
      .sixsigma_tool_card(
        "Five Whys",
        "you need a fast, simple drill-down from a symptom to a single dominant root cause.",
        "quick investigations that don't need a full team brainstorm.",
        "\"Do a Five Whys on why our website checkout keeps failing\""
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "Pareto Chart",
        "you need to prioritize which causes or categories to fix first, based on frequency, cost, or impact.",
        "focusing limited improvement resources using the 80/20 rule.",
        "\"Build a Pareto chart of our top customer complaint categories\""
      ),
      .sixsigma_tool_card(
        "FMEA (Failure Mode & Effects Analysis)",
        "you need to proactively assess and prioritize the risk of potential failure modes before they occur.",
        "risk-based prioritization using Severity \u00d7 Occurrence \u00d7 Detection (RPN) - the app computes RPN for you.",
        "\"Build an FMEA for our new online payment system\""
      )
    ),

    .sixsigma_phase_header("IMPROVE", "Designing, comparing, and piloting solutions."),
    fluidRow(
      .sixsigma_tool_card(
        "Pugh Decision Matrix",
        "you need to objectively compare several candidate solutions against a baseline across multiple criteria.",
        "solution-selection decisions where you want to remove personal bias - the app computes each column's total.",
        "\"Compare 3 candidate CRM systems using a Pugh matrix against our current system\""
      ),
      .sixsigma_tool_card(
        "DOE Factorial Design Table",
        "you need to plan an experiment that tests multiple process factors at once, efficiently.",
        "finding optimal process operating settings without testing every combination one at a time.",
        "\"Design a 2x2 factorial experiment testing temperature and pressure on yield\""
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "5S Workplace Organisation",
        "you're planning a foundational workplace organization initiative.",
        "creating a disciplined foundation (Sort, Set in Order, Shine, Standardise, Sustain) that other improvements build on.",
        "\"Plan a 5S implementation for our warehouse picking area\""
      ),
      box(title = "Moving into Control", status = "info", solidHeader = TRUE, width = 6,
          p("Once a solution is implemented, the Control-phase tools below help you monitor whether the gain ",
            "actually holds over time.")
      )
    ),

    .sixsigma_phase_header("CONTROL", "Monitoring that the improvement sticks, long after the project ends."),
    fluidRow(
      .sixsigma_tool_card(
        "Control Chart",
        "you need to monitor whether a process is statistically stable over time.",
        "ongoing process monitoring and detecting special-cause variation - the app computes the center line and \u00b13\u03c3 limits from your data, never trusting Claude with that maths.",
        "\"Build a control chart for our call center average handle time over the last 15 days\""
      ),
      .sixsigma_tool_card(
        "Balanced Scorecard",
        "you need to track strategic performance across multiple perspectives at once, not just one metric.",
        "holistic, ongoing monitoring across Financial, Customer, Internal Process, and Learning & Growth.",
        "\"Build a balanced scorecard for our customer service department\""
      )
    )
  )
}
