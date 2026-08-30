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
        ),

        fluidRow(
          box(title = "🎓 Bridging From Traditional ML: Distillation Is Supervised Learning on Soft Labels", status = "success", solidHeader = TRUE, width = 12,
              div(class = "framework-card",
                  tags$h5("1. Knowledge distillation — the original idea, and why it still applies"),
                  tags$p("Distillation predates foundation models — the classic formulation trains a smaller 'student' model to match a larger 'teacher' model's full output probability distribution (soft labels), not just its single predicted class (hard label). The insight: soft labels carry extra information — 'this image is 70% cat, 25% dog, 5% other' tells the student far more about the decision boundary than the hard label 'cat' alone (often called 'dark knowledge'). For LLMs, the same idea applies: train a smaller model on a frontier model's generated OUTPUTS (or, more richly, its output probability distributions where accessible) rather than only on hard-labeled human data.")),
              div(class = "framework-card",
                  tags$h5("2. Why this connects directly to your semi-supervised-learning background"),
                  tags$p("If you've used pseudo-labeling or self-training (a semi-supervised technique: use a trained model to label unlabeled data, then train on those labels) — using a frontier model to generate synthetic training examples for a smaller model is structurally the same pattern, just with a much more capable 'labeler.' The same risk applies too: pseudo-labels/synthetic data inherit and can amplify the labeling model's systematic errors and biases — a student can only be as good as its teacher's blind spots allow, sometimes worse if errors compound.")),
              div(class = "framework-card",
                  tags$h5("3. Model collapse — the new failure mode synthetic data introduces"),
                  tags$p("A risk that doesn't have a strong analogy in traditional pseudo-labeling at smaller scale: if synthetic data generated by a model is used to train the NEXT generation of models, which then generates the data for the generation after that, quality/diversity can degenerate over successive generations — the model increasingly reflects its own prior outputs' statistical patterns rather than the true underlying data distribution. This is a concrete, well-documented reason to always cap the proportion of synthetic data and prioritize replacing it with real examples over time, rather than treating synthetic generation as an infinitely renewable data source.")),
              div(class = "framework-card",
                  tags$h5("4. Curation quality vs. quantity — an old lesson, now amplified"),
                  tags$p("You already know that in supervised learning, a smaller clean dataset often beats a larger noisy one, and that class imbalance (many easy examples, few hard ones) needs deliberate handling (oversampling, reweighting). At foundation-model scale this lesson doesn't go away — if anything it matters MORE, because 'noise' now includes subtler failure modes like near-duplicate examples that silently inflate a model's apparent performance, and hard/failure cases are an even smaller fraction of raw logged data than 'hard examples' typically are in a traditional labeled dataset.")),
              div(class = "warn-box", HTML("<strong>⚠️ Likely interview probe:</strong> \"If you distill a frontier model down to a small model for cost reasons, what quality risks does that introduce, and how would you monitor for them?\" Strong answer: name inherited teacher blind spots and potential model-collapse-like degeneration if synthetic data dominates over successive iterations, then tie it to Ch.3/4's eval pipeline — track the distilled student's rubric scores against the SAME eval set used for the teacher, on a recurring basis, not just at initial launch."))
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

      # ══════════════════════════════════════════════════════════ GLOSSARY
      tabPanel("📔 Glossary",
        br(),
        fluidRow(
          box(title = "Key Terms — Chapter 8", status = "info", solidHeader = TRUE, width = 12,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Term"), tags$th("Definition"), tags$th("How It Relates to What You Already Know"))),
                tags$tbody(
                  tags$tr(tags$td(tags$b("Data Curation")), tags$td("Deliberately selecting, filtering, and organizing data for training/evaluation, prioritizing quality and coverage over raw volume."), tags$td("The same discipline you apply to building a clean labeled dataset — now including coverage of specific failure-mode categories, not just class balance.")),
                  tags$tr(tags$td(tags$b("Deduplication")), tags$td("Removing exact or near-duplicate examples from a dataset."), tags$td("Prevents the same silent performance inflation and overfitting risk that near-duplicate rows cause in a traditional training set.")),
                  tags$tr(tags$td(tags$b("Data Augmentation")), tags$td("Generating variations of existing examples (e.g. paraphrasing text) to increase training data diversity."), tags$td("The text equivalent of image augmentation (flips, crops, rotations) you already know — same goal of improving robustness to superficial input variation.")),
                  tags$tr(tags$td(tags$b("Synthetic Data")), tags$td("Training/eval examples generated by a model rather than collected from real usage or hand-labeled by humans."), tags$td("Structurally similar to pseudo-labeling in semi-supervised learning — using a model to generate labels/examples, with the same risk of inheriting the generator's biases.")),
                  tags$tr(tags$td(tags$b("Knowledge Distillation")), tags$td("Training a smaller 'student' model to replicate a larger 'teacher' model's outputs (or output distribution)."), tags$td("A classic ML technique predating foundation models — soft labels from the teacher carry richer signal than hard labels alone ('dark knowledge').")),
                  tags$tr(tags$td(tags$b("Teacher / Student Model")), tags$td("In distillation, the teacher is the larger/more capable source model; the student is the smaller model being trained to mimic it."), tags$td("Direct terminology carryover from classic distillation literature (Hinton et al.) — the underlying idea is unchanged at foundation-model scale.")),
                  tags$tr(tags$td(tags$b("Dark Knowledge / Soft Labels")), tags$td("The extra information contained in a model's full output probability distribution, beyond just its top prediction."), tags$td("Why distillation on probabilities (where accessible) generally outperforms distillation on hard labels alone — the same reason soft-label distillation works in traditional classification.")),
                  tags$tr(tags$td(tags$b("Data Leakage")), tags$td("When information from the evaluation/test set inadvertently influences training, invalidating the evaluation."), tags$td("The exact same concept as train/test leakage in traditional ML — still catastrophic here, and easier to introduce accidentally given data volume.")),
                  tags$tr(tags$td(tags$b("PII Scrubbing")), tags$td("Removing or masking personally identifiable information from data before storage or use in training."), tags$td("A privacy-engineering practice that applies to any data pipeline, now essential given foundation-model training/eval data often comes from real user interactions.")),
                  tags$tr(tags$td(tags$b("Dataset Versioning")), tags$td("Tracking distinct, reproducible snapshots of a dataset over time."), tags$td("The same discipline as versioning a labeled dataset in traditional ML — critical for reproducibility and for auditing which data produced which model version.")),
                  tags$tr(tags$td(tags$b("Train/Eval Split")), tags$td("Strictly separating data used for training from data used for evaluation to get an unbiased performance estimate."), tags$td("A foundational ML practice, unchanged in principle — just requiring extra vigilance given the scale and diversity of foundation-model data sources."))
                )
              )
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
