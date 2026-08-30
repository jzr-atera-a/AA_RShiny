# modules/ch08_dataset_engineering.R
# Ch. 8 — Dataset Engineering

ch08_dataset_engineering_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ch.8 — Dataset Engineering"),
        tags$h2("Data Curation · Data Augmentation & Synthesis · Data Processing"),
        div(
          span(class = "hero-badge", "Curation"),
          span(class = "hero-badge", "Synthetic Data"),
          span(class = "hero-badge", "Distillation")
        )
    ),

    tabsetPanel(
      id = ns("subtabs"), type = "tabs",

      tabPanel("📖 Theory",
        br(),
        fluidRow(
          box(title = "🗂️ Data Curation Principles", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("Quality over quantity"), tags$p("A smaller, high-quality, diverse, well-deduplicated dataset consistently outperforms a larger noisy one for finetuning and eval-set construction.")),
              div(class = "framework-card", tags$h5("Coverage of failure modes"), tags$p("Curated eval/finetune data should deliberately include edge cases and known failure patterns — not just 'typical' happy-path examples.")),
              div(class = "framework-card", tags$h5("Deduplication and leakage control"), tags$p("Near-duplicate examples inflate apparent performance; eval data leaking into training data invalidates your evaluation entirely.")),
              jobfit_box("For A1, the highest-leverage curated dataset is the failure-case log from real agent traces — every agent failure (Ch.6) becomes a labeled example for both eval and finetuning.",
                         c("Failure-Case Curation", "Eval Integrity"))
          ),

          box(title = "🧪 Data Augmentation & Synthesis", status = "info", solidHeader = TRUE, width = 6,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Technique"), tags$th("Use Case"), tags$th("Risk"))),
                tags$tbody(
                  tags$tr(tags$td(tags$span(class="stage-pill","Model-generated synthesis")), tags$td("Bootstrap training/eval data when real examples are scarce"), tags$td("Can inherit and amplify the generating model's biases/errors")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Distillation")), tags$td("Use a strong 'teacher' model's outputs to train a smaller 'student'"), tags$td("Student inherits teacher's blind spots; licensing considerations")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Paraphrase/perturbation")), tags$td("Increase robustness to phrasing variation"), tags$td("Can create near-duplicates if not filtered")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Back-translation")), tags$td("Diversify phrasing while preserving meaning"), tags$td("Quality depends on translation model fidelity"))
                )
              ),
              div(class = "tip-box", HTML("<strong>💡 A1 angle:</strong> distillation (Ch.8) is one of the JD's named frontier techniques — a plausible A1 architecture is a frontier 'teacher' model used offline to generate training signal for smaller, cheaper 'student' models running the high-volume sub-tasks in production."))
          )
        ),

        fluidRow(
          box(title = "⚙️ Data Processing Pipeline", status = "warning", solidHeader = TRUE, width = 12,
              fluidRow(
                column(3, div(class="chapter-card", div(class="chapter-num","1"), div(class="chapter-title","Collect"), div(class="chapter-desc","Logging from real usage, with consent/privacy controls baked in from day one."))),
                column(3, div(class="chapter-card", div(class="chapter-num","2"), div(class="chapter-title","Clean & filter"), div(class="chapter-desc","Remove PII, low-quality/malformed examples, and near-duplicates."))),
                column(3, div(class="chapter-card", div(class="chapter-num","3"), div(class="chapter-title","Label / annotate"), div(class="chapter-desc","Human labels for ground truth on ambiguous cases; AI-assisted labeling for scale."))),
                column(3, div(class="chapter-card", div(class="chapter-num","4"), div(class="chapter-title","Version & split"), div(class="chapter-desc","Track dataset versions; strict train/eval separation to prevent leakage.")))
              )
          )
        )
      ),

      tabPanel("🎯 A1 Use Case Deep-Dive",
        br(),
        fluidRow(
          box(title = "📌 Use Case: A1's End-to-End Data Flywheel", status = "primary", solidHeader = TRUE, width = 12,
              div(class = "success-box", HTML("<strong>Design goal:</strong> every real interaction A1's assistant has should make the NEXT version of the assistant measurably better — turning usage itself into A1's durable moat, independent of whichever frontier model is best this quarter.")),

              div(class = "section-heading", "1. Concrete data sources at A1, mapped to what they feed"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Source"), tags$th("Signal Captured"), tags$th("Privacy Handling"), tags$th("Feeds"))),
                tags$tbody(
                  tags$tr(tags$td("Draft edits"), tags$td("Diff between AI draft and what user actually sent"), tags$td("Store diff pattern, not full content, where possible; PII-scrub before any offline use"), tags$td("Eval rubric refinement (Ch.3), drafting-prompt iteration")),
                  tags$tr(tags$td("Tool-call outcomes"), tags$td("Success/failure/schema-validity of every tool call"), tags$td("Structured metadata only, no raw content needed"), tags$td("Tool-argument model finetuning (Ch.7)")),
                  tags$tr(tags$td("Agent traces (full plan + steps)"), tags$td("Complete multi-step task execution, incl. failures/re-plans"), tags$td("Anonymised, access-controlled, retained on a defined schedule"), tags$td("Failure-mode eval set (Ch.6), planning-prompt iteration")),
                  tags$tr(tags$td("Explicit feedback (thumbs up/down)"), tags$td("Direct quality signal, low volume"), tags$td("Linked to the specific output only"), tags$td("Judge calibration (Ch.3), qualitative failure review")),
                  tags$tr(tags$td("Task completion/abandonment"), tags$td("Did the workflow finish or did the user take over manually"), tags$td("Aggregate/behavioural, minimal raw content"), tags$td("The core >90% time-reduction product metric (Ch.10)"))
                )
              ),

              div(class = "section-heading", "2. Curation pipeline for the finetuning dataset (routing + tool-args, from Ch.7)"),
              tags$ol(
                tags$li(tags$b("Collect:"), " every real routing decision and tool call, tagged with outcome (success/failure/user-correction)."),
                tags$li(tags$b("Clean:"), " strip PII from stored examples (replace names/emails/dates with typed placeholders where the exact value isn't needed for the pattern being learned); deduplicate near-identical requests."),
                tags$li(tags$b("Weight toward failures:"), " oversample failure and correction cases relative to their natural frequency — this is where the model actually learns, not from the 95% of already-correct routine cases."),
                tags$li(tags$b("Label ambiguous cases:"), " a human reviews cases where the outcome is unclear (e.g. user abandoned the task for an unrelated reason, not because the AI was wrong) before they enter the training set."),
                tags$li(tags$b("Version & split:"), " every finetuning run uses a dated dataset snapshot; the eval set (Ch.3/4) is a strictly separate, independently versioned sample — never overlapping with training data, checked programmatically before each run.")
              ),

              div(class = "section-heading", "3. Synthetic data / distillation use — filling the cold-start gap"),
              div(class = "framework-card",
                  tags$h5("Before A1 has enough real usage data"),
                  tags$p("Use a frontier 'teacher' model to generate synthetic (request → correct plan/tool-call) examples across a deliberately designed set of scenario templates (the errand types, tone variations, and edge cases product/research believe matter) — this is what makes Ch.7's finetuning possible from week one instead of waiting months for organic volume.")),
              div(class = "warn-box", HTML("<strong>⚠️ Risk to manage:</strong> synthetic data inherits the teacher model's blind spots and stylistic quirks. Mitigation: cap the proportion of synthetic data in any training run, and prioritise replacing it with real examples as they accumulate — track this ratio explicitly as a dataset health metric.")),

              div(class = "section-heading", "4. The flywheel loop, end to end"),
              div(class = "info-box-plain", HTML("<strong>🗣️ Interview talking point:</strong> \"I'd treat every user correction, tool-call failure, and task abandonment as free labeled data. Concretely: PII-scrubbed, failure-weighted, versioned datasets feed both the eval sets (Ch.3/4) and periodic LoRA finetuning (Ch.7) for the narrow high-volume models, while synthetic distillation from a frontier teacher fills the cold-start gap before real volume exists. That's the durable data moat — it compounds regardless of which frontier model is best next quarter.\""))
          )
        )
      ),

      tabPanel("✍️ Practice",
        br(),
        fluidRow(
          box(title = "Practice: Design a Data Flywheel for A1", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                       selectInput(ns("scenario"), "Choose a data source to design around:",
                                   choices = c("User corrections/edits to assistant-drafted replies", "Agent failure traces from multi-step errands",
                                               "Thumbs up/down feedback on task completions", "Synthetic data generation for a rare workflow type")),
                       sliderInput(ns("confidence"), "Confidence (1–10):", 1, 10, 5),
                       actionButton(ns("save_btn"), "Save Assessment", class = "btn-meta", width = "100%")
                ),
                column(8,
                       div(class = "practice-area",
                           tags$b("Describe how this data gets collected, cleaned, and used (eval set, finetuning, or distillation)."),
                           textAreaInput(ns("notes"), label = NULL, rows = 9, width = "100%",
                                         placeholder = "## Collection (what signal, consent/privacy handling)\n\n## Cleaning / filtering approach\n\n## How it's used (eval set / finetuning / distillation)\n\n## Feedback loop back into the product"),
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

ch08_dataset_engineering_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_btn, {
      notes <- input$notes
      conf  <- input$confidence
      score <- 0
      if (grepl("collect|privacy|consent|log", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("clean|filter|dedup|quality", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("eval|finetun|distill|train", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("loop|flywheel|feed back|continuous", notes, ignore.case = TRUE)) score <- score + 25

      prep_manager$update_progress("ch08_dataset_engineering", min(score + conf * 2, 100))
      prep_manager$save_note("ch08_notes", notes)
      prep_manager$add_practice_score("ch08_dataset_engineering", score, input$scenario)

      output$feedback <- renderUI({
        div(class = if (score >= 75) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            if (score < 100) tags$p("Complete flywheel answers close the loop: collection → cleaning → use in eval/training → measurable product improvement → more/better data.")
        )
      })
      showNotification("Saved!", type = "message")
    })
  })
}
