# modules/monitoring.R
# Tab 8: Monitoring & Distribution Shifts — Ch. 8, 9, 10

monitoring_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Monitoring, Drift & MLOps Infrastructure"),
        tags$h2("Chapters 8–10 — Distribution Shifts, Continual Learning, MLOps Platform"),
        div(
          span(class = "hero-badge", "Distribution Shift"),
          span(class = "hero-badge", "Drift Detection"),
          span(class = "hero-badge", "Retraining Triggers"),
          span(class = "hero-badge", "MLOps Stack")
        )
    ),

    fluidRow(
      box(title = "📉 Data Distribution Shifts — 3 Types (Ch. 8)", status = "danger",
          solidHeader = TRUE, width = 6,

          div(class = "warn-box",
              HTML("<strong>⚠️ Huyen's key insight:</strong> Models can degrade SILENTLY. A model predicting yesterday's patterns looks fine on error rates but loses predictive power. Monitor input and output distributions, not just accuracy.")),

          div(class = "framework-card",
              tags$h5("Covariate Shift"),
              tags$p("Input distribution P(X) changes but P(Y|X) stays the same."),
              tags$p(tags$b("Example:"), " Model trained on desktop traffic deployed to increasing mobile traffic — features have different distributions."),
              tags$p(tags$b("Fix:"), " Importance reweighting, domain adaptation, model retraining on recent data.")),
          div(class = "framework-card",
              tags$h5("Label Shift"),
              tags$p("Output distribution P(Y) changes but P(X|Y) stays the same."),
              tags$p(tags$b("Example:"), " Spam classification — new spam techniques push spam rate from 10% to 40%."),
              tags$p(tags$b("Fix:"), " Black-box shift estimation, adjust prior probability at inference.")),
          div(class = "framework-card",
              tags$h5("Concept Drift"),
              tags$p("The relationship P(Y|X) changes. Most difficult to detect — even with stable features, the correct labels shift."),
              tags$p(tags$b("Example:"), " 'Sports' topics change over time as e-sports becomes mainstream. Model misclassifies correctly-structured inputs."),
              tags$p(tags$b("Fix:"), " Frequent retraining, recency-weighted training data."))
      ),

      box(title = "🔍 Monitoring Strategy (Ch. 8)", status = "warning",
          solidHeader = TRUE, width = 6,

          div(class = "section-heading-dark", "What to Monitor"),
          div(class = "framework-card",
              tags$h5("Operational Metrics (Infrastructure)"),
              tags$ul(
                tags$li("Throughput (requests per second)"),
                tags$li("Latency (p50, p95, p99)"),
                tags$li("CPU/GPU utilisation and memory"),
                tags$li("Error rate (4xx, 5xx, model timeouts)")
              )),
          div(class = "framework-card",
              tags$h5("ML-Specific Metrics"),
              tags$ul(
                tags$li("Prediction distribution (output drift — e.g., PSI on score distribution)"),
                tags$li("Feature distribution per feature (input drift — KL divergence, KS test)"),
                tags$li("Label distribution (if labels available)"),
                tags$li("Model accuracy metrics by subgroup (sliced performance)"),
                tags$li("Feedback loop detection (e.g., recommendation diversity)")
              )),
          div(class = "framework-card",
              tags$h5("Retraining Triggers"),
              tags$ul(
                tags$li(tags$b("Time-based:"), " Retrain every N days. Simple, not adaptive."),
                tags$li(tags$b("Performance-based:"), " Retrain when metric drops below threshold."),
                tags$li(tags$b("Drift-based:"), " Retrain when PSI > threshold on key features."),
                tags$li(tags$b("Volume-based:"), " Retrain when N new labelled examples accumulate.")
              ))
      )
    ),

    fluidRow(
      box(title = "🏗️ MLOps Platform Architecture (Ch. 10)", status = "info",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   div(class = "section-heading-dark", "Development Layer"),
                   div(class = "framework-card",
                       tags$h5("Dev Environments"),
                       tags$p("Jupyter for exploration. IDEs for production code. Standardised Docker containers. Cloud notebooks: SageMaker Studio, Vertex AI Workbench.")),
                   div(class = "framework-card",
                       tags$h5("Experiment Management"),
                       tags$p("Track experiments, hyperparams, metrics. MLflow, W&B, Comet. Model registry: staging → production promotion pipeline. Link models to data versions for reproducibility."))
            ),
            column(4,
                   div(class = "section-heading-dark", "Data + Feature Layer"),
                   div(class = "framework-card",
                       tags$h5("Data Versioning"),
                       tags$p("DVC (Data Version Control) for large files. Delta Lake for ACID transactions on data lake. Reproducible training: same data version must produce same model.")),
                   div(class = "framework-card",
                       tags$h5("Feature Store"),
                       tags$p("Centralised feature repository. Offline (batch, Parquet) + Online (low-latency, Redis) stores. Train/serve consistency guarantee. Feature discovery API. Versioned feature groups."))
            ),
            column(4,
                   div(class = "section-heading-dark", "Training + Serving Layer"),
                   div(class = "framework-card",
                       tags$h5("Training Orchestration"),
                       tags$p("Kubeflow Pipelines, Apache Airflow, Metaflow, Prefect. Containerised jobs (Docker/Kubernetes). GPU resource scheduling. Checkpoint/resume support for long training runs.")),
                   div(class = "framework-card",
                       tags$h5("Model Serving"),
                       tags$p("Triton Inference Server (NVIDIA). TorchServe. TF Serving. KServe (Kubernetes). vLLM for LLMs (PagedAttention, 30× throughput). Load balancing, autoscaling, canary deployments."))
            )
          )
      )
    ),

    fluidRow(
      box(title = "📊 Self-Assessment: Monitoring & Infrastructure", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   sliderInput(ns("sc_drift"),    "Drift type identification",    0, 10, 5),
                   sliderInput(ns("sc_monitor"),  "Monitoring pipeline design",   0, 10, 5),
                   sliderInput(ns("sc_retrain"),  "Retraining trigger design",    0, 10, 5),
                   sliderInput(ns("sc_mlops"),    "MLOps platform knowledge",     0, 10, 5),
                   actionButton(ns("calc_mon"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8, br(), uiOutput(ns("mon_result")))
          )
      )
    )
  )
}

monitoring_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_mon, {
      avg <- mean(c(input$sc_drift, input$sc_monitor, input$sc_retrain, input$sc_mlops))
      pct <- round(avg * 10)
      prep_manager$update_progress("monitoring", pct)

      output$mon_result <- renderUI({
        colour <- progress_colour(pct)
        div(class = if (pct >= 70) "success-box" else "tip-box",
            tags$h3(style = paste0("color:", colour), paste0(pct, "% ready")),
            if (pct >= 80) tags$p("✅ Strong monitoring knowledge. Proactively mention drift monitoring in every design.") else
              tags$p("💡 Review: the 3 drift types and how to detect each, and the full MLOps stack from Ch. 10.")
        )
      })
      showNotification(paste0("Monitoring: ", pct, "% saved"), type = "message")
    })
  })
}
