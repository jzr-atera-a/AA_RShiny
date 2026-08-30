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
        ),

        fluidRow(
          box(title = "🎓 Bridging From Traditional ML: The Mechanics Under the Hood", status = "success", solidHeader = TRUE, width = 12,
              div(class = "framework-card",
                  tags$h5("1. Self-attention, explained against what you already know"),
                  tags$p("In classic ML, a fixed-length feature vector (e.g. TF-IDF, or a hand-engineered set of columns) is fed to a model that has no notion of 'which input elements relate to which.' The transformer's self-attention mechanism computes, for every token in a sequence, a learned weighted combination of every OTHER token's representation — the weights come from a similarity score (query·key) between token pairs. Intuitively: instead of a fixed feature vector, every token dynamically re-weights its representation based on context. This is why the same word gets a different internal representation depending on surrounding words — something a bag-of-words or fixed-embedding model (e.g. static word2vec) cannot do.")),
              div(class = "framework-card",
                  tags$h5("2. Pretraining IS self-supervised learning — and that's the paradigm shift"),
                  tags$p("You already know supervised learning requires labeled (x, y) pairs someone had to collect. Self-supervised pretraining sidesteps this: the 'label' for next-token prediction is just the next word in the raw text itself — no human annotation required. This is the single biggest reason foundation models can be pretrained on internet-scale data: the supervision signal is free, generated automatically from unlabeled text. Contrast with your prior experience where dataset size was bottlenecked by labeling budget — here it's bottlenecked by compute and data availability instead.")),
              div(class = "framework-card",
                  tags$h5("3. Supervised Finetuning (SFT) — the part that IS exactly what you know"),
                  tags$p("SFT is literally supervised learning: curated (instruction, ideal-response) pairs, cross-entropy loss, gradient descent — no new concept here beyond 'the label is a full text sequence instead of a class index.' The novelty is only that training starts from the pretrained checkpoint's weights (transfer learning) rather than random initialization, so far fewer labeled examples are needed to reach good performance than training from scratch.")),
              div(class = "framework-card",
                  tags$h5("4. RLHF and DPO, explained via things you know"),
                  tags$p("Step 1 (reward modeling) is a pairwise preference classifier — structurally similar to learning-to-rank: given two candidate responses, a model is trained (via ordinary supervised learning on human-labeled 'A is better than B' pairs) to predict which one humans preferred. Step 2 (policy optimization, e.g. PPO) then uses reinforcement learning to adjust the language model so it generates outputs the reward model scores highly — this IS classic RL: an agent (the LM), a reward signal, and policy-gradient updates. DPO is a more recent, popular simplification: it derives a loss function that achieves the same alignment goal directly from the preference-pair data, using ordinary supervised-style gradient descent — skipping the separate reward model and the instability of RL training entirely. Know both, but be ready to explain WHY DPO has become popular: simpler, more stable, cheaper to train, comparable quality on many tasks.")),
              div(class = "framework-card",
                  tags$h5("5. Sampling & temperature — the actual math intuition"),
                  tags$p("The model outputs a probability distribution over the vocabulary via softmax(logits / temperature). At temperature → 0, softmax collapses toward always picking the single highest-probability token (like taking argmax in a classifier — fully deterministic). As temperature increases, the distribution flattens, so lower-probability tokens get sampled more often, injecting variety. This is precisely why classification (which reports argmax or a calibrated probability) feels deterministic to you, while generation with temperature > 0 does not: generation makes an explicit sampling DECISION at every single token, compounding variability across a whole sequence.")),
              div(class = "framework-card",
                  tags$h5("6. Mixture-of-Experts (MoE) — and how it differs from ensembling"),
                  tags$p("You know ensembles: train several models, combine ALL of their outputs (e.g. averaging, voting) at inference time — cost scales with the number of models used. MoE is different: it's a SINGLE model containing many 'expert' sub-networks, but a learned router activates only a small subset (e.g. 2 of 64 experts) for each input token. This gives you a much larger total parameter count (more capacity) WITHOUT a proportional increase in inference compute, because most experts stay dormant for any given token. The key distinction to state clearly in interview: ensembling trades inference cost for accuracy by always using more compute; MoE trades a larger memory footprint for the SAME per-token inference compute as a smaller dense model, via sparse activation.")),
              div(class = "warn-box", HTML("<strong>⚠️ Likely interview probe:</strong> \"Explain why the same prompt gives different outputs on two calls, at the token/probability level, not just 'AI is random.'\" Answer with the softmax/temperature mechanism above, not a hand-wavy description — this is exactly the kind of mechanistic depth a VP of Research is expected to have on tap."))
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

      # ══════════════════════════════════════════════════════════ GLOSSARY
      tabPanel("📔 Glossary",
        br(),
        fluidRow(
          box(title = "Key Terms — Chapter 2", status = "info", solidHeader = TRUE, width = 12,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Term"), tags$th("Definition"), tags$th("How It Relates to What You Already Know"))),
                tags$tbody(
                  tags$tr(tags$td(tags$b("Transformer")), tags$td("A neural network architecture built around self-attention, processing all tokens in a sequence in parallel while modeling relationships between them."), tags$td("Replaces the sequential processing of RNNs and the fixed local receptive fields of CNNs with a mechanism that can relate any two positions directly, regardless of distance.")),
                  tags$tr(tags$td(tags$b("Self-Attention")), tags$td("A mechanism where each token's representation is updated as a learned, weighted combination of all other tokens' representations in the sequence."), tags$td("Think of it as a dynamic, learned similarity-weighting between all pairs of inputs — unlike a fixed feature vector, the 'features' reshape based on context.")),
                  tags$tr(tags$td(tags$b("Token")), tags$td("The basic unit of text the model processes — often a sub-word piece, not a full word."), tags$td("Analogous to a discretized feature unit, roughly like a categorical bucket in a bag-of-n-grams representation, but learned via a compression algorithm (e.g. BPE) rather than hand-defined.")),
                  tags$tr(tags$td(tags$b("Embedding")), tags$td("A dense vector representation of a token (or a chunk of text) capturing semantic meaning."), tags$td("The same core idea as embeddings you may already know from word2vec or entity embeddings in recommender systems — just learned jointly with a much larger model.")),
                  tags$tr(tags$td(tags$b("Self-Supervised Learning")), tags$td("Training where the supervision signal (label) is automatically derived from the unlabeled data itself, rather than manually annotated."), tags$td("The key departure from supervised learning: no labeling budget bottleneck. Next-token prediction is the standard self-supervised objective for language models.")),
                  tags$tr(tags$td(tags$b("Pretraining")), tags$td("The initial, large-scale, self-supervised training phase that produces a base foundation model."), tags$td("Conceptually similar to pretraining a CNN on ImageNet before finetuning on a specific task — but at vastly larger scale and using self-supervision instead of labels.")),
                  tags$tr(tags$td(tags$b("Scaling Laws")), tags$td("Empirical power-law relationships describing how model loss decreases predictably as parameters, data, and compute increase."), tags$td("Analogous to learning curves you've seen in traditional ML (more data → lower error), but formalized as a predictable mathematical relationship used to plan training runs in advance.")),
                  tags$tr(tags$td(tags$b("Post-Training")), tags$td("The stages after pretraining (SFT, preference finetuning) that adapt a base model into an instruction-following, aligned assistant."), tags$td("The point where the pipeline re-enters familiar supervised-learning territory.")),
                  tags$tr(tags$td(tags$b("Supervised Finetuning (SFT)")), tags$td("Continuing training on a pretrained model using labeled (instruction, response) pairs and standard supervised loss."), tags$td("Exactly the supervised learning you already know, applied on top of a pretrained checkpoint instead of random initialization.")),
                  tags$tr(tags$td(tags$b("Reward Model")), tags$td("A model trained to predict which of two candidate responses a human would prefer, used to guide alignment."), tags$td("Structurally a pairwise preference classifier — similar to learning-to-rank models trained on labeled comparison data.")),
                  tags$tr(tags$td(tags$b("RLHF")), tags$td("Reinforcement Learning from Human Feedback — using a reward model's scores to further train the language model via reinforcement learning (e.g. PPO)."), tags$td("Classic RL: an agent, a reward signal, and policy-gradient-style updates — but the 'environment' is text generation and the reward comes from a learned model of human preference.")),
                  tags$tr(tags$td(tags$b("DPO")), tags$td("Direct Preference Optimization — a supervised-learning-style loss that achieves alignment directly from preference-pair data, without a separate reward model or RL training loop."), tags$td("A simpler, more stable alternative to RLHF that stays within the supervised-learning paradigm you're already comfortable with.")),
                  tags$tr(tags$td(tags$b("Temperature")), tags$td("A scalar that rescales logits before the softmax during sampling, controlling how 'flat' vs 'peaked' the output probability distribution is."), tags$td("At temperature → 0, sampling approaches argmax (deterministic, like standard classification); higher temperature increases randomness.")),
                  tags$tr(tags$td(tags$b("Top-k / Top-p (Nucleus) Sampling")), tags$td("Sampling strategies that restrict candidate tokens to the k highest-probability tokens (top-k) or the smallest set whose cumulative probability exceeds p (top-p)."), tags$td("A way to bound the 'risk' of sampling a very unlikely, low-quality token — similar in spirit to thresholding low-confidence predictions in a classifier.")),
                  tags$tr(tags$td(tags$b("Mixture-of-Experts (MoE)")), tags$td("An architecture where a learned router activates only a small subset of specialized sub-networks ('experts') per input, rather than the whole model."), tags$td("Different from ensembling: ensembles always combine ALL models' outputs (cost scales up); MoE sparsely activates a few experts per token, growing capacity without proportionally growing inference cost.")),
                  tags$tr(tags$td(tags$b("Autoregressive Generation")), tags$td("Generating output one token at a time, where each new token is conditioned on all previously generated tokens."), tags$td("Unlike a single forward pass in a classifier that outputs one prediction, generation is a sequential, non-i.i.d. process — this is the root cause of many of Ch.9's inference-optimization challenges."))
                )
              )
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
