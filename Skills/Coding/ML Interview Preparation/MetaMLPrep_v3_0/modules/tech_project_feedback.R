# modules/tech_project_feedback.R
# FEEDBACK TAB
tech_project_feedback_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="feedback-hero",
        tags$h1("Technical Retrospective — Previous Round Feedback"),
        tags$h2("IC7 Business Complexity Confirmed — Technical Depth Needs Work"),
        div(
          span(class="hero-badge","Round: Tech Retrospective"),
          span(class="hero-badge","Business Level: IC7 Confirmed"),
          span(class="hero-badge","Technical Depth: Below IC7"),
          span(class="hero-badge","Same Project — Go Deeper")
        )
    ),
    fluidRow(
      box(title="What Went Well", status="success", solidHeader=TRUE, width=5,
        div(class="strength-card",
          tags$h4("Strong Business Understanding"),
          tags$ul(
            tags$li(tags$b("Deep understanding of business objectives:"), " You clearly articulated why the project existed and what problem it solved for the organisation."),
            tags$li(tags$b("User needs:"), " You connected technical decisions to user impact — the interviewer noted this positively."),
            tags$li(tags$b("Project complexity:"), " The multichannel communications / Kafka / privacy filter project was rated at IC7 complexity level for business scope.")
          )
        ),
        div(class="insight-card",
          tags$h5("What This Means"),
          tags$p("The business story is right. The project scope is right. You are not being asked to change the project or find a different story. You need to go significantly deeper on the technical details of the same project.")
        )
      ),
      box(title="Exact Growth Area — Technical Depth", status="danger", solidHeader=TRUE, width=7,
        div(class="growth-card",
          tags$h4("Technical Depth Was Insufficient for IC7"),
          tags$p("The interviewer said: the project primarily involved integrating existing components and developing Python scripting for testing and evaluation."),
          tags$p(tags$b("This is the wrong frame."), " Even if true, you must describe the technical depth of those integrations — not just that they happened."),
          tags$hr(),
          tags$h5("What They Wanted to Hear"),
          div(class="action-card",
            tags$ul(
              tags$li(tags$b("Latency breakdowns:"), " Where does time get spent? p50/p99 latency? What was the bottleneck? How did you measure and reduce it?"),
              tags$li(tags$b("Deep Learning / LLM experience:"), " If you used any DL models — describe the architecture choice, loss function, hyperparameter decisions, why not a simpler baseline."),
              tags$li(tags$b("Kafka internals:"), " Not just 'we used Kafka' — consumer group design, partition strategy, message schema, exactly-once semantics or at-least-once, reprocessing strategy."),
              tags$li(tags$b("Privacy filter:"), " Not just 'we used regex' — what were the categories, false positive rate, how you evaluated, how you handled edge cases."),
              tags$li(tags$b("A major bug or incident:"), " What broke in production? How did you find it? What was the blast radius? How did you fix it and prevent recurrence?")
            )
          )
        )
      )
    ),
    fluidRow(
      box(title="How to Prepare Your Answer Now", status="primary", solidHeader=TRUE, width=12,
        div(class="framework-card",
          tags$h5("Rebuild the Same Story with Technical Depth"),
          fluidRow(
            column(6,
              div(class="growth-card",
                tags$h6("What You Said Before (paraphrased)"),
                tags$ul(
                  tags$li("Multichannel communications project"),
                  tags$li("Privacy filters using regex in Kafka"),
                  tags$li("Python scripting for testing and evaluation"),
                  tags$li("Business objectives clearly articulated")
                )
              )
            ),
            column(6,
              div(class="strength-card",
                tags$h6("What to Add This Time"),
                tags$ul(
                  tags$li("Kafka: exact throughput (events/sec), consumer lag metrics, retry logic"),
                  tags$li("Regex filters: precision/recall numbers, false positive cost in business terms"),
                  tags$li("Python testing: what you tested, what edge cases you found, what broke"),
                  tags$li("One specific incident: what failed, your debugging process, fix and post-mortem"),
                  tags$li("What you would do differently: name a specific architectural decision")
                )
              )
            )
          )
        ),
        div(class="tip-box",
          tags$b("Preparation exercise:"), " Write out all technical decisions you made on this project. For each one, answer: Why did you make this choice? What did you measure? What alternative did you reject? What went wrong and why? This is the level of depth they want.")
      )
    )

  )
}
tech_project_feedback_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("tech_project_feedback", 30)
  })
}
