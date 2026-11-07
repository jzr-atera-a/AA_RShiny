# modules/practice_exercise.R
# Tab: Practice & Exercise Prep

practice_exercise_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Practice & Exercise Prep"),
        tags$h2("One structure, applied across all four stations"),
        div(
          span(class = "hero-badge", icon("diagram-project"), " Frame \u2192 Evidence \u2192 Mechanism \u2192 Tradeoffs \u2192 Decision"),
          span(class = "hero-badge", icon("stopwatch"), " ~48 min, AI Interview + Exercise")
        )
    ),

    fluidRow(
      box(title = "Universal Answer Structure", status = "primary", solidHeader = TRUE, width = 7,
          timeline_entry("1", "Frame", "Restate the situation in your own terms \u2014 what's actually being claimed or asked, and what's at stake if you get it wrong."),
          timeline_entry("2", "Evidence", "State what you'd look at first. Be concrete: sample sizes, baselines, who's affected, what data exists."),
          timeline_entry("3", "Mechanism", "Walk through the reasoning step by step \u2014 this is where systems-level thinking gets evaluated."),
          timeline_entry("4", "Tradeoffs", "Name at least one limitation, risk, or alternative reading of the evidence. Don't oversell certainty."),
          timeline_entry("5", "Decision", "End with a concrete recommendation, next step, or \u2018what I'd do by end of week\u2019 \u2014 not just analysis.")
      ),
      box(title = "Exercise-Format Tips", status = "warning", solidHeader = TRUE, width = 5,
          tags$ol(
            tags$li(tags$b("Narrate everything."), " It's an AI interviewer \u2014 it grades what you say, not what you're thinking."),
            tags$li(tags$b("Use the 5-step shape every time."), " Even a 2-minute answer should hit Frame and Decision."),
            tags$li(tags$b("Be specific with numbers."), " Hypothetical figures are fine \u2014 vagueness is not."),
            tags$li(tags$b("It's safe to say \u2018not yet\u2019."), " That's the quality-gate instinct the role wants \u2014 just pair it with a path forward."),
            tags$li(tags$b("Watch the clock."), " ~48 minutes total covers conversation and exercise \u2014 don't let one answer run long.")
          ),
          success_box("Keep one concrete example ready per focus area before you start \u2014 abstract answers score lower than specific, slightly-imperfect ones.")
      )
    ),

    fluidRow(
      box(title = "Mixed Scenario Bank \u2014 Rehearse Out Loud", status = "info", solidHeader = TRUE, width = 12,
          p("Each scenario below is tagged with the station it draws on most. Say your answer out loud using the 5-step structure, then jot the key beats in the notes box \u2014 notes are local to this session only."),

          fluidRow(
            column(6,
              scenario_card(ns, "s1", "Station 03 \u00b7 Research Signal Judgment", "Your team reports a 12% jump on an internal eval after a prompt change. The eval was last updated two weeks ago. What's your first move?"),
              textAreaInput(ns("notes1"), NULL, placeholder = "Frame / Evidence / Mechanism / Tradeoffs / Decision\u2026", rows = 3, width = "100%")
            ),
            column(6,
              scenario_card(ns, "s2", "Station 02 \u00b7 ML-Oriented Data Design", "You need a rubric for grading whether a chatbot response is 'over-confident'. Sketch the dimensions and how you'd calibrate raters."),
              textAreaInput(ns("notes2"), NULL, placeholder = "Frame / Evidence / Mechanism / Tradeoffs / Decision\u2026", rows = 3, width = "100%")
            )
          ),
          fluidRow(
            column(6,
              scenario_card(ns, "s3", "Station 01 \u00b7 Ops \u2192 Research Translation", "A domain expert says an agent's outputs 'don't feel grounded anymore' after a model swap, but has no specific examples yet. What do you do in the next 24 hours?"),
              textAreaInput(ns("notes3"), NULL, placeholder = "Frame / Evidence / Mechanism / Tradeoffs / Decision\u2026", rows = 3, width = "100%")
            ),
            column(6,
              scenario_card(ns, "s4", "Station 04 \u00b7 Stakeholder Judgment", "Leadership wants a go/no-go decision on a launch by Friday, but your eval suite only covers 60% of the relevant scenarios. How do you frame this for them?"),
              textAreaInput(ns("notes4"), NULL, placeholder = "Frame / Evidence / Mechanism / Tradeoffs / Decision\u2026", rows = 3, width = "100%")
            )
          ),
          fluidRow(
            column(6,
              scenario_card(ns, "s5", "Cross-station \u00b7 Translation \u2192 Data Design", "Three different teams report 'weird' agent behaviour in tool calls, each describing it differently. How do you decide whether this is one issue or three \u2014 and what would you build to check?"),
              textAreaInput(ns("notes5"), NULL, placeholder = "Frame / Evidence / Mechanism / Tradeoffs / Decision\u2026", rows = 3, width = "100%")
            ),
            column(6,
              scenario_card(ns, "s6", "Cross-station \u00b7 Signal \u2192 Stakeholder", "A 10-point improvement on your eval doesn't show up in production metrics after rollout. Walk through your investigation and how you'd report it."),
              textAreaInput(ns("notes6"), NULL, placeholder = "Frame / Evidence / Mechanism / Tradeoffs / Decision\u2026", rows = 3, width = "100%")
            )
          )
      )
    ),

    fluidRow(
      box(title = "Final Pre-Interview Recap", status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4, framework_box("Know the loop", "Translation \u2192 Data Design \u2192 Signal Judgment \u2192 Stakeholder Judgment \u2192 back to ops.", "rotate")),
            column(4, framework_box("Know your checklists", "5-point signal validation, 5-layer data design stack, 5-step translation, 5-step stakeholder framework.", "list-check")),
            column(4, framework_box("Know your structure", "Frame \u2192 Evidence \u2192 Mechanism \u2192 Tradeoffs \u2192 Decision, every time.", "diagram-project"))
          )
      )
    )
  )
}

practice_exercise_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Notes are session-local (textAreaInput); no persistence needed.

    answers <- list(
      s1 = list(
        title = "Scenario 1 \u2014 12% jump after a prompt change, eval updated 2 weeks ago",
        frame = "Two variables changed close together \u2014 the prompt and the eval \u2014 which creates a high risk of confounding the result.",
        evidence = "Check the eval's changelog from two weeks ago: what exactly changed, and could that alone account for part of the 12%?",
        mechanism = "Run a 2x2: old prompt x old eval, old prompt x new eval, new prompt x old eval, new prompt x new eval (where possible) \u2014 to isolate the eval-change effect from the prompt-change effect.",
        tradeoffs = "This doubles the number of runs needed and delays the headline number by a day or two \u2014 but without it, the 12% conflates two unrelated changes.",
        decision = "Run the isolating comparison before reporting any number, even if it means the update goes out a day late."
      ),
      s2 = list(
        title = "Scenario 2 \u2014 Rubric for 'over-confident' chatbot responses",
        frame = "\u2018Over-confidence\u2019 is subjective as stated \u2014 it needs to be broken into checkable sub-signals before raters can apply it consistently.",
        evidence = "Look at real transcripts for concrete patterns: stating uncertain facts as certain, no hedging on close calls, or ignoring uncertainty the user themselves stated.",
        mechanism = "Define two dimensions: \u2018calibration language\u2019 (does the response hedge appropriately given how reliable the claim actually is) and \u2018factual certainty mismatch\u2019 (does confident phrasing accompany an actually-uncertain or incorrect claim). Calibrate with 15-20 gold examples spanning both axes.",
        tradeoffs = "The factual-mismatch dimension needs a reference answer key, which adds setup cost; calibration-language alone is cheaper and needs no reference.",
        decision = "Start with calibration-language only, and add the factual-mismatch dimension once a reference set exists."
      ),
      s3 = list(
        title = "Scenario 3 \u2014 'Doesn't feel grounded anymore', no examples yet, 24-hour window",
        frame = "Need to convert a vague expert intuition into concrete evidence within a tight window \u2014 without manufacturing a pattern that isn't there.",
        evidence = "Ask the expert to flag the next 3-5 outputs that trigger that feeling in real time, rather than recalling past ones from memory.",
        mechanism = "Pair each flagged output with the equivalent output from the prior model version where available, and look for a common thread \u2014 e.g. less citation of source material, more generic phrasing.",
        tradeoffs = "24 hours may only yield 1-2 flagged examples \u2014 enough to form a hypothesis, not enough to confirm a pattern.",
        decision = "At 24 hours, report a hypothesis with the available examples and propose a short follow-up window to gather more before deciding whether to build a formal eval."
      ),
      s4 = list(
        title = "Scenario 4 \u2014 Go/no-go by Friday, eval suite covers 60%",
        frame = "The decision deadline is fixed and the evidence coverage is incomplete \u2014 both need to be communicated honestly.",
        evidence = "Identify what's in the uncovered 40%: is it mostly low-frequency edge cases, or does it include high-severity scenarios?",
        mechanism = "Present the 60% results as \u2018what we know\u2019, and characterize the 40% gap by risk level rather than leaving it unspoken.",
        tradeoffs = "Full coverage by Friday isn't achievable \u2014 the real choice is launching with a stated residual risk versus delaying the launch.",
        decision = "Recommend a conditional go: launch with the 60% evidence plus a monitoring plan targeting the uncovered 40%, with a rollback trigger agreed in advance."
      ),
      s5 = list(
        title = "Scenario 5 \u2014 Three teams, three descriptions, maybe one cause",
        frame = "Surface-level reports differ, so the first job is determining whether a shared underlying mechanism actually exists before building anything.",
        evidence = "Collect 1-2 concrete transcript examples from each team and look at the actual tool-call sequences, not just each team's description of the symptom.",
        mechanism = "Form a candidate shared trigger \u2014 e.g. all three involve tool calls after the context window fills, or all involve a specific tool type \u2014 and test it against each team's examples individually.",
        tradeoffs = "If the mechanism only explains 2 of 3, building one eval for all three would mislabel the third team's issue.",
        decision = "Build one eval sized to however many teams the confirmed mechanism explains, and track the remaining team's issue separately as an open item."
      ),
      s6 = list(
        title = "Scenario 6 \u2014 10-point eval gain doesn't show up in production",
        frame = "This is the classic disconnect between offline eval gains and online outcomes \u2014 an eval-validity question.",
        evidence = "Check whether the eval's task distribution matches a sample of real production traffic, and whether the production metric is even sensitive to the dimension the eval measures.",
        mechanism = "Compare the eval's scenario mix to real production traffic; if they diverge significantly, the eval may be measuring something rare or low-impact in practice.",
        tradeoffs = "Fixing this means either re-scoping the eval to better match production (more representative, possibly less sensitive) or accepting it as a leading indicator that takes longer to show up online.",
        decision = "Report the disconnect plainly \u2014 \u2018the eval improvement is real, but doesn't map to this production metric yet\u2019 \u2014 and propose either re-scoping the eval or identifying a metric more directly downstream of what it measures."
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
