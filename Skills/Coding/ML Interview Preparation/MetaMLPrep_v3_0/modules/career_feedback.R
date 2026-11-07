# modules/career_feedback.R
# FEEDBACK TAB
career_feedback_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="feedback-hero",
        tags$h1("Behavioural Interview — Previous Round Feedback"),
        tags$h2("Detailed Analysis of What Went Well and Where to Grow"),
        div(
          span(class="hero-badge","Round: Behavioural"),
          span(class="hero-badge","Result: Solid with Growth Areas"),
          span(class="hero-badge","Reusable Examples"),
          span(class="hero-badge","Key Fix: Ambiguity Depth")
        )
    ),
    fluidRow(
      box(title="What Went Well", status="success", solidHeader=TRUE, width=6,
        div(class="strength-card",
          tags$h4("Strengths Confirmed by Interviewer"),
          tags$ul(
            tags$li(tags$b("Right complexity level:"), " You discussed a business-critical goal involving cross-business influence and multi-team engineering delivery. This was rated at the correct IC6/7 scope."),
            tags$li(tags$b("Risk identification:"), " You demonstrated the ability to spot risks early and use escalation to mitigate them in time — exactly what Meta looks for at L6."),
            tags$li(tags$b("Motivation and leadership:"), " Showed you can motivate engineers to deliver when the stakes are high."),
            tags$li(tags$b("Trust and commitment:"), " Strong evidence of building trust and gaining buy-in across business units.")
          )
        )
      ),
      box(title="Growth Areas — Exact Feedback", status="warning", solidHeader=TRUE, width=6,
        div(class="growth-card",
          tags$h5("Growth Area 1: Ambiguity Handling"),
          tags$p("The interviewer noted: there were many unknowns described, but all the unknowns appeared to have data available within the organisation."),
          tags$p(tags$b("What this means:"), " The ambiguity was solvable with existing resources — not true IC7-level ambiguity. True ambiguity means the organisation genuinely did not know, even with all available data."),
          tags$p(tags$b("Fix:"), " Prepare a story where you had to make a call with no data, no precedent, and real downside risk. Your Atera founding story is the right example.")
        ),
        div(class="growth-card",
          tags$h5("Growth Area 2: Continuous Growth Reflection"),
          tags$p("You cited the MBA as the learning from a past project. The interviewer wanted:"),
          tags$ul(
            tags$li("What was the specific impact of the gap on the project?"),
            tags$li("How did the gap affect your team, timeline, or outcome?"),
            tags$li("What specific behaviour did you change as a result?"),
            tags$li("Has this change been tested — where did it show up next?")
          ),
          tags$p(tags$b("Fix:"), " The reflection must be project-specific, not a general life lesson. Name a concrete metric that changed.")
        )
      )
    ),
    fluidRow(
      box(title="Revised Story Structure", status="primary", solidHeader=TRUE, width=12,
        div(class="action-card",
          tags$h5("How to Restructure Your Best Story"),
          fluidRow(
            column(6,
              div(class="framework-card",
                tags$h6("Before (what you said)"),
                tags$ul(
                  tags$li("Many unknowns — but data was available in the org"),
                  tags$li("Used escalation and mitigation"),
                  tags$li("MBA as the learning"),
                  tags$li("Implied the growth was general professional maturity")
                )
              )
            ),
            column(6,
              div(class="framework-card",
                tags$h6("After (what to say instead)"),
                tags$ul(
                  tags$li("Unknowns where NO data existed — you had to commit without proof"),
                  tags$li("Same escalation and mitigation — this was strong, keep it"),
                  tags$li("Specific impact: 'The gap cost us 3 months and X euros in rework'"),
                  tags$li("Specific change: 'I now build latency benchmarks before product features'")
                )
              )
            )
          )
        ),
        div(class="tip-box",
          tags$b("Remember:"), " The interviewer scores both the positive behaviours AND the quality of your self-reflection. A strong strength story with a weak reflection is an IC5 answer. An honest growth story with a clear, specific, tested lesson is IC7.")
      )
    )

  )
}
career_feedback_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("career_feedback", 30)
  })
}
