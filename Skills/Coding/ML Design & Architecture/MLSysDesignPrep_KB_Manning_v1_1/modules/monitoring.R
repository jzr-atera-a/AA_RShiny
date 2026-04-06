# modules/monitoring.R
# Tab 8: Monitoring & Reliability — Ch. 8

monitoring_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Monitoring & Reliability"),
        tags$h2("Chapter 8 — Drift Detection, Alerting, SLO Enforcement & Retraining Pipelines"),
        div(span(class="hero-badge","Covariate Drift"), span(class="hero-badge","Concept Drift"),
            span(class="hero-badge","PSI"), span(class="hero-badge","SLO Enforcement"),
            span(class="hero-badge","Retraining Triggers"))
    ),

    fluidRow(
      box(title="📉 Distribution Shift — K&B's Three Types (Ch. 8)", status="danger", solidHeader=TRUE, width=6,
          div(class="warn-box",
              HTML("<strong>K&B's central monitoring insight:</strong> ML models fail SILENTLY. Unlike traditional software (exceptions, crashes), models can degrade gradually over weeks with no error logs. Monitoring must be proactive, not reactive.")),
          br(),
          div(class="framework-card",
              tags$h5("Type 1: Covariate Shift — P(X) changes, P(Y|X) stable"),
              tags$p(tags$b("What:"), " Input feature distribution changes. Model was trained on one distribution, now sees another."),
              tags$p(tags$b("Example:"), " Model trained on desktop traffic deployed as mobile usage grows 3×. Features have different distributions (session length, screen size, touch vs click)."),
              tags$p(tags$b("Detection:"), " Monitor feature distribution statistics (mean, variance, quantiles) over rolling windows. Kolmogorov-Smirnov test, PSI (Population Stability Index)."),
              tags$p(tags$b("Fix:"), " Importance reweighting. Domain adaptation. Retrain on recent data.")),
          div(class="framework-card",
              tags$h5("Type 2: Label Shift — P(Y) changes, P(X|Y) stable"),
              tags$p(tags$b("What:"), " Label distribution changes. Same input patterns but different prevalence of classes."),
              tags$p(tags$b("Example:"), " Fraud detection model trained when fraud rate was 0.1%. Fraud rate increases to 0.5% due to new attack vector. Model's threshold is miscalibrated."),
              tags$p(tags$b("Detection:"), " Monitor prediction score distribution. If output distribution shifts while input features look stable → likely label shift."),
              tags$p(tags$b("Fix:"), " Black-box shift estimation. Adjust decision threshold. Retrain with recency weighting.")),
          div(class="framework-card",
              tags$h5("Type 3: Concept Drift — P(Y|X) changes"),
              tags$p(tags$b("What:"), " The relationship between features and labels changes. The MEANING of the problem evolves."),
              tags$p(tags$b("Example:"), " Sentiment model trained in 2022 on 'Twitter'. After platform changes, language and sentiment norms shift. Same input text now has different meaning."),
              tags$p(tags$b("Example 2:"), " House price prediction — model trained pre-2020. COVID changes the relationship between location and price fundamentally."),
              tags$p(tags$b("Detection:"), " Requires ground truth labels (delayed). Monitor error rate on labelled holdout set. Most insidious drift type."),
              tags$p(tags$b("Fix:"), " Frequent retraining. Recency weighting. Online learning."))
      ),

      box(title="🔍 What to Monitor & How (Ch. 8)", status="warning", solidHeader=TRUE, width=6,
          div(class="section-heading-dark","Monitoring Hierarchy"),
          div(class="framework-card",
              tags$h5("Layer 1: Infrastructure Metrics (Always First)"),
              tags$ul(
                tags$li("Request throughput and error rate (HTTP 4xx/5xx)"),
                tags$li("Latency distribution: p50, p95, p99 vs SLO"),
                tags$li("CPU/GPU utilisation and memory pressure"),
                tags$li("Queue depth (if asynchronous serving)")
              )),
          div(class="framework-card",
              tags$h5("Layer 2: Data Quality Metrics"),
              tags$ul(
                tags$li(tags$b("Feature completeness:"), " % null/missing per feature. Alert on spike."),
                tags$li(tags$b("Distribution metrics:"), " PSI, KL divergence, KS statistic per feature."),
                tags$li(tags$b("Volume:"), " if event volume drops > 20%, upstream pipeline issue."),
                tags$li(tags$b("Freshness watermark:"), " max event_time lag in streaming pipeline.")
              )),
          div(class="framework-card",
              tags$h5("Layer 3: Prediction Quality Metrics"),
              tags$ul(
                tags$li(tags$b("Output distribution:"), " prediction score histogram. Alert on shape change."),
                tags$li(tags$b("Confidence distribution:"), " avg confidence trending down → model uncertain."),
                tags$li(tags$b("Prediction volume by class:"), " class distribution shift in outputs."),
                tags$li(tags$b("Business proxy metrics:"), " CTR, conversion rate, rejection rate trending.")
              )),
          div(class="framework-card",
              tags$h5("Layer 4: Ground Truth Metrics (Delayed)"),
              tags$ul(
                tags$li("Actual accuracy on labelled holdout window"),
                tags$li("Feedback-loop signals (user ratings, corrections)"),
                tags$li("Sliced performance on known sensitive subgroups")
              )),
          div(class="section-heading-dark","Drift Detection Methods"),
          div(class="framework-card",
              tags$h5("PSI (Population Stability Index)"),
              tags$p("PSI = Σ (actual% - expected%) × ln(actual%/expected%). PSI < 0.1: no change. 0.1–0.2: moderate shift. > 0.2: significant shift → retrain."),
              tags$p("Applied per feature to detect covariate shift. Standard in finance for credit scoring model monitoring."))
      )
    ),

    fluidRow(
      box(title="🔄 Retraining Pipelines & Strategies (Ch. 8)", status="info", solidHeader=TRUE, width=12,
          fluidRow(
            column(3, div(class="framework-card",
                tags$h5("Time-Based Retraining"),
                tags$p("Retrain every N days regardless of performance. Simple, predictable. N depends on data drift rate."),
                tags$p(tags$b("Best for:"), " Systems where drift is gradual and predictable (seasonal)."),
                tags$p(tags$b("Risk:"), " May retrain unnecessarily (wasted compute) or not retrain when drift is sudden."),
                div(class="badge-blue","Simple")),
                div(class="framework-card",
                    tags$h5("Performance-Based Retraining"),
                    tags$p("Retrain when evaluation metric drops below a threshold on a held-out evaluation set."),
                    tags$p(tags$b("Requires:"), " Continuous evaluation, labelled holdout data. Harder for delayed-label scenarios (fraud, conversions)."),
                    div(class="badge-green","Efficient"))),
            column(3, div(class="framework-card",
                tags$h5("Drift-Based Retraining"),
                tags$p("Retrain when PSI > threshold on key features or prediction distribution changes significantly."),
                tags$p(tags$b("Best for:"), " Cases where labels are delayed but input drift can be detected quickly."),
                tags$p(tags$b("Caution:"), " Input drift doesn't always cause model degradation — validate before triggering expensive retrain."),
                div(class="badge-green","Responsive")),
                div(class="framework-card",
                    tags$h5("Online / Continual Learning"),
                    tags$p("Update model weights continuously with streaming data. Eliminates staleness."),
                    tags$p(tags$b("Challenge:"), " Catastrophic forgetting — model loses performance on older patterns."),
                    tags$p(tags$b("Solutions:"), " Elastic Weight Consolidation (EWC), replay buffers, experience replay."),
                    tags$p(tags$b("K&B caution:"), " Use only when staleness cost > stability cost. Not a default choice."),
                    div(class="badge-blue","Advanced"))),
            column(3, div(class="framework-card",
                tags$h5("Retraining Pipeline Components"),
                tags$ul(
                  tags$li(tags$b("Trigger:"), " drift alert, schedule, manual"),
                  tags$li(tags$b("Data assembly:"), " fetch + validate training window"),
                  tags$li(tags$b("Feature recomputation:"), " use feature store canonical functions"),
                  tags$li(tags$b("Training:"), " parallelised, with HPO if budget allows"),
                  tags$li(tags$b("Evaluation gate:"), " must beat champion on offline metrics + sliced eval"),
                  tags$li(tags$b("Shadow deploy:"), " validate predictions before live traffic"),
                  tags$li(tags$b("Canary:"), " gradual ramp with guardrail monitoring")
                ))),
            column(3, div(class="warn-box",
                HTML("<strong>⚠️ K&B's retraining pitfall:</strong> Teams that automate retraining without evaluation gates create 'model poisoning' risk. If the trigger fires due to a data pipeline bug (corrupt data), the retrained model trains on garbage and gets promoted automatically. Always gate on offline eval quality.")),
                div(class="framework-card",
                    tags$h5("Retraining Cadence by System Type"),
                    tags$p(tags$b("Fraud detection:"), " Daily or near-real-time. Adversarial drift."),
                    tags$p(tags$b("Product recommendation:"), " Weekly. Seasonal + catalogue changes."),
                    tags$p(tags$b("Search ranking:"), " Weekly to monthly. Stable signals."),
                    tags$p(tags$b("NLP/LLM features:"), " Monthly+. Fine-tuning is expensive.")))
          )
      )
    ),

    fluidRow(
      box(title="📊 Self-Assessment: Monitoring & Reliability", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(3, sliderInput(ns("sc_drift_types"), "Drift type identification",  0,10,5),
                      sliderInput(ns("sc_monitoring"),  "Monitoring layer design",    0,10,5)),
            column(3, sliderInput(ns("sc_detection"),   "Drift detection methods",   0,10,5),
                      sliderInput(ns("sc_retrain"),     "Retraining pipeline design", 0,10,5)),
            column(3, sliderInput(ns("sc_slo"),         "SLO enforcement",           0,10,5),
                      br(), actionButton(ns("calc_mon"), "Save Assessment", class="btn-meta", width="100%")),
            column(3, br(), uiOutput(ns("mon_result")))
          )
      )
    )
  )
}

monitoring_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_mon, {
      avg <- mean(c(input$sc_drift_types, input$sc_monitoring, input$sc_detection, input$sc_retrain, input$sc_slo))
      pct <- round(avg * 10)
      prep_manager$update_progress("monitoring", pct)
      output$mon_result <- renderUI({
        div(class=if(pct>=70)"success-box" else "tip-box",
            tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
            if(input$sc_drift_types < 6) tags$p("⚠️ Priority: know the 3 drift types and how to detect each. K&B Ch.8 core topic."),
            if(pct>=80) tags$p("✅ Strong monitoring design. Proactively mention drift monitoring in every system design."))
      })
      showNotification(paste0("Monitoring: ",pct,"% saved"), type="message")
    })
  })
}
