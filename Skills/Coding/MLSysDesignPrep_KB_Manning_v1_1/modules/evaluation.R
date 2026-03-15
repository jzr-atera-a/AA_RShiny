# modules/evaluation.R
# Tab 6: Evaluation & Testing — Ch. 6

evaluation_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Evaluation & Testing"),
        tags$h2("Chapter 6 — Offline Metrics, Sliced Evaluation, Shadow Testing, A/B Design"),
        div(span(class="hero-badge","Offline Metrics"), span(class="hero-badge","Sliced Evaluation"),
            span(class="hero-badge","Shadow Testing"), span(class="hero-badge","Champion-Challenger"),
            span(class="hero-badge","Guardrail Metrics"))
    ),

    fluidRow(
      box(title="📏 Offline Metric Selection — K&B's Guide (Ch. 6)", status="primary", solidHeader=TRUE, width=6,
          div(class="warn-box",
              HTML("<strong>K&B's critical warning:</strong> Offline metrics are proxies. A model can achieve +3% AUC-ROC offline and produce -2% revenue in production. Always evaluate whether your offline metric is a VALID PROXY for the business metric you care about.")),
          br(),
          div(class="section-heading-dark","Classification Metrics"),
          tags$table(class="table table-hover",
            tags$thead(tags$tr(tags$th("Metric"), tags$th("Use When"), tags$th("K&B Caution"))),
            tags$tbody(
              tags$tr(tags$td("Accuracy"),     tags$td("Balanced classes, equal error costs"), tags$td("Never use alone for imbalanced problems")),
              tags$tr(tags$td("AUC-ROC"),      tags$td("Ranking quality, class-agnostic"),     tags$td("Misleading at extreme class imbalance")),
              tags$tr(tags$td("PR-AUC"),       tags$td("Imbalanced (fraud, rare events)"),     tags$td("More informative than ROC for rare classes")),
              tags$tr(tags$td("F-β Score"),    tags$td("Asymmetric FP/FN costs"),              tags$td("β > 1 weights recall; β < 1 weights precision")),
              tags$tr(tags$td("Log-Loss"),     tags$td("Calibrated probabilities needed"),      tags$td("Sensitive to overconfident wrong predictions")),
              tags$tr(tags$td("KS Statistic"), tags$td("Credit scoring, fraud scoring"),       tags$td("Max separation between pos/neg score distributions"))
            )
          ),
          br(),
          div(class="section-heading-dark","Ranking & Retrieval Metrics"),
          div(class="framework-card",
              tags$h5("NDCG@K — Production Standard for Ranked Lists"),
              tags$p("Normalised Discounted Cumulative Gain. Rewards relevant items ranked higher. Normalised to [0,1] vs ideal ordering. Industry standard for: feed ranking, search, recommendations, ads."),
              tags$p(tags$b("K&B tip:"), " Evaluate at multiple K values (5, 10, 20) to understand performance at different list depths.")),
          div(class="framework-card",
              tags$h5("Recall@K — For Retrieval Systems"),
              tags$p("What fraction of all relevant items appear in the top-K results? Critical for the RETRIEVAL stage (ANN search). A retrieval stage with 90% recall@100 means 10% of relevant items are lost before ranking — no ranking model can recover them.")),
          div(class="framework-card",
              tags$h5("MRR (Mean Reciprocal Rank)"),
              tags$p("Average of 1/rank_of_first_relevant_item. Good for Q&A, factual lookup where one correct answer exists. Less informative for multi-relevant-item scenarios."))
      ),

      box(title="🔬 Sliced Evaluation — K&B's Non-Negotiable (Ch. 6)", status="danger", solidHeader=TRUE, width=6,
          div(class="warn-box",
              HTML("<strong>K&B's strongest warning:</strong> Aggregate metrics HIDE disparities. A model with 95% overall accuracy can have 40% accuracy for a specific group. Shipping without sliced evaluation is an ethical and business risk. This is non-negotiable at any serious ML org.")),
          br(),
          div(class="framework-card",
              tags$h5("Why Aggregate Metrics Fail"),
              tags$p("Simpson's Paradox: a trend that appears in aggregated data can REVERSE when data is split by subgroup. Example: model improves overall CTR but degrades for mobile users (2× larger population impact). Aggregate hides this.")),
          div(class="framework-card",
              tags$h5("K&B's Required Slice Dimensions"),
              tags$ul(
                tags$li(tags$b("Demographic:"), " age group, gender identity, geography, language, disability status"),
                tags$li(tags$b("Data characteristics:"), " text length, image resolution, feature sparsity, missing value rate"),
                tags$li(tags$b("User behaviour:"), " new vs returning, power vs casual, engagement cohorts"),
                tags$li(tags$b("Platform / device:"), " mobile vs desktop, OS version, connection speed"),
                tags$li(tags$b("Time:"), " day-of-week, hour, seasonal (holiday vs normal), recency of user data"),
                tags$li(tags$b("Label subgroups:"), " rare classes, hard cases, near-boundary examples")
              )),
          div(class="framework-card",
              tags$h5("Automated Slice Discovery"),
              tags$p("Manual slicing misses UNKNOWN failure modes. Use tools that automatically find subpopulations with degraded performance:"),
              tags$ul(
                tags$li(tags$b("SliceFinder (Google):"), " Decision-tree search over feature space for degraded slices"),
                tags$li(tags$b("Robustness Gym (SalesForce):"), " Structured evaluation across NLP transformation types"),
                tags$li(tags$b("Domino Data:"), " Slice monitoring dashboards in production")
              )),
          div(class="tip-box",
              HTML("<strong>💡 Interview move:</strong> 'Before any model launch, I'd set a sliced evaluation gate: no demographic group should have performance more than 15% below aggregate. This must be a hard release blocker.'"))
      )
    ),

    fluidRow(
      box(title="🧪 Testing Strategy: Shadow → Champion-Challenger → A/B (Ch. 6)", status="warning", solidHeader=TRUE, width=12,
          fluidRow(
            column(3,
                   div(class="framework-card",
                       tags$h5("Shadow Testing"),
                       tags$p("New model makes predictions alongside production model. NO user impact. Compare outputs offline."),
                       tags$p(tags$b("Use for:"), " Verifying new model output distribution, latency SLO compliance, catching obvious bugs."),
                       div(class="badge-green","Zero risk"))),
            column(3,
                   div(class="framework-card",
                       tags$h5("Champion-Challenger (Canary)"),
                       tags$p("Route 1–5% of real traffic to challenger model. Monitor primary + guardrail metrics. Gradually increase if metrics hold."),
                       tags$p(tags$b("Rollback trigger:"), " Guardrail violation, error rate spike, or primary metric degradation > threshold."),
                       div(class="badge-blue","Low risk"))),
            column(3,
                   div(class="framework-card",
                       tags$h5("A/B Testing"),
                       tags$p(tags$b("Randomisation unit:"), " User-level (not request-level) to prevent carryover effects."),
                       tags$p(tags$b("Duration:"), " ≥ 2 weeks. Captures novelty effects and weekly seasonality."),
                       tags$p(tags$b("Power analysis:"), " Calculate minimum detectable effect before starting. Don't stop early!"),
                       div(class="badge-green","Controlled"))),
            column(3,
                   div(class="framework-card",
                       tags$h5("Guardrail Metrics"),
                       tags$p("Constraints that MUST NOT be violated even if primary metric improves:"),
                       tags$ul(
                         tags$li("Latency p99 < SLO"),
                         tags$li("User complaint rate"),
                         tags$li("New user retention rate"),
                         tags$li("Content diversity index"),
                         tags$li("Error / exception rate")
                       )))
          ),
          div(class="warn-box",
              HTML("<strong>⚠️ Network effects on social platforms:</strong> Users in control and treatment groups interact with each other. Treatment can affect control. Solution: cluster randomisation by social graph component, or geo-based holdout experiments."))
      )
    ),

    fluidRow(
      box(title="📊 Self-Assessment: Evaluation & Testing", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(3, sliderInput(ns("sc_metrics"),    "Metric selection for task",   0,10,5),
                      sliderInput(ns("sc_sliced"),     "Sliced evaluation design",    0,10,5)),
            column(3, sliderInput(ns("sc_shadow"),     "Shadow/canary deployment",    0,10,5),
                      sliderInput(ns("sc_ab"),         "A/B test design",             0,10,5)),
            column(3, sliderInput(ns("sc_guardrails"), "Guardrail metrics",           0,10,5),
                      br(), actionButton(ns("calc_eval"), "Save Assessment", class="btn-meta", width="100%")),
            column(3, br(), uiOutput(ns("eval_result")))
          )
      )
    )
  )
}

evaluation_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_eval, {
      avg <- mean(c(input$sc_metrics, input$sc_sliced, input$sc_shadow, input$sc_ab, input$sc_guardrails))
      pct <- round(avg * 10)
      prep_manager$update_progress("evaluation", pct)
      output$eval_result <- renderUI({
        div(class=if(pct>=70)"success-box" else "tip-box",
            tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
            if(input$sc_sliced < 6) tags$p("⚠️ Priority: sliced evaluation is K&B's non-negotiable. Review Ch.6."),
            if(pct>=80) tags$p("✅ Strong evaluation framework. Remember: always propose sliced eval + guardrails."))
      })
      showNotification(paste0("Evaluation: ",pct,"% saved"), type="message")
    })
  })
}
