# modules/experiment_tracking.R
# Experiment Tracking Board — Chapter 6: Model Development & Offline Evaluation
# Chip Huyen, "Designing Machine Learning Systems" (O'Reilly, 2022)
# Covers: what to log, experiment management, AutoML, debugging, Huyen's 6-step loop

# ── Demo seed data (Huyen Ch.6 realistic scenarios) ──────────────────────────
.et_seed <- function() {
  data.frame(
    run_id       = paste0("run-00", 1:9),
    run_name     = c(
      "lr-baseline",
      "heuristic-baseline",
      "gbdt-v1-default",
      "gbdt-v2-focal",
      "gbdt-v3-optuna50",
      "nn-simple-v1",
      "nn-v2-dropout",
      "nn-v3-ensemble-gbdt",
      "champion-ensemble-v2"
    ),
    model_class  = c(
      "Logistic Regression",
      "Rule-Based Heuristic",
      "Gradient Boosted Trees",
      "Gradient Boosted Trees",
      "Gradient Boosted Trees",
      "Neural Network",
      "Neural Network",
      "Ensemble",
      "Ensemble"
    ),
    algorithm    = c(
      "Logistic Regression","Human Rules","XGBoost","XGBoost","XGBoost",
      "2-layer MLP","3-layer MLP + Dropout","XGBoost + MLP","XGBoost + MLP + LR"
    ),
    loss_fn      = c(
      "Log Loss","N/A","Cross-Entropy","Focal (gamma=2)","Focal (gamma=2)",
      "Cross-Entropy","Cross-Entropy","Weighted CE","Weighted CE"
    ),
    training_data = c(
      "v1-raw","v1-raw","v1-raw","v2-balanced","v2-balanced",
      "v2-balanced","v2-balanced","v3-augmented","v3-augmented"
    ),
    git_sha      = c(
      "a1b2c3","a1b2c3","d4e5f6","g7h8i9","j0k1l2",
      "m3n4o5","p6q7r8","s9t0u1","v2w3x4"
    ),
    val_auc      = c(0.748, NA, 0.821, 0.849, 0.872, 0.835, 0.851, 0.881, 0.903),
    val_logloss  = c(0.611, NA, 0.498, 0.451, 0.420, 0.462, 0.441, 0.402, 0.375),
    val_f1       = c(0.612, NA, 0.724, 0.758, 0.789, 0.741, 0.765, 0.812, 0.844),
    val_prec     = c(0.641, NA, 0.748, 0.771, 0.801, 0.762, 0.779, 0.829, 0.860),
    val_rec      = c(0.585, NA, 0.701, 0.745, 0.778, 0.721, 0.752, 0.795, 0.829),
    train_hrs    = c(0.05, 0.00, 0.8, 0.9, 3.2, 2.1, 2.5, 4.1, 4.8),
    params_M     = c(0.001, 0.000, 0.3, 0.3, 0.3, 1.2, 1.8, 2.1, 2.4),
    status       = c(
      "✅ Completed","✅ Completed","✅ Completed","✅ Completed","✅ Completed",
      "✅ Completed","✅ Completed","✅ Completed","🏆 Champion"
    ),
    notes        = c(
      "Baseline #1 — Huyen: always start with simplest model.",
      "Baseline #2 — Huyen: heuristic baseline sets the floor. If model < heuristic, something is wrong.",
      "First tree model. Big jump over LR. Feature set v1.",
      "Added focal loss for class imbalance (positive rate ~4%).",
      "Optuna TPE, 50 trials. Best single model so far.",
      "First NN. Worse than GBDT — less training data than needed.",
      "Added dropout 0.3 + batch norm. Slightly better than v1.",
      "Ensemble GBDT + MLP. Correlation between models is low — gains stack.",
      "Final ensemble: GBDT + MLP + LR. Soft voting. Champion. Passes all eval gates."
    ),
    logged_at    = c(
      "2024-01-08 09:00","2024-01-08 10:30","2024-01-09 14:00","2024-01-10 11:20",
      "2024-01-11 16:45","2024-01-12 09:30","2024-01-13 14:00","2024-01-14 10:15",
      "2024-01-15 11:00"
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
        tags$h2("Chapter 6 — Model Development & Offline Evaluation · Chip Huyen, O'Reilly 2022"),
        div(
          span(class = "hero-badge", "Log & Compare Runs"),
          span(class = "hero-badge", "Huyen's Baseline Strategy"),
          span(class = "hero-badge", "Hyperparameter Tuning"),
          span(class = "hero-badge", "AutoML"),
          span(class = "hero-badge", "Experiment Debugging"),
          span(class = "hero-badge", "Model Selection")
        )
    ),

    # ── KPI bar ───────────────────────────────────────────────────────────────
    fluidRow(
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_total"))),
        span(class = "metric-label", "Runs Logged"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_best_auc"))),
        span(class = "metric-label", "Best Val AUC"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_best_f1"))),
        span(class = "metric-label", "Best Val F1"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_model_classes"))),
        span(class = "metric-label", "Model Classes"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_champion"))),
        span(class = "metric-label", "Champion Run"))),
      column(2, div(class = "metric-card",
        span(class = "metric-value", textOutput(ns("kpi_lift"))),
        span(class = "metric-label", "AUC vs Baseline")))
    ),

    br(),

    # ── Row 1: Log form + table ───────────────────────────────────────────────
    fluidRow(

      # Left — Log form
      box(title = "➕ Log Experiment Run", status = "primary",
          solidHeader = TRUE, width = 4,

          div(class = "section-heading-dark", "Run Identity"),
          fluidRow(
            column(7, textInput(ns("run_name"), "Run Name:",
                                placeholder = "e.g. gbdt-v3-focal")),
            column(5, textInput(ns("git_sha"),  "Git SHA:",
                                placeholder = "e.g. a3f9b1c"))
          ),
          textInput(ns("training_data"), "Training Data Version:",
                    placeholder = "e.g. v2-balanced / s3://data/train/2024-01-10"),

          div(class = "section-heading-dark", "Model"),
          fluidRow(
            column(6,
              selectInput(ns("model_class"), "Model Class:",
                choices = c(
                  "Rule-Based Heuristic",
                  "Logistic Regression",
                  "Gradient Boosted Trees",
                  "Random Forest",
                  "Neural Network",
                  "Ensemble",
                  "Pretrained + Fine-tuned",
                  "AutoML Output",
                  "Custom / Other"
                ))),
            column(6, textInput(ns("algorithm"), "Algorithm / Framework:",
                                placeholder = "e.g. XGBoost, PyTorch MLP"))
          ),
          selectInput(ns("loss_fn"), "Loss Function:",
            choices = c(
              "Cross-Entropy / Log Loss",
              "Focal Loss — class imbalance",
              "Binary Cross-Entropy",
              "MSE / MAE",
              "Huber Loss",
              "Contrastive / Triplet",
              "Custom multi-task",
              "N/A (rule-based)"
            )),

          div(class = "section-heading-dark", "Offline Metrics"),
          fluidRow(
            column(4, numericInput(ns("val_auc"),  "Val AUC:",  value=NA, min=0, max=1, step=0.001)),
            column(4, numericInput(ns("val_f1"),   "Val F1:",   value=NA, min=0, max=1, step=0.001)),
            column(4, numericInput(ns("val_prec"), "Val Prec:", value=NA, min=0, max=1, step=0.001))
          ),
          fluidRow(
            column(4, numericInput(ns("val_rec"),     "Val Recall:", value=NA, min=0, max=1, step=0.001)),
            column(4, numericInput(ns("val_logloss"), "Log-Loss:",   value=NA, min=0,       step=0.001)),
            column(4, numericInput(ns("train_hrs"),   "Train Hrs:",  value=NA, min=0,       step=0.25))
          ),
          numericInput(ns("params_M"), "Model Parameters (millions):",
                       value=NA, min=0, step=0.1),

          div(class = "section-heading-dark", "Status & Notes"),
          fluidRow(
            column(7,
              selectInput(ns("status"), "Status:",
                choices = c("✅ Completed","🔄 Running","❌ Failed",
                            "⏸ Paused","🏆 Champion"))),
            column(5,
              selectInput(ns("sort_metric"), "Rank Runs By:",
                choices = c("Val AUC ↓","Val F1 ↓","Log-Loss ↑","Train Hrs ↑")))
          ),
          textAreaInput(ns("notes"), "Notes / Hypothesis:",
                        placeholder = "What did you change? What do results mean? What's next?",
                        rows = 3, width = "100%"),
          br(),
          fluidRow(
            column(8, actionButton(ns("log_run"), "📝 Log Run",
                                   class = "btn-meta", width = "100%",
                                   icon = icon("plus-circle"))),
            column(4, actionButton(ns("load_demo"), "Demo Data",
                                   class = "btn btn-default btn-sm",
                                   style = "width:100%;font-size:11px;margin-top:1px;"))
          )
      ),

      # Right — Runs table
      box(title = "📋 Runs Log", status = "info",
          solidHeader = TRUE, width = 8,
          fluidRow(
            column(3, selectInput(ns("flt_class"), "Model Class:",
                                  choices = "All", width = "100%")),
            column(3, selectInput(ns("flt_status"), "Status:",
                                  choices = c("All","✅ Completed","🔄 Running",
                                              "❌ Failed","🏆 Champion"),
                                  width = "100%")),
            column(3, selectInput(ns("flt_data"), "Data Version:",
                                  choices = "All", width = "100%")),
            column(3, br(),
              actionButton(ns("clear_runs"), "🗑 Clear",
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
            tabPanel("AUC by Run",
              br(), plotly::plotlyOutput(ns("chart_auc"),        height = "290px")),
            tabPanel("F1 / Precision / Recall",
              br(), plotly::plotlyOutput(ns("chart_f1"),         height = "290px")),
            tabPanel("Log-Loss Trend",
              br(), plotly::plotlyOutput(ns("chart_logloss"),    height = "290px")),
            tabPanel("Model Class Comparison",
              br(), plotly::plotlyOutput(ns("chart_class"),      height = "290px")),
            tabPanel("Cost vs Quality",
              br(), plotly::plotlyOutput(ns("chart_cost"),       height = "290px")),
            tabPanel("Baseline Gap",
              br(), plotly::plotlyOutput(ns("chart_baseline"),   height = "290px"))
          )
      )
    ),

    # ── Row 3: Diff + Huyen Baseline Rule ─────────────────────────────────────
    fluidRow(

      box(title = "🔍 Run Diff", status = "success",
          solidHeader = TRUE, width = 5,
          div(class = "tip-box",
            HTML("<strong>💡 Huyen Ch.6:</strong> Compare every new model against a well-defined baseline. Understand exactly what changed and why the metric moved — without this, experiments are noise.")),
          br(),
          fluidRow(
            column(6, uiOutput(ns("ui_run_a"))),
            column(6, uiOutput(ns("ui_run_b")))
          ),
          actionButton(ns("do_diff"), "⚡ Compare",
                       class = "btn-meta", icon = icon("code-branch")),
          br(), br(),
          uiOutput(ns("diff_out"))
      ),

      box(title = "🏆 Champion & Baseline Tracker", status = "success",
          solidHeader = TRUE, width = 7,

          div(class = "section-heading-dark", "Huyen's Baseline Hierarchy"),
          div(class = "tip-box",
            HTML("<strong>Huyen, Ch.6 — Always establish multiple baselines before model development:</strong>")),
          fluidRow(
            column(6,
              div(class = "framework-card",
                tags$h5("Tier 1 — Random / Constant"),
                tags$p("Predict majority class always. For imbalanced problems (e.g. fraud detection, 1% positive), this trivially achieves 99% accuracy. Shows why accuracy is a poor metric."),
                tags$p(style="margin-top:6px;",
                  tags$b("When you must beat it: "), "Always — if your model can't beat random, something is fundamentally broken.")),
              div(class = "framework-card",
                tags$h5("Tier 2 — Human / Rule-Based Heuristic"),
                tags$p("Domain experts writing rules. E.g., 'flag transactions > $10,000 in a new country'. This is your real floor for most business problems."),
                tags$p(style="margin-top:6px;",
                  tags$b("Huyen: "), "If your model doesn't beat a heuristic baseline, it's not ready for production — full stop."))
            ),
            column(6,
              div(class = "framework-card",
                tags$h5("Tier 3 — Simple ML Model"),
                tags$p("Logistic regression with basic features. Fast to train, highly interpretable, excellent debugging tool. Unexpectedly strong in practice — Huyen cites cases where LR beats deep nets on structured data."),
                tags$p(style="margin-top:6px;",
                  tags$b("When to use: "), "Before any tree model or neural net. If LR with good features performs well, that's signal to focus on feature engineering, not architecture.")),
              div(class = "framework-card",
                tags$h5("Tier 4 — SotA / Published Reference"),
                tags$p("Reproduce or reference the best published result on your task/data type. Sets ceiling expectations."),
                tags$p(style="margin-top:6px;",
                  tags$b("Huyen: "), "Knowing the SotA helps you calibrate how much headroom exists and informs architecture choices."))
            )
          ),
          br(),
          div(class = "section-heading-dark", "Current Champion"),
          uiOutput(ns("champion_card"))
      )
    ),

    # ── Row 4: Huyen theory tabs ──────────────────────────────────────────────
    fluidRow(
      box(title = "📖 Huyen Ch.6 — Theory Deep Dive", status = "primary",
          solidHeader = TRUE, width = 12,
          tabsetPanel(

            # ── What to log ────────────────────────────────────────────────
            tabPanel("What to Log",
              br(),
              div(class = "success-box",
                HTML("<strong>Huyen's core principle:</strong> Experiment tracking isn't optional overhead — it IS the scientific method applied to ML. Without it you can't debug failures, reproduce successes, or justify architectural choices to stakeholders.")),
              br(),
              fluidRow(
                column(3,
                  div(class = "framework-card",
                    tags$h5("Model Artifacts"),
                    tags$p("Everything that defines the model:"),
                    tags$ul(
                      tags$li("Loss function + all hyperparameters"),
                      tags$li("Model architecture (layers, units, activations)"),
                      tags$li("Optimizer + learning rate schedule"),
                      tags$li("Serialised weights / checkpoint path"),
                      tags$li("Feature list and feature importance"),
                      tags$li("Random seed (for every source)")
                    ))),
                column(3,
                  div(class = "framework-card",
                    tags$h5("Data Provenance"),
                    tags$p("Huyen: treating data version with the same rigour as code version is non-negotiable:"),
                    tags$ul(
                      tags$li("Training data version / snapshot ID"),
                      tags$li("Train/val/test split strategy and dates"),
                      tags$li("Label definition version (label drift!)"),
                      tags$li("Feature set version / feature store tag"),
                      tags$li("Class distribution (+ imbalance ratio)")
                    ))),
                column(3,
                  div(class = "framework-card",
                    tags$h5("Execution Environment"),
                    tags$p("Full reproducibility requires:"),
                    tags$ul(
                      tags$li("Git commit SHA — mandatory"),
                      tags$li("Python + framework versions (requirements.txt hash)"),
                      tags$li("Hardware: GPU model, CUDA version"),
                      tags$li("Docker image tag (best practice)"),
                      tags$li("Training duration + compute cost estimate")
                    ))),
                column(3,
                  div(class = "framework-card",
                    tags$h5("Evaluation Results"),
                    tags$p("Never log just one number:"),
                    tags$ul(
                      tags$li("All offline metrics (AUC, F1, precision, recall, log-loss)"),
                      tags$li("Per-slice metrics — user segments, time periods, geography"),
                      tags$li("Train vs val curves (loss per epoch)"),
                      tags$li("Confusion matrix / calibration curve"),
                      tags$li("Statistical confidence intervals where possible")
                    )))
              ),
              br(),
              div(class = "warn-box",
                HTML("<strong>⚠️ Huyen's debugging warning:</strong> The three most common causes of an experiment failing to improve over baseline are: (1) a data bug — wrong labels, leakage, or the wrong split; (2) a hyperparameter that wasn't tuned; (3) a code bug in the evaluation pipeline. Log everything so you can distinguish them."))
            ),

            # ── Huyen's 6-step loop ────────────────────────────────────────
            tabPanel("Huyen's Iterative Loop",
              br(),
              fluidRow(
                column(7,
                  div(class = "section-heading-dark", "The Iterative ML Development Loop (Ch. 6)"),
                  div(class = "tip-box",
                    HTML("<strong>Huyen's framework:</strong> ML development is not linear — it's an iterative loop where each step can force you backwards. The fastest teams iterate quickly and log everything so they can backtrack efficiently.")),
                  br(),
                  div(class = "timeline-item",
                    div(class = "timeline-badge", "1"),
                    div(class = "timeline-content",
                      tags$h6("Start with the Simplest Model That Could Possibly Work"),
                      tags$p("Resist the temptation to start with the most complex architecture. A logistic regression with good features often beats a neural net with bad features. Huyen: 'Simple models are easier to debug, faster to train, and set a clear bar for what complexity needs to justify.'"))),
                  div(class = "timeline-item",
                    div(class = "timeline-badge", "2"),
                    div(class = "timeline-content",
                      tags$h6("Overfit a Small Batch First"),
                      tags$p("Before training on the full dataset, verify your model can perfectly overfit a batch of 2–10 examples. If it can't, there's a bug in the model, loss function, or data pipeline. This is Huyen's standard sanity check — saves hours."))),
                  div(class = "timeline-item",
                    div(class = "timeline-badge", "3"),
                    div(class = "timeline-content",
                      tags$h6("Bias vs Variance Diagnosis"),
                      tags$p("High training error → underfitting (bias problem): use more complex model or better features. Low training error, high val error → overfitting (variance problem): regularise, add data, or reduce model size. Huyen: always know which regime you're in before changing architecture."))),
                  div(class = "timeline-item",
                    div(class = "timeline-badge", "4"),
                    div(class = "timeline-content",
                      tags$h6("Tune Hyperparameters"),
                      tags$p("Don't do this manually for more than 2–3 parameters. Use random search as default, Bayesian for expensive training, neural architecture search (NAS) or AutoML when the architecture itself is unknown. Log all trials — not just winners."))),
                  div(class = "timeline-item",
                    div(class = "timeline-badge", "5"),
                    div(class = "timeline-content",
                      tags$h6("Evaluate Holistically"),
                      tags$p("Aggregate metrics (AUC, F1) hide problems. Slice your evaluation data by user cohort, time period, geography, and edge cases. Huyen: 'A model that achieves 95% accuracy overall but 60% accuracy on your most important user segment is a bad model.'"))),
                  div(class = "timeline-item",
                    div(class = "timeline-badge", "6"),
                    div(class = "timeline-content",
                      tags$h6("Perturbation & Debugging Tests"),
                      tags$p("Before declaring success: (1) permute input features — if permuting important features doesn't change the output, there's a bug; (2) add random noise — model should degrade gracefully; (3) remove features one by one to measure true marginal value.")))
                ),
                column(5,
                  div(class = "section-heading-dark", "When to Stop Iterating"),
                  div(class = "framework-card",
                    tags$h5("Convergence Signals"),
                    tags$ul(
                      tags$li("Marginal gain per additional experiment < business threshold"),
                      tags$li("Offline-online metric gap is stable across experiments"),
                      tags$li("Model passes all sliced evaluation gates"),
                      tags$li("Compute cost vs marginal quality gain is unfavourable")
                    )),
                  div(class = "framework-card",
                    tags$h5("Huyen's Ensemble Rule"),
                    tags$p("Ensembling is most effective when:"),
                    tags$ul(
                      tags$li("Base models have LOW correlation in errors"),
                      tags$li("Model types are diverse (tree + NN + linear)"),
                      tags$li("Inference latency budget allows it")
                    ),
                    tags$p(style="margin-top:6px;",
                      tags$b("Anti-pattern: "), "Ensembling two XGBoost models trained on the same features — high correlation, minimal gain, double the cost.")),
                  div(class = "framework-card",
                    tags$h5("Experiment Velocity Tips"),
                    tags$ul(
                      tags$li("Never run experiments serially if you can parallelise"),
                      tags$li("Use a validation set that's representative of your deployment distribution"),
                      tags$li("Set a compute budget per experiment upfront and respect it"),
                      tags$li("Always document the hypothesis before running — not after seeing results ('HARKing' is the enemy of reproducible ML)")
                    )),
                  div(class = "warn-box",
                    HTML("<strong>⚠️ HARKing:</strong> Hypothesising After Results are Known. Running many experiments, seeing what worked, and retrofitting a hypothesis is a major reproducibility failure. Log your hypothesis BEFORE the experiment."))
                )
              )
            ),

            # ── HPO ────────────────────────────────────────────────────────
            tabPanel("Hyperparameter Tuning",
              br(),
              fluidRow(
                column(4,
                  div(class = "framework-card",
                    tags$h5("Manual Tuning"),
                    tags$p(tags$b("When appropriate:"), " 1–2 obviously dominant hyperparameters, strong domain intuition about the search space."),
                    tags$p("Still log every manual trial — intuition about which params matter is only valid if systematically verified."),
                    div(class = "warn-box",
                      HTML("<strong>Huyen:</strong> Manual tuning at scale is unsustainable and non-reproducible. Use automated methods for any experiment you'd run more than 5 times."))),
                  div(class = "framework-card",
                    tags$h5("Random Search"),
                    tags$p(tags$b("Default choice."), " Bergstra & Bengio (2012): far more efficient than grid search for high-dimensional spaces. Most HPO problems have low intrinsic dimensionality — only 1–2 params truly matter."),
                    div(class = "success-box",
                      HTML("<strong>Huyen's practice:</strong> Start here. Run 50–100 random trials before investing in Bayesian.")))
                ),
                column(4,
                  div(class = "framework-card",
                    tags$h5("Bayesian Optimisation"),
                    tags$p(tags$b("When training is expensive (hours per run)."), " Builds a probabilistic surrogate model of the objective function, balancing exploitation of known good regions and exploration of unknowns."),
                    tags$p(tags$b("Acquisition function: "), "Expected Improvement (EI) or Upper Confidence Bound (UCB)."),
                    tags$p(tags$b("Tools: "), "Optuna (TPE — Huyen's preferred default), Hyperopt, BoTorch."),
                    div(class = "success-box",
                      HTML("<strong>Huyen's recommendation:</strong> Optuna with TPE sampler. Track all trials — not just winners — in your experiment tracker."))),
                  div(class = "framework-card",
                    tags$h5("Early Stopping"),
                    tags$p("Kill unpromising runs early. Successive Halving: allocate minimal budget to all candidates, promote top performers, repeat. ASHA (Asynchronous Successive Halving) is the async variant."),
                    tags$p(tags$b("When: "), "Training cost > 30 min, many candidates. Pair with Bayesian for maximum efficiency."))
                ),
                column(4,
                  div(class = "framework-card",
                    tags$h5("AutoML"),
                    tags$p("Automates the joint search over architecture and hyperparameters. Key systems:"),
                    tags$ul(
                      tags$li(tags$b("AutoSklearn:"), " Bayesian HPO + meta-learning on historical tasks. Strong for tabular data."),
                      tags$li(tags$b("Google AutoML / Vertex AutoML:"), " Managed NAS + HPO. Production-grade for GCP users."),
                      tags$li(tags$b("H2O AutoML:"), " Open-source. Good ensemble generation."),
                      tags$li(tags$b("FLAML (Microsoft):"), " Cost-efficient AutoML. Huyen notes this is well-suited for time-constrained scenarios.")
                    ),
                    div(class = "tip-box",
                      HTML("<strong>💡 Huyen's take:</strong> AutoML is most valuable when the team is ML-experienced but time-constrained, or when the architecture choice is genuinely unclear. It is NOT a substitute for understanding your data."))),
                  div(class = "framework-card",
                    tags$h5("Huyen's HPO Decision Guide"),
                    div(class = "hpo-decision-node",
                      tags$strong("< 5 params, fast train:"), " Manual + random (30 trials)"),
                    div(class = "hpo-decision-node",
                      tags$strong("Many params, < 30 min:"), " Random search (100 trials)"),
                    div(class = "hpo-decision-node",
                      tags$strong("30 min – 3 hr per run:"), " Bayesian (Optuna TPE, 50 trials)"),
                    div(class = "hpo-decision-node",
                      tags$strong("> 3 hr per run:"), " Successive halving + Bayesian"),
                    div(class = "hpo-decision-node",
                      tags$strong("Architecture unknown:"), " AutoML or NAS"))
                )
              )
            ),

            # ── Model Selection ────────────────────────────────────────────
            tabPanel("Model Selection Logic",
              br(),
              div(class = "tip-box",
                HTML("<strong>Huyen Ch.6:</strong> Model selection should be driven by the problem constraints, not architectural fashion. Ask: what are the latency, compute, and interpretability requirements before choosing a model family.")),
              br(),
              fluidRow(
                column(6,
                  tags$table(class = "table table-hover",
                    tags$thead(tags$tr(
                      tags$th("Model Class"), tags$th("Best When"), tags$th("Watch Out For")
                    )),
                    tags$tbody(
                      tags$tr(
                        tags$td(tags$b("Logistic Regression")),
                        tags$td("Baseline, interpretability required, features are well-engineered, online learning needed."),
                        tags$td("Non-linear relationships; feature interactions must be manual.")
                      ),
                      tags$tr(
                        tags$td(tags$b("Gradient Boosted Trees")),
                        tags$td("Tabular data, fast inference, strong regularisation, less data than NNs need. Huyen: 'Often the best first real model on structured data.'"),
                        tags$td("Large datasets become slow; doesn't handle sequential/image data natively.")
                      ),
                      tags$tr(
                        tags$td(tags$b("Neural Networks")),
                        tags$td("Unstructured data (text, image, audio), sequential patterns, large data budgets, when embeddings are needed downstream."),
                        tags$td("Require more data; harder to debug; slower to iterate on; latency risk.")
                      ),
                      tags$tr(
                        tags$td(tags$b("Ensemble")),
                        tags$td("When base models have low error correlation; when marginal quality gain justifies inference cost."),
                        tags$td("Doubles/triples training and serving cost; debugging is harder; often overkill.")
                      ),
                      tags$tr(
                        tags$td(tags$b("Pretrained + Fine-tuned")),
                        tags$td("NLP, vision, audio. Small in-domain training data. Transfer learning almost always helps on these modalities."),
                        tags$td("License, latency, and cost. Large model → deployment complexity.")
                      )
                    )
                  )
                ),
                column(6,
                  div(class = "framework-card",
                    tags$h5("Huyen's Six Selection Criteria"),
                    tags$ol(
                      tags$li(tags$b("Business constraints first:"), " latency SLO, compute budget, interpretability requirements."),
                      tags$li(tags$b("Data characteristics:"), " size, modality, label quality, class imbalance."),
                      tags$li(tags$b("Team expertise:"), " a well-understood model is better than a state-of-the-art model no-one can debug."),
                      tags$li(tags$b("Offline-online gap:"), " choose models with proven correlation between offline and online metrics for your task type."),
                      tags$li(tags$b("Iteration speed:"), " prefer models that can be retrained quickly on new data."),
                      tags$li(tags$b("Baseline first:"), " no complex model should be deployed without demonstrating a clear, statistically significant improvement over the best baseline.")
                    )),
                  div(class = "framework-card",
                    tags$h5("Neural Architecture Search (NAS) — Huyen's View"),
                    tags$p("NAS automates the search over layer configurations, skip connections, and activation functions. Used by Google (EfficientNet, NASNet), Microsoft, and major labs."),
                    tags$p(tags$b("Cost:"), " Naive NAS is extremely expensive (thousands of GPU-hours). Differentiable NAS (DARTS) and one-shot NAS reduce cost significantly."),
                    tags$p(tags$b("When to consider:"), " Only when the team has evidence that architecture is the bottleneck, not data or features. For most production ML problems, architecture search is premature optimisation."),
                    div(class = "warn-box",
                      HTML("<strong>Huyen:</strong> Avoid NAS unless architecture really is the bottleneck. In practice, better data and better features outperform better architecture most of the time.")))
                )
              )
            ),

            # ── Debugging ─────────────────────────────────────────────────
            tabPanel("Debugging & Perturbation Tests",
              br(),
              div(class = "warn-box",
                HTML("<strong>Huyen Ch.6:</strong> Most 'model problems' are actually data problems or evaluation bugs. Run these tests before concluding your architecture is at fault.")),
              br(),
              fluidRow(
                column(4,
                  div(class = "framework-card",
                    tags$h5("1. Overfit a Tiny Batch"),
                    tags$p("Feed the model 2–10 examples and train until the loss goes to near-zero. If it can't:"),
                    tags$ul(
                      tags$li("Loss function is buggy or ill-conditioned"),
                      tags$li("Model has insufficient capacity"),
                      tags$li("Gradient flow is broken (vanishing/exploding)"),
                      tags$li("Data pipeline is corrupted")
                    ),
                    div(class = "success-box",
                      HTML("<strong>Expected outcome:</strong> Loss → ~0 on tiny batch in a few dozen iterations. If not, fix this before training on the full dataset."))),
                  div(class = "framework-card",
                    tags$h5("2. Learning Curve Analysis"),
                    tags$p(tags$b("High train AND val error (underfitting):"), " Add capacity, better features, longer training, lower regularisation."),
                    tags$p(tags$b("Low train error, high val error (overfitting):"), " Add regularisation, more data, data augmentation, reduce model size."),
                    tags$p(tags$b("Train/val gap stable but both high:"), " Representational issue — your features don't encode the signal."))
                ),
                column(4,
                  div(class = "framework-card",
                    tags$h5("3. Feature Permutation Test"),
                    tags$p("Randomly shuffle the values of one feature column at a time. Expected results:"),
                    tags$ul(
                      tags$li("Permuting important features → large metric drop"),
                      tags$li("Permuting unimportant features → small or no change"),
                      tags$li(tags$b("Permuting random noise → metric IMPROVES"), " → your model learned to use noise, data leakage is likely")
                    ),
                    div(class = "warn-box",
                      HTML("<strong>Huyen:</strong> If permuting a feature INCREASES validation metric, that feature encodes leakage and must be removed."))),
                  div(class = "framework-card",
                    tags$h5("4. Sensitivity to Random Seed"),
                    tags$p("Train the same model 3–5 times with different seeds. High variance across seeds suggests:"),
                    tags$ul(
                      tags$li("Dataset is too small"),
                      tags$li("Learning rate is too high — escaping minima"),
                      tags$li("Model is near a phase transition — change capacity")
                    ),
                    tags$p(tags$b("Good practice:"), " report mean ± std across seeds rather than the single best run."))
                ),
                column(4,
                  div(class = "framework-card",
                    tags$h5("5. Perturbation / Noise Test"),
                    tags$p("Add Gaussian noise to input features at increasing magnitudes. A robust model should:"),
                    tags$ul(
                      tags$li("Degrade gradually (not catastrophically) as noise increases"),
                      tags$li("Show higher sensitivity to semantically important features"),
                      tags$li("Show low sensitivity to known-noisy features")
                    ),
                    tags$p("Sharp cliffs in the noise curve indicate the model is relying on brittle feature interactions.")),
                  div(class = "framework-card",
                    tags$h5("6. Invariance & Equivariance Checks"),
                    tags$p("Define transformations that should NOT change the output (invariance) or should change it proportionally (equivariance)."),
                    tags$ul(
                      tags$li(tags$b("Example invariance:"), " translating an image should not change the object class prediction"),
                      tags$li(tags$b("Example equivariance:"), " doubling all prices should double the predicted revenue")
                    ),
                    div(class = "tip-box",
                      HTML("<strong>Huyen:</strong> Violations indicate the model has learned spurious correlations — a risk for production reliability.")))
                )
              )
            ),

            # ── Tooling ────────────────────────────────────────────────────
            tabPanel("Tooling Reference",
              br(),
              fluidRow(
                column(12,
                  tags$table(class = "table table-hover",
                    tags$thead(tags$tr(
                      tags$th("Tool"), tags$th("Type"),
                      tags$th("Tracking"), tags$th("Vis. & Collab."),
                      tags$th("Model Registry"), tags$th("Huyen's Notes")
                    )),
                    tags$tbody(
                      tags$tr(
                        tags$td(tags$b("MLflow")), tags$td("Open-source"),
                        tags$td(tags$span(class="badge-green","Yes")),
                        tags$td("Basic UI"),
                        tags$td(tags$span(class="badge-green","Built-in")),
                        tags$td("Most widely adopted. Open-source, backend-agnostic, works offline. De facto standard for teams not on a managed cloud.")),
                      tags$tr(
                        tags$td(tags$b("Weights & Biases")), tags$td("SaaS / On-prem"),
                        tags$td(tags$span(class="badge-green","Rich")),
                        tags$td(tags$span(class="badge-green","Best-in-class")),
                        tags$td("Via Artifacts"),
                        tags$td("Huyen cites W&B as preferred for research teams. Best visualisation. Automatic system metrics (GPU/CPU). Built-in Sweeps HPO.")),
                      tags$tr(
                        tags$td(tags$b("Neptune.ai")), tags$td("SaaS"),
                        tags$td(tags$span(class="badge-green","Yes")),
                        tags$td("Good"),
                        tags$td("Yes"),
                        tags$td("Strong metadata query API. Notebook versioning. Good for compliance-heavy environments.")),
                      tags$tr(
                        tags$td(tags$b("Comet ML")), tags$td("SaaS / On-prem"),
                        tags$td(tags$span(class="badge-green","Yes")),
                        tags$td("Good"),
                        tags$td("Yes"),
                        tags$td("Automatic code capture is distinctive. Good diff tooling between runs.")),
                      tags$tr(
                        tags$td(tags$b("Vertex AI Experiments")), tags$td("Managed (GCP)"),
                        tags$td(tags$span(class="badge-green","Yes")),
                        tags$td("Good"),
                        tags$td(tags$span(class="badge-green","Via Vertex")),
                        tags$td("Native GCP. No infra. Best when training on Vertex AI pipelines.")),
                      tags$tr(
                        tags$td(tags$b("SageMaker Experiments")), tags$td("Managed (AWS)"),
                        tags$td(tags$span(class="badge-green","Yes")),
                        tags$td("Basic"),
                        tags$td(tags$span(class="badge-green","Via SageMaker")),
                        tags$td("Native AWS. Integrates with SageMaker training jobs and model registry. Tighter API than W&B.")),
                      tags$tr(
                        tags$td(tags$b("DVC")), tags$td("Open-source"),
                        tags$td("Via Studio"),
                        tags$td("DVC Studio"),
                        tags$td("Via Git"),
                        tags$td("Huyen notes DVC excels when data versioning (not just model versioning) is the priority. Git-native workflow."))
                    )
                  )
                )
              ),
              br(),
              div(class = "info-box-plain",
                HTML("<strong>💡 Interview answer (Huyen-aligned):</strong> 'I'd default to MLflow — open-source, no vendor lock-in, bundles tracking and a model registry. If the team is research-heavy with frequent collaborative analysis, I'd add W&B for its richer visualisation and Sweeps integration. For a managed cloud deployment, I'd use the native option (Vertex or SageMaker) to reduce infra burden.'"))
            )
          )
      )
    ),

    # ── Self-assessment ───────────────────────────────────────────────────────
    fluidRow(
      box(title = "📊 Self-Assessment: Experiment Tracking (Ch.6)",
          status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3,
              sliderInput(ns("sc_what_log"),  "What to log per experiment",     0, 10, 5),
              sliderInput(ns("sc_baseline"),  "Baseline strategy (4 tiers)",    0, 10, 5)),
            column(3,
              sliderInput(ns("sc_iterloop"), "Huyen's iterative dev loop",      0, 10, 5),
              sliderInput(ns("sc_hpo"),       "HPO methods + AutoML",            0, 10, 5)),
            column(3,
              sliderInput(ns("sc_debug"),     "Debugging + perturbation tests",  0, 10, 5),
              sliderInput(ns("sc_selection"), "Model selection logic",            0, 10, 5)),
            column(3,
              br(),
              actionButton(ns("calc_score"), "Save Assessment",
                           class = "btn-meta", width = "100%"),
              br(), br(),
              uiOutput(ns("score_result")))
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

    # ── Run store ─────────────────────────────────────────────────────────────
    runs <- reactiveVal(.et_seed())

    # ── KPIs ──────────────────────────────────────────────────────────────────
    output$kpi_total <- renderText({ nrow(runs()) })

    output$kpi_best_auc <- renderText({
      v <- runs()$val_auc
      if (!length(v) || all(is.na(v))) return("—")
      sprintf("%.3f", max(v, na.rm = TRUE))
    })

    output$kpi_best_f1 <- renderText({
      v <- runs()$val_f1
      if (!length(v) || all(is.na(v))) return("—")
      sprintf("%.3f", max(v, na.rm = TRUE))
    })

    output$kpi_model_classes <- renderText({
      df <- runs()
      if (!nrow(df)) return("0")
      length(unique(df$model_class))
    })

    output$kpi_champion <- renderText({
      df <- runs()
      champ <- df[grepl("Champion", df$status), ]
      if (!nrow(champ)) {
        if (!nrow(df) || all(is.na(df$val_auc))) return("—")
        return(df$run_id[which.max(df$val_auc)])
      }
      champ$run_id[1]
    })

    output$kpi_lift <- renderText({
      df  <- runs()
      all_auc <- df$val_auc[!is.na(df$val_auc)]
      if (length(all_auc) < 2) return("—")
      base_auc <- min(all_auc)
      best_auc <- max(all_auc)
      sprintf("+%.3f", best_auc - base_auc)
    })

    # ── Log run ───────────────────────────────────────────────────────────────
    observeEvent(input$log_run, {
      req(nzchar(trimws(input$run_name)))
      new_id <- sprintf("run-%03d", nrow(runs()) + 1)
      new_row <- data.frame(
        run_id       = new_id,
        run_name     = trimws(input$run_name),
        model_class  = input$model_class,
        algorithm    = input$algorithm,
        loss_fn      = input$loss_fn,
        training_data = input$training_data,
        git_sha      = input$git_sha,
        val_auc      = as.numeric(input$val_auc),
        val_logloss  = as.numeric(input$val_logloss),
        val_f1       = as.numeric(input$val_f1),
        val_prec     = as.numeric(input$val_prec),
        val_rec      = as.numeric(input$val_rec),
        train_hrs    = as.numeric(input$train_hrs),
        params_M     = as.numeric(input$params_M),
        status       = input$status,
        notes        = input$notes,
        logged_at    = format(Sys.time(), "%Y-%m-%d %H:%M"),
        stringsAsFactors = FALSE
      )
      runs(rbind(runs(), new_row))
      updateSelectInput(session, "flt_class",
                        choices = c("All", unique(runs()$model_class)))
      updateSelectInput(session, "flt_data",
                        choices = c("All", unique(runs()$training_data)))
      showNotification(paste0("✅ ", new_id, " — '", new_row$run_name, "' logged."),
                       type = "message", duration = 4)
    })

    # ── Demo data ─────────────────────────────────────────────────────────────
    observeEvent(input$load_demo, {
      runs(.et_seed())
      seed <- .et_seed()
      updateSelectInput(session, "flt_class",
                        choices = c("All", unique(seed$model_class)))
      updateSelectInput(session, "flt_data",
                        choices = c("All", unique(seed$training_data)))
      showNotification("Demo runs loaded.", type = "message")
    })

    # ── Clear ─────────────────────────────────────────────────────────────────
    observeEvent(input$clear_runs, {
      runs(.et_seed()[0, ])
      updateSelectInput(session, "flt_class", choices = "All")
      updateSelectInput(session, "flt_data",  choices = "All")
      showNotification("All runs cleared.", type = "warning")
    })

    # ── Filtered view ─────────────────────────────────────────────────────────
    view <- reactive({
      df <- runs()
      if (!nrow(df)) return(df)
      if (!is.null(input$flt_class)  && input$flt_class  != "All") df <- df[df$model_class   == input$flt_class,  ]
      if (!is.null(input$flt_status) && input$flt_status != "All") df <- df[df$status         == input$flt_status, ]
      if (!is.null(input$flt_data)   && input$flt_data   != "All") df <- df[df$training_data  == input$flt_data,   ]
      sm <- input$sort_metric %||% "Val AUC \u2193"
      sc <- switch(sm,
        "Val AUC \u2193"    = "val_auc",
        "Val F1 \u2193"     = "val_f1",
        "Log-Loss \u2191"   = "val_logloss",
        "Train Hrs \u2191"  = "train_hrs",
        "val_auc"
      )
      desc <- !grepl("\u2191", sm)
      if (sc %in% names(df))
        df <- df[order(df[[sc]], decreasing = desc, na.last = TRUE), ]
      df
    })

    # ── Runs DT table ─────────────────────────────────────────────────────────
    output$runs_table <- DT::renderDataTable({
      df <- view()
      if (!nrow(df)) {
        return(DT::datatable(
          data.frame(Message = "No runs — log one or click 'Demo Data'."),
          options = list(dom = "t", paging = FALSE), rownames = FALSE
        ))
      }
      disp <- df[, c("run_id","run_name","model_class","algorithm",
                     "val_auc","val_f1","val_prec","val_rec","val_logloss",
                     "train_hrs","params_M","status","logged_at")]
      colnames(disp) <- c("Run","Name","Class","Algorithm",
                          "AUC","F1","Prec","Rec","LogLoss",
                          "Hrs","Params(M)","Status","Logged")
      for (col in c("AUC","F1","Prec","Rec","LogLoss"))
        disp[[col]] <- round(as.numeric(disp[[col]]), 4)

      DT::datatable(
        disp,
        selection  = "single",
        rownames   = FALSE,
        extensions = "Buttons",
        options    = list(
          dom = "Bfrtip",
          buttons = list("csv","copy"),
          pageLength = 9,
          scrollX    = TRUE,
          columnDefs = list(list(className = "dt-center", targets = "_all"))
        )
      ) %>%
        DT::formatStyle(
          "AUC",
          background         = DT::styleColorBar(c(0.5, 1), "rgba(14,165,233,0.22)"),
          backgroundSize     = "100% 70%",
          backgroundRepeat   = "no-repeat",
          backgroundPosition = "center"
        ) %>%
        DT::formatStyle(
          "Status",
          color = DT::styleEqual(
            c("✅ Completed","🔄 Running","❌ Failed","⏸ Paused","🏆 Champion"),
            c("#10b981","#f59e0b","#ef4444","#8a9bb0","#38bdf8")
          ),
          fontWeight = "bold",
          fontSize   = "11px"
        )
    })

    # ── Chart helpers ─────────────────────────────────────────────────────────
    BL <- list(
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor  = "rgba(0,0,0,0)",
      font      = list(family = "Inter, sans-serif", color = "#8a9bb0", size = 11),
      xaxis     = list(gridcolor = "rgba(14,165,233,0.08)",
                       zerolinecolor = "rgba(14,165,233,0.15)",
                       tickfont = list(size = 10)),
      yaxis     = list(gridcolor = "rgba(14,165,233,0.08)",
                       zerolinecolor = "rgba(14,165,233,0.15)"),
      hoverlabel = list(bgcolor = "#020810", bordercolor = "#0ea5e9",
                        font = list(color = "#e0f2fe", size = 11)),
      margin    = list(l = 55, r = 25, t = 45, b = 65),
      legend    = list(orientation = "h", y = -0.30,
                       font = list(color = "#8a9bb0", size = 10))
    )

    no_data <- function(msg = "No data — log runs or click 'Demo Data'.") {
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

    BLUE    <- "rgba(14,165,233,0.85)"
    BLUE_DIM <- "rgba(14,165,233,0.30)"
    GREEN   <- "#10b981"
    AMBER   <- "#f59e0b"

    # ── AUC bars ──────────────────────────────────────────────────────────────
    output$chart_auc <- plotly::renderPlotly({
      df <- view()
      if (!nrow(df) || all(is.na(df$val_auc))) return(no_data())
      best <- max(df$val_auc, na.rm = TRUE)
      df$is_best <- !is.na(df$val_auc) & df$val_auc == best

      plotly::plot_ly(df,
        x    = ~run_id, y = ~val_auc,
        type = "bar",
        text = ~ifelse(is.na(val_auc), "", sprintf("%.4f", val_auc)),
        textposition = "outside",
        customdata   = ~paste0(run_name, "<br>", model_class),
        hovertemplate = "<b>%{x}</b><br>%{customdata}<br>AUC: %{y:.4f}<extra></extra>",
        marker = list(
          color = ~ifelse(is_best, BLUE, BLUE_DIM),
          line  = list(color = "rgba(14,165,233,0.5)", width = 1)
        )
      ) %>%
        plotly::add_segments(
          x    = ~run_id[1], xend = ~run_id[nrow(df)],
          y    = ~best, yend = ~best,
          inherit = FALSE,
          line = list(color = GREEN, width = 1.5, dash = "dot"),
          name = paste0("Champion AUC (", sprintf("%.4f", best), ")")
        ) %>%
        plotly::layout(
          BL,
          title = list(text = "Validation AUC per Run",
                       font = list(color = "#e0f2fe", size = 13)),
          xaxis = list(title = "Run ID", tickangle = -35),
          yaxis = list(title = "AUC",
                       range = list(max(0.5, min(df$val_auc, na.rm=TRUE) - 0.04), 1.03)),
          showlegend = TRUE
        )
    })

    # ── F1 / Precision / Recall ────────────────────────────────────────────────
    output$chart_f1 <- plotly::renderPlotly({
      df <- view()
      if (!nrow(df)) return(no_data())

      p <- plotly::plot_ly()
      if (!all(is.na(df$val_f1)))
        p <- p %>% plotly::add_trace(
          data=df, x=~run_id, y=~val_f1,
          type="scatter", mode="lines+markers", name="F1",
          line=list(color=BLUE, width=2.5),
          marker=list(color=BLUE, size=8),
          hovertemplate="<b>%{x}</b><br>F1: %{y:.4f}<extra></extra>"
        )
      if (!all(is.na(df$val_prec)))
        p <- p %>% plotly::add_trace(
          data=df, x=~run_id, y=~val_prec,
          type="scatter", mode="lines+markers", name="Precision",
          line=list(color=GREEN, width=2, dash="dash"),
          marker=list(color=GREEN, size=7, symbol="diamond"),
          hovertemplate="<b>%{x}</b><br>Precision: %{y:.4f}<extra></extra>"
        )
      if (!all(is.na(df$val_rec)))
        p <- p %>% plotly::add_trace(
          data=df, x=~run_id, y=~val_rec,
          type="scatter", mode="lines+markers", name="Recall",
          line=list(color=AMBER, width=2, dash="dot"),
          marker=list(color=AMBER, size=7, symbol="square"),
          hovertemplate="<b>%{x}</b><br>Recall: %{y:.4f}<extra></extra>"
        )
      p %>% plotly::layout(
        BL,
        title = list(text = "F1 / Precision / Recall Across Runs",
                     font = list(color = "#e0f2fe", size = 13)),
        xaxis = list(title = "Run ID", tickangle = -35),
        yaxis = list(title = "Score (higher better)")
      )
    })

    # ── Log-Loss ──────────────────────────────────────────────────────────────
    output$chart_logloss <- plotly::renderPlotly({
      df <- view()
      if (!nrow(df) || all(is.na(df$val_logloss))) return(no_data())

      plotly::plot_ly(df,
        x    = ~run_id, y = ~val_logloss,
        type = "scatter", mode = "lines+markers",
        fill = "tozeroy", fillcolor = "rgba(14,165,233,0.05)",
        line   = list(color = BLUE, width = 2.5),
        marker = list(color = "#7dd3fc", size = 8,
                      line = list(color = BLUE, width = 2)),
        hovertemplate = "<b>%{x}</b><br>Log-Loss: %{y:.4f}<extra></extra>"
      ) %>%
        plotly::layout(
          BL,
          title = list(text = "Validation Log-Loss per Run (lower is better)",
                       font = list(color = "#e0f2fe", size = 13)),
          xaxis = list(title = "Run ID", tickangle = -35),
          yaxis = list(title = "Log-Loss \u2193 better",
                       autorange = "reversed")
        )
    })

    # ── Model class box ───────────────────────────────────────────────────────
    output$chart_class <- plotly::renderPlotly({
      df <- view()
      valid <- df[!is.na(df$val_auc), ]
      if (!nrow(valid)) return(no_data())

      plotly::plot_ly(valid,
        x    = ~model_class, y = ~val_auc,
        type = "box", boxpoints = "all",
        jitter = 0.4, pointpos = 0,
        fillcolor = "rgba(14,165,233,0.07)",
        line      = list(color = BLUE),
        marker    = list(color = BLUE, size = 8, opacity = 0.85,
                         line = list(color = "#0a1628", width = 1)),
        hovertemplate = "<b>%{x}</b><br>AUC: %{y:.4f}<extra></extra>"
      ) %>%
        plotly::layout(
          BL,
          title = list(text = "AUC Distribution by Model Class (Huyen's selection guide)",
                       font = list(color = "#e0f2fe", size = 13)),
          xaxis = list(title = "Model Class", tickangle = -20),
          yaxis = list(title = "Validation AUC"),
          showlegend = FALSE
        )
    })

    # ── Cost vs Quality ───────────────────────────────────────────────────────
    output$chart_cost <- plotly::renderPlotly({
      df <- view()
      valid <- df[!is.na(df$train_hrs) & !is.na(df$val_auc), ]
      if (!nrow(valid)) return(no_data("No runs with train hours and AUC logged."))
      best <- max(valid$val_auc)
      valid$isbest <- valid$val_auc == best

      plotly::plot_ly(valid,
        x    = ~train_hrs, y = ~val_auc,
        type = "scatter", mode = "markers+text",
        text = ~run_id, textposition = "top center",
        customdata = ~paste0(run_name, "<br>", model_class),
        hovertemplate = paste0(
          "<b>%{text}</b><br>%{customdata}<br>",
          "Train Hrs: %{x:.1f}<br>AUC: %{y:.4f}<extra></extra>"
        ),
        marker = list(
          size    = 14,
          color   = ~ifelse(isbest, BLUE, BLUE_DIM),
          opacity = 0.85,
          line    = list(color = "#7dd3fc", width = 1.5)
        )
      ) %>%
        plotly::layout(
          BL,
          title = list(text = "Training Cost vs Quality — Pareto Efficiency (Huyen Ch.6)",
                       font = list(color = "#e0f2fe", size = 13)),
          xaxis = list(title = "Training Hours"),
          yaxis = list(title = "Validation AUC")
        )
    })

    # ── Baseline gap bar ─────────────────────────────────────────────────────
    output$chart_baseline <- plotly::renderPlotly({
      df <- view()
      valid <- df[!is.na(df$val_auc), ]
      if (!nrow(valid)) return(no_data())

      # Use minimum AUC as baseline
      baseline <- min(valid$val_auc)
      valid$lift <- valid$val_auc - baseline
      valid$is_base <- valid$val_auc == baseline

      plotly::plot_ly(valid,
        x    = ~run_id, y = ~lift,
        type = "bar",
        text = ~sprintf("+%.4f", lift),
        textposition = "outside",
        customdata = ~paste0(run_name, "<br>AUC: ", sprintf("%.4f", val_auc)),
        hovertemplate = "<b>%{x}</b><br>%{customdata}<br>Lift over baseline: +%{y:.4f}<extra></extra>",
        marker = list(
          color = ~ifelse(is_base, "rgba(100,116,139,0.3)", BLUE),
          line  = list(color = "rgba(14,165,233,0.4)", width = 1)
        )
      ) %>%
        plotly::layout(
          BL,
          title = list(text = "AUC Lift Over Weakest Baseline (Huyen: always measure baseline gap)",
                       font = list(color = "#e0f2fe", size = 13)),
          xaxis = list(title = "Run ID", tickangle = -35),
          yaxis = list(title = "AUC Lift over Baseline")
        )
    })

    # ── Run diff ─────────────────────────────────────────────────────────────
    output$ui_run_a <- renderUI({
      ids <- runs()$run_id
      if (!length(ids)) return(tags$small(style="color:#3a4b5c;", "No runs yet."))
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
        list(l="Model Class",   a=ra$model_class,   b=rb$model_class,   num=FALSE),
        list(l="Algorithm",     a=ra$algorithm,     b=rb$algorithm,     num=FALSE),
        list(l="Loss Function", a=ra$loss_fn,       b=rb$loss_fn,       num=FALSE),
        list(l="Training Data", a=ra$training_data, b=rb$training_data, num=FALSE),
        list(l="Git SHA",       a=ra$git_sha,       b=rb$git_sha,       num=FALSE),
        list(l="Val AUC",       a=ra$val_auc,       b=rb$val_auc,       num=TRUE),
        list(l="Val F1",        a=ra$val_f1,        b=rb$val_f1,        num=TRUE),
        list(l="Val Precision", a=ra$val_prec,      b=rb$val_prec,      num=TRUE),
        list(l="Val Recall",    a=ra$val_rec,       b=rb$val_rec,       num=TRUE),
        list(l="Val Log-Loss",  a=ra$val_logloss,   b=rb$val_logloss,   num=TRUE),
        list(l="Train Hrs",     a=ra$train_hrs,     b=rb$train_hrs,     num=TRUE),
        list(l="Params (M)",    a=ra$params_M,      b=rb$params_M,      num=TRUE)
      )

      rows <- lapply(fields, function(f) {
        fmt <- function(v) {
          if (!length(v) || (length(v)==1 && is.na(v))) return("—")
          if (f$num) sprintf("%.4g", as.numeric(v)) else as.character(v)
        }
        av <- fmt(f$a); bv <- fmt(f$b)
        changed <- !identical(av, bv)

        delta_td <- if (f$num && av != "—" && bv != "—") {
          d <- as.numeric(f$b) - as.numeric(f$a)
          better <- if (grepl("Loss|Hrs|Params", f$l)) d < 0 else d > 0
          cls    <- if (better) "diff-improved" else "diff-regressed"
          tags$td(class = cls, sprintf("%+.4g", d))
        } else tags$td(class = "diff-neutral", "—")

        tags$tr(
          style = if (changed) "background:rgba(14,165,233,0.04);" else "",
          tags$td(style="font-weight:600;color:#7dd3fc;font-size:11.5px;width:120px;", f$l),
          tags$td(style="font-family:'JetBrains Mono',monospace;color:#8a9bb0;font-size:11px;", av),
          tags$td(style="font-family:'JetBrains Mono',monospace;color:#0ea5e9;font-size:11px;", bv),
          delta_td,
          tags$td(
            if (changed) tags$span(class="stage-pill", "CHANGED")
            else tags$span(style="color:#3a4b5c;font-size:10px;","same")
          )
        )
      })

      output$diff_out <- renderUI({
        tagList(
          div(style="margin-bottom:10px;",
              span(class="badge-blue", input$run_a), " vs ",
              span(class="stage-pill", input$run_b)),
          tags$table(class="table table-hover",
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
                tags$b(paste0(input$run_a, ": ")), ra$notes),
          if (nzchar(rb$notes %||% ""))
            div(class="tip-box",
                tags$b(paste0(input$run_b, ": ")), rb$notes)
        )
      })
    })

    # ── Champion card ─────────────────────────────────────────────────────────
    output$champion_card <- renderUI({
      df    <- runs()
      champ <- df[grepl("Champion", df$status), ]
      if (!nrow(champ)) {
        if (!nrow(df) || all(is.na(df$val_auc))) {
          return(div(class="warn-box",
            HTML("No champion yet. Mark a run as <strong>🏆 Champion</strong> when it passes all evaluation gates.")))
        }
        # Use best AUC as champion
        champ <- df[which.max(df$val_auc), ]
      }
      r <- champ[1, ]
      div(
        style = "background:rgba(14,165,233,0.07);border:1px solid rgba(14,165,233,0.3);border-radius:10px;padding:16px;",
        fluidRow(
          column(3, tags$p(style="font-size:11px;color:#64748b;margin:0;","Run"), tags$p(style="font-weight:800;color:#7dd3fc;", r$run_id)),
          column(3, tags$p(style="font-size:11px;color:#64748b;margin:0;","Name"), tags$p(style="font-weight:700;color:#e0f2fe;font-size:13px;", r$run_name)),
          column(3, tags$p(style="font-size:11px;color:#64748b;margin:0;","Model"), tags$p(style="color:#94a3b8;font-size:12px;", r$model_class)),
          column(3, tags$p(style="font-size:11px;color:#64748b;margin:0;","Val AUC"),
                    tags$p(style="font-weight:800;color:#38bdf8;font-size:1.4em;font-family:'JetBrains Mono',monospace;",
                           if (!is.na(r$val_auc)) sprintf("%.4f", r$val_auc) else "—"))
        ),
        tags$hr(style="border-color:rgba(14,165,233,0.15);margin:10px 0;"),
        fluidRow(
          column(4, tags$p(style="font-size:11px;color:#64748b;margin:0;","F1"), tags$p(style="color:#10b981;font-weight:700;", if(!is.na(r$val_f1)) sprintf("%.4f",r$val_f1) else "—")),
          column(4, tags$p(style="font-size:11px;color:#64748b;margin:0;","Log-Loss"), tags$p(style="color:#f59e0b;font-weight:700;", if(!is.na(r$val_logloss)) sprintf("%.4f",r$val_logloss) else "—")),
          column(4, tags$p(style="font-size:11px;color:#64748b;margin:0;","Training Data"), tags$p(style="color:#94a3b8;font-size:11px;", r$training_data %||% "—"))
        ),
        if (nzchar(r$notes %||% ""))
          tags$p(style="font-size:12px;color:#64748b;margin-top:8px;font-style:italic;",
                 paste0('"', r$notes, '"'))
      )
    })

    # ── Self-assessment ───────────────────────────────────────────────────────
    observeEvent(input$calc_score, {
      avg <- mean(c(input$sc_what_log, input$sc_baseline, input$sc_iterloop,
                    input$sc_hpo, input$sc_debug, input$sc_selection))
      pct <- round(avg * 10)
      prep_manager$update_progress("experiment_tracking", pct)
      output$score_result <- renderUI({
        div(class = if (pct >= 70) "success-box" else "tip-box",
          tags$h3(style = paste0("color:", progress_colour(pct)), paste0(pct, "% ready")),
          if (input$sc_baseline < 6)
            tags$p("\u26a0\ufe0f Baseline strategy is foundational in Huyen — know all four tiers cold."),
          if (input$sc_debug < 6)
            tags$p("\u26a0\ufe0f Debugging tests (overfit tiny batch, permutation test) are Huyen's most distinctive contribution to Ch.6."),
          if (input$sc_iterloop < 6)
            tags$p("\u26a0\ufe0f Review Huyen's iterative loop — interviewers expect you to name HARKing as an anti-pattern."),
          if (pct >= 80)
            tags$p("\u2705 Strong experiment tracking foundation. You can articulate Huyen's full methodology.")
        )
      })
      showNotification(paste0("Experiment Tracking: ", pct, "% saved"), type = "message")
    })

  })
}
