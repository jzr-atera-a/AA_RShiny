# modules/data_engineering.R
# Tab 3: Data Engineering — Ch. 3 & 4

data_engineering_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Data Engineering"),
        tags$h2("Chapters 3 & 4 — Storage, Formats, Sampling, Labelling, Class Imbalance"),
        div(
          span(class = "hero-badge", "Parquet vs CSV"),
          span(class = "hero-badge", "Batch vs Streaming"),
          span(class = "hero-badge", "Natural Labels"),
          span(class = "hero-badge", "Class Imbalance")
        )
    ),

    fluidRow(
      box(title = "🗄️ Data Storage & Access Patterns (Ch. 3)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
              tags$h5("Data Formats — Know the Trade-offs"),
              tags$p(tags$b("Row-major (CSV, JSON):"), " Good for writing and accessing complete rows. Wasteful for column-specific reads. Default for logs and events."),
              tags$p(tags$b("Column-major (Parquet, ORC):"), " Efficient for ML feature reads — access only needed columns. 10–100× compression. Rule: use Parquet for ML training data at scale."),
              tags$p(tags$b("Interview move:"), " 'I'd store training features as Parquet in S3 partitioned by date, enabling efficient temporal splits and feature store batch materialisation.'")),
          div(class = "framework-card",
              tags$h5("Data Storage Paradigms"),
              tags$p(tags$b("Data Warehouse:"), " Structured, processed, SQL-queryable. Redshift, BigQuery, Snowflake. For analytics and historical feature generation."),
              tags$p(tags$b("Data Lake:"), " Raw, unstructured, cheap. S3, GCS. Source of truth for ML raw data."),
              tags$p(tags$b("Data Lakehouse:"), " Combined paradigm. Delta Lake, Apache Iceberg. ACID transactions on lake storage. Enables time-travel queries for reproducible training.")),
          div(class = "framework-card",
              tags$h5("Data Flow Modes"),
              tags$p(tags$b("Batch (Spark, MapReduce):"), " High throughput, high latency. For training data generation and batch feature computation."),
              tags$p(tags$b("Streaming (Kafka + Flink):"), " Low latency, used for real-time features and online serving. Stateful aggregations."),
              tags$p(tags$b("Micro-batch:"), " Structured Streaming — compromise between the two."))
      ),

      box(title = "🏷️ Training Data & Labelling (Ch. 4)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "section-heading-dark", "Sampling Strategies"),
          div(class = "framework-card",
              tags$h5("Probability Sampling (Prefer in Production)"),
              tags$p(tags$b("Simple Random:"), " All examples have equal probability. Baseline approach."),
              tags$p(tags$b("Stratified:"), " Sample from each subgroup proportionally. Critical for class imbalance and demographic coverage."),
              tags$p(tags$b("Reservoir:"), " For streaming data — maintain a representative sample without knowing total size.")),

          div(class = "section-heading-dark", "Labelling Approaches"),
          div(class = "framework-card",
              tags$h5("Natural Labels (Implicit Feedback)"),
              tags$p("Clicks, purchases, watch-through rate, dwell time. Cheap and abundant but noisy. Feedback delay matters — clicks happen at different lags. Survivorship bias: only shown items can be labelled.")),
          div(class = "framework-card",
              tags$h5("Hand Labels"),
              tags$p("Expensive and slow but highest quality. Label consistency between annotators (Cohen's κ). Active learning: prioritise uncertain examples near the decision boundary.")),
          div(class = "framework-card",
              tags$h5("Programmatic Labelling (Weak Supervision)"),
              tags$p("Snorkel framework: labelling functions from heuristics + rules. Low precision per rule but combined signal is strong. Best for large-scale low-resource settings."))
      )
    ),

    fluidRow(
      box(title = "⚖️ Class Imbalance — A Critical Interview Topic (Ch. 4)", status = "danger",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   div(class = "section-heading-dark", "Detection"),
                   div(class = "framework-card",
                       tags$h5("Identifying the Problem"),
                       tags$p("Class distribution analysis. Confusion matrix. If accuracy is misleadingly high (e.g., 99.9% — just predicting majority), class imbalance is the culprit. Always check PR-AUC, not just AUC-ROC.")),
                   div(class = "warn-box",
                       HTML("<strong>⚠️ Common mistake:</strong> Using accuracy as the metric for imbalanced problems. Always use precision/recall, F1, AUC-PR."))
            ),
            column(4,
                   div(class = "section-heading-dark", "Data-Level Methods"),
                   div(class = "framework-card",
                       tags$h5("Resampling Strategies"),
                       tags$p(tags$b("Oversampling minority: "), "SMOTE — synthetic minority oversampling via k-NN interpolation. Random duplication."),
                       tags$p(tags$b("Undersampling majority: "), "Tomek links, cluster centroids. Risky — may remove useful borderline examples."),
                       tags$p(tags$b("Combined:"), " SMOTEENN — apply both for better decision boundary."))
            ),
            column(4,
                   div(class = "section-heading-dark", "Algorithm-Level Methods"),
                   div(class = "framework-card",
                       tags$h5("Loss & Training Modifications"),
                       tags$p(tags$b("Class weights:"), " Inversely proportional to class frequency. Easy to implement."),
                       tags$p(tags$b("Focal loss:"), " Down-weights easy examples, focuses on hard cases. Used in content moderation, object detection (RetinaFace)."),
                       tags$p(tags$b("Cost-sensitive learning:"), " Assign explicit misclassification costs based on business impact."))
            )
          )
      )
    ),

    fluidRow(
      box(title = "📊 Self-Assessment: Data Engineering", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   sliderInput(ns("sc_formats"),  "Storage format selection", 0, 10, 5),
                   sliderInput(ns("sc_pipeline"), "Pipeline design (batch vs stream)", 0, 10, 5),
                   sliderInput(ns("sc_labels"),   "Labelling strategy knowledge", 0, 10, 5),
                   sliderInput(ns("sc_imbalance"),"Class imbalance handling", 0, 10, 5),
                   actionButton(ns("calc_data"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8, br(), uiOutput(ns("data_result")))
          )
      )
    )
  )
}

data_engineering_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_data, {
      avg <- mean(c(input$sc_formats, input$sc_pipeline, input$sc_labels, input$sc_imbalance))
      pct <- round(avg * 10)
      prep_manager$update_progress("data_engineering", pct)

      output$data_result <- renderUI({
        colour <- progress_colour(pct)
        div(class = if (pct >= 70) "success-box" else "tip-box",
            tags$h3(style = paste0("color:", colour), paste0(pct, "% ready")),
            if (pct >= 80) tags$p("✅ Strong data engineering foundation!") else
              tags$p("💡 Focus: review Ch. 3–4 on labelling and class imbalance handling.")
        )
      })
      showNotification(paste0("Data Engineering: ", pct, "% saved"), type = "message")
    })
  })
}
