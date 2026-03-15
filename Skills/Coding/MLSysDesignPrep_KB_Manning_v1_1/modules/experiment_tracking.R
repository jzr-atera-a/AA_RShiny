# modules/experiment_tracking.R
# Experiment Tracking Board — Ch.6 Model Development & Offline Evaluation
# Kravchenko & Babushkin (Manning 2025)

# ── Seed data shown on first load ─────────────────────────────────────────────
.et_seed_runs <- function() {
  data.frame(
    run_id       = c("run-001","run-002","run-003","run-004",
                     "run-005","run-006","run-007","run-008"),
    run_name     = c("logr-baseline","lgbm-v1-ce","lgbm-v2-focal","lgbm-v3-tuned",
                     "mlp-v1-dropout","two-tower-v1","two-tower-v2-larger","two-tower-v3-champion"),
    author       = c("alice","alice","bob","bob","carol","carol","alice","bob"),
    git_sha      = c("a1b2c3d","e4f5g6h","i7j8k9l","m0n1o2p",
                     "q3r4s5t","u6v7w8x","y9z0a1b","c2d3e4f"),
    data_version = rep("s3://data/train/v2025-02-01", 8),
    model_family = c("Logistic Regression","LightGBM","LightGBM","LightGBM",
                     "MLP / Feed-forward NN","Two-Tower (Embedding)",
                     "Two-Tower (Embedding)","Two-Tower (Embedding)"),
    loss_fn      = c("Cross-Entropy","Cross-Entropy","Focal Loss","Focal Loss",
                     "Cross-Entropy","Contrastive / NTXent",
                     "Contrastive / NTXent","Contrastive / NTXent"),
    lr           = c(0.1, 0.05, 0.05, 0.01, 0.001, 0.0005, 0.0003, 0.0002),
    batch_size   = c(1024, 512, 512, 512, 256, 512, 1024, 1024),
    epochs       = c(1, 100, 100, 150, 30, 20, 25, 30),
    extra_params = c(
      "C=1.0",
      "num_leaves=63",
      "num_leaves=63,gamma=2",
      "num_leaves=127,gamma=2,min_data=50",
      "hidden=256x128,dropout=0.3",
      "dim=64",
      "dim=128",
      "dim=128,margin=0.5"
    ),
    val_auc     = c(0.7812, 0.8234, 0.8401, 0.8589, 0.8312, 0.8703, 0.8841, 0.9012),
    val_prauc   = c(0.6201, 0.7108, 0.7342, 0.7681, 0.7220, 0.7890, 0.8021, 0.8290),
    val_ndcg    = c(0.5510, 0.6234, 0.6455, 0.6812, 0.6380, 0.7012, 0.7189, 0.7441),
    val_logloss = c(0.5812, 0.4901, 0.4712, 0.4390, 0.4601, 0.4180, 0.3990, 0.3802),
    gpu_hours   = c(0.1, 0.8, 0.9, 1.2, 3.5, 4.2, 6.1, 6.8),
    latency_ms  = c(2, 8, 8, 9, 22, 18, 21, 20),
    status      = c("✅ Completed","✅ Completed","✅ Completed","✅ Completed",
                    "✅ Completed","✅ Completed","✅ Completed",
                    "🏆 Promoted to Registry"),
    primary_metric = rep("Val AUC-ROC", 8),
    notes = c(
      "Baseline — logistic regression, all dense features only.",
      "First LightGBM run. Big jump over LR baseline.",
      "Switched to focal loss (gamma=2). Helps class imbalance.",
      "HPO with Optuna: tuned num_leaves and min_data. Best LightGBM so far.",
      "MLP experiment. Higher GPU cost, worse than tuned LightGBM.",
      "First two-tower run. dim=64 embeddings. Promising retrieval quality.",
      "Scaled embeddings to dim=128. Clear improvement across all metrics.",
      "Added margin=0.5 to NTXent. Best model overall. Promoted to registry."
    ),
    logged_at = c(
      "2025-02-10 09:12","2025-02-11 11:30","2025-02-12 14:05","2025-02-13 16:22",
      "2025-02-14 10:00","2025-02-17 13:45","2025-02-18 15:30","2025-02-19 11:00"
    ),
    stringsAsFactors = FALSE
  )
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  UI                                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
experiment_tracking_ui <- function(id) {
  ns <- NS(id)

  tagList(

    # ── Hero ──────────────────────────────────────────────────────────────────
    div(class = "meta-hero",
        tags$h1("Experiment Tracking Board"),
        tags$h2("Chapter 6 — Model Development & Offline Evaluation · K&B Manning 2025"),
        div(
          span(class = "hero-badge", "Log Runs"),
          span(class = "hero-badge", "Compare Metrics"),
          span(class = "hero-badge", "Run Diff"),
          span(class = "hero-badge", "HPO Strategy"),
          span(class = "hero-badge", "Model Registry")
        )
    ),

    # ── KPI bar ───────────────────────────────────────────────────────────────
    fluidRow(
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_runs"))),
        span(class = "metric-label", "Runs Logged"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_best_auc"))),
        span(class = "metric-label", "Best AUC-ROC"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_best_ndcg"))),
        span(class = "metric-label", "Best NDCG@10"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_families"))),
        span(class = "metric-label", "Model Families"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_champion"))),
        span(class = "metric-label", "Champion Run"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_promoted"))),
        span(class = "metric-label", "In Registry")))
    ),

    br(),

    # ── Row 1: Log form + Runs table ──────────────────────────────────────────
    fluidRow(

      # Left — log form
      box(title = "➕ Log Experiment Run", status = "primary",
          solidHeader = TRUE, width = 4,

          div(class = "section-heading-dark", "Run Identity"),
          fluidRow(
            column(6, textInput(ns("run_name"), "Run Name:",
                                placeholder = "e.g. lgbm-v3-focal")),
            column(6, textInput(ns("run_author"), "Author:",
                                placeholder = "name / team"))
          ),
          fluidRow(
            column(6, textInput(ns("git_sha"), "Git Commit SHA:",
                                placeholder = "e.g. a3f91bc")),
            column(6, textInput(ns("data_version"), "Data Version:",
                                placeholder = "e.g. v2025-03-01"))
          ),

          div(class = "section-heading-dark", "Model Config"),
          fluidRow(
            column(6,
              selectInput(ns("model_family"), "Model Family:",
                choices = c("Logistic Regression","LightGBM","XGBoost","CatBoost",
                            "Random Forest","MLP / Feed-forward NN","Wide & Deep",
                            "Two-Tower (Embedding)","Transformer / BERT",
                            "Custom / Other"))),
            column(6,
              selectInput(ns("loss_fn"), "Loss Function:",
                choices = c("Cross-Entropy","Focal Loss","MSE / MAE","Huber Loss",
                            "BPR (Bayesian Personalised Ranking)",
                            "LambdaRank / LambdaLoss",
                            "Multi-Task Weighted","Contrastive / NTXent","Custom")))
          ),
          fluidRow(
            column(4, numericInput(ns("lr"),         "Learn. Rate:", value=0.01,  min=1e-6, max=1,   step=1e-4)),
            column(4, numericInput(ns("batch_size"), "Batch Size:",  value=512,   min=1,             step=64)),
            column(4, numericInput(ns("epochs"),     "Epochs:",      value=10,    min=1,             step=1))
          ),
          textInput(ns("extra_params"), "Extra Hyperparams:",
                    placeholder = "num_leaves=127, dropout=0.2"),

          div(class = "section-heading-dark", "Offline Metrics"),
          fluidRow(
            column(4, numericInput(ns("val_auc"),     "AUC-ROC:", value=NA, min=0, max=1, step=0.0001)),
            column(4, numericInput(ns("val_prauc"),   "PR-AUC:",  value=NA, min=0, max=1, step=0.0001)),
            column(4, numericInput(ns("val_ndcg"),    "NDCG@10:", value=NA, min=0, max=1, step=0.0001))
          ),
          fluidRow(
            column(4, numericInput(ns("val_logloss"), "Log-Loss:",     value=NA, min=0, step=0.001)),
            column(4, numericInput(ns("gpu_hours"),   "GPU-Hours:",    value=NA, min=0, step=0.5)),
            column(4, numericInput(ns("latency_ms"),  "p99 lat (ms):", value=NA, min=0, step=1))
          ),

          div(class = "section-heading-dark", "Status & Notes"),
          fluidRow(
            column(7,
              selectInput(ns("run_status"), "Status:",
                choices = c("✅ Completed","🔄 Running","❌ Failed",
                            "⏸ Paused","🏆 Promoted to Registry"))),
            column(5,
              selectInput(ns("primary_metric"), "Rank By:",
                choices = c("Val AUC-ROC","Val PR-AUC","Val NDCG@10",
                            "Val Log-Loss ↑")))
          ),
          textAreaInput(ns("run_notes"), "Notes:",
                        placeholder = "What changed vs last run? Key findings...",
                        rows = 3, width = "100%"),
          br(),
          fluidRow(
            column(8, actionButton(ns("log_run"), "📝 Log Run",
                                   class = "btn-meta", width = "100%",
                                   icon = icon("plus-circle"))),
            column(4, actionButton(ns("seed_demo"), "Load Demo",
                                   class = "btn btn-default btn-sm",
                                   style = "width:100%;margin-top:1px;font-size:11px;"))
          )
      ),

      # Right — runs table
      box(title = "📋 Experiment Runs Log", status = "info",
          solidHeader = TRUE, width = 8,
          fluidRow(
            column(3, selectInput(ns("filter_model"), "Model:",
                                  choices = "All", width = "100%")),
            column(3, selectInput(ns("filter_status"), "Status:",
                                  choices = c("All","✅ Completed","🔄 Running",
                                              "❌ Failed","🏆 Promoted to Registry"),
                                  width = "100%")),
            column(3, selectInput(ns("sort_by"), "Sort By:",
                                  choices = c("AUC-ROC ↓","PR-AUC ↓","NDCG@10 ↓",
                                              "Log-Loss ↑","GPU-Hours ↑",
                                              "Run # newest"),
                                  width = "100%")),
            column(3, br(),
              actionButton(ns("clear_runs"), "🗑 Clear All",
                class = "btn btn-default btn-sm",
                style = "width:100%;font-size:11px;"))
          ),
          br(),
          DT::dataTableOutput(ns("runs_table"))
      )
    ),

    # ── Row 2: Charts ─────────────────────────────────────────────────────────
    fluidRow(
      box(title = "📈 Metric Visualisation", status = "warning",
          solidHeader = TRUE, width = 12,
          tabsetPanel(
            tabPanel("AUC-ROC by Run",
              br(), plotly::plotlyOutput(ns("chart_auc"),        height = "300px")),
            tabPanel("PR-AUC vs Log-Loss",
              br(), plotly::plotlyOutput(ns("chart_prauc_ll"),   height = "300px")),
            tabPanel("NDCG@10 by Run",
              br(), plotly::plotlyOutput(ns("chart_ndcg"),       height = "300px")),
            tabPanel("Efficiency: GPU-Hours vs AUC",
              br(), plotly::plotlyOutput(ns("chart_efficiency"), height = "300px")),
            tabPanel("Learning Rate Sensitivity",
              br(), plotly::plotlyOutput(ns("chart_lr"),         height = "300px")),
            tabPanel("Model Family Comparison",
              br(), plotly::plotlyOutput(ns("chart_family"),     height = "300px"))
          )
      )
    ),

    # ── Row 3: Diff + Registry ────────────────────────────────────────────────
    fluidRow(

      box(title = "🔍 Run Diff — Compare Two Runs", status = "success",
          solidHeader = TRUE, width = 6,
          div(class = "tip-box",
            HTML("<strong>💡 K&B principle:</strong> Always compare a new run against the champion. Document what changed and why the metric moved — without this discipline, experiments become unauditable.")),
          br(),
          fluidRow(
            column(6, uiOutput(ns("ui_run_a"))),
            column(6, uiOutput(ns("ui_run_b")))
          ),
          actionButton(ns("do_diff"), "⚡ Compare Runs",
                       class = "btn-meta", icon = icon("code-branch")),
          br(), br(),
          uiOutput(ns("diff_output"))
      ),

      box(title = "🏆 Model Registry", status = "success",
          solidHeader = TRUE, width = 6,
          div(class = "success-box",
            HTML("<strong>K&B Ch.6:</strong> The model registry is the gatekeeper between experimentation and production. Only runs that pass the evaluation gate — offline metrics + sliced eval + shadow test — should be promoted. The registry tracks model version, training data version, eval results, and reviewer sign-off.")),
          br(),
          uiOutput(ns("registry_ui")),
          br(),
          div(class = "section-heading-dark", "Promotion Gate — Required Checklist"),
          div(class = "framework-card",
            tags$ul(
              tags$li("Beats current champion on primary metric (statistically significant)"),
              tags$li("Passes sliced evaluation — no group > 15% below aggregate"),
              tags$li("Latency p99 within SLO"),
              tags$li("Shadow mode for ≥ 24 hours without anomalies"),
              tags$li("Git SHA and training data version recorded"),
              tags$li("Reviewer sign-off documented in run notes")
            ))
      )
    ),

    # ── Row 4: Theory reference ───────────────────────────────────────────────
    fluidRow(
      box(title = "📖 K&B Ch.6 — Theory Reference",
          status = "primary", solidHeader = TRUE, width = 12,
          tabsetPanel(

            tabPanel("What to Track",
              br(),
              fluidRow(
                column(3,
                  div(class = "framework-card",
                    tags$h5("Hyperparameters"),
                    tags$p("Log ALL of them — not a hand-selected subset. K&B: 'The parameter you don't log is always the one that mattered.'"),
                    tags$ul(
                      tags$li("Learning rate, batch size, epochs"),
                      tags$li("Regularisation: L1/L2 λ, dropout"),
                      tags$li("Architecture: depth, width, heads"),
                      tags$li("LR scheduler: warmup steps, decay type"),
                      tags$li("Augmentation: strategy and magnitude")
                    ))),
                column(3,
                  div(class = "framework-card",
                    tags$h5("Data Provenance"),
                    tags$p("A model trained on different data is a DIFFERENT model, even if hyperparams are identical."),
                    tags$ul(
                      tags$li("Training dataset version / snapshot ID"),
                      tags$li("Feature store group tag"),
                      tags$li("Train / val / test split dates (temporal!)"),
                      tags$li("Label definition version"),
                      tags$li("Data size and class distribution")
                    ))),
                column(3,
                  div(class = "framework-card",
                    tags$h5("Code & Environment"),
                    tags$p("K&B: 'If you can't reproduce an experiment, it didn't happen.'"),
                    tags$ul(
                      tags$li("Git commit SHA — non-negotiable"),
                      tags$li("Python & library versions (requirements.txt hash)"),
                      tags$li("CUDA / GPU driver version"),
                      tags$li("Docker image tag (if containerised)"),
                      tags$li("All random seeds (Python, NumPy, PyTorch, CUDA)")
                    ))),
                column(3,
                  div(class = "framework-card",
                    tags$h5("Metrics & Artifacts"),
                    tags$ul(
                      tags$li("Train / val loss curves per epoch"),
                      tags$li("Final offline metrics: AUC, NDCG, log-loss"),
                      tags$li("Sliced metrics per subgroup"),
                      tags$li("Serialised model file + config"),
                      tags$li("Feature importance / SHAP summary"),
                      tags$li("GPU hours + estimated cost")
                    )))
              )
            ),

            tabPanel("Tooling Comparison",
              br(),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(
                  tags$th("Tool"), tags$th("Type"), tags$th("Strengths"),
                  tags$th("Limitations"), tags$th("K&B Rec.")
                )),
                tags$tbody(
                  tags$tr(
                    tags$td(tags$b("MLflow")), tags$td("Open-source"),
                    tags$td("Tracking + model registry + serving. Most widely adopted. Backend-agnostic. Works fully offline."),
                    tags$td("UI less polished than W&B. No built-in system metrics."),
                    tags$td(tags$span(class="badge-green","Default"))),
                  tags$tr(
                    tags$td(tags$b("Weights & Biases")), tags$td("SaaS / On-prem"),
                    tags$td("Best-in-class UI. Automatic GPU/CPU metrics. Built-in Sweeps (HPO). Collaborative reports."),
                    tags$td("Requires network unless self-hosted. Cost at scale."),
                    tags$td(tags$span(class="badge-blue","Research"))),
                  tags$tr(
                    tags$td(tags$b("Neptune.ai")), tags$td("SaaS"),
                    tags$td("Very detailed metadata. Query/filter API. Strong audit trail. Notebook versioning."),
                    tags$td("Cost. Smaller ecosystem than MLflow / W&B."),
                    tags$td("Compliance-heavy orgs")),
                  tags$tr(
                    tags$td(tags$b("Comet ML")), tags$td("SaaS / On-prem"),
                    tags$td("Automatic code capture. Strong diff tooling. Production integration."),
                    tags$td("Cost. Less open-source adoption."),
                    tags$td("Auto code tracking")),
                  tags$tr(
                    tags$td(tags$b("Vertex AI Experiments")), tags$td("Managed (GCP)"),
                    tags$td("Native GCP integration. No infra to manage. Links to Vertex Pipelines + model registry."),
                    tags$td("GCP lock-in."),
                    tags$td("GCP-native teams")),
                  tags$tr(
                    tags$td(tags$b("SageMaker Experiments")), tags$td("Managed (AWS)"),
                    tags$td("Native AWS integration. Links to training jobs and model registry."),
                    tags$td("AWS lock-in. API less ergonomic."),
                    tags$td("AWS-native teams")),
                  tags$tr(
                    tags$td(tags$b("DVC + Studio")), tags$td("Open-source + SaaS"),
                    tags$td("Best data + model versioning via Git. Pipeline tracking. Any cloud backend."),
                    tags$td("More setup. Less real-time metric streaming."),
                    tags$td("Data versioning focus"))
                )
              ),
              br(),
              div(class = "tip-box",
                HTML("<strong>💡 Interview answer:</strong> 'Default is MLflow — open-source, backend-agnostic, bundles tracking, registry, and serving. For a research team I'd add W&B for its Sweep integration and collaborative report features.'"))
            ),

            tabPanel("Reproducibility Checklist",
              br(),
              fluidRow(
                column(6,
                  div(class = "warn-box",
                    HTML("<strong>K&B's reproducibility principle:</strong> A result that can't be reproduced is worthless in production engineering. Treat reproducibility as a first-class requirement.")),
                  br(),
                  div(class = "framework-card",
                    tags$h5("The Six-Point Checklist"),
                    tags$ol(
                      tags$li(tags$b("Pin the data:"), " training data version must be immutable. Use Delta Lake time-travel, DVC tags, or S3 versioned prefixes."),
                      tags$li(tags$b("Pin the code:"), " git SHA in every run record. Never log 'latest' or 'main'."),
                      tags$li(tags$b("Pin the environment:"), " Docker image tag or conda env hash — not just requirements.txt."),
                      tags$li(tags$b("Fix all seeds:"), " Python random, NumPy, PyTorch, CUDA, DataLoader worker seeds."),
                      tags$li(tags$b("Log the split:"), " exact train/val/test date ranges or row IDs, not a random split fraction."),
                      tags$li(tags$b("Store all artifacts:"), " serialised model file + config, linked to run ID.")
                    )),
                  div(class = "framework-card",
                    tags$h5("Sources of Non-Determinism (K&B)"),
                    tags$ul(
                      tags$li(tags$b("GPU:"), " cuDNN kernel selection varies. Set torch.backends.cudnn.deterministic=True."),
                      tags$li(tags$b("DataLoader:"), " fix worker_init_fn seeding."),
                      tags$li(tags$b("Distributed:"), " gradient aggregation order can differ. Log ±variance across seeds."),
                      tags$li(tags$b("Feature store:"), " ensure point-in-time snapshot, not a live read during training.")
                    ))
                ),
                column(6,
                  div(class = "framework-card",
                    tags$h5("MLflow Minimum Viable Tracking — Python Pattern"),
                    tags$pre(
"import mlflow

mlflow.set_experiment('feed-ranking-v3')

with mlflow.start_run(run_name='lgbm-focal-lr0.01') as run:

  # Log ALL hyperparameters
  mlflow.log_params({
    'model':        'LightGBM',
    'lr':            0.01,
    'num_leaves':    127,
    'loss':          'focal',
    'data_version': 's3://data/train/v2025-03-01',
    'git_sha':       get_git_sha(),  # non-negotiable
    'env_hash':      get_env_hash(),
    'seed':          42
  })

  model = lgb.train(params, train_data,
                    valid_sets=[val_data])

  # Log ALL eval metrics (including sliced)
  mlflow.log_metrics({
    'val_auc_roc': eval_auc(model, val_data),
    'val_pr_auc':  eval_pr_auc(model, val_data),
    'val_logloss': eval_logloss(model, val_data),
    'val_ndcg_10': eval_ndcg(model, val_data, k=10),
    'gpu_hours':   get_gpu_hours(run)
  })
  for group in EVAL_GROUPS:
    mlflow.log_metric(
      f'val_auc_{group}',
      eval_auc(model, val_data.filter(group))
    )

  # Promote if it beats champion
  if beats_champion(run.info.run_id):
    mlflow.register_model(
      f'runs:/{run.info.run_id}/model',
      'feed-ranking-champion'
    )"
                    )
                  )
                )
              )
            ),

            tabPanel("HPO Strategy Guide",
              br(),
              fluidRow(
                column(3,
                  div(class = "framework-card",
                    tags$h5("Grid Search"),
                    tags$p(tags$b("Use when:"), " ≤ 3 params, small exhaustive search needed."),
                    tags$p(tags$b("Complexity:"), " O(N^d) — exponential in dimensions. Never for deep learning."),
                    div(class = "warn-box",
                      HTML("<strong>K&B:</strong> Almost never the right choice. Wastes compute on parameter combinations that don't matter."))),
                  div(class = "framework-card",
                    tags$h5("Random Search"),
                    tags$p(tags$b("Use when:"), " Many hyperparameters. Bergstra & Bengio (2012): 10× more efficient than grid for high-dimensional spaces."),
                    tags$p("Most HPO spaces have low intrinsic dimensionality — only 1–2 params matter. Random search covers the important ones faster."),
                    div(class = "success-box",
                      HTML("<strong>K&B:</strong> Always use as baseline before investing in Bayesian.")))
                ),
                column(3,
                  div(class = "framework-card",
                    tags$h5("Bayesian Optimisation"),
                    tags$p(tags$b("Use when:"), " Each eval is expensive (hours of training). Builds a surrogate model of the objective surface."),
                    tags$p(tags$b("Acquisition function:"), " Expected Improvement (EI) balances exploration vs exploitation."),
                    tags$p(tags$b("Tools:"), " Optuna (TPE — best default), Hyperopt, BoTorch, Ray Tune."),
                    div(class = "success-box",
                      HTML("<strong>K&B rec:</strong> Optuna with TPE sampler + MLflow callback for all trials."))),
                  div(class = "framework-card",
                    tags$h5("Successive Halving / ASHA"),
                    tags$p(tags$b("Use when:"), " Many candidates + early stopping possible. Allocate minimal budget to all candidates, double budget to top 50% survivors."),
                    tags$p(tags$b("Implemented in:"), " Ray Tune (ASHA), Optuna (successive halving sampler)."))
                ),
                column(3,
                  div(class = "framework-card",
                    tags$h5("Population-Based Training"),
                    tags$p(tags$b("Use when:"), " Hyperparameters should evolve DURING training (LR schedule, augmentation strength)."),
                    tags$p("Population trained in parallel. Worst agents copy weights from best and perturb hyperparams. Discovered at DeepMind for game-playing agents."),
                    tags$p(tags$b("Implemented in:"), " Ray Tune PBT scheduler, Determined.ai."))
                ),
                column(3,
                  div(class = "framework-card",
                    tags$h5("K&B Decision Flowchart"),
                    tags$p(tags$b("Training < 10 min:"), " → Random search (100 trials)"),
                    tags$p(tags$b("10 min – 2 hr:"),     " → Bayesian / Optuna TPE (50 trials)"),
                    tags$p(tags$b("> 2 hr per run:"),    " → ASHA early elim → Bayesian on survivors"),
                    tags$p(tags$b("Dynamic schedules:"), " → Population-Based Training"),
                    div(class = "tip-box",
                      HTML("<strong>💡 Interview line:</strong> 'Training takes ~3 hours per run — I'd use ASHA to eliminate poor configs early, then Bayesian on survivors: near-Bayesian quality at ~30% of compute cost.'")))
                )
              )
            )
          )
      )
    ),

    # ── Self-assessment ───────────────────────────────────────────────────────
    fluidRow(
      box(title = "📊 Self-Assessment: Experiment Tracking",
          status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3,
              sliderInput(ns("sc_what_track"), "What to track per run",     0, 10, 5),
              sliderInput(ns("sc_tooling"),    "Tooling (MLflow / W&B)",    0, 10, 5)),
            column(3,
              sliderInput(ns("sc_repro"),      "Reproducibility practices", 0, 10, 5),
              sliderInput(ns("sc_hpo"),        "HPO strategy selection",    0, 10, 5)),
            column(3,
              sliderInput(ns("sc_registry"),   "Model registry workflow",   0, 10, 5),
              br(),
              actionButton(ns("calc_et"), "Save Assessment",
                           class = "btn-meta", width = "100%")),
            column(3, br(), uiOutput(ns("et_result")))
          )
      )
    )
  )
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SERVER                                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
experiment_tracking_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    # ns() is available automatically inside moduleServer via session$ns
    # All output$, input$, and renderUI selectInput IDs are automatically
    # namespaced — we must NOT call NS(id)() again inside the server.

    # ── Run store — seeded with demo data ─────────────────────────────────────
    runs <- reactiveVal(.et_seed_runs())

    # ── KPI outputs ───────────────────────────────────────────────────────────
    output$kpi_runs <- renderText({ nrow(runs()) })

    output$kpi_best_auc <- renderText({
      v <- runs()$val_auc
      if (!length(v) || all(is.na(v))) return("—")
      sprintf("%.4f", max(v, na.rm = TRUE))
    })

    output$kpi_best_ndcg <- renderText({
      v <- runs()$val_ndcg
      if (!length(v) || all(is.na(v))) return("—")
      sprintf("%.4f", max(v, na.rm = TRUE))
    })

    output$kpi_families <- renderText({
      df <- runs()
      if (!nrow(df)) return("0")
      length(unique(df$model_family))
    })

    output$kpi_champion <- renderText({
      df <- runs()
      if (!nrow(df) || all(is.na(df$val_auc))) return("—")
      df$run_id[which.max(df$val_auc)]
    })

    output$kpi_promoted <- renderText({
      sum(grepl("Promoted", runs()$status))
    })

    # ── Log a new run ─────────────────────────────────────────────────────────
    observeEvent(input$log_run, {
      req(nzchar(trimws(input$run_name)))
      new_id <- sprintf("run-%03d", nrow(runs()) + 1)
      new_row <- data.frame(
        run_id       = new_id,
        run_name     = trimws(input$run_name),
        author       = input$run_author,
        git_sha      = input$git_sha,
        data_version = input$data_version,
        model_family = input$model_family,
        loss_fn      = input$loss_fn,
        lr           = as.numeric(input$lr),
        batch_size   = as.numeric(input$batch_size),
        epochs       = as.numeric(input$epochs),
        extra_params = input$extra_params,
        val_auc      = as.numeric(input$val_auc),
        val_prauc    = as.numeric(input$val_prauc),
        val_ndcg     = as.numeric(input$val_ndcg),
        val_logloss  = as.numeric(input$val_logloss),
        gpu_hours    = as.numeric(input$gpu_hours),
        latency_ms   = as.numeric(input$latency_ms),
        status       = input$run_status,
        primary_metric = input$primary_metric,
        notes        = input$run_notes,
        logged_at    = format(Sys.time(), "%Y-%m-%d %H:%M"),
        stringsAsFactors = FALSE
      )
      runs(rbind(runs(), new_row))
      updateSelectInput(session, "filter_model",
                        choices = c("All", unique(runs()$model_family)))
      showNotification(
        paste0("✅ ", new_id, " — '", new_row$run_name, "' logged."),
        type = "message", duration = 4
      )
    })

    # ── Load demo data ────────────────────────────────────────────────────────
    observeEvent(input$seed_demo, {
      runs(.et_seed_runs())
      updateSelectInput(session, "filter_model",
                        choices = c("All", unique(.et_seed_runs()$model_family)))
      showNotification("Demo data loaded.", type = "message")
    })

    # ── Clear all ─────────────────────────────────────────────────────────────
    observeEvent(input$clear_runs, {
      empty <- .et_seed_runs()[0, ]
      runs(empty)
      updateSelectInput(session, "filter_model", choices = "All")
      showNotification("All runs cleared.", type = "warning")
    })

    # ── Filtered + sorted reactive ────────────────────────────────────────────
    view_df <- reactive({
      df <- runs()
      if (!nrow(df)) return(df)

      fm <- input$filter_model
      if (!is.null(fm) && fm != "All")
        df <- df[df$model_family == fm, ]

      fs <- input$filter_status
      if (!is.null(fs) && fs != "All")
        df <- df[df$status == fs, ]

      sb <- input$sort_by %||% "AUC-ROC \u2193"
      sort_col <- switch(sb,
        "AUC-ROC \u2193"   = "val_auc",
        "PR-AUC \u2193"    = "val_prauc",
        "NDCG@10 \u2193"   = "val_ndcg",
        "Log-Loss \u2191"  = "val_logloss",
        "GPU-Hours \u2191" = "gpu_hours",
        "run_id"
      )
      desc <- !grepl("\u2191", sb)
      if (sort_col %in% names(df))
        df <- df[order(df[[sort_col]], decreasing = desc, na.last = TRUE), ]
      df
    })

    # ── Runs DT table ─────────────────────────────────────────────────────────
    output$runs_table <- DT::renderDataTable({
      df <- view_df()
      if (!nrow(df)) {
        return(DT::datatable(
          data.frame(
            Message = "No runs — use the form on the left or click 'Load Demo'."
          ),
          options = list(dom = "t", paging = FALSE), rownames = FALSE
        ))
      }

      disp <- df[, c("run_id","run_name","model_family","loss_fn",
                     "lr","batch_size","epochs",
                     "val_auc","val_prauc","val_ndcg","val_logloss",
                     "gpu_hours","latency_ms","status","logged_at")]
      colnames(disp) <- c("Run","Name","Model","Loss",
                          "LR","Batch","Ep",
                          "AUC-ROC","PR-AUC","NDCG@10","Log-Loss",
                          "GPU-hrs","p99(ms)","Status","Logged")
      for (col in c("AUC-ROC","PR-AUC","NDCG@10","Log-Loss"))
        disp[[col]] <- round(as.numeric(disp[[col]]), 4)

      DT::datatable(
        disp,
        selection  = "single",
        rownames   = FALSE,
        extensions = "Buttons",
        options    = list(
          dom        = "Bfrtip",
          buttons    = list("csv", "copy"),
          pageLength = 8,
          scrollX    = TRUE,
          columnDefs = list(
            list(className = "dt-center", targets = "_all")
          )
        )
      ) %>%
        DT::formatStyle(
          "AUC-ROC",
          background         = DT::styleColorBar(c(0.5, 1), "rgba(232,65,10,0.22)"),
          backgroundSize     = "100% 70%",
          backgroundRepeat   = "no-repeat",
          backgroundPosition = "center"
        ) %>%
        DT::formatStyle(
          "Status",
          color = DT::styleEqual(
            c("✅ Completed","🔄 Running","❌ Failed",
              "⏸ Paused","🏆 Promoted to Registry"),
            c("#10b981","#f59e0b","#ef4444","#8a9bb0","#e8410a")
          ),
          fontWeight = "bold",
          fontSize   = "11px"
        )
    })

    # ── Shared chart layout ───────────────────────────────────────────────────
    BL <- list(
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor  = "rgba(0,0,0,0)",
      font      = list(family = "Inter, sans-serif", color = "#8a9bb0", size = 11),
      xaxis     = list(gridcolor = "rgba(232,65,10,0.08)",
                       zerolinecolor = "rgba(232,65,10,0.15)",
                       tickfont = list(size = 10)),
      yaxis     = list(gridcolor = "rgba(232,65,10,0.08)",
                       zerolinecolor = "rgba(232,65,10,0.15)"),
      hoverlabel = list(bgcolor = "#0d1219", bordercolor = "#e8410a",
                        font = list(color = "#fde8de", size = 11)),
      margin    = list(l = 55, r = 25, t = 45, b = 55),
      legend    = list(orientation = "h", y = -0.28,
                       font = list(color = "#8a9bb0", size = 10))
    )

    no_data <- function(msg = "No data — log runs or click \u2018Load Demo\u2019.") {
      plotly::plot_ly() %>%
        plotly::layout(
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor  = "rgba(0,0,0,0)",
          annotations   = list(list(
            text = msg, x = 0.5, y = 0.5,
            xref = "paper", yref = "paper", showarrow = FALSE,
            font = list(color = "#3a4b5c", size = 13,
                        family = "Inter, sans-serif")
          ))
        )
    }

    OG     <- "rgba(232,65,10,0.9)"
    OG_DIM <- "rgba(232,65,10,0.32)"
    GR     <- "#10b981"

    # ── Chart: AUC-ROC bars ───────────────────────────────────────────────────
    output$chart_auc <- plotly::renderPlotly({
      df <- view_df()
      if (!nrow(df) || all(is.na(df$val_auc))) return(no_data())
      best <- max(df$val_auc, na.rm = TRUE)

      plotly::plot_ly(df,
        x    = ~run_id,
        y    = ~val_auc,
        type = "bar",
        text = ~sprintf("%.4f", val_auc),
        textposition = "outside",
        customdata   = ~paste0(run_name, "<br>", model_family),
        hovertemplate = "<b>%{x}</b><br>%{customdata}<br>AUC-ROC: %{y:.4f}<extra></extra>",
        marker = list(
          color = ~ifelse(!is.na(val_auc) & val_auc == best, OG, OG_DIM),
          line  = list(color = "rgba(232,65,10,0.55)", width = 1)
        )
      ) %>%
        plotly::add_segments(
          x    = ~run_id[1],    xend = ~run_id[nrow(df)],
          y    = ~best,         yend = ~best,
          inherit = FALSE,
          line = list(color = GR, width = 1.5, dash = "dot"),
          name = paste0("Champion (", sprintf("%.4f", best), ")")
        ) %>%
        plotly::layout(
          BL,
          title  = list(text = "Validation AUC-ROC per Run",
                        font = list(color = "#fde8de", size = 13)),
          xaxis  = list(title = "Run ID", tickangle = -30),
          yaxis  = list(title = "AUC-ROC",
                        range = list(
                          max(0.5, min(df$val_auc, na.rm = TRUE) - 0.03),
                          1.03
                        )),
          showlegend = TRUE
        )
    })

    # ── Chart: PR-AUC vs Log-Loss dual axis ───────────────────────────────────
    output$chart_prauc_ll <- plotly::renderPlotly({
      df   <- view_df()
      has_p  <- nrow(df) > 0 && !all(is.na(df$val_prauc))
      has_ll <- nrow(df) > 0 && !all(is.na(df$val_logloss))
      if (!has_p && !has_ll) return(no_data())

      p <- plotly::plot_ly()
      if (has_p)
        p <- p %>% plotly::add_trace(
          data  = df, x = ~run_id, y = ~val_prauc,
          type  = "scatter", mode = "lines+markers", name = "PR-AUC",
          line   = list(color = OG, width = 2.5),
          marker = list(color = OG, size = 8, symbol = "circle"),
          hovertemplate = "<b>%{x}</b><br>PR-AUC: %{y:.4f}<extra></extra>"
        )
      if (has_ll)
        p <- p %>% plotly::add_trace(
          data  = df, x = ~run_id, y = ~val_logloss,
          type  = "scatter", mode = "lines+markers", name = "Log-Loss",
          yaxis  = "y2",
          line   = list(color = "#f59e0b", width = 2, dash = "dash"),
          marker = list(color = "#f59e0b", size = 7, symbol = "diamond"),
          hovertemplate = "<b>%{x}</b><br>Log-Loss: %{y:.4f}<extra></extra>"
        )

      p %>% plotly::layout(
        BL,
        title  = list(text = "PR-AUC vs Log-Loss Across Runs",
                      font = list(color = "#fde8de", size = 13)),
        xaxis  = list(title = "Run ID", tickangle = -30),
        yaxis  = list(title = "PR-AUC (higher better)", side = "left"),
        yaxis2 = list(title = "Log-Loss (lower better)", side = "right",
                      overlaying = "y", showgrid = FALSE)
      )
    })

    # ── Chart: NDCG@10 area ───────────────────────────────────────────────────
    output$chart_ndcg <- plotly::renderPlotly({
      df <- view_df()
      if (!nrow(df) || all(is.na(df$val_ndcg))) return(no_data())

      plotly::plot_ly(df,
        x    = ~run_id, y = ~val_ndcg,
        type = "scatter", mode = "lines+markers",
        fill = "tozeroy", fillcolor = "rgba(232,65,10,0.07)",
        line   = list(color = OG, width = 2.5),
        marker = list(color = "#ffb49a", size = 9,
                      line = list(color = OG, width = 2)),
        hovertemplate = "<b>%{x}</b><br>NDCG@10: %{y:.4f}<extra></extra>"
      ) %>%
        plotly::layout(
          BL,
          title = list(text = "Validation NDCG@10 per Run",
                       font = list(color = "#fde8de", size = 13)),
          xaxis = list(title = "Run ID", tickangle = -30),
          yaxis = list(title = "NDCG@10")
        )
    })

    # ── Chart: GPU-Hours vs AUC scatter ──────────────────────────────────────
    output$chart_efficiency <- plotly::renderPlotly({
      df    <- view_df()
      valid <- df[!is.na(df$gpu_hours) & !is.na(df$val_auc), ]
      if (!nrow(valid))
        return(no_data("No runs with both GPU-Hours and AUC-ROC logged."))

      best <- max(valid$val_auc)
      valid$is_best <- valid$val_auc == best

      plotly::plot_ly(valid,
        x    = ~gpu_hours, y = ~val_auc,
        type = "scatter", mode = "markers+text",
        text = ~run_id, textposition = "top center",
        customdata = ~paste0(run_name, "<br>", model_family),
        hovertemplate = paste0(
          "<b>%{text}</b><br>%{customdata}<br>",
          "GPU-Hours: %{x:.1f}<br>AUC-ROC: %{y:.4f}<extra></extra>"
        ),
        marker = list(
          size    = 14,
          color   = ~ifelse(is_best, OG, OG_DIM),
          opacity = 0.85,
          line    = list(color = "#ffb49a", width = 1.5)
        )
      ) %>%
        plotly::layout(
          BL,
          title = list(text = "Training Cost vs Quality — Pareto Frontier",
                       font = list(color = "#fde8de", size = 13)),
          xaxis = list(title = "GPU-Hours (Training Cost)"),
          yaxis = list(title = "Validation AUC-ROC")
        )
    })

    # ── Chart: LR sensitivity scatter ────────────────────────────────────────
    output$chart_lr <- plotly::renderPlotly({
      df    <- view_df()
      valid <- df[!is.na(df$lr) & df$lr > 0 & !is.na(df$val_auc), ]
      if (!nrow(valid))
        return(no_data("No runs with learning rate and AUC-ROC logged."))

      plotly::plot_ly(valid,
        x    = ~log10(lr), y = ~val_auc,
        type = "scatter", mode = "markers+text",
        color = ~model_family,
        colors = c(OG,"#f59e0b","#3b82f6","#10b981",
                   "#8b5cf6","#ef4444","#06b6d4"),
        text = ~run_id, textposition = "top center",
        marker = list(size = 12, opacity = 0.85,
                      line = list(color = "#1e293b", width = 1)),
        hovertemplate = paste0(
          "<b>%{text}</b><br>LR: 10^%{x:.2f}<br>",
          "AUC-ROC: %{y:.4f}<extra></extra>"
        )
      ) %>%
        plotly::layout(
          BL,
          title = list(text = "Learning Rate Sensitivity (log\u2081\u2080 scale)",
                       font = list(color = "#fde8de", size = 13)),
          xaxis = list(title = "log\u2081\u2080(Learning Rate)"),
          yaxis = list(title = "Validation AUC-ROC")
        )
    })

    # ── Chart: family box plot ────────────────────────────────────────────────
    output$chart_family <- plotly::renderPlotly({
      df    <- view_df()
      valid <- df[!is.na(df$val_auc), ]
      if (!nrow(valid))
        return(no_data("No completed runs to compare by model family."))

      plotly::plot_ly(valid,
        x    = ~model_family, y = ~val_auc,
        type = "box", boxpoints = "all",
        jitter = 0.4, pointpos = 0,
        marker    = list(color = OG, size = 7, opacity = 0.8),
        line      = list(color = OG),
        fillcolor = "rgba(232,65,10,0.07)",
        hovertemplate = "<b>%{x}</b><br>AUC-ROC: %{y:.4f}<extra></extra>"
      ) %>%
        plotly::layout(
          BL,
          title  = list(text = "AUC-ROC Distribution by Model Family",
                        font = list(color = "#fde8de", size = 13)),
          xaxis  = list(title = "Model Family", tickangle = -20),
          yaxis  = list(title = "Validation AUC-ROC"),
          showlegend = FALSE
        )
    })

    # ── Run diff ─────────────────────────────────────────────────────────────
    # renderUI for selects must use ns() which is session$ns inside moduleServer
    output$ui_run_a <- renderUI({
      ids <- runs()$run_id
      if (!length(ids)) return(tags$small(style="color:#3a4b5c;","No runs yet."))
      selectInput(session$ns("run_a"), "Run A — Baseline:",
                  choices = ids, width = "100%")
    })
    output$ui_run_b <- renderUI({
      ids <- runs()$run_id
      if (!length(ids)) return(NULL)
      selectInput(session$ns("run_b"), "Run B — Challenger:",
                  choices = rev(ids), width = "100%")
    })

    observeEvent(input$do_diff, {
      df <- runs()
      req(nrow(df) >= 2, input$run_a, input$run_b)
      ra <- df[df$run_id == input$run_a, ]
      rb <- df[df$run_id == input$run_b, ]
      req(nrow(ra) == 1, nrow(rb) == 1)

      fields <- list(
        list(l="Model Family",   a=ra$model_family,  b=rb$model_family,  num=FALSE),
        list(l="Loss Function",  a=ra$loss_fn,       b=rb$loss_fn,       num=FALSE),
        list(l="Learning Rate",  a=ra$lr,            b=rb$lr,            num=TRUE),
        list(l="Batch Size",     a=ra$batch_size,    b=rb$batch_size,    num=TRUE),
        list(l="Epochs / Iters", a=ra$epochs,        b=rb$epochs,        num=TRUE),
        list(l="Data Version",   a=ra$data_version,  b=rb$data_version,  num=FALSE),
        list(l="Git SHA",        a=ra$git_sha,       b=rb$git_sha,       num=FALSE),
        list(l="Val AUC-ROC",    a=ra$val_auc,       b=rb$val_auc,       num=TRUE),
        list(l="Val PR-AUC",     a=ra$val_prauc,     b=rb$val_prauc,     num=TRUE),
        list(l="Val NDCG@10",    a=ra$val_ndcg,      b=rb$val_ndcg,      num=TRUE),
        list(l="Val Log-Loss",   a=ra$val_logloss,   b=rb$val_logloss,   num=TRUE),
        list(l="GPU-Hours",      a=ra$gpu_hours,     b=rb$gpu_hours,     num=TRUE),
        list(l="Latency p99 ms", a=ra$latency_ms,    b=rb$latency_ms,    num=TRUE)
      )

      rows <- lapply(fields, function(f) {
        fmt <- function(v) {
          if (!length(v) || (length(v) == 1 && is.na(v))) return("—")
          if (f$num) sprintf("%.4g", as.numeric(v)) else as.character(v)
        }
        av <- fmt(f$a);  bv <- fmt(f$b)
        changed <- !identical(av, bv)

        delta_td <- if (f$num && av != "—" && bv != "—") {
          d   <- as.numeric(f$b) - as.numeric(f$a)
          better <- if (grepl("Loss|Hours|Latency", f$l)) d < 0 else d > 0
          col    <- if (better) "#10b981" else "#ef4444"
          tags$td(
            style = paste0("color:", col,
                           ";font-weight:700;",
                           "font-family:'JetBrains Mono',monospace;font-size:11px;"),
            sprintf("%+.4g", d)
          )
        } else tags$td(style="color:#3a4b5c;","—")

        tags$tr(
          style = if (changed) "background:rgba(232,65,10,0.04);" else "",
          tags$td(style="font-weight:600;color:#ffb49a;font-size:11.5px;width:130px;", f$l),
          tags$td(style="font-family:'JetBrains Mono',monospace;color:#8a9bb0;font-size:11px;", av),
          tags$td(style="font-family:'JetBrains Mono',monospace;color:#e8410a;font-size:11px;", bv),
          delta_td,
          tags$td(
            if (changed) tags$span(class="stage-pill","CHANGED")
            else         tags$span(style="color:#3a4b5c;font-size:10px;","same")
          )
        )
      })

      output$diff_output <- renderUI({
        tagList(
          div(style = "margin-bottom:10px;",
              span(class = "badge-blue",  input$run_a), " vs ",
              span(class = "stage-pill",  input$run_b)),
          tags$table(class = "table table-hover",
            tags$thead(tags$tr(
              tags$th("Field"),
              tags$th(paste0("A — ", input$run_a)),
              tags$th(paste0("B — ", input$run_b)),
              tags$th("\u0394"), tags$th("")
            )),
            tags$tbody(do.call(tagList, rows))
          ),
          if (nzchar(ra$notes %||% ""))
            div(class="info-box-plain",
                tags$b(paste0(input$run_a, " notes: ")), ra$notes),
          if (nzchar(rb$notes %||% ""))
            div(class="tip-box",
                tags$b(paste0(input$run_b, " notes: ")), rb$notes)
        )
      })
    })

    # ── Model Registry ────────────────────────────────────────────────────────
    output$registry_ui <- renderUI({
      prom <- runs()[grepl("Promoted", runs()$status), ]
      if (!nrow(prom)) {
        return(div(class="warn-box",
          HTML("No runs promoted yet. Set status to <strong>🏆 Promoted to Registry</strong> when logging.")))
      }
      rows <- lapply(seq_len(nrow(prom)), function(i) {
        r <- prom[i, ]
        tags$tr(
          tags$td(tags$span(class="stage-pill", r$run_id)),
          tags$td(r$run_name),
          tags$td(tags$small(r$model_family)),
          tags$td(style="font-weight:700;color:#e8410a;",
                  if (!is.na(r$val_auc)) sprintf("%.4f", r$val_auc) else "—"),
          tags$td(style="color:#60a5fa;",
                  if (!is.na(r$val_ndcg)) sprintf("%.4f", r$val_ndcg) else "—"),
          tags$td(tags$code(style="font-size:10px;", r$git_sha)),
          tags$td(tags$small(r$logged_at))
        )
      })
      tags$table(class="table table-hover",
        tags$thead(tags$tr(
          tags$th("Run"), tags$th("Name"), tags$th("Model"),
          tags$th("AUC-ROC"), tags$th("NDCG@10"),
          tags$th("Git SHA"), tags$th("Promoted")
        )),
        tags$tbody(do.call(tagList, rows))
      )
    })

    # ── Self-assessment ───────────────────────────────────────────────────────
    observeEvent(input$calc_et, {
      avg <- mean(c(input$sc_what_track, input$sc_tooling,
                    input$sc_repro, input$sc_hpo, input$sc_registry))
      pct <- round(avg * 10)
      prep_manager$update_progress("experiment_tracking", pct)
      output$et_result <- renderUI({
        div(class = if (pct >= 70) "success-box" else "tip-box",
          tags$h3(style = paste0("color:", progress_colour(pct)),
                  paste0(pct, "% ready")),
          if (input$sc_repro < 6)
            tags$p("\u26a0\ufe0f Priority: reproducibility is K&B's baseline requirement — pin data, code, env, and seeds."),
          if (input$sc_tooling < 6)
            tags$p("\U0001f4a1 Review tooling comparison — know MLflow vs W\u0026B trade-offs cold."),
          if (pct >= 80)
            tags$p("\u2705 Strong experiment tracking foundation — ready to articulate in interviews.")
        )
      })
      showNotification(paste0("Experiment Tracking: ", pct, "% saved"),
                       type = "message")
    })

  })
}
