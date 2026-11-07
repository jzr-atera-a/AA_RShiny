# modules/data_pipeline.R
# Tab 3: Data Pipeline Design — Ch. 3

data_pipeline_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Data Pipeline Design"),
        tags$h2("Chapter 3 — Batch, Streaming, Schema Evolution, Quality & Lineage"),
        div(span(class="hero-badge","Kafka"), span(class="hero-badge","Spark"),
            span(class="hero-badge","Schema Evolution"), span(class="hero-badge","Data Quality"),
            span(class="hero-badge","Exactly-Once"))
    ),

    fluidRow(
      box(title="⚡ Batch vs Streaming — The Core Decision (Ch. 3)", status="primary", solidHeader=TRUE, width=7,
          div(class="warn-box",
              HTML("<strong>K&B insight:</strong> Most production ML systems need BOTH batch and streaming pipelines serving different parts of the feature set. The choice per feature depends on required freshness, not a global architecture decision.")),
          br(),
          tags$table(class="table table-hover",
            tags$thead(tags$tr(tags$th("Dimension"), tags$th("Batch (Spark/MapReduce)"), tags$th("Streaming (Kafka+Flink/Spark SS)"))),
            tags$tbody(
              tags$tr(tags$td(tags$b("Latency")),        tags$td("Minutes to hours"),       tags$td("Milliseconds to seconds")),
              tags$tr(tags$td(tags$b("Throughput")),     tags$td("Very high (TBs/hr)"),     tags$td("High (millions events/sec)")),
              tags$tr(tags$td(tags$b("Complexity")),     tags$td("Lower — simpler to debug"),tags$td("Higher — stateful, ordering, exactly-once")),
              tags$tr(tags$td(tags$b("Cost")),           tags$td("Lower (off-peak spot)"),  tags$td("Higher (always-on infra)")),
              tags$tr(tags$td(tags$b("Fault tolerance")),tags$td("Rerun from checkpoint"),  tags$td("Exactly-once via offset commits")),
              tags$tr(tags$td(tags$b("Use for")),        tags$td("Historical features, training data generation, batch scoring"), tags$td("Real-time features, fraud signals, personalisation events")),
              tags$tr(tags$td(tags$b("Key tools")),      tags$td("Apache Spark, Hadoop, AWS Glue, dbt"), tags$td("Kafka, Flink, Spark Structured Streaming, Kinesis"))
            )
          ),
          div(class="tip-box",
              HTML("<strong>💡 Interview answer template:</strong> 'For [slow-changing feature], I'd use a nightly Spark batch job writing Parquet to the offline store. For [real-time feature], I'd use a Kafka consumer updating the Redis online store within 500ms of the event.'"))
      ),

      box(title="🏗️ Lambda vs Kappa Architecture (Ch. 3)", status="info", solidHeader=TRUE, width=5,
          div(class="framework-card",
              tags$h5("Lambda Architecture"),
              tags$p(tags$b("Batch layer:"), " Spark jobs recompute features from scratch periodically. High accuracy, handles corrections."),
              tags$p(tags$b("Speed layer:"), " Streaming pipeline for recent/real-time features."),
              tags$p(tags$b("Serving layer:"), " Merge batch + speed results at query time."),
              tags$p(tags$b("Downside:"), " Maintaining two codepaths. Consistency bugs between layers.")),
          div(class="framework-card",
              tags$h5("Kappa Architecture"),
              tags$p("Everything is a stream. Historical reprocessing = replay Kafka topics. One codebase for batch + realtime."),
              tags$p(tags$b("Upside:"), " Simpler, one truth. Used by LinkedIn, Uber."),
              tags$p(tags$b("Downside:"), " Storing Kafka history is expensive. Complex windowing.")),
          div(class="framework-card",
              tags$h5("Delta Architecture (Modern)"),
              tags$p("Delta Lake / Apache Iceberg for ACID transactions on data lakes. Time-travel queries for reproducible training splits. Best of batch + streaming. K&B preferred for 2024+ systems.")),
          div(class="success-box",
              HTML("<strong>✅ K&B recommendation:</strong> Prefer Kappa or Delta for new systems. Use Lambda only when you have existing batch infrastructure that can't be migrated."))
      )
    ),

    fluidRow(
      box(title="⚠️ Data Quality — The Silent Killer (Ch. 3)", status="danger", solidHeader=TRUE, width=6,
          div(class="warn-box",
              HTML("<strong>K&B warning:</strong> Data quality issues are harder to debug than model bugs. They create silent failures — model trains fine, evaluates fine, then degrades slowly in production because input distribution changed upstream.")),
          div(class="framework-card",
              tags$h5("Data Validation Checklist"),
              tags$ul(
                tags$li(tags$b("Schema validation:"), " field types, nullability, enum values — fail fast at ingestion"),
                tags$li(tags$b("Statistical validation:"), " expected mean/variance/min/max per feature — catch distribution shifts"),
                tags$li(tags$b("Volume checks:"), " if events drop > 20%, alert immediately (upstream outage)"),
                tags$li(tags$b("Freshness checks:"), " watermark on event timestamps — detect delayed data"),
                tags$li(tags$b("Referential integrity:"), " user_id exists in users table, item_id in catalog")
              )),
          div(class="framework-card",
              tags$h5("Data Quality Tools"),
              tags$p(tags$b("Great Expectations:"), " Python-native data validation framework. Define expectations as code. Run on every pipeline run."),
              tags$p(tags$b("dbt tests:"), " SQL-layer quality checks integrated into transform pipeline."),
              tags$p(tags$b("Apache Griffin:"), " Big data quality at scale (Spark/Flink integrated)."),
              tags$p(tags$b("Soda Core:"), " Open-source, supports 15+ data sources.")),
          div(class="tip-box",
              HTML("<strong>💡 Interview signal:</strong> 'I'd add data validation checks at every pipeline stage as first-class citizens — not afterthoughts. Schema violations and distribution anomalies should page oncall immediately.'"))
      ),

      box(title="📋 Schema Evolution & Data Lineage (Ch. 3)", status="warning", solidHeader=TRUE, width=6,
          div(class="framework-card",
              tags$h5("Schema Evolution Strategies"),
              tags$p(tags$b("Backward compatible (safe):"), " Adding optional fields. Old consumers ignore new fields."),
              tags$p(tags$b("Forward compatible:"), " Old producers fill new fields with defaults. New consumers handle missing data."),
              tags$p(tags$b("Breaking change (dangerous):"), " Removing fields, changing types. Requires versioned schemas + migration window."),
              tags$p(tags$b("Schema registry:"), " Confluent Schema Registry or AWS Glue. Enforces compatibility rules on Kafka topics. Version control for data contracts.")),
          div(class="framework-card",
              tags$h5("Data Lineage — Why It Matters"),
              tags$p("Track: which model was trained on which data version? Which feature depends on which upstream table? K&B argue this is essential for debugging model regressions."),
              tags$ul(
                tags$li("Understand impact of upstream data bugs on model predictions"),
                tags$li("Reproduce a model training run exactly 6 months later"),
                tags$li("Audit which user data went into which model version (GDPR compliance)")
              )),
          div(class="framework-card",
              tags$h5("Lineage Tools"),
              tags$p(tags$b("Apache Atlas:"), " Hadoop ecosystem lineage and metadata."),
              tags$p(tags$b("DataHub (LinkedIn):"), " Open-source metadata platform. Tracks lineage across pipelines."),
              tags$p(tags$b("OpenLineage standard:"), " Open specification. Supported by Airflow, dbt, Spark, Flink.")),
          div(class="success-box",
              HTML("<strong>✅ K&B practice:</strong> Version every dataset used for training with a hash or snapshot ID. Link model versions to their training data versions. This is non-negotiable for production ML."))
      )
    ),

    fluidRow(
      box(title="📊 Self-Assessment: Data Pipeline", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(3, sliderInput(ns("sc_batch_stream"), "Batch vs streaming decision",0,10,5),
                      sliderInput(ns("sc_arch"),         "Lambda/Kappa/Delta patterns",0,10,5)),
            column(3, sliderInput(ns("sc_quality"),      "Data quality design",        0,10,5),
                      sliderInput(ns("sc_schema"),       "Schema evolution handling",  0,10,5)),
            column(3, sliderInput(ns("sc_lineage"),      "Data lineage awareness",     0,10,5),
                      br(), actionButton(ns("calc_dp"), "Save Assessment", class="btn-meta", width="100%")),
            column(3, br(), uiOutput(ns("dp_result")))
          )
      )
    )
  )
}

data_pipeline_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_dp, {
      avg <- mean(c(input$sc_batch_stream, input$sc_arch, input$sc_quality, input$sc_schema, input$sc_lineage))
      pct <- round(avg * 10)
      prep_manager$update_progress("data_pipeline", pct)
      output$dp_result <- renderUI({
        div(class=if(pct>=70)"success-box" else "tip-box",
            tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
            if(pct>=80) tags$p("✅ Strong data pipeline foundation.") else
              tags$p("💡 Focus: review Ch.3 on streaming patterns and data quality validation."))
      })
      showNotification(paste0("Data Pipeline: ",pct,"% saved"), type="message")
    })
  })
}
