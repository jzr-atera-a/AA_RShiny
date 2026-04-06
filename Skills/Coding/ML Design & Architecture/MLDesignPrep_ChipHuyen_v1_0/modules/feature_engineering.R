# modules/feature_engineering.R
# Tab 4: Feature Engineering — Ch. 5 (Data Leakage, Feature Store)

feature_engineering_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Feature Engineering"),
        tags$h2("Chapter 5 — The Most Impactful Step in the ML Pipeline"),
        div(
          span(class = "hero-badge", "Data Leakage"),
          span(class = "hero-badge", "Feature Store"),
          span(class = "hero-badge", "Scaling & Encoding"),
          span(class = "hero-badge", "Train/Serve Skew")
        )
    ),

    fluidRow(
      box(title = "⚡ Core Feature Operations (Ch. 5)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
              tags$h5("Missing Value Handling"),
              tags$p(tags$b("MCAR (Missing Completely At Random):"), " Impute with mean/median."),
              tags$p(tags$b("MAR (Missing At Random):"), " Conditional imputation."),
              tags$p(tags$b("MNAR (Missing Not At Random):"), " The missing-ness IS informative — create indicator feature. Never blindly drop rows without understanding why values are missing.")),
          div(class = "framework-card",
              tags$h5("Feature Scaling"),
              tags$p(tags$b("Normalisation [0,1]:"), " Use when range matters, not distribution. Min-max scaling."),
              tags$p(tags$b("Standardisation (Z-score):"), " Use for Gaussian assumptions (linear models, NNs). Subtract mean, divide by std."),
              tags$p(tags$b("Log transform:"), " For power-law distributed features (follower count, purchase amount, revenue).")),
          div(class = "framework-card",
              tags$h5("Encoding Categorical Features"),
              tags$p(tags$b("One-hot:"), " Low cardinality (gender, device type, day of week). Creates sparse but interpretable representation."),
              tags$p(tags$b("Target encoding:"), " High cardinality (user_id, item_id) — encode with mean label value. Careful of target leakage — use out-of-fold encoding."),
              tags$p(tags$b("Embedding:"), " Learn dense representations for sparse IDs. Dominant pattern in deep recommenders. Foundation of DLRM, two-tower models.")),
          div(class = "framework-card",
              tags$h5("Feature Crossing"),
              tags$p("Create interaction features: user_age × item_category. Powerful for non-linear relationships that linear models miss. Learned crosses in DNNs via feature interactions layer."))
      ),

      box(title = "🚨 Data Leakage — The Career-Ending Bug (Ch. 5)", status = "danger",
          solidHeader = TRUE, width = 6,

          div(class = "warn-box",
              HTML("<strong>⚠️ Huyen's #1 warning:</strong> Data leakage is the most subtle and damaging problem in ML systems. Models appear excellent offline but fail catastrophically in production.")),

          div(class = "framework-card",
              tags$h5("Leakage from the Future (Temporal)"),
              tags$p("Using features that contain information not available at inference time. Example: using 'total purchases this month' to predict whether a user will purchase — this feature is computed AFTER the purchase."),
              tags$p(tags$b("Fix:"), " Always split data by time, not randomly. Use rolling-window evaluation.")),
          div(class = "framework-card",
              tags$h5("Leakage through Preprocessing"),
              tags$p("Normalising data using statistics computed on the full dataset (including test set). The scaler has 'seen' test data."),
              tags$p(tags$b("Fix:"), " Always fit scaler on train set only. Transform test set using train statistics.")),
          div(class = "framework-card",
              tags$h5("Label Leakage"),
              tags$p("Features that are proxies for the label. Example: predicting hospital readmission with discharge notes written after the outcome is known. High feature importance of a suspicious feature is a red flag.")),
          div(class = "tip-box",
              HTML("<strong>💡 Interview signal:</strong> 'I'd use a temporal train/validation split and verify no future-event features exist. I'd also check feature importance for suspiciously high-scoring features that shouldn't have predictive power logically.'"))
      )
    ),

    fluidRow(
      box(title = "🏪 Feature Store Architecture — Production Standard (Ch. 5)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   div(class = "framework-card",
                       tags$h5("Why Feature Stores?"),
                       tags$ul(
                         tags$li("Prevent duplication of feature computation across teams"),
                         tags$li("Guarantee train/serve consistency — same feature computed the same way"),
                         tags$li("Enable feature discovery and reuse across the org"),
                         tags$li("Centralise feature versioning and lineage")
                       )),
                   div(class = "framework-card",
                       tags$h5("Offline Store"),
                       tags$p("Historical features for training. Column-oriented format (Parquet, Delta Lake). High throughput, high latency. Used by training pipeline. Examples: Hive, BigQuery, S3."))
            ),
            column(4,
                   div(class = "framework-card",
                       tags$h5("Online Store"),
                       tags$p("Low-latency serving of pre-computed features. Key-value store: Redis, DynamoDB, Cassandra. Sub-millisecond reads. Populated by streaming pipeline from event bus. Critical for real-time personalisation.")),
                   div(class = "warn-box",
                       HTML("<strong>⚠️ Train/Serve Skew — #1 production failure.</strong> Train features differ from serve features due to different computation paths. Feature store solves this by centralising logic."))
            ),
            column(4,
                   div(class = "section-heading-dark", "Industry Examples"),
                   div(class = "framework-card",
                       tags$h5("Feature Store Ecosystem"),
                       tags$p(tags$b("Uber Michelangelo Palette"), " — pioneer, 2017"),
                       tags$p(tags$b("Airbnb Zipline"), " — open-source inspired"),
                       tags$p(tags$b("LinkedIn Feathr"), " — open-sourced 2022"),
                       tags$p(tags$b("Feast"), " — most popular open-source"),
                       tags$p(tags$b("AWS SageMaker / Vertex AI FS"), " — managed cloud options")),
                   div(class = "tip-box",
                       HTML("<strong>💡 Drop in interview:</strong> 'I'd use a feature store to guarantee train/serve consistency and enable feature reuse across teams — essential at this scale.'"))
            )
          )
      )
    ),

    fluidRow(
      box(title = "📊 Self-Assessment: Feature Engineering", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   sliderInput(ns("sc_encoding"),  "Encoding strategies",       0, 10, 5),
                   sliderInput(ns("sc_leakage"),   "Data leakage detection",    0, 10, 5),
                   sliderInput(ns("sc_store"),     "Feature store design",      0, 10, 5),
                   sliderInput(ns("sc_skew"),      "Train/serve skew awareness", 0, 10, 5),
                   actionButton(ns("calc_feat"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8, br(), uiOutput(ns("feat_result")))
          )
      )
    )
  )
}

feature_engineering_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_feat, {
      avg <- mean(c(input$sc_encoding, input$sc_leakage, input$sc_store, input$sc_skew))
      pct <- round(avg * 10)
      prep_manager$update_progress("feature_engineering", pct)

      output$feat_result <- renderUI({
        colour <- progress_colour(pct)
        div(class = if (pct >= 70) "success-box" else "tip-box",
            tags$h3(style = paste0("color:", colour), paste0(pct, "% ready")),
            if (input$sc_leakage < 6)
              tags$p("⚠️ Priority: data leakage is Huyen's #1 cited failure. Review Ch. 5 carefully."),
            if (pct >= 80) tags$p("✅ Feature engineering mastery — don't forget to mention feature stores proactively!")
        )
      })
      showNotification(paste0("Feature Engineering: ", pct, "% saved"), type = "message")
    })
  })
}
