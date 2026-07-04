# modules/ops_translation.R
# Tab: Ops -> Research Translation (Station 01 of the loop)

ops_translation_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ops \u2192 Research Translation"),
        tags$h2("Where messy reality enters the loop"),
        div(
          span(class = "hero-badge", icon("comments"), " Vague \u2192 specific"),
          span(class = "hero-badge", icon("layer-group"), " Pattern, not anecdote"),
          span(class = "hero-badge", icon("file-export"), " Hands off cleanly")
        )
    ),

    fluidRow(
      box(title = "What's Being Tested", status = "primary", solidHeader = TRUE, width = 6,
          p("The JD asks you to \u201ctranslate ambiguous, real-world behavior into structured evaluation frameworks and new data categories\u201d and to do \u201cfailure analysis\u201d that finds \u201croot causes, edge cases, and opportunities for improvement.\u201d This tab is about that translation step \u2014 turning a fuzzy report into something a data-design team can build from."),
          success_box("What's tested isn't problem-solving in the abstract \u2014 it's the discipline of reading enough raw examples to find the real pattern, before naming it.")
      ),
      box(title = "The 5-Step Translation Framework", status = "info", solidHeader = TRUE, width = 6,
          timeline_entry("1", "Collect raw signal", "Read actual transcripts, tickets or logs first \u2014 summaries hide the detail that matters."),
          timeline_entry("2", "Cluster by cause", "Group instances by underlying mechanism, not surface wording."),
          timeline_entry("3", "Name the dimension", "Give it a measurable definition: binary pass/fail, a 1-5 rubric, or a rate."),
          timeline_entry("4", "Scope severity & frequency", "How often it happens, how bad when it does, and who's affected."),
          timeline_entry("5", "Write the hand-off spec", "Concrete enough that a data-design team could build the eval without another conversation with you.")
      )
    ),

    fluidRow(
      box(title = "Worked Example", status = "warning", solidHeader = TRUE, width = 12,
          p(tags$b("Signal:"), " Users say an agent \u201csometimes ignores instructions in long conversations.\u201d"),
          spec_block(paste(
            "spec: long_context_instruction_drift",
            "definition: \"Model fails to apply an instruction given >6 turns earlier\"",
            "measurement: binary pass/fail per conversation, rubric-graded",
            "severity: high (silent failure, no error signal to user)",
            "est. frequency: ~14% of conversations >10 turns (from 40 sampled transcripts)",
            "next step: build 100-conversation eval set, stratified by conversation length",
            sep = "\n"
          )),
          tip_box("Distinguish \u2018this happened once\u2019 from \u2018this is a pattern worth building an eval for\u2019 \u2014 cite a rate (e.g. 6 of 40 transcripts \u2192 ~15%), not just an example.")
      )
    ),

    fluidRow(
      box(title = "Practice Prompts", status = "success", solidHeader = TRUE, width = 7,
          scenario_card(ns, "p1", "Prompt 1", "Users say an agent \u2018sometimes ignores instructions in long conversations.\u2019 You have 40 transcripts. Walk me through how you'd turn this into something a research team can measure."),
          scenario_card(ns, "p2", "Prompt 2", "A client says a model \u2018feels less careful than it used to\u2019 after a recent update, but can't point to a specific example. How do you investigate this?"),
          scenario_card(ns, "p3", "Prompt 3", "You notice three unrelated bug reports might actually share a root cause. How do you confirm that before proposing a new eval category?")
      ),
      box(title = "Strong Answer Shape", status = "danger", solidHeader = TRUE, width = 5,
          tags$ol(
            tags$li("Situation: restate the vague signal as given"),
            tags$li("Action: how you'd sample and read examples, what you'd look for when clustering"),
            tags$li("Result: the resulting eval dimension and its definition"),
            tags$li("Check: how you'd sanity-check this framing is right before handing it off")
          ),
          warn_box("Don't jump straight to \u2018we'd build a benchmark for this\u2019 without grounding the dimension in real examples \u2014 and resist proposing a fix; this station is about framing, not engineering.")
      )
    )
  )
}

ops_translation_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    answers <- list(
      p1 = list(
        title = "Prompt 1 \u2014 40 transcripts, \u2018ignores instructions in long conversations\u2019",
        frame = "A vague complaint needs to become a measurable, reproducible eval dimension \u2014 not a fix, and not yet a benchmark.",
        evidence = "Read through all 40 transcripts, focusing on conversations longer than ~6 turns, and note every instance where an instruction given earlier wasn't applied later.",
        mechanism = "Cluster the instances by cause \u2014 e.g. instruction superseded by later context, instruction simply forgotten, or instruction contradicted by a later turn. For the dominant cluster, define a binary measurable criterion and estimate its frequency (e.g. 6 of 40 \u2248 15% of long conversations).",
        tradeoffs = "40 transcripts is a small sample, so a 15% estimate carries wide uncertainty \u2014 the spec should present it as a starting estimate, not a final figure.",
        decision = "Hand off a spec defining \u2018long_context_instruction_drift\u2019 with its definition, the estimated frequency range, and a recommendation to build a 100-conversation stratified eval set to tighten the estimate."
      ),
      p2 = list(
        title = "Prompt 2 \u2014 \u2018Feels less careful\u2019, no concrete example yet",
        frame = "An ambiguous qualitative signal with zero concrete examples \u2014 the first job is surfacing examples, not building an eval.",
        evidence = "Ask the client for any logs from before/after the update on similar tasks. If none exist, run a small set of matched prompts through both model versions side by side.",
        mechanism = "Do a blind side-by-side comparison of old vs. new outputs on 15-20 representative prompts, looking for systematic differences in hedging, caveats, or risk-related language.",
        tradeoffs = "Synthetic side-by-sides may miss the actual production triggering conditions, but they're the fastest way to surface candidate hypotheses without waiting for new production examples.",
        decision = "Run the side-by-side this week. If a pattern emerges, frame it as a hypothesis and ask the client for ~5 production examples matching it before investing in a formal eval."
      ),
      p3 = list(
        title = "Prompt 3 \u2014 Three bug reports, possibly one root cause",
        frame = "Risk of premature pattern-matching \u2014 need to verify a shared cause is real before investing in a new eval category.",
        evidence = "Pull the underlying transcripts/logs for all three reports and look at the actual mechanism, not just the surface-level symptom description each team used.",
        mechanism = "Form a candidate shared mechanism (e.g. a specific tool-call sequence or context condition), then test it against each of the three cases individually \u2014 does it explain all three, or only some?",
        tradeoffs = "If the mechanism explains 2 of 3, that's still a real, useful pattern \u2014 but claiming \u20183 reports, 1 cause\u2019 when it's really 2 would overstate the case and misdirect the fix.",
        decision = "Report exactly how many of the three the mechanism explains, and size the new eval category to that confirmed subset \u2014 tracking the remaining case separately as an open question."
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
