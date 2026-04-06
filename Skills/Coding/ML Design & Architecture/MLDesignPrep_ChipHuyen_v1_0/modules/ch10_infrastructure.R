# modules/ch10_infrastructure.R
# Chapter 10: Infrastructure and Tooling for MLOps — Chip Huyen

ch10_infrastructure_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
      tags$h1("Ch.10 — Infrastructure and Tooling for MLOps"),
      tags$h2("The full ML platform stack: storage, compute, development, orchestration, and build vs buy"),
      div(span(class="hero-badge","Storage & Compute"),span(class="hero-badge","Dev Environment"),
          span(class="hero-badge","Resource Management"),span(class="hero-badge","ML Platform"),
          span(class="hero-badge","Build vs Buy"))
    ),

    # ── 1. Storage and Compute ───────────────────────────────────────────────
    fluidRow(
      box(title="💾 Storage and Compute", status="primary", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            div(class="section-heading-dark","Storage Layer"),
            div(class="framework-card",
              tags$h5("Data Storage Tiers"),
              tags$ul(
                tags$li(tags$b("HDD (Hard Disk Drive):"), " cheapest, slowest. For long-term archival of cold data."),
                tags$li(tags$b("SSD (Solid State Drive):"), " fast random access. Local training data cache."),
                tags$li(tags$b("RAM:"), " fastest, expensive. For active training batch data and feature caches."),
                tags$li(tags$b("Network-attached:"), " NFS, S3, GCS, Azure Blob. Scalable, shared across cluster.")
              )
            ),
            div(class="framework-card",
              tags$h5("Data Formats for ML"),
              tags$ul(
                tags$li(tags$b("Parquet:"), " columnar, compressed, fast read. Default for training datasets."),
                tags$li(tags$b("TFRecord / Arrow:"), " row-oriented, streaming-friendly. Good for training loops."),
                tags$li(tags$b("HDF5:"), " hierarchical. Scientific data, model checkpoints."),
                tags$li(tags$b("LMDB:"), " memory-mapped, fast for image datasets (e.g., ImageNet training).")
              )
            ),
            div(class="framework-card",
              tags$h5("Cloud Object Storage"),
              tags$ul(
                tags$li(tags$b("AWS S3:"), " industry standard. Versioning, lifecycle policies, event triggers."),
                tags$li(tags$b("GCS:"), " tightly integrated with Vertex AI. BigQuery federation."),
                tags$li(tags$b("Azure Blob:"), " tight integration with Azure ML."),
                tags$li(tags$b("Lakehouse:"), " Delta Lake (Databricks), Apache Iceberg — ACID transactions on object storage. Time-travel queries for reproducible training snapshots.")
              )
            )
          ),
          column(4,
            div(class="section-heading-dark","Compute Layer"),
            div(class="framework-card",
              tags$h5("Compute Hardware"),
              tags$ul(
                tags$li(tags$b("CPU:"), " general purpose. Inference for small models, data preprocessing, tree-based models (XGBoost)."),
                tags$li(tags$b("GPU (NVIDIA A100/H100):"), " massive parallelism for NN training. CUDA cores + Tensor Cores for mixed-precision (FP16/BF16)."),
                tags$li(tags$b("TPU:"), " Google's purpose-built ML accelerator. Excellent for large-scale training on JAX/TensorFlow. Not available outside GCP."),
                tags$li(tags$b("Apple Silicon (ANE):"), " Neural Engine for on-device inference. CoreML."),
                tags$li(tags$b("Edge accelerators:"), " NVIDIA Jetson, Google Coral, Qualcomm AI Engine for IoT/mobile.")
              )
            ),
            div(class="framework-card",
              tags$h5("Compute Pricing Strategies"),
              tags$ul(
                tags$li(tags$b("On-demand instances:"), " highest cost, immediate availability. Use for latency-sensitive serving."),
                tags$li(tags$b("Reserved instances:"), " 1-3 year commitment, 40-60% discount. Use for baseline serving capacity."),
                tags$li(tags$b("Spot/Preemptible instances:"), " up to 90% discount. Interrupted anytime. Use for fault-tolerant training with checkpointing."),
                tags$li(tags$b("Multi-cloud:"), " avoid vendor lock-in, use best-in-class services. Adds operational complexity.")
              )
            )
          ),
          column(4,
            div(class="section-heading-dark","Distributed Training"),
            div(class="framework-card",
              tags$h5("Parallelism Strategies"),
              tags$p(tags$b("Data Parallelism:"), " copy model to each GPU; split mini-batch across GPUs. Gradients aggregated via AllReduce. Scales well. Limited by model fitting in single GPU memory."),
              tags$p(tags$b("Model Parallelism:"), " split model layers across GPUs. Required when model > single GPU memory. More complex communication overhead."),
              tags$p(tags$b("Pipeline Parallelism:"), " partition layers into stages, process micro-batches in pipeline fashion. Used in GPT-3/4 training."),
              tags$p(tags$b("Tensor Parallelism:"), " split individual weight matrices across GPUs. Used in Megatron-LM."),
              tags$p(tags$b("ZeRO (DeepSpeed):"), " partition optimizer states, gradients, and parameters across GPUs. Enables training models 10-100× the size of single-GPU memory. Used to train most large-scale LLMs.")
            )
          )
        )
      )
    ),

    # ── 2. Development Environment ───────────────────────────────────────────
    fluidRow(
      box(title="🖥️ Development Environment", status="warning", solidHeader=TRUE, width=6,
        div(class="framework-card",
          tags$h5("Standardised Dev Environments"),
          tags$p("One of the biggest sources of 'works on my machine' bugs. Huyen advocates for containerised, reproducible environments from day one."),
          tags$ul(
            tags$li(tags$b("Docker:"), " containerise all ML code, dependencies, and configuration. Base images: NVIDIA NGC (pre-built CUDA/cuDNN), PyTorch official images."),
            tags$li(tags$b("Conda/venv:"), " per-project Python environments. requirements.txt + environment.yml for reproducibility."),
            tags$li(tags$b("Makefile:"), " standardise common tasks: make train, make test, make serve. Reduces onboarding friction.")
          )
        ),
        div(class="framework-card",
          tags$h5("Notebook vs IDE"),
          tags$p(tags$b("Notebooks (Jupyter, Colab):"), " great for exploration, EDA, visualisation, quick experiments. Poor for production code — no version control, hidden state, hard to test."),
          tags$p(tags$b("IDEs (VSCode, PyCharm):"), " essential for production code. Linting, debugging, git integration, refactoring."),
          tags$p(tags$b("Best practice:"), " explore in notebooks → extract reusable code to .py modules → version control .py files → notebooks reference modules."),
          tags$p(tags$b("Cloud notebooks:"), " SageMaker Studio, Vertex AI Workbench, Databricks. Persistent storage, GPU access, team sharing.")
        ),
        div(class="framework-card",
          tags$h5("Experiment Tracking"),
          tags$p("Every experiment should be tracked: hyperparameters, metrics, code version, data version, model artifacts. Without this, teams repeat experiments and lose institutional knowledge."),
          tags$ul(
            tags$li(tags$b("MLflow:"), " open-source, self-hosted. MLflow Tracking + Model Registry + Projects."),
            tags$li(tags$b("Weights & Biases:"), " best-in-class UI. Real-time dashboards, sweep (HPO), artifact versioning."),
            tags$li(tags$b("Comet, Neptune:"), " strong alternatives with similar feature sets."),
            tags$li(tags$b("Vertex AI Experiments:"), " managed, tight GCP integration.")
          )
        )
      ),

      box(title="⚙️ Resource Management", status="info", solidHeader=TRUE, width=6,
        div(class="framework-card",
          tags$h5("Cluster Orchestration"),
          tags$p("In production ML, training jobs and serving workloads compete for GPU resources. Resource management systems schedule, prioritise, and isolate workloads."),
          tags$ul(
            tags$li(tags$b("Kubernetes:"), " de facto standard for container orchestration. ML workloads run as Jobs (training) or Deployments (serving). GPU scheduling via device plugins."),
            tags$li(tags$b("SLURM:"), " HPC scheduler, common in research clusters and on-premise environments. Queue-based job scheduling."),
            tags$li(tags$b("Yarn:"), " Hadoop resource manager. Common in large data engineering orgs."),
            tags$li(tags$b("Ray:"), " Python-native distributed computing. Ray Train, Ray Tune, Ray Serve cover training, HPO, and serving in one framework.")
          )
        ),
        div(class="framework-card",
          tags$h5("Workflow Orchestration"),
          tags$p("ML pipelines are DAGs: data ingestion → feature engineering → training → evaluation → deployment. Orchestrators schedule and monitor these DAGs."),
          tags$ul(
            tags$li(tags$b("Apache Airflow:"), " most widely used. Python DAGs. Strong ecosystem. Complex to operate."),
            tags$li(tags$b("Kubeflow Pipelines:"), " Kubernetes-native. Each pipeline step is a container. Good for ML-specific workflows."),
            tags$li(tags$b("Metaflow (Netflix):"), " data scientist-friendly. Versioning built in. AWS-native."),
            tags$li(tags$b("Prefect / Dagster:"), " modern alternatives. Better observability than Airflow."),
            tags$li(tags$b("Vertex AI Pipelines:"), " fully managed on GCP. Based on KFP.")
          )
        ),
        div(class="tip-box", HTML("<strong>Interview pattern:</strong> When asked about ML infrastructure, always structure your answer around the pipeline: data → features → training → evaluation → serving → monitoring. Mention orchestration for each stage."))
      )
    ),

    # ── 3. ML Platform ───────────────────────────────────────────────────────
    fluidRow(
      box(title="🏗️ ML Platform", status="danger", solidHeader=TRUE, width=8,
        div(class="info-box-plain", HTML("<strong>What is an ML Platform?</strong> An integrated set of tools and infrastructure that covers the full ML lifecycle — from data ingestion to model monitoring. Huyen: the ML platform is the difference between a team that ships models in weeks and a team that ships them in months.")),
        br(),
        tags$table(class="table table-hover",
          tags$thead(tags$tr(
            tags$th("Layer"),tags$th("Component"),tags$th("Open Source"),tags$th("Cloud-Managed"),tags$th("Purpose")
          )),
          tags$tbody(
            tags$tr(tags$td("Data"),      tags$td("Feature Store"),       tags$td("Feast, Hopsworks"),tags$td("Vertex, SageMaker"),tags$td("Consistent train/serve features")),
            tags$tr(tags$td("Data"),      tags$td("Data Versioning"),      tags$td("DVC, Delta Lake"),  tags$td("Iceberg, Unity Catalog"),tags$td("Reproducible datasets")),
            tags$tr(tags$td("Training"),  tags$td("Experiment Tracking"),  tags$td("MLflow, W&B"),      tags$td("Vertex, SageMaker"),tags$td("Track params/metrics/artifacts")),
            tags$tr(tags$td("Training"),  tags$td("Model Registry"),       tags$td("MLflow Registry"),  tags$td("Vertex, SageMaker"),tags$td("Version and promote models")),
            tags$tr(tags$td("Training"),  tags$td("HPO"),                  tags$td("Optuna, Ray Tune"), tags$td("Vertex, SageMaker"),tags$td("Automated hyperparameter search")),
            tags$tr(tags$td("Serving"),   tags$td("Model Server"),         tags$td("Triton, TorchServe"),tags$td("KServe, SageMaker"),tags$td("Low-latency inference")),
            tags$tr(tags$td("Serving"),   tags$td("A/B & Traffic Split"),  tags$td("Seldon, KFServing"),tags$td("Vertex, SageMaker"),tags$td("Canary and A/B routing")),
            tags$tr(tags$td("Monitoring"),tags$td("Drift Detection"),      tags$td("Evidently, Alibi"), tags$td("SageMaker Monitor"),tags$td("Alert on distribution shifts")),
            tags$tr(tags$td("Orchestr."), tags$td("Pipeline Orchestration"),tags$td("Airflow, Kubeflow"),tags$td("Vertex Pipelines"),tags$td("Automated ML DAGs")),
            tags$tr(tags$td("Compute"),   tags$td("Training Cluster"),     tags$td("K8s + SLURM"),     tags$td("SageMaker Training"),tags$td("Distributed GPU training"))
          )
        )
      ),
      box(title="⚖️ Build vs Buy", status="success", solidHeader=TRUE, width=4,
        div(class="section-heading-dark","Huyen's Build vs Buy Framework"),
        div(class="framework-card",
          tags$h5("Build When:"),
          tags$ul(
            tags$li("It is a core competitive differentiator"),
            tags$li("Off-the-shelf solutions don't fit your scale or requirements"),
            tags$li("You have the engineering capacity to build and maintain it"),
            tags$li("Vendor lock-in risk is unacceptable for this component"),
            tags$li("The domain expertise to build it exists in-house")
          )
        ),
        div(class="framework-card",
          tags$h5("Buy When:"),
          tags$ul(
            tags$li("It is a commodity capability (object storage, compute)"),
            tags$li("A vendor solution is battle-tested at your scale"),
            tags$li("The cost of building and maintaining exceeds the vendor cost"),
            tags$li("Time-to-production matters more than custom optimisation"),
            tags$li("Your team lacks the specialist expertise to build it well")
          )
        ),
        div(class="framework-card",
          tags$h5("Classic ML Build vs Buy Examples"),
          tags$ul(
            tags$li(tags$b("Build:"), " custom feature transformations, model architectures, domain-specific evaluation"),
            tags$li(tags$b("Buy:"), " object storage, GPU cloud compute, monitoring dashboards, Jupyter environments"),
            tags$li(tags$b("Situational:"), " feature store (build if <5 models; buy at scale), model serving (buy Triton; build custom for unique latency needs)")
          )
        ),
        div(class="warn-box", HTML("<strong>The hidden cost of building:</strong> Ongoing maintenance. A feature store built in-house requires a dedicated team to maintain, upgrade, and support. Underestimating this cost is one of the most common mistakes Huyen observes in ML teams."))
      )
    ),

    fluidRow(
      box(title="📊 Self-Assessment: Ch.10", status="success", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            sliderInput(ns("sc_storage"),  "Storage tiers and formats",     0,10,5),
            sliderInput(ns("sc_compute"),  "Compute and parallelism",        0,10,5),
            sliderInput(ns("sc_devenv"),   "Dev environment best practices", 0,10,5),
            sliderInput(ns("sc_platform"), "Full ML platform stack",         0,10,5),
            sliderInput(ns("sc_bvb"),      "Build vs buy reasoning",         0,10,5),
            actionButton(ns("save_ch10"), "Save Assessment", class="btn-meta", width="100%")
          ),
          column(8, br(), uiOutput(ns("ch10_result")))
        )
      )
    )
  )
}

ch10_infrastructure_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_ch10, {
      avg <- mean(c(input$sc_storage, input$sc_compute, input$sc_devenv, input$sc_platform, input$sc_bvb))
      pct <- round(avg * 10)
      prep_manager$update_progress("ch10_infrastructure", pct)
      output$ch10_result <- renderUI({
        div(class=if(pct>=70)"success-box"else"tip-box",
          tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
          if(pct>=80) tags$p("Strong Ch.10 knowledge. In interviews: always mention the full ML platform stack and use build vs buy reasoning when discussing infrastructure choices.")
          else tags$p("Review: the ML platform component table, distributed training strategies (ZeRO, data vs model parallelism), and build vs buy criteria.")
        )
      })
      showNotification(paste0("Ch.10: ",pct,"% saved"), type="message")
    })
  })
}
