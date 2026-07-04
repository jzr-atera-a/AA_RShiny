# modules/stakeholder_judgment.R
# Tab: Stakeholder Judgment (Station 04 of the loop)

stakeholder_judgment_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Stakeholder Judgment"),
        tags$h2("Where signal becomes a decision"),
        div(
          span(class = "hero-badge", icon("users"), " Audience-aware"),
          span(class = "hero-badge", icon("hand"), " \u201cNo, and here's the path\u201d"),
          span(class = "hero-badge", icon("scale-balanced"), " Tradeoffs out loud")
        )
    ),

    fluidRow(
      box(title = "What's Being Tested", status = "primary", solidHeader = TRUE, width = 6,
          p("The JD asks you to \u201cpartner with cross-functional and client-facing teams to translate research progress into clear, credible narratives grounded in evidence,\u201d and \u2014 again \u2014 to \u201cblock claims, pause work, or force scope changes\u201d when needed. This tab is where the result of the Research Signal Judgment tab actually reaches people who'll make decisions with it."),
          success_box("Both halves matter: a hold that isn't communicated well is as costly as no hold at all. Lead with the recommendation, then the reasoning.")
      ),
      box(title = "The Stakeholder Framework", status = "info", solidHeader = TRUE, width = 6,
          timeline_entry("1", "Assess evidence strength", "Start from where Research Signal Judgment left off \u2014 how confident are you, really?"),
          timeline_entry("2", "Identify what's at stake", "A client deck, an internal roadmap call, a model launch \u2014 the evidence bar scales with the stakes."),
          timeline_entry("3", "Tailor the message", "A researcher needs the mechanism and confidence interval; a non-technical stakeholder needs the implication and the recommendation."),
          timeline_entry("4", "Lead with the recommendation", "\u2018Here's what I'd do, and why\u2019 lands better than a list of concerns."),
          timeline_entry("5", "Offer a concrete path forward", "\u2018Not yet\u2019 should come with \u2018here's what would change my mind, and by when.\u2019")
      )
    ),

    fluidRow(
      box(title = "Worked Example \u2014 Same Situation, Two Audiences", status = "warning", solidHeader = TRUE, width = 12,
          p(tags$b("Situation:"), " A client wants to publish a case study based on 5 cherry-picked examples."),
          fluidRow(
            column(6,
              div(class = "section-heading-dark", "To the client (non-technical)"),
              spec_block("\"These 5 examples are promising, but 5 isn't enough to support a published claim. I'd like 1 week to run this against a 100-item sample -- if it holds, we have a much stronger story; if it doesn't, we've avoided a retraction risk.\"")
            ),
            column(6,
              div(class = "section-heading-dark", "To the research team (technical)"),
              spec_block("\"Selection bias risk -- need a stratified sample, not hand-picked wins. Can we get a 100-item eval run by Thursday?\"")
            )
          ),
          tip_box("Notice both messages lead with a recommendation and a timeline \u2014 not just a concern.")
      )
    ),

    fluidRow(
      box(title = "Practice Prompts", status = "success", solidHeader = TRUE, width = 7,
          scenario_card(ns, "p1", "Prompt 1", "A client wants to publish a case study based on 5 cherry-picked examples. How do you respond in the next stakeholder meeting?"),
          scenario_card(ns, "p2", "Prompt 2", "A PM wants to ship a feature based on a 5-example demo that looked great. How do you handle this conversation?"),
          scenario_card(ns, "p3", "Prompt 3", "You need to explain to a non-technical stakeholder why a result that looks like an improvement might not be one \u2014 without sounding like you're saying \u2018no\u2019 for no reason.")
      ),
      box(title = "Strong Answer Shape", status = "danger", solidHeader = TRUE, width = 5,
          tags$ol(
            tags$li("State your read of the evidence in one sentence"),
            tags$li("Name what's at stake if the claim is wrong"),
            tags$li("Give the recommendation"),
            tags$li("Give the concrete condition that would change your mind, with a timeline")
          ),
          warn_box("\u2018I'd just be honest with them\u2019 is the whole-plan trap. Show the actual words you'd use, and the path you'd offer \u2014 not just a refusal.")
      )
    )
  )
}

stakeholder_judgment_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    answers <- list(
      p1 = list(
        title = "Prompt 1 \u2014 Case study based on 5 cherry-picked examples",
        frame = "There's a reputational/legal risk in publishing an unvalidated claim, versus a relationship cost in pushing back on something the client is excited about.",
        evidence = "Note the sample size (5) and ask how those 5 were selected. If they were hand-picked, selection bias is the core issue \u2014 not the underlying capability.",
        mechanism = "Propose a quick stratified sample (e.g. 100 items) that could either strengthen or moderate the claim within a defined timeframe, run in parallel with other publication prep.",
        tradeoffs = "Delaying publication has a real cost \u2014 momentum, client excitement \u2014 but a retraction after publication costs far more in credibility.",
        decision = "Recommend a 1-week delay for the larger sample, framed as \u2018making the story bulletproof\u2019 rather than \u2018we don't trust this\u2019."
      ),
      p2 = list(
        title = "Prompt 2 \u2014 Shipping a feature off a 5-example demo",
        frame = "This is an internal launch decision based on insufficient evidence; the stakes are a possible rollback or user-facing regression after launch.",
        evidence = "Ask what the 5 examples were chosen to represent, and whether there's existing data on this feature's failure modes at scale.",
        mechanism = "Propose a lightweight gating eval \u2014 e.g. 50-100 cases covering known edge cases \u2014 that can run before the ship date, with a clear go/no-go threshold agreed up front.",
        tradeoffs = "This adds a few days to the timeline; shipping broken can cost more in user trust and rollback effort, but the team also has real momentum to preserve.",
        decision = "Recommend the scoped eval runs in parallel with other launch prep, not blocking, with the threshold agreed before results come in so the decision isn't relitigated afterward."
      ),
      p3 = list(
        title = "Prompt 3 \u2014 Explaining a non-improvement to a non-technical stakeholder",
        frame = "The communication challenge is translating a statistical/methodological concern into plain language without sounding obstructive.",
        evidence = "Use a concrete, relatable analogy \u2014 e.g. \u2018if I flip a coin 10 times and get 7 heads, that doesn't mean the coin is biased; we need more flips to know.\u2019",
        mechanism = "Pair the analogy with the actual numbers from this case, then immediately follow with the plan to get a clearer answer \u2014 don't leave the analogy hanging without a next step.",
        tradeoffs = "Oversimplifying risks the stakeholder underestimating the issue; over-explaining risks losing them in methodology.",
        decision = "One sentence of plain-language reasoning plus one sentence of recommended next step, framed as \u2018good news \u2014 we can know for sure by [date]\u2019."
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
