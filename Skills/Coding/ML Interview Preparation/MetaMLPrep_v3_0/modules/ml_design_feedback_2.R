# modules/ml_design_feedback_2.R
# FEEDBACK TAB
ml_design_feedback_2_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="feedback-hero",
        tags$h1("ML Design Interview II — Previous Round Feedback"),
        tags$h2("Short-Form Video Recommendation — Key Lessons for This Round"),
        div(
          span(class="hero-badge","Round: Design 2"),
          span(class="hero-badge","Question: Video Recommendation"),
          span(class="hero-badge","Main Issue: Too Little ML"),
          span(class="hero-badge","Fix: Always Anchor on ML First")
        )
    ),
    fluidRow(
      box(title="What the Interviewer Said", status="danger", solidHeader=TRUE, width=12,
        div(class="growth-card",
          tags$h4("The Main Issue: Solution Had Very Little ML"),
          tags$p("The interviewer's exact concern: the solution relied primarily on heuristics-based inference rather than ML. This is the most critical piece of feedback from this round."),
          tags$p(tags$b("What likely happened:"), " Under time pressure, it is common to reach for simpler heuristics — 'show popular videos,' 'filter by watch history,' 'weight by recency.' These feel safe but signal a lack of ML depth."),
          tags$p(tags$b("What a video recommendation system must include:"),
            tags$ul(
              tags$li("Two-tower retrieval model — user embedding + item embedding — NOT a rules-based filter"),
              tags$li("DNN ranking model with explicit features: user history, video metadata, context"),
              tags$li("A named loss function: binary cross-entropy on engagement, ListMLE for ranking"),
              tags$li("Cold start handling using content-based embeddings, not 'show random popular content'"),
              tags$li("Online learning or retraining strategy — not just a deployed static model")
            )
          )
        )
      )
    ),
    fluidRow(
      box(title="Not Capitalising on Interviewer Signals", status="warning", solidHeader=TRUE, width=6,
        div(class="growth-card",
          tags$h4("Missed Opportunities to Engage"),
          tags$p("The interviewer tried to give engagement signals — hints that a particular direction would be valuable. These signals were acknowledged but not explored."),
          tags$p(tags$b("Example signal:"), " Interviewer says 'interesting — how would you handle the cold start problem for new creators?'"),
          tags$p(tags$b("What was done:"), " Acknowledged it briefly and continued with the planned design."),
          tags$p(tags$b("What should be done:"), " Stop. Explore it fully. Say: 'Great point — for new creators I would use content-based embeddings from video metadata and audio/visual features via a pre-trained ViT, then transition to collaborative signals as engagement data accumulates. The threshold I would use is...'"),
          div(class="insight-card",
            tags$b("Rule:"), " Every signal from the interviewer is a free gift telling you what they want to see. Treat it as an invitation to go deep, not a distraction."
          )
        )
      ),
      box(title="Not Asking Enough Clarifying Questions", status="warning", solidHeader=TRUE, width=6,
        div(class="growth-card",
          tags$h4("Clarification Questions Are Not Optional"),
          tags$p("The interviewer noted: could have asked way more clarification questions and incorporated the provided input into the design."),
          tags$p(tags$b("Minimum clarifying questions for any design:"),
            tags$ol(
              tags$li("What is the primary success metric — watch time, completion rate, shares, DAU?"),
              tags$li("What scale — monthly active users, videos per day, peak QPS?"),
              tags$li("Latency requirement — what is the SLO for the recommendation API?"),
              tags$li("Cold start scope — how many new users and new videos per day?"),
              tags$li("Any content safety or fairness requirements I should design around?")
            )
          ),
          tags$p(tags$b("Rule:"), " Never start drawing boxes until you have asked at least 3 clarifying questions. The answers change the architecture.")
        )
      )
    ),
    fluidRow(
      box(title="Practical Note — Excalidraw", status="primary", solidHeader=TRUE, width=12,
        div(class="action-card",
          tags$h5("Do Not Delete Your Diagrams After the Interview"),
          tags$p("The recruiter mentioned: it appeared the Excalidraw content was deleted immediately after disconnecting from the video call. There is no bad intent assumed, but this is worth noting."),
          tags$p("Interviewers may reference, share, or score diagrams after the call. Leave all whiteboard content in place when you disconnect. Do not clear or close the tab."),
          div(class="insight-card",
            tags$p("This is a minor note — the recruiter was explicit that no bad intent is inferred. But it is easy to avoid: simply close the browser window rather than clearing the board.")
          )
        )
      )
    )

  )
}
ml_design_feedback_2_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("ml_design_feedback_2", 30)
  })
}
