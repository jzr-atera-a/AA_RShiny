# modules/intro.R
# Tab 1: Overview & Book Guide — Kravchenko & Babushkin (Manning 2025)

intro_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Machine Learning System Design"),
        tags$h2("End-to-End Interview Prep — Kravchenko & Babushkin · Manning 2025"),
        div(
          span(class="hero-badge","End-to-End Examples"),
          span(class="hero-badge","Production ML"),
          span(class="hero-badge","Real Architecture"),
          span(class="hero-badge","Business Impact")
        )
    ),

    fluidRow(
      box(title="🎯 Your Overall Readiness", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(2, div(class="metric-card", span(class="metric-value", textOutput(ns("pct_overall"))),    span(class="metric-label","Overall Score"))),
            column(2, div(class="metric-card", span(class="metric-value","10"),   span(class="metric-label","Book Chapters"))),
            column(2, div(class="metric-card", span(class="metric-value","E2E"),  span(class="metric-label","Case Studies"))),
            column(2, div(class="metric-card", span(class="metric-value","45m"),  span(class="metric-label","Interview Slot"))),
            column(2, div(class="metric-card", span(class="metric-value","PROD"), span(class="metric-label","Focus: Production"))),
            column(2, div(class="metric-card", span(class="metric-value","2025"), span(class="metric-label","Manning Edition")))
          ),
          br(),
          uiOutput(ns("tab_progress_bars"))
      )
    ),

    fluidRow(
      box(title="📚 Book Chapter Guide — What to Study & When", status="primary", solidHeader=TRUE, width=7,
          div(class="success-box",
              HTML("<strong>✅ Book premise:</strong> Kravchenko & Babushkin teach ML system design through complete, production-grade end-to-end examples. Each chapter addresses a real system type you'll encounter in interviews.")),
          br(),
          div(class="scroll-pane",
            chapter_card("CH 1","Introduction to ML System Design","The design process, stakeholders, trade-offs, and how to structure your thinking in interviews. Business→ML translation.",c("Foundations","Framework","Interview Structure")),
            chapter_card("CH 2","Requirements Engineering","Functional vs non-functional requirements. SLOs, latency, throughput, freshness. How to gather requirements without wasting time.",c("SLOs","Scoping","Constraints")),
            chapter_card("CH 3","Data Pipeline Design","Batch vs streaming ingestion. Schema evolution. Exactly-once semantics. Data quality. Lineage. The hidden complexity of production data.",c("Kafka","Spark","Data Quality")),
            chapter_card("CH 4","Feature Engineering & Feature Stores","Feature computation, serving consistency, the offline/online store pattern. Train/serve skew. Backfilling.",c("Feature Store","Embeddings","Skew")),
            chapter_card("CH 5","Model Development & Training","Architecture selection, loss functions, distributed training, hyperparameter optimisation, experiment tracking.",c("Training","Distributed","MLflow")),
            chapter_card("CH 6","Evaluation & Testing","Offline metrics, sliced evaluation, shadow testing, champion-challenger, statistical testing, metric traps.",c("A/B Testing","Metrics","Slicing")),
            chapter_card("CH 7","Model Serving & Deployment","Online vs batch prediction, model servers, quantisation, canary deploys, blue-green, rollback strategies.",c("TorchServe","Triton","Latency")),
            chapter_card("CH 8","Monitoring & Reliability","Data drift, concept drift, model degradation, alerting, retraining pipelines, SLO enforcement.",c("Drift","Alerting","SRE")),
            chapter_card("CH 9","End-to-End: Recommendation","Full walkthrough of a production recommender — retrieval, ranking, re-ranking, cold start.",c("Two-Tower","DLRM","Cold Start")),
            chapter_card("CH 10","End-to-End: Search & NLP","Search ranking, query understanding, entity resolution, LLM-powered features, RAG systems.",c("LTR","RAG","NLP"))
          )
      ),

      box(title="🗂️ How to Use This App — Study Plan", status="info", solidHeader=TRUE, width=5,
          div(class="section-heading-dark","Kravchenko & Babushkin's Core Framework"),
          div(class="framework-card",
              tags$h5("The 6-Step Design Loop"),
              tags$p(tags$b("1. Clarify requirements"), " → SLOs, scale, latency, freshness, constraints"),
              tags$p(tags$b("2. Data pipeline"), " → sources, format, batch vs stream, quality"),
              tags$p(tags$b("3. Feature engineering"), " → computation, store, consistency"),
              tags$p(tags$b("4. Model architecture"), " → selection, training, embeddings"),
              tags$p(tags$b("5. Evaluation"), " → offline + online, sliced, guard-rails"),
              tags$p(tags$b("6. Serving & monitoring"), " → deployment, drift, retraining")),
          div(class="warn-box",
              HTML("<strong>⚠️ The book's key differentiator:</strong> Unlike academic treatments, K&B treat every component as a <em>production system</em>. In interviews, this means discussing failure modes, SLOs, data contracts, and operational overhead — not just model accuracy.")),
          br(),
          div(class="section-heading-dark","Recommended Study Order"),
          timeline_entry("Wk 1", "Ch.1–2 — Framework & Requirements", "Master the 6-step loop. Practice asking the right clarifying questions."),
          timeline_entry("Wk 2", "Ch.3–4 — Data & Features",          "Data pipeline patterns + feature store architecture. The hidden complexity."),
          timeline_entry("Wk 3", "Ch.5–6 — Modelling & Evaluation",   "Training, distributed systems, A/B testing, sliced evaluation."),
          timeline_entry("Wk 4", "Ch.7–8 — Serving & Monitoring",     "Production deployment, latency, drift detection, retraining."),
          timeline_entry("Wk 5", "Ch.9–10 — Case Studies",            "Full end-to-end systems. Recommendation + Search/NLP deep dives."),
          timeline_entry("Wk 6", "Timed Practice",                    "45-min simulated sessions. Score yourself on all 6 components.")
      )
    ),

    fluidRow(
      box(title="✅ Pre-Interview Checklist", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(6,
                   div(class="section-heading-dark","Technical Concepts to Master"),
                   checkboxGroupInput(ns("tech_checklist"), label=NULL, choices=c(
                     "6-step design loop (clarify → data → features → model → eval → serve)",
                     "Batch vs streaming pipeline: trade-offs, Kafka, Spark, Flink",
                     "Feature store: offline/online stores, train/serve skew, backfilling",
                     "Model selection criteria: latency, accuracy, interpretability, data size",
                     "Distributed training: data parallelism vs model parallelism",
                     "Offline evaluation: metric selection, sliced eval, statistical significance",
                     "A/B testing design: randomisation unit, guardrail metrics, duration",
                     "Serving architecture: batch vs online, model compression, SLOs",
                     "Distribution shift: covariate, label, concept drift — detection + fix",
                     "Recommender system: two-tower retrieval, ranking, re-ranking, cold start",
                     "LTR (Learning to Rank): pointwise vs pairwise vs listwise",
                     "RAG architecture: retrieval, chunking, re-ranking, hallucination mitigation"
                   )),
                   br(),
                   actionButton(ns("save_checklist"),"Save Progress", class="btn-meta", icon=icon("save"))
            ),
            column(6,
                   div(class="section-heading-dark","Interview Performance Habits"),
                   checkboxGroupInput(ns("habit_checklist"), label=NULL, choices=c(
                     "Start EVERY answer by clarifying requirements and constraints",
                     "Justify EVERY architecture choice with a trade-off statement",
                     "Proactively name failure modes before the interviewer asks",
                     "Discuss monitoring and retraining as part of every design",
                     "Always propose A/B test design when discussing serving",
                     "Name real tools (Kafka, Redis, Triton, MLflow) with brief justification",
                     "Discuss cold start problem for any recommendation/search system",
                     "Mention sliced evaluation (not just aggregate metrics) proactively",
                     "Show you think about data quality, not just model quality"
                   )),
                   br(),
                   uiOutput(ns("checklist_status"))
            )
          )
      )
    )
  )
}

intro_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    output$pct_overall <- renderText({
      prep_manager$progress_trigger()
      paste0(prep_manager$get_overall_progress(), "%")
    })
    output$tab_progress_bars <- renderUI({
      prep_manager$progress_trigger()
      tabs <- list(
        list(id="requirements",  label="Requirements & Scoping"),
        list(id="data_pipeline", label="Data Pipeline Design"),
        list(id="feature_store", label="Feature Eng & Store"),
        list(id="modelling",     label="Modelling & Training"),
        list(id="evaluation",    label="Evaluation & Testing"),
        list(id="serving",       label="Serving & Deployment"),
        list(id="monitoring",    label="Monitoring & Reliability"),
        list(id="end_to_end",    label="End-to-End Case Studies"),
        list(id="practice",      label="Timed Practice")
      )
      do.call(tagList, lapply(tabs, function(t) {
        pct <- prep_manager$get_progress(t$id)
        col <- progress_colour(pct)
        fluidRow(
          column(3, tags$small(tags$b(t$label))),
          column(7, div(style="background:rgba(232,65,10,0.08);border-radius:5px;height:12px;",
                        div(style=paste0("width:",pct,"%;background:",col,";border-radius:5px;height:12px;transition:width 0.5s;")))),
          column(2, tags$small(style=paste0("color:",col,";font-weight:700;"), paste0(pct,"%")))
        )
      }))
    })
    observeEvent(input$save_checklist, {
      n1  <- length(input$tech_checklist)
      n2  <- length(input$habit_checklist)
      pct <- round((n1 + n2) / (12 + 9) * 100)
      prep_manager$update_progress("intro", pct)
      showNotification(paste0(n1," tech + ",n2," habit items checked (", pct,"%)"), type="message")
    })
    output$checklist_status <- renderUI({
      n1 <- length(input$tech_checklist)
      n2 <- length(input$habit_checklist)
      div(class="success-box",
          tags$b(paste0("Tech concepts: ", n1, "/12")), tags$br(),
          tags$b(paste0("Interview habits: ", n2, "/9")), tags$br(),
          tags$small("Aim for 100% before your interview day."))
    })
  })
}
