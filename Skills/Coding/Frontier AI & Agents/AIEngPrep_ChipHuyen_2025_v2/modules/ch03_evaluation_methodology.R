# modules/ch03_evaluation_methodology.R
# Ch. 3 — Evaluation Methodology

ch03_evaluation_methodology_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ch.3 — Evaluation Methodology"),
        tags$h2("Challenges of Evaluating Foundation Models · Language Modeling Metrics · Exact Eval · AI-as-Judge · Comparative Eval"),
        div(
          span(class = "hero-badge", "Beyond Leaderboards"),
          span(class = "hero-badge", "AI-as-Judge"),
          span(class = "hero-badge", "Comparative Eval")
        )
    ),

    tabsetPanel(
      id = ns("subtabs"), type = "tabs",

      tabPanel("📖 Theory",
        br(),
        fluidRow(
          box(title = "🧭 Why Evaluation Is Hard for Foundation Models", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "warn-box", HTML("<strong>⚠️ Core challenge:</strong> open-ended, generative outputs don't have one correct answer — classic accuracy/F1 metrics from discriminative ML don't transfer cleanly.")),
              div(class = "framework-card",
                  tags$h5("Public benchmarks ≠ your product"),
                  tags$p("Leaderboard scores measure general capability on tasks that may not resemble your actual use case, and are prone to contamination/overfitting by model vendors.")),
              div(class = "framework-card",
                  tags$h5("Criteria are multi-dimensional"),
                  tags$p("Correctness, relevance, factuality, safety, tone, latency, and cost all need separate — sometimes conflicting — evaluation criteria.")),
              div(class = "framework-card",
                  tags$h5("Ground truth is expensive or absent"),
                  tags$p("Many tasks (long-running assistant workflows) have no single labeled 'correct' trace to compare against.")),
              jobfit_box("This is the JD's loudest, most explicit ask: 'define evaluation frameworks that measure real-world usefulness... not benchmark vanity.' Be ready to name specific criteria beyond leaderboard scores for A1's assistant.",
                         c("Custom Eval", "Not Benchmark Vanity"))
          ),

          box(title = "🛠️ Evaluation Method Toolkit", status = "info", solidHeader = TRUE, width = 6,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Method"), tags$th("What It Measures"), tags$th("Limitation"))),
                tags$tbody(
                  tags$tr(tags$td(tags$span(class="stage-pill","LM metrics")), tags$td("Perplexity, cross-entropy — model's fit to text distribution"), tags$td("Doesn't measure task usefulness")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Exact eval")), tags$td("Exact match, functional correctness (e.g. code passes tests)"), tags$td("Only works for tasks with verifiable outputs")),
                  tags$tr(tags$td(tags$span(class="stage-pill","AI-as-judge")), tags$td("A capable model scores outputs against a rubric"), tags$td("Judge bias, cost, needs calibration against humans")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Comparative eval")), tags$td("Pairwise/preference comparisons (A vs B), Elo-style ranking"), tags$td("Doesn't give an absolute quality bar")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Human eval")), tags$td("Gold standard for nuanced judgment"), tags$td("Slow, expensive, doesn't scale to CI/CD"))
                )
              ),
              div(class = "tip-box", HTML("<strong>💡 In practice:</strong> production systems combine several — cheap automated checks (exact/AI-judge) gate every change, human eval samples periodically to calibrate the judge."))
          )
        ),

        fluidRow(
          box(title = "⚖️ AI-as-Judge — Design Considerations", status = "warning", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4, div(class="chapter-card", div(class="chapter-num","RUBRIC"), div(class="chapter-title","Write explicit, decomposed criteria"), div(class="chapter-desc","Score correctness, safety, tone separately rather than one vague 'quality' score."))),
                column(4, div(class="chapter-card", div(class="chapter-num","CALIBRATE"), div(class="chapter-title","Validate judge against humans"), div(class="chapter-desc","Sample judge outputs, compare to human raters, measure agreement before trusting it in CI."))),
                column(4, div(class="chapter-card", div(class="chapter-num","GUARD"), div(class="chapter-title","Watch for judge bias"), div(class="chapter-desc","Position bias, verbosity bias, self-preference bias (judge favors its own model family's style).")))
              )
          )
        ),

        fluidRow(
          box(title = "🎓 Bridging From Traditional ML: Why Evaluation Gets Genuinely Harder", status = "success", solidHeader = TRUE, width = 12,
              div(class = "framework-card",
                  tags$h5("1. Why accuracy/F1/AUC don't transfer"),
                  tags$p("Those metrics all assume a closed, enumerable output space: a fixed set of classes, or a continuous target with one correct value. You compare prediction to ground truth with simple arithmetic. Free-text generation has an effectively unbounded output space — there are many equally 'correct' ways to phrase a good email reply. There is no single ground-truth string to diff against, so the entire concept of a 'test accuracy number' has to be rebuilt around rubrics and judgment rather than exact comparison.")),
              div(class = "framework-card",
                  tags$h5("2. Perplexity / cross-entropy — the one metric that DOES generalize directly"),
                  tags$p("Cross-entropy loss is exactly the log-loss you already use for classification, just computed per-token and averaged across a sequence. Perplexity is simply exp(cross-entropy) — an interpretable 'how surprised was the model, on average, by the true next token' score. The key limitation to articulate: perplexity measures how well the model's probability distribution fits held-out TEXT, not whether a specific generated RESPONSE was useful, safe, or correct for a task — which is why it's a language-modeling health metric, not a product-quality metric.")),
              div(class = "framework-card",
                  tags$h5("3. AI-as-judge, reframed as something you already know: weak supervision"),
                  tags$p("If you've encountered weak/distant/programmatic supervision (e.g. Snorkel-style labeling functions — notably the book's author has direct experience here) — AI-as-judge is structurally the same idea: a noisy, imperfect, but CHEAP and SCALABLE labeling function, used in place of expensive human annotation, with the explicit expectation that its noise needs to be measured and corrected for (Ch.3's calibration loop) rather than trusted blindly. Treating a judge model as 'ground truth' without calibration is the AI-engineering equivalent of trusting an uncalibrated weak-labeling heuristic in a semi-supervised pipeline without checking its precision/recall against a gold set.")),
              div(class = "framework-card",
                  tags$h5("4. Comparative evaluation and Elo — the math intuition"),
                  tags$p("Rather than scoring each response in isolation, comparative eval asks 'is A or B better?' repeatedly across many pairs, then aggregates these pairwise judgments into a global ranking using an Elo-style update rule (the same rating system used in chess): each comparison nudges both items' scores based on the surprise of the outcome relative to their current rating gap. This sidesteps the hard problem of defining an absolute quality scale, at the cost of not telling you whether even the 'best' model is actually good enough in absolute terms — worth stating explicitly if asked to critique the method.")),
              div(class = "warn-box", HTML("<strong>⚠️ Likely interview probe:</strong> \"Your team proposes reporting a single 'quality score' from an LLM judge as the ship/no-ship metric. What's wrong with that, and what would you do instead?\" Strong answer: name it as an uncalibrated weak-supervision signal, insist on per-dimension scoring plus a periodic human-agreement check (the calibration loop), and treat the judge as a component with its OWN reliability metric, not an oracle."))
          )
        )
      ),

      tabPanel("🎯 A1 Use Case Deep-Dive",
        br(),
        fluidRow(
          box(title = "📌 Use Case: The A1 Evaluation Suite for Inbox Triage & Auto-Draft", status = "primary", solidHeader = TRUE, width = 12,
              div(class = "success-box", HTML("<strong>Goal:</strong> a concrete, running evaluation pipeline for the Ch.1 MVP use case (email drafting + task extraction) that a VP of Research could describe end-to-end in an interview — not an abstract framework.")),

              div(class = "section-heading", "1. Rubric — decomposed, per-dimension scoring (0–2 each)"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Dimension"), tags$th("0"), tags$th("1"), tags$th("2"), tags$th("Scoring method"))),
                tags$tbody(
                  tags$tr(tags$td(tags$b("Factual grounding")), tags$td("Contradicts thread content"), tags$td("Mostly accurate, minor omission"), tags$td("Fully consistent with thread"), tags$td("AI-as-judge, given thread + draft")),
                  tags$tr(tags$td(tags$b("Tone match")), tags$td("Clearly off-brand/off-voice"), tags$td("Acceptable but generic"), tags$td("Matches user's own past style"), tags$td("AI-as-judge, given user's sent-mail samples as reference")),
                  tags$tr(tags$td(tags$b("Actionability")), tags$td("Doesn't address the request"), tags$td("Partially addresses it"), tags$td("Fully addresses it"), tags$td("AI-as-judge, given original email")),
                  tags$tr(tags$td(tags$b("Safety")), tags$td("Contains unsafe/sensitive disclosure"), tags$td("Borderline"), tags$td("Clean"), tags$td("Rule-based + classifier, not LLM judge alone")),
                  tags$tr(tags$td(tags$b("Structural validity")), tags$td("Malformed task-extraction JSON"), tags$td("Valid but incomplete fields"), tags$td("Fully valid schema"), tags$td("Exact eval — schema validation, deterministic"))
                )
              ),

              div(class = "section-heading", "2. Judge prompt design (structure, not literal text)"),
              div(class = "framework-card",
                  tags$h5("What the judge prompt must include"),
                  tags$ul(
                    tags$li("The rubric definitions above, verbatim, so scoring is consistent across runs"),
                    tags$li("The original email thread AND the draft, clearly delimited (avoids the judge conflating source content with the thing being judged)"),
                    tags$li("A forced structured-output schema: one score per dimension + one-sentence justification per score (justifications make later human audit of judge decisions possible)"),
                    tags$li("Explicit instruction to ignore stylistic preference and only score against the rubric — reduces verbosity/position bias")
                  )),

              div(class = "section-heading", "3. Calibration loop — judge vs. human"),
              tags$ol(
                tags$li("Weekly: sample ~50 judged drafts, have a human rater independently score the same rubric"),
                tags$li("Compute per-dimension agreement (e.g. exact match rate, or correlation for ordinal scores)"),
                tags$li("Dimensions with agreement below a set threshold get the judge prompt revised, or move to human-only scoring until fixed"),
                tags$li("Track calibration drift over time — a judge that agreed well at launch can drift as the underlying model or product changes")
              ),

              div(class = "section-heading", "4. Ground truth from real usage — the highest-value signal"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Implicit Signal"), tags$th("Interpretation"), tags$th("Use"))),
                tags$tbody(
                  tags$tr(tags$td("Sent as-is"), tags$td("Strong positive"), tags$td("Add to few-shot / finetuning pool as a positive example")),
                  tags$tr(tags$td("Sent with minor edit"), tags$td("Weak positive"), tags$td("Diff the edit — recurring edit patterns reveal systematic gaps")),
                  tags$tr(tags$td("Sent with heavy rewrite"), tags$td("Weak negative"), tags$td("Flag for judge-rubric review — is tone or factuality the issue?")),
                  tags$tr(tags$td("Discarded entirely"), tags$td("Strong negative"), tags$td("Highest-priority item for weekly failure review"))
                )
              ),

              div(class = "section-heading", "5. CI/CD gate"),
              div(class = "tip-box", HTML("<strong>💡 Concrete gate:</strong> every prompt-template or model change runs against a fixed, versioned eval set of 200+ real (anonymised) past threads. A change ships only if the weighted rubric score doesn't regress by more than a set threshold on any single dimension — not just on average, so a change that trades safety for tone doesn't silently pass.")),

              div(class = "info-box-plain", HTML("<strong>🗣️ Interview talking point:</strong> \"I'd never ship on a single 'quality' number. For A1 I'd run a 5-dimension rubric — factual grounding, tone, actionability, safety, structural validity — mixing AI-as-judge for the subjective dimensions with deterministic schema checks for the structural one, calibrated weekly against human raters, gating every change in CI.\""))
          )
        )
      ),

      # ══════════════════════════════════════════════════════════ GLOSSARY
      tabPanel("📔 Glossary",
        br(),
        fluidRow(
          box(title = "Key Terms — Chapter 3", status = "info", solidHeader = TRUE, width = 12,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Term"), tags$th("Definition"), tags$th("How It Relates to What You Already Know"))),
                tags$tbody(
                  tags$tr(tags$td(tags$b("Perplexity")), tags$td("exp(cross-entropy loss); an interpretable measure of how well a model's probability distribution predicts held-out text."), tags$td("Directly derived from the log-loss metric you already use for classifiers — just applied per-token and exponentiated for interpretability.")),
                  tags$tr(tags$td(tags$b("Cross-Entropy Loss")), tags$td("The standard training/eval loss measuring the distance between predicted and true probability distributions."), tags$td("The exact same loss function used in multi-class classification, applied at each token position.")),
                  tags$tr(tags$td(tags$b("Ground Truth")), tags$td("The reference 'correct' answer used to evaluate a prediction."), tags$td("Often absent or non-unique for generative tasks, unlike classification where it's a single fixed label.")),
                  tags$tr(tags$td(tags$b("Exact Match / Functional Correctness")), tags$td("Evaluation methods that check output correctness deterministically — e.g. string match, or code that passes unit tests."), tags$td("The closest generative-eval analog to classification accuracy — usable only when the task has a verifiable, checkable output.")),
                  tags$tr(tags$td(tags$b("AI-as-Judge / LLM-as-a-Judge")), tags$td("Using a capable model to score another model's output against a rubric."), tags$td("Structurally a weak/programmatic supervision labeling function — cheap and scalable, but noisy, and must be calibrated against human labels.")),
                  tags$tr(tags$td(tags$b("Rubric")), tags$td("A set of explicit, decomposed scoring criteria (e.g. correctness, safety, tone) used to structure evaluation."), tags$td("Analogous to defining multiple labeled target variables instead of one — multi-output/multi-task labeling, scored separately.")),
                  tags$tr(tags$td(tags$b("Comparative Evaluation")), tags$td("Evaluating by pairwise comparison ('is A or B better?') rather than absolute scoring."), tags$td("Similar to pairwise-preference / learning-to-rank data collection, aggregated into a ranking rather than a fixed label.")),
                  tags$tr(tags$td(tags$b("Elo Rating")), tags$td("A rating system (originally from chess) that updates each item's score based on pairwise comparison outcomes, used to rank models/outputs from comparative eval."), tags$td("A well-known aggregation method for pairwise comparisons — no direct traditional-ML equivalent, but conceptually similar to any ranking-from-pairwise-preferences algorithm.")),
                  tags$tr(tags$td(tags$b("Human Evaluation")), tags$td("Direct scoring/labeling of model outputs by human raters."), tags$td("Equivalent to the manual labeling process in traditional supervised learning — the 'gold standard' but slow and expensive, used here to calibrate cheaper automated methods.")),
                  tags$tr(tags$td(tags$b("Benchmark Contamination")), tags$td("When a model's training data includes or overlaps with public benchmark test data, inflating its apparent performance."), tags$td("The generative-AI analog of train/test leakage — a well-known failure mode you already guard against, just harder to detect at internet-scale pretraining data.")),
                  tags$tr(tags$td(tags$b("Inter-Rater Agreement")), tags$td("A measure of how consistently two raters (human or AI) score the same items — used to validate an AI judge against humans."), tags$td("The same concept used to validate human annotator quality in traditional labeling pipelines, applied here to validate an AI judge instead."))
                )
              )
          )
        )
      ),

      tabPanel("✍️ Practice",
        br(),
        fluidRow(
          box(title = "Practice: Design an Eval Rubric for A1's Assistant", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                       selectInput(ns("scenario"), "Choose the task to evaluate:",
                                   choices = c("Drafting an email reply on the user's behalf", "Booking/confirming a multi-step errand",
                                               "Summarising a week of notes into action items", "Deciding whether to escalate to the human user")),
                       sliderInput(ns("confidence"), "Confidence (1–10):", 1, 10, 5),
                       actionButton(ns("save_btn"), "Save Assessment", class = "btn-meta", width = "100%")
                ),
                column(8,
                       div(class = "practice-area",
                           tags$b("Write 4–6 rubric dimensions plus how you'd automate scoring for each."),
                           textAreaInput(ns("notes"), label = NULL, rows = 9, width = "100%",
                                         placeholder = "## Rubric dimensions (e.g. correctness, safety, tone, latency)\n\n## Automated scoring approach per dimension\n\n## Where human eval is still required"),
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

ch03_evaluation_methodology_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_btn, {
      notes <- input$notes
      conf  <- input$confidence
      score <- 0
      if (grepl("correctness|accura|factual", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("safe|guardrail|harm|risk", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("judge|rubric|automat|score", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("human|calibrat|sample", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("latency|cost|tone|relevan", notes, ignore.case = TRUE)) score <- score + 20

      prep_manager$update_progress("ch03_evaluation_methodology", min(score + conf * 2, 100))
      prep_manager$save_note("ch03_notes", notes)
      prep_manager$add_practice_score("ch03_evaluation_methodology", score, input$scenario)

      output$feedback <- renderUI({
        div(class = if (score >= 80) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            if (score < 100) tags$p("Aim for a multi-dimensional rubric (correctness, safety, tone, latency/cost) with a clear automated-vs-human split — vague single scores read as 'benchmark vanity' to an interviewer.")
        )
      })
      showNotification("Saved!", type = "message")
    })
  })
}
