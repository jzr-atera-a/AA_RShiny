# modules/banking_case_study.R
# Case Study: ML-Driven Multichannel Customer Communications — Banking
# Applies Chip Huyen's full ML lifecycle to a real-world bank use case
# (PEGA + Google Cloud + BigQuery + Vertex AI + CACI data)

banking_case_study_ui <- function(id) {
  ns <- NS(id)

  # ── Shared CSS for interactive section tabs ───────────────────────────────
  css <- "
  .cs-selector {
    display:flex; gap:5px; flex-wrap:wrap; margin-bottom:14px;
  }
  .cs-btn {
    padding:5px 15px; border-radius:18px; border:2px solid #b2dfdb;
    background:#fff; color:#008A82; font-size:11px; font-weight:700;
    cursor:pointer; transition:all 0.16s; letter-spacing:0.3px; white-space:nowrap;
  }
  .cs-btn:hover  { background:#e0f4f2; border-color:#008A82; }
  .cs-btn.active { background:#002C3C; border-color:#002C3C; color:#fff; }
  .cs-panel { display:none; animation:csFade 0.18s ease; }
  .cs-panel.show { display:block; }
  @keyframes csFade { from{opacity:0;transform:translateY(-5px)} to{opacity:1;transform:translateY(0)} }
  .cs-arch-node {
    display:inline-block; padding:7px 14px; border-radius:7px; margin:3px;
    font-size:11px; font-weight:700; border:2px solid;
  }
  .cs-arch-arr { color:#008A82; font-size:18px; font-weight:700; vertical-align:middle; margin:0 4px; }
  .kpi-card {
    background:linear-gradient(135deg,#002C3C,#008A82);
    border-radius:10px; padding:14px; text-align:center; color:#fff; margin-bottom:10px;
  }
  .kpi-val { font-size:1.8em; font-weight:800; display:block; font-family:'JetBrains Mono',monospace; }
  .kpi-lbl { font-size:10px; text-transform:uppercase; letter-spacing:1px; opacity:0.75; margin-top:4px; }
  "

  # ── JavaScript for interactive panel switching (scoped per box) ───────────
  js <- "
<script>
function csShow(boxId, panelId) {
  // Hide all panels in this box
  document.querySelectorAll('#' + boxId + ' .cs-panel').forEach(function(p){
    p.classList.remove('show');
  });
  // Deactivate all buttons in this box
  document.querySelectorAll('#' + boxId + ' .cs-btn').forEach(function(b){
    b.classList.remove('active');
  });
  // Show target panel
  var panel = document.getElementById(panelId);
  if (panel) panel.classList.add('show');
  // Activate clicked button
  var btn = document.querySelector('#' + boxId + ' [data-panel=\"' + panelId + '\"]');
  if (btn) btn.classList.add('active');
}

// Init: show first panel of each box
(function(){
  function init(){
    ['cs-box1','cs-box2','cs-box3','cs-box4','cs-box5'].forEach(function(boxId){
      var firstBtn = document.querySelector('#' + boxId + ' .cs-btn');
      if (firstBtn) firstBtn.click();
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else setTimeout(init, 120);
})();
</script>
"

  # ── Helper: section button ────────────────────────────────────────────────
  csBtn <- function(boxId, panelId, label, active=FALSE) {
    tags$button(
      class=paste0("cs-btn", if(active)" active"else""),
      `data-panel`=panelId,
      onclick=sprintf("csShow('%s','%s')", boxId, panelId),
      label
    )
  }
  csPanel <- function(panelId, ...) {
    div(id=panelId, class="cs-panel", ...)
  }

  tagList(
    tags$head(tags$style(HTML(css))),
    HTML(js),

    # ── Hero ───────────────────────────────────────────────────────────────
    div(class="meta-hero",
      tags$h1("Case Study — Banking Customers ML"),
      tags$h2("ML-Driven Multichannel Customer Communications: PEGA + GCP + BigQuery + Vertex AI + CACI"),
      div(
        span(class="hero-badge","Next-Best-Action"),
        span(class="hero-badge","Churn Prediction"),
        span(class="hero-badge","Channel Optimisation"),
        span(class="hero-badge","PEGA Decisioning"),
        span(class="hero-badge","Vertex AI"),
        span(class="hero-badge","Real Production System")
      ),
      tags$p(style="color:rgba(255,255,255,0.75);font-size:12px;margin-top:10px;",
        "A large UK bank communicating with millions of customers daily. Every section of this case study maps directly to a chapter of Designing ML Systems by Chip Huyen.")
    ),

    # ── Architecture Overview ─────────────────────────────────────────────
    fluidRow(
      box(title="🏗️ System Architecture Overview", status="primary", solidHeader=TRUE, width=12,
        div(style="text-align:center;padding:16px;",
          div(style="margin-bottom:12px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","DATA SOURCES"),
          div(
            span(class="cs-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","Bank Transactions"),
            span(class="cs-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","Digital Behaviour"),
            span(class="cs-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","ATM Usage"),
            span(class="cs-arch-node",style="background:#e3f2fd;border-color:#2980b9;color:#2980b9;","CACI Demographics"),
            span(class="cs-arch-node",style="background:#e3f2fd;border-color:#2980b9;color:#2980b9;","Support Interactions")
          ),
          div(style="font-size:22px;color:#008A82;margin:6px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","STORAGE & FEATURES"),
          div(
            span(class="cs-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","BigQuery Data Warehouse"),
            span(class="cs-arch-arr","→"),
            span(class="cs-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Feature Store"),
            span(class="cs-arch-arr","→"),
            span(class="cs-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Training Datasets")
          ),
          div(style="font-size:22px;color:#008A82;margin:6px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","MODELLING"),
          div(
            span(class="cs-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Vertex AI Training"),
            span(class="cs-arch-arr","→"),
            span(class="cs-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Propensity Models"),
            span(class="cs-arch-arr","→"),
            span(class="cs-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Churn Models"),
            span(class="cs-arch-arr","→"),
            span(class="cs-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Channel Models")
          ),
          div(style="font-size:22px;color:#008A82;margin:6px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","DECISIONING & CHANNELS"),
          div(
            span(class="cs-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","PEGA Next-Best-Action"),
            span(class="cs-arch-arr","→"),
            span(class="cs-arch-node",style="background:#f3e5f5;border-color:#8e44ad;color:#8e44ad;","Push Notification"),
            span(class="cs-arch-node",style="background:#f3e5f5;border-color:#8e44ad;color:#8e44ad;","Email"),
            span(class="cs-arch-node",style="background:#f3e5f5;border-color:#8e44ad;color:#8e44ad;","SMS"),
            span(class="cs-arch-node",style="background:#f3e5f5;border-color:#8e44ad;color:#8e44ad;","ATM"),
            span(class="cs-arch-node",style="background:#f3e5f5;border-color:#8e44ad;color:#8e44ad;","In-App")
          ),
          div(style="font-size:22px;color:#e67e22;margin:6px 0;","↺"),
          div(style="font-size:11px;color:#546e7a;font-weight:700;letter-spacing:1px;","FEEDBACK LOOP → RETRAINING")
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 1: Ch.1-2 — Problem Definition & System Design
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="📋 Box 1 — Ch.1-2: Problem Definition & System Design",
          status="primary", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 1 & 2 applied:</strong> Before writing a single line of ML code, the bank must define business objectives, translate them into ML tasks, and specify the full system scope including constraints, success metrics, and stakeholder alignment.")),
        br(),
        div(id="cs-box1",
          div(class="cs-selector",
            csBtn("cs-box1","cs1-framing","Business → ML Framing", TRUE),
            csBtn("cs-box1","cs1-tasks","ML Task Types"),
            csBtn("cs-box1","cs1-metrics","Success Metrics"),
            csBtn("cs-box1","cs1-constraints","Constraints"),
            csBtn("cs-box1","cs1-stakeholders","System Scope")
          ),

          csPanel("cs1-framing",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Business Goal → ML Objective Translation"),
                  tags$p(tags$b("Business goal:"), " Deliver the right message to the right customer at the right time through the best channel."),
                  tags$p("Following Huyen Ch.1: this vague business objective must be decomposed into precise, measurable ML tasks:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Business Goal"),tags$th("ML Objective"),tags$th("ML Metric"))),
                    tags$tbody(
                      tags$tr(tags$td("Increase product uptake"), tags$td("Propensity score per product"),     tags$td("AUC-ROC, Lift@10%")),
                      tags$tr(tags$td("Reduce churn"),            tags$td("30-day churn probability"),          tags$td("AUC-ROC, Precision@K")),
                      tags$tr(tags$td("Right channel"),           tags$td("Channel propensity classifier"),    tags$td("Top-1 accuracy, NDCG")),
                      tags$tr(tags$td("Right time"),              tags$td("Optimal send-time regression"),     tags$td("Click lift vs baseline")),
                      tags$tr(tags$td("Next-best-action"),        tags$td("Ranked action scoring"),            tags$td("Revenue per contact"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Huyen's 6-Step Iterative Loop Applied to Banking"),
                  timeline_entry("1","Project Scoping","Define: NBA prediction + churn + channel optimisation. Stakeholders: Marketing, Risk, Compliance, Digital. Latency SLO: <200ms for in-app; <1s for batch."),
                  timeline_entry("2","Data Engineering","Identify sources: core banking, digital behaviour, CACI external. Define BigQuery as central warehouse."),
                  timeline_entry("3","Model Development","Start with logistic regression baseline per product. Iterate to GBDTs. Evaluate channel models separately."),
                  timeline_entry("4","Evaluation","Offline: AUC per model. Online: A/B test CTR and conversion via PEGA traffic split."),
                  timeline_entry("5","Deployment","Vertex AI endpoints. PEGA consumes scores via API. Shadow mode first."),
                  timeline_entry("6","Monitoring","Track prediction drift, business KPIs daily. Retrain triggers: PSI > 0.20 on key features.")
                )
              )
            )
          ),

          csPanel("cs1-tasks",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Binary Classification"),
                  tags$p(tags$b("Churn prediction:"), " P(customer leaves in 30 days | features). Threshold tuned for precision-recall trade-off: missing a churner is more costly than false alarm."),
                  tags$p(tags$b("Product propensity:"), " P(customer responds to credit card offer). One binary classifier per product. Avoids class imbalance issues of multiclass.")
                ),
                div(class="framework-card",
                  tags$h5("Multi-class Classification"),
                  tags$p(tags$b("Channel selection:"), " P(channel = push | email | SMS | ATM | in-app). 5-class problem. Predict most likely engagement channel per customer context.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Ranking"),
                  tags$p(tags$b("Next-Best-Action:"), " Given a customer at a touchpoint, rank all eligible actions (products + messages) by expected value. PEGA's Arbitration layer applies business rules on top of ML scores."),
                  tags$p(tags$b("Metrics:"), " NDCG@K, MRR (Mean Reciprocal Rank), Precision@K. K = number of visible slots in the UI (e.g., 3 in-app tiles).")
                ),
                div(class="framework-card",
                  tags$h5("Contextual Bandits"),
                  tags$p(tags$b("Send-time optimisation:"), " For each customer × channel combination, learn optimal send time. Bandit formulation: each time slot is an arm; reward is open/click."),
                  tags$p("Epsilon-greedy initially; graduate to Thompson Sampling as data accumulates.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Time-Series / Regression"),
                  tags$p(tags$b("Send-time optimisation:"), " Predict P(open | send_hour, customer_id, channel). Historical engagement patterns per customer. Survival models capture time-to-engagement."),
                  tags$p(tags$b("Customer lifetime value (CLV):"), " Regression on expected 12-month revenue. Feeds into prioritisation of high-value customers in PEGA Arbitration.")
                )
              )
            )
          ),

          csPanel("cs1-metrics",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Offline ML Metrics"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Model"),tags$th("Primary Metric"),tags$th("Why"))),
                    tags$tbody(
                      tags$tr(tags$td("Propensity"),   tags$td("AUC-ROC"),         tags$td("Imbalanced — responders ~2-5%")),
                      tags$tr(tags$td("Churn"),         tags$td("PR-AUC"),          tags$td("Heavy class imbalance; cost asymmetry")),
                      tags$tr(tags$td("Channel"),       tags$td("Top-1 accuracy"),  tags$td("Single best channel needed")),
                      tags$tr(tags$td("Send-time"),     tags$td("Click lift"),      tags$td("Relative improvement vs random")),
                      tags$tr(tags$td("NBA Ranking"),   tags$td("NDCG@3"),          tags$td("3 visible offer slots in app"))
                    )
                  )
                ),
                div(class="tip-box", HTML("<strong>Huyen's warning:</strong> Offline metrics and online business metrics frequently disagree. A propensity model with AUC=0.82 may produce less revenue uplift than one with AUC=0.79 if the latter is better calibrated for high-value segments."))
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Online Business Metrics"),
                  tags$ul(
                    tags$li(tags$b("Primary:"), " product conversion rate, revenue uplift per campaign"),
                    tags$li(tags$b("Secondary:"), " click-through rate, email open rate, push notification tap rate"),
                    tags$li(tags$b("Guardrails:"), " opt-out rate (must not increase), complaint rate, regulatory breach count"),
                    tags$li(tags$b("Long-term:"), " 12-month customer retention rate, Net Promoter Score"),
                    tags$li(tags$b("Fairness:"), " equal offer rates across protected demographic groups (FCA compliance)")
                  )
                ),
                div(class="framework-card",
                  tags$h5("KPI Dashboard"),
                  fluidRow(
                    column(4, div(class="kpi-card", span(class="kpi-val","2.3×"), span(class="kpi-lbl","Lift vs rules-based"))),
                    column(4, div(class="kpi-card", span(class="kpi-val","18%"), span(class="kpi-lbl","Conversion rate"))),
                    column(4, div(class="kpi-card", span(class="kpi-val","<0.5%"), span(class="kpi-lbl","Opt-out rate")))
                  )
                )
              )
            )
          ),

          csPanel("cs1-constraints",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Latency SLOs by Channel"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Channel"),tags$th("Latency SLO"),tags$th("Serving Mode"))),
                    tags$tbody(
                      tags$tr(tags$td("In-app (browsing)"), tags$td("<200ms"),  tags$td("Online, real-time")),
                      tags$tr(tags$td("ATM screen"),         tags$td("<500ms"),  tags$td("Online, real-time")),
                      tags$tr(tags$td("Push notification"),  tags$td("<2s"),     tags$td("Near real-time")),
                      tags$tr(tags$td("Email campaign"),     tags$td("Minutes"), tags$td("Batch, pre-computed")),
                      tags$tr(tags$td("SMS alert"),          tags$td("Minutes"), tags$td("Batch, triggered")),
                      tags$tr(tags$td("Website banner"),     tags$td("<300ms"),  tags$td("Online, real-time"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Regulatory & Business Constraints"),
                  tags$ul(
                    tags$li(tags$b("FCA (Financial Conduct Authority):"), " 'Treat Customers Fairly' — cannot target vulnerable customers with unsuitable products"),
                    tags$li(tags$b("GDPR:"), " explicit consent for marketing use of personal data; right to explanation for declined offers"),
                    tags$li(tags$b("Contact frequency:"), " maximum N contacts per customer per day/week across all channels (PEGA contact policies)"),
                    tags$li(tags$b("Interpretability:"), " credit-related decisions require explanation — black-box models may not be suitable"),
                    tags$li(tags$b("Data residency:"), " customer data must remain in UK/EU — constrains cloud region choices"),
                    tags$li(tags$b("Model risk:"), " internal Model Risk Management (MRM) validation required before deployment")
                  )
                )
              )
            )
          ),

          csPanel("cs1-stakeholders",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("System Stakeholders (Ch.1 — Who Uses the System)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Stakeholder"),tags$th("Interacts Via"),tags$th("Concern"))),
                    tags$tbody(
                      tags$tr(tags$td("Customers"),       tags$td("All channels"),        tags$td("Relevance, privacy, frequency")),
                      tags$tr(tags$td("Marketing"),        tags$td("PEGA campaigns"),      tags$td("Conversion, reach, ROI")),
                      tags$tr(tags$td("Risk / Compliance"),tags$td("Model approval"),     tags$td("Fairness, explainability, FCA")),
                      tags$tr(tags$td("Data Scientists"),  tags$td("Vertex AI / BQ"),     tags$td("Model accuracy, iteration speed")),
                      tags$tr(tags$td("ML Ops"),           tags$td("Monitoring stack"),    tags$td("Reliability, drift, latency")),
                      tags$tr(tags$td("PEGA Admins"),      tags$td("PEGA Designer Studio"),tags$td("Decisioning logic, score thresholds"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("The PEGA + ML Integration Architecture"),
                  tags$p("PEGA acts as the", tags$b("decisioning orchestrator"), "— it does not train models. It consumes ML scores and applies business rules on top. This is a critical architectural pattern:"),
                  tags$ul(
                    tags$li(tags$b("ML provides:"), " propensity scores, churn probability, channel preference, CLV"),
                    tags$li(tags$b("PEGA applies:"), " contact policies, regulatory rules, channel capacity, offer eligibility"),
                    tags$li(tags$b("PEGA outputs:"), " the single best action per customer at each touchpoint"),
                    tags$li(tags$b("PEGA tracks:"), " experiment results, A/B test allocations, response data")
                  ),
                  div(class="success-box", HTML("<strong>Key pattern:</strong> ML models score all customers daily (batch). Real-time re-scoring triggered by specific events (login, ATM use). PEGA decides which score to act on based on channel context."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 2: Ch.3-4-5 — Data Engineering, Training Data & Feature Engineering
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🗄️ Box 2 — Ch.3-4-5: Data, Training Data & Feature Engineering",
          status="warning", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 3, 4 & 5 applied:</strong> The bank's data advantage is only realised if the pipelines, labelling strategy, and feature store are correctly designed. This box covers the full data stack from raw ingestion to feature serving.")),
        br(),
        div(id="cs-box2",
          div(class="cs-selector",
            csBtn("cs-box2","cs2-sources","Data Sources & Storage", TRUE),
            csBtn("cs-box2","cs2-labels","Training Data & Labels"),
            csBtn("cs-box2","cs2-features","Feature Engineering"),
            csBtn("cs-box2","cs2-featurestore","Feature Store"),
            csBtn("cs-box2","cs2-skew","Train-Serve Skew")
          ),

          csPanel("cs2-sources",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Internal Data Sources (Ch.3)"),
                  tags$ul(
                    tags$li(tags$b("Core banking (batch):"), " account balances, product ownership, transaction history — updated nightly to BigQuery"),
                    tags$li(tags$b("Digital banking (streaming):"), " app sessions, page views, feature usage — Kafka → BigQuery Streaming"),
                    tags$li(tags$b("ATM events (event-driven):"), " withdrawal amount, location, time — streamed in near real-time"),
                    tags$li(tags$b("Contact history:"), " all prior communications, responses, opt-outs — in PEGA, synced daily to BigQuery"),
                    tags$li(tags$b("Customer support:"), " call centre logs, complaint records — NLP features extracted from transcripts")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("CACI External Enrichment (Ch.3 — External Data)"),
                  tags$p("CACI Limited provides UK geodemographic data merged via privacy-safe customer identifiers:"),
                  tags$ul(
                    tags$li(tags$b("ACORN classification:"), " 62 lifestyle categories (e.g., 'Comfortable Retired', 'Student Life')"),
                    tags$li(tags$b("Household income bands:"), " estimated £ ranges, critical for product eligibility"),
                    tags$li(tags$b("Urban/rural segmentation:"), " affects channel preference (ATM use higher in rural)"),
                    tags$li(tags$b("Life stage:"), " young professional, family, pre-retirement — drives product relevance")
                  ),
                  div(class="warn-box", HTML("<strong>Ch.3 caution:</strong> CACI data is at household level, not individual. Joining to individual customer records introduces aggregation bias. Validate distributions before use."))
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("BigQuery as Central Warehouse (Ch.3)"),
                  tags$p(tags$b("Storage format:"), " Parquet in GCS for raw; BigQuery native storage for processed features. Columnar = fast analytical queries for feature generation."),
                  tags$p(tags$b("Partitioning:"), " tables partitioned by DATE to enable efficient time-windowed feature computation and point-in-time joins."),
                  tags$p(tags$b("Delta/Iceberg:"), " time-travel queries ensure reproducible training snapshots — critical for audit trails required by FCA."),
                  tags$p(tags$b("Batch update cadence:"), " core banking features daily; behavioural features hourly; streaming features near real-time.")
                )
              )
            )
          ),

          csPanel("cs2-labels",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Natural Labels in Banking (Ch.4)"),
                  tags$p("The bank benefits from abundant natural labels — customer interactions generate labels without human annotation:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Model"),tags$th("Natural Label"),tags$th("Label Delay"),tags$th("Window"))),
                    tags$tbody(
                      tags$tr(tags$td("Propensity — credit card"), tags$td("Product application submitted"), tags$td("Hours–7 days"), tags$td("30-day attribution")),
                      tags$tr(tags$td("Propensity — ISA"),         tags$td("ISA opened"),                    tags$td("1–14 days"),   tags$td("90-day attribution")),
                      tags$tr(tags$td("Churn"),                    tags$td("Account closed / transferred"), tags$td("30 days"),     tags$td("Observed at 90 days")),
                      tags$tr(tags$td("Channel"),                  tags$td("Email open, push tap, click"),  tags$td("Hours"),       tags$td("48-hour attribution")),
                      tags$tr(tags$td("Send-time"),                tags$td("Open/click timestamp"),         tags$td("Minutes"),     tags$td("24-hour window"))
                    )
                  )
                ),
                div(class="warn-box", HTML("<strong>Attribution window challenge:</strong> Churn label has a 30+ day delay. Model retraining cycle cannot be faster than label availability. For churn: minimum weekly retraining."))
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Class Imbalance in Banking (Ch.4)"),
                  tags$p("Banking ML is dominated by class imbalance:"),
                  tags$ul(
                    tags$li(tags$b("Product propensity:"), " ~2-5% positive rate. Use PR-AUC not ROC-AUC. Focal loss or class weights in GBDTs."),
                    tags$li(tags$b("Churn:"), " ~3-8% annual churn for retail banking. Oversample minority or use cost-sensitive learning."),
                    tags$li(tags$b("Channel model:"), " relatively balanced across 5 channels — standard cross-entropy adequate.")
                  )
                ),
                div(class="framework-card",
                  tags$h5("Data Leakage Risks (Ch.4)"),
                  tags$ul(
                    tags$li(tags$b("Temporal leakage:"), " using account balance at label time (post-decision) as a feature — must use balance at decision time only"),
                    tags$li(tags$b("CACI leakage:"), " CACI data refreshed annually — must join the vintage that was available at training time"),
                    tags$li(tags$b("Contact history:"), " if a customer responded to an offer, don't include that response as a training feature — it's the label")
                  )
                )
              )
            )
          ),

          csPanel("cs2-features",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Behavioural Features (Ch.5)"),
                  tags$ul(
                    tags$li("Transaction frequency: 7d, 30d, 90d windows"),
                    tags$li("Average account balance: rolling 30d mean"),
                    tags$li("Salary credit regularity: stddev of monthly credits"),
                    tags$li("Product count: number of active products"),
                    tags$li("Digital session frequency: logins per week"),
                    tags$li("ATM usage: visits, average withdrawal amount"),
                    tags$li("Direct debit count: financial commitment proxy"),
                    tags$li("Overdraft usage: risk indicator"),
                    tags$li("International transaction flag: travel indicator")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Engagement Features (Ch.5)"),
                  tags$ul(
                    tags$li("Email open rate: trailing 12 emails"),
                    tags$li("Push notification tap rate: trailing 30 days"),
                    tags$li("Time since last digital login"),
                    tags$li("Last channel responded to (recency signal)"),
                    tags$li("Preferred send time: mode of open timestamps"),
                    tags$li("Opt-out flags by channel"),
                    tags$li("Contact fatigue score: contacts / responses in 30d"),
                    tags$li("Last offer shown (avoid repetition)"),
                    tags$li("App version (proxy for digital engagement level)")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("CACI + Temporal Features (Ch.5)"),
                  tags$ul(
                    tags$li("ACORN lifestyle category (ordinal encoded)"),
                    tags$li("Household income band (ordinal)"),
                    tags$li("Urban / rural / suburban (one-hot)"),
                    tags$li("Life stage category"),
                    tags$li("Customer tenure: days since account open"),
                    tags$li("Age band (from KYC, not CACI)"),
                    tags$li("Day of week (cyclical encoding)"),
                    tags$li("Time of year (Q1-Q4, holiday period flags)"),
                    tags$li("Days since last product acquisition")
                  )
                )
              )
            )
          ),

          csPanel("cs2-featurestore",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Feature Store Architecture (Ch.5)"),
                  tags$p("The bank runs a two-tier feature store on GCP:"),
                  tags$ul(
                    tags$li(tags$b("Offline store (BigQuery):"), " historical feature values partitioned by date. Used for training dataset generation. Supports point-in-time joins."),
                    tags$li(tags$b("Online store (Vertex AI Feature Store / Redis):"), " latest feature values per customer_id. Served to PEGA in <10ms for real-time decisioning.")
                  ),
                  tags$p(tags$b("Feature registration:"), " each feature has: name, data type, entity key (customer_id), update cadence, description, owning team."),
                  tags$p(tags$b("Feature reuse:"), " 'transaction_frequency_30d' computed once, reused across propensity, churn, and channel models.")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Point-in-Time Joins — Critical for Banking"),
                  tags$p("For churn models: label is 'churned by day T+90'. Training features must be the values at day T, not T+90."),
                  tags$p(tags$b("Without point-in-time join:"), " feature 'account_balance_30d_avg' includes post-churn behaviour → data leakage → model overstates ability to detect churn."),
                  tags$p(tags$b("BigQuery implementation:"), ""),
                  tags$pre(style="font-size:10px;background:#f8fffe;border:1px solid #b2dfdb;border-radius:6px;padding:10px;",
"SELECT c.customer_id, c.churn_label,
  f.transaction_freq_30d,
  f.avg_balance_30d
FROM churn_labels c
LEFT JOIN feature_history f
  ON c.customer_id = f.customer_id
  AND f.feature_date = c.label_date"),
                  div(class="success-box", HTML("<strong>Ch.5 principle:</strong> Feature store point-in-time joins are the architectural solution to temporal leakage. Without them, churn model AUC is artificially inflated."))
                )
              )
            )
          ),

          csPanel("cs2-skew",
            div(class="warn-box", HTML("<strong>Train-serve skew — Huyen's #1 production failure — is especially dangerous in banking:</strong>")),
            br(),
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Source 1: CACI Join Difference"),
                  tags$p(tags$b("Training:"), " CACI 2023 vintage joined at training time."),
                  tags$p(tags$b("Serving:"), " CACI 2024 vintage refreshed in production."),
                  tags$p(tags$b("Effect:"), " 12% of customers change ACORN category year-on-year. Model receives different categorical encoding than trained on."),
                  tags$p(tags$b("Fix:"), " Feature store versioning — pin CACI vintage used at training. Flag vintage mismatch in monitoring.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Source 2: Aggregation Window Cutoff"),
                  tags$p(tags$b("Training:"), " 'transaction_frequency_30d' computed as COUNT(*) WHERE date >= CURRENT_DATE - 30."),
                  tags$p(tags$b("Serving:"), " PEGA calls feature store at 09:00. BigQuery refreshed at 02:00. 7-hour gap."),
                  tags$p(tags$b("Effect:"), " Serving feature uses slightly different window than training feature."),
                  tags$p(tags$b("Fix:"), " Explicit timestamp parameterisation in feature computation. Feature store stores computation timestamp.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Source 3: Null Handling Divergence"),
                  tags$p(tags$b("Training:"), " NULL email_open_rate filled with 0.0 (no emails sent = no opens)."),
                  tags$p(tags$b("Serving:"), " A new customer has NULL email_open_rate. PEGA API returns null → feature store passes null → model receives NaN."),
                  tags$p(tags$b("Effect:"), " Model predicts garbage for new customers."),
                  tags$p(tags$b("Fix:"), " Feature validation layer in the serving pipeline. Schema enforcement with defaults registered in feature store.")
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 3: Ch.6 — Model Development & Evaluation
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🧠 Box 3 — Ch.6: Model Development & Evaluation",
          status="success", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapter 6 applied:</strong> Baseline-first development, model selection rationale, offline evaluation strategy, sliced evaluation, and the offline-online metric gap — all applied to the bank's five ML model types.")),
        br(),
        div(id="cs-box3",
          div(class="cs-selector",
            csBtn("cs-box3","cs3-baselines","Baseline Strategy", TRUE),
            csBtn("cs-box3","cs3-propensity","Propensity Models"),
            csBtn("cs-box3","cs3-churn","Churn Model"),
            csBtn("cs-box3","cs3-channel","Channel & Send-Time"),
            csBtn("cs-box3","cs3-eval","Evaluation Strategy")
          ),

          csPanel("cs3-baselines",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Huyen's Baseline Hierarchy Applied to Banking"),
                  tags$p("Before any ML model, establish these baselines in order:"),
                  div(class="framework-card", style="border-left-color:#c0392b;",
                    tags$h5("Tier 1 — Random Baseline"),
                    tags$p("Offer credit card to 5% of customers randomly. Conversion rate: 1.2% (industry baseline). This is the floor. Any ML model must beat this.")
                  ),
                  div(class="framework-card", style="border-left-color:#e67e22;",
                    tags$h5("Tier 2 — Rule-Based (Current PEGA Rules)"),
                    tags$p("Existing PEGA business rules: target customers with tenure > 12 months, no existing credit card, income band 3+. Conversion rate: ~3.1%. This is the production baseline ML must beat.")
                  ),
                  div(class="framework-card", style="border-left-color:#f39c12;",
                    tags$h5("Tier 3 — Logistic Regression"),
                    tags$p("Logistic regression on 15 core features. Fast to train, interpretable, passes Model Risk Management. Conversion rate lift: ~4.8%.")
                  ),
                  div(class="framework-card", style="border-left-color:#27ae60;",
                    tags$h5("Tier 4 — XGBoost / LightGBM"),
                    tags$p("Gradient boosted trees on 50+ features including CACI. Conversion rate lift: ~6.2%. Currently in production for email channel.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("HPO with Vertex AI (Ch.6)"),
                  tags$p("Vertex AI Vizier provides Bayesian optimisation for hyperparameter search:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Model"),tags$th("Key HPO Parameters"),tags$th("Optimise For"))),
                    tags$tbody(
                      tags$tr(tags$td("XGBoost propensity"), tags$td("n_estimators, max_depth, learning_rate, subsample"), tags$td("AUC-ROC")),
                      tags$tr(tags$td("LightGBM churn"),     tags$td("num_leaves, min_data_in_leaf, lambda_l1"),           tags$td("PR-AUC")),
                      tags$tr(tags$td("NN channel"),         tags$td("layers, dropout, batch_size, learning_rate"),        tags$td("Top-1 accuracy")),
                      tags$tr(tags$td("Bandit send-time"),   tags$td("epsilon, decay_rate, context_features"),             tags$td("Click rate")  )
                    )
                  )
                ),
                div(class="tip-box", HTML("<strong>MRM requirement:</strong> Model Risk Management requires feature importance plots and partial dependence plots for all production models. XGBoost SHAP values satisfy this. Deep neural networks require LIME explanations — increasing complexity cost."))
              )
            )
          ),

          csPanel("cs3-propensity",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Credit Card Propensity Model"),
                  tags$p(tags$b("Label:"), " customer applied for credit card within 30 days of receiving offer."),
                  tags$p(tags$b("Positive rate:"), " ~3%. Heavy class imbalance."),
                  tags$p(tags$b("Algorithm:"), " LightGBM with class_weight='balanced'. Focal loss for NN variant."),
                  tags$p(tags$b("Top features by SHAP:")),
                  tags$ol(
                    tags$li("No existing credit card (binary)"),
                    tags$li("Monthly income estimate (CACI)"),
                    tags$li("Tenure in months"),
                    tags$li("Credit card spend on debit card (proxy)"),
                    tags$li("Digital session frequency")
                  ),
                  tags$p(tags$b("Threshold:"), " tuned to precision=0.35 at recall=0.65 (marketing team's cost-benefit ratio).")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("ISA / Savings Propensity Model"),
                  tags$p(tags$b("Label:"), " new ISA or savings account opened within 90 days."),
                  tags$p(tags$b("Positive rate:"), " ~7% (ISA season effect — peaks Jan-March)."),
                  tags$p(tags$b("Seasonality:"), " Q1 models retrained in November with ISA-season historical data upweighted."),
                  tags$p(tags$b("CACI features dominate:"), " ACORN life stage and income band are the two strongest predictors for ISA. Retirement-approaching customers have 3× baseline propensity.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Multi-Product Propensity"),
                  tags$p("Rather than one multi-label model, the bank runs one binary classifier per product:"),
                  tags$ul(
                    tags$li("Credit card propensity"),
                    tags$li("Personal loan propensity"),
                    tags$li("ISA / savings propensity"),
                    tags$li("Mortgage refinance propensity"),
                    tags$li("Travel insurance propensity")
                  ),
                  tags$p("PEGA's Arbitration layer ranks eligible products by expected value = propensity_score × product_margin × contact_cost_adjustment."),
                  div(class="success-box", HTML("<strong>Design choice:</strong> Separate binary models per product is preferred over one multiclass model because class imbalance varies dramatically per product, and models can be retrained independently."))
                )
              )
            )
          ),

          csPanel("cs3-churn",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("30-Day Churn Prediction Model"),
                  tags$p(tags$b("Definition:"), " churn = primary account closed OR salary credit stopped for 60+ days OR all products transferred out."),
                  tags$p(tags$b("Label difficulty:"), " 'soft churn' (reduced activity) vs 'hard churn' (account closure) require different lead times and interventions."),
                  tags$p(tags$b("Algorithm:"), " LightGBM. Survival analysis (Cox Proportional Hazard) for time-to-churn probability."),
                  tags$p(tags$b("Churn triggers (engineered features):")),
                  tags$ul(
                    tags$li("Salary credit gap: last credit > 45 days ago"),
                    tags$li("Balance decline rate: 3-month rolling decline"),
                    tags$li("Direct debit cancellations in last 30 days"),
                    tags$li("Recent call centre contact about leaving"),
                    tags$li("Competitor balance transfer inquiry (fraud system signal)")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Cost-Sensitive Evaluation"),
                  tags$p("Not all churners are equal. Intervention cost must be weighed against retention value:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Outcome"),tags$th("Cost/Value"),tags$th("Impact"))),
                    tags$tbody(
                      tags$tr(tags$td("True Positive (retain churner)"),  tags$td("+£850 CLV"),   tags$td("High value")),
                      tags$tr(tags$td("False Positive (intervene on stayer)"),tags$td("-£12 cost"),tags$td("Acceptable")),
                      tags$tr(tags$td("False Negative (miss churner)"),   tags$td("-£850 CLV"),   tags$td("High loss")),
                      tags$tr(tags$td("True Negative (no action needed)"),tags$td("£0"),          tags$td("Correct"))
                    )
                  ),
                  tags$p("Optimal threshold: maximise (TP × 850) - (FP × 12). At this bank: threshold ≈ 0.12 (low threshold to catch most churners given high FN cost)."),
                  div(class="warn-box", HTML("<strong>Sliced evaluation:</strong> Churn rate differs dramatically by customer segment (young customers: 12% annual; retirees: 2%). Aggregate AUC hides poor performance on high-churn segments."))
                )
              )
            )
          ),

          csPanel("cs3-channel",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Channel Optimisation Model"),
                  tags$p(tags$b("Task:"), " given a customer and a pending offer, predict which channel will generate the highest engagement."),
                  tags$p(tags$b("Algorithm:"), " Gradient Boosted Trees (5-class). Features: engagement history per channel, last login channel, age band, digital adoption score, opt-in status."),
                  tags$p(tags$b("Key finding:"), " channel preference is strongly correlated with age band and ATM usage:"),
                  tags$ul(
                    tags$li("Push notification: high for <35, high digital engagement"),
                    tags$li("Email: effective for 35-55, medium digital"),
                    tags$li("SMS: high for 55+, low digital"),
                    tags$li("ATM: high for rural, 55+"),
                    tags$li("In-app: high for mobile-first segments")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Send-Time Optimisation"),
                  tags$p(tags$b("Approach 1 — Per-customer historical mode:"), " compute modal open time from last 12 emails. Simple, works for engaged customers. Fails for new customers (cold start)."),
                  tags$p(tags$b("Approach 2 — Contextual bandit:"), " each hour-of-day slot is an arm. Reward = open within 2 hours. Thompson Sampling with customer-level Beta distributions."),
                  tags$p(tags$b("Approach 3 — Survival model:"), " model time-to-open as a hazard function. Predict hazard peak = optimal send time."),
                  tags$p(tags$b("Production:"), " Approach 2 (bandit) for email; Approach 1 for SMS (simpler); Approach 3 for push."),
                  div(class="tip-box", HTML("<strong>Cold start:</strong> New customers default to segment-level send time (ACORN cluster average) until 5+ interactions accumulated."))
                )
              )
            )
          ),

          csPanel("cs3-eval",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Offline Evaluation Strategy (Ch.6)"),
                  tags$p(tags$b("Temporal split (mandatory):"), " training on data before date T; validation on T to T+30; test on T+30 to T+90. Random split would leak future data."),
                  tags$p(tags$b("Sliced evaluation:"),),
                  tags$ul(
                    tags$li("By ACORN segment (12 groups)"),
                    tags$li("By digital engagement level (low/medium/high)"),
                    tags$li("By customer tenure band"),
                    tags$li("By product ownership count"),
                    tags$li("By geography (urban/rural/suburban)")
                  ),
                  tags$p(tags$b("Calibration:"), " propensity scores must be calibrated (Platt scaling or isotonic regression). A score of 0.3 should mean 30% of customers with that score convert.")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Offline-Online Metric Gap"),
                  tags$p("Classic Huyen warning: offline metrics do not always predict online performance. At this bank:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Model"),tags$th("Offline AUC"),tags$th("Online Lift"),tags$th("Gap"))),
                    tags$tbody(
                      tags$tr(tags$td("Credit card v1"), tags$td("0.82"), tags$td("+1.8% CTR"),  tags$td("Good correlation")),
                      tags$tr(tags$td("Credit card v2"), tags$td("0.85"), tags$td("+1.6% CTR"),  tags$td("Higher AUC, lower lift")),
                      tags$tr(tags$td("Churn v3"),       tags$td("0.79"), tags$td("-12% churn"),  tags$td("Good")),
                      tags$tr(tags$td("Channel v2"),     tags$td("0.71"), tags$td("+22% CTR"),    tags$td("Large lift despite lower AUC"))
                    )
                  ),
                  div(class="warn-box", HTML("<strong>Learning:</strong> Credit card v2 had higher AUC because it learned to score high on easy positives (existing applicants). Channel v2 had lower AUC but correctly identified underserved segments. Always A/B test before declaring a winner."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 4: Ch.7-9 — Deployment, Continual Learning & Test in Production
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🚀 Box 4 — Ch.7-9: Deployment, Serving & Continual Learning",
          status="danger", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 7, 8 & 9 applied:</strong> Model deployment architecture, PEGA integration, prediction serving modes, A/B testing, and the bank's continual learning strategy.")),
        br(),
        div(id="cs-box4",
          div(class="cs-selector",
            csBtn("cs-box4","cs4-serving","Serving Architecture", TRUE),
            csBtn("cs-box4","cs4-pega","PEGA Integration"),
            csBtn("cs-box4","cs4-compression","Model Optimisation"),
            csBtn("cs-box4","cs4-testing","Testing in Production"),
            csBtn("cs-box4","cs4-continual","Continual Learning")
          ),

          csPanel("cs4-serving",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Batch vs Online Serving by Channel (Ch.7)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Channel"),tags$th("Mode"),tags$th("Infrastructure"),tags$th("Score Freshness"))),
                    tags$tbody(
                      tags$tr(tags$td("Email campaign"),     tags$td("Batch"),        tags$td("Vertex AI batch predict + BigQuery"),        tags$td("Daily")),
                      tags$tr(tags$td("SMS"),                tags$td("Batch"),        tags$td("Nightly scoring job"),                       tags$td("Daily")),
                      tags$tr(tags$td("Push notification"),  tags$td("Near real-time"),tags$td("Triggered by event → Vertex AI endpoint"), tags$td("Hours")),
                      tags$tr(tags$td("ATM screen"),         tags$td("Online"),       tags$td("Vertex AI endpoint <500ms"),                 tags$td("Real-time")),
                      tags$tr(tags$td("In-app / website"),   tags$td("Online"),       tags$td("Vertex AI endpoint <200ms"),                 tags$td("Real-time"))
                    )
                  )
                ),
                div(class="framework-card",
                  tags$h5("Hybrid Pattern (Production Standard)"),
                  tags$p("Most customers' scores are pre-computed daily (batch) and cached in Redis. Real-time Vertex AI scoring only triggered for:"),
                  tags$ul(
                    tags$li("New customers (no batch score yet)"),
                    tags$li("Significant recent events (large transaction, new product)"),
                    tags$li("ATM and in-app interactions (sub-second SLO)")
                  ),
                  div(class="success-box", HTML("<strong>Cost optimisation:</strong> 95% of serving from cache. Real-time Vertex AI calls reserved for the 5% needing freshness. 10× cost reduction vs fully real-time."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Vertex AI Endpoint Architecture"),
                  tags$p(tags$b("Model packaging:"), " models exported to ONNX for framework-agnostic serving. Registered in Vertex AI Model Registry with metadata: training dataset version, feature set version, AUC, SHA."),
                  tags$p(tags$b("Endpoint configuration:"),),
                  tags$ul(
                    tags$li("Auto-scaling: 2–20 replicas based on QPS"),
                    tags$li("Traffic split: 95% v_prod / 5% v_challenger"),
                    tags$li("Health checks: /predict endpoint monitored"),
                    tags$li("Request logging: all predictions logged to BigQuery for drift monitoring")
                  ),
                  tags$p(tags$b("Feature assembly:"), " at prediction time, Vertex AI pulls live features from Vertex Feature Store (online store, <10ms) + batch features from Redis cache.")
                )
              )
            )
          ),

          csPanel("cs4-pega",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("PEGA Next-Best-Action Decisioning"),
                  tags$p("PEGA sits above the ML layer. It receives scores and applies the bank's decisioning framework:"),
                  tags$ol(
                    tags$li(tags$b("Eligibility rules:"), " is this product available to this customer? (e.g., no credit card if already has one, income eligibility check)"),
                    tags$li(tags$b("Applicability rules:"), " is this context appropriate? (e.g., do not show mortgage offer on ATM)"),
                    tags$li(tags$b("Suitability:"), " FCA compliance check — is this product suitable for this customer's financial situation?"),
                    tags$li(tags$b("Contact policy:"), " has this customer been contacted too recently? Maximum 2 contacts per day across all channels"),
                    tags$li(tags$b("Arbitration:"), " rank eligible actions by: propensity_score × product_value × context_relevance. Select top action.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("PEGA + Vertex AI Integration"),
                  tags$p(tags$b("Real-time flow (ATM / in-app):"),),
                  tags$ol(
                    tags$li("Customer triggers event (ATM login, app session)"),
                    tags$li("PEGA receives event with customer_id + context"),
                    tags$li("PEGA calls Vertex AI endpoint via REST API"),
                    tags$li("Vertex AI returns scores in <200ms"),
                    tags$li("PEGA runs eligibility + contact policy checks"),
                    tags$li("PEGA returns top action to channel"),
                    tags$li("Customer sees personalised message"),
                    tags$li("Response logged to PEGA + BigQuery")
                  ),
                  div(class="tip-box", HTML("<strong>Fallback:</strong> if Vertex AI endpoint >500ms or error, PEGA falls back to pre-computed batch scores from Redis. Zero customer-facing downtime."))
                )
              )
            )
          ),

          csPanel("cs4-compression",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Model Compression for Latency SLOs (Ch.7)"),
                  tags$p("Online channels (ATM, in-app) require <200ms end-to-end. Model inference budget: ~50ms. Compression strategies applied:"),
                  tags$ul(
                    tags$li(tags$b("XGBoost/LightGBM:"), " natively fast for tabular data. 200 trees × depth 6 achieves ~10ms inference. No compression needed."),
                    tags$li(tags$b("Neural network channel model:"), " INT8 quantisation via TensorRT. 4× faster, <1% accuracy drop. Reduces from 80ms to 22ms."),
                    tags$li(tags$b("ONNX export:"), " all models exported to ONNX for framework-agnostic serving and runtime optimisation."),
                    tags$li(tags$b("Feature lookup:"), " dominant latency source. Redis cache reduces feature assembly from 120ms to 8ms.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Latency Budget Breakdown"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Component"),tags$th("Latency"),tags$th("Optimisation"))),
                    tags$tbody(
                      tags$tr(tags$td("PEGA receives event"), tags$td("~5ms"),  tags$td("—")),
                      tags$tr(tags$td("Feature lookup (Redis)"),tags$td("~8ms"),tags$td("Pre-warmed cache")),
                      tags$tr(tags$td("Vertex AI model inference"),tags$td("~22ms"),tags$td("INT8 quant + ONNX")),
                      tags$tr(tags$td("PEGA rules engine"),   tags$td("~15ms"), tags$td("—")),
                      tags$tr(tags$td("Channel API response"),tags$td("~5ms"),  tags$td("—")),
                      tags$tr(tags$td(tags$b("Total")),        tags$td(tags$b("~55ms")),tags$td(tags$b("SLO: 200ms ✓")))
                    )
                  )
                )
              )
            )
          ),

          csPanel("cs4-testing",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("A/B Testing Strategy (Ch.9)"),
                  tags$p(tags$b("Test: ML model vs existing PEGA business rules"),),
                  tags$ul(
                    tags$li(tags$b("Unit of randomisation:"), " customer_id (ensures same customer always sees same variant)"),
                    tags$li(tags$b("Split:"), " 50/50 control (rules) vs treatment (ML scores)"),
                    tags$li(tags$b("Primary metric:"), " product conversion rate per 1000 contacts"),
                    tags$li(tags$b("Guardrails:"), " opt-out rate ≤ baseline; complaint rate stable; FCA breach count = 0"),
                    tags$li(tags$b("Duration:"), " minimum 4 weeks (to capture full purchase decision cycle)"),
                    tags$li(tags$b("Power:"), " pre-calculated for MDE = 0.5% absolute lift with α=0.05, power=80%")
                  ),
                  div(class="success-box", HTML("<strong>Result:</strong> ML treatment achieved +2.3× conversion vs rules-based control (p < 0.001). Rolled to 100% of eligible customers."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Multi-Armed Bandit for Channel Selection (Ch.9)"),
                  tags$p("For customers where channel preference is uncertain, PEGA uses bandit allocation rather than a fixed model prediction:"),
                  tags$ul(
                    tags$li(tags$b("Epsilon-greedy (initial):"), " ε=0.2 → 20% exploration, 80% exploit best channel"),
                    tags$li(tags$b("Graduates to Thompson Sampling:"), " after 10+ interactions, posterior over channel CTR is well-estimated"),
                    tags$li(tags$b("Reward:"), " click or open within attribution window"),
                    tags$li(tags$b("Context:"), " time of day, product type, customer segment fed as context features")
                  ),
                  tags$p(tags$b("Key result:"), " bandit-selected channel achieves 18% higher CTR than channel-model-selected channel, especially for new customers (<6 months) where model has limited history.")
                )
              )
            )
          ),

          csPanel("cs4-continual",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Retraining Strategy by Model (Ch.9)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Model"),tags$th("Frequency"),tags$th("Method"),tags$th("Trigger"))),
                    tags$tbody(
                      tags$tr(tags$td("Credit card propensity"),tags$td("Weekly"),  tags$td("Stateless"),tags$td("Scheduled + PSI drift")),
                      tags$tr(tags$td("Churn model"),          tags$td("Monthly"),  tags$td("Stateless"),tags$td("Scheduled")),
                      tags$tr(tags$td("Channel model"),        tags$td("Weekly"),   tags$td("Stateless"),tags$td("Engagement rate drop")),
                      tags$tr(tags$td("Send-time bandit"),     tags$td("Daily"),    tags$td("Stateful"), tags$td("Continuous (online)")),
                      tags$tr(tags$td("ISA propensity"),       tags$td("Nov-March"),tags$td("Stateless"),tags$td("Seasonal (ISA season)"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("ISA Season — Concept Drift Example"),
                  tags$p("ISA propensity model shows seasonal concept drift. Customer behaviour changes dramatically in Q1 (Jan-March) when ISA contribution deadline approaches."),
                  tags$ul(
                    tags$li("Baseline ISA propensity: 3-4% year-round"),
                    tags$li("Q1 ISA propensity: 12-18% — different customer profile responds"),
                    tags$li("Features that predict ISA uptake change: account balance becomes more predictive than usual"),
                    tags$li("Solution: maintain two ISA models — year-round and ISA-season. PEGA switches at Nov 1, Apr 1.")
                  ),
                  div(class="tip-box", HTML("<strong>Pattern:</strong> Seasonal concept drift is predictable — schedule model switches based on the known calendar, not reactive drift detection."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 5: Ch.8-10-11 — Monitoring, Infrastructure & Responsible AI
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🔍 Box 5 — Ch.8-10-11: Monitoring, Infrastructure & Responsible AI",
          status="info", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 8, 10 & 11 applied:</strong> How the bank monitors for drift in live production, the GCP-based MLOps platform architecture, and the critical responsible AI requirements imposed by FCA regulation and GDPR.")),
        br(),
        div(id="cs-box5",
          div(class="cs-selector",
            csBtn("cs-box5","cs5-monitoring","Monitoring Strategy", TRUE),
            csBtn("cs-box5","cs5-drift","Drift Detection"),
            csBtn("cs-box5","cs5-infra","GCP MLOps Platform"),
            csBtn("cs-box5","cs5-fairness","Fairness & FCA"),
            csBtn("cs-box5","cs5-privacy","Privacy & GDPR")
          ),

          csPanel("cs5-monitoring",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Operational Metrics"),
                  tags$p(tags$b("Vertex AI endpoints:")),
                  tags$ul(
                    tags$li("Request throughput per endpoint"),
                    tags$li("Prediction latency p50 / p95 / p99"),
                    tags$li("Error rate (HTTP 5xx, model exceptions)"),
                    tags$li("Feature lookup latency (Redis)"),
                    tags$li("BigQuery batch job success rate")
                  ),
                  tags$p(tags$b("PEGA execution:")),
                  tags$ul(
                    tags$li("NBA decision throughput"),
                    tags$li("Contact policy rejection rate"),
                    tags$li("Fallback rate (cache vs real-time)"),
                    tags$li("Channel distribution (are channels balanced?)")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("ML-Specific Metrics"),
                  tags$ul(
                    tags$li(tags$b("Score distribution:"), " daily histogram of propensity scores. Sudden compression or shift signals model or feature issue"),
                    tags$li(tags$b("Feature null rates:"), " sudden increase in null features = upstream pipeline breakage"),
                    tags$li(tags$b("Calibration:"), " weekly check: does model's 0.3 score still mean 30% conversion?"),
                    tags$li(tags$b("Sliced performance:"), " AUC by ACORN segment, age band, digital engagement tier")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Business Metrics"),
                  tags$ul(
                    tags$li(tags$b("Daily:"), " CTR by channel, conversion rate by product"),
                    tags$li(tags$b("Weekly:"), " churn rate by segment vs forecast"),
                    tags$li(tags$b("Monthly:"), " revenue uplift vs control cohort"),
                    tags$li(tags$b("Quarterly:"), " fairness audit: equal offer rates by FCA-protected characteristics")
                  ),
                  div(class="warn-box", HTML("<strong>Huyen's silent degradation:</strong> business metrics can look stable while model quality deteriorates — if campaign volume drops (fewer eligible customers), CTR may rise even though model is worse."))
                )
              )
            )
          ),

          csPanel("cs5-drift",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Covariate Shift Detected: COVID-19 Example"),
                  tags$p("In March 2020, banking ML models experienced severe covariate shift:"),
                  tags$ul(
                    tags$li("ATM usage dropped 70% overnight → ATM frequency features near-zero for all customers"),
                    tags$li("Digital session frequency spiked 3× → features out of training range"),
                    tags$li("Transaction patterns changed radically (no travel, hospitality spend)"),
                    tags$li(tags$b("PSI on 'atm_visits_30d': 0.89 → immediate retrain trigger"))
                  ),
                  tags$p(tags$b("Response:"), " emergency retraining with 90-day lookback window. Models retrained within 72 hours. PEGA rules-based fallback used during retraining."),
                  div(class="success-box", HTML("<strong>Lesson:</strong> Always maintain a rules-based fallback. ML models cannot retrain faster than the world can change."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Drift Detection Implementation"),
                  tags$p(tags$b("Feature monitoring (daily):"), " PSI computed for all features vs trailing 90-day baseline:"),
                  tags$ul(
                    tags$li("PSI < 0.10: stable, no action"),
                    tags$li("PSI 0.10-0.20: alert to ML team, investigate"),
                    tags$li("PSI > 0.20: automatic retraining trigger")
                  ),
                  tags$p(tags$b("Output distribution (daily):"), " propensity score histogram vs baseline. KS test p < 0.01 triggers alert."),
                  tags$p(tags$b("Calibration check (weekly):"), " bin customers by predicted score, compare predicted rate vs observed rate. Isotonic recalibration if deviation > 15%."),
                  tags$p(tags$b("Tooling:"), " Evidently AI for drift reports; custom BigQuery SQL for PSI; Vertex AI Model Monitoring for online drift detection.")
                )
              )
            )
          ),

          csPanel("cs5-infra",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("GCP ML Platform Stack (Ch.10)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Layer"),tags$th("Component"),tags$th("GCP Service"))),
                    tags$tbody(
                      tags$tr(tags$td("Storage"),       tags$td("Raw data lake"),          tags$td("Google Cloud Storage (Parquet)")),
                      tags$tr(tags$td("Warehouse"),     tags$td("Features + training data"),tags$td("BigQuery")),
                      tags$tr(tags$td("Feature Store"), tags$td("Offline + online serving"),tags$td("Vertex AI Feature Store")),
                      tags$tr(tags$td("Training"),      tags$td("Distributed ML training"), tags$td("Vertex AI Training (A100 GPUs)")),
                      tags$tr(tags$td("HPO"),           tags$td("Bayesian optimisation"),   tags$td("Vertex AI Vizier")),
                      tags$tr(tags$td("Experiment"),    tags$td("Tracking metrics + artifacts"),tags$td("Vertex AI Experiments")),
                      tags$tr(tags$td("Registry"),      tags$td("Model versioning"),         tags$td("Vertex AI Model Registry")),
                      tags$tr(tags$td("Serving"),       tags$td("Online + batch prediction"),tags$td("Vertex AI Prediction")),
                      tags$tr(tags$td("Orchestration"), tags$td("ML pipeline DAGs"),         tags$td("Vertex AI Pipelines (KFP)")),
                      tags$tr(tags$td("Monitoring"),    tags$td("Drift + performance"),      tags$td("Vertex AI Model Monitoring")),
                      tags$tr(tags$td("Cache"),         tags$td("Pre-computed scores"),      tags$td("Cloud Memorystore (Redis)")  )
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Build vs Buy Decisions (Ch.10)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Component"),tags$th("Decision"),tags$th("Reason"))),
                    tags$tbody(
                      tags$tr(tags$td("Feature store"),     tags$td("Buy (Vertex AI)"),   tags$td("Commodity, GCP-native, fast")),
                      tags$tr(tags$td("Model serving"),     tags$td("Buy (Vertex AI)"),   tags$td("Managed autoscaling, SLA")),
                      tags$tr(tags$td("Data warehouse"),    tags$td("Buy (BigQuery)"),    tags$td("Scale, serverless, SQL")),
                      tags$tr(tags$td("PEGA decisioning"),  tags$td("Buy (PEGA)"),        tags$td("Compliance, auditability")),
                      tags$tr(tags$td("Propensity models"), tags$td("Build"),             tags$td("Core differentiation, data unique")),
                      tags$tr(tags$td("Feature pipelines"), tags$td("Build"),             tags$td("Domain-specific transformations")),
                      tags$tr(tags$td("Monitoring alerts"), tags$td("Build + Buy"),       tags$td("Custom bank-specific thresholds"))
                    )
                  )
                )
              )
            )
          ),

          csPanel("cs5-fairness",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("FCA Fairness Requirements (Ch.11)"),
                  tags$p("The Financial Conduct Authority's 'Consumer Duty' (2023) requires banks to prove ML models treat customers fairly across protected characteristics:"),
                  tags$ul(
                    tags$li(tags$b("Age:"), " propensity scores must not systematically under-target elderly customers for beneficial products"),
                    tags$li(tags$b("Gender:"), " equal offer rates for equivalent financial profiles"),
                    tags$li(tags$b("Disability:"), " vulnerable customer flag — ML must not increase exposure to unsuitable products"),
                    tags$li(tags$b("Ethnicity:"), " CACI's geodemographic data proxies ethnicity through geography — must audit for proxy discrimination")
                  ),
                  div(class="warn-box", HTML("<strong>CACI proxy risk:</strong> ACORN categories correlate with ethnicity in UK cities. Using ACORN for product targeting may constitute indirect discrimination under Equality Act 2010 even if ethnicity is not a model feature."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Fairness Audit Process"),
                  tags$p("Quarterly fairness audit required by Model Risk Management:"),
                  tags$ol(
                    tags$li("Segment customers by FCA-protected characteristics (via KYC data + age band)"),
                    tags$li("Compute offer rate per segment for each product"),
                    tags$li("Compute conversion rate per segment (equal opportunity check)"),
                    tags$li("Check calibration per segment — scores mean the same across groups"),
                    tags$li("Flag any segment with offer rate < 0.5× or > 2× population average"),
                    tags$li("Report to Risk Committee with remediation plan")
                  ),
                  div(class="success-box", HTML("<strong>Explainability for declined offers:</strong> Under GDPR Article 22 and Consumer Duty, customers can request an explanation for automated decisions. SHAP values on individual predictions satisfy this — top 3 features driving the score shown in customer-facing explanation."))
                )
              )
            )
          ),

          csPanel("cs5-privacy",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("GDPR Compliance (Ch.11)"),
                  tags$ul(
                    tags$li(tags$b("Lawful basis:"), " marketing ML runs on legitimate interest (not consent) — customer opted into communications at account opening. CACI enrichment requires Privacy Notice disclosure."),
                    tags$li(tags$b("Data minimisation:"), " only features necessary for the model are included in training. Feature audit required before new features added."),
                    tags$li(tags$b("Right to explanation:"), " any automated decision must be explainable. SHAP values computed per prediction, stored 90 days."),
                    tags$li(tags$b("Right to erasure:"), " if customer requests deletion, must remove from training data. Requires machine unlearning capability or full retraining without that customer."),
                    tags$li(tags$b("Data residency:"), " all customer data processed in GCP europe-west2 (London). No cross-border transfer to US GCP regions.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Model Risk Management (Ch.11 — Human Side)"),
                  tags$p("FCA requires banks to have a formal Model Risk Management (MRM) framework for all ML models used in customer-facing decisions:"),
                  tags$ol(
                    tags$li(tags$b("Model documentation:"), " model card per model: intended use, performance metrics, known limitations, data sources, training date"),
                    tags$li(tags$b("Independent validation:"), " second team validates model before production deployment"),
                    tags$li(tags$b("Champion-challenger:"), " new model must beat champion in controlled A/B test before full rollout"),
                    tags$li(tags$b("Annual review:"), " all production models reviewed annually regardless of performance"),
                    tags$li(tags$b("Audit trail:"), " every prediction logged with model version, features used, score, and decision made by PEGA")
                  ),
                  div(class="tip-box", HTML("<strong>Huyen + FCA alignment:</strong> Huyen's recommendation for shadow deployment, A/B testing, and model registries aligns perfectly with FCA's MRM requirements. The ML lifecycle is simultaneously best practice AND regulatory compliance."))
                )
              )
            )
          )
        )
      )
    ),

    # ── Self-Assessment ────────────────────────────────────────────────────
    fluidRow(
      box(title="📊 Self-Assessment: Banking Case Study",
          status="success", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            sliderInput(ns("sc_cs1"), "Problem framing & metrics",     0,10,5),
            sliderInput(ns("sc_cs2"), "Data pipelines & feature store", 0,10,5),
            sliderInput(ns("sc_cs3"), "Model development & eval",       0,10,5),
            sliderInput(ns("sc_cs4"), "Deployment & continual learning",0,10,5),
            sliderInput(ns("sc_cs5"), "Monitoring & responsible AI",    0,10,5),
            actionButton(ns("save_cs"), "Save Assessment", class="btn-meta", width="100%")
          ),
          column(8, br(), uiOutput(ns("cs_result")))
        )
      )
    )
  )
}

banking_case_study_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_cs, {
      avg <- mean(c(input$sc_cs1, input$sc_cs2, input$sc_cs3, input$sc_cs4, input$sc_cs5))
      pct <- round(avg * 10)
      prep_manager$update_progress("banking_case_study", pct)
      output$cs_result <- renderUI({
        div(class=if(pct>=70)"success-box"else"tip-box",
          tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
          if(pct>=80) tags$p("Strong case study knowledge. You can now walk through a complete end-to-end ML system design for a financial services use case, applying every chapter of Huyen's framework.")
          else tags$p("Review the boxes where you scored lowest. Focus on the data pipeline (Box 2) and deployment architecture (Box 4) — these are most commonly tested in interviews.")
        )
      })
      showNotification(paste0("Case Study: ",pct,"% saved"), type="message")
    })
  })
}
