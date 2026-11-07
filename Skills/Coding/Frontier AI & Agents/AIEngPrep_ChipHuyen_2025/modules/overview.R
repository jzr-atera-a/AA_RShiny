# modules/overview.R
# Landing tab — book map + why it matters for the A1 role

overview_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("AI Engineering Prep"),
        tags$h2("Chip Huyen — \"AI Engineering: Building Applications with Foundation Models\" (O'Reilly, 2025)"),
        div(
          span(class = "hero-badge", "10 Chapters"),
          span(class = "hero-badge", "VP of Research, ML — A1"),
          span(class = "hero-badge", "Seeded by BJAK, $100M"),
          span(class = "hero-badge", "Build vs. Buy · Eval · Agents")
        )
    ),

    fluidRow(
      valueBoxOutput(ns("vb_progress"), width = 3),
      valueBoxOutput(ns("vb_chapters"), width = 3),
      valueBoxOutput(ns("vb_practice"), width = 3),
      valueBoxOutput(ns("vb_role"), width = 3)
    ),

    fluidRow(
      box(title = "📚 Why This Book, For This Role", status = "primary", solidHeader = TRUE, width = 6,
          div(class = "success-box",
              HTML("<strong>Direct overlap:</strong> the A1 JD reads almost like a chapter list from this book — evaluation rigor over benchmark vanity, context/memory/reasoning/planning/orchestration, build-vs-buy on model architecture, alignment & guardrails as first-class concerns, and the exact frontier techniques named (RAG, MoE, distillation, multi-agent, multimodal).")),
          div(class = "framework-card",
              tags$h5("Author background"),
              tags$p("Huyen built production ML at NVIDIA, Netflix, and Snorkel AI, and teaches Stanford's ML Systems Design course. The book is grounded in deployment experience, not just theory — matching the JD's explicit call for a \"builder's mindset.\"")),
          div(class = "framework-card",
              tags$h5("How to use this app"),
              tags$p("Work chapter by chapter (left sidebar). Each tab has: core concepts, a decision framework or comparison table, an A1-specific job-fit callout, and a short practice exercise that scores your written response and updates your progress below."))
      ),

      box(title = "🗺️ Book Map — 10 Chapters", status = "info", solidHeader = TRUE, width = 6,
          chapter_card("CH 1", "Introduction to Building AI Applications with Foundation Models",
                       "The rise of AI engineering; foundation model use cases; planning AI applications; the AI engineering stack.",
                       c("Stack", "Planning")),
          chapter_card("CH 2", "Understanding Foundation Models",
                       "Training data, architecture & scale, post-training, sampling, and the probabilistic nature of AI.",
                       c("Architecture", "Non-determinism")),
          chapter_card("CH 3", "Evaluation Methodology",
                       "Challenges of evaluating foundation models; language modeling metrics; exact eval; AI-as-judge; comparative eval.",
                       c("Eval", "AI Judge")),
          chapter_card("CH 4", "Evaluate AI Systems",
                       "Evaluation criteria; model selection (build vs. buy); designing an evaluation pipeline.",
                       c("Build vs Buy", "Pipeline"))
      )
    ),

    fluidRow(
      box(title = NULL, status = "success", solidHeader = FALSE, width = 12,
          fluidRow(
            column(3, chapter_card("CH 5", "Prompt Engineering", "Prompting fundamentals, best practices, defensive prompting (jailbreaks, injection, defenses).", c("Guardrails"))),
            column(3, chapter_card("CH 6", "RAG and Agents", "RAG architecture & retrieval; agents (tools, planning, failure modes); memory.", c("Agents", "Memory"))),
            column(3, chapter_card("CH 7", "Finetuning", "When to finetune; memory bottlenecks; PEFT and model merging.", c("PEFT"))),
            column(3, chapter_card("CH 8", "Dataset Engineering", "Data curation; augmentation & synthesis; data processing.", c("Data")))
          ),
          fluidRow(
            column(4, chapter_card("CH 9", "Inference Optimization", "Inference fundamentals; AI accelerators; model & service optimization.", c("Latency", "Cost"))),
            column(4, chapter_card("CH 10", "AI Engineering Architecture & User Feedback", "Guardrails, routers, caching, agent patterns, monitoring; user feedback design.", c("Architecture", "Feedback"))),
            column(4, div(class = "tip-box",
                          HTML("<strong>💡 Interview framing:</strong> Chapters 1–4 are the framing/evaluation backbone (weight your prep here — it's the JD's first and loudest ask). Ch. 5–7 are the model/technique layer. Ch. 8–10 are the production layer A1 will probe hardest given \"reliability for long-running workflows.\"")))
          )
      )
    )
  )
}

overview_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    output$vb_progress <- renderValueBox({
      prep_manager$progress_trigger()
      valueBox(paste0(prep_manager$get_overall_progress(), "%"), "Overall Progress",
                icon = icon("chart-line"), color = "teal")
    })

    output$vb_chapters <- renderValueBox({
      valueBox("10", "Chapters Covered", icon = icon("book"), color = "blue")
    })

    output$vb_practice <- renderValueBox({
      prep_manager$score_trigger()
      total_scores <- sum(sapply(prep_manager$practice_scores, length))
      valueBox(total_scores, "Practice Exercises Done", icon = icon("pen"), color = "yellow")
    })

    output$vb_role <- renderValueBox({
      valueBox("A1", "Target: VP Research, ML", icon = icon("bullseye"), color = "green")
    })
  })
}
