# modules/cross_functional_feedback.R
# FEEDBACK TAB
cross_functional_feedback_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="feedback-hero",
        tags$h1("Cross-Functional Interview — Previous Round Feedback"),
        tags$h2("Three Clear Growth Areas — Communication, Complexity, Navigation"),
        div(
          span(class="hero-badge","Round: XFN"),
          span(class="hero-badge","3 Buckets of Feedback"),
          span(class="hero-badge","Answer the Question Asked"),
          span(class="hero-badge","Use Your Most Complex Stories")
        )
    ),
    fluidRow(
      box(title="Feedback Bucket 1: Communication", status="warning", solidHeader=TRUE, width=4,
        div(class="growth-card",
          tags$h4("Answering a Different Question"),
          tags$p("The interviewer noted: your stories had good detail but felt like you answered a different question than the one actually asked."),
          tags$p(tags$b("Why this happens:"), " When we have a prepared story we like, we can unconsciously steer toward it even when the question calls for something else."),
          tags$p(tags$b("Fix:"), " Before answering any behavioural question:"),
          tags$ol(
            tags$li("Repeat the question back in your own words"),
            tags$li("Confirm you are answering the right thing: 'What they are really asking is...'"),
            tags$li("If your prepared story does not fit, choose a different one")
          )
        )
      ),
      box(title="Feedback Bucket 2: Complexity", status="warning", solidHeader=TRUE, width=4,
        div(class="growth-card",
          tags$h4("Examples Not Complex Enough"),
          tags$p("The interviewer felt the situations described were more like simple migration projects or reporting system builds — not true cross-functional challenges."),
          tags$p(tags$b("What IC7 XFN complexity looks like:"),
            tags$ul(
              tags$li("Cross-org, not just cross-team"),
              tags$li("Competing priorities that genuinely conflict (not just coordination)"),
              tags$li("Real stakes — timeline, budget, customer impact"),
              tags$li("Proactive alignment before the conflict emerged")
            )
          ),
          div(class="insight-card",
            tags$b("Use:"), " Santander 40-person XFN or BCG multi-region deployment. These are the right complexity for IC7."
          )
        )
      ),
      box(title="Feedback Bucket 3: Navigation", status="warning", solidHeader=TRUE, width=4,
        div(class="growth-card",
          tags$h4("Situations Not Tricky Enough"),
          tags$p("The specific example cited: a project that resulted in an AB test platform without proactively aligning the marketing team, which likely created friction."),
          tags$p(tags$b("What the interviewer wanted:"), " Evidence that you spotted the potential friction before it emerged and proactively resolved it."),
          tags$p(tags$b("Fix:"), " In every XFN story, explicitly state: 'Before this became a problem, I did X to align Y.'"),
          tags$p(tags$b("The question to ask yourself:"), " Who could have been hurt by this project? Did I proactively bring them in before they found out?")
        )
      )
    ),
    fluidRow(
      box(title="How to Answer XFN Questions This Time", status="primary", solidHeader=TRUE, width=12,
        div(class="action-card",
          tags$h5("A Better Story Structure for XFN"),
          tags$ol(
            tags$li(tags$b("State the partnership:"), " Who were the parties? What were their competing interests? Why was alignment non-trivial?"),
            tags$li(tags$b("Acknowledge the friction:"), " What was the risk of misalignment? What would have happened if you had not intervened?"),
            tags$li(tags$b("Your proactive move:"), " What did you do before being asked? Who did you bring in early that others would have ignored?"),
            tags$li(tags$b("The negotiation:"), " What did you give up? What did they give up? How did you find the shared interest?"),
            tags$li(tags$b("The outcome:"), " Quantified result. What changed because of this partnership?"),
            tags$li(tags$b("What you would do differently:"), " One honest reflection")
          )
        ),
        div(class="tip-box",
          tags$b("Signal response:"), " When the interviewer signals interest in a direction ('what about the marketing team?') — stop and explore it fully. They are telling you what they want. Treat it as a gift, not an interruption.")
      )
    )

  )
}
cross_functional_feedback_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("cross_functional_feedback", 30)
  })
}
