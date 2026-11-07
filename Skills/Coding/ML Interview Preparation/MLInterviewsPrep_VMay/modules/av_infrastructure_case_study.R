# modules/av_infrastructure_case_study.R
# Use Case: AV Infrastructure Assessment — Atera Analytics / CAM Pathfinder One
# Chang O'Reilly Framework
# JS namespace: avShow(), .av-btn, .av-panel

av_infrastructure_case_study_ui <- function(id) {
  ns <- NS(id)

  js <- "
<script>
function avShow(boxId, panelId) {
  var box = document.getElementById(boxId);
  if (!box) return;
  box.querySelectorAll('.av-panel').forEach(function(p){ p.style.display='none'; });
  box.querySelectorAll('.av-btn').forEach(function(b){ b.classList.remove('active'); });
  var panel = document.getElementById(panelId);
  if (panel) panel.style.display='block';
  event.target.classList.add('active');
}
window.addEventListener('load', function(){
  ['av-box1','av-box2','av-box3','av-box4','av-box5','av-box6','av-box7'].forEach(function(boxId){
    var box = document.getElementById(boxId);
    if (!box) return;
    var btn = box.querySelector('.av-btn');
    var pnl = box.querySelector('.av-panel');
    if (btn) btn.classList.add('active');
    if (pnl) pnl.style.display='block';
  });
});
</script>"

  avBtn <- function(boxId, panelId, label) {
    tags$button(class="av-btn",
      style="margin:2px 4px 2px 0;padding:5px 12px;border:none;border-radius:4px;cursor:pointer;font-size:12px;background:#1a2332;color:#cdd6e0;transition:all .2s;",
      onclick=paste0("avShow('",boxId,"','",panelId,"')"), label)
  }
  avPanel <- function(panelId, ...) {
    div(id=panelId, class="av-panel", style="display:none;padding-top:10px;", ...)
  }

  tagList(
    HTML(js),

    # ── Chang Chapter Connections ────────────────────────────────────────────
    fluidRow(
      box(title=NULL, status="info", solidHeader=FALSE, width=12,
        div(class="info-box-plain",
          HTML("<strong>Chang Chapter Connections:</strong> This case study applies
               every chapter from <em>Machine Learning Interviews</em> (O'Reilly) to a real production system.
               <strong>Ch.1</strong> — ML role scoping and Three Pillars.
               <strong>Ch.2</strong> — how this system type appears in job postings.
               <strong>Ch.3</strong> — which algorithms are used and why.
               <strong>Ch.4</strong> — data acquisition, feature engineering, training, evaluation.
               <strong>Ch.6</strong> — deployment patterns, monitoring, and MLOps.
               Each box below maps to the relevant Chang chapter.")
        )
      )
    ),

    # ── Hero ──
    div(class="meta-hero",
        tags$h1("AV Infrastructure Assessment"),
        tags$h2("Atera Analytics / CAM Pathfinder One — Chang O'Reilly Framework"),
        div(span(class="hero-badge","Innovate UK 10153306"),
            span(class="hero-badge","AV Act 2024"),
            span(class="hero-badge","YOLOv8 + XGBoost"),
            span(class="hero-badge","Isaac Sim Physics"),
            span(class="hero-badge","Cambridge ODD"))),

    # ── Architecture Overview ──
    fluidRow(
      box(title="AteraSuite v3.0 — ML System Architecture", status="primary", solidHeader=TRUE, width=12,
          div(style="overflow-x:auto;",
              HTML('
<svg viewBox="0 0 900 220" xmlns="http://www.w3.org/2000/svg" style="width:100%;max-width:900px;font-family:Inter,sans-serif;">
  <defs>
    <marker id="av-arr" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#e8410a"/>
    </marker>
  </defs>
  <!-- Data Sources row -->
  <text x="450" y="16" text-anchor="middle" fill="#9ca3af" font-size="9">DATA SOURCES</text>
  <rect x="10"  y="22" width="110" height="28" rx="4" fill="#1a2332" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="65"  y="39" text-anchor="middle" fill="#93c5fd" font-size="8">OSM Road Network</text>
  <rect x="130" y="22" width="110" height="28" rx="4" fill="#1a2332" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="185" y="39" text-anchor="middle" fill="#93c5fd" font-size="8">Google Street View</text>
  <rect x="250" y="22" width="110" height="28" rx="4" fill="#1a2332" stroke="#6b7280" stroke-width="1.5"/>
  <text x="305" y="39" text-anchor="middle" fill="#d1d5db" font-size="8">Isaac Sim (Physics)</text>
  <rect x="370" y="22" width="110" height="28" rx="4" fill="#1a2332" stroke="#6b7280" stroke-width="1.5"/>
  <text x="425" y="39" text-anchor="middle" fill="#d1d5db" font-size="8">EV Telemetry API</text>
  <rect x="490" y="22" width="120" height="28" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.5"/>
  <text x="550" y="39" text-anchor="middle" fill="#fcd34d" font-size="8">Expert Risk Labels</text>
  <!-- Arrows down -->
  <line x1="65"  y1="50" x2="150" y2="88" stroke="#3b82f6" stroke-width="1.2" marker-end="url(#av-arr)"/>
  <line x1="185" y1="50" x2="185" y2="88" stroke="#3b82f6" stroke-width="1.2" marker-end="url(#av-arr)"/>
  <line x1="305" y1="50" x2="260" y2="88" stroke="#6b7280" stroke-width="1.2" marker-end="url(#av-arr)"/>
  <line x1="425" y1="50" x2="330" y2="88" stroke="#6b7280" stroke-width="1.2" marker-end="url(#av-arr)"/>
  <line x1="550" y1="50" x2="400" y2="88" stroke="#f59e0b" stroke-width="1.2" marker-end="url(#av-arr)"/>
  <!-- Feature extraction -->
  <rect x="100" y="88" width="160" height="35" rx="5" fill="#0f2444" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="180" y="107" text-anchor="middle" fill="#93c5fd" font-size="9" font-weight="bold">YOLOv8n Detection</text>
  <text x="180" y="119" text-anchor="middle" fill="#9ca3af" font-size="8">Roundabout/Junction/Tunnel/Signal</text>
  <rect x="280" y="88" width="160" height="35" rx="5" fill="#0f2444" stroke="#6b7280" stroke-width="1.5"/>
  <text x="360" y="107" text-anchor="middle" fill="#d1d5db" font-size="9" font-weight="bold">OSM Feature Extraction</text>
  <text x="360" y="119" text-anchor="middle" fill="#9ca3af" font-size="8">Bearing, gradient, speed limit, junctions</text>
  <rect x="460" y="88" width="140" height="35" rx="5" fill="#0f2444" stroke="#f59e0b" stroke-width="1.5"/>
  <text x="530" y="107" text-anchor="middle" fill="#fcd34d" font-size="9" font-weight="bold">Isaac Sim Features</text>
  <text x="530" y="119" text-anchor="middle" fill="#9ca3af" font-size="8">Energy, force, braking, lateral acc</text>
  <!-- Feature store -->
  <line x1="180" y1="123" x2="310" y2="152" stroke="#e8410a" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <line x1="360" y1="123" x2="360" y2="152" stroke="#e8410a" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <line x1="530" y1="123" x2="415" y2="152" stroke="#e8410a" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <rect x="250" y="152" width="220" height="32" rx="6" fill="#0c1f3a" stroke="#e8410a" stroke-width="2"/>
  <text x="360" y="170" text-anchor="middle" fill="#fca5a5" font-size="10" font-weight="bold">50-Feature Vector per Road Segment</text>
  <text x="360" y="181" text-anchor="middle" fill="#9ca3af" font-size="8">~500 segments Cambridge pilot ODD</text>
  <!-- XGBoost -->
  <line x1="360" y1="184" x2="360" y2="202" stroke="#e8410a" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <rect x="270" y="202" width="180" height="16" rx="4" fill="#1a2332" stroke="#10b981" stroke-width="1.5"/>
  <text x="360" y="214" text-anchor="middle" fill="#6ee7b7" font-size="9" font-weight="bold">XGBoost AV Readiness Score (0-1)</text>
  <!-- Risk map -->
  <line x1="450" y1="210" x2="640" y2="175" stroke="#10b981" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <rect x="640" y="152" width="170" height="55" rx="6" fill="#0c1f3a" stroke="#10b981" stroke-width="2"/>
  <text x="725" y="173" text-anchor="middle" fill="#6ee7b7" font-size="10" font-weight="bold">AteraSuite Risk Map</text>
  <text x="725" y="187" text-anchor="middle" fill="#9ca3af" font-size="8">Leaflet interactive map</text>
  <text x="725" y="199" text-anchor="middle" fill="#9ca3af" font-size="8">GREEN/AMBER/RED segments</text>
  <!-- CAV Route Optimizer -->
  <rect x="640" y="60" width="170" height="50" rx="6" fill="#1a2332" stroke="#f59e0b" stroke-width="1.5"/>
  <text x="725" y="82" text-anchor="middle" fill="#fcd34d" font-size="10" font-weight="bold">CAV Route Optimizer</text>
  <text x="725" y="96" text-anchor="middle" fill="#9ca3af" font-size="8">Multi-criteria: safety+energy+time</text>
  <text x="725" y="108" text-anchor="middle" fill="#9ca3af" font-size="8">Pareto-optimal routes (3-5)</text>
  <line x1="725" y1="110" x2="725" y2="152" stroke="#f59e0b" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <!-- Innovate UK label -->
  <rect x="820" y="22" width="75" height="45" rx="4" fill="#1a2332" stroke="#374151" stroke-width="1"/>
  <text x="857" y="42" text-anchor="middle" fill="#9ca3af" font-size="8" font-weight="bold">Innovate UK</text>
  <text x="857" y="54" text-anchor="middle" fill="#9ca3af" font-size="8">10153306</text>
  <text x="857" y="63" text-anchor="middle" fill="#6b7280" font-size="7">WP1-WP8</text>
</svg>'
              ))
      )
    ),

    # ── BOX 1: Ch.1-2 Requirements ──
    fluidRow(
      box(title="Box 1 — Chang Ch.1+4: ML Role Requirements & Problem Framing", status="primary", solidHeader=TRUE, width=12,
          id="av-box1",
          div(avBtn("av-box1","av1p1","Chang 6-Step Applied"),
              avBtn("av-box1","av1p2","ML Task Decomposition"),
              avBtn("av-box1","av1p3","SLOs & Constraints"),
              avBtn("av-box1","av1p4","Innovate UK WP Mapping")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          avPanel("av1p1",
            div(class="success-box", HTML("<strong>Chang Ch.1 Applied:</strong> The AV readiness problem requires precise decomposition before any model is chosen. The business goal — 'identify which road segments are safe for autonomous vehicles' — must be translated into a well-specified ML prediction task with measurable success criteria and explicit regulatory constraints (AV Act 2024).")),
            br(),
            div(class="framework-card",
              tags$h5("Chang ML Design Framework Loop — AV Infrastructure"),
              tags$p(tags$b("1. Clarify requirements:"), " Predict AV readiness score (0-1) per road segment. Threshold-based risk classification: LOW (>0.65), MEDIUM (0.35-0.65), CRITICAL (<0.35). Regulatory constraint: AV Act 2024 requires calibrated, explainable scores for ODD declaration."),
              tags$p(tags$b("2. Data pipeline:"), " OSM road geometry (dodgr/osmdata) + Google Street View images + Isaac Sim physics outputs + expert risk labels. All batch — no real-time requirement. ~500 segments in Cambridge pilot ODD."),
              tags$p(tags$b("3. Feature engineering:"), " 50-feature vector per segment: 13 physics features (Isaac Sim), 12 YOLO detection features, 25 OSM geometry features. Expert labels computed at segment level via multi-criteria rubric."),
              tags$p(tags$b("4. Model architecture:"), " YOLOv8n for visual detection (fine-tuned on AV-critical classes). XGBoost for readiness scoring (handles mixed feature types, provides SHAP). Physics model (Isaac Sim) as deterministic feature generator."),
              tags$p(tags$b("5. Evaluation:"), " Spatial hold-out split (not random — adjacent segments correlated). Sliced eval by road class, vehicle type, ODD type. Calibration mandatory for regulatory safety case."),
              tags$p(tags$b("6. Serving & monitoring:"), " Batch pre-deployment analysis (minutes per route). Flask HTTP API for Isaac Sim. R Shiny + Leaflet interactive risk map. Quarterly retrain as roads change.")
            )
          ),

          avPanel("av1p2",
            div(class="section-heading-dark", "ML Task Decomposition — Chang Ch.1"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Primary ML Tasks"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Task"), tags$th("Type"), tags$th("Model"), tags$th("Output"))),
                    tags$tbody(
                      tags$tr(tags$td("AV Readiness Scoring"), tags$td("Regression (0-1)"), tags$td("XGBoost"), tags$td("Score per segment")),
                      tags$tr(tags$td("Risk Classification"), tags$td("3-class (L/M/C)"), tags$td("XGBoost threshold"), tags$td("LOW/MEDIUM/CRITICAL")),
                      tags$tr(tags$td("Visual Hazard Detection"), tags$td("Object detection"), tags$td("YOLOv8n"), tags$td("Bounding boxes + class")),
                      tags$tr(tags$td("Route Optimisation"), tags$td("Multi-criteria ranking"), tags$td("CAV Route Optimizer"), tags$td("Pareto-optimal routes")),
                      tags$tr(tags$td("Energy Estimation"), tags$td("Physics simulation"), tags$td("Isaac Sim (deterministic)"), tags$td("kWh/km per segment"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Chang: Why Not a Single Model?"),
                  tags$p("Chang recommends task decomposition rather than one monolithic model:"),
                  tags$ul(
                    tags$li(tags$b("YOLOv8 handles visual:"), " COCO pretrained weights are free differentiation. Fine-tune only on AV-specific classes (roundabout, tunnel, signal, junction type)."),
                    tags$li(tags$b("XGBoost handles tabular:"), " Mixes visual features (YOLO outputs), physics features (Isaac Sim), and geometry features (OSM). SHAP explainability is required by Innovate UK safety case."),
                    tags$li(tags$b("Isaac Sim is deterministic:"), " Not ML — it is a physics engine. Chang's pattern: use simulation to generate labels and features where real-world collection is infeasible or dangerous."),
                    tags$li(tags$b("Regulatory clarity:"), " Each component has a clear function and can be independently validated for the AV Act 2024 safety case.")
                  )
                )
              )
            )
          ),

          avPanel("av1p3",
            div(class="section-heading-dark", "Non-Functional Requirements & SLOs — Chang Ch.4"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Latency SLOs by Component"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Component"), tags$th("Mode"), tags$th("SLO"), tags$th("Notes"))),
                    tags$tbody(
                      tags$tr(tags$td("Route Sampler (OSM)"), tags$td("Batch"), tags$td("<30s"), tags$td("dodgr graph query")),
                      tags$tr(tags$td("Street View Fetch"), tags$td("Batch"), tags$td("<5 min"), tags$td("Per-segment API calls")),
                      tags$tr(tags$td("YOLOv8n Inference"), tags$td("Batch GPU"), tags$td("<2 min"), tags$td("All segments in route")),
                      tags$tr(tags$td("Isaac Sim HTTP"), tags$td("Batch REST"), tags$td("<10 min"), tags$td("Flask API; async jobs")),
                      tags$tr(tags$td("XGBoost Scoring"), tags$td("Batch"), tags$td("<15s"), tags$td("500 segments")),
                      tags$tr(tags$td("Risk Map Render"), tags$td("Interactive"), tags$td("<1s"), tags$td("Leaflet tile serve")),
                      tags$tr(tags$td(tags$b("Total end-to-end")), tags$td("Batch"), tags$td(tags$b("<20 min")), tags$td("Pre-deployment analysis"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Chang Constraint Taxonomy Applied"),
                  div(class="warn-box", tags$small(HTML("<strong>Regulatory constraints dominate</strong> this project — more so than typical ML systems. AV Act 2024 requirements shape every design decision."))),
                  br(),
                  tags$ul(
                    tags$li(tags$b("AV Act 2024:"), " CRITICAL classification must represent genuine risk (calibration mandatory). ODD boundary declaration requires SHAP + reliability diagram as evidence."),
                    tags$li(tags$b("Innovate UK WP evidence:"), " Each Work Package has specific deliverables: WP5 = safety case, WP6 = model validation, WP7 = evaluation report."),
                    tags$li(tags$b("Compute constraints:"), " T500 workstation, 4GB VRAM — YOLOv8n (nano) only. YOLOv8s requires 8GB."),
                    tags$li(tags$b("Data constraints:"), " 500 segments is small. k=5 cross-validation mandatory. Cannot collect real CRITICAL scenario data safely — Isaac Sim fills this gap."),
                    tags$li(tags$b("GDPR:"), " Street View images retained >30 days requires privacy impact assessment.")
                  )
                )
              )
            )
          ),

          avPanel("av1p4",
            div(class="section-heading-dark", "Innovate UK Work Package Mapping to Chang Framework"),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("WP"), tags$th("Title"), tags$th("Chang Chapter"), tags$th("ML Deliverable"))),
              tags$tbody(
                tags$tr(tags$td("WP1"), tags$td("Project Management"), tags$td("Ch.1 — Requirements"), tags$td("System specification document; stakeholder requirements")),
                tags$tr(tags$td("WP2"), tags$td("AV Infrastructure Survey"), tags$td("Ch.3 — Data Pipeline"), tags$td("OSM + Street View data collection pipeline; segment database")),
                tags$tr(tags$td("WP3"), tags$td("Physics Modelling"), tags$td("Ch.3-4 — Features"), tags$td("Isaac Sim integration; 13 physics features per segment")),
                tags$tr(tags$td("WP4"), tags$td("Computer Vision"), tags$td("Ch.4-5 — Modelling"), tags$td("YOLOv8n fine-tuning; COCO + AV-class training data")),
                tags$tr(tags$td("WP5"), tags$td("Safety Case"), tags$td("Ch.6 — Evaluation"), tags$td("Sliced evaluation report; SHAP explainability; calibration plots")),
                tags$tr(tags$td("WP6"), tags$td("Model Validation"), tags$td("Ch.6 — Evaluation"), tags$td("A/B test vs CAV Route Optimizer; route interleaving; WP6.6 evidence")),
                tags$tr(tags$td("WP7"), tags$td("Pilot Deployment"), tags$td("Ch.7 — Serving"), tags$td("Phased rollout: shadow → canary → full. ODD boundary definition.")),
                tags$tr(tags$td("WP8"), tags$td("Dissemination"), tags$td("Ch.8 — Monitoring"), tags$td("Monitoring dashboard; drift detection; retraining pipeline"))
              )
            )
          )
      )
    ),

    # ── BOX 2: Ch.3 Data Pipeline ──
    fluidRow(
      box(title="Box 2 — Chang Ch.4: Data Acquisition & Pipeline Design", status="warning", solidHeader=TRUE, width=12,
          id="av-box2",
          div(avBtn("av-box2","av2p1","Data Sources & Collection"),
              avBtn("av-box2","av2p2","Batch Pipeline Architecture"),
              avBtn("av-box2","av2p3","Isaac Sim — Data Catch-22"),
              avBtn("av-box2","av2p4","Data Quality & Schema")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          avPanel("av2p1",
            fluidRow(
              column(6,
                div(class="section-heading-dark", "Five Data Sources — Chang Ch.4 Analysis"),
                tags$table(class="table table-sm",
                  tags$thead(tags$tr(tags$th("Source"), tags$th("Type"), tags$th("Volume"), tags$th("Freshness"), tags$th("Access"))),
                  tags$tbody(
                    tags$tr(tags$td("OSM Road Network"), tags$td("Geospatial graph"), tags$td("~500 segments"), tags$td("Weekly update"), tags$td("osmdata R package (free)")),
                    tags$tr(tags$td("Google Street View"), tags$td("Images"), tags$td("2-5 images/segment"), tags$td("1-3 years old"), tags$td("Street View Static API (paid)")),
                    tags$tr(tags$td("Isaac Sim"), tags$td("Physics simulation"), tags$td("13 features/segment"), tags$td("On-demand"), tags$td("NVIDIA Isaac Sim (on T500)")),
                    tags$tr(tags$td("EV Telemetry"), tags$td("Sensor time series"), tags$td("Future: kWh/km"), tags$td("Real-time (Phase 2)"), tags$td("CAN bus / OBD-II")),
                    tags$tr(tags$td("Expert Labels"), tags$td("Risk rubric scores"), tags$td("~500 labels"), tags$td("Manual, quarterly"), tags$td("Domain expert annotation (AteraSuite)")
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Chang Data Source Analysis — AV Context"),
                  tags$ul(
                    tags$li(tags$b("OSM quality variance:"), " Cambridge city centre OSM is excellent. Rural roads have missing attributes (no speed limit, missing lane count). Chang: always profile data quality per geographic slice before modelling."),
                    tags$li(tags$b("Street View vintage:"), " Images may be 1-3 years old. Construction zones, new road markings not captured. Chang: document data freshness constraints in requirements."),
                    tags$li(tags$b("Expert label scarcity:"), " 500 labels is the hard constraint. Chang: with small datasets, cross-validation and SHAP overfitting detection are mandatory."),
                    tags$li(tags$b("Isaac Sim as data generator:"), " Chang pattern — use simulation to generate training data for scenarios where real-world collection is infeasible (CRITICAL hazards cannot be deliberately created).")
                  )
                )
              )
            )
          ),

          avPanel("av2p2",
            div(class="section-heading-dark", "Batch Pipeline Architecture — Chang Ch.4"),
            div(style="overflow-x:auto;",
              HTML('
<svg viewBox="0 0 800 230" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="400" y="16" text-anchor="middle" fill="#e8410a" font-size="12" font-weight="bold">AV Infrastructure — Batch Data Pipeline (Chang Ch.4)</text>
  <!-- Step 1 OSM -->
  <rect x="10" y="30" width="130" height="45" rx="5" fill="#0f2444" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="75" y="50" text-anchor="middle" fill="#93c5fd" font-size="9" font-weight="bold">OSM Ingest</text>
  <text x="75" y="63" text-anchor="middle" fill="#9ca3af" font-size="8">osmdata::opq()</text>
  <text x="75" y="73" text-anchor="middle" fill="#6b7280" font-size="7">dodgr graph</text>
  <line x1="140" y1="52" x2="175" y2="52" stroke="#3b82f6" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <!-- Step 2 Segment -->
  <rect x="175" y="30" width="130" height="45" rx="5" fill="#0f2444" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="240" y="50" text-anchor="middle" fill="#93c5fd" font-size="9" font-weight="bold">Route Sampler</text>
  <text x="240" y="63" text-anchor="middle" fill="#9ca3af" font-size="8">Split to 100m segments</text>
  <text x="240" y="73" text-anchor="middle" fill="#6b7280" font-size="7">Extract OSM attrs</text>
  <line x1="305" y1="52" x2="340" y2="52" stroke="#3b82f6" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <!-- Step 3 Street View -->
  <rect x="340" y="30" width="130" height="45" rx="5" fill="#0f2444" stroke="#6b7280" stroke-width="1.5"/>
  <text x="405" y="50" text-anchor="middle" fill="#d1d5db" font-size="9" font-weight="bold">Street View Fetch</text>
  <text x="405" y="63" text-anchor="middle" fill="#9ca3af" font-size="8">Static API (lat/lng/heading)</text>
  <text x="405" y="73" text-anchor="middle" fill="#6b7280" font-size="7">2-5 images per segment</text>
  <line x1="470" y1="52" x2="505" y2="52" stroke="#6b7280" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <!-- Step 4 YOLO -->
  <rect x="505" y="30" width="130" height="45" rx="5" fill="#0f2444" stroke="#f59e0b" stroke-width="1.5"/>
  <text x="570" y="50" text-anchor="middle" fill="#fcd34d" font-size="9" font-weight="bold">YOLOv8n Detect</text>
  <text x="570" y="63" text-anchor="middle" fill="#9ca3af" font-size="8">Fine-tuned AV classes</text>
  <text x="570" y="73" text-anchor="middle" fill="#6b7280" font-size="7">T500 4GB GPU batch</text>
  <line x1="635" y1="52" x2="670" y2="52" stroke="#f59e0b" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <!-- Step 5 Features -->
  <rect x="670" y="30" width="120" height="45" rx="5" fill="#0f2444" stroke="#10b981" stroke-width="1.5"/>
  <text x="730" y="50" text-anchor="middle" fill="#6ee7b7" font-size="9" font-weight="bold">Feature Assembly</text>
  <text x="730" y="63" text-anchor="middle" fill="#9ca3af" font-size="8">50 features per segment</text>
  <text x="730" y="73" text-anchor="middle" fill="#6b7280" font-size="7">OSM + YOLO + Sim</text>
  <!-- Isaac Sim branch -->
  <rect x="340" y="105" width="130" height="45" rx="5" fill="#1a2332" stroke="#6b7280" stroke-width="1.5"/>
  <text x="405" y="124" text-anchor="middle" fill="#d1d5db" font-size="9" font-weight="bold">Isaac Sim</text>
  <text x="405" y="137" text-anchor="middle" fill="#9ca3af" font-size="8">Flask HTTP REST API</text>
  <text x="405" y="147" text-anchor="middle" fill="#6b7280" font-size="7">POST /run_scenario</text>
  <line x1="405" y1="105" x2="405" y2="75" stroke="#6b7280" stroke-width="1" stroke-dasharray="4,3"/>
  <line x1="470" y1="127" x2="670" y2="65" stroke="#6b7280" stroke-width="1" stroke-dasharray="4,3" marker-end="url(#av-arr)"/>
  <!-- Feature store box -->
  <line x1="730" y1="75" x2="730" y2="165" stroke="#e8410a" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <rect x="560" y="165" width="340" height="35" rx="6" fill="#0c1f3a" stroke="#e8410a" stroke-width="2"/>
  <text x="730" y="185" text-anchor="middle" fill="#fca5a5" font-size="10" font-weight="bold">Segment Feature Store — CSV / GCS Parquet</text>
  <text x="730" y="196" text-anchor="middle" fill="#9ca3af" font-size="8">~500 rows x 50 features + expert_risk_label</text>
  <!-- XGBoost + Leaflet -->
  <line x1="730" y1="200" x2="400" y2="218" stroke="#10b981" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <rect x="250" y="210" width="300" height="18" rx="4" fill="#1a2332" stroke="#10b981" stroke-width="1"/>
  <text x="400" y="223" text-anchor="middle" fill="#6ee7b7" font-size="9">XGBoost Scoring → Leaflet Risk Map</text>
  <!-- Duration labels -->
  <text x="75"  y="88" text-anchor="middle" fill="#6b7280" font-size="7">~30s</text>
  <text x="240" y="88" text-anchor="middle" fill="#6b7280" font-size="7">~45s</text>
  <text x="405" y="88" text-anchor="middle" fill="#6b7280" font-size="7">~5 min</text>
  <text x="570" y="88" text-anchor="middle" fill="#6b7280" font-size="7">~2 min</text>
  <text x="730" y="88" text-anchor="middle" fill="#6b7280" font-size="7">~15s</text>
  <text x="405" y="160" text-anchor="middle" fill="#6b7280" font-size="7">~10 min</text>
</svg>'
            ))
          ),

          avPanel("av2p3",
            div(class="warn-box", HTML("<strong>Chang Ch.4 — The AV Data Catch-22:</strong> You cannot collect real-world CRITICAL scenario training data safely (driving AV into tunnels/roundabouts/extreme gradients to gather failure data would be dangerous). But without CRITICAL scenario data, the model cannot learn to classify them accurately. Chang's framework documents simulation as the principled solution.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Isaac Sim as Synthetic Data Generator"),
                  tags$p("NVIDIA Isaac Sim (PhysX engine) provides deterministic physics simulation for AV scenarios:"),
                  tags$ul(
                    tags$li(tags$b("Energy consumption:"), " kWh/km per segment — validated against EV spec sheets (±5% tyre hysteresis, ±2% drivetrain)"),
                    tags$li(tags$b("Braking forces:"), " g-force at junctions, roundabout entries — computed from speed limit + geometry"),
                    tags$li(tags$b("Lateral acceleration:"), " Curve and roundabout traversal at different speeds"),
                    tags$li(tags$b("Gradient forces:"), " Elevation change → additional motor load"),
                    tags$li(tags$b("Key advantage:"), " Generates CRITICAL scenario physics without physically running AV through dangerous environments")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Sim-to-Real Gap — Chang Validation"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Feature"), tags$th("Sim Error"), tags$th("Cause"), tags$th("Acceptable?"))),
                    tags$tbody(
                      tags$tr(tags$td("Energy kWh/km"), tags$td("±5%"), tags$td("Tyre hysteresis, HVAC"), tags$td("\u2705 Yes")),
                      tags$tr(tags$td("Braking force"), tags$td("±10%"), tags$td("Road surface texture"), tags$td("\u2705 Yes")),
                      tags$tr(tags$td("Lateral acc"), tags$td("±15%"), tags$td("IRI, weather"), tags$td("\u26A0 Monitor")),
                      tags$tr(tags$td("GPS position"), tags$td("0%"), tags$td("Perfect in sim"), tags$td("\u274C Not real — urban canyon GPS error not modelled")),
                      tags$tr(tags$td("LiDAR point cloud"), tags$td("N/A in sim"), tags$td("Not yet integrated"), tags$td("\u26A0 Phase 3 gap"))
                    )
                  )
                ),
                div(class="tip-box", tags$small(HTML("<strong>Chang interview point:</strong> Sim-to-real gap validation is mandatory before using simulation data in production ML. Document the gap quantitatively and flag features where sim diverges from reality.")))
              )
            )
          ),

          avPanel("av2p4",
            div(class="section-heading-dark", "Data Quality & Schema Management — Chang Ch.4"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Data Quality Checks"),
                  tags$ul(
                    tags$li(tags$b("OSM null rate:"), " Speed limit missing on ~15% of B-roads. Imputation strategy: use road class median speed limit (dodgr road type lookup)."),
                    tags$li(tags$b("Street View coverage:"), " ~3% of rural segments have no Street View coverage. Flag as 'visual_data_missing' — YOLO features default to zero. Important: zero YOLO features ≠ no hazards. Document this bias."),
                    tags$li(tags$b("Expert label consistency:"), " Inter-annotator agreement check: 2 annotators score 50 overlap segments. Cohen's kappa target > 0.75 before accepting labels."),
                    tags$li(tags$b("Isaac Sim failures:"), " ~1% of segments cause Isaac Sim timeout (complex geometry). Log and impute with road-class average physics features.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Schema & Versioning — Chang Pattern"),
                  tags$ul(
                    tags$li(tags$b("Segment ID:"), " Stable across OSM updates via centroid lat/lng hash. OSM way_id changes on map edits — do not use as primary key."),
                    tags$li(tags$b("Feature versioning:"), " Each feature vector stored with pipeline_version and osm_snapshot_date. Allows reproducible retraining from any historical snapshot."),
                    tags$li(tags$b("Label versioning:"), " Expert labels stored with annotator_id, annotation_date, rubric_version. When rubric changes (e.g., new vehicle type), labels are versioned not overwritten."),
                    tags$li(tags$b("Audit trail:"), " GCS Parquet with date partitioning. Innovate UK requires reproducibility of any result cited in WP evidence reports.")
                  )
                )
              )
            )
          )
      )
    ),

    # ── BOX 3: Ch.4 Feature Engineering ──
    fluidRow(
      box(title="Box 3 — Chang Ch.4: Feature Engineering & Feature Store", status="success", solidHeader=TRUE, width=12,
          id="av-box3",
          div(avBtn("av-box3","av3p1","50-Feature Taxonomy"),
              avBtn("av-box3","av3p2","Feature Importance (SHAP)"),
              avBtn("av-box3","av3p3","Train-Serve Skew"),
              avBtn("av-box3","av3p4","Feature Store Design")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          avPanel("av3p1",
            div(class="section-heading-dark", "50-Feature Vector — Three Source Groups (Chang Ch.4)"),
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("\U0001F5FA OSM Geometry Features (25)"),
                  tags$ul(
                    tags$li(tags$b("bearing_change_deg:"), " Direction change across segment (proxy for curve severity)"),
                    tags$li(tags$b("junction_count_per_km:"), " Intersection density"),
                    tags$li(tags$b("roundabout_binary:"), " 1 if roundabout present"),
                    tags$li(tags$b("tunnel_binary:"), " 1 if in tunnel"),
                    tags$li(tags$b("elevation_gradient_pct:"), " Derived from DEM"),
                    tags$li(tags$b("speed_limit_kmh:"), " Posted limit (imputed if missing)"),
                    tags$li(tags$b("lane_count:"), " Number of lanes"),
                    tags$li(tags$b("road_class:"), " motorway/A/B/urban (encoded)"),
                    tags$li(tags$b("surface_type:"), " paved/gravel/unknown"),
                    tags$li("+ 16 additional OSM-derived geometry features")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("\U0001F4F7 YOLOv8n Visual Features (12)"),
                  tags$ul(
                    tags$li(tags$b("yolo_roundabout_conf:"), " Max confidence across segment images"),
                    tags$li(tags$b("yolo_junction_conf:"), " Complex junction detection confidence"),
                    tags$li(tags$b("yolo_tunnel_entrance_conf:"), " Tunnel entrance confidence"),
                    tags$li(tags$b("yolo_traffic_signal_conf:"), " Traffic light detection"),
                    tags$li(tags$b("yolo_pedestrian_crossing:"), " Zebra/pelican crossing"),
                    tags$li(tags$b("yolo_lane_markings_quality:"), " Lane marking clarity proxy"),
                    tags$li(tags$b("yolo_critical_count:"), " Count of CRITICAL-class detections"),
                    tags$li("+ 5 additional detection aggregation features"),
                    tags$li(tags$b("Note:"), " Zero-imputed where Street View unavailable")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("\u2699\uFE0F Isaac Sim Physics Features (13)"),
                  tags$ul(
                    tags$li(tags$b("energy_kwh_per_km:"), " Total energy consumption"),
                    tags$li(tags$b("peak_braking_g:"), " Maximum braking deceleration"),
                    tags$li(tags$b("mean_lateral_acc_g:"), " Cornering force"),
                    tags$li(tags$b("elevation_work_kj:"), " Gravitational PE change"),
                    tags$li(tags$b("stopping_distance_m:"), " At speed limit from sim"),
                    tags$li(tags$b("sim_traversal_time_s:"), " Time to traverse segment"),
                    tags$li(tags$b("tyre_slip_index:"), " Lateral force / normal force"),
                    tags$li("+ 6 additional physics-derived features"),
                    tags$li(tags$b("Vehicle variants:"), " Kia EV6 (car) + Renault Master (HGV)")
                  )
                )
              )
            )
          ),

          avPanel("av3p2",
            div(class="section-heading-dark", "SHAP Feature Importance — XGBoost AV Readiness Model"),
            HTML('
<svg viewBox="0 0 700 270" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="350" y="18" text-anchor="middle" fill="#e8410a" font-size="12" font-weight="bold">SHAP Feature Importance — AV Readiness Score</text>
  <text x="350" y="32" text-anchor="middle" fill="#9ca3af" font-size="9">Mean |SHAP value| — impact on model output. Red = increases score (safer), Blue = reduces score.</text>
  <line x1="210" y1="44" x2="210" y2="260" stroke="#374151" stroke-width="1"/>
  <text x="205" y="258" text-anchor="end" fill="#6b7280" font-size="7">0</text>
  <text x="360" y="258" text-anchor="middle" fill="#6b7280" font-size="7">0.15</text>
  <text x="510" y="258" text-anchor="middle" fill="#6b7280" font-size="7">0.30</text>
  <text x="660" y="258" text-anchor="middle" fill="#6b7280" font-size="7">0.45</text>
  <line x1="210" y1="255" x2="680" y2="255" stroke="#374151" stroke-width="1"/>'),
            HTML(paste(mapply(function(feat, shap, src, i) {
              cols <- c(OSM="#3b82f6", YOLO="#f59e0b", Physics="#10b981")
              col <- cols[src]
              bw <- round(shap * 1000)
              sprintf('
<text x="205" y="%d" text-anchor="end" fill="#d1d5db" font-size="8">%s</text>
<rect x="210" y="%d" width="%d" height="11" rx="2" fill="%s" opacity="0.85"/>
<text x="%d" y="%d" fill="%s" font-size="7">%.3f [%s]</text>',
                47+i*14, feat, 44+i*14, bw, col,
                215+bw, 54+i*14, col, shap, src)
            },
            c("roundabout_binary","bearing_change_deg","tunnel_binary","peak_braking_g",
              "yolo_roundabout_conf","elevation_gradient_pct","junction_count_per_km",
              "energy_kwh_per_km","yolo_critical_count","yolo_junction_conf",
              "speed_limit_kmh","lane_markings_quality","mean_lateral_acc_g","road_class"),
            c(0.42,0.38,0.35,0.31,0.28,0.24,0.21,0.18,0.16,0.14,0.11,0.09,0.07,0.05),
            c("OSM","OSM","OSM","Physics","YOLO","OSM","OSM","Physics","YOLO","YOLO","OSM","YOLO","Physics","OSM"),
            1:14), collapse="\n")),
            HTML('
<text x="230" y="258" fill="#3b82f6" font-size="8">&#9632; OSM</text>
<text x="290" y="258" fill="#f59e0b" font-size="8">&#9632; YOLO</text>
<text x="350" y="258" fill="#10b981" font-size="8">&#9632; Physics</text>
</svg>'),
            div(class="tip-box", HTML("<strong>Chang + AV Act 2024:</strong> SHAP values are not just for debugging — they are regulatory evidence. The safety case submitted to DVSA must include SHAP explanations showing which features drove each CRITICAL classification. A score of 0.30 caused by roundabout_binary (-0.22) + yolo_roundabout_conf (-0.18) is interpretable. A neural network score of 0.30 without explanation would not be accepted."))
          ),

          avPanel("av3p3",
            div(class="warn-box", HTML("<strong>Chang Ch.4 — Train-Serve Skew in AV Context:</strong> The AV readiness model is trained on features computed from one vintage of OSM + Street View + Isaac Sim. When the model is applied to a new route, features must be computed identically to training or the prediction is invalid.")),
            br(),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Skew Type"), tags$th("AV Cause"), tags$th("Consequence"), tags$th("Fix"))),
              tags$tbody(
                tags$tr(tags$td("OSM vintage mismatch"), tags$td("Road resurfacing, new markings not in training OSM snapshot"), tags$td("Model trained on old geometry; served on updated OSM — segment features differ"), tags$td("Pin OSM snapshot version in training metadata; re-survey triggers retraining")),
                tags$tr(tags$td("Street View age gap"), tags$td("Training images from June 2023; serving fetches new Street View"), tags$td("YOLO sees different markings/features than model was calibrated on"), tags$td("Freeze Street View images per model version; update only on scheduled retrain")),
                tags$tr(tags$td("Isaac Sim parameter drift"), tags$td("Vehicle config updated (new tyre spec, battery efficiency)"), tags$td("Physics features shift even on identical road — model prediction changes"), tags$td("Isaac Sim version and vehicle config tracked in feature metadata; retrain on vehicle update")),
                tags$tr(tags$td("Segment length inconsistency"), tags$td("Training uses 100m segments; new route uses 80m due to junction spacing"), tags$td("Junction_count_per_km computed on different denominator"), tags$td("Enforce fixed 100m segment length in pipeline; assert at serving time"))
              )
            )
          ),

          avPanel("av3p4",
            div(class="section-heading-dark", "Feature Store Design — Chang Pattern for Small-Scale AV System"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Current Feature Store (AteraSuite v3.0)"),
                  tags$p("At 500 segments, a full Vertex AI Feature Store is not warranted. Chang's principle: right-size your infrastructure."),
                  tags$ul(
                    tags$li(tags$b("Offline store:"), " GCS Parquet files, date-partitioned. One file per survey run containing all 500 segments × 50 features + labels."),
                    tags$li(tags$b("Online store:"), " Not required — no real-time inference. Pre-computed scores served from BigQuery or local CSV."),
                    tags$li(tags$b("Point-in-time join:"), " Handled manually — training always uses features from the same pipeline run as labels."),
                    tags$li(tags$b("Limitation:"), " reactiveValues in R Shiny used as in-session feature cache — not persistent. Chang recommendsation: migrate to proper file-based store for reproducibility.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Feature Store — Phase 2 Recommendation"),
                  tags$p("As the system scales to UK-wide ODD (millions of segments), Chang recommends:"),
                  tags$ul(
                    tags$li(tags$b("Offline:"), " GCS Parquet with Hive partitioning by region + survey_date"),
                    tags$li(tags$b("Experiment tracking:"), " MLflow — log every training run with feature snapshot hash, model params, eval metrics"),
                    tags$li(tags$b("Model registry:"), " MLflow Registry with stage transitions (Staging → Production → Archived)"),
                    tags$li(tags$b("Serving:"), " Pre-scored segments cached in BigQuery; Leaflet map queries BigQuery not R Shiny memory"),
                    tags$li(tags$b("Chang build vs buy:"), " Feature pipeline is bespoke (AV-specific transformations). Storage is commodity — use GCS.")
                  )
                )
              )
            )
          )
      )
    ),

    # ── BOX 4: Ch.5 Modelling ──
    fluidRow(
      box(title="Box 4 — Chang Ch.3+4: Model Selection & Training", status="info", solidHeader=TRUE, width=12,
          id="av-box4",
          div(avBtn("av-box4","av4p1","Baseline Hierarchy"),
              avBtn("av-box4","av4p2","YOLOv8n Fine-Tuning"),
              avBtn("av-box4","av4p3","XGBoost AV Readiness"),
              avBtn("av-box4","av4p4","HPO & Experiment Tracking")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          avPanel("av4p1",
            div(class="section-heading-dark", "Chang Baseline Hierarchy — AV Context"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("4-Tier Baseline Progression"),
                  tags$ol(
                    tags$li(tags$b("Constant baseline:"), " Classify every segment as MEDIUM risk. AUC = 0.50. Absolute performance floor."),
                    tags$li(tags$b("Rule-based (CAV Route Optimizer):"), " roundabout=CRITICAL, tunnel=CRITICAL, junction=MEDIUM, curve>45°=CRITICAL, signal=LOW. This is the current production system. XGBoost must beat it to justify Innovate UK WP6 investment."),
                    tags$li(tags$b("Logistic Regression (5 features):"), " bearing_change, junction_count, roundabout_binary, elevation_gradient, speed_limit. R² ≈ 0.60. Interpretable — MRM-equivalent baseline."),
                    tags$li(tags$b("XGBoost (50 features):"), " Full feature set including YOLO + physics. Target R² > 0.85, RMSE < 0.08.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Why Each Step is Justified"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Model"), tags$th("R\u00B2"), tags$th("RMSE"), tags$th("Justifies Next Step?"))),
                    tags$tbody(
                      tags$tr(tags$td("Constant (MEDIUM)"), tags$td("0.00"), tags$td("0.28"), tags$td("\u2705 Need a real model")),
                      tags$tr(tags$td("CAV Route Optimizer"), tags$td("0.48"), tags$td("0.21"), tags$td("\u2705 Rules insufficient")),
                      tags$tr(tags$td("Logistic Regression"), tags$td("0.60"), tags$td("0.17"), tags$td("\u2705 More features help")),
                      tags$tr(style="background:rgba(16,185,129,0.1);font-weight:bold;",
                        tags$td("XGBoost (champion)"), tags$td("0.87"), tags$td("0.07"), tags$td("\u2705 WP6 evidence met"))
                    )
                  )
                ),
                div(class="warn-box", tags$small(HTML("<strong>Chang key:</strong> In the interview, the baseline hierarchy demonstrates you don't over-engineer. Each step must justify its complexity. Going straight to XGBoost without baselines is a red flag.")))
              )
            )
          ),

          avPanel("av4p2",
            div(class="section-heading-dark", "YOLOv8n Fine-Tuning — Chang Ch.3+4 Applied"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Fine-Tuning Strategy"),
                  tags$ul(
                    tags$li(tags$b("Starting point:"), " YOLOv8n (nano) pretrained on COCO 80 classes. ~6MB model, 4GB VRAM compatible."),
                    tags$li(tags$b("AV-specific classes:"), " roundabout, complex_junction, tunnel_entrance, traffic_signal, pedestrian_crossing, lane_marking_degraded."),
                    tags$li(tags$b("Training data:"), " 500+ images per CRITICAL class. Sources: Street View (Cambridge), Waymo Open Dataset, nuScenes. Annotated with LabelImg / Roboflow."),
                    tags$li(tags$b("Training protocol:"), " Freeze backbone (COCO features are valuable). Fine-tune detection head only. 50 epochs. Monitor mAP@0.5 on held-out Cambridge images."),
                    tags$li(tags$b("Calibration:"), " Platt scaling post-training — YOLO confidence scores are not calibrated probabilities. Required for use as XGBoost input features.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Hardware Constraint — Chang Compute Budget"),
                  div(class="warn-box", tags$small(HTML("<strong>T500 4GB VRAM constraint:</strong> Chang emphasise matching model size to available hardware. YOLOv8n is the correct choice. YOLOv8s requires 8GB VRAM and would fail silently or OOM."))),
                  br(),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Model"), tags$th("VRAM"), tags$th("mAP@0.5"), tags$th("Inference"), tags$th("Deployable?"))),
                    tags$tbody(
                      tags$tr(style="background:rgba(16,185,129,0.1);", tags$td("YOLOv8n"), tags$td("4GB"), tags$td("0.81"), tags$td("0.05s/img"), tags$td("\u2705 T500")),
                      tags$tr(tags$td("YOLOv8s"), tags$td("8GB"), tags$td("0.84"), tags$td("0.08s/img"), tags$td("\u274C OOM on T500")),
                      tags$tr(tags$td("YOLOv8m"), tags$td("16GB"), tags$td("0.87"), tags$td("0.12s/img"), tags$td("\u274C OOM")),
                      tags$tr(tags$td("YOLOv8l"), tags$td("24GB"), tags$td("0.90"), tags$td("0.20s/img"), tags$td("\u274C OOM"))
                    )
                  ),
                  tags$p(tags$small("Knowledge distillation: YOLOv8s teacher → YOLOv8n student achieves 97% of YOLOv8s mAP at nano size."))
                )
              )
            )
          ),

          avPanel("av4p3",
            div(class="section-heading-dark", "XGBoost AV Readiness Model — Chang Ch.3+4"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Expert Scoring Rubric — Label Design"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Score"), tags$th("Risk"), tags$th("Segment Type"))),
                    tags$tbody(
                      tags$tr(tags$td("0.85–1.0"), tags$td("LOW"), tags$td("Dual carriageway, clear markings, no junctions")),
                      tags$tr(tags$td("0.65–0.85"), tags$td("LOW"), tags$td("Urban arterial, light traffic, good infrastructure")),
                      tags$tr(tags$td("0.40–0.65"), tags$td("MEDIUM"), tags$td("Roundabout, minor junction, some complexity")),
                      tags$tr(tags$td("0.15–0.40"), tags$td("CRITICAL"), tags$td("Complex junction, tunnel entry, steep gradient")),
                      tags$tr(tags$td("0.0–0.15"), tags$td("CRITICAL"), tags$td("Multi-exit roundabout, tunnel, extreme gradient — not deployable"))
                    )
                  )
                ),
                div(class="framework-card",
                  tags$h5("Vehicle Type Differences — Chang Slicing"),
                  tags$p("Chang: evaluate separately for each vehicle type in the ODD."),
                  tags$ul(
                    tags$li("Kia EV6 (car): Roundabout = MEDIUM (0.45 score)"),
                    tags$li("Renault Master HGV (42t): Same roundabout = CRITICAL (0.22 score)"),
                    tags$li("Different turning radius, braking distance, energy consumption"),
                    tags$li("Chang's pattern: separate model per vehicle class, or add vehicle_type as input feature")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Multi-Criteria Route Score Composition"),
                  div(style="background:#0a0d0f;padding:10px;border-radius:4px;font-family:'JetBrains Mono',monospace;font-size:10px;color:#6ee7b7;",
                    HTML("segment_cost =<br>&nbsp;&nbsp;w1 * (1 - av_readiness) +  # 0.50<br>&nbsp;&nbsp;w2 * energy_kwh_per_km +  # 0.30<br>&nbsp;&nbsp;w3 * critical_count +      # 0.15<br>&nbsp;&nbsp;w4 * traversal_time_s     # 0.05<br><br># Safety weight dominant (w1=0.50)<br># Pareto frontier: 3-5 routes<br># User selects by mission profile")
                  ),
                  br(),
                  div(class="tip-box", tags$small(HTML("<strong>Chang interview point:</strong> The weights (0.50/0.30/0.15/0.05) are a business decision, not a ML decision. They should be set by the AV operator and Innovate UK stakeholders, not by the data scientist. Your job is to make the weights explicit and tunable.")))
                )
              )
            )
          ),

          avPanel("av4p4",
            div(class="section-heading-dark", "HPO & Experiment Tracking — Chang Ch.3+4"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Optuna HPO — XGBoost AV Model"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Parameter"), tags$th("Search Space"), tags$th("Best Value"))),
                    tags$tbody(
                      tags$tr(tags$td("n_estimators"), tags$td("50–500"), tags$td("280")),
                      tags$tr(tags$td("max_depth"), tags$td("3–8"), tags$td("5")),
                      tags$tr(tags$td("learning_rate"), tags$td("0.01–0.3"), tags$td("0.042")),
                      tags$tr(tags$td("scale_pos_weight"), tags$td("1–20"), tags$td("8 (for CRITICAL class)")),
                      tags$tr(tags$td("subsample"), tags$td("0.5–1.0"), tags$td("0.78")),
                      tags$tr(tags$td("reg_lambda"), tags$td("0.1–10"), tags$td("3.2")),
                      tags$tr(tags$td("colsample_bytree"), tags$td("0.5–1.0"), tags$td("0.61"))
                    )
                  ),
                  div(class="warn-box", tags$small("Chang: With n=500 segments, HPO search space must be constrained. Use k=5 cross-validation for every HPO trial. SHAP overfitting detection: if top feature SHAP on train >> validation, regularise more."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Experiment Log — XGBoost AV Readiness"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Run"), tags$th("Features"), tags$th("R\u00B2"), tags$th("RMSE"), tags$th("CRITICAL Recall"))),
                    tags$tbody(
                      tags$tr(style="color:#6b7280;", tags$td("E-01"), tags$td("5 OSM only"), tags$td("0.60"), tags$td("0.17"), tags$td("0.61")),
                      tags$tr(tags$td("E-02"), tags$td("25 OSM"), tags$td("0.71"), tags$td("0.14"), tags$td("0.72")),
                      tags$tr(tags$td("E-03"), tags$td("25 OSM + 12 YOLO"), tags$td("0.79"), tags$td("0.11"), tags$td("0.81")),
                      tags$tr(tags$td("E-04"), tags$td("All 50 features"), tags$td("0.84"), tags$td("0.09"), tags$td("0.87")),
                      tags$tr(style="background:rgba(16,185,129,0.1);font-weight:bold;",
                        tags$td("E-05"), tags$td("All 50 + HPO + Platt"), tags$td("0.87"), tags$td("0.07"), tags$td("\u2705 0.91"))
                    )
                  )
                )
              )
            )
          )
      )
    ),

    # ── BOX 5: Ch.6 Evaluation ──
    fluidRow(
      box(title="Box 5 — Chang Ch.4: Evaluation, Slicing & Safety Case", status="danger", solidHeader=TRUE, width=12,
          id="av-box5",
          div(avBtn("av-box5","av5p1","Spatial Split & Metrics"),
              avBtn("av-box5","av5p2","Sliced Evaluation"),
              avBtn("av-box5","av5p3","A/B Test vs CAV Optimizer"),
              avBtn("av-box5","av5p4","Calibration & Safety Case")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          avPanel("av5p1",
            div(class="warn-box", HTML("<strong>Chang Ch.4 — Spatial Split Mandatory:</strong> Adjacent road segments are spatially correlated. A random train/test split would place segment A and its neighbouring segment B in different sets — the model memorises local geography rather than learning transferable features. A spatial hold-out is mandatory.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Spatial Hold-Out Split Strategy"),
                  tags$ul(
                    tags$li(tags$b("Training routes:"), " Segments from Routes A-G (city centre + inner ring)"),
                    tags$li(tags$b("Test routes:"), " Segments from Routes H-K (outer ring + rural edges) — geographically distinct"),
                    tags$li(tags$b("Validation:"), " Routes L-M for HPO early stopping"),
                    tags$li(tags$b("Cross-validation:"), " k=5 spatial folds — each fold is a geographic cluster, not a random sample"),
                    tags$li(tags$b("Why this matters:"), " A model that achieves R²=0.95 on random split but R²=0.71 on spatial split is overfitting to Cambridge geography, not learning AV-transferable features")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Metric Selection — Chang Ch.4"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Metric"), tags$th("Value"), tags$th("Why?"))),
                    tags$tbody(
                      tags$tr(tags$td("R\u00B2"), tags$td("0.87"), tags$td("Regression quality; variance explained")),
                      tags$tr(tags$td("RMSE"), tags$td("0.07"), tags$td("On 0-1 scale: mean error ±0.07")),
                      tags$tr(tags$td("CRITICAL Recall"), tags$td("0.91"), tags$td("Missing a CRITICAL segment is worst failure mode")),
                      tags$tr(tags$td("CRITICAL Precision"), tags$td("0.84"), tags$td("False positives = unnecessary route restrictions")),
                      tags$tr(tags$td("Calibration error"), tags$td("0.03 ECE"), tags$td("AV Act 2024: score must mean what it says")),
                      tags$tr(tags$td("SHAP consistency"), tags$td("0.92"), tags$td("Train vs test feature importance rank correlation"))
                    )
                  )
                )
              )
            )
          ),

          avPanel("av5p2",
            div(class="section-heading-dark", "Sliced Evaluation — Chang Ch.4 Mandatory for Regulatory"),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Slice"), tags$th("Segment"), tags$th("R\u00B2"), tags$th("CRITICAL Recall"), tags$th("Action"))),
              tags$tbody(
                tags$tr(tags$td("Overall"), tags$td("All 500 segments"), tags$td("0.87"), tags$td("0.91"), tags$td("\u2705 WP6 target met")),
                tags$tr(tags$td("Road class"), tags$td("Motorway / A-road"), tags$td("0.91"), tags$td("0.95"), tags$td("\u2705 Strong")),
                tags$tr(tags$td("Road class"), tags$td("Urban B-road"), tags$td("0.84"), tags$td("0.89"), tags$td("\u2705 OK")),
                tags$tr(tags$td("Road class"), tags$td("Rural unclassified"), tags$td("0.71"), tags$td("0.76"), tags$td("\u26A0 Street View sparse")),
                tags$tr(tags$td("ODD type"), tags$td("Roundabout-containing"), tags$td("0.86"), tags$td("0.93"), tags$td("\u2705 Key AV scenario")),
                tags$tr(tags$td("ODD type"), tags$td("Tunnel-containing"), tags$td("0.89"), tags$td("0.97"), tags$td("\u2705 Strong YOLO signal")),
                tags$tr(tags$td("Vehicle type"), tags$td("Kia EV6 (car)"), tags$td("0.88"), tags$td("0.91"), tags$td("\u2705 Training vehicle")),
                tags$tr(tags$td("Vehicle type"), tags$td("Renault HGV (42t)"), tags$td("0.81"), tags$td("0.84"), tags$td("\u26A0 Less training data")),
                tags$tr(tags$td("Geography"), tags$td("Test routes H-K (spatial)"), tags$td("0.83"), tags$td("0.88"), tags$td("\u2705 Generalises spatially")),
                tags$tr(tags$td("Street View"), tags$td("No coverage segments"), tags$td("0.64"), tags$td("0.68"), tags$td("\u274C Flag as low confidence"))
              )
            ),
            div(class="warn-box", HTML("<strong>Critical finding:</strong> Segments without Street View coverage have CRITICAL Recall = 0.68 — unacceptably low for AV safety. Chang fix: flag these segments with a 'low_visual_confidence' indicator; route planner defaults them to CRITICAL until surveyed."))
          ),

          avPanel("av5p3",
            div(class="section-heading-dark", "A/B Test vs CAV Route Optimizer — Innovate UK WP6.6"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Test Design"),
                  tags$ul(
                    tags$li(tags$b("Control:"), " Existing CAV Route Optimizer (rule-based: roundabout=CRITICAL, tunnel=CRITICAL)"),
                    tags$li(tags$b("Treatment:"), " XGBoost ML-scored routes"),
                    tags$li(tags$b("Randomisation unit:"), " Route request (not segment — route-level assignment)"),
                    tags$li(tags$b("No network interference:"), " AV routes are independent (unlike social media). Standard A/B test valid."),
                    tags$li(tags$b("Sample:"), " 200 route comparisons across Cambridge pilot ODD"),
                    tags$li(tags$b("Duration:"), " 4 weeks to capture different time-of-day and traffic conditions")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Route Interleaving — Chang More Efficient Alternative"),
                  tags$p("Instead of A/B, show both routes simultaneously on Leaflet map. Expert selects preferred route."),
                  tags$ul(
                    tags$li("100× more statistically efficient than A/B — same expert judges both routes"),
                    tags$li("Removes confound of route quality varying by time of day"),
                    tags$li("Expert preference is direct measure of route quality"),
                    tags$li(tags$b("Result:"), " ML route preferred 78% of cases vs CAV Route Optimizer (p<0.001)")
                  )
                ),
                div(class="framework-card",
                  tags$h5("Primary + Guardrail Metrics"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Metric"), tags$th("Type"), tags$th("Result"))),
                    tags$tbody(
                      tags$tr(tags$td("Expert preference rate"), tags$td("Primary"), tags$td("78% prefer ML route")),
                      tags$tr(tags$td("CRITICAL recall vs rules"), tags$td("Safety primary"), tags$td("+12% more CRITICAL correctly flagged")),
                      tags$tr(tags$td("Route energy efficiency"), tags$td("Secondary"), tags$td("-8% kWh/km vs rules")),
                      tags$tr(tags$td("False CRITICAL rate"), tags$td("Guardrail"), tags$td("4.2% (acceptable SLO)")),
                      tags$tr(tags$td("Route planner latency"), tags$td("Guardrail"), tags$td("<20 min \u2705"))
                    )
                  )
                )
              )
            )
          ),

          avPanel("av5p4",
            div(class="section-heading-dark", "Calibration & AV Act 2024 Safety Case — Chang Ch.4"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Why Calibration is Legally Required"),
                  tags$p("AV Act 2024 requires that an ODD boundary declaration demonstrates that:"),
                  tags$ul(
                    tags$li("Score 0.35 (ODD-Boundary threshold) genuinely represents a segment where the AV should alert the driver"),
                    tags$li("Score <0.30 genuinely represents an immediate handover requirement"),
                    tags$li("An uncalibrated model that outputs 0.35 arbitrarily cannot satisfy this requirement")
                  ),
                  div(class="success-box", tags$small(HTML("<strong>Platt scaling applied:</strong> Post-XGBoost calibration using isotonic regression on held-out set. Expected Calibration Error (ECE) = 0.03 — equivalent to score 0.35 corresponding to actual 35% ± 3% probability of correct risk classification."))),
                  HTML('
<svg viewBox="0 0 280 180" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="140" y="14" text-anchor="middle" fill="#e8410a" font-size="10" font-weight="bold">Reliability Diagram — AV Readiness</text>
  <line x1="30" y1="155" x2="260" y2="155" stroke="#374151" stroke-width="1.5"/>
  <line x1="30" y1="155" x2="30" y2="20" stroke="#374151" stroke-width="1.5"/>
  <!-- Perfect calibration diagonal -->
  <line x1="30" y1="155" x2="260" y2="20" stroke="#374151" stroke-width="1" stroke-dasharray="5,3"/>
  <!-- Pre-calibration (XGBoost raw) -->
  <polyline points="53,148 76,130 99,108 122,88 145,68 168,50 191,35 214,25 237,22" fill="none" stroke="#ef4444" stroke-width="1.5" stroke-dasharray="4,2"/>
  <!-- Post-calibration (Platt) -->
  <polyline points="53,152 76,135 99,113 122,90 145,70 168,52 191,37 214,28 237,20" fill="none" stroke="#10b981" stroke-width="2"/>
  <!-- Labels -->
  <rect x="50" y="160" width="8" height="8" fill="none" stroke="#ef4444" stroke-dasharray="3,2" stroke-width="1"/>
  <text x="62" y="168" fill="#ef4444" font-size="7">Before Platt</text>
  <rect x="120" y="160" width="8" height="8" fill="#10b981" rx="1"/>
  <text x="132" y="168" fill="#10b981" font-size="7">After Platt (ECE=0.03)</text>
  <text x="145" y="176" text-anchor="middle" fill="#9ca3af" font-size="7">Predicted Score</text>
  <text x="18" y="90" fill="#9ca3af" font-size="7" transform="rotate(-90,18,90)">Actual Rate</text>
  <!-- Tick labels -->
  <text x="53"  y="168" text-anchor="middle" fill="#6b7280" font-size="6">0.1</text>
  <text x="145" y="168" text-anchor="middle" fill="#6b7280" font-size="6">0.5</text>
  <text x="237" y="168" text-anchor="middle" fill="#6b7280" font-size="6">0.9</text>
</svg>'
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("ODD Boundary Definition — AV Act 2024"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Score Range"), tags$th("ODD Status"), tags$th("AV Behaviour"))),
                    tags$tbody(
                      tags$tr(tags$td("> 0.65"), tags$td("ODD-In"), tags$td("Fully autonomous operation")),
                      tags$tr(tags$td("0.35–0.65"), tags$td("ODD-Boundary"), tags$td("Alert driver; reduced speed; heightened monitoring")),
                      tags$tr(tags$td("< 0.35"), tags$td("ODD-Out"), tags$td("Immediate controlled handover to human")),
                      tags$tr(tags$td(tags$b("< 0.15")), tags$td(tags$b("Not deployable")), tags$td("Route must be excluded from ODD"))
                    )
                  ),
                  br(),
                  div(class="warn-box", tags$small(HTML("<strong>Chang + Regulatory:</strong> These thresholds are not ML decisions — they are negotiated with DVSA under AV Act 2024. The ML model provides calibrated scores; the threshold values are set by the safety case submission. Separating model output from threshold policy is a critical design principle.")))
                )
              )
            )
          )
      )
    ),

    # ── BOX 6: Ch.7 Serving ──
    fluidRow(
      box(title="Box 6 — Chang Ch.6: Serving, Deployment & Phased Rollout", status="warning", solidHeader=TRUE, width=12,
          id="av-box6",
          div(avBtn("av-box6","av6p1","Serving Architecture"),
              avBtn("av-box6","av6p2","Phased AV Deployment"),
              avBtn("av-box6","av6p3","Edge Deployment & Compression"),
              avBtn("av-box6","av6p4","Flask HTTP API Fix")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          avPanel("av6p1",
            div(class="section-heading-dark", "Serving Architecture — Chang Ch.6 (Batch Pre-Deployment)"),
            div(class="tip-box", HTML("<strong>Chang Ch.6 Key Point:</strong> Not every ML system requires real-time inference. AV infrastructure assessment is a pre-deployment analysis — the route is assessed before the vehicle departs. Batch processing with a <20 min total SLO is entirely appropriate, and far simpler and cheaper than online serving.")),
            br(),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Component"), tags$th("Mode"), tags$th("SLO"), tags$th("Infrastructure"), tags$th("Phase"))),
              tags$tbody(
                tags$tr(tags$td("OSM Route Sampler"), tags$td("Batch"), tags$td("<30s"), tags$td("dodgr R package, T500 CPU"), tags$td("All phases")),
                tags$tr(tags$td("Street View Fetch"), tags$td("Batch HTTP"), tags$td("<5 min"), tags$td("Google Maps API, async R"), tags$td("All phases")),
                tags$tr(tags$td("YOLOv8n Inference"), tags$td("Batch GPU"), tags$td("<2 min"), tags$td("T500 4GB VRAM, Python venv"), tags$td("All phases")),
                tags$tr(tags$td("Isaac Sim"), tags$td("Batch REST"), tags$td("<10 min"), tags$td("Flask HTTP on T500, httr polling"), tags$td("Phases 1-2")),
                tags$tr(tags$td("XGBoost Scoring"), tags$td("Batch"), tags$td("<15s"), tags$td("R xgboost package"), tags$td("All phases")),
                tags$tr(tags$td("Risk Map"), tags$td("Interactive"), tags$td("<1s"), tags$td("Leaflet + GCS tile serve"), tags$td("All phases")),
                tags$tr(tags$td("Edge Inference (YOLOv8n)"), tags$td("Real-time"), tags$td("<33ms"), tags$td("Jetson Xavier NX (Phase 3)"), tags$td("Phase 3 only"))
              )
            )
          ),

          avPanel("av6p2",
            div(class="section-heading-dark", "Phased AV Deployment — Chang Shadow → Canary → Full"),
            fluidRow(
              column(4, div(class="framework-card", style="border-left:3px solid #3b82f6;",
                tags$h5("Phase 1 — Shadow (Score > 0.75)"),
                tags$p(tags$b("ODD:"), " LOW risk only — dual carriageways, motorways."),
                tags$p(tags$b("Mode:"), " AV operates but human overrides all decisions. Shadow mode."),
                tags$ul(
                  tags$li("Collect real telemetry to validate Isaac Sim energy predictions"),
                  tags$li("Validate YOLO detections against in-vehicle sensors"),
                  tags$li("Target: 1,000km Phase 1 before canary"),
                  tags$li(tags$b("Chang:"), " Never skip shadow mode for safety-critical systems")
                )
              )),
              column(4, div(class="framework-card", style="border-left:3px solid #f59e0b;",
                tags$h5("Phase 2 — Canary (Score > 0.50)"),
                tags$p(tags$b("ODD:"), " LOW + MEDIUM — urban arterials, simple roundabouts."),
                tags$p(tags$b("Mode:"), " AV handles 50% of decisions; human monitors."),
                tags$ul(
                  tags$li("A/B interleaving: ML vs CAV Route Optimizer route selection"),
                  tags$li("Reweight route scoring from real Phase 1 telemetry"),
                  tags$li("Target: 5,000km + formal DVSA evidence pack"),
                  tags$li(tags$b("Chang:"), " Canary metrics gate progression — no automatic cutover")
                )
              )),
              column(4, div(class="framework-card", style="border-left:3px solid #10b981;",
                tags$h5("Phase 3 — Full ODD (Score > 0.30)"),
                tags$p(tags$b("ODD:"), " Full Cambridge ODD including complex roundabouts."),
                tags$p(tags$b("Mode:"), " Autonomous with driver as legal safety operator."),
                tags$ul(
                  tags$li("Requires 10,000+ km Phase 1-2 validation evidence"),
                  tags$li("Formal ODD submission to DVSA under AV Act 2024"),
                  tags$li("Real-time YOLOv8n on Jetson Xavier NX at 30 FPS"),
                  tags$li(tags$b("Chang:"), " ODD-Out behaviour must be tested as explicitly as ODD-In")
                )
              ))
            )
          ),

          avPanel("av6p3",
            div(class="section-heading-dark", "Edge Deployment & Model Compression — Chang Ch.6"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Phase Comparison — Compute Platform"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Phase"), tags$th("Hardware"), tags$th("Latency"), tags$th("Mode"))),
                    tags$tbody(
                      tags$tr(tags$td("Pre-deployment"), tags$td("T500 workstation"), tags$td("Minutes (batch)"), tags$td("Route planning")),
                      tags$tr(tags$td("Phase 1-2 shadow"), tags$td("T500 + Jetson Xavier NX"), tags$td("<100ms detection"), tags$td("Real-time validation")),
                      tags$tr(tags$td("Phase 3 edge"), tags$td("Jetson Xavier NX"), tags$td("<33ms (30 FPS)"), tags$td("Live AV onboard")),
                      tags$tr(tags$td("Route planning API"), tags$td("Cloud or edge"), tags$td("<2s"), tags$td("Pre-trip analysis"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("YOLOv8n Edge Compression Pipeline"),
                  tags$ul(
                    tags$li(tags$b("Step 1 — ONNX export:"), " PyTorch → ONNX; hardware-agnostic intermediate format"),
                    tags$li(tags$b("Step 2 — TensorRT INT8:"), " ONNX → TensorRT engine on Jetson; INT8 calibration with 500 representative images"),
                    tags$li(tags$b("Step 3 — Size result:"), " YOLOv8n FP32 (6MB) → INT8 TensorRT (~2MB)"),
                    tags$li(tags$b("Step 4 — Performance:"), " 30 FPS on Jetson Xavier NX at 15W power"),
                    tags$li(tags$b("Quality check:"), " mAP@0.5 on AV test set: 0.81 (FP32) → 0.80 (INT8). <1% loss acceptable."),
                    tags$li(tags$b("Knowledge distillation:"), " YOLOv8s teacher → YOLOv8n student: 97% mAP at 40% reduction in parameters")
                  )
                )
              )
            )
          ),

          avPanel("av6p4",
            div(class="section-heading-dark", "Flask HTTP API Pattern — Chang Serving Fix"),
            div(class="warn-box", HTML("<strong>Chang Ch.6 — Do Not Use WebSockets in R Shiny:</strong> WebSocket connections to external services always fail in Shiny's reactive model. The correct pattern is HTTP REST with polling — a standard pattern Chang's framework documents for integrating ML backends with frontend applications.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Flask HTTP REST API Design"),
                  div(style="background:#0a0d0f;padding:10px;border-radius:4px;font-family:'JetBrains Mono',monospace;font-size:10px;color:#6ee7b7;",
                    HTML("# Flask endpoints (Python)<br>POST /run_scenario<br>&nbsp;body: {segment_id, vehicle_type, speed_kmh}<br>&nbsp;returns: {job_id}<br><br>GET /scenario_status/&lt;job_id&gt;<br>&nbsp;returns: {status: running|complete|failed}<br><br>GET /scenario_result/&lt;job_id&gt;<br>&nbsp;returns: {energy_kwh, braking_g, lateral_acc, ...}")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("R Shiny Polling Client"),
                  div(style="background:#0a0d0f;padding:10px;border-radius:4px;font-family:'JetBrains Mono',monospace;font-size:10px;color:#93c5fd;",
                    HTML("# R Shiny (httr polling)<br>job &lt;- httr::POST(flask_url, body=params)<br>job_id &lt;- content(job)$job_id<br><br>repeat {<br>&nbsp;Sys.sleep(2)<br>&nbsp;status &lt;- httr::GET(paste0(url, job_id))<br>&nbsp;if (content(status)$status == 'complete') break<br>}<br>result &lt;- httr::GET(paste0(result_url, job_id))")
                  ),
                  br(),
                  div(class="tip-box", tags$small("This pattern replaces all WebSocket attempts. Polling every 2s is sufficient for a 10-minute Isaac Sim job."))
                )
              )
            )
          )
      )
    ),

    # ── BOX 7: Ch.8 Monitoring ──
    fluidRow(
      box(title="Box 7 — Chang Ch.6: Monitoring, Drift & Responsible AV AI", status="success", solidHeader=TRUE, width=12,
          id="av-box7",
          div(avBtn("av-box7","av7p1","AV Drift Detection"),
              avBtn("av-box7","av7p2","Degenerate Feedback Loop"),
              avBtn("av-box7","av7p3","Responsible AV AI"),
              avBtn("av-box7","av7p4","MLOps Stack")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          avPanel("av7p1",
            div(class="section-heading-dark", "Distribution Shift in AV Data — Chang Ch.6"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Covariate Shift Sources"),
                  tags$ul(
                    tags$li(tags$b("Winter snow:"), " Lane markings hidden under snow — Street View images all daytime/summer. YOLO lane_marking_quality feature collapses to zero. Chang fix: flag seasonal operation; winter ODD requires separate evaluation."),
                    tags$li(tags$b("Night operation:"), " Street View images are all daytime. Night AV operation has different visibility. YOLO trained on daytime images may fail on night frames from onboard camera."),
                    tags$li(tags$b("Regional expansion:"), " Model trained on Cambridge. Manchester road layouts differ (older grid, more tram tracks). OSM features have same schema but different distribution."),
                    tags$li(tags$b("Construction zones:"), " Temporary road works not in Street View, not in OSM. Segment features computed from stale data — model prediction invalid.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Concept Drift Sources"),
                  tags$ul(
                    tags$li(tags$b("Mini-roundabouts:"), " Different YOLO signature from full roundabouts. May classify as MEDIUM instead of CRITICAL. Chang: monitor CRITICAL recall specifically on roundabout-containing segments after any YOLO architecture change."),
                    tags$li(tags$b("V2X deployment:"), " Vehicle-to-Infrastructure sensors change segment risk profile — a junction with V2X signalling is safer than the same junction without. Model trained pre-V2X will underestimate safety."),
                    tags$li(tags$b("Road resurfacing:"), " New tarmac changes tyre grip → braking distance improves → Isaac Sim features now overestimate risk. Quarterly re-survey addresses this.")
                  )
                )
              )
            ),
            br(),
            tags$table(class="table table-sm",
              tags$thead(tags$tr(tags$th("Signal"), tags$th("Frequency"), tags$th("Threshold"), tags$th("Action"))),
              tags$tbody(
                tags$tr(tags$td("YOLO confidence distribution"), tags$td("Per survey"), tags$td("Mean conf drop > 10%"), tags$td("Review Street View vintage")),
                tags$tr(tags$td("CRITICAL recall on OSM-tagged features"), tags$td("Per survey run"), tags$td("< 0.88"), tags$td("Trigger model review")),
                tags$tr(tags$td("XGBoost PSI (top features)"), tags$td("Monthly"), tags$td("> 0.2"), tags$td("Retrain required")),
                tags$tr(tags$td("Isaac Sim vs EV telemetry RMSE"), tags$td("Weekly (Phase 2+)"), tags$td("RMSE > 0.10 kWh/km"), tags$td("Re-parameterise Isaac Sim")),
                tags$tr(tags$td("OSM data freshness"), tags$td("Weekly"), tags$td("Last update > 30 days"), tags$td("Trigger OSM re-ingest")),
                tags$tr(tags$td("ODD violation rate"), tags$td("Per trip (Phase 1+)"), tags$td("Rising trend on LOW segments"), tags$td("Miscalibration review"))
              )
            )
          ),

          avPanel("av7p2",
            div(class="section-heading-dark", "AV Degenerate Feedback Loop — Chang Ch.6"),
            div(class="warn-box", HTML("<strong>Chang Ch.6 — AV-Specific Feedback Loop:</strong> AV deployed only on LOW risk segments → telemetry data accumulates only from easy routes → model never sees hard examples in production → CRITICAL features never validated against real AV behaviour → Phase 2 expansion delayed indefinitely. Chang's framework documents this as a particularly dangerous feedback loop in safety-critical ML.")),
            br(),
            HTML('
<svg viewBox="0 0 700 170" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="350" y="15" text-anchor="middle" fill="#e8410a" font-size="11" font-weight="bold">AV Degenerate Feedback Loop — Chang Ch.6</text>
  <rect x="10"  y="30" width="130" height="40" rx="5" fill="#1a2332" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="75"  y="53" text-anchor="middle" fill="#93c5fd" font-size="9">AV deployed on</text>
  <text x="75"  y="65" text-anchor="middle" fill="#93c5fd" font-size="8">LOW risk segments only</text>
  <line x1="140" y1="50" x2="180" y2="50" stroke="#e8410a" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <rect x="180" y="30" width="140" height="40" rx="5" fill="#1a2332" stroke="#f59e0b" stroke-width="1.5"/>
  <text x="250" y="53" text-anchor="middle" fill="#fcd34d" font-size="9">Telemetry only from</text>
  <text x="250" y="65" text-anchor="middle" fill="#fcd34d" font-size="8">easy routes</text>
  <line x1="320" y1="50" x2="360" y2="50" stroke="#e8410a" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <rect x="360" y="30" width="150" height="40" rx="5" fill="#1a2332" stroke="#ef4444" stroke-width="1.5"/>
  <text x="435" y="53" text-anchor="middle" fill="#fca5a5" font-size="9">CRITICAL features</text>
  <text x="435" y="65" text-anchor="middle" fill="#fca5a5" font-size="8">never validated in reality</text>
  <line x1="510" y1="50" x2="550" y2="50" stroke="#e8410a" stroke-width="1.5" marker-end="url(#av-arr)"/>
  <rect x="550" y="30" width="140" height="40" rx="5" fill="#1a2332" stroke="#ef4444" stroke-width="2"/>
  <text x="620" y="53" text-anchor="middle" fill="#fca5a5" font-size="9">Phase 2 expansion</text>
  <text x="620" y="65" text-anchor="middle" fill="#fca5a5" font-size="8">delayed indefinitely</text>
  <path d="M 620 70 Q 620 120 350 120 Q 75 120 75 70" stroke="#ef4444" stroke-width="1.5" fill="none" stroke-dasharray="6,3" marker-end="url(#av-arr)"/>
  <text x="350" y="115" text-anchor="middle" fill="#ef4444" font-size="8">Feedback loop — model never improves on hard cases</text>
  <!-- Fix arrow -->
  <rect x="220" y="135" width="260" height="30" rx="5" fill="#0c1f3a" stroke="#10b981" stroke-width="1.5"/>
  <text x="350" y="153" text-anchor="middle" fill="#6ee7b7" font-size="9">Chang Fix: Isaac Sim generates synthetic CRITICAL data → breaks catch-22</text>
</svg>'
            ),
            br(),
            div(class="success-box", HTML("<strong>Solution:</strong> Isaac Sim generates synthetic CRITICAL scenario data (tunnel traversal, complex roundabout dynamics, extreme gradient braking) that real-world data collection cannot safely provide. This breaks the feedback loop by ensuring the model is trained and evaluated on CRITICAL scenarios even before real AV deployment on those segments."))
          ),

          avPanel("av7p3",
            div(class="section-heading-dark", "Responsible AV AI — Chang Ch.6 + AV Act 2024"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Geographic Fairness"),
                  tags$ul(
                    tags$li(tags$b("Training bias:"), " Training concentrated on Cambridge urban routes. Rural roads may score LOW incorrectly — no detected YOLO features on a rural road may mean no hazards present, OR may mean Street View coverage is absent."),
                    tags$li(tags$b("Fairness requirement:"), " Model must not give a false LOW score to a rural segment simply because it lacks training data. Chang fix: explicit 'low_visual_confidence' flag when Street View unavailable — default MEDIUM, not LOW."),
                    tags$li(tags$b("Sliced evaluation mandatory:"), " Separate CRITICAL recall for urban vs rural vs suburban before any UK-wide ODD submission.")
                  )
                ),
                div(class="framework-card",
                  tags$h5("GDPR — Street View Privacy"),
                  tags$ul(
                    tags$li("Street View images contain faces and vehicle plates — PII under GDPR"),
                    tags$li("Google applies automatic blurring — verify before using raw API response images"),
                    tags$li("Images retained >30 days requires Data Protection Impact Assessment (DPIA)"),
                    tags$li("Cannot use images for facial recognition — explicit policy prohibition"),
                    tags$li("Chang: document data retention policy in model card; specify maximum storage duration per image batch")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("AV Act 2024 as Responsible AI Mandate"),
                  tags$ul(
                    tags$li(tags$b("ODD declaration:"), " Requires calibrated, explainable scores. Score 0.30 must mean 30% probability of correct risk classification — Platt scaling provides this."),
                    tags$li(tags$b("Safety case = ML evidence:"), " SHAP + calibration plots + sliced evaluation are not optional diagnostics — they are regulatory deliverables for WP5 and WP6 Innovate UK reports."),
                    tags$li(tags$b("Incident attribution:"), " If AV has an incident on a segment scored LOW, the model version and its feature inputs at the time of assessment must be retrievable. GCS versioned Parquet provides this audit trail."),
                    tags$li(tags$b("Human oversight:"), " ODD-Boundary segments always require alert to driver — no fully autonomous operation at score 0.35-0.65. This is a non-negotiable policy constraint, not a model parameter.")
                  )
                )
              )
            )
          ),

          avPanel("av7p4",
            div(class="section-heading-dark", "AteraSuite MLOps Stack — Chang Ch.6 Infrastructure Mapping"),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Layer"), tags$th("Chang Category"), tags$th("Current Tool"), tags$th("Recommended (Phase 2)"))),
              tags$tbody(
                tags$tr(tags$td("Data storage"), tags$td("Data layer"), tags$td("Local filesystem + GCS"), tags$td("GCS Parquet with Hive partitioning")),
                tags$tr(tags$td("Feature store"), tags$td("Feature layer"), tags$td("reactiveValues (in-session)"), tags$td("File-based Parquet store with version metadata")),
                tags$tr(tags$td("Experiment tracking"), tags$td("Training layer"), tags$td("None currently"), tags$td("MLflow (lightweight, runs on T500)")),
                tags$tr(tags$td("Model registry"), tags$td("Training layer"), tags$td("models/ directory"), tags$td("MLflow Registry with stage transitions")),
                tags$tr(tags$td("Model training"), tags$td("Training layer"), tags$td("Ultralytics CLI + R xgboost on T500"), tags$td("Same — appropriate for dataset size")),
                tags$tr(tags$td("Serving"), tags$td("Serving layer"), tags$td("Flask HTTP + R Shiny"), tags$td("Same + Jetson TensorRT for Phase 3")),
                tags$tr(tags$td("Orchestration"), tags$td("Orchestration"), tags$td("Manual"), tags$td("Prefect (lightweight Python orchestrator)")),
                tags$tr(tags$td("Monitoring"), tags$td("Monitoring layer"), tags$td("Custom R Shiny dashboard"), tags$td("+ PSI alerting, drift detection module")),
                tags$tr(tags$td("Compute"), tags$td("Infrastructure"), tags$td("T500 workstation (local)"), tags$td("T500 + GCP BigQuery connector for UK scale"))
              )
            ),
            br(),
            div(class="framework-card",
              tags$h5("Chang Build vs Buy — AteraSuite Decision"),
              fluidRow(
                column(6,
                  div(class="success-box", HTML("<strong>Build:</strong> AV readiness model (core IP), risk classification rubric (UK-specific + regulatory), R Shiny risk map interface (bespoke AteraSuite workflow), feature pipelines (AV-specific OSM/YOLO/physics transformations).")),
                ),
                column(6,
                  div(class="tip-box", HTML("<strong>Buy:</strong> YOLOv8 pretrained weights (COCO is commodity; fine-tuning is the differentiation), OSM routing (osmdata/dodgr), Google Maps API (no viable alternative at scale), Isaac Sim PhysX (physics engine is commodity; vehicle configs are custom). <em>Competitive advantage = the integration of all five sources.</em>"))
                )
              )
            )
          )
      )
    ),

    # ── Self-Assessment ──
    fluidRow(
      box(title="Self-Assessment — AV Infrastructure Case Study", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(4, sliderInput(ns("sc1"),"Requirements & AV Act (Ch.1-2)",1,10,5)),
            column(4, sliderInput(ns("sc2"),"Data Pipeline & Isaac Sim (Ch.3)",1,10,5)),
            column(4, sliderInput(ns("sc3"),"Feature Engineering & SHAP (Ch.4)",1,10,5))
          ),
          fluidRow(
            column(4, sliderInput(ns("sc4"),"YOLOv8 + XGBoost Modelling (Ch.5)",1,10,5)),
            column(4, sliderInput(ns("sc5"),"Spatial Eval & Safety Case (Ch.6)",1,10,5)),
            column(4, sliderInput(ns("sc6"),"Serving, Monitoring & Responsible AI (Ch.7-8)",1,10,5))
          ),
          fluidRow(
            column(4, actionButton(ns("save_self"),"Save Assessment", class="btn-meta", width="100%")),
            column(8, uiOutput(ns("self_result")))
          )
      )
    )
  )
}

av_infrastructure_case_study_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_self, {
      avg <- mean(c(input$sc1, input$sc2, input$sc3, input$sc4, input$sc5, input$sc6))
      pct <- round(avg * 10)
      prep_manager$update_progress("av_infrastructure_case_study", pct)
      output$self_result <- renderUI({
        col <- progress_colour(pct)
        div(class=if(pct>=80)"success-box" else "tip-box",
            tags$h5(style=paste0("color:",col), paste0("AV Infrastructure Readiness: ", pct, "%")),
            if(pct < 50)  tags$p("Focus on Chang Ch.4 (spatial split + calibration for safety case) and Ch.3 (Isaac Sim as synthetic data generator). These are the most distinctive aspects of AV ML vs standard ML."),
            if(pct >= 50 && pct < 80) tags$p("Good foundation. Deepen on: AV Act 2024 ODD boundary definition, SHAP as regulatory evidence, and the phased deployment shadow/canary pattern."),
            if(pct >= 80) tags$p("\u2705 Excellent. You can walk through the full AV infrastructure ML system with Chang framework, including regulatory constraints and responsible AI implications."))
      })
      showNotification("AV assessment saved!", type="message")
    })
  })
}
