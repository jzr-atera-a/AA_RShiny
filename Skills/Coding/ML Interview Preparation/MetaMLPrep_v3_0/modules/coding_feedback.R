# modules/coding_feedback.R
# FEEDBACK TAB
coding_feedback_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="feedback-hero",
        tags$h1("Coding Interview — Previous Round Feedback"),
        tags$h2("What Was Strong and the Single Most Important Fix for the New Format"),
        div(
          span(class="hero-badge","Round: Coding"),
          span(class="hero-badge","Strength: Communication"),
          span(class="hero-badge","Fix: Think Before Coding"),
          span(class="hero-badge","New Format: Multi-Part")
        )
    ),
    fluidRow(
      box(title="What Went Well", status="success", solidHeader=TRUE, width=5,
        div(class="strength-card",
          tags$h4("Exceptional Communication — Top of Field"),
          tags$p("The interviewer rated your communication significantly above average compared to other candidates at this level."),
          tags$ul(
            tags$li(tags$b("Clearly explained thought process:"), " You narrated what you were doing and why throughout."),
            tags$li(tags$b("Stated assumptions explicitly:"), " You flagged constraints and edge case assumptions as you went."),
            tags$li(tags$b("Engaged with the interviewer:"), " The session felt collaborative, not adversarial.")
          ),
          div(class="insight-card",
            tags$p(tags$b("This is a genuine differentiator."), " Keep this. It is rare and valuable. Do not rush through it in the new format.")
          )
        )
      ),
      box(title="The One Growth Area", status="danger", solidHeader=TRUE, width=7,
        div(class="growth-card",
          tags$h4("Jumped Into Coding Too Quickly"),
          tags$p("The interviewer wanted more thought about the solution before implementation began. The problem-solving felt rushed."),
          tags$p(tags$b("What happened:"), " You described feeling time pressure, which pushed you to start coding before fully planning the approach. The result was developing a slightly different solution to what was needed."),
          tags$p(tags$b("The fix — 3 minutes before any code:"),
            tags$ol(
              tags$li("Restate the problem in your own words"),
              tags$li("Clarify 2-3 edge cases or constraints explicitly"),
              tags$li("Sketch the approach at a high level — data structure, algorithm choice, why"),
              tags$li("State the expected time and space complexity BEFORE writing code"),
              tags$li("Only then open the editor")
            )
          )
        ),
        div(class="action-card",
          tags$h5("Adapting to the New Format"),
          tags$p("The new format is multi-part with starter code. This actually helps:"),
          tags$ul(
            tags$li("You have time to read existing code before writing anything"),
            tags$li("The multi-part structure gives natural checkpoints to pause and plan"),
            tags$li("The AI assistant can generate boilerplate so you can focus on logic"),
            tags$li("Running code is allowed — test early and often, not at the end")
          )
        )
      )
    ),
    fluidRow(
      box(title="Practice Protocol", status="info", solidHeader=TRUE, width=12,
        div(class="framework-card",
          tags$h5("How to Practise for the New Format"),
          fluidRow(
            column(4, div(class="action-card",
              tags$h6("Week 1-2: Read Codebases"),
              tags$ul(
                tags$li("Take an open-source Python project (scikit-learn, FastAPI)"),
                tags$li("Navigate without running it — understand structure from code alone"),
                tags$li("Explain it out loud as if to an interviewer"),
                tags$li("Then run it and verify your understanding")
              )
            )),
            column(4, div(class="action-card",
              tags$h6("Week 3-4: Multi-Part Problems"),
              tags$ul(
                tags$li("Do LeetCode graph/BFS problems with a timer"),
                tags$li("Force 3 minutes of planning before writing anything"),
                tags$li("Narrate your approach throughout"),
                tags$li("Add test cases before checking solution")
              )
            )),
            column(4, div(class="action-card",
              tags$h6("Week 5-6: CoderPad Sandbox"),
              tags$ul(
                tags$li("Use the sandbox link in your career profile"),
                tags$li("Practice using the AI assistant tab — ask it to explain starter code"),
                tags$li("Run code at each step — do not write 50 lines before testing"),
                tags$li("Time yourself — 60 minutes feels longer than 45")
              )
            ))
          )
        )
      )
    )

  )
}
coding_feedback_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("coding_feedback", 30)
  })
}
