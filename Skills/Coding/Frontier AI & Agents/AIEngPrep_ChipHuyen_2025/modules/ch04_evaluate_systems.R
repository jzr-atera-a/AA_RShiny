# modules/ch04_evaluate_systems.R
# Ch. 4 — Evaluate AI Systems (Evaluation Criteria, Model Selection, Pipeline Design)

ch04_evaluate_systems_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ch.4 — Evaluate AI Systems"),
        tags$h2("Evaluation Criteria · Model Selection (Build vs. Buy) · Designing the Evaluation Pipeline"),
        div(
          span(class = "hero-badge", "Build vs Buy"),
          span(class = "hero-badge", "System-Level Eval"),
          span(class = "hero-badge", "Pipeline Design")
        )
    ),

    tabsetPanel(
      id = ns("subtabs"), type = "tabs",

      tabPanel("📖 Theory",
        br(),
        fluidRow(
          box(title = "🏗️ Build vs. Buy — The Core Decision Framework", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "success-box", HTML("<strong>Huyen's framing:</strong> model selection is not one decision — it's a sequence: (1) hard filters (cost, license, data residency), (2) soft filters (quality on your task via eval), (3) ongoing re-evaluation as new models ship.")),
              div(class = "framework-card", tags$h5("Hard constraints first"), tags$p("Latency SLO, cost per request at expected volume, data privacy/regulatory requirements, and licensing eliminate candidates before quality comparison even starts.")),
              div(class = "framework-card", tags$h5("Then quality, on your task"), tags$p("Run your own eval pipeline (Ch.3 methods) on YOUR data/tasks — public leaderboard rank is a weak proxy once hard filters are applied.")),
              div(class = "framework-card", tags$h5("Build is rarely 'from scratch'"), tags$p("In practice 'build' usually means adapting an open-weight model (finetuning, distillation) rather than pretraining — full pretraining is reserved for cases with a durable, structural advantage.")),
              jobfit_box("This chapter IS the JD bullet 'decide when to design new model architectures versus adapting or leveraging frontier open-source or commercial models' — expect a live build-vs-buy exercise in interview.",
                         c("Model Selection", "Hard Filters"))
          ),

          box(title = "📊 Model Selection Scorecard (Example)", status = "info", solidHeader = TRUE, width = 6,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Criterion"), tags$th("Frontier API"), tags$th("Open-Weight + Finetune"), tags$th("Custom Architecture"))),
                tags$tbody(
                  tags$tr(tags$td("Time to first version"), tags$td(tags$span(class="badge-green","Fast")), tags$td(tags$span(class="badge-amber","Medium")), tags$td(tags$span(class="badge-red","Slow"))),
                  tags$tr(tags$td("Marginal cost at scale"), tags$td(tags$span(class="badge-red","High")), tags$td(tags$span(class="badge-amber","Medium")), tags$td(tags$span(class="badge-green","Low (if amortized)"))),
                  tags$tr(tags$td("Data control / privacy"), tags$td(tags$span(class="badge-red","Low")), tags$td(tags$span(class="badge-green","High")), tags$td(tags$span(class="badge-green","High"))),
                  tags$tr(tags$td("Ceiling capability"), tags$td(tags$span(class="badge-green","Highest")), tags$td(tags$span(class="badge-amber","Task-dependent")), tags$td(tags$span(class="badge-amber","Task-dependent"))),
                  tags$tr(tags$td("Team / research investment needed"), tags$td(tags$span(class="badge-green","Low")), tags$td(tags$span(class="badge-amber","Medium")), tags$td(tags$span(class="badge-red","High")))
                )
              ),
              div(class = "tip-box", HTML("<strong>💡 A1-specific read:</strong> a young, high-density startup team most plausibly runs a hybrid: frontier API for ceiling capability + open-weight finetuned/distilled models for cost-sensitive, high-volume sub-tasks (e.g. routing, simple classification steps within a workflow)."))
          )
        ),

        fluidRow(
          box(title = "🔁 Designing an Evaluation Pipeline — End to End", status = "warning", solidHeader = TRUE, width = 12,
              fluidRow(
                column(3, div(class="chapter-card", div(class="chapter-num","1"), div(class="chapter-title","Define criteria & data"), div(class="chapter-desc","Rubric dimensions + a representative, versioned eval set drawn from real (or realistic synthetic) traffic."))),
                column(3, div(class="chapter-card", div(class="chapter-num","2"), div(class="chapter-title","Automate scoring"), div(class="chapter-desc","Exact-match / functional checks where possible; AI-as-judge calibrated against humans elsewhere."))),
                column(3, div(class="chapter-card", div(class="chapter-num","3"), div(class="chapter-title","Wire into CI/CD"), div(class="chapter-desc","Every prompt/model/pipeline change runs the eval suite before shipping — regression gate, not a one-off report."))),
                column(3, div(class="chapter-card", div(class="chapter-num","4"), div(class="chapter-title","Monitor in production"), div(class="chapter-desc","Sample live traffic, track drift in scores over time, feed failures back into the eval set (closes the loop with Ch.10 user feedback).")))
              )
          )
        )
      ),

      tabPanel("🎯 A1 Use Case Deep-Dive",
        br(),
        fluidRow(
          box(title = "📌 Use Case: The A1 Model Stack — A Full Build-vs-Buy Walkthrough", status = "primary", solidHeader = TRUE, width = 12,
              div(class = "success-box", HTML("<strong>Scenario:</strong> A1 needs to decide, per pipeline stage (from Ch.2's stage breakdown), whether to use a frontier API, an open-weight finetuned/distilled model, or — almost never at this stage of the company — a custom-trained architecture.")),

              div(class = "section-heading", "1. Hard filters applied first, per stage"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Stage"), tags$th("Latency SLO"), tags$th("Volume"), tags$th("Data sensitivity"), tags$th("Survives hard filter as")) ),
                tags$tbody(
                  tags$tr(tags$td("Intent routing"), tags$td("< 300ms"), tags$td("Very high"), tags$td("Medium (sees raw content)"), tags$td("Small open-weight, self-hosted or low-cost API only")),
                  tags$tr(tags$td("Planning"), tags$td("< 3s"), tags$td("Medium"), tags$td("Medium"), tags$td("Frontier API or strong open-weight — both survive")),
                  tags$tr(tags$td("Draft generation"), tags$td("< 8s"), tags$td("Medium"), tags$td("High (full email content)"), tags$td("Any option surviving A1's data-handling policy for the vendor")),
                  tags$tr(tags$td("Tool-argument generation"), tags$td("< 500ms"), tags$td("Very high"), tags$td("Low (structured, minimal)"), tags$td("Small open-weight — cost dominates at this volume")),
                  tags$tr(tags$td("Safety/guardrail check"), tags$td("< 200ms"), tags$td("Every step, so highest volume"), tags$td("Sees everything"), tags$td("Small, self-hostable classifier — latency and volume rule out frontier API"))
                )
              ),

              div(class = "section-heading", "2. Quality-on-task evaluation plan (survives-the-filter candidates only)"),
              tags$ol(
                tags$li("Build a per-stage eval set from real (anonymised) A1 traffic — reuse the Ch.3 rubric methodology, but a separate rubric per stage (e.g. routing = classification accuracy; drafting = the 5-dimension rubric)."),
                tags$li("Run every surviving candidate model against the same eval set; report per-dimension scores, not an aggregate."),
                tags$li("Weight the decision by stage-specific priorities — e.g. tool-argument generation weights schema-validity near 100%, drafting weights tone/factuality highest.")
              ),

              div(class = "section-heading", "3. The actual recommended hybrid stack"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Stage"), tags$th("Recommendation"), tags$th("Justification"))),
                tags$tbody(
                  tags$tr(tags$td("Intent routing"), tags$td(tags$span(class="stage-pill","Distilled open-weight")), tags$td("Ch.8 distillation: frontier model as offline teacher, small student in production — cheap, fast, good enough for a narrow label set")),
                  tags$tr(tags$td("Planning"), tags$td(tags$span(class="stage-pill","Frontier API")), tags$td("Reasoning quality has outsized impact on downstream success; volume is low enough that cost is manageable")),
                  tags$tr(tags$td("Draft generation"), tags$td(tags$span(class="stage-pill","Frontier API")), tags$td("User-facing quality bar is highest here — the JD's product promise is won or lost on this step")),
                  tags$tr(tags$td("Tool-argument generation"), tags$td(tags$span(class="stage-pill","Small open-weight, finetuned")), tags$td("PEFT/LoRA finetuned on schema-following examples (Ch.7) — deterministic decoding, cheap, fast")),
                  tags$tr(tags$td("Safety/guardrail check"), tags$td(tags$span(class="stage-pill","Small self-hosted classifier")), tags$td("Runs on every step; must be self-hosted for latency and to avoid sending every message to a third party just to check it"))
                )
              ),

              div(class = "section-heading", "4. Re-evaluation trigger — when this decision gets revisited"),
              div(class = "tip-box", HTML("<strong>💡 Concrete trigger:</strong> re-run the full comparison whenever (a) a new frontier model ships with a meaningfully lower price point, (b) the finetuned small model's eval score on tool-argument generation drops below threshold on the rolling eval set, or (c) volume in any stage grows 5x — cost assumptions from the original decision may no longer hold.")),

              div(class = "info-box-plain", HTML("<strong>🗣️ Interview talking point:</strong> \"For A1 I wouldn't make one model-selection decision — I'd apply hard filters per pipeline stage first (latency, volume, data sensitivity), then run quality-on-task eval only on survivors. The result is a hybrid stack: distilled/finetuned open-weight models for high-volume, narrow, latency-critical steps, frontier API for the two steps where reasoning or generation quality directly drives the product's core promise.\""))
          )
        )
      ),

      tabPanel("✍️ Practice",
        br(),
        fluidRow(
          box(title = "Practice: Make the Build-vs-Buy Call", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                       selectInput(ns("scenario"), "Choose a sub-system to decide on:",
                                   choices = c("Top-level assistant reasoning/orchestration model", "Intent routing / task classification (high volume, low complexity)",
                                               "Long-context document summarisation for notes", "Safety/guardrail classifier for tool-call approval")),
                       sliderInput(ns("confidence"), "Confidence (1–10):", 1, 10, 5),
                       actionButton(ns("save_btn"), "Save Assessment", class = "btn-meta", width = "100%")
                ),
                column(8,
                       div(class = "practice-area",
                           tags$b("State your decision and justify it against hard filters, quality-on-task, and cost at scale."),
                           textAreaInput(ns("notes"), label = NULL, rows = 9, width = "100%",
                                         placeholder = "## Hard filters (cost, latency, privacy, licensing)\n\n## Quality-on-task evaluation plan\n\n## Decision: build / buy / hybrid, and why\n\n## What would change your mind"),
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

ch04_evaluate_systems_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_btn, {
      notes <- input$notes
      conf  <- input$confidence
      score <- 0
      if (grepl("cost|latency|privacy|licens|constraint", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("eval|quality|task|test|benchmark", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("decision|build|buy|hybrid|adapt", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("chang|revisit|reconsider|new model", notes, ignore.case = TRUE)) score <- score + 25

      prep_manager$update_progress("ch04_evaluate_systems", min(score + conf * 2, 100))
      prep_manager$save_note("ch04_notes", notes)
      prep_manager$add_practice_score("ch04_evaluate_systems", score, input$scenario)

      output$feedback <- renderUI({
        div(class = if (score >= 75) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            if (score < 100) tags$p("A strong build-vs-buy answer always names hard filters explicitly, then a quality-on-task eval plan, then a clear decision AND the condition under which you'd revisit it.")
        )
      })
      showNotification("Saved!", type = "message")
    })
  })
}
