# modules/ch10_architecture_feedback.R
# Ch. 10 — AI Engineering Architecture and User Feedback

ch10_architecture_feedback_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ch.10 — Architecture & User Feedback"),
        tags$h2("Guardrails, Routers, Caching, Agent Patterns, Monitoring · User Feedback Design"),
        div(
          span(class = "hero-badge", "Production Architecture"),
          span(class = "hero-badge", "Monitoring"),
          span(class = "hero-badge", "Feedback Loops")
        )
    ),

    tabsetPanel(
      id = ns("subtabs"), type = "tabs",

      tabPanel("📖 Theory",
        br(),
        fluidRow(
          box(title = "🏛️ Production AI Architecture — Layer by Layer", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("Router"), tags$p("Directs each request to the right model/pipeline — a simple intent classifier can route between fast/cheap and frontier/expensive paths.")),
              div(class = "framework-card", tags$h5("Guardrails"), tags$p("Input and output checks (Ch.5) implemented as an architectural layer — not embedded ad hoc in individual prompts — so policy changes don't require touching every prompt.")),
              div(class = "framework-card", tags$h5("Cache"), tags$p("Exact and semantic caching for repeated/similar requests — a major cost lever at scale, especially for common sub-tasks.")),
              div(class = "framework-card", tags$h5("Agent patterns"), tags$p("Orchestrator-worker, plan-and-execute, and reflection patterns for structuring multi-step agent behaviour reliably.")),
              jobfit_box("This is the architectural blueprint the JD's 'set the technical bar... across the organisation' bullet is really about — being able to sketch this layered architecture live is a strong signal.",
                         c("Architecture Diagram", "Production Bar"))
          ),

          box(title = "📡 Monitoring & Observability", status = "info", solidHeader = TRUE, width = 6,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Signal"), tags$th("What It Catches"))),
                tags$tbody(
                  tags$tr(tags$td(tags$span(class="stage-pill","Quality drift")), tags$td("Eval scores on sampled live traffic degrading over time (model updates, distribution shift)")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Latency/cost")), tags$td("p50/p99 latency and $/request trending against SLOs and budget")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Guardrail trigger rate")), tags$td("Spikes may indicate an attack pattern (Ch.5) or a genuine new failure mode")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Agent loop/abandon rate")), tags$td("How often multi-step tasks fail to complete or get stuck — direct proxy for reliability")),
                  tags$tr(tags$td(tags$span(class="stage-pill","User correction rate")), tags$td("How often users edit/reject assistant output — cheapest, richest feedback signal"))
                )
              ),
              div(class = "tip-box", HTML("<strong>💡 A1 metric:</strong> 'time saved vs. manual completion' is the closest production proxy for the JD's stated >90% time-reduction goal — track it per workflow type, not just in aggregate."))
          )
        ),

        fluidRow(
          box(title = "🔁 User Feedback Design", status = "warning", solidHeader = TRUE, width = 12,
              fluidRow(
                column(3, div(class="chapter-card", div(class="chapter-num","EXPLICIT"), div(class="chapter-title","Thumbs up/down, edits"), div(class="chapter-desc","Direct but low-volume — users rarely bother unless friction is near-zero."))),
                column(3, div(class="chapter-card", div(class="chapter-num","IMPLICIT"), div(class="chapter-title","Accept/reject/edit actions"), div(class="chapter-desc","High-volume, passive signal — did the user keep the drafted reply as-is, or rewrite it?"))),
                column(3, div(class="chapter-card", div(class="chapter-num","BEHAVIORAL"), div(class="chapter-title","Task completion / abandonment"), div(class="chapter-desc","Did the multi-step workflow finish, or did the user take over manually?"))),
                column(3, div(class="chapter-card", div(class="chapter-num","LOOP"), div(class="chapter-title","Feed back into data (Ch.8) & eval (Ch.3/4)"), div(class="chapter-desc","Every signal type should route into either the eval set or the finetuning/distillation pipeline.")))
              )
          )
        )
      ),

      tabPanel("🎯 A1 Use Case Deep-Dive",
        br(),
        fluidRow(
          box(title = "📌 Use Case: A1's Full Production Architecture, End to End", status = "primary", solidHeader = TRUE, width = 12,
              div(class = "success-box", HTML("<strong>This tab pulls every earlier chapter's use case into one system diagram</strong> — the answer to \"design A1's assistant\" as it would actually be drawn on a whiteboard.")),

              div(class = "section-heading", "1. Request flow — a single user turn, end to end"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("#"), tags$th("Component"), tags$th("Function"), tags$th("Chapter Reference"))),
                tags$tbody(
                  tags$tr(tags$td("1"), tags$td(tags$b("Input guardrail")), tags$td("Scan incoming content (user message + any retrieved email/note) for injection patterns"), tags$td("Ch.5")),
                  tags$tr(tags$td("2"), tags$td(tags$b("Router")), tags$td("Classify intent; decide which downstream pipeline handles this request"), tags$td("Ch.2, Ch.9")),
                  tags$tr(tags$td("3"), tags$td(tags$b("Memory read")), tags$td("Pull relevant working/episodic/semantic memory into context, scoped to this task"), tags$td("Ch.6")),
                  tags$tr(tags$td("4"), tags$td(tags$b("Cache check")), tags$td("Semantic cache lookup for near-identical recent requests before generating"), tags$td("Ch.9, Ch.10")),
                  tags$tr(tags$td("5"), tags$td(tags$b("Planner")), tags$td("For multi-step tasks, generate a structured plan object"), tags$td("Ch.6")),
                  tags$tr(tags$td("6"), tags$td(tags$b("Agent executor")), tags$td("Execute plan steps, calling tools; re-plan on failure rather than restart"), tags$td("Ch.6")),
                  tags$tr(tags$td("7"), tags$td(tags$b("Action guardrail")), tags$td("Gate irreversible/external tool calls behind explicit user confirmation"), tags$td("Ch.5")),
                  tags$tr(tags$td("8"), tags$td(tags$b("Output guardrail")), tags$td("Scan generated content for leaked secrets/unsafe content before returning"), tags$td("Ch.5, Ch.10")),
                  tags$tr(tags$td("9"), tags$td(tags$b("Memory write")), tags$td("Persist relevant outcome to episodic/semantic/procedural memory"), tags$td("Ch.6")),
                  tags$tr(tags$td("10"), tags$td(tags$b("Feedback capture")), tags$td("Log implicit signal (accept/edit/discard) tied to this interaction"), tags$td("Ch.8, Ch.10"))
                )
              ),

              div(class = "section-heading", "2. Monitoring dashboard — the 5 metrics a VP of Research would actually watch daily"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Metric"), tags$th("Why It's Top-5"), tags$th("Alert Condition"))),
                tags$tbody(
                  tags$tr(tags$td("Eval rubric score on sampled live traffic (per dimension)"), tags$td("Direct proxy for output quality, not just uptime"), tags$td("Any single dimension drops >X% week over week")),
                  tags$tr(tags$td("Task completion rate by workflow type"), tags$td("Direct proxy for the >90% time-reduction promise"), tags$td("Completion rate for any workflow type drops below baseline")),
                  tags$tr(tags$td("Guardrail trigger rate (input + action)"), tags$td("Early warning for both attacks and new legitimate edge cases"), tags$td("Sudden spike, especially concentrated on one user/pattern")),
                  tags$tr(tags$td("User correction/edit rate on drafts"), tags$td("Cheapest, richest continuous quality signal"), tags$td("Sustained upward trend, not just a single bad day")),
                  tags$tr(tags$td("p95 latency by workflow type"), tags$td("Reliability as users actually experience it"), tags$td("Breach of the Ch.9 per-workflow-type budget"))
                )
              ),

              div(class = "section-heading", "3. Feedback loop closing the system"),
              div(class = "tip-box", HTML("<strong>💡 The loop:</strong> feedback capture (component 10) → curated into the Ch.8 dataset → refines the Ch.3 eval rubric AND the Ch.7 finetuning data → both feed back into components 2, 5, and 6 (better routing, tighter guardrails, better planning) → measured again by the same monitoring dashboard. This is what makes the system get better with usage rather than staying static after launch.")),

              div(class = "section-heading", "4. Where this differs from a naive single-model chatbot architecture"),
              div(class = "warn-box", HTML("<strong>⚠️ Naive version:</strong> one model call, no memory tiering, no action guardrails, no structured feedback capture — works for a demo, breaks down exactly on the JD's stated requirements: reliability, long-running workflows, and non-deterministic behaviour at scale.")),

              div(class = "info-box-plain", HTML("<strong>🗣️ Interview talking point:</strong> \"I'd draw this as a 10-component pipeline, not a single model call — router and guardrails at the edges, memory read/write and planning in the middle, with every interaction feeding a dataset that improves the eval rubric and the narrow finetuned models over time. The five metrics I'd actually watch daily are eval score by dimension, task completion by workflow type, guardrail trigger rate, correction rate, and p95 latency by workflow type — because together they catch quality drift, reliability regressions, and security issues before users report them.\""))
          )
        )
      ),

      tabPanel("✍️ Practice",
        br(),
        fluidRow(
          box(title = "Practice: Sketch A1's Production Architecture", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                       selectInput(ns("scenario"), "Choose a focus for your sketch:",
                                   choices = c("End-to-end architecture for one user request", "Guardrail layer placement across the pipeline",
                                               "Monitoring dashboard — what 5 metrics matter most", "Feedback loop from user correction to model improvement")),
                       sliderInput(ns("confidence"), "Confidence (1–10):", 1, 10, 5),
                       actionButton(ns("save_btn"), "Save Assessment", class = "btn-meta", width = "100%")
                ),
                column(8,
                       div(class = "practice-area",
                           tags$b("Sketch the components and how data/requests flow between them."),
                           textAreaInput(ns("notes"), label = NULL, rows = 9, width = "100%",
                                         placeholder = "## Components (router / guardrails / cache / agent / memory / model)\n\n## Flow — how a request moves through them\n\n## Where feedback and monitoring hook in"),
                           uiOutput(ns("feedback"))
                       )
                )
              )
          )
        )
      )
    )
  )
}

ch10_architecture_feedback_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_btn, {
      notes <- input$notes
      conf  <- input$confidence
      score <- 0
      if (grepl("router|guardrail|cache|agent|architecture", notes, ignore.case = TRUE)) score <- score + 30
      if (grepl("flow|request|pipeline|step", notes, ignore.case = TRUE)) score <- score + 30
      if (grepl("feedback|monitor|metric|log", notes, ignore.case = TRUE)) score <- score + 40

      prep_manager$update_progress("ch10_architecture_feedback", min(score + conf * 2, 100))
      prep_manager$save_note("ch10_notes", notes)
      prep_manager$add_practice_score("ch10_architecture_feedback", score, input$scenario)

      output$feedback <- renderUI({
        div(class = if (score >= 70) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            if (score < 100) tags$p("A complete architecture sketch names the components, the request flow between them, AND where monitoring/feedback hooks in — this ties together every earlier chapter into one whiteboard answer.")
        )
      })
      showNotification("Saved!", type = "message")
    })
  })
}
