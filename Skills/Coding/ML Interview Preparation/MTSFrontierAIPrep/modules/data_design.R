# modules/data_design.R
# Tab: ML-Oriented Data Design (Station 02 of the loop)

data_design_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("ML-Oriented Data Design"),
        tags$h2("Building the factory that produces training & eval signal"),
        div(
          span(class = "hero-badge", icon("layer-group"), " Schema \u2192 Rubric \u2192 Calibration \u2192 Incentives \u2192 Pipeline"),
          span(class = "hero-badge", icon("gears"), " The pipeline is the product")
        )
    ),

    fluidRow(
      box(title = "What's Being Tested", status = "primary", solidHeader = TRUE, width = 6,
          p("The JD asks for \u201cdesigning ML-oriented data systems, including task definitions, annotation schemas, rubrics, incentives, and pipelines optimized for downstream model performance.\u201d This tab is about the mechanism behind a good rubric \u2014 not just having one."),
          success_box("A rubric that's easy to grade but doesn't correlate with what you actually care about produces confident, useless signal. The hardest part is usually the edge cases, not the main case.")
      ),
      box(title = "The 5-Layer Data Design Stack", status = "info", solidHeader = TRUE, width = 6,
          timeline_entry("1", "Task definition", "Precise enough that two independent people would label the same example the same way."),
          timeline_entry("2", "Annotation schema / rubric", "Structured criteria with edge cases pre-resolved \u2014 what counts as \u2018partial credit\u2019?"),
          timeline_entry("3", "Rater calibration", "Gold examples, inter-rater agreement targets, a process for resolving disagreement."),
          timeline_entry("4", "Incentive design", "Reward careful, consistent grading \u2014 not just throughput."),
          timeline_entry("5", "Pipeline & QA loop", "Ongoing sampling, spot-checks and drift monitoring so quality doesn't decay silently.")
      )
    ),

    fluidRow(
      box(title = "Worked Example", status = "warning", solidHeader = TRUE, width = 12,
          p(tags$b("Task:"), " Grade whether an AI agent's multi-step tool-use trajectory achieved the user's goal safely and efficiently."),
          spec_block(paste(
            "task: grade_agent_tool_use_trajectory",
            "dimensions:",
            "  - goal_achievement   (0-2: failed / partial / complete)",
            "  - efficiency         (0-2: excessive steps / reasonable / optimal)",
            "  - safety             (binary: any unsafe/irreversible action taken?)",
            "calibration: 20 gold trajectories, target agreement >= 0.8 (Cohen's kappa)",
            "incentive: per-item rate + bonus tied to agreement with gold, not volume",
            "QA: 5% re-grade sample weekly, flag raters drifting from gold",
            sep = "\n"
          )),
          tip_box("Pick dimensions that are independently checkable. A single dimension that secretly captures three things (goal + efficiency + safety all in one score) is the most common rubric mistake.")
      )
    ),

    fluidRow(
      box(title = "Practice Prompts", status = "success", solidHeader = TRUE, width = 7,
          scenario_card(ns, "p1", "Prompt 1", "Design an annotation schema for grading whether an AI agent's multi-step tool-use trajectory achieved the user's goal safely and efficiently."),
          scenario_card(ns, "p2", "Prompt 2", "Your raters agree only 60% of the time on a \u2018helpfulness\u2019 rubric. Walk me through how you'd diagnose and fix this."),
          scenario_card(ns, "p3", "Prompt 3", "You're designing incentives for a rating task \u2014 how do you avoid rewarding raters for speed at the expense of quality?")
      ),
      box(title = "Strong Answer Shape", status = "danger", solidHeader = TRUE, width = 5,
          tags$ol(
            tags$li("Define the task in one precise sentence"),
            tags$li("Propose 2-4 rubric dimensions, each with its own scale"),
            tags$li("Describe a calibration step (gold examples, agreement target)"),
            tags$li("Say what you'd do if agreement comes in low \u2014 not just that you'd \u2018recalibrate\u2019")
          ),
          warn_box("\u2018We'd just hire good raters\u2019 is a non-answer. Show the mechanism: schema, calibration, incentives and an ongoing QA loop, separated from each other.")
      )
    )
  )
}

data_design_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    answers <- list(
      p1 = list(
        title = "Prompt 1 \u2014 Schema for grading agent tool-use trajectories",
        frame = "The goal is a rubric that raters who didn't build the agent can apply consistently, producing labels usable for both eval and training signal.",
        evidence = "Before finalizing dimensions, look at real trajectories to find the natural failure categories \u2014 goal not achieved, too many steps taken, or an unsafe/irreversible action along the way.",
        mechanism = "Define three dimensions: goal_achievement (0-2: failed / partial / complete), efficiency (0-2: excessive steps / reasonable / optimal), and safety (binary: any unsafe or irreversible action?). Write a decision rule for ambiguous overlaps \u2014 e.g. partial goal achievement plus an unsafe action is an automatic fail on safety regardless of the goal score.",
        tradeoffs = "More dimensions give richer signal but are harder to calibrate; fewer dimensions are easier to apply but may hide important failure modes.",
        decision = "Start with this 3-dimension schema, calibrate on ~20 gold trajectories, and only add a 4th dimension if agreement is high and a clear gap remains."
      ),
      p2 = list(
        title = "Prompt 2 \u2014 60% rater agreement on \u2018helpfulness\u2019",
        frame = "Low agreement signals one of: an ambiguous rubric, insufficient rater training, or a construct that's genuinely subjective as written.",
        evidence = "Pull the disagreement cases and look for a pattern \u2014 are they concentrated in specific edge cases, or spread randomly across the set?",
        mechanism = "If concentrated, add explicit examples and decision rules for those edge cases and re-calibrate. If spread randomly, the construct itself likely needs splitting into more objective sub-dimensions \u2014 e.g. \u2018helpfulness\u2019 \u2192 \u2018addresses the request\u2019 + \u2018appropriate detail level\u2019 + \u2018actionable\u2019.",
        tradeoffs = "Splitting into sub-dimensions adds rater time and cost but increases reliability. Some residual subjectivity may be irreducible and better handled by averaging across multiple raters than by chasing full agreement.",
        decision = "Run a focused calibration session on the top 10 disagreement cases, update the rubric with explicit examples, and re-measure agreement on a fresh sample before scaling up."
      ),
      p3 = list(
        title = "Prompt 3 \u2014 Incentives that don't trade quality for speed",
        frame = "Pay structure shapes rater behaviour \u2014 pure per-item pay rewards throughput over care.",
        evidence = "Look at existing data: is there a correlation between a rater's speed and their agreement with gold labels?",
        mechanism = "Tie part of pay to agreement with periodically-inserted gold items that raters can't distinguish from regular items. Flag raters whose throughput rises while gold-agreement falls.",
        tradeoffs = "Maintaining a gold set adds overhead, and raters may eventually learn to recognise gold items, so the set needs periodic refreshing.",
        decision = "Implement a base rate plus a gold-agreement bonus, refresh the gold set monthly, and manually review any raters flagged for a speed-up alongside an agreement drop."
      )
    )

    observeEvent(input$open_prompt, {
      a <- answers[[input$open_prompt]]
      if (!is.null(a)) {
        showModal(answer_modal(a$title, a$frame, a$evidence, a$mechanism, a$tradeoffs, a$decision))
      }
    })
  })
}
