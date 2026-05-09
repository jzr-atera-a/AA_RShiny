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
        span(class = "hero-badge", "Data Preprocessing"),
        span(class = "hero-badge", "Loss Functions"),
        span(class = "hero-badge", "Evaluation Metrics"),
        span(class = "hero-badge", "Validation Strategy")
      )
    ),

    fluidRow(
      box(title = "🎯 Defining the ML Problem (Ch.4)", status = "primary",
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
            "Offline metric (AUC, RMSE) AND online metric (CTR, GMV). They must align — a key interview point."),

          div(class = "warn-box",
            HTML("<strong>⚠️ Interview trap:</strong> Jumping to model selection before defining the
                 objective. Interviewers at senior levels will stop you and ask
                 'but what are you actually optimising?'"))
      ),

      box(title = "📉 Loss Function Selection (Ch.4)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Loss Function Decision Table"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Task"), tags$th("Loss Function"), tags$th("Why choose it"))),
              tags$tbody(
                tags$tr(tags$td("Binary classification"),  tags$td(tags$code("Binary cross-entropy")),    tags$td("Penalises confident wrong predictions exponentially")),
                tags$tr(tags$td("Multi-class"),            tags$td(tags$code("Categorical cross-entropy")), tags$td("Generalises BCE to K classes via softmax")),
                tags$tr(tags$td("Regression — outliers"),  tags$td(tags$code("MSE")),                      tags$td("Penalises large errors more — use when outliers matter")),
                tags$tr(tags$td("Regression — robust"),    tags$td(tags$code("MAE / Huber")),              tags$td("MAE ignores outliers; Huber blends both regimes")),
                tags$tr(tags$td("Ranking"),                tags$td(tags$code("Pairwise BPR / ListNet")),   tags$td("Optimise relative order, not absolute scores")),
                tags$tr(tags$td("Generation"),             tags$td(tags$code("Cross-entropy (token)")),    tags$td("Next-token prediction probability at each position"))
              )
            )),

          div(class = "tip-box",
            HTML("<strong>💡 Interview move:</strong> When stating a loss function, say WHY.
                 'I would use binary cross-entropy because the output is a probability and
                 I want to penalise confident wrong predictions — MSE would underestimate
                 the severity of those errors.'"))
      )
    ),

    fluidRow(
      box(title = "🔧 Data Preprocessing & Feature Engineering (Ch.4)", status = "warning",
          solidHeader = TRUE, width = 7,

          div(class = "framework-card",
            tags$h5("Missing Data Strategies"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Strategy"), tags$th("When to use"), tags$th("Risk"))),
              tags$tbody(
                tags$tr(tags$td(tags$span(class = "stage-pill", "Mean/median")),   tags$td("Random missingness, numeric features"), tags$td("Reduces variance, distorts distribution")),
                tags$tr(tags$td(tags$span(class = "stage-pill", "Model-based")),   tags$td("Systematic missingness with predictable pattern"), tags$td("Complex, can propagate errors")),
                tags$tr(tags$td(tags$span(class = "stage-pill", "Indicator flag")), tags$td("Missingness is itself informative (e.g. income not filled)"), tags$td("Adds new feature — higher dimensionality")),
                tags$tr(tags$td(tags$span(class = "stage-pill", "Drop rows")),     tags$td("< 1% missing, MCAR confirmed"), tags$td("Biased if not truly random"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Feature Scaling — When to Apply Each"),
            tags$ul(
              tags$li(tags$b("Standardisation (z-score):"), " Gaussian features, neural networks, SVMs — required"),
              tags$li(tags$b("Min-max normalisation:"), " bounded known range — pixel values, probabilities"),
              tags$li(tags$b("Log transform:"), " right-skewed distributions — income, counts, transaction amounts"),
              tags$li(tags$b("No scaling needed:"), " tree-based models (GBDT, Random Forest) are invariant to monotonic transforms")
            )),

          div(class = "framework-card",
            tags$h5("Categorical Encoding"),
            tags$ul(
              tags$li(tags$b("One-hot:"), " low cardinality (< ~20 categories), nominal features"),
              tags$li(tags$b("Label encoding:"), " ordinal features only — implies ordering"),
              tags$li(tags$b("Target encoding:"), " replace category with mean target — leakage risk if not done inside CV fold"),
              tags$li(tags$b("Embedding lookup:"), " high cardinality (user IDs, product IDs) in deep models")
            ))
      ),

      box(title = "⚠️ Data Pitfalls (Ch.4)", status = "danger",
          solidHeader = TRUE, width = 5,

          div(class = "framework-card",
            tags$h5("Data Leakage — Three Forms"),
            tags$ul(
              tags$li(tags$b("Target leakage:"), " a feature is causally downstream of the target variable"),
              tags$li(tags$b("Train-test contamination:"), " scaler or imputer fit on full dataset before train/test split"),
              tags$li(tags$b("Temporal leakage:"), " using future data to predict past events in time series")
            ),
            div(class = "warn-box",
              HTML("<strong>⚠️ The rule:</strong> Fit all preprocessing transformers on training data ONLY.
                   Apply (transform) to validation and test sets. Never the reverse."))),

          div(class = "framework-card",
            tags$h5("Class Imbalance Toolkit"),
            tags$ul(
              tags$li(tags$b("Oversampling (SMOTE):"), " generate synthetic minority class samples"),
              tags$li(tags$b("Undersampling:"), " reduce majority class — fast but loses data"),
              tags$li(tags$b("Class weights:"), " penalise majority class errors more in the loss"),
              tags$li(tags$b("Threshold tuning:"), " move decision boundary post-training to favour recall")
            ),
            div(class = "tip-box",
              HTML("<strong>💡 Chang's advice:</strong> Never report accuracy on imbalanced data.
                   Use F1, precision-recall AUC, or class-specific metrics.")))
      )
    ),

    fluidRow(
      box(title = "📈 Evaluation Metrics Deep Dive (Ch.4)", status = "primary",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "framework-card",
                tags$h5("Classification Metrics"),
                tags$ul(
                  tags$li(tags$b("Accuracy:"), " correct / total — misleading under class imbalance"),
                  tags$li(tags$b("Precision:"), " TP / (TP + FP) — of predicted positives, how many were correct?"),
                  tags$li(tags$b("Recall:"), " TP / (TP + FN) — of all actual positives, how many did we catch?"),
                  tags$li(tags$b("F1:"), " harmonic mean of precision and recall — use when both matter"),
                  tags$li(tags$b("AUC-ROC:"), " rank positives above negatives — threshold-independent")
                ),
                div(class = "tip-box",
                  HTML("<strong>💡 Key distinction:</strong> Optimise <b>precision</b> when FPs are costly
                       (spam filter). Optimise <b>recall</b> when FNs are costly (cancer screening)."))
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Regression & Ranking Metrics"),
                tags$ul(
                  tags$li(tags$b("RMSE:"), " root mean squared error — penalises large errors, same units as target"),
                  tags$li(tags$b("MAE:"), " mean absolute error — robust to outliers, interpretable"),
                  tags$li(tags$b("MAPE:"), " percentage error — intuitive but breaks when actual = 0"),
                  tags$li(tags$b("NDCG:"), " normalised discounted cumulative gain — quality of ranked list"),
                  tags$li(tags$b("MAP:"), " mean average precision — information retrieval relevance")
                ),
                div(class = "success-box",
                  HTML("<strong>✅ Know the formulas:</strong> RMSE and NDCG are the two most
                       commonly requested metric explanations at senior-level interviews."))
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Validation Strategies"),
                tags$ul(
                  tags$li(tags$b("Hold-out split:"), " fast — high variance on small datasets"),
                  tags$li(tags$b("k-fold CV:"), " k models trained, averaged — gold standard for tabular data"),
                  tags$li(tags$b("Stratified k-fold:"), " preserves class proportions — required for imbalanced data"),
                  tags$li(tags$b("Walk-forward:"), " for time series — ALWAYS test on future, train on past"),
                  tags$li(tags$b("Leave-one-out:"), " for tiny N — computationally prohibitive otherwise")
                ),
                div(class = "warn-box",
                  HTML("<strong>⚠️ Never:</strong> Shuffle time-series data before splitting.
                       Leaks future information into training — a cardinal sin."))
              )
            )
          )
      )
    ),

    fluidRow(
      box(title = "⚙️ Training Process & Optimisation (Ch.4)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Gradient Descent Variants"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Variant"), tags$th("Batch size"), tags$th("Stability"), tags$th("Speed"))),
              tags$tbody(
                tags$tr(tags$td("Batch GD"),      tags$td("All data"), tags$td("Stable"),    tags$td("Slow, memory heavy")),
                tags$tr(tags$td("Stochastic GD"), tags$td("1 sample"), tags$td("Noisy"),     tags$td("Fast, unstable")),
                tags$tr(tags$td("Mini-batch SGD"), tags$td("32–512"),  tags$td("Balanced"),  tags$td("Industry standard"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Optimisers"),
            tags$ul(
              tags$li(tags$b("SGD + momentum:"), " builds velocity in consistent gradient direction — good for convex problems"),
              tags$li(tags$b("Adam:"), " adaptive learning rates per parameter — default for deep learning"),
              tags$li(tags$b("AdamW:"), " Adam + decoupled weight decay — preferred for transformers"),
              tags$li(tags$b("LR scheduling:"), " warmup + cosine decay — standard for large model training")
            ))
      ),

      box(title = "🔬 Baselines & Hyperparameter Tuning (Ch.4)", status = "warning",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Baseline-First — Chang's Rule"),
            tags$ul(
              tags$li(tags$b("Random baseline:"), " predict majority class or random output — lower bound"),
              tags$li(tags$b("Heuristic baseline:"), " business rule or domain knowledge — often surprisingly strong"),
              tags$li(tags$b("Simple ML baseline:"), " logistic regression or decision tree — fast to train, interpretable"),
              tags$li(tags$b("Purpose:"), " proves the problem is learnable AND gives a benchmark to beat")
            ),
            div(class = "success-box",
              HTML("<strong>✅ Chang's principle:</strong> 'I would first train a logistic regression baseline,
                   measure the headroom, then decide whether deep learning is justified.'
                   Saying this proactively signals seniority."))),

          div(class = "framework-card",
            tags$h5("Hyperparameter Search"),
            tags$ul(
              tags$li(tags$b("Grid search:"), " exhaustive — only practical for < 3 hyperparameters"),
              tags$li(tags$b("Random search:"), " more efficient than grid for high-dimensional spaces"),
              tags$li(tags$b("Bayesian optimisation:"), " builds surrogate of loss surface — sample efficient"),
              tags$li(tags$b("Early stopping:"), " halt when validation loss plateaus — free regularisation")
            ))
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
                tags$b("Practice: Design the evaluation plan for the selected scenario."),
                textAreaInput(ns("eval_notes"), label = NULL, rows = 10, width = "100%",
                  placeholder = "## 1. Primary offline metric (and why)\n\n## 2. Secondary metrics / guardrails\n\n## 3. Validation strategy (train/val/test split or CV)\n\n## 4. Baseline to beat\n\n## 5. Class imbalance / data issues to address"),
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
      if (grepl("metric|auc|f1|rmse|ndcg|precision|recall|accuracy", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("baseline|heuristic|simple|logistic|rule",             notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("split|fold|cross.valid|walk.forward|train|test|val",  notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("imbalanc|weight|smote|oversamp|threshold",            notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("leakage|contamin|temporal|future|fit.on.train",       notes, ignore.case = TRUE)) score <- score + 20

      prep_manager$update_progress("ch4_model_training", min(score + conf * 3, 100))
      prep_manager$save_note("ch4_notes", notes)

      output$eval_feedback <- renderUI({
        div(class = if (score >= 80) "success-box" else "tip-box",
          tags$h5(paste0("Evaluation Plan Score: ", score, "/100")),
          if (score < 20) tags$p("⚠️ Missing: primary offline metric with justification"),
          if (score < 40) tags$p("⚠️ Missing: baseline to compare against"),
          if (score < 60) tags$p("⚠️ Missing: validation strategy (k-fold, walk-forward, etc.)"),
          if (score < 80) tags$p("⚠️ Missing: handling class imbalance or data issues"),
          if (score < 100) tags$p("⚠️ Consider: data leakage prevention (fit transformers on train only)"),
          if (score >= 80) tags$p("✅ Complete evaluation plan — strong answer for a technical interview!")
        )
      })
      showNotification("Ch.4 assessment saved!", type = "message")
    })
  })
}
