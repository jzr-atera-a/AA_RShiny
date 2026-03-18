# modules/banking_case_study.R
# Use Case: UK Banking Customers ML — Kravchenko & Babushkin (Manning 2025) Framework
# JS namespace: bkShow(), .bk-btn, .bk-panel

banking_case_study_ui <- function(id) {
  ns <- NS(id)

  js <- "
<script>
function bkShow(boxId, panelId) {
  var box = document.getElementById(boxId);
  if (!box) return;
  box.querySelectorAll('.bk-panel').forEach(function(p){ p.style.display='none'; });
  box.querySelectorAll('.bk-btn').forEach(function(b){ b.classList.remove('active'); });
  var panel = document.getElementById(panelId);
  if (panel) panel.style.display='block';
  event.target.classList.add('active');
}
window.addEventListener('load', function(){
  ['bk-box1','bk-box2','bk-box3','bk-box4','bk-box5','bk-box6','bk-box7'].forEach(function(boxId){
    var box = document.getElementById(boxId);
    if (!box) return;
    var firstBtn = box.querySelector('.bk-btn');
    var firstPanel = box.querySelector('.bk-panel');
    if (firstBtn) firstBtn.classList.add('active');
    if (firstPanel) firstPanel.style.display='block';
  });
});
</script>"

  bkBtn <- function(boxId, panelId, label, active=FALSE) {
    tags$button(
      class=paste("bk-btn", if(active) "active" else ""),
      style="margin:2px 4px 2px 0;padding:5px 12px;border:none;border-radius:4px;cursor:pointer;font-size:12px;background:#1a2332;color:#cdd6e0;transition:all .2s;",
      onclick=paste0("bkShow('",boxId,"','",panelId,"')"),
      label
    )
  }

  bkPanel <- function(panelId, ...) {
    div(id=panelId, class="bk-panel", style="display:none;padding-top:10px;", ...)
  }

  tagList(
    HTML(js),

    # ── Hero ──────────────────────────────────────────────────────────────────
    div(class="meta-hero",
        tags$h1("UK Banking Customers ML"),
        tags$h2("PEGA + GCP + BigQuery + Vertex AI — K&B Manning 2025 Framework"),
        div(span(class="hero-badge","Next-Best-Action"),
            span(class="hero-badge","Propensity Models"),
            span(class="hero-badge","FCA Regulated"),
            span(class="hero-badge","Vertex AI"),
            span(class="hero-badge","Real-Time + Batch"))),

    # ── Architecture Overview ─────────────────────────────────────────────────
    fluidRow(
      box(title="System Architecture", status="primary", solidHeader=TRUE, width=12,
          div(style="overflow-x:auto;",
              HTML(sprintf('
<svg viewBox="0 0 860 210" xmlns="http://www.w3.org/2000/svg" style="width:100%%;max-width:860px;font-family:Inter,sans-serif;">
  <defs>
    <marker id="bk-arr" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#e8410a"/>
    </marker>
  </defs>
  <!-- Data Sources -->
  <rect x="10" y="10" width="120" height="22" rx="4" fill="#1a2332" stroke="#e8410a" stroke-width="1.2"/>
  <text x="70" y="25" text-anchor="middle" fill="#cdd6e0" font-size="9">Bank Transactions</text>
  <rect x="140" y="10" width="120" height="22" rx="4" fill="#1a2332" stroke="#e8410a" stroke-width="1.2"/>
  <text x="200" y="25" text-anchor="middle" fill="#cdd6e0" font-size="9">Digital Behaviour (Kafka)</text>
  <rect x="270" y="10" width="100" height="22" rx="4" fill="#1a2332" stroke="#e8410a" stroke-width="1.2"/>
  <text x="320" y="25" text-anchor="middle" fill="#cdd6e0" font-size="9">ATM Events</text>
  <rect x="380" y="10" width="120" height="22" rx="4" fill="#1a2332" stroke="#374151" stroke-width="1.2"/>
  <text x="440" y="25" text-anchor="middle" fill="#cdd6e0" font-size="9">CACI ACORN Demographics</text>
  <rect x="510" y="10" width="120" height="22" rx="4" fill="#1a2332" stroke="#374151" stroke-width="1.2"/>
  <text x="570" y="25" text-anchor="middle" fill="#cdd6e0" font-size="9">Contact History (PEGA)</text>
  <!-- Arrow to BigQuery -->
  <line x1="70" y1="32" x2="200" y2="62" stroke="#e8410a" stroke-width="1.2" marker-end="url(#bk-arr)"/>
  <line x1="200" y1="32" x2="240" y2="62" stroke="#e8410a" stroke-width="1.2" marker-end="url(#bk-arr)"/>
  <line x1="320" y1="32" x2="280" y2="62" stroke="#e8410a" stroke-width="1.2" marker-end="url(#bk-arr)"/>
  <line x1="440" y1="32" x2="320" y2="62" stroke="#6b7280" stroke-width="1.2" marker-end="url(#bk-arr)"/>
  <line x1="570" y1="32" x2="360" y2="62" stroke="#6b7280" stroke-width="1.2" marker-end="url(#bk-arr)"/>
  <!-- BigQuery -->
  <rect x="160" y="62" width="200" height="30" rx="6" fill="#0f2444" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="260" y="81" text-anchor="middle" fill="#93c5fd" font-size="10" font-weight="bold">BigQuery Data Warehouse</text>
  <!-- Feature Store -->
  <line x1="260" y1="92" x2="260" y2="110" stroke="#e8410a" stroke-width="1.5" marker-end="url(#bk-arr)"/>
  <rect x="160" y="110" width="200" height="28" rx="6" fill="#1a2332" stroke="#10b981" stroke-width="1.5"/>
  <text x="260" y="128" text-anchor="middle" fill="#6ee7b7" font-size="10" font-weight="bold">Vertex AI Feature Store</text>
  <!-- Models -->
  <line x1="260" y1="138" x2="260" y2="155" stroke="#e8410a" stroke-width="1.5" marker-end="url(#bk-arr)"/>
  <rect x="30" y="155" width="110" height="28" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.2"/>
  <text x="85" y="173" text-anchor="middle" fill="#fcd34d" font-size="9">Propensity Models</text>
  <rect x="155" y="155" width="100" height="28" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.2"/>
  <text x="205" y="173" text-anchor="middle" fill="#fcd34d" font-size="9">Churn Models</text>
  <rect x="270" y="155" width="100" height="28" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.2"/>
  <text x="320" y="173" text-anchor="middle" fill="#fcd34d" font-size="9">Channel Models</text>
  <rect x="385" y="155" width="100" height="28" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.2"/>
  <text x="435" y="173" text-anchor="middle" fill="#fcd34d" font-size="9">Send-Time Optimiser</text>
  <!-- PEGA -->
  <line x1="205" y1="183" x2="580" y2="183" stroke="#e8410a" stroke-width="1.5" marker-end="url(#bk-arr)"/>
  <rect x="580" y="155" width="160" height="56" rx="6" fill="#0f2444" stroke="#e8410a" stroke-width="2"/>
  <text x="660" y="175" text-anchor="middle" fill="#fca5a5" font-size="10" font-weight="bold">PEGA Next-Best-Action</text>
  <text x="660" y="190" text-anchor="middle" fill="#9ca3af" font-size="8">Eligibility + Contact Policy</text>
  <text x="660" y="202" text-anchor="middle" fill="#9ca3af" font-size="8">Arbitration + Single Action</text>
  <!-- Channels -->
  <line x1="740" y1="175" x2="810" y2="130" stroke="#6b7280" stroke-width="1" marker-end="url(#bk-arr)"/>
  <text x="820" y="108" fill="#d1d5db" font-size="8">Push</text>
  <text x="820" y="122" fill="#d1d5db" font-size="8">Email</text>
  <text x="820" y="136" fill="#d1d5db" font-size="8">SMS</text>
  <text x="820" y="150" fill="#d1d5db" font-size="8">ATM</text>
  <text x="820" y="164" fill="#d1d5db" font-size="8">In-App</text>
  <!-- Feedback loop -->
  <path d="M 660 211 Q 660 230 400 230 Q 140 230 140 92" stroke="#374151" stroke-width="1" fill="none" stroke-dasharray="4,3" marker-end="url(#bk-arr)"/>
  <text x="400" y="245" text-anchor="middle" fill="#6b7280" font-size="8">Feedback Loop (click/conversion signals)</text>
</svg>'
              ))
          )
      )
    ),

    # ── Box 1: Ch.1–2 Requirements ────────────────────────────────────────────
    fluidRow(
      box(title="Box 1 — Ch.1–2: Requirements & System Scoping (K&B)", status="primary", solidHeader=TRUE, width=12,
          id="bk-box1",
          div(bkBtn("bk-box1","bk1p1","K&B 6-Step Loop",TRUE),
              bkBtn("bk-box1","bk1p2","ML Task Decomposition"),
              bkBtn("bk-box1","bk1p3","SLOs & Constraints"),
              bkBtn("bk-box1","bk1p4","Stakeholder Map")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          bkPanel("bk1p1",
                  div(class="success-box", HTML("<strong>K&B Principle (Ch.1):</strong> Every ML design starts with translating business language into a precise ML specification using the 6-step loop. For banking, the business goal is <em>'deliver the right message via the right channel at the right time'</em> — K&B insist this must be decomposed before touching any data.")),
                  fluidRow(
                    column(6,
                           div(class="framework-card",
                               tags$h5("K&B 6-Step Loop Applied to Banking"),
                               tags$p(tags$b("1. Clarify requirements:"), " Business goal = maximise customer lifetime value across 6 channels. Constraints: FCA TCF, GDPR, PEGA contact caps."),
                               tags$p(tags$b("2. Data pipeline:"), " Nightly batch (core banking) + Kafka streaming (digital) + CACI external (weekly refresh)."),
                               tags$p(tags$b("3. Feature engineering:"), " Temporal spend patterns, ACORN lifestyle categories, channel engagement history, contact recency."),
                               tags$p(tags$b("4. Model architecture:"), " One XGBoost per product (propensity), one churn model, one channel model, Thompson Sampling for send-time."),
                               tags$p(tags$b("5. Evaluation:"), " Offline: PR-AUC (churn), AUC-ROC + Lift@10% (propensity). Online: CTR, conversion rate, opt-out guardrail."),
                               tags$p(tags$b("6. Serving & monitoring:"), " Batch scores daily (push/email/SMS), real-time re-scoring for ATM/in-app events; PSI drift monitoring monthly.")
                           )
                    ),
                    column(6,
                           div(class="warn-box", HTML("<strong>K&B Warning (Ch.1):</strong> Do NOT jump to model selection. Spend 20% of interview time on requirements. 'What does success look like in business terms?' is always the first question.")),
                           div(class="tip-box",
                               tags$h6("Business → ML Translation"),
                               tags$table(class="table table-sm",
                                 tags$thead(tags$tr(tags$th("Business Goal"), tags$th("ML Task"), tags$th("Metric"))),
                                 tags$tbody(
                                   tags$tr(tags$td("Product uptake"), tags$td("Binary classification"), tags$td("AUC-ROC, Lift@10%")),
                                   tags$tr(tags$td("Reduce churn"), tags$td("Binary classification"), tags$td("PR-AUC")),
                                   tags$tr(tags$td("Best channel"), tags$td("Multi-class (5-way)"), tags$td("Top-1 Accuracy")),
                                   tags$tr(tags$td("Right send time"), tags$td("Contextual bandit"), tags$td("Click Lift")),
                                   tags$tr(tags$td("Best action ranking"), tags$td("Ranking (PEGA arbitration)"), tags$td("NDCG@3"))
                                 )
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk1p2",
                  div(class="section-heading-dark", "K&B ML Task Type Analysis — One Model per Problem"),
                  fluidRow(
                    column(4,
                           div(class="framework-card",
                               tags$h5("Propensity Models (Per-Product)"),
                               tags$p("K&B recommend separate binary classifiers per product, not multiclass. Why?"),
                               tags$ul(tags$li("Avoids class imbalance across unrelated products"), tags$li("Allows independent threshold tuning per product risk"), tags$li("Easier regulatory approval (one model = one MRM review)"), tags$li("Failure isolation: ISA model drift doesn't affect mortgage model"))
                           )
                    ),
                    column(4,
                           div(class="framework-card",
                               tags$h5("Channel Selection — Multi-Class"),
                               tags$p("5-class classification: push / email / SMS / ATM / in-app."),
                               tags$ul(tags$li("Input: customer features + eligible actions"), tags$li("Output: channel probability vector"), tags$li("PEGA overrides with contact cap policy on top"), tags$li("K&B pattern: ML scores → business rules → final decision"))
                           )
                    ),
                    column(4,
                           div(class="framework-card",
                               tags$h5("Send-Time — Contextual Bandit"),
                               tags$p("Each hour slot (6am-10pm) is an arm. Customer context is state."),
                               tags$ul(tags$li("Epsilon-greedy → Thompson Sampling (more Bayesian)"), tags$li("Reward: click within 4-hour window"), tags$li("Cold start for new customers: prior from segment"), tags$li("K&B: bandits beat static send-time rules by 15-30%"))
                           )
                    )
                  )
          ),

          bkPanel("bk1p3",
                  div(class="section-heading-dark", "Non-Functional Requirements & SLOs (K&B Ch.2)"),
                  fluidRow(
                    column(6,
                           tags$table(class="table table-hover",
                             tags$thead(tags$tr(tags$th("Channel"), tags$th("Mode"), tags$th("p50 SLO"), tags$th("p99 SLO"), tags$th("Serving Pattern"))),
                             tags$tbody(
                               tags$tr(tags$td("In-App message"), tags$td("Online"), tags$td("80ms"), tags$td("200ms"), tags$td("Real-time Vertex")),
                               tags$tr(tags$td("ATM screen"), tags$td("Online"), tags$td("200ms"), tags$td("500ms"), tags$td("Real-time Vertex")),
                               tags$tr(tags$td("Push notification"), tags$td("Batch"), tags$td("N/A"), tags$td("<2s trigger"), tags$td("Pre-computed daily")),
                               tags$tr(tags$td("Email"), tags$td("Batch"), tags$td("N/A"), tags$td("<5min"), tags$td("Pre-computed daily")),
                               tags$tr(tags$td("SMS"), tags$td("Batch"), tags$td("N/A"), tags$td("<5min"), tags$td("Pre-computed daily")),
                               tags$tr(tags$td("Website prompt"), tags$td("Online"), tags$td("100ms"), tags$td("300ms"), tags$td("Real-time Vertex"))
                             )
                           )
                    ),
                    column(6,
                           div(class="warn-box", HTML("<strong>Regulatory Constraints (K&B Ch.2 — Constraint Taxonomy):</strong>")),
                           tags$ul(
                             tags$li(tags$b("FCA TCF:"), " Cannot target vulnerable customers with unsuitable products. Model output must feed eligibility filter in PEGA before arbitration."),
                             tags$li(tags$b("GDPR Art.22:"), " Automated decision-making disclosure required. Customers can request human review."),
                             tags$li(tags$b("CACI Data:"), " Geodemographic enrichment requires Privacy Notice update. Household-level data joined to individual records."),
                             tags$li(tags$b("MRM:"), " Model Risk Management validation required pre-production. Each model requires challenger vs champion documentation."),
                             tags$li(tags$b("Contact caps:"), " PEGA enforces max contacts per day/channel. ML cannot override — post-filter only.")
                           )
                    )
                  )
          ),

          bkPanel("bk1p4",
                  div(class="section-heading-dark", "Stakeholder Map & System Interfaces"),
                  fluidRow(
                    column(5,
                           tags$table(class="table table-sm",
                             tags$thead(tags$tr(tags$th("Stakeholder"), tags$th("Role"), tags$th("ML Interface"))),
                             tags$tbody(
                               tags$tr(tags$td("Marketing"), tags$td("Business owner"), tags$td("Campaign targeting lists")),
                               tags$tr(tags$td("Risk & Compliance"), tags$td("FCA gate"), tags$td("Model cards, fairness reports")),
                               tags$tr(tags$td("Data Science"), tags$td("Model owners"), tags$td("Vertex AI, BigQuery")),
                               tags$tr(tags$td("ML Ops"), tags$td("Production ops"), tags$td("Monitoring dashboards")),
                               tags$tr(tags$td("PEGA Admins"), tags$td("Decisioning config"), tags$td("Score API, contact policies")),
                               tags$tr(tags$td("Customers"), tags$td("End users"), tags$td("Channel experiences"))
                             )
                           )
                    ),
                    column(7,
                           div(class="tip-box", HTML("<strong>K&B Key Pattern:</strong> ML provides <em>scores</em>. PEGA provides <em>decisions</em>. The boundary is critical: ML is not aware of PEGA's contact caps or eligibility rules. PEGA is not aware of how scores were computed. This separation of concerns is intentional — it allows each system to evolve independently.")),
                           div(class="framework-card",
                               tags$h5("Integration Contract"),
                               tags$p("Vertex AI exposes REST endpoint → PEGA calls with customer ID → Returns JSON: {customer_id, product_id, propensity_score, channel_scores, churn_risk, send_time_scores}"),
                               tags$p("PEGA applies: eligibility filter → contact cap check → suitability (FCA) → arbitration → single best action")
                           )
                    )
                  )
          )
      )
    ),

    # ── Box 2: Ch.3 Data Pipeline ─────────────────────────────────────────────
    fluidRow(
      box(title="Box 2 — Ch.3: Data Pipeline Design (K&B)", status="warning", solidHeader=TRUE, width=12,
          id="bk-box2",
          div(bkBtn("bk-box2","bk2p1","Data Sources & Ingestion",TRUE),
              bkBtn("bk-box2","bk2p2","Batch vs Streaming"),
              bkBtn("bk-box2","bk2p3","Data Quality & Schema"),
              bkBtn("bk-box2","bk2p4","Pipeline Architecture SVG")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          bkPanel("bk2p1",
                  fluidRow(
                    column(6,
                           div(class="section-heading-dark", "Internal Data Sources"),
                           tags$table(class="table table-sm",
                             tags$thead(tags$tr(tags$th("Source"), tags$th("Frequency"), tags$th("Volume"), tags$th("Format"))),
                             tags$tbody(
                               tags$tr(tags$td("Core banking (Oracle)"), tags$td("Nightly batch"), tags$td("~2M records/day"), tags$td("Parquet → BigQuery")),
                               tags$tr(tags$td("Digital banking (web/app)"), tags$td("Kafka streaming"), tags$td("~50M events/day"), tags$td("Avro → GCS → BQ")),
                               tags$tr(tags$td("ATM events"), tags$td("Near real-time"), tags$td("~500k/day"), tags$td("JSON → Pub/Sub")),
                               tags$tr(tags$td("Contact history (PEGA)"), tags$td("Daily sync"), tags$td("~1M actions/day"), tags$td("CSV → BigQuery")),
                               tags$tr(tags$td("Call centre NLP"), tags$td("Daily batch"), tags$td("~100k calls/day"), tags$td("Audio → text → BQ"))
                             )
                           )
                    ),
                    column(6,
                           div(class="section-heading-dark", "External Data — CACI ACORN"),
                           div(class="framework-card",
                               tags$h5("CACI Geodemographic Enrichment"),
                               tags$p("CACI ACORN classifies UK households into 62 lifestyle categories, 6 categories, 18 groups."),
                               tags$ul(
                                 tags$li("Joined to customer records via privacy-safe postcode + DOB hash"),
                                 tags$li(tags$b("Aggregation bias:"), " Household-level data applied to individual — single person in student house may inherit 'family' profile"),
                                 tags$li(tags$b("Vintage mismatch:"), " CACI refreshed annually; model trained on June data may serve on December data with shifted demographics"),
                                 tags$li(tags$b("GDPR requirement:"), " Privacy Notice must disclose use of third-party enrichment data")
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk2p2",
                  div(class="section-heading-dark", "K&B Batch vs Streaming Decision Framework"),
                  fluidRow(
                    column(4,
                           div(class="framework-card", style="border-left:3px solid #3b82f6;",
                               tags$h5("\U0001F7E6 Batch Pipeline (Most Features)"),
                               tags$p("Nightly BigQuery job computes all propensity, churn, and channel scores for 10M eligible customers."),
                               tags$ul(
                                 tags$li("Spark SQL on Dataproc for feature computation"),
                                 tags$li("Scores written to BigQuery → synced to PEGA daily"),
                                 tags$li(tags$b("Freshness:"), " 24 hours — acceptable for email/SMS/push"),
                                 tags$li(tags$b("Cost:"), " ~$200/day on GCP Dataproc")
                               ),
                               div(class="success-box", tags$small("K&B: Batch is always cheaper and simpler. Only add streaming when freshness requirement genuinely demands it."))
                           )
                    ),
                    column(4,
                           div(class="framework-card", style="border-left:3px solid #10b981;",
                               tags$h5("\U0001F7E2 Streaming Pipeline (ATM/In-App)"),
                               tags$p("Kafka consumer processes digital events in near real-time; triggers real-time Vertex inference for in-app and ATM channels."),
                               tags$ul(
                                 tags$li("Kafka → Cloud Dataflow (Beam) → Pub/Sub → Vertex Endpoint"),
                                 tags$li("Event: customer opens app → trigger propensity + channel inference"),
                                 tags$li(tags$b("Freshness:"), " <1 second for in-app re-scoring"),
                                 tags$li(tags$b("Cost:"), " ~$2,000/month for Dataflow always-on")
                               ),
                               div(class="warn-box", tags$small("K&B: Streaming introduces at-least-once vs exactly-once semantics. Use idempotent writes to BigQuery."))
                           )
                    ),
                    column(4,
                           div(class="framework-card", style="border-left:3px solid #f59e0b;",
                               tags$h5("\U0001F7E1 Lambda Architecture Hybrid"),
                               tags$p("Batch layer: historical features. Speed layer: session-level events (last 30 min of in-app behaviour)."),
                               tags$ul(
                                 tags$li("Batch features served from Vertex Feature Store (offline store)"),
                                 tags$li("Session features computed on-the-fly from Kafka stream"),
                                 tags$li("Merged at inference time: model sees both stable history + fresh session signals"),
                                 tags$li(tags$b("K&B warning:"), " Train/serve skew risk at merge point")
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk2p3",
                  div(class="section-heading-dark", "Data Quality — K&B Production Concerns (Ch.3)"),
                  fluidRow(
                    column(6,
                           div(class="framework-card",
                               tags$h5("Schema Evolution"),
                               tags$ul(
                                 tags$li(tags$b("Problem:"), " Core banking schema updated quarterly; new product codes, deprecated fields."),
                                 tags$li(tags$b("Solution:"), " BigQuery schema with NULLABLE evolution mode. Avro schema registry for Kafka topics."),
                                 tags$li(tags$b("K&B pattern:"), " Data contracts between producing and consuming teams. Breaking changes require 30-day notice."),
                                 tags$li(tags$b("Audit trail:"), " Delta/Iceberg time-travel for FCA audit requirements. Can reconstruct any feature value at any past date.")
                               )
                           ),
                           div(class="framework-card",
                               tags$h5("Label Quality"),
                               tags$ul(
                                 tags$li(tags$b("Label delay:"), " Conversions measured 30 days post-contact. Model trained on June data won't know June conversion outcomes until July."),
                                 tags$li(tags$b("Implicit feedback:"), " Click = weak positive. Purchase = strong positive. No click = censored (not necessarily negative)."),
                                 tags$li(tags$b("PEGA contamination:"), " Contact history labels reflect PEGA's existing rules, not random assignment. Position bias in historical data.")
                               )
                           )
                    ),
                    column(6,
                           div(class="warn-box", HTML("<strong>K&B Data Quality Checklist (Ch.3):</strong>")),
                           tags$ul(
                             tags$li("\u2705 Null rates monitored per feature per day"),
                             tags$li("\u2705 Distribution shift (PSI) computed weekly"),
                             tags$li("\u2705 Schema version tracked in metadata table"),
                             tags$li("\u274c CACI vintage tracking — not yet implemented"),
                             tags$li("\u274c Label delay adjustment — assumed 30-day fixed window"),
                             tags$li("\u274c Position bias correction — not yet applied")
                           ),
                           div(class="tip-box",
                               tags$h6("Exactly-Once Semantics in Banking"),
                               tags$p("Critical for financial data. A customer score written twice = double contact. BigQuery deduplication via INSERT ... SELECT ... WHERE NOT EXISTS on contact_id PK. Kafka consumer commits offset only after successful BigQuery write.")
                           )
                    )
                  )
          ),

          bkPanel("bk2p4",
                  div(style="overflow-x:auto;",
                      HTML(sprintf('
<svg viewBox="0 0 800 280" xmlns="http://www.w3.org/2000/svg" style="width:100%%;font-family:Inter,sans-serif;">
  <text x="400" y="20" text-anchor="middle" fill="#e8410a" font-size="13" font-weight="bold">Banking ML Data Pipeline — K&B Ch.3 Architecture</text>
  <!-- Batch path -->
  <rect x="20" y="40" width="130" height="35" rx="5" fill="#1a2332" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="85" y="60" text-anchor="middle" fill="#93c5fd" font-size="10">Core Banking (Oracle)</text>
  <text x="85" y="72" text-anchor="middle" fill="#6b7280" font-size="8">Nightly Batch Export</text>
  <line x1="150" y1="57" x2="200" y2="57" stroke="#3b82f6" stroke-width="1.5" marker-end="url(#bk-arr)"/>
  <rect x="200" y="40" width="110" height="35" rx="5" fill="#0f2444" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="255" y="60" text-anchor="middle" fill="#93c5fd" font-size="10">GCS (Parquet)</text>
  <text x="255" y="72" text-anchor="middle" fill="#6b7280" font-size="8">Raw Zone</text>
  <line x1="310" y1="57" x2="360" y2="57" stroke="#3b82f6" stroke-width="1.5" marker-end="url(#bk-arr)"/>

  <!-- Streaming path -->
  <rect x="20" y="100" width="130" height="35" rx="5" fill="#1a2332" stroke="#10b981" stroke-width="1.5"/>
  <text x="85" y="120" text-anchor="middle" fill="#6ee7b7" font-size="10">Digital Banking Events</text>
  <text x="85" y="132" text-anchor="middle" fill="#6b7280" font-size="8">Kafka (Avro)</text>
  <line x1="150" y1="117" x2="200" y2="117" stroke="#10b981" stroke-width="1.5" marker-end="url(#bk-arr)"/>
  <rect x="200" y="100" width="110" height="35" rx="5" fill="#0f2444" stroke="#10b981" stroke-width="1.5"/>
  <text x="255" y="120" text-anchor="middle" fill="#6ee7b7" font-size="10">Cloud Dataflow</text>
  <text x="255" y="132" text-anchor="middle" fill="#6b7280" font-size="8">Beam Streaming</text>
  <line x1="310" y1="117" x2="360" y2="117" stroke="#10b981" stroke-width="1.5" marker-end="url(#bk-arr)"/>

  <!-- External path -->
  <rect x="20" y="160" width="130" height="35" rx="5" fill="#1a2332" stroke="#6b7280" stroke-width="1.5"/>
  <text x="85" y="180" text-anchor="middle" fill="#d1d5db" font-size="10">CACI ACORN</text>
  <text x="85" y="192" text-anchor="middle" fill="#6b7280" font-size="8">Weekly Refresh (CSV)</text>
  <line x1="150" y1="177" x2="360" y2="100" stroke="#6b7280" stroke-width="1" stroke-dasharray="5,3" marker-end="url(#bk-arr)"/>

  <!-- BigQuery -->
  <rect x="360" y="60" width="140" height="110" rx="6" fill="#0c1f3a" stroke="#e8410a" stroke-width="2"/>
  <text x="430" y="85" text-anchor="middle" fill="#fca5a5" font-size="11" font-weight="bold">BigQuery</text>
  <text x="430" y="100" text-anchor="middle" fill="#9ca3af" font-size="8">raw.transactions</text>
  <text x="430" y="113" text-anchor="middle" fill="#9ca3af" font-size="8">raw.events</text>
  <text x="430" y="126" text-anchor="middle" fill="#9ca3af" font-size="8">enriched.caci_acorn</text>
  <text x="430" y="139" text-anchor="middle" fill="#9ca3af" font-size="8">features.customer_daily</text>
  <text x="430" y="152" text-anchor="middle" fill="#9ca3af" font-size="8">scores.propensity_daily</text>

  <!-- Feature Store -->
  <line x1="500" y1="115" x2="560" y2="115" stroke="#e8410a" stroke-width="1.5" marker-end="url(#bk-arr)"/>
  <rect x="560" y="60" width="140" height="110" rx="6" fill="#0f2444" stroke="#10b981" stroke-width="2"/>
  <text x="630" y="85" text-anchor="middle" fill="#6ee7b7" font-size="11" font-weight="bold">Vertex Feature Store</text>
  <text x="630" y="100" text-anchor="middle" fill="#9ca3af" font-size="8">Offline: Parquet snapshots</text>
  <text x="630" y="113" text-anchor="middle" fill="#9ca3af" font-size="8">Online: Bigtable (low-lat)</text>
  <text x="630" y="126" text-anchor="middle" fill="#9ca3af" font-size="8">Point-in-time joins</text>
  <text x="630" y="139" text-anchor="middle" fill="#9ca3af" font-size="8">~500 features per customer</text>

  <!-- Training + Serving -->
  <line x1="630" y1="170" x2="630" y2="210" stroke="#e8410a" stroke-width="1.5" marker-end="url(#bk-arr)"/>
  <rect x="550" y="210" width="160" height="30" rx="5" fill="#1a2332" stroke="#f59e0b" stroke-width="1.5"/>
  <text x="630" y="229" text-anchor="middle" fill="#fcd34d" font-size="10">Vertex AI Training + Endpoint</text>

  <!-- Data quality monitoring -->
  <rect x="360" y="215" width="140" height="30" rx="5" fill="#1a2332" stroke="#374151" stroke-width="1"/>
  <text x="430" y="230" text-anchor="middle" fill="#6b7280" font-size="9">Data Quality Monitoring</text>
  <text x="430" y="242" text-anchor="middle" fill="#6b7280" font-size="8">PSI + null rates + schema checks</text>
  <line x1="430" y1="170" x2="430" y2="215" stroke="#374151" stroke-width="1" stroke-dasharray="4,3"/>
</svg>'
                      ))
                  )
          )
      )
    ),

    # ── Box 3: Ch.4 Feature Engineering ──────────────────────────────────────
    fluidRow(
      box(title="Box 3 — Ch.4: Feature Engineering & Feature Store (K&B)", status="success", solidHeader=TRUE, width=12,
          id="bk-box3",
          div(bkBtn("bk-box3","bk3p1","Feature Categories",TRUE),
              bkBtn("bk-box3","bk3p2","Offline/Online Store"),
              bkBtn("bk-box3","bk3p3","Train-Serve Skew"),
              bkBtn("bk-box3","bk3p4","Feature Importance")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          bkPanel("bk3p1",
                  div(class="section-heading-dark", "Feature Taxonomy for Banking ML (K&B Ch.4 Framework)"),
                  fluidRow(
                    column(3, div(class="framework-card",
                        tags$h5("\U0001F4B3 Transactional Features"),
                        tags$p("Computed over rolling windows (7/30/90d):"),
                        tags$ul(tags$li("Total spend by category (MCC)"), tags$li("Transaction count/value"), tags$li("ATM withdrawal frequency"), tags$li("International transaction ratio"), tags$li("Balance volatility (std dev)"), tags$li("Overdraft usage days"))
                    )),
                    column(3, div(class="framework-card",
                        tags$h5("\U0001F4F1 Digital Engagement Features"),
                        tags$p("Session-level + aggregated:"),
                        tags$ul(tags$li("App sessions per week"), tags$li("Feature adoption (e.g., savings goals used)"), tags$li("Push notification CTR (14d)"), tags$li("Email open rate (30d)"), tags$li("In-app journey completion"), tags$li("Last login recency (days)"))
                    )),
                    column(3, div(class="framework-card",
                        tags$h5("\U0001F3D8 CACI ACORN Features"),
                        tags$p("External geodemographic enrichment:"),
                        tags$ul(tags$li("ACORN category (1-62)"), tags$li("Household income band"), tags$li("Life stage (student/family/retired)"), tags$li("Urban/rural/suburban"), tags$li("Property ownership proxy"), tags$li("Financial resilience score"))
                    )),
                    column(3, div(class="framework-card",
                        tags$h5("\U0001F4DE Contact History Features"),
                        tags$p("PEGA-sourced interaction history:"),
                        tags$ul(tags$li("Days since last contact per channel"), tags$li("Contact count by product (90d)"), tags$li("Opt-out flags per channel"), tags$li("Response rate per offer type"), tags$li("Churn risk score (current)"), tags$li("MRC (Most Recent Channel)"))
                    ))
                  )
          ),

          bkPanel("bk3p2",
                  div(class="section-heading-dark", "Offline vs Online Feature Store — K&B Pattern"),
                  fluidRow(
                    column(6,
                           div(class="framework-card", style="border-left:3px solid #3b82f6;",
                               tags$h5("Offline Store — Vertex AI Feature Store"),
                               tags$p("Purpose: Training data generation with point-in-time joins."),
                               tags$ul(
                                 tags$li(tags$b("Storage:"), " Parquet snapshots in GCS, queryable via BigQuery"),
                                 tags$li(tags$b("Point-in-time join:"), " When training on June 2023 data, use only features available BEFORE June 2023 label date. Prevents data leakage."),
                                 tags$li(tags$b("Backfilling:"), " Recompute historical features when feature logic changes — critical for CACI vintage corrections"),
                                 tags$li(tags$b("Freshness:"), " Daily snapshots — acceptable for batch training")
                               )
                           )
                    ),
                    column(6,
                           div(class="framework-card", style="border-left:3px solid #10b981;",
                               tags$h5("Online Store — Bigtable (Low Latency)"),
                               tags$p("Purpose: Feature serving for real-time inference (ATM, in-app)."),
                               tags$ul(
                                 tags$li(tags$b("Storage:"), " Google Cloud Bigtable — <10ms lookup by customer_id"),
                                 tags$li(tags$b("Populated by:"), " Nightly batch job from BigQuery (stable features) + streaming (session features)"),
                                 tags$li(tags$b("Consistency:"), " K&B critical point — online store may lag offline by up to 1 hour. Accept staleness or implement dual write."),
                                 tags$li(tags$b("Monitoring:"), " Alert if online feature value diverges >2 std dev from offline training distribution")
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk3p3",
                  div(class="warn-box", HTML("<strong>K&B Ch.4 — Train-Serve Skew: The Silent Model Killer.</strong> The model was trained on one distribution of feature values; at serving time, the feature computation logic differs. For banking, this is a critical production risk.")),
                  br(),
                  fluidRow(
                    column(6,
                           div(class="framework-card",
                               tags$h5("Banking Train-Serve Skew Sources"),
                               tags$table(class="table table-sm",
                                 tags$thead(tags$tr(tags$th("Skew Type"), tags$th("Cause"), tags$th("Fix"))),
                                 tags$tbody(
                                   tags$tr(tags$td("CACI vintage mismatch"), tags$td("Model trained on Jun CACI; served with Dec CACI"), tags$td("Pin CACI version at training time; flag vintage in feature metadata")),
                                   tags$tr(tags$td("Window cutoff difference"), tags$td("Train uses 90-day window; serving uses 88-day window due to pipeline latency"), tags$td("Explicit window parameter in feature code; assert at serving time")),
                                   tags$tr(tags$td("Null handling"), tags$td("Train replaces null spend with 0; serving passes null"), tags$td("Centralise imputation logic in feature store, not model pipeline")),
                                   tags$tr(tags$td("PEGA schema change"), tags$td("Contact history column renamed in PEGA sync"), tags$td("Schema validation step in ingestion pipeline; fail fast"))
                                 )
                               )
                           )
                    ),
                    column(6,
                           div(class="success-box", HTML("<strong>K&B Prevention Strategy:</strong>")),
                           tags$ul(
                             tags$li("Store feature computation SQL/code in versioned feature store"),
                             tags$li("Log feature values at serving time → compare to training distribution daily"),
                             tags$li("Run feature consistency checks before each model training run"),
                             tags$li("Shadow serving: compute features two ways, alert on divergence >1%")
                           ),
                           div(class="tip-box",
                               tags$h6("Backfilling After Feature Logic Change"),
                               tags$p("When a feature definition changes (e.g., 90d → 60d window), must backfill entire offline store. With 5 years of history and 10M customers this takes hours. Mitigate with: incremental backfill, feature versioning (v1 / v2 coexist), A/B test models on old vs new features before full cutover.")
                           )
                    )
                  )
          ),

          bkPanel("bk3p4",
                  div(class="section-heading-dark", "Feature Importance — SHAP Analysis (Propensity Model)"),
                  HTML(sprintf('
<svg viewBox="0 0 700 260" xmlns="http://www.w3.org/2000/svg" style="width:100%%;font-family:Inter,sans-serif;">
  <text x="350" y="20" text-anchor="middle" fill="#e8410a" font-size="12" font-weight="bold">Top 15 Features — ISA Propensity Model (SHAP Values)</text>
  <text x="350" y="35" text-anchor="middle" fill="#9ca3af" font-size="9">Beeswarm: point = customer, colour = feature value (red=high, blue=low)</text>
  %s
</svg>',
                    paste(mapply(function(feat, shap, i) {
                      col <- if(i <= 5) "#ef4444" else if(i <= 10) "#f59e0b" else "#6b7280"
                      bw <- round(shap * 400)
                      sprintf('<text x="195" y="%d" text-anchor="end" fill="#d1d5db" font-size="9">%s</text>
<rect x="200" y="%d" width="%d" height="10" rx="2" fill="%s" opacity="0.8"/>
<text x="%d" y="%d" fill="%s" font-size="8">%.3f</text>',
                        45+i*14, feat, 42+i*14, bw, col, 205+bw, 52+i*14, col, shap)
                    },
                    c("savings_balance_change_30d","days_since_isa_inquiry","acorn_income_band",
                      "age_proxy","app_sessions_7d","push_ctr_14d","income_credits_30d",
                      "tax_year_proximity_days","email_open_rate_30d","overdraft_days_90d",
                      "contact_count_90d","atm_withdrawals_30d","digital_login_recency",
                      "caci_life_stage","sms_opt_in"),
                    c(0.42,0.38,0.31,0.28,0.22,0.19,0.17,0.15,0.12,0.10,0.09,0.07,0.06,0.05,0.04),
                    1:15), collapse="\n")
                  ))
          )
      )
    ),

    # ── Box 4: Ch.5 Modelling ─────────────────────────────────────────────────
    fluidRow(
      box(title="Box 4 — Ch.5: Modelling & Training (K&B)", status="info", solidHeader=TRUE, width=12,
          id="bk-box4",
          div(bkBtn("bk-box4","bk4p1","Model Selection",TRUE),
              bkBtn("bk-box4","bk4p2","Training Strategy"),
              bkBtn("bk-box4","bk4p3","Experiment Tracking"),
              bkBtn("bk-box4","bk4p4","HPO & Baselines")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          bkPanel("bk4p1",
                  div(class="section-heading-dark", "K&B Model Selection Framework (Ch.5)"),
                  fluidRow(
                    column(6,
                           tags$table(class="table table-hover",
                             tags$thead(tags$tr(tags$th("Model"), tags$th("Task"), tags$th("Rationale"), tags$th("Chosen?"))),
                             tags$tbody(
                               tags$tr(tags$td("Logistic Regression"), tags$td("Propensity baseline"), tags$td("Interpretable; MRM baseline requirement"), tags$td("\u2705 Baseline")),
                               tags$tr(tags$td("XGBoost"), tags$td("Propensity (per product)"), tags$td("Handles mixed types, class imbalance, non-linear; industry standard for tabular"), tags$td("\u2705 Champion")),
                               tags$tr(tags$td("LightGBM"), tags$td("Propensity challenger"), tags$td("Faster than XGBoost on large data; leaf-wise growth"), tags$td("\u26A0 Challenger")),
                               tags$tr(tags$td("Neural Network"), tags$td("Channel selection"), tags$td("Captures interaction between products + channels; embedding for ACORN"), tags$td("\u274C Explored, not prod")),
                               tags$tr(tags$td("Thompson Sampling"), tags$td("Send-time bandit"), tags$td("Bayesian exploration; naturally handles cold start via prior"), tags$td("\u2705 Production")),
                               tags$tr(tags$td("Two-Tower DNN"), tags$td("NBA ranking"), tags$td("Separate customer + action towers; scalable"), tags$td("\u26A0 Roadmap"))
                             )
                           )
                    ),
                    column(6,
                           div(class="tip-box",
                               tags$h6("K&B Key Insight: One Model Per Product"),
                               tags$p("K&B strongly recommend separate models per prediction task rather than one multi-output model. For banking:"),
                               tags$ul(
                                 tags$li("ISA model trained on ISA converters — gets ISA-specific signals"),
                                 tags$li("Mortgage model needs longer history, different features (LTV, employment stability)"),
                                 tags$li("Independent MRM approval per model — regulatory simplicity"),
                                 tags$li("Different retraining cadences: ISA retrains pre-tax year, mortgage retrains quarterly")
                               )
                           ),
                           div(class="framework-card",
                               tags$h5("Class Imbalance Handling"),
                               tags$p("ISA propensity: ~3% conversion rate (97:3 imbalance). K&B recommendations:"),
                               tags$ul(
                                 tags$li("Adjust", tags$b("scale_pos_weight"), "in XGBoost (= negative_count / positive_count ≈ 32)"),
                                 tags$li("Use PR-AUC as primary metric, not accuracy (accuracy is misleading with imbalance)"),
                                 tags$li("Threshold tuning: choose threshold at F1 maximum or cost-optimal point"),
                                 tags$li("Do NOT oversample with SMOTE — creates synthetic banking transactions that may be unrealistic")
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk4p2",
                  div(class="section-heading-dark", "Training Strategy — K&B Ch.5"),
                  fluidRow(
                    column(6,
                           div(class="framework-card",
                               tags$h5("Temporal Split — Critical for Banking"),
                               tags$p("K&B insist on temporal splits for any time-series-contaminated data:"),
                               tags$ul(
                                 tags$li("Train: Jan 2021 — Jun 2023 (30 months of customer behaviour)"),
                                 tags$li("Validation: Jul 2023 — Sep 2023 (3 months, HPO)"),
                                 tags$li("Test: Oct 2023 — Dec 2023 (3 months, final evaluation)"),
                                 tags$li(tags$b("Never"), " use random split — future labels would contaminate training data")
                               )
                           ),
                           div(class="framework-card",
                               tags$h5("Retraining Cadence"),
                               tags$table(class="table table-sm",
                                 tags$thead(tags$tr(tags$th("Model"), tags$th("Trigger"), tags$th("Cadence"))),
                                 tags$tbody(
                                   tags$tr(tags$td("ISA propensity"), tags$td("Tax year approaching"), tags$td("Quarterly + Jan refresh")),
                                   tags$tr(tags$td("Churn"), tags$td("PSI > 0.2 or monthly"), tags$td("Monthly")),
                                   tags$tr(tags$td("Channel"), tags$td("CTR shift > 10%"), tags$td("Bi-monthly")),
                                   tags$tr(tags$td("Bandit arms"), tags$td("Continuous"), tags$td("Online (Thompson posterior updates)"))
                                 )
                               )
                           )
                    ),
                    column(6,
                           div(class="success-box", HTML("<strong>K&B Distributed Training Note:</strong> For banking, XGBoost on 10M rows x 500 features fits on a single n1-highmem-32 GCP instance (256GB RAM). No distributed training needed. K&B: don't over-engineer — add distributed training only when single-machine training exceeds 4 hours.")),
                           br(),
                           div(class="framework-card",
                               tags$h5("Data Leakage Prevention"),
                               tags$ul(
                                 tags$li("Features computed using", tags$b("data available at prediction time only")),
                                 tags$li("Contact history features: PEGA contacts up to T-1 day only"),
                                 tags$li("Label assignment: conversion flagged at T+30d, feature snapshot at T"),
                                 tags$li("Point-in-time join validation: automated test compares feature store join vs naive join for sample of 1000 rows")
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk4p3",
                  div(class="section-heading-dark", "Experiment Tracking — K&B Ch.5"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Run"), tags$th("Model"), tags$th("Features"), tags$th("AUC-ROC"), tags$th("PR-AUC"), tags$th("Lift@10%"), tags$th("Status"))),
                    tags$tbody(
                      tags$tr(style="color:#6b7280;", tags$td("Exp-01"), tags$td("LR Baseline"), tags$td("50 tabular"), tags$td("0.71"), tags$td("0.18"), tags$td("2.1x"), tags$td("Baseline")),
                      tags$tr(tags$td("Exp-02"), tags$td("XGBoost"), tags$td("50 tabular"), tags$td("0.78"), tags$td("0.24"), tags$td("3.2x"), tags$td("Improved")),
                      tags$tr(tags$td("Exp-03"), tags$td("XGBoost"), tags$td("50 + CACI"), tags$td("0.81"), tags$td("0.28"), tags$td("3.8x"), tags$td("Improved")),
                      tags$tr(tags$td("Exp-04"), tags$td("XGBoost"), tags$td("50 + CACI + contact history"), tags$td("0.84"), tags$td("0.31"), tags$td("4.2x"), tags$td("Improved")),
                      tags$tr(style="background:rgba(16,185,129,0.1);font-weight:bold;",
                        tags$td("Exp-05"), tags$td("XGBoost + Platt"), tags$td("Full 500 features"), tags$td("0.86"), tags$td("0.33"), tags$td("4.5x"), tags$td("\U0001F3C6 Champion"))
                    )
                  ),
                  div(class="tip-box", HTML("<strong>K&B Experiment Tracking Requirements:</strong> Log every run with: data snapshot hash, feature list, hyperparameters, evaluation metrics per slice (not just aggregate), training duration, model artifact path, and the hypothesis being tested. MLflow on Vertex AI Managed MLflow."))
          ),

          bkPanel("bk4p4",
                  div(class="section-heading-dark", "Hyperparameter Optimisation & Baselines"),
                  fluidRow(
                    column(6,
                           div(class="framework-card",
                               tags$h5("K&B Baseline Hierarchy"),
                               tags$ol(
                                 tags$li(tags$b("Constant:"), " Score everyone as 50% propensity (AUC=0.50)"),
                                 tags$li(tags$b("Rules-based:"), " Existing PEGA marketing rules (AUC≈0.60)"),
                                 tags$li(tags$b("LR:"), " Logistic regression on 50 features (AUC≈0.71)"),
                                 tags$li(tags$b("XGBoost simple:"), " Default hyperparams (AUC≈0.78)"),
                                 tags$li(tags$b("XGBoost tuned:"), " Optuna HPO + CACI features (AUC≈0.86)")
                               ),
                               div(class="warn-box", tags$small("K&B: Each step must justify its complexity. If LR achieves 0.71 and XGBoost achieves 0.72, the operational cost of XGBoost is not justified."))
                           )
                    ),
                    column(6,
                           div(class="framework-card",
                               tags$h5("Optuna HPO Results — XGBoost ISA"),
                               tags$table(class="table table-sm",
                                 tags$thead(tags$tr(tags$th("Parameter"), tags$th("Search Space"), tags$th("Best Value"))),
                                 tags$tbody(
                                   tags$tr(tags$td("n_estimators"), tags$td("100–2000"), tags$td("850")),
                                   tags$tr(tags$td("max_depth"), tags$td("3–10"), tags$td("6")),
                                   tags$tr(tags$td("learning_rate"), tags$td("0.005–0.3"), tags$td("0.035")),
                                   tags$tr(tags$td("scale_pos_weight"), tags$td("1–50"), tags$td("28")),
                                   tags$tr(tags$td("subsample"), tags$td("0.5–1.0"), tags$td("0.82")),
                                   tags$tr(tags$td("colsample_bytree"), tags$td("0.5–1.0"), tags$td("0.67")),
                                   tags$tr(tags$td("reg_lambda"), tags$td("0.1–10"), tags$td("2.1"))
                                 )
                               )
                           )
                    )
                  )
          )
      )
    ),

    # ── Box 5: Ch.6 Evaluation ────────────────────────────────────────────────
    fluidRow(
      box(title="Box 5 — Ch.6: Evaluation & Testing (K&B)", status="danger", solidHeader=TRUE, width=12,
          id="bk-box5",
          div(bkBtn("bk-box5","bk5p1","Offline Metrics",TRUE),
              bkBtn("bk-box5","bk5p2","Sliced Evaluation"),
              bkBtn("bk-box5","bk5p3","A/B Test Design"),
              bkBtn("bk-box5","bk5p4","Offline-Online Gap")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          bkPanel("bk5p1",
                  fluidRow(
                    column(6,
                           div(class="section-heading-dark", "Metric Selection — K&B Ch.6"),
                           div(class="tip-box", HTML("<strong>K&B principle:</strong> Choose metrics that reflect the real cost of errors, not just statistical elegance. In banking, a false positive (contacting a customer with a product they don't want) costs a marketing budget. A false negative (missing a ready-to-buy customer) costs revenue.")),
                           tags$table(class="table table-sm",
                             tags$thead(tags$tr(tags$th("Model"), tags$th("Primary Metric"), tags$th("Why Not Accuracy?"))),
                             tags$tbody(
                               tags$tr(tags$td("ISA Propensity"), tags$td("Lift@10% + PR-AUC"), tags$td("3% base rate — accuracy trivially 97% by predicting all negatives")),
                               tags$tr(tags$td("Churn"), tags$td("PR-AUC + F2 score"), tags$td("Recall matters more — missing a churner is worse than a false alarm")),
                               tags$tr(tags$td("Channel"), tags$td("Top-1 Accuracy + Confusion Matrix"), tags$td("5-class balanced — accuracy is meaningful here")),
                               tags$tr(tags$td("Send-Time"), tags$td("Click Lift vs random"), tags$td("Bandit reward signal — not a classification metric")),
                               tags$tr(tags$td("NBA Ranking"), tags$td("NDCG@3"), tags$td("Ranking quality, not binary outcome"))
                             )
                           )
                    ),
                    column(6,
                           div(class="section-heading-dark", "Calibration — Critical for Business Use"),
                           div(class="framework-card",
                               tags$h5("Why Calibration Matters in Banking"),
                               tags$p("PEGA uses propensity scores for arbitration — scores must be", tags$b("calibrated probabilities"), ", not just relative rankings."),
                               tags$ul(
                                 tags$li("Score 0.15 must mean ~15% of customers with this score convert"),
                                 tags$li("Platt scaling applied post-XGBoost training (isotonic regression for large datasets)"),
                                 tags$li("Reliability diagram (calibration curve) included in MRM pack"),
                                 tags$li("FCA: model documentation must show calibration evidence for credit-related products")
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk5p2",
                  div(class="section-heading-dark", "Sliced Evaluation — K&B's Must-Do (Ch.6)"),
                  div(class="warn-box", HTML("<strong>K&B Ch.6 Warning:</strong> Aggregate AUC can look great while performance on a specific regulatory segment (e.g., vulnerable customers) is poor. Sliced evaluation is mandatory for FCA-regulated models.")),
                  br(),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Slice"), tags$th("Segment"), tags$th("AUC-ROC"), tags$th("PR-AUC"), tags$th("Lift@10%"), tags$th("Action"))),
                    tags$tbody(
                      tags$tr(tags$td("Overall"), tags$td("All customers"), tags$td("0.86"), tags$td("0.33"), tags$td("4.5x"), tags$td("\u2705 Champion")),
                      tags$tr(tags$td("Age"), tags$td("18-25 (young)"), tags$td("0.79"), tags$td("0.21"), tags$td("3.1x"), tags$td("\u26A0 Review threshold")),
                      tags$tr(tags$td("Age"), tags$td("65+ (senior)"), tags$td("0.83"), tags$td("0.29"), tags$td("4.0x"), tags$td("\u2705 OK")),
                      tags$tr(tags$td("CACI"), tags$td("ACORN E (student)"), tags$td("0.74"), tags$td("0.19"), tags$td("2.8x"), tags$td("\u26A0 CACI mismatch")),
                      tags$tr(tags$td("FCA"), tags$td("Financially vulnerable"), tags$td("0.77"), tags$td("0.22"), tags$td("3.2x"), tags$td("\u274C Eligibility block")),
                      tags$tr(tags$td("Channel"), tags$td("ATM-only customers"), tags$td("0.81"), tags$td("0.25"), tags$td("3.5x"), tags$td("\u2705 OK")),
                      tags$tr(tags$td("Geography"), tags$td("Rural (<5k pop)"), tags$td("0.80"), tags$td("0.24"), tags$td("3.4x"), tags$td("\u2705 OK")),
                      tags$tr(tags$td("Product"), tags$td("New customers (<90d)"), tags$td("0.68"), tags$td("0.15"), tags$td("2.1x"), tags$td("\u274C Cold start issue"))
                    )
                  )
          ),

          bkPanel("bk5p3",
                  div(class="section-heading-dark", "A/B Test Design — K&B Ch.6"),
                  fluidRow(
                    column(6,
                           div(class="framework-card",
                               tags$h5("Test Design"),
                               tags$ul(
                                 tags$li(tags$b("Randomisation unit:"), " Customer ID (not session) — avoid same customer seeing both arms"),
                                 tags$li(tags$b("Splitting:"), " Hash(customer_id + experiment_id) % 100 for deterministic assignment"),
                                 tags$li(tags$b("Control:"), " PEGA rule-based system (existing production)"),
                                 tags$li(tags$b("Treatment:"), " ML propensity scores fed to PEGA"),
                                 tags$li(tags$b("Duration:"), " Minimum 6 weeks (captures weekly patterns + ISA seasonality)"),
                                 tags$li(tags$b("Sample size:"), " 80% power, alpha=0.05, minimum detectable effect = 5% conversion lift → n=50k per arm")
                               )
                           )
                    ),
                    column(6,
                           div(class="framework-card",
                               tags$h5("Primary + Guardrail Metrics"),
                               tags$table(class="table table-sm",
                                 tags$thead(tags$tr(tags$th("Metric"), tags$th("Type"), tags$th("Result"))),
                                 tags$tbody(
                                   tags$tr(tags$td("Product conversion rate"), tags$td("Primary"), tags$td("+18% (p<0.001)")),
                                   tags$tr(tags$td("Click-through rate"), tags$td("Primary"), tags$td("+2.3x vs rules")),
                                   tags$tr(tags$td("12-month retention"), tags$td("Secondary"), tags$td("+3.1% (p=0.02)")),
                                   tags$tr(tags$td("Opt-out rate"), tags$td("Guardrail"), tags$td("0.4% (under 0.5% SLO \u2705)")),
                                   tags$tr(tags$td("Complaints vol"), tags$td("Guardrail"), tags$td("-8% \u2705"))
                                 )
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk5p4",
                  div(class="warn-box", HTML("<strong>K&B Ch.6 — The Offline-Online Metric Gap:</strong> A model with high offline AUC may not improve online business metrics. K&B document three root causes, all present in this banking system.")),
                  br(),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Gap Source"), tags$th("Description"), tags$th("Banking Example"), tags$th("Mitigation"))),
                    tags$tbody(
                      tags$tr(tags$td("Label proxy mismatch"), tags$td("Offline label ≠ business outcome"), tags$td("Model optimises for click; PEGA delivers impression — click may not lead to conversion"), tags$td("Add conversion (30d) as additional label; train multi-objective")),
                      tags$tr(tags$td("Position bias"), tags$td("Higher-ranked items get more clicks regardless of quality"), tags$td("ISA offer shown first on app → always gets clicks regardless of propensity"), tags$td("Inverse Propensity Scoring (IPS) in offline eval")),
                      tags$tr(tags$td("Feedback loop"), tags$td("Model trained on PEGA historical decisions, not random"), tags$td("PEGA only contacted 'likely responders' historically → training data biased"), tags$td("Exploration budget in PEGA (10% random actions for exploration data")),
                      tags$tr(tags$td("Distribution shift"), tags$td("Test set distribution ≠ serving distribution"), tags$td("ISA model tested on Dec data; served Jan-Mar (ISA season) — different customer cohort"), tags$td("Temporal test set; re-evaluate after Jan deployment"))
                    )
                  )
          )
      )
    ),

    # ── Box 6: Ch.7 Serving ───────────────────────────────────────────────────
    fluidRow(
      box(title="Box 6 — Ch.7: Serving & Deployment (K&B)", status="warning", solidHeader=TRUE, width=12,
          id="bk-box6",
          div(bkBtn("bk-box6","bk6p1","Serving Architecture",TRUE),
              bkBtn("bk-box6","bk6p2","Deployment Strategy"),
              bkBtn("bk-box6","bk6p3","PEGA Integration"),
              bkBtn("bk-box6","bk6p4","Model Compression")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          bkPanel("bk6p1",
                  div(class="section-heading-dark", "Serving Architecture — Batch + Online Hybrid (K&B Ch.7)"),
                  fluidRow(
                    column(6,
                           div(class="framework-card", style="border-left:3px solid #3b82f6;",
                               tags$h5("Batch Serving (Push / Email / SMS / Website)"),
                               tags$p("Daily Vertex AI Batch Prediction job:"),
                               tags$ul(
                                 tags$li("Input: 10M customer feature vectors from BigQuery"),
                                 tags$li("Output: score file → BigQuery → PEGA sync"),
                                 tags$li("SLO: complete by 6:00 AM before channel campaigns begin"),
                                 tags$li("Cost: ~$400/day (n1-highmem-32 x 4 replicas)"),
                                 tags$li("K&B: pre-compute for all likely served users, not just active ones")
                               )
                           )
                    ),
                    column(6,
                           div(class="framework-card", style="border-left:3px solid #10b981;",
                               tags$h5("Online Serving (ATM / In-App / Web Session)"),
                               tags$p("Vertex AI Endpoint (autoscaling):"),
                               tags$ul(
                                 tags$li("REST API: POST /predict with customer_id"),
                                 tags$li("Feature lookup from Bigtable (<10ms) + model inference (<50ms)"),
                                 tags$li("Total p99 SLO: <200ms"),
                                 tags$li("Autoscaling: 2–20 replicas based on QPS"),
                                 tags$li("Peak: ~500 QPS (9-5 workday for ATM + lunch hour in-app)")
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk6p2",
                  div(class="section-heading-dark", "Deployment Strategy — K&B Ch.7 (Shadow → Canary → Blue-Green)"),
                  fluidRow(
                    column(4, div(class="framework-card",
                        tags$h5("Phase 1: Shadow Deployment"),
                        tags$p("ML model runs in parallel with PEGA rules. ML predictions logged but not served to customers. 2-week validation:"),
                        tags$ul(tags$li("Score distribution matches expectations"), tags$li("No null predictions"), tags$li("Latency SLO met"), tags$li("No regulatory flag triggers (FCA check)"))
                    )),
                    column(4, div(class="framework-card",
                        tags$h5("Phase 2: Canary — 10% Traffic"),
                        tags$p("10% of customers receive ML-driven actions. Monitor for 2 weeks:"),
                        tags$ul(tags$li("Opt-out rate ≤ 0.5% SLO"), tags$li("No complaint spike"), tags$li("ML conversion rate ≥ rules baseline"), tags$li("Automated rollback if guardrail breached"))
                    )),
                    column(4, div(class="framework-card",
                        tags$h5("Phase 3: Full Rollout"),
                        tags$p("Blue-green deployment to full customer base:"),
                        tags$ul(tags$li("Old PEGA rules preserved as 'blue' version"), tags$li("ML as 'green' version — instant rollback available"), tags$li("Champion-challenger: 90% ML, 10% rules (ongoing exploration)"), tags$li("MRM sign-off required before 100% ML"))
                    ))
                  )
          ),

          bkPanel("bk6p3",
                  div(class="section-heading-dark", "PEGA Integration — K&B Serving Contract"),
                  div(class="tip-box", HTML("<strong>K&B Ch.7 Pattern:</strong> The ML system and the decisioning system (PEGA) are explicitly decoupled. ML provides <em>signals</em>, PEGA provides <em>decisions</em>. This is a critical interview point.")),
                  br(),
                  fluidRow(
                    column(6,
                           div(class="framework-card",
                               tags$h5("API Contract (JSON)"),
                               tags$pre(style="font-size:10px;background:#0a0d0f;padding:10px;border-radius:4px;color:#d1d5db;",
                                 '// Request
{"customer_id": "UK-123456", "channel": "in_app", "context": {"session_id": "...", "page": "savings"}}

// Response (< 200ms p99)
{"customer_id": "UK-123456",
 "propensity": {"isa": 0.72, "mortgage": 0.08, "credit_card": 0.31},
 "churn_risk": 0.18,
 "channel_scores": {"push": 0.55, "email": 0.30, "sms": 0.10, "atm": 0.03, "in_app": 0.80},
 "send_time_arm": 18,  // 6pm UTC
 "model_version": "v5.2",
 "feature_timestamp": "2025-01-15T00:00:00Z"}'
                               )
                           )
                    ),
                    column(6,
                           div(class="framework-card",
                               tags$h5("PEGA Arbitration Pipeline"),
                               tags$ol(
                                 tags$li("Receive ML scores from Vertex endpoint"),
                                 tags$li("Apply eligibility filter (product rules — customer must be eligible)"),
                                 tags$li("Apply FCA suitability filter (vulnerable customer check)"),
                                 tags$li("Apply contact policy (channel caps, opt-out flags)"),
                                 tags$li("Arbitration: rank remaining actions by propensity × commercial value"),
                                 tags$li("Output: single best action per touchpoint")
                               )
                           )
                    )
                  )
          ),

          bkPanel("bk6p4",
                  div(class="section-heading-dark", "Model Compression — K&B Ch.7 Applied"),
                  fluidRow(
                    column(6,
                           tags$table(class="table table-sm",
                             tags$thead(tags$tr(tags$th("Technique"), tags$th("XGBoost Bank"), tags$th("Latency Gain"), tags$th("AUC Loss"))),
                             tags$tbody(
                               tags$tr(tags$td("Baseline (FP64)"), tags$td("50MB, 850 trees"), tags$td("—"), tags$td("—")),
                               tags$tr(tags$td("Tree pruning"), tags$td("42MB, 650 trees"), tags$td("15% faster"), tags$td("-0.003")),
                               tags$tr(tags$td("Feature selection (top 200)"), tags$td("28MB"), tags$td("25% faster"), tags$td("-0.008")),
                               tags$tr(tags$td("Float32 quantisation"), tags$td("22MB"), tags$td("30% faster"), tags$td("-0.001")),
                               tags$tr(tags$td("ONNX export"), tags$td("18MB"), tags$td("40% faster"), tags$td("-0.002"))
                             )
                           )
                    ),
                    column(6,
                           div(class="framework-card",
                               tags$h5("K&B Latency Budget Breakdown"),
                               tags$table(class="table table-sm",
                                 tags$thead(tags$tr(tags$th("Component"), tags$th("Budget"))),
                                 tags$tbody(
                                   tags$tr(tags$td("Network (Vertex endpoint)"), tags$td("20ms")),
                                   tags$tr(tags$td("Bigtable feature lookup"), tags$td("8ms")),
                                   tags$tr(tags$td("Feature assembly"), tags$td("5ms")),
                                   tags$tr(tags$td("XGBoost inference"), tags$td("15ms")),
                                   tags$tr(tags$td("Response serialisation"), tags$td("3ms")),
                                   tags$tr(tags$td(tags$b("Total p50"), style="font-weight:bold"), tags$td(tags$b("51ms \u2705"))),
                                   tags$tr(tags$td(tags$b("Total p99"), style="font-weight:bold"), tags$td(tags$b("148ms \u2705")))
                                 )
                               )
                           )
                    )
                  )
          )
      )
    ),

    # ── Box 7: Ch.8 Monitoring ────────────────────────────────────────────────
    fluidRow(
      box(title="Box 7 — Ch.8: Monitoring & Reliability (K&B)", status="success", solidHeader=TRUE, width=12,
          id="bk-box7",
          div(bkBtn("bk-box7","bk7p1","Drift Detection",TRUE),
              bkBtn("bk-box7","bk7p2","Alerting & Retraining"),
              bkBtn("bk-box7","bk7p3","ISA Season Shift"),
              bkBtn("bk-box7","bk7p4","MLOps Stack")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          bkPanel("bk7p1",
                  div(class="section-heading-dark", "Distribution Shift Detection — K&B Ch.8"),
                  fluidRow(
                    column(6,
                           div(class="framework-card",
                               tags$h5("PSI (Population Stability Index)"),
                               tags$p("K&B recommend PSI as the primary drift indicator for tabular models:"),
                               tags$ul(
                                 tags$li(tags$b("PSI < 0.1:"), " No significant shift — model stable"),
                                 tags$li(tags$b("PSI 0.1–0.2:"), " Moderate shift — monitor closely, consider retraining"),
                                 tags$li(tags$b("PSI > 0.2:"), " Significant shift — retrain required"),
                                 tags$li("Computed monthly for all 500 features"),
                                 tags$li("Top 20 features by SHAP importance get daily PSI")
                               )
                           ),
                           div(class="framework-card",
                               tags$h5("Banking Drift Types"),
                               tags$ul(
                                 tags$li(tags$b("Covariate shift:"), " CACI ACORN vintage mismatch — feature distribution shifts annually when CACI refreshes its classifications"),
                                 tags$li(tags$b("Concept drift:"), " Customer spending patterns shift post-interest-rate rise — relationship between features and conversion changes"),
                                 tags$li(tags$b("Label shift:"), " Base rate of ISA conversions spikes in Jan-Apr (ISA season) — model calibration becomes off")
                               )
                           )
                    ),
                    column(6,
                           div(class="section-heading-dark", "Monitoring Dashboard (GCP Vertex AI)"),
                           tags$table(class="table table-sm",
                             tags$thead(tags$tr(tags$th("Signal"), tags$th("Frequency"), tags$th("Threshold"), tags$th("Action"))),
                             tags$tbody(
                               tags$tr(tags$td("PSI (top features)"), tags$td("Daily"), tags$td("> 0.1"), tags$td("Alert ML Ops")),
                               tags$tr(tags$td("PSI (all features)"), tags$td("Weekly"), tags$td("> 0.2"), tags$td("Trigger retrain")),
                               tags$tr(tags$td("Prediction distribution"), tags$td("Daily"), tags$td("Mean shift > 5%"), tags$td("Alert")),
                               tags$tr(tags$td("Online CTR"), tags$td("Daily"), tags$td("Drop > 15%"), tags$td("Page on-call")),
                               tags$tr(tags$td("Opt-out rate"), tags$td("Hourly"), tags$td("> 0.5%"), tags$td("PEGA auto-pause")),
                               tags$tr(tags$td("Model null rate"), tags$td("Hourly"), tags$td("> 0.01%"), tags$td("Alert")),
                               tags$tr(tags$td("Feature null rate"), tags$td("Daily"), tags$td("> baseline × 2"), tags$td("Data pipeline check"))
                             )
                           )
                    )
                  )
          ),

          bkPanel("bk7p2",
                  div(class="section-heading-dark", "Alerting & Automated Retraining (K&B Ch.8)"),
                  fluidRow(
                    column(6,
                           div(class="framework-card",
                               tags$h5("Retraining Trigger Hierarchy"),
                               tags$ol(
                                 tags$li(tags$b("Scheduled (default):"), " Monthly retrain for churn model; quarterly for propensity models"),
                                 tags$li(tags$b("Drift-triggered:"), " PSI > 0.2 on any top-10 SHAP feature → automated retraining job on Vertex AI Pipelines"),
                                 tags$li(tags$b("Business-triggered:"), " FCA product rule change, CACI vintage refresh, interest rate change → manual retrain with updated feature engineering"),
                                 tags$li(tags$b("Emergency:"), " Opt-out rate breaches SLO → immediate model rollback to previous version, then retrain on fresh data")
                               )
                           )
                    ),
                    column(6,
                           div(class="warn-box", HTML("<strong>K&B Warning — Retraining is NOT Free:</strong>")),
                           tags$ul(
                             tags$li("Each retrain requires: data snapshot, feature computation, model training, offline eval, MRM review, canary deployment, monitoring confirmation"),
                             tags$li("MRM review adds 2-4 week delay for material model changes"),
                             tags$li("K&B: automate as much as possible but never skip offline evaluation before redeployment"),
                             tags$li("Champion-challenger always maintained: new model runs as 10% challenger before full cutover")
                           )
                    )
                  )
          ),

          bkPanel("bk7p3",
                  div(class="section-heading-dark", "ISA Season Concept Drift — Banking Specific Case Study"),
                  div(class="tip-box", HTML("<strong>UK ISA Season (Jan–Apr):</strong> Individual Savings Account subscription deadline is 5 April each tax year. Customer intent to open an ISA spikes 10x in January-April. A model trained on May-December data will underestimate ISA propensity during ISA season.")),
                  br(),
                  HTML(sprintf('
<svg viewBox="0 0 700 180" xmlns="http://www.w3.org/2000/svg" style="width:100%%;font-family:Inter,sans-serif;">
  <text x="350" y="18" text-anchor="middle" fill="#e8410a" font-size="12" font-weight="bold">ISA Conversion Rate by Month — Concept Drift Illustration</text>
  <line x1="50" y1="150" x2="680" y2="150" stroke="#374151" stroke-width="1.5"/>
  <line x1="50" y1="150" x2="50" y2="25" stroke="#374151" stroke-width="1.5"/>
  %s
  <text x="355" y="168" text-anchor="middle" fill="#9ca3af" font-size="8">Month</text>
  <text x="30" y="90" text-anchor="middle" fill="#9ca3af" font-size="8" transform="rotate(-90,30,90)">Conversion Rate</text>
  <rect x="55" y="135" width="8" height="8" fill="#e8410a" rx="2"/>
  <text x="67" y="144" fill="#d1d5db" font-size="8">Actual rate</text>
  <rect x="120" y="135" width="8" height="8" fill="#3b82f6" rx="2"/>
  <text x="132" y="144" fill="#d1d5db" font-size="8">Model prediction</text>
  <rect x="200" y="135" width="8" height="8" fill="#10b981" rx="2"/>
  <text x="212" y="144" fill="#d1d5db" font-size="8">After re-calibration</text>
</svg>',
paste(sapply(1:12, function(i) {
  months <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
  actual <- c(0.15,0.18,0.22,0.14,0.04,0.03,0.03,0.03,0.04,0.05,0.06,0.09)
  predicted <- c(0.05,0.06,0.06,0.05,0.04,0.03,0.03,0.03,0.04,0.05,0.06,0.07)
  recal <- c(0.14,0.17,0.21,0.13,0.04,0.03,0.03,0.03,0.04,0.05,0.06,0.08)
  x <- 50 + (i-1) * 54
  ay <- 150 - actual[i] * 500
  py <- 150 - predicted[i] * 500
  ry <- 150 - recal[i] * 500
  sprintf('<text x="%d" y="162" text-anchor="middle" fill="#9ca3af" font-size="7">%s</text>
<circle cx="%d" cy="%.0f" r="3" fill="#e8410a"/>
<circle cx="%d" cy="%.0f" r="3" fill="#3b82f6" opacity="0.8"/>
<circle cx="%d" cy="%.0f" r="3" fill="#10b981" opacity="0.8"/>',
    x+27, months[i], x+27, ay, x+27, py, x+27, ry)
}), collapse="\n")
                  )),
                  div(class="framework-card",
                      tags$h5("Mitigation Strategy"),
                      tags$ul(
                        tags$li(tags$b("Seasonal recalibration:"), " Update Platt scaling parameters monthly using last 30 days of data"),
                        tags$li(tags$b("ISA season model:"), " Separate model trained on Jan-Apr data; switched on 1 January automatically"),
                        tags$li(tags$b("Feature engineering:"), " Add 'days_to_tax_year_end' as an explicit feature — model learns season itself"),
                        tags$li(tags$b("Monitoring:"), " Compare actual conversion rate to model-predicted rate daily during ISA season; alert if gap > 20%")
                      )
                  )
          ),

          bkPanel("bk7p4",
                  div(class="section-heading-dark", "GCP MLOps Stack — K&B Ch.8 Infrastructure"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Layer"), tags$th("K&B Ch.8 Category"), tags$th("Tool (Banking)"), tags$th("Notes"))),
                    tags$tbody(
                      tags$tr(tags$td("Data storage"), tags$td("Data layer"), tags$td("BigQuery + GCS"), tags$td("Delta/Iceberg for time-travel")),
                      tags$tr(tags$td("Feature store"), tags$td("Feature layer"), tags$td("Vertex AI Feature Store"), tags$td("Offline: GCS Parquet; Online: Bigtable")),
                      tags$tr(tags$td("Experiment tracking"), tags$td("Training layer"), tags$td("MLflow on Vertex AI"), tags$td("Model registry + artifact store")),
                      tags$tr(tags$td("Model training"), tags$td("Training layer"), tags$td("Vertex AI Training"), tags$td("n1-highmem-32 for XGBoost")),
                      tags$tr(tags$td("Pipeline orchestration"), tags$td("Orchestration"), tags$td("Vertex AI Pipelines (KFP)"), tags$td("Triggered by Cloud Scheduler")),
                      tags$tr(tags$td("Model serving"), tags$td("Serving layer"), tags$td("Vertex AI Endpoints"), tags$td("Autoscale 2-20 replicas")),
                      tags$tr(tags$td("Monitoring"), tags$td("Monitoring layer"), tags$td("Vertex Model Monitoring"), tags$td("PSI alerts → PagerDuty")),
                      tags$tr(tags$td("Governance"), tags$td("Responsible AI"), tags$td("Model Cards + MRM Portal"), tags$td("FCA requirement"))
                    )
                  )
          )
      )
    ),

    # ── Self-Assessment ───────────────────────────────────────────────────────
    fluidRow(
      box(title="Self-Assessment — Banking ML Case Study", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(4, sliderInput(ns("sc1"),"Requirements & SLOs (Ch.1-2)",1,10,5)),
            column(4, sliderInput(ns("sc2"),"Data Pipeline & Features (Ch.3-4)",1,10,5)),
            column(4, sliderInput(ns("sc3"),"Modelling & Evaluation (Ch.5-6)",1,10,5))
          ),
          fluidRow(
            column(4, sliderInput(ns("sc4"),"Serving & Deployment (Ch.7)",1,10,5)),
            column(4, sliderInput(ns("sc5"),"Monitoring & Drift (Ch.8)",1,10,5)),
            column(4, actionButton(ns("save_self"),"Save Assessment", class="btn-meta", width="100%"))
          ),
          uiOutput(ns("self_result"))
      )
    )
  )
}

banking_case_study_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_self, {
      avg <- mean(c(input$sc1, input$sc2, input$sc3, input$sc4, input$sc5))
      pct <- round(avg * 10)
      prep_manager$update_progress("banking_case_study", pct)
      output$self_result <- renderUI({
        col <- progress_colour(pct)
        div(class=if(pct>=80)"success-box" else "tip-box",
            tags$h5(style=paste0("color:",col), paste0("Banking ML Readiness: ", pct, "%")),
            if(pct < 50) tags$p("Focus: re-read K&B Ch.1-2 and Ch.7. Requirements and serving are the most commonly tested interview areas for production banking ML."),
            if(pct >= 50 && pct < 80) tags$p("Good foundation. Deepen understanding of FCA constraints and PEGA integration pattern."),
            if(pct >= 80) tags$p("\u2705 Strong command. You can walk an interviewer through a regulated banking ML system end-to-end."))
      })
      showNotification("Banking assessment saved!", type="message")
    })
  })
}
