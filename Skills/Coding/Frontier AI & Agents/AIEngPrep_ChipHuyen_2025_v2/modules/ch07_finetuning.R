# modules/ch07_finetuning.R
# Ch. 7 — Finetuning

ch07_finetuning_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ch.7 — Finetuning"),
        tags$h2("When to Finetune · Memory Bottlenecks · Finetuning Techniques (PEFT, Model Merging)"),
        div(
          span(class = "hero-badge", "When NOT to Finetune"),
          span(class = "hero-badge", "PEFT / LoRA"),
          span(class = "hero-badge", "Model Merging")
        )
    ),

    tabsetPanel(
      id = ns("subtabs"), type = "tabs",

      tabPanel("📖 Theory",
        br(),
        fluidRow(
          box(title = "🤔 When to Finetune (and When Not To)", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "warn-box", HTML("<strong>⚠️ Default bias should be 'no.'</strong> Try prompting + RAG first — they're cheaper, faster to iterate, and easier to debug. Finetune only once you've hit a ceiling those approaches can't cross.")),
              div(class = "framework-card", tags$h5("Good reasons to finetune"), tags$p("Consistent output format/style at scale, domain-specific tone or terminology, reducing prompt length/cost for a high-volume narrow task, or teaching behaviour that's hard to specify in-context.")),
              div(class = "framework-card", tags$h5("Weak reasons to finetune"), tags$p("Trying to fix a knowledge gap (RAG is usually the right tool), or trying to fix a reasoning gap (often a bigger/better base model or better prompting is more effective and far cheaper).")),
              jobfit_box("Ch.7's build vs buy nuance is a deeper version of Ch.4 — knowing 'finetuning is not the default answer' signals the judgment the JD explicitly wants over reflexive model-building.",
                         c("Judgment", "Cost Discipline"))
          ),

          box(title = "🧩 Finetuning Techniques", status = "info", solidHeader = TRUE, width = 6,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Technique"), tags$th("What It Does"), tags$th("Trade-off"))),
                tags$tbody(
                  tags$tr(tags$td(tags$span(class="stage-pill","Full finetuning")), tags$td("Update all model weights"), tags$td("Best quality ceiling, highest memory/compute cost")),
                  tags$tr(tags$td(tags$span(class="stage-pill","LoRA / PEFT")), tags$td("Train small low-rank adapter matrices, freeze base weights"), tags$td("Much cheaper, near-full-finetune quality on many tasks")),
                  tags$tr(tags$td(tags$span(class="stage-pill","QLoRA")), tags$td("LoRA on a quantized base model"), tags$td("Further reduces memory footprint, some quality trade-off")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Model merging")), tags$td("Combine weights of multiple finetuned models"), tags$td("Cheap way to blend capabilities, unpredictable interactions"))
                )
              ),
              div(class = "section-heading-dark", "Memory bottlenecks"),
              tags$ul(
                tags$li("Optimizer states (e.g. Adam) often dominate memory usage, not just parameter count."),
                tags$li("Activation memory scales with sequence length — long-context finetuning is disproportionately expensive."),
                tags$li("PEFT methods target exactly this: freeze most weights so gradients/optimizer states shrink dramatically.")
              )
          )
        ),

        fluidRow(
          box(title = "🔀 Finetune vs. RAG vs. Better Prompting — Decision Guide", status = "warning", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4, div(class="chapter-card", div(class="chapter-num","SYMPTOM"), div(class="chapter-title","Model doesn't know a fact"), div(class="chapter-desc","→ RAG. Finetuning is a poor, expensive way to inject knowledge and risks staleness."))),
                column(4, div(class="chapter-card", div(class="chapter-num","SYMPTOM"), div(class="chapter-title","Wrong tone/format at scale"), div(class="chapter-desc","→ Finetune (or structured output + prompting first, if volume is low)."))),
                column(4, div(class="chapter-card", div(class="chapter-num","SYMPTOM"), div(class="chapter-title","Weak reasoning on hard steps"), div(class="chapter-desc","→ Better base model, better prompting/decomposition, or a bigger model for that sub-step — rarely finetuning.")))
              )
          )
        ),

        fluidRow(
          box(title = "🎓 Bridging From Traditional ML: Finetuning Is Transfer Learning, With a Twist", status = "success", solidHeader = TRUE, width = 12,
              div(class = "framework-card",
                  tags$h5("1. This is exactly transfer learning — the part of the book closest to home"),
                  tags$p("You already know transfer learning: take a model pretrained on a large, general dataset (e.g. ImageNet), replace/adapt the final layers, and continue training on your smaller task-specific labeled dataset — converging faster and needing far less data than training from scratch, because early/general representations transfer. Finetuning a foundation model is the identical idea: start from pretrained weights, continue supervised training (cross-entropy loss on instruction→response pairs) on YOUR labeled data. Nothing conceptually new here — the differences are the base model's scale and the sophistication of parameter-efficient methods (below).")),
              div(class = "framework-card",
                  tags$h5("2. LoRA — the math intuition, one level deeper"),
                  tags$p("A weight matrix W in a transformer layer normally gets a full update ΔW during finetuning — as large as W itself, hence the large memory cost. LoRA's insight: the USEFUL update ΔW during task adaptation tends to have low 'intrinsic rank' — it can be well-approximated by a product of two much smaller matrices, ΔW ≈ B·A, where B and A have a small inner dimension r (e.g. r=8 or 16) instead of the full hidden dimension (e.g. 4096). You freeze the original W entirely and only train A and B — cutting trainable parameters (and optimizer memory) by orders of magnitude, while the frozen base model still contributes its full pretrained knowledge at inference time (W + B·A is used together).")),
              div(class = "framework-card",
                  tags$h5("3. Why memory bottlenecks aren't just about parameter count"),
                  tags$p("You may be used to thinking of model size mainly in terms of parameter count and inference memory. Training memory is different: optimizer states for methods like Adam store TWO extra values per trainable parameter (momentum + variance), so full finetuning's memory cost is roughly 4x+ the raw parameter count once you include gradients and optimizer state — this is exactly why PEFT methods, which shrink the TRAINABLE parameter count (not the model's total size), disproportionately reduce training memory even though the frozen base model still needs to be loaded in full.")),
              div(class = "framework-card",
                  tags$h5("4. Model merging vs. ensembling — a distinction worth stating precisely"),
                  tags$p("Ensembling (which you know) combines multiple models' OUTPUTS at inference time — you pay inference cost for every model in the ensemble. Model merging combines multiple models' WEIGHTS (e.g. simple averaging, or more sophisticated methods that account for parameter importance) into a single set of weights BEFORE inference — you pay full training cost for each source model once, but inference cost for only ONE resulting model. The trade-off: merging can produce unpredictable interactions between the merged capabilities (unlike ensembling's outputs, which combine transparently), so it needs empirical validation on your eval set, not just a theoretical justification.")),
              div(class = "warn-box", HTML("<strong>⚠️ Likely interview probe:</strong> \"Explain, at a level below 'LoRA is cheaper,' WHY LoRA works almost as well as full finetuning for many tasks.\" Strong answer: name the low-intrinsic-rank hypothesis explicitly — most of the useful task-adaptation signal lives in a low-dimensional subspace of the full weight-update space, so constraining updates to that subspace loses little quality while saving most of the compute/memory."))
          )
        )
      ),

      tabPanel("🎯 A1 Use Case Deep-Dive",
        br(),
        fluidRow(
          box(title = "📌 Use Case: Finetuning A1's Tool-Argument & Routing Models", status = "primary", solidHeader = TRUE, width = 12,
              div(class = "success-box", HTML("<strong>Where finetuning earns its cost at A1:</strong> the two Ch.2/4 pipeline stages that are high-volume, narrow, and format-critical — intent routing and tool-argument generation — are exactly the 'good reasons to finetune' case: consistent structured output, high volume amortizes training cost, and prompting alone tends to have a non-trivial malformed-output rate at this volume.")),

              div(class = "section-heading", "1. Technique choice and why"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Model"), tags$th("Technique"), tags$th("Why"))),
                tags$tbody(
                  tags$tr(tags$td("Intent router"), tags$td(tags$span(class="stage-pill","LoRA (PEFT) on a small open-weight base")), tags$td("Narrow classification-like task; LoRA reaches near-ceiling quality at a fraction of full-finetune cost and lets A1 iterate quickly as new intent categories are added")),
                  tags$tr(tags$td("Tool-argument generator"), tags$td(tags$span(class="stage-pill","QLoRA on a small open-weight base")), tags$td("Needs to run cheaply at very high volume (every tool call); quantized base keeps serving cost low without materially hurting schema-following accuracy"))
                )
              ),

              div(class = "section-heading", "2. Training data source (ties to Ch.8 flywheel)"),
              tags$ol(
                tags$li(tags$b("Bootstrap:"), " use a frontier model as a 'teacher' to generate (request → correct tool call) pairs offline — this is distillation (Ch.8), producing the initial finetuning dataset without needing months of real production data first."),
                tags$li(tags$b("Refine:"), " once live, log every real routing decision and tool call, paired with success/failure (did the call execute without schema error? did the routed intent match what the downstream step actually needed?)."),
                tags$li(tags$b("Curate:"), " weight failure cases more heavily in the next finetuning round — this is where most of the quality improvement comes from, not raw volume of correct examples.")
              ),

              div(class = "section-heading", "3. Memory/compute footprint estimate (illustrative, for interview framing)"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Approach"), tags$th("Trainable Params"), tags$th("Relative Memory"), tags$th("Iteration Speed"))),
                tags$tbody(
                  tags$tr(tags$td("Full finetune of a small base model"), tags$td("100%"), tags$td("Highest — full optimizer state for all weights"), tags$td("Slowest — full retrain per iteration")),
                  tags$tr(tags$td("LoRA (rank 8–16)"), tags$td("~0.1–1%"), tags$td("Low — optimizer state only for adapter"), tags$td("Fast — cheap enough to retrain weekly on new failure data")),
                  tags$tr(tags$td("QLoRA on quantized base"), tags$td("~0.1–1%"), tags$td("Lowest"), tags$td("Fast, with a small serving-quality trade-off to validate against the Ch.3 eval rubric"))
                )
              ),

              div(class = "section-heading", "4. What A1 should explicitly NOT finetune"),
              div(class = "warn-box", HTML("<strong>⚠️ Explicit non-goal:</strong> the drafting model (email/message generation) and the planning model should NOT be finetuned early on — their quality bar is broad and subjective (tone, reasoning), which is exactly the case where a stronger frontier base model or better prompting outperforms finetuning, and finetuning risks overfitting to a narrow style that doesn't generalize across A1's diverse user base.")),

              div(class = "info-box-plain", HTML("<strong>🗣️ Interview talking point:</strong> \"I'd only finetune the two narrow, high-volume, format-critical stages — routing and tool-argument generation — using LoRA/QLoRA, bootstrapped via distillation from a frontier teacher, then continuously refined from real failure logs. Drafting and planning stay on frontier models with strong prompting, because that's where reasoning/tone quality — not format consistency — is the bottleneck, and finetuning is the wrong tool for that.\""))
          )
        )
      ),

      # ══════════════════════════════════════════════════════════ GLOSSARY
      tabPanel("📔 Glossary",
        br(),
        fluidRow(
          box(title = "Key Terms — Chapter 7", status = "info", solidHeader = TRUE, width = 12,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Term"), tags$th("Definition"), tags$th("How It Relates to What You Already Know"))),
                tags$tbody(
                  tags$tr(tags$td(tags$b("Transfer Learning")), tags$td("Reusing a model pretrained on one (typically broader) task/dataset as the starting point for training on a new, related task."), tags$td("The umbrella concept finetuning falls under — you already use this with pretrained CNNs/embeddings; foundation-model finetuning is the same idea at much larger scale.")),
                  tags$tr(tags$td(tags$b("Finetuning")), tags$td("Continuing supervised training on a pretrained model's weights using a smaller, task-specific labeled dataset."), tags$td("Standard supervised learning (cross-entropy loss, gradient descent) applied on top of pretrained weights instead of random initialization.")),
                  tags$tr(tags$td(tags$b("Full Finetuning")), tags$td("Updating ALL of a model's weights during finetuning."), tags$td("The traditional transfer-learning approach — highest quality ceiling, highest memory/compute cost.")),
                  tags$tr(tags$td(tags$b("PEFT (Parameter-Efficient Finetuning)")), tags$td("A family of techniques that finetune only a small subset or a compact reparameterization of a model's weights, freezing the rest."), tags$td("A way to get most of transfer learning's benefit while training a tiny fraction of the parameters — dramatically cheaper than full finetuning.")),
                  tags$tr(tags$td(tags$b("LoRA")), tags$td("Low-Rank Adaptation — a PEFT method that approximates the weight update ΔW as a product of two small low-rank matrices, leaving the original weights frozen."), tags$td("Relies on the empirical observation that task-adaptation updates have low intrinsic rank — a dimensionality-reduction idea applied to weight updates.")),
                  tags$tr(tags$td(tags$b("QLoRA")), tags$td("LoRA applied on top of a quantized (lower numeric precision) base model, further reducing memory footprint."), tags$td("Combines two independent memory-saving techniques — quantization (Ch.9) and LoRA — stacked together.")),
                  tags$tr(tags$td(tags$b("Rank (Low-Rank Decomposition)")), tags$td("The inner dimension of the low-rank matrices used in LoRA, controlling how expressive the adaptation can be."), tags$td("Directly analogous to choosing the number of components in PCA/SVD — a size/capacity hyperparameter trading expressiveness for efficiency.")),
                  tags$tr(tags$td(tags$b("Quantization")), tags$td("Representing weights/activations with lower numeric precision (e.g. 8-bit or 4-bit instead of 16/32-bit) to reduce memory and increase speed."), tags$td("Analogous to model compression techniques you may know from deploying traditional ML models to resource-constrained (edge) environments.")),
                  tags$tr(tags$td(tags$b("Catastrophic Forgetting")), tags$td("A model losing previously learned capabilities as it's finetuned heavily on new, narrow data."), tags$td("The generative-AI instance of the classic transfer-learning trade-off between adapting to a new task and retaining prior general performance.")),
                  tags$tr(tags$td(tags$b("Model Merging")), tags$td("Combining the weights of multiple (typically finetuned) models into a single set of weights, without additional training."), tags$td("Different from ensembling: ensembling combines OUTPUTS at inference time (higher inference cost); merging combines WEIGHTS beforehand (single-model inference cost, but less predictable interactions).")),
                  tags$tr(tags$td(tags$b("Adapter")), tags$td("A small set of additional trainable parameters (e.g. LoRA matrices) inserted into a frozen pretrained model to enable efficient task adaptation."), tags$td("A lightweight, swappable 'plugin' to a frozen base model — conceptually similar to swapping the final classification head on a frozen pretrained feature extractor.")),
                  tags$tr(tags$td(tags$b("Optimizer State")), tags$td("Auxiliary values (e.g. momentum, variance estimates in Adam) an optimizer maintains per trainable parameter during training."), tags$td("Often the dominant memory cost during training — a detail traditional ML practitioners know but that becomes acutely important at foundation-model scale.")),
                  tags$tr(tags$td(tags$b("Gradient Checkpointing")), tags$td("A memory-saving technique that recomputes some intermediate activations during the backward pass instead of storing them all."), tags$td("A compute-for-memory trade-off technique, useful whenever training memory (not just parameter count) is the binding constraint."))
                )
              )
          )
        )
      ),

      tabPanel("✍️ Practice",
        br(),
        fluidRow(
          box(title = "Practice: Justify a Finetuning Decision", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                       selectInput(ns("scenario"), "Choose a symptom to diagnose:",
                                   choices = c("Assistant drafts replies in the wrong tone for this user's brand voice", "Assistant doesn't know about a user's recent calendar changes",
                                               "Assistant struggles to plan complex 5+ step errands", "Cost per request is too high due to long few-shot prompts")),
                       sliderInput(ns("confidence"), "Confidence (1–10):", 1, 10, 5),
                       actionButton(ns("save_btn"), "Save Assessment", class = "btn-meta", width = "100%")
                ),
                column(8,
                       div(class = "practice-area",
                           tags$b("State whether you'd finetune, use RAG, improve prompting, or switch models — and why."),
                           textAreaInput(ns("notes"), label = NULL, rows = 9, width = "100%",
                                         placeholder = "## Diagnosis of the underlying gap (knowledge / format / reasoning / cost)\n\n## Recommended fix and why it's the cheapest sufficient option\n\n## What you'd try first before finetuning, if anything"),
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

ch07_finetuning_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_btn, {
      notes <- input$notes
      conf  <- input$confidence
      score <- 0
      if (grepl("knowledge|format|reasoning|cost|diagnos", notes, ignore.case = TRUE)) score <- score + 30
      if (grepl("finetun|rag|prompt|switch model", notes, ignore.case = TRUE)) score <- score + 40
      if (grepl("try first|cheaper|before finetun|prompting first", notes, ignore.case = TRUE)) score <- score + 30

      prep_manager$update_progress("ch07_finetuning", min(score + conf * 2, 100))
      prep_manager$save_note("ch07_notes", notes)
      prep_manager$add_practice_score("ch07_finetuning", score, input$scenario)

      output$feedback <- renderUI({
        div(class = if (score >= 70) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            if (score < 100) tags$p("The strongest answers explicitly state what cheaper option you'd rule out first — finetuning-by-default reads as inexperience to an interviewer who wrote this book.")
        )
      })
      showNotification("Saved!", type = "message")
    })
  })
}
