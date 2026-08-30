# modules/prompting_techniques.R — Chapter 10: Prompting Techniques

prompting_techniques_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Prompting Techniques"),
        tags$h2("Chapter 10 — Eleven Techniques: Zero-Shot Through Tree-of-Thoughts"),
        div(span(class="hero-badge","Zero-Shot"), span(class="hero-badge","Few-Shot"),
            span(class="hero-badge","Chain-of-Thought"), span(class="hero-badge","Tree-of-Thoughts"),
            span(class="hero-badge","Self-Consistency"))
    ),

    fluidRow(
      box(title="🧪 Interactive Prompt Shape Comparison", status="primary", solidHeader=TRUE, width=12,
          div(class="success-box", HTML("<strong>Key insight:</strong> The eleven techniques in Ch.10 differ primarily in <em>how the prompt is structured</em> — not in model choice or temperature. Select a technique to see how the same question is asked differently.")),
          br(),
          fluidRow(
            column(3,
                   div(class="section-heading-dark", "Select technique"),
                   selectInput(ns("technique"), NULL, choices=c(
                     "Zero-shot",
                     "Few-shot",
                     "Chain-of-Thought (with examples)",
                     "Zero-shot Chain-of-Thought",
                     "Reasoning prompting",
                     "Question-Answer (grounded)",
                     "Prompt chaining",
                     "Self-consistency",
                     "Tree-of-Thoughts"
                   )),
                   uiOutput(ns("technique_badge"))
            ),
            column(9,
                   div(class="section-heading-dark", "Prompt structure"),
                   uiOutput(ns("technique_display"))
            )
          )
      )
    ),

    fluidRow(
      box(title="📊 The 11 Techniques at a Glance", status="info", solidHeader=TRUE, width=12,
          tags$table(class="table table-hover",
            tags$thead(tags$tr(
              tags$th("Technique"), tags$th("Core idea"), tags$th("When to use"), tags$th("Cost"), tags$th("Prompt Flow")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$b("Zero-shot")),          tags$td("Just an instruction, no examples"),         tags$td("Well-understood tasks, GPT-4 class model"), tags$td("💚 Cheapest"), tags$td("zero-shot-prompting")),
              tags$tr(tags$td(tags$b("Few-shot")),           tags$td("2–5 worked examples in the prompt"),        tags$td("Pattern-matching tasks, weaker models"),  tags$td("💛 Low"),      tags$td("few-shot-prompting")),
              tags$tr(tags$td(tags$b("CoT (examples)")),     tags$td("Examples showing the reasoning steps"),     tags$td("Multi-step arithmetic, logic"),            tags$td("💛 Low"),      tags$td("chain-of-thought-prompting")),
              tags$tr(tags$td(tags$b("Zero-shot CoT")),      tags$td("'Let's think step by step'"),               tags$td("When you don't have worked examples"),     tags$td("💚 Low"),      tags$td("zero-shot-cot-prompting")),
              tags$tr(tags$td(tags$b("Reasoning")),          tags$td("Explicit structured reasoning scaffold"),   tags$td("Complex analysis, explainability needed"), tags$td("💛 Medium"),   tags$td("reasoning-prompting")),
              tags$tr(tags$td(tags$b("Q&A (grounded)")),     tags$td("Context passage + question"),               tags$td("RAG, document Q&A, fact-grounding"),      tags$td("💛 Medium"),   tags$td("question-answer-prompting")),
              tags$tr(tags$td(tags$b("Prompt chaining")),    tags$td("3+ sequential dependent LLM calls"),        tags$td("Decompose-then-solve pipelines"),          tags$td("🔴 Higher"),   tags$td("prompt-chaining")),
              tags$tr(tags$td(tags$b("Self-consistency")),   tags$td("Sample N paths, pick most representative"), tags$td("High-stakes decisions, reduce variance"),  tags$td("🔴 N× cost"),  tags$td("self-consistancy-prompting")),
              tags$tr(tags$td(tags$b("Self-consist. eval")), tags$td("Batch eval of sampled paths by embedding"), tags$td("Evaluating self-consistency outputs"),     tags$td("🔴 High"),    tags$td("self-consistency-evaluation")),
              tags$tr(tags$td(tags$b("Tree-of-Thoughts")),   tags$td("Multiple expert branches, pruned by score"),tags$td("Complex open-ended reasoning tasks"),     tags$td("🔴🔴 Very high"),tags$td("tree-of-thoughts")),
              tags$tr(tags$td(tags$b("ToT + evaluation")),   tags$td("Same + confidence-gated branch pruning"),   tags$td("When branch quality varies greatly"),     tags$td("🔴🔴 Very high"),tags$td("tree-of-thoughts_evaluation"))
            )
          )
      )
    ),

    fluidRow(
      box(title="✍️ Study Notes", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(6, textAreaInput(ns("notes"), "Study notes:", value="", rows=3, placeholder="Notes on prompting techniques, when to use each...")),
            column(3, sliderInput(ns("progress"), "Chapter 10 readiness:", 0, 100, 0, step=5)),
            column(3, br(), actionButton(ns("save_progress"), "Save Progress", class="btn-primary"))
          )
      )
    )
  )
}

TECHNIQUES <- list(
  "Zero-shot" = list(
    desc = "No examples — the model relies entirely on its training to understand the task.",
    cost = "💚", when = "Simple, well-defined classification or generation tasks.",
    prompt = 'Classify the sentiment as positive, negative, or neutral.\n\nStatement: "I think the vacation is okay."\n\nSentiment:'
  ),
  "Few-shot" = list(
    desc = "A handful of worked input→output examples teach the pattern before the real question.",
    cost = "💛", when = "Pattern-matching tasks where format matters, or with weaker models.",
    prompt = 'Examples:\n"I loved every minute." → positive\n"Complete waste of time." → negative\n"It was fine, nothing special." → neutral\n\nNow classify:\n"I think the vacation is okay." →'
  ),
  "Chain-of-Thought (with examples)" = list(
    desc = "Examples explicitly show the reasoning steps, not just the final answer.",
    cost = "💛", when = "Multi-step arithmetic, logic puzzles — where intermediate steps matter.",
    prompt = 'Q: Roger has 5 tennis balls. He buys 2 more cans of 3 balls each. How many does he have?\nA: Roger starts with 5. He buys 2×3=6 more. Total: 5+6 = 11. Answer: 11\n\nQ: A bakery has 12 loaves. They sell 5 and bake 8 more. How many loaves are there now?\nA:'
  ),
  "Zero-shot Chain-of-Thought" = list(
    desc = "Just add 'Let's think step by step' — no examples needed. Surprisingly effective.",
    cost = "💚", when = "When you don't have worked examples or are short on prompt space.",
    prompt = 'Q: A train travels 120km in 2 hours, then 90km in 1.5 hours. What was the average speed?\n\nLet\'s think step by step.'
  ),
  "Reasoning prompting" = list(
    desc = "A structured reasoning scaffold with explicit headers for analysis, evidence, and conclusion.",
    cost = "💛", when = "Complex analysis, explainability required, domain expert-level responses.",
    prompt = 'Question: Should a startup prioritise speed or quality in early development?\n\nAnalysis:\n[Reason through the tradeoffs here]\n\nEvidence:\n[Cite relevant principles or examples]\n\nConclusion:\n[State your final recommendation]'
  ),
  "Question-Answer (grounded)" = list(
    desc = "A context passage is provided; the model must ground its answer in the supplied text.",
    cost = "💛", when = "RAG pipelines, document Q&A, fact-checking — prevents hallucination.",
    prompt = 'Context: Back to the Future is a 1985 American science fiction film directed by Robert Zemeckis. Marty McFly travels back to 1955 using a time machine built from a DeLorean automobile.\n\nQuestion: What year does Marty travel back to?\n\nAnswer based only on the context above:'
  ),
  "Prompt chaining" = list(
    desc = "The output of one LLM call becomes the input of the next — 3 separate API calls.",
    cost = "🔴", when = "Decompose-then-solve problems: plan first, then execute each step.",
    prompt = 'Call 1 — Decompose:\nBreak down "plan a 3-day Tokyo itinerary" into 6 steps.\n\n→ [LLM returns 6 steps]\n\nCall 2 — Elaborate each step:\nFor step 1 from above: provide 3 specific recommendations.\n\n→ [LLM returns detailed step 1]\n\nCall 3 — Synthesise:\nCombine all elaborated steps into a readable day-by-day guide.'
  ),
  "Self-consistency" = list(
    desc = "Sample the same question N times, then pick the most representative answer by embedding similarity.",
    cost = "🔴 N× cost", when = "High-stakes decisions where answer variance is a problem.",
    prompt = '[Run 5× with temperature=0.8]\nQ: What is 15% of 240?\nA1: 36  A2: 36  A3: 34  A4: 36  A5: 35\n\n[Pick most common / most similar to centroid → 36]\n\nNote: Ch.10 implements this as a Prompt Flow evaluation flow using embedding cosine similarity to find the centroid answer.'
  ),
  "Tree-of-Thoughts" = list(
    desc = "Multiple independent 'expert' reasoning branches, each scored for confidence, low-scoring branches pruned.",
    cost = "🔴🔴 Very high", when = "Open-ended complex problems; worth cost only for critical decisions.",
    prompt = 'Imagine THREE different experts answering independently:\n\n<expert1>\n[Expert 1\'s reasoning chain...]\nConfidence: 82%\n</expert1>\n\n<expert2>\n[Expert 2\'s reasoning chain...]\nConfidence: 41% → PRUNED\n</expert2>\n\n<expert3>\n[Expert 3\'s reasoning chain...]\nConfidence: 78%\n</expert3>\n\n[Synthesise from non-pruned experts: 1 and 3]'
  )
)

prompting_techniques_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {

    output$technique_badge <- renderUI({
      t <- TECHNIQUES[[input$technique]]
      if (is.null(t)) return(NULL)
      div(
        br(),
        div(class="framework-card",
            tags$h5("When to use"),
            tags$p(t$when)),
        div(class="metric-card", style="padding:10px;",
            tags$small("Token cost", style="color:rgba(255,255,255,0.7);display:block;"),
            tags$b(t$cost, style="font-size:20px;"))
      )
    })

    output$technique_display <- renderUI({
      t <- TECHNIQUES[[input$technique]]
      if (is.null(t)) return(NULL)
      div(
        div(class="success-box", HTML(paste0("<strong>What it does:</strong> ", t$desc))),
        br(),
        div(class="section-heading-dark", "Prompt structure"),
        div(class="code-box",
            tags$pre(style="background:transparent;border:none;color:#E9D5FF;margin:0;padding:0;white-space:pre-wrap;", t$prompt))
      )
    })

    observeEvent(input$save_progress, {
      study_mgr$save_note("prompting_techniques", input$notes)
      study_mgr$update_progress("prompting_techniques", input$progress)
      showNotification("Chapter 10 progress saved!", type="message", duration=3)
    })
  })
}
