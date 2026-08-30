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
