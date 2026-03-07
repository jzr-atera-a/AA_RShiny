# modules/practice.R
# Tab 10: Timed Practice — 45-min simulation with auto-scoring

practice_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Timed Design Practice"),
        tags$h2("45-Minute ML System Design Interview Simulation — Huyen's 5-Step Framework"),
        div(
          span(class = "hero-badge", "45 Min Timer"),
          span(class = "hero-badge", "Auto-Score"),
          span(class = "hero-badge", "5-Step Framework"),
          span(class = "hero-badge", "Feedback")
        )
    ),

    fluidRow(
      box(title = "⚙️ Session Setup & Timer", status = "primary",
          solidHeader = TRUE, width = 4,

          selectInput(ns("design_topic"), "Choose Design System:",
                      choices = c(
                        "Video Recommendation System",
                        "Product Search Ranking",
                        "Real-time Fraud Detection",
                        "LLM Customer Support (RAG)",
                        "News Feed Ranking",
                        "Ad CTR Prediction System",
                        "Content Moderation at Scale",
                        "Entity Resolution / Deduplication",
                        "Supply Chain Demand Forecasting",
                        "Medical Diagnosis Assistance"
                      )),

          div(class = "timer-card",
              uiOutput(ns("timer_display"))
          ),
          br(),

          fluidRow(
            column(6, actionButton(ns("start_design"), "▶ Start (45 min)",
                                   class = "btn-meta", width = "100%",
                                   icon = icon("play"))),
            column(6, actionButton(ns("reset_timer"), "↺ Reset",
                                   class = "btn-meta", width = "100%"))
          ),
          br(),

          sliderInput(ns("design_confidence"), "Self-assessed confidence (1–10):", 1, 10, 5),
          actionButton(ns("save_design"), "📊 Score My Design", class = "btn-meta",
                       width = "100%", icon = icon("chart-bar")),
          br(), br(),
          uiOutput(ns("design_feedback"))
      ),

      box(title = "✍️ Design Notes — Huyen's 5-Step Framework", status = "success",
          solidHeader = TRUE, width = 8,

          div(class = "practice-area",
              tags$b("Instructions:"), " Work through all 5 steps below. Use the framework as your guide. The auto-scorer will check for coverage of each step."),
          textAreaInput(ns("design_notes"), label = NULL, rows = 24, width = "100%",
                        placeholder =
"## 1. SCOPE (0–5 min)
Business objective → ML objective. What are we predicting and why?
Constraints: latency SLO, scale (QPS), interpretability required, compute budget.
Success metric: how does 'good enough' look?

## 2. DATA STRATEGY (5–15 min)
Data sources. Labelling strategy (natural labels / hand labels / programmatic).
Format: Parquet for training. Batch vs streaming pipeline decision.
Class balance? Data leakage risk? Feature store needs?

## 3. MODEL ARCHITECTURE (15–30 min)
Feature engineering: dense features, sparse embeddings, crossing.
Model choice + justification (WHY this model vs alternatives).
Training setup: loss function, distributed training, data parallelism.
Two-tower or single model? Embeddings?

## 4. EVALUATION (30–40 min)
Offline metrics: which metric and why for this task type.
Sliced evaluation: which subgroups, why, automated discovery?
A/B test design: randomisation unit, guardrail metrics, duration.
Shadow mode + canary deployment plan.

## 5. DEPLOYMENT & MONITORING (40–45 min)
Batch vs online prediction decision (justify).
Serving architecture: latency, throughput, model compression?
Monitoring: which drift types to watch, retraining triggers.
Iteration plan: what's next in 3 months?")
      )
    ),

    fluidRow(
      box(title = "📖 Interview Reminders — Read Before Starting", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(3, div(class = "framework-card",
                tags$h5("Own the Conversation"),
                tags$p("80% of the talking should be you. Drive the design — don't wait to be led. Treat it as presenting to a Staff Engineer."))),
            column(3, div(class = "framework-card",
                tags$h5("Justify Every Choice"),
                tags$p("Never say 'I'll use XGBoost' without 'because: low latency, handles missing values, proven on tabular data at this scale.'"))),
            column(3, div(class = "framework-card",
                tags$h5("Trade-offs, Not Just Features"),
                tags$p("'This gives lower latency but sacrifices freshness. Given the SLO, I'd accept this trade.' Shows production maturity."))),
            column(3, div(class = "framework-card",
                tags$h5("Mention Monitoring Early"),
                tags$p("Don't wait to be asked. Say: 'I'd set up PSI-based drift monitoring on key features with automated retraining triggers.' Shows full system ownership.")))
          )
      )
    )
  )
}

practice_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    timer_start  <- reactiveVal(NULL)
    timer_active <- reactiveVal(FALSE)

    # ── Timer display ──────────────────────────────
    output$timer_display <- renderUI({
      invalidateLater(1000)
      if (!timer_active() || is.null(timer_start())) {
        return(tagList(
          span(class = "timer-value", "45:00"),
          div(class = "timer-label", "Ready")
        ))
      }
      elapsed   <- as.numeric(difftime(Sys.time(), timer_start(), units = "secs"))
      total     <- 45 * 60
      remaining <- max(0, total - elapsed)
      mins      <- floor(remaining / 60)
      secs      <- floor(remaining %% 60)

      val_colour <- if (remaining < 300) "#ef4444" else if (remaining < 600) "#f59e0b" else "#7dd3fc"

      tagList(
        span(style = paste0("font-size:3em;font-weight:800;font-family:'JetBrains Mono',monospace;",
                            "display:block;line-height:1;color:", val_colour, ";"),
             sprintf("%02d:%02d", mins, secs)),
        div(class = "timer-label",
            if (remaining == 0) "Time's up — score your design!"
            else if (remaining < 300) "Final sprint — wrap up serving & monitoring!"
            else if (remaining < 600) "Last 10 min — evaluation and deployment!"
            else "Session in progress")
      )
    })

    # ── Start timer ────────────────────────────────
    observeEvent(input$start_design, {
      timer_start(Sys.time())
      timer_active(TRUE)
      showNotification("Timer started! 45 minutes — own the design.", type = "message")
    })

    # ── Reset timer ────────────────────────────────
    observeEvent(input$reset_timer, {
      timer_active(FALSE)
      timer_start(NULL)
      showNotification("Timer reset.", type = "message")
    })

    # ── Score and feedback ─────────────────────────
    observeEvent(input$save_design, {
      notes <- input$design_notes
      conf  <- input$design_confidence

      criteria <- list(
        list(label = "1. Scope & Framing",        kw = c("objective","latency","scale","qps","constraint","slo","metric","success","predict"), weight = 20),
        list(label = "2. Data Strategy",           kw = c("label","data","parquet","streaming","batch","feature store","imbalance","leakage","drift","pipeline"), weight = 20),
        list(label = "3. Model Architecture",      kw = c("model","embed","feature","loss","train","architecture","tower","layer","mlp","transformer","gbdt","xgboost"), weight = 20),
        list(label = "4. Evaluation Framework",    kw = c("offline","ndcg","auc","precision","recall","a/b","slice","guardrail","eval","metric","shadow"), weight = 20),
        list(label = "5. Deployment & Monitoring", kw = c("serving","monitor","retrain","drift","batch","online","latency","throughput","compression","canary"), weight = 20)
      )

      score <- 0
      breakdown <- lapply(criteria, function(c) {
        hits <- sum(sapply(c$kw, function(kw) grepl(kw, notes, ignore.case = TRUE)))
        s <- min(c$weight, round((hits / length(c$kw)) * c$weight * 2.5))
        score <<- score + s
        list(label = c$label, score = s, max = c$weight, hits = hits, total_kw = length(c$kw))
      })
      score <- min(100, score)

      prep_manager$add_practice_score("practice", score, input$design_topic)
      prep_manager$update_progress("practice", min(score + conf * 3, 100))
      timer_active(FALSE)

      output$design_feedback <- renderUI({
        feedback_items <- lapply(breakdown, function(b) {
          cls <- if (b$score >= b$max * 0.7) "success-box" else if (b$score > 0) "tip-box" else "warn-box"
          div(class = cls,
              tags$b(paste0(b$label, ": ", b$score, "/", b$max)),
              if (b$score < b$max * 0.4)
                tags$p(paste0("⚠️ Low coverage. Focus on expanding this section."))
              else if (b$score < b$max * 0.7)
                tags$p(paste0("💡 Good start. Add more depth."))
              else
                tags$p("✅ Well covered.")
          )
        })

        overall_msg <- if (score >= 80) "✅ Excellent design! All 5 steps covered with good depth." else
          if (score >= 60) "💡 Good structure. Expand the lower-scoring sections." else
            "⚠️ Review the Huyen 5-step framework and retry. Focus on the missing sections above."

        tagList(
          div(style = "text-align:center;padding:15px;",
              tags$h3(style = paste0("color:", progress_colour(score)), paste0(score, " / 100")),
              tags$p(tags$b(paste0("Confidence: ", conf, "/10")))
          ),
          do.call(tagList, feedback_items),
          div(class = if (score >= 80) "success-box" else "warn-box",
              HTML(paste0("<strong>Overall:</strong> ", overall_msg)))
        )
      })

      showNotification(paste0("Design scored: ", score, "/100"), type = "message")
    })
  })
}
