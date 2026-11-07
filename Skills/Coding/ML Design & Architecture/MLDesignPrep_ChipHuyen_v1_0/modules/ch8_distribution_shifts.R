# modules/ch8_distribution_shifts.R
# Chapter 8: Data Distribution Shifts and Monitoring — Chip Huyen

ch8_distribution_shifts_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
      tags$h1("Ch.8 — Data Distribution Shifts and Monitoring"),
      tags$h2("Causes of failure, the three shift types, and how to build observable ML systems"),
      div(span(class="hero-badge","Covariate Shift"),span(class="hero-badge","Label Shift"),
          span(class="hero-badge","Concept Drift"),span(class="hero-badge","Monitoring"),
          span(class="hero-badge","Observability"))
    ),

    # ── 1. Causes of ML System Failures ─────────────────────────────────────
    fluidRow(
      box(title="⚠️ Causes of ML System Failures", status="danger", solidHeader=TRUE, width=12,
        div(class="warn-box", HTML("<strong>Huyen's central warning:</strong> Most ML system failures are silent. The model continues returning predictions — they just stop being correct. You cannot rely on exception handling to catch model degradation.")),
        br(),
        fluidRow(
          column(4,
            div(class="framework-card",
              tags$h5("Production Data Differs from Training Data"),
              tags$p("The single biggest cause. Training data is a snapshot; production data is a live stream. Sources of divergence:"),
              tags$ul(
                tags$li(tags$b("Sampling bias:"), " how training data was collected skews what the model learns"),
                tags$li(tags$b("Label lag:"), " labels collected at time T, but distribution has shifted by T+1"),
                tags$li(tags$b("Feedback loops:"), " model predictions influence future data (e.g., recommended items get more clicks → more training signal → amplification bias"),
                tags$li(tags$b("World changes:"), " economies shift, user behaviour evolves, new features enter the domain")
              )
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("Edge Cases and Degenerate Feedback Loops"),
              tags$p(tags$b("Edge cases:"), " rare but high-impact inputs the model has never seen. A fraud detection model trained on historical fraud misses entirely new fraud patterns."),
              tags$p(tags$b("Degenerate feedback loops:"), " system behaviour changes the data distribution it was trained on. Classic examples:"),
              tags$ul(
                tags$li("Popularity bias: recommended items get more exposure → more clicks → more training signal → further amplification"),
                tags$li("Ad ranking: highest-bidding ads trained on historical CTR, but CTR of an ad changes once it is ranked higher"),
                tags$li("Self-fulfilling predictions: crime prediction models deployed to police → more arrests in predicted areas → more training data from those areas")
              )
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("Software and Data Pipeline Bugs"),
              tags$p("Huyen dedicates significant attention to non-model failures:"),
              tags$ul(
                tags$li(tags$b("Feature pipeline bugs:"), " a feature computed differently at serving vs training (train-serve skew)"),
                tags$li(tags$b("Schema changes:"), " upstream data source changes a field type silently — model receives nulls"),
                tags$li(tags$b("Clock skew:"), " feature timestamp misaligned with label timestamp — temporal leakage"),
                tags$li(tags$b("Hardware failures:"), " numeric underflow/overflow on edge devices producing garbage predictions"),
                tags$li(tags$b("Cascading failures:"), " one model's output feeds another — errors compound multiplicatively")
              )
            )
          )
        )
      )
    ),

    # ── 2. Data Distribution Shifts ─────────────────────────────────────────
    fluidRow(
      box(title="📊 Data Distribution Shifts — The Three Types", status="warning", solidHeader=TRUE, width=8,
        fluidRow(
          column(4,
            div(class="framework-card",
              tags$h5("Covariate Shift"),
              div(class="info-box-plain", HTML("<strong>P(X) changes, P(Y|X) stays the same</strong>")),
              tags$p("The input distribution changes but the relationship between inputs and outputs remains stable. The model's learned function is still correct — it just encounters new territory."),
              tags$p(tags$b("Example:"), " NLP model trained on formal news articles deployed to social media text. Vocabulary, sentence structure, and length differ dramatically."),
              tags$p(tags$b("Example:"), " CV model trained on daytime images deployed in night conditions."),
              tags$p(tags$b("Detection:"), " Monitor feature distributions (KS test for continuous, chi-square for categorical). PSI per feature."),
              tags$p(tags$b("Fix:"), " Importance reweighting, domain adaptation, collect representative data, retrain on recent window.")
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("Label Shift"),
              div(class="info-box-plain", HTML("<strong>P(Y) changes, P(X|Y) stays the same</strong>")),
              tags$p("Also called prior probability shift. The marginal distribution of labels changes, but given a label, the input looks the same. Label shift is the transpose of covariate shift."),
              tags$p(tags$b("Example:"), " Disease diagnosis model. Prevalence of a condition changes seasonally. The features of patients with the disease remain the same, but more patients now have it."),
              tags$p(tags$b("Example:"), " Spam detection. Volume of spam increases dramatically — prior shifts from 10% to 40%."),
              tags$p(tags$b("Detection:"), " Monitor output (prediction) distribution. If labels exist, monitor label distribution directly."),
              tags$p(tags$b("Fix:"), " Black-box shift estimation (BBSE). Adjust prior at inference time without retraining.")
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("Concept Drift"),
              div(class="warn-box", HTML("<strong>P(Y|X) changes — the hardest to detect</strong>")),
              tags$p("The true relationship between inputs and outputs changes. The model's learned function becomes incorrect even on inputs it has seen before. Often happens gradually."),
              tags$p(tags$b("Example:"), " Credit scoring. Economic conditions change — the same applicant profile that indicated low risk 3 years ago now indicates higher risk."),
              tags$p(tags$b("Example:"), " Sentiment analysis. The word 'sick' used to be negative; in certain communities it became a positive slang term."),
              tags$p(tags$b("Types:"), " Sudden (event-driven), gradual (slow drift), recurring (seasonal), blip (temporary outlier)."),
              tags$p(tags$b("Detection:"), " Requires ground truth labels — difficult. Proxy: monitor model confidence distribution, use reference windows."),
              tags$p(tags$b("Fix:"), " Frequent retraining, recency-weighted training data, sliding window retraining.")
            )
          )
        )
      ),
      box(title="📐 Detecting Distribution Shifts", status="info", solidHeader=TRUE, width=4,
        div(class="section-heading-dark","Statistical Tests"),
        div(class="framework-card",
          tags$h5("Two-Sample Tests"),
          tags$p("Compare training distribution vs serving distribution by asking: could these two samples have come from the same distribution?"),
          tags$ul(
            tags$li(tags$b("KS Test (Kolmogorov-Smirnov):"), " non-parametric, works on any continuous distribution. Compares CDFs. p-value < 0.05 → distributions differ."),
            tags$li(tags$b("Chi-Square Test:"), " categorical features. Compare observed vs expected frequency tables."),
            tags$li(tags$b("MMD (Maximum Mean Discrepancy):"), " works in kernel space — can detect higher-order distribution differences. Better for high-dimensional data."),
            tags$li(tags$b("Learned classifier:"), " train a model to distinguish training vs serving data. If it succeeds, distributions differ.")
          )
        ),
        div(class="framework-card",
          tags$h5("PSI — Population Stability Index"),
          tags$p(HTML("PSI = Σ (A<sub>i</sub>% − E<sub>i</sub>%) × ln(A<sub>i</sub>% / E<sub>i</sub>%)")),
          tags$ul(
            tags$li(HTML("<strong>PSI < 0.10</strong> — stable, no action")),
            tags$li(HTML("<strong>PSI 0.10–0.20</strong> — minor shift, investigate")),
            tags$li(HTML("<strong>PSI > 0.20</strong> — major shift, retrain"))
          )
        ),
        div(class="tip-box", HTML("<strong>Huyen's tip:</strong> Monitoring output distribution (predictions) requires no labels and is the fastest early-warning signal. Monitor input distributions per feature for root cause analysis."))
      )
    ),

    # ── 3. Monitoring and Observability ─────────────────────────────────────
    fluidRow(
      box(title="🔬 Monitoring and Observability", status="primary", solidHeader=TRUE, width=12,
        div(class="success-box", HTML("<strong>Monitoring vs Observability:</strong> Monitoring tells you <em>when</em> something goes wrong (threshold alerts on known metrics). Observability gives you the ability to understand <em>why</em> it went wrong (logs, traces, metrics that let you ask novel questions without redeployment).")),
        br(),
        fluidRow(
          column(3,
            div(class="section-heading-dark","Operational Metrics"),
            div(class="framework-card",
              tags$h5("Infrastructure Health"),
              tags$ul(
                tags$li("Request throughput (QPS)"),
                tags$li("Latency: p50, p95, p99"),
                tags$li("CPU/GPU/Memory utilisation"),
                tags$li("Error rate (4xx, 5xx, timeouts)"),
                tags$li("Queue depth (batch systems)"),
                tags$li("Cache hit rate (feature store)")
              )
            )
          ),
          column(3,
            div(class="section-heading-dark","ML Model Metrics"),
            div(class="framework-card",
              tags$h5("What to Track"),
              tags$ul(
                tags$li("Prediction score distribution (output drift)"),
                tags$li("Feature value distributions (input drift)"),
                tags$li("Null/missing rate per feature"),
                tags$li("Model accuracy (when labels available)"),
                tags$li("Sliced performance by cohort"),
                tags$li("Calibration: predicted prob vs observed rate"),
                tags$li("Feature importance drift over time")
              )
            )
          ),
          column(3,
            div(class="section-heading-dark","Business Metrics"),
            div(class="framework-card",
              tags$h5("Downstream Impact"),
              tags$ul(
                tags$li("Click-through rate / conversion rate"),
                tags$li("Revenue per user"),
                tags$li("User satisfaction (explicit ratings)"),
                tags$li("Churn rate"),
                tags$li("Content diversity index"),
                tags$li("Fairness metrics by demographic"),
                tags$li("Upstream/downstream system health")
              )
            )
          ),
          column(3,
            div(class="section-heading-dark","Tooling Stack"),
            div(class="framework-card",
              tags$h5("Monitoring Infrastructure"),
              tags$ul(
                tags$li(tags$b("Metrics:"), " Prometheus + Grafana"),
                tags$li(tags$b("Logs:"), " ELK Stack, Splunk, Datadog"),
                tags$li(tags$b("Tracing:"), " Jaeger, Zipkin for distributed systems"),
                tags$li(tags$b("ML-specific:"), " Evidently AI, Arize, WhyLabs, Fiddler"),
                tags$li(tags$b("Alerting:"), " PagerDuty, OpsGenie"),
                tags$li(tags$b("Dashboards:"), " Looker, Superset, custom Grafana")
              )
            )
          )
        ),
        br(),
        div(class="section-heading-dark","Alerting Design"),
        fluidRow(
          column(6,
            div(class="framework-card",
              tags$h5("Retraining Triggers"),
              tags$table(class="table table-hover",
                tags$thead(tags$tr(tags$th("Trigger Type"),tags$th("Condition"),tags$th("Best For"))),
                tags$tbody(
                  tags$tr(tags$td("Time-based"),   tags$td("Every N days/hours"),    tags$td("Predictable, simple pipelines")),
                  tags$tr(tags$td("Performance"),  tags$td("Metric < threshold"),    tags$td("When labels available quickly")),
                  tags$tr(tags$td("Drift-based"),  tags$td("PSI > 0.20 on key feat"),tags$td("No labels needed, proactive")),
                  tags$tr(tags$td("Volume-based"), tags$td("N new labelled examples"),tags$td("Active learning workflows")),
                  tags$tr(tags$td("Event-based"),  tags$td("Major world event detected"),tags$td("News, finance, social media"))
                )
              )
            )
          ),
          column(6,
            div(class="framework-card",
              tags$h5("Alerting Best Practices"),
              tags$ul(
                tags$li(tags$b("Alert on symptoms, not causes:"), " 'model accuracy dropped' is actionable; 'feature X PSI=0.22' is a diagnosis aid"),
                tags$li(tags$b("Avoid alert fatigue:"), " too many alerts = engineers ignore them. Tune thresholds carefully."),
                tags$li(tags$b("Severity tiers:"), " P0 (immediate page), P1 (1hr response), P2 (next business day)"),
                tags$li(tags$b("Runbooks:"), " every alert must have a runbook — what to check, what to do"),
                tags$li(tags$b("Correlation:"), " correlate ML alerts with business metric alerts to confirm impact")
              )
            )
          )
        )
      )
    ),

    # Self-assessment
    fluidRow(
      box(title="📊 Self-Assessment: Ch.8", status="success", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            sliderInput(ns("sc_causes"), "Causes of ML failures",        0,10,5),
            sliderInput(ns("sc_shifts"), "3 distribution shift types",   0,10,5),
            sliderInput(ns("sc_detect"), "Drift detection methods",      0,10,5),
            sliderInput(ns("sc_monit"),  "Monitoring pipeline design",   0,10,5),
            actionButton(ns("save_ch8"), "Save Assessment", class="btn-meta", width="100%")
          ),
          column(8, br(), uiOutput(ns("ch8_result")))
        )
      )
    )
  )
}

ch8_distribution_shifts_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_ch8, {
      avg <- mean(c(input$sc_causes, input$sc_shifts, input$sc_detect, input$sc_monit))
      pct <- round(avg * 10)
      prep_manager$update_progress("ch8_distribution_shifts", pct)
      output$ch8_result <- renderUI({
        div(class=if(pct>=70)"success-box"else"tip-box",
          tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
          if(pct>=80) tags$p("Strong Ch.8 knowledge. Always name all 3 drift types and describe PSI in interviews.")
          else tags$p("Review: the 3 drift types with examples, PSI thresholds, and how to detect each without labels.")
        )
      })
      showNotification(paste0("Ch.8: ",pct,"% saved"), type="message")
    })
  })
}
