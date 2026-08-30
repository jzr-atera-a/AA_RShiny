# modules/ch01_intro.R
# Ch. 1 — Introduction to Building AI Applications with Foundation Models

ch01_intro_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ch.1 — Introduction to AI Engineering"),
        tags$h2("The Rise of AI Engineering · Use Cases · Planning AI Applications · The AI Engineering Stack"),
        div(
          span(class = "hero-badge", "From ML Eng to AI Eng"),
          span(class = "hero-badge", "Foundation Model Use Cases"),
          span(class = "hero-badge", "The Stack")
        )
    ),

    tabsetPanel(
      id = ns("subtabs"), type = "tabs",

      # ══════════════════════════════════════════════════════════ THEORY
      tabPanel("📖 Theory",
        br(),
        fluidRow(
          box(title = "🚀 What Changed: ML Engineering → AI Engineering", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("From training to adapting"),
                  tags$p("Traditional ML engineering centres on training models from scratch on task-specific data. AI engineering centres on adapting general-purpose foundation models — via prompting, RAG, or finetuning — to a product's specific need, with far less (or no) model training required.")),
              div(class = "framework-card",
                  tags$h5("New bottleneck: the application layer"),
                  tags$p("With the model itself increasingly commoditised (open weights, APIs), the differentiating engineering work shifts to evaluation, data, prompting, orchestration, and guardrails — the layers wrapped around the model.")),
              div(class = "framework-card",
                  tags$h5("Faster iteration, higher ambiguity"),
                  tags$p("Applications can ship in days instead of months, but correctness is harder to pin down: outputs are open-ended and non-deterministic, so \"is it working?\" becomes the central, recurring engineering question.")),
              jobfit_box("A1's whole pitch is an application built on foundation models, not a from-scratch model shop — this chapter's framing (adapt, don't necessarily train) is exactly the judgment call the JD wants: \"decide when to design new architectures versus adapting or leveraging frontier models.\"",
                         c("Build vs Adapt", "Application Layer"))
          ),

          box(title = "🧱 The AI Engineering Stack", status = "info", solidHeader = TRUE, width = 6,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Layer"), tags$th("What Lives Here"), tags$th("A1 Relevance"))),
                tags$tbody(
                  tags$tr(tags$td(tags$span(class="stage-pill","Application Development")), tags$td("Prompting, context construction, RAG, agent orchestration, UX around the assistant"), tags$td("Where the smart-assistant product logic lives")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Model Development")), tags$td("Model selection, finetuning, dataset engineering, inference optimization"), tags$td("Build-vs-buy decisions land here")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Infrastructure")), tags$td("Serving, accelerators, monitoring, evaluation pipelines, guardrail systems"), tags$td("Reliability at scale for long-running workflows"))
                )
              ),
              div(class = "tip-box", HTML("<strong>💡 Interview framing:</strong> Most candidates default to talking model architecture. Strong candidates for this role talk about the application layer first — because that's where a proactive assistant's reliability actually gets won or lost.")),
              div(class = "section-heading-dark", "Common Foundation Model Use Case Patterns"),
              tags$ul(
                tags$li("Coding / agentic tool use — directly analogous to A1's \"interact with external tools\""),
                tags$li("Conversational assistants & customer support — the core of A1's product"),
                tags$li("Information aggregation & summarisation — errands, organising, workflows"),
                tags$li("Writing & content generation — drafting emails, notes, task descriptions")
              )
          )
        ),

        fluidRow(
          box(title = "🗺️ Planning an AI Application — Checklist", status = "warning", solidHeader = TRUE, width = 12,
              fluidRow(
                column(3, div(class = "chapter-card", div(class="chapter-num","STEP 1"), div(class="chapter-title","Use case & success metric"), div(class="chapter-desc","What task, for whom, measured how? A1: >90% time reduction on daily tasks."))),
                column(3, div(class = "chapter-card", div(class="chapter-num","STEP 2"), div(class="chapter-title","Set a milestone / MVP"), div(class="chapter-desc","Smallest reliable slice of the workflow — not full autonomy on day one."))),
                column(3, div(class = "chapter-card", div(class="chapter-num","STEP 3"), div(class="chapter-title","Maintain a human-in-the-loop path"), div(class="chapter-desc","Escalation / confirmation for high-stakes or irreversible actions."))),
                column(3, div(class = "chapter-card", div(class="chapter-num","STEP 4"), div(class="chapter-title","Design for iteration"), div(class="chapter-desc","Feedback loops, logging, evaluation from day one — not bolted on later.")))
              )
          )
        )
      ),

      # ══════════════════════════════════════════════════ A1 USE CASE DEEP-DIVE
      tabPanel("🎯 A1 Use Case Deep-Dive",
        br(),
        fluidRow(
          box(title = "📌 Use Case: MVP Scoping for A1's Assistant — \"Inbox Triage & Auto-Draft\"", status = "primary", solidHeader = TRUE, width = 12,
              div(class = "success-box", HTML("<strong>Why this is the right first slice:</strong> email triage is high-frequency (many touches/day), low-irreversibility (a draft is always reviewable before sending), and has a natural ground-truth signal (did the user send the draft as-is, edit it, or discard it) — ideal for the eval + feedback loop A1 needs to build early.")),

              div(class = "section-heading", "1. Business objective → ML/product objective"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Layer"), tags$th("Statement"))),
                tags$tbody(
                  tags$tr(tags$td("Business goal"), tags$td("Reduce time users spend on daily inbox/task admin by >90%")),
                  tags$tr(tags$td("Product objective"), tags$td("Assistant reads incoming email/notes, drafts a reply or extracts a task, with minimal user prompting")),
                  tags$tr(tags$td("Engineering objective"), tags$td("Maximise (draft accepted as-is + draft accepted with light edit), minimise (draft discarded + user reports it as wrong/unsafe)")),
                  tags$tr(tags$td("Constraints"), tags$td("p95 draft-ready latency < 8s; never auto-send without confirmation in MVP; PII must not leave the user's own data boundary unnecessarily"))
                )
              ),

              div(class = "section-heading", "2. MVP scope — what's IN vs OUT"),
              fluidRow(
                column(6, div(class="framework-card", tags$h5("In scope (v0)"), tags$ul(
                  tags$li("Single-turn reply drafting for direct, unambiguous emails"),
                  tags$li("Task extraction into a simple task list (no calendar writes yet)"),
                  tags$li("User always reviews/edits/approves before send — no autonomous sending"),
                  tags$li("English-language, single mailbox account")
                ))),
                column(6, div(class="framework-card", tags$h5("Explicitly out of scope (v0)"), tags$ul(
                  tags$li("Multi-step negotiation threads (scheduling back-and-forth) — defer to Ch.6 agent design"),
                  tags$li("Autonomous sending without confirmation"),
                  tags$li("Cross-account / cross-tool orchestration (calendar + email + task app together)"),
                  tags$li("Non-English support")
                )))
              ),

              div(class = "section-heading", "3. Stack-layer breakdown for this use case"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Stack Layer"), tags$th("Concrete v0 Implementation"))),
                tags$tbody(
                  tags$tr(tags$td(tags$span(class="stage-pill","Application")), tags$td("Prompt template that ingests thread history + user's writing-style samples; structured output = {draft_text, task_candidates[], confidence}")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Model")), tags$td("Frontier API model for drafting (quality-sensitive, low volume relative to routing); no finetuning yet — style is handled via few-shot examples of the user's own past sent emails")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Infrastructure")), tags$td("Simple synchronous request/response for v0 (no agent loop yet); logging every draft + user action (accept/edit/discard) from day one for the eval set in Ch.3/4"))
                )
              ),

              div(class = "section-heading", "4. Human-in-the-loop design"),
              div(class = "warn-box", HTML("<strong>⚠️ Non-negotiable for v0:</strong> every draft is presented, never sent, until the user explicitly approves. This buys time to build the evaluation and guardrail layers (Ch.3–5) before increasing autonomy — directly addressing the JD's \"comfortable making irreversible decisions with incomplete information\" by choosing where NOT to be irreversible yet.")),

              div(class = "section-heading", "5. What \"success\" looks like after 4 weeks"),
              tags$ul(
                tags$li(tags$b("Primary metric:"), " % of drafts sent with zero or minor edits (target: establish baseline, then improve)"),
                tags$li(tags$b("Guardrail metric:"), " 0 incidents of a draft containing fabricated facts presented with high confidence"),
                tags$li(tags$b("Leading indicator:"), " draft-ready latency p95, to catch inference-layer problems before they affect adoption"),
                tags$li(tags$b("Qualitative:"), " weekly review of a sample of discarded drafts to catch systematic failure patterns early")
              ),

              div(class = "info-box-plain", HTML("<strong>🗣️ Interview talking point:</strong> \"I'd deliberately scope the MVP narrower than the full JD vision — single-turn drafting, human-approved, single mailbox — specifically so the evaluation and guardrail infrastructure exists BEFORE we grant the assistant more autonomy in multi-step workflows.\" This shows staged-autonomy thinking, which is exactly what a reliability-focused VP of Research role is testing for."))
          )
        )
      ),

      # ══════════════════════════════════════════════════════════ PRACTICE
      tabPanel("✍️ Practice",
        br(),
        fluidRow(
          box(title = "Practice: Frame A1's Assistant as an AI Engineering Problem", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                       selectInput(ns("scenario"), "Choose a workflow to plan:",
                                   choices = c("Inbox triage & auto-drafted replies", "Multi-step errand (book + confirm + reschedule)",
                                               "Note-taking → task extraction → calendar sync", "Long-running project tracking across tools")),
                       sliderInput(ns("confidence"), "Confidence in your plan (1–10):", 1, 10, 5),
                       actionButton(ns("save_btn"), "Save Assessment", class = "btn-meta", width = "100%")
                ),
                column(8,
                       div(class = "practice-area",
                           tags$b("Sketch: use case → success metric → MVP slice → human-in-the-loop path → stack layer breakdown."),
                           textAreaInput(ns("notes"), label = NULL, rows = 9, width = "100%",
                                         placeholder = "## Use case & metric\n\n## MVP slice\n\n## Human-in-the-loop / escalation\n\n## Stack layers touched (app / model / infra)"),
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

ch01_intro_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_btn, {
      notes <- input$notes
      conf  <- input$confidence
      score <- 0
      if (grepl("metric|success|measure", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("mvp|slice|milestone|minimal", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("human|escalat|confirm|loop", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("stack|layer|application|model|infra", notes, ignore.case = TRUE)) score <- score + 25

      prep_manager$update_progress("ch01_intro", min(score + conf * 3, 100))
      prep_manager$save_note("ch01_notes", notes)
      prep_manager$add_practice_score("ch01_intro", score, input$scenario)

      output$feedback <- renderUI({
        div(class = if (score >= 75) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            if (score < 25) tags$p("⚠️ Add a concrete success metric."),
            if (score < 50) tags$p("⚠️ Define a minimal MVP slice, not the full workflow."),
            if (score < 75) tags$p("⚠️ Add a human-in-the-loop / escalation path."),
            if (score >= 100) tags$p("✅ Full plan covered — good scaffolding for a design interview answer.")
        )
      })
      showNotification("Saved!", type = "message")
    })
  })
}
