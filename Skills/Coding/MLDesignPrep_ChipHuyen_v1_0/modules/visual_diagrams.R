# modules/visual_diagrams.R
# Visual Diagrams — Interactive reproductions of key figures from
# Chip Huyen, "Designing Machine Learning Systems" (O'Reilly, 2022)
# Figures: 1-1, 2-2, 2-7, 7-6, 7-8

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  UI                                                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
visual_diagrams_ui <- function(id) {
  ns <- NS(id)

  # ── Shared inline CSS for diagrams ──────────────────────────────────────────
  diagram_css <- "
  /* ── Diagram shell ── */
  .diag-wrap {
    width: 100%;
    padding: 8px 0 16px;
    font-family: 'Inter', 'Segoe UI', sans-serif;
    position: relative;
  }

  /* ── Clickable nodes ── */
  .dn {
    cursor: pointer;
    transition: all 0.22s ease;
    user-select: none;
  }
  .dn:hover { filter: brightness(1.08) drop-shadow(0 4px 12px rgba(0,138,130,0.35)); transform: scale(1.03); }
  .dn.active { filter: brightness(1.0) drop-shadow(0 0 0 3px #00A39A); }

  /* ── Detail panels ── */
  .detail-panel {
    display: none;
    margin-top: 16px;
    background: linear-gradient(135deg,#f0fafa 0%,#e8f5f4 100%);
    border: 1.5px solid #80cbc4;
    border-left: 5px solid #008A82;
    border-radius: 10px;
    padding: 18px 22px;
    animation: slideIn 0.22s ease;
  }
  .detail-panel.visible { display: block; }
  @keyframes slideIn {
    from { opacity:0; transform:translateY(-6px); }
    to   { opacity:1; transform:translateY(0); }
  }
  .detail-panel h4 {
    color: #002C3C;
    font-weight: 800;
    font-size: 14px;
    margin: 0 0 10px;
    display: flex; align-items: center; gap: 8px;
  }
  .detail-panel p  { color: #2c3e50; font-size: 12.5px; line-height: 1.7; margin: 0 0 8px; }
  .detail-panel ul { padding-left: 18px; margin: 6px 0; }
  .detail-panel li { color: #2c3e50; font-size: 12px; line-height: 1.65; margin-bottom: 4px; }
  .detail-panel .dp-tag {
    display: inline-block;
    background: #008A82;
    color: #fff;
    border-radius: 12px;
    padding: 2px 10px;
    font-size: 10px;
    font-weight: 700;
    margin: 2px;
    letter-spacing: 0.4px;
  }
  .detail-panel .dp-tag.amber { background:#e67e22; }
  .detail-panel .dp-tag.blue  { background:#2980b9; }
  .detail-panel .dp-tag.red   { background:#c0392b; }
  .detail-panel .dp-tag.green { background:#1a9b6b; }
  .detail-panel .close-btn {
    float: right;
    background: none;
    border: none;
    color: #80cbc4;
    font-size: 18px;
    cursor: pointer;
    line-height: 1;
    padding: 0;
    margin-top: -2px;
  }
  .detail-panel .close-btn:hover { color: #008A82; }

  /* ── Diagram caption ── */
  .diag-caption {
    text-align: center;
    font-size: 11.5px;
    color: #546e7a;
    margin-top: 12px;
    font-style: italic;
  }

  /* SVG text default */
  .diag-wrap svg text { font-family: 'Inter','Segoe UI',sans-serif; }
  "

  tagList(

    tags$head(tags$style(HTML(diagram_css))),

    # ── Page hero ─────────────────────────────────────────────────────────────
    div(class = "meta-hero",
        tags$h1("📐 Key Diagrams — Chip Huyen"),
        tags$h2("Interactive reproductions of the core figures from Designing ML Systems (O'Reilly, 2022)"),
        div(
          span(class="hero-badge","Fig 1-1 — ML System Map"),
          span(class="hero-badge","Fig 2-2 — Dev Cycle"),
          span(class="hero-badge","Fig 2-7 — Data Hierarchy"),
          span(class="hero-badge","Fig 7-6 — Online Prediction"),
          span(class="hero-badge","Fig 7-8 — Data Pipeline")
        ),
        tags$p(style="color:rgba(255,255,255,0.7);font-size:12px;margin-top:12px;",
               "Click any component to reveal in-depth interview preparation notes tied directly to Huyen's text.")
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # DIAGRAM 1 — Figure 1-1: Components of an ML System
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title = "Figure 1-1 — Components of an ML System",
          status = "primary", solidHeader = TRUE, width = 12,
          div(class="diag-wrap",
            HTML('
<svg viewBox="0 0 900 380" xmlns="http://www.w3.org/2000/svg" style="width:100%;max-width:900px;display:block;margin:0 auto;">
  <defs>
    <marker id="arr1" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#008A82"/>
    </marker>
    <filter id="sh"><feDropShadow dx="0" dy="2" stdDeviation="3" flood-opacity="0.15"/></filter>
  </defs>

  <!-- ML System outer box -->
  <rect x="300" y="30" width="570" height="310" rx="16" fill="#e0f4f2" stroke="#008A82" stroke-width="2"/>
  <text x="575" y="58" text-anchor="middle" font-size="15" font-weight="800" fill="#002C3C">ML System</text>

  <!-- Deployment row -->
  <rect x="320" y="70" width="530" height="52" rx="10" fill="#008A82" class="dn" onclick="showDetail(&#39;d1-deploy&#39;)" filter="url(#sh)"/>
  <text x="397" y="91" font-size="10" font-weight="700" fill="white">Chapters 7, 8 &amp; 9</text>
  <text x="490" y="108" text-anchor="middle" font-size="12.5" font-weight="600" fill="white">Deployment, monitoring, updating of logics</text>

  <!-- Feature Eng row -->
  <rect x="320" y="138" width="175" height="90" rx="10" fill="#00A39A" class="dn" onclick="showDetail(&#39;d1-features&#39;)" filter="url(#sh)"/>
  <text x="407" y="162" text-anchor="middle" font-size="10" font-weight="700" fill="white">Chapter 5</text>
  <text x="407" y="180" text-anchor="middle" font-size="12.5" font-weight="600" fill="white">Feature</text>
  <text x="407" y="197" text-anchor="middle" font-size="12.5" font-weight="600" fill="white">engineering</text>

  <!-- ML Algorithms -->
  <rect x="508" y="138" width="152" height="90" rx="10" fill="#00868e" class="dn" onclick="showDetail(&#39;d1-algo&#39;)" filter="url(#sh)"/>
  <text x="584" y="162" text-anchor="middle" font-size="10" font-weight="700" fill="white">Chapter 6</text>
  <text x="584" y="185" text-anchor="middle" font-size="12.5" font-weight="600" fill="white">ML algorithms</text>

  <!-- Evaluation -->
  <rect x="672" y="138" width="178" height="90" rx="10" fill="#007a72" class="dn" onclick="showDetail(&#39;d1-eval&#39;)" filter="url(#sh)"/>
  <text x="761" y="162" text-anchor="middle" font-size="10" font-weight="700" fill="white">Chapter 6</text>
  <text x="761" y="185" text-anchor="middle" font-size="12.5" font-weight="600" fill="white">Evaluation</text>

  <!-- Data row -->
  <rect x="320" y="244" width="530" height="48" rx="10" fill="#4db6ac" class="dn" onclick="showDetail(&#39;d1-data&#39;)" filter="url(#sh)"/>
  <text x="500" y="268" text-anchor="middle" font-size="13" font-weight="600" fill="white">Data</text>
  <text x="780" y="268" text-anchor="middle" font-size="10" font-weight="700" fill="white">Chapters 3 &amp; 4</text>

  <!-- Infrastructure row -->
  <rect x="320" y="304" width="530" height="24" rx="8" fill="#80cbc4" class="dn" onclick="showDetail(&#39;d1-infra&#39;)" filter="url(#sh)"/>
  <text x="500" y="321" text-anchor="middle" font-size="12" font-weight="600" fill="#002C3C">Infrastructure</text>
  <text x="780" y="321" text-anchor="middle" font-size="10" font-weight="700" fill="#002C3C">Chapter 10</text>

  <!-- LEFT: Personas -->
  <!-- ML Users -->
  <rect x="20" y="50" width="130" height="72" rx="12" fill="#f0fafa" stroke="#80cbc4" stroke-width="1.5" class="dn" onclick="showDetail(&#39;d1-users&#39;)"/>
  <text x="85" y="75" text-anchor="middle" font-size="22">👥</text>
  <text x="85" y="95" text-anchor="middle" font-size="11.5" font-weight="700" fill="#002C3C">ML System</text>
  <text x="85" y="110" text-anchor="middle" font-size="11.5" font-weight="700" fill="#002C3C">Users</text>

  <!-- Business -->
  <rect x="20" y="155" width="130" height="72" rx="12" fill="#f0fafa" stroke="#80cbc4" stroke-width="1.5" class="dn" onclick="showDetail(&#39;d1-biz&#39;)"/>
  <text x="85" y="180" text-anchor="middle" font-size="22">💼</text>
  <text x="85" y="200" text-anchor="middle" font-size="11.5" font-weight="700" fill="#002C3C">Business</text>
  <text x="85" y="215" text-anchor="middle" font-size="11.5" font-weight="700" fill="#002C3C">Requirements</text>

  <!-- ML Devs -->
  <rect x="20" y="260" width="130" height="72" rx="12" fill="#f0fafa" stroke="#80cbc4" stroke-width="1.5" class="dn" onclick="showDetail(&#39;d1-devs&#39;)"/>
  <text x="85" y="285" text-anchor="middle" font-size="22">🧑‍💻</text>
  <text x="85" y="306" text-anchor="middle" font-size="11.5" font-weight="700" fill="#002C3C">ML System</text>
  <text x="85" y="321" text-anchor="middle" font-size="11.5" font-weight="700" fill="#002C3C">Developers</text>

  <!-- Arrows -->
  <!-- Users → Ch11 label -->
  <rect x="162" y="74" width="110" height="22" rx="6" fill="#002C3C"/>
  <text x="217" y="89" text-anchor="middle" font-size="10" font-weight="700" fill="white">Chapter 11</text>
  <line x1="150" y1="85" x2="162" y2="85" stroke="#008A82" stroke-width="1.5" marker-end="url(#arr1)"/>
  <line x1="272" y1="85" x2="300" y2="95" stroke="#008A82" stroke-width="1.5" marker-end="url(#arr1)"/>

  <!-- Biz → Ch1&2 label -->
  <rect x="162" y="178" width="110" height="22" rx="6" fill="#002C3C"/>
  <text x="217" y="193" text-anchor="middle" font-size="10" font-weight="700" fill="white">Chapters 1 &amp; 2</text>
  <line x1="150" y1="189" x2="162" y2="189" stroke="#008A82" stroke-width="1.5" marker-end="url(#arr1)"/>
  <line x1="272" y1="189" x2="320" y2="165" stroke="#008A82" stroke-width="1.5" marker-end="url(#arr1)"/>

  <!-- Devs → Entire book -->
  <rect x="162" y="283" width="110" height="22" rx="6" fill="#002C3C"/>
  <text x="217" y="298" text-anchor="middle" font-size="10" font-weight="700" fill="white">Entire Book</text>
  <line x1="150" y1="294" x2="162" y2="294" stroke="#008A82" stroke-width="1.5" marker-end="url(#arr1)"/>
  <line x1="272" y1="294" x2="320" y2="280" stroke="#008A82" stroke-width="1.5" marker-end="url(#arr1)"/>
</svg>
            '),
            div(class="diag-caption","Figure 1-1 — Different components of an ML system. \"ML algorithms\" is usually what people think of when they say machine learning, but it is only a small part of the entire system."),
            br(),
            # Detail panels
            div(id="d1-deploy", class="detail-panel",
              tags$button(class="close-btn", onclick="hideDetail('d1-deploy')","✕"),
              tags$h4("🚀 Chapters 7, 8 & 9 — Deployment, Monitoring, Updating of Logics"),
              tags$p("This top layer is where ML meets production reality. Huyen dedicates three full chapters to it because the majority of ML system failures occur here, not in model training."),
              tags$ul(
                tags$li(tags$b("Ch.7 — Model Deployment & Prediction Service:"), " Batch vs online prediction, streaming features, model compression (quantisation, distillation, pruning), edge deployment. Key decision: what's your latency SLO? That determines everything."),
                tags$li(tags$b("Ch.8 — Data Distribution Shifts & Monitoring:"), " Covariate shift, label shift, concept drift. PSI/KS-stat detection. Monitoring infrastructure — logs, metrics, alerts."),
                tags$li(tags$b("Ch.9 — Continual Learning & Updating:"), " Stateless vs stateful retraining. When to retrain: data drift thresholds, scheduled windows, performance degradation. Champion/challenger patterns.")
              ),
              div(span(class="dp-tag","Latency SLO"), span(class="dp-tag","Drift Detection"), span(class="dp-tag amber","Retraining Triggers"), span(class="dp-tag blue","Monitoring Stack"))
            ),
            div(id="d1-features", class="detail-panel",
              tags$button(class="close-btn", onclick="hideDetail('d1-features')","✕"),
              tags$h4("⚙️ Chapter 5 — Feature Engineering"),
              tags$p("Huyen argues feature engineering is the highest-leverage activity in most real-world ML projects. A week of good feature work can outperform months of architecture tuning."),
              tags$ul(
                tags$li(tags$b("Common operations:"), " handling missing values (deletion, imputation), scaling (standardisation vs min-max vs log), encoding (one-hot, embedding, hashing), discretisation."),
                tags$li(tags$b("Feature crossing:"), " DeepFM and DCN-style interactions. Be careful of dimensionality explosion."),
                tags$li(tags$b("Train-serve skew:"), " Huyen's #1 production failure mode. Features computed differently at training vs serving time. Feature store is the solution."),
                tags$li(tags$b("Data leakage:"), " Label leakage (target encoded in features), temporal leakage (future data used for training). Must be caught at the feature level, not model level.")
              ),
              div(span(class="dp-tag","Feature Store"), span(class="dp-tag red","Train-Serve Skew"), span(class="dp-tag amber","Data Leakage"), span(class="dp-tag blue","Point-in-Time Joins"))
            ),
            div(id="d1-algo", class="detail-panel",
              tags$button(class="close-btn", onclick="hideDetail('d1-algo')","✕"),
              tags$h4("🧠 Chapter 6 — ML Algorithms (Model Development)"),
              tags$p("Despite being what most people associate with 'machine learning', algorithms are just one layer of the system. Huyen's key insight: model selection should be driven by constraints, not fashion."),
              tags$ul(
                tags$li(tags$b("Baseline first:"), " random → heuristic → logistic regression → SotA reference. Never skip this hierarchy."),
                tags$li(tags$b("Selection criteria:"), " latency budget, interpretability requirements, training data size, team expertise."),
                tags$li(tags$b("Ensembles:"), " effective when base models have low error correlation. Bagging (variance reduction), boosting (bias reduction), stacking."),
                tags$li(tags$b("Distributed training:"), " data parallelism vs model parallelism. ZeRO optimisation for large models.")
              ),
              div(span(class="dp-tag","Baseline Strategy"), span(class="dp-tag","Model Selection"), span(class="dp-tag amber","Ensembling"), span(class="dp-tag blue","Distributed Training"))
            ),
            div(id="d1-eval", class="detail-panel",
              tags$button(class="close-btn", onclick="hideDetail('d1-eval')","✕"),
              tags$h4("📊 Chapter 6 — Evaluation"),
              tags$p("Evaluation is co-located with ML algorithms in Chapter 6 because Huyen treats them as inseparable. You design your evaluation strategy before you choose your model."),
              tags$ul(
                tags$li(tags$b("Offline metrics:"), " AUC-ROC, F1, NDCG, precision@k, RMSE. Choose based on what the business actually optimises."),
                tags$li(tags$b("Sliced evaluation:"), " aggregate metrics hide subgroup failures. Evaluate by user cohort, time period, geography, edge cases. Huyen: non-negotiable release gate."),
                tags$li(tags$b("Calibration:"), " predicted probabilities should match actual frequencies. Critical for decision systems."),
                tags$li(tags$b("Offline→online gap:"), " the correlation between offline metrics and online business metrics. High gap = evaluation strategy needs rethinking.")
              ),
              div(span(class="dp-tag","Sliced Evaluation"), span(class="dp-tag","Calibration"), span(class="dp-tag amber","Offline-Online Gap"), span(class="dp-tag blue","A/B Testing"))
            ),
            div(id="d1-data", class="detail-panel",
              tags$button(class="close-btn", onclick="hideDetail('d1-data')","✕"),
              tags$h4("🗄️ Chapters 3 & 4 — Data"),
              tags$p("Data is the foundation layer — everything above it depends on data quality and availability. Huyen dedicates two chapters because data problems are the most common production failures."),
              tags$ul(
                tags$li(tags$b("Ch.3 — Data Engineering Fundamentals:"), " data sources, formats (row vs column, Parquet/Avro), data models (structured/unstructured), storage (data lake, data warehouse, lakehouse), batch vs streaming."),
                tags$li(tags$b("Ch.4 — Training Data:"), " sampling (non-probability, simple random, stratified, weighted), labelling (hand labels, programmatic, natural labels, semi-supervised), class imbalance (resampling, SMOTE, focal loss, class weights)."),
                tags$li(tags$b("Data lineage:"), " knowing where every training example came from is critical for debugging. Huyen emphasises this is often ignored until it causes a major incident.")
              ),
              div(span(class="dp-tag","Data Lineage"), span(class="dp-tag","Labelling Strategy"), span(class="dp-tag amber","Class Imbalance"), span(class="dp-tag blue","Batch vs Streaming"))
            ),
            div(id="d1-infra", class="detail-panel",
              tags$button(class="close-btn", onclick="hideDetail('d1-infra')","✕"),
              tags$h4("🏗️ Chapter 10 — Infrastructure & Tooling"),
              tags$p("The bottom of the pyramid. Infrastructure determines what's actually possible at scale. Huyen covers the ML platform stack that underpins production systems."),
              tags$ul(
                tags$li(tags$b("Storage & compute:"), " cloud (S3/GCS/Azure Blob), on-prem, hybrid. GPU clusters, spot instance strategies, cost optimisation."),
                tags$li(tags$b("Development environment:"), " standardised containers (Docker), managed notebooks, versioned environments."),
                tags$li(tags$b("ML platform:"), " orchestration (Airflow, Kubeflow, Metaflow), experiment tracking (MLflow, W&B), model registry, feature store, serving platform."),
                tags$li(tags$b("Build vs buy:"), " Huyen's framework: build when it's a core differentiator, buy when it's commodity infrastructure.")
              ),
              div(span(class="dp-tag","ML Platform"), span(class="dp-tag","Orchestration"), span(class="dp-tag amber","Build vs Buy"), span(class="dp-tag blue","Cost Optimisation"))
            ),
            div(id="d1-users", class="detail-panel",
              tags$button(class="close-btn", onclick="hideDetail('d1-users')","✕"),
              tags$h4("👥 ML System Users"),
              tags$p("End users interact with the ML system through the application layer. Their experience is mediated entirely by Chapter 11 — the UI/product interface."),
              tags$ul(
                tags$li("Users never interact with the model directly — they interact with the product built on top of it."),
                tags$li("User behaviour generates natural labels (clicks, purchases, dwell time) that flow back into training data."),
                tags$li(tags$b("Huyen Ch.11:"), " Human-computer interaction considerations, explanation interfaces, feedback loops from user behaviour to model retraining.")
              )
            ),
            div(id="d1-biz", class="detail-panel",
              tags$button(class="close-btn", onclick="hideDetail('d1-biz')","✕"),
              tags$h4("💼 Business Requirements → ML Objectives"),
              tags$p("The hardest and most important translation in ML system design: converting a vague business goal into a well-defined ML objective."),
              tags$ul(
                tags$li(tags$b("Common business → ML translations:"), " 'increase engagement' → maximise watch time (but watch out for clickbait); 'reduce fraud' → binary classifier with precision/recall tradeoff."),
                tags$li(tags$b("Framing choices:"), " classification vs regression, ranking vs retrieval, single vs multi-task learning."),
                tags$li(tags$b("Constraints matter:"), " latency SLO, interpretability requirements, regulatory compliance, fairness constraints — all come from business, not from data."),
                tags$li(tags$b("Chapters 1 & 2"), " cover this translation in detail, including Huyen's 6-step iterative loop.")
              ),
              div(span(class="dp-tag","Objective Framing"), span(class="dp-tag","Business KPIs"), span(class="dp-tag amber","Constraints"), span(class="dp-tag blue","Success Metrics"))
            ),
            div(id="d1-devs", class="detail-panel",
              tags$button(class="close-btn", onclick="hideDetail('d1-devs')","✕"),
              tags$h4("🧑‍💻 ML System Developers"),
              tags$p("ML system developers need to understand the entire stack — not just model training. This is why the entire book is targeted at developers, not just data scientists."),
              tags$ul(
                tags$li("Must understand data engineering, feature engineering, model development, evaluation, deployment, and monitoring as an integrated system."),
                tags$li(tags$b("Key skill:"), " knowing which layer is responsible for a given failure. Most 'model problems' are actually data problems. Most 'accuracy problems' are actually evaluation design problems."),
                tags$li("Full-stack ML engineers are more valuable than specialists in production contexts — Huyen's implicit career recommendation throughout the book.")
              )
            )
          )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # DIAGRAM 2 — Figure 2-2: The 6-Step Iterative ML Development Cycle
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title = "Figure 2-2 — The Iterative ML System Development Cycle",
          status = "success", solidHeader = TRUE, width = 12,
          div(class="diag-wrap",
            HTML('
<svg viewBox="0 0 900 420" xmlns="http://www.w3.org/2000/svg" style="width:100%;max-width:900px;display:block;margin:0 auto;">
  <defs>
    <marker id="arr2s" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#008A82"/>
    </marker>
    <marker id="arr2d" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#546e7a"/>
    </marker>
    <filter id="sh2"><feDropShadow dx="0" dy="3" stdDeviation="5" flood-opacity="0.18"/></filter>
  </defs>

  <!-- Step nodes — hexagonal/rounded boxes arranged in a circle -->
  <!-- 1. Project Scoping — top center -->
  <rect x="370" y="20" width="160" height="72" rx="14" fill="#008A82" filter="url(#sh2)" class="dn" onclick="showDetail(&#39;d2-scope&#39;)"/>
  <text x="450" y="51" text-anchor="middle" font-size="13" font-weight="800" fill="white">1. Project</text>
  <text x="450" y="70" text-anchor="middle" font-size="13" font-weight="800" fill="white">Scoping</text>

  <!-- 2. Data Engineering — right top -->
  <rect x="700" y="140" width="170" height="72" rx="14" fill="#00A39A" filter="url(#sh2)" class="dn" onclick="showDetail(&#39;d2-data&#39;)"/>
  <text x="785" y="171" text-anchor="middle" font-size="13" font-weight="800" fill="white">2. Data</text>
  <text x="785" y="190" text-anchor="middle" font-size="13" font-weight="800" fill="white">Engineering</text>

  <!-- 3. ML Model Development — right bottom -->
  <rect x="700" y="290" width="170" height="72" rx="14" fill="#007a72" filter="url(#sh2)" class="dn" onclick="showDetail(&#39;d2-model&#39;)"/>
  <text x="785" y="321" text-anchor="middle" font-size="13" font-weight="800" fill="white">3. ML Model</text>
  <text x="785" y="340" text-anchor="middle" font-size="13" font-weight="800" fill="white">Development</text>

  <!-- 4. Deployment — bottom center -->
  <rect x="370" y="350" width="160" height="52" rx="14" fill="#4db6ac" filter="url(#sh2)" class="dn" onclick="showDetail(&#39;d2-deploy&#39;)"/>
  <text x="450" y="381" text-anchor="middle" font-size="13" font-weight="800" fill="white">4. Deployment</text>

  <!-- 5. Monitoring — left bottom -->
  <rect x="30" y="290" width="170" height="72" rx="14" fill="#00897b" filter="url(#sh2)" class="dn" onclick="showDetail(&#39;d2-monitor&#39;)"/>
  <text x="115" y="321" text-anchor="middle" font-size="12.5" font-weight="800" fill="white">5. Monitoring &amp;</text>
  <text x="115" y="339" text-anchor="middle" font-size="12.5" font-weight="800" fill="white">Continual Learning</text>

  <!-- 6. Business Analysis — left top -->
  <rect x="30" y="140" width="160" height="72" rx="14" fill="#005f5a" filter="url(#sh2)" class="dn" onclick="showDetail(&#39;d2-biz&#39;)"/>
  <text x="110" y="168" text-anchor="middle" font-size="13" font-weight="800" fill="white">6. Business</text>
  <text x="110" y="187" text-anchor="middle" font-size="13" font-weight="800" fill="white">Analysis</text>

  <!-- SOLID arrows — clockwise main flow -->
  <!-- 1→2 -->
  <path d="M530 56 Q640 56 700 165" stroke="#008A82" stroke-width="2.5" fill="none" marker-end="url(#arr2s)"/>
  <!-- 2→3 -->
  <line x1="785" y1="212" x2="785" y2="290" stroke="#008A82" stroke-width="2.5" marker-end="url(#arr2s)"/>
  <!-- 3→4 -->
  <path d="M700 330 Q640 376 530 376" stroke="#008A82" stroke-width="2.5" fill="none" marker-end="url(#arr2s)"/>
  <!-- 4→5 -->
  <path d="M370 376 Q260 376 200 340" stroke="#008A82" stroke-width="2.5" fill="none" marker-end="url(#arr2s)"/>
  <!-- 5→6 -->
  <line x1="115" y1="290" x2="115" y2="212" stroke="#008A82" stroke-width="2.5" marker-end="url(#arr2s)"/>
  <!-- 6→1 -->
  <path d="M190 165 Q260 56 370 56" stroke="#008A82" stroke-width="2.5" fill="none" marker-end="url(#arr2s)"/>

  <!-- DASHED back-arrows (non-linear jumps) -->
  <!-- 2↔6 diagonal -->
  <line x1="700" y1="160" x2="200" y2="188" stroke="#546e7a" stroke-width="1.5" stroke-dasharray="6,4" marker-end="url(#arr2d)"/>
  <line x1="200" y1="172" x2="700" y2="172" stroke="#546e7a" stroke-width="1.5" stroke-dasharray="6,4" marker-end="url(#arr2d)"/>
  <!-- 3↔5 diagonal -->
  <line x1="700" y1="310" x2="200" y2="310" stroke="#546e7a" stroke-width="1.5" stroke-dasharray="6,4" marker-end="url(#arr2d)"/>
  <line x1="200" y1="326" x2="700" y2="326" stroke="#546e7a" stroke-width="1.5" stroke-dasharray="6,4" marker-end="url(#arr2d)"/>

  <!-- Center label -->
  <rect x="340" y="155" width="220" height="98" rx="12" fill="rgba(0,44,60,0.06)" stroke="#b2dfdb" stroke-width="1" stroke-dasharray="5,3"/>
  <text x="450" y="194" text-anchor="middle" font-size="11.5" fill="#546e7a" font-weight="600">Non-linear process</text>
  <text x="450" y="212" text-anchor="middle" font-size="11" fill="#546e7a">Any step can trigger a</text>
  <text x="450" y="228" text-anchor="middle" font-size="11" fill="#546e7a">return to any prior step</text>

  <!-- Legend -->
  <line x1="320" y1="390" x2="360" y2="390" stroke="#008A82" stroke-width="2.5"/>
  <text x="368" y="394" font-size="10" fill="#546e7a">Main flow</text>
  <line x1="440" y1="390" x2="480" y2="390" stroke="#546e7a" stroke-width="1.5" stroke-dasharray="5,3"/>
  <text x="488" y="394" font-size="10" fill="#546e7a">Back-jumps</text>
</svg>
            '),
            div(class="diag-caption","Figure 2-2 — The ML development process is a cycle with constant back-and-forth between steps. It is NOT waterfall."),
            br(),
            div(id="d2-scope", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d2-scope')","✕"),
              tags$h4("🎯 Step 1 — Project Scoping"),
              tags$p("Huyen: the most underinvested step. Teams rush to modelling without fully scoping the problem, which leads to building the wrong system entirely."),
              tags$ul(
                tags$li(tags$b("What to define:"), " stakeholders, goals, constraints (latency, cost, interpretability, fairness), success metrics (business KPIs, proxy ML metrics), timeline."),
                tags$li(tags$b("The framing decision:"), " is this a classification, regression, ranking, or generation problem? Can it be decomposed into simpler sub-problems?"),
                tags$li(tags$b("Feasibility:"), " is the data available? Is the signal strong enough? What's the floor (random baseline) and ceiling (human-level performance)?"),
                tags$li(tags$b("Interview tip:"), " spend the first 5 minutes of any ML design interview here. Ask clarifying questions before touching data or models.")
              ),
              div(span(class="dp-tag","Problem Framing"), span(class="dp-tag","Success Metrics"), span(class="dp-tag amber","Feasibility Check"), span(class="dp-tag blue","Stakeholder Alignment"))
            ),
            div(id="d2-data", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d2-data')","✕"),
              tags$h4("🗄️ Step 2 — Data Engineering"),
              tags$p("Data engineering is the step where most ML projects fail — not because of poor models, but because the data pipeline is brittle, slow, or incorrect."),
              tags$ul(
                tags$li(tags$b("Data sources:"), " user-generated, system logs, third-party, synthetic. Understand the collection mechanism before trusting the data."),
                tags$li(tags$b("Batch vs streaming:"), " batch for training, streaming for online features. Lambda architecture vs Kappa architecture."),
                tags$li(tags$b("Data quality:"), " completeness, accuracy, consistency, timeliness. Build data validation checks as early as the pipeline."),
                tags$li(tags$b("Back-jumps from here:"), " discovering data quality issues sends you back to scoping (is the problem even solvable?). Finding that labelling is expensive sends you back to scoping (budget negotiation).")
              ),
              div(span(class="dp-tag","Pipeline Design"), span(class="dp-tag","Data Validation"), span(class="dp-tag amber","Batch vs Streaming"), span(class="dp-tag blue","Labelling Strategy"))
            ),
            div(id="d2-model", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d2-model')","✕"),
              tags$h4("🧠 Step 3 — ML Model Development"),
              tags$p("Only at step 3 do you touch algorithms. Huyen's placement of this step is intentional — it signals that model development is not the primary challenge in production ML."),
              tags$ul(
                tags$li(tags$b("Iterative loop within this step:"), " feature engineering → model selection → HPO → evaluation → back to feature engineering."),
                tags$li(tags$b("Feature engineering:"), " the highest-leverage activity. Start here before touching architecture."),
                tags$li(tags$b("Model selection:"), " start simple. Logistic regression sets the bar. GBDTs for tabular. NNs for unstructured data."),
                tags$li(tags$b("Back-jumps from here:"), " model won't learn → back to data engineering (data quality issue). Model learns but offline metrics don't correlate with business → back to scoping (wrong objective).")
              ),
              div(span(class="dp-tag","Feature Engineering"), span(class="dp-tag","Model Selection"), span(class="dp-tag amber","HPO"), span(class="dp-tag blue","Offline Evaluation"))
            ),
            div(id="d2-deploy", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d2-deploy')","✕"),
              tags$h4("🚀 Step 4 — Deployment"),
              tags$p("Deployment is not the end of the process — it's the beginning of the feedback loop. The model starts seeing real distribution data for the first time."),
              tags$ul(
                tags$li(tags$b("Deployment strategies:"), " shadow deployment (safe, expensive), canary release (small % traffic), A/B test (controlled comparison), blue/green (instant rollback)."),
                tags$li(tags$b("Prediction modalities:"), " batch prediction (high throughput, latency-tolerant), online prediction (low-latency, event-driven), streaming prediction (continuous, near-real-time)."),
                tags$li(tags$b("Model compression:"), " quantisation (INT8/FP16), pruning (remove low-weight connections), knowledge distillation (train small model to mimic large). Required for edge/latency-constrained deployments."),
                tags$li(tags$b("Back-jumps:"), " deployment reveals latency issues → back to model development (compression). Deployment reveals data distribution mismatch → back to data engineering.")
              ),
              div(span(class="dp-tag","Deployment Strategies"), span(class="dp-tag","Model Compression"), span(class="dp-tag amber","Latency Budget"), span(class="dp-tag blue","Shadow Mode"))
            ),
            div(id="d2-monitor", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d2-monitor')","✕"),
              tags$h4("📡 Step 5 — Monitoring & Continual Learning"),
              tags$p("Huyen: a deployed model without monitoring is a liability, not an asset. Production data distributions shift — models decay silently without monitoring."),
              tags$ul(
                tags$li(tags$b("What to monitor:"), " operational metrics (latency p50/p95/p99, throughput, error rate), ML metrics (prediction distribution, feature drift, label drift), business metrics (conversion rate, revenue impact)."),
                tags$li(tags$b("Drift types:"), " covariate shift (input X distribution changes), label shift (output Y distribution changes), concept drift (P(Y|X) changes — the hardest to detect)."),
                tags$li(tags$b("Continual learning:"), " stateless retraining (train from scratch on new data window), stateful retraining (fine-tune existing model on new data). Stateful is cheaper but risks catastrophic forgetting."),
                tags$li(tags$b("Retraining triggers:"), " time-based (daily/weekly), performance-based (metric below threshold), drift-based (PSI > 0.2).")
              ),
              div(span(class="dp-tag","Drift Detection"), span(class="dp-tag","PSI / KS-Stat"), span(class="dp-tag amber","Continual Learning"), span(class="dp-tag blue","Retraining Strategy"))
            ),
            div(id="d2-biz", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d2-biz')","✕"),
              tags$h4("📊 Step 6 — Business Analysis"),
              tags$p("The feedback loop closes here. Monitoring data and user behaviour data are analysed to determine whether the ML system is actually achieving the original business goal."),
              tags$ul(
                tags$li(tags$b("Online A/B test results:"), " did the model improve the business KPI, not just the ML metric? This is where offline-online metric correlation is validated."),
                tags$li(tags$b("Cost analysis:"), " infrastructure cost per prediction, cost of errors (FP vs FN asymmetry), ROI of retraining."),
                tags$li(tags$b("User feedback integration:"), " explicit (thumbs down, ratings) and implicit (click-through, dwell time, abandonment) feedback."),
                tags$li(tags$b("Back-jumps:"), " business KPI not improving despite good ML metrics → back to project scoping (wrong objective function). New business requirements → restart the cycle.")
              ),
              div(span(class="dp-tag","A/B Test Analysis"), span(class="dp-tag","ROI Analysis"), span(class="dp-tag amber","Objective Alignment"), span(class="dp-tag blue","User Feedback Loop"))
            )
          )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # DIAGRAM 3 — Figure 2-7: The Data Science Hierarchy of Needs
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title = "Figure 2-7 — The Data Science Hierarchy of Needs",
          status = "warning", solidHeader = TRUE, width = 12,
          div(class="diag-wrap",
            HTML('
<svg viewBox="0 0 900 420" xmlns="http://www.w3.org/2000/svg" style="width:100%;max-width:900px;display:block;margin:0 auto;">
  <defs>
    <filter id="sh3"><feDropShadow dx="0" dy="2" stdDeviation="4" flood-opacity="0.15"/></filter>
  </defs>

  <!-- Layer 1 — Collect (base, widest) -->
  <polygon points="50,370 850,370 800,300 100,300" fill="#006064" filter="url(#sh3)" class="dn" onclick="showDetail(&#39;d3-collect&#39;)"/>
  <text x="450" y="343" text-anchor="middle" font-size="13.5" font-weight="800" fill="white">Collect</text>
  <text x="450" y="362" text-anchor="middle" font-size="11.5" fill="rgba(255,255,255,0.85)">Instrumentation, logging, sensors, external data, user-generated content</text>

  <!-- Layer 2 — Move/Store -->
  <polygon points="100,298 800,298 745,230 155,230" fill="#00796b" filter="url(#sh3)" class="dn" onclick="showDetail(&#39;d3-move&#39;)"/>
  <text x="450" y="258" text-anchor="middle" font-size="13" font-weight="800" fill="white">Move / Store</text>
  <text x="450" y="277" text-anchor="middle" font-size="11" fill="rgba(255,255,255,0.85)">Reliable data flow, infrastructure, pipelines, ETL, structured and unstructured data storage</text>

  <!-- Layer 3 — Explore/Transform -->
  <polygon points="155,228 745,228 685,160 215,160" fill="#00897b" filter="url(#sh3)" class="dn" onclick="showDetail(&#39;d3-explore&#39;)"/>
  <text x="450" y="188" text-anchor="middle" font-size="13" font-weight="800" fill="white">Explore / Transform</text>
  <text x="450" y="207" text-anchor="middle" font-size="11" fill="rgba(255,255,255,0.85)">Cleaning, anomaly detection, preparation</text>

  <!-- Layer 4 — Aggregate/Label -->
  <polygon points="215,158 685,158 625,92 275,92" fill="#26a69a" filter="url(#sh3)" class="dn" onclick="showDetail(&#39;d3-aggregate&#39;)"/>
  <text x="450" y="118" text-anchor="middle" font-size="13" font-weight="800" fill="white">Aggregate / Label</text>
  <text x="450" y="137" text-anchor="middle" font-size="11" fill="rgba(255,255,255,0.9)">Analytics, metrics, segments, aggregates, features, training data</text>

  <!-- Layer 5 — Learn/Optimize -->
  <polygon points="275,90 625,90 565,30 335,30" fill="#4db6ac" filter="url(#sh3)" class="dn" onclick="showDetail(&#39;d3-learn&#39;)"/>
  <text x="450" y="55" text-anchor="middle" font-size="12.5" font-weight="800" fill="#002C3C">Learn / Optimize</text>
  <text x="450" y="72" text-anchor="middle" font-size="10.5" fill="#002C3C">A/B testing, experimentation, simple ML algorithms</text>

  <!-- Apex — AI/Deep Learning label -->
  <text x="450" y="22" text-anchor="middle" font-size="11" font-weight="700" fill="#002C3C">AI / Deep Learning</text>

  <!-- Left axis labels -->
  <text x="38" y="343" text-anchor="end" font-size="11" font-weight="700" fill="#546e7a" dominant-baseline="middle">①</text>
  <text x="88" y="265" text-anchor="end" font-size="11" font-weight="700" fill="#546e7a" dominant-baseline="middle">②</text>
  <text x="142" y="196" text-anchor="end" font-size="11" font-weight="700" fill="#546e7a" dominant-baseline="middle">③</text>
  <text x="200" y="127" text-anchor="end" font-size="11" font-weight="700" fill="#546e7a" dominant-baseline="middle">④</text>
  <text x="260" y="62" text-anchor="end" font-size="11" font-weight="700" fill="#546e7a" dominant-baseline="middle">⑤</text>

  <!-- Arrow indicating hierarchy direction -->
  <line x1="870" y1="370" x2="870" y2="30" stroke="#b2dfdb" stroke-width="1.5" marker-end="url(#arr2s)"/>
  <text x="878" y="200" font-size="10" fill="#80cbc4" writing-mode="vertical-rl" transform="rotate(0,878,200)">Higher value</text>
  <text x="889" y="220" font-size="10" fill="#80cbc4">▲</text>

  <!-- Caption note -->
  <text x="450" y="398" text-anchor="middle" font-size="10.5" fill="#546e7a" font-style="italic">Adapted from Monica Rogati. Most organisations are stuck at levels 1–3, yet rush to AI at level 5.</text>
</svg>
            '),
            div(class="diag-caption","Figure 2-7 — The data science hierarchy of needs. Teams that skip lower levels to pursue AI/deep learning almost always fail in production."),
            br(),
            div(id="d3-collect", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d3-collect')","✕"),
              tags$h4("① Collect — The Foundation of Every ML System"),
              tags$p("Without high-quality, representative data collection, everything above is built on sand. Huyen: organisations routinely underinvest in this layer, then wonder why their models fail."),
              tags$ul(
                tags$li(tags$b("Instrumentation:"), " event tracking, logging schemas. If it isn't logged, it doesn't exist for ML. Instrument everything that could be a useful signal before you need it."),
                tags$li(tags$b("External data:"), " third-party datasets, public APIs, purchased data. Understand provenance, licensing, update cadence, and quality."),
                tags$li(tags$b("User-generated content:"), " the richest signal but hardest to process. Implicit feedback (clicks, dwell time) vs explicit feedback (ratings, reviews)."),
                tags$li(tags$b("Data collection bias:"), " selection bias (what gets logged?), historical bias (past decisions in data), feedback loops (model predictions influence future data). Critical to identify before training.")
              ),
              div(span(class="dp-tag","Event Tracking"), span(class="dp-tag","Instrumentation"), span(class="dp-tag amber","Collection Bias"), span(class="dp-tag blue","Data Provenance"))
            ),
            div(id="d3-move", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d3-move')","✕"),
              tags$h4("② Move / Store — Data Infrastructure"),
              tags$p("Data that can't be reliably moved and stored at scale cannot support ML in production. This is the data engineering foundation described in Chapter 3."),
              tags$ul(
                tags$li(tags$b("Storage formats:"), " row-oriented (CSV, JSON — for writes), column-oriented (Parquet, ORC — for reads/analytics). Parquet is the default for training data."),
                tags$li(tags$b("ETL vs ELT:"), " traditional ETL transforms before loading; modern ELT loads first, transforms later in the warehouse. ELT is now standard for ML pipelines."),
                tags$li(tags$b("Streaming infrastructure:"), " Kafka, Kinesis, Pub/Sub. Enables low-latency feature computation for online prediction."),
                tags$li(tags$b("Data warehouse vs data lake:"), " warehouse (structured, schema-on-write, fast queries) vs lake (schema-on-read, cheap, flexible). Lakehouse (Delta Lake, Iceberg) combines both.")
              ),
              div(span(class="dp-tag","Parquet / ORC"), span(class="dp-tag","Kafka Streaming"), span(class="dp-tag amber","ETL vs ELT"), span(class="dp-tag blue","Data Lakehouse"))
            ),
            div(id="d3-explore", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d3-explore')","✕"),
              tags$h4("③ Explore / Transform — Data Preparation"),
              tags$p("Raw data is almost never suitable for ML training. This layer transforms it into a form models can learn from. Huyen: time spent here saves 10x time debugging model failures."),
              tags$ul(
                tags$li(tags$b("Missing data handling:"), " deletion (if missing at random, low rate), mean/median/mode imputation (introduces bias), learned imputation (missForest, MICE), indicator features."),
                tags$li(tags$b("Anomaly detection:"), " Z-score, IQR, isolation forest, autoencoders. Outliers must be investigated, not blindly removed — they may be the signal, not noise."),
                tags$li(tags$b("Scaling:"), " standardisation (Z-score — for Gaussian-ish distributions), min-max normalisation (for bounded ranges), log transform (for power-law distributions). Neural nets are sensitive to scale; trees are not."),
                tags$li(tags$b("Encoding:"), " one-hot (low cardinality), embedding (high cardinality), hashing trick (unknown cardinality, risk of collisions).")
              ),
              div(span(class="dp-tag","Missing Data"), span(class="dp-tag","Anomaly Detection"), span(class="dp-tag amber","Feature Scaling"), span(class="dp-tag blue","Encoding Strategies"))
            ),
            div(id="d3-aggregate", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d3-aggregate')","✕"),
              tags$h4("④ Aggregate / Label — Creating Training Data"),
              tags$p("This is where raw data becomes supervised training data. Huyen dedicates Chapter 4 to this because the quality of labels is a direct ceiling on model quality."),
              tags$ul(
                tags$li(tags$b("Natural labels:"), " feedback generated by users or systems without human effort. E.g., click-through on recommendations. Label delay can be hours to weeks."),
                tags$li(tags$b("Human labelling:"), " expert vs crowd-sourced. Inter-annotator agreement (Cohen's kappa) is critical — low agreement means the task is ambiguous, not just noisy."),
                tags$li(tags$b("Programmatic labelling (Snorkel):"), " labelling functions + label model. 10–100x cheaper than human labels. Noisy but scalable."),
                tags$li(tags$b("Class imbalance:"), " resampling (oversampling minority / undersampling majority), SMOTE, class weights, focal loss. Always report per-class metrics.")
              ),
              div(span(class="dp-tag","Natural Labels"), span(class="dp-tag","Label Quality"), span(class="dp-tag amber","Class Imbalance"), span(class="dp-tag blue","Programmatic Labelling"))
            ),
            div(id="d3-learn", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d3-learn')","✕"),
              tags$h4("⑤ Learn / Optimize — ML & Experimentation"),
              tags$p("Only at this level does 'machine learning' in the traditional sense begin. The hierarchy makes clear: if lower levels are broken, learning is impossible or misleading."),
              tags$ul(
                tags$li(tags$b("A/B testing:"), " the gold standard for measuring model impact on business metrics. Requires statistical power analysis, holdout groups, and guardrail metrics."),
                tags$li(tags$b("Simple ML first:"), " logistic regression, decision trees, GBDTs. These are often competitive with deep learning on structured data and far easier to debug."),
                tags$li(tags$b("Deep learning:"), " necessary for unstructured data (text, image, audio, video) and when scale is available. Transfer learning dramatically reduces data requirements."),
                tags$li(tags$b("AI/deep learning at the apex:"), " the smallest triangle. Most organisations attempting to start here fail because layers 1–4 are not solid. Building AI on a broken data foundation is one of the most common costly mistakes in the industry.")
              ),
              div(span(class="dp-tag","A/B Testing"), span(class="dp-tag","Transfer Learning"), span(class="dp-tag amber","Deep Learning"), span(class="dp-tag green","Foundation Models"))
            )
          )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # DIAGRAM 4 — Figure 7-6: Online Prediction Architecture
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title = "Figure 7-6 — Online Prediction with Batch + Streaming Features",
          status = "info", solidHeader = TRUE, width = 12,
          div(class="diag-wrap",
            HTML('
<svg viewBox="0 0 900 360" xmlns="http://www.w3.org/2000/svg" style="width:100%;max-width:900px;display:block;margin:0 auto;">
  <defs>
    <marker id="arr4" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#008A82"/>
    </marker>
    <marker id="arr4d" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#90a4ae"/>
    </marker>
    <filter id="sh4"><feDropShadow dx="0" dy="2" stdDeviation="4" flood-opacity="0.15"/></filter>
  </defs>

  <!-- Outer box label -->
  <rect x="15" y="15" width="870" height="310" rx="16" fill="none" stroke="#b2dfdb" stroke-width="2" stroke-dasharray="8,4"/>
  <text x="440" y="40" text-anchor="middle" font-size="14" font-weight="800" fill="#002C3C">Online Prediction (Streaming)</text>

  <!-- App -->
  <rect x="50" y="80" width="140" height="90" rx="14" fill="#008A82" filter="url(#sh4)" class="dn" onclick="showDetail(&#39;d4-app&#39;)"/>
  <text x="120" y="120" text-anchor="middle" font-size="14" font-weight="800" fill="white">App</text>
  <text x="120" y="140" text-anchor="middle" font-size="10.5" fill="rgba(255,255,255,0.8)">(User-facing)</text>

  <!-- Real-time transport -->
  <ellipse cx="150" cy="255" rx="110" ry="45" fill="#00897b" filter="url(#sh4)" class="dn" onclick="showDetail(&#39;d4-transport&#39;)"/>
  <text x="150" y="250" text-anchor="middle" font-size="11.5" font-weight="800" fill="white">Real-time</text>
  <text x="150" y="267" text-anchor="middle" font-size="11.5" font-weight="800" fill="white">Transport</text>

  <!-- Data warehouse -->
  <rect x="340" y="210" width="170" height="90" rx="50" fill="#26a69a" filter="url(#sh4)" class="dn" onclick="showDetail(&#39;d4-dw&#39;)"/>
  <text x="425" y="250" text-anchor="middle" font-size="12" font-weight="800" fill="white">Data</text>
  <text x="425" y="268" text-anchor="middle" font-size="12" font-weight="800" fill="white">Warehouse</text>

  <!-- Prediction service -->
  <rect x="680" y="80" width="185" height="130" rx="14" fill="#005f5a" filter="url(#sh4)" class="dn" onclick="showDetail(&#39;d4-service&#39;)"/>
  <text x="772" y="135" text-anchor="middle" font-size="13" font-weight="800" fill="white">Prediction</text>
  <text x="772" y="155" text-anchor="middle" font-size="13" font-weight="800" fill="white">Service</text>
  <text x="772" y="175" text-anchor="middle" font-size="10" fill="rgba(255,255,255,0.7)">(Model + Serving)</text>

  <!-- Arrows + labels -->
  <!-- 1: App → Prediction Service (request) -->
  <path d="M190 105 L680 120" stroke="#008A82" stroke-width="2" fill="none" marker-end="url(#arr4)"/>
  <rect x="370" y="96" width="100" height="20" rx="5" fill="white" stroke="#b2dfdb" stroke-width="1"/>
  <text x="420" y="110" text-anchor="middle" font-size="10.5" font-weight="600" fill="#008A82">① Requests</text>

  <!-- 3: Prediction Service → App (predictions) -->
  <path d="M680 148 L190 130" stroke="#008A82" stroke-width="2" fill="none" marker-end="url(#arr4)"/>
  <rect x="370" y="138" width="116" height="20" rx="5" fill="white" stroke="#b2dfdb" stroke-width="1"/>
  <text x="428" y="152" text-anchor="middle" font-size="10.5" font-weight="600" fill="#002C3C">③ Predictions</text>

  <!-- App → Real-time transport (logs) -->
  <path d="M120 170 L135 210" stroke="#008A82" stroke-width="1.8" fill="none" marker-end="url(#arr4)"/>
  <text x="90" y="195" font-size="10" fill="#546e7a">↓ Logs</text>

  <!-- Real-time transport → Prediction Service (streaming features) -->
  <path d="M260 240 Q450 200 680 160" stroke="#008A82" stroke-width="2" fill="none" marker-end="url(#arr4)"/>
  <rect x="380" y="196" width="135" height="20" rx="5" fill="white" stroke="#b2dfdb" stroke-width="1"/>
  <text x="447" y="210" text-anchor="middle" font-size="10.5" font-weight="600" fill="#008A82">Streaming features</text>

  <!-- Data warehouse → Prediction Service (batch features) ② -->
  <path d="M510 240 Q600 215 680 190" stroke="#90a4ae" stroke-width="2" fill="none" stroke-dasharray="6,4" marker-end="url(#arr4d)"/>
  <rect x="555" y="226" width="110" height="20" rx="5" fill="white" stroke="#e0e0e0" stroke-width="1"/>
  <text x="610" y="240" text-anchor="middle" font-size="10.5" font-weight="600" fill="#546e7a">② Batch features</text>

  <!-- Real-time → Data warehouse (dashed) -->
  <path d="M260 265 Q310 270 340 255" stroke="#90a4ae" stroke-width="1.5" fill="none" stroke-dasharray="5,3" marker-end="url(#arr4d)"/>

  <!-- Step number callouts -->
  <circle cx="340" cy="104" r="11" fill="#002C3C"/>
  <text x="340" y="108" text-anchor="middle" font-size="10" font-weight="800" fill="white">1</text>
  <circle cx="625" cy="244" r="11" fill="#546e7a"/>
  <text x="625" y="248" text-anchor="middle" font-size="10" font-weight="800" fill="white">2</text>
  <circle cx="625" cy="144" r="11" fill="#002C3C"/>
  <text x="625" y="148" text-anchor="middle" font-size="10" font-weight="800" fill="white">3</text>
</svg>
            '),
            div(class="diag-caption","Figure 7-6 — A simplified architecture for online prediction that uses both batch features and streaming features. Both paths converge at the prediction service."),
            br(),
            div(id="d4-app", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d4-app')","✕"),
              tags$h4("📱 App — The User-Facing Layer"),
              tags$p("The application is the only part of the ML system users interact with directly. From an ML systems perspective, it has two critical roles: request dispatch and log generation."),
              tags$ul(
                tags$li(tags$b("Request dispatch (step ①):"), " sends prediction requests to the prediction service, typically via REST or gRPC. The app should handle the prediction service being unavailable gracefully (fallback logic)."),
                tags$li(tags$b("Log generation:"), " every user action is logged to the real-time transport layer. These logs become natural labels and training features."),
                tags$li(tags$b("Latency budget allocation:"), " if the end-to-end latency SLO is 200ms, the prediction service typically has 50–100ms. The app layer consumes the rest."),
                tags$li(tags$b("Interview tip:"), " always ask 'what's the latency requirement?' before designing the prediction architecture. It determines batch vs streaming vs online.")
              ),
              div(span(class="dp-tag","REST / gRPC"), span(class="dp-tag","Fallback Logic"), span(class="dp-tag amber","Latency SLO"), span(class="dp-tag blue","Log Generation"))
            ),
            div(id="d4-transport", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d4-transport')","✕"),
              tags$h4("⚡ Real-Time Transport — The Streaming Bus"),
              tags$p("The real-time transport layer (Kafka, Kinesis, Pub/Sub) is the nervous system of an online ML system. It decouples producers (app logs) from consumers (feature computation, training pipelines)."),
              tags$ul(
                tags$li(tags$b("Apache Kafka:"), " the industry standard. Partitioned, ordered, durable log. Consumers can replay events. Latency in single-digit milliseconds."),
                tags$li(tags$b("Streaming feature computation:"), " Flink, Spark Streaming, or cloud-native (Kinesis Data Analytics). Computes features like 'user's last 5 clicks' or 'rolling 1-hour transaction count' in near real-time."),
                tags$li(tags$b("Why streaming features matter:"), " batch features (computed daily) miss recent user behaviour. For fraud detection, a user's purchases in the last 5 minutes is far more predictive than yesterday's profile."),
                tags$li(tags$b("Feature store integration:"), " streaming features are typically written to an online feature store (Redis, DynamoDB) for low-latency serving at prediction time.")
              ),
              div(span(class="dp-tag","Apache Kafka"), span(class="dp-tag","Apache Flink"), span(class="dp-tag amber","Streaming Features"), span(class="dp-tag blue","Feature Store"))
            ),
            div(id="d4-dw", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d4-dw')","✕"),
              tags$h4("🏛️ Data Warehouse — Batch Feature Source"),
              tags$p("The data warehouse provides pre-computed batch features: aggregations, user profiles, item embeddings computed on a schedule (hourly, daily). Lower latency requirement than streaming features."),
              tags$ul(
                tags$li(tags$b("Batch features (step ②):"), " user's 30-day purchase history, item's all-time popularity score, demographic features. Computed on a schedule and cached."),
                tags$li(tags$b("Offline feature store:"), " the data warehouse serves as an offline feature store for training. The same features used in training should be reproducible for any historical timestamp (point-in-time correctness)."),
                tags$li(tags$b("Two-tier feature serving:"), " online store (Redis/DynamoDB) for low-latency streaming features + batch features at serving; offline store (data warehouse) for training data generation."),
                tags$li(tags$b("Train-serve skew risk:"), " batch features computed differently at training time vs serving time. Feature store with point-in-time joins solves this — critical to flag in an interview.")
              ),
              div(span(class="dp-tag","Batch Features"), span(class="dp-tag","Point-in-Time Joins"), span(class="dp-tag red","Train-Serve Skew"), span(class="dp-tag blue","Offline Feature Store"))
            ),
            div(id="d4-service", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d4-service')","✕"),
              tags$h4("🔮 Prediction Service — The Model Serving Layer"),
              tags$p("The prediction service receives a prediction request, assembles all features (streaming + batch), runs the model, and returns a prediction — all within the latency SLO."),
              tags$ul(
                tags$li(tags$b("Serving frameworks:"), " TorchServe (PyTorch), TensorFlow Serving, Triton Inference Server (NVIDIA — multi-framework). Triton supports GPU batching which dramatically improves throughput."),
                tags$li(tags$b("Feature assembly:"), " at prediction time, the service must look up both streaming features (from online store) and batch features (from cache/online store) and join them. This join is performance-critical."),
                tags$li(tags$b("Model versioning:"), " the service should support A/B routing between model versions (traffic splitting). Shadow mode: new model runs in parallel, predictions logged but not served."),
                tags$li(tags$b("Model compression for serving:"), " INT8 quantisation can deliver 4x speedup with <1% accuracy loss on most tasks. Critical for GPU cost reduction at scale.")
              ),
              div(span(class="dp-tag","Triton Inference"), span(class="dp-tag","Shadow Mode"), span(class="dp-tag amber","Feature Assembly"), span(class="dp-tag blue","Model Quantisation"))
            )
          )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # DIAGRAM 5 — Figure 7-8: Data Pipeline for Online ML Systems
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title = "Figure 7-8 — Full Data Pipeline for Online ML Systems",
          status = "danger", solidHeader = TRUE, width = 12,
          div(class="diag-wrap",
            HTML('
<svg viewBox="0 0 900 560" xmlns="http://www.w3.org/2000/svg" style="width:100%;max-width:900px;display:block;margin:0 auto;">
  <defs>
    <marker id="arr5" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#008A82"/>
    </marker>
    <marker id="arr5r" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#c0392b"/>
    </marker>
    <filter id="sh5"><feDropShadow dx="0" dy="2" stdDeviation="3" flood-opacity="0.15"/></filter>
  </defs>

  <!-- Title -->
  <rect x="15" y="10" width="870" height="530" rx="16" fill="none" stroke="#b2dfdb" stroke-width="1.5" stroke-dasharray="8,5"/>
  <text x="440" y="36" text-anchor="middle" font-size="14" font-weight="800" fill="#002C3C">Data Pipeline for Online ML Systems</text>

  <!-- Research box (red outline) -->
  <rect x="450" y="50" width="380" height="330" rx="12" fill="rgba(192,57,43,0.04)" stroke="#c0392b" stroke-width="2" stroke-dasharray="6,3"/>
  <text x="640" y="76" text-anchor="middle" font-size="12" font-weight="800" fill="#c0392b">Research / Offline Training</text>

  <!-- LEFT SIDE — Production pipeline -->
  <!-- Streaming data -->
  <rect x="30" y="55" width="155" height="46" rx="10" fill="#008A82" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-stream&#39;)"/>
  <text x="108" y="83" text-anchor="middle" font-size="12" font-weight="700" fill="white">Streaming Data</text>

  <!-- Control? diamond -->
  <polygon points="108,125 148,155 108,185 68,155" fill="#00897b" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-control&#39;)"/>
  <text x="108" y="159" text-anchor="middle" font-size="11" font-weight="700" fill="white">Control?</text>

  <!-- Process -->
  <rect x="55" y="205" width="105" height="40" rx="10" fill="#26a69a" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-process&#39;)"/>
  <text x="108" y="231" text-anchor="middle" font-size="12" font-weight="700" fill="white">Process</text>

  <!-- Store -->
  <rect x="180" y="205" width="95" height="40" rx="10" fill="#4db6ac" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-store&#39;)"/>
  <text x="228" y="231" text-anchor="middle" font-size="12" font-weight="700" fill="white">Store</text>

  <!-- Feature engineer (left) -->
  <rect x="30" y="330" width="155" height="46" rx="10" fill="#00796b" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-feateng&#39;)"/>
  <text x="108" y="353" text-anchor="middle" font-size="11" font-weight="700" fill="white">Feature</text>
  <text x="108" y="369" text-anchor="middle" font-size="11" font-weight="700" fill="white">Engineer</text>

  <!-- RIGHT SIDE — Research box contents -->
  <!-- Data warehouse -->
  <rect x="470" y="90" width="150" height="50" rx="10" fill="#c0392b" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-dw2&#39;)"/>
  <text x="545" y="121" text-anchor="middle" font-size="12" font-weight="700" fill="white">Data Warehouse</text>

  <!-- Ingest -->
  <rect x="490" y="165" width="110" height="40" rx="10" fill="#c0392b" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-ingest&#39;)"/>
  <text x="545" y="191" text-anchor="middle" font-size="12" font-weight="700" fill="white">Ingest</text>

  <!-- Feature engineer (right, research) -->
  <rect x="465" y="225" width="110" height="40" rx="10" fill="#c0392b" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-feateng2&#39;)"/>
  <text x="520" y="241" text-anchor="middle" font-size="11" font-weight="700" fill="white">Feature</text>
  <text x="520" y="257" text-anchor="middle" font-size="11" font-weight="700" fill="white">Engineer</text>

  <!-- Label -->
  <rect x="605" y="225" width="110" height="40" rx="10" fill="#c0392b" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-label&#39;)"/>
  <text x="660" y="250" text-anchor="middle" font-size="12" font-weight="700" fill="white">Label</text>

  <!-- Develop ML model -->
  <ellipse cx="545" cy="310" rx="75" ry="35" fill="#922b21" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-devmodel&#39;)"/>
  <text x="545" y="306" text-anchor="middle" font-size="11" font-weight="700" fill="white">Develop</text>
  <text x="545" y="322" text-anchor="middle" font-size="11" font-weight="700" fill="white">ML Model</text>

  <!-- ML Model (shared — where research meets production) -->
  <rect x="300" y="405" width="300" height="55" rx="12" fill="#002C3C" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-model&#39;)"/>
  <text x="450" y="438" text-anchor="middle" font-size="14" font-weight="800" fill="white">ML Model</text>

  <!-- Logs -->
  <rect x="660" y="415" width="120" height="40" rx="10" fill="#4db6ac" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-logs&#39;)"/>
  <text x="720" y="441" text-anchor="middle" font-size="12" font-weight="700" fill="white">Logs</text>

  <!-- Predictions -->
  <rect x="380" y="490" width="140" height="40" rx="10" fill="#008A82" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-preds&#39;)"/>
  <text x="450" y="516" text-anchor="middle" font-size="12" font-weight="700" fill="white">Predictions</text>

  <!-- Application (gear icon area) -->
  <rect x="340" y="490" width="220" height="40" rx="10" fill="#008A82" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-preds&#39;)"/>
  <text x="450" y="516" text-anchor="middle" font-size="12" font-weight="700" fill="white">⚙ Application + Predictions</text>

  <!-- Inputs -->
  <rect x="620" y="490" width="120" height="40" rx="10" fill="#4db6ac" filter="url(#sh5)" class="dn" onclick="showDetail(&#39;d5-inputs&#39;)"/>
  <text x="680" y="516" text-anchor="middle" font-size="12" font-weight="700" fill="white">Inputs</text>

  <!-- Arrows — production path (left) -->
  <line x1="108" y1="101" x2="108" y2="125" stroke="#008A82" stroke-width="2" marker-end="url(#arr5)"/>
  <line x1="108" y1="185" x2="108" y2="205" stroke="#008A82" stroke-width="2" marker-end="url(#arr5)"/>
  <line x1="160" y1="225" x2="180" y2="225" stroke="#008A82" stroke-width="2" marker-end="url(#arr5)"/>
  <line x1="275" y1="225" x2="470" y2="115" stroke="#008A82" stroke-width="2" marker-end="url(#arr5)"/>
  <line x1="108" y1="245" x2="108" y2="330" stroke="#008A82" stroke-width="2" marker-end="url(#arr5)"/>
  <!-- "Should be equal" label -->
  <line x1="185" y1="352" x2="465" y2="265" stroke="#c0392b" stroke-width="1.5" stroke-dasharray="5,3" marker-end="url(#arr5r)"/>
  <text x="310" y="300" text-anchor="middle" font-size="10" font-weight="600" fill="#c0392b" transform="rotate(-22,310,300)">Should be equal</text>

  <!-- Research path arrows -->
  <line x1="545" y1="140" x2="545" y2="165" stroke="#c0392b" stroke-width="1.8" marker-end="url(#arr5r)"/>
  <line x1="545" y1="205" x2="520" y2="225" stroke="#c0392b" stroke-width="1.8" marker-end="url(#arr5r)"/>
  <line x1="545" y1="205" x2="660" y2="225" stroke="#c0392b" stroke-width="1.8" marker-end="url(#arr5r)"/>
  <line x1="520" y1="265" x2="530" y2="275" stroke="#c0392b" stroke-width="1.8" marker-end="url(#arr5r)"/>
  <line x1="660" y1="265" x2="570" y2="282" stroke="#c0392b" stroke-width="1.8" marker-end="url(#arr5r)"/>

  <!-- Model receives inputs from research and production -->
  <line x1="545" y1="345" x2="510" y2="405" stroke="#002C3C" stroke-width="2.5" marker-end="url(#arr5)"/>
  <line x1="108" y1="376" x2="330" y2="430" stroke="#008A82" stroke-width="2" marker-end="url(#arr5)"/>
  <text x="195" y="418" font-size="10" font-weight="600" fill="#546e7a" transform="rotate(-16,195,418)">Inference</text>

  <!-- Model → Logs, Predictions, Application -->
  <line x1="600" y1="430" x2="660" y2="430" stroke="#008A82" stroke-width="2" marker-end="url(#arr5)"/>
  <line x1="450" y1="460" x2="450" y2="490" stroke="#008A82" stroke-width="2" marker-end="url(#arr5)"/>
  <line x1="560" y1="460" x2="630" y2="490" stroke="#008A82" stroke-width="2" marker-end="url(#arr5)"/>
  <!-- Logs loop back up (to streaming data) -->
  <path d="M720 415 Q800 300 700 100 Q650 55 200 78" stroke="#80cbc4" stroke-width="1.5" fill="none" stroke-dasharray="5,4" marker-end="url(#arr5)"/>
  <text x="760" y="250" font-size="9.5" fill="#80cbc4" text-anchor="middle">feedback</text>
  <text x="760" y="264" font-size="9.5" fill="#80cbc4" text-anchor="middle">loop</text>
</svg>
            '),
            div(class="diag-caption","Figure 7-8 — A data pipeline for ML systems that do online prediction, showing the research (training) path in red and the production (inference) path in teal."),
            br(),
            div(id="d5-stream", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-stream')","✕"),
              tags$h4("📡 Streaming Data — The Production Input"),
              tags$p("In online ML systems, production data arrives as a continuous stream. The pipeline must process it in near real-time to keep features current and catch concept drift early."),
              tags$ul(
                tags$li(tags$b("Sources:"), " user events (clicks, searches, purchases), system events (API calls, errors, transactions), sensor data (IoT), external feeds (market prices, social signals)."),
                tags$li(tags$b("Velocity:"), " can range from thousands to millions of events per second. The pipeline must scale horizontally."),
                tags$li(tags$b("Data quality at the source:"), " malformed events, missing fields, duplicate events are all common. Validate at ingestion, not downstream."),
                tags$li(tags$b("Huyen's warning:"), " if your production streaming data distribution drifts from your training batch data, your model will silently degrade. The feedback loop (logs → stream) is what enables continual learning.")
              ),
              div(span(class="dp-tag","Kafka / Kinesis"), span(class="dp-tag","Event Streams"), span(class="dp-tag amber","Data Quality"), span(class="dp-tag blue","Schema Registry"))
            ),
            div(id="d5-control", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-control')","✕"),
              tags$h4("🔀 Control? — Routing Logic"),
              tags$p("The control decision gate determines how incoming streaming data is routed: directly to feature engineering (fast path), into storage (durable path), or both."),
              tags$ul(
                tags$li(tags$b("Direct processing path:"), " for low-latency features needed immediately (e.g., user's last 3 clicks for a recommendation). Goes directly to process → feature engineer."),
                tags$li(tags$b("Store path:"), " writes to durable storage first, then processes asynchronously. Used for training data generation and batch feature computation."),
                tags$li(tags$b("Lambda architecture:"), " parallel batch and streaming layers. Batch layer for accuracy, speed layer for recency. Complexity of maintaining two systems is the main drawback."),
                tags$li(tags$b("Kappa architecture:"), " streaming only. Replay from the log (Kafka) for batch processing. Simpler, increasingly preferred for modern systems.")
              ),
              div(span(class="dp-tag","Lambda Architecture"), span(class="dp-tag","Kappa Architecture"), span(class="dp-tag amber","Routing Logic"), span(class="dp-tag blue","Fast vs Slow Path"))
            ),
            div(id="d5-process", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-process')","✕"),
              tags$h4("⚙️ Process — Stream Processing"),
              tags$p("Stream processing transforms raw events into structured data and computes time-windowed aggregations that become real-time features."),
              tags$ul(
                tags$li(tags$b("Windowed aggregations:"), " tumbling windows (fixed, non-overlapping), sliding windows (overlapping), session windows (activity-based). E.g., 'sum of purchases in last 1 hour'."),
                tags$li(tags$b("Frameworks:"), " Apache Flink (stateful, exactly-once, industry standard), Spark Streaming (micro-batch, easier ops), Kafka Streams (simple, in-process)."),
                tags$li(tags$b("Late data handling:"), " events can arrive out-of-order due to network delays. Watermarks define how long to wait before closing a window. Critical for correctness."),
                tags$li(tags$b("Stateful processing:"), " maintaining per-user session state across events. Flink's state backend (RocksDB) handles this at scale.")
              ),
              div(span(class="dp-tag","Apache Flink"), span(class="dp-tag","Windowed Aggregations"), span(class="dp-tag amber","Late Data"), span(class="dp-tag blue","Watermarks"))
            ),
            div(id="d5-store", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-store')","✕"),
              tags$h4("💾 Store — Durable Data Storage"),
              tags$p("The store step writes processed events to durable storage for downstream use: training data generation, batch feature computation, audit trails, and replay."),
              tags$ul(
                tags$li(tags$b("Storage destination:"), " object store (S3, GCS) in Parquet format for training data. OLAP database (Redshift, BigQuery, ClickHouse) for analytics queries."),
                tags$li(tags$b("Data partitioning:"), " partition by time (year/month/day/hour) for efficient range queries during training data generation."),
                tags$li(tags$b("Compaction:"), " small files problem — many small Parquet files from streaming writes reduce read performance. Periodic compaction jobs merge them."),
                tags$li(tags$b("Retention policy:"), " how long to keep raw event data? Balance storage cost vs ability to retrain on historical data. Huyen: keep at least the data used to train your current production model.")
              ),
              div(span(class="dp-tag","Parquet on S3"), span(class="dp-tag","Data Partitioning"), span(class="dp-tag amber","Compaction"), span(class="dp-tag blue","Retention Policy"))
            ),
            div(id="d5-feateng", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-feateng')","✕"),
              tags$h4("⚙️ Feature Engineer (Production) — Real-Time Feature Computation"),
              tags$p("The production feature engineer computes features from the live data stream to serve to the prediction service. This is the serving-time counterpart of the training-time feature engineer."),
              tags$ul(
                tags$li(tags$b("\"Should be equal\" annotation:"), " Huyen's most important warning in this diagram. The features computed here at serving time MUST be identical to the features computed in the research box at training time. Any discrepancy is train-serve skew — silent, catastrophic."),
                tags$li(tags$b("Feature store:"), " the architectural solution. Features are registered, versioned, and served from a centralised store. Feast, Tecton, Hopsworks, Vertex Feature Store."),
                tags$li(tags$b("Online vs offline store:"), " online (Redis/DynamoDB) for low-latency serving; offline (data warehouse) for training. Feature store manages the sync between them."),
                tags$li(tags$b("Point-in-time joins:"), " when generating training data, look up feature values at the timestamp of each training example, not the current value. Prevents temporal leakage.")
              ),
              div(span(class="dp-tag red","Train-Serve Skew"), span(class="dp-tag","Feature Store"), span(class="dp-tag amber","Point-in-Time"), span(class="dp-tag blue","Feature Versioning"))
            ),
            div(id="d5-dw2", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-dw2')","✕"),
              tags$h4("🏛️ Data Warehouse (Research) — Training Data Source"),
              tags$p("Inside the research box, the data warehouse is the starting point for all training data generation. It contains the stored, processed events from the production pipeline."),
              tags$ul(
                tags$li(tags$b("Training data generation:"), " SQL queries + feature computation against historical data. Must respect time-based splits — no future data leakage into training."),
                tags$li(tags$b("Snapshot isolation:"), " the data warehouse should support time-travel queries (Delta Lake, Iceberg) so training pipelines can reproduce any historical training set."),
                tags$li(tags$b("Scale:"), " training on years of event data can involve petabytes. Columnar storage + distributed query engines (Spark, Trino, BigQuery) are required."),
                tags$li(tags$b("Feedback from production:"), " prediction logs from the ML model flow back to the data warehouse as natural labels. This closes the training feedback loop.")
              ),
              div(span(class="dp-tag","Time-Travel Queries"), span(class="dp-tag","Training Data Gen"), span(class="dp-tag amber","Natural Labels"), span(class="dp-tag blue","Temporal Splits"))
            ),
            div(id="d5-label", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-label')","✕"),
              tags$h4("🏷️ Label — Ground Truth Generation"),
              tags$p("The label step attaches ground truth labels to training examples. This is where natural labels, human labels, or programmatic labels are joined to the feature data."),
              tags$ul(
                tags$li(tags$b("Label delay:"), " for natural labels, there's a delay between prediction and outcome. Ads: click within 1 hour. E-commerce: purchase within 2 weeks. Longer delay = slower retraining cycles."),
                tags$li(tags$b("Label quality:"), " human labellers have error rates. Use multiple labellers + majority voting or confidence weighting. Track inter-annotator agreement."),
                tags$li(tags$b("Label shift:"), " the distribution of labels in production changes over time. Monitor label statistics as part of your data quality checks."),
                tags$li(tags$b("Hand label vs natural label tradeoff:"), " natural labels are free and scalable but noisy and delayed. Hand labels are expensive but precise. Programmatic labels (Snorkel) are the middle ground.")
              ),
              div(span(class="dp-tag","Label Delay"), span(class="dp-tag","Natural Labels"), span(class="dp-tag amber","Label Quality"), span(class="dp-tag blue","Programmatic Labels"))
            ),
            div(id="d5-devmodel", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-devmodel')","✕"),
              tags$h4("🔬 Develop ML Model — The Research Loop"),
              tags$p("Inside the research box, model development follows Huyen's iterative loop: feature engineering → model selection → HPO → offline evaluation → repeat."),
              tags$ul(
                tags$li(tags$b("Research isolation:"), " the red box represents research that happens offline, on historical data. Models developed here must be validated before reaching production."),
                tags$li(tags$b("Offline evaluation gate:"), " no model exits the research box without passing all offline evaluation checks: aggregate metrics, sliced metrics, calibration, perturbation tests."),
                tags$li(tags$b("Model promotion:"), " validated model is registered in the model registry with metadata (training data version, feature set version, evaluation results, git SHA). From registry → prediction service."),
                tags$li(tags$b("Shadow deployment:"), " new model from research runs in shadow mode alongside production model before full rollout. Predictions are logged but not served.")
              ),
              div(span(class="dp-tag","Research Isolation"), span(class="dp-tag","Model Registry"), span(class="dp-tag amber","Offline Eval Gate"), span(class="dp-tag blue","Shadow Deployment"))
            ),
            div(id="d5-model", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-model')","✕"),
              tags$h4("🧠 ML Model — The Convergence Point"),
              tags$p("The ML Model box is where the research path and production path converge. The trained model artifact (from research) is loaded by the serving infrastructure (production) to serve predictions."),
              tags$ul(
                tags$li(tags$b("Model artifact formats:"), " ONNX (cross-framework, portable), SavedModel (TensorFlow), TorchScript (PyTorch), PMML (classical ML). ONNX enables framework-agnostic serving."),
                tags$li(tags$b("Model registry:"), " centralised store for model versions (MLflow Model Registry, Vertex AI Model Registry). Tracks lineage: training data → model → deployment."),
                tags$li(tags$b("Serving path:"), " production feature engineer computes features → model runs inference → predictions returned to application + logged."),
                tags$li(tags$b("Feedback loop:"), " model logs feed back to the streaming data input, enabling natural label generation and continual learning.")
              ),
              div(span(class="dp-tag","ONNX"), span(class="dp-tag","Model Registry"), span(class="dp-tag amber","Model Lineage"), span(class="dp-tag blue","Inference Path"))
            ),
            div(id="d5-logs", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-logs')","✕"),
              tags$h4("📋 Logs — The Feedback Mechanism"),
              tags$p("Every prediction made by the model is logged. These logs are the raw material for monitoring, natural label generation, debugging, and continual learning."),
              tags$ul(
                tags$li(tags$b("What to log:"), " prediction input features (for debugging), model output (prediction + confidence), model version, timestamp, request ID, user/session context."),
                tags$li(tags$b("Log volume:"), " high-traffic systems generate billions of log events per day. Sampling strategies (systematic, stratified) reduce volume while preserving statistical validity."),
                tags$li(tags$b("Log retention:"), " recent logs for monitoring dashboards (7–30 days), compressed archives for periodic retraining (1–3 years)."),
                tags$li(tags$b("Privacy:"), " raw feature values in logs may contain PII. Apply differential privacy, k-anonymisation, or feature hashing before long-term storage.")
              ),
              div(span(class="dp-tag","Prediction Logging"), span(class="dp-tag","Sampling Strategy"), span(class="dp-tag amber","Log Retention"), span(class="dp-tag blue","Privacy"))
            ),
            div(id="d5-preds", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-preds')","✕"),
              tags$h4("⚙️ Application — Serving Predictions to Users"),
              tags$p("The application layer receives predictions from the ML model and integrates them into the user experience. This is the end of the forward path and the start of the feedback loop."),
              tags$ul(
                tags$li(tags$b("Prediction display:"), " recommendations shown, risk scores used in decisioning, generated text surfaced to users. The UX of prediction display affects engagement, bias perception, and model feedback quality."),
                tags$li(tags$b("Fallback strategies:"), " if the prediction service is unavailable (timeout, error), the application must have a fallback: rule-based default, cached last prediction, or degraded-mode UX."),
                tags$li(tags$b("User feedback capture:"), " explicit (thumbs up/down, rating) and implicit (click, dwell, skip) feedback from user interactions with predictions flows back as training signal."),
                tags$li(tags$b("Inputs loop:"), " raw inputs to the application (user context, request parameters) feed back into the feature engineering step, closing the production loop.")
              ),
              div(span(class="dp-tag","Fallback Strategy"), span(class="dp-tag","User Feedback"), span(class="dp-tag amber","Feedback Loop"), span(class="dp-tag blue","Implicit Labels"))
            ),
            div(id="d5-ingest", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-ingest')","✕"),
              tags$h4("📥 Ingest — Loading Data into the Research Environment"),
              tags$p("The ingest step transfers data from the data warehouse into the research environment (notebooks, training jobs) in a form suitable for feature engineering and model training."),
              tags$ul(
                tags$li(tags$b("Data sampling:"), " for large datasets, stratified sampling ensures the training set preserves the original class distribution. Temporal sampling ensures no future leakage."),
                tags$li(tags$b("Train/val/test split:"), " for time-series data, always split by time (not randomly). Future events must not appear in training data. Huyen: this is one of the most common leakage sources."),
                tags$li(tags$b("Data versioning:"), " snapshot the exact data used for each training run. DVC, Delta Lake, or Iceberg time-travel enable this. Essential for reproducibility."),
                tags$li(tags$b("Schema validation:"), " validate schema and statistics of ingested data before training begins. Catch upstream data pipeline changes early.")
              ),
              div(span(class="dp-tag","Temporal Splits"), span(class="dp-tag","Data Versioning"), span(class="dp-tag red","Leakage Prevention"), span(class="dp-tag blue","Schema Validation"))
            ),
            div(id="d5-feateng2", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-feateng2')","✕"),
              tags$h4("⚙️ Feature Engineer (Research) — Training Feature Computation"),
              tags$p("The research feature engineer computes the same features as the production feature engineer, but applied to historical data for model training. The 'Should be equal' constraint is the critical design requirement."),
              tags$ul(
                tags$li(tags$b("Consistency with production:"), " every feature transformation applied at training time must be exactly reproducible at serving time. Use the same code path, not separate implementations."),
                tags$li(tags$b("Feature store as solution:"), " store feature transformation logic in a feature store that both training and serving call. Same code, same output. This is the architectural solution to train-serve skew."),
                tags$li(tags$b("Temporal correctness:"), " when computing features for a training example at time T, only use data available before T. Never use future information, even implicitly (e.g., global statistics computed on the full dataset include future data)."),
                tags$li(tags$b("Feature documentation:"), " each feature should have: definition, data type, range, update frequency, and known issues. Without this, features become unmaintainable.")
              ),
              div(span(class="dp-tag red","Train-Serve Skew"), span(class="dp-tag","Feature Store"), span(class="dp-tag amber","Temporal Correctness"), span(class="dp-tag blue","Feature Docs"))
            ),
            div(id="d5-inputs", class="detail-panel",
              tags$button(class="close-btn",onclick="hideDetail('d5-inputs')","✕"),
              tags$h4("📤 Inputs — Closing the Production Loop"),
              tags$p("The Inputs node represents the raw inputs to the application feeding back into the feature engineering step, closing the real-time production loop."),
              tags$ul(
                tags$li(tags$b("Request context:"), " user ID, session ID, device type, geographic location, timestamp, and the raw query or item being acted upon."),
                tags$li(tags$b("Contextual features:"), " time-of-day, day-of-week, user's current context (e.g., on mobile vs desktop) are powerful features that can only be computed at request time."),
                tags$li(tags$b("Request logging:"), " the inputs are logged along with the prediction output, enabling post-hoc analysis and natural label attachment when outcome becomes known."),
                tags$li(tags$b("Input validation:"), " validate incoming request inputs before feature engineering. Unexpected input values (null, out-of-range) should be handled gracefully, not silently propagated.")
              ),
              div(span(class="dp-tag","Request Context"), span(class="dp-tag","Contextual Features"), span(class="dp-tag amber","Input Validation"), span(class="dp-tag blue","Request Logging"))
            )
          )
      )
    ),

    # JS to handle show/hide detail panels
    tags$script(HTML('
      function showDetail(id) {
        // hide all panels first
        var panels = document.querySelectorAll(".detail-panel");
        panels.forEach(function(p) { p.classList.remove("visible"); });
        // show the target
        var el = document.getElementById(id);
        if (el) {
          el.classList.add("visible");
          setTimeout(function() {
            el.scrollIntoView({ behavior: "smooth", block: "nearest" });
          }, 50);
        }
      }
      function hideDetail(id) {
        var el = document.getElementById(id);
        if (el) el.classList.remove("visible");
      }
    '))
  )
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SERVER (minimal — this tab is fully client-side interactive)              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
visual_diagrams_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    # No reactive server logic needed — all interactivity is JavaScript
    # Progress is auto-set to 50% when the tab is visited via the overview self-assessment
  })
}
