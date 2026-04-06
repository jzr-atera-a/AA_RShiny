# modules/feature_store.R
# Tab 4: Feature Engineering & Feature Store — Ch. 4

feature_store_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Feature Engineering & Feature Store"),
        tags$h2("Chapter 4 — Production Feature Pipelines, Train/Serve Consistency, Backfilling"),
        div(span(class="hero-badge","Offline Store"), span(class="hero-badge","Online Store"),
            span(class="hero-badge","Train/Serve Skew"), span(class="hero-badge","Point-in-Time Joins"),
            span(class="hero-badge","Backfilling"))
    ),

    fluidRow(
      box(title="🏪 Feature Store Architecture — The Full Picture (Ch. 4)", status="primary", solidHeader=TRUE, width=7,
          div(class="success-box",
              HTML("<strong>K&B's key insight:</strong> The feature store is the most important infrastructure component in production ML. Without it, every team re-implements features differently, creating inconsistency between training and serving that silently degrades model performance.")),
          br(),
          div(class="section-heading-dark","Three-Layer Architecture"),
          div(class="funnel-stage",
              div(class="funnel-num","1"),
              div(div(class="funnel-title","Feature Computation Layer"),
                  div(class="funnel-desc","Batch jobs (Spark) + streaming jobs (Flink/Kafka). Computes feature values from raw events. One canonical implementation.")),
              div(class="funnel-count","Source of Truth")),
          div(class="funnel-stage",
              div(class="funnel-num","2"),
              div(div(class="funnel-title","Offline Store (Historical)"),
                  div(class="funnel-desc","Parquet on S3/GCS. Delta Lake for ACID. Used by training pipeline. Enables point-in-time correct joins. S3 + Hive metastore.")),
              div(class="funnel-count","Training Data")),
          div(class="funnel-stage",
              div(class="funnel-num","3"),
              div(div(class="funnel-title","Online Store (Low-Latency Serving)"),
                  div(class="funnel-desc","Redis / DynamoDB / Cassandra. Key: entity_id → feature vector. p99 < 5ms. Populated by streaming pipeline.")),
              div(class="funnel-count","Serving (<5ms)")),
          br(),
          div(class="warn-box",
              HTML("<strong>⚠️ Train/Serve Skew — K&B's #1 production failure mode:</strong> Training features are computed differently from serving features (different code, different timestamps, different business logic). The model trains on data that never matches what it sees in production. <em>This is the most common silent failure in ML systems.</em>")),
          div(class="framework-card",
              tags$h5("How the Feature Store Prevents Skew"),
              tags$p("One feature computation function, called both at training time (reading from offline store) and at serving time (reading from online store). Same code path → same values."))
      ),

      box(title="📐 Point-in-Time Joins — Critical for Correctness (Ch. 4)", status="danger", solidHeader=TRUE, width=5,
          div(class="warn-box",
              HTML("<strong>⚠️ Most subtle data leakage source:</strong> Using feature values from AFTER the label event during training. Point-in-time joins ensure features reflect only information available AT the time of the prediction.")),
          br(),
          div(class="framework-card",
              tags$h5("The Problem — Illustrated"),
              tags$p("Scenario: predict whether a user will churn in the next 7 days."),
              tags$p("Feature: 'user's total sessions in the past 7 days'"),
              tags$p(tags$b("Wrong:"), " Query this feature today for all historical rows → includes sessions AFTER the label date. Model sees the future."),
              tags$p(tags$b("Right:"), " For each training row (user, date), query sessions where event_time ≤ row_date.")),
          div(class="framework-card",
              tags$h5("Point-in-Time Join Implementation"),
              tags$p("In SQL: JOIN ON feature_table.entity_id = label_table.entity_id AND feature_table.event_time <= label_table.label_date"),
              tags$p("In Feast/Tecton: built-in PITP (point-in-time-correct) join. Handles efficiently with range partitioning."),
              tags$p("In Spark: as-of join or sorted merge join with time constraint.")),
          div(class="framework-card",
              tags$h5("Feature Backfilling"),
              tags$p("When introducing a new feature, historical values must be computed to train models on it. Backfilling = re-running feature computation over historical data using the same canonical function. Critical: use PITP semantics when backfilling.")),
          div(class="success-box",
              HTML("<strong>✅ Interview move:</strong> 'I'd use point-in-time correct joins in the training pipeline to prevent temporal leakage — this is supported natively by Feast and Tecton.'"))
      )
    ),

    fluidRow(
      box(title="🔬 Feature Engineering Patterns (Ch. 4)", status="warning", solidHeader=TRUE, width=12,
          fluidRow(
            column(3,
                   div(class="section-heading-dark","Numerical Features"),
                   div(class="framework-card",
                       tags$h5("Transformations"),
                       tags$p(tags$b("Log transform:"), " revenue, follower count, price. Right-skewed distributions."),
                       tags$p(tags$b("Z-score:"), " age, rating score. Gaussian assumption needed."),
                       tags$p(tags$b("Min-max:"), " pixel values, percentages. Known range."),
                       tags$p(tags$b("Bucketisation:"), " age → bins. Captures non-linear relationships without polynomial features. Caution: information loss at bin boundaries."))),
            column(3,
                   div(class="section-heading-dark","Categorical Features"),
                   div(class="framework-card",
                       tags$h5("Encoding Strategies"),
                       tags$p(tags$b("One-hot (OHE):"), " Low cardinality. device_type, day_of_week."),
                       tags$p(tags$b("Target encoding:"), " High cardinality (city, product_category). Encode with label mean. MUST use out-of-fold to prevent target leakage."),
                       tags$p(tags$b("Embedding (learned):"), " Very high cardinality (user_id, item_id, query). Dense representation. DLRM / two-tower pattern."))),
            column(3,
                   div(class="section-heading-dark","Temporal Features"),
                   div(class="framework-card",
                       tags$h5("Time-Based Signals"),
                       tags$p(tags$b("Recency:"), " time since last action. Exponential decay weighting."),
                       tags$p(tags$b("Cyclical encoding:"), " sin/cos for hour-of-day, day-of-week. Preserves cyclical continuity for linear models."),
                       tags$p(tags$b("Rolling aggregates:"), " 7-day / 30-day counts, sums, means. Must compute with PITP semantics!"),
                       tags$p(tags$b("Seasonal features:"), " is_weekend, is_holiday, is_peak_hour."))),
            column(3,
                   div(class="section-heading-dark","Cross Features"),
                   div(class="framework-card",
                       tags$h5("Interaction Features"),
                       tags$p(tags$b("Manual crosses:"), " user_age_group × item_category. Captures non-linear signal for linear models. Powerful for CTR prediction."),
                       tags$p(tags$b("Embedding dot product:"), " user_embedding · item_embedding = relevance score. The two-tower fundamental."),
                       tags$p(tags$b("DCN (Deep & Cross):"), " Automatically learns feature crosses of bounded order. Used in Google's production ad system.")))
          )
      )
    ),

    fluidRow(
      box(title="📊 Self-Assessment: Feature Engineering & Store", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(3, sliderInput(ns("sc_fs_arch"),    "Feature store architecture", 0,10,5),
                      sliderInput(ns("sc_pitp"),       "Point-in-time joins",        0,10,5)),
            column(3, sliderInput(ns("sc_encoding"),   "Feature encoding strategies",0,10,5),
                      sliderInput(ns("sc_skew"),       "Train/serve skew awareness", 0,10,5)),
            column(3, sliderInput(ns("sc_backfill"),   "Backfilling design",         0,10,5),
                      br(), actionButton(ns("calc_fs"),"Save Assessment", class="btn-meta", width="100%")),
            column(3, br(), uiOutput(ns("fs_result")))
          )
      )
    )
  )
}

feature_store_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_fs, {
      avg <- mean(c(input$sc_fs_arch, input$sc_pitp, input$sc_encoding, input$sc_skew, input$sc_backfill))
      pct <- round(avg * 10)
      prep_manager$update_progress("feature_store", pct)
      output$fs_result <- renderUI({
        div(class=if(pct>=70)"success-box" else "tip-box",
            tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
            if(input$sc_skew < 6)  tags$p("⚠️ Priority: train/serve skew is K&B's #1 production failure. Review the feature store architecture."),
            if(input$sc_pitp < 6)  tags$p("⚠️ Point-in-time joins are critical for correct training data — review Ch.4."),
            if(pct>=80) tags$p("✅ Strong feature engineering knowledge!"))
      })
      showNotification(paste0("Feature Store: ",pct,"% saved"), type="message")
    })
  })
}
