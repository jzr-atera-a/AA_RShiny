# modules/ch4_model_training.R
# Ch.4: Technical Interview — Model Training and Evaluation

ch4_model_training_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Chapter 4 — Model Training & Evaluation"),
      tags$h2("Technical Interview: Model Training and Evaluation — Susan Shu Chang"),
      div(
        span(class = "hero-badge", "Problem Framing"),
        span(class = "hero-badge", "Data Acquisition & EDA"),
        span(class = "hero-badge", "Feature Engineering"),
        span(class = "hero-badge", "Model Selection & Training"),
        span(class = "hero-badge", "Evaluation Metrics"),
        span(class = "hero-badge", "Model Versioning")
      )
    ),

    fluidRow(
      box(title = "🎯 Defining a Machine Learning Problem (Ch.4)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
            HTML("<strong>Chang's rule:</strong> Mis-specifying the objective function is the single
                 most common source of production ML failure. Spend time here before touching data or models.")),
          br(),
          div(class = "section-heading-dark", "5-Question Framing Framework"),
          timeline_entry("1", "What is the business objective?",
            "Define success in business terms first — conversion rate, revenue, retention. ML comes second."),
          timeline_entry("2", "Is ML the right tool?",
            "A rule-based system that handles the problem well is cheaper and more explainable. Justify ML."),
          timeline_entry("3", "What exactly are we predicting?",
            "Define Y precisely — binary class, multi-class, continuous score, ranked list, or sequence."),
          timeline_entry("4", "What data and labels exist?",
            "Audit available signals, label availability, freshness requirements, and collection cost."),
          timeline_entry("5", "How do we measure success?",
            "Offline metric (AUC, RMSE) AND online metric (CTR, GMV). They must align."),
          div(class = "warn-box",
            HTML("<strong>⚠️ Interview trap:</strong> Jumping to model selection before defining the objective.
                 Senior interviewers will stop you and ask: 'but what are you actually optimising?'"))
      ),

      box(title = "📉 Loss Function Selection (Ch.4)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Loss Function Decision Table"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Task"), tags$th("Loss Function"), tags$th("Why choose it"))),
              tags$tbody(
                tags$tr(tags$td("Binary classification"), tags$td(tags$code("Binary cross-entropy")),     tags$td("Penalises confident wrong predictions exponentially")),
                tags$tr(tags$td("Multi-class"),           tags$td(tags$code("Categorical cross-entropy")), tags$td("Generalises BCE to K classes via softmax")),
                tags$tr(tags$td("Regression — outliers"), tags$td(tags$code("MSE")),                       tags$td("Penalises large errors more")),
                tags$tr(tags$td("Regression — robust"),   tags$td(tags$code("MAE / Huber")),               tags$td("MAE ignores outliers; Huber blends both")),
                tags$tr(tags$td("Ranking"),               tags$td(tags$code("BPR / ListNet")),             tags$td("Optimise relative order, not absolute scores")),
                tags$tr(tags$td("Generation"),            tags$td(tags$code("Token cross-entropy")),       tags$td("Next-token prediction probability"))
              )
            )),
          div(class = "tip-box",
            HTML("<strong>💡 Interview move:</strong> Always explain WHY when naming a loss function —
                 this distinguishes you from candidates who just recall names."))
      )
    ),

    fluidRow(
      box(title = "🗄️ Data Acquisition, EDA & Feature Engineering (Ch.4)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "framework-card",
                tags$h5("Introduction to Data Acquisition"),
                tags$ul(
                  tags$li(tags$b("First-party data:"), " most valuable — direct user interactions, proprietary signals"),
                  tags$li(tags$b("Third-party data:"), " purchased or licensed — check GDPR/CCPA compliance"),
                  tags$li(tags$b("Synthetic data:"), " generated or augmented — useful for rare classes or privacy constraints"),
                  tags$li(tags$b("Public datasets:"), " ImageNet, Common Crawl, HuggingFace Hub"),
                  tags$li(tags$b("Data freshness:"), " define staleness tolerance — real-time vs daily batch"),
                  tags$li(tags$b("Label cost:"), " human annotation is expensive; consider weak supervision or active learning")
                ),
                div(class = "tip-box",
                  HTML("<strong>💡 Interview signal:</strong> Asking about data provenance and
                       freshness requirements before modelling shows production awareness."))
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Introduction to Exploratory Data Analysis"),
                tags$ul(
                  tags$li(tags$b("Class balance:"), " check target distribution — define imbalance threshold"),
                  tags$li(tags$b("Feature distributions:"), " histograms, box plots — skew, outliers, bimodality"),
                  tags$li(tags$b("Missing data patterns:"), " heatmaps — MCAR vs MAR vs MNAR"),
                  tags$li(tags$b("Correlations:"), " feature-feature and feature-target — collinearity risks"),
                  tags$li(tags$b("Temporal patterns:"), " seasonality, trend, drift over time"),
                  tags$li(tags$b("Label quality:"), " noise rate, annotation disagreements, systematic errors")
                )
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Introduction to Feature Engineering"),
                tags$ul(
                  tags$li(tags$b("Numeric scaling:"), " z-score for NNs/SVMs; none for tree models"),
                  tags$li(tags$b("Categorical encoding:"), " one-hot (low cardinality), embedding (high cardinality)"),
                  tags$li(tags$b("Interaction features:"), " multiplicative terms for non-linear relationships"),
                  tags$li(tags$b("Cyclical encoding:"), " sin/cos for hour-of-day, day-of-week"),
                  tags$li(tags$b("Text features:"), " TF-IDF, sentence-transformers, BM25"),
                  tags$li(tags$b("Image features:"), " normalisation, augmentation, CNN backbone embeddings")
                ),
                div(class = "warn-box",
                  HTML("<strong>⚠️ Train-serve skew:</strong> Features computed differently
                       at train vs serve time cause silent production failures.
                       Use a feature store to enforce consistency."))
              )
            )
          ),

          div(class = "section-heading-dark", style = "margin-top:10px;",
              "Sample Interview Questions on Data Preprocessing and Feature Engineering"),
          fluidRow(
            column(6, tags$ul(
              tags$li("How would you handle 30% missing values in a key feature?"),
              tags$li("When would you use one-hot vs target encoding vs embeddings?"),
              tags$li("What is train-serve skew and how do you prevent it?")
            )),
            column(6, tags$ul(
              tags$li("Describe your EDA process for a new classification problem."),
              tags$li("What is a feature store and when would you use one?"),
              tags$li("How would you engineer features from raw user click logs?")
            ))
          )
      )
    ),

    fluidRow(
      box(title = "⚙️ The Model Training Process (Ch.4)", status = "primary",
          solidHeader = TRUE, width = 7,

          div(class = "framework-card",
            tags$h5("The Iteration Process in Model Training"),
            timeline_entry("1", "Define the ML task",
              "Classify the problem: binary/multi-class, regression, ranking, generation, anomaly detection."),
            timeline_entry("2", "Establish a baseline",
              "Random, heuristic, or logistic regression. Sets a floor before any complexity is added."),
            timeline_entry("3", "Feature engineering",
              "Domain-informed signal creation. More data > better features > better model — in that priority."),
            timeline_entry("4", "Model selection",
              "Choose model family based on data size, latency budget, interpretability, and training cost."),
            timeline_entry("5", "Train and validate",
              "Mini-batch SGD / Adam. Monitor train vs validation loss curves for over/underfitting."),
            timeline_entry("6", "Error analysis",
              "Slice performance by subgroup. Find systematic failures. Diagnose: data issue or model issue?"),
            timeline_entry("7", "Iterate",
              "Return to step 3 or step 4 with findings. Repeat until diminishing returns.")
          ),

          div(class = "framework-card",
            tags$h5("Defining the ML Task — Decision Matrix"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Output"), tags$th("Task"), tags$th("Example"), tags$th("Loss"))),
              tags$tbody(
                tags$tr(tags$td("Binary label"),  tags$td("Binary classification"), tags$td("Fraud, spam"),              tags$td("Binary cross-entropy")),
                tags$tr(tags$td("K-class label"), tags$td("Multi-class"),           tags$td("Intent, sentiment, topic"), tags$td("Categorical cross-entropy")),
                tags$tr(tags$td("Continuous"),    tags$td("Regression"),            tags$td("Price, demand, risk"),      tags$td("MSE / Huber")),
                tags$tr(tags$td("Ordered list"),  tags$td("Ranking"),               tags$td("Search, feed, RecSys"),     tags$td("LambdaRank / BPR")),
                tags$tr(tags$td("Sequence"),      tags$td("Generation"),            tags$td("Chat, code, summary"),      tags$td("Token cross-entropy")),
                tags$tr(tags$td("Score"),         tags$td("Anomaly detection"),     tags$td("Fraud, system health"),     tags$td("Reconstruction loss"))
              )
            ))
      ),

      box(title = "🔬 Model Selection & Overview of Model Training (Ch.4)", status = "info",
          solidHeader = TRUE, width = 5,

          div(class = "framework-card",
            tags$h5("Overview of Model Selection"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Situation"), tags$th("Start with"))),
              tags$tbody(
                tags$tr(tags$td("Tabular, interpretability"),  tags$td("Logistic regression, decision tree")),
                tags$tr(tags$td("Tabular, performance"),       tags$td("XGBoost / LightGBM")),
                tags$tr(tags$td("Text classification"),        tags$td("Fine-tuned BERT / DistilBERT")),
                tags$tr(tags$td("Text generation"),            tags$td("Fine-tuned GPT / LLaMA")),
                tags$tr(tags$td("Image classification"),       tags$td("ResNet / EfficientNet (transfer)")),
                tags$tr(tags$td("Time series"),                tags$td("LightGBM with lags or Prophet")),
                tags$tr(tags$td("Large scale, low latency"),   tags$td("Two-tower, linear model"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Overview of Model Training — Optimisers"),
            tags$ul(
              tags$li(tags$b("Mini-batch SGD:"), " batch 32–512 — industry standard"),
              tags$li(tags$b("Adam:"), " adaptive per-parameter LR — default for deep learning"),
              tags$li(tags$b("AdamW:"), " Adam + decoupled weight decay — preferred for transformers"),
              tags$li(tags$b("LR warmup + cosine decay:"), " standard large model schedule"),
              tags$li(tags$b("Early stopping:"), " halt when val loss plateaus — free regularisation")
            )),

          div(class = "section-heading-dark", "Sample Interview Questions on Model Selection & Training"),
          tags$ul(
            tags$li("Why choose XGBoost over a neural network for tabular data?"),
            tags$li("Difference between Adam and SGD with momentum?"),
            tags$li("How do you decide when to stop training?"),
            tags$li("How do you handle a model that converges to a poor local minimum?")
          )
      )
    ),

    fluidRow(
      box(title = "⚠️ Data Pitfalls — Leakage & Imbalance (Ch.4)", status = "danger",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Data Leakage — Three Forms"),
            tags$ul(
              tags$li(tags$b("Target leakage:"), " a feature is causally downstream of the target"),
              tags$li(tags$b("Train-test contamination:"), " scaler or imputer fit on full dataset before split"),
              tags$li(tags$b("Temporal leakage:"), " using future data to predict past events")
            ),
            div(class = "warn-box",
              HTML("<strong>⚠️ The rule:</strong> Fit all preprocessing transformers on training data ONLY.
                   Apply (transform only) to validation and test sets."))),

          div(class = "framework-card",
            tags$h5("Class Imbalance Toolkit"),
            tags$ul(
              tags$li(tags$b("Oversampling (SMOTE):"), " generate synthetic minority class samples"),
              tags$li(tags$b("Undersampling:"), " reduce majority class — fast but loses data"),
              tags$li(tags$b("Class weights:"), " penalise majority class errors more in the loss"),
              tags$li(tags$b("Threshold tuning:"), " move decision boundary post-training to favour recall")
            ),
            div(class = "tip-box",
              HTML("<strong>💡 Chang's advice:</strong> Never use accuracy as primary metric
                   on imbalanced data. Use F1, PR-AUC, or class-specific metrics.")))
      ),

      box(title = "📈 Model Evaluation — Common Metrics & Trade-offs (Ch.4)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Summary of Common ML Evaluation Metrics"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Metric"), tags$th("Use when"), tags$th("Limitation"))),
              tags$tbody(
                tags$tr(tags$td(tags$b("Accuracy")),  tags$td("Balanced classes"),         tags$td("Misleading under imbalance")),
                tags$tr(tags$td(tags$b("Precision")), tags$td("FP cost is high"),           tags$td("Ignores false negatives")),
                tags$tr(tags$td(tags$b("Recall")),    tags$td("FN cost is high"),           tags$td("Ignores false positives")),
                tags$tr(tags$td(tags$b("F1")),        tags$td("Both FP and FN matter"),     tags$td("Treats FP/FN symmetrically")),
                tags$tr(tags$td(tags$b("AUC-ROC")),   tags$td("Ranking ability, threshold-free"), tags$td("Can mislead at extremes")),
                tags$tr(tags$td(tags$b("PR-AUC")),    tags$td("Highly imbalanced data"),   tags$td("Does not factor in TNs")),
                tags$tr(tags$td(tags$b("RMSE")),      tags$td("Regression, outliers matter"), tags$td("Sensitive to outliers")),
                tags$tr(tags$td(tags$b("NDCG")),      tags$td("Ranked list quality"),      tags$td("Requires graded relevance"))
              )
            )),
          div(class = "framework-card",
            tags$h5("Trade-offs in Evaluation Metrics"),
            tags$ul(
              tags$li(tags$b("Precision vs Recall:"), " threshold movement trades one for the other"),
              tags$li(tags$b("Offline vs Online:"), " high AUC can still fail on CTR if population shifts"),
              tags$li(tags$b("Global vs sliced:"), " global AUC may hide poor performance on a critical subgroup"),
              tags$li(tags$b("Single vs guardrail:"), " optimise one metric; monitor secondary guardrail metrics")
            ))
      )
    ),

    fluidRow(
      box(title = "🧪 Additional Offline Evaluation Methods & Model Versioning (Ch.4)", status = "info",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(6,
              div(class = "framework-card",
                tags$h5("Additional Methods for Offline Evaluation"),
                tags$ul(
                  tags$li(tags$b("Sliced evaluation:"), " measure performance by subgroup (age, geography, language) — finds hidden failures"),
                  tags$li(tags$b("Perturbation tests:"), " add typos, noise, lighting changes — tests model robustness"),
                  tags$li(tags$b("Invariance tests:"), " output must not change on irrelevant attribute change (e.g. user name)"),
                  tags$li(tags$b("Directional tests:"), " adding a positive word should increase positive sentiment score"),
                  tags$li(tags$b("Calibration check:"), " predicted probabilities should match observed frequencies"),
                  tags$li(tags$b("Walk-forward CV:"), " for time series — always test on future data, train on past")
                ),
                div(class = "section-heading-dark", "Sample Questions on Model Evaluation"),
                tags$ul(
                  tags$li("How would you evaluate a fraud model on imbalanced data?"),
                  tags$li("What is calibration and when does it matter?"),
                  tags$li("How do you detect performance differences across subgroups?"),
                  tags$li("Why can't k-fold CV be used on time series data?")
                )
              )
            ),
            column(6,
              div(class = "framework-card",
                tags$h5("Model Versioning"),
                tags$p("Every production model needs reproducibility — you must be able to recreate any previous model exactly."),
                tags$ul(
                  tags$li(tags$b("Model weights:"), " serialised file — ONNX, SavedModel, safetensors"),
                  tags$li(tags$b("Training code:"), " git SHA of training script"),
                  tags$li(tags$b("Dataset version:"), " DVC or data catalogue reference"),
                  tags$li(tags$b("Hyperparameters:"), " full config — LR, batch size, architecture"),
                  tags$li(tags$b("Environment:"), " Docker image or requirements.txt"),
                  tags$li(tags$b("Eval results:"), " metrics per split — comparable across runs")
                ),
                tags$table(class = "table table-hover",
                  tags$thead(tags$tr(tags$th("Tool"), tags$th("Versions"), tags$th("Key feature"))),
                  tags$tbody(
                    tags$tr(tags$td("MLflow"),          tags$td("Runs, params, metrics, artifacts"), tags$td("UI for comparison")),
                    tags$tr(tags$td("Weights & Biases"), tags$td("Training curves, checkpoints"),    tags$td("Real-time collab")),
                    tags$tr(tags$td("DVC"),             tags$td("Datasets + models in git"),        tags$td("Data versioning")),
                    tags$tr(tags$td("Model Registry"),  tags$td("Production model lifecycle"),      tags$td("Staging → prod promotion"))
                  )
                ),
                div(class = "success-box",
                  HTML("<strong>✅ Interview signal:</strong> Mention MLflow or a model registry
                       unprompted. 'I would log each experiment tracking hyperparameters and metrics,
                       and promote to a model registry on improvement of the primary metric.'"))
              )
            )
          )
      )
    ),

    fluidRow(
      box(title = "✍️ Practice: Write Your Evaluation Plan", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              selectInput(ns("eval_topic"), "Choose a scenario to evaluate:",
                choices = c(
                  "Binary fraud detection model",
                  "Product demand regression",
                  "Search ranking model",
                  "Time series sales forecast",
                  "Multi-class content moderation",
                  "User churn prediction (imbalanced)",
                  "Ad CTR prediction",
                  "Image classification (few-shot)"
                )),
              sliderInput(ns("eval_conf"), "Confidence in evaluation design (1–10):", 1, 10, 5),
              actionButton(ns("save_eval"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8,
              div(class = "practice-area",
                tags$b("Practice: Design the full evaluation plan for the selected scenario."),
                textAreaInput(ns("eval_notes"), label = NULL, rows = 10, width = "100%",
                  placeholder = "## 1. ML task type and loss function\n\n## 2. Primary offline metric (and why)\n\n## 3. Validation strategy\n\n## 4. Baseline to beat\n\n## 5. Data issues (imbalance, leakage, missingness)\n\n## 6. Model versioning approach"),
                uiOutput(ns("eval_feedback"))
              )
            )
          )
      )
    )
  )
}

ch4_model_training_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_eval, {
      notes <- input$eval_notes
      conf  <- input$eval_conf
      score <- 0
      if (grepl("metric|auc|f1|rmse|ndcg|precision|recall",            notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("baseline|heuristic|simple|logistic|rule",             notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("split|fold|cross.valid|walk.forward|train|test|val",  notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("imbalanc|weight|smote|oversamp|threshold",            notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("leakage|contamin|temporal|version|mlflow|dvc|docker", notes, ignore.case = TRUE)) score <- score + 20

      prep_manager$update_progress("ch4_model_training", min(score + conf * 3, 100))
      prep_manager$save_note("ch4_notes", notes)

      output$eval_feedback <- renderUI({
        div(class = if (score >= 80) "success-box" else "tip-box",
          tags$h5(paste0("Evaluation Plan Score: ", score, "/100")),
          if (score < 20)  tags$p("⚠️ Missing: primary offline metric with justification"),
          if (score < 40)  tags$p("⚠️ Missing: baseline to compare against"),
          if (score < 60)  tags$p("⚠️ Missing: validation strategy"),
          if (score < 80)  tags$p("⚠️ Missing: class imbalance or data quality considerations"),
          if (score < 100) tags$p("⚠️ Consider: data leakage prevention and model versioning"),
          if (score >= 80) tags$p("✅ Complete evaluation plan — strong technical interview answer!")
        )
      })
      showNotification("Ch.4 assessment saved!", type = "message")
    })
  })
}
