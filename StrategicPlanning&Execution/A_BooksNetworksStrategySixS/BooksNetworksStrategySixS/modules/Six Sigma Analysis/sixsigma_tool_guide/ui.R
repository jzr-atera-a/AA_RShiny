# modules/Six Sigma Analysis/sixsigma_tool_guide/ui.R

# Small local helper - not exported, just keeps the 33 cards below
# consistent. Adds a "Learn more" link to a verified, reputable external
# source (mostly ASQ - the American Society for Quality - and the Lean
# Enterprise Institute) for each tool, with a one-line note on what that
# page covers.
.sixsigma_tool_card <- function(name, definition, what_you_get, when_to_use, sample_request, learn_url, learn_note) {
  box(
    title = name, status = "primary", solidHeader = TRUE, width = 6,
    p(definition),
    p(tags$strong("What you'll get: "), what_you_get),
    p(tags$strong("Use it when: "), when_to_use),
    div(class = "example-box",
        h4("Try asking for it like this:"),
        p(tags$em(sample_request))
    ),
    p(style = "margin-top: 10px; font-size: 0.9em;",
      tags$i(class = "fa fa-external-link-alt"), " ",
      tags$a(href = learn_url, target = "_blank", rel = "noopener noreferrer", "Learn more"),
      " - ", learn_note)
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
            "Diagram tab, organized by which of the 7 Groups (", tags$strong("Diagram Group"), ") it belongs ",
            "to - all 33 tools from the Lean Six Sigma Green Belt Body of Knowledge. Pick the Group first, ",
            "then the specific Type. Every card below explains what the tool actually is, exactly what the ",
            "app will generate for it, and links to a reputable source (mostly ASQ, the American Society for ",
            "Quality) if you want to read more. Cards marked ", tags$strong("\u2713 Computed"),
            " mean the app itself calculates the key numbers (cumulative %, RPN, control limits, Cp/Cpk, ",
            "correlation, totals) from Claude's raw inputs - Claude is never trusted with that arithmetic.")
      )
    ),

    .sixsigma_phase_header("FRAMEWORK OVERVIEW", "The overarching Six Sigma methodology and organizational structure, before diving into a specific project phase."),
    fluidRow(
      .sixsigma_tool_card(
        "DMAIC Process Flow",
        "The core Six Sigma methodology for improving an EXISTING process: Define the problem, Measure current performance, Analyse root causes, Improve the process, Control the gains.",
        "5 boxes in a fixed left-to-right sequence (Define \u2192 Measure \u2192 Analyse \u2192 Improve \u2192 Control), each with a sub-description of what that phase means for your specific project.",
        "you need to show the 5-phase methodology used to improve an existing process, or frame a project plan for stakeholders.",
        "\"Show the DMAIC process for improving our order fulfillment cycle time\"",
        "https://asq.org/quality-resources/dmaic",
        "ASQ's full explanation of each DMAIC phase and the tools used within it."
      ),
      .sixsigma_tool_card(
        "DMADV Process Flow",
        "The Design for Six Sigma (DFSS) counterpart to DMAIC, used when creating a NEW product or process rather than fixing an existing one: Define, Measure, Analyse, Design, Verify.",
        "5 boxes in a fixed left-to-right sequence (Define \u2192 Measure \u2192 Analyse \u2192 Design \u2192 Verify), each with a topic-specific sub-description.",
        "you're designing something new from scratch, not improving something that already exists.",
        "\"Show the DMADV process for designing our new customer onboarding flow\"",
        "https://asq.org/quality-resources/sixsigma/tools",
        "ASQ's Six Sigma tools hub, covering DMAIC and its Design-for-Six-Sigma counterpart."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "Six Sigma Roles Hierarchy",
        "The belt-based organizational structure of a Six Sigma program, from senior sponsors down to front-line team members.",
        "5 levels top-to-bottom (Champions \u2192 Master Black Belts \u2192 Black Belts \u2192 Green Belts \u2192 Yellow Belts), each with a specific responsibility description for your organization.",
        "you need to explain who does what in a Six Sigma program, e.g. onboarding new team members.",
        "\"Show our Six Sigma roles hierarchy from Champions to Yellow Belts\"",
        "https://asq.org/quality-resources/sixsigma/tools",
        "ASQ's Six Sigma resource hub, which covers program roles and structure."
      ),
      box(title = "Moving into Define", status = "info", solidHeader = TRUE, width = 6,
          p("Once the methodology is clear, the Define-phase tools below help scope the actual project.")
      )
    ),

    .sixsigma_phase_header("DEFINE", "Scoping the project and translating customer needs into measurable requirements."),
    fluidRow(
      .sixsigma_tool_card(
        "SIPOC",
        "A high-level, single-page map of a process's boundaries: Suppliers, Inputs, Process, Outputs, and Customers - deliberately shallow so a team can agree on scope in minutes, not days.",
        "5 fixed columns in that exact order, each populated with 3-5 specific bullet points for your process.",
        "you need to scope a project and identify key stakeholders before mapping any detail.",
        "\"Build a SIPOC for our invoice processing workflow\"",
        "https://asq.org/quality-resources/sipoc",
        "ASQ's official page on developing and using a SIPOC diagram."
      ),
      .sixsigma_tool_card(
        "CTQ Tree",
        "Critical-to-Quality Tree - a structured way to translate a broad customer need into the specific, measurable requirements that actually drive project metrics.",
        "A 2-level tree: customer needs at the top, branching down to their measurable CTQ requirements below, with the connecting lines drawn between them.",
        "you need to turn Voice of the Customer feedback into concrete, measurable success criteria for the project.",
        "\"Build a CTQ tree for 'reliable delivery' for our logistics customers\"",
        "https://asq.org/quality-resources/sixsigma/tools",
        "ASQ's Six Sigma tools hub, which covers Voice of the Customer and CTQ translation."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "Stakeholder Analysis",
        "A Power/Interest grid used to decide how much time and what kind of communication each stakeholder deserves, based on how much influence they have and how invested they are.",
        "A 2x2 quadrant: Manage Closely, Keep Satisfied, Keep Informed, Monitor - populated with the specific people/groups relevant to your project.",
        "you need to prioritize stakeholder engagement and communication planning for a project.",
        "\"Build a stakeholder power/interest grid for our ERP rollout\"",
        "https://asq.org/quality-resources/dmaic",
        "ASQ's DMAIC guide, which describes stakeholder analysis as part of the Define phase."
      ),
      .sixsigma_tool_card(
        "Voice of the Customer Tree",
        "Captures raw customer statements (in their own words) and shows how each one maps to a specific, actionable interpretation - the input CTQ Trees are built from.",
        "A 2-level tree: raw customer quotes at the top, each branching down to its translated meaning/requirement below.",
        "you need to ground a project in what customers actually said, not internal assumptions about what they want.",
        "\"Build a Voice of Customer tree for our restaurant's service complaints\"",
        "https://asq.org/quality-resources/sixsigma/tools",
        "ASQ's Six Sigma tools hub - see the Voice of the Customer / QFD section."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "Cost of Quality",
        "Categorizes all quality-related spending into 4 buckets - Prevention, Appraisal, Internal Failure, External Failure - to show where quality money is really going.",
        "4 cells in a single row, in that fixed order, each listing specific cost items for your situation.",
        "you're building the financial case for a quality improvement project.",
        "\"Break down the cost of quality for our current defect rate\"",
        "https://asq.org/quality-resources",
        "ASQ's Quality Resources hub, including its Cost of Quality reference material."
      ),
      box(title = "Moving into Measure", status = "info", solidHeader = TRUE, width = 6,
          p("Once the project is scoped, the Measure-phase tools below help document and quantify the current state.")
      )
    ),

    .sixsigma_phase_header("MEASURE", "Documenting how the process actually works today, and collecting reliable data about it."),
    fluidRow(
      .sixsigma_tool_card(
        "Process Map",
        "The actual step-by-step sequence of a process as it really runs today, including decision points - not the idealized version people assume.",
        "A left-to-right sequence of steps; decision points render as diamonds, everything else as rectangles.",
        "you need an accurate, shared baseline understanding of a process before analysing it.",
        "\"Map our current mortgage approval process including decision points\"",
        "https://asq.org/quality-resources/seven-basic-quality-tools",
        "ASQ's overview of the 7 basic quality tools, including the flowchart."
      ),
      .sixsigma_tool_card(
        "Gage R&R",
        "\u2713 Computed. Measurement System Analysis that checks whether your measuring equipment itself is trustworthy, before you trust any data it produces. Splits total variation into Repeatability (same operator, same part) and Reproducibility (different operators) plus genuine Part-to-Part variation.",
        "3 bars: Repeatability %, Reproducibility %, Part-to-Part Variation % - plus the standard \"under 10% is acceptable\" reference line.",
        "you need to confirm your measurement system isn't the actual source of the variation you're seeing.",
        "\"Show a Gage R&R breakdown for our caliper measurements on machined parts\"",
        "https://asq.org/quality-resources/gage-repeatability",
        "ASQ's explanation of Gage R&R studies and how the variance components are calculated."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "House of Quality",
        "The core matrix of Quality Function Deployment (QFD) - correlates customer requirements against technical/engineering characteristics so teams can see where trade-offs and priorities lie.",
        "A matrix: customer requirements as rows, technical characteristics as columns, each cell marked Strong / Medium / Weak / N/A correlation.",
        "you're translating customer needs into engineering specifications and need to manage technical trade-offs explicitly.",
        "\"Build a House of Quality matrix for our new laptop's cooling requirements\"",
        "https://asq.org/quality-resources/sixsigma/tools",
        "ASQ's Six Sigma tools hub, which introduces Quality Function Deployment and the House of Quality."
      ),
      .sixsigma_tool_card(
        "Check Sheet",
        "The simplest of the seven basic quality tools - a structured tally table for collecting raw frequency data by category, consistently, over time or across shifts.",
        "A table: categories as rows, time periods/shifts/locations as columns, raw tally counts in each cell.",
        "you need a simple, structured way to present tallied observation data.",
        "\"Build a check sheet for defect types recorded over 5 shifts\"",
        "https://asq.org/quality-resources/seven-basic-quality-tools",
        "ASQ's overview of the 7 basic quality tools, including the check sheet."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "Histogram",
        "Shows the shape of a data distribution - central tendency, spread, and skew - by grouping continuous data into bins and counting frequency in each.",
        "A bar chart with bins on the x-axis (in ascending order) and frequency counts on the y-axis.",
        "you need to see the shape of a distribution: is it centered where it should be, is it skewed, is it too spread out?",
        "\"Build a histogram of our call center response times\"",
        "https://asq.org/quality-resources/seven-basic-quality-tools",
        "ASQ's overview of the 7 basic quality tools, including the histogram and its typical shapes."
      ),
      .sixsigma_tool_card(
        "Scatter Plot",
        "\u2713 Computed. Tests whether two variables are actually related, rather than assumed to be. The app fits a real linear trend line and computes the correlation coefficient from your raw data points - it never asks Claude to eyeball or state a correlation.",
        "A scatter of (x,y) points plus a computed trend line, labeled with the computed correlation coefficient (r).",
        "you suspect two variables are correlated (e.g. a process input and a defect rate) and want it quantified, not guessed.",
        "\"Build a scatter plot of machine temperature vs. defect rate\"",
        "https://asq.org/quality-resources/seven-basic-quality-tools",
        "ASQ's overview of the 7 basic quality tools, including the scatter diagram."
      )
    ),

    .sixsigma_phase_header("ANALYSE", "Finding and prioritizing the root cause(s) of the problem."),
    fluidRow(
      .sixsigma_tool_card(
        "Fishbone / Ishikawa Diagram",
        "A structured brainstorming tool that organizes potential causes of a problem into standard categories, so a team explores broadly before narrowing down.",
        "A spine-and-bones diagram: your problem statement as the \"head,\" with angled category bones (Methods, Machines, Materials, Manpower, Measurement, Environment) each carrying specific candidate causes.",
        "you need to brainstorm and categorize potential root causes systematically, especially with a group.",
        "\"Build a fishbone diagram investigating why our deliveries keep arriving late\"",
        "https://asq.org/quality-resources/fishbone",
        "ASQ's official page on the Fishbone/Ishikawa diagram, including its history and the \"6 M's.\""
      ),
      .sixsigma_tool_card(
        "Five Whys",
        "A fast root-cause technique: ask \"why\" repeatedly (typically 5 times) until you move past the symptom and reach the actual underlying cause.",
        "A chain of 5 sequential boxes, each a why-question/answer pair, with the final box highlighted as the identified root cause.",
        "you need a quick drill-down to a single dominant cause without a full team workshop.",
        "\"Do a Five Whys on why our website checkout keeps failing\"",
        "https://asq.org/quality-resources/five-whys",
        "ASQ's official page on the Five Whys (and Five Hows) technique."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "Pareto Chart",
        "\u2713 Computed. Applies the 80/20 rule: a small number of causes usually account for most of the problem. The app sorts your raw categories by frequency and computes the cumulative percentage line itself - Claude only supplies the raw counts.",
        "Bars sorted descending by frequency, with a computed cumulative % line and the standard 80% threshold marker overlaid.",
        "you need to prioritize which causes or categories to fix first, based on actual impact rather than assumption.",
        "\"Build a Pareto chart of our top customer complaint categories\"",
        "https://asq.org/quality-resources/pareto",
        "ASQ's official page on the Pareto chart and the 80/20 principle behind it."
      ),
      .sixsigma_tool_card(
        "FMEA",
        "\u2713 Computed. Failure Mode and Effects Analysis - a proactive risk-assessment tool. The app computes the Risk Priority Number (RPN = Severity \u00d7 Occurrence \u00d7 Detection) for every failure mode and sorts by it; Claude only supplies the three raw 1-10 ratings.",
        "A table of failure modes with their potential effects and causes, each row showing S/O/D ratings and a computed, color-banded RPN (red \u2265200, amber 100-199, green <100), sorted highest-risk first.",
        "you need to proactively identify and prioritize the risk of things that could go wrong before they do.",
        "\"Build an FMEA for our new online payment system\"",
        "https://asq.org/quality-resources/fmea",
        "ASQ's official page on FMEA, its history, and how RPN is calculated."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "Current Reality Tree",
        "A Theory of Constraints logic tool that traces a chain of intermediate causes back to a single deep root cause - useful when a problem has layered, non-obvious causes that Five Whys' simple chain can't capture.",
        "A 3-level tree: observed symptoms at the top, intermediate causes in the middle, one root cause at the bottom, with the logical connections drawn between them.",
        "you're facing a complex problem with multiple interacting symptoms, not one obvious cause.",
        "\"Build a Current Reality Tree for chronic late shipments\"",
        "https://www.lean.org/explore-lean/lexicon-terms/",
        "The Lean Enterprise Institute's lexicon, which includes an entry on Theory of Constraints."
      ),
      .sixsigma_tool_card(
        "Spaghetti Diagram",
        "\u2713 Computed. Tracks the actual movement of a person, material, or piece of information through a physical space - the tangled path it produces is what gives the tool its name, and usually reveals surprising amounts of wasted travel.",
        "A path connecting each location in visit order, with the total distance travelled computed by summing the individual leg distances Claude supplies - never a total Claude states itself.",
        "you want to visualize and quantify wasted movement to justify a layout change.",
        "\"Build a spaghetti diagram of a nurse's movement pattern through a hospital ward\"",
        "https://www.lean.org/explore-lean/lexicon-terms/",
        "The Lean Enterprise Institute's lexicon, which lists this tool under its original name, \"Spaghetti Chart.\""
      )
    ),

    .sixsigma_phase_header("IMPROVE", "Designing, comparing, and piloting solutions."),
    fluidRow(
      .sixsigma_tool_card(
        "Pugh Decision Matrix",
        "\u2713 Computed. An objective way to compare several candidate solutions against a baseline across multiple criteria, scoring each as better (+), worse (-), or the same (S). The app sums each option's column total itself - Claude only supplies the raw symbols.",
        "A table: criteria as rows, candidate solutions (including a Baseline column) as columns, +/-/S symbols in each cell, with a computed totals row at the bottom.",
        "you're choosing between several options and want to remove personal bias from the decision.",
        "\"Compare 3 candidate CRM systems using a Pugh matrix against our current system\"",
        "https://asq.org/quality-resources/decision-matrix",
        "ASQ's page on the decision matrix, explicitly covering the Pugh matrix variant."
      ),
      .sixsigma_tool_card(
        "DOE Factorial Design Table",
        "Design of Experiments - a structured way to test multiple process factors simultaneously (rather than one at a time), efficiently revealing which factors and interactions actually matter.",
        "A table: experimental runs as rows, factors (plus a Response column) as columns, showing each run's factor levels and observed result.",
        "you need to find optimal process settings without testing every possible combination individually.",
        "\"Design a 2x2 factorial experiment testing temperature and pressure on yield\"",
        "https://asq.org/quality-resources/quality-tools",
        "ASQ's quality tools library, including a Design of Experiments (DOE) template and explanation."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "5S Workplace Organisation",
        "A 5-stage workplace discipline - Sort, Set in Order, Shine, Standardise, Sustain - that removes clutter and builds the foundation other improvements rely on.",
        "5 stacked stages in fixed order, each with a description and specific actions for your workspace.",
        "you're planning a foundational workplace organization initiative before other improvements.",
        "\"Plan a 5S implementation for our warehouse picking area\"",
        "https://asq.org/quality-resources/learn-about-quality",
        "ASQ's quality glossary hub, which includes a Five S (5S) reference entry."
      ),
      .sixsigma_tool_card(
        "Seven Deadly Wastes",
        "The classic Lean taxonomy of non-value-added activity: Transport, Inventory, Motion, Waiting, Overproduction, Over-processing, Defects (\"TIMWOOD\").",
        "7 cells in a single row, in that fixed order, each with a specific example of that waste type in your process.",
        "you're running a waste-identification workshop and want a structured taxonomy to work through.",
        "\"Identify the seven wastes present in our current order-picking process\"",
        "https://www.lean.org/explore-lean/lexicon-terms/",
        "The Lean Enterprise Institute's lexicon entry on the \"7 Wastes\" from the Toyota Production System."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "Five Lean Principles",
        "The core Lean philosophy in sequence: identify Value, map the Value Stream, create Flow, establish Pull, and pursue Perfection.",
        "5 boxes in a fixed left-to-right sequence, each with a description of what that principle means for your specific process.",
        "you need to frame an improvement effort around Lean's foundational philosophy.",
        "\"Apply the five Lean principles to our software deployment pipeline\"",
        "https://www.lean.org/explore-lean/lexicon-terms/",
        "The Lean Enterprise Institute (co-founded by James Womack, who defined these 5 principles)."
      ),
      .sixsigma_tool_card(
        "Poka-Yoke Devices",
        "Mistake-proofing: designing errors out of a process entirely, rather than relying on training or vigilance. Prevention devices make an error physically impossible; detection devices catch it immediately if it happens anyway.",
        "A 2-column table: Prevention Devices and Detection Devices, each listing 3-5 specific mechanisms for your process.",
        "you want to inventory concrete error-proofing options rather than relying on \"be more careful.\"",
        "\"List Poka-Yoke devices to prevent wrong-part assembly on our production line\"",
        "https://www.lean.org/explore-lean/lexicon-terms/",
        "The Lean Enterprise Institute's lexicon entry on Poka-Yoke (mistake-proofing), coined by Shigeo Shingo."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "SMED Analysis",
        "Single-Minute Exchange of Dies - a systematic method for slashing equipment changeover time by separating activities that need the machine stopped (internal) from those that don't (external), then converting as many internal activities to external as possible.",
        "A table listing each changeover activity, its classification (Internal/External), and the recommended action (Keep/Convert/Eliminate).",
        "you're planning to reduce setup or changeover time on equipment.",
        "\"Build a SMED analysis for our injection moulding changeover\"",
        "https://www.lean.org/explore-lean/lexicon-terms/",
        "The Lean Enterprise Institute's lexicon entry on Single Minute Exchange of Die, developed by Shigeo Shingo."
      ),
      .sixsigma_tool_card(
        "Chaku-Chaku Flow",
        "\"Load-load\" in Japanese - a one-operator, multi-station production line design where a single person moves station to station loading and unloading parts, eliminating waiting time between steps.",
        "A left-to-right sequence of stations in the order the operator visits them, each with its specific task/cycle time.",
        "you're designing a continuous-flow line with minimal staffing and work-in-progress.",
        "\"Design a Chaku-Chaku flow for our small parts assembly cell\"",
        "https://www.lean.org/explore-lean/lexicon-terms/",
        "The Lean Enterprise Institute's lexicon, covering Toyota Production System line-design terms."
      )
    ),

    .sixsigma_phase_header("CONTROL", "Monitoring that the improvement sticks, long after the project ends."),
    fluidRow(
      .sixsigma_tool_card(
        "Control Chart",
        "\u2713 Computed. Monitors whether a process is statistically stable over time by distinguishing normal (common-cause) variation from a genuine (special-cause) shift. The app computes the center line and \u00b13\u03c3 control limits itself from your raw measurements, and flags any point outside them.",
        "A time-ordered line of your measurements, with a computed center line and upper/lower control limits overlaid; out-of-control points are highlighted.",
        "you need ongoing monitoring to detect when a process has genuinely changed, not just normal noise.",
        "\"Build a control chart for our call center average handle time over the last 15 days\"",
        "https://asq.org/quality-resources/control-chart",
        "ASQ's official page on control charts, out-of-control signals, and Shewhart's original work."
      ),
      .sixsigma_tool_card(
        "Balanced Scorecard",
        "Tracks organizational performance across 4 perspectives at once - Financial, Customer, Internal Process, Learning & Growth - so no single metric gets over-optimized at the expense of the others.",
        "A 2x2 quadrant, one perspective per corner, each listing specific objectives/metrics with targets.",
        "you need holistic, ongoing performance monitoring across more than just financial results.",
        "\"Build a balanced scorecard for our customer service department\"",
        "https://balancedscorecard.org/bsc-basics-overview/",
        "The Balanced Scorecard Institute's overview of Kaplan and Norton's original framework."
      )
    ),
    fluidRow(
      .sixsigma_tool_card(
        "Andon Board",
        "A visual management signal board - a shop-floor convention where stations show their real-time status (running, minor issue, stopped) at a glance, so problems get noticed and acted on immediately.",
        "4-8 stations in a row, each color-coded (green/amber/red) with a brief current-status description.",
        "you want real-time visual status monitoring across multiple lines or stations.",
        "\"Build an Andon board for our 5 assembly line stations\"",
        "https://www.lean.org/explore-lean/lexicon-terms/",
        "The Lean Enterprise Institute's lexicon, covering visual management terms from the Toyota Production System."
      ),
      box(title = "Moving to Data Analysis", status = "info", solidHeader = TRUE, width = 6,
          p("The Data Analysis tools below sit underneath everything else - they're the statistical foundation ",
            "for judging whether a process is actually capable and stable.")
      )
    ),

    .sixsigma_phase_header("DATA ANALYSIS", "The statistical foundation - understanding variation and process capability."),
    fluidRow(
      .sixsigma_tool_card(
        "Normal Distribution",
        "\u2713 Computed. Illustrates the Central Limit Theorem and the classic bell-curve shape that underpins most Six Sigma statistics. The app computes the actual curve mathematically from just a mean and standard deviation - Claude never describes or draws the shape itself.",
        "A real, computed bell curve with \u00b11\u03c3/\u00b12\u03c3/\u00b13\u03c3 zone boundaries marked.",
        "you're teaching or explaining variation and want a mathematically accurate curve, not an approximation.",
        "\"Show the normal distribution of our part weights with mean 250g and sd 3g\"",
        "https://asq.org/quality-resources/process-capability",
        "ASQ's page on process capability, which explains the normal-distribution assumption these statistics rely on."
      ),
      .sixsigma_tool_card(
        "Process Capability (Cp/Cpk)",
        "\u2713 Computed. Formally assesses whether a process can reliably meet specification limits. The app computes Cp, Cpk, and an approximate sigma level directly from your raw mean, standard deviation, and spec limits - the exact calculation a real capability study performs, never left to Claude.",
        "A capability histogram with USL/LSL specification lines overlaid, titled with the computed Cp, Cpk, and approximate sigma level.",
        "you need a rigorous, numeric answer to \"can this process meet spec?\", not a qualitative guess.",
        "\"Assess process capability for our shaft diameter with spec 100\u00b15mm\"",
        "https://asq.org/quality-resources/process-capability",
        "ASQ's official page on process capability, Cp/Cpk, and their limitations."
      )
    ),
    fluidRow(
      box(title = "Still not sure?", status = "info", solidHeader = TRUE, width = 12,
          p("If you know the tool's name, just say it in your request - e.g. \"Build a Fishbone for...\" - and ",
            "pick the matching Group + Type from the dropdowns above. Claude fills in the content; the Type you ",
            "pick fixes the exact structure and, where the tool involves real statistics, guarantees the app - ",
            "not Claude - does the maths.")
      )
    )
  )
}
