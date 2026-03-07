# modules/evaluation.R
# Tab 6: Evaluation & Metrics — Ch. 6 Offline, Sliced, A/B Testing

evaluation_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Evaluation & Metrics"),
        tags$h2("Chapter 6 — Offline Metrics, Sliced Evaluation, A/B Testing & Business Alignment"),
        div(
          span(class = "hero-badge", "Offline vs Online"),
          span(class = "hero-badge", "Sliced Evaluation"),
          span(class = "hero-badge", "A/B Test Design"),
          span(class = "hero-badge", "Guardrail Metrics")
        )
    ),

    fluidRow(
      box(title = "📏 Offline Metrics Reference (Ch. 6)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "section-heading-dark", "Classification Metrics"),
          tags$table(class = "table table-hover",
            tags$thead(tags$tr(tags$th("Metric"), tags$th("Use When"), tags$th("Caution"))),
            tags$tbody(
              tags$tr(tags$td("Accuracy"),     tags$td("Balanced classes"),          tags$td("Misleading on imbalanced data")),
              tags$tr(tags$td("Precision/Recall"), tags$td("Asymmetric costs"),      tags$td("Trade-off — pick based on FP vs FN cost")),
              tags$tr(tags$td("F1 Score"),     tags$td("Balance P and R"),            tags$td("Treats FP = FN cost equally")),
              tags$tr(tags$td("AUC-ROC"),      tags$td("Ranking quality"),            tags$td("Misleading with extreme class imbalance")),
              tags$tr(tags$td("PR-AUC"),       tags$td("Imbalanced classes"),         tags$td("More informative than AUC-ROC when positive class is rare")),
              tags$tr(tags$td("Log Loss"),     tags$td("Probability calibration"),    tags$td("Sensitive to overconfident wrong predictions"))
            )
          ),
          br(),
          div(class = "section-heading-dark", "Ranking Metrics"),
          div(class = "framework-card",
              tags$h5("NDCG (Normalised Discounted Cumulative Gain)"),
              tags$p("Gold standard for ranking. Measures quality of ranked list. Penalises relevant items ranked lower. Normalised to [0,1] vs ideal ordering. Standard for feed ranking, search, ads systems.")),
          div(class = "framework-card",
              tags$h5("MRR (Mean Reciprocal Rank)"),
              tags$p("Average of reciprocal rank of first relevant item. Good for single-answer retrieval (Q&A, factual search). Less informative for multi-relevant item rankings.")),
          div(class = "framework-card",
              tags$h5("MAP (Mean Average Precision)"),
              tags$p("Average precision averaged over queries. Rewards models that place relevant items early. Commonly used in IR benchmarks."))
      ),

      box(title = "🔬 Sliced Evaluation — The Leadership Signal (Ch. 6)", status = "warning",
          solidHeader = TRUE, width = 6,

          div(class = "warn-box",
              HTML("<strong>⚠️ Huyen's key insight:</strong> A model with 95% overall accuracy may have 40% accuracy for a specific demographic group. Aggregate metrics HIDE disparities. Always slice before shipping.")),

          div(class = "framework-card",
              tags$h5("Why Slice?"),
              tags$p("1. Fairness: detect performance disparities across demographic groups."),
              tags$p("2. Debugging: find systematic failures on specific input subsets."),
              tags$p("3. Compliance: required by regulations in healthcare, finance, hiring.")),

          div(class = "framework-card",
              tags$h5("What to Slice By"),
              tags$ul(
                tags$li(tags$b("Demographic:"), " age group, gender, language, geography, device type"),
                tags$li(tags$b("Recency:"), " new users vs established users, new items vs established"),
                tags$li(tags$b("Behaviour:"), " power users vs casual, engagement cohorts"),
                tags$li(tags$b("Data characteristics:"), " text length, image resolution, feature sparsity"),
                tags$li(tags$b("Label subgroups:"), " rare classes vs common classes, edge cases")
              )),
          div(class = "framework-card",
              tags$h5("Automated Slice Discovery"),
              tags$p("Manual slicing misses unknown failure modes. Use SliceFinder or Orca to automatically identify input subspaces where model underperforms. Embed inputs, cluster errors. Requires label coverage across slices.")),
          div(class = "tip-box",
              HTML("<strong>💡 Interview signal:</strong> 'I'd include sliced evaluation across demographic and behavioural dimensions as a standard release gate — non-negotiable before production."))
      )
    ),

    fluidRow(
      box(title = "📊 A/B Testing & Metric Alignment (Ch. 6, Ch. 9)", status = "info",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   div(class = "section-heading-dark", "A/B Test Design"),
                   div(class = "framework-card",
                       tags$h5("Correct Setup"),
                       tags$p(tags$b("Randomisation unit:"), " user-level (not request-level) to avoid carryover effects and network interference."),
                       tags$p(tags$b("Min detectable effect:"), " use power analysis — don't stop early."),
                       tags$p(tags$b("Duration:"), " run ≥2 weeks to capture novelty effects and weekly seasonality.")),
                   div(class = "framework-card",
                       tags$h5("Network Effects on Social Platforms"),
                       tags$p("Treating user A and B differently affects their interactions. Use cluster randomisation (by social graph component) or geo-based holdout to avoid spillover bias."))
            ),
            column(4,
                   div(class = "section-heading-dark", "Guardrail Metrics"),
                   div(class = "framework-card",
                       tags$h5("What are Guardrails?"),
                       tags$p("Constraints that must not be violated even when optimising the primary metric. If a guardrail is violated, the experiment FAILS regardless of primary metric uplift.")),
                   div(class = "framework-card",
                       tags$h5("Common Guardrails"),
                       tags$ul(
                         tags$li("Latency p99 must stay under X ms"),
                         tags$li("User report rate must not increase"),
                         tags$li("New user retention must not decrease"),
                         tags$li("Content diversity index must stay above threshold"),
                         tags$li("Model error rate must not increase")
                       ))
            ),
            column(4,
                   div(class = "section-heading-dark", "Offline → Online Alignment"),
                   div(class = "warn-box",
                       HTML("<strong>⚠️ Classic failure:</strong> Model achieves +2% AUC-ROC offline but produces -5% revenue in production. Offline metrics are proxies — a good proxy is predictive, measurable, and fast.")),
                   div(class = "framework-card",
                       tags$h5("Proxy Metric Pitfalls"),
                       tags$ul(
                         tags$li("CTR optimisation → clickbait content"),
                         tags$li("Session time → addictive/harmful content"),
                         tags$li("Engagement rate → controversial posts"),
                         tags$li("Recommendation click rate → filter bubble")
                       ))
            )
          )
      )
    ),

    fluidRow(
      box(title = "📊 Self-Assessment: Evaluation", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   sliderInput(ns("sc_metrics"),   "Metric selection for task type", 0, 10, 5),
                   sliderInput(ns("sc_sliced"),    "Sliced evaluation design",       0, 10, 5),
                   sliderInput(ns("sc_ab"),        "A/B test design",                0, 10, 5),
                   sliderInput(ns("sc_guardrails"),"Guardrail metrics",              0, 10, 5),
                   actionButton(ns("calc_eval"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8, br(), uiOutput(ns("eval_result")))
          )
      )
    )
  )
}

evaluation_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_eval, {
      avg <- mean(c(input$sc_metrics, input$sc_sliced, input$sc_ab, input$sc_guardrails))
      pct <- round(avg * 10)
      prep_manager$update_progress("evaluation", pct)

      output$eval_result <- renderUI({
        colour <- progress_colour(pct)
        div(class = if (pct >= 70) "success-box" else "tip-box",
            tags$h3(style = paste0("color:", colour), paste0(pct, "% ready")),
            if (input$sc_sliced < 6)
              tags$p("⚠️ Priority: sliced evaluation is a top L6 signal. Review why aggregate metrics are insufficient."),
            if (pct >= 80)
              tags$p("✅ Strong evaluation framework. Remember guardrail metrics in every A/B test design.")
        )
      })
      showNotification(paste0("Evaluation: ", pct, "% saved"), type = "message")
    })
  })
}
