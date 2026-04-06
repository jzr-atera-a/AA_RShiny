# modules/ch6_deployment.R
# Ch.6: Technical Interview — Model Deployment and End-to-End ML

ch6_deployment_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Chapter 6 — Model Deployment & End-to-End ML"),
      tags$h2("Technical Interview: Model Deployment and End-to-End ML — Susan Shu Chang"),
      div(
        span(class = "hero-badge", "End-to-End ML"),
        span(class = "hero-badge", "Model Deployment"),
        span(class = "hero-badge", "Model Monitoring"),
        span(class = "hero-badge", "Cloud Providers"),
        span(class = "hero-badge", "Developer Best Practices"),
        span(class = "hero-badge", "MLOps")
      )
    ),

    # ── Experience Gap & End-to-End ───────────────────────────────────────────
    fluidRow(
      box(title = "🚀 Model Deployment — The Experience Gap (Ch.6)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "warn-box",
            HTML("<strong>⚠️ Chang's core observation:</strong> The main experience gap for new entrants
                 into the ML industry is <em>deployment experience</em>. Most candidates can train
                 a model in a notebook. Few can get it serving real traffic reliably.")),
          br(),

          div(class = "framework-card",
            tags$h5("Should Data Scientists and MLEs Know This?"),
            tags$p("Chang argues yes — even if you do not deploy personally, you must understand the pipeline."),
            tags$ul(
              tags$li(tags$b("Data Scientists:"), " need deployment awareness to design models that are serveable — latency, memory footprint, reproducibility"),
              tags$li(tags$b("MLEs:"), " own the full pipeline — training, packaging, serving, monitoring"),
              tags$li(tags$b("Interview signal:"), " demonstrating end-to-end thinking separates junior from senior candidates")
            )),

          div(class = "framework-card",
            tags$h5("End-to-End Machine Learning Pipeline"),
            timeline_entry("1", "Data collection & versioning",
              "Source data, DVC or data catalogue, label pipeline, freshness SLA"),
            timeline_entry("2", "Feature engineering",
              "Feature store, online vs offline features, train-serve consistency"),
            timeline_entry("3", "Model training & experiment tracking",
              "MLflow or W&B, hyperparameter search, reproducible training runs"),
            timeline_entry("4", "Model evaluation & validation",
              "Offline metrics, sliced eval, shadow mode, A/B gate before launch"),
            timeline_entry("5", "Model packaging & registry",
              "Serialise weights, containerise (Docker), push to model registry"),
            timeline_entry("6", "Serving infrastructure",
              "REST API, batch job, or streaming — latency SLO, autoscaling, load balancing"),
            timeline_entry("7", "Monitoring & retraining",
              "Data drift, prediction drift, business metric alerts, retraining triggers")
          )
      ),

      box(title = "☁️ Cloud & Deployment Overview (Ch.6)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Cloud Environments vs Local Environments"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Environment"), tags$th("When to use"), tags$th("Key tools"))),
              tags$tbody(
                tags$tr(tags$td(tags$span(class = "stage-pill", "Local")),  tags$td("Development, debugging, small data"), tags$td("Jupyter, VSCode, Docker Desktop")),
                tags$tr(tags$td(tags$span(class = "stage-pill", "Cloud")),  tags$td("Training at scale, production serving"), tags$td("GCP, AWS, Azure ML platforms")),
                tags$tr(tags$td(tags$span(class = "stage-pill", "Hybrid")), tags$td("Data on-prem, compute in cloud"), tags$td("VPN, VPC peering, data connectors"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Overview of Model Deployment Patterns"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Pattern"), tags$th("Latency"), tags$th("Use case"))),
              tags$tbody(
                tags$tr(tags$td(tags$b("Real-time REST API")), tags$td("< 100ms"), tags$td("Recommendations, fraud, search re-ranking")),
                tags$tr(tags$td(tags$b("Batch prediction")),   tags$td("Hours"),   tags$td("Nightly scoring, reporting, offline features")),
                tags$tr(tags$td(tags$b("Streaming")),          tags$td("Seconds"), tags$td("Event-driven — clickstream, IoT, log processing")),
                tags$tr(tags$td(tags$b("On-device (edge)")),   tags$td("< 10ms"),  tags$td("Mobile apps, autonomous vehicles, wearables"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Additional Tooling to Know"),
            tags$ul(
              tags$li(tags$b("TorchServe / TF Serving:"), " purpose-built model serving frameworks"),
              tags$li(tags$b("FastAPI:"), " lightweight Python REST API for serving custom model code"),
              tags$li(tags$b("BentoML:"), " model packaging and serving with versioning built in"),
              tags$li(tags$b("Seldon Core / KServe:"), " Kubernetes-native model serving at scale"),
              tags$li(tags$b("Feature Store:"), " Feast, Tecton, Vertex Feature Store — online/offline consistency"),
              tags$li(tags$b("Docker + Kubernetes:"), " containerisation and orchestration — industry standard")
            )),

          div(class = "framework-card",
            tags$h5("On-Device Machine Learning"),
            tags$ul(
              tags$li(tags$b("Use case:"), " privacy-sensitive, latency-critical, offline applications"),
              tags$li(tags$b("Model compression:"), " quantisation (INT8/INT4), pruning, knowledge distillation"),
              tags$li(tags$b("Frameworks:"), " TensorFlow Lite, Core ML (iOS), ONNX Runtime, MediaPipe"),
              tags$li(tags$b("Constraint:"), " memory and compute severely limited — model size is a hard budget")
            )),

          div(class = "tip-box",
            HTML("<strong>💡 Interview signal:</strong> Mention that you consider serving latency and
                 memory footprint during model selection — not just accuracy. This is a strong
                 production ML indicator."))
      )
    ),

    # ── Model Monitoring ──────────────────────────────────────────────────────
    fluidRow(
      box(title = "📡 Model Monitoring (Ch.6)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "framework-card",
                tags$h5("Monitoring Setups"),
                tags$ul(
                  tags$li(tags$b("Shadow mode:"), " new model runs in parallel with production — no traffic served; compare outputs"),
                  tags$li(tags$b("Canary deployment:"), " route 1–5% of traffic to new model — catch failures before full rollout"),
                  tags$li(tags$b("A/B testing:"), " split traffic by user segment — measure business metric uplift"),
                  tags$li(tags$b("Multi-armed bandit:"), " dynamic traffic allocation — maximises reward during experimentation"),
                  tags$li(tags$b("Rollback plan:"), " always have a one-click way to revert to the previous model version")
                )
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("ML-Related Monitoring Metrics"),
                tags$ul(
                  tags$li(tags$b("Data drift:"), " input feature distributions shift — KL divergence, PSI, KS test"),
                  tags$li(tags$b("Prediction drift:"), " output score or label distribution changes — check without ground truth"),
                  tags$li(tags$b("Model performance:"), " precision, recall, AUC on labelled incoming samples"),
                  tags$li(tags$b("Business metrics:"), " CTR, revenue, conversion — the ultimate signal of model health"),
                  tags$li(tags$b("Infrastructure metrics:"), " latency (p50, p99), throughput (QPS), error rate, memory usage"),
                  tags$li(tags$b("Data quality:"), " null rates, schema violations, out-of-range values in feature pipelines")
                ),
                div(class = "success-box",
                  HTML("<strong>✅ Retraining triggers:</strong> When to retrain is as important as
                       how to train. Triggers: scheduled cadence, performance threshold breach,
                       data drift alert, or business metric drop."))
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Interviews for Roles Focused on Model Training"),
                tags$p("Roles with 'Research Scientist', 'Applied Scientist', or 'Model Training' in title focus more on:"),
                tags$ul(
                  tags$li(tags$b("Loss function design:"), " custom objectives for novel tasks"),
                  tags$li(tags$b("Distributed training:"), " data parallelism, model parallelism, gradient accumulation"),
                  tags$li(tags$b("Mixed precision:"), " FP16/BF16 training for speed and memory efficiency"),
                  tags$li(tags$b("Pre-training vs fine-tuning:"), " when each is appropriate, compute cost trade-offs"),
                  tags$li(tags$b("Scaling laws:"), " relationship between model size, data, and compute (Chinchilla)"),
                  tags$li(tags$b("RLHF:"), " reinforcement learning from human feedback — instruction tuning, reward models")
                )
              )
            )
          )
      )
    ),

    # ── Cloud Providers ───────────────────────────────────────────────────────
    fluidRow(
      box(title = "☁️ Overview of Cloud Providers (Ch.6)", status = "info",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "framework-card",
                tags$h5("GCP — Google Cloud Platform"),
                tags$ul(
                  tags$li(tags$b("Vertex AI:"), " managed ML platform — training, tuning, serving, monitoring"),
                  tags$li(tags$b("BigQuery ML:"), " train models directly in SQL on massive datasets"),
                  tags$li(tags$b("TPUs:"), " Google's custom ML accelerator — Tensor Processing Units"),
                  tags$li(tags$b("Dataflow:"), " Apache Beam-based streaming and batch data pipelines"),
                  tags$li(tags$b("Feature Store:"), " Vertex Feature Store — online and offline serving"),
                  tags$li(tags$b("Best for:"), " teams already on Google Workspace; heavy TensorFlow / JAX users")
                )
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("AWS — Amazon Web Services"),
                tags$ul(
                  tags$li(tags$b("SageMaker:"), " most feature-complete managed ML platform — training, tuning, deployment, monitoring"),
                  tags$li(tags$b("S3:"), " object storage — de facto standard for ML datasets and model artefacts"),
                  tags$li(tags$b("EC2 / EKS:"), " raw compute and Kubernetes — full control over infrastructure"),
                  tags$li(tags$b("Glue:"), " serverless ETL for data preparation pipelines"),
                  tags$li(tags$b("Lambda:"), " serverless inference for lightweight models"),
                  tags$li(tags$b("Best for:"), " enterprise teams with broad AWS infrastructure; most widely used cloud for ML")
                )
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Microsoft Azure"),
                tags$ul(
                  tags$li(tags$b("Azure ML:"), " managed ML platform with strong MLOps and experiment tracking"),
                  tags$li(tags$b("Azure OpenAI Service:"), " managed access to GPT-4 and other OpenAI models"),
                  tags$li(tags$b("Synapse Analytics:"), " integrated analytics for large-scale data processing"),
                  tags$li(tags$b("AKS:"), " Azure Kubernetes Service — container-based model serving"),
                  tags$li(tags$b("Cognitive Services:"), " pre-built AI APIs for vision, speech, NLP"),
                  tags$li(tags$b("Best for:"), " enterprise teams on Microsoft stack; strong compliance and governance tools")
                )
              )
            )
          ),
          div(class = "tip-box",
            HTML("<strong>💡 Interview tip:</strong> You do not need to memorise every cloud service.
                 Know the main ML platform (Vertex AI / SageMaker / Azure ML) for each cloud,
                 and the core storage + compute primitives. Demonstrate you can reason about
                 trade-offs between managed services and raw infrastructure."))
      )
    ),

    # ── Developer Best Practices ──────────────────────────────────────────────
    fluidRow(
      box(title = "🛠️ Developer Best Practices for Interviews (Ch.6)", status = "warning",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Version Control"),
            tags$ul(
              tags$li(tags$b("Git fundamentals:"), " commit, branch, merge, rebase — interviewers assume fluency"),
              tags$li(tags$b("Branching strategy:"), " feature branches, main/staging/prod — GitFlow or trunk-based"),
              tags$li(tags$b("Code + data + model:"), " git for code; DVC or LFS for large data and model files"),
              tags$li(tags$b("PR reviews:"), " small, focused PRs with clear descriptions — shows engineering maturity")
            )),

          div(class = "framework-card",
            tags$h5("Dependency Management"),
            tags$ul(
              tags$li(tags$b("requirements.txt / pyproject.toml:"), " pin exact versions for reproducibility"),
              tags$li(tags$b("Virtual environments:"), " venv, conda — isolate project dependencies"),
              tags$li(tags$b("Docker:"), " containerise everything — eliminates 'works on my machine' issues"),
              tags$li(tags$b("Poetry / uv:"), " modern Python dependency management with lock files")
            )),

          div(class = "framework-card",
            tags$h5("Code Review"),
            tags$ul(
              tags$li(tags$b("What reviewers look for:"), " correctness, readability, edge cases, test coverage"),
              tags$li(tags$b("ML-specific:"), " data leakage, hardcoded paths, reproducibility (random seeds), large files in git"),
              tags$li(tags$b("How to give feedback:"), " specific, constructive, non-personal — 'this approach may...' not 'you did...'")
            )),

          div(class = "framework-card",
            tags$h5("Tests"),
            tags$ul(
              tags$li(tags$b("Unit tests:"), " test individual functions in isolation — pytest"),
              tags$li(tags$b("Integration tests:"), " test pipeline components working together"),
              tags$li(tags$b("Data validation tests:"), " Great Expectations, Pandera — assert schema, ranges, nulls"),
              tags$li(tags$b("Model tests:"), " assert model performance above baseline on held-out set in CI/CD"),
              tags$li(tags$b("CI/CD:"), " GitHub Actions, Jenkins — run tests on every PR before merge")
            ))
      ),

      box(title = "🎯 Additional Technical Interview Components (Ch.6)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Machine Learning Systems Design Interview"),
            tags$p("Open-ended system design for a production ML system. Structure matters more than the exact answer."),
            tags$ul(
              tags$li(tags$b("Requirements:"), " clarify scale, latency, freshness, accuracy vs speed trade-off"),
              tags$li(tags$b("Data:"), " sources, labelling, pipeline, feature store, class balance"),
              tags$li(tags$b("Model:"), " family choice + justification, training setup, embedding strategy"),
              tags$li(tags$b("Serving:"), " batch vs real-time, API design, autoscaling, caching"),
              tags$li(tags$b("Monitoring:"), " drift detection, retraining trigger, rollback plan")
            ),
            div(class = "success-box",
              HTML("<strong>✅ Chang's framework:</strong> Requirements (5m) → Data (10m) →
                   Model (15m) → Serving (10m) → Monitoring (5m) = 45 minutes exactly."))),

          div(class = "framework-card",
            tags$h5("Technical Deep-Dive Interview"),
            tags$ul(
              tags$li(tags$b("Format:"), " interviewer asks you to walk through a past project in depth"),
              tags$li(tags$b("What they want:"), " how you scoped the problem, what trade-offs you made, what failed"),
              tags$li(tags$b("Prepare:"), " 2–3 projects you can describe at three levels of depth: 30s, 5min, 30min"),
              tags$li(tags$b("Signal:"), " owning failures and describing learnings is more impressive than claiming everything succeeded")
            )),

          div(class = "framework-card",
            tags$h5("Take-Home Exercise Tips"),
            tags$ul(
              tags$li(tags$b("Treat it like production code:"), " docstrings, README, requirements.txt, clean git history"),
              tags$li(tags$b("Communicate assumptions:"), " state what you assumed about the data and problem"),
              tags$li(tags$b("Show process:"), " EDA notebook + clean modelling code — show your thinking"),
              tags$li(tags$b("Time budget:"), " most companies expect 3–6 hours — do not over-invest")
            )),

          div(class = "framework-card",
            tags$h5("Product Sense"),
            tags$ul(
              tags$li(tags$b("What it is:"), " how would you improve Feature X? What ML problems does Product Y have?"),
              tags$li(tags$b("Framework:"), " user goal → current gap → ML opportunity → success metric → risks"),
              tags$li(tags$b("Key:"), " ground ideas in user needs and business metrics, not just technical feasibility")
            )),

          div(class = "section-heading-dark", "Sample Interview Questions on MLOps"),
          tags$ul(
            tags$li("How would you detect data drift in production without ground truth labels?"),
            tags$li("Walk me through your model deployment process end-to-end."),
            tags$li("How would you design a retraining pipeline for a recommendation model?"),
            tags$li("What is shadow mode deployment and why would you use it?"),
            tags$li("How do you ensure reproducibility across training runs?")
          )
      )
    ),

    fluidRow(
      box(title = "✍️ Practice: Design a Deployment Pipeline", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              selectInput(ns("deploy_topic"), "Choose a system to deploy:",
                choices = c(
                  "Real-time fraud detection API",
                  "Batch nightly product recommendations",
                  "On-device image classification (mobile)",
                  "Streaming clickstream ranking model",
                  "LLM-powered customer support bot",
                  "Daily demand forecasting pipeline",
                  "Content moderation classifier",
                  "Search re-ranking model"
                )),
              sliderInput(ns("deploy_conf"), "Confidence in deployment knowledge (1–10):", 1, 10, 5),
              actionButton(ns("save_deploy"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8,
              div(class = "practice-area",
                tags$b("Practice: Design the full deployment pipeline for the selected system."),
                textAreaInput(ns("deploy_notes"), label = NULL, rows = 10, width = "100%",
                  placeholder = "## 1. Serving pattern (real-time / batch / streaming / on-device)\n\n## 2. Model packaging and containerisation\n\n## 3. Deployment strategy (shadow / canary / A/B)\n\n## 4. Monitoring (what metrics, what alerts)\n\n## 5. Retraining trigger and rollback plan\n\n## 6. Cloud services you would use"),
                uiOutput(ns("deploy_feedback"))
              )
            )
          )
      )
    )
  )
}

ch6_deployment_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_deploy, {
      notes <- input$deploy_notes
      conf  <- input$deploy_conf
      score <- 0
      if (grepl("real.time|batch|streaming|on.device|serving|api",    notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("docker|container|packag|serialise|onnx|registry",    notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("shadow|canary|a/b|rollout|rollback|blue.green",      notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("monitor|drift|latency|alert|metric|p99|qps",         notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("retrain|trigger|cadence|cloud|gcp|aws|azure|vertex", notes, ignore.case = TRUE)) score <- score + 20

      prep_manager$update_progress("ch6_deployment", min(score + conf * 3, 100))
      prep_manager$save_note("ch6_notes", notes)

      output$deploy_feedback <- renderUI({
        div(class = if (score >= 80) "success-box" else "tip-box",
          tags$h5(paste0("Deployment Design Score: ", score, "/100")),
          if (score < 20)  tags$p("⚠️ Missing: serving pattern choice with justification"),
          if (score < 40)  tags$p("⚠️ Missing: model packaging and containerisation approach"),
          if (score < 60)  tags$p("⚠️ Missing: deployment strategy (shadow / canary / A/B)"),
          if (score < 80)  tags$p("⚠️ Missing: monitoring plan and alerting"),
          if (score < 100) tags$p("⚠️ Missing: retraining trigger and cloud infrastructure"),
          if (score >= 80) tags$p("✅ Full deployment pipeline designed — strong MLOps interview answer!")
        )
      })
      showNotification("Ch.6 deployment assessment saved!", type = "message")
    })
  })
}
