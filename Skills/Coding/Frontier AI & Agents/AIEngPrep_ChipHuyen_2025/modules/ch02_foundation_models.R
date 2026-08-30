# modules/ch02_foundation_models.R
# Ch. 2 — Understanding Foundation Models

ch02_foundation_models_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ch.2 — Understanding Foundation Models"),
        tags$h2("Training Data · Architecture & Scale · Post-Training · Sampling · The Probabilistic Nature of AI"),
        div(
          span(class = "hero-badge", "Transformers & MoE"),
          span(class = "hero-badge", "RLHF / DPO"),
          span(class = "hero-badge", "Sampling & Temperature"),
          span(class = "hero-badge", "Non-determinism")
        )
    ),

    tabsetPanel(
      id = ns("subtabs"), type = "tabs",

      tabPanel("📖 Theory",
        br(),
        fluidRow(
          box(title = "🧬 Training Pipeline: Pretraining → Post-training", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Pretraining"),
                  tags$p("Self-supervised next-token prediction over massive, broad corpora. Produces a raw base model — strong pattern completion, weak instruction-following.")),
              div(class = "framework-card",
                  tags$h5("Supervised Finetuning (SFT)"),
                  tags$p("Trains the base model on curated instruction-response pairs to make it follow instructions and adopt a consistent conversational format.")),
              div(class = "framework-card",
                  tags$h5("Preference finetuning (RLHF / DPO)"),
                  tags$p("Aligns outputs to human preference — helpfulness, harmlessness, honesty — using reward models or direct preference optimization. This is where a lot of \"alignment\" work concretely happens.")),
              jobfit_box("Architecture and MoE decisions (Ch.2) feed directly into the JD's build-vs-buy ask — knowing when scaling laws / MoE sparsity favour adapting a frontier model vs. training bespoke components is exactly the technical judgment being screened for.",
                         c("MoE", "Scaling Laws", "Build vs Buy"))
          ),

          box(title = "🎲 Sampling & the Probabilistic Nature of AI", status = "info", solidHeader = TRUE, width = 6,
              div(class = "section-heading-dark", "Key sampling levers"),
              tags$ul(
                tags$li(tags$b("Temperature:"), " scales logits before softmax — low = deterministic/greedy-like, high = more diverse/riskier."),
                tags$li(tags$b("Top-k / top-p (nucleus):"), " restrict the candidate pool so low-probability, low-quality tokens are excluded."),
                tags$li(tags$b("Greedy / beam search:"), " deterministic decoding strategies, generally more consistent but less creative.")
              ),
              div(class = "warn-box",
                  HTML("<strong>⚠️ Engineering implication:</strong> the same prompt can yield different outputs across calls. Systems that assume determinism (retries assuming identical results, strict output parsing) will silently break in production.")),
              div(class = "success-box",
                  HTML("<strong>✅ Mitigations:</strong> structured/constrained decoding, lower temperature for tool-calling steps, output validators + automatic retries, and treating variance itself as a monitored metric — not just accuracy.")),
              div(class = "tip-box",
                  HTML("<strong>💡 A1 angle:</strong> \"reliability despite non-deterministic model behaviour\" in the JD is a near-verbatim reference to this chapter's core theme."))
          )
        ),

        fluidRow(
          box(title = "⚖️ Architecture / Scale Decision Table", status = "warning", solidHeader = TRUE, width = 12,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Decision"), tags$th("Favor Frontier API"), tags$th("Favor Own/Adapted Model"))),
                tags$tbody(
                  tags$tr(tags$td("Latency/cost at massive scale"), tags$td("Low volume, prototyping fast"), tags$td("High volume — distillation/smaller model amortizes cost")),
                  tags$tr(tags$td("Data sensitivity"), tags$td("Vendor has adequate data controls"), tags$td("Strict privacy/on-prem/regulatory requirement")),
                  tags$tr(tags$td("Capability ceiling needed"), tags$td("Need frontier reasoning/multimodality now"), tags$td("Narrow task — smaller finetuned/distilled model suffices")),
                  tags$tr(tags$td("Team & timeline"), tags$td("Small team, need to ship this quarter"), tags$td("Research-heavy team, long-horizon differentiation bet"))
                )
              )
          )
        )
      ),

      tabPanel("🎯 A1 Use Case Deep-Dive",
        br(),
        fluidRow(
          box(title = "📌 Use Case: Model & Sampling Configuration Across A1's Assistant Pipeline", status = "primary", solidHeader = TRUE, width = 12,
              div(class = "success-box", HTML("<strong>Core insight for A1:</strong> a proactive assistant is NOT one model call — it's a pipeline of distinct sub-tasks (intent routing, planning, drafting, tool-argument generation, safety checks), each with a different optimal model AND a different optimal sampling configuration. Treating it as \"pick one model\" is the single most common design mistake.")),

              div(class = "section-heading", "1. Per-stage model & sampling configuration"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Pipeline Stage"), tags$th("Model Tier"), tags$th("Temperature"), tags$th("Decoding"), tags$th("Rationale"))),
                tags$tbody(
                  tags$tr(tags$td("Intent routing (classify request type)"), tags$td(tags$span(class="badge-green","Small/distilled")), tags$td("~0.0–0.1"), tags$td("Greedy / constrained to fixed label set"), tags$td("High volume, narrow output space — determinism and cost matter far more than creativity")),
                  tags$tr(tags$td("Planning (decompose multi-step task)"), tags$td(tags$span(class="badge-red","Frontier")), tags$td("~0.2–0.4"), tags$td("Structured JSON plan output"), tags$td("Needs strong reasoning; low-but-nonzero temperature avoids brittle single-path plans")),
                  tags$tr(tags$td("Draft generation (email/message text)"), tags$td(tags$span(class="badge-amber","Frontier or strong open-weight")), tags$td("~0.6–0.8"), tags$td("Free-form text"), tags$td("Quality and natural tone matter; some variety is desirable across drafts")),
                  tags$tr(tags$td("Tool-argument generation (e.g. calendar API call)"), tags$td(tags$span(class="badge-green","Small/distilled")), tags$td("~0.0"), tags$td("Constrained/schema-validated decoding"), tags$td("Must be deterministic and schema-valid — a malformed argument breaks the tool call")),
                  tags$tr(tags$td("Safety/guardrail check"), tags$td(tags$span(class="badge-green","Small/distilled classifier")), tags$td("~0.0"), tags$td("Greedy, binary/scored output"), tags$td("Needs to be fast, cheap, and consistent — run on every step"))
                )
              ),

              div(class = "section-heading", "2. Why NOT one frontier model for everything"),
              fluidRow(
                column(6, div(class="framework-card", tags$h5("Cost"), tags$p("Routing and tool-argument generation happen far more often than drafting or planning per user session — routing everything through a frontier model multiplies cost for the highest-volume, lowest-complexity steps."))),
                column(6, div(class="framework-card", tags$h5("Reliability"), tags$p("Tool-argument generation needs schema-valid, near-deterministic output. High-temperature frontier generation here increases malformed-call rate — exactly the kind of failure that breaks a multi-step workflow.")))
              ),

              div(class = "section-heading", "3. Handling non-determinism where it can't be removed"),
              tags$ul(
                tags$li(tags$b("Draft generation:"), " non-determinism is acceptable (even desirable) since a human reviews before send — no mitigation needed beyond quality eval."),
                tags$li(tags$b("Planning:"), " log the full plan object; if a downstream step fails, re-plan from the failure point rather than silently retrying the entire chain (Ch.6 failure-mode handling)."),
                tags$li(tags$b("Tool-argument generation:"), " validate against the tool's schema before execution; on validation failure, retry once with an explicit error message injected into context, then escalate to the user rather than looping.")
              ),

              div(class = "info-box-plain", HTML("<strong>🗣️ Interview talking point:</strong> \"I'd design A1's pipeline as heterogeneous by stage — not a single model choice. Routing and tool-calls get small, cheap, near-deterministic models; planning and drafting get frontier capability. That's the concrete version of 'decide when to design new architectures vs. adapt frontier models' — the answer differs stage by stage within the same product.\""))
          )
        )
      ),

      tabPanel("✍️ Practice",
        br(),
        fluidRow(
          box(title = "Practice: Explain Non-Determinism to a Non-Technical Stakeholder", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                       selectInput(ns("scenario"), "Choose a stakeholder scenario:",
                                   choices = c("PM asks why the assistant gave two different answers to the same request",
                                               "Exec asks if we can 'just fix' hallucinations with a bigger model",
                                               "Support lead asks why retries sometimes make things worse")),
                       sliderInput(ns("confidence"), "Confidence (1–10):", 1, 10, 5),
                       actionButton(ns("save_btn"), "Save Assessment", class = "btn-meta", width = "100%")
                ),
                column(8,
                       div(class = "practice-area",
                           tags$b("Draft a plain-language explanation plus one concrete engineering mitigation."),
                           textAreaInput(ns("notes"), label = NULL, rows = 8, width = "100%",
                                         placeholder = "## Plain-language explanation of why outputs vary\n\n## Concrete mitigation (sampling, validation, retries, etc.)\n\n## What you would still tell them to expect"),
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

ch02_foundation_models_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_btn, {
      notes <- input$notes
      conf  <- input$confidence
      score <- 0
      if (grepl("probabilist|sampl|temperature|token|distribution", notes, ignore.case = TRUE)) score <- score + 30
      if (grepl("mitigat|retry|valid|guardrail|constrain|lower temp", notes, ignore.case = TRUE)) score <- score + 40
      if (grepl("expect|monitor|variance|manage", notes, ignore.case = TRUE)) score <- score + 30

      prep_manager$update_progress("ch02_foundation_models", min(score + conf * 2, 100))
      prep_manager$save_note("ch02_notes", notes)
      prep_manager$add_practice_score("ch02_foundation_models", score, input$scenario)

      output$feedback <- renderUI({
        div(class = if (score >= 70) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            if (score < 30) tags$p("⚠️ Ground the explanation in sampling/probabilistic generation, not just 'AI is unpredictable.'"),
            if (score < 70) tags$p("⚠️ Add a concrete engineering mitigation, not just an explanation."),
            if (score >= 70) tags$p("✅ Clear explanation + mitigation — this is the shape interviewers want.")
        )
      })
      showNotification("Saved!", type = "message")
    })
  })
}
