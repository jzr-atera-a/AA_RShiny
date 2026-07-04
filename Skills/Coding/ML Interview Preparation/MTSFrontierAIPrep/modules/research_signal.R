# modules/research_signal.R
# Tab: Research Signal Judgment (Station 03 of the loop)

research_signal_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Research Signal Judgment"),
        tags$h2("Is this result real \u2014 and strong enough to act on?"),
        div(
          span(class = "hero-badge", icon("magnifying-glass-chart"), " Quality gate"),
          span(class = "hero-badge", icon("ban"), " \u201cNot yet\u201d is a valid answer"),
          span(class = "hero-badge", icon("list-check"), " 5-point validation")
        )
    ),

    fluidRow(
      box(title = "What's Being Tested", status = "primary", solidHeader = TRUE, width = 6,
          p("The role asks you to \u201cblock claims, pause work, or force scope changes when signal strength or data integrity is insufficient.\u201d This tab is about the judgment behind that line \u2014 separating a genuine improvement from noise, a confound, or a metric that moved for the wrong reason."),
          success_box("A quality gate is a person, not a metric. The interviewer wants to see whether you'll actually hold a claim back under social or time pressure \u2014 not just whether you know the word \u2018confound\u2019.")
      ),
      box(title = "The 5-Point Validation Checklist", status = "info", solidHeader = TRUE, width = 6,
          timeline_entry("1", "Baseline comparison", "What would \u2018no real change\u2019 look like on this metric? Has the baseline itself been validated?"),
          timeline_entry("2", "Sample size & variance", "Is N large enough that the observed difference exceeds normal run-to-run noise?"),
          timeline_entry("3", "Confound check", "Did anything else change between the two conditions \u2014 data, prompts, infra, eval version?"),
          timeline_entry("4", "Reproducibility", "Does it hold on a held-out slice, or only on the set it was tuned against?"),
          timeline_entry("5", "Failure-mode shift", "Did errors actually decrease \u2014 or just move to a category that isn't being measured?")
      )
    ),

    fluidRow(
      box(title = "Worked Example", status = "warning", solidHeader = TRUE, width = 12,
          p(tags$b("Claim:"), " \u201cThe new model scores 8 points higher on the 100-item rubric set we built last week.\u201d"),
          spec_block(paste(
            "check 1 (baseline): was this rubric set used during model selection? -> if yes, contaminated",
            "check 2 (N): 100 items, +/-8pts -- is that outside historical run-to-run variance (~5pts)?",
            "check 3 (confound): rubric grader model also changed last week -> re-run old model w/ new grader",
            "check 4 (repro): re-test on a fresh 50-item held-out slice",
            "check 5 (shift): compare per-category error rates, not just the aggregate score",
            "",
            "verdict: hold the claim until checks 2-4 are re-run",
            sep = "\n"
          )),
          tip_box("Use specific numbers even when the scenario is hypothetical \u2014 \u2018is +8 outside the ~5pt noise band we've seen historically?\u2019 reads as far stronger than \u2018we'd want to check for variance.\u2019")
      )
    ),

    fluidRow(
      box(title = "Practice Prompts", status = "success", solidHeader = TRUE, width = 7,
          scenario_card(ns, "p1", "Prompt 1", "An eval shows the new model scoring 8 points higher on a 100-item rubric-graded set you built last week. Walk me through how you'd decide whether to report this as a real improvement."),
          scenario_card(ns, "p2", "Prompt 2", "A researcher is excited about a result and wants to share it with a client today. You're not convinced it's solid. What do you do in the next hour?"),
          scenario_card(ns, "p3", "Prompt 3", "How would you tell the difference between \u2018the model got better\u2019 and \u2018the eval got easier\u2019?")
      ),
      box(title = "Strong Answer Shape", status = "danger", solidHeader = TRUE, width = 5,
          tags$ol(
            tags$li("Acknowledge the result is interesting"),
            tags$li("Name 2-3 specific checks you'd run first (contamination, variance, reproducibility)"),
            tags$li("State what would make you confident vs. what would make you hold the claim"),
            tags$li("Describe how you'd communicate the \u2018hold\u2019 without killing momentum (\u2192 see Stakeholder Judgment tab)")
          ),
          warn_box("Avoid pure statistical-rigor-in-the-abstract answers. Anchor every check in the scenario's specifics \u2014 this rubric set, this grader, this sample size.")
      )
    )
  )
}

research_signal_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    answers <- list(
      p1 = list(
        title = "Prompt 1 \u2014 An 8-point jump on last week's rubric set",
        frame = "This is a claim that the new model is meaningfully better, based on a single eval run. What's at stake is whether other teams start citing \u201c+8 points\u201d as a confirmed win.",
        evidence = "Check whether this rubric set was used during model selection or tuning (contamination risk), what the historical run-to-run variance on this eval looks like (is +8 outside a ~5pt noise band?), and whether anything else changed alongside the model \u2014 grader version, prompts, infra.",
        mechanism = "Walk the 5-point checklist: baseline, sample size/variance, confounds, reproducibility, failure-mode shift. Concretely: re-run the old model with the new grader to isolate the grader effect, then re-test both models on a fresh 50-item held-out slice and compare per-category error rates, not just the aggregate score.",
        tradeoffs = "Re-running takes a day and may dampen the team's excitement \u2014 but reporting a false positive costs far more credibility once other teams have already acted on it.",
        decision = "Hold the \u2018+8 points\u2019 framing for now. Report it as \u2018promising, pending a held-out re-run by [date]\u2019, and kick off that re-run today."
      ),
      p2 = list(
        title = "Prompt 2 \u2014 A researcher wants to share an unvalidated result today",
        frame = "There's tension between speed (a same-day client share) and signal integrity. The stakes are client-facing credibility if the result doesn't hold.",
        evidence = "In an hour, check the two highest-leverage things: sample size of the result, and whether the eval set overlaps with anything used during tuning.",
        mechanism = "Run a fast 10-15 minute spot-check on a small held-out sample while, in parallel, drafting two messaging options with the researcher \u2014 one for \u2018confirmed result\u2019 and one for \u2018early positive signal, validation in progress\u2019.",
        tradeoffs = "An hour isn't enough for full validation, so whichever message goes out must match that reality \u2014 overstating confidence now creates a bigger walk-back later.",
        decision = "Recommend sharing today with the \u2018early results look promising, full validation by [date]\u2019 framing \u2014 this respects the researcher's momentum and the client's timeline without overstating certainty."
      ),
      p3 = list(
        title = "Prompt 3 \u2014 Model got better vs. eval got easier",
        frame = "This is about diagnosing whether an aggregate score increase reflects a real capability gain or a measurement artifact.",
        evidence = "Compare item-level results between the old and new model on the exact same fixed eval version, and check whether the eval items themselves changed \u2014 added, removed, or reworded \u2014 between the two runs.",
        mechanism = "Look at item-level deltas: did the new model fix items the old model previously failed, or did formerly-hard items get reclassified as easier (e.g. a grader leniency change)? Spot-audit a sample of the grader's scores for consistency.",
        tradeoffs = "Sometimes both are true at once \u2014 the model improved and the eval drifted \u2014 so the two effects need to be isolated rather than assumed to be one or the other.",
        decision = "Freeze the eval version and re-run both models on an identical fixed set with the same grader. Only attribute the score delta to the model once that's done."
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
