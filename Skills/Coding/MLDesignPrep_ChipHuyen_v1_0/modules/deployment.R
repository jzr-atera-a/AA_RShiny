# modules/deployment.R
# Tab 7: Deployment & Serving — Ch. 7

deployment_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Deployment & Prediction Serving"),
        tags$h2("Chapter 7 — Batch vs Online, Model Compression, Edge vs Cloud"),
        div(
          span(class = "hero-badge", "Batch Prediction"),
          span(class = "hero-badge", "Online Serving"),
          span(class = "hero-badge", "Quantisation"),
          span(class = "hero-badge", "Edge ML")
        )
    ),

    fluidRow(
      box(title = "⚡ Batch vs Online Prediction (Ch. 7)", status = "primary",
          solidHeader = TRUE, width = 7,

          tags$table(class = "table table-hover",
            tags$thead(tags$tr(
              tags$th(""), tags$th("Batch Prediction"), tags$th("Online Prediction")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$b("When")),       tags$td("Pre-compute for all users/items periodically"),   tags$td("Compute at request time")),
              tags$tr(tags$td(tags$b("Latency")),    tags$td("High (hours/minutes)"),                           tags$td("Low (<100ms typically)")),
              tags$tr(tags$td(tags$b("Throughput")), tags$td("Very high (process billions)"),                   tags$td("Limited by QPS")),
              tags$tr(tags$td(tags$b("Freshness")),  tags$td("Stale — predictions are N hours old"),            tags$td("Fresh — uses real-time context")),
              tags$tr(tags$td(tags$b("Cold Start")), tags$td("Cannot handle new items/users"),                  tags$td("Can handle dynamically")),
              tags$tr(tags$td(tags$b("Use Cases")),  tags$td("Email recs, batch scoring, offline reports"),     tags$td("Search ranking, real-time fraud, feed")),
              tags$tr(tags$td(tags$b("Infra")),      tags$td("Spark, MapReduce, Flink batch"),                  tags$td("REST/gRPC serving, model server"))
            )
          ),
          br(),
          div(class = "tip-box",
              HTML("<strong>💡 Hybrid pattern (production standard):</strong> Pre-compute batch embeddings (slow-changing user/item representations), combine with real-time context features at serving time. Best of both worlds — low latency + freshness where it matters."))
      ),

      box(title = "🚦 Deployment Strategies (Ch. 7, Ch. 9)", status = "info",
          solidHeader = TRUE, width = 5,

          div(class = "framework-card",
              tags$h5("Shadow Mode"),
              tags$p("Deploy new model alongside production model. New model makes predictions but they are not served to users. Compare outputs offline. Safe and risk-free way to validate a new model.")),
          div(class = "framework-card",
              tags$h5("Canary Release"),
              tags$p("Route a small % of traffic (1–5%) to the new model. Monitor metrics carefully. If metrics hold, gradually increase traffic allocation. Roll back immediately if guardrails are violated.")),
          div(class = "framework-card",
              tags$h5("Blue-Green Deployment"),
              tags$p("Maintain two identical environments (blue = current, green = new). Switch all traffic at once. Easy rollback — switch traffic back to blue. Higher infrastructure cost but zero downtime.")),
          div(class = "framework-card",
              tags$h5("A/B Testing"),
              tags$p("Split traffic by user cohort. Run controlled experiment with statistical significance. Primary use: validating business metric impact, not just technical correctness."))
      )
    ),

    fluidRow(
      box(title = "🗜️ Model Compression — Serving at Scale (Ch. 7)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(3,
                   div(class = "framework-card",
                       tags$h5("Quantisation"),
                       tags$p("Reduce numerical precision: FP32 → FP16 (2× reduction) → INT8 (4× reduction)."),
                       tags$p(tags$b("PTQ (Post-training):"), " Fast, slight accuracy drop. Apply after training."),
                       tags$p(tags$b("QAT (Quantisation-aware training):"), " Slower but minimal accuracy drop. Standard for mobile deployment."))
            ),
            column(3,
                   div(class = "framework-card",
                       tags$h5("Knowledge Distillation"),
                       tags$p("Train a small 'student' model to mimic a large 'teacher' model. Student learns from teacher's soft probability outputs (not just hard labels). Captures inter-class relationships."),
                       tags$p(tags$b("Example:"), " DistilBERT — 60% size of BERT, 97% of performance."))
            ),
            column(3,
                   div(class = "framework-card",
                       tags$h5("Pruning"),
                       tags$p("Remove weights with small magnitudes (weight pruning) or entire neurons/filters (structured pruning). Can achieve 90% sparsity with <1% accuracy drop on some tasks."),
                       tags$p("Structured pruning creates hardware-efficient sparse models."))
            ),
            column(3,
                   div(class = "framework-card",
                       tags$h5("Low-Rank Factorisation / LoRA"),
                       tags$p("Decompose weight matrices: ΔW = BA (low-rank). LoRA for LLM fine-tuning: 0.1% of parameters trained, 3× less GPU memory."),
                       tags$p(tags$b("Multi-LoRA serving:"), " Share base model weights, swap adapters per request — enables cost-effective multi-tenant fine-tuning."))
            )
          ),
          div(class = "success-box",
              HTML("<strong>✅ Huyen's principle:</strong> 'Most production models are over-parameterised for the serving environment. Compression can often recover 90%+ of accuracy while reducing model size 10–100×.' Always discuss compression as part of your serving architecture."))
      )
    ),

    fluidRow(
      box(title = "📊 Self-Assessment: Deployment & Serving", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   sliderInput(ns("sc_batch"),       "Batch vs online decision",   0, 10, 5),
                   sliderInput(ns("sc_compression"), "Model compression methods",  0, 10, 5),
                   sliderInput(ns("sc_strategies"),  "Deployment strategies",      0, 10, 5),
                   sliderInput(ns("sc_infra"),       "Serving infrastructure",     0, 10, 5),
                   actionButton(ns("calc_dep"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8, br(), uiOutput(ns("dep_result")))
          )
      )
    )
  )
}

deployment_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_dep, {
      avg <- mean(c(input$sc_batch, input$sc_compression, input$sc_strategies, input$sc_infra))
      pct <- round(avg * 10)
      prep_manager$update_progress("deployment", pct)

      output$dep_result <- renderUI({
        colour <- progress_colour(pct)
        div(class = if (pct >= 70) "success-box" else "tip-box",
            tags$h3(style = paste0("color:", colour), paste0(pct, "% ready")),
            if (pct >= 80) tags$p("✅ Strong deployment knowledge. Remember to propose shadow mode + canary as your rollout strategy.") else
              tags$p("💡 Review: batch vs online trade-offs, model compression, and the hybrid serving pattern.")
        )
      })
      showNotification(paste0("Deployment: ", pct, "% saved"), type = "message")
    })
  })
}
