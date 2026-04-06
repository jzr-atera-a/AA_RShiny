# modules/intro_feedback.R
# FEEDBACK TAB — based on recruiter call transcript
intro_feedback_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="feedback-hero",
        tags$h1("Interview Process — What Changed"),
        tags$h2("Recruiter Briefing Summary — Key Updates for the 2026 Final Round"),
        div(
          span(class="hero-badge","New Coding Format"),
          span(class="hero-badge","60 Min Coding"),
          span(class="hero-badge","5 Unchanged Rounds"),
          span(class="hero-badge","Interviewers Fresh Start")
        )
    ),
    fluidRow(
      box(title="What the Recruiter Confirmed", status="primary", solidHeader=TRUE, width=8,
        div(class="strength-card",
          tags$h4("Key Updates Confirmed in Recruiter Call"),
          tags$ul(
            tags$li(tags$b("5 rounds unchanged:"), " Technical Retrospective, ML Design x2, Cross-Functional, Behavioural — same format as before."),
            tags$li(tags$b("Interviewers have zero context:"), " They cannot see previous feedback. Fresh slate. You can reuse your best examples."),
            tags$li(tags$b("Automation prevents duplicate questions:"), " System prevents the exact same questions being asked, but themes recur."),
            tags$li(tags$b("Technical Retrospective is the same project:"), " Same project you discussed before — prepare it to a much deeper technical level."),
            tags$li(tags$b("Coding interview fundamentally changed:"), " From 2 LeetCode questions to 1 multi-part real-world problem in a new environment.")
          )
        ),
        div(class="insight-card",
          tags$h5("The One Big Change: AI-Enabled Coding"),
          tags$p("Previous format: 2 LeetCode-style algorithmic questions, 45 minutes, CoderPad, no code execution."),
          tags$p(tags$b("New format:"), " 1 thematic multi-part problem, 60 minutes, multi-file codebase, code execution enabled, optional AI assistant tab."),
          tags$p("Think of it like the ML Design interview — but focused on code. Multiple checkpoints, not a single question.")
        )
      ),
      box(title="Preparation Priority", status="warning", solidHeader=TRUE, width=4,
        div(class="action-card",
          tags$h5("High Priority"),
          tags$ul(
            tags$li("Practice CoderPad sandbox — use the link in your career profile"),
            tags$li("Read unfamiliar codebases — GitHub repos, open source ML projects"),
            tags$li("Write test cases habitually — pytest assertions")
          )
        ),
        div(class="action-card",
          tags$h5("Medium Priority"),
          tags$ul(
            tags$li("Refresh BFS/DFS — maze, graph, grid problems"),
            tags$li("Practice thinking aloud before writing any code"),
            tags$li("Prepare deeper technical depth on retrospective project")
          )
        ),
        div(class="action-card",
          tags$h5("Scheduling"),
          tags$ul(
            tags$li("Interviews can be in any order"),
            tags$li("Split across multiple days if needed"),
            tags$li("US-based interviewers — can accommodate later UK times")
          )
        )
      )
    )

  )
}
intro_feedback_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("intro_feedback", 30)
  })
}
